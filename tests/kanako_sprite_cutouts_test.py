"""Exact supplied Kanako pixels, reviewed pose ownership and native imports."""
import hashlib
import json
import re
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHA = 'c44ba7f90de7c8ffd80bf03aa2bf39660c58e61544d56644f77da2df0e2b667b'
AUDIO_SHA = {'stage': 'cbb36dc946549decf88b244b22be882f06bae532f8983249de5fa9d2297db303',
             'ending': '47f4098e29b6bf5eb9860d1a2464580883a11f59853b8948d87f255870887595'}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    folder = ROOT / 'art/source_sheets/kanako'
    manifest = json.loads((folder / 'manifest.json').read_text())
    record = manifest['sprite']
    source = np.array(Image.open(folder / 'kanako.png').convert('RGBA'))
    assert digest(folder / 'kanako.png') == SOURCE_SHA == record['source_sha256'] == record['original_sha256']
    assert record['original_filename'] == 'Purple-Haired Shrine Maiden Sprite Sheet.png'
    original_sheet = Path('/Users/hecrereed/Downloads') / record['original_filename']
    if original_sheet.exists():
        assert digest(original_sheet) == SOURCE_SHA
    assert source.shape == (1024, 1536, 4) and source[:, :, 3].max() == 254
    assert (folder / '.gdignore').exists()
    assert record['frame_count'] == record['source_pose_count'] == len(record['individual_crops']) == 24
    assert record['canvas'] == [512, 384] and record['pivot'] == [256, 320]
    assert record['runtime_source_slots'] == list(range(24))
    assert len(list((ROOT / 'art/kanako').glob('frame_*.png'))) == 24
    coverage = np.zeros(source.shape[:2], np.uint8)
    ownership = np.full(source.shape[:2], -1, np.int16)
    for index, crop in enumerate(record['individual_crops']):
        path = ROOT / f'art/kanako/frame_{index:02d}.png'
        frame = np.array(Image.open(path).convert('RGBA'))
        assert frame.shape == (384, 512, 4)
        alpha = frame[:, :, 3]
        assert not alpha[:2].any() and not alpha[-2:].any() and not alpha[:, :2].any() and not alpha[:, -2:].any()
        _, _, stats, _ = cv2.connectedComponentsWithStats((alpha > 240).astype('uint8'), 8)
        bodies = [s for s in stats[1:] if s[4] > 10000]
        assert len(bodies) == 1, ('neighboring figure', index)
        assert int(bodies[0][1] + bodies[0][3]) == 320, ('core foot anchor', index)
        y, x = np.where(alpha > 0)
        sy = y + crop['anchor'][1] - 320
        sx = x + crop['anchor'][0] - 256
        assert np.array_equal(frame[y, x], source[sy, sx]), ('altered/rotated/resampled RGBA', index)
        coverage[sy, sx] += 1
        ownership[sy, sx] = index
        assert digest(path) == crop['frame_sha256']
        settings = Path(str(path) + '.import').read_text()
        for expected in ['compress/mode=0', 'process/fix_alpha_border=false', 'process/premult_alpha=false', 'mipmaps/generate=false']:
            assert expected in settings
        if index == 0:
            oy, _ = np.where(alpha >= 128)
            assert (int(oy.max() - oy.min() + 1), int(oy.max() + 1)) == (record['idle_height'], record['idle_bottom'])
    visible = source[:, :, 3] > 0
    assert np.all(coverage[visible] == 1), 'Every visible rope/shide/mirror/crystal pixel belongs exactly once'
    assert not coverage[~visible].any(), 'No transparent RGB backdrop adopted'
    # Detached effects that cross the 256px grid stay with their own pose:
    # 08's red arrow tip, 09's red crescent and the crystals of 20/21.
    for region, owner in [((521, 346, 578, 414), 8), ((810, 322, 830, 428), 9), ((560, 906, 581, 953), 20),
                          ((825, 921, 849, 980), 21), ((975, 954, 995, 997), 21), ((997, 837, 1019, 891), 21)]:
        x0, y0, x1, y1 = region
        patch = ownership[y0:y1, x0:x1][source[y0:y1, x0:x1, 3] > 32]
        assert patch.size and np.all(patch == owner), ('effect donated to a neighbour', region, owner)
    sys.path.insert(0, str(ROOT / 'scripts/tools'))
    from import_kanako_sprite_cutouts import extract_kanako
    rebuilt, rebuilt_crops = extract_kanako(folder / 'kanako.png')
    for index, (frame, crop) in enumerate(zip(rebuilt, rebuilt_crops)):
        stored = np.array(Image.open(ROOT / f'art/kanako/frame_{index:02d}.png').convert('RGBA'))
        assert np.array_equal(np.array(frame), stored), ('non-reproducible pose', index)
        assert crop['anchor'] == record['individual_crops'][index]['anchor']
    standalone = json.loads((folder / 'animation_source_record.json').read_text())
    registry = next(r for r in json.loads((ROOT / 'art/touhou_boss_animation_sources.json').read_text()) if r['kind'] == 'kanako_boss')
    for key in ['source_sha256', 'idle_height', 'idle_bottom', 'canvas', 'pivot', 'frame_count']:
        assert standalone[key] == registry[key] == record[key]
    script = (ROOT / 'scripts/data/kanako_sprite_defs.gd').read_text()
    for key, value in [('IDLE_HEIGHT', record['idle_height']), ('IDLE_BOTTOM', record['idle_bottom'])]:
        assert re.search(r'const\s+' + key + r'\s*:?=\s*' + str(value) + r'\.0', script)
    actions = script.split('const ACTIONS', 1)[1].split('}', 1)[0]
    groups = dict((name, [int(v) for v in group.split(',')]) for name, group in re.findall(r'"([a-z_]+)"\s*:\s*\[([\d, ]+)\]', actions))
    assert groups['defeat'][-1] == 18 and 19 in groups['hit']
    for name, slots in groups.items():
        assert all(0 <= v < 24 for v in slots)
        if name not in ['hit', 'defeat']:
            assert not any(v in [18, 19] for v in slots), ('collapse/recoil used as a cast', name)
    assert set(groups['final']) == {22, 23} and set(groups['crystal']) == {20, 21} and set(groups['shot']) == {6, 7, 8}
    for role, expected in AUDIO_SHA.items():
        path = ROOT / f'audio/bgm/touhou/4-24-{role}.mp3'
        assert digest(path) == expected
        assert 'loop=true' in Path(str(path) + '.import').read_text()
        original = Path('/Users/hecrereed/Downloads') / ('4-24道中.mp3' if role == 'stage' else '4-24终末.mp3')
        if original.exists():
            assert digest(original) == expected
    print('PASS:24 reproducible Kanako poses preserve all %d original RGBA pixels once; detached effects/feet/actions; 2 exact looping MP3s' % int(visible.sum()))


if __name__ == '__main__':
    main()
