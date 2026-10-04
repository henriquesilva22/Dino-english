/// What kind of thing the Dino remembers. Only these are ever stored --
/// small talk is not ("save only relevant memories").
enum DinoMemoryKind {
  /// key = topic (`food`, `animal`, `color`...), value = English word.
  preference,

  /// Official word practised in conversation. key = word id, value =
  /// English term, confidence = conversational mastery (0..1). Never a
  /// translation: the official one always comes from the word bank.
  learnedWord,

  /// A word the child taught that is NOT in the word bank. key = English
  /// word, value = Portuguese. Never used to grade anything.
  taughtWord,

  /// key = activity name, value = times started from a conversation.
  activity,

  /// key = task id, value = description (future: tidy room, feed Dino...).
  task,

  /// key = fact name (`child_name`, `child_age`), value = fact.
  fact,

  /// An English word met in the Dino's Portuguese sentences ("Eu vou
  /// WALK amanhã"). key = the English word, value = its `WordMastery`
  /// as JSON (level, repetitions, last seen), confidence = level / 4.
  wordMastery,
}

class DinoMemory {
  const DinoMemory({
    required this.kind,
    required this.key,
    required this.value,
    this.confidence = 1.0,
    this.timesReinforced = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final DinoMemoryKind kind;
  final String key;
  final String value;
  final double confidence;
  final int timesReinforced;
  final DateTime createdAt;
  final DateTime updatedAt;

  DinoMemory copyWith({
    String? value,
    double? confidence,
    int? timesReinforced,
    DateTime? updatedAt,
  }) {
    return DinoMemory(
      kind: kind,
      key: key,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      timesReinforced: timesReinforced ?? this.timesReinforced,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Persistence port for [DinoMemoryBank]. The app uses the Drift-backed
/// `DriftDinoMemoryStore`; tests use [InMemoryDinoMemoryStore].
abstract class DinoMemoryStore {
  Future<List<DinoMemory>> loadAll();
  Future<void> save(DinoMemory memory);
  Future<void> delete(DinoMemoryKind kind, String key);
}

class InMemoryDinoMemoryStore implements DinoMemoryStore {
  final Map<String, DinoMemory> _rows = {};

  @override
  Future<List<DinoMemory>> loadAll() async => _rows.values.toList();

  @override
  Future<void> save(DinoMemory memory) async =>
      _rows['${memory.kind.name}/${memory.key}'] = memory;

  @override
  Future<void> delete(DinoMemoryKind kind, String key) async =>
      _rows.remove('${kind.name}/$key');
}

/// The Dino's long-term memory: an in-memory cache over a
/// [DinoMemoryStore], with one method per thing worth remembering so the
/// "what is relevant" policy lives in one place.
class DinoMemoryBank {
  DinoMemoryBank(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DinoMemoryStore _store;
  final DateTime Function() _clock;
  final Map<String, DinoMemory> _cache = {};

  static const double _learnedStep = 0.15;
  static const double _forgetStep = 0.10;
  static const double taughtWordConfidence = 0.5;

  Future<void> load() async {
    _cache.clear();
    for (final m in await _store.loadAll()) {
      _cache[_id(m.kind, m.key)] = m;
    }
  }

  String _id(DinoMemoryKind kind, String key) => '${kind.name}/$key';

  DinoMemory? recall(DinoMemoryKind kind, String key) => _cache[_id(kind, key)];

  List<DinoMemory> all(DinoMemoryKind kind) =>
      _cache.values.where((m) => m.kind == kind).toList(growable: false);

  Future<DinoMemory> _upsert(
    DinoMemoryKind kind,
    String key,
    String value, {
    double? confidence,
    bool reinforce = true,
  }) async {
    final now = _clock();
    final existing = recall(kind, key);
    final memory = existing == null
        ? DinoMemory(
            kind: kind,
            key: key,
            value: value,
            confidence: confidence ?? 1.0,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            value: value,
            confidence: confidence,
            timesReinforced: existing.timesReinforced + (reinforce ? 1 : 0),
            updatedAt: now,
          );
    _cache[_id(kind, key)] = memory;
    await _store.save(memory);
    return memory;
  }

  // ---- preferences --------------------------------------------------------

  String? preference(String topic) =>
      recall(DinoMemoryKind.preference, topic)?.value;

  Future<void> rememberPreference(String topic, String englishWord) =>
      _upsert(DinoMemoryKind.preference, topic, englishWord);

  // ---- learned (official) words -------------------------------------------

  double learnedConfidence(String wordId) =>
      recall(DinoMemoryKind.learnedWord, wordId)?.confidence ?? 0;

  /// Moves the conversational mastery of an official word. Stores only
  /// the word id and English term -- the translation always comes from
  /// the word bank, so a wrong answer can never teach a wrong meaning.
  Future<double> reinforceLearnedWord(
    String wordId,
    String englishTerm, {
    required bool correct,
  }) async {
    final current = learnedConfidence(wordId);
    final next = (correct ? current + _learnedStep : current - _forgetStep)
        .clamp(0.0, 1.0);
    final memory = await _upsert(
      DinoMemoryKind.learnedWord,
      wordId,
      englishTerm,
      confidence: next,
    );
    return memory.confidence;
  }

  /// A word was talked about (asked, explained): remembered with a small
  /// confidence so it can be picked for a later quiz.
  Future<void> noteWordDiscussed(String wordId, String englishTerm) async {
    if (recall(DinoMemoryKind.learnedWord, wordId) != null) return;
    await _upsert(
      DinoMemoryKind.learnedWord,
      wordId,
      englishTerm,
      confidence: 0.1,
    );
  }

  // ---- words met in hybrid sentences ---------------------------------------

  /// The stored mastery JSON of [englishWord], or null if never met.
  String? wordMastery(String englishWord) =>
      recall(DinoMemoryKind.wordMastery, englishWord.toLowerCase())?.value;

  Future<void> saveWordMastery(
    String englishWord,
    String json, {
    required double confidence,
  }) => _upsert(
    DinoMemoryKind.wordMastery,
    englishWord.toLowerCase(),
    json,
    confidence: confidence,
  );

  // ---- words taught by the child (unofficial) -----------------------------

  String? taughtTranslation(String englishWord) =>
      recall(DinoMemoryKind.taughtWord, englishWord.toLowerCase())?.value;

  Future<void> rememberTaughtWord(String englishWord, String portuguese) =>
      _upsert(
        DinoMemoryKind.taughtWord,
        englishWord.toLowerCase(),
        portuguese,
        confidence: taughtWordConfidence,
      );

  // ---- activities, tasks, facts -------------------------------------------

  Future<void> rememberActivity(String activity) {
    final times =
        int.tryParse(recall(DinoMemoryKind.activity, activity)?.value ?? '') ??
        0;
    return _upsert(DinoMemoryKind.activity, activity, '${times + 1}');
  }

  Future<void> rememberTask(String taskId, String description) =>
      _upsert(DinoMemoryKind.task, taskId, description);

  Future<void> completeTask(String taskId) async {
    _cache.remove(_id(DinoMemoryKind.task, taskId));
    await _store.delete(DinoMemoryKind.task, taskId);
  }

  String? fact(String key) => recall(DinoMemoryKind.fact, key)?.value;

  Future<void> rememberFact(String key, String value) =>
      _upsert(DinoMemoryKind.fact, key, value);
}

/// Facts ([DinoMemoryKind.fact]) the companion keeps. Favorites
/// (food, colors, animals) are [DinoMemoryKind.preference]s.
abstract final class MemoryKeys {
  static const String childName = 'child_name';
  static const String childAge = 'child_age';

  /// Last care activity (`feed`, `water`, `play`, `sleep`).
  static const String lastActivity = 'last_activity';

  /// Last official word the child repeated/answered correctly.
  static const String lastWordLearned = 'last_word_learned';

  /// ISO time of the last sentence the child said.
  static const String lastInteraction = 'last_interaction';
}
