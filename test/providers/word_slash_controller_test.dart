import 'dart:ui' show Offset, Size;

import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/game/sound/word_slash_sfx.dart';
import 'package:dino_english/game/sound/word_slash_sound_service.dart';
import 'package:dino_english/game/word_slash/word_slash_round_config.dart';
import 'package:dino_english/game/word_slash/word_slash_session_state.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/word_slash_providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never touches a real `AudioPool`/`AudioCache` (platform-channel-backed)
/// -- mirrors `_FakeAdventureSoundService` in
/// `pet_adventure_game_screen_lifecycle_test.dart`. `WordSlashController
/// .build()` always calls `preload()`, so every test in this file needs
/// this override regardless of whether it cares about audio.
class _FakeWordSlashSoundService implements WordSlashSoundService {
  @override
  Future<void> preload() async {}

  @override
  void play(WordSlashSfx sfx) {}
}

WordsCompanion _word(String id) {
  return WordsCompanion.insert(
    id: id,
    englishTerm: id,
    portugueseTranslation: '$id (pt)',
    category: 'test',
    difficulty: 1,
    recommendedLevel: 1,
    exampleSentenceEn: 'This is $id.',
    exampleSentencePt: 'Isto é $id.',
  );
}

Future<AppDatabase> _seededDatabase(int wordCount) async {
  final database = AppDatabase(NativeDatabase.memory());
  await database
      .into(database.userProfile)
      .insertOnConflictUpdate(
        UserProfileCompanion.insert(
          id: const Value(1),
          createdAt: DateTime(2026),
        ),
      );
  await database
      .into(database.dinoEvolutionState)
      .insertOnConflictUpdate(
        DinoEvolutionStateCompanion.insert(id: const Value(1)),
      );
  for (var i = 0; i < wordCount; i++) {
    await database.into(database.words).insert(_word('slashword$i'));
  }
  return database;
}

/// Widens `playAreaSize` well beyond any real screen, then simulates a
/// few real seconds of movement so the very first round's bubbles (spawned
/// within the small pre-widen default area) actually have time to travel
/// out into the new open space -- a zero-duration tick would only change
/// the boundary, not move anything. Later spawns (replacements) are
/// already born into the widened area, so this matters most for that
/// first round.
void _widenPlayArea(WordSlashController notifier) {
  notifier.tick(Duration.zero, const Size(5000, 5000));
  notifier.tick(const Duration(seconds: 3), const Size(5000, 5000));
}

/// Finds [count] pairIds whose bubbles are each far enough from every
/// *other* bubble that a swipe simulated as a tiny segment through the
/// target's exact center (see [_swipeThroughPair]) cannot possibly also
/// graze one of them -- avoids the test depending on the controller's
/// real, unseeded `Random` happening to spread the (small, fixed) number
/// of bubbles apart by luck. Retries across a few small ticks (which
/// reshuffle positions) in the unlikely case the current layout has too
/// few clean pairs; only meaningfully needed for the very first round's
/// initial bubbles, since every later, post-[_widenPlayArea] spawn already
/// has a huge area to spread out in.
List<String> _findCleanPairIds(
  WordSlashController notifier,
  ProviderContainer container, {
  required int count,
}) {
  for (var attempt = 0; attempt < 20; attempt++) {
    final state = container.read(wordSlashControllerProvider);
    final hitPadding = WordSlashRoundConfig.forRound(
      state.roundNumber,
    ).hitPadding;
    final minSafeDistance =
        WordSlashRoundConfig.bubbleRadius * 2 + hitPadding + 1;
    final clean = <String>[];
    for (final pairId in state.bubbles.map((b) => b.pairId).toSet()) {
      final target = state.bubbles.where((b) => b.pairId == pairId).toList();
      final others = state.bubbles.where((b) => b.pairId != pairId);
      final safe = target.every(
        (t) => others.every(
          (o) => (o.position - t.position).distance > minSafeDistance,
        ),
      );
      if (safe) clean.add(pairId);
    }
    if (clean.length >= count) return clean.take(count).toList();
    notifier.tick(const Duration(milliseconds: 500), const Size(5000, 5000));
  }
  throw StateError('could not find $count uncontested pairs after retries');
}

void _swipeThroughPair(
  WordSlashController notifier,
  ProviderContainer container,
  String pairId,
) {
  final state = container.read(wordSlashControllerProvider);
  final bubbles = state.bubbles.where((b) => b.pairId == pairId).toList();
  notifier.beginSwipe();
  for (final bubble in bubbles) {
    notifier.registerSwipeSegment(
      bubble.position - const Offset(1, 1),
      bubble.position + const Offset(1, 1),
    );
  }
  notifier.endSwipe();
}

void main() {
  late AppDatabase database;
  late ProviderContainer container;
  late ProviderSubscription<WordSlashSessionState> subscription;

  Future<void> setUpWith(int wordCount) async {
    database = await _seededDatabase(wordCount);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        wordSlashSoundServiceProvider.overrideWithValue(
          _FakeWordSlashSoundService(),
        ),
      ],
    );
  }

  tearDown(() async {
    subscription.close();
    container.dispose();
    await database.close();
  });

  /// Mirrors `study_session_controller_test.dart`'s `awaitLoaded`: the
  /// initial word fetch is fire-and-forget from `build()`, and the
  /// provider is `.autoDispose`, so a subscription must be established
  /// before polling or it would be torn down and rebuilt every iteration.
  Future<WordSlashSessionState> awaitLoaded() async {
    subscription = container.listen(wordSlashControllerProvider, (_, _) {});
    while (subscription.read().roundTimeRemaining == null) {
      await Future<void>.delayed(Duration.zero);
    }
    _widenPlayArea(container.read(wordSlashControllerProvider.notifier));
    return container.read(wordSlashControllerProvider);
  }

  test(
    'a correct pair records exactly one exercise_attempts row and grants exactly the fixed XP, not per-frame or doubled',
    () async {
      await setUpWith(6);
      await awaitLoaded();
      final notifier = container.read(wordSlashControllerProvider.notifier);
      final pairId = _findCleanPairIds(notifier, container, count: 1).single;

      _swipeThroughPair(notifier, container, pairId);
      // resolvePair's XP/history write is awaited internally via
      // unawaited(), so give it a turn to actually land before asserting.
      await Future<void>.delayed(Duration.zero);
      // A couple of harmless extra frames -- must not record anything more.
      notifier.tick(const Duration(milliseconds: 16), const Size(5000, 5000));
      notifier.tick(const Duration(milliseconds: 16), const Size(5000, 5000));
      await Future<void>.delayed(Duration.zero);

      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, hasLength(1));
      expect(attempts.single.exerciseType, 'word_slash');
      expect(attempts.single.sessionKind, 'review');
      expect(attempts.single.wasCorrect, isTrue);
      expect(attempts.single.xpAwarded, 5);

      final profile = await database.select(database.userProfile).getSingle();
      expect(profile.totalXp, 5);
    },
  );

  test(
    'a wrong pair records an attempt with wordId null and zero XP',
    () async {
      await setUpWith(6);
      await awaitLoaded();
      final notifier = container.read(wordSlashControllerProvider.notifier);
      final pairIds = _findCleanPairIds(notifier, container, count: 2);
      final state = container.read(wordSlashControllerProvider);
      final mismatched = [
        state.bubbles.firstWhere((b) => b.pairId == pairIds[0]),
        state.bubbles.firstWhere((b) => b.pairId == pairIds[1]),
      ];

      notifier.beginSwipe();
      for (final bubble in mismatched) {
        notifier.registerSwipeSegment(
          bubble.position - const Offset(1, 1),
          bubble.position + const Offset(1, 1),
        );
      }
      notifier.endSwipe();
      await Future<void>.delayed(Duration.zero);

      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, hasLength(1));
      expect(attempts.single.wordId, isNull);
      expect(attempts.single.wasCorrect, isFalse);
      expect(attempts.single.xpAwarded, 0);
    },
  );

  test(
    'endSession stops the round -- a tick afterwards changes nothing',
    () async {
      await setUpWith(6);
      await awaitLoaded();
      final notifier = container.read(wordSlashControllerProvider.notifier);
      final before = container.read(wordSlashControllerProvider);

      await notifier.endSession();
      notifier.tick(const Duration(seconds: 1), const Size(5000, 5000));

      final after = container.read(wordSlashControllerProvider);
      expect(after.sessionPhase, WordSlashSessionPhase.ending);
      expect(after.roundTimeRemaining, before.roundTimeRemaining);
      expect(after.bubbles, before.bubbles);
    },
  );

  test(
    'a swipe after endSession is a no-op -- no attempt is recorded',
    () async {
      await setUpWith(6);
      await awaitLoaded();
      final notifier = container.read(wordSlashControllerProvider.notifier);
      // Pick the target *before* ending the session -- once ended, tick()
      // (which the retry loop in _findCleanPairIds relies on) is a no-op.
      final pairId = _findCleanPairIds(notifier, container, count: 1).single;

      await notifier.endSession();
      _swipeThroughPair(notifier, container, pairId);
      await Future<void>.delayed(Duration.zero);

      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, isEmpty);
    },
  );

  test(
    'closing the old subscription and starting a new one creates a fresh, higher sessionId -- proof '
    'reentering the game is a genuinely new session, never the old one still alive',
    () async {
      await setUpWith(6);
      await awaitLoaded();
      final firstId = container
          .read(wordSlashControllerProvider.notifier)
          .sessionId;

      // Mirrors what really happens on screen exit/reentry: the widget's
      // `ref.watch` unsubscribes (listener count hits zero), `.autoDispose`
      // tears the old instance down, and a fresh `ref.watch` from the
      // newly-mounted screen creates a brand new one -- not
      // `container.invalidate()` while a listener is still attached, which
      // (confirmed while writing this test) rebuilds the *same* instance
      // in place instead, an artificial scenario this app's real
      // navigation never triggers.
      subscription.close();
      // `.autoDispose` teardown is debounced onto a microtask, not
      // synchronous with the last listener leaving (also confirmed while
      // writing this test) -- closing and re-listening back-to-back with
      // no real gap can still land on the not-yet-disposed instance. A
      // couple of real event-loop turns give the scheduled disposal a
      // chance to actually run first.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      subscription = container.listen(wordSlashControllerProvider, (_, _) {});
      while (subscription.read().roundTimeRemaining == null) {
        await Future<void>.delayed(Duration.zero);
      }
      final secondId = container
          .read(wordSlashControllerProvider.notifier)
          .sessionId;

      expect(secondId, greaterThan(firstId));
    },
  );

  test(
    'a word bank sized for exactly one round (4 pairs) still keeps supplying pairs after several correct '
    'answers -- WordSelectionService\'s repetition guarantee reaches the real controller, words are never '
    '"exhausted"',
    () async {
      await setUpWith(4); // exactly pairsOnScreen -- no spare words at all
      final state = await awaitLoaded();
      final notifier = container.read(wordSlashControllerProvider.notifier);
      expect(state.bubbles, hasLength(8));

      // Solve several pairs in a row -- with only 3 distinct words ever
      // existing, every replacement necessarily repeats one already seen.
      for (var i = 0; i < 4; i++) {
        final pairId = _findCleanPairIds(notifier, container, count: 1).single;
        _swipeThroughPair(notifier, container, pairId);
        // Let the background top-up (which calls WordSelectionService
        // through the real DB) get a turn to run.
        for (var j = 0; j < 20; j++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      // The answers are written by real (async) DB transactions: wait for
      // them instead of a fixed number of event-loop turns, which was
      // flaky when the whole suite runs in parallel.
      var attempts = await database.select(database.exerciseAttempts).get();
      for (
        var t = 0;
        t < 100 && attempts.where((a) => a.wasCorrect).length < 4;
        t++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        attempts = await database.select(database.exerciseAttempts).get();
      }
      expect(attempts.where((a) => a.wasCorrect), hasLength(4));
    },
  );
}
