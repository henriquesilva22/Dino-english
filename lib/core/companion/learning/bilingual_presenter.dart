import '../../brain/nlp/normalizer.dart';
import '../companion_response.dart';
import '../engine/companion_intent.dart';
import 'learning_word.dart';
import 'learning_word_bank.dart';

/// How the Dino talks: in Portuguese, with one English word slipped in
/// where it fits ("Estou com fome!" -> "Estou HUNGRY!", "Que delícia!
/// Obrigado!" -> "Que delícia! THANK YOU!").
///
/// Every reply line already carries its Portuguese meaning; this shows
/// that Portuguese and swaps one word the lesson bank knows for its
/// English. Never more than one English word per reply (no
/// incomprehensible mixes) and never a translation on screen: the child
/// asks "o que é thank you?" when curious, and the word lesson answers.
/// Lessons, translations and quizzes (the child asked for the English)
/// are left as they are.
class BilingualPresenter {
  BilingualPresenter(this._bank) {
    for (final word in _bank.words) {
      if (!word.insertable) continue;
      for (final form in word.forms) {
        final folded = Normalizer.fold(form);
        if (folded.isEmpty) continue;
        _forms.add((folded, word));
        // "maçãs", "bolas": the plural of a noun is the same word.
        if (word.type == WordType.noun && !folded.contains(' ')) {
          final plural = _plural(folded);
          if (plural != folded) _forms.add((plural, word));
        }
      }
    }
    // Longest first: "com fome" before "fome", "gosto de" before "gosto".
    _forms.sort((a, b) => b.$1.length.compareTo(a.$1.length));
  }

  final LearningWordBank _bank;
  final List<(String, LearningWord)> _forms = [];

  /// Replies the child asked to hear in English, or as a lesson: kept.
  static const Set<CompanionIntent> _asIs = {
    CompanionIntent.learnWord,
    CompanionIntent.translateWord,
    CompanionIntent.repeatWord,
    CompanionIntent.requestPortuguese,
    CompanionIntent.requestTranslation,
    CompanionIntent.answer,
  };

  /// [response] in Portuguese with (at most) one English word.
  CompanionResponse present(CompanionResponse response) {
    if (_asIs.contains(response.intent)) return response;
    if (response.voice != VoiceMode.english) return response;
    if (!response.lines.any((l) => l.translation != null)) return response;
    var inserted = response.lines.any(
      (l) => l.isMixed && l.english!.isNotEmpty,
    );
    final lines = <CompanionLine>[];
    for (final line in response.lines) {
      final pt = line.translation;
      if (pt == null) {
        lines.add(line);
        continue;
      }
      // English the Portuguese already quotes ("Diga: Apple!") is spoken
      // in English.
      final quoted = _quotedEnglish(line.text, pt);
      if (quoted.isNotEmpty) {
        lines.add(CompanionLine.mixed(_upper(pt, quoted), english: quoted));
        inserted = true;
        continue;
      }
      // Quoted words ("dog") are part of a question: keep the line.
      if (pt.contains('"') || line.text.contains('"')) {
        lines.add(line);
        continue;
      }
      if (!inserted) {
        final swapped = insertWord(
          pt,
          prefer: {...response.vocabulary, ...response.detectedWords},
        );
        if (swapped != null) {
          lines.add(swapped);
          inserted = true;
          continue;
        }
      }
      lines.add(CompanionLine.mixed(pt));
    }
    return response.copyWith(lines: lines);
  }

  /// [portuguese] with a word the bank knows shown in English, or null
  /// if none fits: the word the reply is about ([prefer], "bread" in
  /// "Vamos comer pão!") first, then the longest form.
  CompanionLine? insertWord(
    String portuguese, {
    Set<String> prefer = const {},
  }) {
    final folded = Normalizer.fold(portuguese);
    // Fold keeps one letter per letter, so positions match the original.
    if (folded.length != portuguese.length) return null;
    (int, int, LearningWord)? best;
    var bestPreferred = false;
    for (final (form, word) in _forms) {
      final at = _wordAt(folded, form);
      if (at < 0) continue;
      final end = at + form.length;
      final preferred = prefer.contains(word.english);
      if (bestPreferred && !preferred) continue;
      if (best == null ||
          (preferred && !bestPreferred) ||
          form.length > best.$2 - best.$1 ||
          (form.length == best.$2 - best.$1 && at < best.$1)) {
        best = (at, end, word);
        bestPreferred = preferred;
      }
    }
    if (best == null) return null;
    final (start, end, word) = best;
    final text =
        portuguese.substring(0, start) +
        word.display +
        portuguese.substring(end);
    return CompanionLine.mixed(text, english: [word.display]);
  }

  /// Bank words written in both the English line and its Portuguese.
  List<String> _quotedEnglish(String english, String portuguese) {
    final en = Normalizer.fold(english);
    final pt = Normalizer.fold(portuguese);
    return [
      for (final word in _bank.words)
        if (_wordAt(pt, word.english) >= 0 &&
            _wordAt(en, word.english) >= 0 &&
            // A word that is the same in both languages is Portuguese too
            // ("banana", "pizza").
            !word.forms.any((f) => Normalizer.fold(f) == word.english))
          word.display,
    ];
  }

  static String _upper(String text, List<String> words) {
    var out = text;
    for (final w in words) {
      out = out.replaceAllMapped(
        RegExp('\\b${RegExp.escape(w)}\\b', caseSensitive: false),
        (_) => w,
      );
    }
    return out;
  }

  /// Where [form] occurs in [text] as whole word(s), or -1.
  static int _wordAt(String text, String form) {
    var from = 0;
    while (true) {
      final at = text.indexOf(form, from);
      if (at < 0) return -1;
      final end = at + form.length;
      final before = at == 0 || !_isLetter(text[at - 1]);
      final after = end == text.length || !_isLetter(text[end]);
      if (before && after) return at;
      from = at + 1;
    }
  }

  /// Portuguese plural of a (folded) noun, regular cases only.
  static String _plural(String noun) {
    if (noun.endsWith('ao')) return '${noun.substring(0, noun.length - 2)}oes';
    if (RegExp(r'[aeiou]$').hasMatch(noun)) return '${noun}s';
    if (RegExp(r'[rz]$').hasMatch(noun)) return '${noun}es';
    if (noun.endsWith('l')) return '${noun.substring(0, noun.length - 1)}is';
    return noun;
  }

  static bool _isLetter(String c) => RegExp(r'[a-z0-9]').hasMatch(c);
}
