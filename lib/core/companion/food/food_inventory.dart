import 'food_item.dart';

/// What the panel shows for a food.
enum FoodStatus { locked, available }

/// The child's 🪙 coins and the foods they can give the Dino.
class FoodInventory {
  const FoodInventory({required this.coins, required this.unlockedIds});

  final int coins;

  /// Bought foods (free foods are always available, stored or not).
  final Set<String> unlockedIds;

  bool isUnlocked(FoodItem food) =>
      food.isFree || unlockedIds.contains(food.id);

  FoodStatus statusOf(FoodItem food) =>
      isUnlocked(food) ? FoodStatus.available : FoodStatus.locked;

  bool canAfford(FoodItem food) => coins >= food.price;

  /// Coins still missing to buy [food] (0 when affordable).
  int missingFor(FoodItem food) => canAfford(food) ? 0 : food.price - coins;
}

/// Result of trying to buy a food.
sealed class PurchaseResult {
  const PurchaseResult();
}

class Purchased extends PurchaseResult {
  const Purchased({required this.food, required this.coinsLeft});
  final FoodItem food;
  final int coinsLeft;
}

class NotEnoughCoins extends PurchaseResult {
  const NotEnoughCoins({required this.price, required this.coins});
  final int price;
  final int coins;
}

class AlreadyUnlocked extends PurchaseResult {
  const AlreadyUnlocked();
}
