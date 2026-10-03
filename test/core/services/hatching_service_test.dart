import 'package:dino_english/core/models/dino_evolution_stage.dart';
import 'package:dino_english/core/services/hatching_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = HatchingService(); // requiredActiveDays: 4

  test(
    'levels below 10 always show the dormant egg, regardless of activity',
    () {
      for (final level in [1, 5, 9]) {
        final stage = service.stageFor(
          currentLevel: level,
          activeDaysSinceHatchingStarted: 0,
          alreadyHatched: false,
        );
        expect(stage, DinoEvolutionStage.eggDormant);
      }
    },
  );

  test(
    'already hatched always returns the hatched stage, even below level 10',
    () {
      final stage = service.stageFor(
        currentLevel: 1,
        activeDaysSinceHatchingStarted: 0,
        alreadyHatched: true,
      );
      expect(stage, DinoEvolutionStage.hatchedBabyPlaceholder);
    },
  );

  group('crack stage derivation at level 10+', () {
    test('0 active days: intact but hatching', () {
      final stage = service.stageFor(
        currentLevel: 10,
        activeDaysSinceHatchingStarted: 0,
        alreadyHatched: false,
      );
      expect(stage, DinoEvolutionStage.eggHatchingIntact);
    });

    test('1-2 active days: small crack', () {
      for (final days in [1, 2]) {
        final stage = service.stageFor(
          currentLevel: 10,
          activeDaysSinceHatchingStarted: days,
          alreadyHatched: false,
        );
        expect(
          stage,
          DinoEvolutionStage.eggSmallCrack,
          reason: '$days active days',
        );
      }
    });

    test('3 active days (requiredActiveDays - 1): large crack', () {
      final stage = service.stageFor(
        currentLevel: 10,
        activeDaysSinceHatchingStarted: 3,
        alreadyHatched: false,
      );
      expect(stage, DinoEvolutionStage.eggLargeCrack);
    });

    test('hatch fires exactly at requiredActiveDays, not one day before', () {
      final oneBefore = service.stageFor(
        currentLevel: 10,
        activeDaysSinceHatchingStarted: 3,
        alreadyHatched: false,
      );
      expect(oneBefore, isNot(DinoEvolutionStage.hatchedBabyPlaceholder));

      final atThreshold = service.stageFor(
        currentLevel: 10,
        activeDaysSinceHatchingStarted: 4,
        alreadyHatched: false,
      );
      expect(atThreshold, DinoEvolutionStage.hatchedBabyPlaceholder);
    });

    test('stays hatched beyond the threshold', () {
      final stage = service.stageFor(
        currentLevel: 15,
        activeDaysSinceHatchingStarted: 10,
        alreadyHatched: false,
      );
      expect(stage, DinoEvolutionStage.hatchedBabyPlaceholder);
    });
  });

  group('isReadyToHatch', () {
    test('false below the threshold', () {
      expect(service.isReadyToHatch(3), isFalse);
    });

    test('true at and above the threshold', () {
      expect(service.isReadyToHatch(4), isTrue);
      expect(service.isReadyToHatch(5), isTrue);
    });
  });
}
