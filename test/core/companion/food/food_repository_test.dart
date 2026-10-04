import 'dart:io';

import 'package:dino_english/core/companion/companion_needs_service.dart';
import 'package:dino_english/core/companion/companion_state.dart';
import 'package:dino_english/core/brain/model/dino_enums.dart';
import 'package:dino_english/core/companion/food/food_inventory.dart';
import 'package:dino_english/core/companion/food/food_item.dart';
import 'package:dino_english/core/companion/food/food_repository.dart';
import 'package:dino_english/core/database/app_bootstrap.dart';
import 'package:dino_english/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _setCoins(AppDatabase database, int coins) =>
    (database.update(database.userProfile)..where((t) => t.id.equals(1))).write(
      UserProfileCompanion(coins: Value(coins)),
    );

void main() {
  late AppDatabase database;
  late FoodRepository foods;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await AppBootstrapper(database).ensureSingletonRows();
    foods = FoodRepository(database);
  });

  tearDown(() => database.close());

  test('a new player has bread and apple, the rest is locked', () async {
    final inventory = await foods.load();
    expect(inventory.coins, 30);
    expect(inventory.statusOf(FoodCatalog.bread), FoodStatus.available);
    expect(inventory.statusOf(FoodCatalog.apple), FoodStatus.available);
    expect(inventory.statusOf(FoodCatalog.banana), FoodStatus.locked);
    expect(inventory.statusOf(FoodCatalog.pizza), FoodStatus.locked);
  });

  test('buying spends the coins and unlocks the food', () async {
    final result = await foods.buy(FoodCatalog.banana);
    expect(result, isA<Purchased>());
    expect((result as Purchased).coinsLeft, 0);
    final inventory = await foods.load();
    expect(inventory.coins, 0);
    expect(inventory.isUnlocked(FoodCatalog.banana), isTrue);
    // Never paid twice.
    expect(await foods.buy(FoodCatalog.banana), isA<AlreadyUnlocked>());
    expect((await foods.load()).coins, 0);
  });

  test('not enough coins: nothing changes, never negative', () async {
    await _setCoins(database, 18);
    final result = await foods.buy(FoodCatalog.banana);
    expect(result, isA<NotEnoughCoins>());
    expect((result as NotEnoughCoins).price, 30);
    expect(result.coins, 18);
    final inventory = await foods.load();
    expect(inventory.coins, 18);
    expect(inventory.missingFor(FoodCatalog.banana), 12);
    expect(inventory.isUnlocked(FoodCatalog.banana), isFalse);
  });

  test('coins, unlocked foods and the hint survive closing the app', () async {
    final dir = await Directory.systemTemp.createTemp('dino_food');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    var db = AppDatabase(NativeDatabase(file));
    await AppBootstrapper(db).ensureSingletonRows();
    await _setCoins(db, 80);
    await FoodRepository(db).buy(FoodCatalog.cookie);
    await FoodRepository(db).markHintSeen();
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    final reopened = FoodRepository(db);
    final inventory = await reopened.load();
    expect(inventory.coins, 30);
    expect(inventory.isUnlocked(FoodCatalog.cookie), isTrue);
    expect(await reopened.hintSeen(), isTrue);
    await db.close();
  });

  test('each food feeds and cheers by its own numbers, capped', () {
    const needs = CompanionNeedsService();
    final now = DateTime(2026, 10, 3, 12);
    final state = CompanionState.initial(
      now,
    ).copyWith(hunger: 40, happiness: 70);

    final bread = needs.applyCare(
      state,
      DinoCare.feed,
      now,
      food: FoodCatalog.bread,
    );
    expect(bread.state.hunger, 50);
    expect(bread.state.happiness, 75);
    expect(bread.xp, 5);

    final pizza = needs.applyCare(
      state,
      DinoCare.feed,
      now,
      food: FoodCatalog.pizza,
    );
    expect(pizza.state.hunger, 60);
    expect(pizza.state.happiness, 85);
    expect(pizza.xp, 10);

    final full = needs.applyCare(
      state.copyWith(hunger: 90, happiness: 98),
      DinoCare.feed,
      now,
      food: FoodCatalog.pizza,
    );
    expect(full.state.hunger, CompanionState.max);
    expect(full.state.happiness, CompanionState.max);
  });
}
