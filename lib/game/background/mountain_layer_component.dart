import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../ground_component.dart' show kGroundHeight;
import 'scrolling_layer_component.dart';

const String kHillsBackgroundAsset =
    'assets/sprites/map/Sprites/Backgrounds/Default/background_fade_hills.png';

/// Mid-distance hills silhouette -- moves at 35% of ground speed. Uses
/// the real Kenney `background_fade_hills.png` (256x256, tiled
/// seamlessly across the width, scaled to a fixed on-screen height).
class MountainLayerComponent extends ScrollingLayerComponent {
  MountainLayerComponent() : super(parallaxFactor: 0.35);

  static const double _tileSourceSize = 256;
  static const double _displayHeight = 170;

  late final Sprite _hillsSprite = Sprite(
    Flame.images.fromCache(kHillsBackgroundAsset),
  );

  double _groundY = 0;
  double _tileDisplayWidth = _tileSourceSize;

  @override
  void regeneratePattern(Vector2 size) {
    _groundY = size.y - kGroundHeight;
    _tileDisplayWidth = _tileSourceSize;
  }

  @override
  void paintPattern(Canvas canvas) {
    for (var x = 0.0; x < size.x + _tileDisplayWidth; x += _tileDisplayWidth) {
      _hillsSprite.render(
        canvas,
        position: Vector2(x, _groundY),
        size: Vector2(_tileDisplayWidth, _displayHeight),
        anchor: Anchor.bottomLeft,
      );
    }
  }
}
