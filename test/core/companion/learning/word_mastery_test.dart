import 'package:dino_english/core/brain/memory/dino_memory.dart';
import 'package:dino_english/core/companion/learning/word_mastery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late InMemoryDinoMemoryStore store;
  late DinoMemoryBank memory;
  late WordMasteryTracker tracker;

  setUp(() async {
    now = DateTime(2026, 10, 5, 10); // a Monday
    store = InMemoryDinoMemoryStore();
    memory = DinoMemoryBank(store, clock: () => now);
    await memory.load();
    tracker = WordMasteryTracker(memory, clock: () => now);
  });

  test('new -> knowing -> practicing in one day; then a level a day', () async {
    expect(tracker.of('walk').level, MasteryLevel.fresh);
    await tracker.seen('walk');
    expect(tracker.of('walk').timesSeen, 1);
    await tracker.explained('walk');
    expect(tracker.of('walk').level, MasteryLevel.knowing);
    await tracker.correct('walk');
    expect(tracker.of('walk').level, MasteryLevel.practicing);
    // Same day: counted, but no level up.
    await tracker.correct('walk');
    expect(tracker.of('walk').level, MasteryLevel.practicing);
    expect(tracker.of('walk').correctRepetitions, 2);

    now = DateTime(2026, 10, 7, 10); // Wednesday
    await tracker.correct('walk');
    expect(tracker.of('walk').level, MasteryLevel.learned);
    now = DateTime(2026, 10, 11, 10); // Sunday
    await tracker.correct('walk');
    expect(tracker.of('walk').level, MasteryLevel.mastered);
  });

  test('a wrong repetition never lowers the level', () async {
    await tracker.explained('eat');
    await tracker.correct('eat');
    await tracker.incorrect('eat');
    final m = tracker.of('eat');
    expect(m.level, MasteryLevel.practicing);
    expect(m.incorrectRepetitions, 1);
  });

  test('asking again for a learned word sends it back to review', () async {
    await tracker.explained('run');
    await tracker.correct('run');
    now = now.add(const Duration(days: 2));
    await tracker.correct('run');
    expect(tracker.of('run').level, MasteryLevel.learned);
    await tracker.explained('run');
    expect(tracker.of('run').level, MasteryLevel.practicing);
  });

  test('spaced repetition: a word comes back after its interval', () async {
    await tracker.explained('jump');
    await tracker.correct('jump'); // practicing: 1 day
    expect(tracker.of('jump').isDue(now), isFalse);
    expect(tracker.of('jump').isDue(now.add(const Duration(days: 1))), isTrue);
  });

  test('persists in the Dino memory and survives a reload', () async {
    await tracker.explained('ball');
    await tracker.correct('ball');
    final reloaded = DinoMemoryBank(store, clock: () => now);
    await reloaded.load();
    final again = WordMasteryTracker(reloaded, clock: () => now);
    expect(again.of('ball').level, MasteryLevel.practicing);
    expect(again.of('ball').correctRepetitions, 1);
    expect(
      reloaded.recall(DinoMemoryKind.wordMastery, 'ball')!.confidence,
      0.5,
    );
  });
}
