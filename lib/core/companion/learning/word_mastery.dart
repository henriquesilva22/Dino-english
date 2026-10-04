import 'dart:convert';

import '../../brain/memory/dino_memory.dart';
import '../../utils/date_key.dart';

/// How well the child knows a word met in the Dino's sentences.
enum MasteryLevel {
  /// Never explained.
  fresh,

  /// Explained once ("WALK significa caminhar").
  knowing,

  /// Repeated correctly.
  practicing,

  /// Repeated correctly on two different days.
  learned,

  /// On three different days: only comes back now and then, to review.
  mastered,
}

/// The progress of one word: level, repetitions and when it was last met
/// -- enough for spaced repetition (a word comes back after 1, 3, 7
/// days as it is learned).
class WordMastery {
  const WordMastery({
    this.level = MasteryLevel.fresh,
    this.timesSeen = 0,
    this.correctRepetitions = 0,
    this.incorrectRepetitions = 0,
    this.lastSeen,
    this.lastLevelUp,
  });

  factory WordMastery.fromJson(Map<String, dynamic> json) => WordMastery(
    level:
        MasteryLevel.values[((json['level'] as num?)?.toInt() ?? 0).clamp(
          0,
          MasteryLevel.values.length - 1,
        )],
    timesSeen: (json['seen'] as num?)?.toInt() ?? 0,
    correctRepetitions: (json['correct'] as num?)?.toInt() ?? 0,
    incorrectRepetitions: (json['incorrect'] as num?)?.toInt() ?? 0,
    lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? ''),
    lastLevelUp: DateTime.tryParse(json['lastLevelUp'] as String? ?? ''),
  );

  final MasteryLevel level;
  final int timesSeen;
  final int correctRepetitions;
  final int incorrectRepetitions;
  final DateTime? lastSeen;
  final DateTime? lastLevelUp;

  /// Days before the word is due again, by level.
  static const List<int> reviewDays = [0, 0, 1, 3, 7];

  Map<String, dynamic> toJson() => {
    'level': level.index,
    'seen': timesSeen,
    'correct': correctRepetitions,
    'incorrect': incorrectRepetitions,
    if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
    if (lastLevelUp != null) 'lastLevelUp': lastLevelUp!.toIso8601String(),
  };

  /// Whether it's time to meet the word again.
  bool isDue(DateTime now) {
    final seen = lastSeen;
    if (seen == null) return true;
    return !now.isBefore(seen.add(Duration(days: reviewDays[level.index])));
  }

  WordMastery copyWith({
    MasteryLevel? level,
    int? timesSeen,
    int? correctRepetitions,
    int? incorrectRepetitions,
    DateTime? lastSeen,
    DateTime? lastLevelUp,
  }) => WordMastery(
    level: level ?? this.level,
    timesSeen: timesSeen ?? this.timesSeen,
    correctRepetitions: correctRepetitions ?? this.correctRepetitions,
    incorrectRepetitions: incorrectRepetitions ?? this.incorrectRepetitions,
    lastSeen: lastSeen ?? this.lastSeen,
    lastLevelUp: lastLevelUp ?? this.lastLevelUp,
  );
}

/// Reads and moves [WordMastery] in the Dino's long-term memory (one
/// [DinoMemoryKind.wordMastery] row per word, offline). A wrong
/// repetition never lowers anything: it's practice, not a test.
class WordMasteryTracker {
  WordMasteryTracker(this._memory, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DinoMemoryBank _memory;
  final DateTime Function() _clock;

  WordMastery of(String english) {
    final raw = _memory.wordMastery(english);
    if (raw == null) return const WordMastery();
    try {
      return WordMastery.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const WordMastery();
    }
  }

  /// The word appeared in one of the Dino's sentences.
  Future<WordMastery> seen(String english) {
    final m = of(english);
    return _save(
      english,
      m.copyWith(timesSeen: m.timesSeen + 1, lastSeen: _clock()),
    );
  }

  /// The Dino explained it. Asking again for a word already learned
  /// means it was forgotten a little: one level back, to review it more.
  Future<WordMastery> explained(String english) {
    final m = of(english);
    final level = switch (m.level) {
      MasteryLevel.fresh => MasteryLevel.knowing,
      MasteryLevel.learned => MasteryLevel.practicing,
      MasteryLevel.mastered => MasteryLevel.learned,
      final other => other,
    };
    return _save(english, m.copyWith(level: level, lastSeen: _clock()));
  }

  /// Repeated correctly. Up to "practicing" right away; each next level
  /// needs another day, so "learned" means remembered over time.
  Future<WordMastery> correct(String english) {
    final now = _clock();
    final m = of(english);
    final sameDay =
        m.lastLevelUp != null && dateKeyFor(m.lastLevelUp!) == dateKeyFor(now);
    final canRise =
        m.level.index < MasteryLevel.practicing.index ||
        (!sameDay && m.level != MasteryLevel.mastered);
    final level = canRise ? MasteryLevel.values[m.level.index + 1] : m.level;
    return _save(
      english,
      m.copyWith(
        level: level,
        correctRepetitions: m.correctRepetitions + 1,
        lastSeen: now,
        lastLevelUp: canRise ? now : null,
      ),
    );
  }

  Future<WordMastery> incorrect(String english) {
    final m = of(english);
    return _save(
      english,
      m.copyWith(
        incorrectRepetitions: m.incorrectRepetitions + 1,
        lastSeen: _clock(),
      ),
    );
  }

  Future<WordMastery> _save(String english, WordMastery mastery) async {
    await _memory.saveWordMastery(
      english,
      jsonEncode(mastery.toJson()),
      confidence: mastery.level.index / MasteryLevel.mastered.index,
    );
    return mastery;
  }
}
