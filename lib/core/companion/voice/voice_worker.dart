import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'whisper_transcriber.dart';

/// What the background worker reports back.
sealed class VoiceWorkerEvent {
  const VoiceWorkerEvent();
}

class WorkerSpeechStarted extends VoiceWorkerEvent {
  const WorkerSpeechStarted();
}

class WorkerProcessing extends VoiceWorkerEvent {
  const WorkerProcessing();
}

class WorkerTranscript extends VoiceWorkerEvent {
  const WorkerTranscript(this.text);

  /// Null when the segment had no usable words.
  final String? text;
}

/// Runs the always-on pipeline in a background isolate, so the UI never
/// stutters:
///
/// `16 kHz audio -> Silero VAD (is the child talking?) -> finished
///  sentence -> Whisper tiny -> text`
///
/// Both models load once; audio chunks stream in through [addAudio].
class VoiceWorker {
  VoiceWorker._(this._isolate, this._commands, this._responses, this.events);

  final Isolate _isolate;
  final SendPort _commands;
  final ReceivePort _responses;
  final Stream<VoiceWorkerEvent> events;
  bool _closed = false;

  static const String vadName = 'silero_vad.onnx';

  /// Every model file the worker needs, relative to its directory.
  static const List<String> modelNames = [...WhisperModelFiles.names, vadName];

  /// Loads the models found in [modelDir]. Throws when they can't load.
  static Future<VoiceWorker> spawn(String modelDir) async {
    final responses = ReceivePort();
    final isolate = await Isolate.spawn(_main, (responses.sendPort, modelDir));
    final events = StreamController<VoiceWorkerEvent>.broadcast();
    final ready = Completer<Object?>();
    responses.listen((message) {
      if (!ready.isCompleted) {
        ready.complete(message);
        return;
      }
      switch (message) {
        case 'start':
          events.add(const WorkerSpeechStarted());
        case 'processing':
          events.add(const WorkerProcessing());
        case ('text', final String? text):
          events.add(WorkerTranscript(text));
      }
    });
    final first = await ready.future;
    if (first is! SendPort) {
      responses.close();
      isolate.kill();
      throw StateError('Voice models failed to load: $first');
    }
    return VoiceWorker._(isolate, first, responses, events.stream);
  }

  /// 16 kHz mono samples (-1..1) from the microphone.
  void addAudio(Float32List samples) {
    if (_closed || samples.isEmpty) return;
    _commands.send(('audio', TransferableTypedData.fromList([samples])));
  }

  void setHint(SpeechLanguageHint hint) {
    if (!_closed) _commands.send(('hint', hint.index));
  }

  /// Forgets any half-heard sentence (after the Dino talked or a pause).
  void reset() {
    if (!_closed) _commands.send('reset');
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _commands.send(null);
    _responses.close();
    // The isolate frees the models and exits; kill() is the safety net.
    Future<void>.delayed(const Duration(seconds: 2), _isolate.kill);
  }

  // ---- background isolate -------------------------------------------------

  /// Silero works on fixed windows of 512 samples (32 ms).
  static const int _window = 512;

  static void _main((SendPort, String) args) {
    final (reply, dir) = args;
    final WhisperTranscriber transcriber;
    final sherpa.VoiceActivityDetector vad;
    try {
      transcriber = WhisperTranscriber(WhisperModelFiles.inDirectory(dir));
      vad = sherpa.VoiceActivityDetector(
        config: sherpa.VadModelConfig(
          sileroVad: sherpa.SileroVadModelConfig(
            model: '$dir/$vadName',
            // Children pause mid-sentence: wait a bit before cutting.
            minSilenceDuration: 0.7,
            minSpeechDuration: 0.25,
            maxSpeechDuration: 8,
          ),
          numThreads: 1,
          debug: false,
        ),
        bufferSizeInSeconds: 30,
      );
    } catch (e) {
      reply.send('$e');
      return;
    }

    final commands = ReceivePort();
    reply.send(commands.sendPort);

    var hint = SpeechLanguageHint.auto;
    var pending = Float32List(0);
    var speaking = false;

    void drainSegments() {
      while (!vad.isEmpty()) {
        final segment = vad.front();
        vad.pop();
        speaking = false;
        reply.send('processing');
        String? text;
        try {
          text = transcriber.transcribe(segment.samples, hint: hint)?.text;
        } catch (_) {
          text = null;
        }
        reply.send(('text', text));
      }
    }

    commands.listen((message) {
      switch (message) {
        case null:
          vad.free();
          transcriber.free();
          commands.close();
          Isolate.exit();
        case 'reset':
          vad.reset();
          pending = Float32List(0);
          speaking = false;
        case ('hint', final int index):
          hint = SpeechLanguageHint.values[index];
        case ('audio', final TransferableTypedData data):
          final chunk = data.materialize().asFloat32List();
          final all = Float32List(pending.length + chunk.length)
            ..setAll(0, pending)
            ..setAll(pending.length, chunk);
          var offset = 0;
          while (all.length - offset >= _window) {
            vad.acceptWaveform(
              Float32List.sublistView(all, offset, offset + _window),
            );
            offset += _window;
            if (!speaking && vad.isDetected()) {
              speaking = true;
              reply.send('start');
            }
            drainSegments();
          }
          pending = Float32List.fromList(Float32List.sublistView(all, offset));
      }
    });
  }
}
