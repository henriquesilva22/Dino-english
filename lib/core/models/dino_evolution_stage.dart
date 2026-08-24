/// The egg/dino lifecycle stage, cached in `dino_evolution_state.stage`
/// and always recomputed by [HatchingService] from the user's level and
/// hatching-activity-day count -- never hand-set anywhere else.
///
/// Levels 1-9 stay at [eggDormant]. Levels 11-100 evolution stages are
/// out of scope for this MVP (no 3D/visual work yet -- see the project
/// plan), but this enum exists now so the DB column has a stable value
/// to persist and later visual stages are purely additive.
enum DinoEvolutionStage {
  eggDormant,
  eggHatchingIntact,
  eggSmallCrack,
  eggLargeCrack,
  hatchedBabyPlaceholder,
}

extension DinoEvolutionStageStorage on DinoEvolutionStage {
  String toStorageKey() => name;
}

DinoEvolutionStage dinoEvolutionStageFromStorageKey(String key) {
  return DinoEvolutionStage.values.firstWhere(
    (stage) => stage.name == key,
    orElse: () => DinoEvolutionStage.eggDormant,
  );
}
