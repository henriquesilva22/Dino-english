import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/word_review_selector.dart';
import 'repository_providers.dart';

/// Bumped by the "🔄" button and whenever the profile is opened again: a
/// new set of review words. The set stays the same in between.
class WordReviewRound extends Notifier<int> {
  @override
  int build() => 0;

  void next() => state++;
}

final wordReviewRoundProvider = NotifierProvider<WordReviewRound, int>(
  WordReviewRound.new,
);

/// The profile's "Revisão de palavras": a few English words with their
/// meaning, from the official word bank (read only -- showing them never
/// changes XP, coins or mastery).
final wordReviewProvider = FutureProvider.autoDispose<List<ReviewCandidate>>((
  ref,
) async {
  ref.watch(wordReviewRoundProvider);
  final pool = await ref.watch(wordRepositoryProvider).fetchReviewPool();
  return const WordReviewSelector().select(
    pool,
    random: Random(),
    now: DateTime.now(),
  );
});
