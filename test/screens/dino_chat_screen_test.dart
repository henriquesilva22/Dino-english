import 'package:dino_english/core/companion/voice/speech_recognition_service.dart';
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
  Future<SpeechResult> speak(String text) async => SpeechResult.spoken;

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

    expect(find.text('Comer'), findsOneWidget);
    expect(find.text('Água'), findsOneWidget);
    expect(find.text('Brincar'), findsOneWidget);
    expect(find.text('Dormir'), findsOneWidget);
    expect(find.text('🍎 60'), findsOneWidget);

    await tester.tap(find.text('Comer'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.text('🍎 80'), findsOneWidget);

    await tester.tap(find.text('Dormir'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.text('Acordar'), findsOneWidget);

    // Leave the screen so the controller's timers are cancelled.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(database.close);
    debugDefaultTargetPlatformOverride = null;
    await tester.binding.setSurfaceSize(null);
  });
}
