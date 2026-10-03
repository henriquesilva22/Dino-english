import 'dart:collection' show Queue;

import '../models/session_kind.dart';
import '../models/word_candidate.dart';

class _BucketMix {
  const _BucketMix({
    required this.newRatio,
    required this.overdueRatio,
    required this.weakRatio,
    required this.maintenanceRatio,
  });

  final double newRatio;
  final double overdueRatio;
  final double weakRatio;
  final double maintenanceRatio;

  /// Study mix: mostly new material with a meaningful review backbone.
  static const study = _BucketMix(
    newRatio: 0.4,
    overdueRatio: 0.3,
    weakRatio: 0.2,
    maintenanceRatio: 0.1,
  );

  /// Review mix: no new words, weighted toward what's overdue/weak.
  static const review = _BucketMix(
    newRatio: 0.0,
    overdueRatio: 0.5,
    weakRatio: 0.3,
    maintenanceRatio: 0.2,
  );

  Map<_Bucket, int> slotsFor(int count) {
    final newCount = (count * newRatio).round();
    final overdueCount = (count * overdueRatio).round();
    final weakCount = (count * weakRatio).round();
    final maintenanceCount = (count - newCount - overdueCount - weakCount)
        .clamp(0, count);
    return {
      _Bucket.newWord: newCount,
      _Bucket.overdue: overdueCount,
      _Bucket.weak: weakCount,
      _Bucket.maintenance: maintenanceCount,
    };
  }
}

enum _Bucket { newWord, overdue, weak, maintenance }

/// Builds a study/review session by blending candidate words into
/// priority buckets, in pure Dart -- no DB access, fully unit-testable.
///
/// Each candidate lands in exactly one bucket (see [_bucketFor]); the
/// target mix is filled per bucket and then backfilled, in priority
/// order overdue > weak > new > maintenance, if a bucket runs short --
/// which matters a lot for the ~240-word bank.
///
/// [count] is always honored as long as [pool] isn't empty: once every
/// candidate that's actually due/new/weak has been used once, this does
/// NOT return short. It keeps filling by cycling the whole pool as
/// maintenance repetition (weakest mastery first), so a study session can
/// request an arbitrarily large batch -- or be called over and over, batch
/// after batch -- and never run out of words as long as the bank itself
/// has content. See [_fillByRepetition].
class WordSelectionService {
  const WordSelectionService();

  List<WordCandidate> buildSession({
    required List<WordCandidate> pool,
    required SessionKind kind,
    required int userLevel,
    required DateTime now,
    int count = 10,
    String? recentCategory,
    int newWordLevelBuffer = 3,

    /// Word ids shown immediately before this call (e.g. the tail of the
    /// previous batch in an ongoing session) -- seeds the no-immediate-
    /// repeat window in [_fillByRepetition] so a batch boundary doesn't
    /// show the same word twice in a row. Purely advisory: an empty list
    /// (the default, and every existing call site) just means the window
    /// starts out seeded from this call's own selection instead.
    List<String> recentlyShownWordIds = const [],
  }) {
    final buckets = <_Bucket, List<WordCandidate>>{
      _Bucket.newWord: [],
      _Bucket.overdue: [],
      _Bucket.weak: [],
      _Bucket.maintenance: [],
    };

    for (final candidate in pool) {
      final bucket = _bucketFor(
        candidate,
        userLevel: userLevel,
        now: now,
        newWordLevelBuffer: newWordLevelBuffer,
      );
      if (bucket != null) buckets[bucket]!.add(candidate);
    }

    // Most-overdue-first within overdue/maintenance, then a stable
    // category-affinity boost on top of that ordering.
    for (final bucket in [_Bucket.overdue, _Bucket.maintenance]) {
      buckets[bucket]!.sort(
        (a, b) => (a.nextReviewAt ?? now).compareTo(b.nextReviewAt ?? now),
      );
    }
    for (final entry in buckets.entries) {
      buckets[entry.key] = _prioritizeByCategory(entry.value, recentCategory);
    }

    final mix = kind == SessionKind.study
        ? _BucketMix.study
        : _BucketMix.review;
    final targetSlots = mix.slotsFor(count);

    final selected = <WordCandidate>[];
    final selectedIds = <String>{};

    void takeFrom(_Bucket bucket, int maxToTake) {
      var remaining = maxToTake;
      for (final candidate in buckets[bucket]!) {
        if (selected.length >= count || remaining <= 0) break;
        if (selectedIds.add(candidate.wordId)) {
          selected.add(candidate);
          remaining--;
        }
      }
    }

    for (final bucket in _Bucket.values) {
      takeFrom(bucket, targetSlots[bucket]!);
    }

    if (selected.length < count) {
      for (final bucket in [
        _Bucket.overdue,
        _Bucket.weak,
        _Bucket.newWord,
        _Bucket.maintenance,
      ]) {
        takeFrom(bucket, count - selected.length);
        if (selected.length >= count) break;
      }
    }

    if (selected.length < count && pool.isNotEmpty) {
      _fillByRepetition(
        selected: selected,
        pool: pool,
        count: count,
        userLevel: userLevel,
        newWordLevelBuffer: newWordLevelBuffer,
        recentlyShownWordIds: recentlyShownWordIds,
      );
    }

    return selected;
  }

  /// The pool isn't "out of words" just because nothing is due/new/weak
  /// right now -- it's time for maintenance review. Cycles the pool,
  /// weakest mastery (then most-overdue) first, repeating as many times as
  /// needed to reach [count]. A small trailing window (seeded from
  /// [recentlyShownWordIds] plus whatever [selected] already holds) is
  /// skipped where possible so the same word never appears back-to-back --
  /// except when the pool is too small to avoid it at all, in which case
  /// repetition is unavoidable and expected (a 1-word pool repeats that
  /// word every time).
  ///
  /// Never-introduced words still above [userLevel] + [newWordLevelBuffer]
  /// are excluded here too -- repetition is for reviewing what's already
  /// been seen (or is otherwise due), not a backdoor for surfacing content
  /// the learner hasn't been paced into yet. That filter is dropped only
  /// if it would leave nothing at all to repeat, since never running out
  /// of words outranks pacing in that one corner case.
  void _fillByRepetition({
    required List<WordCandidate> selected,
    required List<WordCandidate> pool,
    required int count,
    required int userLevel,
    required int newWordLevelBuffer,
    required List<String> recentlyShownWordIds,
  }) {
    final eligiblePool = pool
        .where(
          (c) =>
              c.hasBeenIntroduced ||
              c.recommendedLevel <= userLevel + newWordLevelBuffer,
        )
        .toList();
    final ranked = [...(eligiblePool.isNotEmpty ? eligiblePool : pool)]
      ..sort((a, b) {
        final byMastery = a.masteryLevel.compareTo(b.masteryLevel);
        if (byMastery != 0) return byMastery;
        final aDue = a.nextReviewAt ?? DateTime(9999);
        final bDue = b.nextReviewAt ?? DateTime(9999);
        return aDue.compareTo(bDue);
      });

    final windowSize = (ranked.length - 1).clamp(0, 5);
    final recentIds = [
      ...recentlyShownWordIds,
      ...selected.map((c) => c.wordId),
    ];
    final recentWindow = Queue<String>.of(
      recentIds.length > windowSize
          ? recentIds.sublist(recentIds.length - windowSize)
          : recentIds,
    );

    var cursor = 0;
    var skippedInARow = 0;
    while (selected.length < count) {
      final candidate = ranked[cursor % ranked.length];
      cursor++;
      if (recentWindow.contains(candidate.wordId) &&
          skippedInARow < ranked.length) {
        skippedInARow++;
        continue;
      }
      skippedInARow = 0;
      selected.add(candidate);
      recentWindow.addLast(candidate.wordId);
      if (recentWindow.length > windowSize) recentWindow.removeFirst();
    }
  }

  _Bucket? _bucketFor(
    WordCandidate candidate, {
    required int userLevel,
    required DateTime now,
    required int newWordLevelBuffer,
  }) {
    if (!candidate.hasBeenIntroduced) {
      final withinLevelRange =
          candidate.recommendedLevel <= userLevel + newWordLevelBuffer;
      return withinLevelRange ? _Bucket.newWord : null;
    }
    if (candidate.lastResultCorrect == false) {
      return _Bucket.weak;
    }
    final isDue =
        candidate.nextReviewAt != null && !candidate.nextReviewAt!.isAfter(now);
    if (!isDue) return null;
    return candidate.masteryLevel >= 5 ? _Bucket.maintenance : _Bucket.overdue;
  }

  List<WordCandidate> _prioritizeByCategory(
    List<WordCandidate> bucket,
    String? recentCategory,
  ) {
    if (recentCategory == null) return bucket;
    final matching = <WordCandidate>[];
    final rest = <WordCandidate>[];
    for (final candidate in bucket) {
      (candidate.category == recentCategory ? matching : rest).add(candidate);
    }
    return [...matching, ...rest];
  }
}
