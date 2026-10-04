/// "O que é walk?" / "Essa palavra?" -- the child asks what a word means.
class MeaningRequest {
  const MeaningRequest.word(String this.word) : refersToLastWord = false;
  const MeaningRequest.lastWord() : word = null, refersToLastWord = true;

  /// The word asked about, as said ("walk"), or null for [refersToLastWord].
  final String? word;

  /// "O que é isso?", "Que palavra é essa?", "Não entendi": the English
  /// word the Dino just used.
  final bool refersToLastWord;

  @override
  String toString() =>
      refersToLastWord ? 'MeaningRequest(last)' : 'MeaningRequest($word)';
}

/// Spots meaning questions asked in Portuguese (English ones -- "what
/// does walk mean?" -- stay with the Dino's English answers). Works on
/// folded text: lower case, no accents, no punctuation.
class WordMeaningRequestDetector {
  const WordMeaningRequestDetector();

  static const String _article =
      r'(?:(?:a |essa |esta )?palavra |o |a |um |uma |esse |essa )?';

  static final List<RegExp> _withWord = [
    // "o que é walk", "que significa walk", "o que quer dizer walk"
    RegExp(
      '^(?:mas |e )?(?:o )?que (?:e|eh|seria|significa|quer dizer) '
      '$_article(.+)\$',
    ),
    // "walk significa o quê", "walk é o que"
    RegExp(r'^(.+?) (?:significa|quer dizer|e) (?:o )?que$'),
    // "não sei o que é walk"
    RegExp(
      '^(?:eu )?nao (?:sei|entendi) o que (?:e|significa|quer dizer) '
      '$_article(.+)\$',
    ),
    // "qual o significado de walk"
    RegExp(r'^(?:qual|que) (?:e )?(?:o )?significado (?:de |da |do )?(.+)$'),
    // "essa palavra walk", "a palavra walk"
    RegExp(r'^(?:essa|esta|a) palavra (.+)$'),
    // "me explica walk", "explica a palavra walk"
    RegExp('^(?:me )?expli(?:ca|que) $_article(.+)\$'),
  ];

  /// Always about the last English word: they say "palavra".
  static final List<RegExp> _aboutWord = [
    RegExp(r'^que palavra (?:e )?essa$'),
    RegExp(r'^(?:essa|esta) palavra$'),
    RegExp(r'^o que (?:e|significa|quer dizer) (?:essa|esta) palavra$'),
  ];

  /// Only right after the Dino used an English word ("o que é isso?",
  /// "não entendi"); otherwise they are about the whole last reply.
  static final List<RegExp> _aboutLast = [
    RegExp(r'^o que (?:ele|voce|vc) quis dizer$'),
    RegExp(r'^(?:o )?que (?:e|significa|quer dizer)$'),
    RegExp(r'^(?:o )?que (?:e|significa|quer dizer) (?:isso|essa|esse)$'),
    RegExp(
      r'^(?:eu )?(?:nao entendi|nao entendo|como assim|hein|que|o que|ue)$',
    ),
  ];

  static const Set<String> _pronouns = {
    'isso',
    'isto',
    'essa',
    'esse',
    'ela',
    'ele',
    'aquilo',
    'palavra',
    'essa palavra',
    'esta palavra',
    'a palavra',
    'isso ai',
    'essa ai',
  };

  static final RegExp _tail = RegExp(
    r'\s+(?:ai|ae|em ingles|em portugues|ne|hein)$',
  );

  /// Null when [folded] doesn't ask a word's meaning. [lastWordFresh]: the
  /// Dino's previous line had an English word in it.
  MeaningRequest? detect(String folded, {bool lastWordFresh = false}) {
    final text = folded.trim();
    if (text.isEmpty) return null;
    for (final pattern in _aboutWord) {
      if (pattern.hasMatch(text)) return const MeaningRequest.lastWord();
    }
    if (_aboutLast.any((p) => p.hasMatch(text))) {
      return lastWordFresh ? const MeaningRequest.lastWord() : null;
    }
    for (final pattern in _withWord) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      var slot = match.group(1)!.trim();
      while (_tail.hasMatch(slot)) {
        slot = slot.replaceFirst(_tail, '').trim();
      }
      if (slot.isEmpty || _pronouns.contains(slot)) {
        return const MeaningRequest.lastWord();
      }
      // A whole sentence is not a word question ("o que é que você
      // comeu hoje").
      if (slot.split(' ').length > 2) return null;
      return MeaningRequest.word(slot);
    }
    return null;
  }
}
