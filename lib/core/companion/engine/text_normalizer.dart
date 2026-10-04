import '../../brain/nlp/normalizer.dart';

/// One child sentence, ready for the companion's rules.
class NormalizedText {
  const NormalizedText({
    required this.input,
    required this.folded,
    required this.tokens,
  });

  /// The brain's normalization (lowercase, contractions expanded,
  /// punctuation removed, accents kept) -- what `DinoBrain` consumes.
  final NormalizedInput input;

  /// [input] without accents and without the "dino"/"por favor" around
  /// it: "Dino, você gosta de MAÇÃ?" -> "voce gosta de maca".
  final String folded;
  final List<String> tokens;

  String get raw => input.raw;
  bool get isQuestion => input.isQuestion;
  bool get isEmpty => folded.isEmpty;
}

/// First step of the companion pipeline. Builds on the brain's
/// [Normalizer] (no second set of contraction rules): "OI DINO!", "oi
/// dino" and "Oi Dino!!" all become `oi`.
class TextNormalizer {
  const TextNormalizer();

  static const _normalizer = Normalizer();

  static final RegExp _leadingVocative = RegExp(
    r'^(?:(?:oi|ola|hi|hello|hey|ei)\s+)?(?:dino|dinossauro|amigo|friend|buddy)\b\s*',
  );
  static final RegExp _trailingFiller = RegExp(
    r'(?:\s+(?:dino|por favor|please|amigo|friend|agora|now))+$',
  );

  NormalizedText normalize(String raw) {
    final input = _normalizer.normalize(raw);
    var folded = Normalizer.fold(input.text);
    final withoutVocative = folded.replaceFirst(_leadingVocative, '');
    // "oi dino" stays a greeting ("oi"), never an empty sentence.
    if (withoutVocative.isNotEmpty) {
      folded = withoutVocative;
    } else {
      folded = folded.replaceFirst(RegExp(r'\s*\b(?:dino|amigo)\b'), '');
    }
    final trimmed = folded.replaceFirst(_trailingFiller, '');
    if (trimmed.isNotEmpty) folded = trimmed;
    folded = folded.trim();
    return NormalizedText(
      input: input,
      folded: folded,
      tokens: folded.isEmpty ? const [] : folded.split(' '),
    );
  }
}
