import 'package:dino_english/core/companion/engine/text_normalizer.dart';
import 'package:dino_english/core/companion/learning/word_meaning_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const detector = WordMeaningRequestDetector();
  const normalizer = TextNormalizer();

  MeaningRequest? detect(String said, {bool fresh = false}) =>
      detector.detect(normalizer.normalize(said).folded, lastWordFresh: fresh);

  test('asking about a named word, many ways', () {
    for (final said in [
      'O que é walk?',
      'O que significa walk?',
      'Walk significa o quê?',
      'O que quer dizer walk?',
      'Não sei o que é walk.',
      'Qual o significado de walk?',
      'Essa palavra walk',
      'Dino, o que é a palavra walk?',
    ]) {
      final r = detect(said);
      expect(r?.word, 'walk', reason: said);
    }
  });

  test('"essa palavra" always means the word the Dino just used', () {
    for (final said in ['Que palavra é essa?', 'Essa palavra?']) {
      expect(detect(said)?.refersToLastWord, isTrue, reason: said);
    }
  });

  test(
    '"o que é isso?" / "não entendi": the last word, only right after it',
    () {
      for (final said in [
        'O que é isso?',
        'O que significa?',
        'O que ele quis dizer?',
        'Não entendi',
        'Como assim?',
      ]) {
        expect(
          detect(said, fresh: true)?.refersToLastWord,
          isTrue,
          reason: said,
        );
        // Otherwise the whole last reply is meant (handled elsewhere).
        expect(detect(said), isNull, reason: said);
      }
    },
  );

  test('ordinary sentences are not meaning questions', () {
    for (final said in [
      'Você gosta de maçã?',
      'Vamos brincar',
      'O que você comeu hoje?',
      'Eu quero água',
      'o que é que você vai fazer amanhã de manhã',
    ]) {
      expect(detect(said), isNull, reason: said);
    }
  });
}
