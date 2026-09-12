import 'package:flutter/material.dart';

/// Gentle idle "breathing" motion for the egg showcase -- a subtle scale
/// pulse so the Home doesn't feel static, without needing a sprite.
class EggIdlePulse extends StatefulWidget {
  const EggIdlePulse({required this.child, super.key});

  final Widget child;

  @override
  State<EggIdlePulse> createState() => _EggIdlePulseState();
}

class _EggIdlePulseState extends State<EggIdlePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.97 + Curves.easeInOut.transform(_controller.value) * 0.06;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
