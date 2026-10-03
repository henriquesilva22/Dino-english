import 'dart:math';

import 'package:dino_english/core/services/distractor_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final picker = DistractorPicker();
  const correct = DistractorCandidate(
    wordId: 'word.animals.dog',
    answerText: 'dog',
    category: 'animals',
    difficulty: 1,
  );

  test('never returns the correct answer as a distractor', () {
    final pool = [
      correct,
      const DistractorCandidate(
        wordId: 'w1',
        answerText: 'cat',
        category: 'animals',
        difficulty: 1,
      ),
      const DistractorCandidate(
        wordId: 'w2',
        answerText: 'bird',
        category: 'animals',
        difficulty: 1,
      ),
      const DistractorCandidate(
        wordId: 'w3',
        answerText: 'fish',
        category: 'animals',
        difficulty: 1,
      ),
    ];

    for (var seed = 0; seed < 20; seed++) {
      final distractors = picker.pickDistractors(
        correct: correct,
        pool: pool,
        random: Random(seed),
      );
      expect(distractors.map((d) => d.wordId), isNot(contains(correct.wordId)));
      expect(
        distractors.map((d) => d.answerText),
        isNot(contains(correct.answerText)),
      );
    }
  });

  test('prefers same-category, similar-difficulty candidates first', () {
    final pool = [
      const DistractorCandidate(
        wordId: 'close',
        answerText: 'cat',
        category: 'animals',
        difficulty: 1,
      ),
      const DistractorCandidate(
        wordId: 'far_category',
        answerText: 'bread',
        category: 'food',
        difficulty: 1,
      ),
      const DistractorCandidate(
        wordId: 'far_difficulty',
        answerText: 'elephant',
        category: 'animals',
        difficulty: 5,
      ),
    ];

    final distractors = picker.pickDistractors(
      correct: correct,
      pool: pool,
      count: 1,
      random: Random(1),
    );

    expect(distractors.single.wordId, 'close');
  });

  test(
    'degrades gracefully and returns fewer than requested when the pool is small',
    () {
      final pool = [
        const DistractorCandidate(
          wordId: 'w1',
          answerText: 'cat',
          category: 'animals',
          difficulty: 1,
        ),
      ];

      final distractors = picker.pickDistractors(
        correct: correct,
        pool: pool,
        count: 3,
        random: Random(2),
      );

      expect(distractors, hasLength(1));
    },
  );

  test('returns an empty list rather than throwing when the pool is empty', () {
    final distractors = picker.pickDistractors(
      correct: correct,
      pool: const [],
      count: 3,
    );

    expect(distractors, isEmpty);
  });

  test('never duplicates a distractor within one result', () {
    final pool = List.generate(
      5,
      (i) => DistractorCandidate(
        wordId: 'w$i',
        answerText: 'answer$i',
        category: 'animals',
        difficulty: 1,
      ),
    );

    final distractors = picker.pickDistractors(
      correct: correct,
      pool: pool,
      count: 3,
      random: Random(3),
    );

    expect(
      distractors.map((d) => d.wordId).toSet(),
      hasLength(distractors.length),
    );
  });
}
