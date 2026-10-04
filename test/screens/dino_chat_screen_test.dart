import 'package:dino_english/core/companion/voice/speech_recognition_service.dart';
import 'package:dino_english/core/companion/voice/portuguese_voice.dart';
import 'package:dino_english/core/database/app_bootstrap.dart';
import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/database/seed/word_seed_loader.dart';
import 'package:dino_english/core/speech/speech_service.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/dino_chat_providers.dart';
import 'package:dino_english/providers/speech_providers.dart';
import 'package:dino_english/screens/dino_chat_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SilentSpeech implements SpeechService {
  @override
  Future<SpeechResult> speak(
    String text, {
    String locale = kEnglishLocale,
    double? rate,
    double? pitch,
  }) async => SpeechResult.spoken;

  @override
  Future<void> stop() async {}

  @override
  ValueListenable<Object?> get activeUtterance => ValueNotifier(null);
}

void main() {
  testWidgets('the companion screen shows needs, bubble and care buttons', (
    tester,
  ) async {
    // Desktop platform: the 3D viewer shows its static fallback (no
    // WebView in widget tests).
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester.binding.setSurfaceSize(const Size(390, 780));

    final database = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      await WordSeedLoader(database).seedIfNeeded();
      await AppBootstrapper(database).ensureSingletonRows();
    });
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        speechServiceProvider.overrideWithValue(_SilentSpeech()),
        portugueseVoiceProvider.overrideWithValue(
          SystemPortugueseVoice(_SilentSpeech()),
        ),
        speechRecognitionServiceProvider.overrideWithValue(
          const UnavailableSpeechRecognitionService(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DinoChatScreen()),
      ),
    );
    for (var i = 0; i < 50 && !container.read(dinoChatProvider).isReady; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> dragBreadTo(Offset target) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('🍞')),
      );
      final from = tester.getCenter(find.text('🍞'));
      for (var i = 1; i <= 10; i++) {
        await gesture.moveTo(Offset.lerp(from, target, i / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('Comer'), findsOneWidget);
    expect(find.text('Água'), findsOneWidget);
    expect(find.text('Brincar'), findsOneWidget);
    expect(find.text('Dormir'), findsOneWidget);
    expect(find.text('🍎 60'), findsOneWidget);

    // "Comer" opens the food panel: bread and apple are free, the rest
    // costs 🪙 coins.
    await tester.tap(find.text('Comer'));
    await settle();
    expect(find.text('🍽️ Comidas'), findsOneWidget);
    expect(find.text('🪙 30 moedas'), findsOneWidget);
    expect(find.text('🪙 100'), findsOneWidget); // pizza, locked
    await tester.tap(find.byKey(const ValueKey('food-bread')));
    await settle();

    // The bread waits on the stage with its name and the drag hint.
    expect(find.text('🍽️ Comidas'), findsNothing);
    expect(find.text('Bread — Pão'), findsOneWidget);
    expect(find.text('Arraste até a boca! 👆'), findsOneWidget);
    expect(find.text('🍎 60'), findsOneWidget);

    // Dropped away from the mouth: it goes back, nothing is eaten.
    await dragBreadTo(const Offset(20, 140));
    expect(find.text('Bread — Pão'), findsOneWidget);
    expect(find.text('🍎 60'), findsOneWidget);

    // Dropped on the mouth: it snaps in, the Dino chews, loves it (❤️)
    // and the meters move by the bread's numbers (+10 🍎, +5 ❤️).
    await dragBreadTo(
      tester.getCenter(find.byKey(const ValueKey('mouth-drop-zone'))),
    );
    for (var i = 0; i < 60 && find.text('🍎 70').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('🍎 70'), findsOneWidget);
    expect(find.text('Bread — Pão'), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('❤️'), findsWidgets);
    expect(container.read(dinoChatProvider).xpEarned, greaterThan(0));
    // The hearts float away and are gone.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('❤️'), findsNothing);
    // Feeding never pays coins.
    final profile = await tester.runAsync(
      () => database.select(database.userProfile).getSingle(),
    );
    expect(profile!.coins, 30);

    // "Dormir": the bedroom appears; tapping the bed sends the Dino there
    // to sleep.
    await tester.tap(find.text('Dormir'));
    await settle();
    expect(find.text('Toque na cama! 🛏️'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bed')));
    for (var i = 0; i < 60 && find.text('Acordar').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Acordar'), findsOneWidget);

    // Leave the screen so the controller's timers are cancelled.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(database.close);
    debugDefaultTargetPlatformOverride = null;
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('back from the ball game goes to the Dino, then to the screen '
      'before it -- never further', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester.binding.setSurfaceSize(const Size(390, 780));

    final database = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      await WordSeedLoader(database).seedIfNeeded();
      await AppBootstrapper(database).ensureSingletonRows();
    });
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        speechServiceProvider.overrideWithValue(_SilentSpeech()),
        portugueseVoiceProvider.overrideWithValue(
          SystemPortugueseVoice(_SilentSpeech()),
        ),
        speechRecognitionServiceProvider.overrideWithValue(
          const UnavailableSpeechRecognitionService(),
        ),
      ],
    );
    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // A screen before the Dino (the Home / Aprender of the real app).
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DinoChatScreen(),
                  ),
                ),
                child: const Text('Abrir o Dino'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir o Dino'));
    // Let the route build the screen (it owns the controller).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 50 && !container.read(dinoChatProvider).isReady; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await settle();

    // Brincar -> the ball game.
    await tester.tap(find.text('Brincar'));
    await settle();
    expect(find.byKey(const ValueKey('ball-arena')), findsOneWidget);

    // Android back: Bola -> the Dino (still on its screen).
    await tester.binding.handlePopRoute();
    await settle();
    expect(find.byKey(const ValueKey('ball-arena')), findsNothing);
    expect(find.byType(DinoChatScreen), findsOneWidget);

    // Bola again, then ✕: same as back.
    await tester.tap(find.text('Brincar'));
    await settle();
    expect(find.byKey(const ValueKey('ball-arena')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle();
    expect(find.byKey(const ValueKey('ball-arena')), findsNothing);
    expect(find.byType(DinoChatScreen), findsOneWidget);

    // Back again: the screen before the Dino, not further.
    await tester.binding.handlePopRoute();
    await settle();
    expect(find.byType(DinoChatScreen), findsNothing);
    expect(find.text('Abrir o Dino'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(database.close);
    debugDefaultTargetPlatformOverride = null;
    await tester.binding.setSurfaceSize(null);
  });
}
