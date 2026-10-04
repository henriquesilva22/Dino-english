import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dino_english/core/companion/interaction/companion_interaction_controller.dart';
import 'package:dino_english/core/companion/model/companion_model.dart';
import 'package:dino_english/widgets/companion/dino_animated_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The built GLB (tool/build_companion_model.js) against what the app
/// believes about it.
void main() {
  const model = CompanionModel.dino;
  final bytes = File(model.asset).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  final jsonLength = data.getUint32(12, Endian.little);
  final gltf =
      jsonDecode(utf8.decode(bytes.sublist(20, 20 + jsonLength)))
          as Map<String, dynamic>;
  final binStart = 20 + jsonLength + 8;

  List<List<double>> read(int accessor) {
    final acc = (gltf['accessors'] as List)[accessor] as Map;
    final n = {'SCALAR': 1, 'VEC3': 3, 'VEC4': 4}[acc['type']]!;
    final view = (gltf['bufferViews'] as List)[acc['bufferView']] as Map;
    final offset =
        binStart +
        (view['byteOffset'] as int? ?? 0) +
        (acc['byteOffset'] as int? ?? 0);
    return [
      for (var i = 0; i < (acc['count'] as int); i++)
        [
          for (var c = 0; c < n; c++)
            data.getFloat32(offset + (i * n + c) * 4, Endian.little),
        ],
    ];
  }

  Map<String, Map> animations() => {
    for (final a in gltf['animations'] as List) (a as Map)['name'] as String: a,
  };

  test('is bundled', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains(model.asset));
  });

  test('every clip exists with the length the app expects', () {
    final anims = animations();
    for (final clip in model.clips.values) {
      final anim = anims[clip.name];
      expect(anim, isNotNull, reason: clip.name);
      final input = ((anim!['samplers'] as List).first as Map)['input'] as int;
      final times = read(input);
      expect(times.last.first, closeTo(clip.seconds, 0.01), reason: clip.name);
    }
  });

  test('walk and run play in place (the app moves the Dino)', () {
    final nodes = gltf['nodes'] as List;
    final hips = nodes.indexWhere(
      (n) => (n as Map)['name'] == 'mixamorig:Hips',
    );
    final anims = animations();
    for (final name in ['walk', 'run']) {
      final anim = anims[name]!;
      final channel = (anim['channels'] as List).cast<Map>().firstWhere(
        (c) =>
            (c['target'] as Map)['node'] == hips &&
            (c['target'] as Map)['path'] == 'translation',
      );
      final sampler = (anim['samplers'] as List)[channel['sampler']] as Map;
      final t = read(sampler['output'] as int);
      expect(t.last[0], closeTo(t.first[0], 0.002), reason: name);
      expect(t.last[2], closeTo(t.first[2], 0.002), reason: name);
    }
  });

  test('size, pivot on the floor, no mouth blend shapes', () {
    final prim =
        (((gltf['meshes'] as List).first as Map)['primitives'] as List).first
            as Map;
    final pos =
        (gltf['accessors'] as List)[(prim['attributes'] as Map)['POSITION']]
            as Map;
    expect((pos['min'] as List)[1], closeTo(0, 0.001)); // feet on y = 0
    expect((pos['max'] as List)[1], closeTo(model.height, 0.01));
    expect((pos['max'] as List)[0], closeTo(model.halfWidth, 0.01));
    expect(prim['targets'], isNull);
    expect(model.mouthShapes, isNull);
  });

  test('the camera frames the whole Dino, feet low in the view', () {
    final camera = model.camera;
    expect(camera.feetFraction, inInclusiveRange(0.7, 0.92));
    final head = camera.project(ModelPoint(0, model.height, 0));
    expect(head.y, greaterThan(0.05));
    expect(camera.viewWidthAtFeet, greaterThan(model.halfWidth * 2));
  });

  test('the mouth drop zone sits on the head, inside the view', () {
    final zone = const CompanionInteractionController(model: model).mouthZone();
    expect(zone.alignment.y, inInclusiveRange(-0.9, 0));
    expect(zone.alignment.x, closeTo(0, 0.01));
    expect(zone.widthFactor, inInclusiveRange(0.3, 0.8));
  });

  test('walking to bed turns towards it; asleep faces the child', () {
    const interaction = CompanionInteractionController(model: model);
    final walking = interaction.placement(walkingToBed: true, sleeping: false);
    expect(walking.yaw, greaterThan(0));
    expect(walking.alignment, interaction.bed.alignment);
    final asleep = interaction.placement(walkingToBed: false, sleeping: true);
    expect(asleep.yaw, 0);
    final away = interaction.placement(walkingToBed: false, sleeping: false);
    expect(away.scale, 1);
  });

  test('the page script drives clips, speed, facing and the camera', () {
    final js = companionAnimatorJs(model);
    for (final fn in [
      'dinoPlay',
      'dinoFace',
      'dinoPlaying',
      'dinoTalk',
      'dinoMouth',
      'dinoChew',
      'dinoGape',
      'dinoLook',
      'dinoDebug',
    ]) {
      expect(js, contains('window.$fn'));
    }
    expect(js, contains('__dinoPending'));
    expect(js, contains('animationCrossfadeDuration'));
    expect(js, contains('timeScale'));
    expect(js, contains(model.camera.orbit));
  });
}
