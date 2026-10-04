import 'package:dino_english/widgets/companion/mixed_line_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the English word stands out and can be tapped', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MixedLineText(
            text: 'Eu vou WALK amanhã.',
            english: const ['WALK'],
            style: const TextStyle(fontSize: 16),
            onWord: (w) => tapped = w,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('word-walk')));
    expect(tapped, 'walk');
    final word = tester.widget<Text>(find.text('WALK'));
    expect(word.style!.color, MixedLineText.wordColor);
  });

  testWidgets('English that is not a taught word stays plain', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MixedLineText(
            text: 'Great job! Muito bem!',
            english: ['Great job!'],
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
    expect(find.text('Great job! Muito bem!'), findsOneWidget);
    expect(find.byKey(const ValueKey('word-great job!')), findsNothing);
  });
}
