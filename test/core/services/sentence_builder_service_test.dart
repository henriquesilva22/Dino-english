import 'dart:math';

import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/models/sentence_challenge.dart';
import 'package:dino_english/core/services/sentence_builder_service.dart';
import 'package:flutter_test/flutter_test.dart';

Word _word({
  required String id,
  required String englishTerm,
  required int difficulty,
  required String exampleSentenceEn,
}) {
  return Word(
    id: id,
    englishTerm: englishTerm,
    portugueseTranslation: '$englishTerm (pt)',
    category: 'test',
    difficulty: difficulty,
    recommendedLevel: 1,
    exampleSentenceEn: exampleSentenceEn,
    exampleSentencePt: 'Frase em português para $englishTerm.',
    isActive: true,
  );
}

void main() {
  const service = SentenceBuilderService();

  group('tokenize', () {
    test('attaches punctuation to its neighboring word, never standalone', () {
      final tokens = service.tokenize('The dog is very friendly.');
      expect(tokens, ['The', 'dog', 'is', 'very', 'friendly.']);
      expect(tokens.join(' '), 'The dog is very friendly.');
    });

    test('handles an internal comma the same way', () {
      final tokens = service.tokenize('Take an umbrella, it might rain.');
      expect(tokens, contains('umbrella,'));
      expect(tokens.join(' '), 'Take an umbrella, it might rain.');
    });
  });

  group('SentenceExerciseStyleX.forDifficulty', () {
    test('maps 1-4 to the four styles, 5+ falls back to emojiHint', () {
      expect(
        SentenceExerciseStyleX.forDifficulty(1),
        SentenceExerciseStyle.translationHint,
      );
      expect(
        SentenceExerciseStyleX.forDifficulty(2),
        SentenceExerciseStyle.situationHint,
      );
      expect(
        SentenceExerciseStyleX.forDifficulty(3),
        SentenceExerciseStyle.fillBlank,
      );
      expect(
        SentenceExerciseStyleX.forDifficulty(4),
        SentenceExerciseStyle.emojiHint,
      );
      expect(
        SentenceExerciseStyleX.forDifficulty(9),
        SentenceExerciseStyle.emojiHint,
      );
    });

    test('isAssemble is true for every style except fillBlank', () {
      expect(SentenceExerciseStyle.translationHint.isAssemble, isTrue);
      expect(SentenceExerciseStyle.situationHint.isAssemble, isTrue);
      expect(SentenceExerciseStyle.emojiHint.isAssemble, isTrue);
      expect(SentenceExerciseStyle.fillBlank.isAssemble, isFalse);
    });
  });

  group('buildChallenge -- assemble mechanism (difficulty 1/2/4)', () {
    final target = _word(
      id: 'word.dog',
      englishTerm: 'dog',
      difficulty: 1,
      exampleSentenceEn: 'The dog is happy.',
    );

    test('word bank contains every correct token plus up to 3 decoys', () {
      final challenge = service.buildChallenge(
        targetWord: target,
        otherEnglishTerms: ['cat', 'blue', 'run', 'red'],
        random: Random(1),
      );

      expect(challenge.style, SentenceExerciseStyle.translationHint);
      expect(challenge.displayTokens, ['The', 'dog', 'is', 'happy.']);
      // 4 correct tokens + 3 decoys (4 candidates available, capped at 3).
      expect(challenge.wordBank, hasLength(7));
      final texts = challenge.wordBank.map((t) => t.text).toList();
      for (final correct in challenge.displayTokens) {
        expect(texts, contains(correct));
      }
    });

    test(
      'never adds a decoy that duplicates a correct token (case-insensitive)',
      () {
        final challenge = service.buildChallenge(
          targetWord: target,
          otherEnglishTerms: ['dog', 'Dog', 'cat', 'blue', 'run'],
          random: Random(2),
        );

        final dogCount = challenge.wordBank
            .where((t) => t.text.toLowerCase() == 'dog')
            .length;
        expect(dogCount, 1); // only the real "dog" token from the sentence
      },
    );

    test(
      'degrades gracefully with fewer than 3 decoy candidates available',
      () {
        final challenge = service.buildChallenge(
          targetWord: target,
          otherEnglishTerms: ['cat'],
          random: Random(3),
        );

        expect(
          challenge.wordBank,
          hasLength(5),
        ); // 4 tokens + 1 available decoy
      },
    );

    test('isAssembleCorrect only accepts the exact original order', () {
      final challenge = service.buildChallenge(
        targetWord: target,
        otherEnglishTerms: const [],
        random: Random(4),
      );

      expect(
        service.isAssembleCorrect(challenge, challenge.displayTokens),
        isTrue,
      );
      expect(
        service.isAssembleCorrect(
          challenge,
          challenge.displayTokens.reversed.toList(),
        ),
        isFalse,
      );
      expect(service.isAssembleCorrect(challenge, ['The', 'dog']), isFalse);
    });
  });

  group('buildChallenge -- fill-blank mechanism (difficulty 3)', () {
    test('blanks the target word first, never the last token', () {
      final target = _word(
        id: 'word.apple',
        englishTerm: 'apple',
        difficulty: 3,
        exampleSentenceEn: 'I eat an apple every day.',
      );

      final challenge = service.buildChallenge(
        targetWord: target,
        otherEnglishTerms: ['banana', 'orange', 'grape', 'plum'],
        random: Random(5),
      );

      expect(challenge.style, SentenceExerciseStyle.fillBlank);
      expect(challenge.blanks, isNotEmpty);
      expect(
        challenge.blanks.map((b) => b.tokenIndex),
        isNot(contains(challenge.displayTokens.length - 1)),
      );
      final targetBlank = challenge.blanks.firstWhere(
        (b) => b.correctText == 'apple',
      );
      expect(targetBlank.options, contains('apple'));
      expect(targetBlank.options.length, lessThanOrEqualTo(3));
    });

    test('blanks are ordered left-to-right by tokenIndex', () {
      final target = _word(
        id: 'word.apple',
        englishTerm: 'apple',
        difficulty: 3,
        exampleSentenceEn: 'I eat an apple every day.',
      );
      final challenge = service.buildChallenge(
        targetWord: target,
        otherEnglishTerms: ['banana', 'orange', 'grape'],
        random: Random(6),
      );

      final indices = challenge.blanks.map((b) => b.tokenIndex).toList();
      expect(indices, List.of(indices)..sort());
    });

    test(
      'falls back to the assemble mechanism when no content word is eligible',
      () {
        final target = _word(
          id: 'word.understand',
          englishTerm: 'understand',
          difficulty: 3,
          exampleSentenceEn: 'Do you understand?',
        );

        final challenge = service.buildChallenge(
          targetWord: target,
          otherEnglishTerms: ['banana', 'orange', 'grape'],
          random: Random(7),
        );

        // "Do"/"you" are function words, "understand?" is the last token
        // (never blanked) -- nothing eligible, so it degrades instead of
        // ever returning a blank with no valid options.
        expect(challenge.blanks, isEmpty);
        expect(challenge.style, SentenceExerciseStyle.emojiHint);
        expect(challenge.wordBank, isNotEmpty);
      },
    );

    test('isBlankCorrect compares against the exact correct text', () {
      const blank = SentenceBlank(
        tokenIndex: 3,
        correctText: 'apple',
        options: ['apple', 'banana', 'orange'],
      );
      expect(service.isBlankCorrect(blank, 'apple'), isTrue);
      expect(service.isBlankCorrect(blank, 'banana'), isFalse);
    });
  });
}
