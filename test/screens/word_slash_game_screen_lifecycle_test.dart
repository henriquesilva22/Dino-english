import 'dart:async';

import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/models/word_candidate.dart';
import 'package:dino_english/core/repositories/word_repository.dart';
import 'package:dino_english/core/services/distractor_picker.dart';
import 'package:dino_english/game/sound/word_slash_sfx.dart';
import 'package:dino_english/game/sound/word_slash_sound_service.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/repository_providers.dart';
import 'package:dino_english/providers/word_slash_providers.dart';
import 'package:dino_english/screens/word_slash_game_screen.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWordSlashSoundService implements WordSlashSoundService {
  @override
  Future<void> preload() async {}

  @override
  void play(WordSlashSfx sfx) {}
}

/// Wraps a real [WordRepository], gating [fetchCandidatePool] on
/// [candidatePoolGate] (when set) to simulate leaving mid-load, and
/// counting [fetchActiveWordsCallCount] -- the *next* call `_fetchBatch`
/// makes after the gated one. If the abandoned continuation's `ref
/// .mounted` guard works, that count must stay 0 forever once the screen
/// is popped, even after the gate opens.
class _GatedWordRepository implements WordRepository {
  _GatedWordRepository(this._real);

  final WordRepository _real;
  Completer<void>? candidatePoolGate;
  int fetchActiveWordsCallCount = 0;

  @override
  Future<List<WordCandidate>> fetchCandidatePool() async {
    final gate = candidatePoolGate;
    if (gate != null) await gate.future;
    return _real.fetchCandidatePool();
  }

  @override
  Future<List<Word>> fetchActiveWords() {
    fetchActiveWordsCallCount++;
    return _real.fetchActiveWords();
  }

  @override
  Future<Word?> fetchWordById(String id) => _real.fetchWordById(id);

  @override
  Future<List<DistractorCandidate>> fetchDistractorPool() =>
      _real.fetchDistractorPool();
}

Future<AppDatabase> _seededDatabase() async {
  final database = AppDatabase(NativeDatabase.memory());
  await database
      .into(database.userProfile)
      .insertOnConflictUpdate(
        UserProfileCompanion.insert(
          id: const Value(1),
          createdAt: DateTime(2026),
        ),
      );
  await database
      .into(database.dinoEvolutionState)
      .insertOnConflictUpdate(
        DinoEvolutionStateCompanion.insert(id: const Value(1)),
      );
  for (var i = 0; i < 6; i++) {
    await database
        .into(database.words)
        .insert(
          WordsCompanion.insert(
            id: 'slash$i',
            englishTerm: 'slash$i',
            portugueseTranslation: 'slash$i (pt)',
            category: 'test',
            difficulty: 1,
            recommendedLevel: 1,
            exampleSentenceEn: 'This is slash$i.',
            exampleSentencePt: 'Isto é slash$i.',
          ),
        );
  }
  return database;
}

Widget _harness({
  required AppDatabase database,
  WordRepository? wordRepository,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      wordSlashSoundServiceProvider.overrideWithValue(
        _FakeWordSlashSoundService(),
      ),
      if (wordRepository != null)
        wordRepositoryProvider.overrideWithValue(wordRepository),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WordSlashGameScreen()),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'leaving via the system back gesture stops the round and restores portrait orientation',
    (tester) async {
      final orientationCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            orientationCalls.add(call.method);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      final database = await _seededDatabase();
      addTearDown(database.close);

      await tester.pumpWidget(_harness(database: database));
      await tester.tap(find.text('open'));
      await tester.pump();
      // The initial word batch is a real (if fast, in-memory) DB round
      // trip -- pump until the loading spinner is gone.
      for (
        var i = 0;
        i < 30 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Simulates the actual Android system back gesture/button, exactly
      // like `pet_adventure_game_screen_lifecycle_test.dart` -- routes
      // through `WordSlashGameScreen`'s `PopScope`.
      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(
        orientationCalls,
        isNotEmpty,
        reason:
            'portrait should be restored once the screen is popped -- and since '
            '_handlePop calls endSession() before this, seeing it proves the '
            'whole "stop everything, then leave" chain actually ran',
      );
    },
  );

  testWidgets(
    'leaving mid-load never lets the abandoned load continuation reach the second DB call '
    '(Risk 3 from the design review: ref.mounted must guard every post-await continuation)',
    (tester) async {
      final database = await _seededDatabase();
      addTearDown(database.close);
      final gatedRepository = _GatedWordRepository(WordRepository(database))
        ..candidatePoolGate = Completer<void>();

      await tester.pumpWidget(
        _harness(database: database, wordRepository: gatedRepository),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'still blocked on the gated fetchCandidatePool()',
      );
      expect(gatedRepository.fetchActiveWordsCallCount, 0);

      // Leave now, while the load is still suspended mid-await.
      await tester.binding.handlePopRoute();
      await tester.pump();
      // The route's own exit *animation* -- not the pop call itself --
      // is what actually finishes tearing down the screen's State
      // (dispose()), which is what removes ref.watch's listener and lets
      // `.autoDispose` proceed; both are confirmed non-synchronous with
      // the pop elsewhere in this app (pet_adventure_game_screen.dart's
      // own comments) and while writing this very test. Without this,
      // the provider is often still "mounted" when the gate below opens.
      await tester.pump(const Duration(milliseconds: 350));

      // Only now let the abandoned fetchCandidatePool() actually resolve.
      gatedRepository.candidatePoolGate!.complete();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        gatedRepository.fetchActiveWordsCallCount,
        0,
        reason:
            'the abandoned continuation must observe ref.mounted == false and bail '
            'out before ever making the *next* DB call for a screen that is already gone',
      );
    },
  );
}
