import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../companion_response.dart';
import '../companion_state_machine.dart';
import '../model/companion_model.dart';
import '../movement/companion_movement_controller.dart';
import '../movement/play_area_bounds.dart';

/// Something that happened in one [BallGameController.step].
sealed class BallEvent {
  const BallEvent();
}

/// The Dino hit the ball away; [combo] hits in a row (the child kept
/// bringing the ball back).
class BallHit extends BallEvent {
  const BallHit(this.combo);
  final int combo;
}

/// The ball landed after flying.
class BallLanded extends BallEvent {
  const BallLanded();
}

/// Nobody played with the ball for a while: the combo is lost.
class BallStopped extends BallEvent {
  const BallStopped(this.lostCombo);
  final int lostCombo;
}

/// What the Dino is up to in the game.
enum DinoPlay {
  /// Just saw the ball: a short look before going.
  noticing,

  /// Walking/running after the ball.
  chasing,

  /// At the ball: a tiny pause to line up.
  liningUp,

  /// The punch (the ball flies at [CompanionModel.attackHitSeconds]).
  attacking,

  /// Watching the ball fly; it goes again when the ball lands.
  watching,
}

/// "Brincar com o Dino": the child leads the ball with a finger, the Dino
/// runs after it and punches it far away; the child brings it back. Pure
/// Dart, world metres (`Offset.dx` = x, `Offset.dy` = z), no pixels: the
/// stage draws it through a `FloorProjection` and forwards the finger.
///
/// The ball never bounces off the edges: it stops there. The Dino's loop:
/// notice -> walk (-> run when far) -> line up -> punch -> the ball flies
/// -> watch it land -> chase again. Distances come from the model (its
/// reach and size), never from the screen.
class BallGameController {
  BallGameController({required this.model, math.Random? random})
    : _random = random ?? math.Random(),
      dino = CompanionMovementController(model: model);

  final CompanionModel model;
  final math.Random _random;
  final CompanionMovementController dino;
  static const CompanionStateMachine _states = CompanionStateMachine();

  // ---- the ball ---------------------------------------------------------------

  /// A playground ball, about 40% of the Dino's height.
  static const double ballRadius = 0.2;

  /// How eagerly the ball follows the finger (1/s) and its top speed then.
  static const double followRate = 12;
  static const double maxFollowSpeed = 4;

  /// A punch: across the floor fast, and up in an arc.
  static const double punchSpeed = 4.2;
  static const double punchLift = 2.6;
  static const double gravity = 9.8;

  /// Fraction of speed lost per second rolling on the floor.
  static const double friction = 0.9;
  static const double stopSpeed = 0.08;

  /// Left alone this long after a hit, the combo is lost.
  static const Duration idleLimit = Duration(seconds: 6);

  // ---- the Dino's play ------------------------------------------------------------

  /// Farther than this from the ball: it runs.
  static const double runDistance = 1.2;

  /// Running, it slows to a walk this close.
  static const double walkDistance = 0.7;
  static const Duration noticeTime = Duration(milliseconds: 450);
  static const Duration lineUpTime = Duration(milliseconds: 120);

  /// Watching a flying ball at most this long.
  static const Duration watchTime = Duration(milliseconds: 1500);

  PlayAreaBounds _area = const PlayAreaBounds(
    minX: -1,
    maxX: 1,
    minZ: -1,
    maxZ: 1,
  );
  bool _placed = false;
  Offset _ball = Offset.zero;
  Offset _velocity = Offset.zero;
  double _height = 0;
  double _lift = 0;
  Offset? _finger;
  int _combo = 0;
  int _hits = 0;
  int _bestCombo = 0;
  double _idleTime = 0;

  DinoPlay _play = DinoPlay.noticing;
  double _playTime = 0;
  int _attackSerial = 0;
  bool _punchThrown = false;
  bool _running = false;

  Offset get ballPosition => _ball;
  Offset get ballVelocity => _velocity;
  double get ballSpeed => _velocity.distance;

  /// Height of the ball above the floor (metres): it flies after a punch.
  double get ballHeight => _height;
  bool get ballInAir => _height > 0;

  /// The child's finger is on the ball.
  bool get held => _finger != null;
  int get combo => _combo;
  int get hits => _hits;
  int get bestCombo => _bestCombo;
  DinoPlay get play => _play;
  PlayAreaBounds get area => _area;

  /// Changes with every punch (to restart the clip).
  int get attackSerial => _attackSerial;
  bool get attacking => _play == DinoPlay.attacking;

  /// Where the Dino's body may go: its whole width stays on the floor.
  PlayAreaBounds get dinoBounds =>
      _area.deflate(model.halfWidth, model.bodyRadius);
  PlayAreaBounds get ballBounds => _area.deflate(ballRadius);

  /// Dino origin to ball centre when the punch connects (the fist sinks a
  /// little into the ball). Always beyond touching distance.
  double get strikeDistance => math.max(
    model.attackReach + ballRadius * 0.6,
    model.bodyRadius + ballRadius + 0.05,
  );

  /// What the Dino's body shows, given the engine's reaction and the voice
  /// (it keeps playing while it talks).
  CompanionActivity activity({
    CompanionAnimation engine = CompanionAnimation.idle,
    bool speaking = false,
  }) => _states.resolve(
    // The game itself is the play: no extra one-shot from the engine.
    engine: engine == CompanionAnimation.playing
        ? CompanionAnimation.idle
        : engine,
    speaking: speaking,
    gait: dino.gait,
    attacking: attacking,
  );

  /// Clip speed for the walk/run (1 otherwise).
  double get timeScale =>
      attacking || dino.gait == CompanionGait.still ? 1 : dino.timeScale;

  /// Sets the floor; the first call places the Dino in the middle and the
  /// ball a bit away, in front and to one side, at rest.
  void resize(PlayAreaBounds area) {
    _area = area;
    if (!_placed) {
      _placed = true;
      final c = area.center;
      dino.position = dinoBounds.clamp(c + Offset(0, -area.depth * 0.15));
      final side = _random.nextBool() ? 1 : -1;
      _ball = ballBounds.clamp(
        c + Offset(side * area.width * 0.3, area.depth * 0.25),
      );
      _setPlay(DinoPlay.noticing);
    } else {
      dino.position = dinoBounds.clamp(dino.position);
      _ball = ballBounds.clamp(_ball);
    }
  }

  // ---- the finger -----------------------------------------------------------------

  /// The finger touched the floor at [at]: the ball goes there and follows.
  void grab(Offset at) {
    _finger = ballBounds.clamp(at);
    _idleTime = 0;
  }

  /// The finger moved to [at].
  void drag(Offset at) {
    if (_finger != null) _finger = ballBounds.clamp(at);
  }

  /// The finger left: the ball rolls on with the speed it had.
  void release() => _finger = null;

  // ---- the world --------------------------------------------------------------------

  /// Advances [dt] seconds; returns what happened.
  List<BallEvent> step(double dt) {
    if (dt <= 0) return const [];
    final events = <BallEvent>[];
    _stepBall(dt, events);
    _think(dt, events);
    dino.step(dt, dinoBounds);
    _collide();
    _idleTime += dt;
    if (held || ballInAir) _idleTime = 0;
    if (_combo > 0 && _idleTime >= idleLimit.inMicroseconds / 1e6) {
      events.add(BallStopped(_combo));
      _combo = 0;
    }
    return events;
  }

  void _stepBall(double dt, List<BallEvent> events) {
    if (ballInAir) {
      // Flying: no friction, falls back to the floor.
      _lift -= gravity * dt;
      _height += _lift * dt;
      if (_height <= 0) {
        _height = 0;
        // One small hop, then it rolls.
        _lift = _lift < -2 ? -_lift * 0.3 : 0;
        if (_lift > 0) _height = 1e-4;
        events.add(const BallLanded());
      }
    } else if (_finger case final finger?) {
      final pull = (finger - _ball) * followRate;
      final s = pull.distance;
      _velocity = s > maxFollowSpeed ? pull / s * maxFollowSpeed : pull;
    } else {
      _velocity = _velocity * math.max(0, 1 - friction * dt);
      if (_velocity.distance < stopSpeed) _velocity = Offset.zero;
    }
    // No bouncing: at the edge the ball just stops going that way.
    final b = ballBounds;
    final next = _ball + _velocity * dt;
    final clamped = b.clamp(next);
    if (clamped.dx != next.dx) _velocity = Offset(0, _velocity.dy);
    if (clamped.dy != next.dy) _velocity = Offset(_velocity.dx, 0);
    _ball = clamped;
  }

  /// Nothing goes through the Dino. A loose ball is pushed out (and nudged
  /// along when it walks into it); a ball under the finger pushes the Dino
  /// back instead.
  void _collide() {
    if (_height > ballRadius) return; // flying over it
    final minDistance = model.bodyRadius + ballRadius;
    final d = _ball - dino.position;
    final distance = d.distance;
    if (distance >= minDistance) return;
    final n = distance < 1e-6
        ? CompanionMovementController.forward(dino.heading)
        : d / distance;
    if (!held) {
      _ball = ballBounds.clamp(dino.position + n * minDistance);
      final push =
          CompanionMovementController.forward(dino.heading) * dino.speed;
      final along = push.dx * n.dx + push.dy * n.dy;
      if (along > 0) _velocity += n * along;
    }
    final left = _ball - dino.position;
    if (left.distance < minDistance) {
      final away = left.distance < 1e-6 ? n : left / left.distance;
      dino.position = dinoBounds.clamp(_ball - away * minDistance);
      dino.speed = 0;
    }
  }

  void _setPlay(DinoPlay play) {
    _play = play;
    _playTime = 0;
  }

  double _seconds(Duration d) => d.inMicroseconds / 1e6;

  void _think(double dt, List<BallEvent> events) {
    _playTime += dt;
    final toBall = (_ball - dino.position).distance;
    switch (_play) {
      case DinoPlay.noticing:
        dino.face(_ball);
        if (_playTime >= _seconds(noticeTime)) _setPlay(DinoPlay.chasing);
      case DinoPlay.chasing:
        _chase(toBall);
      case DinoPlay.liningUp:
        dino.face(_ball);
        if (toBall > strikeDistance + 0.3 || ballInAir) {
          _setPlay(DinoPlay.chasing);
        } else if (_playTime >= _seconds(lineUpTime) &&
            dino.angleTo(_ball) < 0.35) {
          _attackSerial++;
          _punchThrown = false;
          dino.stop();
          _setPlay(DinoPlay.attacking);
        }
      case DinoPlay.attacking:
        dino.stop();
        if (!_punchThrown && _playTime >= model.attackHitSeconds) {
          _punchThrown = true;
          if (!ballInAir &&
              toBall <= strikeDistance + 0.25 &&
              dino.angleTo(_ball) < 0.8) {
            _punch(events);
          }
        }
        final clip = model.clip(CompanionAnim.attack)?.seconds ?? 1;
        // Leave a little early: the crossfade covers the recovery.
        if (_playTime >= clip - 0.2) _setPlay(DinoPlay.watching);
      case DinoPlay.watching:
        dino.face(_ball);
        final settled = !ballInAir && ballSpeed < 1.5;
        if ((settled && _playTime >= 0.3) || _playTime >= _seconds(watchTime)) {
          _setPlay(DinoPlay.chasing);
        }
    }
  }

  /// The ball flies away: where the Dino faces, turned towards the open
  /// floor if that points at a nearby edge (so it doesn't just stop there).
  void _punch(List<BallEvent> events) {
    final spread = (_random.nextDouble() - 0.5) * 0.4;
    var dir = CompanionMovementController.forward(dino.heading + spread);
    final ahead = _ball + dir * 1.0;
    if (!ballBounds.contains(ahead)) {
      final toCentre = _area.center - _ball;
      if (toCentre.distance > 1e-6) {
        final mixed = dir + toCentre / toCentre.distance;
        if (mixed.distance > 1e-6) dir = mixed / mixed.distance;
      }
    }
    _finger = null; // it leaves the finger: bring it back!
    _velocity = dir * punchSpeed;
    _lift = punchLift;
    _height = 1e-4;
    _combo++;
    _hits++;
    _bestCombo = math.max(_bestCombo, _combo);
    events.add(BallHit(_combo));
  }

  void _chase(double toBall) {
    if (ballInAir) {
      dino.face(_ball);
      return;
    }
    // Where the ball will be by the time it gets there (roughly).
    final lead = math.min(0.5, toBall / model.runSpeed);
    final ball = ballBounds.clamp(_ball + _velocity * lead);
    final away = dino.position - ball;
    final dir = away.distance < 1e-6
        ? -CompanionMovementController.forward(dino.heading)
        : away / away.distance;
    // Stop in front of the ball, on the side it comes from.
    final spot = dinoBounds.clamp(ball + dir * strikeDistance);
    final toSpot = (spot - dino.position).distance;
    _running = _running ? toSpot > walkDistance : toSpot > runDistance;
    dino.moveTo(
      spot,
      gait: _running ? CompanionGait.run : CompanionGait.walk,
      arriveRadius: 0.06,
    );
    final inReach = toBall <= strikeDistance + 0.1 && dino.angleTo(_ball) < 0.6;
    // Slow enough to aim (a finger may be moving it).
    final calm = dino.speed < 0.5 && ballSpeed < 2;
    if (inReach && calm) {
      _running = false;
      dino.face(_ball);
      _setPlay(DinoPlay.liningUp);
    }
  }
}
