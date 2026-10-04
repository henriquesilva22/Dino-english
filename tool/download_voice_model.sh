#!/usr/bin/env bash
# Downloads the offline speech models: Whisper tiny (int8, sherpa-onnx
# export, ~104 MB) for speech-to-text and Silero VAD (~0.6 MB) to detect
# when the child starts/stops talking into assets/models/voice/. Run once per
# checkout before `flutter build`; the files are bundled into the app, so
# the child's device never needs internet. They are gitignored (too big
# for git). Without them the app still works -- the mic button is hidden.
set -euo pipefail

dir="$(cd "$(dirname "$0")/.." && pwd)/assets/models/voice"
base="https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/main"
mkdir -p "$dir"

vad_url="https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx"

for file in tiny-encoder.int8.onnx tiny-decoder.int8.onnx tiny-tokens.txt silero_vad.onnx; do
  if [ -s "$dir/$file" ]; then
    echo "ok       $file"
    continue
  fi
  echo "baixando $file..."
  url="$base/$file"
  [ "$file" = silero_vad.onnx ] && url="$vad_url"
  curl -fL --retry 3 -o "$dir/$file.part" "$url"
  mv "$dir/$file.part" "$dir/$file"
done
echo "Modelo de voz pronto em $dir"

# Portuguese voice (Piper/VITS, offline TTS) into assets/models/voice_pt/.
# PT_VOICE=faber (default, CC0, ~18 MB int8) or PT_VOICE=razo (MIT,
# ~63 MB). Build the app with --dart-define=PT_VOICE=<same> to use it.
# The espeak-ng phoneme data for Portuguese is already in the repo.
pt_voice="${PT_VOICE:-faber}"
pt_dir="$(cd "$(dirname "$0")/.." && pwd)/assets/models/voice_pt/$pt_voice"
mkdir -p "$pt_dir"
if [ -s "$pt_dir/model.onnx" ] && [ -s "$pt_dir/tokens.txt" ]; then
  echo "ok       voz $pt_voice"
elif [ "$pt_voice" = faber ]; then
  tmp="$(mktemp -d)"
  curl -fL --retry 3 -o "$tmp/faber.tar.bz2" \
    "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-pt_BR-faber-medium-int8.tar.bz2"
  tar xjf "$tmp/faber.tar.bz2" -C "$tmp"
  cp "$tmp/vits-piper-pt_BR-faber-medium-int8/pt_BR-faber-medium.onnx" "$pt_dir/model.onnx"
  cp "$tmp/vits-piper-pt_BR-faber-medium-int8/tokens.txt" "$pt_dir/tokens.txt"
  rm -rf "$tmp"
elif [ "$pt_voice" = razo ]; then
  # Plain Piper export: add the metadata sherpa-onnx needs (Node.js).
  tmp="$(mktemp -d)"
  hf="https://huggingface.co/Lucasllfs/Razo-piper-voice/resolve/main"
  curl -fL --retry 3 -o "$tmp/model.onnx" "$hf/pt-BR-razo-medium.onnx"
  curl -fL --retry 3 -o "$tmp/config.json" "$hf/config.json"
  curl -fL --retry 3 -o "$tmp/onnx.proto" \
    "https://raw.githubusercontent.com/onnx/onnx/main/onnx/onnx.proto"
  (cd "$tmp" && npm init -y >/dev/null && npm i protobufjs@7 --silent)
  NODE_PATH="$tmp/node_modules" node "$(dirname "$0")/prepare_piper_voice.js" \
    "$tmp/model.onnx" "$tmp/config.json" "$tmp/onnx.proto" "$pt_dir"
  rm -rf "$tmp"
fi
echo "Voz portuguesa ($pt_voice) pronta em $pt_dir"
