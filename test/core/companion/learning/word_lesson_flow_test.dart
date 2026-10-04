import 'dart:math';

import 'package:dino_english/core/brain/memory/dino_memory.dart';
import 'package:dino_english/core/companion/companion_engine.dart';
import 'package:dino_english/core/companion/companion_response.dart';
import 'package:dino_english/core/companion/engine/companion_intent.dart';
import 'package:dino_english/core/companion/learning/word_mastery.dart';
import 'package:dino_english/core/companion/voice/speech_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../brain/brain_test_helpers.dart';
import 'learning_test_helpers.dart';

class _Rewards implements CompanionRewards {
  final List<(int, String)> grants = [];

  @override
  Future<CompanionRewardResult> grant({
    required int xp,
    String? wordId,
    required String reason,
    bool countsAsExercise = true,
  }) async {
    grants.add((xp, reason));
    return CompanionRewardResult(xpAwarded: xp, level: 1);
  }
}

void main() {
  final now = DateTime(2026, 10, 4, 10);
  late _Rewards rewards;
  late DinoMemoryBank memory;

  setUp(() {
    rewards = _Rewards();
  });

  Future<CompanionEngine> newEngine({int seed = 1, int level = 1}) async {
    memory = DinoMemoryBank(InMemoryDinoMemoryStore(), clock: () => now);
    await memory.load();
    final engine = CompanionEngine(
      vocabulary: seedVocabulary,
      memory: memory,
      store: InMemoryCompanionStateStore(),
      rewards: rewards,
      level: level,
      learningWords: learningBank,
      random: Random(seed),
      clock: () => now,
    );
    await engine.load();
    return engine;
  }

  List<String> texts(CompanionResponse r) => [for (final l in r.lines) l.text];

  test('🦖 Eu vou WALK amanhã -> O que é walk? -> WALK significa caminhar '
      '-> Agora fala comigo -> Walk. -> Great job! +5 XP', () async {
    final engine = await newEngine();
    final context = engine.brain.context;

    final meaning = await engine.process('O que é walk?');
    expect(meaning.intent, CompanionIntent.repeatWord);
    final said = texts(meaning).join(' ');
    expect(said, contains('WALK'));
    expect(said, contains('caminhar'));
    expect(said, isNot(contains('Example'))); // beginners: short
    // Portuguese voice with WALK in English.
    final explain = meaning.lines.first;
    expect(explain.isMixed, isTrue);
    expect(explain.segments.where((s) => s.isEnglish).map((s) => s.text), [
      'WALK',
    ]);
    expect(meaning.isWaitingForAnswer, isTrue);
    expect(context.awaitingRepetition, isTrue);
    expect(context.lastTargetWord, 'walk');
    // The microphone listens for English meanwhile.
    expect(engine.expectedLanguage, SpeechLanguageHint.english);

    final success = await engine.process('Walk.');
    expect(success.intent, CompanionIntent.repeatWord);
    expect(success.animation, CompanionAnimation.celebrating);
    expect(texts(success).join(' '), contains('+5 XP'));
    expect(success.xpReward, 5);
    expect(rewards.grants, [(5, 'companion_word_lesson')]);
    expect(context.awaitingRepetition, isFalse);
    expect(engine.lessons!.mastery.of('walk').level, MasteryLevel.practicing);

    // Back to normal conversation.
    final next = await engine.process('Qual seu nome?');
    expect(next.intent, CompanionIntent.askName);
  });

  test(
    '"o que é isso?" right after a hybrid sentence means its word',
    () async {
      final engine = await newEngine(seed: 4);
      final teach = await engine.process('me ensina uma palavra');
      final hybrid = teach.lines.firstWhere(
        (l) => l.isMixed && l.english!.isNotEmpty && !l.text.contains('?'),
        orElse: () => teach.lines[1],
      );
      final word = engine.brain.context.lastTargetWord!;
      expect(hybrid.text, contains(word.toUpperCase()));

      final r = await engine.process('O que é isso?');
      expect(texts(r).join(' '), contains(word.toUpperCase()));
      expect(
        texts(r).join(' '),
        contains(learningBank.byEnglish(word)!.portuguese),
      );
      expect(engine.brain.context.awaitingRepetition, isTrue);
    },
  );

  test(
    'a near miss: "Quase!", no XP lost; three misses: "Não tem problema"',
    () async {
      final engine = await newEngine();
      await engine.process('O que significa eat?');
      final first = await engine.process('banana');
      expect(texts(first).join(' '), contains('EAT'));
      expect(first.isWaitingForAnswer, isTrue);
      expect(first.xpReward, 0);
      await engine.process('banana');
      final last = await engine.process('banana');
      expect(last.isWaitingForAnswer, isFalse);
      expect(texts(last).join(' '), contains('comer'));
      expect(engine.brain.context.awaitingRepetition, isFalse);
      expect(rewards.grants, isEmpty);
      expect(engine.lessons!.mastery.of('eat').incorrectRepetitions, 3);
    },
  );

  test('a speech-recognizer spelling is accepted ("wok" for walk)', () async {
    final engine = await newEngine();
    await engine.process('O que é walk?');
    final r = await engine.process('wok');
    expect(r.xpReward, 5);
  });

  test('XP for a word once per session', () async {
    final engine = await newEngine();
    await engine.process('O que é jump?');
    expect((await engine.process('jump')).xpReward, 5);
    await engine.process('O que é jump?');
    expect((await engine.process('jump')).xpReward, 0);
  });

  test('an unknown word: the Dino admits it, never invents', () async {
    final engine = await newEngine();
    final r = await engine.process('O que é zorbix?');
    expect(r.isWaitingForAnswer, isFalse);
    final said = texts(r).join(' ').toLowerCase();
    expect(
      said,
      anyOf(
        contains('não conheço'),
        contains('não sei'),
        contains('nova para mim'),
        contains('não aprendi'),
        contains('não sei explicar'),
      ),
    );
    expect(said, isNot(contains('significa')));
  });

  test('a child who moves on mid-repetition is answered normally', () async {
    final engine = await newEngine();
    await engine.process('O que é walk?');
    final r = await engine.process('Dino, você gosta de comer pizza?');
    expect(r.intent, isNot(CompanionIntent.repeatWord));
    expect(engine.brain.context.awaitingRepetition, isFalse);
  });

  test('older children also hear an example', () async {
    final engine = await newEngine(level: 10);
    final r = await engine.process('O que é walk?');
    expect(texts(r), contains('Example: I walk every day.'));
    expect(texts(r), contains('Eu caminho todos os dias.'));
  });

  test('the Dino slips English words into the conversation by itself, '
      'one per sentence, now and then', () async {
    final engine = await newEngine(seed: 7);
    var hybrids = 0;
    for (var i = 0; i < 8; i++) {
      final r = await engine.process(i.isEven ? 'Eu te amo' : 'Você é fofo');
      final mixed = r.lines.where((l) => l.isMixed).toList();
      expect(mixed.length, lessThanOrEqualTo(1));
      if (mixed.isNotEmpty) {
        hybrids++;
        expect(mixed.single.english, hasLength(1));
        expect(
          engine.brain.context.lastTargetWord,
          mixed.single.english!.single.toLowerCase(),
        );
      }
    }
    expect(hybrids, inInclusiveRange(2, 6));
  });

  test('tapping a word: explain it, or straight to practice', () async {
    final engine = await newEngine();
    expect(engine.wordInfo('ball')!.portuguese, 'bola');
    final practice = await engine.practiceWord('ball');
    expect(practice!.isWaitingForAnswer, isTrue);
    expect(practice.suggestions, ['ball']);
    expect((await engine.process('ball')).xpReward, 5);
    expect(await engine.explainWord('zorbix'), isNull);
  });

  test('without a lesson bank the Dino talks exactly as before', () async {
    final memory = DinoMemoryBank(InMemoryDinoMemoryStore());
    await memory.load();
    final engine = CompanionEngine(
      vocabulary: seedVocabulary,
      memory: memory,
      store: InMemoryCompanionStateStore(),
      rewards: rewards,
      random: Random(1),
      clock: () => now,
    );
    await engine.load();
    for (var i = 0; i < 5; i++) {
      final r = await engine.process('Eu te amo');
      expect(r.lines.any((l) => l.isMixed), isFalse);
    }
    expect(engine.lessons, isNull);
  });
}
