#!/usr/bin/env bash
# Downloads the offline speech-recognition model (Whisper tiny, int8,
# sherpa-onnx export, ~104 MB) into assets/models/voice/. Run once per
# checkout before `flutter build`; the files are bundled into the app, so
# the child's device never needs internet. They are gitignored (too big
# for git). Without them the app still works -- the mic button is hidden.
set -euo pipefail

dir="$(cd "$(dirname "$0")/.." && pwd)/assets/models/voice"
base="https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/main"
mkdir -p "$dir"

for file in tiny-encoder.int8.onnx tiny-decoder.int8.onnx tiny-tokens.txt; do
  if [ -s "$dir/$file" ]; then
    echo "ok       $file"
    continue
  fi
  echo "baixando $file..."
  curl -fL --retry 3 -o "$dir/$file.part" "$base/$file"
  mv "$dir/$file.part" "$dir/$file"
done
echo "Modelo de voz pronto em $dir"
