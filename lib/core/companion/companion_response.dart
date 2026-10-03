import '../brain/intent/intent.dart';
import '../brain/model/dino_enums.dart';
import 'companion_state.dart';

/// How the Dino feels right now (drives its face/idle pose).
enum CompanionEmotion { happy, content, sad, hungry, thirsty, sleepy, excited }

/// What the pet view should play. Names are intent, not clip names: a
/// 2D sprite sheet, the 3D model or plain emoji each map them their own
/// way, so the engine never changes when the visuals do.
enum CompanionAnimation {
  idle,
  happy,
  sad,
  hungry,
  thirsty,
  sleepy,
  eating,
  drinking,
  playing,
  sleeping,
  talking,
  celebrating,

  /// Push-to-talk: the child is speaking to the Dino.
  listening,

  /// The child's voice is being transcribed.
  thinking,
}

/// One thing the Dino says: English [text] (spoken) and an optional
/// Portuguese [translation] (subtitle only).
class CompanionLine {
  const CompanionLine(this.text, [this.translation]);

  final String text;
  final String? translation;
}

/// Everything the UI (and later voice/3D) needs from one interaction.
/// The UI never decides what the Dino says -- it only renders this.
class CompanionResponse {
  const CompanionResponse({
    required this.lines,
    required this.emotion,
    required this.animation,
    required this.state,
    this.intent,
    this.care,
    this.xpReward = 0,
    this.vocabulary = const [],
    this.suggestions = const [],
    this.activity,
    this.isWaitingForAnswer = false,
  });

  final List<CompanionLine> lines;
  final CompanionEmotion emotion;
  final CompanionAnimation animation;

  /// The pet's state after this interaction (already persisted).
  final CompanionState state;

  /// How the child's text was understood (null for care buttons).
  final DinoIntent? intent;

  /// The care applied, if any (button or "eat an apple").
  final DinoCare? care;

  /// XP actually granted by this interaction.
  final int xpReward;

  /// English words taught/practised in this interaction.
  final List<String> vocabulary;

  /// Quick replies for the Dino's question, if it asked one.
  final List<String> suggestions;

  /// An app activity the Dino wants to open (Word Slash, Estudar...).
  final DinoActivity? activity;
  final bool isWaitingForAnswer;

  /// Everything said, in English (what TTS reads).
  String get text => lines.map((l) => l.text).join(' ');

  /// The Portuguese subtitles, or null when there are none.
  String? get translation {
    final parts = [
      for (final l in lines)
        if (l.translation != null) l.translation!,
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }
}
