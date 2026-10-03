import 'dart:math' show Random;
import 'dart:ui' show Offset, Size;

import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/game/word_slash/word_slash_bubble.dart';
import 'package:dino_english/game/word_slash/word_slash_round_config.dart';
import 'package:dino_english/game/word_slash/word_slash_session_state.dart';
import 'package:flutter_test/flutter_test.dart';

Word _word(String id, {String? en, String? pt}) => Word(
  id: id,
  englishTerm: en ?? id,
  portugueseTranslation: pt ?? '$id (pt)',
  category: 'test',
  difficulty: 1,
  recommendedLevel: 1,
  exampleSentenceEn: 'Example $id.',
  exampleSentencePt: 'Exemplo $id.',
  isActive: true,
);

// Deliberately much larger than any real device screen: with only 8
// bubbles ever on screen, a huge area keeps their random spawn positions
// far enough apart that a swipe's small hit-test padding can never
// accidentally graze an unrelated bubble. A real device instead relies on
// `pairsOnScreen` staying small (4 pairs) relative to real screen size to
// avoid crowding -- this is purely a test-determinism concern, not a
// gameplay one.
WordSlashSessionState _stateWithWords(
  List<Word> words, {
  Size area = const Size(5000, 5000),
}) {
  return const WordSlashSessionState()
      .withAreaSize(area)
      .withMoreCandidates(words);
}

/// Simulates one full swipe gesture crossing exactly [targets], using each
/// bubble's own (random-generated, but already-known-from-state) position
/// rather than predicting positions -- decouples these tests from the
/// exact RNG output while still exercising the real segment-vs-circle hit
/// test in `WordSlashBubble.intersectsSegment` (a tiny segment centered on
/// the bubble is trivially within a small padding).
///
/// Every call in a test shares ONE [Random] instance (mirroring how
/// `WordSlashController` owns a single, never-reset `_random` field for
/// its whole lifetime) -- minting a *fresh* `Random(sameSmallSeed)` at
/// several unrelated call sites would make their very first draws
/// coincide (same seed, same first output), which can place a
/// spawned/replacement bubble on top of an unrelated one purely as a test
/// artifact that could never happen with the app's real, continuously
/// advancing `Random()`.
WordSlashSessionState _swipeThrough(
  WordSlashSessionState state,
  List<WordSlashBubble> targets, {
  required Random random,
}) {
  var next = state.beginSwipe();
  for (final bubble in targets) {
    next = next.registerSwipeSegment(
      bubble.position - const Offset(1, 1),
      bubble.position + const Offset(1, 1),
      hitPadding: 5,
    );
  }
  return next.endSwipe(random: random);
}

List<WordSlashBubble> _bubblesForPair(
  WordSlashSessionState state,
  String pairId,
) => state.bubbles.where((b) => b.pairId == pairId).toList();

void main() {
  final words = [
    _word('w1', en: 'apple', pt: 'maçã'),
    _word('w2', en: 'dog', pt: 'cachorro'),
    _word('w3', en: 'house', pt: 'casa'),
    _word('w4', en: 'water', pt: 'água'),
    _word('w5', en: 'book', pt: 'livro'),
  ];

  group('round start', () {
    test('creates exactly 8 bubbles forming exactly 4 pairs', () {
      final random = Random(1);
      final state = _stateWithWords(words).beginFirstRound(random: random);

      expect(state.bubbles, hasLength(8));
      final pairIds = state.bubbles.map((b) => b.pairId).toSet();
      expect(pairIds, hasLength(4));
    });

    test(
      'each bubble carries its word\'s id as pairId, and PT/EN bubbles of the same pair match the same word',
      () {
        final random = Random(1);
        final state = _stateWithWords(words).beginFirstRound(random: random);

        for (final pairId in state.bubbles.map((b) => b.pairId).toSet()) {
          final pair = _bubblesForPair(state, pairId);
          expect(pair, hasLength(2));
          final word = words.firstWhere((w) => w.id == pairId);
          final pt = pair.firstWhere((b) => b.isPortuguese);
          final en = pair.firstWhere((b) => !b.isPortuguese);
          expect(pt.text, word.portugueseTranslation);
          expect(en.text, word.englishTerm);
        }
      },
    );

    test(
      'leaves the unused words queued in pendingWords, ready for replacements',
      () {
        final random = Random(1);
        final state = _stateWithWords(words).beginFirstRound(random: random);
        expect(state.pendingWords, hasLength(1)); // 5 supplied, 4 used
      },
    );
  });

  group('correct pair', () {
    test(
      'is accepted, removes both bubbles, and spawns a replacement pair keeping the total at 8',
      () {
        final random = Random(1);
        var state = _stateWithWords(words).beginFirstRound(random: random);
        final firstPairId = state.bubbles.first.pairId;
        final pair = _bubblesForPair(state, firstPairId);

        state = _swipeThrough(state, pair, random: random);

        expect(state.lastOutcome, WordSlashOutcome.correct);
        expect(state.bubbles.any((b) => b.pairId == firstPairId), isFalse);
        expect(state.bubbles, hasLength(8));
        expect(state.pairsMatched, 1);
        expect(state.correctCount, 1);
      },
    );

    test('increases score and combo', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      final pair = _bubblesForPair(state, state.bubbles.first.pairId);

      state = _swipeThrough(state, pair, random: random);

      expect(state.combo, 1);
      expect(state.maxCombo, 1);
      expect(state.score, WordSlashRoundConfig.basePointsPerPair * 1);
    });

    test('score scales with combo (100 * combo), and combo caps at 10', () {
      final random = Random(1);
      // Wide pool so 12 consecutive correct pairs never run out of
      // distinct replacements.
      final bigPool = List.generate(20, (i) => _word('big$i'));
      var state = _stateWithWords(bigPool).beginFirstRound(random: random);

      var expectedScore = 0;
      for (var i = 1; i <= 12; i++) {
        final pair = _bubblesForPair(state, state.bubbles.first.pairId);
        state = _swipeThrough(state, pair, random: random);
        final combo = i > WordSlashRoundConfig.comboCap
            ? WordSlashRoundConfig.comboCap
            : i;
        expectedScore += WordSlashRoundConfig.basePointsPerPair * combo;
        expect(state.combo, combo, reason: 'after correct pair #$i');
        expect(state.score, expectedScore, reason: 'after correct pair #$i');
      }
      expect(state.maxCombo, WordSlashRoundConfig.comboCap);
    });

    test(
      'never leaves any pairId represented by more than 2 bubbles at once (no pair duplicated on screen)',
      () {
        final random = Random(1);
        var state = _stateWithWords(words).beginFirstRound(random: random);
        final firstPairId = state.bubbles.first.pairId;
        final pair = _bubblesForPair(state, firstPairId);

        state = _swipeThrough(state, pair, random: random);

        final counts = <String, int>{};
        for (final bubble in state.bubbles) {
          counts[bubble.pairId] = (counts[bubble.pairId] ?? 0) + 1;
        }
        expect(counts.values, everyElement(2));
      },
    );

    test('adds a fixed time bonus to the round clock', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      final before = state.roundTimeRemaining!;
      final pair = _bubblesForPair(state, state.bubbles.first.pairId);

      state = _swipeThrough(state, pair, random: random);

      expect(
        state.roundTimeRemaining,
        before +
            const Duration(
              seconds: WordSlashRoundConfig.bonusSecondsPerCorrectPair,
            ),
      );
    });
  });

  group('wrong pair', () {
    test('is rejected: nothing is removed, total stays 8', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      final pairIds = state.bubbles.map((b) => b.pairId).toSet().toList();
      final mismatched = [
        _bubblesForPair(state, pairIds[0]).first,
        _bubblesForPair(state, pairIds[1]).first,
      ];

      state = _swipeThrough(state, mismatched, random: random);

      expect(state.lastOutcome, WordSlashOutcome.wrong);
      expect(state.bubbles, hasLength(8));
      expect(state.wrongCount, 1);
      expect(state.pairsMatched, 0);
    });

    test('does not change the round clock', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      final before = state.roundTimeRemaining;
      final pairIds = state.bubbles.map((b) => b.pairId).toSet().toList();
      final mismatched = [
        _bubblesForPair(state, pairIds[0]).first,
        _bubblesForPair(state, pairIds[1]).first,
      ];

      state = _swipeThrough(state, mismatched, random: random);

      expect(state.roundTimeRemaining, before);
    });

    test('resets combo to zero', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      final correctPair = _bubblesForPair(state, state.bubbles.first.pairId);
      state = _swipeThrough(state, correctPair, random: random);
      expect(state.combo, greaterThan(0));

      final pairIds = state.bubbles.map((b) => b.pairId).toSet().toList();
      final mismatched = [
        _bubblesForPair(state, pairIds[0]).first,
        _bubblesForPair(state, pairIds[1]).first,
      ];
      state = _swipeThrough(state, mismatched, random: random);

      expect(state.combo, 0);
      expect(
        state.maxCombo,
        greaterThan(0),
        reason: 'maxCombo records the peak, not reset by a miss',
      );
    });

    test(
      'crossing more than two bubbles in one gesture counts as wrong, never a silent partial match',
      () {
        final random = Random(1);
        var state = _stateWithWords(words).beginFirstRound(random: random);
        final pairIds = state.bubbles.map((b) => b.pairId).toSet().toList();
        final threeBubbles = [
          _bubblesForPair(state, pairIds[0]).first,
          _bubblesForPair(state, pairIds[1]).first,
          _bubblesForPair(state, pairIds[2]).first,
        ];

        state = _swipeThrough(state, threeBubbles, random: random);

        expect(state.lastOutcome, WordSlashOutcome.wrong);
        expect(state.bubbles, hasLength(8));
      },
    );
  });

  group('incomplete swipe', () {
    test('crossing zero bubbles is a pure no-op', () {
      final random = Random(1);
      final state = _stateWithWords(words).beginFirstRound(random: random);
      final result = state.beginSwipe().endSwipe(random: random);

      expect(result.lastOutcome, WordSlashOutcome.none);
      expect(result.score, state.score);
      expect(result.combo, state.combo);
      expect(result.bubbles, hasLength(8));
    });

    test(
      'crossing exactly one bubble is not a wrong attempt -- it selects that bubble instead',
      () {
        final random = Random(1);
        var state = _stateWithWords(words).beginFirstRound(random: random);
        final oneBubble = _bubblesForPair(
          state,
          state.bubbles.first.pairId,
        ).first;

        state = _swipeThrough(state, [oneBubble], random: random);

        expect(state.lastOutcome, WordSlashOutcome.none);
        expect(state.wrongCount, 0);
        expect(state.combo, 0);
        expect(state.selectedBubbleId, oneBubble.id);
      },
    );
  });

  group('sequential cut (select one bubble, then cut its partner separately)', () {
    test(
      'cutting one bubble alone selects it without affecting score/combo/outcome',
      () {
        final random = Random(1);
        var state = _stateWithWords(words).beginFirstRound(random: random);
        final firstPairId = state.bubbles.first.pairId;
        final firstBubble = _bubblesForPair(state, firstPairId).first;

        state = _swipeThrough(state, [firstBubble], random: random);

        expect(state.selectedBubbleId, firstBubble.id);
        expect(state.lastOutcome, WordSlashOutcome.none);
        expect(state.pairsMatched, 0);
        expect(state.bubbles, hasLength(8));
      },
    );

    test(
      'cutting the matching partner in a later, separate gesture completes the pair',
      () {
        final random = Random(1);
        var state = _stateWithWords(words).beginFirstRound(random: random);
        final firstPairId = state.bubbles.first.pairId;
        final pair = _bubblesForPair(state, firstPairId);

        state = _swipeThrough(state, [pair[0]], random: random);
        expect(state.selectedBubbleId, pair[0].id);
        state = _swipeThrough(state, [pair[1]], random: random);

        expect(state.lastOutcome, WordSlashOutcome.correct);
        expect(state.pairsMatched, 1);
        expect(state.bubbles.any((b) => b.pairId == firstPairId), isFalse);
        expect(state.selectedBubbleId, isNull);
      },
    );

    test(
      'cutting a mismatched bubble in a later, separate gesture is wrong and clears the selection',
      () {
        final random = Random(1);
        var state = _stateWithWords(words).beginFirstRound(random: random);
        final pairIds = state.bubbles.map((b) => b.pairId).toSet().toList();
        final first = _bubblesForPair(state, pairIds[0]).first;
        final mismatched = _bubblesForPair(state, pairIds[1]).first;

        state = _swipeThrough(state, [first], random: random);
        state = _swipeThrough(state, [mismatched], random: random);

        expect(state.lastOutcome, WordSlashOutcome.wrong);
        expect(state.wrongCount, 1);
        expect(state.combo, 0);
        expect(state.selectedBubbleId, isNull);
        // Neither bubble was removed -- a wrong pair never removes bubbles.
        expect(state.bubbles.any((b) => b.id == first.id), isTrue);
        expect(state.bubbles.any((b) => b.id == mismatched.id), isTrue);
      },
    );

    test(
      'missing entirely on the second gesture leaves the selection intact for another try',
      () {
        final random = Random(1);
        var state = _stateWithWords(words).beginFirstRound(random: random);
        final firstPairId = state.bubbles.first.pairId;
        final firstBubble = _bubblesForPair(state, firstPairId).first;

        state = _swipeThrough(state, [firstBubble], random: random);
        // A gesture that crosses nothing at all (e.g. a stray tap in empty
        // space) -- should not discard the pending selection.
        state = state.beginSwipe().endSwipe(random: random);

        expect(state.selectedBubbleId, firstBubble.id);
        expect(state.lastOutcome, WordSlashOutcome.none);
      },
    );

    test(
      'starting a new round clears any pending selection from the previous round',
      () {
        final random = Random(1);
        final bigPool = List.generate(20, (i) => _word('seqadv$i'));
        var state = _stateWithWords(bigPool).beginFirstRound(random: random);
        final firstBubble = _bubblesForPair(
          state,
          state.bubbles.first.pairId,
        ).first;
        state = _swipeThrough(state, [firstBubble], random: random);
        expect(state.selectedBubbleId, isNotNull);
        final duration = WordSlashRoundConfig.forRound(1).duration;
        state = state.tickOnce(duration, random: random);

        state = state.advanceRound(random: random);

        expect(state.selectedBubbleId, isNull);
      },
    );
  });

  group('timer / round lifecycle', () {
    test('counts down each tick', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      final initial = state.roundTimeRemaining!;

      state = state.tickOnce(const Duration(seconds: 1), random: random);

      expect(state.roundTimeRemaining, initial - const Duration(seconds: 1));
    });

    test('reaching zero marks the round complete', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      final duration = WordSlashRoundConfig.forRound(1).duration;

      state = state.tickOnce(
        duration + const Duration(seconds: 5),
        random: random,
      );

      expect(state.roundTimeRemaining, Duration.zero);
      expect(state.isRoundComplete, isTrue);
    });

    test('no further movement/spawns happen once the round is complete', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      final duration = WordSlashRoundConfig.forRound(1).duration;
      state = state.tickOnce(duration, random: random);
      expect(state.isRoundComplete, isTrue);
      final bubblesAtComplete = state.bubbles;

      final again = state.tickOnce(
        const Duration(milliseconds: 500),
        random: random,
      );

      expect(again.bubbles, same(bubblesAtComplete));
      expect(again.roundTimeRemaining, Duration.zero);
    });

    test('a swipe after the round is complete is also a no-op', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      final duration = WordSlashRoundConfig.forRound(1).duration;
      state = state.tickOnce(duration, random: random);
      final pair = _bubblesForPair(state, state.bubbles.first.pairId);

      final result = _swipeThrough(state, pair, random: random);

      expect(result.lastOutcome, isNot(WordSlashOutcome.correct));
      expect(result.pairsMatched, 0);
    });
  });

  group('session lifecycle (sessionPhase)', () {
    test('tick is a no-op once the session is ending', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      state = state.endSession();
      final beforeTick = state;

      state = state.tickOnce(const Duration(seconds: 1), random: random);

      expect(state.roundTimeRemaining, beforeTick.roundTimeRemaining);
      expect(state.bubbles, beforeTick.bubbles);
    });

    test('swipe methods are a no-op once the session is ending', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      state = state.endSession();
      final pair = _bubblesForPair(state, state.bubbles.first.pairId);

      final result = _swipeThrough(state, pair, random: random);

      expect(result.lastOutcome, WordSlashOutcome.none);
      expect(result.pairsMatched, 0);
      expect(result.bubbles, hasLength(8)); // unchanged, not re-evaluated
    });

    test('tick is a no-op once disposed', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      state = state.endSession().markDisposed();

      final result = state.tickOnce(const Duration(seconds: 1), random: random);

      expect(result.bubbles, state.bubbles);
      expect(result.roundTimeRemaining, state.roundTimeRemaining);
    });

    test('endSession is idempotent', () {
      final random = Random(1);
      var state = _stateWithWords(words).beginFirstRound(random: random);
      state = state.endSession();
      final ended = state;

      state = state.endSession();

      expect(state.sessionPhase, ended.sessionPhase);
    });
  });

  group('round progression', () {
    test(
      'advanceRound resets score/combo/pairsMatched for the new round and increments roundNumber',
      () {
        final random = Random(1);
        final bigPool = List.generate(20, (i) => _word('adv$i'));
        var state = _stateWithWords(bigPool).beginFirstRound(random: random);
        final pair = _bubblesForPair(state, state.bubbles.first.pairId);
        state = _swipeThrough(state, pair, random: random);
        expect(state.score, greaterThan(0));
        // A correct pair adds a time bonus, so the round needs a bit more
        // than its nominal duration to actually reach zero.
        final duration =
            WordSlashRoundConfig.forRound(1).duration +
            const Duration(
              seconds: WordSlashRoundConfig.bonusSecondsPerCorrectPair,
            );
        state = state.tickOnce(duration, random: random);
        expect(state.isRoundComplete, isTrue);

        state = state.advanceRound(random: random);

        expect(state.roundNumber, 2);
        expect(state.score, 0);
        expect(state.combo, 0);
        expect(state.pairsMatched, 0);
        expect(state.isRoundComplete, isFalse);
        expect(state.bubbles, hasLength(8));
      },
    );

    test('advanceRound is a no-op past the final round', () {
      final random = Random(1);
      var state = _stateWithWords(words).startRound(
        roundNumber: WordSlashRoundConfig.totalRounds,
        random: random,
      );
      final beforeRoundNumber = state.roundNumber;

      state = state.advanceRound(random: random);

      expect(state.roundNumber, beforeRoundNumber);
    });

    test(
      'isRunComplete is true only once the final round is also complete',
      () {
        final random = Random(1);
        var state = _stateWithWords(words).startRound(
          roundNumber: WordSlashRoundConfig.totalRounds,
          random: random,
        );
        expect(state.isRunComplete, isFalse);

        final duration = WordSlashRoundConfig.forRound(
          WordSlashRoundConfig.totalRounds,
        ).duration;
        state = state.tickOnce(duration, random: random);

        expect(state.isRunComplete, isTrue);
      },
    );

    test('restartRun goes back to round 1 with a fresh state', () {
      final random = Random(1);
      final bigPool = List.generate(20, (i) => _word('pool$i'));
      var state = _stateWithWords(bigPool).startRound(
        roundNumber: WordSlashRoundConfig.totalRounds,
        random: random,
      );
      final duration = WordSlashRoundConfig.forRound(
        WordSlashRoundConfig.totalRounds,
      ).duration;
      state = state.tickOnce(duration, random: random);

      state = state.restartRun(random: random);

      expect(state.roundNumber, 1);
      expect(state.bubbles, hasLength(8));
      expect(state.isRoundComplete, isFalse);
    });

    test(
      'a word already used earlier in the run is eligible again once no longer active or queued -- '
      'words are never permanently "exhausted"',
      () {
        final random = Random(1);
        // A pool sized exactly for one round (4 pairs) -- startRound uses
        // all of it, so nothing is left in pendingWords afterwards.
        final fourWords = [_word('r1'), _word('r2'), _word('r3'), _word('r4')];
        var state = _stateWithWords(fourWords).beginFirstRound(random: random);
        expect(state.pendingWords, isEmpty);
        final solvedPairId = state.bubbles.first.pairId;
        final pair = _bubblesForPair(state, solvedPairId);
        state = _swipeThrough(state, pair, random: random);
        // The just-solved word had no replacement available (pool was
        // exhausted), so the round now runs with only 6 bubbles -- expected,
        // not a bug: nothing artificially blocks `solvedPairId` from being
        // offered again once it's no longer active anywhere.
        expect(state.bubbles, hasLength(6));

        state = state.withMoreCandidates([_word(solvedPairId)]);

        expect(state.pendingWords.map((w) => w.id), contains(solvedPairId));
      },
    );
  });

  group('accuracy', () {
    test(
      'is 0 with no attempts, and correctCount / total once there are some',
      () {
        final random = Random(1);
        final fresh = _stateWithWords(words).beginFirstRound(random: random);
        expect(fresh.accuracy, 0);

        var state = fresh;
        final correctPair = _bubblesForPair(state, state.bubbles.first.pairId);
        state = _swipeThrough(state, correctPair, random: random);
        final pairIds = state.bubbles.map((b) => b.pairId).toSet().toList();
        final mismatched = [
          _bubblesForPair(state, pairIds[0]).first,
          _bubblesForPair(state, pairIds[1]).first,
        ];
        state = _swipeThrough(state, mismatched, random: random);

        expect(state.correctCount, 1);
        expect(state.wrongCount, 1);
        expect(state.accuracy, 0.5);
      },
    );
  });

  group('word supply', () {
    test(
      'withMoreCandidates drops words already active on screen or already queued, including duplicates within the same batch',
      () {
        final random = Random(1);
        var state = _stateWithWords(words).beginFirstRound(random: random);
        final activePairId = state.bubbles.first.pairId;
        final alreadyQueuedId = state.pendingWords.first.id;

        state = state.withMoreCandidates([
          _word(activePairId), // already active on screen
          _word(alreadyQueuedId), // already queued
          _word('brand-new'),
          _word('brand-new'), // duplicated within this very call
        ]);

        final newWordCount = state.pendingWords
            .where((w) => w.id == 'brand-new')
            .length;
        expect(newWordCount, 1);
        expect(state.pendingWords.where((w) => w.id == activePairId), isEmpty);
      },
    );
  });

  group('overlapping bubbles', () {
    test(
      'registerSwipeSegment picks only the topmost (last-rendered) bubble when two fully overlap',
      () {
        const bottom = WordSlashBubble(
          id: 'bottom',
          pairId: 'p-bottom',
          text: 'a',
          isPortuguese: true,
          position: Offset(100, 100),
          velocity: Offset.zero,
          radius: 20,
        );
        const top = WordSlashBubble(
          id: 'top',
          pairId: 'p-top',
          text: 'b',
          isPortuguese: false,
          position: Offset(100, 100),
          velocity: Offset.zero,
          radius: 20,
        );
        // `top` is last in the list -- matches the screen widget's Stack
        // paint order, where later children are drawn on top.
        final state = const WordSlashSessionState(
          sessionPhase: WordSlashSessionPhase.running,
          roundTimeRemaining: Duration(seconds: 10),
          bubbles: [bottom, top],
        );

        final result = state.beginSwipe().registerSwipeSegment(
          const Offset(99, 100),
          const Offset(101, 100),
          hitPadding: 5,
        );

        expect(result.swipeHitBubbleIds, {'top'});
      },
    );

    test(
      'a single stroke can still register two different overlapping bubbles across separate segments',
      () {
        const a = WordSlashBubble(
          id: 'a',
          pairId: 'p-a',
          text: 'a',
          isPortuguese: true,
          position: Offset(100, 100),
          velocity: Offset.zero,
          radius: 20,
        );
        const b = WordSlashBubble(
          id: 'b',
          pairId: 'p-b',
          text: 'b',
          isPortuguese: false,
          position: Offset(200, 100),
          velocity: Offset.zero,
          radius: 20,
        );
        final state = const WordSlashSessionState(
          sessionPhase: WordSlashSessionPhase.running,
          roundTimeRemaining: Duration(seconds: 10),
          bubbles: [a, b],
        );

        final result = state
            .beginSwipe()
            .registerSwipeSegment(
              const Offset(99, 100),
              const Offset(101, 100),
              hitPadding: 5,
            )
            .registerSwipeSegment(
              const Offset(199, 100),
              const Offset(201, 100),
              hitPadding: 5,
            );

        expect(result.swipeHitBubbleIds, {'a', 'b'});
      },
    );
  });

  group('WordSlashBubble.intersectsSegment', () {
    test('hits when the segment passes through the bubble center', () {
      const bubble = WordSlashBubble(
        id: 'b',
        pairId: 'p',
        text: 'x',
        isPortuguese: true,
        position: Offset(100, 100),
        velocity: Offset.zero,
        radius: 20,
      );
      expect(
        bubble.intersectsSegment(
          const Offset(0, 100),
          const Offset(200, 100),
          padding: 0,
        ),
        isTrue,
      );
    });

    test('misses a segment far outside the padded radius', () {
      const bubble = WordSlashBubble(
        id: 'b',
        pairId: 'p',
        text: 'x',
        isPortuguese: true,
        position: Offset(100, 100),
        velocity: Offset.zero,
        radius: 20,
      );
      expect(
        bubble.intersectsSegment(
          const Offset(0, 500),
          const Offset(200, 500),
          padding: 5,
        ),
        isFalse,
      );
    });
  });
}
