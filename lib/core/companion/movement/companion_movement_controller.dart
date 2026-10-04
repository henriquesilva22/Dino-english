import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../companion_state_machine.dart';
import '../model/companion_model.dart';
import 'play_area_bounds.dart';

/// Moves the companion over the floor like a body, never teleporting:
/// current position + target + speed + heading. It turns towards where it
/// goes (turning in place first when the target is behind it), speeds up
/// and slows down smoothly, stops at the play area's edge, and reports the
/// [gait] and clip [timeScale] that make the feet match the ground speed
/// (the clips have no root motion: the model's walk/run speeds are known,
/// so nothing slides).
///
/// World coordinates (metres): `Offset.dx` = x (right), `Offset.dy` = z
/// (towards the child). Heading 0 faces the child; + turns to the right.
class CompanionMovementController {
  CompanionMovementController({
    required this.model,
    this.position = Offset.zero,
    this.heading = 0,
  });

  final CompanionModel model;
  Offset position;

  /// Radians: 0 = facing the child (+z), pi/2 = facing right (+x).
  double heading;

  /// Ground speed now (metres/second).
  double speed = 0;

  /// Turning speed (radians/second): a quick but visible turn.
  static const double turnRate = 5.5;
  static const double acceleration = 2.4;
  static const double deceleration = 3.5;

  /// Run shows from this speed (and stays down to [runExitSpeed]): between
  /// the model's walk and run speeds.
  double get runEnterSpeed =>
      model.walkSpeed + (model.runSpeed - model.walkSpeed) * 0.5;
  double get runExitSpeed =>
      model.walkSpeed + (model.runSpeed - model.walkSpeed) * 0.3;

  Offset? _target;
  CompanionGait _wanted = CompanionGait.still;
  double _arriveRadius = 0.06;
  double? _faceHeading;
  CompanionGait _shown = CompanionGait.still;
  bool _turningInPlace = false;

  Offset? get target => _target;
  bool get moving => _target != null || speed > 0.02;

  /// Arrived and stopped.
  bool get settled => _target == null && speed <= 0.02;

  /// Heading in degrees, for the 3D view.
  double get yawDegrees => heading * 180 / math.pi;

  /// Goes to [target] at [gait] speed (walk or run), stopping within
  /// [arriveRadius].
  void moveTo(
    Offset target, {
    required CompanionGait gait,
    double arriveRadius = 0.06,
  }) {
    _target = target;
    _wanted = gait == CompanionGait.still ? CompanionGait.walk : gait;
    _arriveRadius = arriveRadius;
    _faceHeading = null;
  }

  /// Slows down to a stop where it is.
  void stop() {
    _target = null;
    _wanted = CompanionGait.still;
  }

  /// Stops and turns (in place) towards [point].
  void face(Offset point) {
    stop();
    final d = point - position;
    if (d.distance > 1e-6) _faceHeading = headingTo(d);
  }

  /// Stops and turns back to the child.
  void faceChild() {
    stop();
    _faceHeading = 0;
  }

  double distanceTo(Offset p) => (p - position).distance;

  /// How far (radians, 0..pi) [p] is from straight ahead.
  double angleTo(Offset p) {
    final d = p - position;
    if (d.distance < 1e-6) return 0;
    return _wrap(headingTo(d) - heading).abs();
  }

  /// Heading of the direction [d].
  static double headingTo(Offset d) => math.atan2(d.dx, d.dy);

  /// Unit vector of [heading].
  static Offset forward(double heading) =>
      Offset(math.sin(heading), math.cos(heading));

  double _gaitSpeed(CompanionGait gait) => switch (gait) {
    CompanionGait.run => model.runSpeed,
    CompanionGait.walk => model.walkSpeed,
    CompanionGait.still => 0,
  };

  /// Advances [dt] seconds inside [bounds].
  void step(double dt, PlayAreaBounds bounds) {
    if (dt <= 0) return;
    var desiredSpeed = 0.0;
    double? desiredHeading = _faceHeading;
    final target = _target;
    if (target != null) {
      final d = target - position;
      final distance = d.distance;
      if (distance <= _arriveRadius) {
        _target = null;
      } else {
        desiredHeading = headingTo(d);
        final error = _wrap(desiredHeading - heading).abs();
        // Behind it: turn first, then go (no moonwalking).
        final aligned = error >= math.pi / 2 ? 0.0 : math.cos(error);
        final braking = math.sqrt(
          2 * deceleration * math.max(0, distance - _arriveRadius),
        );
        desiredSpeed = math.min(_gaitSpeed(_wanted), braking) * aligned;
      }
    }

    // Turn.
    var turned = 0.0;
    if (desiredHeading != null) {
      final error = _wrap(desiredHeading - heading);
      final maxTurn = turnRate * dt;
      turned = error.clamp(-maxTurn, maxTurn);
      heading = _wrap(heading + turned);
      if (_faceHeading != null && error.abs() < 0.01) _faceHeading = null;
    }

    // Speed up / slow down.
    final rate = desiredSpeed > speed ? acceleration : deceleration;
    final change = rate * dt;
    speed += (desiredSpeed - speed).clamp(-change, change);
    if (speed < 1e-3) speed = 0;

    // Move along the heading, never out of bounds.
    final next = position + forward(heading) * (speed * dt);
    final clamped = bounds.clamp(next);
    if (clamped != next) speed *= 0.5; // bumped the edge
    position = clamped;

    _turningInPlace = speed < 0.05 && turned.abs() / dt > 1.0;
    _shown = _showGait();
  }

  CompanionGait _showGait() {
    if (speed > runEnterSpeed ||
        (_shown == CompanionGait.run && speed > runExitSpeed)) {
      return CompanionGait.run;
    }
    if (speed > 0.03 || _turningInPlace) return CompanionGait.walk;
    return CompanionGait.still;
  }

  /// How the body looks: still, walking or running.
  CompanionGait get gait => _shown;

  /// Playback speed of the walk/run clip so the feet match [speed].
  double get timeScale => switch (_shown) {
    CompanionGait.run => (speed / model.runSpeed).clamp(0.6, 1.3),
    CompanionGait.walk =>
      _turningInPlace && speed < 0.05
          ? 0.7
          : (speed / model.walkSpeed).clamp(0.6, 1.8),
    CompanionGait.still => 1,
  };

  static double _wrap(double a) {
    var x = (a + math.pi) % (2 * math.pi);
    if (x < 0) x += 2 * math.pi;
    return x - math.pi;
  }
}
