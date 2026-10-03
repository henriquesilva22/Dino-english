import 'dart:math';

import 'package:dino_english/core/brain/context/conversation_context.dart';
import 'package:dino_english/core/brain/intent/intent.dart';
import 'package:dino_english/core/brain/memory/dino_memory.dart';
import 'package:dino_english/core/brain/model/dino_enums.dart';
import 'package:dino_english/core/companion/companion_engine.dart';
import 'package:dino_english/core/companion/companion_needs_service.dart';
import 'package:dino_english/core/companion/companion_response.dart';
import 'package:dino_english/core/companion/companion_state.dart';
import 'package:dino_english/core/companion/voice/speech_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../brain/brain_test_helpers.dart';

class _Grant {
  const _Grant(this.xp, this.wordId, this.reason, this.countsAsExercise);

  final int xp;
  final String? wordId;
  final String reason;
  final bool countsAsExercise;
}

class _FakeRewards implements CompanionRewards {
  final List<_Grant> grants = [];

  int get total => grants.fold(0, (sum, g) => sum + g.xp);

  @override
  Future<CompanionRewardResult> grant({
    required int xp,
    String? wordId,
    required String reason,
    bool countsAsExercise = true,
  }) async {
    grants.add(_Grant(xp, wordId, reason, countsAsExercise));
    return CompanionRewardResult(xpAwarded: xp, level: 1);
  }
}

void main() {
  var now = DateTime(2026, 10, 3, 10);
  late InMemoryCompanionStateStore store;
  late _FakeRewards rewards;

  setUp(() {
    now = DateTime(2026, 10, 3, 10);
    store = InMemoryCompanionStateStore();
    rewards = _FakeRewards();
  });

  CompanionState stateWith({
    double hunger = 60,
    double thirst = 60,
    double energy = 80,
    double happiness = 80,
    bool isSleeping = false,
  }) => CompanionState(
    hunger: hunger,
    thirst: thirst,
    energy: energy,
    happiness: happiness,
    isSleeping: isSleeping,
    updatedAt: now,
  );

  Future<CompanionEngine> newEngine({
    CompanionState? saved,
    int seed = 1,
    int level = 1,
    DinoMemoryBank? memory,
  }) async {
    store.saved = saved;
    final bank = memory ?? DinoMemoryBank(InMemoryDinoMemoryStore());
    await bank.load();
    final engine = CompanionEngine(
      vocabulary: seedVocabulary,
      memory: bank,
      store: store,
      rewards: rewards,
      level: level,
      random: Random(seed),
      clock: () => now,
    );
    await engine.load();
    return engine;
  }

  group('conversation', () {
    test('"Oi" is a greeting answered in English with a translation', () async {
      final engine = await newEngine();
      final r = await engine.process('Oi');
      expect(r.intent, DinoIntent.greeting);
      expect(r.text, isNotEmpty);
      expect(r.translation, isNotNull);
    });

    test('"Qual seu nome?" -> My name is Dino!', () async {
      final engine = await newEngine();
      final r = await engine.process('Qual seu nome?');
      expect(r.intent, DinoIntent.askDinoName);
      expect(r.lines.first.text, 'My name is Dino!');
      expect(r.lines.first.translation, 'Meu nome é Dino!');
    });

    test('beginners only hear short greetings; replies vary', () async {
      final seen = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        final engine = await newEngine(seed: seed);
        final r = await engine.process('hello');
        seen.add(r.lines.first.text);
      }
      expect(seen, {"Hi! I'm Dino!", 'Hello!', 'Hi! Nice to see you!'});
    });

    test('older learners also hear longer sentences', () async {
      final seen = <String>{};
      for (var seed = 0; seed < 40; seed++) {
        final engine = await newEngine(seed: seed, level: 30);
        seen.add((await engine.process('hello')).lines.first.text);
      }
      expect(seen.length, greaterThan(3));
    });

    test('"Eu gosto de você" and "Você é fofo" get kind answers', () async {
      final engine = await newEngine();
      final like = await engine.process('Eu gosto de você');
      expect(like.intent, DinoIntent.affection);
      expect(like.translation, isNotNull);
      final cute = await engine.process('Você é fofo');
      expect(cute.intent, DinoIntent.praise);
      expect(cute.text, contains('Thank you'));
      expect(cute.state.happiness, greaterThan(80));
    });

    test('unknown sentences never get a flat "não entendi"', () async {
      for (var seed = 0; seed < 10; seed++) {
        final engine = await newEngine(seed: seed);
        final r = await engine.process('xpto blorg zuzu');
        expect(r.intent, DinoIntent.unknown);
        expect(r.translation, isNot(contains('Não entendi')));
        expect(r.text, isNot(contains('Wrong')));
        expect(r.translation, isNotNull);
      }
    });

    test('the Dino remembers the child\'s favorite food', () async {
      final engine = await newEngine();
      await engine.process('My favorite food is pizza');
      final r = await engine.process('What is my favorite food?');
      expect(r.intent, DinoIntent.askMemory);
      expect(r.text, 'Your favorite food is pizza!');
    });

    test('it asks when it does not know yet, then remembers', () async {
      final engine = await newEngine();
      final ask = await engine.process('qual é a minha cor favorita?');
      expect(ask.isWaitingForAnswer, isTrue);
      await engine.process('blue');
      final again = await engine.process('What is my favorite color?');
      expect(again.text, 'Your favorite color is blue!');
    });
  });

  group('state-aware answers', () {
    test('"Você está com fome?" depends on the real hunger', () async {
      final hungry = await newEngine(saved: stateWith(hunger: 20));
      expect(
        (await hungry.process('Você está com fome?')).text,
        contains('hungry'),
      );

      final aLittle = await newEngine(saved: stateWith(hunger: 60));
      expect((await aLittle.process('Tá com fome?')).text, 'A little hungry!');

      final full = await newEngine(saved: stateWith(hunger: 95));
      expect(
        (await full.process('Está com fome?')).text,
        contains('not hungry'),
      );
    });

    test('"Você está bem?" while hungry -> hungry; fed -> happy now', () async {
      final engine = await newEngine(saved: stateWith(hunger: 20));
      final before = await engine.process('Você está bem?');
      expect(before.text.toLowerCase(), contains('hungry'));
      expect(before.emotion, CompanionEmotion.hungry);

      final fed = await engine.care(DinoCare.feed);
      expect(fed.text, contains("I'm happy now!"));
      expect(fed.animation, CompanionAnimation.eating);
    });
  });

  group('care', () {
    test('feeding: hunger +20, happiness +5, +5 XP, persisted', () async {
      final engine = await newEngine(saved: stateWith(hunger: 40));
      final r = await engine.care(DinoCare.feed);
      expect(r.care, DinoCare.feed);
      expect(r.state.hunger, 60);
      expect(r.state.happiness, 85);
      expect(r.xpReward, 5);
      expect(store.saved!.hunger, 60);
      expect(rewards.grants.single.countsAsExercise, isFalse);
      expect(rewards.grants.single.reason, 'companion_feed');
    });

    test('water: thirst +25', () async {
      final engine = await newEngine(saved: stateWith(thirst: 30));
      final r = await engine.care(DinoCare.water);
      expect(r.state.thirst, 55);
      expect(r.vocabulary, ['water']);
      expect(r.lines.first.text, startsWith('Water!'));
    });

    test('play: happiness +15, energy -10, +10 XP', () async {
      final engine = await newEngine(saved: stateWith(happiness: 50));
      final r = await engine.care(DinoCare.play);
      expect(r.state.happiness, 65);
      expect(r.state.energy, 70);
      expect(r.xpReward, 10);
    });

    test('sleep: energy +30; asleep it only snores until woken', () async {
      final engine = await newEngine(saved: stateWith(energy: 30));
      final r = await engine.care(DinoCare.sleep);
      expect(r.state.energy, 60);
      expect(r.state.isSleeping, isTrue);
      expect(store.saved!.isSleeping, isTrue);

      final talk = await engine.process('hello');
      expect(talk.text, contains('Z z z'));
      final food = await engine.care(DinoCare.feed);
      expect(food.care, isNull);
      expect(food.state.hunger, 60);

      final awake = await engine.wakeUp();
      expect(awake.state.isSleeping, isFalse);
    });

    test('feeding a full Dino changes nothing and gives no XP', () async {
      final engine = await newEngine(saved: stateWith(hunger: 98));
      final r = await engine.care(DinoCare.feed);
      expect(r.care, isNull);
      expect(r.xpReward, 0);
      expect(r.text, contains('full'));
      expect(rewards.grants, isEmpty);
    });

    test('too tired to play', () async {
      final engine = await newEngine(saved: stateWith(energy: 10));
      final r = await engine.care(DinoCare.play);
      expect(r.care, isNull);
      expect(r.text, contains('tired'));
    });

    test('care XP is capped per day', () async {
      final engine = await newEngine(
        saved: stateWith(hunger: 10, thirst: 10, happiness: 10, energy: 100),
      );
      for (var i = 0; i < 6; i++) {
        await engine.care(DinoCare.play);
        await engine.care(DinoCare.feed);
        await engine.care(DinoCare.water);
      }
      expect(rewards.total, CompanionNeedsService.dailyCareXpCap);
    });

    test(
      'text care ("eat an apple", "vamos brincar") moves the state',
      () async {
        final engine = await newEngine(
          saved: stateWith(hunger: 40, happiness: 50),
        );
        final eat = await engine.process('eat an apple');
        expect(eat.care, DinoCare.feed);
        expect(eat.state.hunger, 60);

        final play = await engine.process('Vamos brincar?');
        expect(play.intent, DinoIntent.play);
        expect(play.care, DinoCare.play);
        expect(play.state.happiness, greaterThan(50));
        expect(play.text, isNotEmpty);
      },
    );

    test('"go to sleep" / "wake up" by text', () async {
      final engine = await newEngine(saved: stateWith(energy: 30));
      final sleep = await engine.process('go to sleep');
      expect(sleep.state.isSleeping, isTrue);
      expect(sleep.state.energy, 60);
      final wake = await engine.process('wake up');
      expect(wake.state.isSleeping, isFalse);
    });
  });

  group('learning words', () {
    test(
      '"Eu quero comer uma maçã" teaches apple, repeating gives XP',
      () async {
        final engine = await newEngine();
        final teach = await engine.process('Eu quero comer uma maçã');
        expect(teach.lines.first.text, 'Apple! 🍎');
        expect(teach.lines.first.translation, 'Maçã!');
        expect(teach.vocabulary, ['apple']);
        expect(teach.isWaitingForAnswer, isTrue);
        expect(teach.suggestions, ['apple']);
        expect(engine.brain.context.pending, isA<RepeatWordQuestion>());
        // First time this word comes up: +5, not counted as an exercise.
        expect(teach.xpReward, 5);
        expect(rewards.grants.last.countsAsExercise, isFalse);

        final repeat = await engine.process('apple');
        expect(repeat.xpReward, 10);
        expect(repeat.animation, CompanionAnimation.celebrating);
        expect(
          rewards.grants.last.wordId,
          seedVocabulary.byEnglish('apple')!.id,
        );
        expect(rewards.grants.last.countsAsExercise, isTrue);

        // Same word again this session: still taught, no more XP.
        await engine.process('quero outra maçã');
        final again = await engine.process('apple');
        expect(again.xpReward, 0);
      },
    );

    test('"Me dá água" teaches water', () async {
      final engine = await newEngine();
      final r = await engine.process('Me dá água');
      expect(r.lines.first.text, startsWith('Water!'));
      expect(r.lines.first.translation, 'Água!');
      expect(r.suggestions, ['water']);
    });

    test('a wrong repetition is encouraged, never "wrong"', () async {
      final engine = await newEngine();
      await engine.process('Me dá água');
      final r = await engine.process('banana');
      expect(r.text, anyOf(contains('Almost!'), contains('Good try!')));
      expect(r.text.toLowerCase(), isNot(contains('wrong')));
      expect(r.xpReward, 0);
    });

    test('feeding with the button teaches a food word to repeat', () async {
      final engine = await newEngine(saved: stateWith(hunger: 40));
      final r = await engine.care(DinoCare.feed);
      expect(r.vocabulary, hasLength(1));
      final word = r.vocabulary.single;
      expect(r.suggestions, [word]);
      final repeat = await engine.process(word);
      expect(repeat.xpReward, 10);
    });
  });

  group('time', () {
    test('needs decay while the app is closed', () async {
      final engine = await newEngine(
        saved: stateWith(hunger: 80, thirst: 80, energy: 80, happiness: 80),
      );
      now = now.add(const Duration(hours: 4));
      final state = await engine.tick();
      expect(state.hunger, 80 - 4 * CompanionNeedsService.hungerPerHour);
      expect(state.thirst, 80 - 4 * CompanionNeedsService.thirstPerHour);
      expect(store.saved!.hunger, state.hunger);
    });

    test('a long absence is capped and never drops below the floor', () async {
      store.saved = stateWith(hunger: 90);
      now = now.add(const Duration(days: 10));
      final engine = await newEngine(saved: store.saved);
      expect(engine.state.hunger, CompanionNeedsService.decayFloor);
    });
  });

  test('the voice expects English while a word should be repeated', () async {
    final engine = await newEngine();
    expect(engine.expectedLanguage, SpeechLanguageHint.auto);
    await engine.process('Me dá água');
    expect(engine.expectedLanguage, SpeechLanguageHint.english);
    expect(engine.didNotHear().suggestions, ['water']);
    await engine.process('water');
    expect(engine.expectedLanguage, SpeechLanguageHint.auto);
  });
}
