import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/word_candidate.dart';
import '../services/distractor_picker.dart';

/// Read-only access to the `words` bank, shaped for the pure services
/// ([WordSelectionService], [DistractorPicker]) that don't know about the
/// database.
class WordRepository {
  const WordRepository(this._database);

  final AppDatabase _database;

  /// One [WordCandidate] per active word, left-joined with its
  /// `word_progress` row (a word may not have one yet -- lazy creation).
  Future<List<WordCandidate>> fetchCandidatePool() async {
    final query = _database.select(_database.words).join([
      leftOuterJoin(
        _database.wordProgress,
        _database.wordProgress.wordId.equalsExp(_database.words.id),
      ),
    ])..where(_database.words.isActive.equals(true));

    final rows = await query.get();
    return rows.map((row) {
      final word = row.readTable(_database.words);
      final progress = row.readTableOrNull(_database.wordProgress);
      return WordCandidate(
        wordId: word.id,
        category: word.category,
        recommendedLevel: word.recommendedLevel,
        masteryLevel: progress?.masteryLevel ?? 0,
        hasBeenIntroduced: progress != null,
        nextReviewAt: progress?.nextReviewAt,
        lastResultCorrect: progress?.lastResultCorrect,
      );
    }).toList();
  }

  Future<List<Word>> fetchActiveWords() =>
      (_database.select(_database.words)
            ..where((w) => w.isActive.equals(true)))
          .get();

  Future<Word?> fetchWordById(String id) =>
      (_database.select(
        _database.words,
      )..where((w) => w.id.equals(id))).getSingleOrNull();

  /// Every active word as a [DistractorCandidate], for [DistractorPicker].
  Future<List<DistractorCandidate>> fetchDistractorPool() async {
    final words = await fetchActiveWords();
    return words
        .map(
          (w) => DistractorCandidate(
            wordId: w.id,
            answerText: w.portugueseTranslation,
            category: w.category,
            difficulty: w.difficulty,
          ),
        )
        .toList();
  }
}
