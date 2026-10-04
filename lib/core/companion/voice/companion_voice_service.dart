import 'package:flutter/foundation.dart';

import '../../speech/speech_service.dart';
import '../companion_response.dart';
import 'portuguese_voice.dart';

/// The sentence being spoken right now (drives the Dino's mouth).
class SpokenLine {
  const SpokenLine(this.text, this.locale);

  final String text;

  /// `en-US` or `pt-BR`.
  final String locale;

  bool get isEnglish => locale == kEnglishLocale;
}

/// How the companion's replies are voiced. The `CompanionEngine` never
/// touches audio: swapping the implementation (device TTS today, bundled
/// audio clips or another offline voice later) needs no engine change.
abstract class CompanionVoiceService {
  /// Voices [response] by its [CompanionResponse.voice]: English only
  /// (the Portuguese stays on screen), Portuguese only, or English then
  /// Portuguese. Never throws; without a voice the text stays on screen.
  Future<void> say(CompanionResponse response);

  /// Stops talking right away.
  Future<void> stop();

  /// Non-null for the whole time the Dino talks (English + Portuguese,
  /// including the short gaps between them) -- the microphone stays
  /// closed meanwhile so the Dino never hears itself.
  ValueListenable<Object?> get speaking;

  /// The line being spoken, or null between/after lines.
  ValueListenable<SpokenLine?> get currentLine;
}

/// Default voice: English through the app's offline [SpeechService]
/// (device TTS, offline voices preferred, no online fallback) in a
/// slightly higher, friendly pitch; Portuguese through [PortugueseVoiceService]
/// (a bundled neural voice, or the device TTS).
class TtsCompanionVoiceService implements CompanionVoiceService {
  TtsCompanionVoiceService(this._speech, {PortugueseVoiceService? portuguese})
    : _portuguese =
          portuguese ??
          SystemPortugueseVoice(
            _speech,
            rate: portugueseRate,
            pitch: dinoPitch,
          );

  final SpeechService _speech;
  final PortugueseVoiceService _portuguese;
  final ValueNotifier<Object?> _speaking = ValueNotifier(null);
  final ValueNotifier<SpokenLine?> _line = ValueNotifier(null);

  /// Bumped by every [say]/[stop]: an older sequence stops at its next
  /// line instead of talking over the new one.
  int _generation = 0;

  /// Locales without a voice on this device: not retried every line.
  final Set<String> _missing = {};

  /// The Dino is a baby: a bit higher than a normal voice.
  static const double dinoPitch = 1.25;
  static const double englishRate = 0.42;
  static const double portugueseRate = 0.5;

  /// Emoji and symbols the TTS would read out loud ("red apple").
  static final RegExp _nonSpeakable = RegExp(
    r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}*]',
    unicode: true,
  );

  static String speakable(String text) =>
      text.replaceAll(_nonSpeakable, '').replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  ValueListenable<Object?> get speaking => _speaking;

  @override
  ValueListenable<SpokenLine?> get currentLine => _line;

  @override
  Future<void> say(CompanionResponse response) async {
    final generation = ++_generation;
    final token = Object();
    final mode = response.voice;
    final queue = [
      for (final line in response.lines) ...[
        if (mode == VoiceMode.portuguese)
          SpokenLine(
            speakable(line.translation ?? line.text),
            kPortugueseLocale,
          )
        else
          SpokenLine(speakable(line.text), kEnglishLocale),
        if (mode == VoiceMode.bilingual)
          if (line.translation case final pt?)
            SpokenLine(speakable(pt), kPortugueseLocale),
      ],
    ].where((l) => l.text.isNotEmpty && !_missing.contains(l.locale));
    if (queue.isEmpty) return;

    _speaking.value = token;
    try {
      for (final line in queue) {
        if (generation != _generation) return;
        _line.value = line;
        final result = line.isEnglish
            ? await _speech.speak(
                line.text,
                locale: line.locale,
                rate: englishRate,
                pitch: dinoPitch,
              )
            : await _portuguese.speak(line.text);
        if (result == SpeechResult.noEnglishVoice ||
            result == SpeechResult.noVoice) {
          _missing.add(line.locale);
        }
        if (generation == _generation) _line.value = null;
      }
    } finally {
      if (generation == _generation) {
        _line.value = null;
        _speaking.value = null;
      }
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    _line.value = null;
    _speaking.value = null;
    await _speech.stop();
    await _portuguese.stop();
  }
}
