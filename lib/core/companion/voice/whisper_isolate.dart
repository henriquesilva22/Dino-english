import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'whisper_transcriber.dart';

/// Keeps one [WhisperTranscriber] alive in a background isolate: the
/// model loads once (about a second) and each clip is decoded without
/// freezing the UI.
class WhisperIsolate {
  WhisperIsolate._(this._isolate, this._commands, this._responses);

  final Isolate _isolate;
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<SpeechTranscript?>> _pending = {};
  int _nextId = 0;
  bool _closed = false;

  static Future<WhisperIsolate> spawn(WhisperModelFiles files) async {
    final responses = ReceivePort();
    final isolate = await Isolate.spawn(_main, (
      responses.sendPort,
      files.encoder,
      files.decoder,
      files.tokens,
    ));
    final first = Completer<Object?>();
    late final WhisperIsolate worker;
    responses.listen((message) {
      if (!first.isCompleted) {
        first.complete(message);
        return;
      }
      final (id, text, language) = message as (int, String?, String?);
      final completer = worker._pending.remove(id);
      completer?.complete(
        text == null ? null : SpeechTranscript(text, language ?? ''),
      );
    });
    final ready = await first.future;
    if (ready is! SendPort) {
      responses.close();
      isolate.kill();
      throw StateError('Whisper failed to load: $ready');
    }
    return worker = WhisperIsolate._(isolate, ready, responses);
  }

  Future<SpeechTranscript?> transcribe(
    Float32List samples, {
    SpeechLanguageHint hint = SpeechLanguageHint.auto,
  }) {
    if (_closed) return Future.value();
    final id = _nextId++;
    final completer = _pending[id] = Completer<SpeechTranscript?>();
    _commands.send((id, TransferableTypedData.fromList([samples]), hint.index));
    return completer.future;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _commands.send(null);
    _responses.close();
    for (final c in _pending.values) {
      c.complete();
    }
    _pending.clear();
    // The isolate frees the model and exits; kill() is the safety net.
    Future<void>.delayed(const Duration(seconds: 2), _isolate.kill);
  }

  static void _main((SendPort, String, String, String) args) {
    final (reply, encoder, decoder, tokens) = args;
    final WhisperTranscriber transcriber;
    try {
      transcriber = WhisperTranscriber(
        WhisperModelFiles(encoder: encoder, decoder: decoder, tokens: tokens),
      );
    } catch (e) {
      reply.send('$e');
      return;
    }
    final commands = ReceivePort();
    reply.send(commands.sendPort);
    commands.listen((message) {
      if (message == null) {
        transcriber.free();
        commands.close();
        Isolate.exit();
      }
      final (id, data, hintIndex) =
          message as (int, TransferableTypedData, int);
      final samples = data.materialize().asFloat32List();
      SpeechTranscript? result;
      try {
        result = transcriber.transcribe(
          samples,
          hint: SpeechLanguageHint.values[hintIndex],
        );
      } catch (_) {
        result = null;
      }
      reply.send((id, result?.text, result?.language));
    });
  }
}
