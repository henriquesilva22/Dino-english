/// Category -> generic "situation" prompt / emoji, for
/// [SentenceExerciseStyle.situationHint]/[SentenceExerciseStyle.emojiHint].
/// Covers the 8 real categories in the seed data (`animals, colors,
/// family, food, greetings, numbers, objects, verbs`); a fallback covers
/// any category added later without this file needing an update.
const Map<String, String> _situationByCategory = {
  'animals': 'Você está falando sobre animais.',
  'colors': 'Você está descrevendo uma cor.',
  'family': 'Você está falando sobre a família.',
  'food': 'Você está falando sobre comida.',
  'greetings': 'Você está cumprimentando alguém.',
  'numbers': 'Você está falando sobre números.',
  'objects': 'Você está falando sobre um objeto.',
  'verbs': 'Você está descrevendo uma ação.',
};

const Map<String, String> _emojiByCategory = {
  'animals': '🐶',
  'colors': '🎨',
  'family': '👪',
  'food': '🍎',
  'greetings': '👋',
  'numbers': '🔢',
  'objects': '📦',
  'verbs': '🏃',
};

String situationFor(String category) =>
    _situationByCategory[category] ?? 'Monte a frase abaixo.';

String emojiFor(String category) => _emojiByCategory[category] ?? '🦖';
