import 'dart:math';

import '../companion_response.dart';
import 'learning_word.dart';
import 'learning_word_bank.dart';
import 'word_mastery.dart';

/// "Eu vou WALK amanhã." -- a Portuguese sentence the child understands
/// with one English [target] word in it.
class HybridSentence {
  const HybridSentence({
    required this.text,
    required this.target,
    required this.template,
  });

  final String text;
  final LearningWord target;
  final SentenceTemplate template;

  /// As a reply line: Portuguese voice, [target] in the English voice.
  CompanionLine toLine() =>
      CompanionLine.mixed(text, english: [target.display]);

  @override
  String toString() => 'HybridSentence($text)';
}

/// Builds [HybridSentence]s from the bank's templates -- never random
/// words in random slots: a verb only goes in verb sentences, a noun
/// gets its article ("uma APPLE", "um BOOK").
class HybridSentenceBuilder {
  HybridSentenceBuilder(this._bank, {Random? random})
    : _random = random ?? Random();

  final LearningWordBank _bank;
  final Random _random;

  /// Last template used per word: the same word comes back in another
  /// sentence.
  final Map<String, String> _lastTemplate = {};

  /// Words used lately (newest last), so the Dino doesn't keep one word.
  final List<String> _recent = [];
  static const int _recentWindow = 6;

  /// A sentence with [word] for a child at [level] (1 beginner .. 3).
  /// Prefers sentences of that level, then simpler ones; a word without
  /// any sentence gets null.
  HybridSentence? build(LearningWord word, {int level = 1}) {
    final all = _bank.templatesFor(word);
    if (all.isEmpty) return null;
    var pool = all.where((t) => t.level == level).toList();
    for (var l = level - 1; pool.isEmpty && l >= 1; l--) {
      pool = all.where((t) => t.level == l).toList();
    }
    if (pool.isEmpty) pool = all;
    final last = _lastTemplate[word.english];
    if (pool.length > 1) pool = pool.where((t) => t.text != last).toList();
    final template = pool[_random.nextInt(pool.length)];
    _lastTemplate[word.english] = template.text;
    _remember(word);
    return HybridSentence(
      text: fill(template.text, word),
      target: word,
      template: template,
    );
  }

  /// [template] with [word] in it: `{WORD}` -> `WALK`, and the
  /// noun's gender: `{um}` (um/uma), `{o}` (o/a), `{O}` (O/A), `{meu}`
  /// (meu/minha), `{seu}` (seu/sua).
  static String fill(String template, LearningWord word) {
    final f = word.feminine;
    return template
        .replaceAll('{WORD}', word.display)
        .replaceAll('{um}', f ? 'uma' : 'um')
        .replaceAll('{o}', f ? 'a' : 'o')
        .replaceAll('{O}', f ? 'A' : 'O')
        .replaceAll('{meu}', f ? 'minha' : 'meu')
        .replaceAll('{seu}', f ? 'sua' : 'seu');
  }

  /// The next word to teach: new words at the child's level and words due
  /// for review are likely; words already mastered and not due rarely
  /// come; words used in the last few sentences never. [context]
  /// (`food`, `play`, `sleep`...) keeps it on topic when possible.
  LearningWord? pick({
    required WordMastery Function(String english) masteryOf,
    required DateTime now,
    int level = 1,
    String? context,
  }) {
    final candidates = [
      for (final w in _bank.words)
        if (!_recent.contains(w.english) && _bank.templatesFor(w).isNotEmpty) w,
    ];
    if (candidates.isEmpty) return null;
    final onTopic = context == null
        ? const <LearningWord>[]
        : candidates
              .where(
                (w) => w.contexts.contains(context) || w.category == context,
              )
              .toList();
    final pool = onTopic.isNotEmpty ? onTopic : candidates;

    double weight(LearningWord w) {
      final m = masteryOf(w.english);
      final due = m.isDue(now);
      final weight = switch (m.level) {
        MasteryLevel.fresh => w.difficulty <= level ? 3.0 : 0.4,
        MasteryLevel.knowing || MasteryLevel.practicing => due ? 4.0 : 1.0,
        MasteryLevel.learned => due ? 3.0 : 0.3,
        MasteryLevel.mastered => due ? 2.0 : 0.1,
      };
      return weight;
    }

    final weights = [for (final w in pool) weight(w)];
    final total = weights.fold(0.0, (a, b) => a + b);
    var roll = _random.nextDouble() * total;
    for (var i = 0; i < pool.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return pool[i];
    }
    return pool.last;
  }

  void _remember(LearningWord word) {
    _recent
      ..remove(word.english)
      ..add(word.english);
    if (_recent.length > _recentWindow) _recent.removeAt(0);
  }
}
