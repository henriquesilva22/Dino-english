import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'speech_recognition_service.dart';
import 'voice_worker.dart';
import 'whisper_transcriber.dart';

/// Hands-free, offline voice input:
///
/// `record (16 kHz PCM stream) -> [muted? drop] -> VoiceWorker isolate
///  (Silero VAD + Whisper tiny) -> SpeechEvent`
///
/// The models are bundled in `assets/models/voice/` (see
/// `tool/download_voice_model.sh`) and copied once to app storage, since
/// the native runtime reads files, not Flutter assets. The microphone
/// permission is asked at runtime through `permission_handler`. Nothing
/// leaves the device.
class OfflineSpeechRecognitionService implements SpeechRecognitionService {
  OfflineSpeechRecognitionService({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String assetDir = 'assets/models/voice';

  /// Bump when a bundled model changes, so the copy is refreshed.
  static const String modelVersion = 'whisper-tiny-int8+silero-v2';

  final StreamController<SpeechEvent> _events =
      StreamController<SpeechEvent>.broadcast();
  Future<bool>? _available;
  Future<VoiceWorker?>? _worker;
  StreamSubscription<VoiceWorkerEvent>? _workerEvents;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audio;
  Future<bool>? _starting;
  bool _muted = false;
  bool _disposed = false;
  SpeechLanguageHint _hint = SpeechLanguageHint.auto;

  @override
  Stream<SpeechEvent> get events => _events.stream;

  @override
  bool get isRunning => _audio != null;

  @override
  Future<bool> isAvailable() => _available ??= _modelsBundled();

  Future<bool> _modelsBundled() async {
    try {
      final assets = (await AssetManifest.loadFromAssetBundle(
        _bundle,
      )).listAssets().toSet();
      return VoiceWorker.modelNames.every(
        (name) => assets.contains('$assetDir/$name'),
      );
    } catch (e) {
      _log('asset manifest: $e');
      return false;
    }
  }

  // ---- permission -----------------------------------------------------------

  static MicPermission _map(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited => MicPermission.granted,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => MicPermission.permanentlyDenied,
    _ => MicPermission.denied,
  };

  @override
  Future<MicPermission> checkPermission() async {
    try {
      return _map(await Permission.microphone.status);
    } catch (e) {
      _log('permission status: $e');
      return MicPermission.denied;
    }
  }

  @override
  Future<MicPermission> requestPermission() async {
    try {
      final result = _map(await Permission.microphone.request());
      _log('permission -> ${result.name}');
      return result;
    } catch (e) {
      _log('permission request: $e');
      return MicPermission.denied;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (_) {}
  }

  // ---- listening ------------------------------------------------------------

  @override
  Future<bool> start() {
    if (_disposed) return Future.value(false);
    if (isRunning) return Future.value(true);
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<bool> _start() async {
    if (!await isAvailable()) return false;
    if (await checkPermission() != MicPermission.granted) return false;
    final worker = await _ensureWorker();
    if (worker == null || _disposed) return false;
    try {
      final recorder = _recorder ??= AudioRecorder();
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: WhisperTranscriber.sampleRate,
          numChannels: 1,
          autoGain: true,
          noiseSuppress: true,
          echoCancel: true,
        ),
      );
      worker
        ..reset()
        ..setHint(_hint);
      _audio = stream.listen(
        (bytes) {
          if (_muted) return;
          worker.addAudio(WhisperTranscriber.pcm16ToFloat(bytes));
        },
        onError: (Object e) {
          _log('mic stream: $e');
          _events.add(SpeechFailed('$e'));
          unawaited(stop());
        },
      );
      _log('listening');
      return true;
    } catch (e) {
      _log('mic start: $e');
      _events.add(SpeechFailed('$e'));
      return false;
    }
  }

  @override
  Future<void> stop() async {
    await _starting;
    final audio = _audio;
    _audio = null;
    await audio?.cancel();
    try {
      final recorder = _recorder;
      if (recorder != null && await recorder.isRecording()) {
        await recorder.stop();
      }
    } catch (e) {
      _log('mic stop: $e');
    }
    if (audio != null) _log('stopped');
  }

  @override
  void setMuted(bool muted) {
    if (_muted == muted) return;
    _muted = muted;
    // Back from mute: forget the half-sentence heard before it.
    if (!muted) unawaited(_worker?.then((w) => w?.reset()));
  }

  @override
  set languageHint(SpeechLanguageHint hint) {
    if (_hint == hint) return;
    _hint = hint;
    unawaited(_worker?.then((w) => w?.setHint(hint)));
  }

  // ---- models ---------------------------------------------------------------

  Future<VoiceWorker?> _ensureWorker() => _worker ??= _startWorker();

  Future<VoiceWorker?> _startWorker() async {
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/voice_model');
      final marker = File('${dir.path}/VERSION');
      if (!await marker.exists() ||
          await marker.readAsString() != modelVersion) {
        _log('copying models...');
        await dir.create(recursive: true);
        for (final name in VoiceWorker.modelNames) {
          final data = await _bundle.load('$assetDir/$name');
          await File('${dir.path}/$name').writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            flush: true,
          );
        }
        await marker.writeAsString(modelVersion, flush: true);
      }
      final worker = await VoiceWorker.spawn(dir.path);
      _workerEvents = worker.events.listen((event) {
        _events.add(switch (event) {
          WorkerSpeechStarted() => const SpeechStarted(),
          WorkerProcessing() => const SpeechProcessing(),
          WorkerTranscript(:final text?) => SpeechRecognized(text),
          WorkerTranscript() => const SpeechNothingHeard(),
        });
      });
      _log('models ready');
      return worker;
    } catch (e) {
      _log('models: $e');
      _events.add(SpeechFailed('$e'));
      // Allow a retry on the next start (e.g. storage was full).
      _worker = null;
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _recorder?.dispose();
    _recorder = null;
    await _workerEvents?.cancel();
    final worker = _worker;
    _worker = null;
    (await worker)?.close();
    await _events.close();
  }

  /// Visible in `adb logcat` (tag `flutter`), also in release builds.
  static void _log(String message) => debugPrint('[voice] $message');
}
