import 'dart:math' show Random, cos, pi, sin;
import 'dart:ui' show Offset, Size;

import '../../core/database/app_database.dart';
import 'word_slash_bubble.dart';
import 'word_slash_round_config.dart';

/// Session/screen lifecycle -- separate on purpose from [roundNumber]'s
/// "which of the 10 timed rounds" concept, so the two "phase" ideas never
/// get conflated (a design-review finding while planning this feature: the
/// same confusion nearly happened here as with `GameSessionPhase` vs. round
/// number). `running` is the only phase in which [tickOnce] or a swipe does
/// anything; `ending`/`disposed` make every mutating method a no-op.
enum WordSlashSessionPhase { starting, running, ending, disposed }

enum WordSlashOutcome { none, correct, wrong }

/// Pure, DB-independent state for one Word Slash play session: bubbles,
/// score/combo, round timer, and the queue of upcoming words. Every
/// mutation is a pure method returning a new instance (mirrors
/// `MinigameRoundState`/`StudySessionState`), which is what makes this
/// directly unit-testable without any widget/ticker/DB harness, and what
/// guarantees [tickOnce] can stay perfectly synchronous (required so a
/// `Ticker` can call it every frame without ever awaiting -- see the
/// plan's "Lifecycle risk 4").
class WordSlashSessionState {
  const WordSlashSessionState({
    this.sessionPhase = WordSlashSessionPhase.starting,
    this.roundNumber = 1,
    this.roundTimeRemaining,
    this.bubbles = const [],
    this.pendingWords = const [],
    this.playAreaSize = const Size(800, 400),
    this.score = 0,
    this.combo = 0,
    this.maxCombo = 0,
    this.pairsMatched = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.swipeHitBubbleIds = const {},
    this.lastOutcome = WordSlashOutcome.none,
    this.lastResolvedWordId,
    this.selectedBubbleId,
  });

  final WordSlashSessionPhase sessionPhase;

  /// 1-based, matches "FASE N" in the UI.
  final int roundNumber;

  /// Null before the first round has ever started ([beginFirstRound]).
  final Duration? roundTimeRemaining;

  final List<WordSlashBubble> bubbles;

  /// Words fetched but not yet turned into bubbles -- kept as a buffer so
  /// [tickOnce]/pair-resolution never need to await a DB read mid-frame.
  /// Topped up in the background by the controller
  /// ([WordSlashSessionState.withMoreCandidates]).
  final List<Word> pendingWords;

  final Size playAreaSize;

  final int score;
  final int combo;
  final int maxCombo;
  final int pairsMatched;
  final int correctCount;
  final int wrongCount;

  /// Bubble ids the current in-flight swipe gesture has crossed so far --
  /// cleared by [beginSwipe], grown by [registerSwipeSegment], consumed and
  /// cleared by [endSwipe].
  final Set<String> swipeHitBubbleIds;

  /// What the most recent [endSwipe] resolved to -- read once by the
  /// controller (which reacts to the *return value* of `endSwipe`
  /// directly, never by re-reading this field later), so there is no
  /// double-processing risk the way a reactive `ref.listen` elsewhere in
  /// this codebase has to explicitly guard against.
  final WordSlashOutcome lastOutcome;

  /// The `Word.id` a correct pair just resolved, for the controller to
  /// record via `ProgressRepository.recordAnswer`. Null for
  /// [WordSlashOutcome.wrong] -- a mismatched pair reflects two
  /// individually-fine words matched badly, not one specific word's
  /// mastery regressing (mirrors `MinigameController
  /// .collectIncorrectWord()`'s `wordId: null`).
  final String? lastResolvedWordId;

  /// The bubble a previous, already-finished gesture cut while nothing was
  /// selected yet -- lets the player cut the two halves of a pair as two
  /// separate swipes (lift finger in between) instead of one continuous
  /// stroke through both. Cleared the instant a second cut resolves the
  /// pair (correct or wrong) or a new round starts; persists across
  /// [beginSwipe]/[endSwipe] calls on purpose, unlike [swipeHitBubbleIds]
  /// which only tracks the *current* in-flight gesture.
  final String? selectedBubbleId;

  bool get isRoundComplete => roundTimeRemaining == Duration.zero;

  bool get isFinalRound => roundNumber >= WordSlashRoundConfig.totalRounds;

  bool get isRunComplete => isFinalRound && isRoundComplete;

  double get accuracy {
    final total = correctCount + wrongCount;
    return total == 0 ? 0 : correctCount / total;
  }

  WordSlashSessionState _copyWith({
    WordSlashSessionPhase? sessionPhase,
    int? roundNumber,
    Duration? roundTimeRemaining,
    List<WordSlashBubble>? bubbles,
    List<Word>? pendingWords,
    Size? playAreaSize,
    int? score,
    int? combo,
    int? maxCombo,
    int? pairsMatched,
    int? correctCount,
    int? wrongCount,
    Set<String>? swipeHitBubbleIds,
    WordSlashOutcome? lastOutcome,
    String? lastResolvedWordId,
    bool clearLastResolvedWordId = false,
    String? selectedBubbleId,
    bool clearSelectedBubbleId = false,
  }) {
    return WordSlashSessionState(
      sessionPhase: sessionPhase ?? this.sessionPhase,
      roundNumber: roundNumber ?? this.roundNumber,
      roundTimeRemaining: roundTimeRemaining ?? this.roundTimeRemaining,
      bubbles: bubbles ?? this.bubbles,
      pendingWords: pendingWords ?? this.pendingWords,
      playAreaSize: playAreaSize ?? this.playAreaSize,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      maxCombo: maxCombo ?? this.maxCombo,
      pairsMatched: pairsMatched ?? this.pairsMatched,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      swipeHitBubbleIds: swipeHitBubbleIds ?? this.swipeHitBubbleIds,
      lastOutcome: lastOutcome ?? this.lastOutcome,
      lastResolvedWordId: clearLastResolvedWordId
          ? null
          : (lastResolvedWordId ?? this.lastResolvedWordId),
      selectedBubbleId: clearSelectedBubbleId
          ? null
          : (selectedBubbleId ?? this.selectedBubbleId),
    );
  }

  // ---------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------

  WordSlashSessionState markRunning() =>
      sessionPhase == WordSlashSessionPhase.starting
      ? _copyWith(sessionPhase: WordSlashSessionPhase.running)
      : this;

  /// The single official way to end this session -- flips [sessionPhase]
  /// synchronously (no awaits anywhere in this class), so [tickOnce] and
  /// every swipe method become inert the instant this is called, even
  /// though the owning `Ticker` may mechanically keep firing for another
  /// ~300ms until the route's exit animation finishes and `dispose()`
  /// actually stops it (see the plan's "Lifecycle risk 1").
  WordSlashSessionState endSession() {
    if (sessionPhase == WordSlashSessionPhase.ending ||
        sessionPhase == WordSlashSessionPhase.disposed) {
      return this;
    }
    return _copyWith(sessionPhase: WordSlashSessionPhase.ending);
  }

  /// Safety-net transition, mirroring `PetAdventureGame.onRemove()` --
  /// called from the controller's `ref.onDispose`, never the primary exit
  /// path (see plan's "Lifecycle risk 2").
  WordSlashSessionState markDisposed() =>
      _copyWith(sessionPhase: WordSlashSessionPhase.disposed);

  // ---------------------------------------------------------------------
  // Word supply
  // ---------------------------------------------------------------------

  /// Appends freshly-fetched words to [pendingWords], dropping anything
  /// already active on screen or already queued -- the explicit
  /// duplicate-pair guard `WordSelectionService` itself doesn't provide
  /// across multiple small `buildSession` calls (see plan's "Seleção de
  /// palavras" section).
  WordSlashSessionState withMoreCandidates(List<Word> newWords) {
    final existingIds = {
      ...bubbles.map((b) => b.pairId),
      ...pendingWords.map((w) => w.id),
    };
    // Checked and grown as we go, not just checked once against the
    // starting set -- otherwise two duplicate ids arriving in the same
    // `newWords` batch would both pass (neither is in the *original*
    // `existingIds`) and both get queued.
    final filtered = <Word>[];
    for (final word in newWords) {
      if (existingIds.contains(word.id)) continue;
      existingIds.add(word.id);
      filtered.add(word);
    }
    if (filtered.isEmpty) return this;
    return _copyWith(pendingWords: [...pendingWords, ...filtered]);
  }

  WordSlashSessionState withAreaSize(Size size) {
    if (size == playAreaSize || size.isEmpty) return this;
    return _copyWith(playAreaSize: size);
  }

  static Word? _pickNonColliding(List<Word> pool, Set<String> excludingPairIds) {
    for (final word in pool) {
      if (!excludingPairIds.contains(word.id)) return word;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Round lifecycle
  // ---------------------------------------------------------------------

  /// (Re)starts a round with fresh bubbles and per-round stats reset --
  /// used for the very first round, "PRÓXIMA FASE", and "JOGAR NOVAMENTE"
  /// alike. All three are in-place resets of the same instance, never a
  /// new screen/controller (see plan's "uma única tela/controller"
  /// decision) -- so this is the only place bubbles are (re)seeded.
  WordSlashSessionState startRound({
    required int roundNumber,
    required Random random,
  }) {
    final config = WordSlashRoundConfig.forRound(roundNumber);
    final usedPairIds = <String>{};
    final newBubbles = <WordSlashBubble>[];
    var pool = pendingWords;
    for (var i = 0; i < WordSlashRoundConfig.pairsOnScreen; i++) {
      final word = _pickNonColliding(pool, usedPairIds);
      if (word == null) break;
      usedPairIds.add(word.id);
      newBubbles.addAll(_spawnPairBubbles(word, random: random, config: config));
    }
    return _copyWith(
      sessionPhase: WordSlashSessionPhase.running,
      roundNumber: roundNumber,
      roundTimeRemaining: config.duration,
      bubbles: newBubbles,
      pendingWords: pool.where((w) => !usedPairIds.contains(w.id)).toList(),
      score: 0,
      combo: 0,
      maxCombo: 0,
      pairsMatched: 0,
      correctCount: 0,
      wrongCount: 0,
      swipeHitBubbleIds: const {},
      lastOutcome: WordSlashOutcome.none,
      clearLastResolvedWordId: true,
      clearSelectedBubbleId: true,
    );
  }

  WordSlashSessionState beginFirstRound({required Random random}) =>
      startRound(roundNumber: 1, random: random);

  /// "PRÓXIMA FASE" -- a no-op once [isFinalRound], since round 10 has no
  /// successor; the caller routes to "run complete" UI instead of calling
  /// this.
  WordSlashSessionState advanceRound({required Random random}) {
    if (isFinalRound) return this;
    return startRound(roundNumber: roundNumber + 1, random: random);
  }

  /// "JOGAR NOVAMENTE" after finishing round 10 -- also in-place, for the
  /// same reason [startRound]'s doc comment explains.
  WordSlashSessionState restartRun({required Random random}) =>
      startRound(roundNumber: 1, random: random);

  // ---------------------------------------------------------------------
  // Per-frame update
  // ---------------------------------------------------------------------

  /// Advances movement and the round timer by [elapsed]. A complete no-op
  /// outside `running` or once the round timer has already hit zero --
  /// this guard is what makes it safe for a `Ticker` to keep calling this
  /// every frame for a few hundred milliseconds after `endSession()`
  /// (see [endSession]'s doc comment). Never awaits anything: word supply
  /// is drawn only from the already-fetched [pendingWords] buffer.
  WordSlashSessionState tickOnce(Duration elapsed, {required Random random}) {
    if (sessionPhase != WordSlashSessionPhase.running) return this;
    if (isRoundComplete) return this;

    final dt = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final remaining = roundTimeRemaining! - elapsed;
    final clampedRemaining = remaining.isNegative ? Duration.zero : remaining;
    if (clampedRemaining == Duration.zero) {
      return _copyWith(roundTimeRemaining: Duration.zero);
    }

    final config = WordSlashRoundConfig.forRound(roundNumber);
    var moved = bubbles.map((b) => _moveBubble(b, dt)).toList();
    moved = _applySeparation(moved);
    final speedCap = config.maxSpeed * 1.5;
    moved = moved.map((b) => _clampSpeed(b, speedCap)).toList();

    var pool = pendingWords;
    final activePairIds = {for (final b in moved) b.pairId};
    while (moved.length < WordSlashRoundConfig.pairsOnScreen * 2) {
      final next = _pickNonColliding(pool, activePairIds);
      if (next == null) break;
      pool = pool.where((w) => w.id != next.id).toList();
      activePairIds.add(next.id);
      moved = [...moved, ..._spawnPairBubbles(next, random: random, config: config)];
    }

    return _copyWith(
      roundTimeRemaining: clampedRemaining,
      bubbles: moved,
      pendingWords: pool,
    );
  }

  WordSlashBubble _moveBubble(WordSlashBubble bubble, double dt) {
    final area = playAreaSize;
    var position = bubble.position + bubble.velocity * dt;
    var velocity = bubble.velocity;
    final minX = bubble.radius;
    final maxX = area.width - bubble.radius;
    final minY = bubble.radius;
    final maxY = area.height - bubble.radius;
    if (maxX > minX) {
      if (position.dx < minX) {
        position = Offset(minX, position.dy);
        velocity = Offset(-velocity.dx, velocity.dy);
      } else if (position.dx > maxX) {
        position = Offset(maxX, position.dy);
        velocity = Offset(-velocity.dx, velocity.dy);
      }
    }
    if (maxY > minY) {
      if (position.dy < minY) {
        position = Offset(position.dx, minY);
        velocity = Offset(velocity.dx, -velocity.dy);
      } else if (position.dy > maxY) {
        position = Offset(position.dx, maxY);
        velocity = Offset(velocity.dx, -velocity.dy);
      }
    }
    return bubble.copyWith(position: position, velocity: velocity);
  }

  /// Light repulsion, not real physics ("boa experiência mobile > física
  /// perfeita" per spec): bubbles closer than their combined radii get a
  /// small outward velocity nudge instead of overlapping indefinitely.
  /// O(n^2) but n is always 8, so cost is irrelevant.
  List<WordSlashBubble> _applySeparation(List<WordSlashBubble> input) {
    const margin = 6.0;
    const pushStrength = 4.0;
    final result = [...input];
    for (var i = 0; i < result.length; i++) {
      for (var j = i + 1; j < result.length; j++) {
        final a = result[i];
        final b = result[j];
        final delta = a.position - b.position;
        final minDistance = a.radius + b.radius + margin;
        final distance = delta.distance;
        if (distance > 0 && distance < minDistance) {
          final push = delta / distance * pushStrength;
          result[i] = a.copyWith(velocity: a.velocity + push);
          result[j] = b.copyWith(velocity: b.velocity - push);
        }
      }
    }
    return result;
  }

  WordSlashBubble _clampSpeed(WordSlashBubble bubble, double maxSpeed) {
    final speed = bubble.velocity.distance;
    if (speed <= maxSpeed || speed == 0) return bubble;
    return bubble.copyWith(velocity: bubble.velocity * (maxSpeed / speed));
  }

  List<WordSlashBubble> _spawnPairBubbles(
    Word word, {
    required Random random,
    required WordSlashRoundConfig config,
  }) {
    return [
      _spawnOneBubble(
        pairId: word.id,
        text: word.portugueseTranslation,
        isPortuguese: true,
        random: random,
        config: config,
      ),
      _spawnOneBubble(
        pairId: word.id,
        text: word.englishTerm,
        isPortuguese: false,
        random: random,
        config: config,
      ),
    ];
  }

  WordSlashBubble _spawnOneBubble({
    required String pairId,
    required String text,
    required bool isPortuguese,
    required Random random,
    required WordSlashRoundConfig config,
  }) {
    final area = playAreaSize;
    final margin = WordSlashRoundConfig.bubbleRadius + 8;
    final width = area.width > margin * 2 ? area.width : margin * 2 + 1;
    final height = area.height > margin * 2 ? area.height : margin * 2 + 1;
    final position = Offset(
      margin + random.nextDouble() * (width - margin * 2),
      margin + random.nextDouble() * (height - margin * 2),
    );
    final angle = random.nextDouble() * 2 * pi;
    final speed = config.minSpeed + random.nextDouble() * (config.maxSpeed - config.minSpeed);
    final velocity = Offset(cos(angle) * speed, sin(angle) * speed);
    final suffix = random.nextInt(1 << 32);
    return WordSlashBubble(
      id: '$pairId-${isPortuguese ? 'pt' : 'en'}-$suffix',
      pairId: pairId,
      text: text,
      isPortuguese: isPortuguese,
      position: position,
      velocity: velocity,
      radius: WordSlashRoundConfig.bubbleRadius,
    );
  }

  // ---------------------------------------------------------------------
  // Swipe / cut
  // ---------------------------------------------------------------------

  WordSlashSessionState beginSwipe() {
    if (sessionPhase != WordSlashSessionPhase.running || isRoundComplete) {
      return this;
    }
    return _copyWith(
      swipeHitBubbleIds: const {},
      lastOutcome: WordSlashOutcome.none,
      clearLastResolvedWordId: true,
    );
  }

  /// Checks the segment between two consecutive pan-update points against
  /// the currently-active bubbles, registering at most ONE new hit per
  /// call: when bubbles visually overlap, a single touch point can fall
  /// within both circles' padded radius at once, and the player expects
  /// whichever bubble is drawn on top -- last in [bubbles], matching the
  /// `Stack`'s paint order in the screen widget -- to be the one they cut,
  /// not whichever happens to be underneath. Iterating back-to-front and
  /// stopping at the first match achieves exactly that, while a single
  /// continuous stroke can still register several *different* bubbles
  /// across its several segments (one topmost bubble per segment).
  WordSlashSessionState registerSwipeSegment(
    Offset a,
    Offset b, {
    required double hitPadding,
  }) {
    if (sessionPhase != WordSlashSessionPhase.running || isRoundComplete) {
      return this;
    }
    for (var i = bubbles.length - 1; i >= 0; i--) {
      final bubble = bubbles[i];
      if (bubble.intersectsSegment(a, b, padding: hitPadding)) {
        if (swipeHitBubbleIds.contains(bubble.id)) return this;
        return _copyWith(swipeHitBubbleIds: {...swipeHitBubbleIds, bubble.id});
      }
    }
    return this;
  }

  /// Resolves the gesture started by [beginSwipe]. Cutting a pair can be
  /// done either as one continuous stroke through both bubbles, or as two
  /// separate strokes with the finger lifted in between -- [selectedBubbleId]
  /// remembers the first bubble cut by an earlier, already-finished gesture
  /// so a *later* gesture's single cut can complete the pair. Concretely:
  /// the bubble(s) this gesture just crossed are combined with whatever was
  /// already selected (deduped), and exactly two distinct bubbles total
  /// determine the outcome -- same [WordSlashBubble.pairId] is correct,
  /// different is wrong. Fewer than two (nothing crossed, or a first cut
  /// with nothing selected yet) just (re)selects and waits; more than two
  /// (e.g. a fresh double-cut while one was already selected) is wrong,
  /// same "no guessing which two were intended" rule as before.
  WordSlashSessionState endSwipe({required Random random}) {
    if (sessionPhase != WordSlashSessionPhase.running || isRoundComplete) {
      return _copyWith(swipeHitBubbleIds: const {});
    }
    final gestureHits = bubbles.where((b) => swipeHitBubbleIds.contains(b.id)).toList();
    if (gestureHits.isEmpty) {
      // Missed entirely -- leaves any existing selection untouched so the
      // player can keep trying to find the second bubble.
      return _copyWith(swipeHitBubbleIds: const {}, lastOutcome: WordSlashOutcome.none);
    }

    final candidates = <WordSlashBubble>[];
    final seenIds = <String>{};
    final previouslySelectedId = selectedBubbleId;
    if (previouslySelectedId != null) {
      for (final b in bubbles) {
        if (b.id == previouslySelectedId && seenIds.add(b.id)) {
          candidates.add(b);
          break;
        }
      }
    }
    for (final b in gestureHits) {
      if (seenIds.add(b.id)) candidates.add(b);
    }

    if (candidates.length == 1) {
      return _copyWith(
        swipeHitBubbleIds: const {},
        selectedBubbleId: candidates.single.id,
        lastOutcome: WordSlashOutcome.none,
      );
    }
    if (candidates.length == 2 && candidates[0].pairId == candidates[1].pairId) {
      return _applyCorrectPair(candidates[0], candidates[1], random: random);
    }
    return _applyWrongPair();
  }

  WordSlashSessionState _applyWrongPair() {
    return _copyWith(
      combo: 0,
      wrongCount: wrongCount + 1,
      swipeHitBubbleIds: const {},
      lastOutcome: WordSlashOutcome.wrong,
      clearLastResolvedWordId: true,
      clearSelectedBubbleId: true,
    );
  }

  WordSlashSessionState _applyCorrectPair(
    WordSlashBubble a,
    WordSlashBubble b, {
    required Random random,
  }) {
    final remaining = bubbles.where((bub) => bub.id != a.id && bub.id != b.id).toList();
    final activePairIds = {for (final bub in remaining) bub.pairId};
    final replacement = _pickNonColliding(pendingWords, activePairIds);
    final config = WordSlashRoundConfig.forRound(roundNumber);
    final newBubbles = [
      ...remaining,
      if (replacement != null) ..._spawnPairBubbles(replacement, random: random, config: config),
    ];
    final newCombo = combo + 1 > WordSlashRoundConfig.comboCap
        ? WordSlashRoundConfig.comboCap
        : combo + 1;
    // Rewards a correct cut with a few extra seconds on the round clock --
    // uncapped, same spirit as the combo multiplier rewarding skilled play.
    final extendedTime =
        (roundTimeRemaining ?? Duration.zero) +
        const Duration(seconds: WordSlashRoundConfig.bonusSecondsPerCorrectPair);
    return _copyWith(
      bubbles: newBubbles,
      pendingWords: replacement == null
          ? pendingWords
          : pendingWords.where((w) => w.id != replacement.id).toList(),
      roundTimeRemaining: extendedTime,
      score: score + WordSlashRoundConfig.basePointsPerPair * newCombo,
      combo: newCombo,
      maxCombo: newCombo > maxCombo ? newCombo : maxCombo,
      pairsMatched: pairsMatched + 1,
      correctCount: correctCount + 1,
      swipeHitBubbleIds: const {},
      lastOutcome: WordSlashOutcome.correct,
      lastResolvedWordId: a.pairId,
      clearSelectedBubbleId: true,
    );
  }
}
