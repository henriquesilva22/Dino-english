import '../../brain/nlp/fuzzy_matcher.dart';
import '../../brain/nlp/normalizer.dart';

/// How close a repetition was to the word asked for.
enum RepetitionMatch {
  /// Said it (or something the recognizer writes for it: "wok", "walkk").
  correct,

  /// Sounds near but not quite ("rock" for walk): "Quase!".
  almost,

  /// Something else.
  miss,
}

/// Grades "Agora fala: WALK" against what the speech recognizer wrote.
///
/// Recognizers rarely spell a child's word exactly, so it compares a
/// rough *sound key* (silent letters dropped, c/k/q merged, "alk" ->
/// "ok"...) with a small edit-distance allowance -- but never accepts
/// another word the Dino teaches ("work" is not "walk"... unless it
/// sounds the same), and never anything far off.
class PronunciationMatcher {
  const PronunciationMatcher();

  /// Whether [heard] repeats [target]. [aliases] are spellings to accept
  /// as they are; [otherWords] are real words that must not pass as a
  /// typo of [target].
  RepetitionMatch match(
    String target,
    String heard, {
    Iterable<String> aliases = const [],
    Set<String> otherWords = const {},
  }) {
    final want = clean(target);
    final tokens = clean(heard).split(' ').where((t) => t.isNotEmpty).toList();
    if (want.isEmpty || tokens.isEmpty) return RepetitionMatch.miss;
    final accepted = {want, for (final a in aliases) clean(a)};
    final size = want.split(' ').length;

    // Every stretch of the sentence as long as the target ("ué, walk").
    final grams = <String>[
      for (var n = size; n >= 1; n--)
        for (var i = 0; i + n <= tokens.length; i++)
          tokens.sublist(i, i + n).join(' '),
    ];
    if (grams.any(accepted.contains)) return RepetitionMatch.correct;
    // "walkk", "waaalk": stretched letters.
    if (grams.any((g) => _squeeze(g) == _squeeze(want))) {
      return RepetitionMatch.correct;
    }

    final wantKey = soundKey(want);
    var best = RepetitionMatch.miss;
    for (final gram in grams) {
      if (gram.split(' ').length != size) continue;
      final isOther = otherWords.contains(gram) && gram != want;
      final key = soundKey(gram);
      if (key == wantKey) {
        // Another real word that only *sounds* alike ("wok"? fine; a
        // different taught word spelled out: only "almost").
        if (!isOther) return RepetitionMatch.correct;
        best = RepetitionMatch.almost;
        continue;
      }
      final distance = FuzzyMatcher.distance(key, wantKey);
      final sameStart = key.isNotEmpty && key[0] == wantKey[0];
      // One sound off, same first sound, a word long enough to tell.
      if (!isOther && sameStart && distance == 1 && wantKey.length >= 3) {
        return RepetitionMatch.correct;
      }
      // "rock" for walk: close. Tiny words ("de", "e") are never close.
      final allowed = wantKey.length >= 4 ? 2 : 1;
      if (gram.length >= 3 && distance <= allowed) {
        best = RepetitionMatch.almost;
      }
    }
    return best;
  }

  /// Lower case, no accents or punctuation, single spaces.
  static String clean(String text) => Normalizer.fold(text)
      .replaceAll(RegExp(r"[^a-z' ]"), ' ')
      .replaceAll("'", '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _squeeze(String s) =>
      s.replaceAllMapped(RegExp(r'([a-z])\1+'), (m) => m.group(1)!);

  static final List<(RegExp, String)> _rules = [
    (RegExp('^kn'), 'n'),
    (RegExp('^wr'), 'r'),
    (RegExp('^wh'), 'w'),
    (RegExp('alk'), 'ok'),
    (RegExp('igh'), 'i'),
    (RegExp('gh'), ''),
    (RegExp('ph'), 'f'),
    (RegExp('th'), 't'),
    (RegExp('ck'), 'k'),
    (RegExp('c(?=[eiy])'), 's'),
    (RegExp('[cq]'), 'k'),
    (RegExp('x'), 'ks'),
    (RegExp('z'), 's'),
    (RegExp('(?<=[a-z])e\$'), ''),
    (RegExp('ee|ea|ie'), 'i'),
    (RegExp('oo|ou'), 'u'),
    (RegExp('y\$'), 'i'),
  ];

  /// A rough sound key: "walk" and "wok" -> "wok", "eat" and "it" ->
  /// "it", "jump" and "jumpp" -> "jump".
  static String soundKey(String word) {
    // Doubled consonants first ("walkk"); doubled vowels are sounds the
    // rules below read ("ee", "oo").
    var s = clean(word)
        .replaceAll(' ', '')
        .replaceAllMapped(
          RegExp(r'([b-df-hj-np-tv-z])\1+'),
          (m) => m.group(1)!,
        );
    for (final (pattern, replacement) in _rules) {
      s = s.replaceAll(pattern, replacement);
    }
    s = _squeeze(s);
    // Vowels blur in a child's mouth: keep the first, merge the rest.
    if (s.length <= 1) return s;
    final rest = s.substring(1).replaceAll(RegExp('[aeiou]+'), 'a');
    return s[0] + rest;
  }
}
