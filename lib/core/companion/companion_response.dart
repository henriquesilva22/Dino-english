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
  const CompanionLine(this.text, [this.translation]) : english = null;

  /// A Portuguese sentence with English inserted ("Eu vou WALK
  /// amanhã."): [english] lists the English parts, voiced in English;
  /// the rest is voiced in Portuguese whatever the [VoiceMode]. An empty
  /// list is a plain Portuguese line.
  const CompanionLine.mixed(this.text, {this.english = const []})
    : translation = null;

  /// Parses `*...*` marks as the English parts: `"*Yes!* Muito bem!"`.
  factory CompanionLine.marked(String marked) {
    final parts = marked.split('*');
    final english = [
      for (var i = 1; i < parts.length; i += 2)
        if (parts[i].trim().isNotEmpty) parts[i].trim(),
    ];
    return CompanionLine.mixed(parts.join(), english: english);
  }

  final String text;
  final String? translation;

  /// Non-null for a [CompanionLine.mixed] line.
  final List<String>? english;

  bool get isMixed => english != null;

  /// [text] split into its Portuguese and English stretches, in order
  /// (only for a mixed line; empty stretches dropped).
  List<LineSegment> get segments => _split(trim: true);

  /// [segments] keeping the spaces and punctuation around them, so they
  /// join back into [text] (for drawing).
  List<LineSegment> get displaySegments => _split(trim: false);

  List<LineSegment> _split({required bool trim}) {
    final words = english;
    if (words == null) return [LineSegment(text, isEnglish: true)];
    final spans = <(int, int)>[];
    final lower = text.toLowerCase();
    for (final word in words) {
      final w = word.toLowerCase();
      var from = 0;
      while (true) {
        final at = lower.indexOf(w, from);
        if (at < 0) break;
        final end = at + w.length;
        final bounded =
            (at == 0 || !_isLetter(lower[at - 1])) &&
            (end == lower.length || !_isLetter(lower[end]));
        if (bounded && !spans.any((s) => at < s.$2 && end > s.$1)) {
          spans.add((at, end));
        }
        from = end;
      }
    }
    spans.sort((a, b) => a.$1.compareTo(b.$1));
    final segments = <LineSegment>[];
    var cursor = 0;
    void add(int from, int to, bool isEnglish) {
      final piece = text.substring(from, to);
      if (trim && piece.trim().isEmpty) return;
      if (piece.isEmpty) return;
      segments.add(
        LineSegment(trim ? piece.trim() : piece, isEnglish: isEnglish),
      );
    }

    for (final (start, end) in spans) {
      add(cursor, start, false);
      add(start, end, true);
      cursor = end;
    }
    add(cursor, text.length, false);
    return segments;
  }

  static bool _isLetter(String c) => RegExp(r'[a-zà-ú0-9]').hasMatch(c);
}

/// A stretch of a [CompanionLine] in one language.
class LineSegment {
  const LineSegment(this.text, {required this.isEnglish});

  final String text;
  final bool isEnglish;

  @override
  bool operator ==(Object other) =>
      other is LineSegment &&
      other.text == text &&
      other.isEnglish == isEnglish;

  @override
  int get hashCode => Object.hash(text, isEnglish);

  @override
  String toString() => '${isEnglish ? 'en' : 'pt'}:"$text"';
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
