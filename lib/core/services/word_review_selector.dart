import 'dart:math';

/// One word from the bank as the review sees it: what the child did with
/// it (studied, got wrong, met in a conversation...).
class ReviewCandidate {
  const ReviewCandidate({
    required this.wordId,
    required this.english,
    required this.portuguese,
    this.studied = false,
    this.metInConversation = false,
    this.lastResultCorrect,
    this.incorrectCount = 0,
    this.lastSeenAt,
  });

  final String wordId;
  final String english;
  final String portuguese;

  /// Has a `word_progress` row (shown in a lesson or game).
  final bool studied;

  /// Talked about with the Dino.
  final bool metInConversation;
  final bool? lastResultCorrect;
  final int incorrectCount;
  final DateTime? lastSeenAt;

  bool get encountered => studied || metInConversation;
}

/// Picks the few words shown in the profile's "Revisão de palavras":
/// different ones over time, no duplicates, words the child already met
/// first -- the ones got wrong or seen recently most of all. Pure: it
/// never changes XP, coins or mastery.
class WordReviewSelector {
  const WordReviewSelector();

  static const int defaultCount = 5;

  List<ReviewCandidate> select(
    List<ReviewCandidate> pool, {
    required Random random,
    required DateTime now,
    int count = defaultCount,
  }) {
    // One entry per English word (a word may be in the bank twice).
    final unique = <String, ReviewCandidate>{};
    for (final c in pool) {
      final key = c.english.trim().toLowerCase();
      if (key.isEmpty || c.portuguese.trim().isEmpty) continue;
      final kept = unique[key];
      if (kept == null || _weight(c, now) > _weight(kept, now)) unique[key] = c;
    }
    final met = unique.values.where((c) => c.encountered).toList();
    final fresh = unique.values.where((c) => !c.encountered).toList();
    final chosen = _weighted(met, count, random, now);
    // Not enough words met yet: complete with new ones from the bank.
    if (chosen.length < count) {
      fresh.shuffle(random);
      chosen.addAll(fresh.take(count - chosen.length));
    }
    return chosen;
  }

  /// Wrong lately > got wrong before > seen this week > seen before.
  static double _weight(ReviewCandidate c, DateTime now) {
    if (!c.encountered) return 0.5;
    var w = 2.0;
    if (c.lastResultCorrect == false) {
      w = 6;
    } else if (c.incorrectCount > 0) {
      w = 4;
    }
    final seen = c.lastSeenAt;
    if (seen != null && now.difference(seen).inDays < 7) w += 1.5;
    if (c.metInConversation) w += 0.5;
    return w;
  }

  /// [count] distinct items, each drawn with probability ∝ its weight.
  static List<ReviewCandidate> _weighted(
    List<ReviewCandidate> items,
    int count,
    Random random,
    DateTime now,
  ) {
    final left = [...items];
    final picked = <ReviewCandidate>[];
    while (picked.length < count && left.isNotEmpty) {
      final weights = [for (final c in left) _weight(c, now)];
      final total = weights.fold(0.0, (a, b) => a + b);
      var roll = random.nextDouble() * total;
      var index = left.length - 1;
      for (var i = 0; i < left.length; i++) {
        roll -= weights[i];
        if (roll <= 0) {
          index = i;
          break;
        }
      }
      picked.add(left.removeAt(index));
    }
    return picked;
  }
}
