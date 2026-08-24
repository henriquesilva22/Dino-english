import 'package:dino_english/core/services/streak_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = StreakService();
  final today = DateTime(2026, 1, 10);

  group('countsAsActiveDay threshold', () {
    test('below threshold does not count', () {
      expect(service.countsAsActiveDay(4), isFalse);
    });

    test('exactly at threshold counts', () {
      expect(service.countsAsActiveDay(5), isTrue);
    });

    test('above threshold counts', () {
      expect(service.countsAsActiveDay(10), isTrue);
    });
  });

  group('currentStreak', () {
    test('zero when there is no activity at all', () {
      final streak = service.currentStreak(activeDates: {}, today: today);
      expect(streak, 0);
    });

    test('counts consecutive days ending today', () {
      final streak = service.currentStreak(
        activeDates: {
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
        },
        today: today,
      );
      expect(streak, 3);
    });

    test('still counts as ongoing if only yesterday was active (today not studied yet)', () {
      final streak = service.currentStreak(
        activeDates: {
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
        },
        today: today,
      );
      expect(streak, 2);
    });

    test('breaks after a full gap day', () {
      final streak = service.currentStreak(
        activeDates: {
          today.subtract(const Duration(days: 2)),
          today.subtract(const Duration(days: 3)),
        },
        today: today,
      );
      expect(streak, 0);
    });

    test('multiple timestamps on the same calendar day still count as one day', () {
      final streak = service.currentStreak(
        activeDates: {
          DateTime(2026, 1, 10, 8),
          DateTime(2026, 1, 10, 21, 30),
          DateTime(2026, 1, 9, 6),
        },
        today: today,
      );
      expect(streak, 2);
    });
  });
}
