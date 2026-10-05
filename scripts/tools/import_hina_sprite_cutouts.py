#!/usr/bin/env python3
"""Assign and anchor all supplied Hina poses without altering their pixels.

Connected character silhouettes identify each pose; reviewed gaps assign
detached curse flames. Character sprites are never rotated or regenerated.
"""

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np

from import_imperishable_sprite_cutouts import extract
from import_scarlet_sprite_cutouts import CANVAS, PIVOT, ROOT, contact_sheet

LAYOUT = {
    'rows': [134, 391, 649, 899],
    'centers': [[142, 386, 639, 897, 1149, 1410],
                [150, 406, 645, 912, 1168, 1428],
                [147, 388, 644, 907, 1165, 1417],
                [152, 383, 649, 908, 1170, 1413]],
    'gaps': [[0, 267, 511, 770, 1027, 1287, 1536],
             [0, 263, 545, 785, 1034, 1301, 1536],
             [0, 266, 523, 782, 1032, 1291, 1536],
             [0, 258, 507, 814, 1035, 1290, 1536]],
    'row_gaps': [0, 263, 520, 770, 1024],
    'seed_alpha': 32, 'soft_component_gaps': True,
}

AUDIO = {
    'stage': 'audio/bgm/touhou/4-20-stage.mp3',
    'ending': 'audio/bgm/touhou/4-20-ending.mp3',
}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_audio_import(path):
    relative = 'res://' + str(path.relative_to(ROOT))
    imported = 'res://.godot/imported/' + path.name + '-' + hashlib.md5(relative.encode()).hexdigest() + '.mp3str'
    target = Path(str(path) + '.import')
    if not target.exists():
        target.write_text(f'[remap]\n\nimporter="mp3"\ntype="AudioStreamMP3"\npath="{imported}"\n\n[deps]\n\nsource_file="{relative}"\ndest_files=["{imported}"]\n\n[params]\n\nloop=true\nloop_offset=0\nbpm=0\nbeat_count=0\nbar_beats=4\n')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path)
    parser.add_argument('--stage-bgm', type=Path)
    parser.add_argument('--ending-bgm', type=Path)
    args = parser.parse_args()
    folder = ROOT / 'art/source_sheets/hina'
    folder.mkdir(parents=True, exist_ok=True)
    (folder / '.gdignore').touch()
    source = folder / 'hina.png'
    if args.source:
        source.write_bytes(args.source.read_bytes())
    poses, crops = extract('hina', source, LAYOUT)
    destination = ROOT / 'art/hina'
    destination.mkdir(parents=True, exist_ok=True)
    for i, pose in enumerate(poses):
        pose.save(destination / f'frame_{i:02d}.png')
    output = ROOT / 'output/hina'
    output.mkdir(parents=True, exist_ok=True)
    contact_sheet('hina', poses, output / 'source-poses.png')
    yy, _ = np.where(np.array(poses[0])[:, :, 3] >= 128)
    record = {
        'kind': 'hina_boss', 'folder': 'art/hina',
        'frame_count': 24, 'source_pose_count': 24,
        'source': 'user_transparent_sheet_individual_crops',
        'source_sheet': str(source.relative_to(ROOT)),
        'original_sha256': sha256(source), 'source_sha256': sha256(source),
        'canvas': list(CANVAS), 'pivot': list(PIVOT),
        'idle_height': int(yy.max() - yy.min() + 1),
        'idle_bottom': int(yy.max() + 1),
        'runtime_source_slots': list(range(24)), 'seed_alpha': 32,
    }
    audio_records = []
    for role, relative in AUDIO.items():
        supplied = getattr(args, role + '_bgm')
        target = ROOT / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if supplied:
            target.write_bytes(supplied.read_bytes())
        write_audio_import(target)
        audio_records.append({'role': role, 'path': relative,
                              'source_name': f'4-20{"道中" if role == "stage" else "终末"}.mp3',
                              'source_sha256': sha256(target)})
    manifest = {
        'method': 'Exact supplied RGBA pixels, individual component ownership and foot anchors; no rotation, resampling, mirroring, recoloring, background extraction or generation.',
        'sprite': dict(record, individual_crops=crops, layout=LAYOUT),
        'audio': audio_records,
    }
    (folder / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    (folder / 'animation_source_record.json').write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n')
    print('Hina: 24 poses, idle height', record['idle_height'],
          'bottom', record['idle_bottom'], 'SHA256', record['source_sha256'])


if __name__ == '__main__':
    main()
