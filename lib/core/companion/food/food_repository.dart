import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import 'food_inventory.dart';
import 'food_item.dart';

/// The Dino's food shop on the local database: 🪙 coins (on the user
/// profile, next to XP), bought foods, and whether the drag hint was
/// already learned. Works fully offline.
class FoodRepository {
  FoodRepository(this._database);

  final AppDatabase _database;

  Future<FoodInventory> load() async {
    final profile = await (_database.select(
      _database.userProfile,
    )..where((t) => t.id.equals(1))).getSingle();
    final unlocked = await _database.select(_database.foodUnlocks).get();
    return FoodInventory(
      coins: profile.coins,
      unlockedIds: {for (final row in unlocked) row.foodId},
    );
  }

  /// Spends the coins and unlocks [food] in one transaction: the balance
  /// never goes negative and a food is never paid twice.
  Future<PurchaseResult> buy(FoodItem food, {DateTime? now}) {
    return _database.transaction(() async {
      final inventory = await load();
      if (inventory.isUnlocked(food)) return const AlreadyUnlocked();
      if (!inventory.canAfford(food)) {
        return NotEnoughCoins(price: food.price, coins: inventory.coins);
      }
      final left = inventory.coins - food.price;
      await (_database.update(_database.userProfile)
            ..where((t) => t.id.equals(1)))
          .write(UserProfileCompanion(coins: Value(left)));
      await _database
          .into(_database.foodUnlocks)
          .insert(
            FoodUnlocksCompanion.insert(
              foodId: food.id,
              unlockedAt: now ?? DateTime.now(),
            ),
          );
      return Purchased(food: food, coinsLeft: left);
    });
  }

  Future<bool> hintSeen() async {
    final settings = await (_database.select(
      _database.appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    return settings?.foodHintSeen ?? false;
  }

  Future<void> markHintSeen() =>
      (_database.update(_database.appSettings)..where((t) => t.id.equals(1)))
          .write(const AppSettingsCompanion(foodHintSeen: Value(true)));
}
