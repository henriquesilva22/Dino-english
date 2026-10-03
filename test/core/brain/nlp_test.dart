import 'package:dino_english/core/brain/entity/entity_extractor.dart';
import 'package:dino_english/core/brain/nlp/fuzzy_matcher.dart';
import 'package:dino_english/core/brain/nlp/inflection.dart';
import 'package:dino_english/core/brain/nlp/normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brain_test_helpers.dart';

void main() {
  group('Normalizer', () {
    const normalizer = Normalizer();

    test('lowercases, expands contractions and drops punctuation', () {
      final r = normalizer.normalize("  What's WATER mean?? ");
      expect(r.text, 'what is water mean');
      expect(r.isQuestion, isTrue);
    });

    test('keeps accents but fold() removes them', () {
      expect(normalizer.normalize('Água!').text, 'água');
      expect(Normalizer.fold('Água'), 'agua');
    });

    test('shortens stretched letters', () {
      expect(normalizer.normalize('hellooooo').text, 'helloo');
    });
  });

  group('FuzzyMatcher', () {
    const fuzzy = FuzzyMatcher();

    test('counts a swap as one edit', () {
      expect(FuzzyMatcher.distance('dgo', 'dog'), 1);
      expect(FuzzyMatcher.distance('woter', 'water'), 1);
    });

    test('corrects a unique close match', () {
      final r = fuzzy.match('woter', ['water', 'winter', 'dog']);
      expect(r.outcome, FuzzyOutcome.corrected);
      expect(r.best!.value, 'water');
    });

    test('reports ties as ambiguous', () {
      final r = fuzzy.match('bet', ['bed', 'bee', 'dog']);
      expect(r.outcome, FuzzyOutcome.ambiguous);
      expect(r.candidates.map((c) => c.value), containsAll(['bed', 'bee']));
    });

    test('does not guess when nothing is close', () {
      expect(
        fuzzy.match('xylophone', ['dog', 'cat']).outcome,
        FuzzyOutcome.none,
      );
    });
  });

  group('Inflection', () {
    const inflection = Inflection();

    test('base forms', () {
      expect(inflection.baseForms('apples'), contains('apple'));
      expect(inflection.baseForms('strawberries'), contains('strawberry'));
      expect(inflection.baseForms('mice'), contains('mouse'));
      expect(inflection.baseForms('running'), contains('run'));
      expect(inflection.baseForms('dancing'), contains('dance'));
    });

    test('pluralize', () {
      expect(inflection.pluralize('apple'), 'apples');
      expect(inflection.pluralize('strawberry'), 'strawberries');
      expect(inflection.pluralize('sandwich'), 'sandwiches');
      expect(inflection.pluralize('rice'), 'rice');
      expect(inflection.pluralize('mouse'), 'mice');
    });
  });

  group('EntityExtractor', () {
    final extractor = EntityExtractor(seedVocabulary);

    test('exact, plural and Portuguese lookups', () {
      expect(extractor.resolveWord('the word water').entry?.english, 'water');
      expect(extractor.resolveWord('apples').entry?.english, 'apple');
      final pt = extractor.resolveWord('cachorro');
      expect(pt.entry?.english, 'dog');
      expect(pt.viaPortuguese, isTrue);
    });

    test('multi-word terms inside a phrase', () {
      expect(extractor.resolveWord('ice cream').entry?.english, 'ice cream');
      expect(
        extractor.findWordInSentence('i really want ice cream now')?.english,
        'ice cream',
      );
    });

    test('corrects children spelling', () {
      final m = extractor.resolveWord('woter');
      expect(m.kind, WordMatchKind.corrected);
      expect(m.entry?.english, 'water');
    });

    test('asks when the typo is ambiguous', () {
      final m = extractor.resolveWord('bet');
      expect(m.kind, WordMatchKind.ambiguous);
      expect(m.candidates.map((e) => e.english), contains('bed'));
    });

    test('unknown words stay unknown', () {
      expect(extractor.resolveWord('dragon').kind, WordMatchKind.unknown);
    });
  });
}
