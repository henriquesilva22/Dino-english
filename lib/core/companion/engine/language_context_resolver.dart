import '../companion_response.dart';
import 'companion_intent.dart';

/// The language the child is talking in.
enum ConversationLanguage { english, portuguese, mixed }

/// Whether the child asked for an explanation in Portuguese.
enum ExplanationLanguage { none, portuguese }

/// What the child asked about the Dino's language.
enum LanguageRequest {
  /// "Fala português", "Pode falar na minha língua?".
  portuguese,

  /// "Não entendi", "Não entendo inglês": say it again in Portuguese.
  notUnderstood,

  /// "O que significa?", "Traduz isso": English + its meaning.
  translation,
}

/// The language situation of one message.
class LanguageContext {
  const LanguageContext({
    this.conversationLanguage = ConversationLanguage.portuguese,
    this.request,
  });

  final ConversationLanguage conversationLanguage;
  final LanguageRequest? request;

  ExplanationLanguage get requestedExplanationLanguage =>
      request == LanguageRequest.portuguese ||
          request == LanguageRequest.notUnderstood
      ? ExplanationLanguage.portuguese
      : ExplanationLanguage.none;
}

/// Decides how the Dino uses its two languages:
///
/// * a question in Portuguese or English -> the answer is in English (the
///   app teaches English), its meaning shown on screen, English voice;
/// * an explicit request for Portuguese / "não entendi" -> Portuguese voice
///   (one reply only, then back to normal);
/// * a translation request -> English, then the Portuguese meaning;
/// * an honest "I don't know" or a word lesson -> both, so it's understood.
///
/// Asking *in* Portuguese is never taken as asking *for* Portuguese.
class LanguageContextResolver {
  const LanguageContextResolver();

  LanguageContext resolve(String folded, {required bool namesAWord}) =>
      LanguageContext(
        conversationLanguage: languageOf(folded),
        request: requestIn(folded, namesAWord: namesAWord),
      );

  // Texts are accent-folded and lower-case ("nao entendi").
  static final RegExp _translation = RegExp(
    r'\btraduz\w*|\btranslat\w*|\bsignifica\b|\bsignificado\b|'
    r'\bcomo (?:se )?(?:fala|diz) isso\b|\bo que (?:voce|vc) (?:disse|falou)\b|'
    r'\bwhat (?:does|did) (?:it|that|this|you) (?:mean|say)\b|\bmeaning\b',
  );

  static final RegExp _notUnderstood = RegExp(
    r'\bn(?:ao|aum|) ?(?:to |estou |consigo |)(?:entendi|entendo|entender|'
    r'entendendo|compreendi|compreendo)\b|'
    r"\bi (?:don'?t|do not|didn'?t|did not) (?:understand|get it)\b",
  );

  static final RegExp _portuguese = RegExp(
    r'\b(?:fala|falar|fale|falando|explica|explicar|explique|responde|'
    r'responder)\b.*\bportugues\b|\bem portugues\b|\bminha lingua\b|'
    r'\bspeak portuguese\b|\bin portuguese\b',
  );

  /// The language request in [folded], if any. A translation request that
  /// names a word ("O que significa hungry?", "Como fala maçã em inglês?")
  /// is a word lesson instead: null, so the word answer handles it.
  LanguageRequest? requestIn(String folded, {required bool namesAWord}) {
    // "Não entendi o que você falou" is about understanding, not a
    // translation request.
    if (_notUnderstood.hasMatch(folded)) return LanguageRequest.notUnderstood;
    if (_translation.hasMatch(folded)) {
      return namesAWord ? null : LanguageRequest.translation;
    }
    if (_portuguese.hasMatch(folded)) return LanguageRequest.portuguese;
    return null;
  }

  static final RegExp _word = RegExp(r"[a-z']+");

  static const Set<String> _ptMarkers = {
    'voce',
    'vc',
    'eu',
    'nao',
    'sim',
    'que',
    'como',
    'esta',
    'estou',
    'quer',
    'gosta',
    'gosto',
    'de',
    'com',
    'um',
    'uma',
    'meu',
    'minha',
    'qual',
    'e',
    'oi',
    'ola',
    'tchau',
    'obrigado',
    'obrigada',
    'vamos',
    'brincar',
    'comer',
    'fome',
    'sede',
    'sono',
    'tudo',
    'bem',
    'muito',
    'para',
    'por',
    'isso',
  };

  static const Set<String> _enMarkers = {
    'you',
    'i',
    'the',
    'what',
    'how',
    'do',
    'are',
    'is',
    'like',
    'my',
    'your',
    'hi',
    'hello',
    'bye',
    'yes',
    'no',
    'thank',
    'thanks',
    'lets',
    "let's",
    'play',
    'eat',
    'hungry',
    'thirsty',
    'sleepy',
    'want',
    'can',
    'please',
    'name',
    'good',
    'love',
    'it',
    'this',
    'a',
    'an',
    'to',
    'and',
    'am',
  };

  /// A light guess from common words: enough to tell "Como você está?"
  /// from "How are you?".
  ConversationLanguage languageOf(String folded) {
    var pt = 0, en = 0;
    for (final match in _word.allMatches(folded)) {
      final word = match.group(0)!;
      if (_ptMarkers.contains(word)) pt++;
      if (_enMarkers.contains(word)) en++;
    }
    if (pt == 0 && en == 0) return ConversationLanguage.portuguese;
    if (pt > 0 && en > 0 && (pt - en).abs() <= 1) {
      return ConversationLanguage.mixed;
    }
    return en > pt
        ? ConversationLanguage.english
        : ConversationLanguage.portuguese;
  }

  /// The voice for an ordinary reply to [intent].
  VoiceMode voiceFor(CompanionIntent? intent) => switch (intent) {
    // Understood only if explained: say the meaning too.
    CompanionIntent.unknown ||
    CompanionIntent.translateWord ||
    CompanionIntent.learnWord => VoiceMode.bilingual,
    _ => VoiceMode.english,
  };
}
