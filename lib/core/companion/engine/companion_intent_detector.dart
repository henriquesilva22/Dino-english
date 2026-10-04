// Patterns are built from reusable raw-string fragments; concatenation
// keeps them raw (no double escaping), which interpolation would not.
// ignore_for_file: prefer_interpolation_to_compose_strings

import '../../brain/context/conversation_context.dart';
import '../../brain/intent/intent.dart';
import '../../brain/intent/intent_detector.dart';
import 'companion_intent.dart';
import 'text_normalizer.dart';

/// How a sentence was understood.
class IntentMatch {
  const IntentMatch(this.intent, {this.slot, this.brain, this.rule});

  final CompanionIntent intent;

  /// The thing the question is about, as said ("macas", "dogs").
  final String? slot;

  /// The brain's own reading, for intents the `DinoBrain` answers.
  final IntentResult? brain;

  /// Which rule matched -- for debugging and tests.
  final String? rule;

  @override
  String toString() => 'IntentMatch($intent, slot: $slot, rule: $rule)';
}

class _Rule {
  _Rule(this.name, this.intent, String pattern)
    : regex = RegExp('^(?:$pattern)\$');

  final String name;
  final CompanionIntent intent;
  final RegExp regex;

  IntentMatch? tryMatch(String text) {
    final m = regex.firstMatch(text);
    if (m == null) return null;
    String? slot;
    for (final n in m.groupNames) {
      final v = m.namedGroup(n)?.trim();
      if (v != null && v.isNotEmpty) {
        slot = v;
        break;
      }
    }
    return IntentMatch(intent, slot: slot, rule: name);
  }
}

/// Third step: accent-free text -> [CompanionIntent].
///
/// Companion questions and commands ("Você gosta de maçã?", "Tá com
/// fome?", "Come uma banana!") have their own keyword/alias rules here;
/// everything else is read by the brain's existing `IntentDetector`
/// (greetings, word questions, quiz answers...) and mapped -- one set of
/// patterns per idea, never two.
class CompanionIntentDetector {
  CompanionIntentDetector({IntentDetector? brainDetector})
    : _brain = brainDetector ?? IntentDetector();

  final IntentDetector _brain;

  static const _you = r'(?:voce |tu )?';
  static const _art =
      r'(?:(?:de|do|da|dos|das|o|a|os|as|um|uma|the|a|an|some) )?';

  /// "gosta de mim?" is affection, not a question about a thing.
  static const _notMe = r'(?!(?:(?:de|do|da) )?(?:me|mim|you|voce|ti)\b)';

  static final List<_Rule> _rules = [
    // -- about the Dino ----------------------------------------------------------
    _Rule(
      'age',
      CompanionIntent.askAge,
      r'(?:and )?how old (?:are|r) you(?: now| today)?|what is your age'
              r'|(?:e )?quantos anos ' +
          _you +
          r'(?:tem|voce tem)|(?:e )?' +
          _you +
          r'tem quantos anos|qual (?:e )?(?:a )?sua idade',
    ),
    _Rule(
      'doing',
      CompanionIntent.askWhatAreYouDoing,
      r'what (?:are|r) you (?:doing|up to)(?: now| today)?|whatcha doing|what you doing'
              r'|(?:e )?o (?:que|q) ' +
          _you +
          r'(?:esta|ta|tas|estas) fazendo(?: agora)?|' +
          _you +
          r'(?:esta|ta) fazendo o (?:que|q)|que ' +
          _you +
          r'(?:esta|ta) fazendo',
    ),

    // -- likes (affection "gosta de mim?" is left to the brain) ----------------
    _Rule(
      'dislike',
      CompanionIntent.askDislike,
      r'(?:do|did) you (?:hate|dislike) ' +
          _art +
          r'(?<x>.+)|what (?:do you not|do not you) like|what do you hate|is there (?:anything|something) you do not like'
              r'|' +
          _you +
          r'(?:odeia|detesta) ' +
          _art +
          r'(?<x2>.+)|' +
          _you +
          r'nao gosta ' +
          _art +
          r'(?<x3>.+)|(?:do )?o (?:que|q) ' +
          _you +
          r'nao gosta',
    ),
    _Rule(
      'favorite',
      CompanionIntent.askFavorite,
      r'(?:and )?what (?:is|are) your (?:favou?rite|best|preferred) (?<x>.+)|which (?<x2>.+?) do you like (?:best|most)|your favou?rite (?<x3>.+)'
          r'|(?:e )?qual (?:e )?(?:a |o )?(?:sua|seu|tua|teu) (?<x4>.+?) (?:favorit[oa]|preferid[oa])|(?:sua|seu) (?<x5>.+?) (?:favorit[oa]|preferid[oa])',
    ),
    _Rule(
      'like',
      CompanionIntent.askLike,
      r'(?:and )?(?:do|did) you (?:like|love|enjoy) ' +
          _notMe +
          _art +
          r'(?<x>.+)|you (?:like|love) ' +
          _notMe +
          _art +
          r'(?<x2>.+)'
              r'|(?:e )?' +
          _you +
          r'(?:gosta|curte|adora|ama|gostaria) ' +
          _notMe +
          _art +
          r'(?<x3>.+)',
    ),

    // -- needs ---------------------------------------------------------------------
    _Rule(
      'hungry',
      CompanionIntent.askHungry,
      r'(?:are you|r u|you) (?:still )?hungry|do you want (?:to eat|some food|food|something to eat)|want (?:to eat|food)'
              r'|' +
          _you +
          r'(?:(?:esta|ta|estas|ainda esta|ainda ta) )?com fome(?: ainda)?|' +
          _you +
          r'(?:quer|precisa|queria) (?:comer|comida|lanchar|um lanche)(?: alguma coisa| algo)?',
    ),
    _Rule(
      'thirsty',
      CompanionIntent.askThirsty,
      r'(?:are you|r u|you) (?:still )?thirsty|do you want (?:to drink|something to drink|water|some water)'
              r'|' +
          _you +
          r'(?:(?:esta|ta|estas|ainda esta|ainda ta) )?com sede(?: ainda)?|' +
          _you +
          r'(?:quer|precisa) (?:beber|tomar|agua)(?: agua| alguma coisa| algo)?',
    ),
    _Rule(
      'sleepy',
      CompanionIntent.askSleepy,
      r'(?:are you|r u|you) (?:still )?(?:sleepy|tired)|do you want to (?:sleep|rest|take a nap)'
              r'|' +
          _you +
          r'(?:(?:esta|ta|estas) )?com sono(?: ainda)?|' +
          _you +
          r'(?:esta|ta) cansad[oa]|' +
          _you +
          r'(?:quer|precisa) (?:dormir|descansar|tirar um cochilo)',
    ),

    // -- commands (imperatives to the Dino) ---------------------------------------
    _Rule(
      'cmd_eat',
      CompanionIntent.commandEat,
      r'(?:(?:can you|please|go|now) )*eat ' +
          _art +
          r'(?<x>.+)|(?:(?:can you|please|go|now) )*eat|time to eat'
              // "come here" is English, not "comer".
              r'|(?:(?:vai|pode|toma) )?(?:come|coma|comer) (?!here\b|on\b|back\b|aqui\b|ca\b)' +
          _art +
          r'(?<x2>.+)|(?:vai |pode )?(?:coma|comer)|hora de comer|(?:toma|tome) (?:sua |a )?comida',
    ),
    _Rule(
      'cmd_drink',
      CompanionIntent.commandDrink,
      r'(?:(?:can you|please|go|now) )*(?:drink|have) ' +
          _art +
          r'(?<x>water|milk|juice)|(?:(?:can you|please|go|now) )*drink(?: something)?'
              r'|(?:(?:vai|pode) )?(?:bebe|beba|beber|toma|tome|tomar) ' +
          _art +
          r'(?<x2>agua|aguinha|leite|suco|suquinho)|(?:vai |pode )?(?:bebe|beba|beber)(?: alguma coisa| algo)?',
    ),
    _Rule(
      'cmd_sleep',
      CompanionIntent.commandSleep,
      r'(?:(?:can you|please|now) )*(?:go to (?:sleep|bed)|sleep|take a nap)|(?:it is )?(?:bed ?time|time (?:to sleep|for bed))'
          r'|(?:vai |pode )?(?:dorme|durma|dormir)(?: agora)?|vai (?:pra|para a) cama|hora de (?:dormir|nanar|ir pra cama)|(?:vai )?nanar',
    ),
    _Rule(
      'cmd_play',
      CompanionIntent.commandPlay,
      r'(?:(?:can you|please|go|now) )*play (?:with )?' +
          _art +
          r'(?<x>ball|soccer|football|toys?|cars?)'
              r'|(?:vai |pode )?(?:brinca|brinque) (?:com )?' +
          _art +
          r'(?<x2>bola|bolinha|carrinho|carro|brinquedo)|(?:vai )?(?:joga|jogue|chuta|chute) ' +
          _art +
          r'(?<x3>bola|bolinha|futebol)',
    ),
  ];

  IntentMatch detect(NormalizedText text, {PendingQuestion? pending}) {
    if (text.isEmpty) return const IntentMatch(CompanionIntent.unknown);
    for (final rule in _rules) {
      final match = rule.tryMatch(text.folded);
      if (match != null) return match;
    }
    return _fromBrain(
      _brain.detect(text.input, pending: pending),
      text,
      pending,
    );
  }

  /// The brain's reading, in the companion's vocabulary.
  IntentMatch _fromBrain(
    IntentResult result,
    NormalizedText text,
    PendingQuestion? pending,
  ) {
    final intent = switch (result.intent) {
      DinoIntent.greeting => CompanionIntent.greeting,
      DinoIntent.farewell => CompanionIntent.goodbye,
      DinoIntent.askDinoName => CompanionIntent.askName,
      DinoIntent.askDinoFeeling => CompanionIntent.askHowAreYou,
      DinoIntent.askDinoNeed => _needIntent(result.slot ?? text.folded),
      DinoIntent.askDinoPreference =>
        (result.rule ?? '').contains('preference') &&
                RegExp(
                  r'favou?rite|favorit|preferid|best',
                ).hasMatch(text.folded)
            ? CompanionIntent.askFavorite
            : CompanionIntent.askLike,
      DinoIntent.askHelp => CompanionIntent.askHelp,
      DinoIntent.thankYou => CompanionIntent.thank,
      DinoIntent.apology => CompanionIntent.apology,
      DinoIntent.affection => CompanionIntent.affection,
      DinoIntent.praise => CompanionIntent.praise,
      DinoIntent.play => CompanionIntent.askPlay,
      DinoIntent.request => _commandIntent(result.slot ?? text.folded),
      DinoIntent.askWordMeaning ||
      DinoIntent.askTranslation ||
      DinoIntent.askWordExample => CompanionIntent.translateWord,
      DinoIntent.teachWord => CompanionIntent.learnWord,
      DinoIntent.answer || DinoIntent.confirmWord || DinoIntent.denyWord =>
        pending is RepeatWordQuestion
            ? CompanionIntent.repeatWord
            : CompanionIntent.answer,
      DinoIntent.yes => CompanionIntent.yes,
      DinoIntent.no => CompanionIntent.no,
      DinoIntent.startActivity => CompanionIntent.startActivity,
      DinoIntent.askActivity => CompanionIntent.askActivity,
      DinoIntent.askReward => CompanionIntent.askReward,
      DinoIntent.askMemory => CompanionIntent.askMemory,
      DinoIntent.unknown => CompanionIntent.unknown,
    };
    return IntentMatch(
      intent,
      slot: result.slot,
      brain: result,
      rule: result.rule,
    );
  }

  static CompanionIntent _needIntent(String text) {
    if (RegExp(r'hungry|fome|eat|comer|food|comida').hasMatch(text)) {
      return CompanionIntent.askHungry;
    }
    if (RegExp(r'thirsty|sede|drink|beber|water|agua').hasMatch(text)) {
      return CompanionIntent.askThirsty;
    }
    if (RegExp(r'tired|sleepy|sono|cansad|dormir|sleep').hasMatch(text)) {
      return CompanionIntent.askSleepy;
    }
    return CompanionIntent.askHowAreYou;
  }

  static CompanionIntent _commandIntent(String text) {
    // "come here" / "come back" are English, not "comer".
    if (RegExp(
      r'\beat\b|\bcom(?:er|a)\b|\bcome\b(?!\s+(?:here|back|on)\b)',
    ).hasMatch(text)) {
      return CompanionIntent.commandEat;
    }
    if (RegExp(r'\bdrink|\bbeb').hasMatch(text)) {
      return CompanionIntent.commandDrink;
    }
    if (RegExp(r'sleep|\bnap\b|\bbed\b|dorm').hasMatch(text)) {
      return CompanionIntent.commandSleep;
    }
    if (RegExp(r'\btoys?\b|brinquedo').hasMatch(text)) {
      return CompanionIntent.commandPlay;
    }
    return CompanionIntent.commandOther;
  }
}
