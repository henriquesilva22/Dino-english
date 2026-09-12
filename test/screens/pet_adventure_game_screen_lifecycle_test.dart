import 'dart:async';

import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/game/sound/adventure_sfx.dart';
import 'package:dino_english/game/sound/adventure_sound_service.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/pet_adventure_providers.dart';
import 'package:dino_english/screens/pet_adventure_game_screen.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never touches a real `Bgm`/`AudioPlayer` (platform-channel-backed) --
/// tracks calls so this test can assert on them directly, mirroring
/// `_FakeSpeechService` in speech_button_test.dart. `preloadGate`, when
/// set, lets a test hold `preload()` open indefinitely to simulate
/// leaving mid-load -- `PetAdventureGame.onLoad()`'s `await`s are plain
/// Dart futures, not cancelled by widget disposal, so this reproduces the
/// exact race Causa Raiz 1 closes.
class _FakeAdventureSoundService implements AdventureSoundService {
  int stopMusicCallCount = 0;
  int playMusicCallCount = 0;
  Completer<void>? preloadGate;

  @override
  Future<void> preload() async {
    final gate = preloadGate;
    if (gate != null) await gate.future;
  }

  @override
  void play(AdventureSfx sfx) {}

  @override
  void playMusic({double volume = 0.35}) {
    playMusicCallCount++;
  }

  @override
  Future<void> stopMusic() async {
    stopMusicCallCount++;
  }
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

Widget _harness({
  required AppDatabase database,
  required AdventureSoundService sound,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      adventureSoundServiceProvider.overrideWithValue(sound),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PetAdventureGameScreen(isBossFight: false),
              ),
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
    'leaving the game screen via the system back gesture stops music and restores portrait orientation',
    (tester) async {
      // main() never runs in a widget test, so Flame.images keeps its
      // default prefix ('assets/images/') unless reset here to match
      // what main.dart actually sets at boot.
      Flame.images.prefix = '';

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
      final fakeSound = _FakeAdventureSoundService();

      await tester.pumpWidget(_harness(database: database, sound: fakeSound));

      await tester.tap(find.text('open'));
      // Getting from here to sound.playMusic() needs two different kinds
      // of progress: pump() for the widget tree to react to Riverpod
      // state (minigameWordPoolProvider resolving, _PetAdventurePlayArea
      // mounting), and real elapsed time for PetAdventureGame.onLoad()'s
      // real image decoding (confirmed empirically: testWidgets' fake
      // clock alone never drives that forward). Alternate both until the
      // music call lands.
      for (var i = 0; i < 50 && fakeSound.playMusicCallCount == 0; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }

      expect(
        fakeSound.playMusicCallCount,
        1,
        reason: 'the round should start its music exactly once',
      );

      // Simulates the actual Android system back gesture/button --
      // routes through PetAdventureGameScreen's PopScope, which is the
      // fix for Causa Raiz 3 (this exit path previously had no
      // pre-emptive pause/cleanup, unlike the HUD's ✕ button).
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        fakeSound.stopMusicCallCount,
        greaterThanOrEqualTo(1),
        reason: 'the system back path must stop music, not just the HUD button',
      );
      expect(
        orientationCalls,
        isNotEmpty,
        reason: 'portrait should be restored once the screen is popped',
      );
    },
  );

  testWidgets(
    'leaving mid-load never lets the abandoned onLoad() continuation start music or populate the world '
    '(Causa Raiz 1: onLoad()\'s awaits are not cancelled by disposal)',
    (tester) async {
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
      final fakeSound = _FakeAdventureSoundService()
        ..preloadGate = Completer<void>();

      await tester.pumpWidget(_harness(database: database, sound: fakeSound));
      await tester.tap(find.text('open'));
      // Enough pumps for minigameWordPoolProvider to resolve and
      // _PetAdventurePlayArea/PetAdventureGame.onLoad() to start -- but
      // onLoad() can't finish, since preload() is gated open.
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      expect(
        fakeSound.playMusicCallCount,
        0,
        reason: 'onLoad() should still be blocked on preload()',
      );

      // Leave now, while onLoad() is still suspended mid-await.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Only now let the abandoned preload() actually resolve.
      fakeSound.preloadGate!.complete();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(
        fakeSound.playMusicCallCount,
        0,
        reason:
            'onLoad()\'s continuation must observe phase == disposed and '
            'bail out before ever calling playMusic() on the shared, '
            'app-lifetime sound service',
      );
    },
  );
}
