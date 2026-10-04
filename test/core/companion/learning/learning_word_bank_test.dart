import 'dart:math';

import 'package:dino_english/core/companion/learning/hybrid_sentence.dart';
import 'package:dino_english/core/companion/learning/learning_word.dart';
import 'package:flutter_test/flutter_test.dart';

import 'learning_test_helpers.dart';

void main() {
  final bank = learningBank;

  test('the first bank has at least 100 useful words, no duplicates', () {
    expect(bank.words.length, greaterThanOrEqualTo(100));
    final names = bank.words.map((w) => w.english).toList();
    expect(names.toSet().length, names.length);
    for (final w in [
      'walk', 'run', 'jump', 'eat', 'drink', 'play', 'sleep', 'happy', //
      'tired', 'hungry', 'ball', 'book', 'water', 'apple', 'bread',
    ]) {
      expect(bank.byEnglish(w), isNotNull, reason: w);
    }
    expect(bank.byEnglish('walk')!.portuguese, 'caminhar');
    expect(bank.byEnglish('sleepy')!.portuguese, 'com sono');
  });

  test('every word fits in at least 3 sentences, all well filled', () {
    for (final word in bank.words) {
      final templates = bank.templatesFor(word);
      expect(templates.length, greaterThanOrEqualTo(3), reason: word.english);
      for (final t in templates) {
        final text = HybridSentenceBuilder.fill(t.text, word);
        expect(text, contains(word.display), reason: t.text);
        expect(text, isNot(contains('{')), reason: '$word: ${t.text}');
        // One English word per sentence: the rest is Portuguese.
        expect(
          RegExp(r'\b[A-Z]{2,}\b').allMatches(text).length,
          word.display.split(' ').length,
          reason: text,
        );
      }
    }
  });

  test('nouns get their article; verbs never land in noun sentences', () {
    final apple = bank.byEnglish('apple')!;
    final book = bank.byEnglish('book')!;
    expect(apple.type, WordType.noun);
    expect(
      HybridSentenceBuilder.fill('Eu quero {um} {WORD}.', apple),
      'Eu quero uma APPLE.',
    );
    expect(
      HybridSentenceBuilder.fill('Eu quero {um} {WORD}.', book),
      'Eu quero um BOOK.',
    );
    final verbOnly = bank
        .templatesFor(bank.byEnglish('jump')!)
        .map((t) => t.text);
    expect(verbOnly, isNot(contains('Eu quero {um} {WORD}.')));
    expect(verbOnly, contains('Eu vou {WORD} amanhã.'));
    // "Eu vou APPLE amanhã" can't happen.
    expect(
      bank.templatesFor(apple).map((t) => t.text),
      isNot(contains('Eu vou {WORD} amanhã.')),
    );
  });

  test('walk comes in several situations', () {
    final builder = HybridSentenceBuilder(bank, random: Random(3));
    final walk = bank.byEnglish('walk')!;
    final seen = {for (var i = 0; i < 40; i++) builder.build(walk)!.text};
    expect(
      seen,
      containsAll(['Eu vou WALK amanhã.', 'Vamos WALK até a casa.']),
    );
    expect(seen.length, greaterThanOrEqualTo(5));
  });

  test('lookups: case, punctuation and simple inflections', () {
    expect(bank.byEnglish('Walk!')!.english, 'walk');
    expect(bank.byEnglish('walking')!.english, 'walk');
    expect(bank.byEnglish('apples')!.english, 'apple');
    expect(bank.byEnglish('thank you')!.english, 'thank you');
    expect(bank.byEnglish('xyzzy'), isNull);
    expect(bank.byAlias('wok')!.english, 'walk');
  });

  test('lesson phrases fill the word and mark the English parts', () {
    final walk = bank.byEnglish('walk')!;
    final line = bank.phrase('explain', Random(0), word: walk)!;
    expect(line.text, contains('WALK'));
    expect(line.text, contains('caminhar'));
    expect(line.english, ['WALK']);
    expect(line.text, isNot(contains('*')));
    for (final key in [
      'explain',
      'repeat_prompt',
      'success_1',
      'almost',
      'give_up',
      'unknown_word',
    ]) {
      expect(bank.hasPhrase(key), isTrue, reason: key);
    }
  });
}
