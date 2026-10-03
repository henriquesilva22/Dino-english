enum BossFightStatus { fighting, victory }

/// Pure, Flame-independent state for a boss fight: HP and outcome. Kept
/// separate from [MinigameRoundState] (which still owns lives/score/XP
/// and governs the loss condition unchanged -- an incorrect word still
/// costs a life exactly like the normal mode) so that class's existing
/// tests/contract stay untouched.
class BossFightState {
  const BossFightState({
    this.hp = startingHp,
    this.status = BossFightStatus.fighting,
  });

  static const int startingHp = 100;

  /// Damage from a correct word with `Word.difficulty` below
  /// [_hardDifficultyThreshold], or from landing a shot on the boss
  /// directly (no word/difficulty involved there).
  static const int normalWordDamage = 5;

  /// Damage from a correct word with `Word.difficulty` at or above
  /// [_hardDifficultyThreshold]. Catching only easy words may not reach
  /// 100 HP within MinigameRoundState.maxCorrectWordsPerRound (15) --
  /// shooting the boss (uncapped by that round limit) is the other damage
  /// channel, intentionally.
  static const int hardWordDamage = 10;

  /// `difficulty >= 3` is "hard". Seed data (240 words) skews easy: 150
  /// difficulty=1, 82 difficulty=2, 7 difficulty=3, 1 difficulty=4 -- this
  /// splits off the 8 advanced words (3-4) from the 232 beginner/
  /// intermediate ones (1-2).
  static const int _hardDifficultyThreshold = 3;

  static const int victoryBonusXp = 50;

  static int damageForWordDifficulty(int difficulty) =>
      difficulty >= _hardDifficultyThreshold
      ? hardWordDamage
      : normalWordDamage;

  final int hp;
  final BossFightStatus status;

  bool get isFinished => status == BossFightStatus.victory;

  BossFightState hit({int damage = normalWordDamage}) {
    if (isFinished) return this;
    final newHp = (hp - damage).clamp(0, startingHp);
    return BossFightState(
      hp: newHp,
      status: newHp <= 0 ? BossFightStatus.victory : status,
    );
  }

  /// Drives the boss fight's progressive difficulty (see
  /// `DifficultyConfig.bossBand`) -- the boss spawns words faster/higher
  /// as its HP drops, for a "desperate boss" feel.
  BossHpBand get band => switch (hp) {
    > 75 => BossHpBand.full,
    > 50 => BossHpBand.wounded,
    > 25 => BossHpBand.critical,
    _ => BossHpBand.desperate,
  };
}

enum BossHpBand { full, wounded, critical, desperate }
