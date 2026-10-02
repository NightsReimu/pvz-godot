#!/usr/bin/env python3
"""Copy individually owned poses from current and earlier supplied sheets.

The user's images already contain alpha. Preserve their pixels without
background regeneration, resampling or mirroring. Pose locations, detached
particle ownership and foot anchors are reviewed separately for each sheet.
"""

import argparse
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

from import_scarlet_sprite_cutouts import CANVAS, PIVOT, ROOT, contact_sheet

LAYOUTS = {
    'wriggle': {
        'rows': [144, 393, 642, 897],
        'centers': [[147, 391, 642, 887, 1136, 1394],
                    [143, 416, 645, 890, 1144, 1395],
                    [137, 385, 627, 884, 1136, 1396],
                    [127, 409, 680, 900, 1142, 1402]],
        'gaps': [[0, 274, 523, 780, 1020, 1280, 1536],
                 [0, 283, 543, 772, 1020, 1270, 1536],
                 [0, 260, 512, 755, 1018, 1272, 1536],
                 [0, 249, 557, 793, 1023, 1264, 1536]],
        'order': list(range(24)),
    },
    'mystia': {
        'rows': [126, 386, 638, 885],
        'centers': [[126, 372, 632, 881, 1147, 1401],
                    [124, 393, 618, 904, 1150, 1397],
                    [126, 392, 642, 897, 1163, 1407],
                    [155, 493, 858, 1137, 1406]],
        'gaps': [[0, 249, 512, 768, 1028, 1284, 1536],
                 [0, 246, 497, 763, 1025, 1270, 1536],
                 [0, 245, 525, 767, 1016, 1290, 1536],
                 [0, 315, 689, 1027, 1259, 1536]],
        # The last row really has five poses; frame 23 reuses recovery 14.
        'order': list(range(23)) + [14],
    },
    'keine': {
        'rows': [153, 422, 694, 967],
        'centers': [[120, 354, 590, 831, 1090, 1330],
                    [125, 393, 631, 864, 1092, 1338],
                    [124, 369, 605, 838, 1084, 1333],
                    [121, 413, 685, 884, 1099, 1332]],
        'gaps': [[0, 242, 476, 721, 974, 1230, 1448],
                 [0, 231, 513, 758, 979, 1216, 1448],
                 [0, 253, 494, 725, 956, 1217, 1448],
                 [0, 240, 567, 803, 992, 1207, 1448]],
        'order': list(range(24)),
    },
    # Earlier release sliced Mokou's increasingly displaced last row on a
    # fixed grid, leaving an effect-only 21 and a neighboring figure in 22.
    'mokou': {
        'rows': [146, 393, 638, 895],
        'centers': [[120, 367, 622, 896, 1165, 1416],
                    [141, 386, 651, 912, 1160, 1417],
                    [131, 381, 634, 886, 1146, 1418],
                    [155, 440, 777, 1063, 1241, 1433]],
        'gaps': [[0, 246, 507, 787, 1027, 1291, 1536],
                 [0, 253, 514, 791, 1024, 1285, 1536],
                 [0, 260, 515, 757, 1026, 1287, 1536],
                 [0, 282, 598, 968, 1158, 1336, 1536]],
        'order': list(range(24)),
    },
}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def extract(name, source):
    rgba = np.array(Image.open(source).convert('RGBA'))
    alpha = rgba[:, :, 3]
    config = LAYOUTS[name]
    # Mystia 07 and 08 touch only through a faint feather glow. Thresholding
    # the ownership seeds separates them; their original soft alpha is restored
    # afterwards rather than cut away along a rectangular grid boundary.
    mask = (alpha > 32).astype('uint8')
    count, labels, stats, centers = cv2.connectedComponentsWithStats(mask, 8)
    bodies = [label for label in range(1, count) if stats[label, 4] > 10000]
    seeds = [(x, y) for row, y in zip(config['centers'], config['rows']) for x in row]
    assert len(bodies) == len(seeds), (name, len(bodies), len(seeds))
    main = []
    for x, y in seeds:
        label = min(bodies, key=lambda i: np.linalg.norm(centers[i] - [x, y]))
        assert label not in main, (name, x, y)
        main.append(label)
    owners = np.full(count, -1, dtype='int16')
    for slot, label in enumerate(main):
        owners[label] = slot
    for label in range(1, count):
        if owners[label] >= 0:
            continue
        x, y = centers[label]
        row = min(range(4), key=lambda r: abs(y - config['rows'][r]))
        gaps = config['gaps'][row]
        col = next(c for c in range(len(gaps) - 1) if gaps[c] <= x < gaps[c + 1])
        owners[label] = sum(map(len, config['centers'][:row])) + col
    ownership = owners[labels]
    _, nearest = cv2.distanceTransformWithLabels(1 - mask, cv2.DIST_L2, 5,
                                                labelType=cv2.DIST_LABEL_PIXEL)
    nearest_owner = np.full(int(nearest.max()) + 1, -1, dtype='int16')
    ys, xs = np.where(mask > 0)
    nearest_owner[nearest[ys, xs]] = ownership[ys, xs]
    ownership = np.where(mask > 0, ownership, nearest_owner[nearest])
    poses, crops = [], []
    for slot, label in enumerate(main):
        body = labels == label
        body_y, _ = np.where(body)
        foot_y = int(body_y.max()) + 1
        feet = body[max(int(body_y.min()), foot_y - 15):foot_y] & (alpha[max(int(body_y.min()), foot_y - 15):foot_y] >= 128)
        feet_x = np.where(feet.sum(axis=0) >= 3)[0]
        if not len(feet_x):
            _, feet_x = np.where(feet)
        anchor_x = int(round((int(feet_x.min()) + int(feet_x.max())) / 2))
        selected = (ownership == slot) & (alpha > 0)
        sy, sx = np.where(selected)
        bounds = [int(sx.min()), int(sy.min()), int(sx.max()) + 1, int(sy.max()) + 1]
        pixels = rgba[bounds[1]:bounds[3], bounds[0]:bounds[2]].copy()
        pixels[~selected[bounds[1]:bounds[3], bounds[0]:bounds[2]]] = 0
        patch = Image.fromarray(pixels)
        dest = (PIVOT[0] + bounds[0] - anchor_x, PIVOT[1] + bounds[1] - foot_y)
        assert min(dest) >= 2, (name, slot, bounds, dest)
        assert dest[0] + patch.width < CANVAS[0] - 1, (name, slot, bounds, dest)
        assert dest[1] + patch.height < CANVAS[1] - 1, (name, slot, bounds, dest)
        canvas = Image.new('RGBA', CANVAS)
        canvas.paste(patch, dest)
        poses.append(canvas)
        crops.append({'source_slot': slot, 'bounds': bounds, 'anchor': [anchor_x, foot_y],
                      'components': int(np.sum(owners == slot))})
    return poses, crops


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--inputs', type=Path, help='name and supplied image path TSV; omit to rebuild committed sources')
    args = parser.parse_args()
    folder = ROOT / 'art/source_sheets/imperishable_refresh'
    folder.mkdir(parents=True, exist_ok=True)
    (folder / '.gdignore').touch()
    output = ROOT / 'output/imperishable-refresh'
    output.mkdir(parents=True, exist_ok=True)
    inputs = [line.split('\t') for line in args.inputs.read_text().splitlines()] if args.inputs else [(name, str(folder / f'{name}.png')) for name in LAYOUTS]
    records = []
    for name, source in inputs:
        target = folder / f'{name}.png'
        target.write_bytes(Path(source).read_bytes())
        poses, crops = extract(name, target)
        order = LAYOUTS[name]['order']
        frames = [poses[slot] for slot in order]
        for i, frame in enumerate(frames):
            frame.save(ROOT / f'art/{name}/frame_{i:02d}.png')
        contact_sheet(name, poses, output / f'{name}-source-poses.png')
        contact_sheet(name, frames, output / f'{name}-runtime-frames.png')
        yy, _ = np.where(np.array(frames[0])[:, :, 3] >= 128)
        height, bottom = int(yy.max() - yy.min() + 1), int(yy.max() + 1)
        print(name, 'idle_height', height, 'idle_bottom', bottom)
        records.append({'kind': name + '_boss', 'folder': 'art/' + name,
                        'frame_count': 24, 'source_pose_count': len(poses),
                        'source': 'user_transparent_sheet_individual_crops',
                        'source_sheet': str(target.relative_to(ROOT)),
                        'original_sha256': sha256(target), 'source_sha256': sha256(target),
                        'canvas': list(CANVAS), 'pivot': list(PIVOT),
                        'idle_height': height, 'idle_bottom': bottom,
                        'runtime_source_slots': order, 'individual_crops': crops})
    (folder / 'manifest.json').write_text(json.dumps({
        'method': 'Original user-supplied alpha and pixels; individual component ownership and foot anchors; no generation, resampling, mirroring or fixed-grid slicing.',
        'sets': records}, indent=2) + '\n')
    metadata = ROOT / 'art/touhou_boss_animation_sources.json'
    old = json.loads(metadata.read_text())
    updates = {r['kind']: {k: v for k, v in r.items() if k != 'individual_crops'} for r in records}
    previous_kinds = {r['kind'] for r in old}
    merged = [updates.get(r['kind'], r) for r in old]
    merged.extend(r for kind, r in updates.items() if kind not in previous_kinds)
    metadata.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    main()
