import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'difficulty_config.dart';
import 'level/platform.dart';
import 'level/platform_landing.dart';
import 'pet_adventure_game.dart';
import 'pets/pet_catalog.dart';
import 'sound/adventure_sfx.dart';
import 'word_component.dart';

/// The player's chosen pet, rendered as its real Kenney preview image
/// (not a generic placeholder) with procedural squash/stretch and a
/// "running" bounce -- no sprite-sheet frames exist for these pets, so
/// motion is faked the same way the Bloco 3 Dino placeholder was.
/// Physics (gravity/jump/collision) is unchanged from that Dino.
class PetComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<PetAdventureGame> {
  PetComponent({required this.difficulty, required this.pet})
    : super(size: Vector2(64, 64), anchor: Anchor.bottomLeft);

  final DifficultyConfig difficulty;
  final PetDefinition pet;

  double _velocityY = 0;
  double _runCyclePhase = 0;

  double _hitReactionTimer = 0;
  bool _hitReactionIsPositive = false;
  static const double _hitReactionDuration = 0.25;

  late final Sprite _sprite = Sprite(Flame.images.fromCache(pet.previewAsset));
  final Paint _hitTintPaint = Paint()
    ..colorFilter = const ColorFilter.mode(
      Color(0xFFFF375F), // NeonColors.red
      BlendMode.srcATop,
    );

  /// Kenney's animal preview PNGs carry a generous, fairly consistent
  /// transparent margin around the character (confirmed visually across
  /// several previews) -- roughly 17% of empty space below the visible
  /// feet before the image's own bottom edge. `Sprite.render()` draws the
  /// full image into `size`, so without this the pet visibly floats above
  /// the ground/platform surface. Shifting the drawing down compensates
  /// for it; a future swap to a definitive, tightly-cropped sprite would
  /// just zero this out, no physics touched. Estimated, not measured --
  /// recalibrate after checking on a real device.
  static const double _spriteVerticalPadding = 0.17;

  /// The hitbox used for word collisions is smaller than the full 64x64
  /// component (which still includes the sprite's transparent margin) so
  /// it hugs the pet's actual visible body. Its bottom edge lands exactly
  /// at `size.y`, matching the ground-aligned foot position produced by
  /// [_spriteVerticalPadding] above.
  static const double _hitboxInsetTop = 0.25;
  static const double _hitboxInsetSide = 0.15;

  bool get isOnGround => _currentPlatform != null;

  Platform? _currentPlatform;
  String? _dropThroughPlatformId;
  double _dropThroughTimer = 0;
  static const double _dropThroughDuration = 0.35;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      RectangleHitbox(
        position: Vector2(size.x * _hitboxInsetSide, size.y * _hitboxInsetTop),
        size: Vector2(
          size.x * (1 - 2 * _hitboxInsetSide),
          size.y * (1 - _hitboxInsetTop),
        ),
        anchor: Anchor.topLeft,
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Re-derives the level layout for the new size (also read by
    // WordSpawner/PlatformComponent) before repositioning against it --
    // see PetAdventureGame.onGameResize, which runs this before its own
    // children are resized. Known limitation: any resize (e.g. a live
    // landscapeLeft<->landscapeRight rotation, not just the initial
    // layout) snaps the pet back to the ground -- acceptable since most
    // devices report identical width/height for both landscape
    // orientations, so this is effectively a no-op in practice.
    position = Vector2(size.x * 0.15, game.levelLayout.ground.top);
    _currentPlatform = game.levelLayout.ground;
  }

  void jump() {
    if (!isOnGround) return;
    _velocityY = -difficulty.jumpVelocity;
    game.sound.play(AdventureSfx.jump);
  }

  /// Quickly falls through the platform currently stood on (a one-way,
  /// "drop-through" platform mechanic) -- has no effect on the ground
  /// (nothing exists below it) or while airborne.
  void dropThrough() {
    if (_currentPlatform == null) return;
    if (_currentPlatform!.id == 'ground') return;
    _dropThroughPlatformId = _currentPlatform!.id;
    _dropThroughTimer = _dropThroughDuration;
    _currentPlatform = null;
  }

  /// Triggers a short, positive squash pulse -- called by
  /// [PetAdventureGame.handleWordCollected] on a correct catch.
  void reactToCorrect() {
    _hitReactionTimer = _hitReactionDuration;
    _hitReactionIsPositive = true;
  }

  /// Triggers a short "hurt" reaction -- called by
  /// [PetAdventureGame.handleWordCollected] on an incorrect catch.
  void reactToIncorrect() {
    _hitReactionTimer = _hitReactionDuration;
    _hitReactionIsPositive = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_dropThroughTimer > 0) {
      _dropThroughTimer -= dt;
      if (_dropThroughTimer <= 0) {
        _dropThroughTimer = 0;
        _dropThroughPlatformId = null;
      }
    }

    final previousFootY = position.y;
    _velocityY += difficulty.gravity * dt;
    final tentativeFootY = position.y + _velocityY * dt;
    final footX = position.x + size.x / 2;

    final landing = resolveLanding(
      footX: footX,
      previousFootY: previousFootY,
      newFootY: tentativeFootY,
      velocityY: _velocityY,
      platforms: game.levelLayout.platforms,
      ignoredPlatformId: _dropThroughPlatformId,
    );

    if (landing != null) {
      position.y = landing.top;
      _velocityY = 0;
      _currentPlatform = landing;
    } else {
      position.y = tentativeFootY;
      _currentPlatform = null;
    }

    if (isOnGround) {
      _runCyclePhase += dt * 10;
    }
    if (_hitReactionTimer > 0) {
      _hitReactionTimer = (_hitReactionTimer - dt).clamp(
        0,
        _hitReactionDuration,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final jumpStretch = isOnGround
        ? 0.0
        : (-_velocityY / difficulty.jumpVelocity).clamp(-1.0, 1.0) * 0.12;
    final runBounce = isOnGround ? sin(_runCyclePhase) * 0.04 : 0.0;
    var scaleX = 1.0 - jumpStretch + runBounce;
    var scaleY = 1.0 + jumpStretch - runBounce;

    Paint? overridePaint;
    if (_hitReactionTimer > 0) {
      final t = _hitReactionTimer / _hitReactionDuration;
      final wave = sin(t * pi);
      if (_hitReactionIsPositive) {
        scaleX += wave * 0.18;
        scaleY += wave * 0.18;
      } else {
        scaleX += wave * 0.22;
        scaleY -= wave * 0.22;
        overridePaint = _hitTintPaint;
      }
    }

    canvas.save();
    // Pivot the squash/stretch around the pet's ground-contact point
    // (bottom-center), not its top-left -- otherwise it visibly slides.
    canvas.translate(size.x / 2, size.y);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-size.x / 2, -size.y);
    canvas.translate(0, size.y * _spriteVerticalPadding);
    _sprite.render(canvas, size: size, overridePaint: overridePaint);
    canvas.restore();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is WordComponent) {
      game.handleWordCollected(other);
    }
  }
}
