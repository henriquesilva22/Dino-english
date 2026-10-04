import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which bottom-nav tab is currently selected: 0=Home, 1=Estudar,
/// 2=Aventura, 3=Perfil.
///
/// Tabs aren't routes (they live in one `IndexedStack`), so the system
/// back would otherwise pop the app's root route and leave the app from
/// any tab. This keeps the tabs visited since Home: [back] returns to the
/// previous one, and from any tab you end up at Home before leaving.
class SelectedTabIndexNotifier extends Notifier<int> {
  final List<int> _history = [];

  @override
  int build() => 0;

  void select(int index) {
    if (index == state) return;
    if (index == 0) {
      // Home is the root: nothing to go back to from there.
      _history.clear();
    } else {
      _history.remove(index);
      _history.add(state);
    }
    state = index;
  }

  /// Whether [back] has somewhere to go (anything but Home with an empty
  /// history).
  bool get canGoBack => state != 0;

  /// One tab back (or Home). Returns false at Home: the app may close.
  bool back() {
    if (state == 0) return false;
    state = _history.isNotEmpty ? _history.removeLast() : 0;
    return true;
  }
}

final selectedTabIndexProvider =
    NotifierProvider<SelectedTabIndexNotifier, int>(
      SelectedTabIndexNotifier.new,
    );
