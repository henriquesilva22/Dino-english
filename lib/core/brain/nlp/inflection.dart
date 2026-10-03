/// Tiny English morphology so "apples", "mice", "jumping" find the
/// vocabulary entries "apple", "mouse", "jump", and the Dino can say "You
/// like apples!" back. Rules, not a dictionary -- good enough for a
/// children's word bank.
class Inflection {
  const Inflection();

  static const Map<String, String> _irregularSingular = {
    'mice': 'mouse',
    'children': 'child',
    'kids': 'child',
    'feet': 'foot',
    'teeth': 'tooth',
    'men': 'man',
    'women': 'woman',
    'people': 'person',
    'geese': 'goose',
    'wolves': 'wolf',
    'knives': 'knife',
  };

  static final Map<String, String> _irregularPlural = {
    for (final e in _irregularSingular.entries)
      if (e.key != 'kids') e.value: e.key,
  };

  /// Nouns that stay the same when talking about liking them.
  static const Set<String> _uncountable = {
    'water',
    'milk',
    'juice',
    'rice',
    'bread',
    'cheese',
    'meat',
    'coffee',
    'tea',
    'soup',
    'salad',
    'sugar',
    'chocolate',
    'candy',
    'fish',
    'sheep',
    'chicken',
    'ice cream',
    'pizza',
    'cake',
    'breakfast',
    'lunch',
    'dinner',
    'grass',
    'rain',
    'wind',
    'hair',
    'paper',
    'soap',
    'light',
    'pants',
    'shoes',
    'deer',
    'family',
  };

  /// Candidate base forms, most likely first, always starting with the
  /// word itself.
  List<String> baseForms(String word) {
    final w = word.toLowerCase();
    final forms = <String>[w];
    void add(String f) {
      if (f.length >= 2 && !forms.contains(f)) forms.add(f);
    }

    final irregular = _irregularSingular[w];
    if (irregular != null) add(irregular);

    if (w.endsWith('ies') && w.length > 4) {
      add('${w.substring(0, w.length - 3)}y');
    }
    if (w.endsWith('ves') && w.length > 4) {
      add('${w.substring(0, w.length - 3)}f');
      add('${w.substring(0, w.length - 3)}fe');
    }
    if (w.endsWith('es') && w.length > 3) add(w.substring(0, w.length - 2));
    if (w.endsWith('s') && !w.endsWith('ss') && w.length > 2) {
      add(w.substring(0, w.length - 1));
    }
    for (final suffix in const ['ing', 'ed']) {
      if (w.endsWith(suffix) && w.length > suffix.length + 2) {
        final stem = w.substring(0, w.length - suffix.length);
        add(stem);
        add('${stem}e'); // dancing -> dance
        if (stem.length > 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
          add(stem.substring(0, stem.length - 1)); // running -> run
        }
      }
    }
    return forms;
  }

  /// "apple" -> "apples", "strawberry" -> "strawberries", "rice" -> "rice".
  String pluralize(String word) {
    final w = word.toLowerCase();
    if (_uncountable.contains(w) || w.contains(' ')) return w;
    final irregular = _irregularPlural[w];
    if (irregular != null) return irregular;
    if (RegExp(r'[^aeiou]y$').hasMatch(w)) {
      return '${w.substring(0, w.length - 1)}ies';
    }
    if (RegExp(r'(s|x|z|ch|sh)$').hasMatch(w) ||
        w == 'potato' ||
        w == 'tomato') {
      return '${w}es';
    }
    return '${w}s';
  }
}
