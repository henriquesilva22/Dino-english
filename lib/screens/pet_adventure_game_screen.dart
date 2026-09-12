import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/orientation_lock.dart';
import '../game/boss_fight_state.dart';
import '../game/minigame_round_state.dart';
import '../game/pet_adventure_game.dart';
import '../game/sound/adventure_sfx.dart';
import '../game/sound/adventure_sound_service.dart';
import '../providers/minigame_providers.dart';
import '../providers/pet_adventure_providers.dart';
import '../theme/neon_colors.dart';
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
class _PetAdventureGameScreenState extends ConsumerState<PetAdventureGameScreen> {
  static int _lockGeneration = 0;
  late final int _myGeneration;

  /// Set by `_PetAdventurePlayAreaState` once it creates its game --
  /// still null while `poolAsync` is loading (nothing to end yet then).
  PetAdventureGame? _activeGame;

  @override
  void initState() {
    super.initState();
    _myGeneration = ++_lockGeneration;
    unawaited(SystemChrome.setPreferredOrientations(kGameLandscapeOrientations));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
  }

  @override
  void dispose() {
    if (_lockGeneration == _myGeneration) {
      unawaited(SystemChrome.setPreferredOrientations(kAppPortraitOrientations));
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
      unawaited(SystemChrome.setPreferredOrientations(kAppPortraitOrientations));
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

class _PetAdventurePlayAreaState
    extends ConsumerState<_PetAdventurePlayArea> {
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
              ref.read(bossFightControllerProvider.notifier).hit(damage: damage),
            )
          : null,
    );
    widget.onGameCreated(_game);
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
      ref.listen<BossFightState>(bossFightControllerProvider, (
        previous,
        next,
      ) {
        if (next.isFinished && (previous == null || !previous.isFinished)) {
          unawaited(_game.endSession());
          _sound.play(AdventureSfx.roundEnd);
        }
      });
    }
    final isGameOver = ref.watch(
      minigameControllerProvider.select((s) => s.isGameOver),
    );
    final bossVictory = widget.isBossFight &&
        ref.watch(bossFightControllerProvider.select((s) => s.isFinished));

    // Every direct Stack child must be Positioned: a Stack with even one
    // non-positioned child sizes *itself* to that child's intrinsic size
    // (here, the HUD's thin top bar) instead of filling the Scaffold --
    // which was squashing the whole game into a ~110px strip.
    return Stack(
      children: [
        Positioned.fill(child: GameWidget(game: _game)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: MinigameHud(
            isBossFight: widget.isBossFight,
            onExit: () => unawaited(_exitGame()),
          ),
        ),
        if (!isGameOver && !bossVictory) ...[
          Positioned(
            right: 20,
            bottom: 28,
            child: _ShootButton(onShoot: _game.shoot),
          ),
          Positioned(
            left: 20,
            bottom: 28,
            child: _DropThroughButton(onDrop: _game.dropThrough),
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

/// Bottom-left control that makes the pet quickly drop through the
/// elevated platform it's currently standing on. Placed opposite the
/// shoot button for comfortable two-thumb landscape play.
class _DropThroughButton extends StatelessWidget {
  const _DropThroughButton({required this.onDrop});

  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onDrop,
      child: NeonBorder(
        color: NeonColors.purple,
        radius: 32,
        child: Container(
          width: 64,
          height: 64,
          color: NeonColors.surface.withValues(alpha: 0.75),
          alignment: Alignment.center,
          child: const Text('⬇️', style: TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}
