// Makes a plain Piper voice (model.onnx + config.json, e.g. Razo) loadable
// by sherpa-onnx: writes the metadata sherpa-onnx reads (sample rate,
// espeak voice...) into the model and a tokens.txt from the phoneme map.
// Build-time only (the app never touches the network).
//
//   cd tool && npm i protobufjs@7
//   node tool/prepare_piper_voice.js model.onnx config.json onnx.proto outDir
//
// onnx.proto: https://raw.githubusercontent.com/onnx/onnx/main/onnx/onnx.proto
const fs = require('fs');
const path = require('path');
const protobuf = require('protobufjs');

const [modelPath, configPath, protoPath, outDir] = process.argv.slice(2);
if (!outDir) {
  console.error('usage: prepare_piper_voice.js model.onnx config.json onnx.proto outDir');
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const ModelProto = protobuf.loadSync(protoPath).lookupType('onnx.ModelProto');
const model = ModelProto.decode(fs.readFileSync(modelPath));

const meta = {
  model_type: 'vits',
  comment: 'piper',
  language: 'Portuguese',
  voice: config.espeak.voice,
  version: '1',
  has_espeak: '1',
  n_speakers: String(config.num_speakers || 1),
  sample_rate: String(config.audio.sample_rate),
};
model.metadataProps = (model.metadataProps || []).filter((p) => !(p.key in meta));
for (const [key, value] of Object.entries(meta)) {
  model.metadataProps.push({ key, value });
}

fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'model.onnx'), ModelProto.encode(model).finish());
const tokens = Object.entries(config.phoneme_id_map)
  .map(([symbol, ids]) => `${symbol} ${ids[0]}`)
  .join('\n');
fs.writeFileSync(path.join(outDir, 'tokens.txt'), tokens + '\n');
console.log('ok', outDir);
