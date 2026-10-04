import 'dart:convert';
import 'dart:io';

import 'package:dino_english/core/companion/learning/learning_word_bank.dart';

/// The real bundled lesson bank, parsed straight from the asset.
LearningWordBank loadLearningBank() => LearningWordBank.fromJson(
  jsonDecode(File(LearningWordBank.asset).readAsStringSync())
      as Map<String, dynamic>,
);

final LearningWordBank learningBank = loadLearningBank();
