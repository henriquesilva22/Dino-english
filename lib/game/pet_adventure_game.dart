import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/database/app_database.dart';
import 'background/cloud_layer_component.dart';
import 'background/mountain_layer_component.dart';
import 'background/sky_component.dart';
import 'background/tree_layer_component.dart';
import 'boss_component.dart';
import 'boss_fight_state.dart';
import 'boss_projectile_component.dart';
import 'difficulty_config.dart';
import 'effects/collect_burst_component.dart';
import 'effects/floating_text_component.dart';
import 'ground_component.dart';
import 'level/adventure_level_layout.dart';
import 'level/platform_component.dart';
import 'minigame_round_state.dart';
import 'pet_component.dart';
import 'pets/boss_pet_selector.dart';
import 'pets/pet_catalog.dart';
import 'projectile_component.dart';
import 'sound/adventure_sfx.dart';
import 'sound/adventure_sound_service.dart';
import 'word_component.dart';
import 'word_spawner.dart';

/// Explicit lifecycle for one game session, checked before anything that
/// mutates gameplay state or plays audio. `starting` while `onLoad()` is
/// still in flight (real asset decoding -- can take real time); `running`
/// once it's done and the round is live; `ending` from the moment
/// [PetAdventureGame.endSession] is called (the single official way to
/// leave); `disposed` once Flame's own [PetAdventureGame.onRemove] fires.
///
/// This exists because `onLoad()`'s `await`s are plain Dart futures --
/// popping the route mid-load does NOT cancel them. Without this guard, a
/// exit-during-load resumes later and unconditionally starts music /
/// populates the world for a screen that's already gone.
enum GameSessionPhase { starting, running, ending, disposed }

/// The Pet Adventure minigame's [FlameGame]. Owns no persistence or
/// Riverpod knowledge -- it only reports collected words through the two
/// constructor callbacks, so the screen/provider layer decides what to do
/// with them (see `lib/providers/minigame_providers.dart`).
class PetAdventureGame extends FlameGame
    with HasCollisionDetection, TapCallbacks {
  PetAdventureGame({
    required this.pet,
    required this.correctWordPool,
    required this.onCollectCorrect,
    required this.onCollectIncorrect,
    required this.sound,
    this.isBossFight = false,
    this.onBossStateChanged,
    DifficultyConfig? difficulty,
    Random? random,
  }) : difficulty = difficulty ?? DifficultyConfig.standard(),
       _random = random ?? Random() {
    _logLifecycle('CREATED');
  }

  /// Debug-only instrumentation (per-session id + lifecycle log lines) so
  /// a real device run can be checked via `adb logcat` for exactly one
  /// session ever being active at a time -- never compiled into release
  /// builds via the [kDebugMode] guard.
  static int _nextSessionId = 0;
  final int sessionId = _nextSessionId++;

  void _logLifecycle(String event) {
    if (kDebugMode) {
      debugPrint('[GAME] Session #$sessionId $event');
    }
  }

  GameSessionPhase _phase = GameSessionPhase.starting;

  /// Read-only outside this class -- every mutation goes through
  /// `onLoad()`'s own transitions, [endSession], or [onRemove].
  GameSessionPhase get phase => _phase;

  final PetDefinition pet;
  final List<Word> correctWordPool;
  final DifficultyConfig difficulty;
  final void Function(Word word) onCollectCorrect;
  final VoidCallback onCollectIncorrect;
  final AdventureSoundService sound;
  final Random _random;

  /// Whether this round is the boss fight rather than the normal
  /// word-collecting round. Drives [bossState]/[activeDifficulty] and
  /// spawns [BossComponent] instead of the plain scenery.
  final bool isBossFight;

  /// Reports every boss HP change (including the killing blow) up to the
  /// screen/provider layer, mirroring [onCollectCorrect]/
  /// [onCollectIncorrect]'s "Flame is the source of truth, report out via
  /// callback" pattern. Carries the exact `damage` applied so the
  /// Riverpod-side `BossFightController` (which drives the HUD bar/
  /// victory detection) can apply the identical hit instead of
  /// recomputing its own -- otherwise the two independent `BossFightState`
  /// copies (this one, driving `BossComponent`/`activeDifficulty`; the
  /// Controller's, driving UI) would diverge now that damage varies by
  /// word difficulty instead of always being the same fixed amount.
  final void Function(BossFightState state, int damage)? onBossStateChanged;

  /// Non-null only in a boss fight. The boss's HP is a purely in-memory
  /// counter -- it never itself touches the database; only the final
  /// victory triggers a single `ProgressRepository.recordAnswer` call (see
  /// `BossFightController` in `minigame_providers.dart`), so no parallel
  /// XP/progress system is introduced.
  BossFightState? bossState;

  /// The active pacing config: the boss fight ramps up as its HP drops
  /// (see `DifficultyConfig.bossBand`), the normal round always uses
  /// [difficulty] unchanged.
  DifficultyConfig get activeDifficulty => bossState == null
      ? difficulty
      : DifficultyConfig.bossBand(bossState!.band);

  late final PetComponent dino;
  late final PetDefinition _bossPet;

  /// Minimum time between shots, so the shoot button can't be spammed
  /// into trivializing the incorrect-word threat entirely.
  static const double _shootCooldownDuration = 0.45;
  static const double _projectileSpeed = 620;
  double _shootCooldownRemaining = 0;

  /// The level's standing surfaces (ground + elevated platforms), rebuilt
  /// against the current screen size. Read by [PetComponent] (landing),
  /// [WordSpawner] (spawn heights) and [PlatformComponent] (visuals).
  late AdventureLevelLayout levelLayout;

  @override
  Color backgroundColor() => const Color(0xFF0B1020);

  @override
  void onGameResize(Vector2 size) {
    // Recomputed *before* calling super: FlameGame.onGameResize propagates
    // resize to already-loaded children synchronously as part of this same
    // call, so they must see the new layout, not the stale one.
    levelLayout = AdventureLevelLayout.standard(size);
    super.onGameResize(size);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    if (isBossFight) {
      bossState = const BossFightState();
      _bossPet = pickBossPet(pet);
    }

    // Preload every sprite the background/ground/pet layers need up
    // front -- GameWidget only renders after onLoad() resolves, so every
    // child component below can read Flame.images.fromCache(...)
    // synchronously.
    await Flame.images.loadAll([
      kCloudsBackgroundAsset,
      kHillsBackgroundAsset,
      ...kForegroundDecorationAssets,
      kGroundTileAsset,
      ...kPlatformAssets,
      pet.previewAsset,
      if (isBossFight) _bossPet.previewAsset,
    ]);
    // The route can be popped while any of the awaits above are still in
    // flight -- that doesn't cancel this coroutine (plain Dart futures
    // aren't cancellable), so it must re-check after every real await
    // before doing anything with a side effect. onRemove() sets _phase to
    // disposed synchronously, so this always observes the current value.
    if (_phase == GameSessionPhase.disposed) return;
    await sound.preload();
    if (_phase == GameSessionPhase.disposed) return;
    sound.playMusic();

    dino = PetComponent(difficulty: difficulty, pet: pet);
    final ground = GroundComponent()
      ..priority = -10
      ..scrollSpeed = difficulty.scrollSpeed;
    final elevatedPlatforms = levelLayout.platforms
        .where((p) => p.id != 'ground')
        .map((p) => PlatformComponent(spec: p)..priority = -5);

    if (_phase == GameSessionPhase.disposed) return;
    world.addAll([
      SkyComponent()..priority = -100,
      CloudLayerComponent()..priority = -90,
      MountainLayerComponent()..priority = -80,
      TreeLayerComponent()..priority = -20,
      ground,
      ...elevatedPlatforms,
      dino,
      WordSpawner(random: _random),
      if (isBossFight) BossComponent(pet: _bossPet)..priority = -1,
    ]);
    _phase = GameSessionPhase.running;
    _logLifecycle('STARTED');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shootCooldownRemaining > 0) {
      _shootCooldownRemaining -= dt;
    }
  }

  /// The single official way to end this session -- called BEFORE popping
  /// the route (not after), by every real exit path. Idempotent: safe to
  /// call more than once, and safe to call from a round-end listener even
  /// though the engine may already be paused.
  Future<void> endSession() async {
    if (_phase == GameSessionPhase.ending ||
        _phase == GameSessionPhase.disposed) {
      return;
    }
    _phase = GameSessionPhase.ending;
    _logLifecycle('ENDING');
    pauseEngine();
    await sound.stopMusic();
  }

  /// Flame-native safety net alongside the widget-level exit paths --
  /// fires on teardown regardless of what caused it. Only stops music
  /// here if [endSession] never ran for *this* instance (i.e. some path
  /// popped the route without going through it) -- otherwise a stale
  /// instance's unconditional stop could land after a newer "JOGAR
  /// NOVAMENTE" instance already started its own music, since both share
  /// one app-lifetime `Bgm`.
  @override
  void onRemove() {
    final endedProperly = _phase == GameSessionPhase.ending;
    _phase = GameSessionPhase.disposed;
    _logLifecycle('DISPOSED');
    if (!endedProperly) {
      unawaited(sound.stopMusic());
    }
    super.onRemove();
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (_phase != GameSessionPhase.running) return;
    dino.jump();
  }

  /// Quickly falls through the elevated platform the pet is currently
  /// standing on -- called from the HUD's descend button.
  void dropThrough() {
    if (_phase != GameSessionPhase.running) return;
    dino.dropThrough();
  }

  /// Fires a straight shot from wherever the pet currently is (works
  /// mid-jump too). Rate-limited by [_shootCooldownDuration]; called from
  /// the shoot button in `PetAdventureGameScreen`.
  void shoot() {
    if (_phase != GameSessionPhase.running) return;
    if (_shootCooldownRemaining > 0) return;
    _shootCooldownRemaining = _shootCooldownDuration;
    sound.play(AdventureSfx.shoot);
    world.add(
      ProjectileComponent(
        position: Vector2(
          dino.position.x + dino.size.x,
          dino.position.y - dino.size.y / 2,
        ),
        speed: _projectileSpeed,
      ),
    );
  }

  /// Called by [ProjectileComponent.onCollisionStart]. Only fires for
  /// incorrect words (see the guard there) -- knocking one out is pure
  /// avoidance, exactly like successfully jumping over one, so it awards
  /// no XP and never touches `ProgressRepository` (same as a word that
  /// simply scrolls off-screen untouched).
  void handleWordShot(WordComponent word, ProjectileComponent projectile) {
    if (_phase != GameSessionPhase.running) return;
    if (word.isRemoving) return;
    final center = word.position + Vector2(word.size.x / 2, -word.size.y / 2);
    word.removeFromParent();
    projectile.removeFromParent();
    world.add(CollectBurstComponent.impact(position: center, random: _random));
    sound.play(AdventureSfx.wordPop);
  }

  /// Called by [ProjectileComponent.onCollisionStart] when a shot lands on
  /// the boss instead of a word -- a second way to damage it besides
  /// collecting correct words, same damage amount for consistency.
  void handleBossShot(ProjectileComponent projectile) {
    if (_phase != GameSessionPhase.running) return;
    if (bossState == null || bossState!.isFinished || projectile.isRemoving) {
      return;
    }
    final center = projectile.position.clone();
    projectile.removeFromParent();
    world.add(CollectBurstComponent.impact(position: center, random: _random));
    sound.play(AdventureSfx.bossHit);
    _damageBoss(BossFightState.normalWordDamage);
  }

  /// Called by [BossProjectileComponent.onCollisionStart] when the boss's
  /// counter-attack lands on the player. Costs exactly one life through
  /// the same [onCollectIncorrect] path an incorrect word uses -- no
  /// separate life-loss mechanism.
  void handleBossProjectileHit(BossProjectileComponent projectile) {
    if (_phase != GameSessionPhase.running) return;
    if (projectile.isRemoving) return;
    final center = projectile.position.clone();
    projectile.removeFromParent();
    world.add(CollectBurstComponent.impact(position: center, random: _random));
    dino.reactToIncorrect();
    sound.play(AdventureSfx.incorrect);
    unawaited(HapticFeedback.mediumImpact());
    onCollectIncorrect();
  }

  /// Called by [PetComponent.onCollisionStart]. Centralizes the
  /// double-collection guard: a word already being removed this frame is
  /// ignored instead of firing its callback twice.
  void handleWordCollected(WordComponent word) {
    if (_phase != GameSessionPhase.running) return;
    if (word.isRemoving) return;
    final isCorrect = word.isCorrect;
    // anchor is bottomLeft: `position` is the world-space bottom-left
    // corner (Y grows downward), so the box's top is `position.y -
    // size.y` -- the same sign convention already fixed on the pet.
    final center = word.position + Vector2(word.size.x / 2, -word.size.y / 2);
    word.removeFromParent();

    if (isCorrect) {
      world.add(
        CollectBurstComponent.sparkle(position: center, random: _random),
      );
      world.add(
        FloatingTextComponent(
          text: '+${MinigameRoundState.xpPerCorrectWord} XP',
          position: center,
          color: const Color(0xFF00E5FF),
        ),
      );
      dino.reactToCorrect();
      sound.play(AdventureSfx.correct);
      onCollectCorrect(word.word!);
      _damageBoss(
        BossFightState.damageForWordDifficulty(word.word!.difficulty),
      );
    } else {
      world.add(
        CollectBurstComponent.impact(position: center, random: _random),
      );
      dino.reactToIncorrect();
      sound.play(AdventureSfx.incorrect);
      unawaited(HapticFeedback.mediumImpact());
      onCollectIncorrect();
    }
  }

  void _damageBoss(int damage) {
    if (bossState == null) return;
    bossState = bossState!.hit(damage: damage);
    onBossStateChanged?.call(bossState!, damage);
  }
}
