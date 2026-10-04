import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../brain/nlp/inflection.dart';
import '../../brain/nlp/normalizer.dart';
import '../companion_response.dart';
import 'learning_word.dart';

/// The offline bank behind the Dino's Portuguese-with-English sentences:
/// words, the sentence templates per word type and the lesson phrases
/// ("{WORD} significa {MEANING}."). All of it is data
/// (`assets/learning/hybrid_lessons.json`), so the content grows without
/// touching the logic.
class LearningWordBank {
  LearningWordBank({
    required Iterable<LearningWord> words,
    this._typeTemplates = const {},
    this._phrases = const {},
  }) : words = List.unmodifiable(words) {
    for (final w in this.words) {
      _byEnglish[w.english] = w;
      for (final alias in w.aliases) {
        _byAlias.putIfAbsent(alias, () => w);
      }
    }
  }

  factory LearningWordBank.fromJson(Map<String, dynamic> json) {
    final templates = <String, List<SentenceTemplate>>{
      for (final MapEntry(:key, :value)
          in (json['templates'] as Map<String, dynamic>? ?? const {}).entries)
        key: [
          for (final t in value as List) SentenceTemplate.fromJson(t as Object),
        ],
    };
    final phrases = <String, List<String>>{
      for (final MapEntry(:key, :value)
          in (json['phrases'] as Map<String, dynamic>? ?? const {}).entries)
        key: [for (final p in value as List) p as String],
    };
    return LearningWordBank(
      words: [
        for (final w in json['words'] as List)
          LearningWord.fromJson(w as Map<String, dynamic>),
      ],
      typeTemplates: templates,
      phrases: phrases,
    );
  }

  static const String asset = 'assets/learning/hybrid_lessons.json';

  /// Decoded here, not with `loadString` (which hands big files to an
  /// isolate): the file is small and this keeps the load predictable.
  static Future<LearningWordBank> load(AssetBundle bundle) async {
    final data = await bundle.load(asset);
    final text = utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return LearningWordBank.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  static const _inflection = Inflection();

  final List<LearningWord> words;
  final Map<String, List<SentenceTemplate>> _typeTemplates;
  final Map<String, List<String>> _phrases;
  final Map<String, LearningWord> _byEnglish = {};
  final Map<String, LearningWord> _byAlias = {};

  bool get isEmpty => words.isEmpty;

  /// `walk`, `Walk!`, `walking` -> walk. Aliases ("wok") are not words.
  LearningWord? byEnglish(String term) {
    final t = Normalizer.fold(term).replaceAll(RegExp(r"[^a-z' ]"), '').trim();
    if (t.isEmpty) return null;
    final direct = _byEnglish[t];
    if (direct != null) return direct;
    if (t.contains(' ')) return null;
    for (final form in _inflection.baseForms(t).skip(1)) {
      final hit = _byEnglish[form];
      if (hit != null) return hit;
    }
    return null;
  }

  /// The word a recognizer spelling ("wok") stands for, if any.
  LearningWord? byAlias(String heard) => _byAlias[heard.toLowerCase()];

  /// Every sentence [word] fits in: its own, plus the ones for its type
  /// (`noun.food`, then `noun`) when it uses them.
  List<SentenceTemplate> templatesFor(LearningWord word) => [
    ...word.templates,
    if (word.useTypeTemplates) ...[
      ...?_typeTemplates['${word.type.name}.${word.category}'],
      if (!_typeTemplates.containsKey('${word.type.name}.${word.category}'))
        ...?_typeTemplates[word.type.name],
    ],
  ];

  /// A lesson phrase ([key] in the bank's `phrases`) as a mixed line:
  /// `{WORD}` is the English word (voiced in English), `{MEANING}` its
  /// meaning, `*...*` other English bits. Null when the bank has none.
  CompanionLine? phrase(
    String key,
    Random random, {
    LearningWord? word,
    Map<String, String> vars = const {},
  }) {
    final pool = _phrases[key];
    if (pool == null || pool.isEmpty) return null;
    var text = pool[random.nextInt(pool.length)];
    if (word != null) {
      text = text
          .replaceAll('{WORD}', '*${word.display}*')
          .replaceAll('{MEANING}', word.portuguese);
    }
    vars.forEach((k, v) => text = text.replaceAll('{$k}', v));
    return CompanionLine.marked(text);
  }

  bool hasPhrase(String key) => _phrases[key]?.isNotEmpty ?? false;
}
