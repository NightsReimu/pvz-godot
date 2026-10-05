"""Reproducible, code-authored garden textures; all geometry is original."""
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[2] / 'art/vector/ancient'
ROOT.mkdir(parents=True, exist_ok=True)
rng = random.Random(8164)

def save(name, w, h, parts):
    (ROOT / name).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">' + ''.join(parts) + '</svg>\n')

parts = ['<defs><linearGradient id="stone" x2="0" y2="1"><stop stop-color="#d9ccaa"/><stop offset="1" stop-color="#a89978"/></linearGradient></defs>', '<rect width="180" height="100" fill="#6b7560"/>']
for row in range(2):
    for col in range(-1,3):
        x = col*90 + (row%2)*45
        y = row*50
        pts = f'{x+3},{y+7} {x+13},{y+3} {x+82},{y+4} {x+87},{y+11} {x+85},{y+45} {x+74},{y+48} {x+7},{y+45} {x+2},{y+36}'
        parts += [f'<polygon points="{pts}" fill="url(#stone)" stroke="#505d4b" stroke-width="2"/>',f'<path d="M{x+12} {y+10} L{x+78} {y+10} M{x+10} {y+13} L{x+10} {y+35}" stroke="#f8eaca" stroke-opacity=".5" fill="none"/>',f'<path d="M{x+18} {y+39} Q{x+30} {y+32} {x+53} {y+36}" stroke="#7f836a" stroke-opacity=".28" fill="none"/>']
for _ in range(22):
    x,y=rng.uniform(0,180),rng.uniform(0,100)
    parts.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rng.uniform(1,3):.1f}" ry=".6" fill="#fff0c7" opacity=".18"/>')
for x,y in [(3,49),(88,3),(174,95),(135,52)]:
    parts.append(f'<path d="M{x-6} {y} Q{x} {y-6} {x+8} {y} Q{x} {y+5} {x-6} {y}" fill="#698554" opacity=".7"/>')
save('courtyard_stone.svg',180,100,parts)
parts=['<defs><radialGradient id="grass"><stop stop-color="#b6c969" stop-opacity=".16"/><stop offset="1" stop-color="#46694c" stop-opacity="0"/></radialGradient></defs>','<rect width="160" height="128" fill="url(#grass)"/>']
for _ in range(70):
    x,y=rng.uniform(3,157),rng.uniform(3,125)
    hue=rng.choice(['#d2d991','#284e35','#8fbe65'])
    parts.append(f'<path d="M{x-2:.1f} {y:.1f} q1 -4 -1 -6 M{x:.1f} {y:.1f} q0 -5 3 -7 M{x+2:.1f} {y:.1f} q2 -2 4 -3" fill="none" stroke="{hue}" stroke-opacity=".22" stroke-width=".9"/>')
for _ in range(12):
    x,y=rng.uniform(0,160),rng.uniform(0,128)
    parts.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rng.uniform(8,22):.1f}" ry="3" fill="#d3d781" opacity=".07"/>')
save('courtyard_grass.svg',160,128,parts)
print('Built two courtyard textures')
