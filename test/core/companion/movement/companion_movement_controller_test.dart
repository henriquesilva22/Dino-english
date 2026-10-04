import 'dart:math' as math;

import 'package:dino_english/core/companion/companion_state_machine.dart';
import 'package:dino_english/core/companion/model/companion_model.dart';
import 'package:dino_english/core/companion/movement/companion_movement_controller.dart';
import 'package:dino_english/core/companion/movement/play_area_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const model = CompanionModel.dino;
  const bounds = PlayAreaBounds(minX: -2, maxX: 2, minZ: -2, maxZ: 2);
  const dt = 1 / 60;

  CompanionMovementController mover() =>
      CompanionMovementController(model: model);

  test('walks to a target and stops there, facing it', () {
    final m = mover()..moveTo(const Offset(1, 0), gait: CompanionGait.walk);
    var steps = 0;
    while (!m.settled && steps++ < 2000) {
      m.step(dt, bounds);
    }
    expect(m.position.dx, closeTo(1, 0.1));
    expect(m.position.dy, closeTo(0, 0.05));
    expect(m.heading, closeTo(math.pi / 2, 0.05)); // facing right
  });

  test('turns towards a target behind it before moving (no sliding back)', () {
    final m = mover()..moveTo(const Offset(0, -1.5), gait: CompanionGait.walk);
    m.step(dt, bounds);
    expect(m.speed, 0);
    expect(m.heading.abs(), greaterThan(0));
    for (var i = 0; i < 120; i++) {
      m.step(dt, bounds);
    }
    expect(m.heading.abs(), closeTo(math.pi, 0.05));
    expect(m.position.dy, lessThan(0));
  });

  test('speeds up through walk into run; the clip speed matches', () {
    final m = mover()..moveTo(const Offset(0, 1.9), gait: CompanionGait.run);
    final gaits = <CompanionGait>[];
    for (var i = 0; i < 50; i++) {
      m.step(dt, bounds);
      if (gaits.isEmpty || gaits.last != m.gait) gaits.add(m.gait);
    }
    expect(gaits, [CompanionGait.walk, CompanionGait.run]);
    expect(m.speed, closeTo(model.runSpeed, 0.05));
    expect(m.timeScale, closeTo(1, 0.05));
  });

  test('walking at walk speed plays the clip at normal speed', () {
    final m = mover()..moveTo(const Offset(0, 1.9), gait: CompanionGait.walk);
    for (var i = 0; i < 30; i++) {
      m.step(dt, bounds);
    }
    expect(m.gait, CompanionGait.walk);
    expect(m.timeScale, closeTo(1, 0.05));
  });

  test('never leaves the play area', () {
    final m = mover()..moveTo(const Offset(9, 9), gait: CompanionGait.run);
    for (var i = 0; i < 600; i++) {
      m.step(dt, bounds);
      expect(bounds.contains(m.position), isTrue);
    }
  });

  test('face() turns in place, showing small steps', () {
    final m = mover()..face(const Offset(-1, 0));
    m.step(dt, bounds);
    expect(m.gait, CompanionGait.walk);
    for (var i = 0; i < 60; i++) {
      m.step(dt, bounds);
    }
    expect(m.heading, closeTo(-math.pi / 2, 0.02));
    expect(m.position, Offset.zero);
    expect(m.gait, CompanionGait.still);
  });
}
