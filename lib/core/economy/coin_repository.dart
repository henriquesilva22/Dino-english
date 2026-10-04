import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// The child's 🪙 coins (on the user profile, next to XP). Studying adds
/// them through `ProgressRepository.recordAnswer`; minigames through
/// [add]; the food shop spends them.
class CoinRepository {
  CoinRepository(this._database);

  final AppDatabase _database;

  Future<int> balance() async {
    final profile = await (_database.select(
      _database.userProfile,
    )..where((t) => t.id.equals(1))).getSingle();
    return profile.coins;
  }

  /// Adds [amount] (> 0) and returns the new balance.
  Future<int> add(int amount) {
    assert(amount >= 0, 'spending goes through the shop');
    return _database.transaction(() async {
      final next = await balance() + amount;
      await (_database.update(_database.userProfile)
            ..where((t) => t.id.equals(1)))
          .write(UserProfileCompanion(coins: Value(next)));
      return next;
    });
  }
}
