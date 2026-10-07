#!/bin/zsh
set -eu
pvz_project_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
exec python3 "$pvz_project_dir/scripts/tools/launch_game.py" "$@"
