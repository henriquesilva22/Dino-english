/// The grammar the sentence templates need: a verb goes in "Eu vou
/// {WORD} amanhã.", a noun in "Eu quero {um} {WORD}.".
enum WordType {
  verb,
  noun,
  adjective,
  emotion,

  /// Greetings and set phrases ("hello", "thank you").
  expression;

  static WordType parse(String? name) =>
      WordType.values.asNameMap()[name] ?? WordType.expression;
}

/// A Portuguese sentence with a `{WORD}` slot for the English word and
/// optional article slots (`{um}`, `{o}`, `{O}`) filled by the noun's
/// gender. [level] 1 is a short sentence for beginners; 2 and 3 add more
/// Portuguese around the same single English word.
class SentenceTemplate {
  const SentenceTemplate(this.text, {this.level = 1});

  factory SentenceTemplate.fromJson(Object json) => switch (json) {
    final String text => SentenceTemplate(text),
    final Map<String, dynamic> map => SentenceTemplate(
      map['t'] as String,
      level: (map['level'] as num?)?.toInt() ?? 1,
    ),
    _ => throw FormatException('Bad template: $json'),
  };

  final String text;
  final int level;
}

/// "I walk every day." / "Eu caminho todos os dias."
class WordExample {
  const WordExample(this.english, this.portuguese);

  final String english;
  final String portuguese;
}

/// One English word the Dino can slip into a Portuguese sentence and
/// teach: its short child-friendly meaning, grammar, the sentences it
/// fits in and what the speech recognizer may hear instead of it.
class LearningWord {
  const LearningWord({
    required this.english,
    required this.portuguese,
    required this.type,
    this.category = 'general',
    this.difficulty = 1,
    this.feminine = false,
    this.aliases = const [],
    this.pronunciation,
    this.examples = const [],
    this.templates = const [],
    this.useTypeTemplates = true,
    this.contexts = const [],
  });

  factory LearningWord.fromJson(Map<String, dynamic> json) {
    final templates = [
      for (final t in json['templates'] as List? ?? const [])
        SentenceTemplate.fromJson(t as Object),
    ];
    return LearningWord(
      english: (json['word'] as String).toLowerCase(),
      portuguese: json['pt'] as String,
      type: WordType.parse(json['type'] as String?),
      category: json['category'] as String? ?? 'general',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      feminine: json['gender'] == 'f',
      aliases: [
        for (final a in json['aliases'] as List? ?? const [])
          (a as String).toLowerCase(),
      ],
      pronunciation: json['say'] as String?,
      examples: [
        for (final e in json['examples'] as List? ?? const [])
          WordExample(
            (e as Map<String, dynamic>)['en'] as String,
            e['pt'] as String,
          ),
      ],
      templates: templates,
      // A word with its own sentences uses only those unless it asks
      // for the generic ones too.
      useTypeTemplates: json['typeTemplates'] as bool? ?? templates.isEmpty,
      contexts: [
        for (final c in json['contexts'] as List? ?? const []) c as String,
      ],
    );
  }

  /// Lower case: `walk`, `thank you`.
  final String english;

  /// The short meaning a child understands: `caminhar`, `com sono`.
  final String portuguese;
  final WordType type;
  final String category;

  /// 1 (first words) .. 3.
  final int difficulty;

  /// Nouns: "uma APPLE" (true) / "um BOOK".
  final bool feminine;

  /// What the recognizer may write for this word ("wok" for walk):
  /// accepted as a correct repetition.
  final List<String> aliases;

  /// A Portuguese-spelled hint of the sound ("uók"), for the UI.
  final String? pronunciation;
  final List<WordExample> examples;
  final List<SentenceTemplate> templates;
  final bool useTypeTemplates;

  /// Moments it fits naturally: `food`, `drink`, `play`, `sleep`...
  final List<String> contexts;

  /// How it is shown and voiced inside a sentence: `WALK`.
  String get display => english.toUpperCase();

  @override
  String toString() => 'LearningWord($english = $portuguese)';
}
