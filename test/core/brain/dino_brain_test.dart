import 'package:dino_english/core/brain/context/conversation_context.dart';
import 'package:dino_english/core/brain/dialogue/dialogue_action.dart';
import 'package:dino_english/core/brain/intent/intent.dart';
import 'package:dino_english/core/brain/memory/dino_memory.dart';
import 'package:dino_english/core/brain/model/dino_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brain_test_helpers.dart';

void main() {
  group('word questions', () {
    for (final phrase in [
      'What does water mean?',
      'What is water?',
      'What means water?',
      'What does the word water mean?',
      'water',
    ]) {
      test('"$phrase" -> Water means água.', () async {
        final (brain, _, _) = await newBrain();
        final reply = await brain.respond(phrase);
        expect(reply.spokenText, 'Water means água.');
      });
    }

    test('several senses are all explained (light = luz / leve)', () async {
      final (brain, _, _) = await newBrain();
      final reply = await brain.respond('What does light mean?');
      expect(reply.spokenText, 'Light means luz. It can also mean leve.');
    });

    test('Portuguese -> English translation', () async {
      final (brain, _, _) = await newBrain();
      final reply = await brain.respond('How do you say cachorro in English?');
      expect(reply.spokenText, 'Cachorro is dog in English.');
    });

    test(
      'example sentence, then "another example" uses the topic word',
      () async {
        final (brain, _, _) = await newBrain();
        final first = await brain.respond('Give me an example with dog');
        expect(first.spokenText, contains('The dog is very friendly.'));
        final again = await brain.respond('another example');
        expect(again.spokenText, contains('dog'));
      },
    );

    test('a misspelling is corrected (woter -> water)', () async {
      final (brain, _, _) = await newBrain();
      final reply = await brain.respond('what does woter mean');
      expect(reply.spokenText, contains('Water means água.'));
    });

    test('an ambiguous misspelling asks for confirmation first', () async {
      final (brain, _, _) = await newBrain();
      final ask = await brain.respond('what does bet mean');
      expect(ask.spokenText, startsWith('Did you mean'));
      expect(brain.context.pending, isA<ConfirmWordQuestion>());

      final answer = await brain.respond('bed');
      expect(answer.intent.intent, DinoIntent.confirmWord);
      expect(answer.spokenText, 'Bed means cama.');
      expect(brain.context.pending, isNull);
    });
  });

  group('context and memory', () {
    test('Dino asks, child answers "Apple.", Dino understands', () async {
      final (brain, memory, _) = await newBrain();
      await memory.rememberFact('child_name', 'Ana');

      final opening = await brain.start();
      expect(opening.spokenText, contains('What is your favorite food?'));

      final reply = await brain.respond('Apple.');
      expect(reply.spokenText, contains('You like apples!'));
      expect(memory.preference('food'), 'apple');
    });

    test('learns the child name, then asks favourites', () async {
      final (brain, memory, _) = await newBrain();
      final opening = await brain.start();
      expect(opening.spokenText, contains('What is your name?'));

      final reply = await brain.respond('Ana');
      expect(reply.spokenText, contains('Nice to meet you, Ana!'));
      expect(reply.spokenText, contains('What is your favorite food?'));
      expect(memory.fact('child_name'), 'Ana');
    });

    test('small talk is not stored as memory', () async {
      final (brain, _, store) = await newBrain();
      await brain.respond('hello');
      await brain.respond('thank you');
      await brain.respond('How are you?');
      expect(await store.loadAll(), isEmpty);
    });
  });

  group('official vocabulary is never overwritten', () {
    test('a wrong quiz answer is corrected, not learned', () async {
      final (brain, memory, store) = await newBrain();
      final water = seedVocabulary.byEnglish('water')!;
      brain.context.pending = QuizQuestion(
        word: water,
        direction: QuizDirection.englishToPortuguese,
      );

      final first = await brain.respond('fire');
      expect(first.spokenText, contains('Try again'));
      final second = await brain.respond('fogo');
      expect(second.spokenText, contains('Water means água'));
      expect(second.actions.whereType<GiveRewardAction>(), isEmpty);

      expect(seedVocabulary.byEnglish('water')!.portuguese, 'água');
      expect(memory.taughtTranslation('water'), isNull);
      final rows = await store.loadAll();
      expect(rows.every((m) => m.value != 'fire' && m.value != 'fogo'), isTrue);
    });

    test('a correct quiz answer gives XP through GiveRewardAction', () async {
      final (brain, memory, _) = await newBrain();
      final dog = seedVocabulary.byEnglish('dog')!;
      brain.context.pending = QuizQuestion(
        word: dog,
        direction: QuizDirection.portugueseToEnglish,
      );
      final reply = await brain.respond('dog');
      final reward = reply.actions.whereType<GiveRewardAction>().single;
      expect(reward.wordId, dog.id);
      expect(reward.xp, greaterThan(0));
      expect(memory.learnedConfidence(dog.id), greaterThan(0));
    });

    test('"water means fire" is corrected and nothing is learned', () async {
      final (brain, memory, _) = await newBrain();
      final reply = await brain.respond('water means fire');
      expect(reply.spokenText, contains('not quite'));
      expect(reply.spokenText, contains('água'));
      expect(memory.taughtTranslation('water'), isNull);
      expect(seedVocabulary.byEnglish('water')!.portuguese, 'água');
    });

    test('"water means água" is praised', () async {
      final (brain, _, _) = await newBrain();
      final reply = await brain.respond('water means água');
      expect(reply.actions.first, isA<PlayAnimationAction>());
      expect(reply.spokenText.toLowerCase(), contains('right'));
    });

    test('a word outside the bank can be taught after confirmation', () async {
      final (brain, memory, _) = await newBrain();
      final ask = await brain.respond('dragon means dragão');
      expect(ask.spokenText, contains('Is that right?'));
      await brain.respond('yes');
      expect(memory.taughtTranslation('dragon'), 'dragão');

      final later = await brain.respond('what does dragon mean?');
      expect(later.spokenText, contains('dragon means dragão'));
    });
  });

  group('actions', () {
    test('requests become animations and care actions', () async {
      final (brain, _, _) = await newBrain();
      final jump = await brain.respond('jump!');
      expect(
        jump.actions.whereType<PlayAnimationAction>().single.animation,
        DinoAnimation.jump,
      );

      final sleep = await brain.respond('go to sleep');
      expect(sleep.actions.whereType<SleepAction>(), hasLength(1));
      expect(
        sleep.actions.whereType<GoToObjectAction>().single.target,
        DinoObject.bed,
      );
      expect(brain.context.status.isSleeping, isTrue);

      final wake = await brain.respond('wake up');
      expect(wake.actions.whereType<WakeUpAction>(), hasLength(1));
      expect(brain.context.status.isSleeping, isFalse);
    });

    test('feeding the Dino updates hunger', () async {
      final (brain, _, _) = await newBrain();
      final reply = await brain.respond('eat an apple');
      final care = reply.actions.whereType<CareAction>().single;
      expect(care.care, DinoCare.feed);
      expect(brain.context.status.levelOf(DinoNeed.hunger), 1.0);
      expect(reply.spokenText, contains('Apple means maçã'));
    });

    test("let's play Word Slash starts the activity", () async {
      final (brain, memory, _) = await newBrain();
      final reply = await brain.respond("Let's play Word Slash");
      expect(
        reply.actions.whereType<StartActivityAction>().single.activity,
        DinoActivity.wordSlash,
      );
      expect(memory.recall(DinoMemoryKind.activity, 'wordSlash')?.value, '1');
    });

    test('quiz offer accepted with "yes" asks a quiz question', () async {
      final (brain, _, _) = await newBrain();
      await brain.respond('Can I get a reward?');
      expect(brain.context.pending, isA<OfferQuestion>());
      final reply = await brain.respond('yes');
      expect(reply.isWaitingForAnswer, isTrue);
      expect(brain.context.pending, isA<QuizQuestion>());
    });
  });

  test('gibberish gets a friendly fallback, then help', () async {
    final (brain, _, _) = await newBrain();
    final first = await brain.respond('zzqxw blorp');
    expect(first.intent.intent, DinoIntent.unknown);
    final second = await brain.respond('qqq ppp rrr ttt');
    expect(second.actions.whereType<AskAction>(), isNotEmpty);
  });

  group('"What is your name?" only takes names', () {
    for (final phrase in [
      'Você está com fome?',
      'Me dá água',
      'eu quero brincar',
    ]) {
      test('"$phrase" is not a name', () async {
        final (brain, memory, _) = await newBrain();
        await brain.start();
        expect(brain.context.pending, isA<ChildNameQuestion>());
        final reply = await brain.respond(phrase);
        expect(reply.spokenText, isNot(contains('Nice to meet you')));
        expect(memory.fact('child_name'), isNull);
      });
    }

    test('a plain name still is', () async {
      final (brain, memory, _) = await newBrain();
      await brain.start();
      await brain.respond('Pedro');
      expect(memory.fact('child_name'), 'Pedro');
    });
  });
}
