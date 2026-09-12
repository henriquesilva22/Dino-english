import 'package:flutter/services.dart';

/// The app's default orientation, set once at boot in `main.dart`.
const List<DeviceOrientation> kAppPortraitOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
];

/// Orientation the Pet Adventure minigame locks into while active --
/// restored back to [kAppPortraitOrientations] when its screen disposes.
const List<DeviceOrientation> kGameLandscapeOrientations = [
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];
