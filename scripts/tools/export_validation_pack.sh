#!/usr/bin/env bash
# Export a validation build under its own Godot project name.
#
# Why this exists: Godot derives user:// from application/config/name. A pack exported with
# the normal name resolves to the SAME user:// directory as the main game, so running it
# reads and rewrites the real save file (this is how a v1.0.112 validation pack wiped a
# grown plant's enhance level). Suffixing the name for validation builds gives them a
# separate save directory, so they can never touch the main progress.
#
# usage: scripts/tools/export_validation_pack.sh <label> [preset] [output-dir]
#   label     short tag, e.g. marisa-validation
#   preset    export preset name (default "macOS")
#   out-dir   output directory (default build/<label>)

set -euo pipefail

LABEL="${1:?usage: export_validation_pack.sh <label> [preset] [output-dir]}"
PRESET="${2:-macOS}"
OUT_DIR="${3:-build/${LABEL}}"
GODOT="${GODOT:-godot}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

BASE_NAME="植物大战僵尸svg版"
SAFE_NAME="${BASE_NAME}-${LABEL}"

BACKUP="$(mktemp)"
cp project.godot "$BACKUP"
restore() { cp "$BACKUP" project.godot; rm -f "$BACKUP"; }
trap restore EXIT

python3 - "$SAFE_NAME" <<'PY'
import io, re, sys
name = sys.argv[1]
path = "project.godot"
src = io.open(path, encoding="utf-8").read()
new, count = re.subn(r'config/name="[^"]*"', 'config/name="%s"' % name, src, count=1)
assert count == 1, "config/name not found in project.godot"
io.open(path, "w", encoding="utf-8").write(new)
PY

mkdir -p "$OUT_DIR"
echo "exporting preset '$PRESET' as project name '$SAFE_NAME' -> $OUT_DIR/game.pck"
"$GODOT" --headless --path . --export-pack "$PRESET" "$OUT_DIR/game.pck" 2>&1 | tail -3
echo
echo "done. this pack writes to its own user:// directory:"
echo "  ~/Library/Application Support/Godot/app_userdata/${SAFE_NAME}/"
echo "the main save at '.../app_userdata/${BASE_NAME}/' is untouched."
