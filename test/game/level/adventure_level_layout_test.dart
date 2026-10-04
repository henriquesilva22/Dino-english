import 'package:dino_english/game/background/scenery_background_component.dart';
import 'package:dino_english/game/level/adventure_level_layout.dart';
import 'package:dino_english/game/level/lane_movement_controller.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    Vector2(844, 390), // phone, landscape
    Vector2(1280, 800), // tablet
    Vector2(1600, 600), // desktop window
  ]) {
    test('the path and two platforms on any screen ($size)', () {
      final layout = AdventureLevelLayout.standard(size);
      expect(layout.platforms.map((p) => p.id), ['high', 'mid', 'ground']);
      // The ground lane is the painted path.
      expect(layout.ground.top, closeTo(size.y * kSceneryPathTop, 1e-9));
      // Platforms above it, in order, below the HUD, under the pet.
      expect(layout.mid.top, lessThan(layout.ground.top));
      expect(layout.high.top, lessThan(layout.mid.top));
      expect(layout.high.top, greaterThan(size.y * 0.3));
      expect(layout.mid.containsX(layout.petX), isTrue);
      expect(layout.high.containsX(layout.petX), isTrue);
      expect(layout.laneTops, [
        layout.ground.top,
        layout.mid.top,
        layout.high.top,
      ]);
      for (final lane in AdventureLane.values) {
        expect(layout.laneSurface(lane).top, layout.laneTops[lane.index]);
      }
    });
  }
}
