#!/usr/bin/env python3
"""Paint the Ancient World journal illustration and place it in atlas slot 8.

The scene is authored as layered SVG (sky, ink-wash mountains, pagoda, torii,
temple approach, maples and lanterns), rasterized with rsvg-convert and given a
light painterly finish so it sits beside the illustrated worlds. Re-running is
deterministic; the previous slot contents are never needed again.
"""
from pathlib import Path
import math
import base64
import random
import subprocess
import tempfile

from PIL import Image, ImageFilter, ImageEnhance

ROOT = Path(__file__).resolve().parents[2]
ATLAS = ROOT / 'art/world_ui/world_scene_atlas.png'
SLOT = 7
SIZE = 1000


def grad(gid, stops, x2='0', y2='1'):
    s = ''.join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">{s}</linearGradient>'


def ridge(seed, base, amp, freq, color, opacity=1.0):
    rnd = random.Random(seed)
    pts = []
    phase = rnd.uniform(0, 6)
    for i in range(0, 41):
        x = i * SIZE / 40
        y = base - amp * (0.55 * math.sin(x * freq + phase) + 0.3 * math.sin(x * freq * 2.7 + phase * 2) + 0.15 * math.sin(x * freq * 6.1))
        pts.append(f'{x:.1f},{y:.1f}')
    return f'<polygon points="0,{SIZE} {" ".join(pts)} {SIZE},{SIZE}" fill="{color}" opacity="{opacity}"/>'


def cloud(x, y, w, opacity):
    parts = ''.join(f'<ellipse cx="{x + dx * w:.1f}" cy="{y + dy * w * 0.3:.1f}" rx="{w * r:.1f}" ry="{w * r * 0.55:.1f}"/>' for dx, dy, r in [(-0.5, 0.1, 0.35), (-0.15, -0.2, 0.42), (0.25, -0.05, 0.38), (0.55, 0.15, 0.3)])
    return f'<g fill="#fff6e4" opacity="{opacity}">{parts}</g>'


def pagoda(x, y, s):
    out = ''
    for tier in range(5):
        w = (120 - tier * 16) * s
        yy = y - tier * 54 * s
        out += f'<rect x="{x - w * 0.34:.1f}" y="{yy - 40 * s:.1f}" width="{w * 0.68:.1f}" height="{38 * s:.1f}" fill="#8a4a36"/>'
        out += f'<rect x="{x - w * 0.22:.1f}" y="{yy - 34 * s:.1f}" width="{w * 0.12:.1f}" height="{24 * s:.1f}" fill="#f0d9a6" opacity=".55"/>'
        out += f'<rect x="{x + w * 0.1:.1f}" y="{yy - 34 * s:.1f}" width="{w * 0.12:.1f}" height="{24 * s:.1f}" fill="#f0d9a6" opacity=".55"/>'
        out += f'<path d="M{x - w * 0.72:.1f} {yy - 36 * s:.1f} Q{x - w * 0.5:.1f} {yy - 44 * s:.1f} {x - w * 0.4:.1f} {yy - 56 * s:.1f} L{x + w * 0.4:.1f} {yy - 56 * s:.1f} Q{x + w * 0.5:.1f} {yy - 44 * s:.1f} {x + w * 0.72:.1f} {yy - 36 * s:.1f} Q{x:.1f} {yy - 44 * s:.1f} {x - w * 0.72:.1f} {yy - 36 * s:.1f}Z" fill="#3c4650" stroke="#232a30" stroke-width="{2 * s:.1f}"/>'
    top = y - 5 * 54 * s
    out += f'<line x1="{x}" y1="{top - 2 * s:.1f}" x2="{x}" y2="{top - 70 * s:.1f}" stroke="#3c4650" stroke-width="{5 * s:.1f}"/>'
    for i in range(5):
        out += f'<circle cx="{x}" cy="{top - (12 + i * 11) * s:.1f}" r="{5 * s:.1f}" fill="#c9a24a"/>'
    return out


def torii(x, y, s):
    red = '#d4432f'
    out = ''
    for side in (-1, 1):
        out += f'<rect x="{x + side * 150 * s - 14 * s:.1f}" y="{y:.1f}" width="{28 * s:.1f}" height="{330 * s:.1f}" fill="{red}" stroke="#7a2116" stroke-width="{3 * s:.1f}"/>'
        out += f'<rect x="{x + side * 150 * s - 18 * s:.1f}" y="{y + 306 * s:.1f}" width="{36 * s:.1f}" height="{30 * s:.1f}" fill="#262222"/>'
    out += f'<rect x="{x - 196 * s:.1f}" y="{y + 40 * s:.1f}" width="{392 * s:.1f}" height="{22 * s:.1f}" fill="{red}" stroke="#7a2116" stroke-width="{3 * s:.1f}"/>'
    out += f'<path d="M{x - 250 * s:.1f} {y - 26 * s:.1f} Q{x:.1f} {y - 4 * s:.1f} {x + 250 * s:.1f} {y - 26 * s:.1f} L{x + 232 * s:.1f} {y + 2 * s:.1f} Q{x:.1f} {y + 18 * s:.1f} {x - 232 * s:.1f} {y + 2 * s:.1f}Z" fill="#262222"/>'
    out += f'<path d="M{x - 226 * s:.1f} {y + 2 * s:.1f} Q{x:.1f} {y + 18 * s:.1f} {x + 226 * s:.1f} {y + 2 * s:.1f} L{x + 214 * s:.1f} {y + 20 * s:.1f} Q{x:.1f} {y + 34 * s:.1f} {x - 214 * s:.1f} {y + 20 * s:.1f}Z" fill="{red}"/>'
    out += f'<rect x="{x - 22 * s:.1f}" y="{y + 14 * s:.1f}" width="{44 * s:.1f}" height="{30 * s:.1f}" fill="#262222"/>'
    out += f'<rect x="{x - 16 * s:.1f}" y="{y + 18 * s:.1f}" width="{32 * s:.1f}" height="{22 * s:.1f}" fill="#d9b25a"/>'
    return out


def lantern(x, y, s):
    stone = '#a9a79c'
    return (f'<rect x="{x - 10 * s:.1f}" y="{y - 30 * s:.1f}" width="{20 * s:.1f}" height="{60 * s:.1f}" fill="{stone}" stroke="#56544c" stroke-width="2"/>'
            f'<path d="M{x - 30 * s:.1f} {y - 30 * s:.1f} L{x + 30 * s:.1f} {y - 30 * s:.1f} L{x + 22 * s:.1f} {y - 18 * s:.1f} L{x - 22 * s:.1f} {y - 18 * s:.1f}Z" fill="#8f8d84"/>'
            f'<rect x="{x - 22 * s:.1f}" y="{y - 74 * s:.1f}" width="{44 * s:.1f}" height="{44 * s:.1f}" fill="{stone}" stroke="#56544c" stroke-width="2"/>'
            f'<rect x="{x - 12 * s:.1f}" y="{y - 66 * s:.1f}" width="{24 * s:.1f}" height="{26 * s:.1f}" fill="#ffd27a"/>'
            f'<circle cx="{x:.1f}" cy="{y - 53 * s:.1f}" r="{46 * s:.1f}" fill="#ffd27a" opacity=".18"/>'
            f'<path d="M{x - 40 * s:.1f} {y - 74 * s:.1f} Q{x:.1f} {y - 112 * s:.1f} {x + 40 * s:.1f} {y - 74 * s:.1f}Z" fill="#8f8d84" stroke="#56544c" stroke-width="2"/>'
            f'<circle cx="{x:.1f}" cy="{y - 104 * s:.1f}" r="{7 * s:.1f}" fill="#8f8d84"/>')


def maple(x, y, s, seed, colors, mirror=1, crown=(560, 900)):
    # A trunk rising from the corner with a canopy that frames the top of the page.
    rnd = random.Random(seed)
    m = mirror
    out = f'<path d="M{x:.1f} {y:.1f} Q{x + m * 70 * s:.1f} {y - 260 * s:.1f} {x + m * 20 * s:.1f} {y - 560 * s:.1f}" stroke="#4d3022" stroke-width="{30 * s:.1f}" fill="none" stroke-linecap="round"/>'
    for bx, by, ex, ey, w in [(40, 380, 250, 640, 14), (30, 480, 300, 760, 10), (25, 540, 170, 840, 8)]:
        out += f'<path d="M{x + m * bx * s:.1f} {y - by * s:.1f} Q{x + m * (bx + ex) * 0.5 * s:.1f} {y - (by + ey) * 0.52 * s:.1f} {x + m * ex * s:.1f} {y - ey * s:.1f}" stroke="#4d3022" stroke-width="{w * s:.1f}" fill="none" stroke-linecap="round"/>'
    shade = []
    light = []
    for i in range(90):
        cx = x + m * rnd.uniform(-60, 330) * s
        cy = y - rnd.uniform(crown[0], crown[1]) * s
        r = rnd.uniform(24, 48) * s
        color = rnd.choice(colors)
        shade.append(f'<ellipse cx="{cx + 4:.1f}" cy="{cy + 6:.1f}" rx="{r:.1f}" ry="{r * 0.8:.1f}" fill="#5c2a24" opacity=".35"/>')
        light.append(f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{r:.1f}" ry="{r * 0.8:.1f}" fill="{color}" opacity="{rnd.uniform(0.82, 0.97):.2f}"/>')
        if i % 3 == 0:
            light.append(f'<ellipse cx="{cx - r * 0.3:.1f}" cy="{cy - r * 0.3:.1f}" rx="{r * 0.35:.1f}" ry="{r * 0.22:.1f}" fill="#fff1d0" opacity=".35"/>')
    return out + ''.join(shade) + ''.join(light)


def hall(x, y, s):
    # Temple hall at the end of the approach, partly veiled by mist.
    out = f'<rect x="{x - 150 * s:.1f}" y="{y - 90 * s:.1f}" width="{300 * s:.1f}" height="{90 * s:.1f}" fill="#efe1c2"/>'
    for i in range(6):
        out += f'<rect x="{x - 146 * s + i * 57 * s:.1f}" y="{y - 90 * s:.1f}" width="{12 * s:.1f}" height="{90 * s:.1f}" fill="#c8432f"/>'
    out += f'<path d="M{x - 210 * s:.1f} {y - 86 * s:.1f} Q{x - 150 * s:.1f} {y - 100 * s:.1f} {x - 110 * s:.1f} {y - 150 * s:.1f} L{x + 110 * s:.1f} {y - 150 * s:.1f} Q{x + 150 * s:.1f} {y - 100 * s:.1f} {x + 210 * s:.1f} {y - 86 * s:.1f} Q{x:.1f} {y - 104 * s:.1f} {x - 210 * s:.1f} {y - 86 * s:.1f}Z" fill="#3b4954" stroke="#232a30" stroke-width="3"/>'
    out += f'<line x1="{x - 110 * s:.1f}" y1="{y - 150 * s:.1f}" x2="{x + 110 * s:.1f}" y2="{y - 150 * s:.1f}" stroke="#d8b25c" stroke-width="5"/>'
    return out


def build_svg() -> str:
    defs = '<defs>'
    defs += grad('sky', [(0, '#f6c98c'), (0.45, '#f8dfb4'), (0.75, '#cfe3e6'), (1, '#a9cfd8')])
    defs += grad('path', [(0, '#d9c8a4'), (1, '#a99070')])
    defs += grad('ground', [(0, '#7aa35a'), (1, '#4d7a3f')])
    defs += '<radialGradient id="sun"><stop offset="0" stop-color="#fff6d6"/><stop offset=".5" stop-color="#ffe0a0" stop-opacity=".8"/><stop offset="1" stop-color="#ffd27a" stop-opacity="0"/></radialGradient>'
    defs += '<filter id="soft"><feGaussianBlur stdDeviation="6"/></filter>'
    defs += '<filter id="mist"><feGaussianBlur stdDeviation="18"/></filter>'
    defs += '</defs>'
    body = f'<rect width="{SIZE}" height="{SIZE}" fill="url(#sky)"/>'
    body += '<circle cx="700" cy="250" r="230" fill="url(#sun)"/><circle cx="700" cy="250" r="62" fill="#fff4d8"/>'
    body += cloud(220, 170, 260, 0.75) + cloud(860, 110, 200, 0.6) + cloud(560, 330, 240, 0.45)
    body += ridge(1, 470, 120, 0.006, '#b6c9cf', 0.95)
    body += f'<rect y="430" width="{SIZE}" height="80" fill="#f3efe2" opacity=".55" filter="url(#mist)"/>'
    body += ridge(2, 540, 110, 0.009, '#8fa9ad', 1)
    body += pagoda(745, 612, 0.82)
    body += f'<rect y="540" width="{SIZE}" height="70" fill="#f0ece0" opacity=".5" filter="url(#mist)"/>'
    body += ridge(3, 640, 70, 0.012, '#6f8f78', 1)
    body += f'<rect y="620" width="{SIZE}" height="{SIZE - 620}" fill="url(#ground)"/>'
    # Temple approach: stone path narrowing toward the torii.
    body += '<path d="M330 1000 L470 700 L530 700 L700 1000Z" fill="url(#path)"/>'
    rnd = random.Random(7)
    for i in range(16):
        t = i / 15
        y = 700 + t * t * 300
        w = 60 + t * 360
        for k in range(3):
            cx = 500 + (k - 1) * w * 0.3 + rnd.uniform(-8, 8)
            body += f'<ellipse cx="{cx:.1f}" cy="{y:.1f}" rx="{w * 0.13:.1f}" ry="{4 + t * 14:.1f}" fill="#c2b08c" stroke="#8f7c5c" stroke-width="{1 + t * 2:.1f}"/>'
    body += hall(500, 690, 0.62)
    body += f'<rect y="640" width="{SIZE}" height="60" fill="#f3efe2" opacity=".45" filter="url(#mist)"/>'
    for i in range(140):
        gx = rnd.uniform(0, SIZE)
        gy = rnd.uniform(700, 1000)
        h = 6 + (gy - 700) / 300 * 14
        body += f'<path d="M{gx:.1f} {gy:.1f} q-2 {-h * 0.6:.1f} -4 {-h:.1f} M{gx:.1f} {gy:.1f} q2 {-h * 0.6:.1f} 5 {-h * 0.9:.1f}" stroke="#3f6a35" stroke-width="2" fill="none" opacity=".55"/>'
    body += torii(500, 400, 0.92)
    body += lantern(330, 760, 0.95) + lantern(680, 760, 0.95) + lantern(210, 900, 1.35) + lantern(810, 900, 1.35)
    body += maple(-40, 1060, 1.0, 11, ['#d9573b', '#e9774a', '#f0a04a', '#c8442f'])
    body += maple(1040, 1060, 0.95, 12, ['#e86a8a', '#f29ab0', '#f6c0cc', '#f7d3dc'], -1, (720, 1010))
    # Drifting petals and dandelion seeds.
    for i in range(40):
        x = rnd.uniform(0, SIZE)
        y = rnd.uniform(80, 900)
        r = rnd.uniform(4, 9)
        body += f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{r:.1f}" ry="{r * 0.55:.1f}" fill="{rnd.choice(["#f29ab0", "#f6c0cc", "#e9774a"])}" transform="rotate({rnd.uniform(0, 180):.0f} {x:.1f} {y:.1f})" opacity=".9"/>'
    for i in range(9):
        x = rnd.uniform(150, 850)
        y = rnd.uniform(120, 520)
        rays = ''.join(f'<line x1="{x:.1f}" y1="{y:.1f}" x2="{x + math.cos(a) * 9:.1f}" y2="{y + math.sin(a) * 9:.1f}" stroke="#ffffff" stroke-width="1.4"/>' for a in [math.pi * (1.1 + k * 0.1) for k in range(9)])
        body += f'<g opacity=".85">{rays}<line x1="{x:.1f}" y1="{y:.1f}" x2="{x:.1f}" y2="{y + 14:.1f}" stroke="#d8c9a6" stroke-width="1.2"/></g>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}">{defs}{body}</svg>'


def card_svg(png_b64: str) -> str:
    """Portrait world card: the scene behind a vermilion-and-gold shrine frame."""
    w, h = 460, 560
    frame = ''
    frame += f'<rect x="14" y="14" width="{w - 28}" height="{h - 28}" rx="34" fill="none" stroke="#7a2116" stroke-width="20"/>'
    frame += f'<rect x="14" y="14" width="{w - 28}" height="{h - 28}" rx="34" fill="none" stroke="#d4432f" stroke-width="14"/>'
    frame += f'<rect x="26" y="26" width="{w - 52}" height="{h - 52}" rx="24" fill="none" stroke="#e8c26a" stroke-width="4"/>'
    for x, y in ((40, 40), (w - 40, 40), (40, h - 40), (w - 40, h - 40)):
        frame += f'<circle cx="{x}" cy="{y}" r="13" fill="#e8c26a" stroke="#7a2116" stroke-width="3"/><circle cx="{x}" cy="{y}" r="5" fill="#7a2116"/>'
    frame += f'<path d="M{w / 2 - 70} 12 L{w / 2 + 70} 12 L{w / 2 + 52} 34 L{w / 2 - 52} 34Z" fill="#262222" stroke="#e8c26a" stroke-width="3"/>'
    frame += f'<path d="M{w / 2 - 40} {h - 12} L{w / 2 + 40} {h - 12} L{w / 2 + 28} {h - 34} L{w / 2 - 28} {h - 34}Z" fill="#262222" stroke="#e8c26a" stroke-width="3"/>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<defs><clipPath id="inner"><rect x="20" y="20" width="{w - 40}" height="{h - 40}" rx="30"/></clipPath></defs>'
            f'<g clip-path="url(#inner)"><image x="-130" y="20" width="720" height="720" preserveAspectRatio="xMidYMid slice" xlink:href="data:image/png;base64,{png_b64}"/></g>{frame}</svg>')


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        svg = Path(tmp) / 'ancient.svg'
        png = Path(tmp) / 'ancient.png'
        svg.write_text(build_svg())
        subprocess.run(['rsvg-convert', '-w', '1000', '-h', '1000', str(svg), '-o', str(png)], check=True)
        art = Image.open(png).convert('RGB')
        card_src = Path(tmp) / 'card.svg'
        card_src.write_text(card_svg(base64.b64encode(png.read_bytes()).decode()))
        subprocess.run(['rsvg-convert', str(card_src), '-o', str(ROOT / 'art/world_ui/world_card_ancient.png')], check=True)
    # Painterly finish: soften, posterize lightly through a mode filter, add warmth.
    art = art.filter(ImageFilter.ModeFilter(5)).filter(ImageFilter.SMOOTH_MORE)
    art = ImageEnhance.Color(art).enhance(1.08)
    atlas = Image.open(ATLAS).convert('RGBA')
    tile_w = atlas.width / 4
    tile_h = atlas.height / 2
    box = (round((SLOT % 4) * tile_w), round((SLOT // 4) * tile_h), round((SLOT % 4 + 1) * tile_w), round((SLOT // 4 + 1) * tile_h))
    art = art.resize((box[2] - box[0], box[3] - box[1]), Image.LANCZOS).convert('RGBA')
    atlas.paste(art, box[:2])
    atlas.save(ATLAS)
    print(f'Painted ancient world into atlas slot {SLOT + 1} at {box}')


if __name__ == '__main__':
    main()
