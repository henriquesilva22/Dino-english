import 'package:dino_english/core/companion/companion_response.dart';
import 'package:dino_english/core/companion/companion_state.dart';
import 'package:dino_english/core/companion/engine/companion_intent.dart';
import 'package:dino_english/core/companion/learning/bilingual_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'learning_test_helpers.dart';

void main() {
  final presenter = BilingualPresenter(learningBank);

  CompanionResponse reply(
    List<CompanionLine> lines, {
    CompanionIntent? intent,
    List<String> vocabulary = const [],
  }) => CompanionResponse(
    lines: lines,
    emotion: CompanionEmotion.happy,
    animation: CompanionAnimation.happy,
    state: CompanionState.initial(DateTime(2026)),
    intent: intent,
    vocabulary: vocabulary,
  );

  test('Portuguese with one English word, no translation on screen', () {
    final r = presenter.present(
      reply(const [
        CompanionLine("I'm hungry!", 'Estou com fome!'),
        CompanionLine('Yummy! Thank you!', 'Que delícia! Obrigado!'),
      ]),
    );
    expect(r.lines[0].text, 'Estou HUNGRY!');
    expect(r.lines[0].english, ['HUNGRY']);
    // Only one English word per reply: the next line stays Portuguese.
    expect(r.lines[1].text, 'Que delícia! Obrigado!');
    expect(r.lines[1].english, isEmpty);
    expect(r.portugueseText, isNull);
  });

  test('the word the reply is about wins ("Vamos comer BREAD!")', () {
    final r = presenter.present(
      reply(
        const [CompanionLine("Let's eat bread!", 'Vamos comer pão!')],
        vocabulary: ['bread'],
      ),
    );
    expect(r.lines.single.text, 'Vamos comer BREAD!');
  });

  test('English quoted in the Portuguese is voiced in English', () {
    final r = presenter.present(
      reply(const [CompanionLine('Say: apple!', 'Diga: apple!')]),
    );
    expect(r.lines.single.text, 'Diga: APPLE!');
    expect(
      r.lines.single.segments.firstWhere((x) => x.text == 'APPLE').isEnglish,
      isTrue,
    );
  });

  test('lessons, translations and quiz questions are left as asked', () {
    for (final intent in [
      CompanionIntent.learnWord,
      CompanionIntent.translateWord,
      CompanionIntent.requestTranslation,
    ]) {
      final r = presenter.present(
        reply(const [
          CompanionLine('Water means água.', 'Water significa água.'),
        ], intent: intent),
      );
      expect(r.lines.single.text, 'Water means água.', reason: '$intent');
    }
    // A quiz never gets its answer swapped in: "cachorro" stays.
    final quiz = presenter.present(
      reply(const [
        CompanionLine(
          'How do you say "cachorro" in English?',
          'Como se diz "cachorro" em inglês?',
        ),
      ]),
    );
    expect(quiz.lines.single.text, isNot(contains('DOG')));
    expect(quiz.lines.single.text, contains('cachorro'));
  });

  test('words that would break the sentence are never swapped', () {
    final r = presenter.present(
      reply(const [CompanionLine('No, thanks!', 'Não, valeu!')]),
    );
    expect(r.lines.single.text, 'Não, valeu!');
    expect(r.lines.single.english, isEmpty);
  });

  test('presenting twice changes nothing more', () {
    final once = presenter.present(
      reply(const [CompanionLine("Let's play!", 'Vamos brincar!')]),
    );
    final twice = presenter.present(once);
    expect(twice.lines.single.text, once.lines.single.text);
    expect(once.lines.single.text, 'Vamos PLAY!');
  });

  test('plural nouns count ("Eu adoro maçãs" -> APPLE)', () {
    final r = presenter.present(
      reply(const [CompanionLine('I love apples!', 'Eu adoro maçãs!')]),
    );
    expect(r.lines.single.english, hasLength(1));
  });
}
