#!/usr/bin/env python3
"""Lossless ownership/translation of the supplied 24 transparent Sanae poses."""
import argparse
import hashlib
import json
import copy
from pathlib import Path
import numpy as np
from PIL import Image
from import_imperishable_sprite_cutouts import extract
from import_scarlet_sprite_cutouts import CANVAS, PIVOT, ROOT, contact_sheet
from import_tengu_sprite_cutouts import write_audio_import, write_texture_import

LAYOUT = {'rows': [130, 386, 642, 898],
          'centers': [[125, 375, 626, 902, 1164, 1420],
                      [125, 385, 632, 898, 1151, 1412],
                      [126, 377, 629, 898, 1150, 1415],
                      [134, 387, 642, 898, 1147, 1407]],
          'gaps': [[0, 256, 512, 768, 1024, 1280, 1536]] * 4,
          'row_gaps': [0, 256, 512, 768, 1024],
          # Rich effect cores keep the tops of15/19 with their own aura/sweep,
          # rather than the nearer feet of09/13 in the preceding row.
          'seed_alpha': 32, 'soft_component_gaps': True,
          # These reviewed seam rectangles split the touching19/20 blue arcs
          # in the SEED MASK only. Every source pixel is restored afterward.
          'seed_dividers': [[463, 850, 467, 858], [471, 862, 501, 887],
                            [512, 921, 525, 927]]}
CALIBRATION_ALPHA = 240
SOURCE_SHA = 'a0955b390603c05b7fa4d7198c7328d15e4c7539699d0bb73692f29fdde2167b'
SOURCE_NAME = 'codex-clipboard-54323c73-a85d-4ab9-bff3-2c6a08098cba.png'


def extract_sanae(source):
    """Restore exact RGBA from rich ownership, anchored by the opaque bodies.

    The original has faint alpha bridges between rows and overlapping sweeps.
    Using only240-alpha seeds borrowed visible effects from another pose;
    using32-alpha bodies as foot anchors would instead anchor to low auras.
    Keep those two concerns independent, with no source pixel mutation.
    """
    rgba = np.array(Image.open(source).convert('RGBA'))
    high = copy.deepcopy(LAYOUT)
    high['seed_alpha'] = CALIBRATION_ALPHA
    high.pop('seed_dividers')
    _, calibrated = extract('sanae', source, high)
    rich, rich_crops = extract('sanae', source, LAYOUT)
    owner = np.full(rgba.shape[:2], -1, np.int16)
    coverage = np.zeros(rgba.shape[:2], np.uint8)
    for slot, (frame, crop) in enumerate(zip(rich, rich_crops)):
        pixels = np.array(frame)
        y, x = np.where(pixels[:, :, 3] > 0)
        sy = y + crop['anchor'][1] - PIVOT[1]
        sx = x + crop['anchor'][0] - PIVOT[0]
        owner[sy, sx] = slot
        coverage[sy, sx] += 1
    assert np.all(coverage[rgba[:, :, 3] > 0] == 1)
    # The source itself overlaps20's blue/white foreground sweep on19's hair.
    # Preserve the visible green hair as19 and the upper blue/white stroke as20.
    # RGB is used only to name the owner; all RGBA bytes remain untouched.
    y, x = np.indices(rgba.shape[:2])
    rgb = rgba[:, :, :3].astype(float)
    hair = (x >= 460) & (x < 503) & (y >= 850) & (y < 910)
    green = (rgb[:, :, 1] > rgb[:, :, 0] * 1.3) & (rgb[:, :, 1] > rgb[:, :, 2] * 1.3)
    owner[hair & green & (rgba[:, :, 3] > 0)] = 19
    upper_stroke = (x >= 460) & (x < 503) & (y >= 850) & (y < 888)
    owner[upper_stroke & (rgb[:, :, 2] >= rgb[:, :, 1]) & (rgba[:, :, 3] > 0)] = 20
    frames, crops = [], []
    for slot, calibration in enumerate(calibrated):
        sy, sx = np.where((owner == slot) & (rgba[:, :, 3] > 0))
        anchor = calibration['anchor']
        dy = sy + PIVOT[1] - anchor[1]
        dx = sx + PIVOT[0] - anchor[0]
        assert dy.min() >= 2 and dx.min() >= 2 and dy.max() < CANVAS[1] - 2 and dx.max() < CANVAS[0] - 2
        canvas = np.zeros((CANVAS[1], CANVAS[0], 4), np.uint8)
        canvas[dy, dx] = rgba[sy, sx]
        frames.append(Image.fromarray(canvas))
        crops.append({'source_slot': slot, 'bounds': [int(sx.min()), int(sy.min()), int(sx.max()) + 1, int(sy.max()) + 1],
                      'anchor': anchor, 'seed_components': rich_crops[slot]['components'],
                      'visible_source_pixels': int(len(sy))})
    return frames, crops

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sheet', type=Path)
    parser.add_argument('--stage-bgm', type=Path)
    parser.add_argument('--ending-bgm', type=Path)
    args = parser.parse_args()
    folder = ROOT / 'art/source_sheets/sanae'
    folder.mkdir(parents=True, exist_ok=True)
    (folder / '.gdignore').touch()
    source = folder / 'sanae.png'
    if args.sheet:
        source.write_bytes(args.sheet.read_bytes())
    assert sha(source) == SOURCE_SHA, 'Rebuild only the reviewed original attachment'
    poses, crops = extract_sanae(source)
    output = ROOT / 'output/sanae-4-23/assets'
    output.mkdir(parents=True, exist_ok=True)
    destination = ROOT / 'art/sanae'
    destination.mkdir(parents=True, exist_ok=True)
    for index, pose in enumerate(poses):
        path = destination / f'frame_{index:02d}.png'
        pose.save(path)
        write_texture_import(path)
        crops[index]['frame_sha256'] = sha(path)
    contact_sheet('sanae', poses, output / 'sanae-source-poses.png')
    ys, _ = np.where(np.array(poses[0])[:, :, 3] >= 128)
    record = {'kind': 'sanae_boss', 'folder': 'art/sanae', 'frame_count': 24,
              'source_pose_count': 24, 'source': 'user_transparent_sheet_individual_crops',
              'source_sheet': str(source.relative_to(ROOT)), 'source_size': list(Image.open(source).size),
              'original_filename': SOURCE_NAME,
              'original_sha256': sha(source), 'source_sha256': sha(source),
              'canvas': list(CANVAS), 'pivot': list(PIVOT),
              'idle_height': int(ys.max()-ys.min()+1), 'idle_bottom': int(ys.max()+1),
              'runtime_source_slots': list(range(24)), 'seed_alpha': LAYOUT['seed_alpha'],
              'calibration_seed_alpha': CALIBRATION_ALPHA, 'source_alpha_range': [0, 254],
              'texture_import': {'compress_mode': 0, 'fix_alpha_border': False,
                                 'premult_alpha': False, 'mipmaps': False}}
    audio = []
    for role in ['stage', 'ending']:
        path = ROOT / f'audio/bgm/touhou/4-23-{role}.mp3'
        supplied = getattr(args, role+'_bgm')
        if supplied:
            path.write_bytes(supplied.read_bytes())
        write_audio_import(path)
        audio.append({'role': role, 'path': str(path.relative_to(ROOT)),
                      'source_name': '4-23道中.mp3' if role == 'stage' else '4-23终末.mp3',
                      'source_sha256': sha(path)})
    method = 'Exact positive-alpha source RGBA owned once; richer32-alpha effect/component ownership and reviewed overlap seams, separately calibrated240-alpha opaque foot anchors; translation only, no rotation, mirroring, resampling, pixel deletion or recoloring.'
    (folder / 'manifest.json').write_text(json.dumps({'method': method, 'sprite': dict(record, individual_crops=crops, layout=LAYOUT),
        'reviewed_overlap': {'bounds': [460, 850, 503, 910], 'green_hair_slot': 19,
                             'upper_blue_white_bounds': [460, 850, 503, 888], 'upper_blue_white_slot': 20,
                             'source_pixels_changed': False}, 'audio': audio}, ensure_ascii=False, indent=2)+'\n')
    (folder / 'animation_source_record.json').write_text(json.dumps(record, indent=2)+'\n')
    meta = ROOT / 'art/touhou_boss_animation_sources.json'
    sources = json.loads(meta.read_text())
    sources = [old for old in sources if old['kind'] != 'sanae_boss'] + [record]
    meta.write_text(json.dumps(sources, ensure_ascii=False, indent=2)+'\n')
    print('Sanae24 original poses:', record['idle_height'], record['idle_bottom'], record['source_sha256'])

if __name__ == '__main__':
    main()
