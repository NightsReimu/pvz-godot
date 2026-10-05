#!/usr/bin/env python3
"""Integrate the supplied transparent Suika sheet without altering its pixels."""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from import_imperishable_sprite_cutouts import extract
from import_scarlet_sprite_cutouts import CANVAS, PIVOT, ROOT, contact_sheet

LAYOUT = {
    'rows': [143, 412, 682, 947],
    'centers': [[123, 371, 612, 858, 1102, 1340],
                [128, 386, 622, 867, 1111, 1338],
                [127, 377, 622, 866, 1114, 1355],
                [127, 377, 622, 866, 1116, 1358]],
    'gaps': [[0, 249, 488, 733, 969, 1207, 1448],
             [0, 249, 499, 754, 992, 1225, 1448],
             [0, 254, 500, 743, 993, 1227, 1448],
             [0, 263, 508, 757, 984, 1226, 1448]],
    'row_gaps': [0, 280, 546, 814, 1086],
    'seed_alpha': 32, 'soft_component_gaps': True,
    'seed_dividers': [[507, 815, 509, 1086]],
}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path)
    args = parser.parse_args()
    folder = ROOT / 'art/source_sheets/suika'
    folder.mkdir(parents=True, exist_ok=True)
    (folder / '.gdignore').touch()
    source = folder / 'suika.png'
    if args.source: source.write_bytes(args.source.read_bytes())
    poses, crops = extract('suika', source, LAYOUT)
    destination = ROOT / 'art/suika'
    destination.mkdir(exist_ok=True)
    for i, pose in enumerate(poses): pose.save(destination / f'frame_{i:02d}.png')
    output = ROOT / 'output/suika'
    output.mkdir(parents=True, exist_ok=True)
    contact_sheet('suika', poses, output / 'source-poses.png')
    yy, _ = np.where(np.array(poses[0])[:, :, 3] >= 128)
    sha = hashlib.sha256(source.read_bytes()).hexdigest()
    record = {'kind': 'suika_boss', 'folder': 'art/suika', 'frame_count': 24,
              'source_pose_count': 24, 'source': 'user_transparent_sheet_individual_crops',
              'source_sheet': str(source.relative_to(ROOT)), 'original_sha256': sha,
              'source_sha256': sha, 'canvas': list(CANVAS), 'pivot': list(PIVOT),
              'idle_height': int(yy.max() - yy.min() + 1), 'idle_bottom': int(yy.max() + 1),
              'seed_alpha': 32, 'runtime_source_slots': list(range(24))}
    (folder / 'manifest.json').write_text(json.dumps(dict(record, individual_crops=crops,
        method='Exact supplied RGBA; component ownership and foot anchors, including one reviewed touching-glow divider; no resampling, mirroring or regeneration.'), ensure_ascii=False, indent=2) + '\n')
    metadata = ROOT / 'art/touhou_boss_animation_sources.json'
    records = [r for r in json.loads(metadata.read_text()) if r['kind'] != 'suika_boss']
    records.append(record)
    metadata.write_text(json.dumps(records, ensure_ascii=False, indent=2) + '\n')
    print('Suika: 24 poses; idle height', record['idle_height'], 'bottom', record['idle_bottom'], 'sha256', sha)

if __name__ == '__main__': main()
