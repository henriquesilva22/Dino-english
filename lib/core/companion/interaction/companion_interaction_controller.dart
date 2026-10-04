import 'dart:math' as math;

import 'package:flutter/painting.dart' show Alignment;

import '../model/companion_model.dart';

/// Where the companion stands on the stage outside the ball game, and the
/// way it faces.
class CompanionPlacement {
  const CompanionPlacement({
    required this.alignment,
    required this.scale,
    required this.yaw,
  });

  final Alignment alignment;
  final double scale;

  /// Degrees, 0 = facing the child.
  final double yaw;
}

/// The mouth's drop zone inside the companion's square 3D view.
class MouthZone {
  const MouthZone({
    required this.alignment,
    required this.widthFactor,
    required this.heightFactor,
  });

  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
}

/// The companion's interaction points with the world, from its model: the
/// mouth (food goes there) and the bed (it walks there to sleep). Screens
/// ask here instead of hard-coding positions, so another model only needs
/// another [CompanionModel].
class CompanionInteractionController {
  const CompanionInteractionController({
    required this.model,
    this.bed = const CompanionBedTarget(alignment: Alignment(0.62, 0.55)),
  });

  final CompanionModel model;
  final CompanionBedTarget bed;

  /// The mouth's drop zone in the view (relative, any screen size).
  /// Generous on purpose: little fingers aren't precise.
  MouthZone mouthZone() {
    final camera = model.camera;
    final p = camera.project(model.mouth.point);
    final r = model.mouth.radius / camera.viewWidthAtFeet;
    return MouthZone(
      alignment: Alignment(p.x * 2 - 1, p.y * 2 - 1),
      widthFactor: math.max(0.4, r * 2 * 1.6),
      heightFactor: math.max(0.35, r * 2 * 1.4),
    );
  }

  /// Bedtime: walking to the bed (facing it), then lying there (facing
  /// the child: no sleeping clip yet, so it stands quietly). Otherwise in
  /// the middle, facing the child.
  CompanionPlacement placement({
    required bool walkingToBed,
    required bool sleeping,
    bool inBedroom = true,
  }) {
    final atBed = inBedroom && (walkingToBed || sleeping);
    if (!atBed) {
      return const CompanionPlacement(
        alignment: Alignment.center,
        scale: 1,
        yaw: 0,
      );
    }
    return CompanionPlacement(
      alignment: bed.alignment,
      scale: bed.scale,
      yaw: walkingToBed && !sleeping ? bed.approachYaw : 0,
    );
  }
}
