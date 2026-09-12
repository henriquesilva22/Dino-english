import 'dart:math';

/// How high a word floats above the ground. Independent of whether the
/// word is correct or incorrect -- the player has to actually read it,
/// not infer the answer from its height.
enum WordHeightTier { low, medium, high }

extension WordHeightTierGroundOffset on WordHeightTier {
  /// Vertical offset (world units) between the ground line and the
  /// bottom of the word capsule. Matches `AdventureLevelLayout`'s platform
  /// heights exactly: `low` sits on the ground, `medium` on the `mid`
  /// platform (85px up), `high` on the `high` platform (165px up) --
  /// reachable within the jump apex of [DifficultyConfig.standard]
  /// (~196px, from jumpVelocity²/(2·gravity)). Revisit both together if
  /// either changes.
  double get groundOffset => switch (this) {
    WordHeightTier.low => 0,
    WordHeightTier.medium => 85,
    WordHeightTier.high => 165,
  };
}

/// Picks a tier weighted by [weights] (a tier missing from the map counts
/// as weight 0). Pure `Random -> tier` function, independent of
/// Flutter/Flame so it's directly unit-testable.
WordHeightTier pickWordHeightTier(
  Random random,
  Map<WordHeightTier, double> weights,
) {
  final total = weights.values.fold<double>(0, (a, b) => a + b);
  assert(total > 0, 'heightTierWeights must not sum to zero');
  var roll = random.nextDouble() * total;
  for (final entry in weights.entries) {
    if (roll < entry.value) return entry.key;
    roll -= entry.value;
  }
  return weights.keys.last;
}
