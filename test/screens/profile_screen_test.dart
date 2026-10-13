import 'package:dino_english/core/database/app_bootstrap.dart';
import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/database/seed/word_seed_loader.dart';
import 'package:dino_english/core/economy/coin_repository.dart';
import 'package:dino_english/core/companion/food/food_item.dart';
import 'package:dino_english/core/companion/food/food_repository.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/word_review_providers.dart';
import 'package:dino_english/screens/profile_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    await tester.runAsync(() async {
      database = AppDatabase(NativeDatabase.memory());
      await WordSeedLoader(database).seedIfNeeded();
      await AppBootstrapper(database).ensureSingletonRows();
    });
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await settle(tester);
  }

  /// Runs a database call in the test's zone (where the screen's streams
  /// live), pumping until it is done -- inside runAsync it would wait on
  /// a lock held by those streams.
  Future<T> db<T>(WidgetTester tester, Future<T> Function() call) async {
    T? result;
    var done = false;
    call().then((v) {
      result = v;
      done = true;
    });
    for (var i = 0; i < 200 && !done; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 5));
    }
    expect(done, isTrue, reason: 'database call finished');
    return result as T;
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await db(tester, database.close);
  }

  String coinsShown(WidgetTester tester) {
    final chip = find.byKey(const ValueKey('profile-coins'));
    final texts = tester
        .widgetList<Text>(
          find.descendant(of: chip, matching: find.byType(Text)),
        )
        .map((t) => t.data)
        .toList();
    return texts.last!;
  }

  testWidgets('13. the coin balance: earned and spent, the official number', (
    tester,
  ) async {
    await open(tester);
    final start = await db(tester, () => CoinRepository(database).balance());
    expect(coinsShown(tester), '$start');

    await db(tester, () => CoinRepository(database).add(100));
    await settle(tester);
    expect(coinsShown(tester), '${start + 100}');

    // Spending in the food shop lowers the same balance.
    await db(tester, () => FoodRepository(database).buy(FoodCatalog.banana));
    await settle(tester);
    expect(coinsShown(tester), '${start + 100 - FoodCatalog.banana.price}');
    await close(tester);
  });

  testWidgets('12. "Revisão de palavras": a few distinct words; 🔄 gives a '
      'new set; showing them changes nothing', (tester) async {
    await open(tester);
    // A couple of words the child got wrong / studied.
    final words = await db(tester, () => database.select(database.words).get());
    await db(tester, () async {
      for (final w in words.take(3)) {
        await database
            .into(database.wordProgress)
            .insert(
              WordProgressCompanion.insert(
                wordId: w.id,
                lastResultCorrect: const Value(false),
                incorrectCount: const Value(2),
                lastSeenAt: Value(DateTime.now()),
              ),
            );
      }
    });
    container.read(wordReviewRoundProvider.notifier).next();
    await settle(tester);

    expect(find.text('Revisão de palavras'), findsOneWidget);
    Set<String> shown() => {
      for (final e in tester.widgetList<Padding>(
        find.byWidgetPredicate(
          (w) =>
              w is Padding &&
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('review-'),
        ),
      ))
        (e.key! as ValueKey<String>).value,
    };
    final first = shown();
    expect(first.length, 5);
    // Words got wrong come first.
    final wrongIds = {for (final w in words.take(3)) 'review-${w.id}'};
    expect(first.intersection(wrongIds), isNotEmpty);

    // Stable while the profile is open.
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(shown(), first);

    final profileBefore = await db(
      tester,
      () => database.select(database.userProfile).getSingle(),
    );
    final sets = <Set<String>>{first};
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('word-review-refresh')));
      await settle(tester);
      final next = shown();
      expect(next.length, 5, reason: 'no duplicates, always 5');
      sets.add(next);
    }
    expect(sets.length, greaterThan(1));
    // Showing words never touches XP or coins.
    final profileAfter = await db(
      tester,
      () => database.select(database.userProfile).getSingle(),
    );
    expect(profileAfter.totalXp, profileBefore.totalXp);
    expect(profileAfter.coins, profileBefore.coins);
    await close(tester);
  });
}
