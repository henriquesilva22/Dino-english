import 'boss_fight_state.dart';
import 'word_height_tier.dart';

/// Tunable knobs for the minigame's pacing. A single place to add harder
/// presets later (e.g. `DifficultyConfig.hard()`) without touching any
/// component logic.
class DifficultyConfig {
  const DifficultyConfig({
    required this.scrollSpeed,
    required this.gravity,
    required this.jumpVelocity,
    required this.minSpawnInterval,
    required this.maxSpawnInterval,
    required this.correctWordProbability,
    this.heightTierWeights = const {
      WordHeightTier.low: 1,
      WordHeightTier.medium: 1,
      WordHeightTier.high: 1,
    },
  });

  /// jumpVelocity=740 with gravity=1400 gives a jump apex of
  /// v²/(2·gravity) ≈ 196 world units -- ~30px of headroom above the
  /// `high` platform's 165px offset (AdventureLevelLayout.highOffset), so
  /// ground->high is reachable without demanding pixel-perfect timing,
  /// while still requiring an actual jump rather than being "free". The
  /// previous 670 (apex ~160px) predates the elevated platforms and would
  /// fall short of `high` now.
  factory DifficultyConfig.standard() => const DifficultyConfig(
    scrollSpeed: 180,
    gravity: 1400,
    jumpVelocity: 740,
    minSpawnInterval: 1.6,
    maxSpawnInterval: 2.6,
    correctWordProbability: 0.55,
  );

  /// Pacing for the boss fight, ramping up as [BossFightState.band] drops
  /// (100-75%, 75-50%, 50-25%, 25-0% HP) -- more/faster words, more weight
  /// on the `high` tier, for a "desperate boss" feel. `gravity`/
  /// `jumpVelocity`/`scrollSpeed` are deliberately identical to
  /// [standard] in every band: changing physics mid-fight would break the
  /// platform-reach calibration above and feel unfair, so only spawn
  /// timing/height mix vary.
  factory DifficultyConfig.bossBand(BossHpBand band) => switch (band) {
    BossHpBand.full => DifficultyConfig.standard(),
    BossHpBand.wounded => const DifficultyConfig(
      scrollSpeed: 180,
      gravity: 1400,
      jumpVelocity: 740,
      minSpawnInterval: 1.3,
      maxSpawnInterval: 2.1,
      correctWordProbability: 0.55,
      heightTierWeights: {
        WordHeightTier.low: 1,
        WordHeightTier.medium: 1.3,
        WordHeightTier.high: 1,
      },
    ),
    BossHpBand.critical => const DifficultyConfig(
      scrollSpeed: 180,
      gravity: 1400,
      jumpVelocity: 740,
      minSpawnInterval: 1.0,
      maxSpawnInterval: 1.7,
      correctWordProbability: 0.55,
      heightTierWeights: {
        WordHeightTier.low: 0.8,
        WordHeightTier.medium: 1.2,
        WordHeightTier.high: 1.4,
      },
    ),
    BossHpBand.desperate => const DifficultyConfig(
      scrollSpeed: 180,
      gravity: 1400,
      jumpVelocity: 740,
      minSpawnInterval: 0.8,
      maxSpawnInterval: 1.3,
      correctWordProbability: 0.55,
      heightTierWeights: {
        WordHeightTier.low: 0.6,
        WordHeightTier.medium: 1.2,
        WordHeightTier.high: 1.6,
      },
    ),
  };

  /// World units per second the ground/words scroll to the left.
  final double scrollSpeed;

  /// Downward acceleration applied to the Dino while airborne.
  final double gravity;

  /// Upward velocity applied the instant the Dino jumps.
  final double jumpVelocity;

  /// Random spawn interval range, in seconds.
  final double minSpawnInterval;
  final double maxSpawnInterval;

  /// Chance (0-1) that a spawned word is a real, correct one.
  final double correctWordProbability;

  /// Relative odds of each [WordHeightTier] being picked when spawning a
  /// word, independent of whether it's correct or incorrect.
  final Map<WordHeightTier, double> heightTierWeights;
}
