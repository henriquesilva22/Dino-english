import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/speech/speech_service.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/speech_providers.dart';
import 'package:dino_english/screens/sentence_builder_screen.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSpeechService implements SpeechService {
  int stopCallCount = 0;

  @override
  ValueListenable<Object?> get activeUtterance => ValueNotifier(null);

  @override
  Future<SpeechResult> speak(
    String text, {
    String locale = kEnglishLocale,
    double? rate,
    double? pitch,
  }) async => SpeechResult.spoken;

  @override
  Future<void> stop() async {
    stopCallCount++;
  }
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
  await database
      .into(database.words)
      .insert(
        WordsCompanion.insert(
          id: 'dog',
          englishTerm: 'dog',
          portugueseTranslation: 'cachorro',
          category: 'animals',
          difficulty: 1,
          recommendedLevel: 1,
          exampleSentenceEn: 'The dog is very happy.',
          exampleSentencePt: 'O cachorro está muito feliz.',
        ),
      );
  return database;
}

void main() {
  testWidgets('the exit button pops the screen and stops any active speech', (
    tester,
  ) async {
    final database = await _seededDatabase();
    addTearDown(database.close);
    final fakeSpeech = _FakeSpeechService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          speechServiceProvider.overrideWithValue(fakeSpeech),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SentenceBuilderScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SentenceBuilderScreen), findsOneWidget);
    expect(find.text('Montar Frase'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(SentenceBuilderScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(fakeSpeech.stopCallCount, 1);

    // Dispose while still inside this test's zone, then flush the
    // zero-duration timer Drift schedules when cancelling stream
    // queries on close -- same fix as test/widget_test.dart, otherwise
    // it fires after the test ends and trips flutter_test's "no
    // pending timers" invariant.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
