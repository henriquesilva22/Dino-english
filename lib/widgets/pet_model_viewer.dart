import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Renders a pet's real 3D asset, same pattern as `EggModelViewer`:
/// `model_viewer_plus` runs on Android/iOS/web only, so unsupported
/// desktop platforms fall back to a simple static placeholder.
class PetModelViewer extends StatelessWidget {
  const PetModelViewer({
    required this.modelAsset,
    required this.label,
    this.height = 220,
    this.animationName,
    super.key,
  });

  final String modelAsset;
  final String label;
  final double height;

  /// A clip to loop (e.g. the companion's idle), or null for none.
  final String? animationName;

  static bool get _isSupportedPlatform {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupportedPlatform) {
      return _UnsupportedPlatformFallback(height: height, label: label);
    }
    return SizedBox(
      height: height,
      child: ModelViewer(
        key: ValueKey(modelAsset),
        src: modelAsset,
        alt: label,
        backgroundColor: Colors.transparent,
        autoRotate: true,
        animationName: animationName,
        autoPlay: animationName != null ? true : null,
        cameraControls: true,
        disableZoom: false,
      ),
    );
  }
}

class _UnsupportedPlatformFallback extends StatelessWidget {
  const _UnsupportedPlatformFallback({
    required this.height,
    required this.label,
  });

  final double height;
  final String label;

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
                Icons.pets,
                size: height * 0.5,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                '$label — modelo 3D disponível no celular',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
