import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import 'scrolling_layer_component.dart';

const String kCloudsBackgroundAsset =
    'assets/sprites/map/Sprites/Backgrounds/Default/background_clouds.png';

/// Slow, distant cloud layer -- moves at 12% of ground speed. Uses the
/// real Kenney `background_clouds.png` sprite (must already be in
/// `Flame.images` cache -- preloaded by `PetAdventureGame.onLoad`).
class CloudLayerComponent extends ScrollingLayerComponent {
  CloudLayerComponent() : super(parallaxFactor: 0.12);

  late final Sprite _cloudSprite = Sprite(
    Flame.images.fromCache(kCloudsBackgroundAsset),
  );
  final List<_Cloud> _clouds = [];

  @override
  void regeneratePattern(Vector2 size) {
    final random = Random(7);
    // Landscape screens are wider than the portrait layout this was first
    // tuned for -- more clouds keeps the sky from looking sparse.
    const cloudCount = 5;
    _clouds
      ..clear()
      ..addAll(
        List.generate(cloudCount, (i) {
          final cx =
              (i + 0.5) / cloudCount * size.x + random.nextDouble() * 30 - 15;
          final cy = size.y * (0.06 + random.nextDouble() * 0.16);
          final scale = 0.35 + random.nextDouble() * 0.25;
          return _Cloud(Offset(cx, cy), scale);
        }),
      );
  }

  @override
  void paintPattern(Canvas canvas) {
    for (final cloud in _clouds) {
      final side = 140 * cloud.scale;
      _cloudSprite.render(
        canvas,
        position: Vector2(cloud.center.dx, cloud.center.dy),
        size: Vector2.all(side),
        anchor: Anchor.center,
      );
    }
  }
}

class _Cloud {
  const _Cloud(this.center, this.scale);
  final Offset center;
  final double scale;
}
