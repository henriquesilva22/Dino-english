import 'package:flame/components.dart';

import '../ground_component.dart';
import 'platform.dart';

/// The Pet Adventure level's standing surfaces: the main ground plus two
/// elevated platforms. `mid`/`high` deliberately span almost the full
/// width (wide "shelves", not narrow islands) since the pet never moves
/// horizontally -- it stays fixed near the left edge, so any platform it
/// should ever be able to land on must cover that column.
class AdventureLevelLayout {
  const AdventureLevelLayout({required this.platforms});

  final List<Platform> platforms;

  Platform get ground => platforms.firstWhere((p) => p.id == 'ground');

  /// Vertical gap between the mid/high platforms and the ground, in world
  /// units. Kept alongside the layout (not buried in the factory) since
  /// [WordSpawner] and `DifficultyConfig.standard`'s jump apex are both
  /// calibrated against these exact numbers.
  static const double midOffset = 85;
  static const double highOffset = 165;

  factory AdventureLevelLayout.standard(Vector2 screenSize) {
    final groundTop = screenSize.y - kGroundHeight;
    final left = screenSize.x * 0.08;
    final right = screenSize.x * 0.95;
    return AdventureLevelLayout(
      platforms: [
        Platform(
          id: 'high',
          left: left,
          right: right,
          top: groundTop - highOffset,
        ),
        Platform(
          id: 'mid',
          left: left,
          right: right,
          top: groundTop - midOffset,
        ),
        Platform(id: 'ground', left: 0, right: screenSize.x, top: groundTop),
      ],
    );
  }
}
