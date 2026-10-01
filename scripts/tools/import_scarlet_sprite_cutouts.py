#!/usr/bin/env python3
"""Extract individually owned poses from transparent, irregular user sheets.

Background extraction is performed by imagegen before this tool runs. This
tool only assigns whole alpha components to poses and copies the selected
pixels onto stable canvases. It never scales, mirrors, or invents inbetweens.
"""

import argparse
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
CANVAS = (512, 384)
PIVOT = (256, 320)
BOSSES = ('rumia', 'daiyousei', 'cirno', 'meiling', 'koakuma',
          'patchouli', 'sakuya', 'remilia', 'flandre')
# The slash-only slot, two spare strides and five fallen poses are separate, never
# substituted for a living boss. Runtime keeps its 24-frame resource contract.
RUMIA_ORDER = [0, 1, 2, 3, 4, 5, 6, 7, 9, 12, 13, 14,
               18, 19, 18, 15, 16, 17, 20, 21, 22, 29, 22, 23]
# Visually reviewed gaps for DETACHED components only. In particular, the
# butterfly left of Daiyousei 07, moon left of Patchouli 07 and knife trail
# left of Sakuya 09 must not be donated to the preceding pose.
PARTICLE_GAPS = {
    'rumia': [[0, 280, 535, 790, 1030, 1290, 1536],
              [0, 290, 537, 826, 1030, 1288, 1536],
              [0, 282, 542, 784, 1025, 1290, 1536],
              [0, 282, 550, 765, 990, 1290, 1536],
              [0, 282, 535, 790, 1040, 1290, 1536]],
    'daiyousei': [[0, 260, 530, 785, 1040, 1300, 1536],
                  [0, 258, 548, 790, 1020, 1280, 1536],
                  [0, 260, 520, 780, 1030, 1300, 1536],
                  [0, 247, 540, 811, 1030, 1280, 1536]],
    'cirno': [[0, 250, 510, 770, 1020, 1280, 1536],
              [0, 233, 470, 781, 1018, 1280, 1536],
              [0, 275, 520, 766, 1018, 1278, 1536],
              [0, 262, 617, 820, 1050, 1280, 1536]],
    'meiling': [[0, 280, 530, 785, 1040, 1300, 1536],
                [0, 280, 503, 764, 1008, 1300, 1536],
                [0, 280, 530, 785, 1040, 1300, 1536],
                [0, 260, 518, 788, 1046, 1286, 1536]],
    'koakuma': [[0, 275, 520, 780, 1020, 1280, 1536],
                [0, 252, 531, 780, 1010, 1274, 1536],
                [0, 270, 520, 760, 1000, 1270, 1536],
                [0, 260, 525, 785, 1030, 1260, 1536]],
    'patchouli': [[0, 250, 510, 770, 1020, 1300, 1536],
                  [0, 241, 500, 767, 1030, 1280, 1536],
                  [0, 260, 515, 765, 1030, 1280, 1536],
                  [0, 270, 535, 802, 1040, 1284, 1536]],
    'sakuya': [[0, 250, 510, 770, 1030, 1295, 1536],
               [0, 249, 490, 764, 1030, 1290, 1536],
               [0, 258, 510, 796, 1030, 1295, 1536],
               [0, 265, 540, 785, 1035, 1280, 1536]],
    'remilia': [[0, 260, 500, 760, 1025, 1300, 1536],
                [0, 246, 490, 787, 1033, 1310, 1536],
                [0, 255, 508, 758, 1048, 1300, 1536],
                [0, 268, 530, 775, 1040, 1290, 1536]],
    'flandre': [[0, 250, 510, 760, 1020, 1290, 1536],
                [0, 245, 499, 767, 1020, 1320, 1536],
                [0, 248, 513, 770, 1030, 1300, 1536],
                [0, 255, 513, 765, 1020, 1280, 1536]],
}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def extract(name, source):
    rgba = np.array(Image.open(source).convert('RGBA'))
    alpha = rgba[:, :, 3]
    mask = (alpha > 8).astype('uint8')
    # Two separate Patchouli poses touch through a faint crescent glow.
    # This separator is in their visual gap, outside both bodies/hair.
    if name == 'patchouli':
        mask[768:, 1284:1286] = 0
    count, labels, stats, centroids = cv2.connectedComponentsWithStats(mask, 8)
    rows = 5 if name == 'rumia' else 4
    row_centers = [115, 330, 540, 750, 945] if rows == 5 else [128, 384, 640, 896]
    # Seeds locate individual figures, not crop boundaries. Large connected
    # weapons/auras stay with their body even when crossing a nominal cell.
    main = {}
    for label in range(1, count):
        if stats[label, cv2.CC_STAT_AREA] < 10000:
            continue
        x, y = centroids[label]
        row = min(range(rows), key=lambda r: abs(y - row_centers[r]))
        col = min(5, int(x / 256))
        slot = row * 6 + col
        if slot not in main or stats[label, 4] > stats[main[slot], 4]:
            main[slot] = label
    if name == 'rumia':
        # The black slash is intentionally a standalone component/asset.
        main[8] = max((i for i in range(1, count)
                       if 540 < centroids[i, 0] < 800 and 280 < centroids[i, 1] < 400),
                      key=lambda i: stats[i, 4])
    assert len(main) == rows * 6, (name, sorted(main))
    owners = np.full(count, -1, dtype='int16')
    for slot, label in main.items():
        owners[label] = slot
    for label in range(1, count):
        if owners[label] >= 0:
            continue
        x, y = centroids[label]
        row = min(range(rows), key=lambda r: abs(y - row_centers[r]))
        gaps = PARTICLE_GAPS[name][row]
        col = next(c for c in range(6) if gaps[c] <= x < gaps[c + 1])
        owners[label] = row * 6 + col
    ownership = owners[labels]
    # Preserve faint alpha around each extracted component without adopting
    # the invisible RGB backdrop as visible sprite pixels.
    _, nearest = cv2.distanceTransformWithLabels(1 - mask, cv2.DIST_L2, 5,
                                                labelType=cv2.DIST_LABEL_PIXEL)
    nearest_owner = np.full(int(nearest.max()) + 1, -1, dtype='int16')
    ys, xs = np.where(mask > 0)
    nearest_owner[nearest[ys, xs]] = ownership[ys, xs]
    ownership = np.where(mask > 0, ownership, nearest_owner[nearest])
    poses, records = [], []
    for slot in range(rows * 6):
        label = main[slot]
        body_pixels = labels == label
        body_y, _ = np.where(body_pixels)
        foot_y = int(body_y.max()) + 1
        if name == 'rumia' and slot == 22:
            foot_y = 843
        # Anchor at the feet, rather than the center of a wide weapon or wing.
        feet = body_pixels[max(int(body_y.min()), foot_y - 15):foot_y] & (alpha[max(int(body_y.min()), foot_y - 15):foot_y] >= 128)
        feet_x = np.where(feet.sum(axis=0) >= 3)[0]
        if not len(feet_x):
            _, feet_x = np.where(feet)
        anchor_x = int(round((int(feet_x.min()) + int(feet_x.max())) / 2))
        if name == 'rumia' and slot == 8:
            anchor_x, foot_y = 680, 435
        selected = (ownership == slot) & (alpha > 0)
        sy, sx = np.where(selected)
        bounds = [int(sx.min()), int(sy.min()), int(sx.max()) + 1, int(sy.max()) + 1]
        pixels = rgba[bounds[1]:bounds[3], bounds[0]:bounds[2]].copy()
        keep = selected[bounds[1]:bounds[3], bounds[0]:bounds[2]]
        pixels[~keep] = 0
        patch = Image.fromarray(pixels)
        dest = (PIVOT[0] + bounds[0] - anchor_x, PIVOT[1] + bounds[1] - foot_y)
        assert dest[0] >= 2 and dest[1] >= 2, (name, slot, bounds, dest)
        assert dest[0] + patch.width < CANVAS[0] - 1, (name, slot, bounds, dest)
        assert dest[1] + patch.height < CANVAS[1] - 1, (name, slot, bounds, dest)
        canvas = Image.new('RGBA', CANVAS)
        canvas.paste(patch, dest)  # no alpha multiplication or resampling
        poses.append(canvas)
        records.append({'source_slot': slot, 'bounds': bounds,
                        'anchor': [anchor_x, foot_y], 'components': int(np.sum(owners == slot))})
    return poses, records


def contact_sheet(name, poses, output):
    scale = 0.54
    w, h = 288, 286
    sheet = Image.new('RGB', (w * 6, h * ((len(poses) + 5) // 6)), '#172531')
    for i, pose in enumerate(poses):
        thumb = pose.resize((round(pose.width * scale), round(pose.height * scale)))
        sheet.paste(thumb, ((i % 6) * w + 6, (i // 6) * h + 6), thumb)
        ImageDraw.Draw(sheet).text(((i % 6) * w + 9, (i // 6) * h + 8), f'{name} {i:02d}', fill='white')
    sheet.save(output)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--inputs', type=Path, help='name, original PNG, transparent cutout TSV; omit to rebuild committed sheets')
    args = parser.parse_args()
    records = []
    source_folder = ROOT / 'art/source_sheets/scarlet_refresh'
    source_folder.mkdir(parents=True, exist_ok=True)
    (source_folder / '.gdignore').touch()
    output = ROOT / 'output/scarlet-refresh'
    output.mkdir(parents=True, exist_ok=True)
    manifest_path = source_folder / 'manifest.json'
    previous = json.loads(manifest_path.read_text())['sets'] if manifest_path.exists() else []
    original_hashes = {r['kind']: r['original_sha256'] for r in previous}
    if args.inputs is not None:
        inputs = [line.split('\t') for line in args.inputs.read_text().splitlines()]
    else:
        inputs = [(name, None, str(source_folder / f'{name}.png')) for name in BOSSES]
    for name, original, cutout in inputs:
        assert name in BOSSES
        target = source_folder / f'{name}.png'
        target.write_bytes(Path(cutout).read_bytes())
        poses, crops = extract(name, target)
        order = RUMIA_ORDER if name == 'rumia' else list(range(24))
        frames = [poses[slot] for slot in order]
        for i, frame in enumerate(frames):
            frame.save(ROOT / f'art/{name}/frame_{i:02d}.png')
        if name == 'rumia':
            extra = ROOT / 'art/touhou_pose_extras/rumia'
            extra.mkdir(parents=True, exist_ok=True)
            poses[8].save(extra / 'dark_slash.png')
            for i, slot in enumerate(range(24, 29)):
                poses[slot].save(extra / f'fallen_{i:02d}.png')
            for i, slot in enumerate([10, 11]):
                poses[slot].save(extra / f'stride_{i:02d}.png')
        contact_sheet(name, poses, output / f'{name}-source-poses.png')
        contact_sheet(name, frames, output / f'{name}-runtime-frames.png')
        alpha = np.array(frames[0])[:, :, 3]
        yy, _ = np.where(alpha >= 128)
        idle_height, idle_bottom = int(yy.max() - yy.min() + 1), int(yy.max() + 1)
        print(name, 'idle_height', idle_height, 'idle_bottom', idle_bottom)
        records.append({'kind': name + '_boss', 'folder': 'art/' + name, 'frame_count': 24,
                        'source': 'user_sheet_imagegen_background_extraction',
                        'source_sheet': str(target.relative_to(ROOT)),
                        'original_sha256': sha256(Path(original)) if original else original_hashes[name + '_boss'], 'source_sha256': sha256(target),
                        'canvas': list(CANVAS), 'pivot': list(PIVOT),
                        'idle_height': idle_height, 'idle_bottom': idle_bottom,
                        'runtime_source_slots': order, 'individual_crops': crops})
    manifest_path.write_text(json.dumps({
        'method': 'Built-in imagegen transparent background extraction; individual alpha-component crops; original direction and pixels retained; no fixed-grid slicing.',
        'prompt': 'Remove only blurred background to transparent alpha; preserve identical canvas, original poses, placement, facing, costumes, detached particles, weapons and spell effects; no redrawing or rearrangement.',
        'sets': records}, indent=2) + '\n')
    metadata = ROOT / 'art/touhou_boss_animation_sources.json'
    old = json.loads(metadata.read_text())
    updates = {r['kind']: {k: v for k, v in r.items() if k != 'individual_crops'} for r in records}
    metadata.write_text(json.dumps([updates.get(r['kind'], r) for r in old], ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    main()
