#!/usr/bin/env python3
"""Lossless ownership/translation of the supplied 24 transparent Kanako poses."""
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

# Reviewed against the supplied sheet: every pose is one alpha>32 body, and the
# column gaps are midpoints between neighbouring body bounds, not the 256px grid
# (row 1's arrow and row 3's crystals cross those grid lines).
LAYOUT = {'rows': [129, 388, 639, 892],
          'centers': [[131, 387, 644, 900, 1156, 1412],
                      [132, 395, 685, 942, 1191, 1429],
                      [139, 399, 654, 918, 1175, 1413],
                      [125, 391, 668, 919, 1171, 1411]],
          'gaps': [[0, 274, 526, 785, 1039, 1299, 1536],
                   [0, 250, 525, 811, 1075, 1320, 1536],
                   [0, 279, 530, 790, 1059, 1298, 1536],
                   [0, 267, 528, 808, 1038, 1293, 1536]],
          'row_gaps': [0, 259, 512, 765, 1024],
          # Detached arcs, sparks and crystals keep their own pose by gap.
          'seed_alpha': 32, 'soft_component_gaps': True}
CALIBRATION_ALPHA = 240
SOURCE_SHA = 'c44ba7f90de7c8ffd80bf03aa2bf39660c58e61544d56644f77da2df0e2b667b'
SOURCE_NAME = 'Purple-Haired Shrine Maiden Sprite Sheet.png'
AUDIO_SHA = {'stage': 'cbb36dc946549decf88b244b22be882f06bae532f8983249de5fa9d2297db303',
             'ending': '47f4098e29b6bf5eb9860d1a2464580883a11f59853b8948d87f255870887595'}


def extract_kanako(source):
    """Restore exact RGBA from rich ownership, anchored by the opaque bodies.

    Rich alpha>32 seeds own the red arrow, mirror rings, crystals and aura
    strokes; the separate alpha>240 pass finds the sandal line so faint glows
    below the feet cannot move the pivot. No source pixel is changed.
    """
    rgba = np.array(Image.open(source).convert('RGBA'))
    high = copy.deepcopy(LAYOUT)
    high['seed_alpha'] = CALIBRATION_ALPHA
    _, calibrated = extract('kanako', source, high)
    rich, rich_crops = extract('kanako', source, LAYOUT)
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
    folder = ROOT / 'art/source_sheets/kanako'
    folder.mkdir(parents=True, exist_ok=True)
    (folder / '.gdignore').touch()
    source = folder / 'kanako.png'
    if args.sheet:
        source.write_bytes(args.sheet.read_bytes())
    assert sha(source) == SOURCE_SHA, 'Rebuild only the reviewed original attachment'
    poses, crops = extract_kanako(source)
    output = ROOT / 'output/kanako-4-24/assets'
    output.mkdir(parents=True, exist_ok=True)
    destination = ROOT / 'art/kanako'
    destination.mkdir(parents=True, exist_ok=True)
    for index, pose in enumerate(poses):
        path = destination / f'frame_{index:02d}.png'
        pose.save(path)
        write_texture_import(path)
        crops[index]['frame_sha256'] = sha(path)
    contact_sheet('kanako', poses, output / 'kanako-source-poses.png')
    ys, _ = np.where(np.array(poses[0])[:, :, 3] >= 128)
    record = {'kind': 'kanako_boss', 'folder': 'art/kanako', 'frame_count': 24,
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
        path = ROOT / f'audio/bgm/touhou/4-24-{role}.mp3'
        supplied = getattr(args, role+'_bgm')
        if supplied:
            path.write_bytes(supplied.read_bytes())
        assert sha(path) == AUDIO_SHA[role], 'Keep the supplied music byte-for-byte'
        write_audio_import(path)
        audio.append({'role': role, 'path': str(path.relative_to(ROOT)),
                      'source_name': '4-24道中.mp3' if role == 'stage' else '4-24终末.mp3',
                      'source_sha256': sha(path)})
    method = 'Exact positive-alpha source RGBA owned once; 32-alpha body/effect ownership with reviewed per-row gaps for detached arcs and crystals, separately calibrated 240-alpha opaque foot anchors; translation only, no rotation, mirroring, resampling, pixel deletion or recoloring.'
    (folder / 'manifest.json').write_text(json.dumps({'method': method, 'sprite': dict(record, individual_crops=crops, layout=LAYOUT),
        'audio': audio}, ensure_ascii=False, indent=2)+'\n')
    (folder / 'animation_source_record.json').write_text(json.dumps(record, indent=2)+'\n')
    meta = ROOT / 'art/touhou_boss_animation_sources.json'
    sources = json.loads(meta.read_text())
    sources = [old for old in sources if old['kind'] != 'kanako_boss'] + [record]
    meta.write_text(json.dumps(sources, ensure_ascii=False, indent=2)+'\n')
    print('Kanako24 original poses:', record['idle_height'], record['idle_bottom'], record['source_sha256'])


if __name__ == '__main__':
    main()
