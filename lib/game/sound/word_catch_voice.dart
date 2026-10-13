import 'dart:async';

import '../../core/companion/voice/portuguese_voice.dart';
import '../../core/speech/speech_service.dart';
import '../word_catch.dart';

/// The Dino's voice in Pet Adventure: a caught word is said in English
/// ("Bread!"), a wrong one gets a short "Errou!" in Portuguese. Offline
/// (the device TTS / the bundled Portuguese voice). Only the newest catch
/// is spoken -- a new one cuts the old one off, nothing piles up -- and
/// the same catch reported twice within [repeatWindow] is said once.
class WordCatchVoice {
  /// The voices are created on the first catch only (a game where nothing
  /// is caught never starts the TTS engines).
  WordCatchVoice({
    required SpeechService Function() english,
    required PortugueseVoiceService Function() portuguese,
    DateTime Function()? clock,
  }) : _englishOf = english,
       _portugueseOf = portuguese,
       _clock = clock ?? DateTime.now;

  final SpeechService Function() _englishOf;
  final PortugueseVoiceService Function() _portugueseOf;
  late final SpeechService _english = _englishOf();
  late final PortugueseVoiceService _portuguese = _portugueseOf();
  final DateTime Function() _clock;

  static const Duration repeatWindow = Duration(milliseconds: 300);
  static const double englishRate = 0.45;
  static const String wrongText = 'Errou!';

  String? _lastKey;
  DateTime? _lastAt;
  int _generation = 0;
  bool _closed = false;

  /// Voices [caught] (never throws, never waits for the voice).
  void say(WordCatch caught) {
    if (_closed) return;
    final key = switch (caught) {
      CorrectWordCaught(:final english) => 'ok:$english',
      WrongWordCaught() => 'wrong',
    };
    final now = _clock();
    if (key == _lastKey &&
        _lastAt != null &&
        now.difference(_lastAt!) < repeatWindow) {
      return;
    }
    _lastKey = key;
    _lastAt = now;
    unawaited(_speak(caught, ++_generation));
  }

  Future<void> _speak(WordCatch caught, int generation) async {
    try {
      await _english.stop();
      await _portuguese.stop();
      if (generation != _generation || _closed) return;
      switch (caught) {
        case CorrectWordCaught(:final english):
          await _english.speak(
            _capitalize(english),
            locale: kEnglishLocale,
            rate: englishRate,
          );
        case WrongWordCaught():
          await _portuguese.speak(wrongText);
      }
    } catch (_) {
      // Voice is a bonus: the game goes on without it.
    }
  }

  /// Leaving the game: stop talking, ignore later catches. A game where
  /// nothing was said never touches the voices.
  Future<void> close() async {
    _closed = true;
    if (_generation == 0) return;
    _generation++;
    try {
      await _english.stop();
      await _portuguese.stop();
    } catch (_) {}
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
