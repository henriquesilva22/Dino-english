import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/orientation_lock.dart';
import '../game/word_slash/word_slash_session_state.dart';
import '../providers/word_slash_providers.dart';
import '../theme/neon_colors.dart';
import '../widgets/word_slash/word_slash_bubble_widget.dart';
import '../widgets/word_slash/word_slash_round_result_overlay.dart';

class WordSlashGameScreen extends ConsumerStatefulWidget {
  const WordSlashGameScreen({super.key});

  @override
  ConsumerState<WordSlashGameScreen> createState() =>
      _WordSlashGameScreenState();
}

/// Locks landscape for as long as this screen is on top, restoring
/// portrait on the way out -- the same mechanism (including the
/// generation counter guarding a rapid re-entry against an old screen's
/// animation-delayed `dispose()`) already proven for
/// `_PetAdventureGameScreenState` in `pet_adventure_game_screen.dart`.
class _WordSlashGameScreenState extends ConsumerState<WordSlashGameScreen> {
  static int _lockGeneration = 0;
  late final int _myGeneration;

  @override
  void initState() {
    super.initState();
    _myGeneration = ++_lockGeneration;
    unawaited(
      SystemChrome.setPreferredOrientations(kGameLandscapeOrientations),
    );
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }

  @override
  void dispose() {
    if (_lockGeneration == _myGeneration) {
      unawaited(
        SystemChrome.setPreferredOrientations(kAppPortraitOrientations),
      );
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  /// What the Android system back button/gesture runs -- stop everything
  /// (via the controller's centralized `endSession()`), *then* leave.
  /// `canPop: false` plus this `if (didPop) return;` guard are both
  /// required: `NavigatorState.pop()` (called at the bottom here)
  /// re-invokes this exact callback synchronously as part of completing
  /// the pop -- without the guard, that second invocation would re-run the
  /// cleanup and pop a second time (same reentrancy hazard already found
  /// and fixed for Pet Adventure's identical `_handlePop`).
  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    await ref.read(wordSlashControllerProvider.notifier).endSession();
    unawaited(SystemChrome.setPreferredOrientations(kAppPortraitOrientations));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: const Scaffold(
        backgroundColor: NeonColors.background,
        body: _WordSlashPlayArea(),
      ),
    );
  }
}

class _WordSlashPlayArea extends ConsumerStatefulWidget {
  const _WordSlashPlayArea();

  @override
  ConsumerState<_WordSlashPlayArea> createState() => _WordSlashPlayAreaState();
}

class _WordSlashPlayAreaState extends ConsumerState<_WordSlashPlayArea>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  Offset? _lastPanPoint;
  Size _areaSize = Size.zero;
  final List<Offset> _trailPoints = [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  /// The single per-frame entry point into gameplay. Reads the controller
  /// fresh via `ref.read` every call rather than caching a reference --
  /// safe because `ref.read` from a still-mounted `ConsumerState` always
  /// resolves through the live `ProviderContainer`, so it can only ever
  /// reach the *current* legitimate instance. What actually makes a late
  /// tick harmless once the player has left is
  /// `WordSlashController.tick`'s own `sessionPhase != running` guard, not
  /// anything about how this reference is obtained -- the `Ticker` itself
  /// mechanically keeps firing for a little while after `endSession()`
  /// (this widget's exit paths always call that before popping), exactly
  /// the same ~300ms animation-gated `dispose()` window already documented
  /// for Pet Adventure.
  void _onTick(Duration elapsed) {
    final dt = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    if (dt <= Duration.zero) return;
    ref.read(wordSlashControllerProvider.notifier).tick(dt, _areaSize);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// The single official way this screen leaves the game via an explicit
  /// button (HUD ✕, round-result "SAIR") rather than the system back
  /// gesture: end the session (awaited, so it's actually done first),
  /// restore portrait eagerly, then pop. Deliberately does NOT call
  /// `Navigator.pop()` and rely on the `PopScope` above to react --
  /// `NavigatorState.pop()` is unconditional and invokes
  /// `onPopInvokedWithResult` with `didPop` already `true`, so relying on
  /// that path here would skip `_handlePop`'s cleanup entirely (the same
  /// bypass already found and fixed for Pet Adventure's HUD exit button).
  void _exitGame() {
    unawaited(_exitGameAsync());
  }

  Future<void> _exitGameAsync() async {
    await ref.read(wordSlashControllerProvider.notifier).endSession();
    unawaited(SystemChrome.setPreferredOrientations(kAppPortraitOrientations));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    if (mounted) Navigator.of(context).pop();
  }

  void _onPanStart(DragStartDetails details) {
    _lastPanPoint = details.localPosition;
    _trailPoints
      ..clear()
      ..add(details.localPosition);
    setState(() {});
    ref.read(wordSlashControllerProvider.notifier).beginSwipe();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final previous = _lastPanPoint;
    _lastPanPoint = details.localPosition;
    _trailPoints.add(details.localPosition);
    if (_trailPoints.length > 14) _trailPoints.removeAt(0);
    setState(() {});
    if (previous == null) return;
    ref
        .read(wordSlashControllerProvider.notifier)
        .registerSwipeSegment(previous, details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _lastPanPoint = null;
    _trailPoints.clear();
    setState(() {});
    ref.read(wordSlashControllerProvider.notifier).endSwipe();
  }

  void _onPanCancel() {
    _lastPanPoint = null;
    _trailPoints.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wordSlashControllerProvider);
    final isLoading = state.roundTimeRemaining == null;

    return Stack(
      children: [
        Positioned.fill(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    _areaSize = constraints.biggest;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      onPanCancel: _onPanCancel,
                      child: CustomPaint(
                        painter: _SwipeTrailPainter(_trailPoints),
                        child: Stack(
                          children: [
                            for (final bubble in state.bubbles)
                              Positioned(
                                left: bubble.position.dx - bubble.radius,
                                top: bubble.position.dy - bubble.radius,
                                child: WordSlashBubbleWidget(
                                  bubble: bubble,
                                  isHit:
                                      bubble.id == state.selectedBubbleId ||
                                      state.swipeHitBubbleIds.contains(
                                        bubble.id,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: _WordSlashTopBar(state: state, onExit: _exitGame),
          ),
        ),
        if (state.isRoundComplete)
          Positioned.fill(
            child: WordSlashRoundResultOverlay(
              state: state,
              onContinue: () {
                final notifier = ref.read(wordSlashControllerProvider.notifier);
                if (state.isFinalRound) {
                  notifier.restartRun();
                } else {
                  notifier.advanceRound();
                }
              },
              onExit: _exitGame,
            ),
          ),
      ],
    );
  }
}

/// Fase/timer/score/combo readout plus the explicit exit button -- kept
/// minimal per spec ("não exagere inicialmente").
class _WordSlashTopBar extends StatelessWidget {
  const _WordSlashTopBar({required this.state, required this.onExit});

  final WordSlashSessionState state;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final seconds = (state.roundTimeRemaining ?? Duration.zero).inSeconds;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onExit,
            icon: const Icon(Icons.close, color: NeonColors.textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: NeonColors.surface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 12),
          _TopBarChip(
            label: 'FASE ${state.roundNumber}',
            color: NeonColors.purple,
          ),
          const SizedBox(width: 10),
          _TopBarChip(label: '⏱ ${seconds}s', color: NeonColors.cyan),
          const SizedBox(width: 10),
          _TopBarChip(label: 'SCORE ${state.score}', color: NeonColors.orange),
          if (state.combo > 1) ...[
            const SizedBox(width: 10),
            _TopBarChip(
              label: 'COMBO x${state.combo}',
              color: NeonColors.green,
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _TopBarChip extends StatelessWidget {
  const _TopBarChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: NeonColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Minimal "feedback visual" for the cut gesture -- a fading trail of the
/// last few drag points, per spec's explicitly-allowed (and
/// explicitly-not-required-to-exceed) "linha/rastro do dedo". Deliberately
/// simple: no particles/explosion effects in this first version.
class _SwipeTrailPainter extends CustomPainter {
  const _SwipeTrailPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = NeonColors.cyan.withValues(alpha: 0.8)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < points.length; i++) {
      paint.color = NeonColors.cyan.withValues(
        alpha: 0.15 + 0.6 * (i / points.length),
      );
      canvas.drawLine(points[i - 1], points[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SwipeTrailPainter oldDelegate) => true;
}
