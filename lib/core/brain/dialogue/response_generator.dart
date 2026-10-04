import 'dart:math';

import '../context/conversation_context.dart';
import '../model/dino_enums.dart';
import '../model/dino_status.dart';
import '../nlp/inflection.dart';
import '../vocabulary/official_vocabulary.dart';

/// One thing the Dino says: English [text] (spoken by TTS) plus an
/// optional Portuguese [translation] shown as a subtitle.
class DinoLine {
  const DinoLine(this.text, [this.translation]);

  final String text;
  final String? translation;
}

/// Turns decisions into child-friendly English lines. All wording lives
/// here (the `DialogueManager` never builds strings), with small variant
/// pools so the Dino doesn't sound like a robot. [Random] is injectable
/// so tests are deterministic.
class ResponseGenerator {
  ResponseGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;
  static const _inflection = Inflection();

  /// How simple the lines should be; set by the `DialogueManager` from
  /// the child's level before each reply.
  EnglishTier tier = EnglishTier.a1;

  T _pick<T>(List<T> options) => options[_random.nextInt(options.length)];

  /// Picks from every pool up to the current [tier]: beginners only hear
  /// the short lines, older learners hear those and longer ones.
  DinoLine _tiered(
    List<DinoLine> a1, {
    List<DinoLine> a2 = const [],
    List<DinoLine> b1 = const [],
  }) => _pick([
    ...a1,
    if (tier.index >= EnglishTier.a2.index) ...a2,
    if (tier.index >= EnglishTier.b1.index) ...b1,
  ]);

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ---- small talk -------------------------------------------------------------

  DinoLine greeting({String? childName, bool returning = false}) {
    final name = childName == null ? '' : ', ${_cap(childName)}';
    if (returning) {
      return _pick([
        DinoLine('Hi again$name!', 'Oi de novo!'),
        DinoLine('Hello$name! I missed you!', 'Olá! Senti sua falta!'),
      ]);
    }
    return _tiered(
      [
        DinoLine("Hi$name! I'm Dino!", 'Oi! Eu sou o Dino!'),
        DinoLine('Hello$name!', 'Olá!'),
        DinoLine('Hi$name! Nice to see you!', 'Oi! Que bom te ver!'),
      ],
      a2: [
        DinoLine(
          'Hi$name! I am so happy to see you!',
          'Oi! Estou muito feliz em te ver!',
        ),
        DinoLine(
          'Hello$name! Rawr! That means hi in dino!',
          'Olá! Rawr! Isso é "oi" em dinossaurês!',
        ),
      ],
      b1: [
        DinoLine(
          "Hey$name! Let's learn English together!",
          'Ei! Vamos aprender inglês juntos!',
        ),
      ],
    );
  }

  DinoLine farewell({String? childName}) {
    final name = childName == null ? '' : ', ${_cap(childName)}';
    return _pick([
      DinoLine('Bye$name! See you soon!', 'Tchau! Até logo!'),
      DinoLine(
        'Goodbye$name! I will miss you!',
        'Tchau! Vou sentir sua falta!',
      ),
      DinoLine('See you later, friend!', 'Até mais, amigo!'),
    ]);
  }

  DinoLine thanksReply() => _pick(const [
    DinoLine('You are welcome!', 'De nada!'),
    DinoLine('Anytime, friend!', 'Quando quiser, amigo!'),
    DinoLine('No problem! Rawr!', 'Sem problemas! Rawr!'),
  ]);

  DinoLine apologyReply() => _pick(const [
    DinoLine(
      'That is okay! Everybody makes mistakes.',
      'Tudo bem! Todo mundo erra.',
    ),
    DinoLine('No worries, friend!', 'Não se preocupe, amigo!'),
  ]);

  DinoLine name(String dinoName) => _tiered(
    [DinoLine('My name is $dinoName!', 'Meu nome é $dinoName!')],
    a2: [
      DinoLine(
        'My name is $dinoName! I am a baby dinosaur who loves English!',
        'Meu nome é $dinoName! Sou um dinossauro bebê que ama inglês!',
      ),
    ],
  );

  DinoLine niceToMeetYou(String childName) => DinoLine(
    'Nice to meet you, ${_cap(childName)}! I will remember your name.',
    'Prazer em te conhecer, ${_cap(childName)}! Vou lembrar do seu nome.',
  );

  DinoLine age(String years) => DinoLine(
    'Wow, $years years old! I am just a baby dino!',
    'Uau, $years anos! Eu sou só um dino bebê!',
  );

  // ---- feelings & needs ------------------------------------------------------

  DinoLine feeling(DinoStatus status) {
    final urgent = status.mostUrgentNeed;
    if (urgent != null) return needComplaint(urgent);
    return _tiered(
      const [
        DinoLine("I'm happy!", 'Estou feliz!'),
        DinoLine('I am good!', 'Estou bem!'),
      ],
      a2: const [
        DinoLine(
          'I am happy! Thank you for asking!',
          'Estou feliz! Obrigado por perguntar!',
        ),
        DinoLine('I feel great today!', 'Eu me sinto ótimo hoje!'),
      ],
      b1: const [
        DinoLine(
          'I am good! Learning with you makes me happy.',
          'Estou bem! Aprender com você me deixa feliz.',
        ),
      ],
    );
  }

  DinoLine needComplaint(DinoNeed need) => switch (need) {
    DinoNeed.hunger => _tiered(
      const [
        DinoLine("Yes! I'm hungry!", 'Sim! Estou com fome!'),
        DinoLine("I'm hungry...", 'Estou com fome...'),
      ],
      a2: const [
        DinoLine('I am hungry. Can we eat?', 'Estou com fome. Podemos comer?'),
      ],
      b1: const [
        DinoLine(
          'I am really hungry. What should we eat?',
          'Estou com muita fome. O que vamos comer?',
        ),
      ],
    ),
    DinoNeed.thirst => _tiered(
      const [
        DinoLine("I'm thirsty!", 'Estou com sede!'),
        DinoLine('Yes! Water, please!', 'Sim! Água, por favor!'),
      ],
      a2: const [
        DinoLine(
          'I am thirsty. Can I have some water?',
          'Estou com sede. Posso tomar água?',
        ),
      ],
    ),
    DinoNeed.energy => _tiered(
      const [
        DinoLine("I'm sleepy...", 'Estou com sono...'),
        DinoLine("Yawn... I'm tired.", 'Bocejo... Estou cansado.'),
      ],
      a2: const [
        DinoLine(
          'I am sleepy... I need to rest.',
          'Estou com sono... Preciso descansar.',
        ),
      ],
    ),
    DinoNeed.hygiene => const DinoLine(
      'I am dirty! I need a bath.',
      'Estou sujo! Preciso de um banho.',
    ),
    DinoNeed.happiness => _tiered(
      const [
        DinoLine("I'm bored. Let's play!", 'Estou entediado. Vamos brincar!'),
      ],
      a2: const [
        DinoLine(
          'I am a little bored. Can we play?',
          'Estou um pouco entediado. Podemos brincar?',
        ),
      ],
    ),
  };

  /// Between fine and urgent: "A little hungry!".
  DinoLine needMild(DinoNeed need) => switch (need) {
    DinoNeed.hunger => const DinoLine('A little hungry!', 'Um pouco de fome!'),
    DinoNeed.thirst => const DinoLine('A little thirsty!', 'Um pouco de sede!'),
    DinoNeed.energy => const DinoLine('A little sleepy!', 'Um pouco de sono!'),
    DinoNeed.hygiene => const DinoLine('A little dirty!', 'Um pouco sujo!'),
    DinoNeed.happiness => const DinoLine(
      "I'm okay! Let's play later!",
      'Estou bem! Vamos brincar depois!',
    ),
  };

  DinoLine needFine(DinoNeed? need) => switch (need) {
    DinoNeed.hunger => const DinoLine(
      'No, I am not hungry. My tummy is full!',
      'Não, não estou com fome. Minha barriga está cheia!',
    ),
    DinoNeed.thirst => const DinoLine(
      'No, I am not thirsty, thank you!',
      'Não, não estou com sede, obrigado!',
    ),
    DinoNeed.energy => const DinoLine(
      'No, I am not tired. I have lots of energy!',
      'Não, não estou cansado. Tenho muita energia!',
    ),
    DinoNeed.hygiene => const DinoLine(
      'I am clean and shiny!',
      'Estou limpinho e brilhando!',
    ),
    DinoNeed.happiness => const DinoLine(
      'I am happy because you are here!',
      'Estou feliz porque você está aqui!',
    ),
    null => const DinoLine(
      'I just want to learn English with you!',
      'Eu só quero aprender inglês com você!',
    ),
  };

  DinoLine childFeeling(String feeling) {
    const good = {
      'happy',
      'good',
      'fine',
      'great',
      'ok',
      'okay',
      'well',
      'cool',
      'awesome',
      'excited',
      'feliz',
      'bem',
      'otimo',
      'ótimo',
      'otima',
      'ótima',
      'legal',
      'animado',
      'animada',
    };
    const bored = {'bored', 'entediado', 'entediada'};
    const tired = {'tired', 'sleepy', 'cansado', 'cansada', 'com sono'};
    const hungry = {'hungry', 'com fome', 'thirsty', 'com sede'};
    if (good.contains(feeling)) {
      return _pick(const [
        DinoLine('Yay! I am happy too!', 'Eba! Eu também estou feliz!'),
        DinoLine('That is great! High five!', 'Que ótimo! Toca aqui!'),
      ]);
    }
    if (bored.contains(feeling)) {
      return const DinoLine(
        "Bored? Let's play a game!",
        'Entediado? Vamos jogar um jogo!',
      );
    }
    if (tired.contains(feeling)) {
      return const DinoLine(
        'Oh, you need some rest. Me too, sometimes!',
        'Ah, você precisa descansar. Eu também, às vezes!',
      );
    }
    if (hungry.contains(feeling)) {
      return const DinoLine(
        "Me too! Let's eat something yummy later.",
        'Eu também! Vamos comer algo gostoso depois.',
      );
    }
    return _pick(const [
      DinoLine(
        'Oh no! I am here with you. Do you want a dino hug?',
        'Ah não! Estou aqui com você. Quer um abraço de dino?',
      ),
      DinoLine(
        'I am sorry. I hope you feel better soon!',
        'Sinto muito. Espero que você se sinta melhor logo!',
      ),
    ]);
  }

  DinoLine askChildFeeling() =>
      const DinoLine('And you? How are you?', 'E você? Como você está?');

  // ---- words -------------------------------------------------------------------

  /// "Water means água." / "Light means luz. It can also mean leve."
  DinoLine meaning(VocabularyEntry word) {
    final translations = word.translations;
    final main = '${_cap(word.english)} means ${translations.first}.';
    if (translations.length == 1) {
      return DinoLine(
        main,
        '${_cap(word.english)} significa ${translations.first}.',
      );
    }
    final others = _joinOr(translations.skip(1).toList());
    return DinoLine('$main It can also mean $others.', _sensesHint(word));
  }

  /// "Cachorro is dog in English."
  DinoLine translation(VocabularyEntry word, String portugueseAsked) =>
      DinoLine(
        '${_cap(portugueseAsked)} is ${word.english} in English.',
        '${_cap(word.english)} significa $portugueseAsked.',
      );

  DinoLine example(VocabularyEntry word, {int senseIndex = 0}) {
    final sense = word.senses[senseIndex.clamp(0, word.senses.length - 1)];
    final en = sense.exampleEn ?? word.exampleEn;
    final pt = sense.examplePt ?? word.examplePt;
    return _pick([
      DinoLine('Here is an example: $en', pt),
      DinoLine('Listen: $en', pt),
      DinoLine('You can say: $en', pt),
    ]);
  }

  DinoLine didYouMean(List<VocabularyEntry> options) => DinoLine(
    'Did you mean ${_joinOr(options.map((e) => e.english).toList())}?',
    'Você quis dizer...?',
  );

  DinoLine correctedSpelling(VocabularyEntry word) => DinoLine(
    'I think you mean "${word.english}".',
    'Acho que você quis dizer "${word.english}".',
  );

  DinoLine unknownWord(String word) => DinoLine(
    'Hmm, I do not know the word "$word" yet. What does it mean?',
    'Hmm, ainda não conheço a palavra "$word". O que ela significa?',
  );

  DinoLine unknownPortugueseWord(String word) => DinoLine(
    'Hmm, I do not know how to say "$word" in English yet. Let\'s find it in a dictionary later!',
    'Hmm, ainda não sei dizer "$word" em inglês. Vamos procurar num dicionário depois!',
  );

  DinoLine rememberedTaught(String english, String portuguese) => DinoLine(
    'You taught me that $english means $portuguese!',
    'Você me ensinou que $english significa $portuguese!',
  );

  DinoLine confirmTeach(String english, String portuguese) => DinoLine(
    '${_cap(english)} means $portuguese? Is that right?',
    '$english significa $portuguese? Está certo?',
  );

  DinoLine learnedTaught(String english, String portuguese) => _pick([
    DinoLine(
      'Thank you! Now I know that $english means $portuguese!',
      'Obrigado! Agora eu sei que $english significa $portuguese!',
    ),
    DinoLine(
      'Cool! $english means $portuguese. I will remember!',
      'Legal! $english significa $portuguese. Vou lembrar!',
    ),
  ]);

  DinoLine teachCorrect(VocabularyEntry word) => _pick([
    DinoLine(
      'Yes! You are right! ${_cap(word.english)} means ${word.translations.first}.',
      'Sim! Você acertou!',
    ),
    DinoLine('That is right! Great job!', 'Isso mesmo! Muito bem!'),
  ]);

  /// Gentle correction: the official translation always wins.
  DinoLine teachWrong(VocabularyEntry word, String said) => DinoLine(
    'Hmm, not quite! ${_cap(word.english)} means ${_joinOr(word.translations)}, not $said.',
    'Quase! ${word.english} significa ${word.translations.first}, não $said.',
  );

  DinoLine teachAskWord() => const DinoLine(
    'Yay! I love new words! Tell me: which word? Say it like this: dragon means dragão.',
    'Eba! Adoro palavras novas! Diga assim: dragon means dragão.',
  );

  DinoLine okNeverMind() => _pick(const [
    DinoLine('Okay, never mind!', 'Tudo bem, deixa pra lá!'),
    DinoLine(
      'Oh, okay! Can you say it another way?',
      'Ah, tudo bem! Pode dizer de outro jeito?',
    ),
  ]);

  DinoLine whichWord() => const DinoLine(
    'Which word? Try: What does water mean?',
    'Qual palavra? Tente: What does water mean?',
  );

  // ---- preferences -------------------------------------------------------------

  static const Map<String, String> topicNames = {
    'food': 'food',
    'animals': 'animal',
    'colors': 'color',
    'nature': 'thing in nature',
    'verbs': 'thing to do',
    'places': 'place',
    'objects': 'toy',
    'clothes': 'clothes',
  };

  static const Map<String, String> _topicNamesPt = {
    'food': 'comida',
    'animals': 'animal',
    'colors': 'cor',
    'nature': 'coisa da natureza',
    'verbs': 'coisa para fazer',
    'places': 'lugar',
    'objects': 'brinquedo',
    'clothes': 'roupa',
  };

  /// The Dino's own favorites (it's a character, so they're fixed).
  static const Map<String, String> dinoFavorites = {
    'food': 'cookie',
    'animals': 'turtle',
    'colors': 'green',
    'nature': 'star',
    'verbs': 'dance',
    'places': 'park',
    'objects': 'ball',
    'clothes': 'hat',
  };

  DinoLine askPreference(String category) => DinoLine(
    'What is your favorite ${topicNames[category] ?? category}?',
    'Qual é o seu ${_topicNamesPt[category] ?? category} favorito?',
  );

  DinoLine likesIt(VocabularyEntry word) {
    final thing = word.category == 'verbs'
        ? 'to ${word.english}'
        : _inflection.pluralize(word.english);
    return _pick([
      DinoLine(
        'Oh! You like $thing! Me too!',
        'Ah! Você gosta de ${word.portuguese}! Eu também!',
      ),
      DinoLine(
        'Yummy... I mean, cool! You like $thing!',
        'Legal! Você gosta de ${word.portuguese}!',
      ),
      DinoLine('$thing? Great choice!', 'Ótima escolha!'),
    ]);
  }

  DinoLine rememberPreference(
    String category,
    VocabularyEntry word,
  ) => DinoLine(
    'I remember! Your favorite ${topicNames[category] ?? category} is ${word.english}!',
    'Eu lembro! Seu favorito é ${word.portuguese}!',
  );

  DinoLine dislikesIt(VocabularyEntry? word, String heard) {
    final thing = word == null ? heard : _inflection.pluralize(word.english);
    return DinoLine(
      'Oh, you do not like $thing. That is okay!',
      'Ah, você não gosta. Tudo bem!',
    );
  }

  DinoLine likesUnknown(String heard) =>
      DinoLine('Cool! You like $heard!', 'Legal! Você gosta de $heard!');

  DinoLine preferenceNotUnderstood(String category) => DinoLine(
    'Hmm, I do not know that one. Tell me a ${topicNames[category] ?? category} in English!',
    'Hmm, não conheço essa. Me diga em inglês!',
  );

  DinoLine dinoFavorite(String category, VocabularyEntry? favorite) {
    if (favorite == null) {
      return const DinoLine(
        'I like everything about English!',
        'Eu gosto de tudo sobre inglês!',
      );
    }
    return DinoLine(
      'My favorite ${topicNames[category] ?? category} is ${favorite.english}! ${_cap(favorite.english)} means ${favorite.portuguese}.',
      'Meu favorito é ${favorite.portuguese}!',
    );
  }

  DinoLine dinoLikes(VocabularyEntry word, {required bool likes}) {
    final thing = word.category == 'verbs'
        ? 'to ${word.english}'
        : _inflection.pluralize(word.english);
    return likes
        ? DinoLine('Yes! I love $thing!', 'Sim! Eu amo ${word.portuguese}!')
        : DinoLine(
            'Hmm, not really. I do not like $thing very much.',
            'Hmm, não muito. Não gosto muito de ${word.portuguese}.',
          );
  }

  // ---- quiz ------------------------------------------------------------------

  DinoLine offerQuiz() => const DinoLine(
    'Do you want a quick word challenge?',
    'Quer um desafio rápido de palavras?',
  );

  DinoLine quizQuestion(VocabularyEntry word, QuizDirection direction) =>
      switch (direction) {
        QuizDirection.englishToPortuguese => DinoLine(
          'What does "${word.english}" mean in Portuguese?',
          'O que "${word.english}" significa em português?',
        ),
        QuizDirection.portugueseToEnglish => DinoLine(
          'How do you say "${word.portuguese}" in English?',
          'Como se diz "${word.portuguese}" em inglês?',
        ),
      };

  DinoLine quizCorrect(VocabularyEntry word, int xp) => _pick([
    DinoLine(
      'Yes! Great job! ${_cap(word.english)} means ${word.portuguese}. You won $xp XP!',
      'Isso! Muito bem! Você ganhou $xp XP!',
    ),
    DinoLine(
      'Correct! Rawr! You are so smart! +$xp XP!',
      'Certo! Você é muito esperto! +$xp XP!',
    ),
  ]);

  DinoLine quizTryAgain() => _pick(const [
    DinoLine('Almost! Try again!', 'Quase! Tente de novo!'),
    DinoLine('Not quite. One more try!', 'Ainda não. Mais uma tentativa!'),
  ]);

  DinoLine quizReveal(VocabularyEntry word) => DinoLine(
    'Good try! ${_cap(word.english)} means ${word.portuguese}. You will get it next time!',
    'Boa tentativa! ${word.english} significa ${word.portuguese}. Na próxima você acerta!',
  );

  DinoLine quizGiveUp(VocabularyEntry word) => DinoLine(
    'That is okay! ${_cap(word.english)} means ${word.portuguese}.',
    'Tudo bem! ${word.english} significa ${word.portuguese}.',
  );

  DinoLine anotherQuiz() =>
      const DinoLine('Want another one?', 'Quer mais um?');

  // ---- activities & rewards ---------------------------------------------------

  DinoLine suggestActivities() => const DinoLine(
    'We can study new words, play Word Slash, build sentences, take a test or go on an adventure. What do you want?',
    'Podemos estudar palavras, jogar Word Slash, montar frases, fazer a prova ou ir para a aventura. O que você quer?',
  );

  DinoLine suggestActivity(DinoActivity activity) => DinoLine(
    'Do you want to ${activity.spokenName}?',
    'Você quer ${activity.portugueseName}?',
  );

  DinoLine startingActivity(DinoActivity activity) => _pick([
    DinoLine(
      "Let's ${activity.spokenName}! Here we go!",
      'Vamos ${activity.portugueseName}!',
    ),
    DinoLine(
      'Great idea! Time to ${activity.spokenName}!',
      'Ótima ideia! Hora de ${activity.portugueseName}!',
    ),
  ]);

  DinoLine rewardInfo(DinoStatus status) => DinoLine(
    'You have ${status.totalXp} XP and you are level ${status.level}! Answer my word challenges to win more XP!',
    'Você tem ${status.totalXp} XP e está no nível ${status.level}! Responda meus desafios para ganhar mais XP!',
  );

  // ---- requests ----------------------------------------------------------------

  DinoLine requestReply(DinoAnimation animation) => switch (animation) {
    DinoAnimation.jump => const DinoLine(
      'Jump! Jump! Look how high I can jump!',
      'Pula! Pula! Olha como eu pulo alto!',
    ),
    DinoAnimation.dance => const DinoLine(
      "Let's dance! Shake, shake, shake!",
      'Vamos dançar!',
    ),
    DinoAnimation.sing => const DinoLine(
      'La la la! I love to sing!',
      'Lá lá lá! Adoro cantar!',
    ),
    DinoAnimation.sleep => const DinoLine(
      'Yawn... Good night! Z z z...',
      'Bocejo... Boa noite! Zzz...',
    ),
    DinoAnimation.eat => const DinoLine(
      'Yum yum! Thank you for the food!',
      'Nham nham! Obrigado pela comida!',
    ),
    DinoAnimation.drink => const DinoLine(
      'Gulp gulp! Thank you, I was thirsty!',
      'Glub glub! Obrigado, eu estava com sede!',
    ),
    DinoAnimation.roar => const DinoLine(
      'RAWR! Was I scary?',
      'RAWR! Eu dei medo?',
    ),
    DinoAnimation.run => const DinoLine(
      'Zoom! I am running fast!',
      'Zum! Estou correndo rápido!',
    ),
    DinoAnimation.sit => const DinoLine(
      'Okay, I am sitting down.',
      'Tá bom, estou sentando.',
    ),
    DinoAnimation.walk => const DinoLine(
      'Here I come! Stomp, stomp!',
      'Estou indo! Pisa, pisa!',
    ),
    DinoAnimation.wave => const DinoLine('Hi hi! *waves*', 'Oi oi! *acena*'),
    DinoAnimation.happy => const DinoLine(
      'Hee hee! You make me smile!',
      'Hihi! Você me faz sorrir!',
    ),
    _ => const DinoLine('Okay!', 'Tá bom!'),
  };

  DinoLine bath() => const DinoLine(
    'Splash splash! Now I am clean!',
    'Splash splash! Agora estou limpinho!',
  );

  DinoLine wakeUp() =>
      const DinoLine('Good morning! I am awake!', 'Bom dia! Estou acordado!');

  DinoLine sleepingNow() => const DinoLine(
    'Z z z... (The Dino is sleeping. Say "wake up"!)',
    'Zzz... (O Dino está dormindo. Diga "wake up"!)',
  );

  DinoLine cannotDoThat() => const DinoLine(
    'Hmm, I do not know how to do that yet!',
    'Hmm, ainda não sei fazer isso!',
  );

  // ---- companion: affection, play, memory --------------------------------------

  DinoLine affection({bool asked = false}) {
    if (asked) {
      return _pick(const [
        DinoLine('Yes! I like you very much!', 'Sim! Eu gosto muito de você!'),
        DinoLine('Of course! You are my friend!', 'Claro! Você é meu amigo!'),
      ]);
    }
    return _tiered(
      const [
        DinoLine('I like you too!', 'Eu também gosto de você!'),
        DinoLine('Aww! Big hug!', 'Own! Abraço apertado!'),
        DinoLine('You are my friend!', 'Você é meu amigo!'),
      ],
      a2: const [
        DinoLine(
          'I like you too! You are my best friend!',
          'Eu também gosto de você! Você é meu melhor amigo!',
        ),
      ],
    );
  }

  DinoLine praise() => _tiered(
    const [
      DinoLine('Thank you!', 'Obrigado!'),
      DinoLine('Aww, thank you!', 'Own, obrigado!'),
      DinoLine('Hee hee! Thank you!', 'Hihi! Obrigado!'),
    ],
    a2: const [
      DinoLine(
        'Thank you! You are very nice too!',
        'Obrigado! Você também é muito legal!',
      ),
    ],
  );

  DinoLine letsPlay() => _tiered(
    const [
      DinoLine("Let's play!", 'Vamos brincar!'),
      DinoLine('Yay! Play time!', 'Eba! Hora de brincar!'),
    ],
    a2: const [
      DinoLine(
        'Yes! I love to play with you!',
        'Sim! Eu adoro brincar com você!',
      ),
    ],
  );

  DinoLine tooTiredToPlay() => const DinoLine(
    "I'm too tired to play... Can I sleep?",
    'Estou cansado demais para brincar... Posso dormir?',
  );

  DinoLine rememberName(String childName) => DinoLine(
    'Your name is ${_cap(childName)}!',
    'Seu nome é ${_cap(childName)}!',
  );

  DinoLine rememberAge(String years) =>
      DinoLine('You are $years years old!', 'Você tem $years anos!');

  DinoLine dontKnowYet() => const DinoLine(
    "Hmm... I don't know yet! Can you tell me?",
    'Hmm... Ainda não sei! Você pode me contar?',
  );

  /// "Sua cor favorita" / "Seu animal favorito": Portuguese agrees with
  /// the topic's gender.
  static const Map<String, String> _yourFavoritePt = {
    'food': 'Sua comida favorita',
    'animals': 'Seu animal favorito',
    'colors': 'Sua cor favorita',
    'nature': 'Sua coisa favorita da natureza',
    'verbs': 'Sua coisa favorita de fazer',
    'places': 'Seu lugar favorito',
    'objects': 'Seu brinquedo favorito',
    'clothes': 'Sua roupa favorita',
  };

  DinoLine rememberFavorite(String category, VocabularyEntry word) => DinoLine(
    'Your favorite ${topicNames[category] ?? category} is ${word.english}!',
    '${_yourFavoritePt[category] ?? 'Seu favorito'} é ${word.portuguese}!',
  );

  // ---- companion: learning words met in conversation ---------------------------

  static const Map<String, String> _emoji = {
    'apple': '🍎',
    'banana': '🍌',
    'bread': '🍞',
    'cake': '🍰',
    'candy': '🍬',
    'carrot': '🥕',
    'cheese': '🧀',
    'chicken': '🍗',
    'chocolate': '🍫',
    'cookie': '🍪',
    'egg': '🥚',
    'grape': '🍇',
    'ice cream': '🍦',
    'juice': '🧃',
    'milk': '🥛',
    'pizza': '🍕',
    'strawberry': '🍓',
    'water': '💧',
    'dog': '🐶',
    'cat': '🐱',
    'bird': '🐦',
    'fish': '🐟',
    'lion': '🦁',
    'turtle': '🐢',
    'ball': '⚽',
    'book': '📖',
    'sun': '☀️',
    'moon': '🌙',
    'star': '⭐',
    'flower': '🌸',
    'tree': '🌳',
    'happy': '😄',
    'sad': '😢',
    'sleep': '😴',
    'play': '🎮',
  };

  String emojiFor(VocabularyEntry word) {
    final e = _emoji[word.english.toLowerCase()];
    return e == null ? '' : ' $e';
  }

  /// "Apple! 🍎" / "Maçã!" -- the word the child just used.
  DinoLine learnWord(VocabularyEntry word) => DinoLine(
    '${_cap(word.english)}!${emojiFor(word)}',
    '${_cap(word.translations.first)}!',
  );

  DinoLine askRepeat(VocabularyEntry word) => _pick([
    DinoLine('Say: ${_cap(word.english)}!', 'Diga: ${_cap(word.english)}!'),
    DinoLine(
      'Can you say ${word.english.toUpperCase()}?',
      'Você consegue falar ${word.english.toUpperCase()}?',
    ),
    DinoLine(
      "Let's learn this word! Say: ${word.english}!",
      'Vamos aprender essa palavra! Diga: ${word.english}!',
    ),
  ]);

  DinoLine repeatCorrect(VocabularyEntry word, int xp) => _pick([
    DinoLine(
      'Great job! ${_cap(word.english)}!${xp > 0 ? ' +$xp XP!' : ''}',
      'Muito bem! ${_cap(word.translations.first)}!',
    ),
    DinoLine(
      'Yes! You said ${word.english}!${xp > 0 ? ' +$xp XP!' : ''}',
      'Isso! Você falou ${word.english}!',
    ),
  ]);

  DinoLine repeatTryAgain(VocabularyEntry word) => _pick([
    DinoLine(
      'Almost! Try again: ${word.english}!',
      'Quase! Tente novamente: ${word.english}!',
    ),
    DinoLine(
      'Good try! Say: ${word.english}!',
      'Boa tentativa! Diga: ${word.english}!',
    ),
  ]);

  DinoLine repeatReveal(VocabularyEntry word) => DinoLine(
    'Good try! It is ${word.english}. We can practice later!',
    'Boa tentativa! É ${word.english}. Podemos praticar depois!',
  );

  // ---- help & fallback ----------------------------------------------------------

  DinoLine help() => const DinoLine(
    'You can ask me: What does water mean? How do you say cachorro? Give me an example with dog. Or say: Let\'s play!',
    'Você pode perguntar: What does water mean? How do you say cachorro? Give me an example with dog. Ou diga: Let\'s play!',
  );

  DinoLine notUnderstood({required bool repeated}) {
    if (repeated) {
      return const DinoLine(
        'I am still learning! Try: What does dog mean?',
        'Ainda estou aprendendo! Tente: What does dog mean?',
      );
    }
    // Never a flat "não entendi", never invented knowledge: honest and
    // inviting.
    return _pick(const [
      DinoLine("I don't know that yet.", 'Eu ainda não sei isso.'),
      DinoLine(
        "Hmm... I don't understand yet.",
        'Hmm... Eu ainda não entendi.',
      ),
      DinoLine("Let's try something else!", 'Vamos tentar outra coisa!'),
      DinoLine(
        "Hmm... I don't know that yet! Can you teach me?",
        'Hmm... Ainda não sei isso! Você pode me ensinar?',
      ),
      DinoLine('Try saying it another way!', 'Vamos tentar de outro jeito!'),
      DinoLine('Can you say it in English?', 'Você consegue falar em inglês?'),
    ]);
  }

  DinoLine yesReply() =>
      _pick(const [DinoLine('Yay!', 'Eba!'), DinoLine('Cool!', 'Legal!')]);

  DinoLine noReply() => _pick(const [
    DinoLine('Okay!', 'Tudo bem!'),
    DinoLine('Alright, no problem!', 'Certo, sem problemas!'),
  ]);

  // ---- helpers -------------------------------------------------------------------

  String _joinOr(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.single;
    return '${items.sublist(0, items.length - 1).join(', ')} or ${items.last}';
  }

  String _sensesHint(VocabularyEntry word) => word.senses
      .map(
        (s) => s.partOfSpeech == null
            ? s.portuguese
            : '${s.portuguese} (${_posPt(s.partOfSpeech!)})',
      )
      .join(' / ');

  String _posPt(String pos) => switch (pos) {
    'noun' => 'substantivo',
    'verb' => 'verbo',
    'adjective' => 'adjetivo',
    _ => pos,
  };
}
