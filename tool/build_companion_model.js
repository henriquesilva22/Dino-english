// Builds the companion's model, assets/models/dino/dino_companion.glb, from
// the source GLBs in assets/glbs/ (Tripo mesh, Mixamo rig, Blender export,
// one clip per file). model-viewer plays clips of ONE file only, so this
// merges them:
//
//   dino run.glb                          -> walk   (a jog; root motion out)
//   Rundino correndo para versão jogo.glb -> run    (root motion out)
//   soco dino.glb                         -> attack (the punch)
//   dino comendoi.glb                     -> eating
//   dino dance.glb                        -> happy
//   dino pulo serve para o jogo.glb       -> jump   (Pet Adventure lanes)
//   (generated, from the eating clip's     -> idle, talk (breathing pose)
//    first pose)
//   ("dano ataque rodopiante" is not used yet.)
//
// The sources are Z-up in centimetres under a rotated, scaled "Armature"
// (the bind pose lies on its back; only the animations stand up). The
// output is normalised: Y-up metres, no transform on the Armature, the
// mesh standing in its bind pose, feet on y = 0, facing +z -- so
// model-viewer's framing and shadow see the real Dino. The material is made
// opaque (the export says BLEND, which sorts badly on a solid character).
//
// It prints the numbers the app needs (clip lengths, the speed the feet
// move at in walk/run, when the punch lands); CompanionModel.dino keeps
// them and test/core/companion/model/companion_model_test.dart checks the
// built file against it. Build-time only, no dependencies:
//
//   node tool/build_companion_model.js
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const src = (f) => path.join(root, 'assets', 'glbs', f);
const OUT = path.join(root, 'assets', 'models', 'dino', 'dino_companion.glb');
const FPS = 24;
const CM = 0.01;

// ---- GLB io -----------------------------------------------------------------

function loadGlb(file) {
  const b = fs.readFileSync(file);
  const jsonLen = b.readUInt32LE(12);
  const json = JSON.parse(b.subarray(20, 20 + jsonLen).toString('utf8'));
  const binLen = b.readUInt32LE(20 + jsonLen);
  const bin = b.subarray(28 + jsonLen, 28 + jsonLen + binLen);
  const comps = { SCALAR: 1, VEC2: 2, VEC3: 3, VEC4: 4, MAT4: 16 };
  const kinds = {
    5126: [4, (o) => bin.readFloatLE(o), 1],
    5121: [1, (o) => bin.readUInt8(o), 255],
    5123: [2, (o) => bin.readUInt16LE(o), 65535],
  };
  const read = (i) => {
    const acc = json.accessors[i];
    const [size, get, max] = kinds[acc.componentType];
    const n = comps[acc.type];
    const bv = json.bufferViews[acc.bufferView];
    const stride = bv.byteStride || n * size;
    const out = [];
    for (let k = 0; k < acc.count; k++) {
      const off = (bv.byteOffset || 0) + (acc.byteOffset || 0) + k * stride;
      const v = [];
      for (let c = 0; c < n; c++) {
        const x = get(off + c * size);
        v.push(acc.normalized ? x / max : x);
      }
      out.push(n === 1 ? v[0] : v);
    }
    return out;
  };
  return { json, bin, read };
}

// ---- math -------------------------------------------------------------------

const qmul = (a, b) => [
  a[3] * b[0] + a[0] * b[3] + a[1] * b[2] - a[2] * b[1],
  a[3] * b[1] - a[0] * b[2] + a[1] * b[3] + a[2] * b[0],
  a[3] * b[2] + a[0] * b[1] - a[1] * b[0] + a[2] * b[3],
  a[3] * b[3] - a[0] * b[0] - a[1] * b[1] - a[2] * b[2],
];
const qnorm = (q) => {
  const l = Math.hypot(...q);
  return q.map((x) => x / l);
};
const qdot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
const qconj = (q) => [-q[0], -q[1], -q[2], q[3]];
const qrot = (q, v) => {
  const p = qmul(qmul(q, [v[0], v[1], v[2], 0]), qconj(q));
  return [p[0], p[1], p[2]];
};
/** Rotation of [deg] degrees about a unit [axis]. */
const qaxis = (axis, deg) => {
  const h = (deg * Math.PI) / 360;
  return [axis[0] * Math.sin(h), axis[1] * Math.sin(h), axis[2] * Math.sin(h), Math.cos(h)];
};
const lerp = (a, b, t) => a.map((x, i) => x + (b[i] - x) * t);
const nlerp = (a, b, t) => {
  const s = qdot(a, b) < 0 ? -1 : 1;
  return qnorm(a.map((x, i) => x + (s * b[i] - x) * t));
};
const X = [1, 0, 0], Y = [0, 1, 0], Z = [0, 0, 1];
/** +90 deg about X: the sources' animation frame (up = -z, forward = +y)
 *  to Y-up (up = +y, forward = +z). */
const RX90 = qaxis(X, 90);
/** Z-up mesh space to Y-up: (x, y, z) -> (x, z, -y). */
const zUpToYUp = (v) => [v[0], v[2], -v[1]];

// ---- the normalised rig ---------------------------------------------------------

const HIPS = 'mixamorig:Hips';

/** The base model, normalised (see the header): new node defaults, mesh
 *  positions/normals rotated, inverse bind matrices recomputed. */
function normaliseBase(glb) {
  const json = JSON.parse(JSON.stringify(glb.json));
  for (const n of json.nodes) {
    if (n.name === 'Armature') {
      delete n.rotation;
      delete n.scale;
      delete n.translation;
    } else if (n.name.startsWith('mixamorig:') && n.translation) {
      n.translation = n.translation.map((x) => x * CM);
    }
  }
  // Opaque: no transparency sorting on the body.
  for (const m of json.materials) m.alphaMode = 'OPAQUE';
  const prim = json.meshes[0].primitives[0];
  const positions = glb.read(prim.attributes.POSITION).map(zUpToYUp);
  const normals = glb.read(prim.attributes.NORMAL).map(zUpToYUp);
  const fk = makeFk(json);
  const bind = bindClip(json);
  const solve = fk(bind, 0);
  const names = json.skins[0].joints.map((j) => json.nodes[j].name);
  // Inverse of each joint's (rigid) bind transform, column-major.
  const ibm = names.map((name) => {
    const { p, q } = solve(name);
    const c = qconj(q);
    const cols = [X, Y, Z].map((axis) => qrot(c, axis));
    const t = qrot(c, p).map((x) => -x);
    return [...cols[0], 0, ...cols[1], 0, ...cols[2], 0, ...t, 1];
  });
  return {
    json,
    bin: glb.bin,
    fk,
    names,
    positions,
    normals,
    joints: glb.read(prim.attributes.JOINTS_0),
    weights: glb.read(prim.attributes.WEIGHTS_0),
    ibm,
    replaced: {
      [prim.attributes.POSITION]: { rows: positions, type: 'VEC3', minMax: true },
      [prim.attributes.NORMAL]: { rows: normals, type: 'VEC3' },
      [json.skins[0].inverseBindMatrices]: { rows: ibm, type: 'MAT4' },
    },
  };
}

/** The bind pose as a one-frame clip. */
function bindClip(json) {
  const tracks = {};
  json.nodes.forEach((n) => {
    if (n.name.startsWith('mixamorig:')) {
      tracks[n.name] = { t: [n.translation || [0, 0, 0]], r: [n.rotation || [0, 0, 0, 1]] };
    }
  });
  return { duration: 0, frames: 1, tracks };
}

// ---- clips: {duration, frames, tracks: {joint: {t: [[x,y,z]], r: [[x,y,z,w]]}}} --
// Sampled at FPS, frame k at k / FPS, in the normalised rig.

function sampleChannel(times, values, interpolation, t, isQuat) {
  if (t <= times[0]) return values[0];
  const last = times.length - 1;
  if (t >= times[last]) return values[last];
  let i = 0;
  while (times[i + 1] < t) i++;
  if (interpolation === 'STEP') return values[i];
  const f = (t - times[i]) / (times[i + 1] - times[i]);
  return isQuat ? nlerp(values[i], values[i + 1], f) : lerp(values[i], values[i + 1], f);
}

/** The (only) clip of a source file, converted to the normalised rig. */
function extractClip(file) {
  const { json, read } = loadGlb(src(file));
  const anim = json.animations[0];
  let duration = 0;
  const channels = {};
  for (const ch of anim.channels) {
    const s = anim.samplers[ch.sampler];
    const times = read(s.input);
    duration = Math.max(duration, times[times.length - 1]);
    const node = json.nodes[ch.target.node].name;
    (channels[node] ??= {})[ch.target.path] = {
      times,
      values: read(s.output),
      interpolation: s.interpolation,
    };
  }
  const frames = Math.round(duration * FPS) + 1;
  const tracks = {};
  for (const [node, c] of Object.entries(channels)) {
    if (!node.startsWith('mixamorig:')) continue;
    const n = json.nodes.find((x) => x.name === node);
    const tr = { t: [], r: [] };
    for (let k = 0; k < frames; k++) {
      const time = k / FPS;
      const t = c.translation
        ? sampleChannel(c.translation.times, c.translation.values, c.translation.interpolation, time, false)
        : n.translation || [0, 0, 0];
      const r = c.rotation
        ? sampleChannel(c.rotation.times, c.rotation.values, c.rotation.interpolation, time, true)
        : n.rotation || [0, 0, 0, 1];
      if (node === HIPS) {
        // The root carries the Armature's old rotation and scale.
        tr.t.push(qrot(RX90, t).map((x) => x * CM));
        tr.r.push(qnorm(qmul(RX90, r)));
      } else {
        tr.t.push(t.map((x) => x * CM));
        tr.r.push(r);
      }
    }
    tracks[node] = tr;
  }
  return { duration: (frames - 1) / FPS, frames, tracks };
}

// ---- forward kinematics (positions in model space, metres) --------------------

function makeFk(json) {
  const parent = {};
  json.nodes.forEach((n, i) => (n.children || []).forEach((c) => (parent[json.nodes[c].name] = json.nodes[i].name)));
  const byName = Object.fromEntries(json.nodes.map((n) => [n.name, n]));
  return (clip, k) => {
    const world = {};
    const solve = (name) => {
      if (world[name]) return world[name];
      const tr = clip.tracks[name];
      const n = byName[name];
      const t = tr ? tr.t[k] : n.translation || [0, 0, 0];
      const r = tr ? tr.r[k] : n.rotation || [0, 0, 0, 1];
      const p = parent[name];
      if (!p || !p.startsWith('mixamorig:')) return (world[name] = { p: t, q: r });
      const pw = solve(p);
      const off = qrot(pw.q, t);
      return (world[name] = { p: pw.p.map((x, i) => x + off[i]), q: qmul(pw.q, r) });
    };
    return solve;
  };
}

/** Removes the forward drift of the hips (root motion) so the clip plays in
 *  place; the app moves the Dino at the returned speed instead. */
function inPlace(clip) {
  const t = clip.tracks[HIPS].t;
  const n = t.length - 1;
  const dx = t[n][0] - t[0][0], dz = t[n][2] - t[0][2];
  clip.tracks[HIPS].t = t.map((v, k) => [v[0] - (dx * k) / n, v[1], v[2] - (dz * k) / n]);
  return Math.hypot(dx, dz) / clip.duration;
}

/** Measures the real soles: the mesh's lowest vertices (bind pose), skinned
 *  like the renderer does. [groundClip] moves the hips so the lowest sole
 *  of the whole clip touches y = 0 -- never buried, never floating. */
function makeSoles(base) {
  const soles = [];
  base.positions.forEach((p, i) => {
    if (p[1] > 0.06) return;
    soles.push(base.joints[i].map((j, c) => {
      const m = base.ibm[j];
      const local = [0, 1, 2].map((r) => m[r] * p[0] + m[4 + r] * p[1] + m[8 + r] * p[2] + m[12 + r]);
      return { joint: base.names[j], w: base.weights[i][c], local };
    }).filter((x) => x.w > 0));
  });
  const lowest = (clip, k) => {
    const solve = base.fk(clip, k);
    let min = Infinity;
    for (const influences of soles) {
      let y = 0;
      for (const { joint, w, local } of influences) {
        const jw = solve(joint);
        y += w * (qrot(jw.q, local)[1] + jw.p[1]);
      }
      min = Math.min(min, y);
    }
    return min;
  };
  return {
    groundClip(clip) {
      let min = Infinity;
      for (let k = 0; k < clip.frames; k++) min = Math.min(min, lowest(clip, k));
      clip.tracks[HIPS].t = clip.tracks[HIPS].t.map((t) => [t[0], t[1] - min, t[2]]);
      return -min;
    },
    lowest,
  };
}

/** One frame of [clip] as a pose. */
function poseAt(clip, k) {
  const pose = {};
  for (const [n, tr] of Object.entries(clip.tracks)) pose[n] = { t: tr.t[k], r: tr.r[k] };
  return pose;
}

/** A looping clip around [pose]: [wobble](name, phase 0..1) returns extra
 *  local rotations in degrees as [[axis, deg], ...]. */
function proceduralClip(pose, seconds, wobble) {
  const frames = Math.round(seconds * FPS) + 1;
  const tracks = {};
  for (const n of Object.keys(pose)) tracks[n] = { t: [], r: [] };
  for (let k = 0; k < frames; k++) {
    const phase = (k / (frames - 1)) % 1;
    for (const [n, p] of Object.entries(pose)) {
      let r = p.r;
      for (const [axis, deg] of wobble(n, phase)) r = qmul(r, qaxis(axis, deg));
      tracks[n].t.push(p.t);
      tracks[n].r.push(qnorm(r));
    }
  }
  return { duration: (frames - 1) / FPS, frames, tracks };
}

const sin = (phase, cycles, shift = 0) => Math.sin(2 * Math.PI * (phase * cycles + shift));

/** Idle: slow breathing in the spine and shoulders, a gentle sway, the head
 *  looking around a little. Small on purpose -- alive, not busy. */
function idleWobble(name, ph) {
  const breath = sin(ph, 2); // 2 breaths per 6 s loop
  switch (name) {
    case 'mixamorig:Spine': return [[X, 1.0 * breath], [Z, 0.8 * sin(ph, 1)]];
    case 'mixamorig:Spine1': return [[X, 0.8 * breath]];
    case 'mixamorig:Spine2': return [[X, 0.8 * breath]];
    case 'mixamorig:LeftShoulder': return [[Z, 1.2 * breath]];
    case 'mixamorig:RightShoulder': return [[Z, -1.2 * breath]];
    case 'mixamorig:Neck': return [[Y, 4 * sin(ph, 1, 0.1)]];
    case 'mixamorig:Head': return [[X, 1.5 * sin(ph, 2, 0.3)], [Z, 1.5 * sin(ph, 1, 0.6)]];
    default: return [];
  }
}

/** Talking (no mouth in this model): idle plus small, quicker nods. */
function talkWobble(name, ph) {
  const base = idleWobble(name, ph);
  switch (name) {
    case 'mixamorig:Head': return [...base, [X, 3 * sin(ph, 4)], [Y, 2 * sin(ph, 2, 0.25)]];
    case 'mixamorig:Neck': return [...base, [X, 1.5 * sin(ph, 4, 0.15)]];
    case 'mixamorig:Spine2': return [...base, [Y, 1.5 * sin(ph, 2)]];
    default: return base;
  }
}

// ---- writer -----------------------------------------------------------------

function writeGlb(base, clips, file) {
  const { json: srcJson, bin: srcBin, replaced } = base;
  const json = JSON.parse(JSON.stringify(srcJson));
  delete json.animations;
  const chunks = [];
  let length = 0;
  const push = (buf) => {
    const pad = (4 - (length % 4)) % 4;
    if (pad) { chunks.push(Buffer.alloc(pad)); length += pad; }
    const offset = length;
    chunks.push(buf);
    length += buf.length;
    return offset;
  };
  const views = [];
  const accessors = [];
  const floatAccessor = (rows, type, minMax = true) => {
    const n = type === 'SCALAR' ? 1 : rows[0].length;
    const buf = Buffer.alloc(rows.length * n * 4);
    const min = Array(n).fill(Infinity), max = Array(n).fill(-Infinity);
    rows.forEach((row, k) => (n === 1 ? [row] : row).forEach((x, c) => {
      buf.writeFloatLE(x, (k * n + c) * 4);
      min[c] = Math.min(min[c], x);
      max[c] = Math.max(max[c], x);
    }));
    views.push({ buffer: 0, byteOffset: push(buf), byteLength: buf.length });
    const acc = { bufferView: views.length - 1, componentType: 5126, count: rows.length, type };
    if (minMax) Object.assign(acc, { min, max });
    accessors.push(acc);
    return accessors.length - 1;
  };

  // Keep what the mesh, skin and images use; rewrite the replaced data.
  const keepAcc = new Set();
  json.meshes.forEach((m) => m.primitives.forEach((p) => {
    Object.values(p.attributes).forEach((a) => keepAcc.add(a));
    if (p.indices !== undefined) keepAcc.add(p.indices);
  }));
  json.skins.forEach((s) => keepAcc.add(s.inverseBindMatrices));
  const bvMap = {};
  const copyView = (i) => {
    if (bvMap[i] !== undefined) return bvMap[i];
    const bv = srcJson.bufferViews[i];
    const off = push(srcBin.subarray(bv.byteOffset || 0, (bv.byteOffset || 0) + bv.byteLength));
    views.push({ ...bv, buffer: 0, byteOffset: off });
    return (bvMap[i] = views.length - 1);
  };
  (json.images || []).forEach((im) => (im.bufferView = copyView(im.bufferView)));
  const accMap = {};
  [...keepAcc].sort((a, b) => a - b).forEach((i) => {
    const r = replaced[i];
    if (r) {
      accMap[i] = floatAccessor(r.rows, r.type, !!r.minMax);
    } else {
      accessors.push({ ...srcJson.accessors[i], bufferView: copyView(srcJson.accessors[i].bufferView) });
      accMap[i] = accessors.length - 1;
    }
  });
  json.meshes.forEach((m) => m.primitives.forEach((p) => {
    for (const k of Object.keys(p.attributes)) p.attributes[k] = accMap[p.attributes[k]];
    if (p.indices !== undefined) p.indices = accMap[p.indices];
  }));
  json.skins.forEach((s) => (s.inverseBindMatrices = accMap[s.inverseBindMatrices]));

  const nodeIndex = (name) => json.nodes.findIndex((n) => n.name === name);
  json.animations = Object.entries(clips).map(([name, clip]) => {
    const input = floatAccessor([...Array(clip.frames)].map((_, k) => k / FPS), 'SCALAR');
    const samplers = [], channels = [];
    for (const [joint, tr] of Object.entries(clip.tracks)) {
      const node = nodeIndex(joint);
      if (node < 0) continue;
      // Only the hips move; every other bone keeps its length.
      if (joint === HIPS) {
        samplers.push({ input, output: floatAccessor(tr.t, 'VEC3', false), interpolation: 'LINEAR' });
        channels.push({ sampler: samplers.length - 1, target: { node, path: 'translation' } });
      }
      samplers.push({ input, output: floatAccessor(tr.r, 'VEC4', false), interpolation: 'LINEAR' });
      channels.push({ sampler: samplers.length - 1, target: { node, path: 'rotation' } });
    }
    return { name, samplers, channels };
  });
  json.accessors = accessors;
  json.bufferViews = views;
  const binary = Buffer.concat(chunks);
  const binPad = Buffer.concat([binary, Buffer.alloc((4 - (binary.length % 4)) % 4)]);
  json.buffers = [{ byteLength: binPad.length }];
  json.asset = { version: '2.0', generator: 'dino_english tool/build_companion_model.js' };
  let text = Buffer.from(JSON.stringify(json), 'utf8');
  text = Buffer.concat([text, Buffer.alloc((4 - (text.length % 4)) % 4, 0x20)]);
  const header = Buffer.alloc(12);
  header.writeUInt32LE(0x46546c67, 0);
  header.writeUInt32LE(2, 4);
  header.writeUInt32LE(12 + 8 + text.length + 8 + binPad.length, 8);
  const chunk = (type, data) => {
    const h = Buffer.alloc(8);
    h.writeUInt32LE(data.length, 0);
    h.writeUInt32LE(type, 4);
    return Buffer.concat([h, data]);
  };
  fs.writeFileSync(file, Buffer.concat([header, chunk(0x4e4f534a, text), chunk(0x004e4942, binPad)]));
}

// ---- build ------------------------------------------------------------------

if (require.main === module) {
  const base = normaliseBase(loadGlb(src('soco dino.glb')));
  const soles = makeSoles(base);

  const walk = extractClip('dino run.glb');
  const run = extractClip('Rundino correndo para versão jogo.glb');
  const attack = extractClip('soco dino.glb');
  const eating = extractClip('dino comendoi.glb');
  const happy = extractClip('dino dance.glb');
  const jump = extractClip('dino pulo serve para o jogo.glb');
  inPlace(jump);
  const walkSpeed = inPlace(walk);
  const runSpeed = inPlace(run);
  inPlace(happy);
  inPlace(eating);

  // Standing pose: where the eating clip starts (arms down, calm).
  const standing = { duration: 0, frames: 1, tracks: {} };
  for (const [n, p] of Object.entries(poseAt(eating, 0))) {
    standing.tracks[n] = { t: [p.t], r: [p.r] };
  }
  soles.groundClip(standing);
  const pose = poseAt(standing, 0);
  const idle = proceduralClip(pose, 6, idleWobble);
  const talk = proceduralClip(pose, 3, talkWobble);

  const lift = Object.fromEntries(Object.entries({ walk, run, attack, eating, happy, jump })
    .map(([n, c]) => [n, +soles.groundClip(c).toFixed(4)]));

  // The punch lands when the fist is furthest in front of the body (+z).
  const reach = [], fistY = [];
  for (let k = 0; k < attack.frames; k++) {
    const solve = base.fk(attack, k);
    const [l, r] = [solve('mixamorig:LeftHand').p, solve('mixamorig:RightHand').p];
    const fist = l[2] > r[2] ? l : r;
    reach.push(fist[2]);
    fistY.push(fist[1]);
  }
  const hit = reach.indexOf(Math.max(...reach));
  if (process.argv.includes('--analyze')) {
    console.log('punch reach per frame:', reach.map((x) => x.toFixed(2)).join(' '));
  }

  const clips = { idle, talk, walk, run, attack, eating, happy, jump };
  writeGlb(base, clips, OUT);

  const head = base.fk(standing, 0)('mixamorig:Head').p;
  const pos = base.positions;
  const ext = (i, f) => f(...pos.map((p) => p[i]));
  console.log(JSON.stringify({
    out: path.relative(root, OUT),
    bytes: fs.statSync(OUT).size,
    boundsMin: [0, 1, 2].map((i) => +ext(i, Math.min).toFixed(3)),
    boundsMax: [0, 1, 2].map((i) => +ext(i, Math.max).toFixed(3)),
    soleLift: lift,
    clips: Object.fromEntries(Object.entries(clips).map(([n, c]) => [n, +c.duration.toFixed(4)])),
    walkSpeed: +walkSpeed.toFixed(4),
    runSpeed: +runSpeed.toFixed(4),
    attackHitSeconds: +(hit / FPS).toFixed(4),
    attackReach: +reach[hit].toFixed(3),
    attackFistHeight: +fistY[hit].toFixed(3),
    idleSoles: +soles.lowest(standing, 0).toFixed(4),
    bindSoles: +soles.lowest(bindClip(base.json), 0).toFixed(4),
    idleHead: head.map((x) => +x.toFixed(3)),
  }, null, 2));
}

module.exports = { loadGlb, normaliseBase, extractClip, makeFk, makeSoles, bindClip };
