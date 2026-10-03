import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/models/dino_evolution_stage.dart';
import 'package:dino_english/core/models/session_kind.dart';
import 'package:dino_english/core/repositories/progress_repository.dart';
import 'package:dino_english/core/services/level_curve.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _insertWord(AppDatabase database, String id) {
  return database
      .into(database.words)
      .insert(
        WordsCompanion.insert(
          id: id,
          englishTerm: id,
          portugueseTranslation: '$id-pt',
          category: 'animals',
          difficulty: 1,
          recommendedLevel: 1,
          exampleSentenceEn: 'Example $id.',
          exampleSentencePt: 'Exemplo $id.',
        ),
      );
}

/// Mirrors what `AppBootstrapper.ensureSingletonRows()` does in the real
/// app -- `recordAnswer` assumes the singleton rows already exist.
Future<void> _seedProfile(AppDatabase database, {int totalXp = 0}) async {
  await database
      .into(database.userProfile)
      .insertOnConflictUpdate(
        UserProfileCompanion.insert(
          id: const Value(1),
          totalXp: Value(totalXp),
          createdAt: DateTime(2026),
        ),
      );
  await database
      .into(database.dinoEvolutionState)
      .insertOnConflictUpdate(
        DinoEvolutionStateCompanion.insert(id: const Value(1)),
      );
}

void main() {
  late AppDatabase database;
  late ProgressRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ProgressRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('first correct answer on a new word promotes mastery 0 -> 1', () async {
    await _insertWord(database, 'word.a');
    await _seedProfile(database);

    final result = await repository.recordAnswer(
      wordId: 'word.a',
      wasCorrect: true,
      exerciseType: 'multiple_choice',
      sessionKind: SessionKind.study,
      sessionId: 's1',
      now: DateTime(2026, 1, 1, 10),
    );

    expect(result.newMasteryLevel, 1);
    final progress = await (database.select(
      database.wordProgress,
    )..where((t) => t.wordId.equals('word.a'))).getSingle();
    expect(progress.masteryLevel, 1);
    expect(progress.correctCount, 1);
  });

  test(
    'correct answer grants the default XP and updates the profile',
    () async {
      await _insertWord(database, 'word.a');
      await _seedProfile(database);

      final result = await repository.recordAnswer(
        wordId: 'word.a',
        wasCorrect: true,
        exerciseType: 'multiple_choice',
        sessionKind: SessionKind.study,
        sessionId: 's1',
        now: DateTime(2026, 1, 1, 10),
      );

      expect(result.xpAwarded, kDefaultCorrectAnswerXp);
      final profile = await repository.fetchUserProfile();
      expect(profile.totalXp, kDefaultCorrectAnswerXp);
      expect(
        profile.currentLevel,
        LevelCurve().levelForTotalXp(profile.totalXp),
      );
    },
  );

  test('wrong answer grants zero XP but still demotes word_progress', () async {
    await _insertWord(database, 'word.a');
    await _seedProfile(database);

    await repository.recordAnswer(
      wordId: 'word.a',
      wasCorrect: true,
      exerciseType: 'multiple_choice',
      sessionKind: SessionKind.study,
      sessionId: 's1',
      now: DateTime(2026, 1, 1, 10),
    );
    final afterCorrect = await repository.fetchUserProfile();

    final wrongResult = await repository.recordAnswer(
      wordId: 'word.a',
      wasCorrect: false,
      exerciseType: 'multiple_choice',
      sessionKind: SessionKind.study,
      sessionId: 's1',
      now: DateTime(2026, 1, 1, 11),
    );

    expect(wrongResult.xpAwarded, 0);
    expect(wrongResult.newMasteryLevel, 0);
    final afterWrong = await repository.fetchUserProfile();
    expect(afterWrong.totalXp, afterCorrect.totalXp);
  });

  test(
    'a null wordId (fake minigame word) never creates a word_progress row',
    () async {
      await _seedProfile(database);

      final result = await repository.recordAnswer(
        wordId: null,
        wasCorrect: false,
        exerciseType: 'minigame_collect',
        sessionKind: SessionKind.review,
        sessionId: 's1',
        xpOverride: 0,
        now: DateTime(2026, 1, 1, 10),
      );

      expect(result.newMasteryLevel, 0);
      final progressRows = await database.select(database.wordProgress).get();
      expect(progressRows, isEmpty);

      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts.single.wordId, isNull);
      expect(attempts.single.masteryLevelBefore, 0);
      expect(attempts.single.masteryLevelAfter, 0);
    },
  );

  test(
    'daily_activity_log only counts as an active day at the streak threshold',
    () async {
      await _insertWord(database, 'word.a');
      await _seedProfile(database);
      final day = DateTime(2026, 1, 1, 9);

      for (var i = 0; i < 4; i++) {
        await repository.recordAnswer(
          wordId: 'word.a',
          wasCorrect: true,
          exerciseType: 'multiple_choice',
          sessionKind: SessionKind.study,
          sessionId: 's1',
          now: day,
        );
      }
      var log = await database.select(database.dailyActivityLog).getSingle();
      expect(log.exercisesCompleted, 4);
      expect(log.countsAsActiveDay, isFalse);

      await repository.recordAnswer(
        wordId: 'word.a',
        wasCorrect: true,
        exerciseType: 'multiple_choice',
        sessionKind: SessionKind.study,
        sessionId: 's1',
        now: day,
      );
      log = await database.select(database.dailyActivityLog).getSingle();
      expect(log.exercisesCompleted, 5);
      expect(log.countsAsActiveDay, isTrue);
    },
  );

  test(
    'currentStreakDays counts consecutive active days and longestStreakDays keeps the peak',
    () async {
      await _insertWord(database, 'word.a');
      await _seedProfile(database);
      final day0 = DateTime(2026, 1, 1, 9);
      final day1 = DateTime(2026, 1, 2, 9);
      final day3 = DateTime(2026, 1, 4, 9); // day2 skipped: gap day

      Future<void> answerNTimes(DateTime day, int times) async {
        for (var i = 0; i < times; i++) {
          await repository.recordAnswer(
            wordId: 'word.a',
            wasCorrect: true,
            exerciseType: 'multiple_choice',
            sessionKind: SessionKind.study,
            sessionId: 's1',
            now: day,
          );
        }
      }

      await answerNTimes(day0, 5);
      var profile = await repository.fetchUserProfile();
      expect(profile.currentStreakDays, 1);

      await answerNTimes(day1, 5);
      profile = await repository.fetchUserProfile();
      expect(profile.currentStreakDays, 2);
      expect(profile.longestStreakDays, 2);

      await answerNTimes(day3, 5);
      profile = await repository.fetchUserProfile();
      expect(profile.currentStreakDays, 1); // day2 gap broke the streak
      expect(profile.longestStreakDays, 2); // peak of 2 is preserved
    },
  );

  test(
    'egg hatching: starts only once the user crosses level 10, then progresses '
    'eggHatchingIntact -> eggSmallCrack -> eggLargeCrack -> hatchedBabyPlaceholder '
    'as active days accrue, and hatchedAt is set exactly once',
    () async {
      await _insertWord(database, 'word.a');
      final level10Threshold = LevelCurve().xpForLevel(10);
      await _seedProfile(database, totalXp: level10Threshold - 1);

      final day0 = DateTime(2026, 1, 1, 9);
      final day1 = DateTime(2026, 1, 2, 9);
      final day2 = DateTime(2026, 1, 3, 9);
      final day3 = DateTime(2026, 1, 4, 9);
      final day4 = DateTime(2026, 1, 5, 9);

      Future<AnswerResult> answer(DateTime day) => repository.recordAnswer(
        wordId: 'word.a',
        wasCorrect: true,
        exerciseType: 'multiple_choice',
        sessionKind: SessionKind.study,
        sessionId: 's1',
        now: day,
      );

      // First answer of day0 crosses level 10 (1 XP short + 10 XP grant),
      // but day0 isn't an active day yet (only 1 exercise so far): dormant
      // egg has just unlocked but no active day has been counted.
      final crossing = await answer(day0);
      expect(crossing.newLevel, greaterThanOrEqualTo(10));
      var dinoState = await (database.select(
        database.dinoEvolutionState,
      )..where((t) => t.id.equals(1))).getSingle();
      expect(dinoState.hatchingStartedAt, day0);
      expect(
        dinoEvolutionStageFromStorageKey(dinoState.stage),
        DinoEvolutionStage.eggHatchingIntact,
      );

      // Finish day0 as an active day (5 exercises total).
      for (var i = 0; i < 4; i++) {
        await answer(day0);
      }
      dinoState = await (database.select(
        database.dinoEvolutionState,
      )..where((t) => t.id.equals(1))).getSingle();
      expect(
        dinoEvolutionStageFromStorageKey(dinoState.stage),
        DinoEvolutionStage.eggSmallCrack,
      );

      // hatchingStartedAt never moves on subsequent answers.
      for (var i = 0; i < 5; i++) {
        await answer(day1);
      }
      dinoState = await (database.select(
        database.dinoEvolutionState,
      )..where((t) => t.id.equals(1))).getSingle();
      expect(dinoState.hatchingStartedAt, day0);
      expect(
        dinoEvolutionStageFromStorageKey(dinoState.stage),
        DinoEvolutionStage.eggSmallCrack,
      );

      for (var i = 0; i < 5; i++) {
        await answer(day2);
      }
      dinoState = await (database.select(
        database.dinoEvolutionState,
      )..where((t) => t.id.equals(1))).getSingle();
      expect(
        dinoEvolutionStageFromStorageKey(dinoState.stage),
        DinoEvolutionStage.eggLargeCrack,
      );

      AnswerResult? lastResult;
      for (var i = 0; i < 5; i++) {
        lastResult = await answer(day3);
      }
      dinoState = await (database.select(
        database.dinoEvolutionState,
      )..where((t) => t.id.equals(1))).getSingle();
      expect(
        dinoEvolutionStageFromStorageKey(dinoState.stage),
        DinoEvolutionStage.hatchedBabyPlaceholder,
      );
      expect(dinoState.hatchedAt, isNotNull);
      expect(lastResult!.hatchedJustNow, isTrue);
      final hatchedAtAfterDay3 = dinoState.hatchedAt;

      // hatchedAt never changes again once set.
      final resultDay4 = await answer(day4);
      expect(resultDay4.hatchedJustNow, isFalse);
      dinoState = await (database.select(
        database.dinoEvolutionState,
      )..where((t) => t.id.equals(1))).getSingle();
      expect(dinoState.hatchedAt, hatchedAtAfterDay3);
    },
  );

  test('exercise_attempts records the right sessionKind/exerciseType/xpAwarded '
      'for both study and minigame answers', () async {
    await _insertWord(database, 'word.a');
    await _seedProfile(database);

    await repository.recordAnswer(
      wordId: 'word.a',
      wasCorrect: true,
      exerciseType: 'multiple_choice',
      sessionKind: SessionKind.study,
      sessionId: 'study-session',
      now: DateTime(2026, 1, 1, 9),
    );
    await repository.recordAnswer(
      wordId: null,
      wasCorrect: true,
      exerciseType: 'minigame_collect',
      sessionKind: SessionKind.review,
      sessionId: 'minigame-session',
      xpOverride: 5,
      now: DateTime(2026, 1, 1, 10),
    );

    final attempts = await (database.select(
      database.exerciseAttempts,
    )..orderBy([(t) => OrderingTerm.asc(t.attemptedAt)])).get();

    expect(attempts, hasLength(2));
    expect(attempts[0].exerciseType, 'multiple_choice');
    expect(attempts[0].sessionKind, 'study');
    expect(attempts[0].xpAwarded, kDefaultCorrectAnswerXp);
    expect(attempts[1].exerciseType, 'minigame_collect');
    expect(attempts[1].sessionKind, 'review');
    expect(attempts[1].xpAwarded, 5);
  });
}
