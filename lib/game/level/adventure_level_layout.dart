import 'package:flame/components.dart';

import '../background/scenery_background_component.dart';
import 'lane_movement_controller.dart';
import 'platform.dart';

/// The Pet Adventure level's three lanes: the path painted in the scenery
/// (ground) and two floating platforms above it (mid, high). Everything is
/// a fraction of the screen height -- the scenery is drawn to fill the
/// height -- so the pet always stands on the painted path, on any screen.
///
/// `mid`/`high` span almost the full width (wide shelves): the pet stays
/// near the left edge, and words on those lanes float in along them.
class AdventureLevelLayout {
  const AdventureLevelLayout({required this.platforms, required this.petX});

  final List<Platform> platforms;

  /// Where the pet stands (its left edge), in world units.
  final double petX;

  Platform get ground => platforms.firstWhere((p) => p.id == 'ground');
  Platform get mid => platforms.firstWhere((p) => p.id == 'mid');
  Platform get high => platforms.firstWhere((p) => p.id == 'high');

  Platform laneSurface(AdventureLane lane) => switch (lane) {
    AdventureLane.ground => ground,
    AdventureLane.mid => mid,
    AdventureLane.high => high,
  };

  /// Each lane's surface, ground first (for `LaneMovementController`).
  List<double> get laneTops => [ground.top, mid.top, high.top];

  /// Height of the platforms above the path, as fractions of the screen
  /// height (about 85 and 165 px on a phone in landscape).
  static const double midOffset = 0.22;
  static const double highOffset = 0.42;

  factory AdventureLevelLayout.standard(Vector2 screenSize) {
    final groundTop = screenSize.y * kSceneryPathTop;
    final left = screenSize.x * 0.08;
    final right = screenSize.x * 0.95;
    return AdventureLevelLayout(
      petX: screenSize.x * 0.16,
      platforms: [
        Platform(
          id: 'high',
          left: left,
          right: right,
          top: groundTop - screenSize.y * highOffset,
        ),
        Platform(
          id: 'mid',
          left: left,
          right: right,
          top: groundTop - screenSize.y * midOffset,
        ),
        Platform(id: 'ground', left: 0, right: screenSize.x, top: groundTop),
      ],
    );
  }
}
