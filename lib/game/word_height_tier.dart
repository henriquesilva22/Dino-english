import 'dart:math';

import 'level/lane_movement_controller.dart';

/// Which lane a word floats in. Independent of whether the word is correct
/// or incorrect -- the player has to actually read it, not infer the
/// answer from its height.
enum WordHeightTier { low, medium, high }

extension WordHeightTierLane on WordHeightTier {
  /// The lane the pet must be on to catch it.
  AdventureLane get lane => switch (this) {
    WordHeightTier.low => AdventureLane.ground,
    WordHeightTier.medium => AdventureLane.mid,
    WordHeightTier.high => AdventureLane.high,
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
