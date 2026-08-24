import 'package:dino_english/core/services/srs_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = SrsService();
  final now = DateTime(2026, 1, 10);

  group('promotion on correct answers', () {
    test('level 0 promotes to 1 after a single correct answer', () {
      final result = service.applyAnswer(
        currentMasteryLevel: 0,
        currentStreak: 0,
        wasCorrect: true,
        attemptedAt: now,
      );
      expect(result.newMasteryLevel, 1);
      expect(result.newStreak, 0);
      expect(result.nextReviewAt, now.add(const Duration(days: 1)));
    });

    test('level 1 needs two consecutive correct answers to promote', () {
      final first = service.applyAnswer(
        currentMasteryLevel: 1,
        currentStreak: 0,
        wasCorrect: true,
        attemptedAt: now,
      );
      expect(first.newMasteryLevel, 1, reason: 'one correct answer is not enough at level 1');
      expect(first.newStreak, 1);

      final second = service.applyAnswer(
        currentMasteryLevel: 1,
        currentStreak: first.newStreak,
        wasCorrect: true,
        attemptedAt: now,
      );
      expect(second.newMasteryLevel, 2);
      expect(second.newStreak, 0);
    });

    test('level 5 (mastered) stays at 5 and reschedules for maintenance', () {
      final result = service.applyAnswer(
        currentMasteryLevel: 5,
        currentStreak: 0,
        wasCorrect: true,
        attemptedAt: now,
      );
      expect(result.newMasteryLevel, 5);
      expect(result.nextReviewAt, now.add(const Duration(days: 30)));
    });
  });

  group('demotion on wrong answers', () {
    test('drops exactly one level, not straight to zero', () {
      final result = service.applyAnswer(
        currentMasteryLevel: 3,
        currentStreak: 2,
        wasCorrect: false,
        attemptedAt: now,
      );
      expect(result.newMasteryLevel, 2);
      expect(result.newStreak, 0);
    });

    test('floors at level 0, never negative', () {
      final result = service.applyAnswer(
        currentMasteryLevel: 0,
        currentStreak: 0,
        wasCorrect: false,
        attemptedAt: now,
      );
      expect(result.newMasteryLevel, 0);
      expect(result.nextReviewAt, isNull, reason: 'level 0 is always eligible');
    });

    test('schedules sooner than the normal interval for the demoted level', () {
      final result = service.applyAnswer(
        currentMasteryLevel: 4,
        currentStreak: 3,
        wasCorrect: false,
        attemptedAt: now,
      );
      expect(result.newMasteryLevel, 3);
      final normalIntervalForLevel3 = const Duration(days: 7);
      expect(result.nextReviewAt!.isBefore(now.add(normalIntervalForLevel3)), isTrue);
      expect(result.nextReviewAt, now.add(const Duration(days: 4)));
    });
  });

  test('interval table matches the spec for reaching every mastery level 1-5', () {
    // streakNeeded[i] = consecutive correct answers to leave level i.
    const streakNeeded = {0: 1, 1: 2, 2: 2, 3: 3, 4: 3};
    const expectedDaysForNewLevel = {1: 1, 2: 3, 3: 7, 4: 14, 5: 30};

    for (final fromLevel in streakNeeded.keys) {
      final result = service.applyAnswer(
        currentMasteryLevel: fromLevel,
        currentStreak: streakNeeded[fromLevel]! - 1, // one answer away from promotion
        wasCorrect: true,
        attemptedAt: now,
      );
      final newLevel = fromLevel + 1;
      expect(result.newMasteryLevel, newLevel, reason: 'promoting from level $fromLevel');
      expect(
        result.nextReviewAt,
        now.add(Duration(days: expectedDaysForNewLevel[newLevel]!)),
        reason: 'interval for newly-reached level $newLevel',
      );
    }
  });
}
