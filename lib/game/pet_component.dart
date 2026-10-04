import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'difficulty_config.dart';
import 'level/lane_movement_controller.dart';
import 'pet_adventure_game.dart';
import 'pets/pet_catalog.dart';
import 'sound/adventure_sfx.dart';
import 'word_component.dart';

/// Where the pet is this frame, for a body drawn outside Flame (the 3D
/// Dino, a Flutter widget over the game): its feet (centre-bottom, in game
/// = screen coordinates) and what it is doing.
@immutable
class PetPose {
  const PetPose({
    required this.feet,
    required this.lane,
    required this.changingLane,
    required this.laneSerial,
  });

  final Offset feet;
  final AdventureLane lane;
  final bool changingLane;

  /// Changes with every lane change (to play the hop once).
  final int laneSerial;

  @override
  bool operator ==(Object other) =>
      other is PetPose &&
      other.feet == feet &&
      other.lane == lane &&
      other.changingLane == changingLane &&
      other.laneSerial == laneSerial;

  @override
  int get hashCode => Object.hash(feet, lane, changingLane, laneSerial);
}

/// The player's pet. It runs in place near the left edge on one of three
/// lanes and hops between them with [moveUp] / [moveDown] (a
/// [LaneMovementController]); words scroll into it.
///
/// A 2D animal draws its Kenney preview with a procedural running bounce
/// and squash on hits. A 3D pet (the Dino) draws nothing here: the screen
/// shows the 3D model at [PetAdventureGame.petPose] -- this component is only its body for
/// collisions.
class PetComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<PetAdventureGame> {
  PetComponent({required this.difficulty, required this.pet})
    : lanes = LaneMovementController(duration: difficulty.laneChangeSeconds),
      super(size: Vector2(64, 64), anchor: Anchor.bottomLeft);

  final DifficultyConfig difficulty;
  final PetDefinition pet;
  final LaneMovementController lanes;

  /// Size (game units) of the square 3D view drawn for a 3D pet, from the
  /// screen height: about a third of it.
  static double viewSizeFor(Vector2 gameSize) => gameSize.y * 0.34;

  double _runCyclePhase = 0;
  double _hitReactionTimer = 0;
  bool _hitReactionIsPositive = false;
  static const double _hitReactionDuration = 0.25;

  late final Sprite? _sprite = pet.previewAsset == null
      ? null
      : Sprite(Flame.images.fromCache(pet.previewAsset!));
  final Paint _hitTintPaint = Paint()
    ..colorFilter = const ColorFilter.mode(
      Color(0xFFFF375F), // NeonColors.red
      BlendMode.srcATop,
    );

  /// Kenney's animal preview PNGs carry ~17% of empty space below the
  /// visible feet; shifting the drawing down puts the feet on the lane.
  static const double _spriteVerticalPadding = 0.17;

  /// The hitbox hugs the pet's visible body (smaller than the box).
  static const double _hitboxInsetTop = 0.25;
  static const double _hitboxInsetSide = 0.15;

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
    if (pet.is3D) {
      // The Dino seen from the side fills about this much of its view.
      final view = viewSizeFor(size);
      this.size = Vector2(view * 0.45, view * 0.62);
      for (final box in children.whereType<RectangleHitbox>()) {
        box
          ..position = Vector2(
            this.size.x * _hitboxInsetSide,
            this.size.y * _hitboxInsetTop,
          )
          ..size = Vector2(
            this.size.x * (1 - 2 * _hitboxInsetSide),
            this.size.y * (1 - _hitboxInsetTop),
          );
      }
    }
    // A new layout (screen size): back on the ground, on the path.
    lanes.reset();
    position = Vector2(game.levelLayout.petX, game.levelLayout.ground.top);
    _publish();
  }

  /// ⬆️: hop up one lane (nothing on the high one).
  void moveUp() {
    if (lanes.moveUp()) game.sound.play(AdventureSfx.jump);
  }

  /// ⬇️: hop down one lane (nothing on the ground).
  void moveDown() {
    if (lanes.moveDown()) game.sound.play(AdventureSfx.jump);
  }

  /// A short, positive squash pulse -- a correct catch.
  void reactToCorrect() {
    _hitReactionTimer = _hitReactionDuration;
    _hitReactionIsPositive = true;
  }

  /// A short "hurt" reaction -- an incorrect catch.
  void reactToIncorrect() {
    _hitReactionTimer = _hitReactionDuration;
    _hitReactionIsPositive = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    lanes.update(dt);
    final layout = game.levelLayout;
    position.y = lanes.footY(layout.laneTops);
    if (!lanes.moving) _runCyclePhase += dt * 10;
    if (_hitReactionTimer > 0) {
      _hitReactionTimer = (_hitReactionTimer - dt).clamp(
        0,
        _hitReactionDuration,
      );
    }
    _publish();
  }

  void _publish() {
    game.petPose.value = PetPose(
      feet: Offset(position.x + size.x / 2, position.y),
      lane: lanes.lane,
      changingLane: lanes.moving,
      laneSerial: lanes.moveSerial,
    );
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) return; // 3D: drawn by the screen
    final hop = lanes.moving ? 0.1 : 0.0;
    final runBounce = lanes.moving ? 0.0 : sin(_runCyclePhase) * 0.04;
    var scaleX = 1.0 - hop + runBounce;
    var scaleY = 1.0 + hop - runBounce;

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
    // Squash/stretch around the feet (bottom-centre), so it doesn't slide.
    canvas.translate(size.x / 2, size.y);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-size.x / 2, -size.y);
    canvas.translate(0, size.y * _spriteVerticalPadding);
    sprite.render(canvas, size: size, overridePaint: overridePaint);
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
