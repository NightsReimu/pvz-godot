"""Accessories and mouth weapons each species lends a fusion.

Accessories are drawn around their own origin for a slot:
  crown  bottom centre sits on the host's head      halo   centred on the head, behind
  side   attach point on the lawn side               back   attach point behind the host
  front  centred on the chest, in front              base   soil centre, behind the feet
  orbit  floating companions centred on the head
Mouth weapons start at the host's mouth and point at the lawn. Their barrels use
url(#skin), {sd} and {sl}, so they grow from the hybrid's own tissue.
"""
import math

import build_vector_unit_art as art
from build_vector_unit_art import path, ell, group, line, leaf, eye, star, crystal, petal, INK

def snout(col='url(#pea)', length=13, ring='#294e37', extra=''):
    b = path(f'M-2 -6 Q{length * 0.5:.1f} -8 {length} -7 L{length} 7 Q{length * 0.5:.1f} 8 -2 6Z', col, INK, 1.6)
    b += ell(length, 0, 5, 8, col, INK, 1.5) + ell(length + 1, 0, 2.6, 5, ring) + ell(length + 1, -1.5, 1, 1.8, '#112f2a')
    return b + extra


def pea_head(col, crest=''):
    b = path('M-12 -9 C-20 -12 -18 -26 -6 -26 C4 -28 12 -20 12 -13 L19 -15 Q24 -14 24 -8 Q24 -2 19 -2 L10 -5 C7 4 -6 6 -12 -1 Z', col, INK, 1.5)
    b += ell(20, -8.5, 4.5, 6.5, col, INK, 1.2) + ell(21.5, -8.5, 2.2, 4, '#294e37')
    b += eye(-4, -16, 2, 3.4) + crest
    return b


def cap(col, w=17, h=14, spots=3, shape='dome', seed=0):
    if shape == 'jag':
        d = f'M{-w} 0 L{-w + 3} {-h * 0.6:.1f} L{-w * 0.5:.1f} {-h * 0.5:.1f} L{-w * 0.25:.1f} {-h} L0 {-h * 0.62:.1f} L{w * 0.3:.1f} {-h * 1.05:.1f} L{w * 0.55:.1f} {-h * 0.5:.1f} L{w - 2} {-h * 0.7:.1f} L{w} 0 Q0 4 {-w} 0Z'
    elif shape == 'tall':
        d = f'M{-w * 0.75:.1f} 0 Q{-w * 0.9:.1f} {-h * 1.6:.1f} 0 {-h * 1.7:.1f} Q{w * 0.9:.1f} {-h * 1.6:.1f} {w * 0.75:.1f} 0 Q0 4 {-w * 0.75:.1f} 0Z'
    elif shape == 'wave':
        d = f'M{-w} 0 Q{-w} {-h:.1f} 0 {-h} Q{w} {-h:.1f} {w} 0 Q{w * 0.6:.1f} 4 {w * 0.3:.1f} 0 Q0 4 {-w * 0.3:.1f} 0 Q{-w * 0.6:.1f} 4 {-w} 0Z'
    elif shape == 'facet':
        d = f'M{-w} 0 L{-w * 0.6:.1f} {-h * 0.85:.1f} L{w * 0.1:.1f} {-h * 1.1:.1f} L{w * 0.8:.1f} {-h * 0.7:.1f} L{w} 0Z'
    else:
        d = f'M{-w} 0 C{-w - 1} {-h * 0.9:.1f} {-w * 0.5:.1f} {-h * 1.2:.1f} 0 {-h * 1.15:.1f} C{w * 0.5:.1f} {-h * 1.2:.1f} {w + 1} {-h * 0.9:.1f} {w} 0 Q0 4 {-w} 0Z'
    b = path(d, col, INK, 1.7)
    b += path(f'M{-w * 0.7:.1f} {-h * 0.35:.1f} Q{-w * 0.6:.1f} {-h * 0.85:.1f} {-w * 0.1:.1f} {-h * 0.95:.1f}', 'none', '#ffffff', 1.6, opacity='.4')
    for i in range(spots):
        a = (i + 0.5) / spots
        x = -w * 0.7 + a * w * 1.4
        y = -h * (0.45 + 0.25 * math.sin(i * 2.1 + seed))
        b += ell(round(x, 1), round(y, 1), 2.2 + (i + seed) % 2, 1.6, '#fff1dc', 'none', 0)
    return b


def petal_ring(col, count=12, length=24, width=7, inner='', double=True):
    b = ''
    for i in range(count):
        b += petal(0, 0, i * 360 / count + 360 / count / 2, length, width, col)
    if double:
        for i in range(count):
            b += petal(0, 0, i * 360 / count, length - 4, width - 0.5, col)
    return b + inner


def armor_plate(col, w=17, h=19, lines=3, studs=0):
    b = path(f'M{-w} {-h * 0.55:.1f} Q0 {-h * 0.85:.1f} {w} {-h * 0.55:.1f} L{w * 0.85:.1f} {h * 0.55:.1f} Q0 {h * 0.85:.1f} {-w * 0.85:.1f} {h * 0.55:.1f}Z', col, INK, 1.7)
    for i in range(lines):
        y = -h * 0.35 + i * h * 0.7 / max(1, lines - 1)
        b += line(f'M{-w * 0.75:.1f} {y:.1f} Q0 {y + 3:.1f} {w * 0.75:.1f} {y:.1f}', '#7b5a3a', 1)
    for i in range(studs):
        b += ell(-w * 0.6 + i * w * 1.2 / max(1, studs - 1), 0, 1.6, 1.6, '#efe2c2', INK, 0.6)
    return b


def catapult(ammo, col='url(#bark)', reach=20):
    b = path(f'M0 0 Q{-reach * 0.4:.1f} {-reach * 0.6:.1f} {-reach} {-reach * 0.9:.1f}', 'none', INK, 5)
    b += path(f'M0 0 Q{-reach * 0.4:.1f} {-reach * 0.6:.1f} {-reach} {-reach * 0.9:.1f}', 'none', '#c99a5c', 3)
    b += path(f'M{-reach - 8} {-reach * 0.9 - 2:.1f} Q{-reach} {-reach * 0.9 + 6:.1f} {-reach + 8} {-reach * 0.9 - 2:.1f}', col, INK, 1.3)
    return b + group(ammo, f'translate({-reach} {-reach * 0.9 - 8:.1f})')


def lotus_seat(col, count=7, inner='#ffe9a8', extra=''):
    b = ell(0, 2, 30, 6, 'url(#mint)', INK, 1.3)
    for i in range(count):
        a = -70 + i * 140 / (count - 1)
        b += petal(math.sin(math.radians(a)) * 14, 4, a, 20, 8, col)
    return b + ell(0, 2, 10, 3.5, inner, INK, 0.9) + extra


def vine_coil(col='url(#leaf)', turns=2, height=36, thick=4):
    pts = []
    for i in range(turns * 8 + 1):
        t = i / (turns * 8)
        pts.append((math.sin(t * turns * math.tau) * 16, -t * height))
    d = 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts)
    return path(d, 'none', INK, thick + 2) + path(d, 'none', '#6aa04f', thick) + ''.join(leaf(x, y, (i * 70) % 360, 9, col) for i, (x, y) in enumerate(pts[::4]))


def flame(x=0, y=0, s=1.0):
    return group(path('M0 8 Q-12 2 -7 -9 Q-3 -5 0 -21 Q12 -9 7 0 Q6 8 0 8Z', 'url(#flame)', INK, 1.2) + path('M0 6 Q-6 0 1 -8 Q6 2 0 6Z', '#fff1b0', 'none'), f'translate({x} {y}) scale({s})')


def bolt(x=0, y=0, s=1.0, col='url(#gold)'):
    return group(path('M-1 -14 L-9 1 L-2 1 L-6 14 L8 -3 L1 -3 L5 -14Z', col, INK, 1.1), f'translate({x} {y}) scale({s})')


def magnet(x=0, y=0, s=1.0, col='#d86761'):
    return group(path('M-9 -10 L-3 -10 L-3 2 Q0 7 3 2 L3 -10 L9 -10 L9 3 Q0 18 -9 3Z', col, INK, 1.3) + path('M-9 -10 L-3 -10 L-3 -6 L-9 -6Z M3 -10 L9 -10 L9 -6 L3 -6Z', '#dfe7e8', INK, 0.8), f'translate({x} {y}) scale({s})')


def wings(col='#f7f4ea'):
    b = ''
    for side in (-1, 1):
        b += path(f'M0 0 Q{side * 18} -20 {side * 36} -14 Q{side * 30} -6 {side * 34} 0 Q{side * 24} 2 {side * 28} 8 Q{side * 14} 10 0 4Z', col, INK, 1.3)
        b += line(f'M{side * 6} -2 Q{side * 18} -10 {side * 30} -10 M{side * 6} 2 Q{side * 18} -2 {side * 26} 2', '#c9c3b4', 0.9)
    return b


def mini_shroom(col, shape='dome', w=17, h=12, spots=2, seed=0):
    stalk = path('M-4 0 Q-5 -8 -3 -12 L3 -12 Q5 -8 4 0Z', 'url(#cream)', INK, 1.2)
    return stalk + group(cap(col, round(w * 0.6, 1), round(h * 0.66, 1), spots, shape, seed), 'translate(0 -11)') + eye(-2, -5, 1, 1.6) + eye(2, -5, 1, 1.6)


GRAFTS = {}


def graft(kinds, slot, size=1.0, alt=None):
    def register(fn):
        for kind in kinds.split():
            GRAFTS[kind] = {'slot': slot, 'fn': fn, 'size': size, 'alt': alt}
        return fn
    return register


# --- pea family: snouts on the lawn side
@graft('peashooter', 'side')
def g_peashooter(kind):
    return snout('url(#pea)')


@graft('repeater', 'side')
def g_repeater(kind):
    return group(snout('url(#pea)', 12), 'translate(0 -6) scale(.85)') + group(snout('url(#pea)', 15), 'translate(0 6) scale(.85)') + leaf(-2, -12, 60, 12)


@graft('threepeater', 'side')
def g_threepeater(kind):
    return ''.join(group(snout('url(#pea)', 11), f'translate(0 {dy}) rotate({a}) scale(.7)') for dy, a in ((-10, -18), (0, 0), (10, 18)))


@graft('split_pea', 'side')
def g_split_pea(kind):
    return snout('url(#pea)', 12) + group(snout('url(#pea)', 10), 'translate(-26 4) matrix(-1 0 0 1 0 0) scale(.8)')


@graft('snow_pea', 'side')
def g_snow_pea(kind):
    return snout('url(#ice)', 13, '#2f5f74') + crystal(4, -6, 12, angle=-15) + crystal(9, -5, 9, angle=20)


@graft('amber_shooter', 'side')
def g_amber(kind):
    return snout('url(#gold)', 14, '#8a4d1b') + ell(6, 0, 3.5, 4.5, '#f7ac42', INK, 1) + flame(8, -9, 0.42)


@graft('shadow_pea', 'side')
def g_shadow_pea(kind):
    return snout('url(#plum)', 14, '#2b2140') + path('M2 -8 Q-6 -16 2 -20 Q-1 -14 8 -10Z', '#bca6ee', INK, 0.8)


@graft('prism_pea', 'side')
def g_prism_pea(kind):
    return snout('url(#mint)', 12, '#20594f') + crystal(16, 0, 14, 'url(#gem)', 90)


@graft('plasma_shooter', 'side')
def g_plasma(kind):
    return snout('url(#mint)', 14, '#155460') + path('M4 -9 Q0 0 4 9 M9 -9 Q5 0 9 9', 'none', '#62dceb', 2) + ell(15, 0, 2.6, 4.6, '#b3fcf2')


@graft('sakura_shooter', 'side')
def g_sakura(kind):
    return snout('url(#rose)', 13, '#6d2b44') + art.flower_small(2, -9, 'url(#lotusp)')


@graft('heather_shooter', 'side')
def g_heather(kind):
    return snout('url(#mint)', 13, '#244c48') + art.flower_small(0, -9, 'url(#violet)') + art.flower_small(6, 9, 'url(#rose)')


@graft('chambord_sniper', 'side')
def g_sniper(kind):
    b = path('M-2 -4 L26 -4 L26 3 L-2 4Z', 'url(#plum)', INK, 1.4) + ell(26, -0.5, 2.5, 4.5, '#2b2140', INK, 1)
    return b + path('M4 -5 L4 -12 L18 -12 L18 -5Z', '#536a61', INK, 1.1) + ell(18, -8.5, 2.2, 3.4, '#bed5c8', INK, 0.8)


# --- sun producers: petal halos behind the head
@graft('sunflower', 'halo')
def g_sunflower(kind):
    return petal_ring('url(#gold)', 12, 25, 6.5)


@graft('marigold', 'halo')
def g_marigold(kind):
    return petal_ring('url(#fire)', 10, 23, 8)


@graft('thermal_sunflower', 'halo')
def g_thermal(kind):
    return petal_ring('url(#fire)', 12, 25, 6) + flame(-14, -22, 0.4) + flame(14, -24, 0.45)


@graft('galaxy_sunflower', 'halo')
def g_galaxy(kind):
    return petal_ring('url(#violet)', 12, 25, 6.5) + star(-22, -18, 4, '#e4baf9') + star(23, -14, 3, '#c4deff')


@graft('soul_flower', 'halo')
def g_soul(kind):
    return petal_ring('url(#violet)', 8, 22, 8, double=False) + path('M-24 -20 Q-30 -10 -22 -9 Q-16 -12 -19 -18 L-21 -26Z', '#b7d5e5', INK, 0.8)


@graft('solar_emperor', 'crown')
def g_solar(kind):
    return path('M-12 0 L-15 -14 L-6 -8 L0 -18 L6 -8 L15 -14 L12 0Z', 'url(#gold)', INK, 1.3) + ell(0, -6, 2.2, 2.8, '#ce6f4a') + ell(-8, -3, 1.4, 1.4, '#9bd6f2') + ell(8, -3, 1.4, 1.4, '#9bd6f2')


@graft('sun_bean', 'crown')
def g_sun_bean(kind):
    return line('M0 0 Q-2 -6 0 -10', '#5d8a3e', 2) + group(petal_ring('url(#gold)', 8, 9, 3.5, double=False), 'translate(0 -14)') + ell(0, -14, 4, 4, 'url(#sun)', INK, 1)


@graft('honey_blossom', 'halo')
def g_honey(kind):
    b = petal_ring('url(#gold)', 9, 22, 7.5, double=False)
    return b + path('M18 8 l5 -3 5 3 v6 l-5 3 -5 -3Z', 'url(#honey)', INK, 1) + path('M23 17 q1 4 0 6', 'none', '#e0a83a', 2)


@graft('hive_flower', 'back')
def g_hive(kind):
    b = path('M0 -2 Q-14 -4 -16 -14 Q-14 -26 0 -26 Q10 -24 10 -14 Q8 -4 0 -2Z', 'url(#honey)', INK, 1.4)
    for y in (-20, -14, -8):
        b += line(f'M-14 {y} Q-3 {y + 2} 9 {y}', '#a46b23', 1)
    b += ell(-3, -12, 2.5, 3, '#4a2d14')
    return b + path('M-22 -30 q3 -3 6 0 q-3 3 -6 0Z', '#f4d35a', INK, 0.6) + ell(-19, -31, 2, 1.2, '#ffffff', INK, 0.4)


@graft('moon_lotus', 'base')
def g_moon_lotus(kind):
    return lotus_seat('url(#violet)', 7, '#f2e9b5', path('M-26 -10 Q-20 -18 -12 -14 Q-18 -16 -20 -8Z', '#f2e9b5', INK, 0.8))


# --- walls and shells: armor in front of the chest
@graft('wallnut', 'front')
def g_wallnut(kind):
    return armor_plate('url(#bark)', 15, 18, 2) + path('M-8 -6 q-3 4 0 8 M7 -4 q3 3 1 7', 'none', '#9a713e', 1)


@graft('tallnut', 'back')
def g_tallnut(kind):
    b = path('M-6 4 Q-14 -10 -12 -34 Q-6 -46 4 -44 Q12 -40 10 -16 Q8 2 -6 4Z', 'url(#bark)', INK, 1.8)
    return b + path('M-8 -30 Q-10 -18 -6 -6', 'none', '#eac78a', 2) + line('M2 -38 q3 3 2 7 M-2 -20 q3 2 2 6', '#9a713e', 1)


@graft('brick_guard', 'crown')
def g_brick(kind):
    b = path('M-15 0 L-15 -10 L-10 -10 L-10 -15 L-4 -15 L-4 -10 L4 -10 L4 -15 L10 -15 L10 -10 L15 -10 L15 0Z', '#a16e49', INK, 1.4)
    return b + line('M-15 -5 H15 M-6 -10 V-5 M6 -5 V0', '#754b37', 1)


@graft('holo_nut', 'orbit')
def g_holo(kind):
    return ell(0, 0, 30, 30, 'none', '#7ef0d0', 1.6) + ell(0, 0, 26, 26, 'none', '#bcffea', 0.8) + path('M-28 -6 h6 v-4 h-8 M22 10 h6 v4 h-9', 'none', '#737dbf', 2.2)


@graft('glitch_walnut', 'front')
def g_glitch(kind):
    b = armor_plate('url(#mint)', 14, 17, 2)
    for x, y in ((-12, -10), (6, -4), (-4, 6), (10, 8)):
        b += path(f'M{x} {y} h5 v4 h-5Z', '#737dbf', 'none')
    return b


@graft('crystal_nut', 'front')
def g_crystal_nut(kind):
    return crystal(-8, 10, 20, angle=-16) + crystal(0, 8, 24) + crystal(9, 10, 19, angle=18)


@graft('pumice_wall', 'front')
def g_pumice(kind):
    b = armor_plate('url(#stone)', 15, 18, 0)
    for x, y, r in ((-7, -6, 2.6), (6, -2, 2.2), (-2, 6, 3), (8, 8, 1.8)):
        b += ell(x, y, r, r * 0.7, '#727d6f')
    return b


@graft('rock_armor_fruit', 'front')
def g_rock(kind):
    return path('M-18 -8 L-10 -16 L-2 -12 L-4 -2 L-16 2Z', 'url(#stone)', INK, 1.3) + path('M18 -8 L12 -16 L3 -14 L5 -3 L17 1Z', 'url(#stone)', INK, 1.3)


@graft('pumpkin', 'base')
def g_pumpkin(kind):
    b = ''
    for x, rx in ((-20, 12), (20, 12), (-9, 13), (9, 13)):
        b += ell(x, -8, rx, 14, 'url(#fire)', INK, 1.3)
    return b + path('M-4 -22 L-2 -30 Q5 -32 6 -28 L2 -22Z', 'url(#leaf)', INK, 1)


@graft('cactus_guard', 'front')
def g_cactus_guard(kind):
    b = path('M-14 -10 L0 -14 L14 -10 L12 8 L0 14 L-12 8Z', 'url(#bark)', INK, 1.5)
    return b + ''.join(line(f'M{x} {y} l{4 if x > 0 else -4} -3', '#f0e8bc', 1.2) for x, y in ((-12, -4), (12, -4), (-10, 6), (10, 6)))


# --- mushrooms: caps, with a companion sprout when the host is a mushroom
SHROOM_CAPS = {
    'puff_shroom': ('url(#violet)', 14, 11, 3, 'dome'), 'sun_shroom': ('url(#gold)', 15, 12, 3, 'dome'),
    'fume_shroom': ('url(#plum)', 19, 13, 4, 'dome'), 'hypno_shroom': ('url(#hypno)', 18, 13, 0, 'wave'),
    'scaredy_shroom': ('url(#plum)', 13, 12, 3, 'tall'), 'ice_shroom': ('url(#ice)', 18, 12, 0, 'jag'),
    'doom_shroom': ('url(#night)', 19, 13, 0, 'dome'), 'sea_shroom': ('url(#sea)', 16, 12, 2, 'wave'),
    'magnet_shroom': ('url(#rose)', 15, 11, 2, 'dome'), 'nether_shroom': ('url(#night)', 16, 12, 2, 'jag'),
    'void_shroom': ('url(#night)', 17, 12, 0, 'wave'), 'mirror_shroom': ('url(#ice)', 17, 12, 0, 'facet'),
    'plasma_shroom': ('url(#violet)', 16, 12, 2, 'dome'), 'chaos_shroom': ('url(#rose)', 17, 13, 1, 'jag'),
}


def shroom_graft(kind):
    col, w, h, spots, shape = SHROOM_CAPS[kind]
    b = cap(col, w, h, spots, shape, len(kind))
    if kind == 'sun_shroom':
        b += ''.join(line(f'M{x} {-h - 2} L{x * 1.2:.1f} {-h - 7}', '#ffe59b', 2) for x in (-8, 0, 8))
    if kind == 'hypno_shroom':
        b += path(f'M-6 {-h * 0.5:.1f} C-2 {-h:.1f} 6 {-h * 0.8:.1f} 4 {-h * 0.45:.1f} C2 {-h * 0.2:.1f} -3 {-h * 0.3:.1f} -1 {-h * 0.5:.1f}', 'none', '#9b4eae', 1.6)
    if kind == 'doom_shroom':
        b += line(f'M-10 {-h * 0.6:.1f} l5 -4 2 5 M4 {-h * 0.9:.1f} l-1 5 5 3', '#9c6674', 1.6)
    if kind == 'magnet_shroom':
        b += magnet(0, -h - 4, 0.7)
    if kind == 'nether_shroom':
        b += path(f'M{-w + 2} {-h * 0.6:.1f} L{-w - 4} {-h * 1.4:.1f} L{-w + 7} {-h * 0.95:.1f}Z M{w - 2} {-h * 0.6:.1f} L{w + 4} {-h * 1.4:.1f} L{w - 7} {-h * 0.95:.1f}Z', 'url(#night)', INK, 1)
    if kind == 'void_shroom':
        b += ell(0, -h * 0.55, 6, 3.5, '#262e45', '#bba5d3', 1.2)
    if kind == 'mirror_shroom':
        b += line(f'M{-w * 0.5:.1f} {-h * 0.7:.1f} L0 -2 M{w * 0.2:.1f} {-h:.1f} L{w * 0.4:.1f} -2', '#e5ffff', 1.2)
    if kind == 'plasma_shroom':
        b += path(f'M-4 {-h * 0.8:.1f} L3 {-h * 0.9:.1f} L0 {-h * 0.55:.1f} L6 {-h * 0.6:.1f} L-1 -2 L1 {-h * 0.4:.1f} L-5 {-h * 0.35:.1f}Z', '#d0f8ff', INK, 0.8)
    if kind == 'chaos_shroom':
        b += star(-5, -h * 0.55, 4, '#ffe393') + path(f'M3 {-h * 0.8:.1f} q7 -2 6 3 q0 3 -3 3 v2', 'none', '#b5efdd', 1.8)
    return b


def shroom_alt(kind):
    col, w, h, spots, shape = SHROOM_CAPS[kind]
    b = mini_shroom(col, shape, w, h, spots, len(kind))
    if kind == 'magnet_shroom':
        b += magnet(0, -24, 0.45)
    if kind == 'fume_shroom':
        b += path('M3 -4 L12 -6 L12 0 L3 -1Z', col, INK, 0.9)
    return b


for _k in SHROOM_CAPS:
    GRAFTS[_k] = {'slot': 'crown', 'fn': shroom_graft, 'size': 1.0, 'alt': None}


# --- flowers and blossoms
def flower_halo(col, count, length, width, mode='petal'):
    if mode == 'orchid':
        return ''.join(petal(0, 0, a, l, w, col) for a, l, w in ((-65, 26, 10), (65, 26, 10), (-130, 21, 9), (130, 21, 9), (0, 24, 7), (180, 18, 7)))
    if mode == 'lily':
        return ''.join(petal(0, 0, i * 60 + 30, length, width, col) for i in range(6))
    return petal_ring(col, count, length, width, double=False)


@graft('wind_orchid', 'halo')
def g_wind_orchid(kind):
    return flower_halo('url(#mint)', 0, 0, 0, 'orchid') + path('M-28 4 Q-36 -6 -28 -12 Q-22 -6 -28 -2', 'none', '#b8ecd8', 1.8)


@graft('mist_orchid', 'halo')
def g_mist(kind):
    return flower_halo('url(#violet)', 0, 0, 0, 'orchid') + path('M-30 8 q6 -4 12 0 q6 4 12 0 M14 12 q6 -4 12 0', 'none', '#d9e6ea', 2)


@graft('aurora_orchid', 'halo')
def g_aurora(kind):
    return flower_halo('url(#violet)', 0, 0, 0, 'orchid') + path('M-30 -14 Q-38 6 -24 18 M30 -14 Q38 6 24 18', 'none', '#9fe8d8', 2.4)


@graft('magnet_orchid', 'crown')
def g_magnet_orchid(kind):
    return magnet(0, -10, 1.0, '#c66a78') + art.flower_small(-12, -4, 'url(#violet)')


@graft('magnet_daisy', 'crown')
def g_magnet_daisy(kind):
    return magnet(0, -10, 1.0, '#c86575') + art.flower_small(12, -4, 'url(#gold)')


@graft('tesla_tulip', 'crown')
def g_tesla(kind):
    b = path('M-9 0 Q-11 -12 -6 -18 L-3 -12 L0 -20 L3 -12 L6 -18 Q11 -12 9 0Z', 'url(#rose)', INK, 1.3)
    return b + path('M-12 -24 Q0 -30 12 -24', 'none', '#7ad7ff', 1.6) + bolt(0, -30, 0.45, '#9de6ff')


@graft('laser_lily', 'side')
def g_laser(kind):
    b = path('M-2 -5 L12 -9 L16 0 L12 9 L-2 5Z', 'url(#lotusp)', INK, 1.3)
    return b + ell(17, 0, 4, 6, '#fbe7d4', INK, 1.2) + ell(18, 0, 2, 3.4, '#ff8db0')


@graft('time_rose', 'front')
def g_time_rose(kind):
    return ell(0, 0, 10, 10, '#e1bd75', INK, 1.4) + ell(0, 0, 7.5, 7.5, '#faf0ca', INK, 0.8) + line('M0 -5 V0 L4 2', '#604a44', 1.4) + art.flower_small(-10, -9, 'url(#rose)')


@graft('seraph_flower', 'back')
def g_seraph(kind):
    return group(wings(), 'translate(18 0)') + ell(18, -24, 12, 3, 'none', '#d5b57a', 2)


@graft('holy_flower holy_lotus', 'crown')
def g_holy(kind):
    b = ell(0, -10, 14, 4, 'none', '#d4b26d', 2.4) + ell(0, -10, 14, 4, 'none', '#fff4c8', 1)
    if kind == 'holy_lotus':
        b += group(lotus_seat('url(#cream)', 5, '#ffe9a8'), 'translate(0 2) scale(.35)')
    return b


@graft('ice_queen', 'crown')
def g_ice_queen(kind):
    return crystal(-9, 0, 14, angle=-25) + crystal(0, 0, 18) + crystal(9, 0, 14, angle=25) + ell(0, -4, 2, 2, '#ffffff', INK, 0.6)


@graft('meteor_flower', 'crown')
def g_meteor_flower(kind):
    return path('M8 -20 Q14 -28 4 -36 Q24 -32 20 -14Z', 'url(#fire)', INK, 1) + star(10, -14, 6, '#fff2a8') + art.flower_small(-8, -4, 'url(#fire)')


@graft('core_blossom', 'halo')
def g_core(kind):
    b = petal_ring('url(#fire)', 8, 22, 8, double=False)
    return b + path('M-26 -4 L-34 -8 L-36 2 L-27 8 M26 -4 L34 -8 L36 2 L27 8', 'url(#stone)', INK, 1) + line('M-20 10 l6 4 -2 6 M20 10 l-2 5 3 6', '#e47739', 1.8)


@graft('orange_bloom', 'halo')
def g_orange(kind):
    return petal_ring('url(#fire)', 9, 22, 8, double=False) + ''.join(ell(math.cos(a) * 26, math.sin(a) * 26, 3, 3, '#ffd06a', INK, 0.6) for a in (0.4, 2.0, 3.6, 5.2))


@graft('snow_bloom', 'halo')
def g_snow_bloom(kind):
    return ''.join(petal(0, 0, i * 60, 24, 7, 'url(#ice)') for i in range(6)) + ''.join(crystal(math.cos(a) * 20, math.sin(a) * 20, 7, angle=math.degrees(a) + 90) for a in (0.5, 2.6, 4.7))


@graft('cotton_candy', 'back')
def g_cotton(kind):
    return ''.join(ell(x, y, r, r * 0.9, 'url(#rose)', INK, 1.2) for x, y, r in ((-6, -10, 10), (-16, -18, 8), (-2, -22, 9), (-14, -4, 7))) + path('M-14 -20 Q-12 -26 -6 -26', 'none', '#fff1ec', 1.6)


@graft('lantern_bloom', 'side')
def g_lantern_bloom(kind):
    b = line('M0 0 Q8 -8 14 -4', '#4d7e4f', 2) + path('M8 -2 L20 -2 L22 12 L14 18 L6 12Z', 'url(#gold)', INK, 1.4)
    return b + line('M7 4 H21 M10 -2 L11 15 M18 -2 L17 15', '#58774e', 1.2) + petal(6, 2, -60, 10, 4, 'url(#gold)') + petal(22, 2, 60, 10, 4, 'url(#gold)')


@graft('plantern', 'crown')
def g_plantern(kind):
    b = path('M-9 0 L-10 -14 L-6 -19 H6 L10 -14 L9 0 L0 4Z', 'url(#gold)', INK, 1.4) + line('M-10 -14 H10 M-4 -18 L-3 0 M4 -18 L3 0', '#58774e', 1.2)
    return b + path('M-12 -14 Q0 -26 12 -14Z', 'url(#leaf)', INK, 1) + ell(0, -8, 4, 4, '#fff4c4', 'none', 0)


@graft('origami_blossom', 'crown')
def g_origami(kind):
    return path('M-14 0 L0 -6 L14 0 L4 -2 L0 -16 L-4 -2Z', 'url(#cream)', INK, 1.2) + path('M0 -6 L0 -16 L4 -2Z', '#d5afcf', INK, 0.6) + path('M14 0 L20 -8 L16 2Z', 'url(#cream)', INK, 0.8)


@graft('starfruit', 'crown')
def g_starfruit(kind):
    return star(0, -10, 11, 'url(#gold)') + eye(-3, -10, 1, 1.6) + eye(3, -10, 1, 1.6)


# --- trees, bamboo, reeds
@graft('torchwood', 'crown')
def g_torchwood(kind):
    return ell(0, 0, 13, 4, '#d89552', INK, 1.3) + ell(0, 0, 8, 2.4, '#603d2b') + flame(-6, -6, 0.7) + flame(6, -9, 0.85) + flame(0, -4, 0.55)


@graft('phoenix_tree', 'back')
def g_phoenix(kind):
    return path('M0 0 Q-26 -2 -30 -30 Q-20 -14 -14 -18 Q-24 -28 -16 -42 Q-12 -24 -4 -22 Q-6 -36 6 -44 Q2 -24 8 -18Z', 'url(#fire)', INK, 1.3) + flame(-18, -30, 0.5)


@graft('thunder_pine frost_cypress', 'back')
def g_pine(kind):
    col = 'url(#ice)' if kind == 'frost_cypress' else 'url(#leaf)'
    b = line('M-6 2 L-8 -30', '#76573d', 4)
    for y, r in ((-30, 10), (-20, 14), (-8, 17)):
        b += path(f'M-8 {y - 10} Q{-8 - r * 0.4:.1f} {y - 2} {-8 - r} {y + 5} Q-8 {y + 8} {-8 + r} {y + 5} Q{-8 + r * 0.4:.1f} {y - 2} -8 {y - 10}Z', col, INK, 1.2)
    if kind == 'thunder_pine':
        b += bolt(-8, -44, 0.55)
    else:
        b += crystal(-8, -38, 9)
    return b


@graft('thunder_god', 'crown')
def g_thunder_god(kind):
    return path('M-12 0 L-14 -10 L-6 -6 L0 -14 L6 -6 L14 -10 L12 0Z', 'url(#gold)', INK, 1.2) + bolt(0, -18, 0.6) + bolt(-12, -16, 0.35) + bolt(12, -16, 0.35)


@graft('mamba_tree', 'front')
def g_mamba(kind):
    b = path('M-18 8 Q-26 -6 -14 -12 Q-2 -18 0 -6 Q2 4 10 2 Q18 0 18 -8', 'none', INK, 6) + path('M-18 8 Q-26 -6 -14 -12 Q-2 -18 0 -6 Q2 4 10 2 Q18 0 18 -8', 'none', '#b59653', 4)
    return b + ell(18, -9, 4, 3, '#b59653', INK, 1) + eye(19, -10, 0.8, 1.2) + line('M22 -9 l4 -1 M22 -9 l4 1', '#d9573b', 0.8)


@graft('destiny_tree', 'halo')
def g_destiny(kind):
    return ''.join(leaf(math.cos(a) * 10, math.sin(a) * 10, math.degrees(a) + 180, 18, 'url(#gold)') for a in [i * math.tau / 7 for i in range(7)]) + star(0, -26, 5, '#f5d98a')


@graft('vine_emperor', 'crown')
def g_vine_emperor(kind):
    return path('M-14 0 L-11 -12 L-5 -5 L0 -16 L5 -5 L11 -12 L14 0Z', 'url(#leaf)', INK, 1.3) + ell(0, -16, 2.6, 2.6, '#f5d98a', INK, 0.6) + leaf(-14, 0, 30, 9) + leaf(14, 0, 150, 9)


@graft('spiral_bamboo pressure_bamboo storm_reed resonance_beet', 'back')
def g_bamboo(kind):
    if kind == 'resonance_beet':
        b = path('M-6 -4 Q-20 -6 -18 -20 Q-14 -30 -4 -28 Q4 -26 4 -16 Q2 -6 -6 -4Z', 'url(#rose)', INK, 1.4)
        return b + path('M-8 -28 L-12 -36 M-6 -28 L-2 -38', 'none', '#4d7e4f', 2) + path('M-24 -10 Q-30 -16 -24 -22 M-28 -6 Q-36 -16 -28 -26', 'none', '#a687ac', 1.6)
    b = ''
    for i, (x, h) in enumerate(((-6, 40), (-16, 30))):
        b += path(f'M{x - 4} 0 V{-h + 4} Q{x} {-h - 2} {x + 4} {-h + 4} V0Z', 'url(#leaf)', INK, 1.4)
        for y in range(-h + 12, 0, 12):
            b += line(f'M{x - 4} {y} H{x + 4}', '#d4e3ab', 1.6)
        b += leaf(x, -h + 10, -30 if i else 210, 12)
    if kind == 'pressure_bamboo':
        b += ell(-20, -12, 7, 7, 'url(#cream)', INK, 1.2) + line('M-20 -12 l3 -4 M-24 -8 h8', '#605e45', 1.2)
    if kind == 'storm_reed':
        b += bolt(-6, -46, 0.5)
    if kind == 'spiral_bamboo':
        b += path('M-26 -30 Q-2 -40 4 -26 Q8 -16 -24 -10', 'none', '#b3c96e', 2.4)
    return b


@graft('mirror_reed', 'side')
def g_mirror_reed(kind):
    return path('M0 -14 L16 -18 L22 4 L4 8Z', 'url(#ice)', INK, 1.4) + line('M6 -10 L14 -2 M4 -4 L10 2', '#efffff', 1.6)


@graft('prism_grass', 'base')
def g_prism_grass(kind):
    return crystal(-22, 0, 22, 'url(#mint)', -18) + crystal(-14, 0, 28, 'url(#mint)', -6) + crystal(20, 0, 20, 'url(#mint)', 16)


@graft('obsidian_artichoke', 'back')
def g_obsidian(kind):
    return catapult(crystal(0, 6, 14, 'url(#night)'))


@graft('leyline', 'base')
def g_leyline(kind):
    return ell(0, 0, 32, 6, 'none', '#b4a3d0', 2) + path('M-24 0 L-12 -4 L0 0 L12 -4 L24 0', 'none', '#d6c8ef', 1.6) + ''.join(ell(x, -2, 2, 2, '#efe6ff', INK, 0.5) for x in (-18, 0, 18))


@graft('moonforge', 'back')
def g_moonforge(kind):
    return path('M-2 0 V-10 H-12 L-2 -18 H14 L20 -12 H10 V0Z', 'url(#stone)', INK, 1.3) + path('M2 0 V-8 Q6 -14 10 -8 V0Z', 'url(#fire)', INK, 0.8) + path('M-14 -24 Q-8 -30 -2 -26 Q-8 -28 -10 -20Z', '#f2e9b5', INK, 0.8)


# --- lobbers: catapult arms behind the host carrying their ammunition
LOBBER_AMMO = {
    'cabbage_pult': lambda: ell(0, 0, 8, 7, 'url(#leaf)', INK, 1.2) + path('M-5 0 Q0 -5 5 -1', 'none', '#bad39b', 1.2),
    'kernel_pult': lambda: path('M-4 6 Q-6 -8 0 -10 Q6 -8 4 6Z', 'url(#gold)', INK, 1.1) + line('M-3 -4 h6 M-3 0 h6', '#b78439', 0.8) + path('M5 0 L10 -2 L9 4Z', '#fff09a', INK, 0.7),
    'melon_pult': lambda: ell(0, 0, 9, 7.5, 'url(#leaf)', INK, 1.2) + path('M-5 -6 Q-8 0 -5 6 M0 -7 V7 M5 -6 Q8 0 5 6', 'none', '#2f6b3c', 1.2),
    'skylight_melon': lambda: ell(0, 0, 9, 7.5, 'url(#ice)', INK, 1.2) + star(4, -6, 2.5, '#eaffff'),
    'dragon_bubble_pult': lambda: ell(0, 0, 8, 8, 'url(#mint)', INK, 1.2) + petal(-3, -6, -35, 7, 3, 'url(#rose)') + petal(3, -6, 35, 7, 3, 'url(#rose)'),
    'toxic_gum_pult': lambda: path('M-7 4 Q-10 -4 -4 -6 Q0 -10 5 -6 Q10 -2 6 4 Q0 8 -7 4Z', 'url(#violet)', INK, 1.1) + ell(-2, -2, 2, 1.4, '#e7ff9a'),
    'fumarole_melon': lambda: ell(0, 0, 9, 7.5, 'url(#stone)', INK, 1.2) + path('M-2 -8 Q-6 -14 -1 -16 M3 -8 Q7 -14 3 -18', 'none', '#c8d7cf', 1.4),
    'sulfur_pod': lambda: path('M-7 3 Q-9 -6 0 -7 Q9 -6 7 3 Q0 8 -7 3Z', 'url(#gold)', INK, 1.1) + ell(-2, -2, 1.6, 1.2, '#a4974f'),
    'pepper_mortar': lambda: path('M-3 -6 Q4 -10 6 -3 Q8 6 -6 6 Q0 2 -3 -6Z', 'url(#fire)', INK, 1) + flame(1, -8, 0.3),
    'chimney_pepper': lambda: path('M-5 6 L-6 -6 H6 L5 6Z', 'url(#bark)', INK, 1) + path('M-2 -8 q-4 -5 1 -9', 'none', '#9caaa3', 1.4),
    'meteor_gourd': lambda: path('M-2 -8 Q-8 -8 -6 -2 Q-10 4 -4 7 Q4 9 6 3 Q8 -4 2 -6 Q4 -10 -2 -8Z', 'url(#fire)', INK, 1.1) + flame(4, -9, 0.3),
    'blast_pomegranate': lambda: ell(0, 0, 8, 8, 'url(#rose)', INK, 1.2) + path('M-3 -8 L-4 -12 L0 -10 L4 -12 L3 -8Z', 'url(#gold)', INK, 0.7),
}


def lobber_graft(kind):
    return catapult(LOBBER_AMMO[kind]())


for _k in LOBBER_AMMO:
    GRAFTS[_k] = {'slot': 'back', 'fn': lobber_graft, 'size': 1.0, 'alt': None}


@graft('corn_cannon', 'side')
def g_corn_cannon(kind):
    b = path('M-2 -8 L24 -12 L28 -2 L26 8 L-2 8Z', 'url(#leaf)', INK, 1.7) + ell(27, -2, 5, 9, '#425543', INK, 1.3) + ell(28, -2, 2.6, 5.4, '#253c35')
    return b + path('M2 -8 Q-4 -22 4 -22 Q12 -20 14 -10Z', 'url(#gold)', INK, 1.1) + line('M3 -18 l8 3 M2 -14 l9 3', '#ac7b39', 0.9)


@graft('gator_cannon', 'side')
def g_gator(kind):
    b = path('M-2 -8 Q10 -14 26 -8 L30 -2 L14 0 L30 4 L26 10 Q10 14 -2 8Z', 'url(#mint)', INK, 1.6)
    return b + path('M14 0 L28 -3 L25 0 L22 -2 L19 1 L16 -1Z M14 1 L28 4 L24 6 L22 3 L18 5Z', '#f5e7c4', INK, 0.6) + eye(10, -8, 1.4, 2)


# --- vines, roots, tentacles, jaws
@graft('vine_lasher', 'back')
def g_vine_lasher(kind):
    return vine_coil('url(#leaf)', 1, 30, 3) + crystal(-2, -32, 10, angle=-30)


@graft('abyss_tentacle', 'back')
def g_abyss(kind):
    b = path('M0 0 C-20 -6 -8 -26 -24 -38 Q-32 -46 -18 -44 Q-24 -40 -16 -34 C-2 -22 -12 -8 6 -2Z', 'url(#plum)', INK, 1.5)
    return b + ''.join(ell(x, y, 1.8, 1.4, '#c8a0d3') for x, y in ((-10, -16), (-16, -26), (-22, -38)))


@graft('tangle_kelp root_snare', 'base')
def g_roots(kind):
    b = ''
    if kind == 'tangle_kelp':
        # Ribbon kelp sways in loose S-curves with air bubbles.
        for side, dx, h in ((-1, 20, 22), (1, 22, 20), (-1, 30, 14), (1, 32, 12)):
            d = f'M{side * 4} 0 C{side * dx * 0.2:.1f} {-h * 0.4:.1f} {side * dx * 0.9:.1f} {-h * 0.5:.1f} {side * dx} {-h}'
            b += path(d, 'none', INK, 5) + path(d, 'none', '#3f8a5c', 3.2)
        return b + ell(-24, -26, 2.4, 2.4, '#bfe4eb', '#5999b8', 0.8) + ell(26, -24, 1.8, 1.8, '#bfe4eb', '#5999b8', 0.8)
    for side, (dx, h) in ((-1, (22, 18)), (1, (24, 16)), (-1, (12, 24)), (1, (10, 22))):
        d = f'M{side * 4} 0 Q{side * dx * 0.6:.1f} {-h * 0.3:.1f} {side * dx} {-h}'
        b += path(d, 'none', INK, 4.4) + path(d, 'none', '#987448', 2.6)
    return b + ''.join(ell(x, y, 2, 1.6, '#b48a58', INK, 0.6) for x, y in ((-16, -8), (16, -7), (-8, -16)))


@graft('chain_lotus', 'base')
def g_chain_lotus(kind):
    return lotus_seat('url(#gold)', 6, '#ffe9a8', ''.join(ell(-26 + i * 10.4, 6, 4.5, 2.6, 'none', '#a87c42', 1.6) for i in range(6)))


@graft('bubble_lotus', 'base')
def g_bubble_lotus(kind):
    return lotus_seat('url(#ice)', 7, '#e6f8ff', ''.join(ell(x, y, r, r, '#bfe4eb', '#5999b8', 0.9) for x, y, r in ((-28, -14, 5), (26, -20, 4), (32, -6, 3))))


@graft('sand_lotus', 'base')
def g_sand_lotus(kind):
    return path('M-34 6 L-26 -2 L-12 2 L0 -4 L14 2 L28 0 L34 6Z', '#e7ca91', '#b18d60', 1) + lotus_seat('url(#bark)', 6, '#f0d9a6')


@graft('caldera_lotus', 'base')
def g_caldera(kind):
    return lotus_seat('url(#fire)', 7, '#ffcf5a') + flame(-20, -8, 0.35) + flame(22, -10, 0.35)


@graft('shadow_assassin', 'back')
def g_shadow(kind):
    return path('M0 0 L-24 -30 L-20 -32 L4 -4Z', 'url(#ice)', INK, 1.2) + path('M-4 0 L-30 -16 L-28 -20 L0 -4Z', 'url(#ice)', INK, 1.2) + path('M-10 -10 Q-18 -20 -10 -26', 'none', '#6e6b88', 2)


@graft('signal_ivy', 'crown')
def g_signal(kind):
    return line('M0 0 V-14', '#3b7050', 2) + leaf(0, -6, 30, 9) + leaf(0, -9, 150, 9) + ell(0, -16, 3, 3, '#86c8a7', INK, 0.8) + path('M6 -20 Q12 -16 12 -10 M8 -24 Q16 -18 16 -8', 'none', '#86c8a7', 1.4)


@graft('glow_ivy glowvine', 'orbit')
def g_glow(kind):
    col = 'url(#gold)' if kind == 'glowvine' else 'url(#mint)'
    angles = (0.6, 2.4, 4.0) if kind == 'glowvine' else (1.2, 2.9, 4.6, 5.8)
    vine = path('M-26 6 Q-30 -20 -6 -28 Q18 -32 26 -10', 'none', '#5f9a52', 1.6) if kind == 'glow_ivy' else ''
    return vine + ''.join(ell(math.cos(a) * 28, math.sin(a) * 20 - 4, 3.2, 4.2, col, INK, 0.9) + ell(math.cos(a) * 28 - 1, math.sin(a) * 20 - 5, 1, 1.6, '#f7f1c7') for a in angles)


@graft('spikeweed', 'base')
def g_spikeweed(kind):
    return ''.join(path(f'M{x - 4} 2 Q{x - 6} {-8 - (i % 2) * 5} {x + 2} {-10 - (i % 2) * 5} L{x + 3} 3Z', 'url(#leaf)', INK, 1) for i, x in enumerate(range(-30, 34, 9)))


@graft('chomper', 'side')
def g_chomper(kind):
    b = path('M-2 -10 Q10 -22 26 -12 L12 -4 L28 4 Q14 16 -2 10Z', 'url(#plum)', INK, 1.6)
    return b + path('M26 -12 L12 -4 L28 4 L10 4 L4 -2Z', '#3c3040') + path('M14 -9 L13 -4 L10 -7 M22 -10 L19 -5 L17 -8 M24 3 L20 -1 L19 4Z', '#fff0d7', INK, 0.7)


@graft('grave_buster', 'base')
def g_grave_buster(kind):
    return path('M-30 2 Q-30 -10 -20 -14 Q-10 -18 -4 -10 L-14 -6 L-2 -2 Q-6 4 -18 4Z', 'url(#leaf)', INK, 1.4) + path('M-12 -8 L-8 -6 L-10 -3Z', '#f5eed2', INK, 0.6)


@graft('dragon_fruit', 'side')
def g_dragon_fruit(kind):
    b = path('M-2 -10 Q14 -18 26 -8 L30 0 L14 2 L28 8 Q14 16 -2 10Z', 'url(#rose)', INK, 1.6)
    return b + petal(4, -12, -40, 10, 4, 'url(#leaf)') + petal(10, -14, -10, 10, 4, 'url(#leaf)') + flame(32, 0, 0.35) + eye(10, -6, 1.2, 1.8)


# --- cacti, wind, blades, beans, bombs
@graft('cactus', 'side')
def g_cactus(kind):
    return path('M-2 -4 H10 V-16 Q14 -22 18 -16 V4 Q18 10 10 10 H-2Z', 'url(#leaf)', INK, 1.5) + ''.join(line(f'M{x} {y} l{dx} {dy}', '#e7daa0', 1.2) for x, y, dx, dy in ((18, -12, 4, -2), (18, -2, 4, 0), (10, 10, 2, 3), (14, -18, 0, -4)))


@graft('thorn_cactus', 'crown')
def g_thorn(kind):
    return art.flower_small(0, -8, 'url(#rose)') + ''.join(line(f'M{x} 0 l{x * 0.3:.1f} -6', '#e7daa0', 1.4) for x in (-12, -6, 6, 12))


@graft('blover', 'back')
def g_blover(kind):
    return ''.join(group(leaf(0, 0, -25, 20) + leaf(0, 0, 25, 20), f'rotate({a})') for a in (-140, -90, -40))


@graft('steam_clover', 'back')
def g_steam_clover(kind):
    return ''.join(group(leaf(0, 0, -20, 16, 'url(#mint)') + leaf(0, 0, 20, 16, 'url(#mint)'), f'rotate({a})') for a in (-130, -60)) + path('M-24 -30 q-6 -6 0 -12 M-14 -36 q-6 -6 0 -12', 'none', '#b1c3ba', 1.6)


@graft('cyclone_grass', 'base')
def g_cyclone(kind):
    return path('M-30 0 Q-34 -14 -16 -16 Q4 -18 10 -8 Q-6 -12 -10 -4 Q0 4 20 -4 Q30 -8 32 0', 'none', INK, 4) + path('M-30 0 Q-34 -14 -16 -16 Q4 -18 10 -8 Q-6 -12 -10 -4 Q0 4 20 -4 Q30 -8 32 0', 'none', '#7fbf6b', 2.4)


@graft('roof_vane', 'crown')
def g_vane(kind):
    return line('M0 0 V-22', '#76573d', 2) + path('M0 -22 L16 -18 L0 -14Z', 'url(#bark)', INK, 1) + path('M0 -22 L-8 -19 L0 -16Z', '#d9573b', INK, 0.8)


@graft('frost_fan', 'back')
def g_frost_fan(kind):
    return path('M0 0 L-30 -24 Q-14 -40 4 -36Z', 'url(#ice)', INK, 1.4) + line('M0 0 L-22 -28 M0 0 L-12 -36 M0 0 L-2 -36', '#eafaff', 1)


@graft('echo_fern anchor_fern', 'back')
def g_fern(kind):
    b = ''
    for x, y in ((-20, -26), (-28, -10)):
        b += path(f'M0 0 Q{x * 0.4:.1f} {y * 0.5:.1f} {x} {y}', 'none', '#3b7050', 2.4)
        for t in (0.4, 0.7, 0.95):
            b += leaf(x * t, y * t, -20, 8) + leaf(x * t, y * t, 200, 8)
    if kind == 'anchor_fern':
        b += path('M-30 -4 Q-30 6 -20 6 M-26 -8 l-3 3 -2 -3', 'none', '#547d7d', 2.2)
    else:
        b += path('M-34 -30 Q-40 -24 -36 -16 M-38 -36 Q-48 -26 -42 -12', 'none', '#82b8a3', 1.4)
    return b


@graft('boomerang_shooter cluster_boomerang frost_boomerang', 'side')
def g_boomerang(kind):
    col = 'url(#ice)' if kind == 'frost_boomerang' else 'url(#bark)'
    one = path('M-6 4 Q-4 -10 6 -16 L10 -12 Q4 -6 4 2 Q12 -2 20 0 L20 6 Q8 6 -6 4Z', col, INK, 1.3)
    if kind == 'frost_boomerang':
        one += crystal(6, -12, 8, angle=-30) + crystal(18, 2, 7, angle=70)
    if kind == 'cluster_boomerang':
        return group(one, 'translate(6 -8) rotate(-20) scale(.8)') + group(one, 'translate(10 2) scale(.8)') + group(one, 'translate(4 10) rotate(20) scale(.8)')
    return group(one, 'translate(4 0)')


@graft('lotus_lancer', 'side')
def g_lancer(kind):
    return line('M-2 6 L24 -18', INK, 4) + line('M-2 6 L24 -18', '#c99a5c', 2.4) + path('M22 -16 L30 -28 L32 -14Z', 'url(#mint)', INK, 1.1)


@graft('coffee_bean', 'crown')
def g_coffee(kind):
    return path('M-8 0 Q-12 -10 -4 -14 Q6 -18 8 -8 Q10 2 -8 0Z', 'url(#bark)', INK, 1.3) + path('M-2 -14 Q-6 -8 0 -4', 'none', '#815233', 1.6) + path('M-4 -20 q-3 -4 1 -8 M3 -20 q3 -4 -1 -8', 'none', '#e7dccf', 1.2)


@graft('garlic', 'crown')
def g_garlic(kind):
    return path('M-10 0 Q-14 -8 -4 -14 L-2 -22 H2 L4 -14 Q14 -8 10 0 Q0 4 -10 0Z', 'url(#cream)', INK, 1.3) + line('M-2 -12 Q-6 -6 -4 0 M2 -12 Q6 -6 4 0', '#b7b796', 0.9)


@graft('cork_plug', 'crown')
def g_cork(kind):
    return path('M-9 0 L-7 -12 H7 L9 0Z', '#b6a480', INK, 1.3) + ell(0, -12, 7, 2.4, '#dbcb9d', INK, 1) + ell(-3, -6, 1, 1, '#8b7a58') + ell(3, -4, 1, 1, '#8b7a58')


@graft('ice_cream', 'crown')
def g_ice_cream(kind):
    return path('M-7 -2 L0 10 L7 -2Z', 'url(#bark)', INK, 1.2) + ell(-4, -6, 6, 6, 'url(#cream)', INK, 1.1) + ell(4, -8, 6.5, 7, 'url(#rose)', INK, 1.1) + ell(1, -15, 2, 2, '#c8303f', INK, 0.6)


@graft('cherry_bomb', 'crown')
def g_cherry(kind):
    b = path('M-6 -10 Q-2 -24 4 -24 Q8 -18 8 -10', 'none', '#42734b', 2) + leaf(4, -24, 14, 10)
    return b + ell(-8, -6, 7, 8, 'url(#cherry)', INK, 1.3) + ell(8, -5, 7, 8, 'url(#cherry)', INK, 1.3) + ell(-10, -9, 1.6, 2.4, '#ffdbc9') + ell(6, -8, 1.6, 2.4, '#ffdbc9') + star(12, -22, 3, '#f7cd77')


@graft('potato_mine', 'crown')
def g_potato(kind):
    return path('M-2 0 V-8 H2 V0Z', '#908979', INK, 1) + ell(0, -10, 5, 4, 'url(#rose)', INK, 1.1) + ell(-1, -11, 1.4, 1, '#fff4d3')


@graft('jalapeno', 'crown')
def g_jalapeno(kind):
    return path('M-6 0 Q-10 -12 -2 -20 Q6 -26 8 -18 Q6 -10 2 -4 Q0 0 -6 0Z', 'url(#fire)', INK, 1.3) + leaf(4, -22, 140, 8)


@graft('magma_stream', 'crown')
def g_magma(kind):
    return path('M-8 0 Q-12 -10 -4 -14 Q-6 -22 2 -28 Q2 -18 8 -14 Q14 -6 6 0Z', 'url(#fire)', INK, 1.2) + path('M-2 -2 Q-6 -8 0 -16 Q6 -8 2 -2Z', 'url(#gold)', 'none')


@graft('healing_gourd', 'side')
def g_healing(kind):
    return line('M0 0 Q6 -2 10 2', '#5d8a3e', 1.6) + path('M8 2 Q4 -6 12 -8 Q20 -6 16 2 Q24 10 14 16 Q4 16 6 8Z', 'url(#mint)', INK, 1.3) + path('M11 6 H17 M14 3 V9', 'none', '#f4eac4', 1.6)


@graft('mango_bowling', 'base')
def g_mango(kind):
    return group(path('M-10 4 Q-14 -8 -2 -12 Q12 -14 12 -2 Q12 8 -10 4Z', 'url(#gold)', INK, 1.3) + line('M-6 -2 L6 -2', '#e09a3a', 1), 'translate(20 -6)') + line('M-6 -2 L4 -2 M-4 2 L6 2', '#c99a5c', 1.2)


@graft('brine_pot', 'base')
def g_brine(kind):
    return group(path('M-8 -10 L-6 2 Q0 5 6 2 L8 -10Z', 'url(#bark)', INK, 1.1) + ell(0, -10, 8, 2.6, '#70583e', INK, 0.8) + path('M-3 -12 Q-6 -18 -2 -20 M3 -12 Q6 -16 2 -20', 'none', '#7ab8a6', 1.4), 'translate(-24 0)')


@graft('squash', 'crown')
def g_squash(kind):
    return path('M-12 0 Q-14 -10 -6 -16 Q0 -20 6 -16 Q14 -10 12 0 Q0 4 -12 0Z', 'url(#leaf)', INK, 1.4) + line('M-6 -14 Q-8 -6 -6 0 M6 -14 Q8 -6 6 0', '#5b944e', 1) + leaf(2, -18, 150, 8)


@graft('umbrella_leaf', 'crown')
def g_umbrella(kind):
    return line('M0 0 V-14', '#4d7e4f', 2) + path('M-24 -10 Q0 -32 24 -10 L14 -13 L6 -9 L0 -13 L-7 -9 L-15 -13Z', 'url(#leaf)', INK, 1.3) + line('M0 -24 L-15 -13 M0 -24 L14 -13', '#a9c597', 1)


@graft('dream_drum', 'side')
def g_drum(kind):
    return path('M0 -10 L2 8 Q12 13 22 8 L24 -10Z', 'url(#rose)', INK, 1.3) + ell(12, -10, 12, 4, 'url(#cream)', INK, 1.1) + line('M3 -4 l5 10 5 -8 5 8 5 -10', '#f6d89d', 1.2)


@graft('dream_disc', 'orbit')
def g_disc(kind):
    return group(ell(0, 0, 10, 7, 'url(#violet)', INK, 1.2) + ell(0, 0, 6, 4, 'url(#plum)', INK, 0.8) + ell(0, 0, 2.6, 2, 'url(#gold)', INK, 0.6), 'translate(26 -20)')


@graft('pulse_bulb', 'crown')
def g_bulb(kind):
    return path('M-7 0 Q-14 -10 -10 -18 Q-4 -26 4 -24 Q12 -22 12 -14 Q12 -6 6 0Z', 'url(#gold)', INK, 1.3) + path('M-5 0 H6 V4 H-5Z', '#7f9980', INK, 0.8) + line('M-12 -26 l-3 -3 M12 -26 l3 -3 M0 -30 v-4', '#d7ac54', 1.4)


# --- ancient world
@graft('dandelion', 'halo')
def g_dandelion(kind):
    b = ell(0, 0, 27, 26, 'url(#fluff)', '#b8c5ca', 1.1)
    for i in range(24):
        a = math.radians(i * 15)
        b += line(f'M{math.cos(a) * 9:.1f} {math.sin(a) * 9:.1f} L{math.cos(a) * 24:.1f} {math.sin(a) * 24:.1f}', '#b9c6c9', 0.5)
    return b + art.seed_tuft(26, -26, 30, 7) + art.seed_tuft(-27, -22, -30, 6)


@graft('jasmine_tea', 'side')
def g_jasmine(kind):
    b = path('M0 -2 Q1 10 8 12 L16 12 Q23 10 24 -2Z', 'url(#porcelain)', INK, 1.4) + ell(12, -2, 12, 3, 'url(#tea)', INK, 1.1)
    b += path('M23 1 Q29 2 28 6 Q27 10 22 9', 'none', INK, 2.4) + line('M3 4 q2 -3 4 0 q2 3 4 0 q2 -3 4 0', '#4f7fb4', 0.9)
    return b + art.jasmine_flower(8, -6, 0.55, 10) + path('M10 -8 q-3 -4 1 -8 M15 -8 q3 -4 -1 -8', 'none', '#ffffff', 1.1)


@graft('golden_milk', 'side')
def g_milk(kind):
    b = path('M4 -14 H14 L15 -8 Q20 -5 20 2 V12 Q20 16 15 16 H3 Q-2 16 -2 12 V2 Q-2 -5 3 -8Z', 'url(#glass)', INK, 1.4)
    b += path('M0 0 H18 V11 Q18 14 15 14 H3 Q0 14 0 11Z', 'url(#milk)', 'none') + path('M3 -18 H15 L16 -14 H2Z', 'url(#gold)', INK, 1)
    return b + art.shovel(22, 4, 20, 0.5)


@graft('samsara_eye', 'front_head')
def g_samsara(kind):
    b = ell(0, 0, 8, 5.5, '#fffdf5', INK, 1.2) + ell(0, 0, 4.4, 4.4, 'url(#iris)', INK, 0.8)
    b += ell(0, 0, 3, 3, 'none', '#3d2563', 0.7) + ell(0, 0, 1.2, 1.2, '#24133d')
    return b + ''.join(petal(0, -3, a, 8, 3, 'url(#samsara)') for a in (-40, 0, 40))


@graft('electric_bonk_choy', 'sides')
def g_bonk(kind):
    arms = path('M14 4 Q22 0 26 6', 'none', '#4d8d4a', 3.4) + path('M-14 4 Q-22 0 -26 6', 'none', '#4d8d4a', 3.4)
    sparks = line('M36 -2 l5 -3 M37 6 l6 0 M-36 -2 l-5 -3 M-37 6 l-6 0', '#7fe0ff', 1.2)
    return arms + art.fist(30, 6, 0, 0.8) + art.fist(-30, 6, 180, 0.8) + sparks




# ================================================================= fusion v2
# Mouth weapons grow out of the hybrid's own skin; the muzzle class tells the
# composer how an already armed host modifies its barrel instead.

def tube(length=13, w=6.0, rim=8.0):
    b = path(f'M-3 {-w:.1f} Q{length * 0.5:.1f} {-w - 2:.1f} {length} {-w - 1:.1f} L{length} {w + 1:.1f} Q{length * 0.5:.1f} {w + 2:.1f} -3 {w:.1f}Z', 'url(#skin)', INK, 1.6)
    b += path(f'M0 {-w + 1.6:.1f} Q{length * 0.5:.1f} {-w - 0.2:.1f} {length - 3} {-w + 0.2:.1f}', 'none', '{sl}', 1.3)
    b += ell(length, 0, rim * 0.62, rim, 'url(#skin)', INK, 1.5) + ell(length + 1, 0, rim * 0.33, rim * 0.62, '{sd}')
    return b + ell(length + 1, -rim * 0.18, rim * 0.12, rim * 0.22, '#112f2a')


WEAPONS = {}
MUZZLE = {}


def weapon(kinds, muzzle):
    def register(fn):
        for kind in kinds.split():
            WEAPONS[kind] = fn
            MUZZLE[kind] = muzzle
        return fn
    return register


@weapon('peashooter split_pea', 'barrel')
def w_pea(kind):
    return tube()


@weapon('repeater', 'barrel')
def w_repeater(kind):
    return group(tube(12), 'translate(0 -6) scale(.8)') + group(tube(15), 'translate(0 6) scale(.8)')


@weapon('threepeater', 'barrel')
def w_threepeater(kind):
    return ''.join(group(tube(11), f'translate(0 {dy}) rotate({a}) scale(.62)') for dy, a in ((-9, -20), (9, 20), (0, 0)))


@weapon('snow_pea', 'barrel')
def w_snow(kind):
    return tube() + crystal(9, -7, 9, 'url(#ice)', -12) + crystal(15, -6, 7, 'url(#ice)', 25)


@weapon('amber_shooter', 'barrel')
def w_amber(kind):
    return tube(14) + ell(5, 0, 3.2, 4, '#f7ac42', INK, 1) + line('M3.6 -1.4 l1.6 -1.2', '#fff0ad', 1)


@weapon('shadow_pea', 'barrel')
def w_shadow(kind):
    return tube(14) + path('M16 -9 Q12 -18 20 -21 Q17 -15 24 -12Z', '#bca6ee', INK, 0.8)


@weapon('plasma_shooter', 'barrel')
def w_plasma(kind):
    return tube(14) + path('M3 -8 Q-1 0 3 8 M8 -8 Q4 0 8 8', 'none', '#62dceb', 1.8) + ell(15, 0, 2.2, 4, '#b3fcf2')


@weapon('prism_pea', 'barrel')
def w_prism(kind):
    return tube(12) + crystal(19, 0, 11, 'url(#gem)', 90)


@weapon('sakura_shooter', 'barrel')
def w_sakura(kind):
    return tube(13) + art.flower_small(4, -8, 'url(#lotusp)')


@weapon('heather_shooter', 'barrel')
def w_heather(kind):
    return tube(13) + art.flower_small(2, -8, 'url(#violet)') + art.flower_small(8, 8, 'url(#rose)')


@weapon('chambord_sniper', 'cannon')
def w_sniper(kind):
    b = path('M-3 -4 L26 -4 L26 4 L-3 5Z', 'url(#skin)', INK, 1.4) + path('M0 -2.4 L22 -2.4', 'none', '{sl}', 1)
    return b + path('M24 -6 H30 V6 H24Z', 'url(#steel)', INK, 1.1) + ell(30, 0, 1.6, 3.4, '{sd}', INK, 0.6)


@weapon('corn_cannon', 'cannon')
def w_corn(kind):
    b = tube(16, 7.5, 10)
    return b + path('M4 -9.5 H9 V9.5 H4Z', 'url(#gold)', INK, 1) + line('M5.5 -7 V7 M7.5 -7 V7', '#b78439', 0.7)


@weapon('gator_cannon', 'teeth')
def w_gator(kind):
    b = path('M-3 -7 Q10 -13 24 -8 L28 -2 L12 0 L28 3 L24 9 Q10 13 -3 7Z', 'url(#skin)', INK, 1.6)
    b += path('M12 0 L27 -2.5 L24 0 L21 -2 L18 1 L15 -1Z M12 1 L27 3.5 L23 5.5 L21 2.5 L17 4.5Z', '#f5e7c4', INK, 0.6)
    return b + ell(14, -8, 2.2, 1.6, '{sd}') + ell(6, -9, 1.6, 2.2, INK)


@weapon('pepper_mortar', 'flame')
def w_mortar(kind):
    b = group(tube(10, 6.5, 9), 'rotate(-28)')
    return b + path('M10 -14 Q8 -20 13 -22 Q12 -17 16 -15Z', 'url(#flame)', INK, 0.8)


@weapon('chimney_pepper', 'flame')
def w_chimney(kind):
    b = path('M-3 -6 H12 L14 -9 H20 V9 H14 L12 6 H-3Z', 'url(#skin)', INK, 1.5)
    b += line('M3 -6 V6 M8 -6 V6 M14 -5 H20 M14 3 H20', '{sd}', 0.9)
    return b + ell(20, 0, 2.4, 7, '{sd}', INK, 1) + path('M22 -6 q5 -4 2 -9 q6 3 3 9', 'none', '#b1c3ba', 1.4)


@weapon('fume_shroom', 'nozzle')
def w_fume(kind):
    b = path('M-3 -5 Q8 -6 14 -9 L20 -12 L20 12 L14 9 Q8 6 -3 5Z', 'url(#skin)', INK, 1.6)
    return b + ell(20, 0, 3.4, 12, 'url(#skin)', INK, 1.3) + ell(20.6, 0, 1.8, 8, '{sd}') + path('M2 -3 Q9 -4 14 -6.5', 'none', '{sl}', 1.2)


@weapon('puff_shroom', 'nozzle')
def w_puff(kind):
    return path('M-3 -4 Q6 -5 11 -5 L11 5 Q6 5 -3 4Z', 'url(#skin)', INK, 1.4) + ell(11, 0, 3, 5.6, 'url(#skin)', INK, 1.2) + ell(11.6, 0, 1.5, 3.4, '{sd}')


@weapon('sea_shroom', 'nozzle')
def w_sea(kind):
    return w_puff(kind) + ell(18, -6, 2.4, 2.4, '#bfe4eb', '#5999b8', 0.7) + ell(22, -10, 1.4, 1.4, '#bfe4eb', '#5999b8', 0.6)


@weapon('chomper', 'teeth')
def w_chomper(kind):
    b = path('M-4 -9 Q8 -20 24 -12 L11 -4 L26 4 Q12 15 -4 9Z', 'url(#skin)', INK, 1.6)
    b += path('M24 -12 L11 -4 L26 4 L9 3 L3 -2Z', '#3c3040')
    return b + path('M12 -9.5 L11 -4.5 L8 -7.5 M20 -10.5 L17.5 -5.5 L15.5 -8.5 M22 2.6 L18 -1 L17 3.4Z', '#fff0d7', INK, 0.7) + path('M0 -8 Q8 -15 18 -12', 'none', '{sl}', 1.2)


@weapon('dragon_fruit', 'flame')
def w_dragon(kind):
    b = path('M-3 -8 Q12 -15 24 -7 L27 0 L13 2 L25 7 Q12 14 -3 8Z', 'url(#skin)', INK, 1.6)
    b += petal(6, -10, -40, 9, 3.6, 'url(#leaf)') + petal(12, -12, -10, 9, 3.6, 'url(#leaf)')
    return b + ell(9, -5, 1.2, 1.8, INK) + group(path('M0 4 Q-8 0 -4 -7 Q0 -4 2 -12 Q10 -4 5 1 Q4 5 0 4Z', 'url(#flame)', INK, 0.9), 'translate(31 1) rotate(90) scale(.62)')


@weapon('laser_lily', 'lens')
def w_laser(kind):
    b = path('M-3 -5 L12 -9 L16 0 L12 9 L-3 5Z', 'url(#skin)', INK, 1.4)
    return b + ell(17, 0, 4, 6, '#fbe7d4', INK, 1.2) + ell(18, 0, 2, 3.4, '#ff8db0') + ell(17.2, -1.8, 0.8, 1.2, '#ffffff')


def accessory(kinds, slot):
    def register(fn):
        for kind in kinds.split():
            GRAFTS[kind] = {'slot': slot, 'fn': fn, 'size': 1.0, 'alt': None}
        return fn
    return register


def sprout(x=0, n=2, col='url(#leaf)'):
    b = line(f'M{x} 0 Q{x - 1} -5 {x} -9', '#4f8a45', 2)
    return b + ''.join(leaf(x, -8, a, 9, col) for a in ((60, 120) if n == 2 else (40, 90, 140)))


@accessory('peashooter', 'crown')
def a_peashooter(kind):
    return sprout()


@accessory('repeater', 'crown')
def a_repeater(kind):
    return sprout(n=3) + line('M-5 -3 L4 -1', INK, 1.6)


@accessory('threepeater', 'crown')
def a_threepeater(kind):
    return ''.join(group(sprout() + ell(0, -11, 3, 3, 'url(#pea)', INK, 0.9), f'translate({x} 0) rotate({x * 1.6}) scale(.7)') for x in (-9, 0, 9))


@accessory('split_pea', 'back')
def a_split_pea(kind):
    return group(tube(10), 'translate(2 0) matrix(-.85 0 0 .85 0 0)').replace('url(#skin)', 'url(#pea)').replace('{sd}', '#294e37').replace('{sl}', '#d2ed93')


@accessory('snow_pea', 'crown')
def a_snow(kind):
    return crystal(-7, 0, 12, angle=-22) + crystal(1, 0, 15) + crystal(8, 0, 11, angle=24) + star(-12, -12, 2.4, '#efffff')


@accessory('amber_shooter', 'crown')
def a_amber(kind):
    return ell(0, -5, 5, 5.5, '#f7ac42', INK, 1.1) + ell(-1.6, -7, 1.4, 1.8, '#fff0ad') + flame(0, -15, 0.5)


@accessory('shadow_pea', 'crown')
def a_shadow(kind):
    return path('M-8 0 Q-16 -10 -10 -20 Q-9 -12 -2 -6Z M8 0 Q16 -10 10 -20 Q9 -12 2 -6Z', '#8e7bc4', INK, 1) + ell(0, -4, 3, 2, '#bca6ee')


@accessory('plasma_shooter', 'orbit')
def a_plasma(kind):
    return ell(0, 0, 30, 24, 'none', '#62dceb', 1.2) + ''.join(ell(math.cos(a) * 30, math.sin(a) * 24, 2.4, 2.4, '#b3fcf2', '#155460', 0.6) for a in (0.7, 2.6, 4.4))


@accessory('prism_pea', 'crown')
def a_prism(kind):
    return crystal(-5, 0, 13, 'url(#gem)', -15) + crystal(5, 0, 17, 'url(#gem)', 10)


@accessory('sakura_shooter', 'crown')
def a_sakura(kind):
    return line('M0 0 Q2 -6 -2 -10', '#6d4b3a', 1.6) + art.flower_small(-4, -12, 'url(#lotusp)') + art.flower_small(6, -7, 'url(#rose)')


@accessory('heather_shooter', 'crown')
def a_heather(kind):
    return ''.join(line(f'M{x} 0 Q{x + 2} -6 {x} -12', '#4f8a45', 1.2) + art.flower_small(x, -13, col) for x, col in ((-6, 'url(#violet)'), (5, 'url(#rose)')))


@accessory('chambord_sniper', 'crown')
def a_scope(kind):
    return path('M-10 0 L-8 -6 H8 L10 0Z', '#536a61', INK, 1.1) + path('M-12 -6 H12 V-13 H-12Z', '#536a61', INK, 1.1) + ell(12, -9.5, 2.4, 4, '#bed5c8', INK, 0.8)


@accessory('corn_cannon', 'crown')
def a_corn(kind):
    b = path('M-5 0 Q-8 -14 0 -20 Q8 -14 5 0Z', 'url(#gold)', INK, 1.2) + line('M-3 -12 h6 M-4 -7 h8 M-3 -3 h6', '#b78439', 0.8)
    return b + path('M-5 0 Q-14 -6 -12 -16 Q-6 -8 -3 -2Z M5 0 Q14 -6 12 -16 Q6 -8 3 -2Z', 'url(#leaf)', INK, 1)


@accessory('gator_cannon', 'back')
def a_gator(kind):
    b = path('M0 4 Q-14 2 -26 -6 Q-32 -10 -30 -4 Q-20 8 -2 12Z', 'url(#mint)', INK, 1.4)
    return b + ''.join(path(f'M{x} {y} l-2 -5 l4 1Z', '#3f8a6d', INK, 0.6) for x, y in ((-8, 4), (-15, 1), (-22, -3)))


@accessory('pepper_mortar', 'crown')
def a_pepper(kind):
    return path('M0 0 Q-2 -7 3 -11 Q8 -14 10 -10', 'none', '#3f7a46', 2.4) + leaf(2, -8, 150, 9)


@accessory('chimney_pepper', 'back')
def a_chimney(kind):
    return path('M-4 0 L-6 -24 H6 L5 0Z', 'url(#bark)', INK, 1.2) + line('M-8 -24 H8 M-5 -16 H5 M-5 -8 H5', '#9caaa3', 1.2) + path('M0 -27 q-6 -6 1 -12 q-4 6 4 11', 'none', '#b1c3ba', 1.8)


@accessory('chomper', 'back')
def a_chomper(kind):
    return leaf(0, 0, 220, 20, 'url(#plum)') + leaf(0, -4, 250, 18, 'url(#plum)') + ell(-10, -12, 1.6, 1.2, '#d6c5ec')


@accessory('dragon_fruit', 'crown')
def a_dragon(kind):
    return ''.join(petal(x, 0, a, 12, 4.6, 'url(#leaf)') for x, a in ((-8, -35), (0, 0), (8, 35))) + ''.join(ell(x, -10, 1, 1, '#f5e7c4') for x in (-11, 0, 11))


@accessory('laser_lily', 'halo')
def a_lily(kind):
    return ''.join(petal(0, 0, i * 60 + 30, 20, 7, 'url(#rose)') for i in range(6))


@accessory('cherry_bomb', 'crown')
def a_cherry(kind):
    b = path('M-2 0 Q-6 -12 2 -20 Q8 -24 12 -20', 'none', '#42734b', 2.6) + leaf(2, -18, 20, 12)
    b += path('M12 -20 Q18 -27 22 -24', 'none', '#a98451', 1.6) + star(23, -25, 4.2, '#f7cd77') + ell(23, -25, 1.4, 1.4, '#fff6d0')
    return b + ell(-4, -3, 4.2, 4.6, 'url(#cherry)', INK, 1) + ell(-5.4, -4.6, 1, 1.4, '#ffdbc9')


@accessory('squash', 'crown')
def a_squash(kind):
    return path('M0 0 Q-2 -8 4 -10 Q10 -11 9 -5 Q8 -2 5 -4', 'none', '#4c8a45', 2.6) + leaf(-1, -6, 150, 11)


@accessory('starfruit', 'crown')
def a_starfruit(kind):
    return star(0, -10, 10, 'url(#gold)') + path('M0 -17 L-2 -11 M-7 -12 L-3 -10', 'none', '#fff1bd', 1.2)


@accessory('wallnut', 'crown')
def a_wallnut(kind):
    b = path('M-15 2 Q-17 -12 -6 -16 Q4 -19 12 -13 Q17 -8 15 2 Q0 -2 -15 2Z', 'url(#bark)', INK, 1.6)
    return b + path('M-11 -1 Q-12 -9 -5 -12', 'none', '#eac78a', 1.6) + line('M3 -14 q2 3 0 6 M9 -9 q2 2 1 5', '#9a713e', 0.9)


@accessory('tallnut', 'crown')
def a_tallnut(kind):
    b = path('M-14 2 Q-17 -18 -7 -26 Q2 -31 10 -24 Q17 -16 14 2 Q0 -2 -14 2Z', 'url(#bark)', INK, 1.7)
    return b + path('M-10 -2 Q-12 -16 -5 -22', 'none', '#eac78a', 1.8) + line('M4 -22 q3 4 0 8 M8 -10 q2 3 0 6', '#9a713e', 1)


@accessory('crystal_nut', 'crown')
def a_crystal_nut(kind):
    return crystal(-8, 0, 13, angle=-20) + crystal(0, 0, 17) + crystal(8, 0, 12, angle=22)


@accessory('cactus', 'crown')
def a_cactus(kind):
    b = path('M-5 0 Q-6 -10 0 -12 Q6 -10 5 0Z', 'url(#leaf)', INK, 1.2)
    return b + ''.join(line(f'M{x} {y} l{dx} {dy}', '#e7daa0', 1.2) for x, y, dx, dy in ((-5, -4, -4, -1), (5, -6, 4, -1), (-3, -10, -3, -3), (3, -10, 3, -3))) + art.flower_small(0, -13, 'url(#rose)')


@accessory('golden_milk', 'crown')
def a_milk(kind):
    b = path('M-12 0 Q-14 -6 -9 -7 Q-8 -13 -3 -11 Q0 -17 4 -12 Q9 -14 10 -8 Q15 -6 12 0 Q0 3 -12 0Z', 'url(#milk)', INK, 1.3)
    b += ell(-6, -15, 1.6, 2, '#fffdf5', INK, 0.6) + ell(7, -17, 1.2, 1.5, '#fffdf5', INK, 0.5)
    return b + art.shovel(9, -10, 30, 0.42)


@accessory('jasmine_tea', 'crown')
def a_jasmine(kind):
    b = path('M-10 0 Q-10 -8 -8 -10 H8 Q10 -8 10 0Z', 'url(#porcelain)', INK, 1.3) + ell(0, -10, 8, 2.2, 'url(#tea)', INK, 0.9)
    b += line('M-6 -5 q2 -2 4 0 q2 2 4 0', '#4f7fb4', 0.9)
    return b + art.jasmine_flower(6, -12, 0.5, 15) + path('M-2 -14 q-3 -4 1 -7 M3 -15 q3 -4 -1 -7', 'none', '#ffffff', 1)
