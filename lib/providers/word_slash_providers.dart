import 'dart:async' show unawaited;
import 'dart:math' show Random;
import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../core/models/session_kind.dart';
import '../core/services/word_selection_service.dart';
import '../game/sound/word_slash_sfx.dart';
import '../game/sound/word_slash_sound_service.dart';
import '../game/word_slash/word_slash_round_config.dart';
import '../game/word_slash/word_slash_session_state.dart';
import 'home_providers.dart';
import 'repository_providers.dart';

/// Shared sound service for Word Slash -- only read from navigation/
/// tap-reachable code (mirrors `adventureSoundServiceProvider`'s own doc
/// comment / reasoning).
final wordSlashSoundServiceProvider = Provider<WordSlashSoundService>(
  (ref) => FlameWordSlashSoundService(),
);

/// Drives one Word Slash play session: bubble movement, swipe/cut
/// detection, round progression, and word supply -- all delegated to the
/// pure [WordSlashSessionState], with this class doing only the DB/async
/// orchestration around it (mirrors `StudySessionController`'s split
/// between itself and `StudySessionState`).
///
/// `.autoDispose` is safe here specifically because there is never a
/// `Navigator.pushReplacement` mid-session (see
/// `WordSlashSessionState.startRound`'s doc comment: round changes and
/// "jogar novamente" are in-place resets of this same instance) -- the
/// same reasoning that already makes `StudySessionController` safe as
/// `.autoDispose`, unlike Pet Adventure's `MinigameController` (which
/// isn't `.autoDispose` precisely because "JOGAR NOVAMENTE" there *does*
/// push a replacement screen).
class WordSlashController extends Notifier<WordSlashSessionState> {
  final String _sessionId = const Uuid().v4();
  final Random _random = Random();
  bool _isToppingUp = false;

  /// A getter, not a `late final` field cached once in `build()`: Riverpod
  /// can call `build()` again on this *same* instance (confirmed while
  /// writing this class's tests -- `container.invalidate()` on a provider
  /// that still has an active listener rebuilds in place rather than
  /// constructing a fresh instance), which would otherwise crash a
  /// `late final` with "already initialized" on the second call.
  /// `ref.read` on a plain `Provider` is cheap and idempotent, so there's
  /// no cost to not caching it.
  WordSlashSoundService get _sound => ref.read(wordSlashSoundServiceProvider);

  /// Debug-only instrumentation (per-session id + lifecycle log lines), so
  /// a real device run can be checked via `adb logcat` for exactly one
  /// session ever being active at a time -- mirrors `PetAdventureGame`'s
  /// identical mechanism.
  static int _nextSessionId = 0;
  final int sessionId = _nextSessionId++;

  void _logLifecycle(String event) {
    if (kDebugMode) debugPrint('[WORD_GAME] Session #$sessionId $event');
  }

  static const int _pairsPerFetch = WordSlashRoundConfig.pairsOnScreen;
  static const int _lowWaterMark = _pairsPerFetch * 2;
  static const int _topUpBatchSize = _pairsPerFetch * 2;

  /// Tracked outside Riverpod's `state` on purpose: reading `state` from
  /// inside `ref.onDispose` trips a real Riverpod debug assertion
  /// ("Cannot use Ref or modify other providers inside
  /// life-cycles/selectors") -- confirmed by actually hitting it while
  /// writing this class's tests, not just theorized. A plain field
  /// mirrors `PetAdventureGame.onRemove()`'s `endedProperly` check without
  /// touching `state`/`ref` from within the dispose callback at all.
  bool _endedProperly = false;

  @override
  WordSlashSessionState build() {
    _logLifecycle('CREATED');
    unawaited(_sound.preload());
    unawaited(_loadInitialPairs());
    // Safety-net log only -- `.autoDispose` teardown isn't synchronous
    // with the widget unmounting (see `WordSlashSessionState.endSession`'s
    // doc comment), so this must never be the primary way anything
    // actually stops; it only records whether `endSession()` already ran
    // for this instance by the time Riverpod gets around to disposing it.
    ref.onDispose(() {
      _logLifecycle(
        _endedProperly ? 'DISPOSED' : 'DISPOSED (safety net -- endSession() never ran)',
      );
    });
    return const WordSlashSessionState();
  }

  Future<void> _loadInitialPairs() async {
    final words = await _fetchBatch(
      count: _pairsPerFetch * 3,
      recentlyShownWordIds: const [],
    );
    if (!ref.mounted) return;
    state = state.withMoreCandidates(words).beginFirstRound(random: _random);
    _logLifecycle('STARTED');
  }

  Future<List<Word>> _fetchBatch({
    required int count,
    required List<String> recentlyShownWordIds,
  }) async {
    final wordRepository = ref.read(wordRepositoryProvider);
    final progressRepository = ref.read(progressRepositoryProvider);

    final pool = await wordRepository.fetchCandidatePool();
    if (pool.isEmpty) return const [];
    if (!ref.mounted) return const [];
    final profile = await progressRepository.fetchUserProfile();
    if (!ref.mounted) return const [];
    final activeWords = await wordRepository.fetchActiveWords();
    if (!ref.mounted) return const [];

    final selected = const WordSelectionService().buildSession(
      pool: pool,
      kind: SessionKind.review,
      userLevel: profile.currentLevel,
      now: DateTime.now(),
      count: count,
      recentlyShownWordIds: recentlyShownWordIds,
    );

    // Word Slash needs `count` *distinct* words to queue as separate
    // simultaneous pairs -- unlike Estudar's one-question-at-a-time
    // stream, a repeated wordId here would mean two pending pairs racing
    // for the same word, so duplicates from buildSession's own
    // (deliberate, correct-for-Estudar) repetition are filtered out here.
    final wordsById = {for (final w in activeWords) w.id: w};
    final seen = <String>{};
    final words = <Word>[];
    for (final candidate in selected) {
      final word = wordsById[candidate.wordId];
      if (word == null || !seen.add(word.id)) continue;
      words.add(word);
    }
    return words;
  }

  void _maybeTopUp() {
    if (_isToppingUp) return;
    if (state.pendingWords.length >= _lowWaterMark) return;
    if (state.sessionPhase != WordSlashSessionPhase.running) return;
    _isToppingUp = true;
    unawaited(_topUpPendingCandidates());
  }

  Future<void> _topUpPendingCandidates() async {
    try {
      final recentlyShown = [
        if (state.lastResolvedWordId != null) state.lastResolvedWordId!,
        ...state.bubbles.map((b) => b.pairId),
      ];
      final words = await _fetchBatch(
        count: _topUpBatchSize,
        recentlyShownWordIds: recentlyShown,
      );
      if (!ref.mounted) return;
      if (words.isNotEmpty) {
        state = state.withMoreCandidates(words);
      }
    } finally {
      _isToppingUp = false;
    }
  }

  /// Called once per animation frame by the play area's `Ticker`. Stays a
  /// no-op the instant [endSession] has run, even though the `Ticker`
  /// mechanically keeps firing for a little longer during the pop
  /// transition (see `WordSlashSessionState.endSession`'s doc comment).
  void tick(Duration elapsed, Size areaSize) {
    if (state.sessionPhase != WordSlashSessionPhase.running) return;
    final wasRoundComplete = state.isRoundComplete;
    state = state.withAreaSize(areaSize).tickOnce(elapsed, random: _random);
    if (!wasRoundComplete && state.isRoundComplete) {
      _sound.play(WordSlashSfx.roundEnd);
      _logLifecycle('ROUND ${state.roundNumber} ENDED');
    }
    _maybeTopUp();
  }

  void beginSwipe() {
    if (state.sessionPhase != WordSlashSessionPhase.running) return;
    state = state.beginSwipe();
  }

  void registerSwipeSegment(Offset a, Offset b) {
    if (state.sessionPhase != WordSlashSessionPhase.running) return;
    final config = WordSlashRoundConfig.forRound(state.roundNumber);
    state = state.registerSwipeSegment(a, b, hitPadding: config.hitPadding);
  }

  void endSwipe() {
    if (state.sessionPhase != WordSlashSessionPhase.running) return;
    final next = state.endSwipe(random: _random);
    state = next;
    switch (next.lastOutcome) {
      case WordSlashOutcome.correct:
        _sound.play(WordSlashSfx.correctPair);
        unawaited(_recordCorrectPair(next.lastResolvedWordId!));
        _maybeTopUp();
      case WordSlashOutcome.wrong:
        _sound.play(WordSlashSfx.wrongPair);
        unawaited(_recordWrongPair());
      case WordSlashOutcome.none:
        break;
    }
  }

  Future<void> _recordCorrectPair(String wordId) async {
    await ref
        .read(progressRepositoryProvider)
        .recordAnswer(
          wordId: wordId,
          wasCorrect: true,
          exerciseType: 'word_slash',
          sessionKind: SessionKind.review,
          sessionId: _sessionId,
          xpOverride: WordSlashRoundConfig.xpPerPair,
        );
    if (!ref.mounted) return;
    ref.invalidate(masteryStatsProvider);
    ref.invalidate(eggProgressProvider);
  }

  /// Mirrors `MinigameController.collectIncorrectWord()`: a wrong pair
  /// can't be attributed to one specific word's mastery (see
  /// `WordSlashSessionState.lastResolvedWordId`'s doc comment), so this
  /// still records the attempt for history/stats without touching any
  /// word's SRS state.
  Future<void> _recordWrongPair() async {
    await ref
        .read(progressRepositoryProvider)
        .recordAnswer(
          wordId: null,
          wasCorrect: false,
          exerciseType: 'word_slash',
          sessionKind: SessionKind.review,
          sessionId: _sessionId,
          xpOverride: 0,
        );
  }

  /// "PRÓXIMA FASE" -- an in-place reset, not a new screen (see class doc).
  void advanceRound() {
    if (state.sessionPhase != WordSlashSessionPhase.running) return;
    state = state.advanceRound(random: _random);
    _logLifecycle('ROUND ${state.roundNumber} STARTED');
  }

  /// "JOGAR NOVAMENTE" after finishing round 10 -- also in-place.
  void restartRun() {
    if (state.sessionPhase != WordSlashSessionPhase.running) return;
    state = state.restartRun(random: _random);
    _logLifecycle('RESTARTED');
  }

  /// The single official way to end this session -- called BEFORE popping
  /// the route by every real exit path (HUD ✕, system back, "SAIR"),
  /// exactly like `PetAdventureGame.endSession()`.
  Future<void> endSession() async {
    if (state.sessionPhase == WordSlashSessionPhase.ending ||
        state.sessionPhase == WordSlashSessionPhase.disposed) {
      return;
    }
    _endedProperly = true;
    state = state.endSession();
    _logLifecycle('ENDING');
  }
}

final wordSlashControllerProvider =
    NotifierProvider.autoDispose<WordSlashController, WordSlashSessionState>(
      WordSlashController.new,
    );
