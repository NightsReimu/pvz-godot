#!/usr/bin/env python3
"""Paint the 4-21 Genbu Ravine backdrop procedurally (deterministic).

Genbu (玄武) puns on basalt: hexagonal basalt columns frame a terrace of wet
flagstones. The main fall drops behind the boss lane on the right, a kappa
water wheel and cucumber vines sit on the left bank, and only a light spray
rises at the plunge pool (no visibility fog). The game animates rain on top.
"""

import argparse
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.spatial import cKDTree

ROOT = Path(__file__).resolve().parents[2]
W, H = 1672, 940
SS = 2
w, h = W * SS, H * SS


def noise(width, height, scale, octaves=4, seed=0, stretch=(1.0, 1.0)):
    rng = np.random.default_rng(seed)
    out = np.zeros((height, width), dtype=np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        cy = max(2, int(scale * (2 ** o) * stretch[1]))
        cx = max(2, int(scale * (2 ** o) * width / height * stretch[0]))
        grid = (rng.random((cy, cx)) * 255).astype(np.uint8)
        layer = np.asarray(Image.fromarray(grid).resize((width, height), Image.BICUBIC), dtype=np.float32) / 255.0
        out += layer * amp
        total += amp
        amp *= 0.5
    return out / total


def rgb(hexstr):
    hexstr = hexstr.lstrip('#')
    return np.array([int(hexstr[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def mix(a, b, t):
    return a + (b - a) * t


def over(base, color, alpha):
    alpha = np.clip(alpha, 0, 1)[..., None]
    return base * (1 - alpha) + color * alpha


def layer_alpha(draw_fn):
    """Render a PIL drawing at full resolution and return its RGBA as floats."""
    image = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(image))
    data = np.asarray(image, dtype=np.float32)
    return data[..., :3], data[..., 3] / 255.0


def paste(base, draw_fn, grain=None, grain_strength=0.0):
    color, alpha = layer_alpha(draw_fn)
    if grain is not None:
        color = color * (1 - grain_strength + grain_strength * 2 * grain[..., None])
    return over(base, color, alpha)


# --- Basalt columns ---------------------------------------------------------

def shade(c, k):
    return tuple(int(max(0, min(255, v * k))) for v in c) + (255,)


def column(draw, cx, wd, top, bottom, rng, palette, moss):
    q = wd * 0.25
    cap = wd * 0.16
    light, mid, dark = palette
    cap_pts = [(cx - wd / 2, top), (cx - q, top - cap), (cx + q, top - cap), (cx + wd / 2, top), (cx + q, top + cap), (cx - q, top + cap)]
    tone = 0.86 + rng.random() * 0.24
    draw.polygon([(cx - wd / 2, top), (cx - q, top + cap), (cx - q, bottom), (cx - wd / 2, bottom)], fill=shade(mid, tone))
    draw.polygon([(cx - q, top + cap), (cx + q, top + cap), (cx + q, bottom), (cx - q, bottom)], fill=shade(light, tone))
    draw.polygon([(cx + q, top + cap), (cx + wd / 2, top), (cx + wd / 2, bottom), (cx + q, bottom)], fill=shade(dark, tone))
    mossy = rng.random() < 0.75
    draw.polygon(cap_pts, fill=shade(moss if mossy else light, 1.05 * tone))
    if mossy:
        for _ in range(int(2 + rng.random() * 3)):
            x = cx - q + rng.random() * 2 * q
            drip = cap + rng.random() * wd * 0.45
            draw.line([(x, top + cap), (x, top + cap + drip)], fill=shade(moss, 0.85 * tone), width=max(2, int(wd * 0.06)))
    y = top + cap + wd * (0.9 + rng.random() * 1.2)
    while y < bottom - wd * 0.4:
        crack = shade(dark, 0.55)
        tilt = (rng.random() - 0.5) * wd * 0.12
        draw.line([(cx - wd / 2, y - cap * 0.6), (cx - q, y + tilt), (cx + q, y + tilt), (cx + wd / 2, y - cap * 0.6)], fill=crack, width=max(2, int(wd * 0.035)))
        y += wd * (1.1 + rng.random() * 1.6)
    for x in (cx - q, cx + q):
        draw.line([(x, top + cap), (x, bottom)], fill=shade(dark, 0.6), width=max(1, int(wd * 0.02)))


def column_wall(draw, x0, x1, base_top, bottom, seed, palette, moss, width, rise, step_bias=0.0, inner=None, drop=0.0):
    rng = np.random.default_rng(seed)
    cols = []
    x = x0 - width * 0.3
    height = 0.0
    while x < x1 + width * 0.3:
        wd = width * (0.78 + rng.random() * 0.4)
        height = 0.65 * height + (rng.random() - 0.5) * rise + step_bias
        t = 0.0
        if inner == 'right': t = np.clip((x - x0) / max(1.0, x1 - x0), 0, 1)
        elif inner == 'left': t = np.clip((x1 - x) / max(1.0, x1 - x0), 0, 1)
        cols.append((x + wd / 2, wd, base_top + height + drop * t ** 2.2))
        x += wd * 0.98
    # Draw back-to-front: higher crowns sit further back on a stepped slope.
    for cx, wd, top in sorted(cols, key=lambda c: c[2]):
        column(draw, cx, wd, min(top, bottom - wd), bottom, rng, palette, moss)


# --- Water --------------------------------------------------------------------

def waterfall(base, x0, x1, top, bottom, seed, lip=True):
    ys = np.arange(h, dtype=np.float32)[:, None]
    xs = np.arange(w, dtype=np.float32)[None, :]
    sway = np.sin(ys / (55.0 * SS) + seed) * 4 * SS + np.sin(ys / (23.0 * SS)) * 1.5 * SS
    widen = (ys - top) / max(1.0, bottom - top) * (x1 - x0) * 0.10
    left, right = x0 - widen + sway, x1 + widen + sway
    inside = np.clip((xs - left) / (6 * SS), 0, 1) * np.clip((right - xs) / (6 * SS), 0, 1)
    inside *= np.clip((ys - top) / (8 * SS), 0, 1) * np.clip((bottom - ys) / (40 * SS), 0, 1)
    streaks = noise(w, h, 2.0, 3, seed, stretch=(9.0, 0.35))
    fine = noise(w, h, 4.0, 2, seed + 1, stretch=(14.0, 0.5))
    depth = np.clip((xs - left) / np.maximum(1, right - left), 0, 1)
    body = mix(rgb('3f86ad'), rgb('cdeef9'), np.clip(streaks * 1.1 + fine * 0.35 - 0.15, 0, 1)[..., None])
    body = mix(body, rgb('2a6488'), (np.abs(depth - 0.5) * 0.7)[..., None])
    body = mix(body, rgb('ffffff'), ((fine > 0.66) * 0.55)[..., None])
    out = over(base, body, inside * 0.97)
    if lip:
        foam = np.exp(-((ys - top - 10 * SS) / (10 * SS)) ** 2) * inside
        out = over(out, rgb('f4fbff'), foam * 0.85)
    churn = np.exp(-((ys - bottom + 18 * SS) / (24 * SS)) ** 2) * np.clip((xs - left + 30 * SS) / (20 * SS), 0, 1) * np.clip((right + 30 * SS - xs) / (20 * SS), 0, 1)
    return over(out, rgb('f6fcff'), churn * 0.9)


def flagstones(base, top, bottom, seed):
    rng = np.random.default_rng(seed)
    sub = 1
    gh, gw = h // sub, w // sub
    count = 520
    depth = rng.random(count) ** 0.75
    pts = np.column_stack([rng.random(count) * gw, top / sub + depth * (bottom - top) / sub * 1.06])
    tree = cKDTree(pts)
    gy, gx = np.mgrid[0:gh, 0:gw]
    dist, idx = tree.query(np.column_stack([gx.ravel(), gy.ravel()]), k=2)
    edge = (dist[:, 1] - dist[:, 0]).reshape(gh, gw)
    owner = idx[:, 0].reshape(gh, gw)
    tones = rng.random(count).astype(np.float32)
    wet = (rng.random(count) < 0.18).astype(np.float32)
    up = lambda a, mode=Image.BILINEAR: np.asarray(Image.fromarray(a.astype(np.float32)).resize((w, h), mode), dtype=np.float32)
    edge = up(edge)
    tone = up(tones[owner], Image.NEAREST)
    puddle = up(wet[owner], Image.NEAREST)
    grain = noise(w, h, 18, 3, seed + 3)
    stone = mix(rgb('5e6a6c'), rgb('85908f'), np.clip(tone * 0.6 + grain * 0.5 - 0.1, 0, 1)[..., None])
    stone = mix(stone, rgb('aebfc4'), (puddle * 0.42 * np.clip(grain * 1.4, 0, 1))[..., None])
    grout = np.clip(1 - edge / (2.6 * SS), 0, 1)
    moss_noise = noise(w, h, 6, 3, seed + 5)
    stone = mix(stone, mix(rgb('2c3734'), rgb('3e5a35'), np.clip(moss_noise * 1.4 - 0.5, 0, 1)[..., None]), grout[..., None])
    # Bevel: a pale top lip and a dark lower lip on every slab.
    lip = np.clip(1 - np.abs(edge - 3.6 * SS) / (1.4 * SS), 0, 1)
    stone = mix(stone, rgb('b7c4c6'), (lip * 0.18)[..., None])
    ys = np.arange(h, dtype=np.float32)[:, None]
    mask = np.clip((ys - top) / (10 * SS), 0, 1) * np.clip((bottom - ys) / (10 * SS), 0, 1) * np.ones((1, w), dtype=np.float32)
    return over(base, stone, mask)


# --- Vegetation and props ---------------------------------------------------

def fern(draw, base, length, angle, color, width):
    x, y = base
    pts = []
    for i in range(12):
        t = i / 11
        bend = angle + t * 0.55
        pts.append((x + math.cos(bend) * length * t, y + math.sin(bend) * length * t))
    draw.line(pts, fill=color, width=width)
    for i in range(1, 11):
        t = i / 11
        px, py = pts[i]
        leaf = length * 0.30 * (1 - t * 0.75)
        a = angle + t * 0.55
        for side in (-1, 1):
            la = a + side * 1.15
            tip = (px + math.cos(la) * leaf, py + math.sin(la) * leaf)
            mid = (px + math.cos(la) * leaf * 0.5 + math.cos(a) * leaf * 0.2, py + math.sin(la) * leaf * 0.5 + math.sin(a) * leaf * 0.2)
            draw.polygon([(px, py), mid, tip], fill=color)


def reeds(draw, x, y, rng, count=6):
    for _ in range(count):
        lean = (rng.random() - 0.5) * 0.5
        length = (40 + rng.random() * 50) * SS
        top = (x + math.sin(lean) * length, y - math.cos(lean) * length)
        draw.line([(x, y), top], fill=(78, 120, 66, 255), width=2 * SS)
        x += (rng.random() - 0.5) * 8 * SS


def cucumber_vine(draw, x, y, rng):
    pts = [(x, y)]
    for i in range(10):
        x += (8 + rng.random() * 10) * SS
        y -= (6 + rng.random() * 9) * SS
        pts.append((x + math.sin(i) * 5 * SS, y))
    draw.line(pts, fill=(72, 128, 60, 255), width=3 * SS)
    for i, (px, py) in enumerate(pts[1:]):
        r = (7 + rng.random() * 5) * SS
        draw.ellipse([px - r, py - r * 0.7, px + r, py + r * 0.7], fill=(70, 140, 64, 255))
        if i % 3 == 1:
            draw.ellipse([px - 3 * SS, py - 3 * SS, px + 3 * SS, py + 3 * SS], fill=(242, 212, 80, 255))
        if i % 4 == 2:
            draw.line([(px, py + 4 * SS), (px + 4 * SS, py + 22 * SS)], fill=(84, 150, 62, 255), width=7 * SS)
            draw.line([(px + 1 * SS, py + 8 * SS), (px + 3 * SS, py + 18 * SS)], fill=(170, 220, 120, 255), width=2 * SS)


def water_wheel(draw, cx, cy, r):
    wood = (122, 88, 54, 255)
    dark = (66, 46, 30, 255)
    paddle = (146, 106, 66, 255)
    draw.rectangle([cx - r * 0.12, cy, cx + r * 0.12, cy + r * 1.25], fill=(84, 62, 42, 255))
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=dark, width=int(r * 0.11))
    draw.ellipse([cx - r * 0.80, cy - r * 0.80, cx + r * 0.80, cy + r * 0.80], outline=wood, width=int(r * 0.06))
    for i in range(12):
        a = 0.2 + i * math.tau / 12
        x1, y1 = cx + math.cos(a) * r * 0.16, cy + math.sin(a) * r * 0.16
        x2, y2 = cx + math.cos(a) * r * 0.98, cy + math.sin(a) * r * 0.98
        draw.line([(x1, y1), (x2, y2)], fill=wood, width=int(r * 0.065))
        nx, ny = -math.sin(a) * r * 0.15, math.cos(a) * r * 0.15
        ox, oy = cx + math.cos(a) * r * 1.16, cy + math.sin(a) * r * 1.16
        draw.polygon([(x2 - nx, y2 - ny), (x2 + nx, y2 + ny), (ox + nx, oy + ny), (ox - nx, oy - ny)], fill=paddle, outline=dark)
    draw.ellipse([cx - r * 0.2, cy - r * 0.2, cx + r * 0.2, cy + r * 0.2], fill=(96, 98, 104, 255), outline=(40, 40, 46, 255), width=int(r * 0.05))
    # Water spilling from the paddles back into the stream.
    for k in range(5):
        x = cx - r * 0.9 + k * r * 0.12
        draw.line([(x, cy + r * 0.4), (x - r * 0.05, cy + r * 1.3)], fill=(196, 232, 244, 200), width=int(r * 0.03))


def build(out):
    ys = np.arange(h, dtype=np.float32)[:, None]
    xs = np.arange(w, dtype=np.float32)[None, :]
    img = np.zeros((h, w, 3), dtype=np.float32)
    # Overcast rainy sky and a distant wet forest ridge.
    img[:] = mix(rgb('a7bcc0'), rgb('6b8687'), np.clip(ys / (h * 0.25), 0, 1)[..., None])
    canopy = noise(w, h, 5, 5, 11)
    ridge = h * (0.10 + 0.035 * np.sin(xs / (180 * SS))) + (canopy - 0.5) * h * 0.08
    img = over(img, mix(rgb('2b463e'), rgb('436455'), canopy[..., None]), np.clip((ys - ridge) / (6 * SS), 0, 1) * (ys < h * 0.36))
    grain = noise(w, h, 24, 3, 77)
    # Back basalt wall (atmospheric, bluer) with a slim upper cascade.
    img = paste(img, lambda d: column_wall(d, 0, w, h * 0.12, h * 0.34, 1, ((112, 124, 128), (86, 98, 104), (60, 70, 78)), (86, 118, 82), 40 * SS, 90 * SS), grain, 0.18)
    img = waterfall(img, w * 0.300, w * 0.338, h * 0.02, h * 0.31, 5)
    img = over(img, rgb('3a5a5c'), np.exp(-((ys - h * 0.335) / (h * 0.012)) ** 2) * np.ones((1, w)) * 0.55)
    # Wet flagstone terrace where the board stands.
    img = flagstones(img, h * 0.30, h * 0.94, 9)
    # Left bank and right gorge walls, nearer and darker.
    img = paste(img, lambda d: column_wall(d, 0, w * 0.13, h * 0.18, h * 0.97, 4, ((98, 108, 112), (72, 82, 88), (44, 52, 58)), (74, 108, 70), 46 * SS, 60 * SS, 0, 'right', h * 0.50), grain, 0.22)
    img = paste(img, lambda d: column_wall(d, w * 0.78, w, h * 0.03, h * 0.97, 2, ((98, 108, 112), (72, 82, 88), (44, 52, 58)), (74, 108, 70), 52 * SS, 70 * SS, 0, 'left', h * 0.45), grain, 0.22)
    # The main fall behind the boss lane and its plunge pool.
    img = waterfall(img, w * 0.852, w * 0.948, -10, h * 0.84, 21)
    pool_x, pool_y = w * 0.90, h * 0.875
    pool = np.exp(-(((xs - pool_x) / (w * 0.11)) ** 2 + ((ys - pool_y) / (h * 0.07)) ** 2) * 2.2)
    img = over(img, rgb('3d8aa6'), np.clip(pool * 3, 0, 1))
    ripple = np.sin(np.sqrt(((xs - pool_x) / 1.7) ** 2 + (ys - pool_y) ** 2) / (9 * SS) + noise(w, h, 8, 2, 41) * 6)
    img = over(img, rgb('a9dcec'), np.clip(ripple - 0.6, 0, 1) * pool * 0.9)
    foam = noise(w, h, 22, 2, 43)
    near = np.exp(-(((xs - pool_x) / (w * 0.05)) ** 2 + ((ys - pool_y + h * 0.02) / (h * 0.035)) ** 2))
    img = over(img, rgb('f4fbff'), np.clip((foam - 0.45) * 4, 0, 1) * near)
    # Bottom stream feeding the kappa wheel.
    stream = np.clip((ys - h * 0.935) / (4 * SS), 0, 1) * np.ones((1, w))
    flow = noise(w, h, 3, 3, 13, stretch=(0.25, 3.0))
    img = over(img, mix(rgb('2f7090'), rgb('8fd0e6'), np.clip(flow * 1.3 - 0.25, 0, 1)[..., None]), stream)
    rng = np.random.default_rng(31)

    def props(d):
        water_wheel(d, w * 0.058, h * 0.80, h * 0.11)
        cucumber_vine(d, w * 0.005, h * 0.62, rng)
        for _ in range(7):
            fern(d, (rng.random() * w * 0.10, h * (0.30 + rng.random() * 0.25)), (60 + rng.random() * 60) * SS, -math.pi / 2 - 0.4 + rng.random() * 0.8, (54, 104 + int(rng.random() * 36), 58, 255), 3 * SS)
        for _ in range(8):
            fern(d, (w * (0.80 + rng.random() * 0.05), h * (0.30 + rng.random() * 0.62)), (50 + rng.random() * 60) * SS, -math.pi / 2 - 0.9 + rng.random() * 0.5, (54, 108 + int(rng.random() * 36), 60, 255), 3 * SS)
        for _ in range(14):
            fern(d, (rng.random() * w, h * (0.325 + rng.random() * 0.02)), (22 + rng.random() * 26) * SS, -math.pi / 2 - 0.5 + rng.random(), (64, 116, 64, 255), 2 * SS)
        for k in range(10):
            reeds(d, w * (0.12 + k * 0.075 + rng.random() * 0.03), h * 0.945, rng, 4)
        for _ in range(40):
            x = rng.random() * w
            y = h * (0.92 + rng.random() * 0.03)
            r = (6 + rng.random() * 14) * SS
            s = 96 + int(rng.random() * 50)
            d.ellipse([x - r, y - r * 0.55, x + r, y + r * 0.55], fill=(s, s + 8, s + 12, 255))
            d.arc([x - r, y - r * 0.55, x + r, y + r * 0.55], 200, 330, fill=(214, 232, 236, 255), width=SS)

    img = paste(img, props, grain, 0.12)
    # Light spray only around the plunge pool and upper cascade.
    spray = np.exp(-(((xs - pool_x) / (w * 0.075)) ** 2 + ((ys - h * 0.79) / (h * 0.09)) ** 2))
    spray += 0.6 * np.exp(-(((xs - w * 0.32) / (w * 0.03)) ** 2 + ((ys - h * 0.31) / (h * 0.03)) ** 2))
    img = over(img, rgb('eef8fb'), np.clip(spray, 0, 1) * 0.42)
    # Sparse baked rain; the game layers animated streaks above this.
    rain = Image.new('L', (w, h), 0)
    draw = ImageDraw.Draw(rain)
    for _ in range(260):
        x = rng.random() * w
        y = rng.random() * h
        length = (16 + rng.random() * 22) * SS
        draw.line([(x, y), (x - length * 0.25, y + length)], fill=200, width=SS)
    rain = np.asarray(rain.filter(ImageFilter.GaussianBlur(0.7 * SS)), dtype=np.float32) / 255.0
    img = over(img, rgb('e2eef2'), rain * 0.22)
    img = img * np.array([0.95, 1.0, 1.04], dtype=np.float32)
    vignette = 1 - 0.20 * (((xs / w - 0.5) * 1.7) ** 2 + ((ys / h - 0.5) * 1.5) ** 2)
    img *= np.clip(vignette, 0.72, 1)[..., None]
    final = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).resize((W, H), Image.LANCZOS)
    final = final.filter(ImageFilter.UnsharpMask(radius=1.2, percent=40, threshold=2))
    final.save(out, optimize=True)
    print('wrote', out, final.size)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=ROOT / 'art/backgrounds/nitori_waterfall_4_21.png')
    args = parser.parse_args()
    build(args.out)


if __name__ == '__main__':
    main()
