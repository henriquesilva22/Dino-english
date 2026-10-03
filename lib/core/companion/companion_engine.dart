import 'dart:math';

import '../brain/context/conversation_context.dart';
import '../brain/dialogue/dialogue_action.dart';
import '../brain/dialogue/response_generator.dart';
import '../brain/dino_brain.dart';
import '../brain/memory/dino_memory.dart';
import '../brain/model/dino_enums.dart';
import '../brain/vocabulary/official_vocabulary.dart';
import 'companion_needs_service.dart';
import 'companion_response.dart';
import 'companion_state.dart';
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

/// The virtual companion, offline and deterministic:
///
/// `text -> DinoBrain (normalize -> intent -> entities -> context ->
///  dialogue) -> actions -> needs/XP/persistence -> CompanionResponse`
///
/// plus care buttons (feed, water, play, sleep) that go through the same
/// needs rules. Pure Dart: the UI only calls [process]/[care] and renders
/// the [CompanionResponse]; voice, 2D or 3D plug in on top of it.
class CompanionEngine {
  CompanionEngine({
    required this._vocabulary,
    required DinoMemoryBank memory,
    required this._store,
    required this._rewards,
    this._totalXp = 0,
    this._level = 1,
    this._needs = const CompanionNeedsService(),
    Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? Random(),
       _clock = clock ?? DateTime.now {
    _brain = DinoBrain(
      vocabulary: _vocabulary,
      memory: memory,
      random: _random,
      clock: _clock,
    );
    _say = ResponseGenerator(random: _random);
  }

  final OfficialVocabulary _vocabulary;
  final CompanionStateStore _store;
  final CompanionRewards _rewards;
  final CompanionNeedsService _needs;
  final Random _random;
  final DateTime Function() _clock;
  late final DinoBrain _brain;
  late final ResponseGenerator _say;

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
    return _fromReply(await _brain.start());
  }

  /// One message from the child (typed now; later from speech).
  Future<CompanionResponse> process(String input) async {
    await _ensureLoaded();
    _refresh();
    final topicBefore = _brain.context.topicWord;
    final reply = await _brain.respond(input);
    return _fromReply(reply, topicBefore: topicBefore);
  }

  /// A care button. Feeding/water/play also teach a word ("Apple! Say:
  /// apple!") the child can repeat for XP.
  Future<CompanionResponse> care(DinoCare care) async {
    await _ensureLoaded();
    _refresh();
    _say.tier = EnglishTier.forLevel(_level);
    final outcome = _needs.applyCare(state, care, _clock());
    _state = outcome.state;
    final xp = await _grant(
      outcome.xp,
      reason: 'companion_${care.name}',
      countsAsExercise: false,
    );

    final lines = _careLines(care, outcome, xp);
    final context = _brain.context;
    context.clearPending();
    var suggestions = const <String>[];
    VocabularyEntry? word;
    if (outcome.applied) {
      word = _careWord(care);
      if (word != null) {
        context.topicWord = word;
        lines.insert(0, _line(_say.learnWord(word)));
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

  /// Push-to-talk caught nothing usable.
  CompanionResponse didNotHear() => _voiceHint(
    _pick(const [
      CompanionLine(
        "Hmm? I didn't hear you! Hold the button and talk.",
        'Hum? Não ouvi! Segure o botão e fale.',
      ),
      CompanionLine(
        'Can you say it again? A little louder!',
        'Pode falar de novo? Um pouco mais alto!',
      ),
    ]),
  );

  /// The microphone can't be used (permission denied...).
  CompanionResponse micUnavailable() => _voiceHint(
    const CompanionLine(
      "I can't hear you... Can you type it for me?",
      'Não consigo te ouvir... Você pode escrever para mim?',
    ),
  );

  CompanionResponse _voiceHint(CompanionLine line) => CompanionResponse(
    lines: [line],
    emotion: _emotion(0),
    animation: CompanionAnimation.talking,
    state: state,
    suggestions: switch (_brain.context.pending) {
      RepeatWordQuestion(:final word) => [word.english],
      _ => const [],
    },
    isWaitingForAnswer: _brain.context.pending != null,
  );

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
      intent: reply.intent.intent,
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
    if (care != DinoCare.feed) {
      return _vocabulary.byEnglish(switch (care) {
        DinoCare.water => 'water',
        DinoCare.play => 'play',
        DinoCare.sleep => 'sleep',
        DinoCare.feed => 'food',
      });
    }
    final foods = [for (final f in _foods) ?_vocabulary.byEnglish(f)];
    if (foods.isEmpty) return _vocabulary.byEnglish('food');
    // Prefer a food the child hasn't repeated yet this session.
    final fresh = foods
        .where((e) => !_brain.context.repeatedWordIds.contains(e.id))
        .toList();
    return _pick(fresh.isNotEmpty ? fresh : foods);
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
