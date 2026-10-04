import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/speech/speech_service.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/speech_providers.dart';
import 'package:dino_english/providers/study_providers.dart';
import 'package:dino_english/widgets/study/learn_word_card.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never touches a real TTS plugin -- mirrors `_FakeSpeechService` in
/// speech_button_test.dart.
class _FakeSpeechService implements SpeechService {
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
  Future<void> stop() async {}
}

/// Bypasses `_loadSession()`'s DB work entirely -- `LearnWordCard` only
/// ever reads `session` (passed in as a plain constructor field) and calls
/// the inherited reveal/finish methods, so a fixed `build()` is enough for
/// a display-focused widget test.
class _FixedStudySessionController extends StudySessionController {
  _FixedStudySessionController(this._fixedState);

  final StudySessionState _fixedState;

  @override
  StudySessionState build() => _fixedState;
}

Word _word() => const Word(
  id: 'word.apple',
  englishTerm: 'apple',
  portugueseTranslation: 'maçã',
  category: 'food',
  difficulty: 1,
  recommendedLevel: 1,
  exampleSentenceEn: 'I eat an apple every day.',
  exampleSentencePt: 'Eu como uma maçã todos os dias.',
  pronunciationAudioAsset: null,
  imageAsset: null,
  isActive: true,
);

/// Seeded only so the card's `StreakBadge`/`XpLevelCard` header (unrelated
/// to what these tests check) has a user profile row to read.
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
  return database;
}

Widget _wrap(AppDatabase database, StudySessionState state) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      studySessionProvider.overrideWith(
        () => _FixedStudySessionController(state),
      ),
      speechServiceProvider.overrideWithValue(_FakeSpeechService()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) =>
              LearnWordCard(session: ref.watch(studySessionProvider)),
        ),
      ),
    ),
  );
}

/// Dispose while still inside the test's zone, then flush the
/// zero-duration timer Drift schedules when cancelling stream queries on
/// close -- same fix as test/widget_test.dart, otherwise it fires after
/// the test ends and trips flutter_test's "no pending timers" invariant.
Future<void> _flushDriftTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase database;

  setUp(() async {
    database = await _seededDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('shows PALAVRA NOVA for a new word with translation visible', (
    tester,
  ) async {
    final question = StudyQuestion(
      word: _word(),
      options: const [],
      isNewWord: true,
    );
    final state = StudySessionState(
      items: [question],
      isLoading: false,
      isWordTranslationRevealed: true,
      isSentenceTranslationRevealed: true,
    );

    await tester.pumpWidget(_wrap(database, state));

    expect(find.text('PALAVRA NOVA'), findsOneWidget);
    expect(find.text('MODO IMERSÃO'), findsNothing);
    expect(find.text('maçã'), findsOneWidget);
    expect(find.text('Eu como uma maçã todos os dias.'), findsOneWidget);
    expect(find.text('Ver tradução'), findsNothing);

    await _flushDriftTimers(tester);
  });

  testWidgets(
    'shows MODO IMERSÃO for a known word with translations hidden behind reveal buttons',
    (tester) async {
      final question = StudyQuestion(
        word: _word(),
        options: const [],
        isNewWord: false,
      );
      final state = StudySessionState(items: [question], isLoading: false);

      await tester.pumpWidget(_wrap(database, state));

      expect(find.text('MODO IMERSÃO'), findsOneWidget);
      expect(find.text('PALAVRA NOVA'), findsNothing);
      expect(find.text('maçã'), findsNothing);
      expect(find.text('Eu como uma maçã todos os dias.'), findsNothing);
      expect(find.text('Ver tradução'), findsOneWidget);
      expect(find.text('Ver tradução da frase'), findsOneWidget);

      await _flushDriftTimers(tester);
    },
  );

  testWidgets('tapping Ver tradução reveals the word translation only', (
    tester,
  ) async {
    final question = StudyQuestion(
      word: _word(),
      options: const [],
      isNewWord: false,
    );
    final state = StudySessionState(items: [question], isLoading: false);

    await tester.pumpWidget(_wrap(database, state));
    await tester.tap(find.text('Ver tradução'));
    await tester.pump();

    expect(find.text('maçã'), findsOneWidget);
    expect(find.text('Eu como uma maçã todos os dias.'), findsNothing);
    expect(find.text('Ver tradução da frase'), findsOneWidget);

    await _flushDriftTimers(tester);
  });

  testWidgets(
    'tapping Ver tradução da frase reveals the sentence translation only',
    (tester) async {
      final question = StudyQuestion(
        word: _word(),
        options: const [],
        isNewWord: false,
      );
      final state = StudySessionState(items: [question], isLoading: false);

      await tester.pumpWidget(_wrap(database, state));
      await tester.tap(find.text('Ver tradução da frase'));
      await tester.pump();

      expect(find.text('Eu como uma maçã todos os dias.'), findsOneWidget);
      expect(find.text('maçã'), findsNothing);
      expect(find.text('Ver tradução'), findsOneWidget);

      await _flushDriftTimers(tester);
    },
  );
}
