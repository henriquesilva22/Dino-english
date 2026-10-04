import 'dart:math';

import 'package:dino_english/core/brain/memory/dino_memory.dart';
import 'package:dino_english/core/brain/model/dino_enums.dart';
import 'package:dino_english/core/companion/companion_engine.dart';
import 'package:dino_english/core/companion/companion_response.dart';
import 'package:dino_english/core/companion/companion_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../brain/brain_test_helpers.dart';

class _Rewards implements CompanionRewards {
  int total = 0;

  @override
  Future<CompanionRewardResult> grant({
    required int xp,
    String? wordId,
    required String reason,
    bool countsAsExercise = true,
  }) async {
    total += xp;
    return CompanionRewardResult(xpAwarded: xp, level: 1);
  }
}

void main() {
  final now = DateTime(2026, 10, 3, 10);
  late _Rewards rewards;

  Future<CompanionEngine> engine({
    double hunger = 60,
    double energy = 80,
    double happiness = 50,
  }) async {
    rewards = _Rewards();
    final memory = DinoMemoryBank(InMemoryDinoMemoryStore());
    await memory.load();
    final e = CompanionEngine(
      vocabulary: seedVocabulary,
      memory: memory,
      store: InMemoryCompanionStateStore(
        CompanionState(
          hunger: hunger,
          thirst: 60,
          energy: energy,
          happiness: happiness,
          updatedAt: now,
        ),
      ),
      rewards: rewards,
      random: Random(1),
      clock: () => now,
    );
    await e.load();
    return e;
  }

  test('offering food: the Dino looks and asks, nothing changes yet', () async {
    final e = await engine(hunger: 40);
    final r = await e.offer(DinoCare.feed);
    expect(r.animation, CompanionAnimation.listening);
    expect(r.portugueseText, isNotNull);
    expect(r.state.hunger, 40);
    expect(r.xpReward, 0);
  });

  test(
    'ball: 1st kick is real play, then cheers, 3rd kick is a GOAL',
    () async {
      final e = await engine();
      final first = await e.kick();
      expect(first.care, DinoCare.play);
      expect(first.state.happiness, 65);
      expect(['ball', 'play', 'run'], contains(first.vocabulary.single));

      final second = await e.kick();
      expect(second.care, isNull);
      expect(second.state.happiness, 65);

      final goal = await e.kick();
      expect(goal.xpReward, CompanionEngine.goalXp);
      expect(goal.animation, CompanionAnimation.celebrating);
      expect(goal.englishText.toUpperCase(), contains('GOAL'));
    },
  );

  test('goal XP is limited per session', () async {
    final e = await engine();
    var goalXp = 0;
    for (var i = 0; i < CompanionEngine.kicksPerGoal * 5; i++) {
      final r = await e.kick();
      if (r.animation == CompanionAnimation.celebrating) goalXp += r.xpReward;
    }
    expect(goalXp, CompanionEngine.goalXp * CompanionEngine.maxGoalRewards);
  });

  test('low needs change behavior: the Dino says it', () async {
    final hungry = await (await engine(hunger: 10)).needNudge();
    expect(hungry!.englishText.toLowerCase(), contains('hungry'));
    final sleepy = await (await engine(energy: 10)).needNudge();
    expect(
      sleepy!.englishText.toLowerCase(),
      anyOf(contains('sleepy'), contains('nap'), contains('tired')),
    );
    expect(await (await engine(happiness: 90)).needNudge(), isNull);
  });

  test('each activity teaches its own words (from the word bank)', () async {
    const taught = {
      DinoCare.water: ['water', 'drink', 'thirsty'],
      DinoCare.sleep: ['sleep', 'bed', 'tired', 'good night'],
      DinoCare.play: ['ball', 'play', 'run'],
    };
    for (final entry in taught.entries) {
      final e = await engine(energy: 50, happiness: 50);
      final r = await e.care(entry.key);
      expect(
        entry.value,
        contains(r.vocabulary.single),
        reason: '${entry.key}',
      );
      expect(seedVocabulary.byEnglish(r.vocabulary.single), isNotNull);
    }
  });

  test('the Dino remembers the last activity, word and interaction', () async {
    final memory = DinoMemoryBank(InMemoryDinoMemoryStore());
    await memory.load();
    final e = CompanionEngine(
      vocabulary: seedVocabulary,
      memory: memory,
      store: InMemoryCompanionStateStore(),
      rewards: _Rewards(),
      random: Random(2),
      clock: () => now,
    );
    await e.load();
    await e.care(DinoCare.water);
    expect(memory.fact(MemoryKeys.lastActivity), 'water');
    final word = (e.brain.context.pending as dynamic).word.english as String;
    await e.process(word);
    expect(memory.fact(MemoryKeys.lastWordLearned), word);
    expect(memory.fact(MemoryKeys.lastInteraction), now.toIso8601String());
  });
}
