import '../intent/intent.dart';
import '../model/dino_enums.dart';
import '../model/dino_status.dart';
import '../vocabulary/official_vocabulary.dart';

/// Something the Dino asked and is waiting for. Lets the brain understand
/// bare answers: Dino "What is your favorite food?" -> child "Apple." ->
/// Dino "Oh! You like apples!".
sealed class PendingQuestion {
  const PendingQuestion();
}

/// "What is your favorite food?" -- [topic] is the memory key, [category]
/// the word-bank category an answer is expected from.
class PreferenceQuestion extends PendingQuestion {
  const PreferenceQuestion({required this.topic, required this.category});

  final String topic;
  final String category;
}

enum QuizDirection {
  /// "What is 'dog' in Portuguese?" -- answer in Portuguese.
  englishToPortuguese,

  /// "How do you say 'cachorro' in English?" -- answer in English.
  portugueseToEnglish,
}

class QuizQuestion extends PendingQuestion {
  const QuizQuestion({
    required this.word,
    required this.direction,
    this.attempts = 0,
  });

  final VocabularyEntry word;
  final QuizDirection direction;
  final int attempts;

  QuizQuestion nextAttempt() =>
      QuizQuestion(word: word, direction: direction, attempts: attempts + 1);
}

/// "Can you say WATER?" -- the child should repeat [word] in English
/// (the companion's way of teaching a word met in conversation).
class RepeatWordQuestion extends PendingQuestion {
  const RepeatWordQuestion({required this.word, this.attempts = 0});

  final VocabularyEntry word;
  final int attempts;

  RepeatWordQuestion nextAttempt() =>
      RepeatWordQuestion(word: word, attempts: attempts + 1);
}

/// "Did you mean water?" / "Did you mean bed or bad?"
class ConfirmWordQuestion extends PendingQuestion {
  const ConfirmWordQuestion({
    required this.candidates,
    required this.originalIntent,
    required this.heard,
  });

  final List<VocabularyEntry> candidates;

  /// What to do once the word is confirmed (explain it, translate it...).
  final DinoIntent originalIntent;
  final String heard;
}

/// Dino didn't know an English word and asked what it means.
class TeachTranslationQuestion extends PendingQuestion {
  const TeachTranslationQuestion(this.englishWord);

  final String englishWord;
}

/// "Dragon means dragão? Is that right?"
class ConfirmTeachQuestion extends PendingQuestion {
  const ConfirmTeachQuestion({
    required this.englishWord,
    required this.portuguese,
  });

  final String englishWord;
  final String portuguese;
}

/// A yes/no offer ("Do you want a quiz?", "Shall we play Word Slash?").
class OfferQuestion extends PendingQuestion {
  const OfferQuestion.quiz() : activity = null;
  const OfferQuestion.activity(DinoActivity this.activity);

  /// Null = the offer is a conversation quiz.
  final DinoActivity? activity;
}

/// "What is your name?"
class ChildNameQuestion extends PendingQuestion {
  const ChildNameQuestion();
}

/// "And you? How are you?"
class ChildFeelingQuestion extends PendingQuestion {
  const ChildFeelingQuestion();
}

enum Speaker { child, dino }

class ConversationTurn {
  const ConversationTurn({
    required this.speaker,
    required this.text,
    required this.at,
    this.intent,
  });

  final Speaker speaker;
  final String text;
  final DateTime at;
  final DinoIntent? intent;
}

/// Short-term memory of one conversation: recent turns, the open
/// question, the word being talked about and the Dino's status.
class ConversationContext {
  ConversationContext({this.status = const DinoStatus()});

  static const int maxTurns = 30;

  final List<ConversationTurn> _turns = [];

  PendingQuestion? pending;

  /// The word currently being talked about, so "give me an example" or
  /// "and in a sentence?" need no word.
  VocabularyEntry? topicWord;

  /// Words already used in conversation quizzes this session.
  final Set<String> quizzedWordIds = {};

  /// Words the child already repeated correctly this session (the repeat
  /// XP is granted once per word per session).
  final Set<String> repeatedWordIds = {};

  /// Which sense the next "another example" of [topicWord] uses.
  int exampleCursor = 0;

  /// Pushed by the needs/XP systems; the brain adjusts it on care
  /// requests (feed, bath, sleep).
  DinoStatus status;

  bool greeted = false;
  int consecutiveMisunderstandings = 0;

  List<ConversationTurn> get turns => List.unmodifiable(_turns);

  int get childTurnCount =>
      _turns.where((t) => t.speaker == Speaker.child).length;

  void addTurn(ConversationTurn turn) {
    _turns.add(turn);
    if (_turns.length > maxTurns) _turns.removeAt(0);
  }

  void clearPending() => pending = null;
}
