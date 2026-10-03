import '../model/dino_enums.dart';
import '../nlp/fuzzy_matcher.dart';
import '../nlp/normalizer.dart';
import '../nlp/tokenizer.dart';
import '../vocabulary/official_vocabulary.dart';

enum WordMatchKind {
  /// Found as typed (or as a plural/verb form of it).
  exact,

  /// Auto-corrected spelling ("woter" -> water).
  corrected,

  /// Several close candidates, or too short to trust -- ask the child.
  ambiguous,

  /// Not in the official vocabulary.
  unknown,
}

/// Where a phrase landed in the official vocabulary.
class WordMatch {
  const WordMatch({
    required this.kind,
    required this.heard,
    this.entry,
    this.candidates = const [],
    this.viaPortuguese = false,
  });

  const WordMatch.unknown(this.heard)
    : kind = WordMatchKind.unknown,
      entry = null,
      candidates = const [],
      viaPortuguese = false;

  final WordMatchKind kind;

  /// The phrase as the child wrote it (after normalization).
  final String heard;

  /// Set for [WordMatchKind.exact] and [WordMatchKind.corrected].
  final VocabularyEntry? entry;

  /// Set for [WordMatchKind.ambiguous].
  final List<VocabularyEntry> candidates;

  /// The child used the Portuguese word ("cachorro") for [entry].
  final bool viaPortuguese;

  bool get isResolved => entry != null;
}

/// Everything the Dino's request/answer handlers need beyond the intent.
class ExtractedEntities {
  const ExtractedEntities({
    this.word,
    this.activity,
    this.animation,
    this.object,
    this.need,
    this.wantsQuiz = false,
  });

  final WordMatch? word;
  final DinoActivity? activity;
  final DinoAnimation? animation;
  final DinoObject? object;
  final DinoNeed? need;

  /// "let's do a quiz" -- a conversation quiz, not a screen.
  final bool wantsQuiz;
}

/// Fourth pipeline step: resolves the slots an [IntentDetector] captured
/// (and free sentences) against the official vocabulary, tolerating
/// children's spelling with [FuzzyMatcher].
class EntityExtractor {
  EntityExtractor(this._vocabulary);

  final OfficialVocabulary _vocabulary;
  static const _tokenizer = Tokenizer();
  static const _fuzzy = FuzzyMatcher();

  /// Words around the target word that aren't part of it.
  static final RegExp _noise = RegExp(
    r'^(?:the word |a palavra |the |a |an |um |uma |o |a |this |that )+|'
    r'(?: in (?:english|portuguese|ingl[eê]s|portugu[eê]s)| em (?:ingl[eê]s|portugu[eê]s)| please| por favor| for me| again| dino)+$',
    unicode: true,
  );

  static const Set<String> _pronouns = {
    'it',
    'that',
    'this',
    'isso',
    'essa',
    'esse',
    'ela',
    'ele',
  };

  /// Resolves one captured phrase ("the word woter") to a vocabulary
  /// entry. English is tried before Portuguese, exact before fuzzy, and
  /// the whole phrase before its parts.
  WordMatch resolveWord(String phrase) {
    final cleaned = phrase.replaceAll(_noise, '').trim();
    if (cleaned.isEmpty) return WordMatch.unknown(phrase);

    final exact = _exact(cleaned);
    if (exact != null) return exact;

    // Parts of the phrase, longest first ("I want ice cream" -> ice cream).
    final tokens = _tokenizer.tokenize(cleaned);
    if (tokens.length > 1) {
      for (final gram in _tokenizer.ngrams(
        tokens,
        maxLength: _vocabulary.maxTermWords,
      )) {
        if (Tokenizer.stopWords.contains(gram)) continue;
        final hit = _exact(gram);
        if (hit != null) return hit;
      }
    }

    // Spelling mistakes: whole phrase first, then each content word.
    final fuzzyTargets = [
      cleaned,
      if (tokens.length > 1) ..._tokenizer.contentTokens(tokens),
    ];
    for (final target in fuzzyTargets) {
      final fuzzy = _fuzzyLookup(target);
      if (fuzzy != null) return fuzzy;
    }
    return WordMatch.unknown(cleaned);
  }

  bool isPronoun(String phrase) =>
      _pronouns.contains(phrase.replaceAll(_noise, '').trim());

  WordMatch? _exact(String term) {
    final english = _vocabulary.byEnglish(term);
    if (english != null) {
      return WordMatch(kind: WordMatchKind.exact, heard: term, entry: english);
    }
    final portuguese = _vocabulary.byPortuguese(term);
    if (portuguese.length == 1) {
      return WordMatch(
        kind: WordMatchKind.exact,
        heard: term,
        entry: portuguese.single,
        viaPortuguese: true,
      );
    }
    if (portuguese.length > 1) {
      return WordMatch(
        kind: WordMatchKind.ambiguous,
        heard: term,
        candidates: portuguese,
        viaPortuguese: true,
      );
    }
    return null;
  }

  WordMatch? _fuzzyLookup(String term) {
    if (term.length < 3) return null;
    final english = _fuzzy.match(term, _vocabulary.englishTerms);
    final result = english.outcome != FuzzyOutcome.none
        ? english
        : _fuzzy.match(Normalizer.fold(term), _vocabulary.portugueseTerms);
    final viaPortuguese = english.outcome == FuzzyOutcome.none;

    List<VocabularyEntry> entriesFor(String value) => viaPortuguese
        ? _vocabulary.byPortuguese(value)
        : [?_vocabulary.byEnglish(value)];

    switch (result.outcome) {
      case FuzzyOutcome.none:
        return null;
      case FuzzyOutcome.exact:
      case FuzzyOutcome.corrected:
        final entries = entriesFor(result.best!.value);
        if (entries.length == 1) {
          return WordMatch(
            kind: result.outcome == FuzzyOutcome.exact
                ? WordMatchKind.exact
                : WordMatchKind.corrected,
            heard: term,
            entry: entries.single,
            viaPortuguese: viaPortuguese,
          );
        }
        return WordMatch(
          kind: WordMatchKind.ambiguous,
          heard: term,
          candidates: entries,
          viaPortuguese: viaPortuguese,
        );
      case FuzzyOutcome.ambiguous:
        final candidates = <VocabularyEntry>[];
        for (final c in result.candidates) {
          for (final e in entriesFor(c.value)) {
            if (!candidates.contains(e)) candidates.add(e);
          }
        }
        return WordMatch(
          kind: WordMatchKind.ambiguous,
          heard: term,
          candidates: candidates
              .take(FuzzyMatcher.maxAmbiguousOptions)
              .toList(),
          viaPortuguese: viaPortuguese,
        );
    }
  }

  /// Finds the first official word mentioned anywhere in a free sentence,
  /// optionally only from [category] ("I think I like pizza" -> pizza).
  /// Exact matches only -- a free sentence has too many words to guess.
  VocabularyEntry? findWordInSentence(String text, {String? category}) {
    final tokens = _tokenizer.tokenize(text);
    for (final gram in _tokenizer.ngrams(
      tokens,
      maxLength: _vocabulary.maxTermWords,
    )) {
      if (Tokenizer.stopWords.contains(gram)) continue;
      final english = _vocabulary.byEnglish(gram);
      if (english != null &&
          (category == null || english.category == category)) {
        return english;
      }
      for (final e in _vocabulary.byPortuguese(gram)) {
        if (category == null || e.category == category) return e;
      }
    }
    return null;
  }

  /// Categories never taught out of a free sentence: "não" (no), "sim"
  /// (yes), "oi" (hi) are glue words, not vocabulary the child meant.
  static const Set<String> _notTaughtCategories = {'greetings', 'numbers'};

  /// Verbs too generic to be "the word" of a sentence ("eu quero..." is
  /// not about learning "want").
  static const Set<String> _genericVerbs = {
    'be',
    'have',
    'go',
    'come',
    'give',
    'take',
    'want',
    'like',
    'see',
    'look',
    'stop',
    'help',
    'understand',
    'speak',
  };

  /// The best official word to teach from a free sentence: concrete words
  /// (food, animals, objects...) beat verbs ("quero comer uma maçã" ->
  /// apple, not eat). Exact matches only, like [findWordInSentence].
  VocabularyEntry? findTeachableWord(String text) {
    final tokens = _tokenizer.tokenize(text);
    VocabularyEntry? verb;
    for (final gram in _tokenizer.ngrams(
      tokens,
      maxLength: _vocabulary.maxTermWords,
    )) {
      if (Tokenizer.stopWords.contains(gram)) continue;
      final english = _vocabulary.byEnglish(gram);
      final candidates = [?english, ..._vocabulary.byPortuguese(gram)];
      for (final e in candidates) {
        if (_notTaughtCategories.contains(e.category) ||
            _genericVerbs.contains(e.english)) {
          continue;
        }
        if (e.category != 'verbs') return e;
        verb ??= e;
      }
    }
    return verb;
  }

  // ---- non-word entities ----------------------------------------------------

  static final List<(RegExp, DinoActivity)> _activityPatterns = [
    (RegExp(r'word ?slash|\bslash\b'), DinoActivity.wordSlash),
    (
      RegExp(r'sentence|montar frase|\bfrases?\b'),
      DinoActivity.sentenceBuilder,
    ),
    (RegExp(r'\b(?:test|exam|prova|teste)\b'), DinoActivity.exam),
    (RegExp(r'adventure|aventura|minigame'), DinoActivity.adventure),
    (
      RegExp(r'\bstud(?:y|ying)\b|learn(?: new)? words|estud|palavras novas'),
      DinoActivity.study,
    ),
  ];

  DinoActivity? findActivity(String text) {
    for (final (pattern, activity) in _activityPatterns) {
      if (pattern.hasMatch(text)) return activity;
    }
    return null;
  }

  bool mentionsQuiz(String text) => RegExp(r'\bquiz\b').hasMatch(text);

  static final List<(RegExp, DinoAnimation)> _animationPatterns = [
    (RegExp(r'\bjump|\bpul'), DinoAnimation.jump),
    (RegExp(r'\bdanc'), DinoAnimation.dance),
    (RegExp(r'\bsing|\bcant'), DinoAnimation.sing),
    (RegExp(r'sleep|\bnap\b|\bbed\b|dorm'), DinoAnimation.sleep),
    (RegExp(r'\beat\b|\bcom(?:er|a)\b'), DinoAnimation.eat),
    (RegExp(r'\bdrink|\bbeb'), DinoAnimation.drink),
    (RegExp(r'\broar|\brug|\bruj'), DinoAnimation.roar),
    (RegExp(r'\brun\b|\bcorr'), DinoAnimation.run),
    (RegExp(r'\bsit\b|\bsent'), DinoAnimation.sit),
    (
      RegExp(r'\bwalk|\band(?:ar|a|e)\b|come here|vem|venha'),
      DinoAnimation.walk,
    ),
    (RegExp(r'\bwave|say hi'), DinoAnimation.wave),
    (RegExp(r'smile|laugh|sorri'), DinoAnimation.happy),
    (RegExp(r'spin|turn around|stand up'), DinoAnimation.dance),
  ];

  DinoAnimation? findAnimation(String text) {
    for (final (pattern, animation) in _animationPatterns) {
      if (pattern.hasMatch(text)) return animation;
    }
    return null;
  }

  DinoObject? findObject(String text) {
    if (RegExp(r'bath|shower|wash|teeth|banho|bathroom|soap').hasMatch(text)) {
      return DinoObject.bathroom;
    }
    if (RegExp(r'\bbed\b|bedroom|sleep|\bnap\b|dorm').hasMatch(text)) {
      return DinoObject.bed;
    }
    if (RegExp(r'kitchen|\beat\b|\bcom(?:er|a)\b|food').hasMatch(text)) {
      return DinoObject.food;
    }
    if (RegExp(r'\bdrink|water|\bbeb|[aá]gua').hasMatch(text)) {
      return DinoObject.water;
    }
    if (RegExp(r'\btoys?\b|brinquedo').hasMatch(text)) return DinoObject.toys;
    return null;
  }

  DinoNeed? findNeed(String text) {
    if (RegExp(r'hungry|fome|\beat\b|food|comida|comer').hasMatch(text)) {
      return DinoNeed.hunger;
    }
    if (RegExp(r'thirsty|sede|drink|water|[aá]gua|beber').hasMatch(text)) {
      return DinoNeed.thirst;
    }
    if (RegExp(r'tired|sleepy|sleep|sono|cansad|dormir|rest').hasMatch(text)) {
      return DinoNeed.energy;
    }
    if (RegExp(r'dirty|bath|shower|wash|sujo|banho').hasMatch(text)) {
      return DinoNeed.hygiene;
    }
    if (RegExp(r'bored|play|fun|entediad|brincar|happy|feliz').hasMatch(text)) {
      return DinoNeed.happiness;
    }
    return null;
  }

  /// Everything a sentence mentions, for requests and activities.
  ExtractedEntities extractAll(String text, {String? wordSlot}) {
    return ExtractedEntities(
      word: wordSlot == null ? null : resolveWord(wordSlot),
      activity: findActivity(text),
      animation: findAnimation(text),
      object: findObject(text),
      need: findNeed(text),
      wantsQuiz: mentionsQuiz(text),
    );
  }
}
