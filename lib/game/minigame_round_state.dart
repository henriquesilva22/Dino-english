enum MinigameStatus { playing, gameOver }

/// Pure, Flame-independent state for one minigame round: lives, score, XP
/// and the outcome rules (4 lives, game over on 0). Kept separate from the
/// Flame components so it can be unit-tested directly, the same way
/// [SrsAnswerResult]/[XpGrantResult] are.
class MinigameRoundState {
  const MinigameRoundState({
    this.lives = startingLives,
    this.score = 0,
    this.xpEarned = 0,
    this.correctWordsCollected = const [],
    this.status = MinigameStatus.playing,
  });

  static const int startingLives = 4;
  static const int pointsPerCorrectWord = 10;
  static const int xpPerCorrectWord = 5;

  /// Round also ends (a "win") after collecting this many correct words,
  /// so a session can't run forever.
  static const int maxCorrectWordsPerRound = 15;

  final int lives;
  final int score;
  final int xpEarned;
  final List<String> correctWordsCollected;
  final MinigameStatus status;

  bool get isGameOver => status == MinigameStatus.gameOver;
  bool get isRoundComplete =>
      correctWordsCollected.length >= maxCorrectWordsPerRound;

  MinigameRoundState collectCorrect(String label) {
    if (isGameOver) return this;
    final collected = [...correctWordsCollected, label];
    final roundComplete = collected.length >= maxCorrectWordsPerRound;
    return MinigameRoundState(
      lives: lives,
      score: score + pointsPerCorrectWord,
      xpEarned: xpEarned + xpPerCorrectWord,
      correctWordsCollected: collected,
      status: roundComplete ? MinigameStatus.gameOver : status,
    );
  }

  MinigameRoundState collectIncorrect() {
    if (isGameOver) return this;
    final newLives = lives - 1;
    return MinigameRoundState(
      lives: newLives,
      score: score,
      xpEarned: xpEarned,
      correctWordsCollected: correctWordsCollected,
      status: newLives <= 0 ? MinigameStatus.gameOver : status,
    );
  }
}
