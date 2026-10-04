import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:flutter/foundation.dart' show ValueListenable;
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
  });

  final Speaker speaker;
  final String text;

  /// Portuguese subtitle for Dino lines.
  final String? translation;

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

    final engine = CompanionEngine(
      vocabulary: OfficialVocabulary.fromWords(words),
      memory: memory,
      store: DriftCompanionStateStore(database),
      rewards: _ProgressCompanionRewards(ref, _sessionId),
      totalXp: profile.totalXp,
      level: profile.currentLevel,
    );
    await engine.load();
    if (!ref.mounted) return;
    _engine = engine;
    state = state.copyWith(isReady: true, companion: engine.state);
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
    final response = await engine.process(trimmed);
    if (!ref.mounted) return;
    await _apply(response);
  }

  Future<void> care(DinoCare care) async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    state = state.copyWith(isThinking: true);
    _updateHalfDuplex();
    final response = await engine.care(care);
    if (!ref.mounted) return;
    await _apply(response);
  }

  Future<void> wakeUp() async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    state = state.copyWith(isThinking: true);
    _updateHalfDuplex();
    final response = await engine.wakeUp();
    if (!ref.mounted) return;
    state = state.copyWith(bedroom: false);
    await _apply(response);
  }

  void consumeActivity() => state = state.copyWith(clearPendingActivity: true);

  // ---- back -------------------------------------------------------------------------

  /// The system back / ✕ inside the companion screen: closes what is open
  /// on it first (the ball game, the bedroom, food or water waiting to be
  /// given), one step at a time. Returns false when nothing was open --
  /// then the screen itself may close.
  bool back() {
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
    final asleep = state.companion?.isSleeping ?? false;
    if (state.bedroom && !state.walkingToBed && !asleep) {
      state = state.copyWith(bedroom: false);
      return true;
    }
    if (state.offered != null) {
      state = state.copyWith(clearOffered: true);
      return true;
    }
    return false;
  }

  /// Whether [back] would close something on the screen.
  bool get hasOpenActivity {
    final asleep = state.companion?.isSleeping ?? false;
    return state.ballGame ||
        (state.bedroom && !state.walkingToBed && !asleep) ||
        state.offered != null;
  }

  // Ball game tallies (for leaving it with the back button).
  int _ballHits = 0;
  int _ballBest = 0;
  Stopwatch? _ballPlayed;

  // ---- pet activities -------------------------------------------------------------

  /// A care button. Food and water first appear on screen (the child
  /// drags them to the Dino); "Brincar" invites to kick the ball;
  /// "Dormir" puts it to bed right away.
  Future<void> startActivity(DinoCare care) async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    final asleep = state.companion?.isSleeping ?? false;
    if (asleep) {
      state = state.copyWith(clearOffered: true);
      return this.care(care);
    }
    // "Dormir": the bedroom appears; the child taps the bed (goToBed).
    if (care == DinoCare.sleep) {
      state = state.copyWith(
        clearOffered: true,
        ballGame: false,
        bedroom: true,
        lookToken: state.lookToken + 1,
      );
      return _apply(await engine.bedtimeInvite());
    }
    state = state.copyWith(
      bedroom: false,
      offered: care == DinoCare.play ? null : care,
      clearOffered: care == DinoCare.play,
      lookToken: state.lookToken + 1,
      // "Brincar": the bouncing-ball game.
      ballGame: care == DinoCare.play ? true : null,
    );
    if (care == DinoCare.play) {
      engine.startBallGame();
      _ballHits = 0;
      _ballBest = 0;
      _ballPlayed = Stopwatch()..start();
    }
    await _apply(
      care == DinoCare.play
          ? await engine.playInvite()
          : await engine.offer(care),
    );
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
    state = state.copyWith(
      walkingToBed: true,
      animation: CompanionAnimation.walking,
    );
    await Future<void>.delayed(walkToBedDuration);
    if (!ref.mounted) return;
    state = state.copyWith(walkingToBed: false);
    await care(DinoCare.sleep);
  }

  // ---- ball game ------------------------------------------------------------------

  /// A hit in the ball game. Most hits are silent (XP only); combos cheer.
  Future<void> ballHit(int combo) async {
    final engine = _engine;
    if (engine == null || !state.ballGame) return;
    _ballHits++;
    if (combo > _ballBest) _ballBest = combo;
    final response = await engine.ballHit(combo);
    if (!ref.mounted || !state.ballGame) return;
    // Don't cut the Dino off for a silent hit.
    if (response.shouldSpeak || response.xpReward > 0) await _apply(response);
  }

  /// The ball stopped rolling.
  Future<void> ballStopped(int lostCombo) async {
    final engine = _engine;
    if (engine == null || !state.ballGame || state.dinoSpeaking) return;
    await _apply(await engine.ballStopped(lostCombo));
  }

  /// "Parar": the game ends with a short summary (+ time bonus).
  Future<void> stopBallGame({
    required int hits,
    required int bestCombo,
    required Duration played,
  }) async {
    final engine = _engine;
    if (engine == null || !state.ballGame) return;
    state = state.copyWith(ballGame: false);
    await _apply(
      await engine.ballGameOver(
        hits: hits,
        bestCombo: bestCombo,
        played: played,
      ),
    );
  }

  /// The food/drink reached the Dino: it chews (or gulps), then the state
  /// and XP update and it says thank you.
  Future<void> deliverOffered() async {
    final care = state.offered;
    if (_engine == null || care == null || _chewing) return;
    final food = care == DinoCare.feed ? state.offeredFood : null;
    final hinted = state.foodHint;
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
    _chewing = false;
    if (!ref.mounted) return;
    if (food == null) return this.care(care);

    // A food from the panel: its own hunger/happiness/XP, then the Dino
    // is happy (❤️) -- eating -> happy -> idle.
    final engine = _engine;
    if (engine == null) return;
    state = state.copyWith(isThinking: true);
    final response = await engine.care(care, food: food);
    if (!ref.mounted) return;
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
    var hintSeen = true;
    try {
      hintSeen = await ref.read(foodRepositoryProvider).hintSeen();
    } catch (_) {}
    if (!ref.mounted) return;
    state = state.copyWith(
      offered: DinoCare.feed,
      offeredFood: food,
      foodHint: !hintSeen,
      lookToken: state.lookToken + 1,
    );
    await _apply(await engine.offerFood(food));
  }

  /// The ball was tapped or picked up: the Dino looks at it.
  Future<void> noticeBall({required bool dragging}) async {
    final engine = _engine;
    if (engine == null || state.isThinking || state.dinoSpeaking) return;
    state = state.copyWith(lookToken: state.lookToken + 1);
    await _apply(await engine.ballNoticed(dragging: dragging));
  }

  /// The ball was thrown: the Dino runs and kicks (goal every 3 kicks).
  Future<void> kickBall() async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    state = state.copyWith(isThinking: true);
    _updateHalfDuplex();
    final response = await engine.kick();
    if (!ref.mounted) return;
    await _apply(response);
  }

  Future<void> _onTick() async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    final companion = await engine.tick();
    if (!ref.mounted) return;
    state = state.copyWith(
      companion: companion,
      animation: _settle?.isActive ?? false
          ? null
          : CompanionEngine.idleAnimationFor(companion),
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

  Future<void> _apply(CompanionResponse response) async {
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
          ),
      ],
      suggestions: response.suggestions,
      animation: response.animation,
      companion: response.state,
      lastResponse: response,
      pendingActivity: response.activity,
      isThinking: false,
      xpEarned: state.xpEarned + response.xpReward,
      xpBurst: response.xpReward > 0 ? state.xpBurst + 1 : null,
    );

    _settle?.cancel();
    _settle = Timer(reactionDuration, () {
      if (!ref.mounted) return;
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
    // Speaking starts right away, so the mic stays muted through it.
    if (response.shouldSpeak) {
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
