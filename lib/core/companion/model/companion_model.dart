import 'dart:math' as math;

import 'package:flutter/painting.dart' show Alignment;

/// What the companion's body can show. A model may lack some (they fall
/// back to [idle]; see `CompanionAnimationController`).
enum CompanionAnim {
  idle,
  walk,
  run,
  attack,
  jump,
  eating,
  sleeping,
  happy,
  talking,
}

/// One animation clip inside the model file.
class CompanionClip {
  const CompanionClip(this.name, {required this.seconds});

  /// Name of the glTF animation.
  final String name;

  /// Length of one play.
  final double seconds;
}

/// A point on/in the model, in model space: metres, origin on the floor
/// between the feet, +y up, +z the way the model faces.
class ModelPoint {
  const ModelPoint(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

/// Where food goes in: the mouth. Used to place the food drop zone (and,
/// later, to bring bread/apples/drinks to it).
class CompanionMouthTarget {
  const CompanionMouthTarget(this.point, {this.radius = 0.18});

  final ModelPoint point;

  /// How big the mouth's drop zone is around [point], in metres.
  final double radius;
}

/// Where the companion goes to sleep, relative to the room (the bedroom
/// background fills the stage): alignment of its feet, its size there and
/// the way it faces while walking to it. No sleeping clip yet -- when one
/// exists, [CompanionAnim.sleeping] plays on arrival.
class CompanionBedTarget {
  const CompanionBedTarget({
    required this.alignment,
    this.scale = 0.8,
    this.approachYaw = 60,
  });

  final Alignment alignment;
  final double scale;

  /// Degrees, 0 = facing the child, + = turning to the screen's right.
  final double approachYaw;
}

/// The fixed camera of the 3D view while the companion moves around (the
/// ball game). Knowing it lets the stage put the model's feet exactly on a
/// floor point and size it in pixels per metre.
class CompanionCamera {
  const CompanionCamera({
    this.pitchDegrees = 70,
    this.distance = 2.4,
    this.targetHeight = 0.45,
    this.fovDegrees = 30,
  });

  /// model-viewer's polar angle (0 = from above, 90 = level).
  final double pitchDegrees;
  final double distance;
  final double targetHeight;

  /// Vertical = horizontal field of view (the view is square).
  final double fovDegrees;

  String get orbit => '0deg ${pitchDegrees}deg ${distance}m';
  String get target => '0m ${targetHeight}m 0m';
  String get fov => '${fovDegrees}deg';

  double get _phi => pitchDegrees * math.pi / 180;
  double get _tanHalfFov => math.tan(fovDegrees * math.pi / 360);

  // Camera at (0, ty + d cos(phi), d sin(phi)), looking at (0, ty, 0);
  // forward (0, -cos, -sin), up (0, sin, -cos), right (1, 0, 0).
  double get _cy => targetHeight + distance * math.cos(_phi);
  double get _cz => distance * math.sin(_phi);

  double _depth(ModelPoint p) =>
      -(p.y - _cy) * math.cos(_phi) - (p.z - _cz) * math.sin(_phi);

  /// Where [p] shows in the square view (model facing the camera):
  /// (0, 0) top-left .. (1, 1) bottom-right.
  ({double x, double y}) project(ModelPoint p) {
    final depth = _depth(p);
    final up = (p.y - _cy) * math.sin(_phi) - (p.z - _cz) * math.cos(_phi);
    final scale = depth * _tanHalfFov;
    return (x: 0.5 + p.x / scale / 2, y: 0.5 - up / scale / 2);
  }

  /// Where the model's origin (its feet) shows: 0 = top, 1 = bottom.
  double get feetFraction => project(const ModelPoint(0, 0, 0)).y;

  /// Metres the square view spans across, at the feet.
  double get viewWidthAtFeet =>
      2 * _depth(const ModelPoint(0, 0, 0)) * _tanHalfFov;
}

/// Everything the app needs to know about one 3D companion model, so the
/// rest of the app never depends on a specific file. Numbers come from
/// `tool/build_companion_model.js` (it prints them), checked against the
/// file by `companion_model_test.dart`.
class CompanionModel {
  const CompanionModel({
    required this.asset,
    required this.height,
    required this.halfWidth,
    required this.bodyRadius,
    required this.clips,
    required this.walkSpeed,
    required this.runSpeed,
    required this.attackHitSeconds,
    required this.attackReach,
    required this.mouth,
    this.mouthShapes,
    this.camera = const CompanionCamera(),
  });

  /// The Dino: one GLB with idle/talk (generated), walk (a jog), run,
  /// attack (a punch), jump, eating and happy (a dance). No sleeping clip, no face
  /// blend shapes and no jaw bone: no lip sync yet.
  static const dino = CompanionModel(
    asset: 'assets/models/dino/dino_companion.glb',
    height: 0.98,
    halfWidth: 0.359,
    bodyRadius: 0.25,
    clips: {
      CompanionAnim.idle: CompanionClip('idle', seconds: 6),
      CompanionAnim.talking: CompanionClip('talk', seconds: 3),
      CompanionAnim.walk: CompanionClip('walk', seconds: 1.875),
      CompanionAnim.run: CompanionClip('run', seconds: 0.6667),
      CompanionAnim.attack: CompanionClip('attack', seconds: 1.2917),
      CompanionAnim.eating: CompanionClip('eating', seconds: 16.2917),
      CompanionAnim.happy: CompanionClip('happy', seconds: 2.4167),
      CompanionAnim.jump: CompanionClip('jump', seconds: 0.9167),
    },
    walkSpeed: 0.7856,
    runSpeed: 1.254,
    attackHitSeconds: 0.5833,
    attackReach: 0.298,
    mouth: CompanionMouthTarget(ModelPoint(0, 0.66, 0.25)),
  );

  /// Flutter asset path of the GLB.
  final String asset;

  /// Size of the model (metres): standing height, half the width with the
  /// arms down, and the radius of its footprint (nothing goes through it).
  final double height;
  final double halfWidth;
  final double bodyRadius;

  /// The clips this model has; missing ones fall back to idle.
  final Map<CompanionAnim, CompanionClip> clips;

  /// How fast the feet move in the walk and run clips (metres/second, the
  /// root motion taken out of them): moving at this speed never slides.
  final double walkSpeed;
  final double runSpeed;

  /// When the punch lands in the attack clip, and how far in front of the
  /// model's origin the fist gets.
  final double attackHitSeconds;
  final double attackReach;

  final CompanionMouthTarget mouth;

  /// Blend shapes for an open/closed mouth (lip sync), or null when the
  /// model has none.
  final ({String open, String close})? mouthShapes;

  final CompanionCamera camera;

  CompanionClip? clip(CompanionAnim anim) => clips[anim];
}
