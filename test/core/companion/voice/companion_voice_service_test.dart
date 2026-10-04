import 'dart:async';

import 'package:dino_english/core/companion/companion_response.dart';
import 'package:dino_english/core/companion/companion_state.dart';
import 'package:dino_english/core/companion/voice/companion_voice_service.dart';
import 'package:dino_english/core/speech/speech_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _Utterance {
  _Utterance(this.text, this.locale, this.rate, this.pitch, this.speaking);

  final String text;
  final String locale;
  final double? rate;
  final double? pitch;

  /// Was the companion "speaking" while this line played?
  final bool speaking;
}

class _FakeSpeech implements SpeechService {
  late final TtsCompanionVoiceService voice;
  final List<_Utterance> said = [];
  final Set<String> missing = {};
  Completer<void>? hold;
  int stops = 0;

  @override
  Future<SpeechResult> speak(
    String text, {
    String locale = kEnglishLocale,
    double? rate,
    double? pitch,
  }) async {
    if (missing.contains(locale)) return SpeechResult.noVoice;
    said.add(
      _Utterance(text, locale, rate, pitch, voice.speaking.value != null),
    );
    await hold?.future;
    return SpeechResult.spoken;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  ValueListenable<Object?> get activeUtterance => ValueNotifier(null);
}

/// Bilingual by default: most tests here check the EN -> PT sequence.
CompanionResponse _reply(
  List<CompanionLine> lines, {
  VoiceMode voice = VoiceMode.bilingual,
}) => CompanionResponse(
  lines: lines,
  emotion: CompanionEmotion.happy,
  animation: CompanionAnimation.happy,
  state: CompanionState.initial(DateTime(2026)),
  voice: voice,
);

void main() {
  late _FakeSpeech speech;
  late TtsCompanionVoiceService voice;

  setUp(() {
    speech = _FakeSpeech();
    voice = TtsCompanionVoiceService(speech);
    speech.voice = voice;
  });

  test('English first, then Portuguese, line by line', () async {
    await voice.say(
      _reply(const [
        CompanionLine('Apple! 🍎', 'Maçã!'),
        CompanionLine('Say: Apple!', 'Diga: Apple!'),
      ]),
    );
    expect(speech.said.map((u) => '${u.locale} ${u.text}'), [
      'en-US Apple!',
      'pt-BR Maçã!',
      'en-US Say: Apple!',
      'pt-BR Diga: Apple!',
    ]);
  });

  test('usual reply: only English is spoken (Portuguese on screen)', () async {
    await voice.say(
      _reply(const [
        CompanionLine("I'm fine!", 'Estou bem!'),
      ], voice: VoiceMode.english),
    );
    expect(speech.said.map((u) => '${u.locale} ${u.text}'), [
      "en-US I'm fine!",
    ]);
  });

  test('Portuguese mode: the meaning in the Portuguese voice', () async {
    await voice.say(
      _reply(const [
        CompanionLine("I'm fine!", 'Estou bem!'),
      ], voice: VoiceMode.portuguese),
    );
    expect(speech.said.map((u) => '${u.locale} ${u.text}'), [
      'pt-BR Estou bem!',
    ]);
  });

  test('"speaking" covers the whole sequence, then turns off', () async {
    await voice.say(
      _reply(const [CompanionLine("I'm hungry!", 'Estou com fome!')]),
    );
    expect(speech.said, hasLength(2));
    expect(speech.said.every((u) => u.speaking), isTrue);
    expect(voice.speaking.value, isNull);
    expect(voice.currentLine.value, isNull);
  });

  test('the current line follows the audio (drives the mouth)', () async {
    speech.hold = Completer<void>();
    final done = voice.say(_reply(const [CompanionLine('Hi!', 'Oi!')]));
    await Future<void>.delayed(Duration.zero);
    expect(voice.currentLine.value?.text, 'Hi!');
    expect(voice.currentLine.value?.isEnglish, isTrue);
    speech.hold!.complete();
    speech.hold = null;
    await done;
    expect(voice.currentLine.value, isNull);
  });

  test('a friendly Dino voice: higher pitch, slower English', () async {
    await voice.say(_reply(const [CompanionLine('Hello!', 'Olá!')]));
    final en = speech.said.first;
    final pt = speech.said.last;
    expect(en.pitch, TtsCompanionVoiceService.dinoPitch);
    expect(en.rate, TtsCompanionVoiceService.englishRate);
    expect(pt.rate, TtsCompanionVoiceService.portugueseRate);
  });

  test('no Portuguese voice: English still spoken, no crash', () async {
    speech.missing.add(kPortugueseLocale);
    await voice.say(_reply(const [CompanionLine('Hello!', 'Olá!')]));
    await voice.say(_reply(const [CompanionLine('Bye!', 'Tchau!')]));
    expect(speech.said.map((u) => u.text), ['Hello!', 'Bye!']);
  });

  test('no voice at all: nothing breaks, "speaking" stays off', () async {
    speech.missing.addAll({kEnglishLocale, kPortugueseLocale});
    await voice.say(_reply(const [CompanionLine('Hello!', 'Olá!')]));
    expect(speech.said, isEmpty);
    expect(voice.speaking.value, isNull);
  });

  test('stop() cuts the rest of the sequence', () async {
    speech.hold = Completer<void>();
    final done = voice.say(_reply(const [CompanionLine('One', 'Um')]));
    await Future<void>.delayed(Duration.zero);
    await voice.stop();
    speech.hold!.complete();
    await done;
    expect(speech.said.map((u) => u.text), ['One']);
    expect(voice.speaking.value, isNull);
  });

  test('a new reply replaces the one being spoken', () async {
    speech.hold = Completer<void>();
    final first = voice.say(_reply(const [CompanionLine('First', 'Primeiro')]));
    await Future<void>.delayed(Duration.zero);
    final hold = speech.hold!;
    speech.hold = null;
    final second = voice.say(
      _reply(const [CompanionLine('Second', 'Segundo')]),
    );
    hold.complete();
    await Future.wait([first, second]);
    expect(speech.said.map((u) => u.text), ['First', 'Second', 'Segundo']);
  });
}
