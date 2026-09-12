import 'package:dino_english/main.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the Home screen with the ESTUDAR button', (
    WidgetTester tester,
  ) async {
    // The Dino showcase's ModelViewer needs a real WebView platform view,
    // which isn't mocked in a plain widget test. Force a desktop platform
    // so PetModelViewer renders its lightweight fallback instead. Must be
    // reset before this test body returns, or the framework's foundation
    // debug-variable invariant check fails.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(
              AppDatabase(NativeDatabase.memory()),
            ),
          ],
          child: const DinoEnglishApp(),
        ),
      );

      // Not pumpAndSettle(): the Dino showcase has an intentionally
      // infinite idle "breathing" animation (EggIdlePulse, reused), which
      // would make pumpAndSettle() spin forever waiting for animations to
      // stop.
      // A few bounded pumps are enough for the async providers to resolve.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('ESTUDAR'), findsWidgets);
      expect(find.byKey(const Key('nav.home')), findsOneWidget);
      expect(find.byKey(const Key('nav.estudar')), findsOneWidget);
      expect(find.byKey(const Key('nav.aventura')), findsOneWidget);
      expect(find.byKey(const Key('nav.perfil')), findsOneWidget);

      // Dispose the ProviderScope (and the in-memory database it owns)
      // while still inside this test's zone, then flush the zero-duration
      // timer Drift schedules when cancelling stream queries on close --
      // otherwise it fires after the test ends and fails the framework's
      // "no pending timers" invariant check.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
