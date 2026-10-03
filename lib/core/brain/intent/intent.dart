/// What the child wants, as detected by `IntentDetector`.
enum DinoIntent {
  greeting,
  farewell,
  askWordMeaning,
  askTranslation,
  askWordExample,
  askDinoName,
  askDinoFeeling,
  askDinoNeed,

  /// "What is your favorite food?", "Do you like pizza?"
  askDinoPreference,
  askHelp,

  /// "I like you", "te amo", "do you like me?", "hug".
  affection,

  /// "You are cute", "você é fofo", "good dino".
  praise,

  /// "Let's play!", "vamos brincar?" -- play *with the Dino* (a care
  /// action), not one of the app's game screens.
  play,

  /// "What is my favorite food?", "qual é o meu nome?" -- facts the Dino
  /// remembers about the child.
  askMemory,
  yes,
  no,
  thankYou,
  apology,
  request,
  answer,
  startActivity,
  askActivity,
  askReward,
  teachWord,
  confirmWord,
  denyWord,
  unknown,
}

/// A fact the child volunteered ("My name is Ana", "I like pizza").
enum StatementKind { childName, childAge, likes, dislikes, childFeeling }

class IntentResult {
  const IntentResult(
    this.intent, {
    this.confidence = 0.9,
    this.slot,
    this.secondSlot,
    this.statement,
    this.rule,
  });

  const IntentResult.unknown()
    : intent = DinoIntent.unknown,
      confidence = 0,
      slot = null,
      secondSlot = null,
      statement = null,
      rule = null;

  final DinoIntent intent;

  /// 0..1. Pattern matches ~0.9, keyword/context guesses lower.
  final double confidence;

  /// The raw phrase a pattern captured (the word asked about, the thing
  /// requested, the answer given...). The `EntityExtractor` resolves it.
  final String? slot;

  /// Second capture, e.g. the translation in "dragon means dragão".
  final String? secondSlot;

  /// Set when an [DinoIntent.answer] is really a volunteered fact.
  final StatementKind? statement;

  /// Which rule matched -- for debugging and tests only.
  final String? rule;

  @override
  String toString() =>
      'IntentResult($intent, slot: $slot, second: $secondSlot, '
      'statement: $statement, confidence: $confidence, rule: $rule)';
}
