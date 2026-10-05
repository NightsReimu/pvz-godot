#!/usr/bin/env python3
"""Generate scripts/data/fusion_art_parts.gd: the anatomy library for fusion SVGs.

A fusion is drawn as one new plant, not a host wearing stickers: the strongest
silhouette lends the body, the most striking partner lends its skin (re-coloured
tissue plus surface pattern), every partner lends an accessory or its weapon,
and the hybrid takes the fiercest expression and the elements of its parents.
This script measures the base art (skin, eyes, mouth, muzzles) and writes the
tables the GDScript composer uses for fixed SVGs and live recursive fusions.

Run after build_vector_unit_art.py:  python3 scripts/tools/build_fusion_parts.py
"""
from pathlib import Path
import json
import re
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_vector_unit_art as art  # noqa: E402
from build_vector_unit_art import path, ell, line, INK  # noqa: E402
import fusion_anatomy as anatomy  # noqa: E402
import fusion_accessories as acc  # noqa: E402
from fusion_traits import T, MATERIAL  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'scripts/data/fusion_art_parts.gd'
EXCLUDED = {'lily_pad', 'flower_pot', 'wallnut_bowling'}
# Hosts whose body already carries a mouth weapon modify it instead of growing another.
UNARMED_WEAPONS = {'dragon_fruit', 'laser_lily'}


def base_gradients():
    grads = {}
    for match in re.finditer(r'<linearGradient id="(\w+)"[^>]*><stop stop-color="(#\w+)"/><stop offset="1" stop-color="(#\w+)"/>', art.DEFS):
        grads[match.group(1)] = [match.group(2), match.group(3)]
    grads['hypno'] = ['#d77be2', '#713b91']
    grads['sea'] = ['#a7f4ec', '#318fa6']
    for items in art.EXTRA_GRADIENTS.values():
        for gid, c1, c2 in items:
            grads[gid] = [c1, c2]
    grads.update({
        'flame': ['#ffe28a', '#ef6a2c'], 'cherry': ['#ff9c9c', '#c8303f'], 'cap': ['#e7c6f4', '#8d5aa5'],
        'shell': ['#e7c38a', '#a26d3a'], 'lotusp': ['#ffd9e6', '#d77ea3'], 'gem': ['#f4e2ff', '#9b74d6'],
        'steel': ['#e3eaee', '#8a9aa3'], 'honey': ['#ffe28a', '#d99a2e'],
    })
    return grads


def torchwood_body(kind, *_):
    b = art.base(False)
    b += path('M-18 -7 L18 -7 L17 23 L25 34 L12 32 L5 37 L-6 33 L-24 35 L-17 23Z', 'url(#bark)', INK, 2)
    b += path('M-18 -4 L-10 -2 L-9 28 L-22 33 L-16 22Z', '#7a4c2f', 'none')
    for x in (-9, 0, 11):
        b += line(f'M{x} 4 L{x - 2} 18 L{x + 1} 30', '#603d2b', 1.5)
    b += ell(0, -5, 18, 7, '#d89552', INK, 1.8) + ell(0, -5, 12, 4, '#603d2b') + ell(0, -5, 8, 2.4, '#e9ad66')
    for i, h in enumerate((27, 39, 29)):
        x = (i - 1) * 12
        b += path(f'M{x - 9} -5 L{x - 11} -14 L{x - 6} -25 L{x - 3} {-h} L{x + 1} {-h - 7} L{x + 3} -22 L{x + 8} -15 L{x + 9} -8 L{x + 4} -3Z', '#f16a28', 'none')
        b += path(f'M{x - 5} -5 L{x - 5} -13 L{x} {-h * 0.7:.1f} L{x + 4} -15 L{x + 5} -6Z', '#ffc64b', 'none')
        b += path(f'M{x - 2} -5 L{x} -17 L{x + 3} -6Z', '#fff1a6', 'none')
    for x in (-7, 7):
        b += ell(x, 11, 4, 5, '#603d2b') + ell(x, 12, 2, 3, '#ffd365')
    b += line('M-4 23 L0 25 L5 22', '#603d2b', 1.8)
    return b


def collect_bodies(kinds):
    anatomy.wrap_base()
    bodies = {}
    for kind in kinds:
        art.CURRENT_KIND = kind
        if kind == 'torchwood':
            body = torchwood_body(kind)
        else:
            fn, args = art.RECIPES[kind]
            body = fn(kind, *args)
        # Throwing arms are authored facing left and mirrored to face the lawn.
        bodies[kind] = body.replace('transform="scale(-1 1)"', 'transform="matrix(-1 0 0 1 0 0)"')
    art.CURRENT_KIND = ''
    return bodies


# Species whose living skin is not their largest painted area.
PRIMARY = {'torchwood': 'bark', 'electric_bonk_choy': 'stalk', 'golden_milk': 'glass', 'jasmine_tea': 'porcelain'}


def primary_gradient(body):
    counts = {}

    def walk(node):
        for child in node:
            if child.attrib.get('data-part') == 'base':
                continue
            match = re.fullmatch(r'url\(#(\w+)\)', child.attrib.get('fill', ''))
            if match:
                counts[match.group(1)] = counts.get(match.group(1), 0) + 1
            walk(child)
    walk(ET.fromstring(f'<svg>{body}</svg>'))
    ranked = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    for gid, _ in ranked:
        if gid != 'leaf':
            return gid
    return ranked[0][0] if ranked else 'leaf'


def defs_block(grads):
    return '<defs>' + ''.join(f'<linearGradient id="{gid}" x1=".2" y1="0" x2=".8" y2="1"><stop stop-color="{c[0]}"/><stop offset="1" stop-color="{c[1]}"/></linearGradient>' for gid, c in grads.items()) + '</defs>'


def compact(svg):
    # Round joins and caps are inherited from the composer's root group.
    svg = svg.replace(' stroke-linejoin="round" stroke-linecap="round" ', ' ').replace(' stroke-linejoin="round" stroke-linecap="round"', '')
    # Inner mirrored parts keep their pose as matrices; a fusion model always faces the lawn.
    svg = re.sub(r'scale\(-([\d.]+) ([\d.]+)\)', r'matrix(-\1 0 0 \2 0 0)', svg)
    return re.sub(r'(\d+\.\d{2})\d+', r'\1', svg)


def gd(value):
    return json.dumps(value, ensure_ascii=True)


def main():
    plant_defs = (ROOT / 'scripts/data/plant_defs.gd').read_text()
    order = re.findall(r'"(\w+)"', re.search(r'const ORDER: Array = \[(.*?)\n\]', plant_defs, re.S).group(1))
    kinds = [k for k in order if k not in EXCLUDED]
    missing = [k for k in kinds if k not in T or k not in acc.GRAFTS]
    if missing:
        raise SystemExit(f'Missing fusion traits or accessory for: {missing}')
    grads = base_gradients()
    defs = defs_block(grads)
    bodies = collect_bodies(kinds)
    table = {}
    templated_bodies = {}
    for kind in kinds:
        body = compact(bodies[kind])
        primary = PRIMARY.get(kind) or anatomy.dominant_gradient(body, defs, ('bark',) if 'pult' in kind or kind in ('melon_pult', 'skylight_melon', 'fumarole_melon') else ())
        templated, slots, shapes = anatomy.tokenize(body, primary, grads)
        filled = templated.replace('url(#lf)', 'url(#leaf)')
        for n, (_, color) in enumerate(slots):
            filled = filled.replace('{s%d}' % n, color)
        renderable = filled.replace('url(#skin)', f'url(#{primary})')
        skin_marked = filled.replace('url(#skin)', '#ff00ff')
        found = anatomy.measure(kind, renderable, skin_marked, defs)
        light, dark = MATERIAL.get(kind, tuple(grads[primary]))
        spec = acc.GRAFTS[kind]
        entry = dict(T[kind])
        entry.update({
            'primary': primary, 'own': list(grads[primary]), 'light': light, 'dark': dark,
            'slots': slots, 'mask': compact(anatomy.mask_svg(shapes)),
            'slot': spec['slot'], 'acc': compact(spec['fn'](kind)),
            'weapon': compact(acc.WEAPONS[kind](kind)) if kind in acc.WEAPONS else '',
            'muzzle': acc.MUZZLE.get(kind, ''),
            'armed': kind in acc.WEAPONS and kind not in UNARMED_WEAPONS,
        })
        entry.update(found)
        table[kind] = entry
        templated_bodies[kind] = templated
    out = ['extends RefCounted', '', '# Generated by scripts/tools/build_fusion_parts.py; do not edit by hand.',
           '# Bodies are base plant art with re-colourable skin; KINDS holds each species\' anatomy and what it lends a fusion.']
    out.append('const GRADIENTS := {' + ', '.join(f'{gd(k)}: [{gd(v[0])}, {gd(v[1])}]' for k, v in grads.items()) + '}')
    out.append('const BODIES := {')
    for k, b in templated_bodies.items():
        out.append(f'\t{gd(k)}: {gd(b)},')
    out.append('}')
    out.append('const KINDS := {')
    for k, e in table.items():
        out.append(f'\t{gd(k)}: {gd(e)},')
    out.append('}')
    OUT.write_text('\n'.join(out) + '\n')
    print(f'Fusion anatomy: {len(table)} species -> {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB)')


if __name__ == '__main__':
    main()
