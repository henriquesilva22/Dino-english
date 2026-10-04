/// Kind of food (for later grouping in the panel).
enum FoodCategory { bakery, fruit, sweet, meal }

/// One food the child can give the Dino. All numbers live here so the
/// economy can be balanced in one place; whether a food is unlocked comes
/// from the [FoodInventory], not from the item.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.englishName,
    required this.emoji,
    required this.price,
    required this.hungerRestore,
    required this.happinessReward,
    required this.xpReward,
    required this.category,
  });

  final String id;

  /// Portuguese name ("Pão").
  final String name;

  /// English name ("Bread"), the word the child learns.
  final String englishName;

  /// The food's icon: the app draws foods with emoji.
  final String emoji;

  /// 🪙 coins to unlock; 0 = always available.
  final int price;

  /// How much the 🍎 meter fills.
  final double hungerRestore;

  /// How much the ❤️ meter fills.
  final double happinessReward;

  /// XP for feeding the Dino with it (still capped by the daily care cap).
  final int xpReward;
  final FoodCategory category;

  bool get isFree => price == 0;

  @override
  bool operator ==(Object other) => other is FoodItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FoodItem($id)';
}

/// The foods in the game, cheapest first. Add a food = add a line.
abstract final class FoodCatalog {
  static const bread = FoodItem(
    id: 'bread',
    name: 'Pão',
    englishName: 'Bread',
    emoji: '🍞',
    price: 0,
    hungerRestore: 10,
    happinessReward: 5,
    xpReward: 5,
    category: FoodCategory.bakery,
  );

  static const apple = FoodItem(
    id: 'apple',
    name: 'Maçã',
    englishName: 'Apple',
    emoji: '🍎',
    price: 0,
    hungerRestore: 8,
    happinessReward: 8,
    xpReward: 5,
    category: FoodCategory.fruit,
  );

  static const banana = FoodItem(
    id: 'banana',
    name: 'Banana',
    englishName: 'Banana',
    emoji: '🍌',
    price: 30,
    hungerRestore: 12,
    happinessReward: 8,
    xpReward: 5,
    category: FoodCategory.fruit,
  );

  static const cookie = FoodItem(
    id: 'cookie',
    name: 'Biscoito',
    englishName: 'Cookie',
    emoji: '🍪',
    price: 50,
    hungerRestore: 5,
    happinessReward: 12,
    xpReward: 5,
    category: FoodCategory.sweet,
  );

  static const pizza = FoodItem(
    id: 'pizza',
    name: 'Pizza',
    englishName: 'Pizza',
    emoji: '🍕',
    price: 100,
    hungerRestore: 20,
    happinessReward: 15,
    xpReward: 10,
    category: FoodCategory.meal,
  );

  static const List<FoodItem> all = [bread, apple, banana, cookie, pizza];

  static FoodItem? byId(String id) {
    for (final food in all) {
      if (food.id == id) return food;
    }
    return null;
  }
}
