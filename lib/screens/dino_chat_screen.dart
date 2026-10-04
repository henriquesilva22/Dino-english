import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/brain/context/conversation_context.dart';
import '../core/brain/model/dino_enums.dart';
import '../core/app_route_observer.dart';
import '../core/companion/animation/companion_animation_controller.dart';
import '../core/companion/animation/mouth_animation_controller.dart';
import '../core/companion/companion_engine.dart';
import '../core/companion/companion_response.dart';
import '../core/companion/companion_state.dart';
import '../core/companion/companion_state_machine.dart';
import '../core/companion/interaction/companion_interaction_controller.dart';
import '../core/companion/model/companion_model.dart';
import '../core/companion/food/food_item.dart';
import '../core/companion/voice/companion_voice_service.dart';
import '../core/companion/voice/speech_recognition_service.dart';
import '../core/single_navigation_guard.dart';
import '../providers/dino_chat_providers.dart';
import '../providers/navigation_providers.dart';
import '../providers/speech_providers.dart';
import '../theme/neon_colors.dart';
import '../widgets/exit_top_bar.dart';
import '../widgets/neon_background.dart';
import '../widgets/companion/ball_arena.dart';
import '../widgets/companion/bedroom.dart';
import '../widgets/companion/dino_animated_model.dart';
import '../widgets/companion/food_drag.dart';
import '../widgets/companion/food_panel.dart';
import '../widgets/companion/hearts_burst.dart';
import 'exam_screen.dart';
import 'sentence_builder_screen.dart';
import 'word_slash_game_screen.dart';

/// The companion's 3D model (swap it here; nothing else names a file).
const CompanionModel _kDinoModel = CompanionModel.dino;

/// Size of the (square) 3D Dino view on the companion screen.
const double _kDinoSize = 240;

/// "Brincar com o Dino": the virtual companion. The child talks to the
/// Dino by text, feeds it, gives it water, plays and puts it to bed --
/// all offline through the `CompanionEngine`. This widget only renders
/// [DinoChatState] and forwards taps; no conversation rule lives here.
class DinoChatScreen extends ConsumerStatefulWidget {
  const DinoChatScreen({super.key});

  @override
  ConsumerState<DinoChatScreen> createState() => _DinoChatScreenState();
}

class _DinoChatScreenState extends ConsumerState<DinoChatScreen>
    with WidgetsBindingObserver, RouteAware {
  final _input = TextEditingController();

  /// The microphone is open only while the app is in the foreground and
  /// this screen is the visible route (not covered by a game, the history
  /// sheet, the lock screen...).
  bool _appVisible = true;
  bool _routeVisible = true;
  ModalRoute<void>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _input.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Background, screen locked, task switcher... -> close the mic.
    _appVisible = state == AppLifecycleState.resumed;
    _syncForeground();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _syncForeground();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _syncForeground();
  }

  void _syncForeground() => unawaited(
    ref
        .read(dinoChatProvider.notifier)
        .setForeground(_appVisible && _routeVisible),
  );

  /// "Comer": pick a food (or buy one), then drag it to the Dino.
  Future<void> _openFoodPanel() async {
    final food = await showFoodPanel(context);
    if (food == null || !mounted) return;
    await ref.read(dinoChatProvider.notifier).selectFood(food);
  }

  void _send([String? text]) {
    final value = text ?? _input.text;
    if (value.trim().isEmpty) return;
    _input.clear();
    unawaited(ref.read(dinoChatProvider.notifier).send(value));
  }

  void _openActivity(DinoActivity activity) {
    final navigator = Navigator.of(context);
    void selectTab(int index) {
      ref.read(selectedTabIndexProvider.notifier).select(index);
      navigator.pop();
    }

    // Not awaited: the guard would stay armed for the whole activity.
    SingleNavigationGuard.run(() {
      switch (activity) {
        case DinoActivity.study:
          selectTab(1);
        case DinoActivity.adventure:
          selectTab(2);
        case DinoActivity.wordSlash:
          navigator.push(
            MaterialPageRoute(builder: (_) => const WordSlashGameScreen()),
          );
        case DinoActivity.sentenceBuilder:
          navigator.push(
            MaterialPageRoute(builder: (_) => const SentenceBuilderScreen()),
          );
        case DinoActivity.exam:
          navigator.push(MaterialPageRoute(builder: (_) => const ExamScreen()));
      }
    });
  }

  void _showHistory(List<DinoChatMessage> messages) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NeonColors.background,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, i) =>
              _Bubble(message: messages[messages.length - 1 - i]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(dinoChatProvider);
    final notifier = ref.read(dinoChatProvider.notifier);

    ref.listen<DinoChatState>(dinoChatProvider, (previous, next) {
      final activity = next.pendingActivity;
      if (activity != null) {
        ref.read(dinoChatProvider.notifier).consumeActivity();
        // Let the Dino finish its "Let's go!" line on screen first.
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _openActivity(activity);
        });
      }
    });

    final companion = chat.companion;
    final canAct = chat.isReady && !chat.isThinking;
    // Back (system or ✕) closes one thing at a time: the ball game, the
    // bedroom or the offered food first; only then the screen itself.
    return PopScope(
      canPop: !notifier.hasOpenActivity,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          unawaited(ref.read(companionVoiceServiceProvider).stop());
        } else {
          notifier.back();
        }
      },
      child: Scaffold(
        body: NeonBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExitTopBar(
                  title: 'Brincar com o Dino',
                  // Same rule as the system back (PopScope above).
                  onExit: () => Navigator.of(context).maybePop(),
                ),
                if (companion != null)
                  _NeedsBar(state: companion, xpEarned: chat.xpEarned),
                Expanded(
                  child: !chat.isReady
                      ? const Center(child: CircularProgressIndicator())
                      : _PetStage(
                          animation: chat.animation,
                          rest: companion == null
                              ? CompanionAnimation.idle
                              : CompanionEngine.idleAnimationFor(companion),
                          response: chat.lastResponse,
                          status: chat.isThinking ? '...' : null,
                          lookToken: chat.lookToken,
                          chewToken: chat.chewToken,
                          offered: chat.offered,
                          offeredFood: chat.offeredFood,
                          foodHint: chat.foodHint,
                          heartsToken: chat.heartsToken,
                          sleeping: companion?.isSleeping ?? false,
                          xpBurst: chat.xpBurst,
                          xpAmount: chat.lastResponse?.xpReward ?? 0,
                          onDeliver: () => unawaited(notifier.deliverOffered()),
                          onBallNoticed: (dragging) => unawaited(
                            notifier.noticeBall(dragging: dragging),
                          ),
                          onKick: () => unawaited(notifier.kickBall()),
                          bedroom: chat.bedroom,
                          walkingToBed: chat.walkingToBed,
                          ballGame: chat.ballGame,
                          onGoToBed: () => unawaited(notifier.goToBed()),
                          onBallHit: (combo) =>
                              unawaited(notifier.ballHit(combo)),
                          onBallStopped: (lost) =>
                              unawaited(notifier.ballStopped(lost)),
                          onStopBall: (hits, best, played) => unawaited(
                            notifier.stopBallGame(
                              hits: hits,
                              bestCombo: best,
                              played: played,
                            ),
                          ),
                        ),
                ),
                if (chat.isReady)
                  _VoiceStatusBar(
                    state: chat.voiceState,
                    dinoSpeaking: chat.dinoSpeaking,
                    thinking: chat.isThinking,
                    heardText: chat.heardText,
                    message: chat.voiceMessage,
                    onTap: () => unawaited(notifier.toggleMicrophone()),
                  ),
                if (chat.suggestions.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chat.suggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => ActionChip(
                        label: Text(chat.suggestions[i]),
                        onPressed: canAct
                            ? () => _send(chat.suggestions[i])
                            : null,
                        backgroundColor: NeonColors.surface,
                        side: const BorderSide(color: NeonColors.cyan),
                        labelStyle: const TextStyle(
                          color: NeonColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                _CareButtons(
                  enabled: canAct,
                  isSleeping: companion?.isSleeping ?? false,
                  onCare: (care) => unawaited(
                    care == DinoCare.feed && !(companion?.isSleeping ?? false)
                        ? _openFoodPanel()
                        // In the bedroom, "Dormir" again = go to bed.
                        : care == DinoCare.sleep && chat.bedroom
                        ? notifier.goToBed()
                        : notifier.startActivity(care),
                  ),
                  onWakeUp: () => unawaited(notifier.wakeUp()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: chat.messages.isEmpty
                            ? null
                            : () => _showHistory(chat.messages),
                        icon: const Icon(
                          Icons.history_rounded,
                          color: NeonColors.textSecondary,
                        ),
                        tooltip: 'Conversa',
                      ),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          enabled: chat.isReady,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: const TextStyle(color: NeonColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Fale com o Dino...',
                            hintStyle: const TextStyle(
                              color: NeonColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: NeonColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: NeonColors.cyan,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: NeonColors.cyan.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: canAct ? _send : null,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: NeonColors.cyan,
                        ),
                        tooltip: 'Enviar',
                      ),
                      if (chat.isReady)
                        _MicButton(
                          state: chat.voiceState,
                          dinoSpeaking: chat.dinoSpeaking,
                          onTap: () => unawaited(notifier.toggleMicrophone()),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ❤️ 🍎 💧 ⚡ meters plus the XP earned in this visit.
class _NeedsBar extends StatelessWidget {
  const _NeedsBar({required this.state, required this.xpEarned});

  final CompanionState state;
  final int xpEarned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          _NeedMeter(
            emoji: '❤️',
            value: state.happiness,
            color: NeonColors.red,
          ),
          _NeedMeter(emoji: '🍎', value: state.hunger, color: NeonColors.green),
          _NeedMeter(emoji: '💧', value: state.thirst, color: NeonColors.cyan),
          _NeedMeter(emoji: '⚡', value: state.energy, color: NeonColors.orange),
          if (xpEarned > 0)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: NeonColors.purple.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeonColors.purple),
              ),
              child: Text(
                '+$xpEarned XP',
                style: const TextStyle(
                  color: NeonColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NeedMeter extends StatelessWidget {
  const _NeedMeter({
    required this.emoji,
    required this.value,
    required this.color,
  });

  final String emoji;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / CompanionState.max).clamp(0.0, 1.0);
    final barColor = fraction < 0.35 ? NeonColors.red : color;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$emoji ${value.round()}',
              style: const TextStyle(
                color: NeonColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: fraction),
                duration: const Duration(milliseconds: 400),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: NeonColors.surface,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Dino in the middle of the screen (3D, animated by the engine, its
/// mouth following the voice), a small emoji for what the model has no
/// clip for, and the speech bubble.
class _PetStage extends ConsumerStatefulWidget {
  const _PetStage({
    required this.animation,
    required this.rest,
    required this.response,
    required this.status,
    required this.lookToken,
    required this.chewToken,
    required this.offered,
    required this.offeredFood,
    required this.foodHint,
    required this.heartsToken,
    required this.sleeping,
    required this.xpBurst,
    required this.xpAmount,
    required this.onDeliver,
    required this.onBallNoticed,
    required this.onKick,
    required this.bedroom,
    required this.walkingToBed,
    required this.ballGame,
    required this.onGoToBed,
    required this.onBallHit,
    required this.onBallStopped,
    required this.onStopBall,
  });

  final CompanionAnimation animation;

  /// Pose for the pet's needs when nothing is happening.
  final CompanionAnimation rest;
  final CompanionResponse? response;

  /// "Ouvindo..." / "..." instead of the reply, or null.
  final String? status;

  /// Changes when the Dino should turn to face the child.
  final int lookToken;
  final int chewToken;

  /// Food or water waiting to be dragged to the Dino.
  final DinoCare? offered;

  /// The food from the panel, to drag to the mouth (with [offered] =
  /// feed).
  final FoodItem? offeredFood;
  final bool foodHint;

  /// Changes when the Dino loved a meal (❤️).
  final int heartsToken;
  final bool sleeping;

  /// Changes when XP is earned ([xpAmount] floats up).
  final int xpBurst;
  final int xpAmount;
  final VoidCallback onDeliver;
  final ValueChanged<bool> onBallNoticed;
  final VoidCallback onKick;

  /// Bedtime: the room with the bed is shown.
  final bool bedroom;
  final bool walkingToBed;

  /// The bouncing-ball game is on.
  final bool ballGame;
  final VoidCallback onGoToBed;
  final ValueChanged<int> onBallHit;
  final ValueChanged<int> onBallStopped;
  final void Function(int hits, int bestCombo, Duration played) onStopBall;

  @override
  ConsumerState<_PetStage> createState() => _PetStageState();
}

class _PetStageState extends ConsumerState<_PetStage> {
  static const _states = CompanionStateMachine();
  static const _animations = CompanionAnimationController(_kDinoModel);
  static const _interaction = CompanionInteractionController(
    model: _kDinoModel,
  );
  final MouthAnimationController _mouth = MouthAnimationController();

  /// One 3D view for the whole screen: it moves between the stage and the
  /// ball game without reloading the model.
  final GlobalKey _dinoKey = GlobalKey(debugLabel: 'dino-3d');

  /// Food held over the mouth: it opens wide.
  bool _gaping = false;

  /// Each ball dropped on/thrown at the Dino: one more punch.
  int _playSerial = 0;
  ValueListenable<SpokenLine?>? _line;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final line = ref.read(companionVoiceServiceProvider).currentLine;
    if (line != _line) {
      _line?.removeListener(_onLine);
      _line = line..addListener(_onLine);
    }
  }

  /// Each line the voice starts (English, then Portuguese) moves the
  /// mouth; between and after lines it closes.
  void _onLine() {
    final line = _line?.value;
    if (line == null) {
      _mouth.stop();
    } else {
      _mouth.talk(line.text);
    }
  }

  @override
  void dispose() {
    _line?.removeListener(_onLine);
    _mouth.dispose();
    super.dispose();
  }

  void _kick() {
    setState(() => _playSerial++);
    widget.onKick();
  }

  /// The 3D Dino. [plan], [yaw]: what it does and the way it faces.
  Widget _dino({
    required CompanionClipPlan plan,
    required double yaw,
    required bool talking,
    bool playing = false,
  }) => DinoAnimatedModel(
    key: _dinoKey,
    model: _kDinoModel,
    size: _kDinoSize,
    plan: plan,
    yaw: yaw,
    playing: playing,
    talking: talking,
    mouth: _mouth.shape,
    lookToken: widget.lookToken,
    chewToken: widget.chewToken,
    gaping: _gaping,
  );

  /// Clips for the engine's reaction while the Dino stays in its place.
  CompanionClipPlan _restingPlan({required bool speaking}) {
    final activity = _states.resolve(
      engine: widget.animation,
      speaking: speaking,
    );
    final rest = _states.resolve(engine: widget.rest, speaking: speaking);
    return _animations.plan(activity, rest: rest, serial: _playSerial);
  }

  /// Props for what the model's own clips can't show (eating, water...).
  static const Map<CompanionAnimation, String> _reaction = {
    CompanionAnimation.hungry: '🍽️',
    CompanionAnimation.thirsty: '💧',
    CompanionAnimation.sleepy: '🥱',
    CompanionAnimation.eating: '😋',
    CompanionAnimation.drinking: '🥤',
    CompanionAnimation.sleeping: '💤',
    CompanionAnimation.celebrating: '🎉',
    CompanionAnimation.listening: '👂',
    CompanionAnimation.thinking: '💭',
  };

  @override
  Widget build(BuildContext context) {
    final animation = widget.animation;
    final reaction = _reaction[animation];
    final voice = ref.watch(companionVoiceServiceProvider);
    final room = widget.bedroom || widget.sleeping;
    // Walking to the bed, then sleeping on it (relative position: works
    // on any screen size and for any Dino model).
    final placement = _interaction.placement(
      walkingToBed: widget.walkingToBed,
      sleeping: widget.sleeping,
      inBedroom: room,
    );
    final mouthZone = _interaction.mouthZone();
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (room)
                Positioned.fill(
                  child: BedroomBackground(night: widget.sleeping),
                ),
              if (room)
                Positioned(
                  right: 4,
                  bottom: 0,
                  child: TappableBed(
                    hint:
                        widget.bedroom &&
                        !widget.walkingToBed &&
                        !widget.sleeping,
                    onTap: widget.onGoToBed,
                  ),
                ),
              // The Dino is the drop target: food/water to eat, the ball to
              // kick.
              // (In the ball game the arena places it on the floor.)
              if (!widget.ballGame)
                Positioned.fill(
                  child: AnimatedAlign(
                    alignment: placement.alignment,
                    duration: DinoChatController.walkToBedDuration,
                    curve: Curves.easeInOut,
                    child: AnimatedScale(
                      scale: placement.scale,
                      duration: DinoChatController.walkToBedDuration,
                      child: DragTarget<_Toy>(
                        onAcceptWithDetails: (details) {
                          HapticFeedback.lightImpact();
                          if (details.data == _Toy.ball) {
                            _kick();
                          } else {
                            widget.onDeliver();
                          }
                        },
                        builder: (context, candidates, _) => AnimatedScale(
                          scale: candidates.isEmpty ? 1 : 1.06,
                          duration: const Duration(milliseconds: 150),
                          child: SizedBox.square(
                            dimension: _kDinoSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Talking body (+ mouth, if the model has one)
                                // while the voice is speaking.
                                ValueListenableBuilder<Object?>(
                                  valueListenable: voice.speaking,
                                  builder: (context, utterance, _) => _dino(
                                    plan: _restingPlan(
                                      speaking: utterance != null,
                                    ),
                                    yaw: placement.yaw,
                                    talking: utterance != null,
                                  ),
                                ),
                                // The mouth's drop zone, from the model's mouth
                                // point: it follows the Dino on any screen.
                                Align(
                                  alignment: mouthZone.alignment,
                                  child: FractionallySizedBox(
                                    widthFactor: mouthZone.widthFactor,
                                    heightFactor: mouthZone.heightFactor,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 220,
                                      ),
                                      child: MouthDropZone(
                                        key: const ValueKey('mouth-drop-zone'),
                                        enabled: !widget.sleeping,
                                        onHover: (on) =>
                                            setState(() => _gaping = on),
                                        onDelivered: (_) => widget.onDeliver(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Night: the room gets dark while the Dino sleeps.
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: widget.sleeping ? 0.3 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: Container(color: Colors.black),
                ),
              ),
              // The ball is a real toy: tap = the Dino looks, drag = it
              // watches, release/throw = it runs and kicks.
              if (!widget.ballGame && !room)
                Positioned(
                  right: 24,
                  top: 8,
                  child: _DraggableToy(
                    toy: _Toy.ball,
                    enabled: !widget.sleeping,
                    onTap: () => widget.onBallNoticed(false),
                    onDragStarted: () => widget.onBallNoticed(true),
                    onThrown: _kick,
                  ),
                ),
              if (widget.ballGame)
                Positioned.fill(
                  child: ValueListenableBuilder<Object?>(
                    valueListenable: voice.speaking,
                    builder: (context, utterance, _) => BallArena(
                      key: const ValueKey('ball-arena'),
                      model: _kDinoModel,
                      dinoSize: _kDinoSize,
                      // Chasing, punching -- and talking while it plays.
                      dinoBuilder: (context, game) => _dino(
                        plan: _animations.plan(
                          game.activity(
                            engine: animation,
                            speaking: utterance != null,
                          ),
                          // Rounded: the view only hears real changes.
                          timeScale: (game.timeScale * 20).round() / 20,
                          serial: game.attackSerial,
                        ),
                        yaw: game.dino.yawDegrees,
                        talking: utterance != null,
                        playing: true,
                      ),
                      onHit: widget.onBallHit,
                      onStopped: widget.onBallStopped,
                      onFinish: widget.onStopBall,
                    ),
                  ),
                ),
              if (widget.offeredFood case final food?
                  when widget.offered == DinoCare.feed)
                Positioned(
                  bottom: 8,
                  child: DraggableFood(
                    key: ValueKey('offered-${food.id}'),
                    food: food,
                    showHint: widget.foodHint,
                  ),
                )
              else if (widget.offered case final care?)
                Positioned(
                  bottom: 12,
                  child: _DraggableToy(
                    toy: care == DinoCare.water ? _Toy.water : _Toy.food,
                    enabled: true,
                    hint: true,
                    // Little hands may just tap it.
                    onTap: widget.onDeliver,
                  ),
                ),
              HeartsBurst(token: widget.heartsToken),
              _XpBurst(token: widget.xpBurst, amount: widget.xpAmount),
              if (reaction != null)
                Positioned(
                  left: 24,
                  top: 8,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Text(
                      reaction,
                      key: ValueKey(animation),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _SpeechBubble(response: widget.response, status: widget.status),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.response, required this.status});

  final CompanionResponse? response;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final lines = response?.lines ?? const <CompanionLine>[];
    // Each new reply pops in (scale + fade) so the child sees it change.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(status ?? identityHashCode(response)),
        child: _bubble(lines),
      ),
    );
  }

  Widget _bubble(List<CompanionLine> lines) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 56, maxHeight: 150),
      decoration: BoxDecoration(
        color: NeonColors.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NeonColors.cyan.withValues(alpha: 0.6)),
      ),
      child: status != null
          ? Center(
              child: Text(
                status!,
                style: const TextStyle(
                  color: NeonColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in lines) ...[
                    Text(
                      line.text,
                      style: const TextStyle(
                        color: NeonColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (line.translation != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          line.translation!,
                          style: const TextStyle(
                            color: NeonColors.textSecondary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CareButtons extends StatelessWidget {
  const _CareButtons({
    required this.enabled,
    required this.isSleeping,
    required this.onCare,
    required this.onWakeUp,
  });

  final bool enabled;
  final bool isSleeping;
  final ValueChanged<DinoCare> onCare;
  final VoidCallback onWakeUp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _CareButton(
            emoji: '🍎',
            label: 'Comer',
            color: NeonColors.green,
            onTap: enabled && !isSleeping ? () => onCare(DinoCare.feed) : null,
          ),
          _CareButton(
            emoji: '💧',
            label: 'Água',
            color: NeonColors.cyan,
            onTap: enabled && !isSleeping ? () => onCare(DinoCare.water) : null,
          ),
          _CareButton(
            emoji: '🎮',
            label: 'Brincar',
            color: NeonColors.purple,
            onTap: enabled && !isSleeping ? () => onCare(DinoCare.play) : null,
          ),
          if (isSleeping)
            _CareButton(
              emoji: '☀️',
              label: 'Acordar',
              color: NeonColors.orange,
              onTap: enabled ? onWakeUp : null,
            )
          else
            _CareButton(
              emoji: '😴',
              label: 'Dormir',
              color: NeonColors.orange,
              onTap: enabled ? () => onCare(DinoCare.sleep) : null,
            ),
        ],
      ),
    );
  }
}

class _CareButton extends StatelessWidget {
  const _CareButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: color.withValues(alpha: enabled ? 0.16 : 0.05),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: enabled ? 0.7 : 0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white.withValues(alpha: enabled ? 1 : 0.4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled
                          ? NeonColors.textPrimary
                          : NeonColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final DinoChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isDino = message.speaker == Speaker.dino;
    final color = isDino ? NeonColors.cyan : NeonColors.purple;
    return Align(
      alignment: isDino ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isDino ? 4 : 16),
            bottomRight: Radius.circular(isDino ? 16 : 4),
          ),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDino
                  ? '🦖 ${message.text}'
                  : message.viaVoice
                  ? '🎤 ${message.text}'
                  : message.text,
              style: const TextStyle(
                color: NeonColors.textPrimary,
                fontSize: 15,
              ),
            ),
            if (message.translation != null) ...[
              const SizedBox(height: 4),
              Text(
                message.translation!,
                style: const TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 🎙️ Ouvindo... / 🎙️ "texto" / 🧠 Processando... / a friendly error.
/// Tapping it does what the mic button does.
class _VoiceStatusBar extends StatelessWidget {
  const _VoiceStatusBar({
    required this.state,
    required this.dinoSpeaking,
    required this.thinking,
    required this.heardText,
    required this.message,
    required this.onTap,
  });

  final VoiceState state;
  final bool dinoSpeaking;
  final bool thinking;
  final String? heardText;
  final String? message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final blocked = state == VoiceState.error || state == VoiceState.disabled;
    final (text, color) = switch (state) {
      // The mic is closed while the Dino thinks/talks: say so.
      _ when dinoSpeaking && !blocked => ('🦖 Falando...', NeonColors.purple),
      _ when thinking && !blocked => ('🧠 Pensando...', NeonColors.cyan),
      VoiceState.listening when heardText != null => (
        '🎙️ "$heardText"',
        NeonColors.green,
      ),
      VoiceState.listening => ('🎙️ Ouvindo...', NeonColors.green),
      VoiceState.processing => (
        '🧠 ${message ?? 'Processando...'}',
        NeonColors.cyan,
      ),
      VoiceState.idle => (
        '🎙️ Microfone pausado — toque para ouvir',
        NeonColors.textSecondary,
      ),
      VoiceState.error || VoiceState.disabled => (
        message ?? 'Conversa por voz indisponível.',
        NeonColors.orange,
      ),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            text,
            key: ValueKey(text),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: state == VoiceState.idle
                  ? NeonColors.textSecondary
                  : NeonColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hands-free mic toggle: green and pulsing while the Dino listens; tap
/// to pause/resume, or to allow the microphone when it's disabled.
class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.state,
    required this.dinoSpeaking,
    required this.onTap,
  });

  final VoiceState state;

  /// While the Dino talks the mic is closed: shows a speaker instead.
  final bool dinoSpeaking;
  final VoidCallback onTap;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.state == VoiceState.listening) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip) = switch (widget.state) {
      VoiceState.idle || VoiceState.listening when widget.dinoSpeaking => (
        Icons.volume_up_rounded,
        NeonColors.purple,
        'O Dino está falando',
      ),
      VoiceState.listening => (
        Icons.mic_rounded,
        NeonColors.green,
        'Ouvindo — toque para pausar',
      ),
      VoiceState.processing => (
        Icons.graphic_eq_rounded,
        NeonColors.cyan,
        'Processando',
      ),
      VoiceState.idle => (
        Icons.mic_off_rounded,
        NeonColors.textSecondary,
        'Microfone pausado — toque para ouvir',
      ),
      VoiceState.error || VoiceState.disabled => (
        Icons.mic_off_rounded,
        NeonColors.orange,
        'Permitir microfone',
      ),
    };
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                if (widget.state == VoiceState.listening)
                  BoxShadow(
                    color: color.withValues(alpha: 0.5 * _pulse.value),
                    blurRadius: 6 + 12 * _pulse.value,
                    spreadRadius: 2 * _pulse.value,
                  ),
              ],
            ),
            child: child,
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}

enum _Toy {
  ball('⚽'),
  food('🍎'),
  water('🥤');

  const _Toy(this.emoji);
  final String emoji;
}

/// Something the child drags to the Dino. Bounces gently to invite a
/// touch ([hint]); dropping it on the Dino is handled by its DragTarget.
class _DraggableToy extends StatefulWidget {
  const _DraggableToy({
    required this.toy,
    required this.enabled,
    this.hint = false,
    this.onTap,
    this.onDragStarted,
    this.onThrown,
  });

  final _Toy toy;
  final bool enabled;
  final bool hint;
  final VoidCallback? onTap;
  final VoidCallback? onDragStarted;

  /// Released anywhere but on the Dino (a throw).
  final VoidCallback? onThrown;

  @override
  State<_DraggableToy> createState() => _DraggableToyState();
}

class _DraggableToyState extends State<_DraggableToy>
    with SingleTickerProviderStateMixin {
  Offset? _down;
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Widget _emoji(double size) => Text(
    widget.toy.emoji,
    style: TextStyle(
      fontSize: size,
      shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final child = AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, widget.hint ? -8 * _bounce.value : 0),
        child: child,
      ),
      child: _emoji(widget.hint ? 56 : 40),
    );
    if (!widget.enabled) return Opacity(opacity: 0.4, child: _emoji(40));
    return Draggable<_Toy>(
      data: widget.toy,
      feedback: Material(color: Colors.transparent, child: _emoji(64)),
      childWhenDragging: Opacity(opacity: 0.25, child: _emoji(40)),
      onDragStarted: widget.onDragStarted,
      onDragEnd: (details) {
        if (!details.wasAccepted) widget.onThrown?.call();
      },
      // Draggable wins the gesture arena on touch, so a GestureDetector
      // would never see a tap: a Listener sees every pointer, and a short
      // touch that barely moved counts as a tap.
      child: Listener(
        onPointerDown: (e) => _down = e.position,
        onPointerUp: (e) {
          final down = _down;
          _down = null;
          if (down != null && (e.position - down).distance < 12) {
            widget.onTap?.call();
          }
        },
        child: child,
      ),
    );
  }
}

/// "+10 XP" floating up and fading each time XP is earned.
class _XpBurst extends StatefulWidget {
  const _XpBurst({required this.token, required this.amount});

  final int token;
  final int amount;

  @override
  State<_XpBurst> createState() => _XpBurstState();
}

class _XpBurstState extends State<_XpBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didUpdateWidget(_XpBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token && widget.amount > 0) {
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          if (!_anim.isAnimating) return const SizedBox.shrink();
          final t = Curves.easeOut.transform(_anim.value);
          return Transform.translate(
            offset: Offset(0, -40 - 80 * t),
            child: Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1 + 0.4 * (1 - t),
                child: Text(
                  '+${widget.amount} XP ⭐',
                  style: const TextStyle(
                    color: NeonColors.orange,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
