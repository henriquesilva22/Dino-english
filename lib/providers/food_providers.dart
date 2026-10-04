import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/companion/food/food_inventory.dart';
import '../core/companion/food/food_item.dart';
import '../core/companion/food/food_repository.dart';
import 'database_providers.dart';

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepository(ref.watch(databaseProvider)),
);

/// 🪙 coins + unlocked foods, re-read after each purchase.
final foodInventoryProvider = FutureProvider.autoDispose<FoodInventory>(
  (ref) => ref.watch(foodRepositoryProvider).load(),
);

/// Buys [food] and refreshes the inventory shown in the panel.
Future<PurchaseResult> buyFood(WidgetRef ref, FoodItem food) async {
  final result = await ref.read(foodRepositoryProvider).buy(food);
  ref.invalidate(foodInventoryProvider);
  return result;
}
