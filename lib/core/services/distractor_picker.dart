import 'dart:math';

/// Minimal view of a word needed to generate multiple-choice distractors.
class DistractorCandidate {
  const DistractorCandidate({
    required this.wordId,
    required this.answerText,
    required this.category,
    required this.difficulty,
  });

  final String wordId;
  final String answerText;
  final String category;
  final int difficulty;
}

/// Picks plausible wrong answers at runtime -- never stored, so adding a
/// distractor-based exercise type never needs a DB migration.
class DistractorPicker {
  const DistractorPicker();

  /// Prefers same-category, similar-difficulty candidates first, then
  /// widens to same-category, then to the full pool -- so it degrades
  /// gracefully when a category has fewer candidates than [count]
  /// (expected with a small seed word bank). Never includes [correct].
  List<DistractorCandidate> pickDistractors({
    required DistractorCandidate correct,
    required List<DistractorCandidate> pool,
    int count = 3,
    Random? random,
  }) {
    final rng = random ?? Random();
    final eligible = pool
        .where(
          (c) =>
              c.wordId != correct.wordId && c.answerText != correct.answerText,
        )
        .toList();

    final closeMatch = eligible
        .where(
          (c) =>
              c.category == correct.category &&
              (c.difficulty - correct.difficulty).abs() <= 1,
        )
        .toList()
      ..shuffle(rng);
    final sameCategory = eligible.where((c) => c.category == correct.category).toList()
      ..shuffle(rng);
    final anyEligible = List.of(eligible)..shuffle(rng);

    final result = <DistractorCandidate>[];
    final usedIds = <String>{};
    for (final tier in [closeMatch, sameCategory, anyEligible]) {
      if (result.length >= count) break;
      for (final candidate in tier) {
        if (result.length >= count) break;
        if (usedIds.add(candidate.wordId)) {
          result.add(candidate);
        }
      }
    }
    return result;
  }
}
