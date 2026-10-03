import 'dart:math';

import '../database/app_database.dart';
import '../models/sentence_challenge.dart';

/// Turns a word's real `exampleSentenceEn` into a "Montar Frase"
/// challenge: tokenizes it, then either builds a scrambled word bank with
/// decoys (assemble mechanism) or blanks out 1-2 content words with
/// multiple-choice options (fill-blank mechanism, difficulty 3 words).
/// Pure, `Random?` injectable for deterministic tests -- same contract as
/// `DistractorPicker`.
class SentenceBuilderService {
  const SentenceBuilderService();

  static const int _decoyCount = 3;
  static const int _blankOptionCount = 3; // correct + 2 distractors

  static const Set<String> _functionWords = {
    'a',
    'an',
    'the',
    'is',
    'are',
    'am',
    'was',
    'were',
    'do',
    'does',
    'did',
    'i',
    'you',
    'he',
    'she',
    'it',
    'we',
    'they',
    'to',
    'in',
    'on',
    'at',
    'of',
    'and',
    'but',
    'not',
  };

  /// Splits on spaces only -- English sentence punctuation never has a
  /// leading space, so it's already attached to its neighboring word
  /// (`"friendly."`, `"umbrella,"`) with zero extra logic, and
  /// `tokens.join(' ')` always reconstructs the original sentence.
  List<String> tokenize(String sentence) =>
      sentence.split(' ').where((t) => t.isNotEmpty).toList();

  String _stripPunctuation(String token) =>
      token.replaceAll(RegExp(r'[.,!?]+$'), '').toLowerCase();

  SentenceChallenge buildChallenge({
    required Word targetWord,
    required List<String> otherEnglishTerms,
    Random? random,
  }) {
    final rng = random ?? Random();
    final tokens = tokenize(targetWord.exampleSentenceEn);
    final style = SentenceExerciseStyleX.forDifficulty(targetWord.difficulty);

    if (style == SentenceExerciseStyle.fillBlank) {
      final blanks = _buildBlanks(tokens, targetWord, otherEnglishTerms, rng);
      if (blanks.isNotEmpty) {
        return SentenceChallenge(
          word: targetWord,
          style: SentenceExerciseStyle.fillBlank,
          displayTokens: tokens,
          blanks: blanks,
        );
      }
      // Fallback: no eligible content token to blank (a very short
      // sentence) -- degrade to the assemble mechanism instead of ever
      // returning a fill-blank challenge with no valid blanks.
      return SentenceChallenge(
        word: targetWord,
        style: SentenceExerciseStyle.emojiHint,
        displayTokens: tokens,
        wordBank: _buildWordBank(tokens, otherEnglishTerms, rng),
      );
    }

    return SentenceChallenge(
      word: targetWord,
      style: style,
      displayTokens: tokens,
      wordBank: _buildWordBank(tokens, otherEnglishTerms, rng),
    );
  }

  List<BankToken> _buildWordBank(
    List<String> tokens,
    List<String> otherEnglishTerms,
    Random rng,
  ) {
    final correctLower = tokens.map(_stripPunctuation).toSet();
    final decoyPool =
        otherEnglishTerms
            .where((t) => !correctLower.contains(t.toLowerCase()))
            .toList()
          ..shuffle(rng);
    final decoys = decoyPool.take(_decoyCount).toList();

    final bank = <BankToken>[
      for (var i = 0; i < tokens.length; i++)
        BankToken(id: 'w$i', text: tokens[i]),
      for (var i = 0; i < decoys.length; i++)
        BankToken(id: 'd$i', text: decoys[i]),
    ];
    bank.shuffle(rng);
    return bank;
  }

  List<SentenceBlank> _buildBlanks(
    List<String> tokens,
    Word targetWord,
    List<String> otherEnglishTerms,
    Random rng,
  ) {
    if (tokens.length < 2) return const [];
    final targetLower = targetWord.englishTerm.toLowerCase();

    final eligible = <int>[
      for (var i = 0; i < tokens.length - 1; i++) // never the last token
        if (!_functionWords.contains(_stripPunctuation(tokens[i]))) i,
    ];
    if (eligible.isEmpty) return const [];

    // Prefer the token that matches the target word itself, so the
    // challenge stays anchored to the word actually being reinforced.
    eligible.sort((a, b) {
      final aMatches = _stripPunctuation(tokens[a]) == targetLower;
      final bMatches = _stripPunctuation(tokens[b]) == targetLower;
      if (aMatches == bMatches) return 0;
      return aMatches ? -1 : 1;
    });

    final blankCount = eligible.length >= 2 ? 2 : 1;
    final chosenIndices = eligible.take(blankCount).toList()..sort();

    final usedTexts = chosenIndices.map((i) => tokens[i]).toSet();
    final blanks = <SentenceBlank>[];
    for (final index in chosenIndices) {
      final correctText = tokens[index];
      final distractorPool =
          otherEnglishTerms
              .where(
                (t) =>
                    !usedTexts.contains(t) &&
                    t.toLowerCase() != _stripPunctuation(correctText),
              )
              .toList()
            ..shuffle(rng);
      final distractors = distractorPool.take(_blankOptionCount - 1).toList();
      final options = [correctText, ...distractors]..shuffle(rng);
      blanks.add(
        SentenceBlank(
          tokenIndex: index,
          correctText: correctText,
          options: options,
        ),
      );
    }
    return blanks;
  }

  bool isAssembleCorrect(
    SentenceChallenge challenge,
    List<String> submittedTokenTexts,
  ) {
    if (submittedTokenTexts.length != challenge.displayTokens.length) {
      return false;
    }
    for (var i = 0; i < submittedTokenTexts.length; i++) {
      if (submittedTokenTexts[i] != challenge.displayTokens[i]) return false;
    }
    return true;
  }

  bool isBlankCorrect(SentenceBlank blank, String submitted) =>
      submitted == blank.correctText;
}
