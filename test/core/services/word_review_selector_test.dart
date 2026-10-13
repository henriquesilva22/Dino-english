import 'dart:math';

import 'package:dino_english/core/services/word_review_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const selector = WordReviewSelector();
  final now = DateTime(2026, 10, 13);

  ReviewCandidate word(
    String en, {
    bool studied = false,
    bool talked = false,
    bool? lastCorrect,
    int wrong = 0,
  }) => ReviewCandidate(
    wordId: 'w.$en',
    english: en,
    portuguese: 'pt-$en',
    studied: studied,
    metInConversation: talked,
    lastResultCorrect: lastCorrect,
    incorrectCount: wrong,
    lastSeenAt: studied ? now.subtract(const Duration(days: 1)) : null,
  );

  final pool = [
    for (var i = 0; i < 30; i++) word('new$i'),
    for (var i = 0; i < 10; i++)
      word('seen$i', studied: true, lastCorrect: true),
    word('wrong1', studied: true, lastCorrect: false, wrong: 3),
    word('wrong2', studied: true, lastCorrect: false, wrong: 1),
    word('talked', talked: true),
  ];

  test('a set of distinct words, never more than asked', () {
    for (var seed = 0; seed < 50; seed++) {
      final set = selector.select(pool, random: Random(seed), now: now);
      expect(set.length, WordReviewSelector.defaultCount);
      expect(set.map((w) => w.english).toSet().length, set.length);
    }
  });

  test('words met before come first; wrong ones most of all', () {
    var wrongShown = 0;
    var newShown = 0;
    for (var seed = 0; seed < 200; seed++) {
      final set = selector.select(pool, random: Random(seed), now: now);
      wrongShown += set.where((w) => w.english.startsWith('wrong')).length;
      newShown += set.where((w) => w.english.startsWith('new')).length;
    }
    // 13 words met >= 5: new words only fill a set when needed.
    expect(newShown, 0);
    // 2 of the 13 words met, but shown well above a uniform 2/13 (15%).
    expect(wrongShown / (200 * 5), greaterThan(0.2));
  });

  test('different words over time', () {
    final seen = <String>{};
    for (var seed = 0; seed < 30; seed++) {
      seen.addAll(
        selector
            .select(pool, random: Random(seed), now: now)
            .map((w) => w.english),
      );
    }
    expect(seen.length, greaterThan(8));
  });

  test('few words met: completed with new ones, still no duplicates', () {
    final small = [word('a', studied: true), word('b'), word('c'), word('b')];
    final set = selector.select(small, random: Random(1), now: now);
    expect(set.map((w) => w.english), unorderedEquals(['a', 'b', 'c']));
    expect(set.first.english, 'a');
  });

  test('an empty bank gives an empty set', () {
    expect(selector.select(const [], random: Random(1), now: now), isEmpty);
  });
}
