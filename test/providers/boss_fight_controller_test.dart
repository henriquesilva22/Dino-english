import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/game/boss_fight_state.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/minigame_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _seededDatabase() async {
  final database = AppDatabase(NativeDatabase.memory());
  await database
      .into(database.userProfile)
      .insertOnConflictUpdate(
        UserProfileCompanion.insert(
          id: const Value(1),
          createdAt: DateTime(2026),
        ),
      );
  await database
      .into(database.dinoEvolutionState)
      .insertOnConflictUpdate(
        DinoEvolutionStateCompanion.insert(id: const Value(1)),
      );
  return database;
}

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
    database = await _seededDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test(
    'hit() below zero HP records exactly one boss-victory exercise attempt',
    () async {
      final notifier = container.read(bossFightControllerProvider.notifier);
      final hitsToWin =
          (BossFightState.startingHp / BossFightState.normalWordDamage).ceil();

      for (var i = 0; i < hitsToWin; i++) {
        await notifier.hit();
      }

      final state = container.read(bossFightControllerProvider);
      expect(state.isFinished, isTrue);
      expect(state.hp, 0);

      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, hasLength(1));
      expect(attempts.single.exerciseType, 'minigame_boss_victory');
      expect(attempts.single.wordId, null);
      expect(attempts.single.xpAwarded, BossFightState.victoryBonusXp);
    },
  );

  test('hit() calls before victory record nothing', () async {
    final notifier = container.read(bossFightControllerProvider.notifier);

    await notifier.hit();

    final attempts = await database.select(database.exerciseAttempts).get();
    expect(attempts, isEmpty);
  });

  test(
    'hit() calls after victory are no-ops and record nothing further',
    () async {
      final notifier = container.read(bossFightControllerProvider.notifier);
      final hitsToWin =
          (BossFightState.startingHp / BossFightState.normalWordDamage).ceil();

      for (var i = 0; i < hitsToWin; i++) {
        await notifier.hit();
      }
      await notifier.hit();
      await notifier.hit();

      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, hasLength(1));
    },
  );

  test(
    'hit(damage:) applies the exact amount passed, not the default',
    () async {
      final notifier = container.read(bossFightControllerProvider.notifier);

      await notifier.hit(damage: BossFightState.hardWordDamage);

      final state = container.read(bossFightControllerProvider);
      expect(
        state.hp,
        BossFightState.startingHp - BossFightState.hardWordDamage,
      );
    },
  );
}
