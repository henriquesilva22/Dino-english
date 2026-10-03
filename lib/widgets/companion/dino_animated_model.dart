import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/companion/dino_model_clips.dart';
import '../pet_model_viewer.dart';

/// The companion's 3D Dino, animated by the engine: every change of
/// [plan] plays the matching `A_*`/`SK_*` clips of the model through
/// `dinoAnimatorJs` -- without reloading the model. Desktop (no WebView)
/// shows [PetModelViewer]'s static fallback.
class DinoAnimatedModel extends StatefulWidget {
  const DinoAnimatedModel({
    required this.modelAsset,
    required this.plan,
    this.height = 240,
    super.key,
  });

  final String modelAsset;
  final DinoClipPlan plan;
  final double height;

  static bool get isSupportedPlatform {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  State<DinoAnimatedModel> createState() => _DinoAnimatedModelState();
}

class _DinoAnimatedModelState extends State<DinoAnimatedModel> {
  WebViewController? _controller;

  @override
  void didUpdateWidget(DinoAnimatedModel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan != widget.plan) _send(widget.plan);
  }

  void _send(DinoClipPlan plan) {
    final controller = _controller;
    if (controller == null) return;
    // Before the page script exists, park the call where the script picks
    // it up on start.
    final call =
        "(window.dinoPlay || function (c, l, r) { window.__dinoPending = [c, l, r]; })"
        "('${plan.clip.clipName}', ${plan.loop}, '${plan.rest.clipName}')";
    controller.runJavaScript(call).catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    if (!DinoAnimatedModel.isSupportedPlatform) {
      return PetModelViewer(
        modelAsset: widget.modelAsset,
        label: 'Dino',
        height: widget.height,
      );
    }
    return SizedBox(
      height: widget.height,
      child: ModelViewer(
        key: ValueKey(widget.modelAsset),
        id: 'dino',
        src: widget.modelAsset,
        alt: 'Dino',
        backgroundColor: Colors.transparent,
        animationName: 'A_${DinoClip.idle.clipName}',
        autoPlay: true,
        cameraControls: true,
        disableZoom: true,
        relatedJs: dinoAnimatorJs,
        debugLogging: false,
        onWebViewCreated: (controller) {
          _controller = controller;
          _send(widget.plan);
        },
      ),
    );
  }
}
