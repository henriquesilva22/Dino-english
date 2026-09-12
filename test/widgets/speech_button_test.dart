import 'dart:async';

import 'package:dino_english/core/speech/speech_service.dart';
import 'package:dino_english/providers/speech_providers.dart';
import 'package:dino_english/widgets/speech_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never touches a real TTS plugin -- lets each test control exactly when
/// `speak()` resolves, so the "speaking" UI state can be observed
/// mid-flight.
class _FakeSpeechService implements SpeechService {
  final List<String> spokenTexts = [];
  final ValueNotifier<Object?> _activeUtterance = ValueNotifier(null);
  Completer<SpeechResult>? _pending;

  @override
  ValueListenable<Object?> get activeUtterance => _activeUtterance;

  @override
  Future<SpeechResult> speak(String text) async {
    spokenTexts.add(text);
    final token = Object();
    _activeUtterance.value = token;
    _pending = Completer<SpeechResult>();
    final result = await _pending!.future;
    if (_activeUtterance.value == token) _activeUtterance.value = null;
    return result;
  }

  void completeSpeak(SpeechResult result) {
    _pending!.complete(result);
  }

  @override
  Future<void> stop() async {
    _activeUtterance.value = null;
  }
}

void main() {
  Widget wrap(_FakeSpeechService fake, {String text = 'apple'}) {
    return ProviderScope(
      overrides: [speechServiceProvider.overrideWithValue(fake)],
      child: MaterialApp(home: Scaffold(body: SpeechButton(text: text))),
    );
  }

  testWidgets('tapping speaks the given text', (tester) async {
    final fake = _FakeSpeechService();
    await tester.pumpWidget(wrap(fake, text: 'apple'));

    await tester.tap(find.byType(SpeechButton));
    await tester.pump();

    expect(fake.spokenTexts, ['apple']);
  });

  testWidgets('a repeat tap while speaking does not start a second utterance', (
    tester,
  ) async {
    final fake = _FakeSpeechService();
    await tester.pumpWidget(wrap(fake));

    await tester.tap(find.byType(SpeechButton));
    await tester.pump();
    await tester.tap(find.byType(SpeechButton));
    await tester.pump();

    expect(fake.spokenTexts, ['apple']);

    fake.completeSpeak(SpeechResult.spoken);
    await tester.pump();
  });

  testWidgets('shows a friendly message when there is no English voice', (
    tester,
  ) async {
    final fake = _FakeSpeechService();
    await tester.pumpWidget(wrap(fake));

    await tester.tap(find.byType(SpeechButton));
    await tester.pump();
    fake.completeSpeak(SpeechResult.noEnglishVoice);
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('Instale uma voz em inglês'),
      findsOneWidget,
    );
  });

  testWidgets('a successful speak leaves no error message and can be tapped again', (
    tester,
  ) async {
    final fake = _FakeSpeechService();
    await tester.pumpWidget(wrap(fake));

    await tester.tap(find.byType(SpeechButton));
    await tester.pump();
    fake.completeSpeak(SpeechResult.spoken);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Instale uma voz'), findsNothing);
    expect(find.textContaining('Não foi possível'), findsNothing);

    await tester.tap(find.byType(SpeechButton));
    await tester.pump();
    fake.completeSpeak(SpeechResult.spoken);
    await tester.pump();
    await tester.pump();

    expect(fake.spokenTexts, ['apple', 'apple']);
  });
}
