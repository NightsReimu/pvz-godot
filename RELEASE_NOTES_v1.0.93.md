# v1.0.93

## Touhou boss animation repair

- Rebuilt the affected 24-frame Touhou boss animations from the preserved
  original pose artwork instead of the chroma-keyed image2 output.
- Removed connected white/green screen residue while retaining internal green
  costumes, spell effects, and Youmu's half-phantom details.
- Added `scripts/tools/repair_touhou_boss_frames.py` so the recovery and
  size-normalized local in-between generation can be repeated deterministically.
- Refreshed Godot texture imports and animation contact sheets.
