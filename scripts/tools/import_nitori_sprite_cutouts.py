#!/usr/bin/env python3
"""Assign and anchor all supplied Nitori poses without altering visible pixels.

The supplied sheet carries a faint full-canvas haze (alpha 1-9). It is cleared
once into a derived ownership source; every remaining RGBA pixel is copied
unchanged. Water blasts that cross a grid line stay with their own pose.
"""

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

from import_imperishable_sprite_cutouts import extract
from import_scarlet_sprite_cutouts import CANVAS, PIVOT, ROOT, contact_sheet

HAZE_ALPHA = 10
# Rows/centers are the opaque character bodies. Gaps sit inside reviewed empty
# vertical strips, so frame 08's and 20's water blasts keep their caster.
LAYOUT = {
    'rows': [135, 390, 641, 890],
    'centers': [[160, 399, 639, 891, 1150, 1386],
                [149, 379, 688, 920, 1156, 1406],
                [153, 391, 649, 910, 1164, 1407],
                [139, 382, 657, 927, 1161, 1403]],
    'gaps': [[0, 278, 516, 760, 1018, 1270, 1536],
             [0, 261, 475, 775, 1015, 1300, 1536],
             [0, 272, 511, 785, 1027, 1295, 1536],
             [0, 261, 488, 824, 1040, 1273, 1536]],
    'row_gaps': [0, 265, 516, 768, 1024],
    'seed_alpha': 32, 'soft_component_gaps': True,
}

AUDIO = {
    'stage': 'audio/bgm/touhou/4-21-stage.mp3',
    'ending': 'audio/bgm/touhou/4-21-ending.mp3',
}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_audio_import(path):
    relative = 'res://' + str(path.relative_to(ROOT))
    imported = 'res://.godot/imported/' + path.name + '-' + hashlib.md5(relative.encode()).hexdigest() + '.mp3str'
    target = Path(str(path) + '.import')
    if not target.exists():
        target.write_text(f'[remap]\n\nimporter="mp3"\ntype="AudioStreamMP3"\npath="{imported}"\n\n[deps]\n\nsource_file="{relative}"\ndest_files=["{imported}"]\n\n[params]\n\nloop=true\nloop_offset=0\nbpm=0\nbeat_count=0\nbar_beats=4\n')


def clear_haze(original, derived):
    rgba = np.array(Image.open(original).convert('RGBA'))
    haze = rgba[:, :, 3] < HAZE_ALPHA
    visible = int(np.sum(haze & (rgba[:, :, 3] > 0)))
    rgba[haze] = 0
    Image.fromarray(rgba).save(derived)
    return visible


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path)
    parser.add_argument('--stage-bgm', type=Path)
    parser.add_argument('--ending-bgm', type=Path)
    args = parser.parse_args()
    folder = ROOT / 'art/source_sheets/nitori'
    folder.mkdir(parents=True, exist_ok=True)
    (folder / '.gdignore').touch()
    original = folder / 'nitori.png'
    if args.source:
        original.write_bytes(args.source.read_bytes())
    output = ROOT / 'output/nitori'
    output.mkdir(parents=True, exist_ok=True)
    # The derived ownership sheet is rebuilt on demand and never committed.
    source = output / 'nitori-haze-cleared.png'
    cleared = clear_haze(original, source)
    poses, crops = extract('nitori', source, LAYOUT)
    destination = ROOT / 'art/nitori'
    destination.mkdir(parents=True, exist_ok=True)
    for i, pose in enumerate(poses):
        pose.save(destination / f'frame_{i:02d}.png')
    contact_sheet('nitori', poses, output / 'source-poses.png')
    yy, _ = np.where(np.array(poses[0])[:, :, 3] >= 128)
    record = {
        'kind': 'nitori_boss', 'folder': 'art/nitori',
        'frame_count': 24, 'source_pose_count': 24,
        'source': 'user_transparent_sheet_individual_crops',
        'source_sheet': str(original.relative_to(ROOT)),
        'original_sha256': sha256(original), 'source_sha256': sha256(original),
        'haze_alpha_below': HAZE_ALPHA, 'haze_pixels_cleared': cleared,
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
                              'source_name': f'4-21{"道中" if role == "stage" else "终末"}.mp3',
                              'source_sha256': sha256(target)})
    manifest = {
        'method': 'Supplied RGBA pixels with alpha >= 10 copied exactly; the near-invisible alpha 1-9 sheet haze is cleared once. Individual component ownership and foot anchors; no rotation, resampling, mirroring, recoloring or generation.',
        'sprite': dict(record, individual_crops=crops, layout=LAYOUT),
        'audio': audio_records,
    }
    (folder / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    (folder / 'animation_source_record.json').write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n')
    print('Nitori: 24 poses, idle height', record['idle_height'],
          'bottom', record['idle_bottom'], 'haze cleared', cleared,
          'SHA256', record['original_sha256'])


if __name__ == '__main__':
    main()
