import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../pet_adventure_game.dart';
import 'platform.dart';

const String kPlatformLeftCapAsset =
    'assets/sprites/map/Sprites/Tiles/Default/terrain_purple_cloud_left.png';
const String kPlatformMiddleAsset =
    'assets/sprites/map/Sprites/Tiles/Default/terrain_purple_cloud_middle.png';
const String kPlatformRightCapAsset =
    'assets/sprites/map/Sprites/Tiles/Default/terrain_purple_cloud_right.png';

const List<String> kPlatformAssets = [
  kPlatformLeftCapAsset,
  kPlatformMiddleAsset,
  kPlatformRightCapAsset,
];

/// A visual, fixed (non-scrolling) elevated platform built from the Kenney
/// "cloud" terrain tiles -- unlike [GroundComponent], platforms don't
/// scroll: only the ground and the words move, the platforms are stable
/// footing the pet jumps between.
class PlatformComponent extends PositionComponent
    with HasGameReference<PetAdventureGame> {
  PlatformComponent({required this.spec}) : super(anchor: Anchor.topLeft);

  final Platform spec;

  static const double kPlatformHeight = 28;
  static const double _tileSize = 64;

  late final Sprite _leftCap = Sprite(
    Flame.images.fromCache(kPlatformLeftCapAsset),
  );
  late final Sprite _middle = Sprite(
    Flame.images.fromCache(kPlatformMiddleAsset),
  );
  late final Sprite _rightCap = Sprite(
    Flame.images.fromCache(kPlatformRightCapAsset),
  );

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Recompute from the current levelLayout (matched by id) instead of
    // relying on the `spec` snapshot passed at construction time -- this
    // component used to be the only visual piece of scenery that never
    // reacted to a resize after being built, so a resize landing after
    // onLoad() (e.g. the landscape/immersive-UI settling on screen
    // re-entry) left it visually stuck at its old position/size while
    // physics (which reads game.levelLayout live every frame) kept
    // working -- collision fine, visuals broken. Same pattern already
    // used by GroundComponent/PetComponent/BossComponent.
    final current = game.levelLayout.platforms.firstWhere(
      (p) => p.id == spec.id,
    );
    position = Vector2(current.left, current.top);
    this.size = Vector2(current.right - current.left, kPlatformHeight);
  }

  @override
  void render(Canvas canvas) {
    final tileCount = (size.x / _tileSize).ceil().clamp(2, 1000);
    for (var i = 0; i < tileCount; i++) {
      final sprite = i == 0
          ? _leftCap
          : (i == tileCount - 1 ? _rightCap : _middle);
      sprite.render(
        canvas,
        position: Vector2(i * _tileSize, 0),
        size: Vector2(_tileSize, kPlatformHeight),
      );
    }
  }
}
