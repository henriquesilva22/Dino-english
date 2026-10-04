import 'dart:math';

import '../../brain/context/conversation_context.dart';
import '../../brain/vocabulary/official_vocabulary.dart';
import '../companion_response.dart';
import '../engine/text_normalizer.dart';
import 'hybrid_sentence.dart';
import 'learning_word.dart';
import 'learning_word_bank.dart';
import 'pronunciation_matcher.dart';
import 'word_mastery.dart';
import 'word_meaning_request.dart';

/// What a lesson step says and does. The engine turns it into a
/// `CompanionResponse` (and grants [xp] through the usual rewards).
class LessonReply {
  const LessonReply({
    required this.lines,
    this.word,
    this.xp = 0,
    this.awaitingRepetition = false,
    this.success = false,
  });

  final List<CompanionLine> lines;
  final LearningWord? word;

  /// XP to grant (already limited to once per word per session).
  final int xp;

  /// The Dino now waits for the child to say [word].
  final bool awaitingRepetition;

  /// The child said the word right.
  final bool success;
}

/// The companion's way of teaching English by context:
///
/// 🦖 "Eu vou WALK amanhã." -> 👦 "O que é walk?" -> 🦖 "WALK significa
/// caminhar. Agora fala comigo: WALK." -> 👦 "Walk." -> 🦖 "Great job! 🎉"
///
/// It writes the shared [ConversationContext] (the brain's): the word
/// just used, and a `RepeatWordQuestion(lesson: true)` while it waits for
/// the repetition, so the voice input listens in English meanwhile.
/// Offline: words, sentences and phrases come from the [LearningWordBank];
/// a word the Dino doesn't know is never explained ("Essa palavra eu
/// ainda não conheço").
class WordLessonController {
  WordLessonController({
    required this.bank,
    required this.mastery,
    required OfficialVocabulary vocabulary,
    Random? random,
    DateTime Function()? clock,
  }) : _vocabulary = vocabulary,
       _random = random ?? Random(),
       _clock = clock ?? DateTime.now {
    sentences = HybridSentenceBuilder(bank, random: _random);
    _knownEnglish = {
      for (final w in bank.words) w.english,
      ...vocabulary.englishTerms,
    };
  }

  final LearningWordBank bank;
  final WordMasteryTracker mastery;
  final OfficialVocabulary _vocabulary;
  final Random _random;
  final DateTime Function() _clock;
  late final HybridSentenceBuilder sentences;
  late final Set<String> _knownEnglish;

  static const _detector = WordMeaningRequestDetector();
  static const _matcher = PronunciationMatcher();

  /// XP for saying a word right (once per word per session).
  static const int repeatXp = 5;

  /// Tries before the Dino says "Não tem problema!" and moves on.
  static const int maxAttempts = 3;

  static final RegExp _giveUp = RegExp(
    r'^(?:(?:eu )?nao sei|nao consigo|nao quero|pula|passa|desisto|depois|'
    r"i (?:do not|don't|cant|can't|cannot) know|skip|pass)$",
  );

  static final RegExp _teachMe = RegExp(
    r'\b(?:me )?(?:ensina|ensine|aprender|fala|diz|conta)\b.*\b(?:palavra|ingles)\b|'
    r'\bpalavra nova\b|\bteach me\b|\bnew word\b',
  );

  /// The word a sentence or question is about: from the lesson bank, or
  /// built from the official word bank (its first meaning).
  LearningWord? wordFor(String english) {
    final hit = bank.byEnglish(english);
    if (hit != null) return hit;
    final official = _vocabulary.byEnglish(english);
    if (official == null) return null;
    return LearningWord(
      english: official.english.toLowerCase(),
      portuguese: official.translations.first,
      type: WordType.expression,
      category: official.category,
      difficulty: official.difficulty,
      examples: [WordExample(official.exampleEn, official.examplePt)],
    );
  }

  /// A Portuguese sentence with one English word for this moment (or
  /// null when the bank has nothing). [context]: `food`, `play`...
  Future<HybridSentence?> sentence({
    required int level,
    String? context,
    ConversationContext? conversation,
  }) async {
    final word = sentences.pick(
      masteryOf: mastery.of,
      now: _clock(),
      level: level,
      context: context,
    );
    if (word == null) return null;
    final known = mastery.of(word.english).level.index;
    // A word already learned can come in a longer sentence.
    final sentence = sentences.build(
      word,
      level: known >= MasteryLevel.learned.index ? max(level, 2) : level,
    );
    if (sentence == null) return null;
    await mastery.seen(word.english);
    conversation
      ?..lastTargetWord = word.english
      ..lastTargetFresh = true;
    return sentence;
  }

  /// The lesson's answer to the child's sentence, or null when it's not
  /// about a word (the normal conversation answers).
  Future<LessonReply?> handle(
    NormalizedText text,
    ConversationContext context, {
    required int level,
  }) async {
    final awaiting = context.awaitingRepetition
        ? (context.pending! as RepeatWordQuestion)
        : null;
    final request = _detector.detect(
      text.folded,
      lastWordFresh: context.lastTargetFresh || awaiting != null,
    );
    if (request != null) {
      final reply = _answerRequest(request, context, level: level);
      if (reply != null) return reply;
    }
    if (awaiting != null) {
      return _grade(awaiting, text, context, level: level);
    }
    // "Walk?" right after "Eu vou WALK amanhã.".
    if (context.lastTargetFresh &&
        text.tokens.length == 1 &&
        context.lastTargetWord != null &&
        bank.byEnglish(text.folded)?.english == context.lastTargetWord) {
      return explain(wordFor(context.lastTargetWord!)!, context, level: level);
    }
    if (_teachMe.hasMatch(text.folded)) {
      final sentence = await this.sentence(level: level, conversation: context);
      if (sentence == null) return null;
      return LessonReply(
        lines: [
          ?bank.phrase('teach_intro', _random),
          sentence.toLine(),
          ?bank.phrase('ask_me', _random, word: sentence.target),
        ],
        word: sentence.target,
      );
    }
    return null;
  }

  Future<LessonReply?>? _answerRequest(
    MeaningRequest request,
    ConversationContext context, {
    required int level,
  }) {
    if (request.refersToLastWord) {
      final last = context.lastTargetWord;
      if (last == null) return null;
      final word = wordFor(last);
      return word == null ? null : explain(word, context, level: level);
    }
    final asked = request.word!;
    final word = wordFor(asked);
    if (word != null) return explain(word, context, level: level);
    // A Portuguese word ("o que é maçã?") is the brain's business.
    if (_vocabulary.byPortuguese(asked).isNotEmpty) return null;
    return Future.value(_unknown(context));
  }

  /// "Essa palavra eu ainda não conheço." -- never a made-up meaning.
  LessonReply _unknown(ConversationContext context) {
    context.lastTargetFresh = false;
    return LessonReply(
      lines: [
        bank.phrase('unknown_word', _random) ??
            const CompanionLine.mixed('Essa palavra eu ainda não conheço.'),
        ?bank.phrase('unknown_follow', _random),
      ],
    );
  }

  /// "WALK significa caminhar." (+ an example for older children) +
  /// "Agora fala comigo: WALK." -- then waits for the repetition.
  Future<LessonReply> explain(
    LearningWord word,
    ConversationContext context, {
    required int level,
  }) async {
    final before = mastery.of(word.english);
    await mastery.explained(word.english);
    final lines = <CompanionLine>[
      (before.level.index >= MasteryLevel.learned.index
              ? bank.phrase('explain_known', _random, word: word)
              : null) ??
          bank.phrase('explain', _random, word: word) ??
          CompanionLine.mixed(
            '${word.display} significa ${word.portuguese}.',
            english: [word.display],
          ),
    ];
    // Beginners get the short version; older children an example too.
    if (level >= 2 && word.examples.isNotEmpty) {
      final example = word.examples[_random.nextInt(word.examples.length)];
      lines
        ..add(
          CompanionLine.mixed(
            'Example: ${example.english}',
            english: ['Example: ${example.english}'],
          ),
        )
        ..add(CompanionLine.mixed(example.portuguese));
    }
    lines.add(
      bank.phrase('repeat_prompt', _random, word: word) ??
          CompanionLine.mixed(
            'Agora fala comigo: ${word.display}.',
            english: [word.display],
          ),
    );
    _awaitRepetition(word, context);
    return LessonReply(lines: lines, word: word, awaitingRepetition: true);
  }

  /// "⭐ Praticar" on a word: straight to the repetition.
  LessonReply practice(LearningWord word, ConversationContext context) {
    _awaitRepetition(word, context);
    return LessonReply(
      lines: [
        bank.phrase('repeat_prompt', _random, word: word) ??
            CompanionLine.mixed(
              'Fala comigo: ${word.display}.',
              english: [word.display],
            ),
      ],
      word: word,
      awaitingRepetition: true,
    );
  }

  void _awaitRepetition(LearningWord word, ConversationContext context) {
    context
      ..pending = RepeatWordQuestion(word: _entryFor(word), lesson: true)
      ..lastTargetWord = word.english
      ..lastTargetFresh = true;
  }

  Future<LessonReply?> _grade(
    RepeatWordQuestion question,
    NormalizedText text,
    ConversationContext context, {
    required int level,
  }) async {
    final word = wordFor(question.word.english)!;
    if (_giveUp.hasMatch(text.folded)) return _reveal(word, context);
    final result = _matcher.match(
      word.english,
      text.raw,
      aliases: word.aliases,
      otherWords: _knownEnglish,
    );
    if (result == RepetitionMatch.correct) {
      context.clearPending();
      await mastery.correct(word.english);
      final id = question.word.id;
      final xp = context.repeatedWordIds.add(id) ? repeatXp : 0;
      return LessonReply(
        lines: [
          bank.phrase('success_$level', _random) ??
              bank.phrase('success', _random) ??
              const CompanionLine('Great job! 🎉'),
          ?bank.phrase('you_said', _random, word: word),
          if (xp > 0) CompanionLine('+$xp XP!'),
        ],
        word: word,
        xp: xp,
        success: true,
      );
    }
    // A whole sentence without the word: the child moved on.
    if (text.tokens.length > 3) {
      context.clearPending();
      return null;
    }
    await mastery.incorrect(word.english);
    if (question.attempts + 1 >= maxAttempts) return _reveal(word, context);
    context.pending = question.nextAttempt();
    return LessonReply(
      lines: [
        bank.phrase('almost', _random, word: word) ??
            CompanionLine.mixed(
              'Quase! Vamos tentar de novo: ${word.display}.',
              english: [word.display],
            ),
      ],
      word: word,
      awaitingRepetition: true,
    );
  }

  /// "Não tem problema! WALK significa caminhar." -- and back to talking.
  LessonReply _reveal(LearningWord word, ConversationContext context) {
    context.clearPending();
    return LessonReply(
      lines: [
        bank.phrase('give_up', _random, word: word) ??
            CompanionLine.mixed(
              'Não tem problema! ${word.display} significa ${word.portuguese}.',
              english: [word.display],
            ),
      ],
      word: word,
    );
  }

  /// Every reply the child sees: keeps track of the English word in it.
  void noteSaid(CompanionResponse response, ConversationContext context) {
    context.lastDinoSentence = response.englishText;
    String? target;
    for (final line in response.lines) {
      for (final english in line.english ?? const <String>[]) {
        // Taught words are in capitals ("WALK"); "Great job!" is not one.
        if (english != english.toUpperCase()) continue;
        final word = wordFor(english);
        if (word != null) target ??= word.english;
      }
    }
    if (target != null) {
      context
        ..lastTargetWord = target
        ..lastTargetFresh = true;
    } else {
      context.lastTargetFresh = false;
    }
  }

  VocabularyEntry _entryFor(LearningWord word) {
    final official = _vocabulary.byEnglish(word.english);
    if (official != null) return official;
    final example = word.examples.isEmpty ? null : word.examples.first;
    return VocabularyEntry(
      id: 'learn.${word.english.replaceAll(' ', '_')}',
      english: word.english,
      portuguese: word.portuguese,
      category: word.category,
      difficulty: word.difficulty,
      exampleEn: example?.english ?? '',
      examplePt: example?.portuguese ?? '',
    );
  }
}
