import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../core/companion/food/food_item.dart';
import '../../theme/neon_colors.dart';

const double _kFoodSize = 56;
const double _kFeedbackSize = 64;

/// The food picked in the panel, waiting on screen: it bounces, shows its
/// name in English and Portuguese and follows the finger when dragged.
/// Dropping it anywhere but the [MouthDropZone] sends it back.
class DraggableFood extends StatefulWidget {
  const DraggableFood({
    required this.food,
    required this.showHint,
    this.onDragging,
    super.key,
  });

  final FoodItem food;

  /// "Arraste até a boca! 👆" (until the child has done it once).
  final bool showHint;

  /// true when picked up, false when released.
  final ValueChanged<bool>? onDragging;

  @override
  State<DraggableFood> createState() => _DraggableFoodState();
}

class _DraggableFoodState extends State<DraggableFood>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Widget _emoji(double size) => Text(
    widget.food.emoji,
    style: TextStyle(
      fontSize: size,
      shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showHint)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'Arraste até a boca! 👆',
              style: TextStyle(
                color: NeonColors.orange,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        Draggable<FoodItem>(
          data: food,
          feedback: Material(
            color: Colors.transparent,
            child: _emoji(_kFeedbackSize),
          ),
          childWhenDragging: Opacity(opacity: 0.2, child: _emoji(_kFoodSize)),
          onDragStarted: () {
            HapticFeedback.selectionClick();
            widget.onDragging?.call(true);
          },
          onDragEnd: (_) => widget.onDragging?.call(false),
          child: AnimatedBuilder(
            animation: _bounce,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -8 * _bounce.value),
              child: child,
            ),
            child: _emoji(_kFoodSize),
          ),
        ),
        Text(
          '${food.englishName} — ${food.name}',
          style: const TextStyle(
            color: NeonColors.textPrimary,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

/// The invisible target over the Dino's mouth. Food held over it makes
/// the Dino open wide ([onHover]); released over it, the food snaps into
/// the mouth (a quick flight that shrinks it away) and then
/// [onDelivered] fires. Make it generous: little fingers aren't precise.
class MouthDropZone extends StatefulWidget {
  const MouthDropZone({
    required this.onDelivered,
    required this.onHover,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<FoodItem> onDelivered;
  final ValueChanged<bool> onHover;
  final bool enabled;

  /// How long the food takes to fly into the mouth.
  static const Duration snapDuration = Duration(milliseconds: 280);

  @override
  State<MouthDropZone> createState() => _MouthDropZoneState();
}

class _MouthDropZoneState extends State<MouthDropZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snap;

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(
      vsync: this,
      duration: MouthDropZone.snapDuration,
    );
  }

  FoodItem? _flying;
  Offset _from = Offset.zero;
  bool _hovering = false;

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  void _hover(bool on) {
    if (_hovering == on) return;
    _hovering = on;
    widget.onHover(on);
  }

  Future<void> _accept(DragTargetDetails<FoodItem> details) async {
    HapticFeedback.mediumImpact();
    final box = context.findRenderObject() as RenderBox?;
    // details.offset is the feedback's top-left; fly from its centre.
    final centre =
        details.offset + const Offset(_kFeedbackSize / 2, _kFeedbackSize / 2);
    setState(() {
      _flying = details.data;
      _from = box?.globalToLocal(centre) ?? Offset.zero;
    });
    await _snap.forward(from: 0);
    if (!mounted) return;
    setState(() => _flying = null);
    _hover(false);
    widget.onDelivered(details.data);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<FoodItem>(
      onWillAcceptWithDetails: (_) => widget.enabled && _flying == null,
      onMove: (_) => _hover(true),
      onLeave: (_) => _hover(false),
      onAcceptWithDetails: _accept,
      builder: (context, candidates, _) => LayoutBuilder(
        builder: (context, constraints) {
          final mouth = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: SizedBox.expand()),
              if (_flying case final food?)
                AnimatedBuilder(
                  animation: _snap,
                  builder: (context, _) {
                    final t = Curves.easeIn.transform(_snap.value);
                    final at = Offset.lerp(_from, mouth, t)!;
                    const size = _kFeedbackSize;
                    return Positioned(
                      key: const ValueKey('flying-food'),
                      left: at.dx - size / 2,
                      top: at.dy - size / 2,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (1 - t * 0.7).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 1 - 0.8 * t,
                            child: Text(
                              food.emoji,
                              style: const TextStyle(fontSize: size),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
