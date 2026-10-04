import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../speech/speech_service.dart';
import 'portuguese_voice.dart';

/// Natural offline Portuguese: a bundled Piper voice synthesised on the
/// device (sherpa-onnx, background isolate) and played locally. No
/// network, no account. If the voice isn't bundled or fails to start, it
/// falls back to [fallback] (the device TTS) for good.
class PiperPortugueseVoice implements PortugueseVoiceService {
  PiperPortugueseVoice({
    required this.fallback,
    PortugueseVoiceModel? model,
    AssetBundle? bundle,
  }) : model = model ?? PortugueseVoiceModel.selected,
       _bundle = bundle ?? rootBundle;

  final PortugueseVoiceService fallback;
  final PortugueseVoiceModel model;
  final AssetBundle _bundle;

  /// Bump when a bundled file changes, so the device copy is refreshed.
  static const String filesVersion = '1';

  Future<_TtsWorker?>? _worker;
  bool _broken = false;
  AudioPlayer? _player;
  Completer<void>? _playing;
  int _generation = 0;

  static void _log(String message) => debugPrint('[voice-pt] $message');

  /// Loads the voice ahead of time (the first sentence then starts fast).
  Future<void> warmUp() async => _broken ? null : await _ensureWorker();

  @override
  Future<SpeechResult> speak(String text) async {
    final generation = ++_generation;
    final worker = _broken ? null : await _ensureWorker();
    if (worker == null) return fallback.speak(text);
    final wav = await worker.render(text);
    if (generation != _generation) return SpeechResult.spoken;
    if (wav == null) return fallback.speak(text);
    try {
      final player = _player ??= AudioPlayer();
      final done = _playing = Completer<void>();
      final sub = player.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete();
      });
      await player.play(DeviceFileSource(wav));
      await done.future;
      await sub.cancel();
      return SpeechResult.spoken;
    } catch (e) {
      _log('play: $e');
      return SpeechResult.failed;
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    final playing = _playing;
    if (playing != null && !playing.isCompleted) playing.complete();
    try {
      await _player?.stop();
    } catch (_) {}
    await fallback.stop();
  }

  Future<_TtsWorker?> _ensureWorker() => _worker ??= _start();

  Future<_TtsWorker?> _start() async {
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/voice_pt');
      final marker = File('${dir.path}/VERSION');
      final version = '$filesVersion-${model.id}';
      if (!await marker.exists() || await marker.readAsString() != version) {
        _log('copying ${model.id}...');
        final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
        final assets = manifest.listAssets().where(
          (a) =>
              a.startsWith('${PortugueseVoiceModel.espeakAssetDir}/') ||
              a == model.modelAsset ||
              a == model.tokensAsset,
        );
        if (!assets.contains(model.modelAsset)) {
          throw StateError('voice ${model.id} is not bundled');
        }
        for (final asset in assets) {
          final relative = asset.substring(
            PortugueseVoiceModel.espeakRoot.length + 1,
          );
          final file = File('${dir.path}/$relative');
          await file.parent.create(recursive: true);
          final data = await _bundle.load(asset);
          await file.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            flush: true,
          );
        }
        await marker.writeAsString(version, flush: true);
      }
      final worker = await _TtsWorker.spawn(
        _TtsConfig(
          model: '${dir.path}/${model.id}/model.onnx',
          tokens: '${dir.path}/${model.id}/tokens.txt',
          dataDir: '${dir.path}/espeak-ng-data',
          outDir: (await getTemporaryDirectory()).path,
          lengthScale: model.lengthScale,
        ),
      );
      _log('${model.id} ready');
      return worker;
    } catch (e) {
      _log('unavailable, using the device voice: $e');
      _broken = true;
      return null;
    }
  }
}

class _TtsConfig {
  const _TtsConfig({
    required this.model,
    required this.tokens,
    required this.dataDir,
    required this.outDir,
    required this.lengthScale,
  });

  final String model;
  final String tokens;
  final String dataDir;
  final String outDir;
  final double lengthScale;
}

/// Background isolate owning the sherpa-onnx TTS: text in, WAV path out
/// (synthesis never blocks the UI).
class _TtsWorker {
  _TtsWorker._(this._commands);

  final SendPort _commands;
  final Map<int, Completer<String?>> _pending = {};
  int _nextId = 0;

  static Future<_TtsWorker> spawn(_TtsConfig config) async {
    final responses = ReceivePort();
    await Isolate.spawn(_main, (responses.sendPort, config));
    final events = responses.asBroadcastStream();
    final first = await events.first;
    if (first is! SendPort) {
      responses.close();
      throw StateError('$first');
    }
    final worker = _TtsWorker._(first);
    events.listen((message) {
      if (message case (final int id, final String? path)) {
        worker._pending.remove(id)?.complete(path);
      }
    });
    return worker;
  }

  Future<String?> render(String text) {
    final id = _nextId++;
    final completer = _pending[id] = Completer<String?>();
    _commands.send((id, text));
    return completer.future;
  }

  static void _main((SendPort, _TtsConfig) args) {
    final (reply, config) = args;
    final sherpa.OfflineTts tts;
    try {
      tts = sherpa.OfflineTts(
        sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            vits: sherpa.OfflineTtsVitsModelConfig(
              model: config.model,
              tokens: config.tokens,
              dataDir: config.dataDir,
              lengthScale: config.lengthScale,
            ),
            numThreads: 2,
            debug: false,
          ),
        ),
      );
    } catch (e) {
      reply.send('$e');
      return;
    }
    final commands = ReceivePort();
    reply.send(commands.sendPort);
    var n = 0;
    commands.listen((message) {
      if (message case (final int id, final String text)) {
        try {
          final audio = tts.generate(text: text);
          // Two files in rotation: the previous one may still be playing.
          final path = '${config.outDir}/dino_pt_${n++ % 2}.wav';
          final ok = sherpa.writeWave(
            filename: path,
            samples: audio.samples,
            sampleRate: audio.sampleRate,
          );
          reply.send((id, ok ? path : null));
        } catch (_) {
          reply.send((id, null));
        }
      }
    });
  }
}
