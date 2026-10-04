import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../core/companion/model/companion_model.dart';
import '../../core/companion/play/ball_game_controller.dart';
import '../../core/companion/play/floor_projection.dart';
import '../../theme/neon_colors.dart';

/// Builds the companion's 3D view for the current frame of [game] (its
/// clip, heading and clip speed come from the game).
typedef BallArenaDinoBuilder =
    Widget Function(BuildContext context, BallGameController game);

/// The "Brincar" game: the ⚽ follows the child's finger on the floor; the
/// Dino chases it, walking or running, and punches it far away -- and the
/// child brings it back. Draws [BallGameController] through a
/// [FloorProjection]: the Dino's feet and the ball sit on the same floor,
/// whatever is closer to the child is drawn in front.
class BallArena extends StatefulWidget {
  const BallArena({
    required this.model,
    required this.dinoSize,
    required this.dinoBuilder,
    required this.onHit,
    required this.onStopped,
    required this.onFinish,
    super.key,
  });

  final CompanionModel model;

  /// Size of the square 3D view at the front of the floor.
  final double dinoSize;
  final BallArenaDinoBuilder dinoBuilder;

  /// The Dino hit the ball ([combo] in a row).
  final ValueChanged<int> onHit;
  final ValueChanged<int> onStopped;

  /// "Parar": hits, best combo, time played.
  final void Function(int hits, int bestCombo, Duration played) onFinish;

  @override
  State<BallArena> createState() => _BallArenaState();
}

class _BallArenaState extends State<BallArena>
    with SingleTickerProviderStateMixin {
  late final BallGameController _game = BallGameController(model: widget.model);
  final Stopwatch _played = Stopwatch()..start();
  late final Ticker _ticker;
  FloorProjection? _projection;
  Duration _last = Duration.zero;
  double _spin = 0;
  int? _pointer;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (_projection == null) return;
    for (final event in _game.step(dt)) {
      switch (event) {
        case BallHit(:final combo):
          HapticFeedback.lightImpact();
          widget.onHit(combo);
        case BallStopped(:final lostCombo):
          widget.onStopped(lostCombo);
        case BallLanded():
          break;
      }
    }
    _spin += _game.ballVelocity.dx * dt / BallGameController.ballRadius;
    setState(() {});
  }

  FloorProjection _fit(Size size) {
    final p = _projection;
    if (p != null && p.arena == size && p.dinoBox == widget.dinoSize) return p;
    final fitted = FloorProjection.fit(
      arena: size,
      dinoBox: widget.dinoSize,
      model: widget.model,
    );
    _game.resize(fitted.bounds);
    return _projection = fitted;
  }

  /// Ball centre and radius on screen (lifted while it flies).
  (Offset, double) _ballOnScreen(FloorProjection p) {
    final at = _game.ballPosition;
    final floor = p.toScreen(at);
    final ppm = p.ppmAt(at.dy);
    final r = BallGameController.ballRadius * ppm;
    return (floor - Offset(0, r + _game.ballHeight * ppm), r);
  }

  // One finger leads the ball: down = the ball comes, move = it follows,
  // up = it rolls on.
  void _down(PointerDownEvent e) {
    final p = _projection;
    if (p == null || _pointer != null) return;
    _pointer = e.pointer;
    _game.grab(p.toWorld(e.localPosition));
  }

  void _move(PointerMoveEvent e) {
    final p = _projection;
    if (p == null || e.pointer != _pointer) return;
    _game.drag(p.toWorld(e.localPosition));
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _game.release();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final p = _fit(constraints.biggest);
        final (centre, r) = _ballOnScreen(p);
        final ballFloor = p.toScreen(_game.ballPosition);
        final dinoAt = _game.dino.position;
        final dinoFloor = p.toScreen(dinoAt);
        final feet = widget.model.camera.feetFraction;
        final size = widget.dinoSize;

        final shadow = Positioned(
          left: ballFloor.dx - r * 1.1,
          top: ballFloor.dy - r * 0.28,
          child: IgnorePointer(
            child: Container(
              width: r * 2.2,
              height: r * 0.56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(r, r * 0.3)),
                gradient: const RadialGradient(
                  colors: [Color(0x66000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        );
        final ball = Positioned(
          key: const ValueKey('ball-layer'),
          left: centre.dx - r,
          top: centre.dy - r,
          child: IgnorePointer(
            child: SizedBox.square(
              dimension: r * 2,
              child: FittedBox(
                child: Transform.rotate(
                  angle: _spin,
                  child: const Text(
                    '⚽',
                    key: ValueKey('game-ball'),
                    style: TextStyle(fontSize: 64, height: 1),
                  ),
                ),
              ),
            ),
          ),
        );
        final dino = Positioned(
          key: const ValueKey('dino-layer'),
          left: dinoFloor.dx - size / 2,
          top: dinoFloor.dy - feet * size,
          child: IgnorePointer(
            child: Transform.scale(
              scale: p.scaleAt(dinoAt.dy),
              alignment: Alignment(0, feet * 2 - 1),
              child: widget.dinoBuilder(context, _game),
            ),
          ),
        );
        // Closer to the child = drawn on top.
        final ballInFront = _game.ballPosition.dy > dinoAt.dy;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: SizedBox.expand()),
            shadow,
            if (ballInFront) ...[dino, ball] else ...[ball, dino],
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _down,
                onPointerMove: _move,
                onPointerUp: _up,
                onPointerCancel: _up,
              ),
            ),
            Positioned(
              left: 12,
              top: 8,
              child: _Hud(
                combo: _game.combo,
                hits: _game.hits,
                hint: _game.hits == 0,
              ),
            ),
            Positioned(
              right: 8,
              top: 4,
              child: FilledButton.tonal(
                onPressed: () => widget.onFinish(
                  _game.hits,
                  _game.bestCombo,
                  _played.elapsed,
                ),
                child: const Text('Parar ✋'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.combo, required this.hits, required this.hint});

  final int combo;
  final int hits;
  final bool hint;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: NeonColors.textPrimary,
      fontWeight: FontWeight.w900,
      fontSize: 16,
      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hint)
          const Text(
            'Arraste a bola! 👆',
            style: TextStyle(
              color: NeonColors.orange,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              shadows: [Shadow(color: Colors.black, blurRadius: 6)],
            ),
          )
        else ...[
          Text('⚽ $hits', style: style),
          AnimatedScale(
            scale: combo >= 5 ? 1.2 : 1,
            duration: const Duration(milliseconds: 150),
            child: Text(
              combo > 1 ? '🔥 x$combo' : '',
              style: style.copyWith(color: NeonColors.orange),
            ),
          ),
        ],
      ],
    );
  }
}
