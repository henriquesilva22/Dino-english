import 'dart:math';

import 'package:dino_english/game/level/lane_movement_controller.dart';
import 'package:dino_english/game/word_height_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a tier with weight zero is never picked', () {
    for (var seed = 0; seed < 50; seed++) {
      final tier = pickWordHeightTier(Random(seed), const {
        WordHeightTier.low: 1,
        WordHeightTier.medium: 0,
        WordHeightTier.high: 0,
      });
      expect(tier, WordHeightTier.low);
    }
  });

  test('equal weights roughly split three ways over many draws', () {
    final random = Random(42);
    final counts = {for (final t in WordHeightTier.values) t: 0};
    const weights = {
      WordHeightTier.low: 1.0,
      WordHeightTier.medium: 1.0,
      WordHeightTier.high: 1.0,
    };

    for (var i = 0; i < 9000; i++) {
      final tier = pickWordHeightTier(random, weights);
      counts[tier] = counts[tier]! + 1;
    }

    for (final count in counts.values) {
      expect(count, closeTo(3000, 400)); // generous tolerance, avoids flakiness
    }
  });

  test('each tier floats in its own lane', () {
    expect(WordHeightTier.low.lane, AdventureLane.ground);
    expect(WordHeightTier.medium.lane, AdventureLane.mid);
    expect(WordHeightTier.high.lane, AdventureLane.high);
  });
}
