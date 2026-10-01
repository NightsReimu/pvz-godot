"""Guard against a second figure, edge clipping and lost wide spell poses."""
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    manifest = json.loads((ROOT / 'art/source_sheets/scarlet_refresh/manifest.json').read_text())
    checked = 0
    for record in manifest['sets']:
        source = ROOT / record['source_sheet']
        assert hashlib.sha256(source.read_bytes()).hexdigest() == record['source_sha256']
        for index in range(24):
            path = ROOT / record['folder'] / f'frame_{index:02d}.png'
            image = np.array(Image.open(path))
            alpha = image[:, :, 3]
            assert image.shape == (384, 512, 4), path
            assert not alpha[:2].any() and not alpha[-2:].any(), f'{path}: vertical edge clipping'
            assert not alpha[:, :2].any() and not alpha[:, -2:].any(), f'{path}: horizontal edge clipping'
            _, _, stats, _ = cv2.connectedComponentsWithStats((alpha > 8).astype('uint8'), 8)
            bodies = sum(s[4] > 12000 for s in stats[1:])
            assert bodies == 1, f'{path}: expected one figure, found {bodies}'
            yy, xx = np.where(alpha >= 128)
            assert yy.max() - yy.min() >= 140, f'{path}: missing body / effect-only frame'
            checked += 1
    # Cirno's giant fan crosses the original column boundary: retain its full
    # width rather than clipping it to a 256px cell. Sakuya's slash likewise.
    for name, index, width in [('cirno', 19, 330), ('sakuya', 8, 250)]:
        alpha = np.array(Image.open(ROOT / f'art/{name}/frame_{index:02d}.png'))[:, :, 3]
        ys, xs = np.where(alpha > 8)
        assert xs.max() - xs.min() >= width, f'{name}: wide effect was clipped'
    for path in (ROOT / 'art/touhou_pose_extras/rumia').glob('*.png'):
        assert Image.open(path).getchannel('A').getbbox(), path
    records = {r['kind'].removesuffix('_boss'): r for r in manifest['sets']}
    for name, slot, point in [('daiyousei', 7, (278, 371)),
                              ('patchouli', 7, (250, 337)),
                              ('sakuya', 9, (774, 342))]:
        record = records[name]
        source = Image.open(ROOT / record['source_sheet'])
        assert source.getpixel(point)[3] > 180
        for frame_index, present in [(slot, True), (slot - 1, False)]:
            anchor = record['individual_crops'][frame_index]['anchor']
            local = tuple(p + pivot - a for p, pivot, a in zip(point, record['pivot'], anchor))
            frame = Image.open(ROOT / record['folder'] / f'frame_{frame_index:02d}.png')
            assert (frame.getpixel(local)[3] > 180) == present, f'{name}: neighboring pose particle contamination'
    print(f'PASS: {checked} individual boss frames, one figure per frame, transparent borders, wide effects and source provenance')


if __name__ == '__main__':
    main()
