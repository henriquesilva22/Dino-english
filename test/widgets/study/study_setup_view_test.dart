import 'package:dino_english/providers/immersion_mode_providers.dart';
import 'package:dino_english/widgets/study/study_setup_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('toggling the switch updates immersionModeEnabledProvider', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: StudySetupView())),
      ),
    );

    expect(container.read(immersionModeEnabledProvider), isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(container.read(immersionModeEnabledProvider), isTrue);
  });

  testWidgets('tapping COMEÇAR starts the session', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: StudySetupView())),
      ),
    );

    expect(container.read(studySessionStartedProvider), isFalse);

    await tester.tap(find.text('COMEÇAR'));
    await tester.pump();

    expect(container.read(studySessionStartedProvider), isTrue);
  });
}
