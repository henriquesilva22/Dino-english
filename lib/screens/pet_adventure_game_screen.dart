import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/companion/animation/companion_animation_controller.dart';
import '../core/companion/companion_state_machine.dart';
import '../core/companion/model/companion_model.dart';
import '../core/database/app_database.dart';
import '../core/orientation_lock.dart';
import '../game/boss_fight_state.dart';
import '../game/minigame_round_state.dart';
import '../game/pet_adventure_game.dart';
import '../game/pet_component.dart';
import '../game/sound/adventure_sfx.dart';
import '../game/sound/adventure_sound_service.dart';
import '../providers/minigame_providers.dart';
import '../providers/pet_adventure_providers.dart';
import '../theme/neon_colors.dart';
import '../widgets/companion/dino_animated_model.dart';
import '../widgets/home/tap_scale.dart';
import '../widgets/minigame_game_over_overlay.dart';
import '../widgets/minigame_hud.dart';
import '../widgets/minigame_victory_overlay.dart';
import '../widgets/neon_border.dart';

class PetAdventureGameScreen extends ConsumerStatefulWidget {
  const PetAdventureGameScreen({this.isBossFight = false, super.key});

  final bool isBossFight;

  @override
  ConsumerState<PetAdventureGameScreen> createState() =>
      _PetAdventureGameScreenState();
}

/// Locks the device into landscape (and hides the system UI) for as long as
/// this screen is on top, restoring the app's normal portrait/edge-to-edge
/// state on the way out.
///
/// Generation counter guards against "JOGAR NOVAMENTE": that flow uses
/// `Navigator.pushReplacement`, so the *new* screen's [initState] (which
/// re-locks landscape) runs before the *old* screen's [dispose] (which only
/// fires once its exit animation finishes) -- an unconditional restore in
/// dispose would un-lock landscape while the new screen is still active.
class _PetAdventureGameScreenState
    extends ConsumerState<PetAdventureGameScreen> {
  static int _lockGeneration = 0;
  late final int _myGeneration;

  /// Set by `_PetAdventurePlayAreaState` once it creates its game --
  /// still null while `poolAsync` is loading (nothing to end yet then).
  PetAdventureGame? _activeGame;

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

  /// What the Android system back button/gesture runs -- the same
  /// "stop everything, then leave" ordering the explicit exit button
  /// uses, instead of relying solely on the delayed dispose()-triggered
  /// cleanup (which only fires once the pop's exit *animation* finishes,
  /// ~300ms later -- confirmed against Flutter's own route/transition
  /// source: dispose() is not synchronous with pop()).
  ///
  /// `canPop: false` + this `if (didPop) return;` guard are both
  /// required, not optional: `NavigatorState.pop()` (called at the
  /// bottom here) re-invokes this exact callback synchronously as part
  /// of completing the pop -- without the guard, that second invocation
  /// would re-run the cleanup and call pop() a second time.
  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    final game = _activeGame;
    if (game != null) {
      await game.endSession();
      unawaited(
        SystemChrome.setPreferredOrientations(kAppPortraitOrientations),
      );
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final poolAsync = ref.watch(minigameWordPoolProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        backgroundColor: NeonColors.background,
        body: poolAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Não foi possível carregar as palavras: $error',
              style: const TextStyle(color: NeonColors.textPrimary),
            ),
          ),
          data: (words) => _PetAdventurePlayArea(
            correctWordPool: words,
            isBossFight: widget.isBossFight,
            onGameCreated: (game) => _activeGame = game,
          ),
        ),
      ),
    );
  }
}

class _PetAdventurePlayArea extends ConsumerStatefulWidget {
  const _PetAdventurePlayArea({
    required this.correctWordPool,
    required this.isBossFight,
    required this.onGameCreated,
  });

  final List<Word> correctWordPool;
  final bool isBossFight;
  final ValueChanged<PetAdventureGame> onGameCreated;

  @override
  ConsumerState<_PetAdventurePlayArea> createState() =>
      _PetAdventurePlayAreaState();
}

class _PetAdventurePlayAreaState extends ConsumerState<_PetAdventurePlayArea> {
  late final PetAdventureGame _game;
  late final AdventureSoundService _sound;

  @override
  void initState() {
    super.initState();
    _sound = ref.read(adventureSoundServiceProvider);
    // Round state (lives/score/boss HP) is reset by the *caller* --
    // whichever button navigated here -- via `resetMinigameState`, before
    // this screen is pushed. Doing it here instead used to crash with
    // "setState() called during build": see `resetMinigameState`'s doc
    // comment in `minigame_providers.dart` for why.
    final pet = selectedPetOrFallback(ref.read(selectedPetIdProvider));
    _game = PetAdventureGame(
      pet: pet,
      correctWordPool: widget.correctWordPool,
      sound: _sound,
      isBossFight: widget.isBossFight,
      onCollectCorrect: (word) => unawaited(
        ref.read(minigameControllerProvider.notifier).collectCorrectWord(word),
      ),
      onCollectIncorrect: () => unawaited(
        ref.read(minigameControllerProvider.notifier).collectIncorrectWord(),
      ),
      onBossStateChanged: widget.isBossFight
          ? (_, damage) => unawaited(
              ref
                  .read(bossFightControllerProvider.notifier)
                  .hit(damage: damage),
            )
          : null,
    );
    widget.onGameCreated(_game);
  }

  /// Shots fired (the 3D Dino punches with each) and when the last one was.
  int _shotSerial = 0;
  DateTime _shotAt = DateTime(0);

  void _shoot() {
    if (!_game.shoot()) return;
    setState(() {
      _shotSerial++;
      _shotAt = DateTime.now();
    });
  }

  /// The single official way this screen leaves the game: end the
  /// session (pauses, stops music -- awaited, so it's actually done
  /// before anything else happens), restore portrait eagerly (don't rely
  /// only on the delayed dispose()-triggered restore), then pop. Used by
  /// the HUD's ✕ button and both post-round overlays' "VOLTAR PARA HOME".
  Future<void> _exitGame() async {
    await _game.endSession();
    unawaited(SystemChrome.setPreferredOrientations(kAppPortraitOrientations));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MinigameRoundState>(minigameControllerProvider, (
      previous,
      next,
    ) {
      if (next.isGameOver && (previous == null || !previous.isGameOver)) {
        // endSession() covers the pause+stop-music this used to do
        // manually -- same centralized path every other exit uses, which
        // also closes the "still-spawning/still-damageable while the
        // overlay is up" window via PetAdventureGame's phase guards.
        unawaited(_game.endSession());
        _sound.play(AdventureSfx.roundEnd);
      }
    });
    if (widget.isBossFight) {
      ref.listen<BossFightState>(bossFightControllerProvider, (previous, next) {
        if (next.isFinished && (previous == null || !previous.isFinished)) {
          unawaited(_game.endSession());
          _sound.play(AdventureSfx.roundEnd);
        }
      });
    }
    final isGameOver = ref.watch(
      minigameControllerProvider.select((s) => s.isGameOver),
    );
    final bossVictory =
        widget.isBossFight &&
        ref.watch(bossFightControllerProvider.select((s) => s.isFinished));

    // Every direct Stack child must be Positioned: a Stack with even one
    // non-positioned child sizes *itself* to that child's intrinsic size
    // (here, the HUD's thin top bar) instead of filling the Scaffold --
    // which was squashing the whole game into a ~110px strip.
    final playing = !isGameOver && !bossVictory;
    // The pet moves only with ⬆️/⬇️ (buttons or arrow keys); touching the
    // game itself does nothing.
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _game.moveUp();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _game.moveDown();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: _playArea(isGameOver, bossVictory, playing),
    );
  }

  Widget _playArea(bool isGameOver, bool bossVictory, bool playing) {
    final pet = _game.pet;
    return Stack(
      children: [
        Positioned.fill(child: GameWidget(game: _game, autofocus: false)),
        if (pet.companionModel case final model?)
          Positioned.fill(
            child: _Dino3DRunner(
              game: _game,
              model: model,
              playing: playing,
              shotSerial: _shotSerial,
              shotAt: _shotAt,
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: MinigameHud(
            isBossFight: widget.isBossFight,
            onExit: () => unawaited(_exitGame()),
          ),
        ),
        if (playing) ...[
          Positioned(
            right: 20,
            bottom: 28,
            child: _ShootButton(onShoot: _shoot),
          ),
          Positioned(
            left: 16,
            bottom: 20,
            child: _LaneArrows(onUp: _game.moveUp, onDown: _game.moveDown),
          ),
        ],
        if (bossVictory)
          Positioned.fill(
            child: MinigameVictoryOverlay(
              game: _game,
              isBossFight: widget.isBossFight,
              onExit: _exitGame,
            ),
          )
        else if (isGameOver)
          Positioned.fill(
            child: MinigameGameOverOverlay(
              game: _game,
              isBossFight: widget.isBossFight,
              onExit: _exitGame,
            ),
          ),
      ],
    );
  }
}

/// Bottom-right control that fires a shot to knock out an incoming
/// incorrect word from a distance -- an alternative to jumping over it.
/// Sits on top of the [GameWidget] in paint order, so tapping it doesn't
/// also register as a jump tap on the game canvas underneath.
class _ShootButton extends StatelessWidget {
  const _ShootButton({required this.onShoot});

  final VoidCallback onShoot;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onShoot,
      child: NeonBorder(
        color: NeonColors.cyan,
        radius: 32,
        child: Container(
          width: 64,
          height: 64,
          color: NeonColors.surface.withValues(alpha: 0.75),
          alignment: Alignment.center,
          child: const Text('🎯', style: TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}

/// The only controls that move the pet: ⬆️ (one lane up) and ⬇️
/// (one lane down), stacked bottom-left, big enough for little
/// thumbs, opposite the shoot button. React on touch-down: no waiting for
/// the finger to lift.
class _LaneArrows extends StatelessWidget {
  const _LaneArrows({required this.onUp, required this.onDown});

  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowButton(
          key: const ValueKey('lane-up'),
          label: '⬆️',
          onPressed: onUp,
        ),
        const SizedBox(height: 12),
        _ArrowButton(
          key: const ValueKey('lane-down'),
          label: '⬇️',
          onPressed: onDown,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _set(true);
        widget.onPressed();
      },
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 90),
        child: NeonBorder(
          color: NeonColors.purple,
          radius: 36,
          child: Container(
            width: 72,
            height: 72,
            color: NeonColors.surface.withValues(alpha: 0.75),
            alignment: Alignment.center,
            child: Text(widget.label, style: const TextStyle(fontSize: 34)),
          ),
        ),
      ),
    );
  }
}

/// The player's 3D Dino drawn over the game where its (invisible) Flame
/// body is: running on its lane facing right, hopping between lanes,
/// punching with every shot -- the same model and animation layer as the
/// companion screen ([CompanionAnimationController]).
class _Dino3DRunner extends StatelessWidget {
  const _Dino3DRunner({
    required this.game,
    required this.model,
    required this.playing,
    required this.shotSerial,
    required this.shotAt,
  });

  final PetAdventureGame game;
  final CompanionModel model;
  final bool playing;
  final int shotSerial;
  final DateTime shotAt;

  /// Facing right: where the words come from.
  static const double _yaw = 90;

  CompanionClipPlan _plan(PetPose pose) {
    final animations = CompanionAnimationController(model);
    if (!playing) return animations.plan(CompanionActivity.idle);
    if (pose.changingLane) {
      // The hop fits the lane change.
      final jump = model.clip(CompanionAnim.jump)?.seconds ?? 1;
      final scale = (jump / game.difficulty.laneChangeSeconds).clamp(1.0, 2.0);
      return animations.plan(
        CompanionActivity.jumping,
        rest: CompanionActivity.running,
        timeScale: (scale * 10).round() / 10,
        serial: pose.laneSerial,
      );
    }
    final attack = model.clip(CompanionAnim.attack)?.seconds ?? 1;
    final sinceShot = DateTime.now().difference(shotAt).inMilliseconds / 1000;
    if (sinceShot < attack) {
      return animations.plan(
        CompanionActivity.attacking,
        rest: CompanionActivity.running,
        serial: shotSerial,
      );
    }
    return animations.plan(CompanionActivity.running);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final view = PetComponent.viewSizeFor(
            Vector2(constraints.maxWidth, constraints.maxHeight),
          );
          final feet = model.camera.feetFraction;
          return ValueListenableBuilder<PetPose?>(
            valueListenable: game.petPose,
            builder: (context, pose, _) {
              if (pose == null) return const SizedBox.shrink();
              return Stack(
                children: [
                  Positioned(
                    left: pose.feet.dx - view / 2,
                    top: pose.feet.dy - view * feet,
                    child: DinoAnimatedModel(
                      model: model,
                      size: view,
                      plan: _plan(pose),
                      yaw: _yaw,
                      playing: true,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
