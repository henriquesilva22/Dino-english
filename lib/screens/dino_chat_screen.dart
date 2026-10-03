import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/brain/context/conversation_context.dart';
import '../core/brain/model/dino_enums.dart';
import '../core/companion/companion_engine.dart';
import '../core/companion/companion_response.dart';
import '../core/companion/companion_state.dart';
import '../core/companion/dino_model_clips.dart';
import '../core/single_navigation_guard.dart';
import '../providers/dino_chat_providers.dart';
import '../providers/navigation_providers.dart';
import '../providers/speech_providers.dart';
import '../theme/neon_colors.dart';
import '../widgets/exit_top_bar.dart';
import '../widgets/neon_background.dart';
import '../widgets/companion/dino_animated_model.dart';
import 'exam_screen.dart';
import 'sentence_builder_screen.dart';
import 'word_slash_game_screen.dart';

const String _kDinoBabyAsset = 'assets/models/dino/Dino_Baby_v2_animado.glb';

/// "Brincar com o Dino": the virtual companion. The child talks to the
/// Dino by text, feeds it, gives it water, plays and puts it to bed --
/// all offline through the `CompanionEngine`. This widget only renders
/// [DinoChatState] and forwards taps; no conversation rule lives here.
class DinoChatScreen extends ConsumerStatefulWidget {
  const DinoChatScreen({super.key});

  @override
  ConsumerState<DinoChatScreen> createState() => _DinoChatScreenState();
}

class _DinoChatScreenState extends ConsumerState<DinoChatScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
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
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) unawaited(ref.read(companionVoiceServiceProvider).stop());
      },
      child: Scaffold(
        body: NeonBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExitTopBar(
                  title: 'Brincar com o Dino',
                  onExit: () => Navigator.of(context).pop(),
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
                          status: chat.isListening
                              ? '🎤 Ouvindo...'
                              : chat.isTranscribing || chat.isThinking
                              ? '...'
                              : null,
                        ),
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
                  onCare: (care) => unawaited(notifier.care(care)),
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
                      if (chat.voiceAvailable)
                        _MicButton(
                          enabled:
                              (canAct && !chat.isTranscribing) ||
                              chat.isListening,
                          isListening: chat.isListening,
                          onStart: () => unawaited(notifier.startListening()),
                          onStop: () => unawaited(notifier.stopListening()),
                          onCancel: () => unawaited(notifier.cancelListening()),
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

/// The Dino in the middle of the screen (3D, animated by the engine), a
/// small emoji for what the model has no clip for, and the speech bubble.
class _PetStage extends ConsumerWidget {
  const _PetStage({
    required this.animation,
    required this.rest,
    required this.response,
    required this.status,
  });

  final CompanionAnimation animation;

  /// Pose for the pet's needs when nothing is happening.
  final CompanionAnimation rest;
  final CompanionResponse? response;

  /// "Ouvindo..." / "..." instead of the reply, or null.
  final String? status;

  static const _clips = DinoClipMapper();

  /// Props for what the model's own clips can't show (eating, water...).
  static const Map<CompanionAnimation, String> _reaction = {
    CompanionAnimation.hungry: '🍽️',
    CompanionAnimation.thirsty: '💧',
    CompanionAnimation.sleepy: '🥱',
    CompanionAnimation.eating: '😋',
    CompanionAnimation.drinking: '🥤',
    CompanionAnimation.playing: '⚽',
    CompanionAnimation.sleeping: '💤',
    CompanionAnimation.celebrating: '🎉',
    CompanionAnimation.listening: '👂',
    CompanionAnimation.thinking: '💭',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reaction = _reaction[animation];
    final voice = ref.watch(companionVoiceServiceProvider);
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The mouth moves while the TTS is actually talking.
              ValueListenableBuilder<Object?>(
                valueListenable: voice.speaking,
                builder: (context, utterance, _) => DinoAnimatedModel(
                  modelAsset: _kDinoBabyAsset,
                  height: 240,
                  plan: _clips.plan(
                    animation: animation,
                    rest: rest,
                    speaking: utterance != null,
                  ),
                ),
              ),
              if (reaction != null)
                Positioned(
                  right: 40,
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
        _SpeechBubble(response: response, status: status),
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

/// Push-to-talk: hold to speak, release to send, slide off to cancel.
class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.enabled,
    required this.isListening,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
  });

  final bool enabled;
  final bool isListening;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final color = isListening ? NeonColors.red : NeonColors.green;
    return Tooltip(
      message: 'Segure para falar',
      child: Listener(
        onPointerDown: enabled ? (_) => onStart() : null,
        onPointerUp: enabled ? (_) => onStop() : null,
        onPointerCancel: enabled ? (_) => onCancel() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isListening ? 56 : 48,
          height: isListening ? 56 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: enabled ? 0.22 : 0.06),
            border: Border.all(
              color: color.withValues(alpha: enabled ? 0.9 : 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
            color: enabled ? color : NeonColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
