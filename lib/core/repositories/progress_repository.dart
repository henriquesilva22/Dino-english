import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/dino_evolution_stage.dart';
import '../models/session_kind.dart';
import '../services/hatching_service.dart';
import '../services/level_curve.dart';
import '../services/srs_service.dart';
import '../services/streak_service.dart';
import '../services/xp_service.dart';
import '../utils/date_key.dart';

/// XP granted for one correct study answer. The only "new" number in this
/// file -- no existing service defines it, since XpService.grantXp takes
/// the amount as a parameter. Tunable in one place.
const int kDefaultCorrectAnswerXp = 10;

class AnswerResult {
  const AnswerResult({
    required this.xpAwarded,
    required this.newMasteryLevel,
    required this.previousLevel,
    required this.newLevel,
    required this.newDinoStage,
    required this.hatchedJustNow,
  });

  final int xpAwarded;
  final int newMasteryLevel;
  final int previousLevel;
  final int newLevel;
  final DinoEvolutionStage newDinoStage;
  final bool hatchedJustNow;

  bool get leveledUp => newLevel > previousLevel;
}

class WordMasteryStats {
  const WordMasteryStats({
    required this.totalActiveWords,
    required this.masteredCount,
    required this.distribution,
  });

  final int totalActiveWords;
  final int masteredCount;

  /// masteryLevel (0..5) -> count of active words at that level.
  final Map<int, int> distribution;
}

class EggProgressInfo {
  const EggProgressInfo({
    required this.stage,
    required this.daysRemaining,
    required this.hatchingStarted,
  });

  final DinoEvolutionStage stage;

  /// Null when not yet eligible to hatch (level < 10) or already hatched.
  final int? daysRemaining;
  final bool hatchingStarted;
}

/// Composes the pure services ([SrsService], [XpService], [StreakService],
/// [HatchingService]) with the Drift database inside a single transaction.
/// This is wiring only -- none of the services' rules are reimplemented
/// here, only sequenced and persisted. Shared by the study screen and the
/// minigame so there is exactly one place that grants XP and updates
/// progress.
class ProgressRepository {
  ProgressRepository(this._database)
    : _srs = const SrsService(),
      _xp = XpService(LevelCurve()),
      _streak = const StreakService(),
      _hatching = const HatchingService();

  final AppDatabase _database;
  final SrsService _srs;
  final XpService _xp;
  final StreakService _streak;
  final HatchingService _hatching;

  Future<AnswerResult> recordAnswer({
    required String? wordId,
    required bool wasCorrect,
    required String exerciseType,
    required SessionKind sessionKind,
    required String sessionId,
    int? xpOverride,
    String? userAnswer,
    int? responseTimeMs,
    DateTime? now,
  }) {
    final attemptedAt = now ?? DateTime.now();
    return _database.transaction(() async {
      var masteryBefore = 0;
      var masteryAfter = 0;

      if (wordId != null) {
        final existing = await (_database.select(
          _database.wordProgress,
        )..where((t) => t.wordId.equals(wordId))).getSingleOrNull();
        masteryBefore = existing?.masteryLevel ?? 0;

        final srsResult = _srs.applyAnswer(
          currentMasteryLevel: masteryBefore,
          currentStreak: existing?.currentStreak ?? 0,
          wasCorrect: wasCorrect,
          attemptedAt: attemptedAt,
        );
        masteryAfter = srsResult.newMasteryLevel;

        await _database
            .into(_database.wordProgress)
            .insertOnConflictUpdate(
              WordProgressCompanion.insert(
                wordId: wordId,
                masteryLevel: Value(srsResult.newMasteryLevel),
                correctCount: Value(
                  (existing?.correctCount ?? 0) + (wasCorrect ? 1 : 0),
                ),
                incorrectCount: Value(
                  (existing?.incorrectCount ?? 0) + (wasCorrect ? 0 : 1),
                ),
                currentStreak: Value(srsResult.newStreak),
                lastSeenAt: Value(attemptedAt),
                nextReviewAt: Value(srsResult.nextReviewAt),
                lastResultCorrect: Value(wasCorrect),
                timesShownTotal: Value((existing?.timesShownTotal ?? 0) + 1),
                introducedAt: Value(existing?.introducedAt ?? attemptedAt),
              ),
            );
      }

      final profile = await (_database.select(
        _database.userProfile,
      )..where((t) => t.id.equals(1))).getSingle();
      final xpToAward = wasCorrect ? (xpOverride ?? kDefaultCorrectAnswerXp) : 0;
      final grant = _xp.grantXp(
        currentTotalXp: profile.totalXp,
        xpToAdd: xpToAward,
      );

      final todayKey = dateKeyFor(attemptedAt);
      final todayRow = await (_database.select(
        _database.dailyActivityLog,
      )..where((t) => t.studyDate.equals(todayKey))).getSingleOrNull();
      final newExercisesCompleted = (todayRow?.exercisesCompleted ?? 0) + 1;
      final newCorrectCount =
          (todayRow?.correctCount ?? 0) + (wasCorrect ? 1 : 0);
      final newXpEarned = (todayRow?.xpEarned ?? 0) + xpToAward;
      final countsAsActiveDay = _streak.countsAsActiveDay(
        newExercisesCompleted,
      );
      await _database
          .into(_database.dailyActivityLog)
          .insertOnConflictUpdate(
            DailyActivityLogCompanion.insert(
              studyDate: todayKey,
              exercisesCompleted: Value(newExercisesCompleted),
              correctCount: Value(newCorrectCount),
              xpEarned: Value(newXpEarned),
              countsAsActiveDay: Value(countsAsActiveDay),
            ),
          );

      final activeDayRows = await (_database.select(
        _database.dailyActivityLog,
      )..where((t) => t.countsAsActiveDay.equals(true))).get();
      final activeDates = activeDayRows
          .map((r) => DateTime.parse(r.studyDate))
          .toSet();
      final newCurrentStreak = _streak.currentStreak(
        activeDates: activeDates,
        today: attemptedAt,
      );
      final newLongestStreak = newCurrentStreak > profile.longestStreakDays
          ? newCurrentStreak
          : profile.longestStreakDays;

      await _database
          .into(_database.userProfile)
          .insertOnConflictUpdate(
            UserProfileCompanion.insert(
              id: const Value(1),
              totalXp: Value(grant.newTotalXp),
              currentLevel: Value(grant.newLevel),
              currentStreakDays: Value(newCurrentStreak),
              longestStreakDays: Value(newLongestStreak),
              lastStudyDate: Value(todayKey),
              createdAt: profile.createdAt,
            ),
          );

      final dinoState = await (_database.select(
        _database.dinoEvolutionState,
      )..where((t) => t.id.equals(1))).getSingle();
      var hatchingStartedAt = dinoState.hatchingStartedAt;
      if (hatchingStartedAt == null && grant.newLevel >= 10) {
        hatchingStartedAt = attemptedAt;
      }
      final activeDaysSinceHatching = _countActiveDaysSince(
        activeDates,
        hatchingStartedAt,
      );
      final newStage = _hatching.stageFor(
        currentLevel: grant.newLevel,
        activeDaysSinceHatchingStarted: activeDaysSinceHatching,
        alreadyHatched: dinoState.hatchedAt != null,
      );
      final hatchedJustNow =
          dinoState.hatchedAt == null &&
          newStage == DinoEvolutionStage.hatchedBabyPlaceholder;
      await _database
          .into(_database.dinoEvolutionState)
          .insertOnConflictUpdate(
            DinoEvolutionStateCompanion.insert(
              id: const Value(1),
              stage: Value(newStage.toStorageKey()),
              hatchingStartedAt: Value(hatchingStartedAt),
              hatchedAt: Value(
                hatchedJustNow ? attemptedAt : dinoState.hatchedAt,
              ),
            ),
          );

      await _database
          .into(_database.exerciseAttempts)
          .insert(
            ExerciseAttemptsCompanion.insert(
              wordId: Value(wordId),
              exerciseType: exerciseType,
              sessionId: sessionId,
              sessionKind: sessionKind.toStorageKey(),
              wasCorrect: wasCorrect,
              userAnswer: Value(userAnswer),
              masteryLevelBefore: masteryBefore,
              masteryLevelAfter: masteryAfter,
              xpAwarded: Value(xpToAward),
              responseTimeMs: Value(responseTimeMs),
              attemptedAt: attemptedAt,
            ),
          );

      return AnswerResult(
        xpAwarded: xpToAward,
        newMasteryLevel: masteryAfter,
        previousLevel: grant.previousLevel,
        newLevel: grant.newLevel,
        newDinoStage: newStage,
        hatchedJustNow: hatchedJustNow,
      );
    });
  }

  int _countActiveDaysSince(Set<DateTime> activeDates, DateTime? since) {
    if (since == null) return 0;
    final startDay = DateTime(since.year, since.month, since.day);
    return activeDates.where((d) => !d.isBefore(startDay)).length;
  }

  Stream<UserProfileRow> watchUserProfile() =>
      (_database.select(
        _database.userProfile,
      )..where((t) => t.id.equals(1))).watchSingle();

  Stream<DinoEvolutionStateRow> watchDinoEvolutionState() =>
      (_database.select(
        _database.dinoEvolutionState,
      )..where((t) => t.id.equals(1))).watchSingle();

  Future<UserProfileRow> fetchUserProfile() =>
      (_database.select(
        _database.userProfile,
      )..where((t) => t.id.equals(1))).getSingle();

  Future<WordMasteryStats> fetchMasteryStats() async {
    final query = _database.select(_database.words).join([
      leftOuterJoin(
        _database.wordProgress,
        _database.wordProgress.wordId.equalsExp(_database.words.id),
      ),
    ])..where(_database.words.isActive.equals(true));
    final rows = await query.get();

    final distribution = <int, int>{for (var i = 0; i <= 5; i++) i: 0};
    for (final row in rows) {
      final progress = row.readTableOrNull(_database.wordProgress);
      final level = progress?.masteryLevel ?? 0;
      distribution[level] = (distribution[level] ?? 0) + 1;
    }
    return WordMasteryStats(
      totalActiveWords: rows.length,
      masteredCount: distribution[SrsService.maxMasteryLevel] ?? 0,
      distribution: distribution,
    );
  }

  Future<EggProgressInfo> fetchEggProgress() async {
    final profile = await fetchUserProfile();
    final dinoState = await (_database.select(
      _database.dinoEvolutionState,
    )..where((t) => t.id.equals(1))).getSingle();

    final activeDayRows = await (_database.select(
      _database.dailyActivityLog,
    )..where((t) => t.countsAsActiveDay.equals(true))).get();
    final activeDates = activeDayRows
        .map((r) => DateTime.parse(r.studyDate))
        .toSet();
    final activeDaysSinceHatching = _countActiveDaysSince(
      activeDates,
      dinoState.hatchingStartedAt,
    );

    final stage = _hatching.stageFor(
      currentLevel: profile.currentLevel,
      activeDaysSinceHatchingStarted: activeDaysSinceHatching,
      alreadyHatched: dinoState.hatchedAt != null,
    );

    int? daysRemaining;
    if (dinoState.hatchedAt == null && dinoState.hatchingStartedAt != null) {
      daysRemaining =
          (_hatching.requiredActiveDays - activeDaysSinceHatching).clamp(
            0,
            _hatching.requiredActiveDays,
          );
    }

    return EggProgressInfo(
      stage: stage,
      daysRemaining: daysRemaining,
      hatchingStarted: dinoState.hatchingStartedAt != null,
    );
  }
}
