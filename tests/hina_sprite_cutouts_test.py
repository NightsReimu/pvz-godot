"""Verify Hina's complete source pixels, transparent frames, anchors and BGM."""

import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHA256 = 'bb03ae975a2b16390bdfadc784b883d3f5bede625337c778b08c7f970b640784'
AUDIO_SHA256 = {
    'stage': '50b4c2344cd13156dea9a77fe2ffe7b14d3af6a63bfa70c458a4a3de0162c576',
    'ending': '809eea7c6047508b1be27770121dc6533cd78ac77f925747b37259cf0cbcaf2c',
}


def main():
    manifest = json.loads((ROOT / 'art/source_sheets/hina/manifest.json').read_text())
    record = manifest['sprite']
    source_path = ROOT / record['source_sheet']
    digest = hashlib.sha256(source_path.read_bytes()).hexdigest()
    assert digest == SOURCE_SHA256 == record['original_sha256'] == record['source_sha256']
    source = np.array(Image.open(source_path).convert('RGBA'))
    assert source.shape == (1024, 1536, 4)
    coverage = np.zeros(source.shape[:2], dtype='uint8')
    assert len(record['individual_crops']) == record['frame_count'] == 24
    assert record['runtime_source_slots'] == list(range(24))
    assert record['canvas'] == [512, 384] and record['pivot'] == [256, 320]
    assert len(list((ROOT / record['folder']).glob('frame_*.png'))) == 24
    for i, crop in enumerate(record['individual_crops']):
        frame = np.array(Image.open(ROOT / record['folder'] / f'frame_{i:02d}.png'))
        alpha = frame[:, :, 3]
        assert frame.shape == (384, 512, 4)
        assert not alpha[:2].any() and not alpha[-2:].any()
        assert not alpha[:, :2].any() and not alpha[:, -2:].any()
        _, _, stats, _ = cv2.connectedComponentsWithStats((alpha > 32).astype('uint8'), 8)
        bodies = [s for s in stats[1:] if s[4] > 10000]
        assert len(bodies) == 1, ('mixed figures', i)
        assert int(bodies[0][1] + bodies[0][3]) == 320, ('foot drift', i)
        yy, xx = np.where(alpha > 0)
        sx = xx + crop['anchor'][0] - record['pivot'][0]
        sy = yy + crop['anchor'][1] - record['pivot'][1]
        assert np.array_equal(frame[yy, xx], source[sy, sx]), ('modified RGBA pixels', i)
        coverage[sy, sx] += 1
        if i == 0:
            opaque_y, _ = np.where(alpha >= 128)
            assert int(opaque_y.max() - opaque_y.min() + 1) == record['idle_height']
            assert int(opaque_y.max() + 1) == record['idle_bottom'] == 319
    assert np.all(coverage[source[:, :, 3] > 0] == 1), 'lost or duplicated source pixels'
    assert not coverage[source[:, :, 3] == 0].any(), 'transparent RGB backdrop was adopted'
    for audio in manifest['audio']:
        path = ROOT / audio['path']
        assert path.stat().st_size > 1000000
        assert hashlib.sha256(path.read_bytes()).hexdigest() == audio['source_sha256'] == AUDIO_SHA256[audio['role']]
        assert 'loop=true' in Path(str(path) + '.import').read_text()
    assert [audio['role'] for audio in manifest['audio']] == ['stage', 'ending']
    print('PASS: 24 Hina poses retain original upright RGBA pixels once, feet align, and both supplied BGM hashes match')


if __name__ == '__main__':
    main()
