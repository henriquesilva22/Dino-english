import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../ground_component.dart' show kGroundHeight;
import 'scrolling_layer_component.dart';

const List<String> kForegroundDecorationAssets = [
  'assets/sprites/map/Sprites/Tiles/Default/bush.png',
  'assets/sprites/map/Sprites/Tiles/Default/mushroom_red.png',
  'assets/sprites/map/Sprites/Tiles/Default/rock.png',
  'assets/sprites/map/Sprites/Tiles/Default/cactus.png',
];

/// Foreground decoration (bushes/mushrooms/rocks/cacti) -- purely
/// decorative (no hitbox), moves at 65% of ground speed for a depth cue
/// closer to the camera than the hills but still behind gameplay. Uses
/// the real Kenney tiles, alternated.
class TreeLayerComponent extends ScrollingLayerComponent {
  TreeLayerComponent() : super(parallaxFactor: 0.65);

  late final List<Sprite> _sprites = kForegroundDecorationAssets
      .map((path) => Sprite(Flame.images.fromCache(path)))
      .toList();

  final List<_Decoration> _items = [];

  @override
  void regeneratePattern(Vector2 size) {
    final random = Random(13);
    final groundY = size.y - kGroundHeight;
    // Landscape screens are noticeably wider than the portrait layout this
    // was first tuned for -- more items keeps the ground line from
    // looking sparse across the extra width.
    const itemCount = 10;
    _items
      ..clear()
      ..addAll(
        List.generate(itemCount, (i) {
          final x =
              (i + 0.5) / itemCount * size.x + random.nextDouble() * 24 - 12;
          final scale = 0.8 + random.nextDouble() * 0.5;
          return _Decoration(x, groundY, i % _sprites.length, scale);
        }),
      );
  }

  @override
  void paintPattern(Canvas canvas) {
    for (final item in _items) {
      final side = 48 * item.scale;
      _sprites[item.spriteIndex].render(
        canvas,
        position: Vector2(item.x, item.groundY),
        size: Vector2.all(side),
        anchor: Anchor.bottomCenter,
      );
    }
  }
}

class _Decoration {
  const _Decoration(this.x, this.groundY, this.spriteIndex, this.scale);
  final double x;
  final double groundY;
  final int spriteIndex;
  final double scale;
}
