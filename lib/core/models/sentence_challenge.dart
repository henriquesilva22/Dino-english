import '../database/app_database.dart';

/// How a [SentenceChallenge] is presented to the learner. Mapped from
/// `Word.difficulty` (1-4, already an existing field -- no new data).
///
/// Simplification, documented deliberately: with only one short canonical
/// sentence per word in the seed data (no compound "because" sentences,
/// no free-form "situation" judging), the underlying *mechanism* is
/// derived from the style rather than combined freely -- every style
/// besides [fillBlank] assembles the full sentence from a scrambled word
/// bank; [fillBlank] instead blanks out 1-2 tokens of that same sentence.
enum SentenceExerciseStyle {
  translationHint,
  situationHint,
  fillBlank,
  emojiHint,
}

extension SentenceExerciseStyleX on SentenceExerciseStyle {
  static SentenceExerciseStyle forDifficulty(int difficulty) =>
      switch (difficulty) {
        1 => SentenceExerciseStyle.translationHint,
        2 => SentenceExerciseStyle.situationHint,
        3 => SentenceExerciseStyle.fillBlank,
        _ => SentenceExerciseStyle.emojiHint,
      };

  bool get isAssemble => this != SentenceExerciseStyle.fillBlank;
}

/// One tappable token in the word bank (assemble mechanism). `id` (not
/// just `text`) is what chips/placements key off of, so two chips with
/// identical text (e.g. two decoys that happen to match) never collide.
class BankToken {
  const BankToken({required this.id, required this.text});

  final String id;
  final String text;
}

/// One blanked-out position in the sentence (fill-blank mechanism).
class SentenceBlank {
  const SentenceBlank({
    required this.tokenIndex,
    required this.correctText,
    required this.options,
  });

  /// Index into [SentenceChallenge.displayTokens].
  final int tokenIndex;
  final String correctText;

  /// Shuffled; always contains [correctText].
  final List<String> options;
}

/// A single "Montar Frase" challenge: one real sentence
/// (`word.exampleSentenceEn`), tokenized, plus whatever the chosen
/// [style] needs to render and validate it.
class SentenceChallenge {
  const SentenceChallenge({
    required this.word,
    required this.style,
    required this.displayTokens,
    this.wordBank = const [],
    this.blanks = const [],
  });

  final Word word;
  final SentenceExerciseStyle style;

  /// The real sentence's tokens, in the correct order, punctuation
  /// attached to its neighboring word (never a standalone token) --
  /// `displayTokens.join(' ')` always reconstructs the original sentence
  /// exactly.
  final List<String> displayTokens;

  /// Assemble mechanism only: [displayTokens] as [BankToken]s plus decoy
  /// tokens from other words, shuffled.
  final List<BankToken> wordBank;

  /// Fill-blank mechanism only: 1-2 blanked positions.
  final List<SentenceBlank> blanks;

  String get correctSentenceText => displayTokens.join(' ');
}
