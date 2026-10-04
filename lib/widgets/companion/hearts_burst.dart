import 'dart:math';

import 'package:flutter/material.dart';

/// ❤️ ❤️ ❤️ floating up and fading around the Dino each time [token]
/// changes ("the Dino loved it"). Nothing stays on screen afterwards.
class HeartsBurst extends StatefulWidget {
  const HeartsBurst({required this.token, this.count = 8, super.key});

  final int token;
  final int count;

  static const Duration duration = Duration(milliseconds: 1800);

  @override
  State<HeartsBurst> createState() => _HeartsBurstState();
}

class _HeartsBurstState extends State<HeartsBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: HeartsBurst.duration,
  );

  /// Per heart: horizontal spread (-1..1), start delay (0..0.35), size.
  late List<(double, double, double)> _hearts = _shuffle(0);

  List<(double, double, double)> _shuffle(int seed) {
    final random = Random(seed);
    return [
      for (var i = 0; i < widget.count; i++)
        (
          random.nextDouble() * 2 - 1,
          random.nextDouble() * 0.35,
          18 + random.nextDouble() * 14,
        ),
    ];
  }

  @override
  void didUpdateWidget(HeartsBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token) {
      _hearts = _shuffle(widget.token);
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          if (!_anim.isAnimating) return const SizedBox.shrink();
          return SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final (spread, delay, size) in _hearts)
                  _heart(spread, delay, size),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _heart(double spread, double delay, double size) {
    final t = ((_anim.value - delay) / (1 - delay)).clamp(0.0, 1.0);
    final rise = Curves.easeOut.transform(t);
    return Positioned(
      left: 110 + spread * 80 + sin(t * pi * 2) * 8 - size / 2,
      top: 170 - rise * 170,
      child: Opacity(
        opacity: t == 0 ? 0 : (1 - t).clamp(0.0, 1.0),
        child: Text('❤️', style: TextStyle(fontSize: size)),
      ),
    );
  }
}
