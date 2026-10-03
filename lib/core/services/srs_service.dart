/// Result of applying one answer to a word's spaced-repetition state.
class SrsAnswerResult {
  const SrsAnswerResult({
    required this.newMasteryLevel,
    required this.newStreak,
    required this.nextReviewAt,
  });

  final int newMasteryLevel;
  final int newStreak;

  /// Null means "always eligible" (mastery level 0 / just demoted to 0).
  final DateTime? nextReviewAt;
}

/// Spaced-repetition state machine for mastery levels 0-5.
///
/// Promotion is Duolingo/Anki-style consecutive-correct streaks; a wrong
/// answer drops one level (a "lapse"), not straight back to zero -- which
/// also keeps the tone non-punitive rather than erasing all progress on
/// one mistake.
class SrsService {
  const SrsService();

  static const int minMasteryLevel = 0;
  static const int maxMasteryLevel = 5;

  /// Consecutive correct answers needed to advance out of level `i`
  /// (index 0 = leaving level 0, ... index 4 = leaving level 4).
  static const List<int> _promotionThresholds = [1, 2, 2, 3, 3];

  /// Review interval, in days, once a word reaches this mastery level.
  static const Map<int, int> _intervalDays = {1: 1, 2: 3, 3: 7, 4: 14, 5: 30};

  SrsAnswerResult applyAnswer({
    required int currentMasteryLevel,
    required int currentStreak,
    required bool wasCorrect,
    required DateTime attemptedAt,
  }) {
    if (wasCorrect) {
      return _applyCorrectAnswer(
        currentMasteryLevel: currentMasteryLevel,
        currentStreak: currentStreak,
        attemptedAt: attemptedAt,
      );
    }
    return _applyWrongAnswer(
      currentMasteryLevel: currentMasteryLevel,
      attemptedAt: attemptedAt,
    );
  }

  SrsAnswerResult _applyCorrectAnswer({
    required int currentMasteryLevel,
    required int currentStreak,
    required DateTime attemptedAt,
  }) {
    final newStreak = currentStreak + 1;
    final promotionThreshold = currentMasteryLevel < _promotionThresholds.length
        ? _promotionThresholds[currentMasteryLevel]
        : null;

    final promotes =
        promotionThreshold != null &&
        newStreak >= promotionThreshold &&
        currentMasteryLevel < maxMasteryLevel;

    final resultingLevel = promotes
        ? currentMasteryLevel + 1
        : currentMasteryLevel;
    return SrsAnswerResult(
      newMasteryLevel: resultingLevel,
      newStreak: promotes ? 0 : newStreak,
      nextReviewAt: _reviewDateForLevel(resultingLevel, attemptedAt),
    );
  }

  SrsAnswerResult _applyWrongAnswer({
    required int currentMasteryLevel,
    required DateTime attemptedAt,
  }) {
    final newLevel = (currentMasteryLevel - 1).clamp(
      minMasteryLevel,
      maxMasteryLevel,
    );
    return SrsAnswerResult(
      newMasteryLevel: newLevel,
      newStreak: 0,
      nextReviewAt: _shortenedReviewDateForLevel(newLevel, attemptedAt),
    );
  }

  DateTime? _reviewDateForLevel(int level, DateTime attemptedAt) {
    final days = _intervalDays[level];
    if (days == null) return null; // level 0: always eligible
    return attemptedAt.add(Duration(days: days));
  }

  DateTime? _shortenedReviewDateForLevel(int level, DateTime attemptedAt) {
    final normalDays = _intervalDays[level];
    if (normalDays == null) return null; // level 0: always eligible
    final shortenedDays = (normalDays / 2).ceil().clamp(1, normalDays);
    return attemptedAt.add(Duration(days: shortenedDays));
  }
}
