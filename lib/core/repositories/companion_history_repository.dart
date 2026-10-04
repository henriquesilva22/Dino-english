import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// One saved exchange with the companion.
class CompanionHistoryEntry {
  const CompanionHistoryEntry({
    this.childText,
    this.viaVoice = false,
    required this.englishText,
    this.portugueseText,
    this.intent,
    this.word,
    required this.createdAt,
  });

  final String? childText;
  final bool viaVoice;
  final String englishText;
  final String? portugueseText;
  final String? intent;
  final String? word;
  final DateTime createdAt;
}

/// The companion's conversation history in the app database.
class CompanionHistoryRepository {
  const CompanionHistoryRepository(this._database);

  final AppDatabase _database;

  /// Keeps the table small: older rows beyond this are deleted.
  static const int maxEntries = 300;

  Future<void> add(CompanionHistoryEntry entry) async {
    await _database
        .into(_database.companionHistory)
        .insert(
          CompanionHistoryCompanion.insert(
            childText: Value(entry.childText),
            viaVoice: Value(entry.viaVoice),
            englishText: entry.englishText,
            portugueseText: Value(entry.portugueseText),
            intent: Value(entry.intent),
            word: Value(entry.word),
            createdAt: entry.createdAt,
          ),
        );
    // Trim: keep only the newest [maxEntries].
    await _database.customStatement(
      'DELETE FROM companion_history WHERE id NOT IN '
      '(SELECT id FROM companion_history ORDER BY id DESC LIMIT $maxEntries)',
    );
  }

  /// The newest [limit] exchanges, oldest first.
  Future<List<CompanionHistoryEntry>> recent({int limit = 40}) async {
    final rows =
        await (_database.select(_database.companionHistory)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(limit))
            .get();
    return [
      for (final r in rows.reversed)
        CompanionHistoryEntry(
          childText: r.childText,
          viaVoice: r.viaVoice,
          englishText: r.englishText,
          portugueseText: r.portugueseText,
          intent: r.intent,
          word: r.word,
          createdAt: r.createdAt,
        ),
    ];
  }
}
