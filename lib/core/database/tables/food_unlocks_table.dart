import 'package:drift/drift.dart';

/// Foods the child bought for the Dino. Free foods are never stored: they
/// are always available.
@DataClassName('FoodUnlockRow')
class FoodUnlocks extends Table {
  TextColumn get foodId => text()();
  DateTimeColumn get unlockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {foodId};
}
