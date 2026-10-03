import 'dart:math';

/// One candidate and how far it is from what the child typed.
class FuzzyCandidate {
  const FuzzyCandidate(this.value, this.distance);

  final String value;
  final int distance;

  @override
  String toString() => 'FuzzyCandidate($value, $distance)';
}

enum FuzzyOutcome {
  /// Typed exactly (after normalization).
  exact,

  /// One clear best candidate within tolerance ("woter" -> "water").
  corrected,

  /// Close to something, but the Dino should ask before assuming: several
  /// candidates tie ("bet" -> bed / bad) or the word is so short that a
  /// single typo could be anything.
  ambiguous,

  /// Nothing close enough.
  none,
}

class FuzzyResult {
  const FuzzyResult(this.outcome, this.candidates);

  const FuzzyResult.none() : outcome = FuzzyOutcome.none, candidates = const [];

  final FuzzyOutcome outcome;

  /// Best candidates, closest first (one for exact/corrected, up to
  /// [FuzzyMatcher.maxAmbiguousOptions] for ambiguous).
  final List<FuzzyCandidate> candidates;

  FuzzyCandidate? get best => candidates.isEmpty ? null : candidates.first;
}

/// Spelling-tolerant lookup for children's typos, using the optimal string
/// alignment variant of Damerau-Levenshtein (a swap like "dgo" -> "dog"
/// costs 1, not 2).
class FuzzyMatcher {
  const FuzzyMatcher();

  static const int maxAmbiguousOptions = 3;

  /// How many edits a word of [length] letters tolerates. Short words get
  /// none-to-little slack: "cat"/"car"/"cap" are all one edit apart.
  int maxDistanceFor(int length) {
    if (length <= 2) return 0;
    if (length <= 5) return 1;
    return 2;
  }

  FuzzyResult match(String input, Iterable<String> candidates) {
    final query = input.toLowerCase().trim();
    if (query.isEmpty) return const FuzzyResult.none();

    final maxDistance = maxDistanceFor(query.length);
    final scored = <FuzzyCandidate>[];
    for (final candidate in candidates) {
      final c = candidate.toLowerCase();
      if (c == query) {
        return FuzzyResult(FuzzyOutcome.exact, [FuzzyCandidate(candidate, 0)]);
      }
      if ((c.length - query.length).abs() > maxDistance) continue;
      final d = distance(query, c);
      if (d <= maxDistance) scored.add(FuzzyCandidate(candidate, d));
    }
    if (scored.isEmpty) return const FuzzyResult.none();

    scored.sort((a, b) {
      final byDistance = a.distance.compareTo(b.distance);
      return byDistance != 0 ? byDistance : a.value.compareTo(b.value);
    });
    final bestDistance = scored.first.distance;
    final tied = scored.where((c) => c.distance == bestDistance).toList();

    // 3-letter words: one typo is too ambiguous to auto-correct silently.
    final tooShortToTrust = query.length <= 3;
    if (tied.length == 1 && !tooShortToTrust) {
      return FuzzyResult(FuzzyOutcome.corrected, [tied.single]);
    }
    return FuzzyResult(
      FuzzyOutcome.ambiguous,
      scored.take(maxAmbiguousOptions).toList(growable: false),
    );
  }

  /// Optimal string alignment distance.
  static int distance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final rows = a.length + 1;
    final cols = b.length + 1;
    final d = List.generate(rows, (_) => List<int>.filled(cols, 0));
    for (var i = 0; i < rows; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      d[0][j] = j;
    }
    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        var value = min(
          min(d[i - 1][j] + 1, d[i][j - 1] + 1),
          d[i - 1][j - 1] + cost,
        );
        if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
          value = min(value, d[i - 2][j - 2] + 1);
        }
        d[i][j] = value;
      }
    }
    return d[a.length][b.length];
  }
}
