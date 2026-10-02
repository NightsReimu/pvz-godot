#!/usr/bin/env python3
"""Extract the eight supplied PCB sheets without changing their RGBA pixels.

The explicit pose seeds and particle gaps are per sheet and per row. Alpha 96
separates touching spell glows; the ownership pass restores ALL original soft
alpha afterwards. Each independently anchored pose is saved as its own PNG.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

from import_imperishable_sprite_cutouts import extract, sha256
from import_scarlet_sprite_cutouts import CANVAS, PIVOT, ROOT, contact_sheet

LAYOUTS = {
    'letty': {
        'centers': [[132,371,629,889,1145,1398], [134,403,657,905,1162,1412],
                    [139,376,636,894,1157,1409], [123,395,633,913,1150,1405]],
        'gaps': [[0,258,511,772,1033,1285,1536], [0,240,530,785,1024,1290,1536],
                 [0,258,520,774,1023,1290,1536], [0,254,516,791,1027,1276,1536]],
        'row_gaps': [0,255,516,751,1024],
    },
    'chen': {
        'centers': [[148,403,649,902,1145,1395], [123,395,643,904,1157,1414],
                    [126,392,653,904,1168,1413], [135,399,658,913,1155,1404]],
        'gaps': [[0,280,537,784,1036,1286,1536], [0,238,518,791,1022,1281,1536],
                 [0,260,520,780,1033,1283,1536], [0,257,550,785,1032,1290,1536]],
        'row_gaps': [0,257,514,755,1024],
    },
    'alice': {
        'centers': [[134,376,621,891,1139,1399], [135,385,619,898,1150,1400],
                    [142,372,647,910,1145,1402], [132,379,645,895,1148,1396]],
        'gaps': [[0,250,507,774,1027,1278,1536], [0,255,513,776,1027,1281,1536],
                 [0,263,517,776,1024,1282,1536], [0,257,514,780,1025,1282,1536]],
        'row_gaps': [0,260,514,769,1024],
    },
    'lily_white': {
        'centers': [[129,367,627,890,1157,1418], [128,372,640,912,1163,1413],
                    [139,404,651,915,1171,1416], [132,388,667,909,1172,1420]],
        'gaps': [[0,254,513,775,1025,1286,1536], [0,239,502,770,1025,1280,1536],
                 [0,265,535,775,1035,1283,1536], [0,253,523,790,1035,1300,1536]],
        'row_gaps': [0,263,523,777,1024],
    },
    'youmu': {
        'centers': [[137,379,626,902,1165,1421], [138,370,615,889,1171,1421],
                    [137,393,651,906,1167,1418], [134,384,645,911,1176,1420]],
        'gaps': [[0,265,515,778,1033,1293,1536], [0,245,496,763,1040,1288,1536],
                 [0,265,535,777,1036,1292,1536], [0,247,510,775,1040,1293,1536]],
        'row_gaps': [0,262,531,773,1024],
    },
    'yuyuko': {
        'centers': [[123,373,627,904,1158,1409], [124,369,623,885,1141,1412],
                    [126,383,619,897,1169,1418], [132,375,639,914,1167,1410]],
        'gaps': [[0,260,520,782,1040,1295,1536], [0,249,490,757,1020,1292,1536],
                 [0,256,516,770,1028,1295,1536], [0,251,510,778,1060,1299,1536]],
        'row_gaps': [0,251,523,766,1024],
    },
    'ran': {
        'centers': [[127,361,602,878,1136,1400], [121,371,614,878,1161,1405],
                    [143,382,630,904,1176,1418], [136,383,644,902,1179,1422]],
        'gaps': [[0,251,490,744,1009,1274,1536], [0,245,487,749,1018,1283,1536],
                 [0,267,509,750,1040,1300,1536], [0,252,506,764,1040,1300,1536]],
        'row_gaps': [0,259,512,763,1024],
    },
    'yukari': {
        'centers': [[128,361,609,872,1137,1395], [123,372,618,875,1149,1405],
                    [138,387,633,889,1152,1411], [137,372,641,905,1173,1412]],
        'gaps': [[0,250,495,750,1010,1276,1536], [0,244,471,753,1008,1273,1536],
                 [0,267,518,757,1036,1286,1536], [0,250,503,765,1028,1320,1536]],
        'row_gaps': [0,257,512,755,1024],
    },
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--inputs', type=Path, help='name / supplied source TSV; omit to rebuild committed originals')
    args = parser.parse_args()
    folder = ROOT / 'art/source_sheets/cherry_refresh'
    folder.mkdir(parents=True, exist_ok=True)
    (folder / '.gdignore').touch()
    output = ROOT / 'output/cherry-refresh'
    output.mkdir(parents=True, exist_ok=True)
    inputs = [line.split('\t') for line in args.inputs.read_text().splitlines()] if args.inputs else [(name, str(folder / f'{name}.png')) for name in LAYOUTS]
    records = []
    for name, source in inputs:
        target = folder / f'{name}.png'
        target.write_bytes(Path(source).read_bytes())
        config = dict(LAYOUTS[name], rows=[140,395,646,897], seed_alpha=96, soft_component_gaps=True)
        poses, crops = extract(name, target, config)
        for i, frame in enumerate(poses):
            frame.save(ROOT / f'art/{name}/frame_{i:02d}.png')
        contact_sheet(name, poses, output / f'{name}-runtime-frames.png')
        yy, _ = np.where(np.array(poses[0])[:, :, 3] >= 128)
        height, bottom = int(yy.max() - yy.min() + 1), int(yy.max() + 1)
        print(name, 'idle_height', height, 'idle_bottom', bottom)
        records.append({'kind': name + '_boss', 'folder': 'art/' + name,
                        'frame_count': 24, 'source_pose_count': len(poses),
                        'source': 'user_transparent_sheet_individual_crops',
                        'source_sheet': str(target.relative_to(ROOT)),
                        'original_sha256': sha256(target), 'source_sha256': sha256(target),
                        'canvas': list(CANVAS), 'pivot': list(PIVOT),
                        'idle_height': height, 'idle_bottom': bottom, 'seed_alpha': 96,
                        'runtime_source_slots': list(range(24)), 'individual_crops': crops})
    (folder / 'manifest.json').write_text(json.dumps({
        'method': 'Exact original RGBA; individually owned components, soft alpha and foot anchors; no fixed-grid slicing, generation, resampling or mirroring.',
        'sets': records}, indent=2) + '\n')
    metadata = ROOT / 'art/touhou_boss_animation_sources.json'
    old = json.loads(metadata.read_text())
    updates = {r['kind']: {k: v for k, v in r.items() if k != 'individual_crops'} for r in records}
    metadata.write_text(json.dumps([updates.get(r['kind'], r) for r in old], ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    main()
