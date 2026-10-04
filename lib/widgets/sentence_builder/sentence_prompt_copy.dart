/// Category -> generic "situation" prompt / emoji, for
/// [SentenceExerciseStyle.situationHint]/[SentenceExerciseStyle.emojiHint].
/// Covers the 15 real categories in the seed data (`animals, colors,
/// family, food, greetings, numbers, objects, verbs, feelings, nature,
/// people, places, adjectives, body, clothes, time`); a fallback covers any
/// category added later without this file needing an update.
const Map<String, String> _situationByCategory = {
  'animals': 'Você está falando sobre animais.',
  'colors': 'Você está descrevendo uma cor.',
  'family': 'Você está falando sobre a família.',
  'food': 'Você está falando sobre comida.',
  'greetings': 'Você está cumprimentando alguém.',
  'numbers': 'Você está falando sobre números.',
  'objects': 'Você está falando sobre um objeto.',
  'verbs': 'Você está descrevendo uma ação.',
  'feelings': 'Você está falando sobre sentimentos.',
  'nature': 'Você está falando sobre a natureza.',
  'people': 'Você está falando sobre pessoas.',
  'places': 'Você está falando sobre um lugar.',
  'adjectives': 'Você está descrevendo alguma coisa.',
  'body': 'Você está falando sobre o corpo.',
  'clothes': 'Você está falando sobre roupas.',
  'time': 'Você está falando sobre o tempo.',
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
  'feelings': '😊',
  'nature': '🌳',
  'people': '🧒',
  'places': '🏫',
  'adjectives': '✨',
  'body': '✋',
  'clothes': '👕',
  'time': '🕐',
};

String situationFor(String category) =>
    _situationByCategory[category] ?? 'Monte a frase abaixo.';

String emojiFor(String category) => _emojiByCategory[category] ?? '🦖';
