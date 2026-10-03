import 'dart:math';

import 'context/conversation_context.dart';
import 'dialogue/dialogue_action.dart';
import 'dialogue/dialogue_manager.dart';
import 'dialogue/response_generator.dart';
import 'entity/entity_extractor.dart';
import 'intent/intent.dart';
import 'intent/intent_detector.dart';
import 'memory/dino_memory.dart';
import 'model/dino_status.dart';
import 'nlp/normalizer.dart';
import 'vocabulary/official_vocabulary.dart';

/// What the Dino does in reply to one input.
class DinoReply {
  const DinoReply({required this.actions, required this.intent});

  final List<DialogueAction> actions;

  /// How the input was understood (useful for debugging/analytics).
  final IntentResult intent;

  /// Everything the Dino says, in order, for TTS.
  List<String> get spokenLines => [
    for (final a in actions)
      if (a is SpeakAction) a.text else if (a is AskAction) a.text,
  ];

  String get spokenText => spokenLines.join(' ');

  bool get isWaitingForAnswer => actions.any((a) => a is WaitForAnswerAction);
}

/// The Dino's offline conversational brain:
///
/// `input -> Normalizer -> Tokenizer -> IntentDetector -> EntityExtractor
///  -> ConversationContext -> DialogueManager/ResponseGenerator
///  -> DialogueActions (TTS, animation, rewards...) -> DinoMemoryBank`
///
/// 100% offline and rule-based: no network, no LLM. Pure Dart -- the
/// Flutter side (TTS, 3D model, navigation, XP) only executes the returned
/// [DialogueAction]s.
class DinoBrain {
  DinoBrain({
    required OfficialVocabulary vocabulary,
    required DinoMemoryBank memory,
    DinoStatus status = const DinoStatus(),
    Random? random,
    DateTime Function()? clock,
  }) : _normalizer = const Normalizer(),
       _detector = IntentDetector(),
       _clock = clock ?? DateTime.now,
       context = ConversationContext(status: status) {
    _manager = DialogueManager(
      vocabulary: vocabulary,
      memory: memory,
      extractor: EntityExtractor(vocabulary),
      detector: _detector,
      generator: ResponseGenerator(random: random),
      random: random,
    );
  }

  final Normalizer _normalizer;
  final IntentDetector _detector;
  final DateTime Function() _clock;
  late final DialogueManager _manager;

  /// Short-term state of this conversation (exposed for tests and for the
  /// future needs system).
  final ConversationContext context;

  /// The Dino speaks first when the chat opens.
  Future<DinoReply> start() async {
    final actions = await _manager.opening(context);
    _recordDino(actions);
    return DinoReply(
      actions: actions,
      intent: const IntentResult(DinoIntent.greeting, rule: 'opening'),
    );
  }

  Future<DinoReply> respond(String text) async {
    final input = _normalizer.normalize(text);
    final intent = _detector.detect(input, pending: context.pending);
    context.addTurn(
      ConversationTurn(
        speaker: Speaker.child,
        text: text,
        at: _clock(),
        intent: intent.intent,
      ),
    );
    final actions = await _manager.handle(
      input: input,
      intent: intent,
      context: context,
    );
    _recordDino(actions);
    return DinoReply(actions: actions, intent: intent);
  }

  /// Push a fresh snapshot from the needs/XP systems.
  void updateStatus(DinoStatus status) => context.status = status;

  void _recordDino(List<DialogueAction> actions) {
    final text = [
      for (final a in actions)
        if (a is SpeakAction) a.text else if (a is AskAction) a.text,
    ].join(' ');
    if (text.isEmpty) return;
    context.addTurn(
      ConversationTurn(speaker: Speaker.dino, text: text, at: _clock()),
    );
  }
}
