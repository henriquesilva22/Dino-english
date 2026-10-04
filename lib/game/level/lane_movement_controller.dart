import 'dart:math' as math;

/// The three places the pet can run on in Pet Adventure, bottom to top:
/// the painted path, the middle platform and the high platform.
enum AdventureLane { ground, mid, high }

/// Moves the pet between the lanes: [moveUp] / [moveDown] (the ⬆️/⬇️
/// buttons, the arrow keys) go one lane at a time. Never teleports: each
/// change is a short hop, eased, that [update] advances. Up on the top
/// lane or down on the ground does nothing.
///
/// Pure Dart: knows nothing about Flame or the pet's look, so any body (the
/// 2D animals, the 3D Dino) just follows [footY].
class LaneMovementController {
  LaneMovementController({this.duration = 0.4, this.hopHeight = 26});

  /// Seconds one lane change takes.
  final double duration;

  /// Extra height (world units) of the hop's arc, mid-way.
  final double hopHeight;

  /// Lane index as a continuous value: 0 = ground .. 2 = high.
  double _progress = 0;
  AdventureLane _target = AdventureLane.ground;

  /// Where it is going (or already is).
  AdventureLane get lane => _target;

  /// Between lanes right now.
  bool get moving => _progress != _goal;

  /// Changes every time a lane change starts (to play the hop).
  int get moveSerial => _moveSerial;
  int _moveSerial = 0;

  double get _goal => _target.index.toDouble();

  /// ⬆️: one lane up. Returns whether it moved.
  bool moveUp() {
    if (_target.index == AdventureLane.values.length - 1) return false;
    return _moveTo(AdventureLane.values[_target.index + 1]);
  }

  /// ⬇️: one lane down. Returns whether it moved.
  bool moveDown() {
    if (_target.index == 0) return false;
    return _moveTo(AdventureLane.values[_target.index - 1]);
  }

  bool _moveTo(AdventureLane lane) {
    _target = lane;
    _moveSerial++;
    return true;
  }

  /// Back on the ground at once (a new level layout).
  void reset() {
    _target = AdventureLane.ground;
    _progress = 0;
  }

  void update(double dt) {
    if (!moving || dt <= 0) return;
    final step = dt / duration;
    _progress = _goal > _progress
        ? math.min(_goal, _progress + step)
        : math.max(_goal, _progress - step);
  }

  /// Foot height (Y grows down) given each lane's surface, ground first:
  /// eased between the two lanes it is between, plus a hop arc while
  /// moving.
  double footY(List<double> laneTops) {
    assert(laneTops.length == AdventureLane.values.length);
    final from = _progress.floor().clamp(0, laneTops.length - 1);
    final to = math.min(from + 1, laneTops.length - 1);
    final f = _progress - from;
    final eased = f * f * (3 - 2 * f);
    final arc = moving ? math.sin(f * math.pi) * hopHeight : 0;
    return laneTops[from] + (laneTops[to] - laneTops[from]) * eased - arc;
  }
}
