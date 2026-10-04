import 'package:flutter/material.dart';

/// The Dino's bedroom behind it when it's bedtime: a cosy wall, a window
/// with the moon, a wooden floor, a rug, a lamp and a plant (Kenney
/// Furniture Kit renders, CC0). Small on purpose: the Dino stays the
/// focus. [night] dims it (lamp glow stays).
class BedroomBackground extends StatelessWidget {
  const BedroomBackground({required this.night, super.key});

  final bool night;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final floorTop = c.maxHeight * 0.58;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _RoomPainter(floorTop)),
              ),
              Positioned(
                left: c.maxWidth * 0.2,
                top: floorTop + (c.maxHeight - floorTop) * 0.25,
                width: c.maxWidth * 0.45,
                child: Image.asset('assets/sprites/room/rug.png'),
              ),
              Positioned(
                left: 10,
                top: floorTop - 70,
                height: 110,
                child: Image.asset('assets/sprites/room/lamp.png'),
              ),
              Positioned(
                right: 10,
                top: floorTop - 60,
                height: 70,
                child: Image.asset('assets/sprites/room/plant.png'),
              ),
              // Warm lamp light.
              Positioned(
                left: -60,
                top: floorTop - 160,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD27A).withValues(alpha: 0.35),
                        const Color(0x00FFD27A),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: night ? 0.35 : 0,
                duration: const Duration(milliseconds: 800),
                child: Container(color: const Color(0xFF050818)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoomPainter extends CustomPainter {
  _RoomPainter(this.floorTop);

  final double floorTop;

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Rect.fromLTWH(0, 0, size.width, floorTop);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B2F6B), Color(0xFF3E3A7A)],
        ).createShader(wall),
    );
    final floor = Rect.fromLTWH(
      0,
      floorTop,
      size.width,
      size.height - floorTop,
    );
    canvas.drawRect(floor, Paint()..color = const Color(0xFF8A5A3C));
    final plank = Paint()
      ..color = const Color(0xFF6E4630)
      ..strokeWidth = 1.5;
    for (var y = floorTop + 18; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), plank);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop - 4, size.width, 6),
      Paint()..color = const Color(0xFF5A3A26),
    );

    // Window with the moon and stars.
    final window = Rect.fromCenter(
      center: Offset(size.width * 0.5, floorTop * 0.38),
      width: size.width * 0.3,
      height: floorTop * 0.45,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window.inflate(6), const Radius.circular(10)),
      Paint()..color = const Color(0xFFE9D8B8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(6)),
      Paint()..color = const Color(0xFF0E1640),
    );
    canvas.drawCircle(
      window.topRight + Offset(-window.width * 0.28, window.height * 0.3),
      window.shortestSide * 0.14,
      Paint()..color = const Color(0xFFFFF3C4),
    );
    final star = Paint()..color = Colors.white70;
    for (final f in const [
      (0.2, 0.25),
      (0.35, 0.65),
      (0.15, 0.8),
      (0.5, 0.4),
    ]) {
      canvas.drawCircle(
        window.topLeft + Offset(window.width * f.$1, window.height * f.$2),
        1.6,
        star,
      );
    }
    final frame = Paint()
      ..color = const Color(0xFFE9D8B8)
      ..strokeWidth = 4;
    canvas.drawLine(window.topCenter, window.bottomCenter, frame);
    canvas.drawLine(window.centerLeft, window.centerRight, frame);
  }

  @override
  bool shouldRepaint(_RoomPainter oldDelegate) =>
      oldDelegate.floorTop != floorTop;
}

/// The bed: tap it and the Dino goes to sleep there.
class TappableBed extends StatelessWidget {
  const TappableBed({required this.onTap, required this.hint, super.key});

  final VoidCallback onTap;

  /// "Toque na cama!" while waiting.
  final bool hint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('bed'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint)
            const Text(
              'Toque na cama! 🛏️',
              style: TextStyle(
                color: Color(0xFFFFB800),
                fontWeight: FontWeight.w900,
                fontSize: 15,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          Image.asset('assets/sprites/room/bed.png', width: 150),
        ],
      ),
    );
  }
}
