import 'package:dino_english/core/brain/context/conversation_context.dart';
import 'package:dino_english/core/brain/intent/intent.dart';
import 'package:dino_english/core/brain/intent/intent_detector.dart';
import 'package:dino_english/core/brain/nlp/normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brain_test_helpers.dart';

void main() {
  final detector = IntentDetector();
  const normalizer = Normalizer();

  IntentResult detect(String text, {PendingQuestion? pending}) =>
      detector.detect(normalizer.normalize(text), pending: pending);

  void expectIntent(String text, DinoIntent intent, {String? slot}) {
    final result = detect(text);
    expect(result.intent, intent, reason: '"$text" -> $result');
    if (slot != null) expect(result.slot, slot, reason: '"$text" -> $result');
  }

  group('ASK_WORD_MEANING', () {
    for (final phrase in [
      'What does water mean?',
      'What is water?',
      'What means water?',
      'What does the word water mean?',
      "what's water mean",
      'Hi Dino, what does water mean please?',
      'what is the meaning of water',
      'water means what?',
      'o que significa water?',
      'What is water in Portuguese?',
      'How do you say water in Portuguese?',
    ]) {
      test(
        phrase,
        () => expectIntent(phrase, DinoIntent.askWordMeaning, slot: 'water'),
      );
    }
  });

  group('ASK_TRANSLATION', () {
    for (final phrase in [
      'How do you say cachorro in English?',
      'How do I say cachorro?',
      'What is cachorro in English?',
      'Como se diz cachorro em inglês?',
      'cachorro em inglês',
      'translate cachorro',
    ]) {
      test(
        phrase,
        () => expectIntent(phrase, DinoIntent.askTranslation, slot: 'cachorro'),
      );
    }
  });

  group('other intents', () {
    final cases = <String, DinoIntent>{
      'Hello!': DinoIntent.greeting,
      'hiii dino': DinoIntent.greeting,
      'oi': DinoIntent.greeting,
      'Bye bye!': DinoIntent.farewell,
      'tchau': DinoIntent.farewell,
      'Give me an example with dog': DinoIntent.askWordExample,
      'use dog in a sentence': DinoIntent.askWordExample,
      'another example': DinoIntent.askWordExample,
      "What's your name?": DinoIntent.askDinoName,
      'qual é o seu nome': DinoIntent.askDinoName,
      'How are you?': DinoIntent.askDinoFeeling,
      'tudo bem?': DinoIntent.askDinoFeeling,
      'Are you hungry?': DinoIntent.askDinoNeed,
      'você está com sede?': DinoIntent.askDinoNeed,
      'What is your favorite food?': DinoIntent.askDinoPreference,
      'Do you like pizza?': DinoIntent.askDinoPreference,
      'help': DinoIntent.askHelp,
      "I don't understand": DinoIntent.askHelp,
      'yes': DinoIntent.yes,
      'nope': DinoIntent.no,
      'thank you so much': DinoIntent.thankYou,
      'sorry': DinoIntent.apology,
      'jump!': DinoIntent.request,
      'can you dance?': DinoIntent.request,
      'go to sleep': DinoIntent.request,
      'eat an apple': DinoIntent.request,
      "Let's play Word Slash": DinoIntent.startActivity,
      'I want to study': DinoIntent.startActivity,
      'vamos jogar word slash': DinoIntent.startActivity,
      'What can we do?': DinoIntent.askActivity,
      "let's play": DinoIntent.play,
      'Can I get a reward?': DinoIntent.askReward,
      'how much xp do i have': DinoIntent.askReward,
      'water means água': DinoIntent.teachWord,
      'dog is cachorro in Portuguese': DinoIntent.teachWord,
      'cachorro em inglês é dog': DinoIntent.teachWord,
      'I want to teach you a word': DinoIntent.teachWord,
      'My name is Ana': DinoIntent.answer,
      'I like apples': DinoIntent.answer,
    };
    cases.forEach((text, intent) {
      test(text, () => expectIntent(text, intent));
    });
  });

  test('teach captures both word and translation', () {
    final r = detect('dragon means dragão');
    expect(r.intent, DinoIntent.teachWord);
    expect(r.slot, 'dragon');
    expect(r.secondSlot, 'dragão');
  });

  test('a bare answer is ANSWER while the Dino waits for one', () {
    final r = detect(
      'Apple.',
      pending: const PreferenceQuestion(topic: 'food', category: 'food'),
    );
    expect(r.intent, DinoIntent.answer);
    expect(r.slot, 'apple');
  });

  test('a real question still wins during a quiz', () {
    final water = seedVocabulary.byEnglish('water')!;
    final r = detect(
      'what does dog mean?',
      pending: QuizQuestion(
        word: water,
        direction: QuizDirection.englishToPortuguese,
      ),
    );
    expect(r.intent, DinoIntent.askWordMeaning);
  });

  test('yes/no become CONFIRM_WORD/DENY_WORD while confirming a word', () {
    final pending = ConfirmWordQuestion(
      candidates: [seedVocabulary.byEnglish('bed')!],
      originalIntent: DinoIntent.askWordMeaning,
      heard: 'bet',
    );
    expect(detect('yes', pending: pending).intent, DinoIntent.confirmWord);
    expect(detect('no', pending: pending).intent, DinoIntent.denyWord);
  });

  group('companion: the same question in different words', () {
    final cases = <DinoIntent, List<String>>{
      DinoIntent.greeting: ['Oi', 'Oi Dino!', 'oi dino', 'OI DINO', 'Olá!'],
      DinoIntent.farewell: ['Tchau!', 'até logo', 'bye dino'],
      DinoIntent.askDinoName: ['Qual seu nome?', 'Como você se chama?'],
      DinoIntent.askDinoFeeling: ['Como você está?', 'Você está bem?'],
      DinoIntent.askDinoNeed: [
        'Você está com fome?',
        'Tá com fome?',
        'Está com fome?',
        'Você quer comer?',
        'vc ta com fome',
        'Você está com sede?',
        'Você está com sono?',
        'Are you sleepy?',
      ],
      DinoIntent.play: [
        'Vamos brincar?',
        'quer brincar comigo?',
        "Let's play!",
        'play with me',
        'do you want to play?',
      ],
      DinoIntent.affection: [
        'Eu gosto de você',
        'eu te amo',
        'I love you',
        'I like you too',
        'você gosta de mim?',
        'um abraço',
      ],
      DinoIntent.praise: [
        'Você é fofo',
        'você é muito inteligente',
        'que fofo!',
        'You are cute',
        'good boy',
        'good job',
      ],
      DinoIntent.askMemory: [
        'What is my favorite food?',
        'what is my name',
        'qual é a minha cor favorita?',
        'qual é o meu nome?',
        'você lembra do meu nome?',
      ],
    };
    cases.forEach((intent, phrases) {
      for (final text in phrases) {
        test('$text -> ${intent.name}', () => expectIntent(text, intent));
      }
    });

    test('"vamos jogar" still lists the games; "vamos brincar" plays', () {
      expectIntent('vamos jogar', DinoIntent.askActivity);
      expectIntent("let's play Word Slash", DinoIntent.startActivity);
    });

    test('memory questions capture the topic', () {
      expectIntent(
        'What is my favorite food?',
        DinoIntent.askMemory,
        slot: 'food',
      );
      expectIntent(
        'qual é a minha cor favorita',
        DinoIntent.askMemory,
        slot: 'cor',
      );
    });

    test('a favorite stated (not asked) is still a fact', () {
      expectIntent('minha cor favorita é azul', DinoIntent.answer);
    });

    test('the repeated word is an ANSWER while the Dino waits for it', () {
      final apple = seedVocabulary.byEnglish('apple')!;
      final r = detect('Apple!', pending: RepeatWordQuestion(word: apple));
      expect(r.intent, DinoIntent.answer);
      expect(r.slot, 'apple');
    });
  });
}
