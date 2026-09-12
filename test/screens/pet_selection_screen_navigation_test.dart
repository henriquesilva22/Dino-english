import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/single_navigation_guard.dart';
import 'package:dino_english/game/sound/adventure_sfx.dart';
import 'package:dino_english/game/sound/adventure_sound_service.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/pet_adventure_providers.dart';
import 'package:dino_english/screens/pet_adventure_game_screen.dart';
import 'package:dino_english/screens/pet_selection_screen.dart';
import 'package:dino_english/widgets/glow_button.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never touches a real `Bgm`/`AudioPlayer` (platform-channel-backed) --
/// see `AdventureSoundService`'s doc comment on why it's an interface.
class _FakeAdventureSoundService implements AdventureSoundService {
  @override
  Future<void> preload() async {}

  @override
  void play(AdventureSfx sfx) {}

  @override
  void playMusic({double volume = 0.35}) {}

  @override
  Future<void> stopMusic() async {}
}

Future<AppDatabase> _seededDatabase() async {
  final database = AppDatabase(NativeDatabase.memory());
  await database
      .into(database.userProfile)
      .insertOnConflictUpdate(
        UserProfileCompanion.insert(id: const Value(1), createdAt: DateTime(2026)),
      );
  await database
      .into(database.words)
      .insert(
        WordsCompanion.insert(
          id: 'word.apple',
          englishTerm: 'apple',
          portugueseTranslation: 'maçã',
          category: 'food',
          difficulty: 1,
          recommendedLevel: 1,
          exampleSentenceEn: 'I eat an apple.',
          exampleSentencePt: 'Eu como uma maçã.',
        ),
      );
  return database;
}

void main() {
  setUp(SingleNavigationGuard.resetForTest);

  testWidgets(
    'a fast double-tap on COMEÇAR AVENTURA only pushes one game screen',
    (tester) async {
      // PetSelectionScreen shows a 3D pet preview (ModelViewer, backed by
      // a real WebView on mobile platforms) -- force a desktop platform so
      // it renders its lightweight fallback instead, same fix already
      // used in test/widget_test.dart.
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      // Flame.images defaults to prefix 'assets/images/'; only main()
      // resets it to '' to match this project's actual asset layout, and
      // main() never runs in a widget test.
      Flame.images.prefix = '';

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      final database = await _seededDatabase();
      addTearDown(database.close);

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(database),
              adventureSoundServiceProvider.overrideWithValue(
                _FakeAdventureSoundService(),
              ),
            ],
            child: const MaterialApp(home: PetSelectionScreen()),
          ),
        );
        await tester.pump();

        // Invoke the real onTap closure directly, twice back-to-back --
        // exercises SingleNavigationGuard deterministically through the
        // real production closure, independent of gesture/hit-test
        // timing nuances.
        final button = tester.widget<GlowButton>(
          find.widgetWithText(GlowButton, 'COMEÇAR AVENTURA'),
        );
        button.onTap();
        button.onTap();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // skipOffstage: false is required here -- a route covered by
        // another pushed route is still genuinely built and mounted (that
        // is exactly the bug this guard prevents), just wrapped in
        // Offstage by _ModalScopeState, which find.byType's default
        // skipOffstage:true would otherwise hide from this assertion,
        // silently making the test pass whether or not the guard exists.
        expect(
          find.byType(PetAdventureGameScreen, skipOffstage: false),
          findsOneWidget,
        );

        // Flush the guard's pending cooldown Timer so it doesn't trip
        // flutter_test's "no pending timers" check at the end of the
        // test.
        await tester.pump(const Duration(milliseconds: 600));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
