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
/// which matters a lot for the MVP's ~120-word bank.
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

    final mix = kind == SessionKind.study ? _BucketMix.study : _BucketMix.review;
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

    return selected;
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
        candidate.nextReviewAt != null &&
        !candidate.nextReviewAt!.isAfter(now);
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
