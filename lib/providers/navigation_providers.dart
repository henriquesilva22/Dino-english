import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which bottom-nav tab is currently selected: 0=Home, 1=Estudar,
/// 2=Aventura, 3=Perfil.
class SelectedTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final selectedTabIndexProvider =
    NotifierProvider<SelectedTabIndexNotifier, int>(
      SelectedTabIndexNotifier.new,
    );
