import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Renders the real egg 3D asset. `model_viewer_plus` runs on Android, iOS
/// and web (it needs a WebView under the hood); there is no Windows/Linux
/// desktop implementation, so those platforms fall back to a simple static
/// placeholder instead of crashing during desktop development.
class EggModelViewer extends StatelessWidget {
  const EggModelViewer({super.key, this.height = 280});

  final double height;

  static bool get _isSupportedPlatform {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupportedPlatform) {
      return _UnsupportedPlatformFallback(height: height);
    }
    return SizedBox(
      height: height,
      child: const ModelViewer(
        src: 'assets/models/egg/Egg_Asset_v04.glb',
        alt: 'Ovo do Dino',
        backgroundColor: Colors.transparent,
        autoRotate: true,
        cameraControls: true,
        disableZoom: false,
      ),
    );
  }
}

class _UnsupportedPlatformFallback extends StatelessWidget {
  const _UnsupportedPlatformFallback({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.egg_outlined,
                size: height * 0.5,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Modelo 3D disponível no celular',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
