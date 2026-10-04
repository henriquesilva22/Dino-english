import 'dart:math';

import '../../brain/model/dino_enums.dart';
import '../companion_response.dart';
import 'companion_entity.dart';
import 'response_bank.dart';

/// Fifth step: picks one line for a situation from the response bank --
/// right for the child's level, never the same one twice in a row -- and
/// fills its placeholders.
class ResponseSelector {
  ResponseSelector({Random? random, this._bank = defaultResponseBank})
    : _random = random ?? Random();

  final Random _random;
  final Map<String, List<ResponseTemplate>> _bank;

  /// Recently used line indexes per key, so variety is real.
  final Map<String, List<int>> _recent = {};

  /// How many recent lines are avoided (when the pool allows it).
  static const int memory = 3;

  bool has(String key) => _bank.containsKey(key);

  List<ResponseTemplate> pool(String key) => _bank[key] ?? const [];

  CompanionLine select(
    String key, {
    EnglishTier tier = EnglishTier.a1,
    Map<String, String> vars = const {},
  }) {
    final all = pool(key);
    if (all.isEmpty) throw ArgumentError('No responses for "$key"');
    final eligible = [
      for (var i = 0; i < all.length; i++)
        if (all[i].tier.index <= tier.index) i,
    ];
    final candidates = eligible.isEmpty ? [0] : eligible;
    final recent = _recent[key] ??= [];
    final avoid = recent
        .skip(max(0, recent.length - min(memory, candidates.length - 1)))
        .toSet();
    final fresh = candidates.where((i) => !avoid.contains(i)).toList();
    final choice = (fresh.isEmpty
        ? candidates
        : fresh)[_random.nextInt((fresh.isEmpty ? candidates : fresh).length)];
    recent.add(choice);
    if (recent.length > memory) recent.removeAt(0);
    final template = all[choice];
    return CompanionLine(fill(template.en, vars), fill(template.pt, vars));
  }

  static String fill(String text, Map<String, String> vars) {
    var out = text;
    vars.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out.replaceAll(RegExp(r'\s+'), ' ').replaceAll(' !', '!').trim();
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// Placeholders for a thing: `{en}`, `{EnG}`, `{ptG}`, `{be}`...
  static Map<String, String> entityVars(CompanionEntity e) {
    final plural = e.countable;
    return {
      'en': e.english,
      'En': _cap(e.english),
      'enG': e.englishGeneric,
      'EnG': _cap(e.englishGeneric),
      'pt': e.portuguese,
      'Pt': _cap(e.portuguese),
      'ptG': e.portugueseGeneric,
      'PtG': _cap(e.portugueseGeneric),
      'be': plural ? 'are' : 'is',
      'ser': plural ? 'são' : 'é',
      'legal': plural ? 'legais' : 'legal',
      'emoji': e.emoji,
    };
  }
}
