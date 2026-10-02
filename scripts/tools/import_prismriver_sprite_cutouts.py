#!/usr/bin/env python3
"""Preserve the supplied sisters' RGBA pixels with individually owned poses."""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from import_imperishable_sprite_cutouts import extract, sha256
from import_scarlet_sprite_cutouts import CANVAS, PIVOT, ROOT, contact_sheet

LAYOUTS = {
    'lunasa': {'centers': [[126,383,632,898,1158,1414], [151,382,676,903,1164,1412],
                           [145,401,642,905,1160,1415], [123,386,660,911,1173,1421]],
               'gaps': [[0,253,505,780,1030,1280,1536], [0,256,514,794,1033,1278,1536],
                        [0,270,535,760,1030,1280,1536], [0,260,516,778,1038,1286,1536]],
               'row_gaps': [0,261,517,769,1024]},
    'merlin': {'centers': [[131,408,662,927,1189,1445], [128,402,644,930,1187,1429],
                           [149,398,659,921,1186,1436], [134,381,657,925,1189,1432]],
               'gaps': [[0,276,533,800,1060,1324,1536], [0,230,501,780,1064,1310,1536],
                        [0,269,530,793,1065,1315,1536], [0,231,505,798,1060,1325,1536]],
               'row_gaps': [0,263,517,768,1024]},
    'lyrica': {'centers': [[128,347,570,829,1102,1379], [125,383,642,874,1136,1427],
                           [125,354,610,844,1105,1378], [126,390,630,886,1163,1408]],
               'gaps': [[0,239,456,690,956,1240,1536], [0,229,513,751,999,1271,1536],
                        [0,230,488,725,984,1229,1536], [0,250,506,757,1017,1294,1536]],
               'row_gaps': [0,252,490,738,1024]},
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--inputs', type=Path)
    args = parser.parse_args()
    folder = ROOT / 'art/source_sheets/prismriver_refresh'
    folder.mkdir(parents=True, exist_ok=True)
    (folder / '.gdignore').touch()
    preview = ROOT / 'output/prismriver-refresh'
    preview.mkdir(parents=True, exist_ok=True)
    inputs = [line.split('\t') for line in args.inputs.read_text().splitlines()] if args.inputs else [(name, str(folder / f'{name}.png')) for name in LAYOUTS]
    records = []
    for name, source in inputs:
        target = folder / f'{name}.png'
        target.write_bytes(Path(source).read_bytes())
        config = dict(LAYOUTS[name], rows=[142,391,643,898], seed_alpha=96, soft_component_gaps=True)
        poses, crops = extract(name, target, config)
        destination = ROOT / ('art/prismriver' if name == 'lunasa' else f'art/prismriver/{name}')
        destination.mkdir(parents=True, exist_ok=True)
        for i, frame in enumerate(poses):
            frame.save(destination / f'frame_{i:02d}.png')
        contact_sheet(name, poses, preview / f'{name}-runtime-frames.png')
        yy, _ = np.where(np.array(poses[0])[:, :, 3] >= 128)
        height, bottom = int(yy.max()-yy.min()+1), int(yy.max()+1)
        print(name, height, bottom)
        records.append({'member': name, 'kind': 'prismriver_boss', 'folder': str(destination.relative_to(ROOT)),
                        'frame_count':24, 'source_pose_count':24, 'source':'user_transparent_sheet_individual_crops',
                        'source_sheet':str(target.relative_to(ROOT)), 'original_sha256':sha256(target), 'source_sha256':sha256(target),
                        'canvas':list(CANVAS), 'pivot':list(PIVOT), 'idle_height':height, 'idle_bottom':bottom,
                        'runtime_source_slots':list(range(24)), 'seed_alpha':96, 'individual_crops':crops})
    (folder / 'manifest.json').write_text(json.dumps({'method':'Exact original RGBA, individual pose ownership and stable foot anchors; no resampling, mirroring or fixed-grid slicing.', 'sets':records},indent=2)+'\n')
    metadata = ROOT / 'art/touhou_boss_animation_sources.json'
    old = json.loads(metadata.read_text())
    replacement = {k:v for k,v in records[0].items() if k not in ['member','individual_crops']}
    replacement['members'] = [{k:v for k,v in r.items() if k != 'individual_crops'} for r in records]
    metadata.write_text(json.dumps([replacement if r['kind']=='prismriver_boss' else r for r in old],ensure_ascii=False,indent=2)+'\n')


if __name__ == '__main__':
    main()
