/// 🪙 How the child earns coins. Coins come from studying (exercises,
/// minigames); they are spent on the Dino's food. Caring for the Dino
/// never pays coins, so feeding can't be farmed.
///
/// Tunable in one place.
abstract final class CoinRewards {
  /// A correct answer in an exercise or minigame.
  static const int correctAnswer = 5;

  /// Bonus the first time a day counts as an active study day (keeps the
  /// streak going).
  static const int activeDay = 15;

  /// Coins awarded for one answer: [correctAnswer] for a correct exercise
  /// answer, plus [activeDay] when this answer completes today's goal.
  static int forAnswer({
    required bool wasCorrect,
    required bool countsAsExercise,
    required bool completedActiveDay,
  }) {
    if (!countsAsExercise) return 0;
    return (wasCorrect ? correctAnswer : 0) +
        (completedActiveDay ? activeDay : 0);
  }
}
