#!/usr/bin/env python3
"""Rebuild the fusion parts library, then compose every fixed fusion SVG with it."""
from pathlib import Path
import subprocess
import sys
ROOT = Path(__file__).resolve().parents[2]
subprocess.run([sys.executable, str(ROOT / "scripts/tools/build_fusion_parts.py")], check=True)
subprocess.run(["godot", "--headless", "--path", str(ROOT), "--script", "res://scripts/tools/build_universal_fusion_art.gd"], check=True)
