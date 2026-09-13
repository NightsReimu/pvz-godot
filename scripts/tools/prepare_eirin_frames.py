"""Extract the user's 6x4 sheet without changing the character or pose scale."""
from pathlib import Path
import argparse
import cv2
import numpy as np
from PIL import Image, ImageDraw

parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path)
parser.add_argument('--output', type=Path, default=Path('art/eirin'))
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
sheet = np.array(Image.open(args.source).convert('RGB'))
previews = Image.new('RGB', (6 * 256, 4 * 256), '#173048')
for i in range(24):
    rgb = sheet[(i // 6)*256:(i // 6+1)*256, (i % 6)*256:(i % 6+1)*256].copy()
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    v, sat = hsv[:,:,2], hsv[:,:,1]
    mask = np.full((256,256), cv2.GC_PR_BGD, np.uint8)
    color = (v < 48) | (v > 176) | ((sat > 135) & (rgb[:,:,0] > 125))
    mask[color] = cv2.GC_PR_FGD
    mask[(v < 28) | (v > 225) | ((sat > 190) & (rgb[:,:,0] > 150))] = cv2.GC_FGD
    mask[:2,:] = mask[-2:,:] = mask[:,:2] = mask[:,-2:] = cv2.GC_BGD
    cv2.grabCut(rgb, mask, None, np.zeros((1,65)), np.zeros((1,65)), 5, cv2.GC_INIT_WITH_MASK)
    alpha = np.where((mask == 1) | (mask == 3), 255, 0).astype(np.uint8)
    # Smooth rose illumination belongs to the background, not the bow trail.
    crisp = (v < 48) | (rgb.min(axis=2) > 164) | ((sat > 150) & (rgb[:,:,0] > 125))
    near_crisp = cv2.dilate(crisp.astype(np.uint8), np.ones((3,3),np.uint8)) > 0
    alpha[~near_crisp] = 0
    if i == 9:  # The preceding bow arc spills over this cell boundary.
        alpha[:, :44] = 0
    if i in (12, 13):  # Detached cross from the following row.
        alpha[244:, :] = 0
    # Retain detached red crosses and bow trails, remove only tiny isolated noise.
    count, labels, stats, _ = cv2.connectedComponentsWithStats(alpha)
    for n in range(1,count):
        if stats[n,cv2.CC_STAT_AREA] < 5:
            alpha[labels == n] = 0
    rgba = Image.fromarray(np.dstack((rgb,alpha)))
    rgba.save(args.output / f'frame_{i:02d}.png')
    previews.paste(rgba, ((i%6)*256,(i//6)*256),rgba)
    if i == 0:
        ys,xs = np.where(alpha > 128)
        print('idle height/bottom:', int(ys.max()-ys.min()+1), int(ys.max()+1))
Path('output/eirin').mkdir(parents=True,exist_ok=True)
previews.save('output/eirin/frames-contact.png')
