import '../../brain/nlp/inflection.dart';
import '../../brain/nlp/normalizer.dart';
import '../../brain/vocabulary/official_vocabulary.dart';

enum EntityCategory {
  food,
  drink,
  animal,
  toy,
  game,
  place,
  object,
  nature,
  other,
}

/// A thing the child can talk about ("maçã", "apples", "bola"...), with
/// both languages and the words that point to it. Plain data: the
/// catalog grows by adding entries, no code changes.
class CompanionEntity {
  const CompanionEntity({
    required this.id,
    required this.english,
    this._englishPlural,
    required this.portuguese,
    this._portuguesePlural,
    this.aliases = const [],
    required this.category,
    this.countable = true,
    this.dinoLikes = true,
    this.emoji = '',
  });

  /// `APPLE`, `WATER`...
  final String id;
  final String english;
  final String? _englishPlural;
  final String portuguese;
  final String? _portuguesePlural;

  /// Extra spellings in either language (plurals, diminutives, typos
  /// kids make). Matching ignores case and accents.
  final List<String> aliases;
  final EntityCategory category;

  /// "water", "milk", "soccer" are never plural ("I like water").
  final bool countable;

  /// The Dino's own taste -- it's a character, so this never changes.
  final bool dinoLikes;
  final String emoji;

  static const _inflection = Inflection();

  /// What you'd say in "I like ___": "apples", "water".
  String get englishGeneric =>
      countable ? (_englishPlural ?? _inflection.pluralize(english)) : english;

  /// "Eu gosto de ___": "maçãs", "água".
  String get portugueseGeneric => countable
      ? (_portuguesePlural ?? pluralizePortuguese(portuguese))
      : portuguese;

  /// Every way of naming it, accent-free and lowercase.
  Iterable<String> get allNames => {
    english,
    englishGeneric,
    portuguese,
    portugueseGeneric,
    ...aliases,
  }.map(Normalizer.fold);

  bool get isEdible =>
      category == EntityCategory.food || category == EntityCategory.drink;

  /// Simple Portuguese plural, good enough for nouns in the word bank.
  static String pluralizePortuguese(String word) {
    if (word.contains(' ')) return word;
    if (word.endsWith('ão')) return '${word.substring(0, word.length - 2)}ões';
    if (RegExp(r'[rzs]$').hasMatch(word)) return '${word}es';
    if (word.endsWith('l')) return '${word.substring(0, word.length - 1)}is';
    if (word.endsWith('m')) return '${word.substring(0, word.length - 1)}ns';
    return '${word}s';
  }

  /// An official word-bank entry the catalog doesn't know ("tiger") as an
  /// entity, so "Do you like tigers?" still gets a real answer.
  factory CompanionEntity.fromWord(VocabularyEntry word) {
    final category = switch (word.category) {
      'food' => EntityCategory.food,
      'animals' => EntityCategory.animal,
      'places' => EntityCategory.place,
      'nature' => EntityCategory.nature,
      'objects' || 'clothes' || 'body' => EntityCategory.object,
      _ => EntityCategory.other,
    };
    final isVerb = word.category == 'verbs';
    return CompanionEntity(
      id: 'WORD_${word.english.toUpperCase().replaceAll(' ', '_')}',
      // "Do you like to play?" -> "I love to play!" / "Eu adoro brincar!"
      english: isVerb ? 'to ${word.english}' : word.english,
      portuguese: word.translations.first,
      category: category,
      countable: !isVerb,
      dinoLikes: !_dinoDislikes.contains(word.english),
    );
  }

  /// Word-bank things the Dino doesn't like (shared with the catalog).
  static const Set<String> _dinoDislikes = {
    'snake',
    'rain',
    'soap',
    'lemon',
    'bee',
  };

  @override
  String toString() => 'CompanionEntity($id)';
}

/// The things the companion knows how to chat about. Plain data.
class CompanionEntityCatalog {
  const CompanionEntityCatalog([this.entities = defaultEntities]);

  final List<CompanionEntity> entities;

  static const List<CompanionEntity> defaultEntities = [
    // -- food -----------------------------------------------------------------
    CompanionEntity(
      id: 'APPLE',
      english: 'apple',
      portuguese: 'maçã',
      aliases: ['maçãzinha', 'maca', 'macas'],
      category: EntityCategory.food,
      emoji: '🍎',
    ),
    CompanionEntity(
      id: 'BANANA',
      english: 'banana',
      portuguese: 'banana',
      aliases: ['bananinha'],
      category: EntityCategory.food,
      emoji: '🍌',
    ),
    CompanionEntity(
      id: 'COOKIE',
      english: 'cookie',
      portuguese: 'biscoito',
      aliases: ['bolacha', 'bolachas', 'biscoitinho', 'cookies'],
      category: EntityCategory.food,
      emoji: '🍪',
    ),
    CompanionEntity(
      id: 'PIZZA',
      english: 'pizza',
      portuguese: 'pizza',
      category: EntityCategory.food,
      emoji: '🍕',
    ),
    CompanionEntity(
      id: 'CAKE',
      english: 'cake',
      portuguese: 'bolo',
      aliases: ['bolinho'],
      category: EntityCategory.food,
      emoji: '🍰',
    ),
    CompanionEntity(
      id: 'ICE_CREAM',
      english: 'ice cream',
      portuguese: 'sorvete',
      portuguesePlural: 'sorvete',
      aliases: ['sorvetes', 'sorvetinho', 'picolé'],
      category: EntityCategory.food,
      countable: false,
      emoji: '🍦',
    ),
    CompanionEntity(
      id: 'CHOCOLATE',
      english: 'chocolate',
      portuguese: 'chocolate',
      category: EntityCategory.food,
      countable: false,
      emoji: '🍫',
    ),
    CompanionEntity(
      id: 'CARROT',
      english: 'carrot',
      portuguese: 'cenoura',
      aliases: ['cenourinha'],
      category: EntityCategory.food,
      emoji: '🥕',
    ),
    CompanionEntity(
      id: 'LEMON',
      english: 'lemon',
      portuguese: 'limão',
      aliases: ['limao', 'limoes'],
      category: EntityCategory.food,
      dinoLikes: false,
      emoji: '🍋',
    ),
    CompanionEntity(
      id: 'FOOD',
      english: 'food',
      portuguese: 'comida',
      aliases: ['comidinha', 'lanche'],
      category: EntityCategory.food,
      countable: false,
      emoji: '🍽️',
    ),
    // -- drinks ---------------------------------------------------------------
    CompanionEntity(
      id: 'WATER',
      english: 'water',
      portuguese: 'água',
      aliases: ['aguinha', 'agua'],
      category: EntityCategory.drink,
      countable: false,
      emoji: '💧',
    ),
    CompanionEntity(
      id: 'MILK',
      english: 'milk',
      portuguese: 'leite',
      aliases: ['leitinho'],
      category: EntityCategory.drink,
      countable: false,
      emoji: '🥛',
    ),
    CompanionEntity(
      id: 'JUICE',
      english: 'juice',
      portuguese: 'suco',
      aliases: ['suquinho'],
      category: EntityCategory.drink,
      countable: false,
      emoji: '🧃',
    ),
    // -- play -----------------------------------------------------------------
    CompanionEntity(
      id: 'SOCCER',
      english: 'soccer',
      portuguese: 'futebol',
      aliases: ['football', 'futebolzinho', 'bater bola'],
      category: EntityCategory.game,
      countable: false,
      emoji: '⚽',
    ),
    CompanionEntity(
      id: 'BALL',
      english: 'ball',
      portuguese: 'bola',
      aliases: ['bolinha'],
      category: EntityCategory.toy,
      emoji: '⚽',
    ),
    CompanionEntity(
      id: 'GAME',
      english: 'game',
      portuguese: 'jogo',
      aliases: ['joguinho', 'brincadeira', 'brincadeiras', 'videogame'],
      category: EntityCategory.game,
      emoji: '🎮',
    ),
    CompanionEntity(
      id: 'CAR',
      english: 'car',
      portuguese: 'carro',
      aliases: ['carrinho', 'carrinhos'],
      category: EntityCategory.toy,
      emoji: '🚗',
    ),
    CompanionEntity(
      id: 'BOOK',
      english: 'book',
      portuguese: 'livro',
      aliases: ['livrinho', 'livrinhos', 'historinha'],
      category: EntityCategory.object,
      emoji: '📖',
    ),
    // -- animals --------------------------------------------------------------
    CompanionEntity(
      id: 'DINOSAUR',
      english: 'dinosaur',
      portuguese: 'dinossauro',
      aliases: ['dinossaurinho', 'dinossauros'],
      category: EntityCategory.animal,
      emoji: '🦖',
    ),
    CompanionEntity(
      id: 'CAT',
      english: 'cat',
      portuguese: 'gato',
      aliases: ['gatinho', 'gatinhos', 'gata', 'kitty'],
      category: EntityCategory.animal,
      emoji: '🐱',
    ),
    CompanionEntity(
      id: 'DOG',
      english: 'dog',
      portuguese: 'cachorro',
      aliases: [
        'cachorrinho',
        'cachorrinhos',
        'cão',
        'cães',
        'doguinho',
        'puppy',
      ],
      category: EntityCategory.animal,
      emoji: '🐶',
    ),
    CompanionEntity(
      id: 'SNAKE',
      english: 'snake',
      portuguese: 'cobra',
      aliases: ['cobrinha'],
      category: EntityCategory.animal,
      dinoLikes: false,
      emoji: '🐍',
    ),
    CompanionEntity(
      id: 'BEE',
      english: 'bee',
      portuguese: 'abelha',
      aliases: ['abelhinha'],
      category: EntityCategory.animal,
      dinoLikes: false,
      emoji: '🐝',
    ),
    // -- places & things ----------------------------------------------------------
    CompanionEntity(
      id: 'BED',
      english: 'bed',
      portuguese: 'cama',
      aliases: ['caminha'],
      category: EntityCategory.place,
      emoji: '🛏️',
    ),
    CompanionEntity(
      id: 'SCHOOL',
      english: 'school',
      portuguese: 'escola',
      aliases: ['escolinha', 'colégio'],
      category: EntityCategory.place,
      countable: false,
      emoji: '🏫',
    ),
    CompanionEntity(
      id: 'RAIN',
      english: 'rain',
      portuguese: 'chuva',
      aliases: ['chuvinha'],
      category: EntityCategory.nature,
      countable: false,
      dinoLikes: false,
      emoji: '🌧️',
    ),
  ];

  CompanionEntity? byId(String id) {
    for (final e in entities) {
      if (e.id == id) return e;
    }
    return null;
  }
}
