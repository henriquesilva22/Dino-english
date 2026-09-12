import 'dart:async' show unawaited;

import 'package:flame_audio/bgm.dart';
import 'package:flame_audio/flame_audio.dart';

import 'adventure_sfx.dart';

/// The custom background track, bundled separately from the Kenney SFX
/// pack (which lives under `assets/sprites/map/Sounds/`).
const String kBackgroundMusicAsset = 'melancholic_tronic_v2.mp3';

/// How `FlameAdventureSoundService` asks flame_audio to build one SFX's
/// reusable player pool -- injectable purely for tests, defaulting to
/// [FlameAudio.createPool] (a real, platform-channel-backed call).
typedef CreateAudioPool = Future<AudioPool> Function(String sound, {required int maxPlayers});

/// Pet Adventure's sound API. Extracted as an interface (mirroring
/// `SpeechService`/`FlutterTtsSpeechService`) so tests can fake it --
/// [FlameAdventureSoundService] eagerly constructs a real,
/// platform-channel-backed `AudioPlayer` merely by being instantiated
/// (via its `Bgm` field), so a subclass-based fake isn't viable the way a
/// plain `implements` fake of an abstract class is.
abstract interface class AdventureSoundService {
  Future<void> preload();
  void play(AdventureSfx sfx);

  /// Starts (or restarts) the looping background track. Fire-and-forget
  /// by design -- callers don't block gameplay start on the track being
  /// ready.
  void playMusic({double volume = 0.35});

  Future<void> stopMusic();
}

/// Thin wrapper over `FlameAudio` for Pet Adventure sound effects. Only
/// ever called from navigation/tap-reachable code (`PetAdventureGame`,
/// `PetSelectionScreen`) -- never from boot-time widgets -- so
/// `test/widget_test.dart` (which has no real platform audio plugin)
/// never touches it.
class FlameAdventureSoundService implements AdventureSoundService {
  FlameAdventureSoundService({CreateAudioPool? createPool})
    : _createPool = createPool ?? FlameAudio.createPool;

  /// A dedicated [Bgm] with its own `AudioCache` (prefix `assets/sounds/`)
  /// rather than `FlameAudio.bgm` (the shared singleton, whose prefix
  /// `main.dart` points at `assets/sprites/map/Sounds/` for the bundled
  /// Kenney SFX). Keeping this separate means starting/stopping music
  /// never has to swap that shared prefix out from under the SFX cache.
  final Bgm _bgm = Bgm(audioCache: AudioCache(prefix: 'assets/sounds/'));
  bool _bgmInitialized = false;

  final CreateAudioPool _createPool;

  /// One small, reusable player pool per SFX, instead of `FlameAudio
  /// .play()`'s "new `AudioPlayer` every call" default -- that leaked one
  /// permanently (3 `StreamSubscription`s + a native platform-channel
  /// registration, never released) on *every single* word-collect/shoot/
  /// hit event, i.e. many times per round, not just across replays.
  /// Sized generously (4) so simultaneous plays of the same sound rarely
  /// exceed pool capacity -- when they do, `AudioPool` releases the
  /// overflow player via `.release()`, not `.dispose()`, which still
  /// leaks its subscriptions; this reduces that residual case rather than
  /// eliminating it outright, since the package gives no stronger hook.
  final Map<AdventureSfx, AudioPool> _sfxPools = {};
  static const _maxPlayersPerSfx = 4;
  bool _sfxPoolsReady = false;

  @override
  Future<void> preload() async {
    await FlameAudio.audioCache.loadAll(
      AdventureSfx.values.map((s) => s.fileName).toList(),
    );
    // This service is an app-lifetime singleton but preload() is called
    // again on every new game session (PetAdventureGame.onLoad()) --
    // pools only need to be built once, ever.
    if (_sfxPoolsReady) return;
    _sfxPoolsReady = true;
    for (final sfx in AdventureSfx.values) {
      _sfxPools[sfx] = await _createPool(sfx.fileName, maxPlayers: _maxPlayersPerSfx);
    }
  }

  @override
  void play(AdventureSfx sfx) => unawaited(_sfxPools[sfx]?.start());

  @override
  void playMusic({double volume = 0.35}) {
    unawaited(_ensureBgmReady().then((_) => _bgm.play(kBackgroundMusicAsset, volume: volume)));
  }

  @override
  Future<void> stopMusic() => _bgm.stop();

  /// Registers [_bgm] as a `WidgetsBinding` observer (lazily, once) so it
  /// auto-pauses/resumes when the app is backgrounded/foregrounded --
  /// without this, the track would keep playing while the app is
  /// minimized.
  Future<void> _ensureBgmReady() async {
    if (_bgmInitialized) return;
    _bgmInitialized = true;
    await _bgm.initialize();
  }
}
