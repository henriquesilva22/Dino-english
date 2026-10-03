import 'dart:math';

import '../context/conversation_context.dart';
import '../entity/entity_extractor.dart';
import '../intent/intent.dart';
import '../intent/intent_detector.dart';
import '../memory/dino_memory.dart';
import '../model/dino_enums.dart';
import '../nlp/fuzzy_matcher.dart';
import '../nlp/normalizer.dart';
import '../nlp/tokenizer.dart';
import '../vocabulary/official_vocabulary.dart';
import 'dialogue_action.dart';
import 'response_generator.dart';

/// Fifth pipeline step: decides what the Dino does with an understood
/// input -- which lines to say, what to ask next, what to remember and
/// which actions (animation, reward, activity...) to emit.
///
/// Rules that protect the official vocabulary live here: answers are
/// always graded against the word bank, a wrong answer is corrected and
/// never learned, and only words *outside* the bank can be taught.
class DialogueManager {
  DialogueManager({
    required this._vocabulary,
    required this._memory,
    required this._extractor,
    required this._detector,
    required ResponseGenerator generator,
    Random? random,
  }) : _say = generator,
       _random = random ?? Random();

  final OfficialVocabulary _vocabulary;
  final DinoMemoryBank _memory;
  final EntityExtractor _extractor;
  final IntentDetector _detector;
  final ResponseGenerator _say;
  final Random _random;

  static const int quizXp = 5;

  /// First time a word is taught from the child's own sentence.
  static const int learnWordXp = 5;

  /// Repeating that word correctly (once per word per session).
  static const int repeatWordXp = 10;
  static const _tokenizer = Tokenizer();

  /// Topics the Dino asks about, in order.
  static const List<String> preferenceTopics = ['food', 'animals', 'colors'];

  static final RegExp _giveUp = RegExp(
    r"^(?:i do not know|i dont know|idk|no idea|i forgot|help|pass|skip|n[aã]o sei|sei l[aá]|esqueci|passo|pula)$",
    unicode: true,
  );

  static const Set<String> _dinoDislikes = {
    'snake',
    'rain',
    'soap',
    'lemon',
    'bee',
  };

  // ---- entry points --------------------------------------------------------

  /// What the Dino says when the chat opens.
  Future<List<DialogueAction>> opening(ConversationContext context) async {
    _say.tier = context.status.tier;
    final childName = _memory.fact('child_name');
    final returning =
        _memory.all(DinoMemoryKind.preference).isNotEmpty || childName != null;
    context.greeted = true;
    final actions = <DialogueAction>[
      const PlayAnimationAction(DinoAnimation.wave),
      _speak(_say.greeting(childName: childName, returning: returning)),
    ];
    actions.addAll(_followUpQuestion(context));
    return actions;
  }

  Future<List<DialogueAction>> handle({
    required NormalizedInput input,
    required IntentResult intent,
    required ConversationContext context,
  }) async {
    _say.tier = context.status.tier;
    if (intent.intent != DinoIntent.unknown) {
      context.consecutiveMisunderstandings = 0;
    }
    if (context.status.isSleeping &&
        intent.intent != DinoIntent.request &&
        intent.intent != DinoIntent.farewell) {
      return [_speak(_say.sleepingNow())];
    }

    switch (intent.intent) {
      case DinoIntent.greeting:
        return _greeting(context);
      case DinoIntent.farewell:
        context.clearPending();
        return [
          const PlayAnimationAction(DinoAnimation.wave),
          _speak(_say.farewell(childName: _memory.fact('child_name'))),
        ];
      case DinoIntent.thankYou:
        return [_speak(_say.thanksReply())];
      case DinoIntent.apology:
        return [_speak(_say.apologyReply())];
      case DinoIntent.askWordMeaning:
      case DinoIntent.askTranslation:
      case DinoIntent.askWordExample:
        return _wordQuestion(intent, context);
      case DinoIntent.teachWord:
        return _teach(intent, context);
      case DinoIntent.askDinoName:
        return _dinoName(context);
      case DinoIntent.askDinoFeeling:
        return _dinoFeeling(context);
      case DinoIntent.askDinoNeed:
        return _dinoNeed(input, intent, context);
      case DinoIntent.askDinoPreference:
        return _dinoPreference(intent, context);
      case DinoIntent.affection:
        return _affection(input, context);
      case DinoIntent.praise:
        return [
          const PlayAnimationAction(DinoAnimation.happy),
          _speak(_say.praise()),
          ..._cheerUp(context),
        ];
      case DinoIntent.play:
        return _play(context);
      case DinoIntent.askMemory:
        return _askMemory(intent, context);
      case DinoIntent.askHelp:
        return [
          _ask(
            _say.help(),
            suggestions: const [
              'What does water mean?',
              'How do you say cachorro?',
              'Give me an example with dog',
              "Let's play!",
            ],
          ),
        ];
      case DinoIntent.askReward:
        context.pending = const OfferQuestion.quiz();
        return [
          _speak(_say.rewardInfo(context.status)),
          ..._askAndWait(_say.offerQuiz(), suggestions: const ['Yes!', 'No']),
        ];
      case DinoIntent.startActivity:
        return _startActivity(input, context);
      case DinoIntent.askActivity:
        return _askAndWait(
          _say.suggestActivities(),
          suggestions: const ['Word Slash', 'Study', 'Quiz', 'Adventure'],
        );
      case DinoIntent.request:
        return _request(input, intent, context);
      case DinoIntent.yes:
      case DinoIntent.no:
        return _yesNo(intent, context);
      case DinoIntent.confirmWord:
      case DinoIntent.denyWord:
        return _confirmation(input, intent, context);
      case DinoIntent.answer:
        return _answer(input, intent, context);
      case DinoIntent.unknown:
        return _fallback(input, context);
    }
  }

  // ---- helpers ---------------------------------------------------------------

  SpeakAction _speak(DinoLine line) =>
      SpeakAction(line.text, translation: line.translation);

  AskAction _ask(DinoLine line, {List<String> suggestions = const []}) =>
      AskAction(
        line.text,
        translation: line.translation,
        suggestions: suggestions,
      );

  List<DialogueAction> _askAndWait(
    DinoLine line, {
    List<String> suggestions = const [],
  }) => [_ask(line, suggestions: suggestions), const WaitForAnswerAction()];

  VocabularyEntry? _entry(String english) => _vocabulary.byEnglish(english);

  /// After greeting: learn the child's name, then their favorites, then
  /// offer a quiz -- one question at a time.
  List<DialogueAction> _followUpQuestion(ConversationContext context) {
    if (_memory.fact('child_name') == null) {
      context.pending = const ChildNameQuestion();
      return _askAndWait(
        const DinoLine('What is your name?', 'Qual é o seu nome?'),
      );
    }
    for (final topic in preferenceTopics) {
      if (_memory.preference(topic) == null) {
        context.pending = PreferenceQuestion(topic: topic, category: topic);
        return _askAndWait(
          _say.askPreference(topic),
          suggestions: _preferenceSuggestions(topic),
        );
      }
    }
    final remembered =
        preferenceTopics[_random.nextInt(preferenceTopics.length)];
    final favorite = _entry(_memory.preference(remembered)!);
    context.pending = const OfferQuestion.quiz();
    return [
      if (favorite != null)
        _speak(_say.rememberPreference(remembered, favorite)),
      ..._askAndWait(_say.offerQuiz(), suggestions: const ['Yes!', 'No']),
    ];
  }

  List<String> _preferenceSuggestions(String category) {
    final pool = _vocabulary.inCategory(category).toList()..shuffle(_random);
    return pool.take(3).map((e) => e.english).toList();
  }

  // ---- intents ---------------------------------------------------------------

  List<DialogueAction> _greeting(ConversationContext context) {
    final returning = context.greeted;
    context.greeted = true;
    context.pending = const ChildFeelingQuestion();
    return [
      const PlayAnimationAction(DinoAnimation.wave),
      _speak(
        _say.greeting(
          childName: _memory.fact('child_name'),
          returning: returning,
        ),
      ),
      ..._askAndWait(
        const DinoLine('How are you today?', 'Como você está hoje?'),
        suggestions: const ['I am happy!', 'I am tired', 'I am bored'],
      ),
    ];
  }

  Future<List<DialogueAction>> _wordQuestion(
    IntentResult intent,
    ConversationContext context,
  ) async {
    final slot = intent.slot;
    if (slot == null || _extractor.isPronoun(slot)) {
      final topic = context.topicWord;
      if (topic == null) return _askAndWait(_say.whichWord());
      return _explain(topic, intent.intent, context, heard: topic.english);
    }

    final match = _extractor.resolveWord(slot);
    switch (match.kind) {
      case WordMatchKind.exact:
      case WordMatchKind.corrected:
        return [
          if (match.kind == WordMatchKind.corrected && !match.viaPortuguese)
            _speak(_say.correctedSpelling(match.entry!)),
          ...await _explain(
            match.entry!,
            intent.intent,
            context,
            heard: match.heard,
            viaPortuguese: match.viaPortuguese,
          ),
        ];
      case WordMatchKind.ambiguous:
        context.pending = ConfirmWordQuestion(
          candidates: match.candidates,
          originalIntent: intent.intent,
          heard: match.heard,
        );
        return _askAndWait(
          _say.didYouMean(match.candidates),
          suggestions: match.candidates.map((e) => e.english).toList(),
        );
      case WordMatchKind.unknown:
        return _unknownWord(match.heard, intent.intent, context);
    }
  }

  Future<List<DialogueAction>> _explain(
    VocabularyEntry word,
    DinoIntent intent,
    ConversationContext context, {
    required String heard,
    bool viaPortuguese = false,
  }) async {
    if (context.topicWord?.id != word.id) context.exampleCursor = 0;
    context.topicWord = word;
    await _memory.noteWordDiscussed(word.id, word.english);

    final DinoLine line;
    if (intent == DinoIntent.askWordExample) {
      line = _say.example(word, senseIndex: context.exampleCursor);
      context.exampleCursor = (context.exampleCursor + 1) % word.senses.length;
    } else if (viaPortuguese) {
      line = _say.translation(word, heard);
    } else {
      line = _say.meaning(word);
    }
    return [const PlayAnimationAction(DinoAnimation.happy), _speak(line)];
  }

  List<DialogueAction> _unknownWord(
    String heard,
    DinoIntent intent,
    ConversationContext context,
  ) {
    final taught = _memory.taughtTranslation(heard);
    if (taught != null) return [_speak(_say.rememberedTaught(heard, taught))];

    // Asked "how do you say X" with a Portuguese word the bank lacks: the
    // Dino can't invent an English word, so it doesn't pretend to.
    if (intent == DinoIntent.askTranslation && _looksPortuguese(heard)) {
      return [
        const PlayAnimationAction(DinoAnimation.think),
        _speak(_say.unknownPortugueseWord(heard)),
      ];
    }
    if (heard.split(' ').length > 3) {
      return _fallbackNotUnderstood(context);
    }
    context.pending = TeachTranslationQuestion(heard);
    return [
      const PlayAnimationAction(DinoAnimation.think),
      ..._askAndWait(
        _say.unknownWord(heard),
        suggestions: const ['I do not know'],
      ),
    ];
  }

  bool _looksPortuguese(String text) =>
      RegExp('[ãõçáéíóúâêô]').hasMatch(text) ||
      RegExp(r'(?:ção|ões|nh|lh|inho|inha)\b').hasMatch(text);

  Future<List<DialogueAction>> _teach(
    IntentResult intent,
    ConversationContext context,
  ) async {
    final wordText = intent.slot;
    final translation = intent.secondSlot;
    if (wordText == null || translation == null) {
      return [
        const PlayAnimationAction(DinoAnimation.happy),
        _speak(_say.teachAskWord()),
      ];
    }

    final match = _extractor.resolveWord(wordText);
    final entry = match.entry;
    if (entry != null) {
      final correct = match.viaPortuguese
          // "cachorro means dog": the translation must be the English term.
          ? _vocabulary.byEnglish(translation)?.id == entry.id
          : _vocabulary.acceptsPortuguese(entry, translation);
      await _memory.reinforceLearnedWord(
        entry.id,
        entry.english,
        correct: correct,
      );
      context.topicWord = entry;
      if (correct) {
        return [
          const PlayAnimationAction(DinoAnimation.happy),
          _speak(_say.teachCorrect(entry)),
        ];
      }
      // Official vocabulary always wins: correct the child, learn nothing.
      return [
        const PlayAnimationAction(DinoAnimation.think),
        _speak(
          match.viaPortuguese
              ? DinoLine(
                  'Hmm, not quite! ${_capitalize(match.heard)} is ${entry.english} in English, not $translation.',
                  'Quase! ${match.heard} em inglês é ${entry.english}.',
                )
              : _say.teachWrong(entry, translation),
        ),
      ];
    }

    // Not in the word bank: can be learned as an unofficial word.
    final english = match.heard;
    if (!_isTeachable(english, translation)) {
      return _fallbackNotUnderstood(context);
    }
    context.pending = ConfirmTeachQuestion(
      englishWord: english,
      portuguese: translation,
    );
    return _askAndWait(
      _say.confirmTeach(english, translation),
      suggestions: const ['Yes', 'No'],
    );
  }

  bool _isTeachable(String english, String portuguese) =>
      english.length <= 30 &&
      portuguese.length <= 40 &&
      english.split(' ').length <= 3 &&
      portuguese.split(' ').length <= 4;

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  List<DialogueAction> _dinoName(ConversationContext context) {
    final actions = <DialogueAction>[
      const PlayAnimationAction(DinoAnimation.wave),
      _speak(_say.name(context.status.name)),
    ];
    if (_memory.fact('child_name') == null) {
      context.pending = const ChildNameQuestion();
      actions.addAll(
        _askAndWait(const DinoLine('What is your name?', 'Qual é o seu nome?')),
      );
    }
    return actions;
  }

  List<DialogueAction> _dinoFeeling(ConversationContext context) {
    final urgent = context.status.mostUrgentNeed;
    context.pending = const ChildFeelingQuestion();
    return [
      PlayAnimationAction(
        urgent == null ? DinoAnimation.happy : DinoAnimation.sad,
      ),
      _speak(_say.feeling(context.status)),
      ..._askAndWait(
        _say.askChildFeeling(),
        suggestions: const ['I am happy!', 'I am tired', 'I am sad'],
      ),
    ];
  }

  List<DialogueAction> _dinoNeed(
    NormalizedInput input,
    IntentResult intent,
    ConversationContext context,
  ) {
    final need = _extractor.findNeed(intent.slot ?? input.text);
    final status = context.status;
    if (need == null) {
      final urgent = status.mostUrgentNeed;
      return [
        _speak(
          urgent == null ? _say.needFine(null) : _say.needComplaint(urgent),
        ),
      ];
    }
    if (status.isUrgent(need)) {
      return [
        const PlayAnimationAction(DinoAnimation.sad),
        _speak(_say.needComplaint(need)),
      ];
    }
    if (status.isMild(need)) {
      return [
        const PlayAnimationAction(DinoAnimation.think),
        _speak(_say.needMild(need)),
      ];
    }
    return [
      const PlayAnimationAction(DinoAnimation.happy),
      _speak(_say.needFine(need)),
    ];
  }

  // ---- companion intents -------------------------------------------------------

  /// Kind words make the Dino a bit happier (no XP: it's not a lesson).
  List<DialogueAction> _cheerUp(ConversationContext context) {
    context.status = context.status.adjustNeed(DinoNeed.happiness, 0.05);
    return const [UpdateNeedAction(DinoNeed.happiness, 0.05)];
  }

  List<DialogueAction> _affection(
    NormalizedInput input,
    ConversationContext context,
  ) {
    final asked = RegExp(
      r'do you (?:like|love) me|gosta de mim',
    ).hasMatch(input.text);
    return [
      const PlayAnimationAction(DinoAnimation.happy),
      _speak(_say.affection(asked: asked)),
      ..._cheerUp(context),
    ];
  }

  /// "Let's play!" -- playing with the Dino itself. The companion layer
  /// applies the [CareAction] (happiness up, energy down, XP).
  List<DialogueAction> _play(ConversationContext context) {
    final status = context.status;
    if (status.isUrgent(DinoNeed.energy)) {
      return [
        const PlayAnimationAction(DinoAnimation.sad),
        _speak(_say.tooTiredToPlay()),
      ];
    }
    context.clearPending();
    context.status = status
        .adjustNeed(DinoNeed.happiness, 0.15)
        .adjustNeed(DinoNeed.energy, -0.1);
    return [
      const PlayAnimationAction(DinoAnimation.jump),
      _speak(_say.letsPlay()),
      const CareAction(DinoCare.play),
    ];
  }

  /// "What is my favorite food?" -- answered from the long-term memory;
  /// when the Dino doesn't know yet, it asks (and remembers the answer).
  List<DialogueAction> _askMemory(
    IntentResult intent,
    ConversationContext context,
  ) {
    final slot = intent.slot ?? 'name';
    if (slot == 'name' || slot == 'nome') {
      final name = _memory.fact('child_name');
      if (name == null) {
        context.pending = const ChildNameQuestion();
        return [
          const PlayAnimationAction(DinoAnimation.think),
          ..._askAndWait(_say.dontKnowYet()),
        ];
      }
      return [
        const PlayAnimationAction(DinoAnimation.happy),
        _speak(_say.rememberName(name)),
      ];
    }
    if (slot == 'age') {
      final age = _memory.fact('child_age');
      return [_speak(age == null ? _say.dontKnowYet() : _say.rememberAge(age))];
    }

    final category = _topicAliases[slot];
    final favorite = category == null ? null : _memory.preference(category);
    final entry = favorite == null ? null : _entry(favorite);
    if (category == null) return [_speak(_say.dontKnowYet())];
    if (entry == null) {
      context.pending = PreferenceQuestion(topic: category, category: category);
      return [
        const PlayAnimationAction(DinoAnimation.think),
        ..._askAndWait(
          _say.dontKnowYet(),
          suggestions: _preferenceSuggestions(category),
        ),
      ];
    }
    return [
      const PlayAnimationAction(DinoAnimation.happy),
      _speak(_say.rememberFavorite(category, entry)),
    ];
  }

  /// "Eu quero uma maçã" -> "Apple! 🍎 / Maçã!" + "Can you say APPLE?".
  /// The word always comes from the official bank.
  Future<List<DialogueAction>> _learnWord(
    VocabularyEntry word,
    ConversationContext context,
  ) async {
    final firstTime =
        _memory.recall(DinoMemoryKind.learnedWord, word.id) == null;
    context.topicWord = word;
    await _memory.noteWordDiscussed(word.id, word.english);
    context.pending = RepeatWordQuestion(word: word);
    return [
      const PlayAnimationAction(DinoAnimation.happy),
      _speak(_say.learnWord(word)),
      if (firstTime)
        const GiveRewardAction(
          xp: learnWordXp,
          reason: 'companion_learn_word',
          countsAsExercise: false,
        ),
      ..._askAndWait(_say.askRepeat(word), suggestions: [word.english]),
    ];
  }

  Future<List<DialogueAction>> _gradeRepeat(
    RepeatWordQuestion question,
    String said,
    ConversationContext context,
  ) async {
    final word = question.word;
    if (_giveUp.hasMatch(said) || RegExp(r'^(?:no|n[aã]o)$').hasMatch(said)) {
      context.clearPending();
      return [_speak(_say.repeatReveal(word))];
    }
    if (_answerHasEnglish(word, said)) {
      context.clearPending();
      final xp = context.repeatedWordIds.add(word.id) ? repeatWordXp : 0;
      await _memory.reinforceLearnedWord(word.id, word.english, correct: true);
      return [
        const PlayAnimationAction(DinoAnimation.dance),
        _speak(_say.repeatCorrect(word, xp)),
        if (xp > 0)
          GiveRewardAction(xp: xp, wordId: word.id, reason: 'companion_repeat'),
        ..._cheerUp(context),
      ];
    }
    // A wrong repetition never costs mastery: it's practice, not a test.
    if (question.attempts == 0) {
      context.pending = question.nextAttempt();
      return [
        const PlayAnimationAction(DinoAnimation.think),
        ..._askAndWait(_say.repeatTryAgain(word), suggestions: [word.english]),
      ];
    }
    context.clearPending();
    return [_speak(_say.repeatReveal(word))];
  }

  static const Map<String, String> _topicAliases = {
    'food': 'food',
    'foods': 'food',
    'comida': 'food',
    'fruit': 'food',
    'animal': 'animals',
    'animals': 'animals',
    'pet': 'animals',
    'bicho': 'animals',
    'color': 'colors',
    'colour': 'colors',
    'colors': 'colors',
    'cor': 'colors',
    'place': 'places',
    'lugar': 'places',
    'toy': 'objects',
    'brinquedo': 'objects',
    'clothes': 'clothes',
    'roupa': 'clothes',
    'game': 'verbs',
    'thing': 'verbs',
    'jogo': 'verbs',
    'star': 'nature',
  };

  List<DialogueAction> _dinoPreference(
    IntentResult intent,
    ConversationContext context,
  ) {
    final slot = intent.slot ?? '';
    final category = _topicAliases[slot];
    if (category != null) {
      final favorite = _entry(ResponseGenerator.dinoFavorites[category] ?? '');
      final actions = <DialogueAction>[
        const PlayAnimationAction(DinoAnimation.happy),
        _speak(_say.dinoFavorite(category, favorite)),
      ];
      final childFavorite = _memory.preference(category);
      if (childFavorite == null) {
        context.pending = PreferenceQuestion(
          topic: category,
          category: category,
        );
        actions.addAll(
          _askAndWait(
            const DinoLine('And you?', 'E você?'),
            suggestions: _preferenceSuggestions(category),
          ),
        );
      } else if (_entry(childFavorite) case final entry?) {
        actions.add(_speak(_say.rememberPreference(category, entry)));
      }
      return actions;
    }

    final match = _extractor.resolveWord(slot);
    final entry = match.entry;
    if (entry == null) {
      return [
        _speak(
          const DinoLine(
            'Hmm, I do not know that one yet!',
            'Hmm, ainda não conheço isso!',
          ),
        ),
      ];
    }
    context.topicWord = entry;
    final likes = !_dinoDislikes.contains(entry.english);
    return [
      PlayAnimationAction(likes ? DinoAnimation.happy : DinoAnimation.think),
      _speak(_say.dinoLikes(entry, likes: likes)),
    ];
  }

  Future<List<DialogueAction>> _startActivity(
    NormalizedInput input,
    ConversationContext context,
  ) async {
    if (_extractor.mentionsQuiz(input.text)) return _startQuiz(context);
    final activity = _extractor.findActivity(input.text);
    if (activity == null) {
      return _askAndWait(
        _say.suggestActivities(),
        suggestions: const ['Word Slash', 'Study', 'Quiz', 'Adventure'],
      );
    }
    return _launch(activity, context);
  }

  Future<List<DialogueAction>> _launch(
    DinoActivity activity,
    ConversationContext context,
  ) async {
    context.clearPending();
    await _memory.rememberActivity(activity.name);
    return [
      const PlayAnimationAction(DinoAnimation.jump),
      _speak(_say.startingActivity(activity)),
      StartActivityAction(activity),
    ];
  }

  List<DialogueAction> _request(
    NormalizedInput input,
    IntentResult intent,
    ConversationContext context,
  ) {
    final text = intent.slot ?? input.text;
    final status = context.status;

    if (RegExp(r'wake|acord').hasMatch(text)) {
      context.status = status.copyWith(isSleeping: false);
      return [
        const WakeUpAction(),
        const PlayAnimationAction(DinoAnimation.happy),
        _speak(_say.wakeUp()),
      ];
    }
    if (status.isSleeping) return [_speak(_say.sleepingNow())];

    final object = _extractor.findObject(text);
    final animation = _extractor.findAnimation(text);

    List<DialogueAction> care(
      DinoNeed need,
      double delta,
      List<DialogueAction> extra, {
      DinoCare? kind,
    }) {
      context.status = context.status.adjustNeed(need, delta);
      return [
        ...extra,
        if (kind == null) UpdateNeedAction(need, delta) else CareAction(kind),
      ];
    }

    if (animation == DinoAnimation.sleep) {
      context.clearPending();
      final actions = care(DinoNeed.energy, 0.3, kind: DinoCare.sleep, const [
        GoToObjectAction(DinoObject.bed),
        PlayAnimationAction(DinoAnimation.sleep),
        SleepAction(),
      ]);
      context.status = context.status.copyWith(isSleeping: true);
      return [...actions, _speak(_say.requestReply(DinoAnimation.sleep))];
    }
    if (object == DinoObject.bathroom) {
      return [
        ...care(DinoNeed.hygiene, 0.5, const [
          GoToObjectAction(DinoObject.bathroom),
          PlayAnimationAction(DinoAnimation.happy),
        ]),
        _speak(_say.bath()),
      ];
    }
    if (animation == DinoAnimation.eat) {
      return [
        ...care(DinoNeed.hunger, 0.2, kind: DinoCare.feed, const [
          GoToObjectAction(DinoObject.food),
          PlayAnimationAction(DinoAnimation.eat),
        ]),
        _speak(_foodReply(text) ?? _say.requestReply(DinoAnimation.eat)),
      ];
    }
    if (animation == DinoAnimation.drink) {
      return [
        ...care(DinoNeed.thirst, 0.25, kind: DinoCare.water, const [
          GoToObjectAction(DinoObject.water),
          PlayAnimationAction(DinoAnimation.drink),
        ]),
        _speak(_say.requestReply(DinoAnimation.drink)),
      ];
    }
    if (object == DinoObject.toys) {
      return [
        ...care(DinoNeed.happiness, 0.15, kind: DinoCare.play, const [
          GoToObjectAction(DinoObject.toys),
          PlayAnimationAction(DinoAnimation.happy),
        ]),
        _speak(
          const DinoLine('Wee! I love my toys!', 'Eba! Adoro meus brinquedos!'),
        ),
      ];
    }
    if (animation != null) {
      return [
        ...care(DinoNeed.happiness, 0.05, [PlayAnimationAction(animation)]),
        _speak(_say.requestReply(animation)),
      ];
    }
    return [
      const PlayAnimationAction(DinoAnimation.think),
      _speak(_say.cannotDoThat()),
    ];
  }

  /// "eat an apple" -> "Yum! Apple means maçã. I love apples!"
  DinoLine? _foodReply(String text) {
    final food = _extractor.findWordInSentence(text, category: 'food');
    if (food == null) return null;
    return DinoLine(
      'Yum yum! Thank you for the ${food.english}! ${_capitalize(food.english)} means ${food.portuguese}.',
      'Nham nham! Obrigado pelo(a) ${food.portuguese}!',
    );
  }

  Future<List<DialogueAction>> _yesNo(
    IntentResult intent,
    ConversationContext context,
  ) async {
    final pending = context.pending;
    final yes = intent.intent == DinoIntent.yes;
    if (pending is OfferQuestion) {
      context.clearPending();
      if (!yes) return [_speak(_say.noReply())];
      final activity = pending.activity;
      return activity == null
          ? _startQuiz(context)
          : _launch(activity, context);
    }
    return [_speak(yes ? _say.yesReply() : _say.noReply())];
  }

  Future<List<DialogueAction>> _confirmation(
    NormalizedInput input,
    IntentResult intent,
    ConversationContext context,
  ) async {
    final pending = context.pending;
    final confirmed = intent.intent == DinoIntent.confirmWord;

    if (pending is ConfirmTeachQuestion) {
      context.clearPending();
      if (confirmed) {
        await _memory.rememberTaughtWord(
          pending.englishWord,
          pending.portuguese,
        );
        return [
          const PlayAnimationAction(DinoAnimation.happy),
          _speak(_say.learnedTaught(pending.englishWord, pending.portuguese)),
        ];
      }
      context.pending = TeachTranslationQuestion(pending.englishWord);
      return _askAndWait(
        DinoLine(
          'Oh! So what does "${pending.englishWord}" mean?',
          'Ah! Então o que "${pending.englishWord}" significa?',
        ),
      );
    }

    if (pending is! ConfirmWordQuestion) {
      return _yesNo(
        IntentResult(confirmed ? DinoIntent.yes : DinoIntent.no),
        context,
      );
    }

    final picked = _pickCandidate(pending.candidates, intent.slot);
    if (picked != null) {
      context.clearPending();
      return _explain(
        picked,
        pending.originalIntent,
        context,
        heard: picked.english,
      );
    }
    if (!confirmed) {
      context.clearPending();
      return [_speak(_say.okNeverMind())];
    }
    if (intent.rule == 'pending_word') {
      // Not one of the options: treat it as a brand new sentence.
      context.clearPending();
      final fresh = _detector.detect(input);
      return handle(input: input, intent: fresh, context: context);
    }
    if (pending.candidates.length == 1) {
      context.clearPending();
      return _explain(
        pending.candidates.single,
        pending.originalIntent,
        context,
        heard: pending.heard,
      );
    }
    return _askAndWait(
      const DinoLine('Which one?', 'Qual deles?'),
      suggestions: pending.candidates.map((e) => e.english).toList(),
    );
  }

  VocabularyEntry? _pickCandidate(
    List<VocabularyEntry> candidates,
    String? said,
  ) {
    if (said == null) return null;
    final text = Normalizer.fold(said);
    for (final c in candidates) {
      if (RegExp(
        '\\b${RegExp.escape(Normalizer.fold(c.english))}\\b',
      ).hasMatch(text)) {
        return c;
      }
    }
    return null;
  }

  // ---- answers to the Dino's questions ----------------------------------------

  Future<List<DialogueAction>> _answer(
    NormalizedInput input,
    IntentResult intent,
    ConversationContext context,
  ) async {
    final pending = context.pending;
    final said = intent.slot ?? input.text;

    // Volunteered facts work with or without a pending question.
    if (intent.statement != null && pending is! QuizQuestion) {
      if (pending is ChildNameQuestion ||
          pending is RepeatWordQuestion ||
          pending is PreferenceQuestion ||
          pending is ChildFeelingQuestion) {
        context.clearPending();
      }
      return _statement(intent, said, context);
    }

    switch (pending) {
      case QuizQuestion():
        return _gradeQuiz(pending, said, context);
      case RepeatWordQuestion():
        return _gradeRepeat(pending, said, context);
      case PreferenceQuestion():
        return _preferenceAnswer(pending, said, context);
      case TeachTranslationQuestion():
        context.clearPending();
        if (_giveUp.hasMatch(said) ||
            RegExp(r'^(?:no|n[aã]o)$').hasMatch(said)) {
          return [_speak(_say.okNeverMind())];
        }
        if (!_isTeachable(pending.englishWord, said)) {
          return _fallbackNotUnderstood(context);
        }
        await _memory.rememberTaughtWord(pending.englishWord, said);
        return [
          const PlayAnimationAction(DinoAnimation.happy),
          _speak(_say.learnedTaught(pending.englishWord, said)),
        ];
      case ChildNameQuestion():
        context.clearPending();
        // "Me dá água" is not a name: handle it as a fresh sentence.
        if (!_looksLikeName(said)) {
          return handle(
            input: input,
            intent: _detector.detect(input),
            context: context,
          );
        }
        return _statement(
          IntentResult(
            DinoIntent.answer,
            slot: said,
            statement: StatementKind.childName,
          ),
          said,
          context,
        );
      case ChildFeelingQuestion():
        context.clearPending();
        return _childFeeling(said, context);
      case ConfirmWordQuestion() ||
          ConfirmTeachQuestion() ||
          OfferQuestion() ||
          null:
        context.clearPending();
        return _fallback(input, context);
    }
  }

  Future<List<DialogueAction>> _statement(
    IntentResult intent,
    String said,
    ConversationContext context,
  ) async {
    switch (intent.statement!) {
      case StatementKind.childName:
        final name = _cleanName(said);
        if (name == null) return _fallbackNotUnderstood(context);
        await _memory.rememberFact('child_name', name);
        return [
          const PlayAnimationAction(DinoAnimation.wave),
          _speak(_say.niceToMeetYou(name)),
          ..._followUpQuestion(context),
        ];
      case StatementKind.childAge:
        await _memory.rememberFact('child_age', said);
        return [_speak(_say.age(said))];
      case StatementKind.likes:
        final topic = intent.secondSlot == null
            ? null
            : _topicAliases[intent.secondSlot!];
        final word =
            _extractor.findWordInSentence(said, category: topic) ??
            _extractor.resolveWord(said).entry;
        if (word == null) return [_speak(_say.likesUnknown(said))];
        context.topicWord = word;
        final category = topic ?? word.category;
        if (ResponseGenerator.topicNames.containsKey(category)) {
          await _memory.rememberPreference(category, word.english);
        }
        return [
          const PlayAnimationAction(DinoAnimation.happy),
          _speak(_say.likesIt(word)),
        ];
      case StatementKind.dislikes:
        final word =
            _extractor.findWordInSentence(said) ??
            _extractor.resolveWord(said).entry;
        return [_speak(_say.dislikesIt(word, said))];
      case StatementKind.childFeeling:
        return _childFeeling(said, context);
    }
  }

  static const Set<String> _notNames = {
    'você',
    'voce',
    'eu',
    'ele',
    'ela',
    'dino',
    'sim',
    'não',
    'nao',
    'oi',
    'olá',
    'ola',
    'quero',
    'me',
    'tá',
    'ta',
    'está',
    'esta',
    'what',
    'how',
  };

  /// A bare answer to "What is your name?" that can be a name: one or
  /// two plain words, none of them a common or vocabulary word.
  bool _looksLikeName(String said) {
    final words = said.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty || words.length > 2) return false;
    return words.every(
      (w) =>
          RegExp(r'^\p{L}+$', unicode: true).hasMatch(w) &&
          !_notNames.contains(w) &&
          !Tokenizer.stopWords.contains(w) &&
          _vocabulary.byEnglish(w) == null &&
          _vocabulary.byPortuguese(w).isEmpty,
    );
  }

  String? _cleanName(String said) {
    final words = said
        .replaceAll(
          RegExp(
            r'^(?:my name is|i am|meu nome é|meu nome e|me chamo|eu sou)\s+',
          ),
          '',
        )
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return null;
    final name = words.first;
    if (name.length > 20 ||
        !RegExp(r'^\p{L}+$', unicode: true).hasMatch(name)) {
      return null;
    }
    return _capitalize(name);
  }

  List<DialogueAction> _childFeeling(String said, ConversationContext context) {
    final feeling = RegExp(
      r'happy|sad|angry|mad|scared|afraid|tired|hungry|thirsty|sleepy|excited|bored|good|fine|great|okay|ok|well|bad|sick|cool|awesome|'
      r'feliz|triste|bravo|brava|com medo|cansad[oa]|com fome|com sede|com sono|animad[oa]|entediad[oa]|bem|mal|doente|[oó]tim[oa]|legal',
      unicode: true,
    ).firstMatch(said)?.group(0);
    if (feeling == null) {
      return [
        _speak(
          const DinoLine(
            'Okay! Thank you for telling me.',
            'Tá bom! Obrigado por me contar.',
          ),
        ),
      ];
    }
    final actions = <DialogueAction>[_speak(_say.childFeeling(feeling))];
    if (RegExp(r'bored|entediad').hasMatch(feeling)) {
      actions.addAll(
        _askAndWait(
          _say.suggestActivities(),
          suggestions: const ['Word Slash', 'Study', 'Quiz'],
        ),
      );
    } else if (RegExp(
      r'sad|scared|afraid|bad|sick|triste|medo|mal|doente|angry|mad|bravo|brava',
    ).hasMatch(feeling)) {
      actions.insert(0, const PlayAnimationAction(DinoAnimation.sad));
    } else {
      actions.insert(0, const PlayAnimationAction(DinoAnimation.happy));
    }
    return actions;
  }

  Future<List<DialogueAction>> _preferenceAnswer(
    PreferenceQuestion pending,
    String said,
    ConversationContext context,
  ) async {
    context.clearPending();
    if (_giveUp.hasMatch(said) ||
        RegExp(r'^(?:no|n[aã]o|nothing|nada)$').hasMatch(said)) {
      return [_speak(_say.okNeverMind())];
    }
    final word =
        _extractor.findWordInSentence(said, category: pending.category) ??
        _extractor.findWordInSentence(said) ??
        _extractor.resolveWord(said).entry;
    if (word == null) {
      return [_speak(_say.preferenceNotUnderstood(pending.category))];
    }
    context.topicWord = word;
    await _memory.rememberPreference(pending.topic, word.english);
    await _memory.noteWordDiscussed(word.id, word.english);
    return [
      const PlayAnimationAction(DinoAnimation.happy),
      _speak(_say.likesIt(word)),
      if (word.category != pending.category ||
          _extractor.findWordInSentence(said) == null)
        _speak(_say.meaning(word)),
    ];
  }

  // ---- conversation quiz --------------------------------------------------------

  List<DialogueAction> _startQuiz(ConversationContext context) {
    final word = _pickQuizWord(context);
    if (word == null) return [_speak(_say.cannotDoThat())];
    context.quizzedWordIds.add(word.id);
    final direction = _random.nextBool()
        ? QuizDirection.englishToPortuguese
        : QuizDirection.portugueseToEnglish;
    context.pending = QuizQuestion(word: word, direction: direction);
    context.topicWord = word;
    return [
      const PlayAnimationAction(DinoAnimation.think),
      ..._askAndWait(
        _say.quizQuestion(word, direction),
        suggestions: const ['I do not know'],
      ),
    ];
  }

  /// Prefers words talked about but not yet mastered in conversation,
  /// then easy words never quizzed this session.
  VocabularyEntry? _pickQuizWord(ConversationContext context) {
    final practising = _memory
        .all(DinoMemoryKind.learnedWord)
        .where(
          (m) => m.confidence < 0.6 && !context.quizzedWordIds.contains(m.key),
        )
        .map((m) => _vocabulary.byId(m.key))
        .whereType<VocabularyEntry>()
        .toList();
    if (practising.isNotEmpty && _random.nextDouble() < 0.6) {
      return practising[_random.nextInt(practising.length)];
    }
    final easy = _vocabulary.entries
        .where(
          (e) =>
              e.difficulty <= 2 &&
              !context.quizzedWordIds.contains(e.id) &&
              !e.english.contains(' ') &&
              e.category != 'greetings' &&
              e.category != 'numbers',
        )
        .toList();
    final pool = easy.isNotEmpty ? easy : _vocabulary.entries;
    if (pool.isEmpty) return null;
    return pool[_random.nextInt(pool.length)];
  }

  Future<List<DialogueAction>> _gradeQuiz(
    QuizQuestion quiz,
    String said,
    ConversationContext context,
  ) async {
    final word = quiz.word;
    if (_giveUp.hasMatch(said)) {
      context.clearPending();
      await _memory.reinforceLearnedWord(word.id, word.english, correct: false);
      return [_speak(_say.quizGiveUp(word)), ..._offerAnotherQuiz(context)];
    }

    final correct = switch (quiz.direction) {
      QuizDirection.englishToPortuguese => _answerHasTranslation(word, said),
      QuizDirection.portugueseToEnglish => _answerHasEnglish(word, said),
    };

    if (correct) {
      context.clearPending();
      await _memory.reinforceLearnedWord(word.id, word.english, correct: true);
      context.status = context.status.adjustNeed(DinoNeed.happiness, 0.1);
      return [
        const PlayAnimationAction(DinoAnimation.dance),
        _speak(_say.quizCorrect(word, quizXp)),
        GiveRewardAction(
          xp: quizXp,
          wordId: word.id,
          reason: 'conversation_quiz',
        ),
        const UpdateNeedAction(DinoNeed.happiness, 0.1),
        ..._offerAnotherQuiz(context),
      ];
    }

    // Wrong: the official translation is repeated, never replaced.
    if (quiz.attempts == 0) {
      context.pending = quiz.nextAttempt();
      return [
        const PlayAnimationAction(DinoAnimation.think),
        ..._askAndWait(
          _say.quizTryAgain(),
          suggestions: const ['I do not know'],
        ),
      ];
    }
    context.clearPending();
    await _memory.reinforceLearnedWord(word.id, word.english, correct: false);
    return [_speak(_say.quizReveal(word)), ..._offerAnotherQuiz(context)];
  }

  List<DialogueAction> _offerAnotherQuiz(ConversationContext context) {
    context.pending = const OfferQuestion.quiz();
    return _askAndWait(_say.anotherQuiz(), suggestions: const ['Yes!', 'No']);
  }

  bool _answerHasTranslation(VocabularyEntry word, String said) {
    final answer = Normalizer.fold(said);
    // Another official word typed correctly is a wrong answer, never a
    // typo ("pato" is duck, not a misspelled "gato").
    final isOtherWord = _vocabulary
        .byPortuguese(answer)
        .any((e) => e.id != word.id);
    for (final translation in word.translations) {
      final t = Normalizer.fold(translation);
      if (answer == t || RegExp('\\b${RegExp.escape(t)}\\b').hasMatch(answer)) {
        return true;
      }
      if (!isOtherWord && _isSmallTypo(answer, t)) return true; // "cachoro"
    }
    return false;
  }

  bool _answerHasEnglish(VocabularyEntry word, String said) {
    final tokens = _tokenizer.tokenize(said);
    for (final gram in _tokenizer.ngrams(
      tokens,
      maxLength: _vocabulary.maxTermWords,
    )) {
      if (_vocabulary.byEnglish(gram)?.id == word.id) return true;
    }
    final answer = said.toLowerCase();
    final isOtherWord = _vocabulary.byEnglish(answer) != null;
    return !isOtherWord && _isSmallTypo(answer, word.english.toLowerCase());
  }

  /// One typo from 5 letters up, two from 8 -- short words are too close
  /// to each other to forgive.
  bool _isSmallTypo(String answer, String expected) {
    if (expected.length < 5) return false;
    final allowed = expected.length >= 8 ? 2 : 1;
    return FuzzyMatcher.distance(answer, expected) <= allowed;
  }

  // ---- fallback ---------------------------------------------------------------------

  Future<List<DialogueAction>> _fallback(
    NormalizedInput input,
    ConversationContext context,
  ) async {
    final tokens = _tokenizer.tokenize(input.text);
    if (tokens.length == 1) {
      // A bare word ("water", "woter", "cachorro") is a meaning question.
      final match = _extractor.resolveWord(input.text);
      if (match.kind != WordMatchKind.unknown) {
        return _wordQuestion(
          IntentResult(
            match.viaPortuguese
                ? DinoIntent.askTranslation
                : DinoIntent.askWordMeaning,
            slot: input.text,
            confidence: 0.6,
          ),
          context,
        );
      }
    } else if (tokens.length > 1) {
      // Not understood as a whole, but it mentions a word the child can
      // learn ("eu quero uma maçã", "me dá água"): teach that word.
      final word = _extractor.findTeachableWord(input.text);
      if (word != null) return _learnWord(word, context);
      if (tokens.length <= 3) {
        final match = _extractor.resolveWord(input.text);
        if (match.kind != WordMatchKind.unknown) {
          return _wordQuestion(
            IntentResult(DinoIntent.askWordMeaning, slot: input.text),
            context,
          );
        }
      }
    }
    return _fallbackNotUnderstood(context);
  }

  List<DialogueAction> _fallbackNotUnderstood(ConversationContext context) {
    context.consecutiveMisunderstandings++;
    final repeated = context.consecutiveMisunderstandings >= 2;
    return [
      const PlayAnimationAction(DinoAnimation.think),
      if (repeated)
        _ask(
          _say.notUnderstood(repeated: true),
          suggestions: const [
            'What does water mean?',
            'How are you?',
            "Let's play!",
          ],
        )
      else
        _speak(_say.notUnderstood(repeated: false)),
    ];
  }
}
