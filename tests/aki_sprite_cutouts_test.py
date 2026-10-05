"""Verify all Aki frames preserve exactly one ownership of supplied RGBA pixels."""

import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_SOURCE_SHA256 = {
    'shizuha_boss': '950585dc85cf2dc19776448528a2131ad3b10ce1187c62feceaef5339c507709',
    'minoriko_boss': 'ef3057727ba3ff42ce04e186a422a0b7001b25b599e9cb3864b82e8351ae3e5d',
}
EXPECTED_AUDIO_SHA256 = {
    'stage': '92460101bb56c2c7a89cb21be1af7779b56af53cad3a08fc2f3537ed56cdb113',
    'ending': 'ae995b9b0040685bea64e21466216c46ba881a17b511f44382ea877513247833',
}


def main():
    manifest = json.loads((ROOT / 'art/source_sheets/aki/manifest.json').read_text())
    assert len(manifest['sets']) == 2
    for record in manifest['sets']:
        source_path = ROOT / record['source_sheet']
        digest = hashlib.sha256(source_path.read_bytes()).hexdigest()
        assert digest == EXPECTED_SOURCE_SHA256[record['kind']]
        assert digest == record['original_sha256'] == record['source_sha256']
        source = np.array(Image.open(source_path).convert('RGBA'))
        coverage = np.zeros(source.shape[:2], dtype='uint8')
        assert len(record['individual_crops']) == record['frame_count'] == 24
        assert record['runtime_source_slots'] == list(range(24))
        assert record['canvas'] == [512, 384] and record['pivot'] == [256, 320]
        assert len(list((ROOT / record['folder']).glob('frame_*.png'))) == 24
        for i, crop in enumerate(record['individual_crops']):
            frame_path = ROOT / record['folder'] / f'frame_{i:02d}.png'
            frame = np.array(Image.open(frame_path))
            alpha = frame[:, :, 3]
            assert frame.shape == (384, 512, 4)
            assert not alpha[:2].any() and not alpha[-2:].any()
            assert not alpha[:, :2].any() and not alpha[:, -2:].any()
            _, _, stats, _ = cv2.connectedComponentsWithStats((alpha > 32).astype('uint8'), 8)
            bodies = [s for s in stats[1:] if s[4] > 10000]
            assert len(bodies) == 1, ('mixed figures', record['kind'], i)
            assert int(bodies[0][1] + bodies[0][3]) == 320, ('foot drift', record['kind'], i)
            yy, xx = np.where(alpha > 0)
            sx = xx + crop['anchor'][0] - record['pivot'][0]
            sy = yy + crop['anchor'][1] - record['pivot'][1]
            assert np.array_equal(frame[yy, xx], source[sy, sx]), ('modified RGBA pixels', record['kind'], i)
            coverage[sy, sx] += 1
            if i == 0:
                opaque_y, _ = np.where(alpha >= 128)
                assert int(opaque_y.max() - opaque_y.min() + 1) == record['idle_height']
                assert int(opaque_y.max() + 1) == record['idle_bottom'] == 320
        assert np.all(coverage[source[:, :, 3] > 0] == 1), ('lost or duplicate source pixels', record['kind'])
        assert not coverage[source[:, :, 3] == 0].any(), 'transparent RGB backdrop was adopted'
    for audio in manifest['audio']:
        path = ROOT / audio['path']
        assert path.stat().st_size > 1000000
        assert hashlib.sha256(path.read_bytes()).hexdigest() == audio['source_sha256'] == EXPECTED_AUDIO_SHA256[audio['role']]
        assert 'loop=true' in Path(str(path) + '.import').read_text()
    assert [item['role'] for item in manifest['audio']] == ['stage', 'ending']
    print('PASS: 48 Aki poses preserve supplied pixels and alpha once, feet align, and both BGM SHA256 hashes match')


if __name__ == '__main__':
    main()
