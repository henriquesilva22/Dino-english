import 'dart:async' show Timer, unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/brain/context/conversation_context.dart';
import '../core/brain/memory/dino_memory.dart';
import '../core/brain/model/dino_enums.dart';
import '../core/brain/vocabulary/official_vocabulary.dart';
import '../core/companion/companion_engine.dart';
import '../core/companion/companion_response.dart';
import '../core/companion/companion_state.dart';
import '../core/companion/voice/speech_recognition_service.dart';
import '../core/models/session_kind.dart';
import '../core/repositories/companion_state_repository.dart';
import '../core/repositories/dino_memory_repository.dart';
import 'database_providers.dart';
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

  /// The child said it with the microphone (shows what the Dino heard).
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
    this.voiceAvailable = false,
    this.isListening = false,
    this.isTranscribing = false,
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

  /// The offline voice model is bundled: show the mic button.
  final bool voiceAvailable;

  /// The mic button is held down.
  final bool isListening;

  /// The voice is being transcribed (about a second).
  final bool isTranscribing;

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
    bool? voiceAvailable,
    bool? isListening,
    bool? isTranscribing,
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
      voiceAvailable: voiceAvailable ?? this.voiceAvailable,
      isListening: isListening ?? this.isListening,
      isTranscribing: isTranscribing ?? this.isTranscribing,
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
/// com o Dino"): text and voice messages, care buttons, needs that decay
/// while the screen is open, the Dino's voice and XP.
class DinoChatController extends Notifier<DinoChatState> {
  final String _sessionId = const Uuid().v4();
  CompanionEngine? _engine;
  late SpeechRecognitionService _recognizer;
  Timer? _tick;
  Timer? _settle;

  /// How often the needs bars are refreshed while the screen is open.
  static const Duration tickInterval = Duration(minutes: 1);

  /// How long a reaction (eating, celebrating...) shows before the pet
  /// returns to its idle pose.
  static const Duration reactionDuration = Duration(seconds: 3);

  @override
  DinoChatState build() {
    // Watched (not read) so the auto-disposed recognizer -- and the voice
    // model in memory -- live exactly as long as this screen.
    _recognizer = ref.watch(speechRecognitionServiceProvider);
    ref.onDispose(() {
      _tick?.cancel();
      _settle?.cancel();
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
    _tick = Timer.periodic(tickInterval, (_) => _onTick());
    await _apply(await engine.start());

    final voice = await _recognizer.isAvailable();
    if (!ref.mounted || !voice) return;
    state = state.copyWith(voiceAvailable: true);
    // Load the model now, so the first answer by voice is quick.
    unawaited(_recognizer.prepare());
  }

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
    final response = await engine.process(trimmed);
    if (!ref.mounted) return;
    await _apply(response);
  }

  Future<void> care(DinoCare care) async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    state = state.copyWith(isThinking: true);
    final response = await engine.care(care);
    if (!ref.mounted) return;
    await _apply(response);
  }

  Future<void> wakeUp() async {
    final engine = _engine;
    if (engine == null || state.isThinking) return;
    state = state.copyWith(isThinking: true);
    final response = await engine.wakeUp();
    if (!ref.mounted) return;
    await _apply(response);
  }

  /// Mic button pressed: the Dino stops talking (so it doesn't hear
  /// itself) and listens.
  Future<void> startListening() async {
    final engine = _engine;
    if (engine == null || state.isThinking || state.isListening) return;
    await ref.read(companionVoiceServiceProvider).stop();
    _settle?.cancel();
    state = state.copyWith(
      isListening: true,
      animation: CompanionAnimation.listening,
    );
    final started = await _recognizer.startListening();
    if (!ref.mounted) return;
    if (!started) {
      state = state.copyWith(isListening: false);
      await _apply(engine.micUnavailable());
    }
  }

  /// Mic button released: transcribe offline and send it like typed text.
  Future<void> stopListening() async {
    final engine = _engine;
    if (engine == null || !state.isListening) return;
    state = state.copyWith(
      isListening: false,
      isTranscribing: true,
      animation: CompanionAnimation.thinking,
    );
    final text = await _recognizer.stopListening(hint: engine.expectedLanguage);
    if (!ref.mounted) return;
    state = state.copyWith(isTranscribing: false);
    if (text == null) {
      await _apply(engine.didNotHear());
    } else {
      await send(text, viaVoice: true);
    }
  }

  /// The finger slid off the button: nothing is sent.
  Future<void> cancelListening() async {
    if (!state.isListening) return;
    await _recognizer.cancel();
    if (!ref.mounted) return;
    final companion = state.companion;
    state = state.copyWith(
      isListening: false,
      animation: companion == null
          ? CompanionAnimation.idle
          : CompanionEngine.idleAnimationFor(companion),
    );
  }

  void consumeActivity() => state = state.copyWith(clearPendingActivity: true);

  Future<void> _onTick() async {
    final engine = _engine;
    if (engine == null || state.isThinking || state.isListening) return;
    final companion = await engine.tick();
    if (!ref.mounted) return;
    state = state.copyWith(
      companion: companion,
      animation: _settle?.isActive ?? false
          ? null
          : CompanionEngine.idleAnimationFor(companion),
    );
  }

  Future<void> _apply(CompanionResponse response) async {
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
    );

    _settle?.cancel();
    _settle = Timer(reactionDuration, () {
      if (!ref.mounted) return;
      if (state.isListening || state.isTranscribing) return;
      final companion = state.companion;
      if (companion == null) return;
      state = state.copyWith(
        animation: CompanionEngine.idleAnimationFor(companion),
      );
    });

    unawaited(ref.read(companionVoiceServiceProvider).say(response));
  }
}

final dinoChatProvider =
    NotifierProvider.autoDispose<DinoChatController, DinoChatState>(
      DinoChatController.new,
    );
