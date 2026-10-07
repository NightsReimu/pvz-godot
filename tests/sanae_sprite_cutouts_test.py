"""Exact supplied Sanae pixels, reviewed pose ownership and native imports."""
import hashlib
import json
import re
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHA = 'a0955b390603c05b7fa4d7198c7328d15e4c7539699d0bb73692f29fdde2167b'
AUDIO_SHA = {'stage': '27c69211c67603193016c4dae73f062098e10a0127af694c43709cb013295ffa',
             'ending': '503044ad980a47f05801eb14259f275a87da35fb5200f732364cb84636f92e97'}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    folder = ROOT / 'art/source_sheets/sanae'
    manifest = json.loads((folder / 'manifest.json').read_text())
    record = manifest['sprite']
    source = np.array(Image.open(folder / 'sanae.png').convert('RGBA'))
    assert digest(folder / 'sanae.png') == SOURCE_SHA == record['source_sha256'] == record['original_sha256']
    original_name = 'codex-clipboard-54323c73-a85d-4ab9-bff3-2c6a08098cba.png'
    assert record['original_filename'] == original_name
    original_sheet = Path('/var/folders/xh/7z0xwb9j0ss_812rll0w1f300000gn/T') / original_name
    if original_sheet.exists():
        assert digest(original_sheet) == SOURCE_SHA
    assert source.shape == (1024, 1536, 4) and source[:, :, 3].max() == 254
    assert (folder / '.gdignore').exists()
    assert record['frame_count'] == record['source_pose_count'] == len(record['individual_crops']) == 24
    assert record['canvas'] == [512, 384] and record['pivot'] == [256, 320]
    assert record['runtime_source_slots'] == list(range(24))
    assert len(list((ROOT / 'art/sanae').glob('frame_*.png'))) == 24
    coverage = np.zeros(source.shape[:2], np.uint8)
    ownership = np.full(source.shape[:2], -1, np.int16)
    for index, crop in enumerate(record['individual_crops']):
        path = ROOT / f'art/sanae/frame_{index:02d}.png'
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
    assert np.all(coverage[source[:, :, 3] > 0] == 1), 'Every visible hair/gohei/glow pixel belongs exactly once'
    assert not coverage[source[:, :, 3] == 0].any(), 'No transparent RGB backdrop adopted'
    yy, xx = np.indices(source.shape[:2])
    rgb = source[:, :, :3].astype(float)
    green = (rgb[:, :, 1] > rgb[:, :, 0] * 1.3) & (rgb[:, :, 1] > rgb[:, :, 2] * 1.3)
    blue = (rgb[:, :, 2] > rgb[:, :, 0] * 1.5) & (rgb[:, :, 2] > rgb[:, :, 1] * 1.1)
    # These reviewed regions are the tops of15/19 effects, below the previous
    # row's feet. They must never create green/blue particles under09/13.
    green_top = (yy >= 517) & (yy < 544) & (xx >= 784) & (xx < 1009) & green & (source[:, :, 3] > 32)
    blue_top = (yy >= 768) & (yy < 791) & (xx >= 280) & (xx < 502) & blue & (source[:, :, 3] > 32)
    assert np.all(ownership[green_top] == 15), 'Green wind15 donated into prayer09'
    assert np.all(ownership[blue_top] == 19), 'Blue sweep19 donated into hit13'
    # At the overlapping last-row sweeps,19's green hair remains behind20's
    # upper blue/white stroke. RGB names the owner without changing its bytes.
    hair_overlap = (yy >= 850) & (yy < 910) & (xx >= 460) & (xx < 503) & green & (source[:, :, 3] > 0)
    upper_stroke = (yy >= 850) & (yy < 888) & (xx >= 460) & (xx < 503) & (rgb[:, :, 2] >= rgb[:, :, 1]) & (source[:, :, 3] > 0)
    assert hair_overlap.any() and upper_stroke.any()
    assert np.all(ownership[hair_overlap] == 19), 'Green hair19 donated into sweep20'
    assert np.all(ownership[upper_stroke] == 20), 'Upper foreground sweep20 donated into hair19'
    sys.path.insert(0, str(ROOT / 'scripts/tools'))
    from import_sanae_sprite_cutouts import extract_sanae
    rebuilt, rebuilt_crops = extract_sanae(folder / 'sanae.png')
    for index, (frame, crop) in enumerate(zip(rebuilt, rebuilt_crops)):
        stored = np.array(Image.open(ROOT / f'art/sanae/frame_{index:02d}.png').convert('RGBA'))
        assert np.array_equal(np.array(frame), stored), ('non-reproducible pose', index)
        assert crop['anchor'] == record['individual_crops'][index]['anchor']
    standalone = json.loads((folder / 'animation_source_record.json').read_text())
    registry = next(r for r in json.loads((ROOT / 'art/touhou_boss_animation_sources.json').read_text()) if r['kind'] == 'sanae_boss')
    for key in ['source_sha256', 'idle_height', 'idle_bottom', 'canvas', 'pivot', 'frame_count']:
        assert standalone[key] == registry[key] == record[key]
    script = (ROOT / 'scripts/data/sanae_sprite_defs.gd').read_text()
    for key, value in [('IDLE_HEIGHT', record['idle_height']), ('IDLE_BOTTOM', record['idle_bottom'])]:
        assert re.search(r'const\s+' + key + r'\s*:?=\s*' + str(value) + r'\.0', script)
    actions = script.split('const ACTIONS', 1)[1].split('}', 1)[0]
    for name, group in re.findall(r'"([a-z_]+)"\s*:\s*\[([\d, ]+)\]', actions):
        slots = [int(v) for v in group.split(',')]
        assert all(0 <= v < 24 for v in slots)
        if name not in ['hit', 'defeat']:
            assert not any(v in [12, 13, 21, 22] for v in slots), ('reaction used as cast', name)
    for role, expected in AUDIO_SHA.items():
        path = ROOT / f'audio/bgm/touhou/4-23-{role}.mp3'
        assert digest(path) == expected
        assert 'loop=true' in Path(str(path) + '.import').read_text()
        original = Path('/Users/hecrereed/Downloads') / ('4-23道中.mp3' if role == 'stage' else '4-23终末.mp3')
        if original.exists():
            assert digest(original) == expected
    print('PASS:24 reproducible Sanae poses preserve all918901 original RGBA pixels once; independent effects/feet/actions;2 exact looping MP3s')


if __name__ == '__main__':
    main()
