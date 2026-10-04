/// What the child wants from the companion, as found by
/// `CompanionIntentDetector`. Social and care intents are answered by
/// the companion itself (`ResponseSelector`); learning intents (words,
/// quizzes, memory) go to the `DinoBrain` dialogue backend.
enum CompanionIntent {
  // -- small talk ---------------------------------------------------------
  greeting,
  goodbye,
  askName,
  askAge,
  askHowAreYou,
  askWhatAreYouDoing,

  // -- likes ----------------------------------------------------------------
  /// "Você gosta de maçã?" / "Do you like apples?"
  askLike,

  /// "Você odeia cobras?" / "What don't you like?"
  askDislike,

  /// "Qual é a sua comida favorita?"
  askFavorite,

  // -- needs ----------------------------------------------------------------
  askHungry,
  askThirsty,
  askSleepy,

  /// "Vamos brincar?" -- play with the Dino.
  askPlay,
  askHelp,

  // -- feelings ---------------------------------------------------------------
  affection,
  praise,
  thank,
  apology,

  // -- things mentioned (no clear question) -----------------------------------
  /// "Eu quero comer uma maçã agora" -- a food word in a free sentence.
  food,
  water,
  play,
  sleep,

  // -- learning ---------------------------------------------------------------
  /// "Water means água" -- the child teaches a word.
  learnWord,

  /// "What does water mean?" / "Como se diz cachorro?"
  translateWord,

  /// The child repeats the word the Dino asked for.
  repeatWord,

  /// "Fala português", "Não entendi": answer in Portuguese (once).
  requestPortuguese,

  /// "O que significa?", "Traduz isso": the last reply + its meaning.
  requestTranslation,

  // -- commands ---------------------------------------------------------------
  commandEat,
  commandDrink,
  commandPlay,
  commandSleep,

  /// Any other request ("jump!", "dance", "wake up").
  commandOther,

  // -- dialogue backend (DinoBrain) -------------------------------------------
  askMemory,
  answer,
  yes,
  no,
  startActivity,
  askActivity,
  askReward,

  unknown,
}
