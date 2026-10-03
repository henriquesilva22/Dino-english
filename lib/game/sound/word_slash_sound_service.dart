import 'dart:async' show unawaited;

import 'package:flame_audio/flame_audio.dart';

import 'word_slash_sfx.dart';

/// How `WordSlashSoundService` asks flame_audio to build one SFX's
/// reusable player pool -- injectable purely for tests, defaulting to
/// [FlameAudio.createPool] (a real, platform-channel-backed call). Mirrors
/// `AdventureSoundService`'s `CreateAudioPool` typedef exactly.
typedef CreateAudioPool =
    Future<AudioPool> Function(String sound, {required int maxPlayers});

/// Word Slash's sound API -- its own small interface/impl pair rather than
/// literally sharing `AdventureSoundService` (a different sound
/// catalog/instance would be needed either way), but copying its exact,
/// already-proven shape: `AudioPool` per effect instead of `FlameAudio
/// .play()`'s "new `AudioPlayer` every call" (which leaked one
/// permanently -- see `AdventureSoundService`'s doc comment for the full
/// story). No background music in v1 -- it was explicitly conditional in
/// the product spec ("se adicionarmos música"), deferred to keep this
/// first version focused on the mechanic.
abstract interface class WordSlashSoundService {
  Future<void> preload();
  void play(WordSlashSfx sfx);
}

class FlameWordSlashSoundService implements WordSlashSoundService {
  FlameWordSlashSoundService({CreateAudioPool? createPool})
    : _createPool = createPool ?? FlameAudio.createPool;

  final CreateAudioPool _createPool;
  final Map<WordSlashSfx, AudioPool> _pools = {};

  /// Sized like `AdventureSoundService`'s SFX pools -- generous enough
  /// that simultaneous plays of the same sound rarely exceed capacity.
  static const _maxPlayersPerSfx = 4;
  bool _poolsReady = false;

  @override
  Future<void> preload() async {
    await FlameAudio.audioCache.loadAll(
      WordSlashSfx.values.map((s) => s.fileName).toList(),
    );
    // This service is expected to live for the whole play session but
    // preload() may be called more than once (e.g. a future "jogar
    // novamente" path) -- pools only need to be built once, ever.
    if (_poolsReady) return;
    _poolsReady = true;
    for (final sfx in WordSlashSfx.values) {
      _pools[sfx] = await _createPool(
        sfx.fileName,
        maxPlayers: _maxPlayersPerSfx,
      );
    }
  }

  @override
  void play(WordSlashSfx sfx) => unawaited(_pools[sfx]?.start());
}
