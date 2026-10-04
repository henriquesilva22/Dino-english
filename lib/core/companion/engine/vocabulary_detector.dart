import '../../brain/nlp/normalizer.dart';
import '../../brain/nlp/tokenizer.dart';
import '../../brain/vocabulary/official_vocabulary.dart';
import 'companion_entity.dart';
import 'text_normalizer.dart';

class DetectedVocabulary {
  const DetectedVocabulary({this.entities = const [], this.words = const []});

  /// Things mentioned, in sentence order ("maçã" -> APPLE).
  final List<CompanionEntity> entities;

  /// Official word-bank words mentioned (English terms), for teaching
  /// and progress -- never invented.
  final List<VocabularyEntry> words;

  CompanionEntity? get first => entities.isEmpty ? null : entities.first;
}

/// Second step: finds known things and official words anywhere in the
/// sentence, so even "Eu quero comer uma maçã agora" (no rule for the
/// whole sentence) is understood as being about an APPLE.
class VocabularyDetector {
  VocabularyDetector(
    this._vocabulary, {
    CompanionEntityCatalog catalog = const CompanionEntityCatalog(),
  }) {
    for (final entity in catalog.entities) {
      for (final name in entity.allNames) {
        _byName.putIfAbsent(name, () => entity);
        final words = name.split(' ').length;
        if (words > _maxWords) _maxWords = words;
      }
    }
  }

  final OfficialVocabulary _vocabulary;
  final Map<String, CompanionEntity> _byName = {};
  int _maxWords = 1;
  static const _tokenizer = Tokenizer();

  /// Words that look like things but are only glue in a sentence.
  static const Set<String> _ignore = {
    'nao',
    'sim',
    'oi',
    'no',
    'yes',
    'hi',
    'eu',
    'voce',
    'quero',
    'gosta',
    'gosto',
    'like',
    'love',
    'want',
    'have',
    'be',
    'go',
    'come',
    'give',
  };

  DetectedVocabulary detect(NormalizedText text) => detectIn(text.folded);

  /// [folded] must already be accent-free and lowercase.
  DetectedVocabulary detectIn(String folded) {
    final tokens = _tokenizer.tokenize(folded);
    final grams = _tokenizer.ngrams(
      tokens,
      maxLength: _maxWords > _vocabulary.maxTermWords
          ? _maxWords
          : _vocabulary.maxTermWords,
    );

    // Longest phrase first ("ice cream" before "ice"), then by position.
    final entities = <(int, CompanionEntity)>[];
    final words = <(int, VocabularyEntry)>[];
    final covered = <int>{};
    for (final gram in grams) {
      if (Tokenizer.stopWords.contains(gram) || _ignore.contains(gram)) {
        continue;
      }
      final position = _positionOf(tokens, gram, covered);
      if (position == null) continue;
      final entity = _byName[gram];
      final word =
          _vocabulary.byEnglish(gram) ??
          _vocabulary.byPortuguese(gram).firstOrNull;
      if (entity == null && word == null) continue;
      final length = gram.split(' ').length;
      for (var i = position; i < position + length; i++) {
        covered.add(i);
      }
      if (entity != null) entities.add((position, entity));
      if (word != null && word.category != 'greetings') {
        words.add((position, word));
      }
    }
    entities.sort((a, b) => a.$1.compareTo(b.$1));
    words.sort((a, b) => a.$1.compareTo(b.$1));
    final seenEntities = <String>{};
    final seenWords = <String>{};
    return DetectedVocabulary(
      entities: [
        for (final (_, e) in entities)
          if (seenEntities.add(e.id)) e,
      ],
      words: [
        for (final (_, w) in words)
          if (seenWords.add(w.id)) w,
      ],
    );
  }

  /// The thing named by a captured phrase ("maçãs", "the dogs",
  /// "tigres"): the catalog first, then the official word bank.
  CompanionEntity? entityIn(String phrase) {
    final folded = Normalizer.fold(phrase);
    final found = detectIn(folded);
    if (found.first != null) return found.first;
    final word = found.words.firstOrNull;
    return word == null ? null : CompanionEntity.fromWord(word);
  }

  /// Start index of [gram] in [tokens] not already used by a longer match.
  int? _positionOf(List<String> tokens, String gram, Set<int> covered) {
    final parts = gram.split(' ');
    for (var i = 0; i + parts.length <= tokens.length; i++) {
      var match = true;
      for (var j = 0; j < parts.length; j++) {
        if (tokens[i + j] != parts[j] || covered.contains(i + j)) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return null;
  }
}
