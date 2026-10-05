"""Anatomy analysis of the base plant art for fusion models.

Every base body is split into its living tissue (the skin painted with the
species' main gradient, which a partner may re-colour), its soil and leaves
(the base), and its face. Eyes, mouth and muzzles are located by rendering
marker colours, so nested transforms (scaled heads, mirrored arms) are honoured.
"""
from pathlib import Path
import colorsys
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

from PIL import Image

import build_vector_unit_art as art
from build_vector_unit_art import INK

EYE = re.compile(r'(<ellipse cx="[-\d.]+" cy="[-\d.]+" rx="([\d.]+)" ry="([\d.]+)" fill=")#283e35(")')
MUZZLES = ('#294e37', '#253c35', '#463347')
GEOMETRY = ('d', 'cx', 'cy', 'rx', 'ry', 'r', 'x', 'y', 'width', 'height', 'points')


def hsv(color):
    color = color.lstrip('#')
    r, g, b = (int(color[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return colorsys.rgb_to_hsv(r, g, b)


def wrap_base():
    """Soil, roots and leaves are tagged so a partner never re-colours them."""
    if getattr(art, '_fusion_wrapped', False):
        return
    original = art.base

    def base(*args, **kwargs):
        return '<g data-part="base">' + original(*args, **kwargs) + '</g>'
    art.base = base
    art._fusion_wrapped = True


def _is_skin(color, light, dark):
    h, s, v = hsv(color)
    lh, ls, lv = hsv(light)
    if ls < 0.1 or s < 0.14 or v < 0.16:
        return False
    dh = abs(h - lh)
    dh = min(dh, 1 - dh)
    dh2 = abs(h - hsv(dark)[0])
    return min(dh, min(dh2, 1 - dh2)) <= 0.085


def _shade(color, light, dark):
    """Position of a colour on the species' light->dark axis (<0 highlight, >1 deep)."""
    lv = hsv(light)[2]
    dv = hsv(dark)[2]
    v = hsv(color)[2]
    if abs(lv - dv) < 0.05:
        return round((lv - v) / 0.3, 2)
    return round((lv - v) / (lv - dv), 2)


def tokenize(body, primary, grads):
    """Return (templated body, slots, mask shapes).

    The primary gradient becomes url(#skin); every solid colour of the same hue
    family outside the base becomes {sN}. A slot keeps its shade position and its
    original colour so the composer can repaint it with any partner's material."""
    light, dark = grads[primary]
    root = ET.fromstring(f'<svg>{body}</svg>')
    slots = []
    index = {}
    shapes = []

    def token(color):
        key = color.lower()
        if key not in index:
            index[key] = len(slots)
            slots.append([_shade(key, light, dark), key])
        return '{s%d}' % index[key]

    def walk(node, transform, in_base):
        for child in node:
            t = transform
            if 'transform' in child.attrib:
                t = (transform + ' ' + child.attrib['transform']).strip()
            base = in_base or child.attrib.get('data-part') == 'base'
            if child.tag == 'g':
                walk(child, t, base)
                continue
            if base:
                if child.attrib.get('fill') == 'url(#leaf)':
                    child.set('fill', 'url(#lf)')
                continue
            if child.attrib.get('opacity') and child.attrib.get('fill', '').startswith('#233e2b'):
                continue
            if child.attrib.get('fill') == f'url(#{primary})':
                child.set('fill', 'url(#skin)')
                geo = ' '.join(f'{k}="{child.attrib[k]}"' for k in GEOMETRY if k in child.attrib)
                shapes.append((child.tag, geo, t))
            for attr in ('fill', 'stroke'):
                color = child.attrib.get(attr, '')
                if re.fullmatch(r'#[0-9a-fA-F]{6}', color) and color.lower() != INK and _is_skin(color, light, dark):
                    child.set(attr, token(color))
    walk(root, '', False)
    templated = ''.join(ET.tostring(child, encoding='unicode') for child in root)
    templated = templated.replace(' />', '/>')
    return templated, slots, shapes


def mask_svg(shapes):
    out = ''
    for tag, geo, t in shapes:
        tr = f' transform="{t}"' if t else ''
        out += f'<{tag} {geo}{tr} fill="#fff" stroke="#000" stroke-width="2.6"/>'
    return out


def _render(defs, body, tmp, name):
    svg = Path(tmp) / f'{name}.svg'
    png = Path(tmp) / f'{name}.png'
    svg.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="384" height="448" viewBox="-48 -60 96 112">{defs}{body}</svg>')
    subprocess.run(['rsvg-convert', str(svg), '-o', str(png)], check=True)
    return Image.open(png).convert('RGBA')


def _clusters(img, test):
    w, h = img.size
    px = img.load()
    seen = set()
    found = []
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if (x, y) in seen or not test(px[x, y]):
                continue
            stack = [(x, y)]
            seen.add((x, y))
            pts = []
            while stack:
                cx, cy = stack.pop()
                pts.append((cx, cy))
                for nx, ny in ((cx + 2, cy), (cx - 2, cy), (cx, cy + 2), (cx, cy - 2)):
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and test(px[nx, ny]):
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            if len(pts) >= 3:
                xs = [p[0] for p in pts]
                ys = [p[1] for p in pts]
                found.append(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (max(xs) - min(xs)) / 2 + 1, (max(ys) - min(ys)) / 2 + 1))
    return found


def _units(x, y, w, h):
    return round(-48 + x * 96 / w, 1), round(-60 + y * 112 / h, 1)


def measure(kind, body, skin_marked, defs):
    """Anchors, eyes, mouth, muzzles and skin box of one host body in model units."""
    with tempfile.TemporaryDirectory() as tmp:
        img = _render(defs, body, tmp, 'b')
        marked = EYE.sub(lambda m: m.group(1) + '#ff00ff' + m.group(4) if float(m.group(2)) <= 4.6 and float(m.group(3)) <= 6.6 else m.group(0), body)
        for color in MUZZLES:
            marked = marked.replace(f'fill="{color}"', 'fill="#00ffff"')
        mimg = _render(defs, marked, tmp, 'm')
        simg = _render(defs, skin_marked, tmp, 's')
        w, h = img.size
        sp = simg.load()
        hits = [(x, y) for y in range(0, h, 2) for x in range(0, w, 2) if sp[x, y][0] > 200 and sp[x, y][1] < 60 and sp[x, y][2] > 200 and sp[x, y][3] > 200]
        if hits:
            x0, y0 = _units(min(x for x, _ in hits), min(y for _, y in hits), w, h)
            x1, y1 = _units(max(x for x, _ in hits), max(y for _, y in hits), w, h)
            box = [x0, y0, x1, y1]
        else:
            box = [-20.0, -30.0, 20.0, 20.0]
        alpha = img.split()[3].load()
        magenta = lambda p: p[0] > 200 and p[1] < 80 and p[2] > 200 and p[3] > 200
        cyan = lambda p: p[0] < 80 and p[1] > 200 and p[2] > 200 and p[3] > 200
        eyes = [e for e in _clusters(mimg, magenta) if e[1] < h * 0.86]
        muzzles = _clusters(mimg, cyan)
    eye_units = []
    for x, y, rx, ry in eyes:
        ux, uy = _units(x, y, w, h)
        eye_units.append([ux, uy, round(rx * 96 / w, 1), round(ry * 112 / h, 1)])
    if kind in EYE_OVERRIDES:
        eye_units = [list(e) for e in EYE_OVERRIDES[kind]]
    muzzle_units = []
    for x, y, rx, ry in muzzles:
        ux, uy = _units(x, y, w, h)
        muzzle_units.append([ux, uy, round(max(rx * 96 / w, ry * 112 / h), 1)])
    # The main face: the largest pair of level eyes, else the largest eye.
    face = None
    best = -1.0
    for i, a in enumerate(eye_units):
        for b in eye_units[i + 1:]:
            if abs(a[1] - b[1]) < 3.5 and abs(a[0] - b[0]) < 20:
                size = a[3] + b[3] - (a[1] + b[1]) * 0.02
                if size > best:
                    best = size
                    face = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[3] + b[3]) / 2, abs(a[0] - b[0]), True)
    if face is None and eye_units:
        e = max(eye_units, key=lambda e: e[3] - e[1] * 0.02)
        face = (e[0], e[1], e[3], 0.0, False)
    if face is None:
        cols = [(x, y) for y in range(0, int(h * 0.7), 3) for x in range(0, w, 3) if alpha[x, y] > 96]
        cx = sum(x for x, _ in cols) / max(1, len(cols))
        cy = (min(y for _, y in cols) + 50) if cols else h * 0.4
        ux, uy = _units(cx, cy, w, h)
        face = (ux, uy, 4.0, 10.0, True)
    fx, fy, eye_ry, spacing, frontal = face
    px = int((fx + 48) * w / 96)
    py = int((fy + 60) * h / 112)
    top = py
    gap = 0
    for y in range(py, -1, -1):
        if alpha[max(0, min(w - 1, px)), y] > 64:
            top = y
            gap = 0
        else:
            gap += 1
            if gap > 6:
                break

    def edge(step):
        x = px
        last = px
        gap = 0
        limit = int(21 * w / 96)
        while 0 <= x < w and abs(x - px) < limit:
            if alpha[x, py] > 64:
                last = x
                gap = 0
            else:
                gap += 1
                if gap > 5:
                    break
            x += step
        return last
    left = round(-48 + edge(-1) * 96 / w, 1)
    right = round(-48 + edge(1) * 96 / w, 1)
    crown_y = round(-60 + top * 112 / h, 1)
    anchors = [round(fx, 1), crown_y, left, right, round(fy, 1), round(fy + 14, 1)]
    if frontal:
        mouth = [round(fx, 1), round(fy + eye_ry * 1.9 + 2.5, 1)]
    else:
        mouth = [round(fx + 8, 1), round(fy + eye_ry + 3, 1)]
    head = round(max(0.55, min(1.15, eye_ry / 4.4)), 2)
    if kind in MOUTH_OVERRIDES:
        mouth = list(MOUTH_OVERRIDES[kind])
    if kind == 'torchwood':
        anchors = [0.0, -24.0, -18.0, 18.0, 11.0, 22.0]
        mouth = [0.0, 21.0]
    return {'anchors': anchors, 'eyes': eye_units, 'mouth': mouth, 'muzzles': muzzle_units, 'head': head, 'frontal': frontal, 'box': box}


# Faces drawn without ink-ellipse eyes (spirals, carved pumpkin, glowing stump).
EYE_OVERRIDES = {
    'hypno_shroom': [[-6.0, 13.0, 4.0, 5.0], [6.0, 13.0, 4.0, 5.0]],
    'chaos_shroom': [[-6.0, 13.0, 4.0, 5.0], [6.0, 13.0, 4.0, 5.0]],
    'pumpkin': [[-12.0, 4.0, 4.0, 4.0], [12.0, 4.0, 4.0, 4.0]],
    'torchwood': [[-7.0, 11.0, 4.0, 5.0], [7.0, 11.0, 4.0, 5.0]],
    'electric_bonk_choy': [[-5.5, -15.0, 4.4, 5.0], [7.5, -15.0, 4.4, 5.0]],
    'samsara_eye': [[0.0, -14.0, 10.5, 10.5]],
}
# Jaws open on the lawn side; a borrowed barrel is spat out from inside them.
MOUTH_OVERRIDES = {'chomper': [10.0, -12.0], 'grave_buster': [8.0, -3.0], 'dragon_fruit': [0.0, 4.0]}


def dominant_gradient(body, defs, avoid=()):
    """The gradient covering the largest living area outside the base."""
    root = ET.fromstring(f'<svg>{body}</svg>')
    used = set()

    def walk(node):
        for child in node:
            if child.attrib.get('data-part') == 'base':
                continue
            match = re.fullmatch(r'url\(#(\w+)\)', child.attrib.get('fill', ''))
            if match:
                used.add(match.group(1))
            walk(child)
    walk(root)
    best, area = 'leaf', -1
    with tempfile.TemporaryDirectory() as tmp:
        for gid in sorted(used):
            if gid in avoid:
                continue
            marked = re.sub(r'<g data-part="base">', '<g data-part="base" opacity="0">', body).replace(f'url(#{gid})', '#ff00ff')
            px = _render(defs, marked, tmp, 'g').load()
            count = sum(1 for y in range(0, 448, 3) for x in range(0, 384, 3) if px[x, y][0] > 200 and px[x, y][1] < 60 and px[x, y][2] > 200 and px[x, y][3] > 200)
            if count > area:
                best, area = gid, count
    return best
