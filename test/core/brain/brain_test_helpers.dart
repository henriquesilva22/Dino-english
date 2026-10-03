import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dino_english/core/brain/dino_brain.dart';
import 'package:dino_english/core/brain/memory/dino_memory.dart';
import 'package:dino_english/core/brain/vocabulary/official_vocabulary.dart';

/// The real bundled word bank, parsed straight from the seed JSON (no
/// database), so brain tests exercise the actual 240-word vocabulary.
OfficialVocabulary loadSeedVocabulary() {
  final json =
      jsonDecode(File('assets/seed/words_seed.json').readAsStringSync())
          as Map<String, dynamic>;
  final words = (json['words'] as List).cast<Map<String, dynamic>>();
  return OfficialVocabulary(
    words.map(
      (w) => VocabularyEntry(
        id: w['id'] as String,
        english: w['english_term'] as String,
        portuguese: w['portuguese_translation'] as String,
        category: w['category'] as String,
        difficulty: w['difficulty'] as int,
        exampleEn: w['example_sentence_en'] as String,
        examplePt: w['example_sentence_pt'] as String,
        senses: (w['senses'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(WordSense.fromJson)
            .toList(),
      ),
    ),
  );
}

final OfficialVocabulary seedVocabulary = loadSeedVocabulary();

Future<(DinoBrain, DinoMemoryBank, InMemoryDinoMemoryStore)> newBrain({
  int seed = 1,
}) async {
  final store = InMemoryDinoMemoryStore();
  final memory = DinoMemoryBank(store);
  await memory.load();
  final brain = DinoBrain(
    vocabulary: seedVocabulary,
    memory: memory,
    random: Random(seed),
  );
  return (brain, memory, store);
}
