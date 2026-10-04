import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_route_observer.dart';
import 'core/orientation_lock.dart';
import 'providers/database_providers.dart';
import 'screens/app_shell_screen.dart';
import 'theme/neon_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(kAppPortraitOrientations);
  // Empty prefix so Pet Adventure's sprite paths (declared in full under
  // pubspec.yaml's assets) don't need a second "assets/images/" prefix.
  Flame.images.prefix = '';
  FlameAudio.updatePrefix('assets/sprites/map/Sounds/');
  runApp(const ProviderScope(child: DinoEnglishApp()));
}

class DinoEnglishApp extends StatelessWidget {
  const DinoEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dino English',
      theme: neonThemeData,
      navigatorObservers: [appRouteObserver],
      home: const _AppBootstrapGate(),
    );
  }
}

/// Waits for [appBootstrapProvider] (word seed + singleton rows) before
/// showing the Home screen, so every screen downstream can assume the
/// database is ready to read.
class _AppBootstrapGate extends ConsumerWidget {
  const _AppBootstrapGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);

    return bootstrap.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Erro ao iniciar o app: $error'))),
      data: (_) => const AppShellScreen(),
    );
  }
}
