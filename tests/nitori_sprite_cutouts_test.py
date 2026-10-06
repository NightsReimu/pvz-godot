"""Verify Nitori's supplied pixels, haze clearing, transparent frames, anchors and BGM."""

import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHA256 = '02722d6496da48c2963d6415548a3c41420e3869dd86bfe5e6a70f61901220a4'
AUDIO_SHA256 = {
    'stage': 'd053d5aaccde2d6621181027df9e6e635d1eb74103d08bd3951c1f9bb63ce181',
    'ending': '57c63b137853fa7f25c1c3cf2bb39e3bdd9ffa29f84b61513b8850d975b50985',
}


def main():
    manifest = json.loads((ROOT / 'art/source_sheets/nitori/manifest.json').read_text())
    record = manifest['sprite']
    source_path = ROOT / record['source_sheet']
    digest = hashlib.sha256(source_path.read_bytes()).hexdigest()
    assert digest == SOURCE_SHA256 == record['original_sha256'] == record['source_sha256']
    assert (ROOT / 'art/source_sheets/nitori/.gdignore').exists()
    source = np.array(Image.open(source_path).convert('RGBA'))
    assert source.shape == (1024, 1536, 4)
    # Only the near-invisible alpha 1-9 haze is removed before ownership.
    assert record['haze_alpha_below'] == 10
    haze = source[:, :, 3] < 10
    assert int(np.sum(haze & (source[:, :, 3] > 0))) == record['haze_pixels_cleared'] > 0
    source[haze] = 0
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
            assert int(opaque_y.max() - opaque_y.min() + 1) == record['idle_height'] == 233
            assert int(opaque_y.max() + 1) == record['idle_bottom'] == 319
    assert np.all(coverage[source[:, :, 3] > 0] == 1), 'lost or duplicated source pixels'
    assert not coverage[source[:, :, 3] == 0].any(), 'transparent haze was adopted'
    # Both long water blasts stay with their caster rather than a neighbor.
    for slot in (8, 20):
        crop = record['individual_crops'][slot]
        assert crop['bounds'][2] - crop['bounds'][0] > 270, ('water blast detached', slot)
    for audio in manifest['audio']:
        path = ROOT / audio['path']
        assert path.stat().st_size > 1000000
        assert hashlib.sha256(path.read_bytes()).hexdigest() == audio['source_sha256'] == AUDIO_SHA256[audio['role']]
        assert 'loop=true' in Path(str(path) + '.import').read_text()
    assert [audio['role'] for audio in manifest['audio']] == ['stage', 'ending']
    print('PASS: 24 Nitori poses retain supplied upright RGBA once, haze stays out, blasts keep their caster, feet align, and both BGM hashes match')


if __name__ == '__main__':
    main()
