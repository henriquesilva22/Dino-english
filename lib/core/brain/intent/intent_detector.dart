// Patterns are built from reusable raw-string fragments; concatenation
// keeps them raw (no double escaping), which interpolation would not.
// ignore_for_file: prefer_interpolation_to_compose_strings

import '../context/conversation_context.dart';
import '../nlp/normalizer.dart';
import 'intent.dart';

class _Rule {
  _Rule(
    this.name,
    this.intent,
    String pattern, {
    this.confidence = 0.9,
    this.statement,
  }) : regex = RegExp('^(?:$pattern)\$', unicode: true);

  final String name;
  final DinoIntent intent;
  final RegExp regex;
  final double confidence;
  final StatementKind? statement;

  IntentResult? tryMatch(String text) {
    final m = regex.firstMatch(text);
    if (m == null) return null;
    String? first(List<String> names) {
      for (final n in names) {
        if (!m.groupNames.contains(n)) continue;
        final value = m.namedGroup(n)?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    // Rules with several alternatives use w2, w3... for the other
    // branches' capture (Dart forbids duplicate group names).
    return IntentResult(
      intent,
      confidence: confidence,
      slot: first(const ['w', 'w2', 'w3', 'w4', 'w5', 'w6', 'w7', 'w8']),
      secondSlot: first(const ['t', 't2']),
      statement: statement,
      rule: name,
    );
  }
}

/// Third pipeline step: normalized text -> [IntentResult].
///
/// Rule-based and offline: an ordered list of anchored patterns (English
/// and the Portuguese a Brazilian child is likely to mix in), where the
/// first match wins, plus [ConversationContext.pending] to understand bare
/// answers ("Apple.", "yes", "cachorro"). Named groups `w`/`t` capture the
/// slots the `EntityExtractor` resolves later.
class IntentDetector {
  IntentDetector();

  // Reused fragments.
  static const _en = r'ingl[eê]s|english';
  static const _pt = r'portugu[eê]s|portuguese';
  static const _you = r'voc[eê]';
  static const _feelingWords =
      r'happy|sad|angry|mad|scared|afraid|tired|hungry|thirsty|sleepy|'
      r'excited|bored|good|fine|great|ok|okay|well|bad|sick|cool|awesome|'
      r'feliz|triste|bravo|brava|com medo|cansado|cansada|com fome|com sede|'
      r'com sono|animado|animada|entediado|entediada|bem|mal|doente|[oó]timo|'
      r'[oó]tima|legal';

  /// Intents that answer a question the child asked, so they win even
  /// while the Dino waits for an answer ("What does water mean?" in the
  /// middle of a quiz is a real question, not a wrong answer).
  static const Set<DinoIntent> _overridePending = {
    DinoIntent.askWordMeaning,
    DinoIntent.askTranslation,
    DinoIntent.askWordExample,
    DinoIntent.askDinoName,
    DinoIntent.askDinoPreference,
    DinoIntent.askDinoFeeling,
    DinoIntent.askDinoNeed,
    DinoIntent.askHelp,
    DinoIntent.startActivity,
    DinoIntent.askActivity,
    DinoIntent.askReward,
    DinoIntent.farewell,
    DinoIntent.request,
    DinoIntent.affection,
    DinoIntent.praise,
    DinoIntent.play,
    DinoIntent.askMemory,
  };

  final List<_Rule> _rules = [
    // --- "... in Portuguese" is always a meaning question -------------------
    _Rule(
      'meaning_how_say_pt',
      DinoIntent.askWordMeaning,
      r'how (?:do|can|would|to) (?:you |i |we )?say (?<w>.+?) in (?:' +
          _pt +
          ')',
    ),
    _Rule(
      'meaning_what_is_in_pt',
      DinoIntent.askWordMeaning,
      r'what (?:is|are) (?<w>.+?) in (?:' + _pt + ')',
    ),
    _Rule(
      'meaning_pt_em_portugues',
      DinoIntent.askWordMeaning,
      r'(?:o que (?:[eé]|significa|quer dizer)|como (?:se )?(?:diz|fala)) (?<w>.+?) em (?:' +
          _pt +
          ')',
    ),

    // --- translation (Portuguese -> English) -------------------------------
    _Rule(
      'translation_what_is_in_en',
      DinoIntent.askTranslation,
      r'what (?:is|are) (?:the )?(?:english )?(?:word )?(?:for )?(?<w>.+?) in (?:' +
          _en +
          ')',
    ),
    _Rule(
      'translation_word_for',
      DinoIntent.askTranslation,
      r'what (?:is|are) the (?:english )?word for (?<w>.+)',
    ),
    _Rule(
      'translation_how_say',
      DinoIntent.askTranslation,
      r'how (?:do|can|would|to) (?:you |i |we )?(?:say|spell|write) (?<w>.+?)(?: in (?:' +
          _en +
          '))?',
    ),
    _Rule(
      'translation_translate',
      DinoIntent.askTranslation,
      r'(?:can you )?(?:translate|traduz|traduza|traduzir) (?<w>.+?)(?: (?:to|into|para|pro) (?:' +
          _en +
          r')| for me)?',
    ),
    _Rule(
      'translation_como_diz',
      DinoIntent.askTranslation,
      r'como (?:se |eu |que )?(?:diz|digo|fala|falo|escreve|escrevo) (?<w>.+?)(?: em (?:' +
          _en +
          '))?',
    ),
    _Rule(
      'translation_como_e',
      DinoIntent.askTranslation,
      r'(?:como|qual) [eé] (?:a tradu[cç][aã]o de )?(?<w>.+?) em (?:' +
          _en +
          ')',
    ),
    _Rule(
      'translation_traducao_de',
      DinoIntent.askTranslation,
      r'(?:what is |qual [eé] )?(?:a |the )?(?:tradu[cç][aã]o|translation) (?:de|of) (?<w>.+)',
    ),

    // --- teaching the Dino ("water means água") ----------------------------
    _Rule(
      'teach_is_in_pt',
      DinoIntent.teachWord,
      r'(?!what\b)(?<w>.+?) (?:is|are) (?<t>.+?) in (?:' + _pt + ')',
    ),
    _Rule(
      'teach_em_ingles_e',
      DinoIntent.teachWord,
      r'(?<t>.+?) em (?:' + _en + r') [eé] (?<w>.+)',
    ),
    _Rule(
      'teach_intro',
      DinoIntent.teachWord,
      r'(?:i )?(?:want to |will |can |am going to |wanna )?teach you(?: (?:a|the|one|another) (?:new )?word)?(?: (?<w>.+))?'
          r'|(?:let me|can i) teach you(?: (?:a|the|one|another) (?:new )?word)?(?: (?<w3>.+))?'
          r'|(?:eu )?(?:vou|quero|posso|deixa eu) te ensinar(?: uma)?(?: palavra)?(?: nova)?(?: (?<w2>.+))?',
    ),

    _Rule(
      'translation_x_in_en',
      DinoIntent.askTranslation,
      r'(?:e |and )?(?<w>.+?) (?:in|em) (?:' + _en + ')',
      confidence: 0.8,
    ),
    _Rule(
      'meaning_x_in_pt',
      DinoIntent.askWordMeaning,
      r'(?:e |and )?(?<w>.+?) (?:in|em) (?:' + _pt + ')',
      confidence: 0.8,
    ),

    // --- meaning (English -> Portuguese) ------------------------------------
    _Rule(
      'meaning_what_does_mean',
      DinoIntent.askWordMeaning,
      r'what (?:does|do|did|is) (?:the word |a |an |the )?(?<w>.+?) means?',
    ),
    _Rule(
      'meaning_meaning_of',
      DinoIntent.askWordMeaning,
      r'(?:what (?:is|are) )?the meaning of (?<w>.+)|meaning of (?<w2>.+)',
    ),
    _Rule(
      'meaning_what_means',
      DinoIntent.askWordMeaning,
      r'what means (?:the word )?(?<w>.+)',
    ),
    _Rule(
      'meaning_x_means_what',
      DinoIntent.askWordMeaning,
      r'(?<w>.+?) means what',
    ),
    _Rule(
      'meaning_define',
      DinoIntent.askWordMeaning,
      r'(?:define|explain) (?:the word )?(?<w>.+)',
    ),
    _Rule(
      'meaning_do_you_know',
      DinoIntent.askWordMeaning,
      r'do you know (?:what )?(?:the word )?(?<w>.+?) (?:means?|is)',
      confidence: 0.8,
    ),
    _Rule(
      'meaning_o_que_significa',
      DinoIntent.askWordMeaning,
      r'o que (?:significa|quer dizer) (?:a palavra )?(?<w>.+)'
          r'|(?<w2>.+?) (?:significa|quer dizer) o (?:que|q)'
          r'|qual (?:[eé] )?o significado de (?<w3>.+)',
    ),

    // --- "water means água" / "cachorro significa dog" (after the
    //     "... means what" / "o que significa" questions above) -------------
    _Rule(
      'teach_means',
      DinoIntent.teachWord,
      r'(?!what\b|o que\b)(?<w>.+?) (?:means|significa|quer dizer) (?<t>.+)',
    ),

    // --- example sentences --------------------------------------------------
    _Rule(
      'example_en',
      DinoIntent.askWordExample,
      r'(?:(?:can you |please )?(?:give|tell|show) me |say |make |i want )?(?:an? |another |one more )?(?:example|sentence)s?(?: (?:with|of|for|using|about) (?:the word )?(?<w>.+))?',
    ),
    _Rule(
      'example_use_in_sentence',
      DinoIntent.askWordExample,
      r'(?:use|say) (?:the word )?(?<w>.+?) in a sentence|how (?:do|can) (?:i|you|we) use (?:the word )?(?<w2>.+)|(?<w3>.+?) in a sentence',
    ),
    _Rule(
      'example_pt',
      DinoIntent.askWordExample,
      r'(?:me )?(?:d[aáeê] )?(?:um |outro |mais um )?exemplo(?: (?:com|de|para|usando) (?:a palavra )?(?<w>.+))?'
          r'|(?:uma |outra )?frase (?:com|usando) (?:a palavra )?(?<w2>.+)',
    ),

    // --- what the Dino remembers about the child -----------------------------
    _Rule(
      'ask_memory',
      DinoIntent.askMemory,
      r'what (?:is|are) my (?:favou?rite|best) (?<w>\w+)|what is my (?<w2>name|age)|do you (?:remember|know) my (?:favou?rite (?<w3>\w+)|(?<w4>name))|who am i'
              r'|qual (?:[eé] )?(?:o |a )?(?:meu|minha) (?<w5>\w+) (?:favorit[oa]|preferid[oa])|qual (?:[eé] )?(?:o )?meu (?<w6>nome)'
              r'|(?:' +
          _you +
          r' )?(?:lembra|sabe) (?:do |o )?meu (?<w7>nome)|(?:' +
          _you +
          r' )?(?:lembra|sabe) (?:qual [eé] )?(?:a |o )?(?:minha|meu) (?<w8>\w+) (?:favorit[oa]|preferid[oa])',
    ),

    // --- affection & praise (before "i like ..." facts) ---------------------
    _Rule(
      'affection',
      DinoIntent.affection,
      r'i (?:really )?(?:like|love) you(?: (?:so much|very much|a lot|too|dino))*|you are my (?:best )?friend|do you (?:like|love) me'
              r'|(?:can i (?:give you|have) )?(?:a )?(?:big )?(?:hug|kiss)(?: (?:you|me))?|i (?:want to )?(?:hug|kiss) you'
              r'|(?:eu )?(?:gosto|adoro) (?:muito )?(?:de )?(?:' +
          _you +
          r'|ti)(?: (?:muito|demais|tamb[eé]m))*|(?:eu )?te (?:amo|adoro)(?: (?:muito|demais))*|(?:eu )?amo (?:' +
          _you +
          r')(?: (?:muito|demais))*|(?:' +
          _you +
          r' )?(?:[eé] )?(?:o )?meu (?:melhor )?amigo|(?:' +
          _you +
          r' )?gosta de mim|(?:um )?(?:abra[cç]o|beijo|beijinho)(?: (?:em|pra|para) (?:' +
          _you +
          r'|o dino))?|(?:vou|quero) te (?:abra[cç]ar|dar um (?:abra[cç]o|beijo))',
    ),
    _Rule(
      'praise',
      DinoIntent.praise,
      r'you are (?:so |very |really |the )?(?:cute|cool|smart|nice|funny|awesome|beautiful|pretty|great|amazing|good|best|clever|lovely|kind|sweet)(?: dino)?'
              r'|(?:good|nice|smart|cute) (?:boy|girl|dino|dinosaur)|(?:so|how) cute|good job'
              r'|(?:' +
          _you +
          r') (?:[eé] |est[aá] |t[aá] )?(?:muito |mt |t[aã]o |super |o )?(?:fofo|fofa|fofinho|lindo|linda|lindinho|legal|inteligente|engra[cç]ado|bonito|bonitinho|esperto|demais|melhor|incr[ií]vel|show|top)(?: demais)?'
              r'|que (?:dino )?(?:fofo|fofinho|lindo|legal|fofura)|(?:muito |t[aã]o )?(?:fofo|fofinho|lindo|lindinho)',
    ),

    // --- about the Dino -----------------------------------------------------
    _Rule(
      'dino_name',
      DinoIntent.askDinoName,
      r'(?:what is|tell me) your name|who are you|what (?:are you called|do they call you)|your name|do you have a name'
              r'|qual (?:[eé] )?(?:o )?seu nome|como (?:' +
          _you +
          r' )?se chama|quem [eé] (?:' +
          _you +
          ')|seu nome',
    ),

    _Rule(
      'dino_preference',
      DinoIntent.askDinoPreference,
      r'what (?:is|are) your (?:favou?rite|best) (?<w>\w+)|do you (?:like|love) (?<w2>.+)|which (?<w3>\w+) do you like(?: best| most)?'
              r'|qual (?:[eé] )?(?:a |o )?(?:sua|seu) (?<w4>\w+) (?:favorit[oa]|preferid[oa])|(?:' +
          _you +
          r' )?gosta de (?<w5>.+)',
    ),

    // --- volunteered facts (become ANSWER + statement) ----------------------
    _Rule(
      'fact_name',
      DinoIntent.answer,
      r'my name is (?<w>.+)|i am called (?<w2>.+)|call me (?<w3>.+)|(?:o )?meu nome [eé] (?<w4>.+)|(?:eu )?me chamo (?<w5>.+)',
      statement: StatementKind.childName,
    ),
    _Rule(
      'fact_age',
      DinoIntent.answer,
      r'i am (?<w>\d{1,2})(?: years old)?|(?:eu )?tenho (?<w2>\d{1,2}) anos',
      statement: StatementKind.childAge,
    ),
    _Rule(
      'fact_dislikes',
      DinoIntent.answer,
      r'i (?:do not|dont|really do not) like (?<w>.+)|i hate (?<w2>.+)|(?:eu )?n[aã]o gosto (?:de |do |da )?(?<w3>.+)|(?:eu )?odeio (?<w4>.+)',
      statement: StatementKind.dislikes,
    ),
    _Rule(
      'fact_likes',
      DinoIntent.answer,
      r'i (?:really )?(?:like|love|prefer) (?<w>.+)|my (?:favou?rite|best) (?<t>\w+) (?:is|are) (?<w2>.+)'
          r'|(?:eu )?(?:gosto (?:de |do |da |dos |das )?|amo |adoro )(?<w3>.+)'
          r'|(?:a |o )?(?:minha|meu) (?<t2>\w+) (?:favorit[oa]|preferid[oa]) [eé] (?<w4>.+)',
      statement: StatementKind.likes,
    ),
    _Rule(
      'fact_feeling',
      DinoIntent.answer,
      r'(?:i am|i feel|i am feeling|(?:eu )?(?:estou|to|tô|t[oô]|me sinto)) (?:very |so |really |a little |muito |meio )?(?<w>' +
          _feelingWords +
          ')(?: today| now| hoje| agora)?',
      statement: StatementKind.childFeeling,
    ),

    // --- how the Dino feels / what it needs ---------------------------------
    _Rule(
      'dino_feeling',
      DinoIntent.askDinoFeeling,
      r'how (?:are|r) you(?: doing| today| now| feeling)?|how do you feel(?: today)?|how is it going|you ok(?:ay)?'
              r'|are you (?:ok|okay|happy|sad|good|fine|well|alright|angry|scared|feeling (?:ok|okay|good|well))'
              r'|and you|what about you|e (?:' +
          _you +
          r')|como (?:' +
          _you +
          r' )?(?:est[aá]|vai|t[aá])(?: hoje)?|tudo bem(?: com (?:' +
          _you +
          '))?|(?:' +
          _you +
          r' )?(?:est[aá]|t[aá]) (?:bem|feliz|triste)',
    ),

    // Activities before needs: "do you want to play Word Slash?" is an
    // invitation, not a question about the Dino's needs.
    // Playing *with the Dino* (no game named) -- before activities, which
    // need a game name ("let's play Word Slash").
    _Rule(
      'play',
      DinoIntent.play,
      r'(?:(?:ok |yes |sim )?(?:let us|can we|could we|shall we|do you want to|you want to|i want to|want to) )?play(?: a game)?(?: (?:with me|together|with you))?(?: now| please)?'
              r'|(?:(?:vamos|bora|quer|' +
          _you +
          r' quer|podemos|quero|vem) )?brincar(?: (?:comigo|junto|juntos|um pouco|agora))*|brinca comigo',
    ),
    _Rule(
      'start_activity',
      DinoIntent.startActivity,
      r'(?:(?:ok |yes |sim )?(?:let us|lets|can we|could we|shall we|i want to|i wanna|we can|please|vamos|bora|quero|posso|podemos) )?'
          r'(?:(?:play|do|start|open|go to|go|take|try|jogar|fazer|come[cç]ar|abrir|ir para|ir pra|ir pro|estudar) )?(?:the |a |o |a |no |na )?'
          r'(?<w>word ?slash|slash|study(?:ing)?|learn(?: new)? words|estudar|estudo|palavras novas|sentence(?:s| builder)?|build(?:ing)? sentences|montar frases?|frases?|test|exam|quiz|prova|teste|adventure|aventura|minigame)(?: game| now| please| agora)?',
    ),
    _Rule(
      'ask_activity',
      DinoIntent.askActivity,
      r'what (?:can|should|do|shall) we (?:do|play)(?: now| today)?|what do you want to (?:do|play)|what (?:games|activities) (?:are there|do you have|can we play)'
          r'|let us (?:do something|have fun)|which games? can we play'
          r'|o que (?:vamos|podemos|a gente vai|a gente pode) fazer|(?:vamos|bora|quero) jogar(?: um jogo)?(?: comigo)?|(?:vamos|bora) fazer (?:algo|alguma coisa)',
    ),
    _Rule(
      'dino_need',
      DinoIntent.askDinoNeed,
      r'are you (?<w>hungry|thirsty|tired|sleepy|dirty|bored|cold|hot|sick)|what do you (?:want|need)(?: now)?|do you (?:want|need)(?: to)? (?<w2>.+)|are you ok'
              r'|(?:' +
          _you +
          r' )?(?:est[aá]|t[aá]) com (?<w3>fome|sede|sono|frio|calor)|(?:' +
          _you +
          r' )?(?:est[aá]|t[aá]) (?<w4>cansado|sujo|entediado)|(?:' +
          _you +
          r' )?(?:quer|precisa de) (?<w5>.+)|o que (?:' +
          _you +
          r' )?(?:quer|precisa)',
    ),

    // --- help ---------------------------------------------------------------
    _Rule(
      'help',
      DinoIntent.askHelp,
      r'help(?: me)?(?: please)?|i need help|can you help(?: me)?|(?:i )?(?:do not|dont) understand|what can (?:i|we) (?:say|ask|talk about|do here)|how does this work|what can you do'
          r'|(?:me )?ajuda(?: aqui)?|socorro|preciso de ajuda|n[aã]o entendi|n[aã]o (?:estou|to|tô) entendendo|o que eu (?:posso|devo) (?:falar|dizer|perguntar)|como funciona',
    ),

    // --- rewards / progress -------------------------------------------------
    _Rule(
      'reward',
      DinoIntent.askReward,
      r'(?:can|do|will|did|could) i (?:get|have|win|earn) (?:a |my |some |any )?(?:reward|prize|gift|present|xp|points?|stickers?|stars?)s?|how (?:much|many) (?:xp|points|stars)(?: do i have)?'
          r'|what(?: is)? my (?:level|xp|score|points)|my (?:xp|level|points|score)|(?:give me|i want) (?:a |my )?(?:reward|prize|gift|present|xp|points)|rewards?|prizes?'
          r'|(?:quero )?(?:um |meu )?(?:pr[eê]mio|recompensa|presente)|(?:quanto|quantos) (?:xp|pontos)(?: eu tenho)?|(?:qual [eé] )?(?:o )?meu n[ií]vel|meus pontos',
    ),

    // --- requests to the Dino -----------------------------------------------
    _Rule(
      'request_en',
      DinoIntent.request,
      r'(?:(?:can|could|will|would) you |please |dino |now |go )*'
          r'(?<w>jump(?: up)?|dance|sing(?: a song| for me)?|go to sleep|sleep|go to bed|take a nap|nap|wake up|eat(?: .+)?|drink(?: .+)?|run|sit(?: down)?|stand up|walk|roar|spin|turn around|wave|smile|laugh|take a (?:bath|shower)|bathe|shower|wash(?: .+)?|brush your teeth|go to the (?:kitchen|bathroom|bed|bedroom|toys?)|play with (?:your )?toys?|come here)'
          r'(?: please| for me| now| again| dino)*',
    ),
    _Rule(
      'request_pt',
      DinoIntent.request,
      r'(?:(?:' +
          _you +
          r' )?(?:pode|consegue|sabe) |dino |agora |vai )*'
              r'(?<w>pul(?:ar|a|e)|dan[cç](?:ar|a|e)|cant(?:ar|a|e)(?: uma m[uú]sica)?|dorm(?:ir|e|a)|(?:ir|vai|v[aá]) dormir|acord(?:ar|a|e)|comer(?: .+)?|coma(?: .+)?|beb(?:er|e|a)(?: .+)?|corr(?:er|e|a)|sent(?:ar|a|e)|rugir|ruge|ruja|tom(?:ar|a|e) banho|and(?:ar|a|e)|(?:vem|venha) (?:aqui|c[aá])|sorri(?:r|a)?)'
              r'(?: por favor| pra mim| agora| de novo)*',
    ),

    // --- small talk -----------------------------------------------------------
    _Rule(
      'farewell',
      DinoIntent.farewell,
      r'(?:bye+|goodbye|bye bye|see you(?: later| soon| tomorrow)?|good night|night night|i have to go|i am leaving|i gotta go|gotta go|later'
          r'|tchau+|at[eé] (?:logo|mais|amanh[aã]|depois|a pr[oó]xima)|boa noite|fui|preciso ir|tenho que ir)(?: dino| friend| amigo)?',
    ),
    _Rule(
      'greeting',
      DinoIntent.greeting,
      r'(?:h+i+|hey+|hello+|hiya|howdy|yo|good (?:morning|afternoon|evening)|what is up|sup|oi+|ol[aá]+|ei|e a[ií]|bom dia|boa tarde)(?: there| dino| friend| buddy| amigo)?',
    ),
    _Rule(
      'thank_you',
      DinoIntent.thankYou,
      r'(?:thank you|thanks|thank u|thx|ty|obrigad[oa]|valeu|brigad[oa])(?: (?:so much|very much|a lot|dino|muito|mesmo))*',
    ),
    _Rule(
      'apology',
      DinoIntent.apology,
      r'(?:i am )?(?:so |very |really )?sorry(?: dino)?|my bad|oops|desculp[ae](?: dino)?|foi mal|perd[aã]o|me desculpe?',
    ),
    _Rule(
      'yes',
      DinoIntent.yes,
      r'(?:yes+|yeah|yep|yup|yea|ya|sure|ok|okay|of course|right|correct|true|i do|i did|i am|i want|sim|claro|isso|uhum|aham|certo|pode ser|com certeza|quero|yay|definitely|absolutely)(?: (?:please|it is|i do|dino|sure))*(?: (?<w>.+))?',
    ),
    _Rule(
      'no',
      DinoIntent.no,
      r'(?:no+|nope|nah|not really|no thanks|no thank you|never|n[aã]o|nem|of course not|i do not|i did not|wrong|errado|negativo|not now|agora n[aã]o)(?: (?:thanks|obrigad[oa]|dino))*(?: (?<w>.+))?',
    ),

    // --- last-resort meaning question ("what is a turtle?") -----------------
    _Rule(
      'meaning_what_is',
      DinoIntent.askWordMeaning,
      r'what (?:is|are) (?:a |an |the |this |that )?(?:word )?(?<w>.+)|o que [eé] (?:um |uma |o |a )?(?<w2>.+)',
      confidence: 0.75,
    ),
  ];

  static final RegExp _leadingGreeting = RegExp(
    r'^(?:h+i+|hey+|hello+|oi+|ol[aá]|ei|good morning|good afternoon|good evening|bom dia|boa tarde)\b\s*',
    unicode: true,
  );
  static final RegExp _leadingVocative = RegExp(
    r'^(?:dino|dinossauro|buddy|friend|amigo|so|and|um|uh|hmm|well|then|ent[aã]o|e a[ií])\b\s*',
    unicode: true,
  );
  static final RegExp _trailingFiller = RegExp(
    r'\s+(?:dino|please|por favor|pls)$',
    unicode: true,
  );

  IntentResult detect(NormalizedInput input, {PendingQuestion? pending}) {
    var text = input.text;
    if (text.isEmpty) return const IntentResult.unknown();

    // "hi dino, what does water mean please" -> "what does water mean".
    var hadGreeting = false;
    final greeting = _leadingGreeting.firstMatch(text);
    if (greeting != null && greeting.end < text.length) {
      hadGreeting = true;
      text = text.substring(greeting.end);
    }
    String previous;
    do {
      previous = text;
      final stripped = text.replaceFirst(_leadingVocative, '');
      if (stripped.isNotEmpty) text = stripped;
      final trimmed = text.replaceFirst(_trailingFiller, '');
      if (trimmed.isNotEmpty) text = trimmed;
    } while (text != previous);
    if (hadGreeting &&
        RegExp(r'^(?:dino|there|friend|buddy|amigo)$').hasMatch(text)) {
      text = 'hi';
    }

    final match = _match(text);
    if (pending == null) return match ?? const IntentResult.unknown();
    return _resolveWithPending(text, match, pending, input.isQuestion);
  }

  IntentResult? _match(String text) {
    for (final rule in _rules) {
      final result = rule.tryMatch(text);
      if (result != null) return result;
    }
    return null;
  }

  IntentResult _resolveWithPending(
    String text,
    IntentResult? match,
    PendingQuestion pending,
    bool isQuestion,
  ) {
    switch (pending) {
      case ConfirmWordQuestion() || ConfirmTeachQuestion():
        if (match?.intent == DinoIntent.yes) {
          return IntentResult(
            DinoIntent.confirmWord,
            slot: match!.slot,
            rule: 'pending_yes',
          );
        }
        if (match?.intent == DinoIntent.no) {
          return IntentResult(
            DinoIntent.denyWord,
            slot: match!.slot,
            rule: 'pending_no',
          );
        }
        if (match != null && _overridePending.contains(match.intent)) {
          return match;
        }
        // A bare word: maybe one of the offered candidates ("bed").
        return IntentResult(
          DinoIntent.confirmWord,
          confidence: 0.6,
          slot: text,
          rule: 'pending_word',
        );

      case OfferQuestion():
        if (match != null &&
            (match.intent == DinoIntent.yes || match.intent == DinoIntent.no)) {
          return match;
        }
        return match ?? const IntentResult.unknown();

      case QuizQuestion() ||
          RepeatWordQuestion() ||
          PreferenceQuestion() ||
          TeachTranslationQuestion() ||
          ChildNameQuestion() ||
          ChildFeelingQuestion():
        if (match != null &&
            _overridePending.contains(match.intent) &&
            !(match.intent == DinoIntent.askWordMeaning &&
                match.rule == 'meaning_what_is' &&
                !isQuestion)) {
          return match;
        }
        if (match?.intent == DinoIntent.teachWord &&
            match!.secondSlot != null) {
          // "dog is cachorro in Portuguese" as a quiz answer.
          return IntentResult(
            DinoIntent.answer,
            slot: match.secondSlot,
            rule: 'pending_teach_answer',
          );
        }
        if (match?.intent == DinoIntent.answer) return match!;
        return IntentResult(
          DinoIntent.answer,
          confidence: 0.8,
          // "yes"/"no"/"I don't know" stay visible to the manager as text.
          slot: text,
          rule: 'pending_answer',
        );
    }
  }
}
