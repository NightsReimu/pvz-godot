"""Reproducible, code-authored courtyard textures; all geometry is original."""
from pathlib import Path
import base64
import random
import subprocess
import tempfile

from build_ancient_world_art import card_svg

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
for variant in range(3):
    slab_rng = random.Random(8167 + variant)
    parts = [
        '<defs><linearGradient id="face" x2=".2" y2="1"><stop stop-color="#b7c1c3"/><stop offset=".55" stop-color="#a3afb2"/><stop offset="1" stop-color="#8d9c9e"/></linearGradient></defs>',
        '<path d="M10 3H150L157 10V117L150 125H10L3 117V10Z" fill="#516164"/>',
        '<path d="M11 3H149L156 10V113L149 120H11L4 113V10Z" fill="url(#face)" stroke="#5b6c71" stroke-width="1.5"/>',
        '<path d="M11 7H148L152 11 M8 13V107" fill="none" stroke="#e3e6de" stroke-opacity=".6" stroke-width="2"/>',
        '<path d="M12 116H146L151 111 M152 14V106" fill="none" stroke="#4d6165" stroke-opacity=".4" stroke-width="2"/>',
        '<path d="M17 20V14H31V19H23V27H17M143 102V108H129V103H137V95H143" fill="none" stroke="#b29a70" stroke-opacity=".64" stroke-width="1.7"/>',
        '<path d="M37 18H124 M18 37V90 M36 105H122 M141 37V87" fill="none" stroke="#647c80" stroke-opacity=".25" stroke-width=".8"/>',
    ]
    for _ in range(130):
        x, y = slab_rng.uniform(12,148), slab_rng.uniform(13,110)
        color = slab_rng.choice(['#fff6df', '#586d71', '#dae0d7'])
        parts.append(f'<path d="M{x:.2f} {y:.2f} l{slab_rng.uniform(1,5):.2f} -.3" stroke="{color}" stroke-opacity=".12" stroke-width=".7"/>')
    crack = [
        'M131 4l-8 8 3 7-12 6',
        'M4 93l13-5 5 4 11-6',
        'M126 119l-6-9 3-5-9-7',
    ][variant]
    parts += [f'<path d="{crack}" fill="none" stroke="#53676b" stroke-opacity=".45" stroke-width="1"/>',
              '<path d="M59 79c-9 0-15-5-15-10s5-8 10-8c0-9 10-13 17-8 5-12 25-11 29 2 10-1 16 6 14 13-2 6-11 11-20 11H59m4-5h29c9 0 15-4 15-8 0-5-7-7-11-4-3-12-15-14-21-5-8-6-14-3-14 6-8-4-15 1-12 6 1 3 6 5 14 5Z" fill="none" stroke="#536e73" stroke-opacity=".17" stroke-width="1.3"/>']
    save(f'courtyard_slab_{variant}.svg',160,128,parts)
print('Built courtyard paving and three carved planting slabs')

# Reuse the existing native SVG card frame around the generated scene. The
# background PNG stays untouched; SVG clipping preserves the UI's alpha border.
project_root = ROOT.parents[2]
scene_path = project_root / 'art/ancient/city_courtyard.png'
if scene_path.is_file():
    with tempfile.TemporaryDirectory() as scratch:
        card_path = Path(scratch) / 'city_card.svg'
        card_path.write_text(card_svg(base64.b64encode(scene_path.read_bytes()).decode()))
        subprocess.run(['rsvg-convert', str(card_path), '-o', str(project_root / 'art/world_ui/world_card_ancient_city.png')], check=True)
    print('Built the ancient city card with the existing SVG frame')
