import '../../core/models/dino_evolution_stage.dart';
import '../../core/repositories/progress_repository.dart';

/// Short, game-flavored copy for the current egg/dino evolution stage.
/// Pure text formatting over [EggProgressInfo] -- no business rule lives
/// here, it just describes what [HatchingService] already computed.
String describeEggStage(EggProgressInfo info) {
  switch (info.stage) {
    case DinoEvolutionStage.eggDormant:
      return 'Alcance o nível 10 para o ovo começar a rachar!';
    case DinoEvolutionStage.eggHatchingIntact:
      return 'O ovo está pronto para começar a rachar. Continue estudando!';
    case DinoEvolutionStage.eggSmallCrack:
      return info.daysRemaining != null
          ? 'O ovo já tem uma rachadura! Faltam ${info.daysRemaining} dias ativos.'
          : 'O ovo já tem uma rachadura!';
    case DinoEvolutionStage.eggLargeCrack:
      return 'Quase lá! Mais um dia ativo e o ovo eclode.';
    case DinoEvolutionStage.hatchedBabyPlaceholder:
      return 'Parabéns, o ovo eclodiu! 🎉';
  }
}
