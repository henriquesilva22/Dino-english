import 'package:drift/drift.dart';

import '../brain/memory/dino_memory.dart';
import '../database/app_database.dart';

/// Drift-backed [DinoMemoryStore]: the Dino's conversation memory lives in
/// `dino_memories`, fully separate from the official `words` table.
class DriftDinoMemoryStore implements DinoMemoryStore {
  const DriftDinoMemoryStore(this._database);

  final AppDatabase _database;

  @override
  Future<List<DinoMemory>> loadAll() async {
    final rows = await _database.select(_database.dinoMemories).get();
    final memories = <DinoMemory>[];
    for (final row in rows) {
      final kind = DinoMemoryKind.values.asNameMap()[row.kind];
      // A kind written by a newer app version is skipped, not a crash.
      if (kind == null) continue;
      memories.add(
        DinoMemory(
          kind: kind,
          key: row.memoryKey,
          value: row.value,
          confidence: row.confidence,
          timesReinforced: row.timesReinforced,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      );
    }
    return memories;
  }

  @override
  Future<void> save(DinoMemory memory) => _database
      .into(_database.dinoMemories)
      .insertOnConflictUpdate(
        DinoMemoriesCompanion.insert(
          kind: memory.kind.name,
          memoryKey: memory.key,
          value: memory.value,
          confidence: Value(memory.confidence),
          timesReinforced: Value(memory.timesReinforced),
          createdAt: memory.createdAt,
          updatedAt: memory.updatedAt,
        ),
      );

  @override
  Future<void> delete(DinoMemoryKind kind, String key) => (_database.delete(
    _database.dinoMemories,
  )..where((t) => t.kind.equals(kind.name) & t.memoryKey.equals(key))).go();
}
