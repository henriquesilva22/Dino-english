import '../../brain/model/dino_enums.dart';

/// One way of saying something: English first (spoken), Portuguese
/// subtitle. `{placeholders}` are filled by `ResponseSelector`:
///
/// * `{name}` -- ", Ana" (or nothing when the name is unknown)
/// * `{en}` / `{En}` -- "apple" / "Apple"
/// * `{enG}` / `{EnG}` -- generic form: "apples", "water"
/// * `{pt}` / `{Pt}` / `{ptG}` / `{PtG}` -- same in Portuguese
/// * `{be}` / `{ser}` -- "are"/"is", "são"/"é" (agrees with `{enG}`)
/// * `{legal}` -- "legais"/"legal"
/// * `{emoji}`
/// * favorites: `{topicEn}`, `{myFavPt}`, `{yourFavPt}`, `{favEn}`,
///   `{FavEn}`, `{favEnG}`, `{favPt}`, `{FavPt}`, `{favPtG}`
class ResponseTemplate {
  const ResponseTemplate(this.en, this.pt, {this.tier = EnglishTier.a1});

  final String en;
  final String pt;

  /// Lowest English level that hears this line (A1 = everyone).
  final EnglishTier tier;
}

const _a2 = EnglishTier.a2;

typedef _R = ResponseTemplate;

/// Everything the companion says by itself, by situation. Plain data, so
/// hundreds of lines can be added (or moved to a JSON asset) without
/// touching the engine. Every line is checked by tests for both
/// languages and known placeholders.
const Map<String, List<ResponseTemplate>> defaultResponseBank = {
  // ---- small talk ---------------------------------------------------------------
  'greeting': [
    _R('Hi{name}!', 'Oi{name}!'),
    _R('Hello{name}!', 'Olá{name}!'),
    _R("Hi{name}! I'm Dino!", 'Oi{name}! Eu sou o Dino!'),
    _R('Hey{name}! Nice to see you!', 'Ei{name}! Que bom te ver!'),
    _R('Hello, friend!', 'Olá, amigo!'),
    _R('Hi hi! Rawr! 🦖', 'Oi oi! Rawr!'),
    _R(
      "Hi{name}! I'm so happy to see you!",
      'Oi{name}! Estou muito feliz em te ver!',
      tier: _a2,
    ),
  ],
  'greeting.ask': [
    _R('How are you?', 'Como você está?'),
    _R('How are you today?', 'Como você está hoje?'),
    _R('Are you okay?', 'Você está bem?'),
  ],
  'goodbye': [
    _R('Bye{name}!', 'Tchau{name}!'),
    _R('Bye bye! See you soon!', 'Tchau tchau! Até logo!'),
    _R('Goodbye, friend!', 'Tchau, amigo!'),
    _R('See you later! 👋', 'Até mais!'),
    _R('Bye! Come back soon!', 'Tchau! Volte logo!'),
    _R(
      'Goodbye{name}! I will miss you!',
      'Tchau{name}! Vou sentir sua falta!',
      tier: _a2,
    ),
  ],
  'thank': [
    _R("You're welcome!", 'De nada!'),
    _R('No problem!', 'Sem problemas!'),
    _R('Anytime, friend!', 'Quando quiser, amigo!'),
    _R("You're welcome! Rawr!", 'De nada! Rawr!'),
    _R('My pleasure!', 'Por nada!'),
    _R('Thank YOU!', 'Eu que agradeço!'),
  ],
  'apology': [
    _R("That's okay!", 'Tudo bem!'),
    _R('No problem, friend!', 'Sem problemas, amigo!'),
    _R("It's okay! Everybody makes mistakes.", 'Tudo bem! Todo mundo erra.'),
    _R("Don't worry!", 'Não se preocupe!'),
    _R('All good! Big hug!', 'Tudo certo! Abraço!'),
  ],
  'affection': [
    _R('I like you too!', 'Eu também gosto de você!'),
    _R('Aww! Big hug! 🤗', 'Own! Abraço apertado!'),
    _R('You are my best friend!', 'Você é meu melhor amigo!'),
    _R('I love you too! Rawr!', 'Eu também te amo! Rawr!'),
    _R('You make me happy!', 'Você me deixa feliz!'),
    _R(
      'I like you too! You are my best friend!',
      'Eu também gosto de você! Você é meu melhor amigo!',
      tier: _a2,
    ),
  ],
  'affection.asked': [
    _R('Yes! I like you very much!', 'Sim! Eu gosto muito de você!'),
    _R('Of course! You are my friend!', 'Claro! Você é meu amigo!'),
    _R('Yes! Very, very much!', 'Sim! Muito, muito!'),
    _R('I love you! 💚', 'Eu te amo!'),
    _R('Of course I do! Big hug!', 'Claro que sim! Abraço!'),
  ],
  'praise': [
    _R('Thank you!', 'Obrigado!'),
    _R('Aww, thank you!', 'Own, obrigado!'),
    _R('Hee hee! Thank you!', 'Hihi! Obrigado!'),
    _R('You are nice too!', 'Você também é legal!'),
    _R('Thanks, friend! 💚', 'Valeu, amigo!'),
    _R(
      'Thank you! You are very nice too!',
      'Obrigado! Você também é muito legal!',
      tier: _a2,
    ),
  ],
  'age': [
    _R("I'm two! I'm a baby dino! 🦖", 'Eu tenho dois anos! Sou um dino bebê!'),
    _R('Two years old!', 'Dois anos!'),
    _R('I am two years old!', 'Eu tenho dois anos!'),
    _R("I'm a baby! Two years old!", 'Sou um bebê! Dois anos!'),
    _R(
      "I'm two. Small, but strong! Rawr!",
      'Tenho dois. Pequeno, mas forte! Rawr!',
    ),
    _R(
      "I'm two years old. Dinosaurs grow up slowly!",
      'Tenho dois anos. Dinossauros crescem devagar!',
      tier: _a2,
    ),
  ],
  'age.ask': [
    _R('And you? How old are you?', 'E você? Quantos anos você tem?'),
  ],

  // ---- how the Dino is -------------------------------------------------------------
  'feeling.fine': [
    _R("I'm happy!", 'Estou feliz!'),
    _R("I'm great!", 'Estou ótimo!'),
    _R("I'm good! Thank you!", 'Estou bem! Obrigado!'),
    _R('Happy! You are here! 😄', 'Feliz! Você está aqui!'),
    _R('Super happy! Rawr!', 'Super feliz! Rawr!'),
    _R(
      "I'm happy! Thank you for asking!",
      'Estou feliz! Obrigado por perguntar!',
      tier: _a2,
    ),
  ],
  'feeling.hunger': [
    _R("I'm hungry...", 'Estou com fome...'),
    _R("Hmm... I'm a little hungry.", 'Hmm... Estou com um pouco de fome.'),
    _R('My tummy says: food, please!', 'Minha barriga diz: comida, por favor!'),
  ],
  'feeling.thirst': [
    _R("I'm thirsty...", 'Estou com sede...'),
    _R("I'm okay... but thirsty!", 'Estou bem... mas com sede!'),
    _R('Water, please! 💧', 'Água, por favor!'),
  ],
  'feeling.energy': [
    _R("I'm sleepy...", 'Estou com sono...'),
    _R("Yawn... I'm tired.", 'Bocejo... Estou cansado.'),
    _R("I'm okay... just sleepy.", 'Estou bem... só com sono.'),
  ],
  'feeling.happiness': [
    _R("I'm a little bored...", 'Estou um pouco entediado...'),
    _R("I'm okay... Can we play?", 'Estou bem... Podemos brincar?'),
    _R("A little sad. Let's play?", 'Um pouco triste. Vamos brincar?'),
  ],
  'feeling.askBack': [
    _R('And you?', 'E você?'),
    _R('And you? How are you?', 'E você? Como você está?'),
  ],
  'doing.fine': [
    _R("I'm talking with you!", 'Estou conversando com você!'),
    _R("I'm learning English!", 'Estou aprendendo inglês!'),
    _R("I'm playing! Rawr!", 'Estou brincando! Rawr!'),
    _R("I'm waiting for you to play!", 'Estou esperando você para brincar!'),
    _R('Nothing! Just being a dino! 🦖', 'Nada! Só sendo um dino!'),
    _R(
      "I'm learning new words with my best friend!",
      'Estou aprendendo palavras novas com meu melhor amigo!',
      tier: _a2,
    ),
  ],
  'doing.hunger': [
    _R("I'm thinking about food... 🍎", 'Estou pensando em comida...'),
    _R(
      "I'm looking for something to eat!",
      'Estou procurando algo para comer!',
    ),
    _R('My tummy is talking! Grrr!', 'Minha barriga está roncando! Grrr!'),
  ],
  'doing.thirst': [
    _R("I'm looking for water! 💧", 'Estou procurando água!'),
    _R("I'm thinking about water...", 'Estou pensando em água...'),
    _R("I'm thirsty. I want a drink!", 'Estou com sede. Quero beber algo!'),
  ],
  'doing.energy': [
    _R(
      "I'm trying not to sleep... Yawn!",
      'Estou tentando não dormir... Bocejo!',
    ),
    _R("I'm resting a little.", 'Estou descansando um pouco.'),
    _R("Yawn... I'm getting sleepy.", 'Bocejo... Estou ficando com sono.'),
  ],
  'doing.happiness': [
    _R(
      "I'm a little bored... Let's play?",
      'Estou um pouco entediado... Vamos brincar?',
    ),
    _R(
      "I'm waiting for a friend to play!",
      'Estou esperando um amigo para brincar!',
    ),
    _R("Nothing... I'm bored.", 'Nada... Estou entediado.'),
  ],

  // ---- needs: "Você está com fome?" ------------------------------------------------
  'hunger.urgent': [
    _R("Yes! I'm hungry!", 'Sim! Estou com fome!'),
    _R("I'm hungry...", 'Estou com fome...'),
    _R('Yes! Food, please! 🍎', 'Sim! Comida, por favor!'),
    _R('So hungry! Can I eat?', 'Com muita fome! Posso comer?'),
    _R('Yes! My tummy is empty!', 'Sim! Minha barriga está vazia!'),
    _R(
      "I'm really hungry. Can we eat something?",
      'Estou com muita fome. Podemos comer alguma coisa?',
      tier: _a2,
    ),
  ],
  'hunger.mild': [
    _R('A little hungry!', 'Um pouco de fome!'),
    _R('Hmm... a little!', 'Hmm... um pouquinho!'),
    _R('A little bit. A snack, maybe?', 'Um pouquinho. Um lanche, talvez?'),
    _R('Just a little hungry!', 'Só um pouquinho de fome!'),
    _R('A bit! An apple would be nice! 🍎', 'Um pouco! Uma maçã seria legal!'),
  ],
  'hunger.fine': [
    _R("No, I'm full!", 'Não, estou cheio!'),
    _R(
      'No, thank you! My tummy is full!',
      'Não, obrigado! Minha barriga está cheia!',
    ),
    _R('Not now! I just ate!', 'Agora não! Acabei de comer!'),
    _R("No! I'm happy and full!", 'Não! Estou feliz e satisfeito!'),
    _R('Nope! No food for me now.', 'Não! Nada de comida agora.'),
  ],
  'thirst.urgent': [
    _R("Yes! I'm thirsty!", 'Sim! Estou com sede!'),
    _R('Water, please! 💧', 'Água, por favor!'),
    _R("I'm thirsty...", 'Estou com sede...'),
    _R('Yes! Can I have some water?', 'Sim! Posso tomar água?'),
    _R('So thirsty! Gulp!', 'Com muita sede! Glub!'),
  ],
  'thirst.mild': [
    _R('A little thirsty!', 'Um pouco de sede!'),
    _R('Hmm... a little!', 'Hmm... um pouquinho!'),
    _R('A little water would be nice!', 'Um pouco de água seria bom!'),
    _R('Just a little!', 'Só um pouquinho!'),
    _R('A bit thirsty, yes!', 'Um pouco de sede, sim!'),
  ],
  'thirst.fine': [
    _R("No, I'm not thirsty!", 'Não, não estou com sede!'),
    _R('No, thank you!', 'Não, obrigado!'),
    _R('Not now! I drank water!', 'Agora não! Eu tomei água!'),
    _R("Nope! I'm fine!", 'Não! Estou bem!'),
    _R('No! I had lots of water!', 'Não! Tomei muita água!'),
  ],
  'energy.urgent': [
    _R("Yes... I'm sleepy...", 'Sim... Estou com sono...'),
    _R('Yawn... Yes!', 'Bocejo... Sim!'),
    _R("I'm so tired...", 'Estou muito cansado...'),
    _R('Yes! Can I sleep? 😴', 'Sim! Posso dormir?'),
    _R('Sleepy... Z z z...', 'Com sono... Zzz...'),
  ],
  'energy.mild': [
    _R('A little sleepy!', 'Um pouco de sono!'),
    _R('Hmm... a little tired.', 'Hmm... um pouco cansado.'),
    _R('A bit! But I can play!', 'Um pouco! Mas eu posso brincar!'),
    _R('Just a little!', 'Só um pouquinho!'),
    _R('A little yawn... Yawn!', 'Um bocejinho... Bocejo!'),
  ],
  'energy.fine': [
    _R("No! I'm full of energy! ⚡", 'Não! Estou cheio de energia!'),
    _R("No way! Let's play!", 'De jeito nenhum! Vamos brincar!'),
    _R('Not sleepy at all!', 'Nem um pouco de sono!'),
    _R("No! I'm awake!", 'Não! Estou acordado!'),
    _R('Nope! Energy! Rawr!', 'Não! Energia! Rawr!'),
  ],

  // ---- likes: "Você gosta de maçã?" ------------------------------------------------
  'like.food': [
    _R('I love {enG}!', 'Eu adoro {ptG}!'),
    _R('Yes! {EnG} {be} yummy!', 'Sim! {PtG} {ser} uma delícia!'),
    _R('{En}? I like it!', '{Pt}? Eu gosto!'),
    _R('Yummy! I love {enG}! {emoji}', 'Delícia! Eu adoro {ptG}!'),
    _R('Of course! I like {enG}!', 'Claro! Eu gosto de {ptG}!'),
    _R(
      '{EnG} {be} one of my favorite foods!',
      '{PtG} {ser} uma das minhas comidas favoritas!',
      tier: _a2,
    ),
  ],
  'like.drink': [
    _R('I love {enG}!', 'Eu adoro {ptG}!'),
    _R('Yes! I love to drink {enG}!', 'Sim! Eu adoro tomar {ptG}!'),
    _R('{En}? Yes, please! {emoji}', '{Pt}? Sim, por favor!'),
    _R('Gulp gulp! I like {enG}!', 'Glub glub! Eu gosto de {ptG}!'),
    _R('Of course! {EnG} {be} yummy!', 'Claro! {PtG} {ser} uma delícia!'),
  ],
  'like.thing': [
    _R('I love {enG}!', 'Eu adoro {ptG}!'),
    _R('Yes! I like {enG}!', 'Sim! Eu gosto de {ptG}!'),
    _R('{En}? I like it! {emoji}', '{Pt}? Eu gosto!'),
    _R('Of course! {EnG} {be} cool!', 'Claro! {PtG} {ser} {legal}!'),
    _R('Wow, {enG}! I like {enG} a lot!', 'Uau, {ptG}! Eu gosto muito!'),
    _R(
      'Yes! I really like {enG}. Do you?',
      'Sim! Eu gosto muito de {ptG}. E você?',
      tier: _a2,
    ),
  ],
  'like.no': [
    _R(
      "Hmm... not really. I don't like {enG}.",
      'Hmm... não muito. Eu não gosto de {ptG}.',
    ),
    _R(
      "No, thank you! I don't like {enG}.",
      'Não, obrigado! Eu não gosto de {ptG}.',
    ),
    _R('{EnG}? Not for me!', '{PtG}? Não pra mim!'),
    _R("Oh no, {enG}! I don't like {enG}!", 'Ah não, {ptG}! Eu não gosto!'),
    _R(
      "Not much... It's not my favorite.",
      'Não muito... Não é o meu favorito.',
    ),
  ],
  'like.unknown': [
    _R("Hmm... I don't know that yet.", 'Hmm... Eu ainda não sei isso.'),
    _R("I don't know what that is yet!", 'Eu ainda não sei o que é isso!'),
    _R(
      "Hmm... I don't understand yet. Can you say it in English?",
      'Hmm... Eu ainda não entendi. Você pode falar em inglês?',
    ),
    _R(
      "I don't know that one! Let's try something else!",
      'Eu não conheço esse! Vamos tentar outra coisa!',
    ),
    _R(
      "Is it a food? A toy? I don't know it yet!",
      'É uma comida? Um brinquedo? Eu ainda não conheço!',
    ),
  ],

  // ---- dislikes: "O que você não gosta?" -----------------------------------------
  'dislike.general': [
    _R("I don't like rain! Brrr! 🌧️", 'Eu não gosto de chuva! Brrr!'),
    _R("I don't like snakes! 🐍", 'Eu não gosto de cobras!'),
    _R("Lemons! They're sour! 🍋", 'Limões! São azedos!'),
    _R(
      "Bees! Bzzz! I'm scared of bees! 🐝",
      'Abelhas! Bzzz! Tenho medo de abelhas!',
    ),
    _R(
      "I don't like being alone. I like you here!",
      'Eu não gosto de ficar sozinho. Gosto quando você está aqui!',
    ),
  ],
  'dislike.yes': [
    _R("Yes... I don't like {enG}.", 'Sim... Eu não gosto de {ptG}.'),
    _R('A little! {EnG}? No, thanks!', 'Um pouco! {PtG}? Não, obrigado!'),
    _R('Yes! {EnG} {be} not for me!', 'Sim! {PtG} não {ser} pra mim!'),
    _R(
      "Hmm, yes. I don't like {enG} very much.",
      'Hmm, sim. Eu não gosto muito de {ptG}.',
    ),
    _R('{EnG}? Brrr! No, thank you!', '{PtG}? Brrr! Não, obrigado!'),
  ],
  'dislike.no': [
    _R('No way! I love {enG}!', 'De jeito nenhum! Eu adoro {ptG}!'),
    _R('No! I like {enG}!', 'Não! Eu gosto de {ptG}!'),
    _R(
      'Hate {enG}? No! {EnG} {be} great!',
      'Odiar {ptG}? Não! {PtG} {ser} demais!',
    ),
    _R('Of course not! I like {enG}!', 'Claro que não! Eu gosto de {ptG}!'),
    _R('Nope! I really like {enG}!', 'Não! Eu gosto muito de {ptG}!'),
  ],

  // ---- pet activities -----------------------------------------------------------
  'offer.food': [
    _R('Food? For me? Yummy!', 'Comida? Pra mim? Delícia!'),
    _R('Ooh! Give it to me!', 'Oba! Me dá!'),
    _R('Yes, please!', 'Sim, por favor!'),
  ],
  'offer.water': [
    _R('Water! Yes, please!', 'Água! Sim, por favor!'),
    _R('Ooh, a drink!', 'Oba, uma bebida!'),
    _R('Bring it here!', 'Traz aqui!'),
  ],
  'play.invite': [
    _R("Let's play! Kick the ball! ⚽", 'Vamos brincar! Chuta a bola!'),
    _R('Ball! Throw the ball to me!', 'Bola! Joga a bola pra mim!'),
    _R("Play time! Let's play ball!", 'Hora de brincar! Vamos jogar bola!'),
  ],
  'ball.tap': [
    _R('Ball! ⚽', 'Bola!'),
    _R('The ball! I see it!', 'A bola! Eu estou vendo!'),
    _R('Ball? Kick it!', 'Bola? Chuta!'),
  ],
  'ball.drag': [
    _R('Ooh! The ball!', 'Oba! A bola!'),
    _R("I'm watching the ball!", 'Estou olhando a bola!'),
  ],
  'kick': [
    _R('Kick! ⚽', 'Chuta!'),
    _R('Run, run! 🏃', 'Corre, corre!'),
    _R('Wow! Kick it again!', 'Uau! Chuta de novo!'),
    _R('I can run fast!', 'Eu corro rápido!'),
    _R('Nice kick!', 'Belo chute!'),
  ],
  'goal': [
    _R('GOAL! 🥅 You did it!', 'GOL! Você conseguiu!'),
    _R('Goal, goal, GOAL! 🎉', 'Gol, gol, GOL!'),
    _R('What a goal! You are a star! ⭐', 'Que gol! Você é uma estrela!'),
    _R('GOAL! Rawr! We win!', 'GOL! Rawr! Ganhamos!'),
    _R('Goal! High five! 🙌', 'Gol! Toca aqui!'),
  ],
  'nudge.hunger': [
    _R("I'm hungry!", 'Estou com fome!'),
    _R(
      'My tummy is empty... Food, please!',
      'Minha barriga está vazia... Comida, por favor!',
    ),
    _R("I'm hungry! Can I eat? 🍎", 'Estou com fome! Posso comer?'),
  ],
  'nudge.thirst': [
    _R("I'm thirsty.", 'Estou com sede.'),
    _R('Water, please! 💧', 'Água, por favor!'),
    _R("I'm thirsty! Can I have water?", 'Estou com sede! Posso tomar água?'),
  ],
  'nudge.energy': [
    _R("I'm sleepy.", 'Estou com sono.'),
    _R('Yawn... I need a nap. 😴', 'Bocejo... Preciso de uma soneca.'),
    _R("I'm so tired...", 'Estou tão cansado...'),
  ],
  'nudge.happiness': [
    _R("I'm bored. Let's play!", 'Estou entediado. Vamos brincar!'),
    _R('Can we play ball? ⚽', 'Podemos jogar bola?'),
    _R(
      "I'm a little sad... Play with me?",
      'Estou um pouco triste... Brinca comigo?',
    ),
  ],

  // ---- favorites: "Qual é a sua comida favorita?" ---------------------------------
  'favorite': [
    _R('My favorite {topicEn} is {favEn}! {emoji}', '{myFavPt} é {favPt}!'),
    _R('{FavEn}! I love {favEnG}!', '{FavPt}! Eu adoro {favPtG}!'),
    _R('I love {favEnG} the most! {emoji}', 'Eu gosto mais de {favPtG}!'),
    _R(
      'Hmm... {favEn}! Definitely {favEn}!',
      'Hmm... {favPt}! Com certeza {favPt}!',
    ),
    _R('My favorite? {FavEn}, of course!', '{myFavPt}? {FavPt}, claro!'),
  ],
  'favorite.ask': [
    _R(
      'And you? What is your favorite {topicEn}?',
      'E você? Qual é {yourFavPt}?',
    ),
  ],
  'favorite.unknown': [
    _R(
      'I have many favorites! Apples, dinosaurs and soccer!',
      'Eu tenho muitos favoritos! Maçãs, dinossauros e futebol!',
    ),
    _R(
      'Favorite what? Food? Color? Animal?',
      'Favorito de quê? Comida? Cor? Animal?',
    ),
    _R(
      'Hmm... I like so many things! Apples! Green! Soccer!',
      'Hmm... Eu gosto de tantas coisas! Maçã! Verde! Futebol!',
    ),
  ],
};
