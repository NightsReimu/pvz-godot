#!/usr/bin/env python3
"""Build all fusion SVGs with the same morphology renderer used by live grafts."""
from pathlib import Path
import subprocess
ROOT = Path(__file__).resolve().parents[2]
subprocess.run(["godot", "--headless", "--path", str(ROOT), "--script", "res://scripts/tools/build_universal_fusion_art.gd"], check=True)
