import 'package:dino_english/providers/navigation_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late SelectedTabIndexNotifier tabs;

  setUp(() {
    container = ProviderContainer();
    tabs = container.read(selectedTabIndexProvider.notifier);
  });
  tearDown(() => container.dispose());

  int tab() => container.read(selectedTabIndexProvider);

  test('back on Home has nowhere to go (the app may close)', () {
    expect(tab(), 0);
    expect(tabs.canGoBack, isFalse);
    expect(tabs.back(), isFalse);
  });

  test('back walks the visited tabs in reverse, then Home', () {
    tabs.select(1); // Estudar
    tabs.select(2); // Aventura
    tabs.select(3); // Perfil
    expect(tabs.back(), isTrue);
    expect(tab(), 2);
    expect(tabs.back(), isTrue);
    expect(tab(), 1);
    expect(tabs.back(), isTrue);
    expect(tab(), 0);
    expect(tabs.back(), isFalse);
  });

  test('a tab visited twice is only one step back', () {
    tabs.select(1);
    tabs.select(2);
    tabs.select(1);
    expect(tabs.back(), isTrue);
    expect(tab(), 2);
    expect(tabs.back(), isTrue);
    expect(tab(), 0);
  });

  test('choosing Home clears the way back', () {
    tabs.select(2);
    tabs.select(0);
    expect(tabs.canGoBack, isFalse);
    tabs.select(3);
    expect(tabs.back(), isTrue);
    expect(tab(), 0);
  });
}
