import 'dart:convert';

import '../../database/app_database.dart';
import '../nlp/inflection.dart';
import '../nlp/normalizer.dart';

/// One meaning of a word: `light` has "luz" (noun) and "leve" (adjective).
class WordSense {
  const WordSense({
    required this.portuguese,
    this.partOfSpeech,
    this.exampleEn,
    this.examplePt,
  });

  factory WordSense.fromJson(Map<String, dynamic> json) => WordSense(
    portuguese: json['pt'] as String,
    partOfSpeech: json['pos'] as String?,
    exampleEn: json['example_en'] as String?,
    examplePt: json['example_pt'] as String?,
  );

  final String portuguese;
  final String? partOfSpeech;
  final String? exampleEn;
  final String? examplePt;

  /// "laranja (fruta)" -> "laranja": what a child would actually type.
  String get bareTranslation =>
      portuguese.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();
}

/// An official word from the app's word bank. Read-only for the brain:
/// nothing a child says in conversation ever changes it.
class VocabularyEntry {
  VocabularyEntry({
    required this.id,
    required this.english,
    required this.portuguese,
    required this.category,
    required this.difficulty,
    required this.exampleEn,
    required this.examplePt,
    List<WordSense>? senses,
  }) : senses = (senses == null || senses.isEmpty)
           ? [
               WordSense(
                 portuguese: portuguese,
                 exampleEn: exampleEn,
                 examplePt: examplePt,
               ),
             ]
           : List.unmodifiable(senses);

  factory VocabularyEntry.fromWord(Word word) {
    List<WordSense>? senses;
    final raw = word.sensesJson;
    if (raw != null && raw.isNotEmpty) {
      senses = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(WordSense.fromJson)
          .toList();
    }
    return VocabularyEntry(
      id: word.id,
      english: word.englishTerm,
      portuguese: word.portugueseTranslation,
      category: word.category,
      difficulty: word.difficulty,
      exampleEn: word.exampleSentenceEn,
      examplePt: word.exampleSentencePt,
      senses: senses,
    );
  }

  final String id;
  final String english;

  /// Primary translation -- the single answer quizzes grade against.
  final String portuguese;
  final String category;
  final int difficulty;
  final String exampleEn;
  final String examplePt;

  /// Always at least one; `senses.first` is the primary sense.
  final List<WordSense> senses;

  bool get hasSeveralMeanings =>
      senses.map((s) => s.bareTranslation).toSet().length > 1;

  /// Every accepted Portuguese translation, primary first, no duplicates.
  List<String> get translations {
    final seen = <String>{};
    return [
      for (final s in senses)
        if (seen.add(Normalizer.fold(s.bareTranslation))) s.bareTranslation,
    ];
  }

  @override
  String toString() => 'VocabularyEntry($english = $portuguese)';
}

/// The app's official vocabulary, indexed for the brain's lookups. Built
/// from the `words` table -- the brain never writes back to it.
class OfficialVocabulary {
  OfficialVocabulary(Iterable<VocabularyEntry> entries)
    : entries = List.unmodifiable(entries) {
    for (final e in this.entries) {
      _byEnglish[e.english.toLowerCase()] = e;
      for (final translation in e.translations) {
        (_byPortuguese[Normalizer.fold(translation)] ??= []).add(e);
      }
      final words = e.english.split(' ').length;
      if (words > _maxTermWords) _maxTermWords = words;
    }
  }

  factory OfficialVocabulary.fromWords(Iterable<Word> words) =>
      OfficialVocabulary(words.map(VocabularyEntry.fromWord));

  static const _inflection = Inflection();

  final List<VocabularyEntry> entries;
  final Map<String, VocabularyEntry> _byEnglish = {};
  final Map<String, List<VocabularyEntry>> _byPortuguese = {};
  int _maxTermWords = 1;

  int get maxTermWords => _maxTermWords;
  Iterable<String> get englishTerms => _byEnglish.keys;
  Iterable<String> get portugueseTerms => _byPortuguese.keys;
  bool get isEmpty => entries.isEmpty;

  /// Exact English lookup, also trying base forms ("apples" -> "apple").
  VocabularyEntry? byEnglish(String term) {
    final t = term.toLowerCase().trim();
    final direct = _byEnglish[t];
    if (direct != null) return direct;
    if (t.contains(' ')) return null;
    for (final form in _inflection.baseForms(t).skip(1)) {
      final hit = _byEnglish[form];
      if (hit != null) return hit;
    }
    return null;
  }

  /// Every entry that has [term] as one of its senses ("laranja" ->
  /// orange; "frio" -> cold). Accent-insensitive.
  List<VocabularyEntry> byPortuguese(String term) =>
      _byPortuguese[Normalizer.fold(term)] ?? const [];

  VocabularyEntry? byId(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<VocabularyEntry> inCategory(String category) =>
      entries.where((e) => e.category == category).toList(growable: false);

  /// Whether [answer] is an accepted Portuguese translation of [entry]
  /// (any sense, accent-insensitive).
  bool acceptsPortuguese(VocabularyEntry entry, String answer) {
    final a = Normalizer.fold(answer);
    return entry.translations.any((t) => Normalizer.fold(t) == a);
  }
}
