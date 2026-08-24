import '../models/dino_evolution_stage.dart';

/// Derives the egg/dino [DinoEvolutionStage] purely from the user's level
/// and how many distinct active study days have occurred since hatching
/// started.
///
/// Deliberately stateless beyond [requiredActiveDays]: there is no stored
/// "days completed" counter here or in the schema -- the active-day
/// count is always recomputed from `daily_activity_log`, removing a
/// whole class of "did I already count today" bugs.
class HatchingService {
  const HatchingService({this.requiredActiveDays = 4});

  /// Active study days needed, once hatching starts at level 10, before
  /// the egg hatches. Spec calls for "3-4 days"; 4 is the default.
  final int requiredActiveDays;

  DinoEvolutionStage stageFor({
    required int currentLevel,
    required int activeDaysSinceHatchingStarted,
    required bool alreadyHatched,
  }) {
    if (alreadyHatched) return DinoEvolutionStage.hatchedBabyPlaceholder;
    if (currentLevel < 10) return DinoEvolutionStage.eggDormant;

    if (activeDaysSinceHatchingStarted >= requiredActiveDays) {
      return DinoEvolutionStage.hatchedBabyPlaceholder;
    }
    if (activeDaysSinceHatchingStarted >= requiredActiveDays - 1) {
      return DinoEvolutionStage.eggLargeCrack;
    }
    if (activeDaysSinceHatchingStarted >= 1) {
      return DinoEvolutionStage.eggSmallCrack;
    }
    return DinoEvolutionStage.eggHatchingIntact;
  }

  bool isReadyToHatch(int activeDaysSinceHatchingStarted) =>
      activeDaysSinceHatchingStarted >= requiredActiveDays;
}
