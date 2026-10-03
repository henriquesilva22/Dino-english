/// Result of [Normalizer.normalize]: the cleaned text plus the one bit of
/// punctuation that carries meaning ("water means água" vs "water means
/// água?").
class NormalizedInput {
  const NormalizedInput({
    required this.raw,
    required this.text,
    required this.isQuestion,
  });

  /// Exactly what the child typed/said.
  final String raw;

  /// Lowercase, contractions expanded, punctuation removed, single
  /// spaces. Accents are kept (Portuguese words are shown back to the
  /// child); compare with [Normalizer.fold] when accents shouldn't matter.
  final String text;
  final bool isQuestion;

  bool get isEmpty => text.isEmpty;
}

/// First pipeline step: turns free child input ("Wat's WATER mean??") into
/// a predictable form ("what is water mean") for the rule-based stages.
class Normalizer {
  const Normalizer();

  /// Contractions and chat/kid shorthand, applied on whole words.
  static const Map<String, String> _expansions = {
    "what's": 'what is',
    'whats': 'what is',
    'wats': 'what is',
    "wat's": 'what is',
    'wat': 'what',
    "who's": 'who is',
    "where's": 'where is',
    "how's": 'how is',
    "that's": 'that is',
    "it's": 'it is',
    "i'm": 'i am',
    'im': 'i am',
    "you're": 'you are',
    "we're": 'we are',
    "they're": 'they are',
    "don't": 'do not',
    'dont': 'do not',
    "doesn't": 'does not',
    'doesnt': 'does not',
    "didn't": 'did not',
    "can't": 'can not',
    'cant': 'can not',
    'cannot': 'can not',
    "won't": 'will not',
    "isn't": 'is not',
    "aren't": 'are not',
    "let's": 'let us',
    'lets': 'let us',
    "i'd": 'i would',
    "i'll": 'i will',
    "you'll": 'you will',
    'u': 'you',
    'ur': 'your',
    'r': 'are',
    'pls': 'please',
    'plz': 'please',
    'thx': 'thanks',
    'ty': 'thanks',
    'wanna': 'want to',
    'gonna': 'going to',
    'vc': 'você',
    'voce': 'você',
    'q': 'que',
    'oq': 'o que',
    'pq': 'por que',
    'tb': 'também',
    'tbm': 'também',
  };

  static const Map<String, String> _accentFold = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  NormalizedInput normalize(String input) {
    final raw = input;
    var text = input.toLowerCase().replaceAll(RegExp('[‘’´`]'), "'").trim();
    final isQuestion =
        text.contains('?') ||
        RegExp(
          r'^(what|how|who|where|why|when|which|do|does|did|can|could|are|is|'
          r'will|would|o que|como|qual|quem|onde|por que|você|voce|vc)\b',
        ).hasMatch(text);

    // Separate punctuation from words (keeping apostrophes inside words
    // for the contraction pass), then expand contractions word by word.
    text = text.replaceAll(RegExp(r"[^\p{L}\p{N}'\s-]", unicode: true), ' ');
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => _expansions[w] ?? w)
        .join(' ');

    text = words
        .replaceAll(RegExp(r"'s\b"), '') // possessive: "dino's" -> "dino"
        .replaceAll(RegExp(r"['-]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Kids stretch words: "hellooooo" -> "helloo" -> fuzzy handles the rest.
    text = text.replaceAllMapped(
      RegExp(r'(\p{L})\1{2,}', unicode: true),
      (m) => '${m[1]}${m[1]}',
    );

    return NormalizedInput(raw: raw, text: text, isQuestion: isQuestion);
  }

  /// Lowercase and accent-free, for comparisons ("agua" == "água").
  static String fold(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accentFold[char] ?? char);
    }
    return buffer.toString().trim();
  }
}
