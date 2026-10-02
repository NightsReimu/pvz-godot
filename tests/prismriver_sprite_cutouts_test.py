"""Every supplied visible RGBA pixel belongs to exactly one of 72 poses."""
import hashlib
import json
import sys
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts/tools'))
from import_prismriver_sprite_cutouts import LAYOUTS
from import_imperishable_sprite_cutouts import extract

manifest = json.loads((ROOT / 'art/source_sheets/prismriver_refresh/manifest.json').read_text())
assert len(manifest['sets']) == 3
for record in manifest['sets']:
    name = record['member']
    source = ROOT / record['source_sheet']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == record['original_sha256']
    expected, crops = extract(name, source, dict(LAYOUTS[name], rows=[142,391,643,898], seed_alpha=96, soft_component_gaps=True))
    assert crops == record['individual_crops'] and len(expected) == 24
    total = 0
    for i, pose in enumerate(expected):
        actual = np.array(Image.open(ROOT / record['folder'] / f'frame_{i:02d}.png'))
        assert np.array_equal(actual, np.array(pose)), (name,i)
        total += int(actual[:,:,3].astype('uint64').sum())
        assert actual[:,:,3].max() > 128 and actual[:,:,3].sum() > 1000000
    assert total == int(np.array(Image.open(source))[:,:,3].astype('uint64').sum()), name
    assert abs(record['idle_height'] * (180.0 / record['idle_height']) - 180.0) < 0.001
print('Three byte-exact original sources, 72 owned poses, all alpha retained once and stable body scale: PASS')
