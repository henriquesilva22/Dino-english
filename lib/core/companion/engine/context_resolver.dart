import '../../brain/context/conversation_context.dart';
import '../../brain/model/dino_enums.dart';
import '../../brain/nlp/normalizer.dart';
import '../companion_state.dart';
import 'companion_entity.dart';
import 'companion_intent.dart';
import 'companion_intent_detector.dart';
import 'vocabulary_detector.dart';

/// Who answers: the companion's own responses (small talk, likes, needs,
/// care) or the `DinoBrain` (words, quizzes, memory, names...).
enum ResponseRoute { companion, brain }

/// How strongly a need is felt (0..100 levels of `CompanionState`).
enum NeedBand { urgent, mild, fine }

/// A "favorite ___" topic and the Dino's answer for it.
class FavoriteTopic {
  const FavoriteTopic({
    required this.english,
    required this.myFavoritePt,
    required this.yourFavoritePt,
    required this.favorite,
    this.brainCategory,
  });

  /// "food" in "my favorite food".
  final String english;

  /// "Minha comida favorita".
  final String myFavoritePt;

  /// "a sua comida favorita".
  final String yourFavoritePt;
  final CompanionEntity favorite;

  /// Word-bank category the brain can remember the child's answer in.
  final String? brainCategory;
}

/// Everything needed to answer one sentence.
class ResolvedContext {
  const ResolvedContext({
    required this.route,
    required this.intent,
    required this.tier,
    this.entity,
    this.detectedWords = const [],
    this.need,
    this.band = NeedBand.fine,
    this.topic,
    this.childName,
    this.asksBack = false,
  });

  final ResponseRoute route;
  final CompanionIntent intent;
  final EnglishTier tier;

  /// The thing the sentence is about (APPLE...), if any.
  final CompanionEntity? entity;

  /// English terms of official words heard in the sentence.
  final List<String> detectedWords;

  /// The need asked about (hunger for "Tá com fome?") or felt the most.
  final DinoNeed? need;
  final NeedBand band;
  final FavoriteTopic? topic;
  final String? childName;

  /// "Do you like me?" (affection asked as a question).
  final bool asksBack;
}

/// Fourth step: puts the sentence in context -- the Dino's needs, the
/// child's level and name, the open question, the thing talked about --
/// and decides who answers.
class ContextResolver {
  const ContextResolver();

  /// Intents the companion answers itself.
  static const Set<CompanionIntent> companionIntents = {
    CompanionIntent.greeting,
    CompanionIntent.goodbye,
    CompanionIntent.askAge,
    CompanionIntent.askHowAreYou,
    CompanionIntent.askWhatAreYouDoing,
    CompanionIntent.askLike,
    CompanionIntent.askDislike,
    CompanionIntent.askFavorite,
    CompanionIntent.askHungry,
    CompanionIntent.askThirsty,
    CompanionIntent.askSleepy,
    CompanionIntent.askPlay,
    CompanionIntent.affection,
    CompanionIntent.praise,
    CompanionIntent.thank,
    CompanionIntent.apology,
    CompanionIntent.commandEat,
    CompanionIntent.commandDrink,
    CompanionIntent.commandPlay,
    CompanionIntent.commandSleep,
  };

  static const double _urgentBelow = 35;
  static const double _mildBelow = 70;

  ResolvedContext resolve({
    required IntentMatch match,
    required String folded,
    required int tokenCount,
    required bool isQuestion,
    required DetectedVocabulary vocabulary,
    required VocabularyDetector detector,
    required CompanionState state,
    required ConversationContext conversation,
    required int level,
    String? childName,
    CompanionEntityCatalog catalog = const CompanionEntityCatalog(),
  }) {
    var intent = match.intent;
    final slot = match.slot;
    final entity =
        (slot == null ? null : detector.entityIn(slot)) ?? vocabulary.first;

    // A known thing in a sentence nobody has a rule for: it's about that
    // thing ("Eu quero comer uma maçã agora" -> FOOD + APPLE).
    if (intent == CompanionIntent.unknown && entity != null) {
      intent = switch (entity.category) {
        EntityCategory.food => CompanionIntent.food,
        EntityCategory.drink => CompanionIntent.water,
        EntityCategory.toy || EntityCategory.game => CompanionIntent.play,
        _ when entity.id == 'BED' => CompanionIntent.sleep,
        _ => intent,
      };
    }

    // The Dino asked for a word ("Say: play!", a quiz, "your favorite
    // food?"): a short plain reply is that answer, even when it looks
    // like a command ("play", "eat") -- the brain grades it.
    final pending = conversation.pending;
    final awaitsWord =
        pending is RepeatWordQuestion ||
        pending is QuizQuestion ||
        pending is PreferenceQuestion ||
        pending is TeachTranslationQuestion;
    if (awaitsWord && tokenCount <= 3 && !isQuestion) {
      intent = pending is RepeatWordQuestion
          ? CompanionIntent.repeatWord
          : CompanionIntent.answer;
    }

    final need = switch (intent) {
      CompanionIntent.askHungry => DinoNeed.hunger,
      CompanionIntent.askThirsty => DinoNeed.thirst,
      CompanionIntent.askSleepy => DinoNeed.energy,
      _ => state.mostUrgentNeed,
    };

    // Asleep: only the brain's snoring / "wake up" handling applies.
    final route = !state.isSleeping && companionIntents.contains(intent)
        ? ResponseRoute.companion
        : ResponseRoute.brain;

    return ResolvedContext(
      route: route,
      intent: intent,
      tier: EnglishTier.forLevel(level),
      entity: entity,
      detectedWords: [for (final w in vocabulary.words) w.english],
      need: need,
      band: need == null ? NeedBand.fine : _band(state.valueOf(need)),
      topic: intent == CompanionIntent.askFavorite
          ? _topic(slot, entity, catalog)
          : null,
      childName: childName,
      asksBack: RegExp(
        r'do you (?:like|love) me|gosta de mim|me ama',
      ).hasMatch(folded),
    );
  }

  static NeedBand _band(double value) {
    if (value < _urgentBelow) return NeedBand.urgent;
    if (value < _mildBelow) return NeedBand.mild;
    return NeedBand.fine;
  }

  static FavoriteTopic? _topic(
    String? slot,
    CompanionEntity? entity,
    CompanionEntityCatalog catalog,
  ) {
    final text = Normalizer.fold(slot ?? '');
    String? key;
    for (final (pattern, k) in _topicWords) {
      if (pattern.hasMatch(text)) {
        key = k;
        break;
      }
    }
    key ??= switch (entity?.category) {
      EntityCategory.food => 'food',
      EntityCategory.drink => 'drink',
      EntityCategory.animal => 'animal',
      EntityCategory.toy => 'toy',
      EntityCategory.game => 'game',
      _ => null,
    };
    return key == null ? null : _topics(catalog)[key];
  }

  static final List<(RegExp, String)> _topicWords = [
    (RegExp(r'\b(?:comidas?|food|foods|frutas?|fruits?|lanches?)\b'), 'food'),
    (RegExp(r'\b(?:bebidas?|drinks?)\b'), 'drink'),
    (RegExp(r'\b(?:animal|animais|animals?|bichos?|pets?)\b'), 'animal'),
    (RegExp(r'\b(?:cor|cores|colou?rs?)\b'), 'color'),
    (RegExp(r'\b(?:brinquedos?|toys?)\b'), 'toy'),
    (RegExp(r'\b(?:jogos?|games?|brincadeiras?|esportes?|sports?)\b'), 'game'),
    (RegExp(r'\b(?:lugar|lugares|places?)\b'), 'place'),
  ];

  static Map<String, FavoriteTopic> _topics(CompanionEntityCatalog c) => {
    'food': FavoriteTopic(
      english: 'food',
      myFavoritePt: 'Minha comida favorita',
      yourFavoritePt: 'a sua comida favorita',
      favorite: c.byId('APPLE')!,
      brainCategory: 'food',
    ),
    'drink': FavoriteTopic(
      english: 'drink',
      myFavoritePt: 'Minha bebida favorita',
      yourFavoritePt: 'a sua bebida favorita',
      favorite: c.byId('MILK')!,
    ),
    'animal': FavoriteTopic(
      english: 'animal',
      myFavoritePt: 'Meu animal favorito',
      yourFavoritePt: 'o seu animal favorito',
      favorite: c.byId('DINOSAUR')!,
      brainCategory: 'animals',
    ),
    'color': const FavoriteTopic(
      english: 'color',
      myFavoritePt: 'Minha cor favorita',
      yourFavoritePt: 'a sua cor favorita',
      favorite: CompanionEntity(
        id: 'GREEN',
        english: 'green',
        portuguese: 'verde',
        category: EntityCategory.other,
        countable: false,
        emoji: '💚',
      ),
      brainCategory: 'colors',
    ),
    'toy': FavoriteTopic(
      english: 'toy',
      myFavoritePt: 'Meu brinquedo favorito',
      yourFavoritePt: 'o seu brinquedo favorito',
      favorite: c.byId('BALL')!,
    ),
    'game': FavoriteTopic(
      english: 'game',
      myFavoritePt: 'Meu jogo favorito',
      yourFavoritePt: 'o seu jogo favorito',
      favorite: c.byId('SOCCER')!,
    ),
    'place': const FavoriteTopic(
      english: 'place',
      myFavoritePt: 'Meu lugar favorito',
      yourFavoritePt: 'o seu lugar favorito',
      favorite: CompanionEntity(
        id: 'PARK',
        english: 'park',
        portuguese: 'parque',
        category: EntityCategory.place,
        countable: false,
        emoji: '🌳',
      ),
    ),
  };
}
