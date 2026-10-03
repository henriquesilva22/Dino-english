import 'package:drift/drift.dart';

/// What the Dino remembers from conversations (DinoBrain): preferences,
/// words discussed/practised, activities, tasks and important facts.
///
/// Deliberately separate from [Words] (the official vocabulary): nothing
/// said in a conversation ever writes to the word bank, so a wrong answer
/// can never change an official translation. [kind] is an open string
/// vocabulary (`DinoMemoryKind.name`), so a new kind is never a
/// migration. Added in schema v2.
@DataClassName('DinoMemoryRow')
class DinoMemories extends Table {
  TextColumn get kind => text()();

  /// Kind-specific key, e.g. `food` for a `preference`, a word id for a
  /// `learnedWord`.
  TextColumn get memoryKey => text()();
  TextColumn get value => text()();

  /// 0..1 -- how sure the Dino is (e.g. a learned word's mastery in
  /// conversation, or a word a child taught that isn't in the bank).
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  IntColumn get timesReinforced => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {kind, memoryKey};
}
