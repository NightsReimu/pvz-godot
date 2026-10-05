#!/usr/bin/env python3
"""Import the supplied Aki sisters' transparent sheets without changing pixels.

Ownership follows connected character silhouettes and reviewed detached-leaf
gaps. Faint alpha is retained, including the original soft spell trails. All
24 supplied poses keep their original size and share a foot anchor.
"""

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np

from import_imperishable_sprite_cutouts import extract
from import_scarlet_sprite_cutouts import CANVAS, PIVOT, ROOT, contact_sheet

LAYOUTS = {
    'shizuha': {
        'rows': [142, 395, 647, 898],
        'centers': [[141, 385, 636, 912, 1172, 1412],
                    [156, 403, 659, 908, 1172, 1423],
                    [146, 390, 645, 905, 1170, 1424],
                    [153, 407, 659, 916, 1175, 1420]],
        'gaps': [[0, 267, 508, 768, 1046, 1294, 1536],
                 [0, 268, 516, 789, 1048, 1305, 1536],
                 [0, 262, 516, 773, 1035, 1290, 1536],
                 [0, 281, 537, 790, 1035, 1300, 1536]],
        'row_gaps': [0, 258, 515, 768, 1024],
        'seed_alpha': 32,
        'soft_component_gaps': True,
    },
    'minoriko': {
        'rows': [141, 395, 650, 900],
        'centers': [[121, 374, 629, 900, 1160, 1409],
                    [124, 382, 634, 899, 1158, 1409],
                    [144, 390, 639, 905, 1163, 1411],
                    [136, 391, 646, 896, 1151, 1413]],
        'gaps': [[0, 253, 503, 774, 1037, 1293, 1536],
                 [0, 249, 507, 778, 1036, 1290, 1536],
                 [0, 276, 523, 779, 1044, 1290, 1536],
                 [0, 257, 541, 771, 1025, 1297, 1536]],
        'row_gaps': [0, 259, 513, 773, 1024],
        'seed_alpha': 32,
        'soft_component_gaps': True,
    },
}

AUDIO = {
    'stage': 'audio/bgm/touhou/4-19-stage.mp3',
    'ending': 'audio/bgm/touhou/4-19-ending.mp3',
}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--shizuha', type=Path)
    parser.add_argument('--minoriko', type=Path)
    parser.add_argument('--stage-bgm', type=Path)
    parser.add_argument('--ending-bgm', type=Path)
    args = parser.parse_args()
    folder = ROOT / 'art/source_sheets/aki'
    folder.mkdir(parents=True, exist_ok=True)
    (folder / '.gdignore').touch()
    output = ROOT / 'output/aki'
    output.mkdir(parents=True, exist_ok=True)
    records = []
    for name, layout in LAYOUTS.items():
        source = folder / f'{name}.png'
        supplied = getattr(args, name)
        if supplied:
            source.write_bytes(supplied.read_bytes())
        poses, crops = extract(name, source, layout)
        destination = ROOT / f'art/{name}'
        destination.mkdir(parents=True, exist_ok=True)
        for i, pose in enumerate(poses):
            pose.save(destination / f'frame_{i:02d}.png')
        contact_sheet(name, poses, output / f'{name}-source-poses.png')
        yy, _ = np.where(np.array(poses[0])[:, :, 3] >= 128)
        record = {
            'kind': name + '_boss', 'folder': f'art/{name}',
            'frame_count': 24, 'source_pose_count': 24,
            'source': 'user_transparent_sheet_individual_crops',
            'source_sheet': str(source.relative_to(ROOT)),
            'original_sha256': sha256(source), 'source_sha256': sha256(source),
            'canvas': list(CANVAS), 'pivot': list(PIVOT),
            'idle_height': int(yy.max() - yy.min() + 1),
            'idle_bottom': int(yy.max() + 1),
            'runtime_source_slots': list(range(24)), 'seed_alpha': 32,
        }
        records.append(dict(record, individual_crops=crops, layout=layout))
        print(name, '24 poses, idle height', record['idle_height'],
              'bottom', record['idle_bottom'], 'SHA256', record['source_sha256'])
    audio_records = []
    for role, relative in AUDIO.items():
        supplied = getattr(args, role + '_bgm')
        target = ROOT / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if supplied:
            target.write_bytes(supplied.read_bytes())
        audio_records.append({'role': role, 'path': relative,
                              'source_name': f'4-19{"道中" if role == "stage" else "终末"}.mp3',
                              'source_sha256': sha256(target)})
    manifest = {'method': 'Exact supplied RGBA pixels, independent component ownership and foot anchors; no resampling, mirroring, recoloring, background extraction or generation.',
                'sets': records, 'audio': audio_records}
    (folder / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    metadata = ROOT / 'art/touhou_boss_animation_sources.json'
    previous = json.loads(metadata.read_text())
    updates = {r['kind']: {k: v for k, v in r.items()
                          if k not in ('individual_crops', 'layout')} for r in records}
    previous_kinds = {r['kind'] for r in previous}
    merged = [updates.get(r['kind'], r) for r in previous]
    merged.extend(record for kind, record in updates.items() if kind not in previous_kinds)
    metadata.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    main()
