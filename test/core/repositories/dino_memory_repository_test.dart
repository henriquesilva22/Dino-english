import 'package:dino_english/core/brain/memory/dino_memory.dart';
import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/repositories/dino_memory_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('memories survive a new DinoMemoryBank (app restart)', () async {
    final bank = DinoMemoryBank(DriftDinoMemoryStore(database));
    await bank.load();
    await bank.rememberPreference('food', 'apple');
    await bank.rememberFact('child_name', 'Ana');
    await bank.reinforceLearnedWord('word.animals.dog', 'dog', correct: true);
    await bank.reinforceLearnedWord('word.animals.dog', 'dog', correct: true);

    final reloaded = DinoMemoryBank(DriftDinoMemoryStore(database));
    await reloaded.load();
    expect(reloaded.preference('food'), 'apple');
    expect(reloaded.fact('child_name'), 'Ana');
    expect(reloaded.learnedConfidence('word.animals.dog'), closeTo(0.3, 1e-9));
    expect(
      reloaded
          .recall(DinoMemoryKind.learnedWord, 'word.animals.dog')!
          .timesReinforced,
      2,
    );
  });

  test('upsert replaces, delete removes', () async {
    final bank = DinoMemoryBank(DriftDinoMemoryStore(database));
    await bank.load();
    await bank.rememberPreference('food', 'apple');
    await bank.rememberPreference('food', 'pizza');
    await bank.rememberTask('feed_dino', 'Feed the Dino');
    await bank.completeTask('feed_dino');

    final rows = await database.select(database.dinoMemories).get();
    expect(rows, hasLength(1));
    expect(rows.single.value, 'pizza');
  });

  test('never touches the official words table', () async {
    final bank = DinoMemoryBank(DriftDinoMemoryStore(database));
    await bank.load();
    await bank.rememberTaughtWord('dragon', 'dragão');
    expect(await database.select(database.words).get(), isEmpty);
  });
}
