import 'package:dino_english/core/companion/engine/companion_intent.dart';
import 'package:dino_english/core/companion/engine/companion_intent_detector.dart';
import 'package:dino_english/core/companion/engine/text_normalizer.dart';
import 'package:dino_english/core/companion/engine/vocabulary_detector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../brain/brain_test_helpers.dart';

void main() {
  const normalizer = TextNormalizer();
  final detector = CompanionIntentDetector();
  final vocabulary = VocabularyDetector(seedVocabulary);

  IntentMatch detect(String text) =>
      detector.detect(normalizer.normalize(text));

  /// Intent + the thing it's about (slot first, then the sentence).
  (CompanionIntent, String?) understand(String text) {
    final normalized = normalizer.normalize(text);
    final match = detector.detect(normalized);
    final entity =
        (match.slot == null ? null : vocabulary.entityIn(match.slot!)) ??
        vocabulary.detect(normalized).first;
    return (match.intent, entity?.id);
  }

  group('ASK_LIKE + APPLE, said many ways', () {
    for (final phrase in [
      'Você gosta de maçã?',
      'Você gosta de maçãs?',
      'Gosta de maçã?',
      'Você curte maçã?',
      'Do you like apples?',
      'VOCÊ GOSTA DE MAÇÃ?',
      'voce gosta de maca',
      'Dino, você gosta de maçã?',
      'do you like apple',
      'E você gosta de maçã?',
    ]) {
      test(phrase, () {
        expect(understand(phrase), (CompanionIntent.askLike, 'APPLE'));
      });
    }
  });

  group('needs and play', () {
    final cases = {
      'Você está com fome?': CompanionIntent.askHungry,
      'Tá com fome?': CompanionIntent.askHungry,
      'Está com fome?': CompanionIntent.askHungry,
      'Você quer comer?': CompanionIntent.askHungry,
      'Are you hungry?': CompanionIntent.askHungry,
      'Você está com sede?': CompanionIntent.askThirsty,
      'quer beber água?': CompanionIntent.askThirsty,
      'Você está com sono?': CompanionIntent.askSleepy,
      'tá cansado?': CompanionIntent.askSleepy,
      'Vamos brincar?': CompanionIntent.askPlay,
      "Let's play!": CompanionIntent.askPlay,
    };
    cases.forEach((text, intent) {
      test(text, () => expect(detect(text).intent, intent, reason: text));
    });
  });

  group('every companion intent', () {
    final cases = {
      'Oi': CompanionIntent.greeting,
      'Oi Dino!': CompanionIntent.greeting,
      'OI DINO': CompanionIntent.greeting,
      'Hello!': CompanionIntent.greeting,
      'Tchau!': CompanionIntent.goodbye,
      'Qual seu nome?': CompanionIntent.askName,
      'Quantos anos você tem?': CompanionIntent.askAge,
      'How old are you?': CompanionIntent.askAge,
      'Como você está?': CompanionIntent.askHowAreYou,
      'O que você está fazendo?': CompanionIntent.askWhatAreYouDoing,
      'What are you doing?': CompanionIntent.askWhatAreYouDoing,
      'Qual é a sua comida favorita?': CompanionIntent.askFavorite,
      'What is your favorite animal?': CompanionIntent.askFavorite,
      'O que você não gosta?': CompanionIntent.askDislike,
      'Você odeia cobras?': CompanionIntent.askDislike,
      'Me ajuda': CompanionIntent.askHelp,
      'Eu gosto de você': CompanionIntent.affection,
      'Você gosta de mim?': CompanionIntent.affection,
      'Do you like me?': CompanionIntent.affection,
      'Você é fofo': CompanionIntent.praise,
      'Obrigado!': CompanionIntent.thank,
      'Desculpa': CompanionIntent.apology,
      'What does water mean?': CompanionIntent.translateWord,
      'Como se diz cachorro?': CompanionIntent.translateWord,
      'dragon means dragão': CompanionIntent.learnWord,
      'Come uma banana': CompanionIntent.commandEat,
      'eat an apple': CompanionIntent.commandEat,
      'Bebe água': CompanionIntent.commandDrink,
      'drink water': CompanionIntent.commandDrink,
      'Vai dormir': CompanionIntent.commandSleep,
      'go to sleep': CompanionIntent.commandSleep,
      'Brinca com a bola': CompanionIntent.commandPlay,
      'jump!': CompanionIntent.commandOther,
      'What is my favorite food?': CompanionIntent.askMemory,
    };
    cases.forEach((text, intent) {
      test(text, () => expect(detect(text).intent, intent, reason: text));
    });

    test('"come here" is English, not "comer"', () {
      expect(detect('come here').intent, isNot(CompanionIntent.commandEat));
    });
  });

  group('entities', () {
    test('each has English, Portuguese, aliases and a category', () {
      expect(understand('Do you like dogs?'), (CompanionIntent.askLike, 'DOG'));
      expect(understand('Você gosta de cachorrinho?'), (
        CompanionIntent.askLike,
        'DOG',
      ));
      expect(understand('Você gosta de futebol?'), (
        CompanionIntent.askLike,
        'SOCCER',
      ));
      expect(understand('Você odeia cobras?'), (
        CompanionIntent.askDislike,
        'SNAKE',
      ));
      expect(understand('Come uma banana'), (
        CompanionIntent.commandEat,
        'BANANA',
      ));
    });

    test('a word-bank word outside the catalog still becomes a thing', () {
      final (intent, id) = understand('Do you like tigers?');
      expect(intent, CompanionIntent.askLike);
      expect(id, 'WORD_TIGER');
    });

    test('"Eu quero comer uma maçã agora": APPLE in a free sentence', () {
      final found = vocabulary.detect(
        normalizer.normalize('Eu quero comer uma maçã agora.'),
      );
      expect(found.first?.id, 'APPLE');
      expect(found.words.map((w) => w.english), contains('apple'));
    });

    test('"ice cream" wins over "ice"', () {
      final found = vocabulary.detect(normalizer.normalize('I want ice cream'));
      expect(found.first?.id, 'ICE_CREAM');
    });
  });

  group('unknown', () {
    for (final phrase in ['xpto blorg zuzu', 'qwerty asdf', 'hmmmm']) {
      test(
        phrase,
        () => expect(detect(phrase).intent, CompanionIntent.unknown),
      );
    }
  });
}
