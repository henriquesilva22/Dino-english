import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/brain/context/conversation_context.dart';
import '../core/brain/memory/dino_memory.dart';
import '../core/brain/model/dino_enums.dart';
import '../core/brain/vocabulary/official_vocabulary.dart';
import '../core/companion/companion_engine.dart';
import '../core/companion/companion_response.dart';
import '../core/companion/companion_state.dart';
import '../core/companion/food/food_item.dart';
import '../core/companion/model/companion_model.dart';
import '../core/companion/pet_scene.dart';
import '../core/companion/learning/learning_word.dart';
import '../core/companion/learning/learning_word_bank.dart';
import '../core/companion/voice/speech_recognition_service.dart';
import '../core/economy/coin_repository.dart';
import '../core/models/session_kind.dart';
import '../core/repositories/companion_history_repository.dart';
import '../core/repositories/companion_state_repository.dart';
import '../core/repositories/dino_memory_repository.dart';
import 'database_providers.dart';
import 'food_providers.dart';
import 'home_providers.dart';
import 'repository_providers.dart';
import 'speech_providers.dart';

class DinoChatMessage {
  const DinoChatMessage({
    required this.speaker,
    required this.text,
    this.translation,
    this.viaVoice = false,
    this.english = const [],
  });

  final Speaker speaker;
  final String text;

  /// Portuguese subtitle for Dino lines.
  final String? translation;

  /// English words inside a Portuguese line ("Eu vou WALK amanhã.").
  final List<String> english;

  /// The child said it out loud (shows what the Dino heard).
  final bool viaVoice;
}

class DinoChatState {
  const DinoChatState({
    this.messages = const [],
    this.suggestions = const [],
    this.isReady = false,
    this.isThinking = false,
    this.animation = CompanionAnimation.idle,
    this.companion,
    this.lastResponse,
    this.pendingActivity,
    this.xpEarned = 0,
    this.voiceState = VoiceState.idle,
    this.heardText,
    this.voiceMessage,
    this.micBlocked = false,
    this.dinoSpeaking = false,
    this.lookToken = 0,
    this.offered,
    this.chewToken = 0,
    this.offeredFood,
    this.heartsToken = 0,
    this.foodHint = false,
    this.ballGame = false,
    this.bedroom = false,
    this.walkingToBed = false,
    this.xpBurst = 0,
    this.scene = PetScene.home,
    this.quietPlay = false,
    this.wakingUp = false,
  });

  /// The whole conversation (shown in the history sheet).
  final List<DinoChatMessage> messages;

  /// Quick-reply chips from the Dino's last question.
  final List<String> suggestions;
  final bool isReady;
  final bool isThinking;

  /// What the pet is doing now: the latest reaction for a moment, then
  /// back to the idle pose for its needs.
  final CompanionAnimation animation;

  /// Needs bars. Null until the engine has loaded.
  final CompanionState? companion;

  /// The Dino's latest reply (the speech bubble).
  final CompanionResponse? lastResponse;

  /// One-shot navigation event; the screen consumes it with
  /// [DinoChatController.consumeActivity].
  final DinoActivity? pendingActivity;

  /// XP earned in this visit.
  final int xpEarned;

  /// Hands-free voice input status (🎙️ Ouvindo... / 🧠 Processando...).
  final VoiceState voiceState;

  /// The last sentence the Dino heard, until the child talks again.
  final String? heardText;

  /// Friendly explanation for [VoiceState.error]/[VoiceState.disabled]
  /// (or "Preparando..." while the models load).
  final String? voiceMessage;

  /// The microphone permission was denied for good: the mic button opens
  /// the system settings instead of asking again.
  final bool micBlocked;

  /// The Dino is talking (English + Portuguese): the microphone is closed.
  final bool dinoSpeaking;

  /// Changes whenever the Dino should turn to face the child.
  final int lookToken;

  /// Food or water on screen, waiting to be dragged to the Dino.
  final DinoCare? offered;

  /// Changes each time the Dino chews/gulps.
  final int chewToken;

  /// The food picked in the panel (with [offered] = feed), waiting to be
  /// dragged to the Dino's mouth.
  final FoodItem? offeredFood;

  /// Changes each time the Dino loved a meal (❤️ float up).
  final int heartsToken;

  /// Show "Arraste até a boca! 👆" (until the child has done it once).
  final bool foodHint;

  /// The ball game ("Brincar") is on.
  final bool ballGame;

  /// "Dormir": the bedroom is shown, waiting for the child to tap the bed.
  final bool bedroom;

  /// The Dino is walking to its bed.
  final bool walkingToBed;

  /// Changes each time XP is earned (the "+XP" burst animation).
  final int xpBurst;

  /// Where the Dino is and what it does (one activity at a time).
  final PetScene scene;

  /// 🔇 in the ball game: play with no voice at all.
  final bool quietPlay;

  /// Getting up from the bed (the wake-up clip plays once).
  final bool wakingUp;

  DinoChatState copyWith({
    List<DinoChatMessage>? messages,
    List<String>? suggestions,
    bool? isReady,
    bool? isThinking,
    CompanionAnimation? animation,
    CompanionState? companion,
    CompanionResponse? lastResponse,
    DinoActivity? pendingActivity,
    bool clearPendingActivity = false,
    int? xpEarned,
    VoiceState? voiceState,
    String? heardText,
    bool clearHeardText = false,
    String? voiceMessage,
    bool clearVoiceMessage = false,
    bool? micBlocked,
    bool? dinoSpeaking,
    int? lookToken,
    DinoCare? offered,
    bool clearOffered = false,
    int? chewToken,
    FoodItem? offeredFood,
    int? heartsToken,
    bool? foodHint,
    bool? ballGame,
    bool? bedroom,
    bool? walkingToBed,
    int? xpBurst,
    PetScene? scene,
    bool? quietPlay,
    bool? wakingUp,
  }) {
    return DinoChatState(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      isReady: isReady ?? this.isReady,
      isThinking: isThinking ?? this.isThinking,
      animation: animation ?? this.animation,
      companion: companion ?? this.companion,
      lastResponse: lastResponse ?? this.lastResponse,
      pendingActivity: clearPendingActivity
          ? null
          : pendingActivity ?? this.pendingActivity,
      xpEarned: xpEarned ?? this.xpEarned,
      voiceState: voiceState ?? this.voiceState,
      heardText: clearHeardText ? null : heardText ?? this.heardText,
      voiceMessage: clearVoiceMessage
          ? null
          : voiceMessage ?? this.voiceMessage,
      micBlocked: micBlocked ?? this.micBlocked,
      dinoSpeaking: dinoSpeaking ?? this.dinoSpeaking,
      lookToken: lookToken ?? this.lookToken,
      offered: clearOffered ? null : offered ?? this.offered,
      chewToken: chewToken ?? this.chewToken,
      offeredFood: clearOffered ? null : offeredFood ?? this.offeredFood,
      heartsToken: heartsToken ?? this.heartsToken,
      foodHint: foodHint ?? this.foodHint,
      ballGame: ballGame ?? this.ballGame,
      bedroom: bedroom ?? this.bedroom,
      walkingToBed: walkingToBed ?? this.walkingToBed,
      xpBurst: xpBurst ?? this.xpBurst,
      scene: scene ?? this.scene,
      quietPlay: quietPlay ?? this.quietPlay,
      wakingUp: wakingUp ?? this.wakingUp,
    );
  }
}

/// [CompanionRewards] over the app's single XP pipeline
/// ([ProgressRepository.recordAnswer]).
class _ProgressCompanionRewards implements CompanionRewards {
  _ProgressCompanionRewards(this._ref, this._sessionId);

  final Ref _ref;
  final String _sessionId;

  @override
  Future<CompanionRewardResult> grant({
    required int xp,
    String? wordId,
    required String reason,
    bool countsAsExercise = true,
  }) async {
    final result = await _ref
        .read(progressRepositoryProvider)
        .recordAnswer(
          wordId: wordId,
          wasCorrect: true,
          exerciseType: reason,
          sessionKind: reason == 'conversation_quiz'
              ? SessionKind.conversation
              : SessionKind.companion,
          sessionId: _sessionId,
          xpOverride: xp,
          countsAsExercise: countsAsExercise,
        );
    if (_ref.mounted) {
      _ref.invalidate(masteryStatsProvider);
      _ref.invalidate(eggProgressProvider);
    }
    return CompanionRewardResult(
      xpAwarded: result.xpAwarded,
      level: result.newLevel,
    );
  }
}

/// Runs the offline [CompanionEngine] for the companion screen ("Brincar
/// com o Dino"): hands-free voice and typed messages, care buttons, needs
/// that decay while the screen is open, the Dino's voice and XP.
///
/// Voice: the microphone permission is asked when the screen opens; once
/// granted the Dino listens by itself while the screen is visible
/// ([setForeground]) and goes deaf while it talks or thinks, so it never
/// hears itself.
class DinoChatController extends Notifier<DinoChatState> {
  final String _sessionId = const Uuid().v4();
  CompanionEngine? _engine;
  late SpeechRecognitionService _recognizer;
  Timer? _tick;
  Timer? _settle;
  Timer? _wake;

  /// Bumped whenever the Dino changes activity: an answer, a chew or a
  /// walk started before that belongs to the old activity and is
  /// dropped when it finishes ([_isStale]).
  int _epoch = 0;

  bool _isStale(int epoch) => !ref.mounted || epoch != _epoch;

  StreamSubscription<SpeechEvent>? _speechEvents;
  ValueListenable<Object?>? _speaking;
  Timer? _resume;

  /// The first start loads the models (shows "Preparando...").
  bool _warmedUp = false;

  /// Models bundled and permission granted.
  bool _voiceReady = false;

  /// App in the foreground and this screen on top.
  bool _foreground = true;

  /// The child tapped the mic to stop listening.
  bool _userPaused = false;

  /// How often the needs bars are refreshed while the screen is open.
  static const Duration tickInterval = Duration(minutes: 1);

  /// How long a reaction (eating, celebrating...) shows before the pet
  /// returns to its idle pose.
  static const Duration reactionDuration = Duration(seconds: 3);

  /// Quiet time after the Dino stops talking before the microphone opens
  /// again (the speaker's echo dies out).
  static const Duration resumeDelay = Duration(milliseconds: 400);

  static const String _msgPreparing = 'Preparando a voz do Dino...';
  static const String _msgNoModel =
      'A conversa por voz não está disponível neste aparelho. '
      'Você pode escrever para o Dino.';
  static const String _msgDenied =
      'O Dino precisa do microfone para conversar por voz. '
      'Toque no 🎤 para permitir. Enquanto isso, você pode escrever.';
  static const String _msgBlocked =
      'O microfone está bloqueado. Toque no 🎤 para abrir as '
      'configurações e permitir. Você pode escrever enquanto isso.';
  static const String _msgMicFailed =
      'Não consegui abrir o microfone. Toque no 🎤 para tentar de novo.';

  @override
  DinoChatState build() {
    // Watched (not read) so the auto-disposed recognizer -- the open
    // microphone and the models in memory -- live exactly as long as this
    // screen.
    _recognizer = ref.watch(speechRecognitionServiceProvider);
    ref.onDispose(() {
      _tick?.cancel();
      _settle?.cancel();
      _wake?.cancel();
      _resume?.cancel();
      unawaited(_speechEvents?.cancel());
      _speaking?.removeListener(_onSpeaking);
    });
    _init();
    return const DinoChatState();
  }

  Future<void> _init() async {
    final words = await ref.read(wordRepositoryProvider).fetchActiveWords();
    final profile = await ref
        .read(progressRepositoryProvider)
        .fetchUserProfile();
    final database = ref.read(databaseProvider);
    final memory = DinoMemoryBank(DriftDinoMemoryStore(database));
    await memory.load();
    if (!ref.mounted) return;

    LearningWordBank? learning;
    try {
      learning = await LearningWordBank.load(rootBundle);
    } catch (_) {
      // Without the bank the Dino still talks, just without word lessons.
    }
    if (!ref.mounted) return;

    final engine = CompanionEngine(
      vocabulary: OfficialVocabulary.fromWords(words),
      memory: memory,
      store: DriftCompanionStateStore(database),
      rewards: _ProgressCompanionRewards(ref, _sessionId),
      totalXp: profile.totalXp,
      level: profile.currentLevel,
      learningWords: learning,
    );
    await engine.load();
    if (!ref.mounted) return;
    _engine = engine;
    state = state.copyWith(
      isReady: true,
      companion: engine.state,
      // A Dino left sleeping is still in its bed.
      scene: engine.state.isSleeping ? PetScene.sleep : PetScene.home,
      bedroom: engine.state.isSleeping,
    );
    _lastUrgent = engine.state.mostUrgentNeed;
    _tick = Timer.periodic(tickInterval, (_) => _onTick());
    await _restoreHistory();
    await _apply(await engine.start());
    if (!ref.mounted) return;
    await _initVoice();
  }

  // ---- voice ------------------------------------------------------------------

  Future<void> _initVoice() async {
    if (!await _recognizer.isAvailable()) {
      if (!ref.mounted) return;
      state = state.copyWith(
        voiceState: VoiceState.disabled,
        voiceMessage: _msgNoModel,
      );
      return;
    }
    if (!ref.mounted) return;
    _speechEvents = _recognizer.events.listen(_onSpeechEvent);
    _speaking = ref.read(companionVoiceServiceProvider).speaking
      ..addListener(_onSpeaking);
    await requestMicrophone();
  }

  /// Asks for the microphone (the system dialog appears only if Android
  /// still allows asking) and starts listening when granted.
  Future<void> requestMicrophone() async {
    var permission = await _recognizer.checkPermission();
    if (permission == MicPermission.denied) {
      permission = await _recognizer.requestPermission();
    }
    if (!ref.mounted) return;
    await _onPermission(permission);
  }

  Future<void> _onPermission(MicPermission permission) async {
    if (permission != MicPermission.granted) {
      _voiceReady = false;
      final blocked = permission == MicPermission.permanentlyDenied;
      state = state.copyWith(
        voiceState: VoiceState.disabled,
        voiceMessage: blocked ? _msgBlocked : _msgDenied,
        micBlocked: blocked,
      );
      return;
    }
    _voiceReady = true;
    state = state.copyWith(micBlocked: false, clearVoiceMessage: true);
    await _syncListening();
  }

  /// The screen is visible and the app in the foreground (or not): the
  /// microphone is only ever open while both are true.
  Future<void> setForeground(bool foreground) async {
    if (_foreground == foreground) return;
    _foreground = foreground;
    // Minimized or covered by another screen: the Dino stops talking.
    if (!foreground) {
      unawaited(ref.read(companionVoiceServiceProvider).stop());
    }
    // Back from the system settings: maybe the mic is allowed now.
    if (foreground && !_voiceReady && state.voiceState == VoiceState.disabled) {
      if (!await _recognizer.isAvailable()) return;
      final permission = await _recognizer.checkPermission();
      if (!ref.mounted) return;
      if (permission == MicPermission.granted) {
        await _onPermission(permission);
        return;
      }
    }
    await _syncListening();
  }

  /// The 🎤 button: pause/resume listening, or ask for the permission.
  Future<void> toggleMicrophone() async {
    switch (state.voiceState) {
      case VoiceState.disabled:
        if (state.micBlocked) {
          await _recognizer.openSettings();
        } else if (await _recognizer.isAvailable()) {
          await requestMicrophone();
        }
      case VoiceState.listening || VoiceState.processing:
        _userPaused = true;
        await _syncListening();
      case VoiceState.idle || VoiceState.error:
        _userPaused = false;
        await _syncListening();
    }
  }

  /// Thinking or talking: the microphone must be closed (half-duplex).
  bool get _busy => state.isThinking || _chewing || _speaking?.value != null;

  /// Eating/drinking: the mouth is busy (and the mic closed) meanwhile.
  bool _chewing = false;

  /// The child's sentence waiting for its answer, to save them together.
  (String, bool)? _childSaid;

  CompanionHistoryRepository get _history =>
      CompanionHistoryRepository(ref.read(databaseProvider));

  /// Last urgent need announced, so "I'm hungry!" is said once.
  DinoNeed? _lastUrgent;

  static const Duration chewDuration = Duration(milliseconds: 1400);

  bool get _shouldListen =>
      _voiceReady && _foreground && !_userPaused && !_busy;

  Future<void> _syncListening() async {
    if (!ref.mounted) return;
    if (!_shouldListen) {
      await _recognizer.stop();
      if (ref.mounted && _voiceReady) {
        state = state.copyWith(
          voiceState: VoiceState.idle,
          clearVoiceMessage: true,
        );
      }
      return;
    }
    if (_recognizer.isRunning) return;
    // The first start copies and loads the models (a few seconds).
    if (!_warmedUp) {
      state = state.copyWith(
        voiceState: VoiceState.processing,
        voiceMessage: _msgPreparing,
      );
    }
    final started = await _recognizer.start();
    if (!ref.mounted) return;
    if (!_shouldListen) {
      // Left the screen while it was starting.
      await _recognizer.stop();
      if (ref.mounted) state = state.copyWith(voiceState: VoiceState.idle);
      return;
    }
    if (started) _warmedUp = true;
    state = started
        ? state.copyWith(
            voiceState: VoiceState.listening,
            clearVoiceMessage: true,
            // Listening again: the Dino looks at the child.
            lookToken: state.lookToken + 1,
          )
        : state.copyWith(
            voiceState: VoiceState.error,
            voiceMessage: _msgMicFailed,
          );
  }

  void _onSpeechEvent(SpeechEvent event) {
    if (!ref.mounted || !_recognizer.isRunning) return;
    switch (event) {
      case SpeechStarted():
        // The child talks: the Dino turns to them, all ears.
        _settle?.cancel();
        state = state.copyWith(
          voiceState: VoiceState.listening,
          clearHeardText: true,
          clearVoiceMessage: true,
          animation: CompanionAnimation.listening,
          lookToken: state.lookToken + 1,
        );
      case SpeechProcessing():
        _settle?.cancel();
        state = state.copyWith(
          voiceState: VoiceState.processing,
          animation: CompanionAnimation.thinking,
        );
      case SpeechRecognized(:final text):
        state = state.copyWith(
          voiceState: VoiceState.listening,
          heardText: text,
        );
        unawaited(send(text, viaVoice: true));
      case SpeechNothingHeard():
        state = state.copyWith(voiceState: VoiceState.listening);
      case SpeechFailed():
        state = state.copyWith(
          voiceState: VoiceState.error,
          voiceMessage: _msgMicFailed,
        );
        unawaited(_recognizer.stop());
    }
  }

  void _onSpeaking() {
    if (!ref.mounted) return;
    final speaking = _speaking?.value != null;
    if (state.dinoSpeaking != speaking) {
      state = state.copyWith(dinoSpeaking: speaking);
    }
    _updateHalfDuplex();
  }

  /// Half-duplex: while the Dino thinks or talks the microphone is
  /// *closed* (and muted at once, before it really closes), so it never
  /// hears itself; it opens again shortly after the voice ends.
  void _updateHalfDuplex() {
    _resume?.cancel();
    if (_busy) {
      _recognizer.setMuted(true);
      unawaited(_syncListening());
    } else {
      _resume = Timer(resumeDelay, () {
        if (!ref.mounted) return;
        _recognizer.setMuted(false);
        unawaited(_syncListening());
      });
    }
  }

  // ---- conversation & care ------------------------------------------------------

  Future<void> send(String text, {bool viaVoice = false}) async {
    final engine = _engine;
    final trimmed = text.trim();
    if (engine == null || trimmed.isEmpty || state.isThinking) return;

    state = state.copyWith(
      messages: [
        ...state.messages,
        DinoChatMessage(
          speaker: Speaker.child,
          text: trimmed,
          viaVoice: viaVoice,
        ),
      ],
      suggestions: const [],
      isThinking: true,
    );
    _updateHalfDuplex();
    _childSaid = (trimmed, viaVoice);
    final epoch = _epoch;
    final response = await engine.process(trimmed);
    if (!ref.mounted) return;
    // Another activity started meanwhile: the answer still belongs to the
    // conversation, but it must not drive the new activity's pose.
    await _apply(response, keepAnimation: epoch != _epoch);
  }

  // ---- English words in the Dino's sentences ---------------------------------

  /// What a word the child tapped means (null if the Dino doesn't know).
  LearningWord? wordInfo(String english) => _engine?.wordInfo(english);

  /// 🔊 on a tapped word: just the word, in the English voice.
  Future<void> hearWord(String english) async {
    final engine = _engine;
    if (engine == null) return;
    final display = english.toUpperCase();
    await ref
        .read(companionVoiceServiceProvider)
        .say(
          CompanionResponse(
            lines: [
              CompanionLine.mixed(display, english: [display]),
            ],
            emotion: CompanionEmotion.happy,
            animation: CompanionAnimation.talking,
            state: engine.state,
          ),
        );
  }

  /// "O que é WALK?" by tapping the word.
  Future<void> explainWord(String english) =>
      _lesson((engine) => engine.explainWord(english));

  /// ⭐ Praticar: "Fala comigo: WALK."
  Future<void> practiceWord(String english) =>
      _lesson((engine) => engine.practiceWord(english));

  Future<void> _lesson(
    Future<CompanionResponse?> Function(CompanionEngine engine) step,
  ) async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    final epoch = _epoch;
    state = state.copyWith(isThinking: true);
    _updateHalfDuplex();
    final response = await step(engine);
    if (_isStale(epoch)) return;
    if (response == null) {
      state = state.copyWith(isThinking: false);
      _updateHalfDuplex();
      return;
    }
    await _apply(response);
  }

  Future<void> care(DinoCare care) async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    final epoch = _epoch;
    state = state.copyWith(isThinking: true);
    _updateHalfDuplex();
    final response = await engine.care(care);
    if (_isStale(epoch)) return;
    await _apply(response);
  }

  /// How long the Dino takes to get out of bed (its wake-up clip).
  static final Duration wakeUpDuration = Duration(
    milliseconds:
        ((CompanionModel.dino.clip(CompanionAnim.wakeUp)?.seconds ?? 1.5) *
                1000)
            .round(),
  );

  /// "Acordar": the Dino gets up from the bed once (wake-up clip), then
  /// leaves the bedroom.
  Future<void> wakeUp() async {
    final engine = _engine;
    if (engine == null || state.isThinking || state.wakingUp) return;
    final epoch = _epoch;
    state = state.copyWith(isThinking: true);
    _updateHalfDuplex();
    final response = await engine.wakeUp();
    if (_isStale(epoch)) return;
    _settle?.cancel();
    state = state.copyWith(
      wakingUp: true,
      animation: CompanionAnimation.wakingUp,
    );
    await _apply(response, keepAnimation: true);
    _wake?.cancel();
    _wake = Timer(wakeUpDuration, () {
      if (_isStale(epoch)) return;
      state = state.copyWith(wakingUp: false);
      _enterScene(PetScene.home, stopVoice: false);
    });
  }

  // ---- one activity at a time ----------------------------------------------------

  /// Leaves what the Dino was doing and enters [next]: the ball stops
  /// and goes away, food on screen is put back, the bedroom closes,
  /// pending answers/chews/walks of the old activity are dropped and
  /// (unless [stopVoice] is false) the Dino stops talking. The pose goes
  /// back to rest, so nothing of the old activity keeps playing.
  void _enterScene(PetScene next, {bool stopVoice = true}) {
    final leaving = state.scene;
    _epoch++;
    _settle?.cancel();
    _wake?.cancel();
    _chewing = false;
    if (leaving == PetScene.play && next != PetScene.play) _endBallQuietly();
    if (stopVoice && leaving != next) {
      unawaited(ref.read(companionVoiceServiceProvider).stop());
    }
    final companion = state.companion;
    state = state.copyWith(
      scene: next,
      ballGame: next == PetScene.play,
      bedroom: next == PetScene.sleep && state.bedroom,
      clearOffered: next != PetScene.food,
      walkingToBed: false,
      wakingUp: false,
      isThinking: false,
      suggestions: leaving == next ? null : const [],
      animation: companion == null
          ? CompanionAnimation.idle
          : CompanionEngine.idleAnimationFor(companion),
    );
    _updateHalfDuplex();
  }

  /// Left the ball game for another activity: the time played still
  /// counts (XP), but no "Good game!" speech over the new activity.
  void _endBallQuietly() {
    final engine = _engine;
    final played = _ballPlayed;
    if (engine == null || played == null) return;
    _ballPlayed = null;
    final hits = _ballHits;
    final best = _ballBest;
    unawaited(() async {
      final over = await engine.ballGameOver(
        hits: hits,
        bestCombo: best,
        played: played.elapsed,
      );
      if (!ref.mounted || over.xpReward <= 0) return;
      state = state.copyWith(
        xpEarned: state.xpEarned + over.xpReward,
        xpBurst: state.xpBurst + 1,
      );
    }());
  }

  /// 🔇 / 🔊 in the ball game.
  void toggleQuietPlay() {
    final quiet = !state.quietPlay;
    state = state.copyWith(quietPlay: quiet);
    if (quiet && state.scene == PetScene.play) {
      unawaited(ref.read(companionVoiceServiceProvider).stop());
    }
  }

  void consumeActivity() => state = state.copyWith(clearPendingActivity: true);

  // ---- back -------------------------------------------------------------------------

  /// The system back / ✕ inside the companion screen: closes what is open
  /// on it first (the ball game, the bedroom, the food room), one step at
  /// a time. Returns false when nothing was open -- then the screen
  /// itself may close.
  bool back() {
    if (!hasOpenActivity) return false;
    if (state.ballGame) {
      unawaited(
        stopBallGame(
          hits: _ballHits,
          bestCombo: _ballBest,
          played: _ballPlayed?.elapsed ?? Duration.zero,
        ),
      );
      return true;
    }
    _enterScene(PetScene.home);
    return true;
  }

  /// Whether [back] would close something on the screen (a sleeping Dino
  /// stays in its bed; walking to it can't be undone).
  bool get hasOpenActivity {
    final asleep = state.companion?.isSleeping ?? false;
    return switch (state.scene) {
      PetScene.home => false,
      PetScene.play || PetScene.food => true,
      PetScene.sleep => !asleep && !state.walkingToBed && !state.wakingUp,
    };
  }

  // Ball game tallies (for leaving it with the back button).
  int _ballHits = 0;
  int _ballBest = 0;
  Stopwatch? _ballPlayed;

  /// "Bola parada" is said at most once per game.
  bool _ballStopSaid = false;

  // ---- pet activities -------------------------------------------------------------

  /// A care button. Food and water first appear on screen (the child
  /// drags them to the Dino); "Brincar" opens the ball game; "Dormir"
  /// opens the bedroom. Each one closes the previous activity first.
  Future<void> startActivity(DinoCare care) async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    final asleep = state.companion?.isSleeping ?? false;
    if (asleep) {
      state = state.copyWith(clearOffered: true);
      return this.care(care);
    }
    switch (care) {
      case DinoCare.sleep:
        // "Dormir": the bedroom appears; the child taps the bed (goToBed).
        _enterScene(PetScene.sleep);
        state = state.copyWith(bedroom: true, lookToken: state.lookToken + 1);
        final epoch = _epoch;
        final invite = await engine.bedtimeInvite();
        if (_isStale(epoch)) return;
        return _apply(invite);
      case DinoCare.play:
        if (state.scene == PetScene.play) return;
        _enterScene(PetScene.play);
        engine.startBallGame();
        _ballHits = 0;
        _ballBest = 0;
        _ballStopSaid = false;
        _ballPlayed = Stopwatch()..start();
        state = state.copyWith(lookToken: state.lookToken + 1);
        final epoch = _epoch;
        final invite = await engine.playInvite();
        if (_isStale(epoch)) return;
        return _apply(invite);
      case DinoCare.feed || DinoCare.water:
        _enterScene(PetScene.food);
        state = state.copyWith(offered: care, lookToken: state.lookToken + 1);
        final epoch = _epoch;
        final offer = await engine.offer(care);
        if (_isStale(epoch)) return;
        return _apply(offer);
    }
  }

  /// How long the Dino walks to its bed before lying down.
  static const Duration walkToBedDuration = Duration(milliseconds: 1600);

  /// The bed was tapped (or "Dormir" again): the Dino walks over, lies
  /// down and sleeps (energy recovers, the room gets dark).
  Future<void> goToBed() async {
    final engine = _engine;
    if (engine == null || !state.bedroom || state.walkingToBed) return;
    if (state.companion?.isSleeping ?? false) return;
    _settle?.cancel();
    final epoch = _epoch;
    state = state.copyWith(
      walkingToBed: true,
      animation: CompanionAnimation.walking,
    );
    await Future<void>.delayed(walkToBedDuration);
    if (_isStale(epoch)) return;
    state = state.copyWith(walkingToBed: false);
    await care(DinoCare.sleep);
  }

  // ---- ball game ------------------------------------------------------------------

  /// A hit in the ball game: the game is about moving, not talking --
  /// most hits are silent (XP only); only big combos cheer.
  Future<void> ballHit(int combo) async {
    final engine = _engine;
    if (engine == null || !state.ballGame) return;
    final epoch = _epoch;
    _ballHits++;
    if (combo > _ballBest) _ballBest = combo;
    final response = await engine.ballHit(combo);
    if (_isStale(epoch) || !state.ballGame) return;
    if (response.shouldSpeak || response.xpReward > 0) {
      await _apply(response, speak: !state.dinoSpeaking);
    }
  }

  /// The ball stopped rolling: one nudge per game at most.
  Future<void> ballStopped(int lostCombo) async {
    final engine = _engine;
    if (engine == null || !state.ballGame || state.dinoSpeaking) return;
    if (_ballStopSaid) return;
    _ballStopSaid = true;
    final epoch = _epoch;
    final response = await engine.ballStopped(lostCombo);
    if (_isStale(epoch) || !state.ballGame) return;
    await _apply(response);
  }

  /// "Parar": the game ends with a short summary (+ time bonus).
  Future<void> stopBallGame({
    required int hits,
    required int bestCombo,
    required Duration played,
  }) async {
    final engine = _engine;
    if (engine == null || !state.ballGame) return;
    // The summary below replaces the quiet ending.
    _ballPlayed = null;
    _enterScene(PetScene.home);
    final epoch = _epoch;
    final response = await engine.ballGameOver(
      hits: hits,
      bestCombo: bestCombo,
      played: played,
    );
    if (_isStale(epoch)) return;
    await _apply(response);
  }

  /// The food/drink reached the Dino: it chews (or gulps), then the state
  /// and XP update and it says thank you.
  Future<void> deliverOffered() async {
    final care = state.offered;
    if (_engine == null || care == null || _chewing) return;
    final food = care == DinoCare.feed ? state.offeredFood : null;
    final hinted = state.foodHint;
    final epoch = _epoch;
    state = state.copyWith(
      clearOffered: true,
      foodHint: false,
      chewToken: state.chewToken + 1,
      animation: care == DinoCare.water
          ? CompanionAnimation.drinking
          : CompanionAnimation.eating,
    );
    _settle?.cancel();
    _chewing = true;
    _updateHalfDuplex();
    await Future<void>.delayed(chewDuration);
    if (_isStale(epoch)) return;
    _chewing = false;
    if (food == null) return this.care(care);

    // A food from the panel: its own hunger/happiness/XP, then the Dino
    // is happy (❤️) -- eating -> happy -> idle.
    final engine = _engine;
    if (engine == null) return;
    state = state.copyWith(isThinking: true);
    final response = await engine.care(care, food: food);
    if (_isStale(epoch)) return;
    final loved = response.care == DinoCare.feed;
    await _apply(
      loved ? response.copyWith(animation: CompanionAnimation.happy) : response,
    );
    if (loved) state = state.copyWith(heartsToken: state.heartsToken + 1);
    if (hinted) {
      try {
        await ref.read(foodRepositoryProvider).markHintSeen();
      } catch (_) {
        // The hint shows again next time: harmless.
      }
    }
  }

  /// A food picked in the "Comer" panel appears on screen: the Dino looks
  /// at it and says its name; the child drags it to the mouth.
  Future<void> selectFood(FoodItem food) async {
    final engine = _engine;
    if (engine == null || state.isThinking || _chewing) return;
    if (state.companion?.isSleeping ?? false) {
      state = state.copyWith(clearOffered: true);
      return care(DinoCare.feed);
    }
    if (state.scene != PetScene.food) _enterScene(PetScene.food);
    final epoch = _epoch;
    var hintSeen = true;
    try {
      hintSeen = await ref.read(foodRepositoryProvider).hintSeen();
    } catch (_) {}
    if (_isStale(epoch)) return;
    state = state.copyWith(
      offered: DinoCare.feed,
      offeredFood: food,
      foodHint: !hintSeen,
      lookToken: state.lookToken + 1,
    );
    final offer = await engine.offerFood(food);
    if (_isStale(epoch)) return;
    await _apply(offer);
  }

  /// The ball was tapped or picked up: the Dino looks at it.
  Future<void> noticeBall({required bool dragging}) async {
    final engine = _engine;
    if (engine == null || state.isThinking || state.dinoSpeaking) return;
    final epoch = _epoch;
    state = state.copyWith(lookToken: state.lookToken + 1);
    final response = await engine.ballNoticed(dragging: dragging);
    if (_isStale(epoch)) return;
    await _apply(response);
  }

  /// The toy ball was thrown at the Dino at home: it punches it (goal
  /// every 3 kicks). The one play move allowed outside the ball game,
  /// because the child asked for it.
  Future<void> kickBall() async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    final epoch = _epoch;
    state = state.copyWith(isThinking: true);
    _updateHalfDuplex();
    final response = await engine.kick();
    if (_isStale(epoch)) return;
    await _apply(response, playMove: true);
  }

  Future<void> _onTick() async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    final companion = await engine.tick();
    if (!ref.mounted) return;
    final busyPose =
        (_settle?.isActive ?? false) || state.wakingUp || state.walkingToBed;
    state = state.copyWith(
      companion: companion,
      animation: busyPose ? null : CompanionEngine.idleAnimationFor(companion),
    );
    // A need just became urgent: the Dino says so by itself, once.
    final urgent = companion.mostUrgentNeed;
    if (urgent != _lastUrgent) {
      _lastUrgent = urgent;
      if (urgent != null && !_busy && state.offered == null) {
        final nudge = await engine.needNudge();
        if (nudge != null && ref.mounted) await _apply(nudge);
      }
    }
  }

  /// The last conversation comes back with the screen (history sheet).
  Future<void> _restoreHistory() async {
    final saved = await _history.recent();
    if (!ref.mounted || saved.isEmpty) return;
    state = state.copyWith(
      messages: [
        for (final e in saved) ...[
          if (e.childText case final said?)
            DinoChatMessage(
              speaker: Speaker.child,
              text: said,
              viaVoice: e.viaVoice,
            ),
          DinoChatMessage(
            speaker: Speaker.dino,
            text: e.englishText,
            translation: e.portugueseText,
          ),
        ],
      ],
    );
  }

  Future<void> _addCoins(int coins) async {
    try {
      await CoinRepository(ref.read(databaseProvider)).add(coins);
      if (ref.mounted) ref.invalidate(foodInventoryProvider);
    } catch (_) {
      // Coins are a bonus: never break the game for them.
    }
  }

  /// Saves one exchange: what the child said + the Dino's answer.
  Future<void> _save(CompanionResponse response) async {
    final said = _childSaid;
    _childSaid = null;
    if (!response.shouldSpeak) return;
    try {
      await _history.add(
        CompanionHistoryEntry(
          childText: said?.$1,
          viaVoice: said?.$2 ?? false,
          englishText: response.englishText,
          portugueseText: response.portugueseText,
          intent: response.intent?.name,
          word:
              response.vocabulary.firstOrNull ??
              response.detectedWords.firstOrNull,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // History is a nice-to-have: never break the conversation for it.
    }
  }

  /// Shows (and voices) one reply. [speak]: false keeps it silent;
  /// [playMove]: the reply may make the Dino punch (only the ball game and
  /// the toy ball do -- a "vamos brincar" said at home just cheers);
  /// [keepAnimation]: the pose was already set (getting up).
  Future<void> _apply(
    CompanionResponse response, {
    bool speak = true,
    bool playMove = false,
    bool keepAnimation = false,
  }) async {
    // Portuguese with one English word (lessons and translations as is).
    response = _engine?.present(response) ?? response;
    // The reply moved the Dino to another activity by itself ("vamos
    // dormir", "come uma maçã"): go to that room, keep this reply.
    final asleep = response.state.isSleeping;
    if (asleep && state.scene != PetScene.sleep) {
      _enterScene(PetScene.sleep, stopVoice: false);
      state = state.copyWith(bedroom: true);
    } else if ((response.care == DinoCare.feed ||
            response.care == DinoCare.water) &&
        state.scene == PetScene.home) {
      _enterScene(PetScene.food, stopVoice: false);
    }
    var animation = response.animation;
    if (animation == CompanionAnimation.playing &&
        !playMove &&
        state.scene != PetScene.play) {
      animation = CompanionAnimation.happy;
    }
    unawaited(_save(response));
    if (response.coinReward > 0) unawaited(_addCoins(response.coinReward));
    state = state.copyWith(
      messages: [
        ...state.messages,
        for (final line in response.lines)
          DinoChatMessage(
            speaker: Speaker.dino,
            text: line.text,
            translation: line.translation,
            english: line.english ?? const [],
          ),
      ],
      suggestions: response.suggestions,
      animation: keepAnimation ? null : animation,
      companion: response.state,
      lastResponse: response,
      pendingActivity: response.activity,
      isThinking: false,
      xpEarned: state.xpEarned + response.xpReward,
      xpBurst: response.xpReward > 0 ? state.xpBurst + 1 : null,
    );

    _settle?.cancel();
    final epoch = _epoch;
    _settle = Timer(reactionDuration, () {
      if (_isStale(epoch) || state.wakingUp || state.walkingToBed) return;
      final companion = state.companion;
      if (companion == null) return;
      state = state.copyWith(
        animation: CompanionEngine.idleAnimationFor(companion),
      );
    });

    final engine = _engine;
    if (engine != null) {
      engine.noteSaid(response);
      _recognizer.languageHint = engine.expectedLanguage;
    }
    // Speaking starts right away, so the mic stays muted through it. The
    // ball game can be played in silence (🔇).
    final muted = state.scene == PetScene.play && state.quietPlay;
    if (response.shouldSpeak && speak && !muted) {
      unawaited(ref.read(companionVoiceServiceProvider).say(response));
    }
    _updateHalfDuplex();
    // "Tchau!" or a game opening: stop listening until the child taps 🎤.
    if (!response.shouldListenAgain && _recognizer.isRunning) {
      _userPaused = true;
      unawaited(_syncListening());
    }
  }
}

final dinoChatProvider =
    NotifierProvider.autoDispose<DinoChatController, DinoChatState>(
      DinoChatController.new,
    );
