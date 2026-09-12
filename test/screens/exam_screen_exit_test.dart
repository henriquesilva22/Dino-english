import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/screens/exam_screen.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _seededDatabase() async {
  final database = AppDatabase(NativeDatabase.memory());
  await database
      .into(database.userProfile)
      .insertOnConflictUpdate(
        UserProfileCompanion.insert(id: const Value(1), createdAt: DateTime(2026)),
      );
  await database.into(database.words).insert(
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
  await database
      .into(database.wordProgress)
      .insert(
        WordProgressCompanion.insert(
          wordId: 'dog',
          lastResultCorrect: const Value(false),
        ),
      );
  return database;
}

void main() {
  testWidgets('the exit button pops the exam screen at any point in the session', (
    tester,
  ) async {
    final database = await _seededDatabase();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExamScreen()),
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

    expect(find.byType(ExamScreen), findsOneWidget);
    expect(find.text('Provas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(ExamScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
