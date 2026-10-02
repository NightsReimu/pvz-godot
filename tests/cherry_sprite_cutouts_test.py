"""Verify irregular sheet coverage, exact original pixels and pose ownership."""
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    records = json.loads((ROOT / 'art/source_sheets/cherry_refresh/manifest.json').read_text())['sets']
    assert {r['kind'] for r in records} == {'letty_boss', 'chen_boss', 'alice_boss', 'lily_white_boss', 'youmu_boss', 'yuyuko_boss', 'ran_boss', 'yukari_boss'}
    checked = 0
    for record in records:
        source_path = ROOT / record['source_sheet']
        assert hashlib.sha256(source_path.read_bytes()).hexdigest() == record['source_sha256'] == record['original_sha256']
        source = np.array(Image.open(source_path).convert('RGBA'))
        coverage = np.zeros(source.shape[:2], dtype=np.uint8)
        seen = set()
        for index, slot in enumerate(record['runtime_source_slots']):
            path = ROOT / record['folder'] / f'frame_{index:02d}.png'
            image = np.array(Image.open(path).convert('RGBA'))
            alpha = image[:, :, 3]
            assert image.shape == (384, 512, 4), path
            assert not alpha[:2].any() and not alpha[-2:].any(), (path, 'vertical clipping')
            assert not alpha[:, :2].any() and not alpha[:, -2:].any(), (path, 'horizontal clipping')
            _, _, stats, _ = cv2.connectedComponentsWithStats((alpha > record['seed_alpha']).astype('uint8'), 8)
            assert sum(s[4] > 10000 for s in stats[1:]) == 1, (path, 'second figure or missing figure')
            ys, xs = np.where(alpha > 0)
            crop = record['individual_crops'][slot]
            sx = xs + crop['anchor'][0] - record['pivot'][0]
            sy = ys + crop['anchor'][1] - record['pivot'][1]
            assert np.array_equal(image[ys, xs], source[sy, sx]), (path, 'original pixels / alpha / facing changed')
            if slot not in seen:
                coverage[sy, sx] += 1
                seen.add(slot)
            checked += 1
        assert len(seen) == record['source_pose_count'], 'all supplied poses must be retained'
        assert np.all(coverage[source[:, :, 3] > 0] == 1), (record['kind'], 'lost pixels or duplicated neighboring content')
        first = np.array(Image.open(ROOT / record['folder'] / 'frame_00.png'))[:, :, 3]
        ys, _ = np.where(first >= 128)
        assert ys.max() - ys.min() + 1 == record['idle_height']
        assert ys.max() + 1 == record['idle_bottom']
    print(f'PASS: {checked} individually owned frames; all 192 original poses and RGBA pixels retained exactly once')


if __name__ == '__main__':
    main()
