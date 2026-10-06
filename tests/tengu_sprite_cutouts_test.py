"""Tengu sheets preserve every supplied visible pixel and both music files."""

import hashlib
import json
import re
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_HASHES = {
    'momiji': 'a80ccccf4fe9d52531157c64331d2e2bb38e8019a5a7e123046f96732a6fa1be',
    'aya': '5c0c78ad9b4c8500e838cf5202c2d5bc4cd1d630cfd17e6ba89cbc045e5ad913',
}
AUDIO_HASHES = {
    'stage': 'a481deebfa6332d9dee5f35140c204d63aeabfcae60709e4f13684027d06f3f8',
    'ending': 'aaa28605e5e9c713a7f356a6024e86509774d5d79f93845902bf999ab27eb732',
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert (ROOT / 'scripts/tools/import_tengu_sprite_cutouts.py').exists(), 'Missing reproducible Tengu importer'
    for name, source_hash in SOURCE_HASHES.items():
        folder = ROOT / f'art/source_sheets/{name}'
        assert (folder / 'manifest.json').exists(), f'Missing {name} source/ownership manifest'
        manifest = json.loads((folder / 'manifest.json').read_text())
        record = manifest['sprite']
        source_path = ROOT / record['source_sheet']
        assert digest(source_path) == source_hash == record['original_sha256'] == record['source_sha256']
        source = np.array(Image.open(source_path).convert('RGBA'))
        assert list(source.shape[1::-1]) == record['source_size']
        assert source.shape[:2] == ((1086, 1448) if name == 'momiji' else (1024, 1536))
        assert (folder / '.gdignore').exists()
        assert record['canvas'] == [512, 384] and record['pivot'] == [256, 320]
        assert record['runtime_source_slots'] == list(range(24))
        assert len(record['individual_crops']) == record['frame_count'] == record['source_pose_count'] == 24
        frames_folder = ROOT / record['folder']
        assert len(list(frames_folder.glob('frame_*.png'))) == 24
        coverage = np.zeros(source.shape[:2], dtype='uint8')
        for index, crop in enumerate(record['individual_crops']):
            frame_path = frames_folder / f'frame_{index:02d}.png'
            frame = np.array(Image.open(frame_path).convert('RGBA'))
            alpha = frame[:, :, 3]
            assert frame.shape == (384, 512, 4)
            assert not alpha[:2].any() and not alpha[-2:].any()
            assert not alpha[:, :2].any() and not alpha[:, -2:].any()
            _, _, stats, _ = cv2.connectedComponentsWithStats((alpha > 32).astype('uint8'), 8)
            bodies = [component for component in stats[1:] if component[4] > 10000]
            assert len(bodies) == 1, ('neighboring body spill', name, index)
            assert int(bodies[0][1] + bodies[0][3]) == 320, ('foot anchor drift', name, index)
            yy, xx = np.where(alpha > 0)
            sx = xx + crop['anchor'][0] - record['pivot'][0]
            sy = yy + crop['anchor'][1] - record['pivot'][1]
            assert np.array_equal(frame[yy, xx], source[sy, sx]), ('RGBA changed/rotated/resampled', name, index)
            coverage[sy, sx] += 1
            assert digest(frame_path) == crop['frame_sha256']
            import_settings = Path(str(frame_path) + '.import').read_text()
            assert 'compress/mode=0' in import_settings
            assert 'process/fix_alpha_border=false' in import_settings
            assert 'process/premult_alpha=false' in import_settings
            assert 'mipmaps/generate=false' in import_settings
            if index == 0:
                opaque_y, _ = np.where(alpha >= 128)
                assert int(opaque_y.max() - opaque_y.min() + 1) == record['idle_height']
                assert int(opaque_y.max() + 1) == record['idle_bottom']
        assert np.all(coverage[source[:, :, 3] > 0] == 1), ('lost or duplicate body/tail/fan/weapon/glow', name)
        assert not coverage[source[:, :, 3] == 0].any(), 'Invisible RGB backdrop adopted'
        standalone = json.loads((folder / 'animation_source_record.json').read_text())
        for key in ['kind', 'source_sheet', 'source_sha256', 'idle_height', 'idle_bottom', 'canvas', 'pivot']:
            assert standalone[key] == record[key]
        script = (ROOT / f'scripts/data/{name}_sprite_defs.gd').read_text()
        assert f'const KIND := "{name}_boss"' in script and 'const FRAME_COUNT := 24' in script
        assert f'const IDLE_HEIGHT := {record["idle_height"]}.0' in script
        assert f'const IDLE_BOTTOM := {record["idle_bottom"]}.0' in script
        actions = script.split('const ACTIONS := {', 1)[1].split('}', 1)[0]
        reaction_slots = [12, 13, 22, 23] if name == 'momiji' else [12, 13, 21, 22]
        for group, values in re.findall(r'"([a-z_]+)":\s*\[([\d, ]+)\]', actions):
            indices = [int(value) for value in values.split(',')]
            assert all(0 <= value < 24 for value in indices), (name, group)
            if group not in ['hit', 'defeat']:
                assert not any(value in reaction_slots for value in indices), ('reaction pose used for casting', name, group)
        assert '"hit": [12, 13, 14]' in actions
        assert ('"defeat": [22, 23]' if name == 'momiji' else '"defeat": [21, 22]') in actions
        assert '"idle": [0, 1, 2, 1]' in actions
        for audio in manifest['audio']:
            target = ROOT / audio['path']
            assert digest(target) == AUDIO_HASHES[audio['role']] == audio['source_sha256']
            assert 'loop=true' in Path(str(target) + '.import').read_text()
    print('PASS: 48 Tengu poses preserve all supplied RGBA once, independent figures and anchors; 2 exact looping MP3s')


if __name__ == '__main__':
    main()
