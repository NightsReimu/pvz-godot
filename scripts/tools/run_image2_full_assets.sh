#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${IMAGE2_CONFIG_PATH:-/Users/hecrereed/xianyu/蜂蜜/image2画图配置}"
IMAGE_GEN="${IMAGE_GEN:-${HOME}/.codex/skills/.system/imagegen/scripts/image_gen.py}"
CHROMA="${CHROMA_KEY_REMOVER:-${HOME}/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py}"
MANIFEST_SCRIPT="${MANIFEST_SCRIPT:-scripts/tools/generate_image2_asset_manifest.py}"
POSTPROCESS="${POSTPROCESS_IMAGE2_ASSETS:-scripts/tools/postprocess_image2_asset_batch.py}"
MANIFEST="${MANIFEST:-output/imagegen/image2-full-manifest.jsonl}"
OUT_DIR="${OUT_DIR:-output/imagegen/image2-full}"
CATEGORY="${CATEGORY:-all}"
KINDS="${KINDS:-}"
OFFSET="${OFFSET:-0}"
LIMIT="${LIMIT:--1}"
CONCURRENCY="${CONCURRENCY:-2}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-1}"
FORCE="${FORCE:-0}"

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

if [[ ! -f "$MANIFEST_SCRIPT" ]]; then
  echo "manifest generator not found: $MANIFEST_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$POSTPROCESS" ]]; then
  echo "postprocess script not found: $POSTPROCESS" >&2
  exit 1
fi

OPENAI_BASE_URL="$(sed -n '1p' "$CONFIG_PATH")"
OPENAI_API_KEY="$(sed -n '2p' "$CONFIG_PATH")"
export OPENAI_BASE_URL
export OPENAI_API_KEY

mkdir -p "$OUT_DIR" art/image2/plants art/image2/zombies art/image2/projectiles art/image2/effects

manifest_args=(
  --out "$MANIFEST"
  --category "$CATEGORY"
  --offset "$OFFSET"
  --limit "$LIMIT"
)
if [[ -n "$KINDS" ]]; then
  manifest_args+=(--kinds "$KINDS")
fi

python3 "$MANIFEST_SCRIPT" "${manifest_args[@]}"

batch_args=(
  generate-batch
  --model gpt-image-2
  --input "$MANIFEST"
  --out-dir "$OUT_DIR"
  --concurrency "$CONCURRENCY"
  --max-attempts "$MAX_ATTEMPTS"
)
if [[ "$FORCE" == "1" ]]; then
  batch_args+=(--force)
fi
if [[ "${FAIL_FAST:-1}" == "1" ]]; then
  batch_args+=(--fail-fast)
fi

python3 "$IMAGE_GEN" "${batch_args[@]}"

postprocess_args=(
  --manifest "$MANIFEST"
  --source-dir "$OUT_DIR"
  --asset-root art/image2
  --chroma-script "$CHROMA"
)
if [[ "$FORCE" == "1" ]]; then
  postprocess_args+=(--force)
fi

python3 "$POSTPROCESS" "${postprocess_args[@]}"

echo "Generated image2 asset batch with gpt-image-2 into art/image2."
