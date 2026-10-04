import 'boss_fight_state.dart';
import 'word_height_tier.dart';

/// Tunable knobs for the minigame's pacing. A single place to add harder
/// presets later (e.g. `DifficultyConfig.hard()`) without touching any
/// component logic.
class DifficultyConfig {
  const DifficultyConfig({
    required this.scrollSpeed,
    required this.minSpawnInterval,
    required this.maxSpawnInterval,
    required this.correctWordProbability,
    this.laneChangeSeconds = 0.4,
    this.heightTierWeights = const {
      WordHeightTier.low: 1,
      WordHeightTier.medium: 1,
      WordHeightTier.high: 1,
    },
  });

  /// The pet changes lanes in [laneChangeSeconds] (0.4 s): quick enough to
  /// reach a word seen coming from the right edge, slow enough to be seen.
  factory DifficultyConfig.standard() => const DifficultyConfig(
    scrollSpeed: 180,
    minSpawnInterval: 1.6,
    maxSpawnInterval: 2.6,
    correctWordProbability: 0.55,
  );

  /// Pacing for the boss fight, ramping up as [BossFightState.band] drops
  /// (100-75%, 75-50%, 50-25%, 25-0% HP) -- more/faster words, more weight
  /// on the high lane, for a "desperate boss" feel. `scrollSpeed` and the
  /// lane change are identical to [standard] in every band: changing the
  /// pet's movement mid-fight would feel unfair, so only spawn timing/
  /// lane mix vary.
  factory DifficultyConfig.bossBand(BossHpBand band) => switch (band) {
    BossHpBand.full => DifficultyConfig.standard(),
    BossHpBand.wounded => const DifficultyConfig(
      scrollSpeed: 180,
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

  /// World units per second the words scroll to the left.
  final double scrollSpeed;

  /// Seconds the pet takes to hop from one lane to the other.
  final double laneChangeSeconds;

  /// Random spawn interval range, in seconds.
  final double minSpawnInterval;
  final double maxSpawnInterval;

  /// Chance (0-1) that a spawned word is a real, correct one.
  final double correctWordProbability;

  /// Relative odds of each [WordHeightTier] (lane) being picked when
  /// spawning a word, independent of whether it's correct or incorrect.
  final Map<WordHeightTier, double> heightTierWeights;
}
