#!/usr/bin/env python3
"""Select a supported local Godot without replacing the user's system engine."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
MINIMUM = (4, 6, 3)

def version_of(candidate):
    try:
        value = subprocess.check_output([str(candidate), '--version'], text=True, timeout=15).strip()
    except (OSError, subprocess.SubprocessError):
        return None
    match = re.match(r'(\d+)\.(\d+)(?:\.(\d+))?', value)
    if not match:
        return None
    version = tuple(int(part or 0) for part in match.groups())
    return value if version >= MINIMUM else None

def find_engine():
    choices = [os.environ.get('PVZ_GODOT_BIN'),
               ROOT / 'build/godot/4.6.3/Godot.app/Contents/MacOS/Godot',
               ROOT / 'output/sanae-4-23/crash/godot-4.6.3/Godot.app/Contents/MacOS/Godot',
               shutil.which('godot'),
               '/Applications/Godot.app/Contents/MacOS/Godot']
    for path in choices:
        if path and (version := version_of(path)):
            return str(path), version
    raise RuntimeError('需要 Godot 4.6.3 或更新版本；可安装新版，或设置 PVZ_GODOT_BIN 指向其可执行文件。')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args, extra = parser.parse_known_args()
    try:
        engine, version = find_engine()
    except RuntimeError as error:
        print(error, file=sys.stderr)
        return 1
    print(f'Godot {version}: {engine}', flush=True)
    if args.check:
        return 0
    return subprocess.call([engine, '--path', str(ROOT), *extra], cwd=ROOT)

if __name__ == '__main__':
    sys.exit(main())
