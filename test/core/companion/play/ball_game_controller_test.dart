import 'dart:math';

import 'package:dino_english/core/companion/companion_state_machine.dart';
import 'package:dino_english/core/companion/model/companion_model.dart';
import 'package:dino_english/core/companion/movement/play_area_bounds.dart';
import 'package:dino_english/core/companion/play/ball_game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const model = CompanionModel.dino;
  const area = PlayAreaBounds(minX: -1.6, maxX: 1.6, minZ: -1.5, maxZ: 1.5);
  const dt = 1 / 60;

  BallGameController game([int seed = 1]) =>
      BallGameController(model: model, random: Random(seed))..resize(area);

  test('starts with the Dino in the middle and the ball away, at rest', () {
    final g = game();
    expect(g.ballSpeed, 0);
    expect(g.ballInAir, isFalse);
    expect(g.play, DinoPlay.noticing);
    expect((g.ballPosition - g.dino.position).distance, greaterThan(0.8));
    expect(g.activity(), CompanionActivity.idle);
  });

  test('the ball follows the finger, and stops at the edge (no bounce)', () {
    final g = game();
    g.grab(const Offset(-1, -1));
    for (var i = 0; i < 90; i++) {
      g.step(dt);
    }
    expect((g.ballPosition - const Offset(-1, -1)).distance, lessThan(0.15));
    // Dragged past the edge: it waits at the edge.
    g.drag(const Offset(-9, -1));
    for (var i = 0; i < 90; i++) {
      g.step(dt);
    }
    expect(g.ballPosition.dx, closeTo(g.ballBounds.minX, 1e-9));
    // Let go while it presses on the edge: no rebound inwards.
    g.release();
    g.step(dt);
    expect(g.ballVelocity.dx, closeTo(0, 0.01));
  });

  test('the Dino plays: walks/runs to the ball, punches it far away', () {
    final g = game();
    final seen = <CompanionActivity>[];
    BallHit? hit;
    Offset? from;
    for (var i = 0; i < 60 * 20 && hit == null; i++) {
      for (final e in g.step(dt)) {
        if (e is BallHit) {
          hit = e;
          from = g.ballPosition;
          expect(g.play, DinoPlay.attacking);
        }
      }
      final a = g.activity();
      if (seen.isEmpty || seen.last != a) seen.add(a);
    }
    expect(hit?.combo, 1);
    expect(seen, contains(CompanionActivity.walking));
    expect(seen.last, CompanionActivity.attacking);
    expect(g.ballInAir, isTrue);
    // It flies, lands and rolls: far from where it was hit.
    var landed = false;
    for (var i = 0; i < 60 * 3; i++) {
      if (g.step(dt).any((e) => e is BallLanded)) landed = true;
    }
    expect(landed, isTrue);
    expect((g.ballPosition - from!).distance, greaterThan(1.2));
  });

  test('a punch takes the ball away from the finger', () {
    final g = game(2);
    var punched = false;
    for (var i = 0; i < 60 * 20 && !punched; i++) {
      // The child holds the ball where it is.
      if (!g.held && !g.ballInAir) g.grab(g.ballPosition);
      punched = g.step(dt).any((e) => e is BallHit);
    }
    expect(punched, isTrue);
    expect(g.held, isFalse);
  });

  test('a far ball makes it run', () {
    final g = game(3);
    var ran = false;
    g.grab(Offset(area.maxX, area.minZ));
    for (var i = 0; i < 60 * 6; i++) {
      g.step(dt);
      if (g.activity() == CompanionActivity.running) ran = true;
    }
    expect(ran, isTrue);
  });

  test('a long game: everything stays in the play area, nothing overlaps', () {
    final g = game(7);
    final random = Random(3);
    var hits = 0;
    for (var i = 0; i < 60 * 90; i++) {
      // Now and then the child brings the ball somewhere.
      if (i % 240 == 0) {
        g.grab(
          Offset(
            area.minX + random.nextDouble() * area.width,
            area.minZ + random.nextDouble() * area.depth,
          ),
        );
      }
      if (i % 240 == 60) g.release();
      for (final e in g.step(dt)) {
        if (e is BallHit) hits++;
      }
      expect(g.dinoBounds.contains(g.dino.position), isTrue);
      expect(g.ballBounds.contains(g.ballPosition), isTrue);
      if (!g.ballInAir) {
        expect(
          (g.ballPosition - g.dino.position).distance,
          greaterThanOrEqualTo(
            model.bodyRadius + BallGameController.ballRadius - 1e-6,
          ),
        );
      }
    }
    expect(hits, greaterThan(5));
  });

  test('left alone after hits, the combo is lost (reported once)', () {
    final g = game();
    final stops = <BallStopped>[];
    var hits = 0;
    for (var i = 0; i < 60 * 60; i++) {
      for (final e in g.step(dt)) {
        if (e is BallHit) hits++;
        if (e is BallStopped) stops.add(e);
      }
      // Keep the Dino from reaching it again after the first hit.
      if (hits > 0) {
        g.dino.position = g.dinoBounds.clamp(
          g.ballPosition.dx > 0 ? const Offset(-9, -9) : const Offset(9, -9),
        );
        g.dino.speed = 0;
      }
    }
    expect(hits, 1);
    expect(stops.length, 1);
    expect(stops.single.lostCombo, 1);
    expect(g.combo, 0);
    expect(g.hits, 1);
  });
}
