import 'package:dino_english/core/companion/voice/portuguese_voice.dart';
import 'package:dino_english/core/speech/speech_service.dart';
import 'package:dino_english/game/sound/word_catch_voice.dart';
import 'package:dino_english/game/word_catch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _English implements SpeechService {
  final List<String> said = [];
  final List<String> locales = [];

  @override
  Future<SpeechResult> speak(
    String text, {
    String locale = kEnglishLocale,
    double? rate,
    double? pitch,
  }) async {
    said.add(text);
    locales.add(locale);
    return SpeechResult.spoken;
  }

  @override
  Future<void> stop() async {}

  @override
  ValueListenable<Object?> get activeUtterance => ValueNotifier(null);
}

class _Portuguese implements PortugueseVoiceService {
  final List<String> said = [];

  @override
  Future<SpeechResult> speak(String text) async {
    said.add(text);
    return SpeechResult.spoken;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  late _English english;
  late _Portuguese portuguese;
  late DateTime now;
  late WordCatchVoice voice;

  setUp(() {
    english = _English();
    portuguese = _Portuguese();
    now = DateTime(2026, 10, 13);
    voice = WordCatchVoice(
      english: () => english,
      portuguese: () => portuguese,
      clock: () => now,
    );
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a correct catch says the word in English', () async {
    voice.say(const CorrectWordCaught('bread'));
    await settle();
    expect(english.said, ['Bread']);
    expect(english.locales, [kEnglishLocale]);
    expect(portuguese.said, isEmpty);
  });

  test('a wrong catch says "Errou!" in Portuguese', () async {
    voice.say(const WrongWordCaught('brede'));
    await settle();
    expect(portuguese.said, ['Errou!']);
    expect(english.said, isEmpty);
  });

  test('one event reported twice is said once; a new word is said', () async {
    voice
      ..say(const CorrectWordCaught('apple'))
      ..say(const CorrectWordCaught('apple'));
    await settle();
    expect(english.said, ['Apple']);
    now = now.add(const Duration(seconds: 1));
    voice.say(const CorrectWordCaught('apple'));
    await settle();
    expect(english.said, ['Apple', 'Apple']);
  });

  test('only the newest catch is spoken (no pile-up)', () async {
    voice
      ..say(const CorrectWordCaught('apple'))
      ..say(const CorrectWordCaught('bread'));
    await settle();
    expect(english.said, ['Bread']);
  });

  test('after leaving the game nothing more is said', () async {
    await voice.close();
    voice.say(const CorrectWordCaught('bread'));
    await settle();
    expect(english.said, isEmpty);
  });
}
