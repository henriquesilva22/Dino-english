import 'package:dino_english/game/level/lane_movement_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tops = [300.0, 215.0, 135.0]; // ground, mid, high

  double foot(LaneMovementController c) => c.footY(tops);

  void run(LaneMovementController c, double seconds) {
    for (var t = 0.0; t < seconds; t += 1 / 60) {
      c.update(1 / 60);
    }
  }

  test('starts on the ground', () {
    final c = LaneMovementController();
    expect(c.lane, AdventureLane.ground);
    expect(c.moving, isFalse);
    expect(foot(c), tops[0]);
  });

  test('⬆️ climbs one lane at a time, ⬇️ comes down one at a time', () {
    final c = LaneMovementController();
    expect(c.moveUp(), isTrue);
    run(c, 1);
    expect(c.lane, AdventureLane.mid);
    expect(foot(c), closeTo(tops[1], 1e-9));

    expect(c.moveUp(), isTrue);
    run(c, 1);
    expect(c.lane, AdventureLane.high);
    expect(foot(c), closeTo(tops[2], 1e-9));

    expect(c.moveDown(), isTrue);
    run(c, 1);
    expect(c.lane, AdventureLane.mid);
    expect(foot(c), closeTo(tops[1], 1e-9));

    expect(c.moveDown(), isTrue);
    run(c, 1);
    expect(c.lane, AdventureLane.ground);
    expect(foot(c), closeTo(tops[0], 1e-9));
  });

  test('⬇️ on the ground and ⬆️ on the high lane do nothing', () {
    final c = LaneMovementController();
    expect(c.moveDown(), isFalse);
    expect(c.moveSerial, 0);
    expect(foot(c), tops[0]);

    c
      ..moveUp()
      ..moveUp();
    run(c, 2);
    final serial = c.moveSerial;
    expect(c.moveUp(), isFalse);
    expect(c.moveSerial, serial);
    expect(foot(c), closeTo(tops[2], 1e-9));
  });

  test('no teleport: one hop takes the configured time, smoothly', () {
    final c = LaneMovementController(duration: 0.4)..moveUp();
    c.update(1 / 60);
    final early = foot(c);
    expect(early, lessThan(tops[0])); // left the ground
    expect(early, greaterThan(tops[1])); // not there yet
    var previous = early;
    var steps = 1;
    while (c.moving) {
      c.update(1 / 60);
      steps++;
      // Never jumps more than a fraction of the gap in one frame.
      expect((foot(c) - previous).abs(), lessThan((tops[0] - tops[1]) * 0.2));
      previous = foot(c);
    }
    expect(steps / 60, closeTo(0.4, 0.05));
  });

  test('two quick ⬆️ go from the ground to the high lane', () {
    final c = LaneMovementController()
      ..moveUp()
      ..moveUp();
    expect(c.lane, AdventureLane.high);
    run(c, 2);
    expect(foot(c), closeTo(tops[2], 1e-9));
  });

  test('changing its mind mid-hop goes back smoothly', () {
    final c = LaneMovementController()..moveUp();
    run(c, 0.2);
    final mid = foot(c);
    expect(c.moveDown(), isTrue);
    c.update(1 / 60);
    expect((foot(c) - mid).abs(), lessThan((tops[0] - tops[1]) * 0.2));
    run(c, 1);
    expect(foot(c), closeTo(tops[0], 1e-9));
  });
}
