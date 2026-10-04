import 'dart:math';

import 'package:dino_english/core/brain/context/conversation_context.dart';
import 'package:dino_english/core/brain/memory/dino_memory.dart';
import 'package:dino_english/core/brain/model/dino_enums.dart';
import 'package:dino_english/core/companion/companion_engine.dart';
import 'package:dino_english/core/companion/companion_state.dart';
import 'package:dino_english/core/companion/engine/companion_entity.dart';
import 'package:dino_english/core/companion/engine/companion_intent.dart';
import 'package:dino_english/core/companion/engine/response_bank.dart';
import 'package:dino_english/core/companion/engine/response_selector.dart';
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

  Future<CompanionEngine> engine({
    int seed = 1,
    int level = 1,
    double hunger = 60,
  }) async {
    final memory = DinoMemoryBank(InMemoryDinoMemoryStore());
    await memory.load();
    final e = CompanionEngine(
      vocabulary: seedVocabulary,
      memory: memory,
      store: InMemoryCompanionStateStore(
        CompanionState(
          hunger: hunger,
          thirst: 60,
          energy: 80,
          happiness: 80,
          updatedAt: now,
        ),
      ),
      rewards: _NoRewards(),
      level: level,
      random: Random(seed),
      clock: () => now,
    );
    await e.load();
    return e;
  }

  group('"Você gosta de maçã?"', () {
    test('ASK_LIKE + APPLE, answered in English then Portuguese', () async {
      final e = await engine();
      final r = await e.process('Você gosta de maçã?');
      expect(r.intent, CompanionIntent.askLike);
      expect(r.detectedEntity?.id, 'APPLE');
      expect(r.detectedWords, contains('apple'));
      expect(r.englishText.toLowerCase(), contains('apple'));
      expect(r.portugueseText!.toLowerCase(), contains('maçã'));
      expect(r.shouldSpeak, isTrue);
      expect(r.shouldListenAgain, isTrue);
    });

    test('at least 5 different answers, never twice in a row', () async {
      final e = await engine(level: 30);
      final answers = <String>[];
      for (var i = 0; i < 12; i++) {
        answers.add((await e.process('Do you like apples?')).englishText);
      }
      expect(answers.toSet().length, greaterThanOrEqualTo(5));
      for (var i = 1; i < answers.length; i++) {
        expect(answers[i], isNot(answers[i - 1]));
      }
    });

    test('the Dino never likes what it doesn\'t like (snakes)', () async {
      final e = await engine();
      final r = await e.process('Você gosta de cobras?');
      expect(r.detectedEntity?.id, 'SNAKE');
      expect(
        r.englishText.toLowerCase(),
        anyOf(contains("don't"), contains('not')),
      );
    });

    test('unknown things are never invented', () async {
      for (var seed = 0; seed < 8; seed++) {
        final e = await engine(seed: seed);
        final r = await e.process('Você gosta de zorblax?');
        expect(r.intent, CompanionIntent.askLike);
        expect(r.detectedEntity, isNull);
        expect(r.englishText, isNot(contains('I love')));
        expect(r.englishText, isNot(contains('I like')));
      }
    });

    test('"Do you like to play?" talks about playing, not "plays"', () async {
      final e = await engine();
      final r = await e.process('Do you like to play?');
      expect(r.englishText, contains('to play'));
      expect(r.englishText, isNot(contains('plays')));
    });
  });

  group('needs answers follow the real state', () {
    test('hungry / a little / full', () async {
      String en(String key) =>
          defaultResponseBank[key]!.map((t) => t.en).join('|');
      final hungry = await (await engine(hunger: 10)).process('Tá com fome?');
      expect(en('hunger.urgent'), contains(hungry.englishText));
      final mild = await (await engine(hunger: 50)).process('Tá com fome?');
      expect(en('hunger.mild'), contains(mild.englishText));
      final full = await (await engine(hunger: 95)).process('Tá com fome?');
      expect(en('hunger.fine'), contains(full.englishText));
    });
  });

  group('small talk', () {
    test('favorite food, then the Dino asks and remembers yours', () async {
      final e = await engine();
      final fav = await e.process('Qual é a sua comida favorita?');
      expect(fav.intent, CompanionIntent.askFavorite);
      expect(fav.englishText.toLowerCase(), contains('apple'));
      expect(fav.isWaitingForAnswer, isTrue);
      await e.process('pizza');
      final mine = await e.process('What is my favorite food?');
      expect(mine.englishText, 'Your favorite food is pizza!');
    });

    test('the Dino\'s age never changes', () async {
      for (var seed = 0; seed < 8; seed++) {
        final r = await (await engine(
          seed: seed,
        )).process('Quantos anos você tem?');
        expect(r.englishText.toLowerCase(), contains('two'));
        expect(r.portugueseText!.toLowerCase(), contains('dois'));
      }
    });

    test('goodbye pauses listening', () async {
      final r = await (await engine()).process('Tchau, Dino!');
      expect(r.intent, CompanionIntent.goodbye);
      expect(r.shouldListenAgain, isFalse);
    });

    test('kind words make the Dino a bit happier, no XP', () async {
      final e = await engine();
      final r = await e.process('Você é muito fofo');
      expect(r.intent, CompanionIntent.praise);
      expect(r.state.happiness, 85);
      expect(r.xpReward, 0);
    });

    test('"Come uma banana" feeds the Dino a banana', () async {
      final e = await engine(hunger: 40);
      final r = await e.process('Come uma banana!');
      expect(r.intent, CompanionIntent.commandEat);
      expect(r.care, DinoCare.feed);
      expect(r.vocabulary, ['banana']);
      expect(r.state.hunger, 60);
    });
  });

  group('answers that look like commands', () {
    test('"Say: play!" -> "play" is graded, not another game', () async {
      final e = await engine();
      e.brain.context.pending = RepeatWordQuestion(
        word: seedVocabulary.byEnglish('play')!,
      );
      final r = await e.process('play');
      expect(r.intent, CompanionIntent.repeatWord);
      expect(r.care, isNull);
      expect(r.xpReward, 10);
    });

    test('a quiz answer "eat" is graded, not a meal', () async {
      final e = await engine(hunger: 40);
      e.brain.context.pending = QuizQuestion(
        word: seedVocabulary.byEnglish('eat')!,
        direction: QuizDirection.portugueseToEnglish,
      );
      final r = await e.process('eat');
      expect(r.intent, CompanionIntent.answer);
      expect(r.care, isNull);
      expect(r.state.hunger, 40);
      expect(r.xpReward, greaterThan(0));
    });

    test('a real question still gets answered mid-quiz', () async {
      final e = await engine();
      e.brain.context.pending = RepeatWordQuestion(
        word: seedVocabulary.byEnglish('apple')!,
      );
      final r = await e.process('Você está com fome?');
      expect(r.intent, CompanionIntent.askHungry);
    });
  });

  group('partial words and unknown sentences', () {
    test('"Eu quero comer uma maçã agora" is about APPLE', () async {
      final r = await (await engine()).process(
        'Eu quero comer uma maçã agora.',
      );
      expect(r.intent, CompanionIntent.food);
      expect(r.detectedEntity?.id, 'APPLE');
      expect(r.englishText, contains('Apple'));
    });

    test('unknown: honest, in both languages, never "Wrong"', () async {
      const honest = {
        "I don't know that yet.",
        "Hmm... I don't understand yet.",
        "Let's try something else!",
        "Hmm... I don't know that yet! Can you teach me?",
        'Try saying it another way!',
        'Can you say it in English?',
      };
      for (var seed = 0; seed < 10; seed++) {
        final r = await (await engine(seed: seed)).process('blorg zuzu xpto');
        expect(r.intent, CompanionIntent.unknown);
        expect(honest, contains(r.englishText));
        expect(r.portugueseText, isNotNull);
      }
    });
  });

  group('level', () {
    Set<String> appleLines(bool Function(EnglishTier) tier) {
      final vars = ResponseSelector.entityVars(
        const CompanionEntityCatalog().byId('APPLE')!,
      );
      return {
        for (final t in defaultResponseBank['like.food']!)
          if (tier(t.tier)) ResponseSelector.fill(t.en, vars),
      };
    }

    test('beginners only get A1 lines; older learners also longer', () async {
      final a1 = appleLines((t) => t == EnglishTier.a1);
      final longer = appleLines((t) => t != EnglishTier.a1);
      expect(longer, isNotEmpty);

      final beginner = <String>{};
      final advanced = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        beginner.add(
          (await (await engine(
            seed: seed,
          )).process('Do you like apples?')).englishText,
        );
        advanced.add(
          (await (await engine(
            seed: seed,
            level: 30,
          )).process('Do you like apples?')).englishText,
        );
      }
      expect(a1, containsAll(beginner));
      expect(advanced.intersection(longer), isNotEmpty);
    });
  });

  group('response bank', () {
    final known = {
      'name',
      'en',
      'En',
      'enG',
      'EnG',
      'pt',
      'Pt',
      'ptG',
      'PtG',
      'be',
      'ser',
      'legal',
      'emoji',
      'topicEn',
      'myFavPt',
      'yourFavPt',
      'favEn',
      'FavEn',
      'favEnG',
      'favPt',
      'FavPt',
      'favPtG',
    };

    test('every line has both languages and known placeholders only', () {
      defaultResponseBank.forEach((key, pool) {
        expect(pool, isNotEmpty, reason: key);
        expect(
          pool.where((t) => t.tier == EnglishTier.a1),
          isNotEmpty,
          reason: '$key needs an A1 line',
        );
        for (final t in pool) {
          expect(t.en.trim(), isNotEmpty, reason: key);
          expect(t.pt.trim(), isNotEmpty, reason: key);
          for (final m in RegExp(r'\{(\w+)\}').allMatches('${t.en} ${t.pt}')) {
            expect(known, contains(m[1]), reason: '$key: ${m[0]}');
          }
        }
      });
    });

    test('main intents have at least 5 answers', () {
      for (final key in [
        'greeting',
        'goodbye',
        'thank',
        'apology',
        'affection',
        'praise',
        'age',
        'feeling.fine',
        'doing.fine',
        'hunger.urgent',
        'hunger.mild',
        'hunger.fine',
        'thirst.urgent',
        'thirst.mild',
        'thirst.fine',
        'energy.urgent',
        'energy.mild',
        'energy.fine',
        'like.food',
        'like.drink',
        'like.thing',
        'like.no',
        'like.unknown',
        'dislike.general',
        'dislike.yes',
        'dislike.no',
        'favorite',
      ]) {
        expect(
          defaultResponseBank[key]!.length,
          greaterThanOrEqualTo(5),
          reason: key,
        );
      }
    });

    test('placeholders agree with the thing ("water is", "apples are")', () {
      const catalog = CompanionEntityCatalog();
      String say(String id) => ResponseSelector.fill(
        '{EnG} {be} yummy! / {PtG} {ser} uma delícia!',
        ResponseSelector.entityVars(catalog.byId(id)!),
      );
      expect(say('APPLE'), 'Apples are yummy! / Maçãs são uma delícia!');
      expect(say('WATER'), 'Water is yummy! / Água é uma delícia!');
      expect(say('LEMON'), 'Lemons are yummy! / Limões são uma delícia!');
    });
  });
}
