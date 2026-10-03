import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dino_english/core/companion/companion_response.dart';
import 'package:dino_english/core/companion/dino_model_clips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = DinoClipMapper();

  DinoClipPlan plan(
    CompanionAnimation animation, {
    CompanionAnimation rest = CompanionAnimation.idle,
    bool speaking = false,
  }) => mapper.plan(animation: animation, rest: rest, speaking: speaking);

  test('every clip exists in the bundled model (A_ and SK_)', () {
    final bytes = File(
      'assets/models/dino/Dino_Baby_v2_animado.glb',
    ).readAsBytesSync();
    final jsonLength = ByteData.sublistView(bytes).getUint32(12, Endian.little);
    final gltf =
        jsonDecode(utf8.decode(bytes.sublist(20, 20 + jsonLength)))
            as Map<String, dynamic>;
    final names = {
      for (final a in gltf['animations'] as List) (a as Map)['name'] as String,
    };
    for (final clip in DinoClip.values) {
      expect(names, contains('A_${clip.clipName}'));
      expect(names, contains('SK_${clip.clipName}'));
    }
  });

  test('every engine animation has a plan', () {
    for (final a in CompanionAnimation.values) {
      expect(() => plan(a), returnsNormally, reason: a.name);
    }
  });

  test('idle loops; the mouth moves while the voice speaks', () {
    expect(
      plan(CompanionAnimation.idle),
      const DinoClipPlan(DinoClip.idle, loop: true, rest: DinoClip.idle),
    );
    expect(
      plan(CompanionAnimation.talking, speaking: true),
      const DinoClipPlan(DinoClip.talk, loop: true, rest: DinoClip.talk),
    );
  });

  test('one-shot reactions return to the pose for the needs', () {
    expect(
      plan(CompanionAnimation.celebrating, rest: CompanionAnimation.hungry),
      const DinoClipPlan(DinoClip.celebrate, loop: false, rest: DinoClip.sad),
    );
    expect(
      plan(CompanionAnimation.eating, speaking: true),
      const DinoClipPlan(DinoClip.happy, loop: false, rest: DinoClip.talk),
    );
    expect(plan(CompanionAnimation.playing).clip, DinoClip.jump);
  });

  test('sleeping wins over talking; listening and thinking', () {
    expect(
      plan(CompanionAnimation.sleeping, speaking: true),
      const DinoClipPlan(DinoClip.sleep, loop: true, rest: DinoClip.sleep),
    );
    expect(plan(CompanionAnimation.listening).clip, DinoClip.surprised);
    expect(plan(CompanionAnimation.thinking).clip, DinoClip.confused);
    expect(plan(CompanionAnimation.hungry).clip, DinoClip.sad);
  });

  test('the injected script drives both the skeleton and the face', () {
    expect(dinoAnimatorJs, contains("'A_' + clip"));
    expect(dinoAnimatorJs, contains("'SK_' + clip"));
    expect(dinoAnimatorJs, contains('__dinoPending'));
    expect(dinoAnimatorJs, contains("'finished'"));
  });
}
