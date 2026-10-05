"""The supplied Suika image is retained once, pixel for pixel, in 24 poses."""
import hashlib
import json
from pathlib import Path
import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

def main():
    record = json.loads((ROOT / 'art/source_sheets/suika/manifest.json').read_text())
    path = ROOT / record['source_sheet']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == record['original_sha256'] == record['source_sha256']
    source = np.array(Image.open(path).convert('RGBA'))
    coverage = np.zeros(source.shape[:2], dtype='uint8')
    for i, crop in enumerate(record['individual_crops']):
        frame = np.array(Image.open(ROOT / record['folder'] / f'frame_{i:02d}.png'))
        alpha = frame[:, :, 3]
        assert frame.shape == (384, 512, 4)
        assert not alpha[:2].any() and not alpha[-2:].any() and not alpha[:, :2].any() and not alpha[:, -2:].any()
        _, _, stats, _ = cv2.connectedComponentsWithStats((alpha > 32).astype('uint8'), 8)
        assert sum(s[4] > 10000 for s in stats[1:]) == 1, ('mixed figures', i)
        yy, xx = np.where(alpha > 0)
        sx = xx + crop['anchor'][0] - record['pivot'][0]
        sy = yy + crop['anchor'][1] - record['pivot'][1]
        assert np.array_equal(frame[yy, xx], source[sy, sx]), ('modified pixels', i)
        coverage[sy, sx] += 1
    assert np.all(coverage[source[:, :, 3] > 0] == 1), 'lost or duplicated source pixels'
    bgm = ROOT / 'audio/th075_suika_boss.mp3'
    assert hashlib.sha256(bgm.read_bytes()).hexdigest() == '0909cb78a53f0816cf83079abe386cc0f4c89c561f3d9c1faa25e05812191594'
    print('PASS: 24 Suika poses, exact alpha/source coverage and supplied BGM SHA256')

if __name__ == '__main__': main()
