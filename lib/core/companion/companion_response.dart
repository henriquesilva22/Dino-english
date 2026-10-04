import '../brain/model/dino_enums.dart';
import 'companion_state.dart';
import 'engine/companion_entity.dart';
import 'engine/companion_intent.dart';

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

  /// Walking somewhere (to its bed).
  walking,
  talking,
  celebrating,

  /// Push-to-talk: the child is speaking to the Dino.
  listening,

  /// The child's voice is being transcribed.
  thinking,
}

/// One thing the Dino says: English [text] (spoken) and an optional
/// Portuguese [translation] (subtitle only).
/// Which voice reads a reply. The Portuguese meaning is always on screen;
/// the Dino only *speaks* Portuguese when there is a reason.
enum VoiceMode {
  /// The usual: English spoken, Portuguese shown.
  english,

  /// Spoken in Portuguese (the child asked for it / didn't understand).
  portuguese,

  /// English, then its Portuguese meaning (translation, explanation).
  bilingual,
}

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
    this.detectedWords = const [],
    this.detectedEntity,
    this.suggestions = const [],
    this.activity,
    this.isWaitingForAnswer = false,
    this.shouldListenAgain = true,
    this.voice = VoiceMode.english,
    this.coinReward = 0,
  });

  final List<CompanionLine> lines;
  final CompanionEmotion emotion;
  final CompanionAnimation animation;

  /// The pet's state after this interaction (already persisted).
  final CompanionState state;

  /// How the child's sentence was understood (null for care buttons).
  final CompanionIntent? intent;

  /// The care applied, if any (button or "come uma maçã").
  final DinoCare? care;

  /// XP actually granted by this interaction.
  final int xpReward;

  /// English words taught/practised in this interaction.
  final List<String> vocabulary;

  /// Official English words heard in the child's sentence.
  final List<String> detectedWords;

  /// The thing the sentence was about (APPLE, DOG...).
  final CompanionEntity? detectedEntity;

  /// Quick replies for the Dino's question, if it asked one.
  final List<String> suggestions;

  /// An app activity the Dino wants to open (Word Slash, Estudar...).
  final DinoActivity? activity;
  final bool isWaitingForAnswer;

  /// False when the conversation pauses (goodbye, opening a game): the
  /// microphone stops until the child taps it.
  final bool shouldListenAgain;

  /// How the voice reads [lines].
  final VoiceMode voice;

  /// 🪙 coins earned (the controller adds them to the wallet).
  final int coinReward;

  /// Whether the voice should say [englishText].
  bool get shouldSpeak => lines.isNotEmpty;

  /// Everything said, in English (what TTS reads) -- always first.
  String get englishText => lines.map((l) => l.text).join(' ');

  /// The Portuguese subtitles, or null when there are none.
  String? get portugueseText {
    final parts = [
      for (final l in lines)
        if (l.translation != null) l.translation!,
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Short names kept for the UI and tests.
  String get text => englishText;
  String? get translation => portugueseText;

  CompanionResponse copyWith({
    CompanionIntent? intent,
    CompanionAnimation? animation,
    List<String>? detectedWords,
    CompanionEntity? detectedEntity,
    bool? shouldListenAgain,
    VoiceMode? voice,
    List<CompanionLine>? lines,
  }) => CompanionResponse(
    lines: lines ?? this.lines,
    emotion: emotion,
    animation: animation ?? this.animation,
    state: state,
    intent: intent ?? this.intent,
    care: care,
    xpReward: xpReward,
    vocabulary: vocabulary,
    detectedWords: detectedWords ?? this.detectedWords,
    detectedEntity: detectedEntity ?? this.detectedEntity,
    suggestions: suggestions,
    activity: activity,
    isWaitingForAnswer: isWaitingForAnswer,
    shouldListenAgain: shouldListenAgain ?? this.shouldListenAgain,
    voice: voice ?? this.voice,
    coinReward: coinReward,
  );
}
