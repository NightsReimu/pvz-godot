#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${IMAGE2_CONFIG_PATH:-/Users/hecrereed/xianyu/蜂蜜/image2画图配置}"
IMAGE_GEN="${IMAGE_GEN:-${HOME}/.codex/skills/.system/imagegen/scripts/image_gen.py}"
CHROMA="${CHROMA_KEY_REMOVER:-${HOME}/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py}"
PROMPTS="${PROMPTS:-scripts/tools/image2_polish_prompts.jsonl}"
OUT_DIR="${OUT_DIR:-output/imagegen/image2-polish}"
PREPARE="${PREPARE_POLISH_ASSET:-scripts/tools/prepare_image2_polish_asset.py}"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "image2 config not found: $CONFIG_PATH" >&2
  exit 1
fi

if [[ ! -f "$IMAGE_GEN" ]]; then
  echo "image generation CLI not found: $IMAGE_GEN" >&2
  exit 1
fi

if [[ ! -f "$CHROMA" ]]; then
  echo "chroma-key remover not found: $CHROMA" >&2
  exit 1
fi

if [[ ! -f "$PREPARE" ]]; then
  echo "asset preparation script not found: $PREPARE" >&2
  exit 1
fi

OPENAI_BASE_URL="$(sed -n '1p' "$CONFIG_PATH")"
OPENAI_API_KEY="$(sed -n '2p' "$CONFIG_PATH")"
export OPENAI_BASE_URL
export OPENAI_API_KEY

mkdir -p "$OUT_DIR" art/polish

python3 "$IMAGE_GEN" generate-batch \
  --model gpt-image-2 \
  --input "$PROMPTS" \
  --out-dir "$OUT_DIR" \
  --concurrency 2 \
  --max-attempts 1 \
  --fail-fast \
  --force

python3 "$CHROMA" \
  --input "$OUT_DIR/peashooter-source.png" \
  --out "$OUT_DIR/peashooter-alpha.png" \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill \
  --force

python3 "$CHROMA" \
  --input "$OUT_DIR/sunflower-source.png" \
  --out "$OUT_DIR/sunflower-alpha.png" \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill \
  --force

python3 "$CHROMA" \
  --input "$OUT_DIR/wallnut-source.png" \
  --out "$OUT_DIR/wallnut-alpha.png" \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill \
  --force

python3 "$CHROMA" \
  --input "$OUT_DIR/pea-source.png" \
  --out "$OUT_DIR/pea-alpha.png" \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill \
  --force

python3 "$PREPARE" --input "$OUT_DIR/peashooter-alpha.png" --out art/polish/peashooter-polished.png --size 128x128 --padding 32
python3 "$PREPARE" --input "$OUT_DIR/sunflower-alpha.png" --out art/polish/sunflower-polished.png --size 128x128 --padding 32
python3 "$PREPARE" --input "$OUT_DIR/wallnut-alpha.png" --out art/polish/wallnut-polished.png --size 128x128 --padding 32
python3 "$PREPARE" --input "$OUT_DIR/pea-alpha.png" --out art/polish/pea-polished.png --size 64x64 --padding 24

echo "Generated image2 polish assets with gpt-image-2."
