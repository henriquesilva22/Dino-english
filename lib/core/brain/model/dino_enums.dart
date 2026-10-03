/// Shared vocabulary of the DinoBrain: what the Dino can do, need, go to
/// and suggest. Kept free of Flutter so the whole brain is testable as
/// plain Dart.
library;

/// The Dino's needs (My Talking Tom style). Each is a 0..1 "satisfied"
/// level in [DinoStatus]: 1 = fully satisfied, 0 = urgent.
enum DinoNeed { hunger, thirst, energy, hygiene, happiness }

/// Animations the 3D Dino may play. Names are intent, not clip names --
/// the UI maps them to whatever clips the model actually has.
enum DinoAnimation {
  idle,
  happy,
  sad,
  think,
  wave,
  jump,
  dance,
  sing,
  eat,
  drink,
  sleep,
  roar,
  run,
  sit,
  walk,
}

/// Objects in the Dino's room it can walk to.
enum DinoObject { bed, food, water, bathroom, toys }

/// App activities the Dino can suggest or start. Maps 1:1 to existing
/// screens (Estudar, Word Slash, Montar Frase, Prova, Aventura).
enum DinoActivity { study, wordSlash, sentenceBuilder, exam, adventure }

extension DinoActivityCopy on DinoActivity {
  /// English name the Dino says out loud.
  String get spokenName => switch (this) {
    DinoActivity.study => 'study new words',
    DinoActivity.wordSlash => 'Word Slash',
    DinoActivity.sentenceBuilder => 'build sentences',
    DinoActivity.exam => 'take a test',
    DinoActivity.adventure => 'go on an adventure',
  };

  String get portugueseName => switch (this) {
    DinoActivity.study => 'estudar palavras',
    DinoActivity.wordSlash => 'Word Slash',
    DinoActivity.sentenceBuilder => 'montar frases',
    DinoActivity.exam => 'fazer a prova',
    DinoActivity.adventure => 'ir para a aventura',
  };
}

/// Ways the child takes care of the Dino (buttons or "eat an apple"). The
/// brain only *requests* care via `CareAction`; the `CompanionEngine`
/// applies it to the persisted needs and decides the XP.
enum DinoCare { feed, water, play, sleep }

/// CEFR-like band of the child's English, derived from the app level, so
/// beginners hear "Hi! I'm Dino!" instead of longer sentences.
enum EnglishTier {
  a1,
  a2,
  b1;

  static EnglishTier forLevel(int level) {
    if (level < 8) return EnglishTier.a1;
    if (level < 20) return EnglishTier.a2;
    return EnglishTier.b1;
  }
}
