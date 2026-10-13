import 'package:flutter/material.dart';

/// The picture of the room behind the Dino (`assets/fundos/`). It fills
/// the stage keeping its proportions (cropped, never stretched), anchored
/// to the floor so the Dino always stands on it. Decoded at the screen's
/// size, not the file's, to keep memory low.
class SceneBackground extends StatelessWidget {
  const SceneBackground({required this.asset, super.key});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = (media.size.width * media.devicePixelRatio).round();
    return IgnorePointer(
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        cacheWidth: width > 0 ? width : null,
        gaplessPlayback: true,
        // A missing picture never breaks the screen.
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    );
  }
}

/// "z Z z" rising softly above the sleeping Dino (its eyes can't close:
/// the model has no eyelids).
class SleepingZs extends StatefulWidget {
  const SleepingZs({super.key});

  @override
  State<SleepingZs> createState() => _SleepingZsState();
}

class _SleepingZsState extends State<SleepingZs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 70,
        height: 80,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) => Stack(
            children: [
              for (var i = 0; i < 3; i++)
                Builder(
                  builder: (context) {
                    final t = (_loop.value + i / 3) % 1;
                    return Positioned(
                      left: 10 + i * 14 + t * 8,
                      bottom: t * 60,
                      child: Opacity(
                        opacity: (t < 0.2 ? t / 0.2 : 1 - t).clamp(0, 1),
                        child: Text(
                          i.isEven ? 'z' : 'Z',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14 + i * 5,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
