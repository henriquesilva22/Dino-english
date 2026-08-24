/// Flattened, DB-independent view of one word plus its SRS state, as fed
/// into [WordSelectionService]. Built by the repository layer from a
/// `words` join `word_progress` (left join, since progress rows are
/// created lazily).
class WordCandidate {
  const WordCandidate({
    required this.wordId,
    required this.category,
    required this.recommendedLevel,
    required this.masteryLevel,
    required this.hasBeenIntroduced,
    this.nextReviewAt,
    this.lastResultCorrect,
  });

  final String wordId;
  final String category;
  final int recommendedLevel;
  final int masteryLevel;

  /// False when there is no `word_progress` row yet -- a genuinely new
  /// word, as opposed to a word at mastery 0 that was already shown and
  /// answered incorrectly (that one is "weak", not "new").
  final bool hasBeenIntroduced;

  final DateTime? nextReviewAt;
  final bool? lastResultCorrect;
}
