import 'dart:math';

import '../brain/context/conversation_context.dart';
import '../brain/dialogue/dialogue_action.dart';
import '../brain/dialogue/response_generator.dart';
import '../brain/dino_brain.dart';
import '../brain/memory/dino_memory.dart';
import '../brain/model/dino_enums.dart';
import '../brain/vocabulary/official_vocabulary.dart';
import '../utils/date_key.dart';
import 'companion_needs_service.dart';
import 'companion_response.dart';
import 'companion_state.dart';
import 'engine/companion_entity.dart';
import 'engine/companion_intent.dart';
import 'engine/companion_intent_detector.dart';
import 'engine/context_resolver.dart';
import 'engine/language_context_resolver.dart';
import 'engine/response_selector.dart';
import 'engine/text_normalizer.dart';
import 'engine/vocabulary_detector.dart';
import 'food/food_item.dart';
import 'learning/learning_word.dart';
import 'learning/learning_word_bank.dart';
import 'learning/word_lesson_controller.dart';
import 'learning/word_mastery.dart';
import 'voice/speech_recognition_service.dart';

/// Persistence port for [CompanionState]. The app uses the Drift-backed
/// `DriftCompanionStateStore`; tests use [InMemoryCompanionStateStore].
abstract class CompanionStateStore {
  /// Null on the very first launch.
  Future<CompanionState?> load();
  Future<void> save(CompanionState state);
}

class InMemoryCompanionStateStore implements CompanionStateStore {
  InMemoryCompanionStateStore([this.saved]);

  CompanionState? saved;

  @override
  Future<CompanionState?> load() async => saved;

  @override
  Future<void> save(CompanionState state) async => saved = state;
}

class CompanionRewardResult {
  const CompanionRewardResult({required this.xpAwarded, required this.level});

  final int xpAwarded;
  final int level;
}

/// Grants XP through the app's single progress pipeline (in the app:
/// `ProgressRepository.recordAnswer`), so XP, level, streak and SRS are
/// never computed twice.
abstract class CompanionRewards {
  Future<CompanionRewardResult> grant({
    required int xp,
    String? wordId,
    required String reason,
    bool countsAsExercise = true,
  });
}

/// The virtual companion's local brain -- offline, deterministic, no LLM:
///
/// `process(input) -> TextNormalizer -> VocabularyDetector ->
///  CompanionIntentDetector -> ContextResolver -> ResponseSelector
///  (or the DinoBrain dialogue backend) -> needs/XP/persistence ->
///  CompanionResponse`
///
/// Small talk, likes, needs and care are answered from the response bank;
/// learning (word meanings, translations, quizzes, repeating words,
/// memory) goes to the [DinoBrain]. Care buttons (feed, water, play,
/// sleep) use the same needs rules. Pure Dart: the UI only calls
/// [process]/[care] and renders the [CompanionResponse]; voice, 2D or 3D
/// plug in on top of it.
class CompanionEngine {
  CompanionEngine({
    required this._vocabulary,
    required this._memory,
    required this._store,
    required this._rewards,
    this._totalXp = 0,
    this._level = 1,
    this._needs = const CompanionNeedsService(),
    LearningWordBank? learningWords,
    Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? Random(),
       _clock = clock ?? DateTime.now {
    _brain = DinoBrain(
      vocabulary: _vocabulary,
      memory: _memory,
      random: _random,
      clock: _clock,
    );
    _say = ResponseGenerator(random: _random);
    _words = VocabularyDetector(_vocabulary);
    _selector = ResponseSelector(random: _random);
    if (learningWords != null && !learningWords.isEmpty) {
      _lessons = WordLessonController(
        bank: learningWords,
        mastery: WordMasteryTracker(_memory, clock: _clock),
        vocabulary: _vocabulary,
        random: _random,
        clock: _clock,
      );
    }
  }

  final OfficialVocabulary _vocabulary;
  final DinoMemoryBank _memory;
  final CompanionStateStore _store;
  final CompanionRewards _rewards;
  final CompanionNeedsService _needs;
  final Random _random;
  final DateTime Function() _clock;
  late final DinoBrain _brain;
  late final ResponseGenerator _say;

  // The pipeline.
  static const _normalizer = TextNormalizer();
  late final VocabularyDetector _words;
  final CompanionIntentDetector _intents = CompanionIntentDetector();
  static const _resolver = ContextResolver();
  late final ResponseSelector _selector;

  /// Teaching by context ("Eu vou WALK amanhã."); null without a
  /// learning bank (then the Dino talks as before).
  WordLessonController? _lessons;

  CompanionState? _state;
  int _totalXp;
  int _level;

  /// Words the Dino offers when fed (only those in the word bank are used).
  static const List<String> _foods = [
    'apple',
    'banana',
    'cookie',
    'bread',
    'cheese',
    'carrot',
    'grape',
    'strawberry',
    'pizza',
    'cake',
    'egg',
  ];

  CompanionState get state {
    final s = _state;
    if (s == null) throw StateError('CompanionEngine.load() not called');
    return s;
  }

  int get totalXp => _totalXp;
  int get level => _level;

  /// Exposed for tests and debugging (conversation context, pending
  /// question...).
  DinoBrain get brain => _brain;

  /// Loads the persisted state and catches up the time the app was
  /// closed (a Dino left alone for hours comes back hungry).
  Future<void> load() async {
    final now = _clock();
    final stored = await _store.load();
    _state = _needs.decay(stored ?? CompanionState.initial(now), now);
    await _store.save(state);
    _syncBrain();
  }

  /// The Dino speaks first when the screen opens.
  Future<CompanionResponse> start() async {
    await _ensureLoaded();
    _refresh();
    if (state.isSleeping) return _sleepingResponse();
    final opening = await _fromReply(await _brain.start());
    return opening.copyWith(intent: CompanionIntent.greeting);
  }

  /// One sentence from the child (typed or recognized from speech).
  Future<CompanionResponse> process(String input) async {
    await _ensureLoaded();
    _refresh();
    final text = _normalizer.normalize(input);
    if (_lessons case final lessons?) {
      final reply = await lessons.handle(
        text,
        _brain.context,
        level: _lessonLevel,
      );
      if (reply != null) {
        await _memory.rememberFact(
          MemoryKeys.lastInteraction,
          _clock().toIso8601String(),
        );
        final response = await _fromLesson(reply);
        _recordTurns(input, response);
        noteSaid(response);
        return response;
      }
    }
    final vocabulary = _words.detect(text);
    _languageContext = _languages.resolve(
      text.folded,
      namesAWord: [
        ...vocabulary.words.map((w) => w.english),
        ...vocabulary.entities.map((e) => e.english),
      ].any((w) => !_languageWords.contains(w)),
    );
    if (_languageContext.request case final request?) {
      await _memory.rememberFact(
        MemoryKeys.lastInteraction,
        _clock().toIso8601String(),
      );
      final response = _explain(request);
      _recordTurns(input, response);
      return response;
    }
    final match = _intents.detect(text, pending: _brain.context.pending);
    final context = _resolver.resolve(
      match: match,
      folded: text.folded,
      tokenCount: text.tokens.length,
      isQuestion: text.isQuestion,
      vocabulary: vocabulary,
      detector: _words,
      state: state,
      conversation: _brain.context,
      level: _level,
      childName: _memory.fact('child_name'),
    );

    await _memory.rememberFact(
      MemoryKeys.lastInteraction,
      _clock().toIso8601String(),
    );
    final CompanionResponse response;
    var intent = context.intent;
    if (context.route == ResponseRoute.companion) {
      response = await _answer(context);
      _recordTurns(input, response);
    } else {
      final topicBefore = _brain.context.topicWord;
      final missesBefore = _brain.context.consecutiveMisunderstandings;
      final reply = await _brain.respond(input);
      response = await _fromReply(reply, topicBefore: topicBefore);
      // The brain couldn't make sense of it (even as an answer to its own
      // question): report it as UNKNOWN.
      if (_brain.context.consecutiveMisunderstandings > missesBefore) {
        intent = CompanionIntent.unknown;
      }
    }
    final topic = _topicOf(intent, context.entity);
    _brain.context
      ..lastIntent = intent.name
      ..lastTopic = topic ?? _brain.context.lastTopic
      ..conversationLanguage = _languageContext.conversationLanguage.name;
    final reply = response.copyWith(
      intent: intent,
      // "I don't know that yet": pensive, never scared.
      animation: intent == CompanionIntent.unknown
          ? CompanionAnimation.thinking
          : null,
      detectedWords: context.detectedWords,
      detectedEntity: context.entity,
      voice: _languages.voiceFor(intent),
      shouldListenAgain:
          intent != CompanionIntent.goodbye && response.activity == null,
    );
    final withWord = _hybridAllowedAfter(intent)
        ? await _withHybrid(reply, context: topic)
        : reply;
    noteSaid(withWord);
    return withWord;
  }

  // ---- teaching by context ("Eu vou WALK amanhã.") -----------------------------

  /// Replies since the Dino last slipped an English word into a
  /// Portuguese sentence.
  int _repliesSinceHybrid = 0;

  /// Template level for the child's English: 1 (A1) .. 3 (B1).
  int get _lessonLevel => EnglishTier.forLevel(_level).index + 1;

  /// The word lessons (word being taught, mastery...), for tests and
  /// debugging.
  WordLessonController? get lessons => _lessons;

  bool _hybridAllowedAfter(CompanionIntent intent) => switch (intent) {
    CompanionIntent.goodbye ||
    CompanionIntent.unknown ||
    CompanionIntent.requestPortuguese ||
    CompanionIntent.requestTranslation ||
    CompanionIntent.learnWord ||
    CompanionIntent.translateWord ||
    CompanionIntent.repeatWord => false,
    _ => true,
  };

  /// Now and then (never twice in a row, surely after a few replies) the
  /// Dino adds a Portuguese sentence with one English word on the topic:
  /// "Eu quero EAT uma maçã." -- the child may ask what it means. Never
  /// while it waits for an answer, opens a game or sleeps.
  Future<CompanionResponse> _withHybrid(
    CompanionResponse response, {
    String? context,
    bool always = false,
  }) async {
    final lessons = _lessons;
    if (lessons == null) return response;
    if (response.lines.isEmpty ||
        response.isWaitingForAnswer ||
        response.activity != null ||
        state.isSleeping ||
        _brain.context.pending != null) {
      _repliesSinceHybrid++;
      return response;
    }
    final due =
        always ||
        _repliesSinceHybrid >= 3 ||
        (_repliesSinceHybrid >= 1 && _random.nextDouble() < 0.4);
    if (!due) {
      _repliesSinceHybrid++;
      return response;
    }
    final sentence = await lessons.sentence(
      level: _lessonLevel,
      context: context,
      conversation: _brain.context,
    );
    if (sentence == null) return response;
    _repliesSinceHybrid = 0;
    return response.copyWith(lines: [...response.lines, sentence.toLine()]);
  }

  /// The topic of an exchange, to keep the English word on it.
  static String? _topicOf(CompanionIntent intent, CompanionEntity? entity) {
    switch (intent) {
      case CompanionIntent.askHungry ||
          CompanionIntent.food ||
          CompanionIntent.commandEat:
        return 'food';
      case CompanionIntent.askThirsty ||
          CompanionIntent.water ||
          CompanionIntent.commandDrink:
        return 'drink';
      case CompanionIntent.askPlay ||
          CompanionIntent.play ||
          CompanionIntent.commandPlay:
        return 'play';
      case CompanionIntent.askSleepy ||
          CompanionIntent.sleep ||
          CompanionIntent.commandSleep:
        return 'sleep';
      default:
        break;
    }
    return switch (entity?.category) {
      EntityCategory.food => 'food',
      EntityCategory.drink => 'drink',
      EntityCategory.animal => 'animal',
      EntityCategory.toy || EntityCategory.game => 'play',
      EntityCategory.place => 'place',
      EntityCategory.nature => 'nature',
      _ => null,
    };
  }

  /// A lesson step as a reply (XP through the usual rewards).
  Future<CompanionResponse> _fromLesson(LessonReply reply) async {
    final word = reply.word;
    final xp = await _grant(
      reply.xp,
      wordId: word == null ? null : _vocabulary.byEnglish(word.english)?.id,
      reason: 'companion_word_lesson',
      countsAsExercise: false,
    );
    if (reply.success && word != null) {
      await _memory.rememberFact(MemoryKeys.lastWordLearned, word.english);
      _state = state.adjust(DinoNeed.happiness, 3);
      await _save();
    }
    return CompanionResponse(
      lines: reply.lines,
      emotion: _emotion(xp),
      animation: reply.success
          ? CompanionAnimation.celebrating
          : CompanionAnimation.talking,
      state: state,
      intent: reply.success || reply.awaitingRepetition
          ? CompanionIntent.repeatWord
          : CompanionIntent.learnWord,
      xpReward: xp,
      vocabulary: [?word?.english],
      suggestions: reply.awaitingRepetition && word != null
          ? [word.english]
          : const [],
      isWaitingForAnswer: reply.awaitingRepetition,
      // Mixed lines carry their own languages.
      voice: VoiceMode.english,
    );
  }

  /// The meaning of an English word shown in a sentence (the child
  /// tapped it), or null if the Dino doesn't know it.
  LearningWord? wordInfo(String english) => _lessons?.wordFor(english);

  /// The child tapped a word and asked what it is: the explanation, then
  /// "Agora fala comigo". Null if unknown.
  Future<CompanionResponse?> explainWord(String english) async {
    await _ensureLoaded();
    _refresh();
    final lessons = _lessons;
    final word = lessons?.wordFor(english);
    if (lessons == null || word == null) return null;
    final response = await _fromLesson(
      await lessons.explain(word, _brain.context, level: _lessonLevel),
    );
    noteSaid(response);
    return response;
  }

  /// "⭐ Praticar": straight to "Fala comigo: WALK.".
  Future<CompanionResponse?> practiceWord(String english) async {
    await _ensureLoaded();
    _refresh();
    final lessons = _lessons;
    final word = lessons?.wordFor(english);
    if (lessons == null || word == null) return null;
    final response = await _fromLesson(lessons.practice(word, _brain.context));
    noteSaid(response);
    return response;
  }

  // ---- language ---------------------------------------------------------------

  static const LanguageContextResolver _languages = LanguageContextResolver();

  /// Words that talk *about* language ("como fala isso"), not a word to
  /// translate.
  static const Set<String> _languageWords = {
    'speak',
    'to speak',
    'say',
    'to say',
    'talk',
    'to talk',
    'mean',
    'understand',
    'to understand',
    'translate',
    'portuguese',
    'english',
  };

  LanguageContext _languageContext = const LanguageContext();

  /// The language of the last message and whether it asked for
  /// Portuguese.
  LanguageContext get languageContext => _languageContext;

  /// The last thing the Dino said that has a Portuguese meaning: what
  /// "Não entendi" / "O que significa?" refer to.
  CompanionResponse? _lastSaid;

  /// Every reply shown to the child goes through here (the controller
  /// calls it), so language requests know what was said last.
  void noteSaid(CompanionResponse response) {
    _lessons?.noteSaid(response, _brain.context);
    if (response.intent == CompanionIntent.requestPortuguese ||
        response.intent == CompanionIntent.requestTranslation) {
      return;
    }
    if (response.lines.any((l) => l.translation != null)) _lastSaid = response;
  }

  /// "Fala português" / "Não entendi": the last reply again, in the
  /// Portuguese voice (this reply only). "O que significa?": the last
  /// reply in English, then its meaning.
  CompanionResponse _explain(LanguageRequest request) {
    final last = [
      for (final line in _lastSaid?.lines ?? const <CompanionLine>[])
        if (line.translation != null) line,
    ];
    final List<CompanionLine> lines;
    final VoiceMode voice;
    switch (request) {
      case LanguageRequest.translation:
        voice = VoiceMode.bilingual;
        lines = last.isNotEmpty
            ? last
            : const [
                CompanionLine(
                  "Tell me a word and I'll translate it!",
                  'Me fale uma palavra e eu traduzo!',
                ),
              ];
      case LanguageRequest.notUnderstood:
        voice = VoiceMode.portuguese;
        lines = last.isNotEmpty
            ? [for (final l in last) CompanionLine(l.translation!)]
            : const [
                CompanionLine(
                  'Tudo bem! Pode falar comigo em português ou em inglês.',
                ),
              ];
      case LanguageRequest.portuguese:
        voice = VoiceMode.portuguese;
        lines = [
          const CompanionLine('Claro! Eu posso falar português.'),
          for (final l in last) CompanionLine(l.translation!),
        ];
    }
    return CompanionResponse(
      lines: lines,
      emotion: _emotion(0),
      animation: state.isSleeping
          ? CompanionAnimation.sleeping
          : CompanionAnimation.happy,
      state: state,
      intent: request == LanguageRequest.translation
          ? CompanionIntent.requestTranslation
          : CompanionIntent.requestPortuguese,
      voice: voice,
    );
  }

  // ---- ball game ----------------------------------------------------------------

  /// XP per hit, a bonus every [ballComboStep] hits in a row, and at
  /// most [maxBallXpPerSession] from hits in one visit.
  static const int ballHitXp = 1;
  static const int ballComboStep = 5;
  static const int ballComboXp = 5;
  static const int maxBallXpPerSession = 40;

  /// 🪙 every 10 hits in a row, at most [dailyBallCoinCap] a day: the
  /// game pays a little, studying pays more.
  static const int ballCoinsPerTen = 2;
  static const int dailyBallCoinCap = 20;

  int _ballXp = 0;
  bool _ballPlayedThisGame = false;

  static const String _ballCoinsDateKey = 'ball_coins_date';
  static const String _ballCoinsTodayKey = 'ball_coins_today';

  /// A new ball game starts: the first hit will be the real "play" care.
  void startBallGame() => _ballPlayedThisGame = false;

  /// The child hit the ball ([combo] in a row). The first hit is the
  /// "play" care (happiness, a word); then small XP, and short English
  /// cheers on combos -- most hits are silent so the game stays fast.
  Future<CompanionResponse> ballHit(int combo) async {
    await _ensureLoaded();
    if (!_ballPlayedThisGame) {
      _ballPlayedThisGame = true;
      return care(DinoCare.play);
    }
    _refresh();
    var xp = _ballXp < maxBallXpPerSession ? ballHitXp : 0;
    final lines = <CompanionLine>[];
    var coins = 0;
    if (combo % ballComboStep == 0) {
      if (_ballXp + xp < maxBallXpPerSession) xp += ballComboXp;
      lines.add(
        _pick(const [
          CompanionLine('Great!', 'Muito bem!'),
          CompanionLine('Good job!', 'Bom trabalho!'),
          CompanionLine('Fast! Hit it!', 'Rápido! Bate nela!'),
          CompanionLine('Bounce! Bounce!', 'Quica! Quica!'),
          CompanionLine('Again! Again!', 'De novo! De novo!'),
        ]),
      );
      if (combo % 10 == 0) coins = await _ballCoins(ballCoinsPerTen);
    }
    xp = xp.clamp(0, maxBallXpPerSession - _ballXp);
    _ballXp += xp;
    final granted = await _grant(
      xp,
      reason: 'companion_ball',
      countsAsExercise: false,
    );
    if (coins > 0) lines.add(CompanionLine('+$coins 🪙'));
    return CompanionResponse(
      lines: lines,
      emotion: _emotion(granted),
      animation: combo % ballComboStep == 0
          ? CompanionAnimation.celebrating
          : CompanionAnimation.happy,
      state: state,
      xpReward: granted,
      coinReward: coins,
      vocabulary: const ['ball', 'hit'],
    );
  }

  /// The ball stopped: a little cheer to try again.
  Future<CompanionResponse> ballStopped(int lostCombo) async {
    await _ensureLoaded();
    _refresh();
    return CompanionResponse(
      lines: [
        lostCombo >= 3
            ? _pick(const [
                CompanionLine('Oops! Again!', 'Ops! De novo!'),
                CompanionLine('Hit the ball!', 'Bate na bola!'),
              ])
            : const CompanionLine('Ball! Hit it!', 'Bola! Bate nela!'),
      ],
      emotion: _emotion(0),
      animation: CompanionAnimation.listening,
      state: state,
      vocabulary: const ['ball', 'again'],
    );
  }

  /// The game ended: a small bonus for the time played (up to 5 XP).
  Future<CompanionResponse> ballGameOver({
    required int hits,
    required int bestCombo,
    required Duration played,
  }) async {
    await _ensureLoaded();
    _refresh();
    final bonus = hits == 0 ? 0 : (played.inSeconds ~/ 15).clamp(0, 5);
    final xp = await _grant(
      bonus,
      reason: 'companion_ball',
      countsAsExercise: false,
    );
    return CompanionResponse(
      lines: [
        hits == 0
            ? const CompanionLine("Let's play later!", 'Vamos brincar depois!')
            : CompanionLine(
                'Good game! $hits hits!',
                'Bom jogo! $hits batidas!',
              ),
        if (bestCombo >= 10)
          CompanionLine(
            'Wow! $bestCombo in a row!',
            'Uau! $bestCombo seguidas!',
          ),
      ],
      emotion: _emotion(xp),
      animation: hits == 0
          ? CompanionAnimation.idle
          : CompanionAnimation.celebrating,
      state: state,
      xpReward: xp,
      vocabulary: const ['ball', 'play'],
    );
  }

  /// [want] coins if today's ball allowance has room.
  Future<int> _ballCoins(int want) async {
    final today = dateKeyFor(_clock());
    final used = _memory.fact(_ballCoinsDateKey) == today
        ? int.tryParse(_memory.fact(_ballCoinsTodayKey) ?? '') ?? 0
        : 0;
    final coins = want.clamp(0, dailyBallCoinCap - used).toInt();
    if (coins > 0) {
      await _memory.rememberFact(_ballCoinsDateKey, today);
      await _memory.rememberFact(_ballCoinsTodayKey, '${used + coins}');
    }
    return coins;
  }

  /// A care button. Feeding/water/play also teach a word ("Apple! Say:
  /// apple!") the child can repeat for XP. [about] picks the word when
  /// the child named it ("come uma banana").
  Future<CompanionResponse> care(
    DinoCare care, {
    CompanionEntity? about,
    FoodItem? food,
  }) async {
    await _ensureLoaded();
    _refresh();
    _say.tier = EnglishTier.forLevel(_level);
    final outcome = _needs.applyCare(state, care, _clock(), food: food);
    _state = outcome.state;
    if (outcome.applied) {
      await _memory.rememberFact(MemoryKeys.lastActivity, care.name);
    }
    final xp = await _grant(
      outcome.xp,
      reason: 'companion_${care.name}',
      countsAsExercise: false,
    );

    final lines = _careLines(care, outcome, xp);
    if (food != null && outcome.applied) {
      lines[0] = CompanionLine(
        'Yummy! ${food.englishName}! ${food.emoji}',
        'Delícia! ${food.name}!',
      );
    }
    final context = _brain.context;
    context.clearPending();
    var suggestions = const <String>[];
    VocabularyEntry? word;
    if (outcome.applied) {
      word = food != null
          ? _vocabulary.byEnglish(food.englishName.toLowerCase())
          : null;
      // Never teach another food than the one just eaten.
      if (food == null) word = _wordFor(about) ?? _careWord(care);
      if (word != null) {
        context.topicWord = word;
        // A dragged food already says its name ("Yummy! Bread!").
        if (food == null) lines.insert(0, _line(_say.learnWord(word)));
        // Ask to repeat only words not practised yet this session, and
        // never while falling asleep.
        if (care != DinoCare.sleep &&
            !context.repeatedWordIds.contains(word.id)) {
          context.pending = RepeatWordQuestion(word: word);
          lines.add(_line(_say.askRepeat(word)));
          suggestions = [word.english];
        }
      }
    }
    await _save();
    return CompanionResponse(
      lines: lines,
      emotion: _emotion(xp),
      animation: _animation(null, outcome.applied ? care : null, 0),
      state: state,
      care: outcome.applied ? care : null,
      xpReward: xp,
      vocabulary: [?word?.english],
      suggestions: suggestions,
      isWaitingForAnswer: suggestions.isNotEmpty,
    );
  }

  Future<CompanionResponse> wakeUp() async {
    await _ensureLoaded();
    _refresh();
    _state = _needs.wakeUp(state);
    await _save();
    return CompanionResponse(
      lines: [
        _line(_say.wakeUp()),
        if (state.mostUrgentNeed case final need?)
          _line(_say.needComplaint(need)),
      ],
      emotion: _emotion(0),
      animation: CompanionAnimation.happy,
      state: state,
      vocabulary: const ['wake'],
    );
  }

  /// What the child should answer in, for the voice recognizer: English
  /// while the Dino waits for an English word ("Say: apple!", "How do
  /// you say cachorro?"), otherwise auto-detected.
  SpeechLanguageHint get expectedLanguage => switch (_brain.context.pending) {
    RepeatWordQuestion() => SpeechLanguageHint.english,
    QuizQuestion(direction: QuizDirection.portugueseToEnglish) =>
      SpeechLanguageHint.english,
    _ => SpeechLanguageHint.auto,
  };

  // ---- pet activities -------------------------------------------------------------

  /// XP for a goal in the ball minigame (once per session per goal, up to
  /// [maxGoalRewards]).
  static const int goalXp = 20;
  static const int kicksPerGoal = 3;
  static const int maxGoalRewards = 3;

  int _kicks = 0;
  int _goalsRewarded = 0;

  /// Food or a drink appears on screen: the Dino looks and asks for it.
  /// The child picked [food] in the panel: the Dino names it in English
  /// ("Let's eat bread! 🍞") and waits for it.
  Future<CompanionResponse> offerFood(FoodItem food) async {
    await _ensureLoaded();
    _refresh();
    final english = food.englishName.toLowerCase();
    final portuguese = food.name.toLowerCase();
    return CompanionResponse(
      lines: [
        CompanionLine(
          "Let's eat $english! ${food.emoji}",
          'Vamos comer $portuguese!',
        ),
      ],
      emotion: _emotion(0),
      animation: state.isSleeping
          ? CompanionAnimation.sleeping
          : CompanionAnimation.listening,
      state: state,
      vocabulary: [english],
    );
  }

  Future<CompanionResponse> offer(DinoCare care) => _quick(
    care == DinoCare.water ? 'offer.water' : 'offer.food',
    CompanionAnimation.listening,
  );

  /// The "Dormir" button: the bedroom appears and the Dino waits for the
  /// child to tap the bed.
  Future<CompanionResponse> bedtimeInvite() async {
    await _ensureLoaded();
    _refresh();
    return CompanionResponse(
      lines: [
        _pick(const [
          CompanionLine(
            'Bedtime? Tap the bed!',
            'Hora de dormir? Toca na cama!',
          ),
          CompanionLine(
            "I'm sleepy... Where is my bed?",
            'Estou com sono... Cadê minha cama?',
          ),
        ]),
      ],
      emotion: _emotion(0),
      animation: CompanionAnimation.sleepy,
      state: state,
      vocabulary: const ['bed', 'sleep', 'bedroom'],
    );
  }

  /// The "Brincar" button: the ball is waiting to be kicked.
  Future<CompanionResponse> playInvite() async => _withHybrid(
    await _quick('play.invite', CompanionAnimation.happy),
    context: 'play',
    always: true,
  );

  /// The ball was tapped or picked up: the Dino watches it.
  Future<CompanionResponse> ballNoticed({required bool dragging}) =>
      _quick(dragging ? 'ball.drag' : 'ball.tap', CompanionAnimation.listening);

  /// The child kicked/threw the ball. The first kick of a round is the
  /// real "play" care (state, XP, a word to learn); the next ones are
  /// cheers; every [kicksPerGoal] kicks is a GOAL (+[goalXp], minigame).
  Future<CompanionResponse> kick() async {
    await _ensureLoaded();
    _refresh();
    _kicks++;
    if (_kicks == 1) return care(DinoCare.play);
    if (_kicks < kicksPerGoal) {
      return _quick('kick', CompanionAnimation.playing);
    }
    _kicks = 0;
    final rewarded = _goalsRewarded < maxGoalRewards;
    if (rewarded) _goalsRewarded++;
    _state = state.adjust(DinoNeed.happiness, 5);
    final xp = rewarded
        ? await _grant(
            goalXp,
            reason: 'companion_ball_goal',
            countsAsExercise: false,
          )
        : 0;
    await _save();
    return CompanionResponse(
      lines: [
        _selector.select('goal', tier: EnglishTier.forLevel(_level)),
        if (xp > 0) CompanionLine('+$xp XP!'),
      ],
      emotion: CompanionEmotion.excited,
      animation: CompanionAnimation.celebrating,
      state: state,
      xpReward: xp,
      vocabulary: const ['ball'],
    );
  }

  /// A need just became urgent: the Dino says so by itself ("I'm
  /// hungry!"), or null when it's fine (or asleep).
  Future<CompanionResponse?> needNudge() async {
    await _ensureLoaded();
    _refresh();
    final need = state.mostUrgentNeed;
    if (need == null || need == DinoNeed.hygiene || state.isSleeping) {
      return null;
    }
    return _withHybrid(
      await _quick('nudge.${need.name}', idleAnimationFor(state)),
      context: switch (need) {
        DinoNeed.hunger => 'food',
        DinoNeed.thirst => 'drink',
        DinoNeed.energy => 'sleep',
        _ => 'play',
      },
      always: true,
    );
  }

  Future<CompanionResponse> _quick(
    String key,
    CompanionAnimation animation,
  ) async {
    await _ensureLoaded();
    _refresh();
    return CompanionResponse(
      lines: [_selector.select(key, tier: EnglishTier.forLevel(_level))],
      emotion: _emotion(0),
      animation: state.isSleeping ? CompanionAnimation.sleeping : animation,
      state: state,
    );
  }

  /// Applies the time passed since the last update (the screen calls
  /// this periodically so the bars move while it's open).
  Future<CompanionState> tick() async {
    await _ensureLoaded();
    _refresh();
    await _save();
    return state;
  }

  /// What the pet does when nothing is happening.
  static CompanionAnimation idleAnimationFor(CompanionState state) {
    if (state.isSleeping) return CompanionAnimation.sleeping;
    return switch (state.mostUrgentNeed) {
      DinoNeed.hunger => CompanionAnimation.hungry,
      DinoNeed.thirst => CompanionAnimation.thirsty,
      DinoNeed.energy => CompanionAnimation.sleepy,
      DinoNeed.happiness => CompanionAnimation.sad,
      DinoNeed.hygiene || null => CompanionAnimation.idle,
    };
  }

  // ---- the companion's own answers ----------------------------------------------

  /// Small talk, likes, needs and care, answered from the response bank.
  Future<CompanionResponse> _answer(ResolvedContext c) async {
    switch (c.intent) {
      case CompanionIntent.commandEat:
        return care(DinoCare.feed, about: _edible(c.entity, drink: false));
      case CompanionIntent.commandDrink:
        return care(DinoCare.water, about: _edible(c.entity, drink: true));
      case CompanionIntent.commandPlay || CompanionIntent.askPlay:
        return care(DinoCare.play);
      case CompanionIntent.commandSleep:
        return care(DinoCare.sleep);
      default:
        break;
    }

    final tier = c.tier;
    final name = c.childName == null ? '' : ', ${c.childName}';
    CompanionLine say(String key, [Map<String, String> vars = const {}]) =>
        _selector.select(key, tier: tier, vars: {'name': name, ...vars});

    final lines = <CompanionLine>[];
    var animation = CompanionAnimation.talking;
    var suggestions = const <String>[];
    PendingQuestion? askNext;
    final entity = c.entity;
    final needKey = switch (c.need) {
      DinoNeed.hunger => 'hunger',
      DinoNeed.thirst => 'thirst',
      DinoNeed.energy => 'energy',
      DinoNeed.happiness => 'happiness',
      DinoNeed.hygiene || null => null,
    };

    switch (c.intent) {
      case CompanionIntent.greeting:
        animation = CompanionAnimation.happy;
        lines
          ..add(say('greeting'))
          ..add(say('greeting.ask'));
        askNext = const ChildFeelingQuestion();
      case CompanionIntent.goodbye:
        animation = CompanionAnimation.happy;
        lines.add(say('goodbye'));
      case CompanionIntent.thank:
        animation = CompanionAnimation.happy;
        lines.add(say('thank'));
      case CompanionIntent.apology:
        lines.add(say('apology'));
      case CompanionIntent.affection:
        animation = CompanionAnimation.happy;
        lines.add(say(c.asksBack ? 'affection.asked' : 'affection'));
        _state = state.adjust(DinoNeed.happiness, 5);
      case CompanionIntent.praise:
        animation = CompanionAnimation.happy;
        lines.add(say('praise'));
        _state = state.adjust(DinoNeed.happiness, 5);
      case CompanionIntent.askAge:
        lines
          ..add(say('age'))
          ..add(say('age.ask'));
      case CompanionIntent.askHowAreYou:
        final urgent = c.band == NeedBand.urgent ? needKey : null;
        animation = urgent == null
            ? CompanionAnimation.happy
            : CompanionAnimation.sad;
        lines
          ..add(say(urgent == null ? 'feeling.fine' : 'feeling.$urgent'))
          ..add(say('feeling.askBack'));
        askNext = const ChildFeelingQuestion();
      case CompanionIntent.askWhatAreYouDoing:
        final urgent = c.band == NeedBand.urgent ? needKey : null;
        lines.add(say(urgent == null ? 'doing.fine' : 'doing.$urgent'));
      case CompanionIntent.askHungry ||
          CompanionIntent.askThirsty ||
          CompanionIntent.askSleepy:
        animation = c.band == NeedBand.urgent
            ? CompanionAnimation.sad
            : CompanionAnimation.happy;
        lines.add(say('$needKey.${c.band.name}'));
      case CompanionIntent.askLike:
        if (entity == null) {
          animation = CompanionAnimation.thinking;
          lines.add(say('like.unknown'));
        } else {
          final vars = ResponseSelector.entityVars(entity);
          animation = entity.dinoLikes
              ? CompanionAnimation.happy
              : CompanionAnimation.talking;
          lines.add(
            say(
              !entity.dinoLikes
                  ? 'like.no'
                  : switch (entity.category) {
                      EntityCategory.food => 'like.food',
                      EntityCategory.drink => 'like.drink',
                      _ => 'like.thing',
                    },
              vars,
            ),
          );
        }
      case CompanionIntent.askDislike:
        if (entity == null) {
          lines.add(say('dislike.general'));
        } else {
          lines.add(
            say(
              entity.dinoLikes ? 'dislike.no' : 'dislike.yes',
              ResponseSelector.entityVars(entity),
            ),
          );
        }
      case CompanionIntent.askFavorite:
        final topic = c.topic;
        if (topic == null) {
          lines.add(say('favorite.unknown'));
        } else {
          animation = CompanionAnimation.happy;
          final fav = topic.favorite;
          final topicVars = {
            'topicEn': topic.english,
            'myFavPt': topic.myFavoritePt,
            'yourFavPt': topic.yourFavoritePt,
            'favEn': fav.english,
            'FavEn': _cap(fav.english),
            'favEnG': fav.englishGeneric,
            'favPt': fav.portuguese,
            'FavPt': _cap(fav.portuguese),
            'favPtG': fav.portugueseGeneric,
            'emoji': fav.emoji,
          };
          lines.add(say('favorite', topicVars));
          // "And you?" -- the brain remembers the child's answer.
          final category = topic.brainCategory;
          if (category != null && _memory.preference(category) == null) {
            lines.add(say('favorite.ask', topicVars));
            askNext = PreferenceQuestion(topic: category, category: category);
            suggestions = [
              for (final e in _vocabulary.inCategory(category).take(3))
                e.english,
            ];
          }
        }
      default:
        // Routed here only for intents listed in ContextResolver.
        lines.add(say('like.unknown'));
    }

    final context = _brain.context;
    if (askNext != null) {
      context.pending = askNext;
    } else if (context.pending is ChildFeelingQuestion) {
      context.clearPending();
    }
    context.consecutiveMisunderstandings = 0;
    final official = entity == null
        ? null
        : _vocabulary.byEnglish(entity.english);
    await _save();
    return CompanionResponse(
      lines: lines,
      emotion: _emotion(0),
      animation: animation,
      state: state,
      vocabulary: [?official?.english],
      suggestions: suggestions,
      isWaitingForAnswer: askNext != null,
    );
  }

  /// "Come uma banana" -> banana; a drink only for drink commands.
  CompanionEntity? _edible(CompanionEntity? entity, {required bool drink}) {
    if (entity == null) return null;
    final isDrink = entity.category == EntityCategory.drink;
    final isFood = entity.category == EntityCategory.food;
    return (drink ? isDrink : isFood) ? entity : null;
  }

  /// The official word for a thing the child named (only real words).
  VocabularyEntry? _wordFor(CompanionEntity? entity) {
    if (entity == null || entity.id == 'FOOD') return null;
    return _vocabulary.byEnglish(entity.english);
  }

  /// Keeps the brain's conversation history complete even when the
  /// companion answered by itself.
  void _recordTurns(String input, CompanionResponse response) {
    final now = _clock();
    _brain.context
      ..addTurn(ConversationTurn(speaker: Speaker.child, text: input, at: now))
      ..addTurn(
        ConversationTurn(
          speaker: Speaker.dino,
          text: response.englishText,
          at: now,
        ),
      );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ---- internals --------------------------------------------------------------

  Future<void> _ensureLoaded() async {
    if (_state == null) await load();
  }

  void _refresh() {
    _state = _needs.decay(state, _clock());
    _syncBrain();
  }

  void _syncBrain() =>
      _brain.updateStatus(state.toStatus(totalXp: _totalXp, level: _level));

  Future<void> _save() async {
    await _store.save(state);
    _syncBrain();
  }

  Future<int> _grant(
    int xp, {
    String? wordId,
    required String reason,
    bool countsAsExercise = true,
  }) async {
    if (xp <= 0) return 0;
    final result = await _rewards.grant(
      xp: xp,
      wordId: wordId,
      reason: reason,
      countsAsExercise: countsAsExercise,
    );
    _totalXp += result.xpAwarded;
    _level = result.level;
    return result.xpAwarded;
  }

  /// Executes the brain's actions against the needs/XP systems.
  Future<CompanionResponse> _fromReply(
    DinoReply reply, {
    VocabularyEntry? topicBefore,
  }) async {
    final lines = <CompanionLine>[];
    var suggestions = const <String>[];
    DinoAnimation? animation;
    DinoCare? care;
    DinoActivity? activity;
    var xp = 0;

    for (final action in reply.actions) {
      switch (action) {
        case SpeakAction(:final text, :final translation):
          lines.add(CompanionLine(text, translation));
        case AskAction(:final text, :final translation):
          lines.add(CompanionLine(text, translation));
          suggestions = action.suggestions;
        case PlayAnimationAction(animation: final a):
          animation = a;
        case CareAction(care: final c):
          final outcome = _needs.applyCare(state, c, _clock());
          _state = outcome.state;
          if (outcome.applied) care = c;
          xp += await _grant(
            outcome.xp,
            reason: 'companion_${c.name}',
            countsAsExercise: false,
          );
        case UpdateNeedAction(:final need, :final delta):
          _state = state.adjust(need, delta * CompanionState.max);
        case WakeUpAction():
          _state = _needs.wakeUp(state);
        case GiveRewardAction():
          if (action.wordId case final id?) {
            if (_vocabulary.byId(id) case final word?) {
              await _memory.rememberFact(
                MemoryKeys.lastWordLearned,
                word.english,
              );
            }
          }
          xp += await _grant(
            action.xp,
            wordId: action.wordId,
            reason: action.reason,
            countsAsExercise: action.countsAsExercise,
          );
        case StartActivityAction(activity: final a):
          activity = a;
        // Sleep is applied through its CareAction; walking to objects and
        // waiting are visual only for now.
        case SleepAction() || GoToObjectAction() || WaitForAnswerAction():
          break;
      }
    }
    await _save();

    final topic = _brain.context.topicWord;
    final newTopic = topic != null && topic.id != topicBefore?.id
        ? topic.english
        : null;
    return CompanionResponse(
      lines: lines,
      emotion: _emotion(xp),
      animation: _animation(animation, care, xp),
      state: state,
      care: care,
      xpReward: xp,
      vocabulary: [?newTopic],
      suggestions: suggestions,
      activity: activity,
      isWaitingForAnswer: reply.isWaitingForAnswer,
    );
  }

  CompanionResponse _sleepingResponse() => CompanionResponse(
    lines: [_line(_say.sleepingNow())],
    emotion: CompanionEmotion.sleepy,
    animation: CompanionAnimation.sleeping,
    state: state,
  );

  CompanionEmotion _emotion(int xp) {
    if (state.isSleeping) return CompanionEmotion.sleepy;
    switch (state.mostUrgentNeed) {
      case DinoNeed.hunger:
        return CompanionEmotion.hungry;
      case DinoNeed.thirst:
        return CompanionEmotion.thirsty;
      case DinoNeed.energy:
        return CompanionEmotion.sleepy;
      case DinoNeed.happiness:
        return CompanionEmotion.sad;
      case DinoNeed.hygiene || null:
        break;
    }
    if (xp > 0) return CompanionEmotion.excited;
    return state.happiness >= 70
        ? CompanionEmotion.happy
        : CompanionEmotion.content;
  }

  CompanionAnimation _animation(DinoAnimation? brain, DinoCare? care, int xp) {
    if (care != null) {
      return switch (care) {
        DinoCare.feed => CompanionAnimation.eating,
        DinoCare.water => CompanionAnimation.drinking,
        DinoCare.play => CompanionAnimation.playing,
        DinoCare.sleep => CompanionAnimation.sleeping,
      };
    }
    if (state.isSleeping) return CompanionAnimation.sleeping;
    if (xp > 0) return CompanionAnimation.celebrating;
    return switch (brain) {
      DinoAnimation.eat => CompanionAnimation.eating,
      DinoAnimation.drink => CompanionAnimation.drinking,
      DinoAnimation.sleep => CompanionAnimation.sleeping,
      DinoAnimation.jump ||
      DinoAnimation.dance ||
      DinoAnimation.run => CompanionAnimation.playing,
      DinoAnimation.happy || DinoAnimation.wave => CompanionAnimation.happy,
      DinoAnimation.sad => CompanionAnimation.sad,
      _ => CompanionAnimation.talking,
    };
  }

  CompanionLine _line(DinoLine line) =>
      CompanionLine(line.text, line.translation);

  T _pick<T>(List<T> options) => options[_random.nextInt(options.length)];

  VocabularyEntry? _careWord(DinoCare care) {
    final pool = switch (care) {
      DinoCare.feed => const [..._foods, 'eat', 'food'],
      // Playing ball teaches ball / play / run.
      DinoCare.play => const ['ball', 'play', 'run'],
      DinoCare.water => const ['water', 'drink', 'thirsty'],
      DinoCare.sleep => const ['sleep', 'bed', 'tired', 'good night'],
    };
    final words = [for (final f in pool) ?_vocabulary.byEnglish(f)];
    if (words.isEmpty) return _vocabulary.byEnglish('food');
    // Prefer a word the child hasn't repeated yet this session.
    final fresh = words
        .where((e) => !_brain.context.repeatedWordIds.contains(e.id))
        .toList();
    return _pick(fresh.isNotEmpty ? fresh : words);
  }

  List<CompanionLine> _careLines(DinoCare care, CareOutcome outcome, int xp) {
    final xpText = xp > 0 ? ' +$xp XP!' : '';
    final lines = <CompanionLine>[];
    switch (outcome.result) {
      case CareResult.asleep:
        return [_line(_say.sleepingNow())];
      case CareResult.tooTired:
        return [_line(_say.tooTiredToPlay())];
      case CareResult.notNeeded:
        return [
          switch (care) {
            DinoCare.feed => const CompanionLine(
              "I'm full! Thank you!",
              'Estou cheio! Obrigado!',
            ),
            DinoCare.water => const CompanionLine(
              "I'm not thirsty now. Thank you!",
              'Não estou com sede agora. Obrigado!',
            ),
            DinoCare.play || DinoCare.sleep => _line(_say.sleepingNow()),
          },
        ];
      case CareResult.applied:
        lines.add(switch (care) {
          DinoCare.feed => _pick(const [
            CompanionLine('Yummy! Thank you!', 'Que delícia! Obrigado!'),
            CompanionLine('Yum yum!', 'Nham nham!'),
          ]),
          DinoCare.water => _pick(const [
            CompanionLine('Gulp gulp! Thank you!', 'Glub glub! Obrigado!'),
            CompanionLine('Ahh! Fresh water!', 'Ahh! Água fresquinha!'),
          ]),
          DinoCare.play => _pick(const [
            CompanionLine("Let's play! Wheee!", 'Vamos brincar! Uhuuu!'),
            CompanionLine('Catch the ball!', 'Pega a bola!'),
          ]),
          DinoCare.sleep => const CompanionLine(
            'Good night! Z z z...',
            'Boa noite! Zzz...',
          ),
        });
        if (xpText.isNotEmpty) lines.add(CompanionLine(xpText.trim()));
    }
    final need = switch (care) {
      DinoCare.feed => DinoNeed.hunger,
      DinoCare.water => DinoNeed.thirst,
      DinoCare.play => DinoNeed.happiness,
      DinoCare.sleep => DinoNeed.energy,
    };
    if (care != DinoCare.sleep && outcome.wasUrgent && !state.isUrgent(need)) {
      lines.add(const CompanionLine("I'm happy now!", 'Agora estou feliz!'));
    }
    return lines;
  }
}
