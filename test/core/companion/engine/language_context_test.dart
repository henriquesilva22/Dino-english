import 'dart:math';

import 'package:dino_english/core/brain/memory/dino_memory.dart';
import 'package:dino_english/core/companion/companion_engine.dart';
import 'package:dino_english/core/companion/companion_response.dart';
import 'package:dino_english/core/companion/companion_state.dart';
import 'package:dino_english/core/companion/engine/companion_intent.dart';
import 'package:dino_english/core/companion/engine/language_context_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../brain/brain_test_helpers.dart';

class _NoRewards implements CompanionRewards {
  @override
  Future<CompanionRewardResult> grant({
    required int xp,
    String? wordId,
    required String reason,
    bool countsAsExercise = true,
  }) async => CompanionRewardResult(xpAwarded: xp, level: 1);
}

void main() {
  final now = DateTime(2026, 10, 3, 10);

  Future<CompanionEngine> engine() async {
    final memory = DinoMemoryBank(InMemoryDinoMemoryStore());
    await memory.load();
    final e = CompanionEngine(
      vocabulary: seedVocabulary,
      memory: memory,
      store: InMemoryCompanionStateStore(
        CompanionState(
          hunger: 60,
          thirst: 60,
          energy: 80,
          happiness: 80,
          updatedAt: now,
        ),
      ),
      rewards: _NoRewards(),
      random: Random(1),
      clock: () => now,
    );
    await e.load();
    return e;
  }

  /// Like the controller: every reply shown is noted.
  Future<CompanionResponse> say(CompanionEngine e, String text) async {
    final r = await e.process(text);
    e.noteSaid(r);
    return r;
  }

  test('"Como você está?" -> English answer, English voice', () async {
    final e = await engine();
    final r = await say(e, 'Como você está?');
    expect(r.intent, CompanionIntent.askHowAreYou);
    expect(r.voice, VoiceMode.english);
    expect(r.portugueseText, isNotNull);
    expect(
      e.languageContext.conversationLanguage,
      ConversationLanguage.portuguese,
    );
    expect(
      e.languageContext.requestedExplanationLanguage,
      ExplanationLanguage.none,
    );
  });

  test('"How are you?" -> English answer, English voice', () async {
    final e = await engine();
    final r = await say(e, 'How are you?');
    expect(r.intent, CompanionIntent.askHowAreYou);
    expect(r.voice, VoiceMode.english);
    expect(
      e.languageContext.conversationLanguage,
      ConversationLanguage.english,
    );
  });

  test('"Não entendi." -> the last answer again, in Portuguese', () async {
    final e = await engine();
    final first = await say(e, 'Como você está?');
    final r = await say(e, 'Não entendi.');
    expect(r.intent, CompanionIntent.requestPortuguese);
    expect(r.voice, VoiceMode.portuguese);
    expect(r.englishText, first.portugueseText);
    expect(
      e.languageContext.requestedExplanationLanguage,
      ExplanationLanguage.portuguese,
    );
    // Then back to normal: English again.
    final next = await say(e, 'Do you like apples?');
    expect(next.voice, VoiceMode.english);
    expect(next.englishText.toLowerCase(), contains('apple'));
  });

  for (final ask in [
    'Fala português.',
    'Pode falar na minha língua?',
    'Você pode falar em português?',
    'Me explica em português.',
  ]) {
    test('"$ask" -> Portuguese voice', () async {
      final e = await engine();
      await say(e, 'Você está com fome?');
      final r = await say(e, ask);
      expect(r.intent, CompanionIntent.requestPortuguese);
      expect(r.voice, VoiceMode.portuguese);
      expect(r.lines.first.text, 'Claro! Eu posso falar português.');
      expect(r.lines.length, greaterThan(1));
    });
  }

  for (final ask in ['O que significa?', 'Pode traduzir?', 'Traduz isso.']) {
    test('"$ask" -> English + its meaning', () async {
      final e = await engine();
      final first = await say(e, 'Do you like apples?');
      final r = await say(e, ask);
      expect(r.intent, CompanionIntent.requestTranslation);
      expect(r.voice, VoiceMode.bilingual);
      expect(r.englishText, first.englishText);
      expect(r.portugueseText, first.portugueseText);
    });
  }

  test('"O que significa hungry?" -> the word and its meaning', () async {
    final e = await engine();
    final r = await say(e, 'O que significa hungry?');
    expect(r.intent, isNot(CompanionIntent.requestTranslation));
    expect(r.englishText.toLowerCase(), contains('hungry'));
    expect('${r.portugueseText}'.toLowerCase(), contains('fome'));
    expect(r.voice, VoiceMode.bilingual);
  });

  test('"Do you like apples?" -> English, English voice', () async {
    final e = await engine();
    final r = await say(e, 'Do you like apples?');
    expect(r.intent, CompanionIntent.askLike);
    expect(r.voice, VoiceMode.english);
  });

  test('"Você gosta de maçã?" -> English answer (asking in Portuguese '
      'is not asking for Portuguese)', () async {
    final e = await engine();
    final r = await say(e, 'Você gosta de maçã?');
    expect(r.intent, CompanionIntent.askLike);
    expect(r.voice, VoiceMode.english);
    expect(r.englishText.toLowerCase(), contains('apple'));
  });

  test('unknown phrase -> honest, explained in both languages', () async {
    final e = await engine();
    final r = await say(e, 'quantum flibber zork');
    expect(r.intent, CompanionIntent.unknown);
    expect(r.voice, VoiceMode.bilingual);
  });

  test('"Eu quero brincar com a bola" finds PLAY and BALL', () async {
    final e = await engine();
    final r = await say(e, 'Eu quero brincar com a bola');
    expect(r.detectedWords, containsAll(['play', 'ball']));
  });

  test(
    '"Estou com fome e quero comer uma maçã" finds HUNGRY, EAT, APPLE',
    () async {
      final e = await engine();
      final r = await say(e, 'Estou com fome e quero comer uma maçã');
      expect(r.detectedWords, containsAll(['hungry', 'eat', 'apple']));
    },
  );
}
