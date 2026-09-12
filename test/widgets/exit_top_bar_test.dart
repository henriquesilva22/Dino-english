import 'package:dino_english/widgets/exit_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the title and calls onExit when tapped', (tester) async {
    var exited = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExitTopBar(title: 'Montar Frase', onExit: () => exited = true),
        ),
      ),
    );

    expect(find.text('Montar Frase'), findsOneWidget);
    expect(exited, isFalse);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(exited, isTrue);
  });
}
