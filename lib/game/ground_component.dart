import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

/// Height, in world units, of the ground strip -- shared with
/// [PetComponent] so it knows where the "floor" is without a hitbox.
/// Left unchanged from the procedural version so `DifficultyConfig`/
/// `WordHeightTier` (calibrated against it) don't need to change.
const double kGroundHeight = 60;

const String kGroundTileAsset =
    'assets/sprites/map/Sprites/Tiles/Default/terrain_purple_horizontal_middle.png';

/// The ground strip: the real Kenney purple terrain tile, repeated,
/// moving at full scroll speed (it's the nearest layer to the camera, no
/// parallax reduction).
class GroundComponent extends PositionComponent {
  GroundComponent() : super(anchor: Anchor.topLeft);

  static const double _tileSize = 64;

  late final Sprite _tileSprite = Sprite(
    Flame.images.fromCache(kGroundTileAsset),
  );

  double _scrollOffset = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = Vector2(size.x, kGroundHeight);
    position = Vector2(0, size.y - kGroundHeight);
  }

  /// Set once by `PetAdventureGame.onLoad` to the active
  /// `DifficultyConfig`'s scroll speed.
  double scrollSpeed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (scrollSpeed <= 0) return;
    _scrollOffset = (_scrollOffset + scrollSpeed * dt) % _tileSize;
  }

  @override
  void render(Canvas canvas) {
    for (var x = -_scrollOffset; x < size.x + _tileSize; x += _tileSize) {
      _tileSprite.render(
        canvas,
        position: Vector2(x, 0),
        size: Vector2(_tileSize, kGroundHeight),
      );
    }
  }
}
