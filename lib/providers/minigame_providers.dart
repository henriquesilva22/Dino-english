import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/models/session_kind.dart';
import '../game/boss_fight_state.dart';
import '../game/minigame_round_state.dart';
import 'home_providers.dart';
import 'repository_providers.dart';

final minigameWordPoolProvider = FutureProvider<List<Word>>((ref) {
  return ref.watch(wordRepositoryProvider).fetchActiveWords();
});

/// Resets round state for a brand new game: 4 lives, zero score, and (in
/// a boss fight) full boss HP. **Must** be called from a genuine user
/// event -- a button's `onTap`, before navigating to
/// `PetAdventureGameScreen` -- never from a widget's `initState`/`build`.
///
/// `ref.invalidate` synchronously notifies every listener of the
/// invalidated provider. Calling it from `PetAdventurePlayArea`'s
/// `initState` used to trip "setState()/markNeedsBuild() called during
/// build": that `initState` runs while Flutter is still mid-build,
/// inflating the widget tree `Navigator.pushReplacement`'s new route
/// produced (from "JOGAR NOVAMENTE") -- i.e. nested inside an
/// already-in-progress build call. Calling it here instead, from the
/// button's tap handler, runs strictly *before* that build starts, so by
/// the time the new screen mounts the state is already fresh and nothing
/// needs to change mid-build.
void resetMinigameState(WidgetRef ref, {required bool isBossFight}) {
  ref.invalidate(minigameControllerProvider);
  if (isBossFight) {
    ref.invalidate(bossFightControllerProvider);
  }
}

/// Bridges Flame's synchronous collision callbacks to the same
/// [ProgressRepository.recordAnswer] path the study screen uses. The round
/// state updates immediately (so the HUD reacts on the spot); the database
/// write happens in the background and only refreshes the Home's
/// aggregates when it completes.
class MinigameController extends Notifier<MinigameRoundState> {
  int _sessionCounter = 0;
  late String _sessionId;

  @override
  MinigameRoundState build() {
    _sessionId =
        'minigame-${_sessionCounter++}-${DateTime.now().microsecondsSinceEpoch}';
    return const MinigameRoundState();
  }

  Future<void> collectCorrectWord(Word word) async {
    if (state.isGameOver) return;
    state = state.collectCorrect(word.englishTerm);

    await ref
        .read(progressRepositoryProvider)
        .recordAnswer(
          wordId: word.id,
          wasCorrect: true,
          exerciseType: 'minigame_collect',
          sessionKind: SessionKind.review,
          sessionId: _sessionId,
          xpOverride: MinigameRoundState.xpPerCorrectWord,
        );
    ref.invalidate(masteryStatsProvider);
    ref.invalidate(eggProgressProvider);
  }

  Future<void> collectIncorrectWord() async {
    if (state.isGameOver) return;
    state = state.collectIncorrect();

    await ref
        .read(progressRepositoryProvider)
        .recordAnswer(
          wordId: null,
          wasCorrect: false,
          exerciseType: 'minigame_collect',
          sessionKind: SessionKind.review,
          sessionId: _sessionId,
          xpOverride: 0,
        );
  }
}

final minigameControllerProvider =
    NotifierProvider<MinigameController, MinigameRoundState>(
      MinigameController.new,
    );

/// Tracks the boss fight's HP in memory, driven by
/// [PetAdventureGame.onBossStateChanged]. Per-word damage never touches the
/// database -- each correct word already goes through
/// [MinigameController.collectCorrectWord] for its normal XP/SRS credit;
/// this only additionally records a single bonus XP grant once the fight
/// is actually won, through the same `ProgressRepository.recordAnswer`
/// path everything else in the minigame uses (no parallel progress
/// system).
class BossFightController extends Notifier<BossFightState> {
  late String _sessionId;

  @override
  BossFightState build() {
    _sessionId = 'boss-${DateTime.now().microsecondsSinceEpoch}';
    return const BossFightState();
  }

  Future<void> hit({int damage = BossFightState.normalWordDamage}) async {
    if (state.isFinished) return;
    final next = state.hit(damage: damage);
    state = next;
    if (next.status == BossFightStatus.victory) {
      await ref
          .read(progressRepositoryProvider)
          .recordAnswer(
            wordId: null,
            wasCorrect: true,
            exerciseType: 'minigame_boss_victory',
            sessionKind: SessionKind.review,
            sessionId: _sessionId,
            xpOverride: BossFightState.victoryBonusXp,
          );
      ref.invalidate(masteryStatsProvider);
      ref.invalidate(eggProgressProvider);
    }
  }
}

final bossFightControllerProvider =
    NotifierProvider<BossFightController, BossFightState>(
      BossFightController.new,
    );
