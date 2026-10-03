import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'speech_recognition_service.dart';

export 'speech_recognition_service.dart' show SpeechLanguageHint;

/// The three files of the bundled offline model (Whisper tiny, int8,
/// sherpa-onnx export) -- see `tool/download_voice_model.sh`.
class WhisperModelFiles {
  const WhisperModelFiles({
    required this.encoder,
    required this.decoder,
    required this.tokens,
  });

  factory WhisperModelFiles.inDirectory(String dir) => WhisperModelFiles(
    encoder: '$dir/$encoderName',
    decoder: '$dir/$decoderName',
    tokens: '$dir/$tokensName',
  );

  static const String encoderName = 'tiny-encoder.int8.onnx';
  static const String decoderName = 'tiny-decoder.int8.onnx';
  static const String tokensName = 'tiny-tokens.txt';
  static const List<String> names = [encoderName, decoderName, tokensName];

  final String encoder;
  final String decoder;
  final String tokens;
}

class SpeechTranscript {
  const SpeechTranscript(this.text, this.language);

  final String text;

  /// Language Whisper used (`en`, `pt`...), empty when unknown.
  final String language;
}

/// Offline speech-to-text over sherpa-onnx + Whisper tiny. Synchronous and
/// CPU-heavy (about a second per short clip on a phone): call it from a
/// background isolate (`WhisperIsolate`), never from the UI isolate.
class WhisperTranscriber {
  WhisperTranscriber(this._files, {int numThreads = 2}) {
    sherpa.initBindings();
    _recognizer = sherpa.OfflineRecognizer(_config('', numThreads));
    _numThreads = numThreads;
  }

  final WhisperModelFiles _files;
  late final sherpa.OfflineRecognizer _recognizer;
  late final int _numThreads;
  String _language = '';

  static const int sampleRate = 16000;

  /// Clips shorter or quieter than this are "nothing said": Whisper
  /// invents sentences out of silence, so it never even sees them.
  static const Duration minDuration = Duration(milliseconds: 300);
  static const double minRms = 0.006;

  /// Whisper's well-known inventions on noise (subtitle credits from its
  /// training data), compared lowercase without punctuation. "Obrigado"
  /// and "thank you" are also classic ones, but a child really says them
  /// to the Dino -- the silence gate ([minRms]) handles those instead.
  static const Set<String> _hallucinations = {
    'thanks for watching',
    'thank you for watching',
    'you',
    'legendas pela comunidade amaraorg',
    'legenda adriana zanotto',
    'subtitles by the amaraorg community',
    'inscrevase no canal',
  };

  sherpa.OfflineRecognizerConfig _config(String language, int threads) =>
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: _files.encoder,
            decoder: _files.decoder,
            language: language,
            task: 'transcribe',
          ),
          tokens: _files.tokens,
          modelType: 'whisper',
          numThreads: threads,
          debug: false,
        ),
      );

  /// Transcribes 16 kHz mono [samples] (-1..1). Returns null when nothing
  /// usable was said.
  SpeechTranscript? transcribe(
    Float32List samples, {
    SpeechLanguageHint hint = SpeechLanguageHint.auto,
  }) {
    if (!hasSpeech(samples)) return null;
    var result = _decode(samples, switch (hint) {
      SpeechLanguageHint.auto => '',
      SpeechLanguageHint.english => 'en',
      SpeechLanguageHint.portuguese => 'pt',
    });
    // Auto-detection picked a third language (often Spanish/Galician for
    // a Brazilian child): the child speaks Portuguese or English, so
    // decode again as Portuguese.
    if (hint == SpeechLanguageHint.auto &&
        result.language.isNotEmpty &&
        result.language != 'en' &&
        result.language != 'pt') {
      result = _decode(samples, 'pt');
    }
    final text = clean(result.text);
    return text == null ? null : SpeechTranscript(text, result.language);
  }

  SpeechTranscript _decode(Float32List samples, String language) {
    if (language != _language) {
      _recognizer.setConfig(_config(language, _numThreads));
      _language = language;
    }
    final stream = _recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
      _recognizer.decode(stream);
      final result = _recognizer.getResult(stream);
      return SpeechTranscript(result.text, _bareLanguage(result.lang));
    } finally {
      stream.free();
    }
  }

  void free() => _recognizer.free();

  /// `<|pt|>` / `pt` -> `pt`.
  static String _bareLanguage(String raw) =>
      raw.replaceAll(RegExp(r'[<|>]'), '').trim().toLowerCase();

  static bool hasSpeech(Float32List samples) {
    if (samples.length < sampleRate * minDuration.inMilliseconds / 1000) {
      return false;
    }
    var sum = 0.0;
    for (final s in samples) {
      sum += s * s;
    }
    return math.sqrt(sum / samples.length) >= minRms;
  }

  /// Confusions measured with the bundled model on children's phrases,
  /// rewritten to what the Dino understands. Add new ones here.
  static final List<(RegExp, String Function(Match))> _mishearings = [
    // "Você está com fome?" -> "Você está conforme?"
    (
      RegExp(r'\b(est[aá]|t[aá]|estou|t[oô]) conforme\b', caseSensitive: false),
      (m) => '${m[1]} com fome',
    ),
  ];

  /// Trims Whisper's output and drops known inventions. Null = nothing.
  static String? clean(String raw) {
    var text = collapseRepeats(
      raw
          .replaceAll(RegExp(r'\[[^\]]*\]|\([^)]*\)'), '') // [Music], (risos)
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    );
    for (final (pattern, fix) in _mishearings) {
      text = text.replaceAllMapped(pattern, fix);
    }
    final bare = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '')
        .trim();
    if (bare.isEmpty || _hallucinations.contains(bare)) return null;
    return text;
  }

  /// "Apple Apple Apple Apple" -> "Apple": Whisper loops on short clips.
  static String collapseRepeats(String text) {
    String bare(String w) =>
        w.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    final out = <String>[];
    for (final word in text.split(' ')) {
      if (out.isNotEmpty &&
          bare(word).isNotEmpty &&
          bare(out.last) == bare(word)) {
        continue;
      }
      out.add(word);
    }
    return out.join(' ');
  }

  /// 16-bit little-endian PCM (what the recorder streams) -> -1..1.
  static Float32List pcm16ToFloat(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final out = Float32List(bytes.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }
}
