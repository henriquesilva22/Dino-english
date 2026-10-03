import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'speech_recognition_service.dart';
import 'whisper_isolate.dart';
import 'whisper_transcriber.dart';

/// Offline push-to-talk: the `record` plugin captures 16 kHz mono PCM and
/// Whisper tiny (sherpa-onnx) transcribes it on-device, in a background
/// isolate. The model is bundled in `assets/models/voice/` (see
/// `tool/download_voice_model.sh`) and copied once to app storage,
/// because the native runtime reads files, not Flutter assets. No audio
/// ever leaves the device.
class WhisperSpeechRecognitionService implements SpeechRecognitionService {
  WhisperSpeechRecognitionService({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String assetDir = 'assets/models/voice';

  /// Bump when the bundled model changes, so the copy is refreshed.
  static const String modelVersion = 'whisper-tiny-int8-v1';

  /// A press longer than this stops recording by itself.
  static const Duration maxListen = Duration(seconds: 10);

  Future<bool>? _available;
  Future<WhisperIsolate?>? _worker;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _subscription;
  Completer<void>? _streamDone;
  Timer? _maxTimer;
  final BytesBuilder _audio = BytesBuilder(copy: false);

  @override
  Future<bool> isAvailable() => _available ??= _modelIsBundled();

  Future<bool> _modelIsBundled() async {
    try {
      final assets = (await AssetManifest.loadFromAssetBundle(
        _bundle,
      )).listAssets().toSet();
      return WhisperModelFiles.names.every(
        (name) => assets.contains('$assetDir/$name'),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> prepare() async {
    if (await isAvailable()) await _ensureWorker();
  }

  Future<WhisperIsolate?> _ensureWorker() => _worker ??= _startWorker();

  Future<WhisperIsolate?> _startWorker() async {
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/voice_model');
      final marker = File('${dir.path}/VERSION');
      if (!await marker.exists() ||
          await marker.readAsString() != modelVersion) {
        await dir.create(recursive: true);
        for (final name in WhisperModelFiles.names) {
          final data = await _bundle.load('$assetDir/$name');
          await File('${dir.path}/$name').writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            flush: true,
          );
        }
        await marker.writeAsString(modelVersion, flush: true);
      }
      return await WhisperIsolate.spawn(
        WhisperModelFiles.inDirectory(dir.path),
      );
    } catch (_) {
      // Allow a retry on the next press (e.g. storage was full).
      _worker = null;
      return null;
    }
  }

  @override
  Future<bool> startListening() async {
    if (!await isAvailable()) return false;
    unawaited(_ensureWorker());
    try {
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission()) return false;
      await _stopCapture();
      _audio.clear();
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: WhisperTranscriber.sampleRate,
          numChannels: 1,
          autoGain: true,
          noiseSuppress: true,
        ),
      );
      final done = _streamDone = Completer<void>();
      _subscription = stream.listen(
        _audio.add,
        onDone: () => done.isCompleted ? null : done.complete(),
        onError: (_) => done.isCompleted ? null : done.complete(),
      );
      _maxTimer = Timer(maxListen, () => unawaited(recorder.stop()));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> stopListening({
    SpeechLanguageHint hint = SpeechLanguageHint.auto,
  }) async {
    try {
      await _stopCapture();
      final bytes = _audio.takeBytes();
      if (bytes.isEmpty) return null;
      final samples = WhisperTranscriber.pcm16ToFloat(bytes);
      final worker = await _ensureWorker();
      if (worker == null) return null;
      return (await worker.transcribe(samples, hint: hint))?.text;
    } catch (_) {
      return null;
    }
  }

  /// Stops the recorder and waits for its last buffered chunk.
  Future<void> _stopCapture() async {
    _maxTimer?.cancel();
    _maxTimer = null;
    final recorder = _recorder;
    if (recorder != null && await recorder.isRecording()) {
      await recorder.stop();
    }
    await _streamDone?.future.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () {},
    );
    await _subscription?.cancel();
    _subscription = null;
    _streamDone = null;
  }

  @override
  Future<void> cancel() async {
    try {
      await _stopCapture();
    } catch (_) {}
    _audio.clear();
  }

  @override
  Future<void> dispose() async {
    await cancel();
    await _recorder?.dispose();
    _recorder = null;
    final worker = _worker;
    _worker = null;
    (await worker)?.close();
  }
}
