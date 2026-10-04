import 'package:dino_english/core/brain/model/dino_enums.dart';
import 'package:dino_english/core/companion/companion_needs_service.dart';
import 'package:dino_english/core/companion/companion_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = CompanionNeedsService();
  final t0 = DateTime(2026, 10, 3, 8);

  CompanionState state({
    double hunger = 50,
    double thirst = 50,
    double energy = 50,
    double happiness = 50,
    bool isSleeping = false,
    DateTime? at,
  }) => CompanionState(
    hunger: hunger,
    thirst: thirst,
    energy: energy,
    happiness: happiness,
    isSleeping: isSleeping,
    updatedAt: at ?? t0,
  );

  group('decay', () {
    test('awake: every need goes down with time', () {
      final s = service.decay(state(), t0.add(const Duration(hours: 2)));
      expect(s.hunger, 40);
      expect(s.thirst, 36);
      expect(s.energy, 42);
      expect(s.happiness, 44);
      expect(s.updatedAt, t0.add(const Duration(hours: 2)));
    });

    test('a few seconds keep fractional progress (no rounding loss)', () {
      var s = state();
      for (var i = 1; i <= 60; i++) {
        s = service.decay(s, t0.add(Duration(minutes: i)));
      }
      expect(s.hunger, closeTo(45, 0.001));
    });

    test('asleep: energy recovers and the Dino wakes up when rested', () {
      final s = service.decay(
        state(energy: 50, isSleeping: true),
        t0.add(const Duration(hours: 1)),
      );
      expect(s.energy, 75);
      expect(s.isSleeping, isTrue);
      final rested = service.decay(s, t0.add(const Duration(hours: 3)));
      expect(rested.energy, CompanionState.max);
      expect(rested.isSleeping, isFalse);
    });

    test('put to bed already full, it keeps sleeping for a nap', () {
      final full = state(energy: 100, isSleeping: true);
      final soon = service.decay(full, t0.add(const Duration(minutes: 5)));
      expect(soon.isSleeping, isTrue);
      final later = service.decay(full, t0.add(const Duration(hours: 2)));
      expect(later.isSleeping, isFalse);
    });

    test('a clock going backwards changes nothing', () {
      final s = service.decay(state(), t0.subtract(const Duration(hours: 5)));
      expect(s.hunger, 50);
    });
  });

  group('care', () {
    test('XP only when the need really needed care', () {
      final needed = service.applyCare(state(hunger: 50), DinoCare.feed, t0);
      expect(needed.xp, CompanionNeedsService.feedXp);
      final notReally = service.applyCare(state(hunger: 85), DinoCare.feed, t0);
      expect(notReally.applied, isTrue);
      expect(notReally.xp, 0);
    });

    test('the daily cap resets the next day', () {
      var s = state(hunger: 0, thirst: 0, happiness: 0, energy: 100);
      var total = 0;
      for (var i = 0; i < 10; i++) {
        final o = service.applyCare(s, DinoCare.play, t0);
        total += o.xp;
        s = o.state.copyWith(happiness: 0, energy: 100);
      }
      expect(total, CompanionNeedsService.dailyCareXpCap);

      final tomorrow = t0.add(const Duration(days: 1));
      final next = service.applyCare(s, DinoCare.play, tomorrow);
      expect(next.xp, CompanionNeedsService.playXp);
    });

    test('values stay within 0..100', () {
      final o = service.applyCare(state(thirst: 90), DinoCare.water, t0);
      expect(o.state.thirst, CompanionState.max);
      final tired = service.applyCare(state(energy: 15), DinoCare.play, t0);
      expect(tired.state.energy, 5);
    });
  });
}
