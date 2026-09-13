"""Crop the supplied 6x4 Kaguya sheet, retaining a shared character scale."""
from pathlib import Path
import argparse
import hashlib
import json
import cv2
import numpy as np
from PIL import Image, ImageDraw

parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path)
parser.add_argument('--output', type=Path, default=Path('art/kaguya'))
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
sheet = np.array(Image.open(args.source).convert('RGB'))
assert sheet.shape == (1024, 1536, 3), 'Expected the original 6x4 256px sheet'
previews = [Image.new('RGB', (1536, 1024), bg) for bg in ['#17273e', '#ecdfcb']]
for i in range(24):
    rgb = sheet[(i//6)*256:(i//6+1)*256, (i%6)*256:(i%6+1)*256].copy()
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    v, sat = hsv[:, :, 2], hsv[:, :, 1]
    mask = np.full((256, 256), cv2.GC_PR_BGD, np.uint8)
    stone = (v > 85) & (rgb[:,:,1].astype(float) > rgb[:,:,0] * 0.93) & (sat < 90)
    crisp = (v < 58) | (v > 172) | (sat > 135) | stone
    mask[crisp] = cv2.GC_PR_FGD
    mask[(v < 29) | (v > 220) | (sat > 200) | stone] = cv2.GC_FGD
    mask[:2,:] = mask[-2:,:] = mask[:,:2] = mask[:,-2:] = cv2.GC_BGD
    cv2.grabCut(rgb, mask, None, np.zeros((1,65)), np.zeros((1,65)), 5, cv2.GC_INIT_WITH_MASK)
    alpha = np.where((mask == 1) | (mask == 3), 255, 0).astype(np.uint8)
    near_crisp = cv2.dilate(crisp.astype(np.uint8), np.ones((3,3), np.uint8)) > 0
    alpha[~near_crisp] = 0
    count, labels, stats, _ = cv2.connectedComponentsWithStats(alpha)
    for n in range(1, count):
        if stats[n, cv2.CC_STAT_AREA] < 5:
            alpha[labels == n] = 0
    rgba = Image.fromarray(np.dstack((rgb, alpha)))
    rgba.save(args.output / f'frame_{i:02d}.png')
    for preview in previews:
        preview.paste(rgba, ((i%6)*256, (i//6)*256), rgba)
    if i == 0:
        ys, xs = np.where(alpha > 128)
        print('idle height/bottom:', int(ys.max()-ys.min()+1), int(ys.max()+1))
out = Path('output/kaguya')
out.mkdir(parents=True, exist_ok=True)
for name, preview in zip(['frames-contact', 'frames-light'], previews):
    preview.save(out / f'{name}.png')
(args.output / 'source.json').write_text(json.dumps({
    'source': args.source.name, 'sha256': hashlib.sha256(args.source.read_bytes()).hexdigest(),
    'layout': '6 columns x 4 rows, 24 original poses', 'canvas': [256,256],
    'processor': 'scripts/tools/prepare_kaguya_frames.py',
    'note': 'User-supplied character; cropped and background removed, never regenerated.'
}, ensure_ascii=False, indent=2) + '\n')
