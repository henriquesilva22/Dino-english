/// Second pipeline step: splits normalized text into word tokens and
/// builds n-grams so multi-word vocabulary ("ice cream", "thank you",
/// "good morning") can be found inside a sentence.
class Tokenizer {
  const Tokenizer();

  /// Words that never carry the "target word" of a sentence.
  static const Set<String> stopWords = {
    'a', 'an', 'the', 'is', 'are', 'am', 'was', 'be', 'do', 'does', 'did',
    'i', 'you', 'me', 'my', 'your', 'it', 'this', 'that', 'to', 'of', 'in',
    'on', 'and', 'or', 'so', 'please', 'word', 'words', 'dino', 'mean',
    'means', 'meaning', 'what', 'say', 'like', 'love', 'favorite',
    'favourite', 'some', 'very', 'really', 'too', 'also', 'um', 'uh', 'hmm',
    // Portuguese ('a', 'do', 'um' are already listed above)
    'o', 'os', 'as', 'uma', 'de', 'da', 'e', 'é', 'que',
    'eu', 'palavra', 'meu', 'minha', 'em', 'no', 'na', 'por', 'favor',
    'gosto', 'amo',
  };

  List<String> tokenize(String normalizedText) => normalizedText
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toList(growable: false);

  /// All contiguous n-grams from [maxLength] words down to 1, longest
  /// first, so the most specific phrase wins ("ice cream" before "ice").
  List<String> ngrams(List<String> tokens, {int maxLength = 3}) {
    final result = <String>[];
    for (var n = maxLength; n >= 1; n--) {
      for (var i = 0; i + n <= tokens.length; i++) {
        result.add(tokens.sublist(i, i + n).join(' '));
      }
    }
    return result;
  }

  List<String> contentTokens(List<String> tokens) =>
      tokens.where((t) => !stopWords.contains(t)).toList(growable: false);
}
