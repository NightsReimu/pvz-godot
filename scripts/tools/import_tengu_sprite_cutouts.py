#!/usr/bin/env python3
"""Own and anchor the two supplied Tengu sheets without changing RGBA pixels.

Both originals already carry transparency; the Aya sheet's brown RGB matte
has alpha zero. Preserve soft effects too, without dematting or thresholding.
Momiji is 1448x1086, so ownership uses reviewed individual figures, not cells.
"""

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

from import_imperishable_sprite_cutouts import extract
from import_scarlet_sprite_cutouts import CANVAS, PIVOT, ROOT, contact_sheet

LAYOUTS = {
    'momiji': {
        'rows': [149, 423, 690, 956],
        'centers': [[128, 368, 608, 845, 1088, 1329],
                    [134, 361, 610, 857, 1107, 1336],
                    [131, 374, 614, 847, 1095, 1334],
                    [135, 381, 630, 858, 1105, 1348]],
        'gaps': [[0, 253, 489, 736, 980, 1220, 1448],
                 [0, 249, 486, 750, 985, 1230, 1448],
                 [0, 258, 492, 739, 976, 1217, 1448],
                 [0, 251, 515, 747, 992, 1228, 1448]],
        'row_gaps': [0, 275, 545, 811, 1086],
        'seed_alpha': 32, 'soft_component_gaps': True,
    },
    'aya': {
        'rows': [134, 388, 642, 899],
        'centers': [[142, 390, 639, 920, 1163, 1420],
                    [151, 384, 670, 925, 1163, 1427],
                    [144, 411, 660, 910, 1181, 1424],
                    [134, 409, 665, 915, 1182, 1425]],
        'gaps': [[0, 273, 520, 782, 1043, 1292, 1536],
                 [0, 253, 517, 811, 1043, 1302, 1536],
                 [0, 278, 540, 786, 1041, 1300, 1536],
                 [0, 262, 528, 812, 1048, 1308, 1536]],
        'row_gaps': [0, 254, 514, 764, 1024],
        'seed_alpha': 32, 'soft_component_gaps': True,
    },
}

AUDIO = {
    'stage': 'audio/bgm/touhou/4-22-stage.mp3',
    'ending': 'audio/bgm/touhou/4-22-ending.mp3',
}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_audio_import(path):
    relative = 'res://' + str(path.relative_to(ROOT))
    imported = 'res://.godot/imported/' + path.name + '-' + hashlib.md5(relative.encode()).hexdigest() + '.mp3str'
    target = Path(str(path) + '.import')
    if not target.exists():
        target.write_text(f'[remap]\n\nimporter="mp3"\ntype="AudioStreamMP3"\npath="{imported}"\n\n[deps]\n\nsource_file="{relative}"\ndest_files=["{imported}"]\n\n[params]\n\nloop=true\nloop_offset=0\nbpm=0\nbeat_count=0\nbar_beats=4\n')


def write_texture_import(path):
    # Godot's default alpha-border fix also recolors alpha 1–19. These sheets
    # already author their soft RGB edges, so preserve them without that pass.
    target = Path(str(path) + '.import')
    if target.exists():
        text = target.read_text()
        text = text.replace('process/fix_alpha_border=true', 'process/fix_alpha_border=false')
        target.write_text(text)
        return
    relative = 'res://' + str(path.relative_to(ROOT))
    imported = 'res://.godot/imported/' + path.name + '-' + hashlib.md5(relative.encode()).hexdigest() + '.ctex'
    target.write_text(f'[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\npath="{imported}"\n\n[deps]\n\nsource_file="{relative}"\ndest_files=["{imported}"]\n\n[params]\n\ncompress/mode=0\nmipmaps/generate=false\nprocess/fix_alpha_border=false\nprocess/premult_alpha=false\nprocess/size_limit=0\n')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--momiji', type=Path)
    parser.add_argument('--aya', type=Path)
    parser.add_argument('--stage-bgm', type=Path)
    parser.add_argument('--ending-bgm', type=Path)
    args = parser.parse_args()
    output = ROOT / 'output/tengu-4-22/assets'
    output.mkdir(parents=True, exist_ok=True)
    audio_records = []
    for role, relative in AUDIO.items():
        supplied = getattr(args, role + '_bgm')
        target = ROOT / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if supplied:
            target.write_bytes(supplied.read_bytes())
        write_audio_import(target)
        audio_records.append({'role': role, 'path': relative,
                              'source_name': f'4-22{"道中" if role == "stage" else "终末"}.mp3',
                              'source_sha256': sha256(target)})
    for name, layout in LAYOUTS.items():
        folder = ROOT / f'art/source_sheets/{name}'
        folder.mkdir(parents=True, exist_ok=True)
        (folder / '.gdignore').touch()
        source = folder / f'{name}.png'
        supplied = getattr(args, name)
        if supplied:
            source.write_bytes(supplied.read_bytes())
        poses, crops = extract(name, source, layout)
        destination = ROOT / f'art/{name}'
        destination.mkdir(parents=True, exist_ok=True)
        for index, pose in enumerate(poses):
            path = destination / f'frame_{index:02d}.png'
            pose.save(path)
            write_texture_import(path)
            crops[index]['frame_sha256'] = sha256(path)
        contact_sheet(name, poses, output / f'{name}-source-poses.png')
        yy, _ = np.where(np.array(poses[0])[:, :, 3] >= 128)
        original = Image.open(source)
        record = {
            'kind': name + '_boss', 'folder': f'art/{name}',
            'frame_count': 24, 'source_pose_count': 24,
            'source': 'user_transparent_sheet_individual_crops',
            'source_sheet': str(source.relative_to(ROOT)),
            'source_size': list(original.size),
            'original_sha256': sha256(source), 'source_sha256': sha256(source),
            'canvas': list(CANVAS), 'pivot': list(PIVOT),
            'idle_height': int(yy.max() - yy.min() + 1),
            'idle_bottom': int(yy.max() + 1),
            'runtime_source_slots': list(range(24)), 'seed_alpha': 32,
            'texture_import': {'compress_mode': 0, 'fix_alpha_border': False,
                               'premult_alpha': False, 'mipmaps': False},
        }
        manifest = {'method': 'Exact supplied RGBA pixels, independent component ownership and original foot anchors; alpha-zero RGB is excluded, all alpha-positive pixels retained once. No background extraction, haze threshold, rotation, mirroring, recoloring, resampling or generation.',
                    'sprite': dict(record, individual_crops=crops, layout=layout),
                    'audio': audio_records}
        (folder / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
        (folder / 'animation_source_record.json').write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n')
        print(name, '24 poses, source', original.size, 'idle height', record['idle_height'],
              'bottom', record['idle_bottom'], 'SHA256', record['source_sha256'])


if __name__ == '__main__':
    main()
