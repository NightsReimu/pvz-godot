#!/usr/bin/env python3
"""Build new fusion anatomy as importable SVGs. Models face right; no raster editing."""
from pathlib import Path
import json, math, hashlib, xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'art/vector/fusions'
INK = '#314c3e'
def path(d, fill, stroke=INK, width=1.5):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"/>'
def ell(x,y,rx,ry,fill,stroke=INK,width=1.3):
    return f'<ellipse cx="{x:.2f}" cy="{y:.2f}" rx="{rx:.2f}" ry="{ry:.2f}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'
def g(body,transform): return f'<g transform="{transform}">{body}</g>'
def eye(x,y): return ell(x,y,2,3.3,INK,'none')+ell(x-.6,y-1,.65,.85,'#fff9de','none')
def leaf(x,y,a,scale=1):
    return g(path('M0 0 Q-14 -13 -25 -1 Q-14 12 0 0Z','url(#leaf)')+path('M-1 0 L-20 -1','none','#73a76b',.8),f'translate({x} {y}) rotate({a}) scale({scale})')
def flower(x,y,r,col,petals=10):
    b=''
    for n in range(petals):
        a=n*360/petals
        b+=g(ell(0,-r,r*.25,r*.55,col,'#6f6941',.8),f'translate({x} {y}) rotate({a})')
    b+=ell(x,y,r*.66,r*.66,'url(#cream)')+eye(x-4,y-2)+eye(x+4,y-2)+path(f'M{x-4} {y+4} Q{x} {y+7} {x+4} {y+4}','none',INK,1)
    return b
DEFS='''<defs><linearGradient id="leaf" x2=".8" y2="1"><stop stop-color="#b1d887"/><stop offset="1" stop-color="#56895c"/></linearGradient><linearGradient id="body" x2=".7" y2="1"><stop stop-color="PRIMARY"/><stop offset="1" stop-color="SECONDARY"/></linearGradient><linearGradient id="cream" x2=".8" y2="1"><stop stop-color="#fff4d5"/><stop offset="1" stop-color="#dcb888"/></linearGradient><linearGradient id="metal" x2="1" y2="1"><stop stop-color="#cce6df"/><stop offset="1" stop-color="#739a90"/></linearGradient></defs>'''
def build_model(id,d):
    style=d['fusion_attack']; parts=d['fusion_components']; traits=d['fusion_traits']; count=min(5,len(parts))
    seed=int(hashlib.sha256(id.encode()).hexdigest()[:8],16)
    variation=(seed%137)/137
    primary,secondary=('#b7d988','#568756')
    if 'cherry_bomb' in parts: primary,secondary=('#f49ba4','#bf5264')
    elif 'potato_mine' in parts: primary,secondary=('#e3c594','#a98659')
    elif 'coffee_bean' in parts: primary,secondary=('#c7a375','#806442')
    if 'fire' in traits: primary,secondary=('#ffcf7c','#cb7851')
    if 'frost' in traits: primary,secondary=('#d8f4f2','#79b5c3')
    if 'hypno' in traits or 'poison' in traits: primary,secondary=('#e5c2ea','#a47dba')
    if 'sun' in traits: primary,secondary=('#f9db89','#c79851')
    if 'magnet' in traits: primary,secondary=('#b4dedb','#7196a1')
    if any(p in ('wallnut','tallnut','rock_armor_fruit') for p in parts): primary,secondary=('#dfbd88','#a27852')
    if 'pumpkin' in parts: primary,secondary=('#ffd288','#ca824d')
    b=ell(0,37,29,4,'#263e32','none',0)
    # Shared living rootstock, with per-species root topology rather than a flat badge.
    b+=path(f'M-18 34 Q{-21-variation*5:.2f} 20 -8 16 Q0 6 8 16 Q25 18 21 34Z','url(#leaf)')
    for n in range(3+seed%3): b+=leaf(-4+n*4,32+n%2*2,(-35+n*39+seed%15),.62+(n%2)*.1)
    if d['fusion_base']=='flower_pot':
        b+=path('M-29 21 L29 21 L23 42 L-22 42Z','url(#body)')+ell(0,22,30,6,'url(#cream)')
    if d['fusion_base']=='lily_pad' or 'water' in traits:
        b+=path('M-34 31 Q-20 14 3 24 Q32 16 37 31 Q18 44 -5 36 Q-25 43 -34 31Z','url(#leaf)')
        b+=path('M2 29 L27 38','none','#3e7054',1)
    if style=='sun':
        heads=2 if id=='twin_sunflower' else (3 if id=='triple_sunflower' else min(4,count))
        for n in range(heads):
            x=-21+n*42/max(heads-1,1); y=-21-((n%2)*10 if heads>2 else 0)
            b+=path(f'M0 27 Q{x*1.1:.2f} 13 {x:.2f} {y}','none','#518159',5)
            b+=flower(x,y,17+variation*2,'url(#body)',10+seed%4)
        if 'shot' in traits:
            b+=g(path('M-6 -6 Q-8 -21 7 -21 L29 -20 L30 -6Z','url(#leaf)')+ell(29,-13,5,8,'url(#metal)')+ell(30,-13,2.5,5,INK,'none'), 'translate(0 10)')
    elif style in ('shooter','spread','beam'):
        if any('shroom' in p for p in parts):
            b+=path('M-11 23 Q-14 2 -8 -6 L9 -6 Q17 7 11 23Z','url(#cream)')
            for n in range(min(3,count)):
                x=-17+n*17; y=-17-(n%2)*9
                b+=path(f'M{x-14} {y+3} Q{x-12} {y-20} {x+2} {y-16} Q{x+17} {y-14} {x+15} {y+3}Z','url(#body)')
                b+=ell(x-5,y-5,3,2,'#fff2d7','none')+eye(x,y+7)
            b+=path('M11 6 L30 4 L32 13 L11 13Z','url(#metal)')+ell(31,9,4,6,INK)
        else:
            b+=path('M-17 24 L-14 -4 L11 -5 L17 24Z','url(#leaf)')
            b+=path('M-25 -9 Q-30 -37 -9 -40 Q14 -44 17 -17 Q15 5 -10 5 Q-22 3 -25 -9Z','url(#body)')+eye(-10,-22)
            barrels=min(5,count) if style!='beam' else 2
            for n in range(barrels):
                y=-30+n*32/max(barrels-1,1)
                b+=path(f'M8 {y-4:.2f} L{31+variation*5:.2f} {y-5:.2f} L35 {y+5:.2f} L9 {y+4:.2f}Z','url(#metal)' if 'gatling' in id or style=='beam' else 'url(#body)')
                b+=ell(34,y,4,6,INK)+ell(35,y-1,2.1,3,'#1f3630','none')
            b+=path('M-19 -36 L-9 -43 L3 -40 L7 -32Z','url(#leaf)')
        if style=='beam':
            for n in range(3): b+=ell(13+n*6,15-n*2,3,5,'url(#body)')
    elif style=='lobber':
        b+=path('M-27 19 Q-34 -5 -21 -19 Q-5 -36 18 -23 Q37 -6 27 19Z','url(#body)')+eye(-10,6)+eye(0,6)
        for n in range(min(3,count)):
            x=-20+n*17
            b+=path(f'M{x-5} -9 L{x-9} -34 L{x+4} -41 L{x+12} -30 L{x+7} -6Z','url(#metal)')
            b+=ell(x-3,-36,7,4,'url(#cream)')+ell(x-3,-37,4,2.4,INK,'none')
        b+=leaf(-20,-10,-35,.65)+leaf(20,-10,210,.65)
    elif style in ('guard','roller'):
        b+=path('M-27 28 Q-38 4 -22 -26 Q-6 -42 16 -28 Q34 -12 29 26Z','url(#body)')+eye(-5,-12)+eye(5,-12)
        for n in range(3): b+=path(f'M{-22+n*16} 21 Q{-12+n*14} 2 {-20+n*15} -25','none','#8c9266',1)
        for side in [-1,1]:
            b+=path(f'M{side*18} -22 L{side*33} -11 L{side*34} 22 L{side*17} 31Z','url(#metal)')
            b+=ell(side*26,10,3,3,'url(#cream)')
        b+=path('M-14 -29 L-20 -42 L-7 -35 L0 -47 L7 -35 L20 -42 L14 -29Z','url(#metal)')
        if style=='roller':
            for side in [-1,1]: b+=ell(side*25,29,10,10,'url(#metal)')+ell(side*25,29,5,5,'url(#body)')
    elif style=='blade':
        b+=path('M-12 23 Q-19 -7 -12 -20 Q0 -38 15 -17 Q23 7 12 24Z','url(#body)')+eye(-4,-6)+eye(5,-6)
        for n in range(min(4,count)):
            a=n*360/min(4,count)+seed%28
            b+=g(path('M0 -20 Q27 -39 36 -14 Q23 -18 5 -9 Q0 -8 0 -20Z','url(#metal)')+path('M11 -19 Q26 -28 33 -17','none',primary,2),f'rotate({a} 0 -8)')
        b+=ell(0,-8,9,9,'url(#cream)')+eye(0,-9)
    elif style=='melee':
        for n in range(min(3,count)):
            x=-17+n*17
            b+=path(f'M0 24 Q{x-10} 9 {x} -9','none','#588454',5)
            b+=g(path('M-13 0 Q-20 -19 -4 -24 Q18 -24 20 -9 L7 -4 L19 3 Q5 17 -13 0Z','url(#body)')+path('M2 -10 L6 -17 L10 -10 L14 -15','none','#fff4d8',2)+eye(-3,-16),f'translate({x} {-12-(n%2)*8})')
    elif style=='bomb':
        for n in range(min(4,count)):
            x=-20+(n%2)*37; y=6-(n//2)*25
            b+=ell(x,y,15,17,'url(#body)')+eye(x-4,y)+eye(x+3,y)
            b+=path(f'M{x} {y-17} Q{x+2} {y-32} {x+10} {y-29}','none',INK,2)
            b+=ell(x+10,y-29,2.4,2.4,'#ffd883')
        b+=path('M-32 24 L31 24 L24 37 L-24 37Z','url(#metal)')
    else:
        # Support/control organisms grow a lantern, canopy or living rune crown.
        b+=path('M-6 27 L-6 -15 L6 -15 L8 27Z','url(#cream)')
        for n in range(min(5,count)+2):
            a=n*TAU/(min(5,count)+2); x=math.cos(a)*23; y=-13+math.sin(a)*17
            b+=leaf(round(x,2),round(y,2),round(a*180/math.pi+130),.65)
        b+=path('M-17 9 L-17 -26 Q0 -42 17 -26 L17 9 Q0 20 -17 9Z','url(#body)')+eye(-5,-9)+eye(5,-9)
        b+=path('M-26 -23 L0 -45 L26 -23Z','url(#metal)')
        b+=ell(0,-31,6,7,'url(#cream)')
    b=source_anatomy(parts,style,count,seed,variation,b,primary)
    # Visible terrain bases remain part of the new organism after anatomical replacement.
    if d['fusion_base']=='lily_pad':
        b+=path('M-34 31 Q-15 22 0 27 Q24 20 36 33 Q15 44 -9 36 Q-29 43 -34 31Z','url(#leaf)')+path('M2 30 L27 39','none','#457052',1)
    if d['fusion_base']=='flower_pot':
        b+=path('M-29 27 L29 27 L23 44 L-22 44Z','#c59b74')+ell(0,27,29,4,'url(#cream)')+path('M-22 35 L22 35','none','#e2be96',1.4)
    # Physical ingredient traits: these modify anatomy and read in a small battle cell.
    if 'fire' in traits:
        b+=path('M-22 -25 Q-32 -36 -22 -48 Q-21 -37 -15 -40 Q-9 -33 -18 -25Z','url(#body)')
    if 'frost' in traits:
        b+=path('M21 -25 L28 -46 L35 -29 L29 -17Z','#d7f4f5','#679da9')+path('M28 -43 L29 -19','none','#fffaff',1)
    if 'magnet' in traits:
        b+=path('M-28 17 L-28 0 Q-28 -8 -19 -8 Q-10 -8 -10 0 L-10 17 L-16 17 L-16 0 Q-19 -4 -22 0 L-22 17Z','url(#metal)')+path('M-28 13 L-22 13 M-16 13 L-10 13','none','#d89488',3)
    if 'shield' in traits and style not in ('guard','roller'):
        b+=path('M-29 11 L-14 9 L-12 25 L-23 33 L-32 24Z','url(#metal)')
    if 'heal' in traits:
        b+=flower(-24,22,8,'#e7b6cf',5)
    if 'shock' in traits:
        b+=path('M30 -12 L21 0 L27 0 L21 12 L35 -3 L28 -3Z','#fce39c','#829785',1)
    # Species leaf-vein topology uses all bits of the source hash (no text metadata in the hash).
    for n in range(4):
        x=-17+n*10; y=30+(seed>>(n*4)&7)*.35
        b+=path(f'M{x} 34 Q{x+2+variation:.3f} {y:.3f} {x+5} 31','none','#40694d',.6)
    signature=hashlib.sha256(b.encode()).hexdigest()[:16]
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="192" height="224" viewBox="-48 -60 96 112" data-plant-kind="{id}" data-facing="right" data-geometry-signature="{signature}">{DEFS.replace("PRIMARY",primary).replace("SECONDARY",secondary)}{b}</svg>'
def source_anatomy(parts,style,count,seed,v,original,primary):
    """Replace the central anatomy for botanical families, preserving the new rootstock.

    These are newly drawn fusion organisms, rather than copies of native SVGs.
    Source anatomy is kept legible: tree branches, bamboo joints, cactus needles,
    lanterns, cap gills, fruit lobes, beans, vines and flower corollas.
    """
    base=parts[0]
    if style in ('sun','blade','bomb','melee','guard','roller') or len(set(parts))>1:
        b=original
    else:
        ground=ell(0,38,31,4,'#263e32','none')+leaf(-3,33,-20,.9)+leaf(10,34,185,.8)
        b=original
        if any(x in base for x in ('pine','cypress','tree')):
            b=ground+path('M-8 35 L-10 -22 L9 -22 L10 35Z','#b38b60')
            for n in range(3):
                y=15-n*17; w=32-n*5
                b+=path(f'M{-w} {y} L0 {y-29} L{w} {y}Z','url(#leaf)')
            b+=eye(-4,19)+eye(4,19)
            for n in range(min(count,4)):
                x=(-1 if n%2==0 else 1)*(18-(n//2)*4);y=4-(n//2)*25
                b+=flower(x,y,8,'url(#body)',7)
                if style=='beam':b+=path(f'M{x} {y+3} L{x+17} {y+3} L{x+18} {y+9} L{x} {y+9}Z','url(#metal)')
        elif any(x in base for x in ('bamboo','reed','leyline')):
            b=ground
            for n in range(min(4,count+1)):
                x=-23+n*15;y=-36+(n%2)*12
                b+=path(f'M{x-4} 32 L{x-5} {y} Q{x} {y-8} {x+5} {y} L{x+4} 32Z','url(#leaf)')
                for y2 in range(int(y+8),31,13):b+=path(f'M{x-4} {y2} L{x+4} {y2}','none',INK,1)
                b+=leaf(x,y+10,40,.52)
                if style=='shooter':b+=path(f'M{x+4} {y+4} L{x+15} {y+4} L{x+15} {y+10} L{x+4} {y+10}Z','url(#body)')
            b+=eye(-10,17)+eye(0,17)
        elif 'cactus' in base:
            b=ground+path('M-15 30 L-16 -26 Q0 -46 15 -26 L17 30Z','url(#leaf)')
            for side in (-1,1):
                b+=path(f'M{side*13} 4 Q{side*34} 13 {side*31} -14 L{side*24} -14 Q{side*25} 0 {side*13} -5Z','url(#leaf)')
            for n in range(9):
                x=(-1 if n%2==0 else 1)*(14 if n<5 else 28);y=-22+n*5
                b+=path(f'M{x} {y} L{x+(-5 if x<0 else 5)} {y-3}','none','#eadfc3',1)
            b+=eye(-4,-13)+eye(4,-13)+flower(0,-34,8,'url(#body)',5)
        elif any(x in base for x in ('ivy','vine','fern','tentacle','root','anchor')):
            b=ground
            for n in range(min(count+1,5)):
                x=-26+n*13;y=-28-(n%2)*12
                b+=path(f'M0 31 Q{x-16} 12 {x} {y} Q{x+8} {y-12} {x+13} {y-1}','none','#61905c',5)
                b+=leaf(x,-4-n%2*9,30+n*18,.65)+leaf(x,y+8,210,.6)
                b+=ell(x+10,y,7,6,'url(#body)')
            b+=ell(0,21,12,13,'url(#body)')+eye(-4,19)+eye(4,19)
        elif any(x in base for x in ('lily','lotus','orchid','tulip','blossom','bloom','flower','grass','daisy')):
            b=ground+path('M-4 33 Q-10 4 0 -25 L6 -25 Q-1 7 4 33Z','url(#leaf)')
            for n in range(min(count,4)):
                x=-22+n*44/max(min(count,4)-1,1); y=-17-(n%2)*13
                b+=path(f'M0 25 Q{x-8} 3 {x} {y}','none','#598858',3)
                b+=flower(x,y,14+(seed%3),'url(#body)',5+seed%3)
                if style in ('beam','shooter','spread'):
                    b+=path(f'M{x+5} {y+1} L{x+17} {y-1} L{x+19} {y+6} L{x+5} {y+7}Z','url(#body)')+ell(x+18,y+3,3,4,INK)
        elif 'shroom' in base:
            b=ground
            for n in range(min(count,3)):
                x=-19+n*19;y=-20-(n%2)*12
                b+=path(f'M{x-6} 30 L{x-8} {y+8} L{x+8} {y+8} L{x+6} 30Z','url(#cream)')
                b+=path(f'M{x-18} {y+9} Q{x-17} {y-24} {x+2} {y-24} Q{x+22} {y-19} {x+18} {y+9}Z','url(#body)')
                b+=ell(x,y+9,18,4,'#e5d1b2')+eye(x-3,y+17)+eye(x+4,y+17)
                for stripe in range(3):b+=ell(x-10+stripe*8,y-5-(stripe%2)*7,3,2,'#fff4df','none')
        elif base in ('garlic','coffee_bean','ice_cream','brine_pot','pulse_bulb'):
            b=ground
            bulb_fill='url(#body)' if base=='coffee_bean' else 'url(#cream)'
            for n in range(min(count,3)):
                x=-18+n*18;y=6-(n%2)*16
                b+=path(f'M{x-12} {y+15} Q{x-22} {y-3} {x-3} {y-24} Q{x+20} {y-9} {x+13} {y+15}Z',bulb_fill)+eye(x-4,y)+eye(x+4,y)
                b+=path(f'M{x} {y-17} Q{x-7} {y-5} {x} {y+10}','none','#a78864',1.3)
                b+=leaf(x,y-24,-20,.4)
        elif base in ('blover','wind_orchid','roof_vane','steam_clover','frost_fan'):
            b=ground+path('M-4 32 L-4 -17 L4 -17 L4 32Z','url(#cream)')
            for n in range(5):
                b+=g(path('M0 -12 Q-9 -40 7 -46 Q25 -36 8 -12Z','url(#leaf)'),f'rotate({n*72} 0 -10)')
            b+=ell(0,-10,10,11,'url(#body)')+eye(-4,-11)+eye(4,-11)
    # Fruit geometry and source identities augment compatible fusion structures.
    if any('melon' in x for x in parts):
        b+=ell(0,17,23,17,'url(#leaf)')
        for n in range(4):b+=path(f'M{-15+n*10} 4 Q{-22+n*13} 19 {-14+n*10} 30','none','#477359',1.4)
        b+=eye(-5,14)+eye(5,14)
    if any('gourd' in x for x in parts):
        b+=path('M-15 30 Q-29 8 -11 0 Q-17 -21 0 -23 Q19 -19 12 -1 Q31 8 17 30Z','url(#body)')+eye(-4,10)+eye(5,10)
    if any('pepper' in x for x in parts):
        b+=path('M-24 16 Q-38 -6 -26 -17 Q-13 -17 -17 5 Q-10 21 1 19 Q-5 34 -24 16Z','#e6a165')+leaf(-26,-19,20,.45)
    if any('hive' in x or 'honey' in x for x in parts):
        for n in range(3):b+=ell(-23+n*8,12+n%2*7,6,7,'#e6c67d')
    if any('time' in x or 'destiny' in x for x in parts):
        b+=path('M-29 -7 L-13 -7 L-25 5 L-13 18 L-29 18 L-17 5Z','url(#cream)')
    if any('plantern'==x or 'lantern' in x for x in parts):
        b+=path('M-28 10 L-28 -12 L-12 -12 L-12 10Z','url(#cream)')+path('M-32 -12 L-20 -22 L-8 -12Z','url(#metal)')+path('M-24 -8 L-24 8 M-16 -8 L-16 8','none','#b89a63',1)
    if any('umbrella' in x for x in parts):
        b+=path('M-37 -27 Q0 -60 37 -27 Q27 -34 18 -25 Q7 -34 0 -25 Q-8 -34 -18 -25 Q-28 -34 -37 -27Z','url(#leaf)')
    # These familiar silhouettes stay recognizable in a mixed graft, even when
    # the combat dispatcher gives them a different weapon class.
    if base == 'torchwood' and len(set(parts)) == 1:
        b=ell(0,38,27,4,'#263e32','none')
        b+=path('M-20 31 L-22 -15 Q-12 -25 0 -19 Q13 -24 22 -14 L20 31 Q0 43 -20 31Z','#af7653')
        for n in range(4):b+=path(f'M{-15+n*9} 31 Q{-22+n*10} 5 {-15+n*9} -13','none','#76533b',1.4)
        b+=ell(0,-17,22,6,'#eac08b')+ell(0,-17,14,3,'#594635')+eye(-6,8)+eye(6,8)
        b+=path('M-15 -20 Q-30 -33 -12 -50 Q-14 -37 -3 -39 Q8 -61 14 -43 Q30 -28 14 -19Z','#ee9c42','#bf6738')
        b+=path('M-5 -22 Q-14 -34 1 -44 Q-1 -32 9 -27 L7 -20Z','#fff2a1','#efc476',.8)
    if base == 'starfruit' and len(set(parts)) == 1:
        b=ell(0,38,28,4,'#263e32','none')+leaf(-3,32,-20,.8)+leaf(10,34,190,.7)
        b+=path('M0 -47 L11 -22 L36 -17 L19 4 L24 32 L0 20 L-24 32 L-19 4 L-36 -17 L-11 -22Z','#f9dd8c','#a88e55',1.8)
        b+=path('M0 -38 L4 -12 L27 -14 L9 0 L17 23 L0 9 L-17 23 L-9 0 L-27 -14 L-4 -12Z','#ffedae','#dabb6f',.8)
        b+=eye(-6,-6)+eye(6,-6)+path('M-5 3 Q0 8 5 3','none',INK,1)
    if base == 'sun_shroom' and len(set(parts)) == 1:
        b=ell(0,38,26,4,'#263e32','none')+leaf(-6,34,-20,.6)+leaf(6,34,190,.6)
        b+=path('M-10 31 L-12 -1 L12 -1 L10 31Z','url(#cream)')
        b+=path('M-30 -1 Q-27 -44 0 -46 Q30 -43 31 -1Z','#e9bd67','#896f42')+ell(0,-1,30,6,'#f8df9c')
        for x,y in [(-16,-18),(0,-30),(18,-20)]:b+=ell(x,y,4,3,'#fff3b8','none')
        b+=eye(-5,14)+eye(5,14)
    if base == 'pumpkin' and len(set(parts)) == 1:
        b=ell(0,38,31,4,'#263e32','none')+path('M-5 -30 Q0 -39 8 -33 L6 -22 L-3 -22Z','#678757')
        b+=path('M-29 28 Q-40 -6 -24 -22 Q-14 -32 0 -25 Q19 -33 29 -17 Q40 7 29 29 Q0 44 -29 28Z','#e5aa5e','#9d7043')
        for x in [-18,-8,8,18]:b+=path(f'M{x} 30 Q{x*1.6} 3 {x} -23','none','#c88a49',1.5)
        b+=path('M-20 -3 L-9 -10 L-5 1Z M7 1 L10 -10 L21 -3Z','#514331')
        b+=path('M-20 15 L-12 11 L-7 18 L0 12 L8 18 L14 11 L21 15 L13 26 L-13 26Z','#514331')
    return b

TAU=math.tau
if __name__=='__main__':
    data=json.loads((ROOT/'output/fusion-plant-data.json').read_text())
    OUT.mkdir(parents=True,exist_ok=True)
    for id,d in data.items():
        if id.startswith(('pair_','mix_')): continue
        (OUT/f'{id}.svg').write_text(build_model(id,d))
    print(f'Authored {sum(not id.startswith(("pair_","mix_")) for id in data)} named fusion SVGs')
    # Standalone botanical organs also support independent SVGs for recursive grafts.
    organ_bodies={}
    native=json.loads((ROOT/'output/fusion-native-art-data.json').read_text())
    import re
    for kind,d in native.items():
        organ=build_model('organ_'+kind,d)
        body=re.search(r'<svg[^>]*>(.*)</svg>',organ).group(1)
        body=re.sub(r'id="([^"]+)"',lambda m:'id="'+kind+'_'+m[1]+'"',body)
        body=re.sub(r'url\(#([^\)]+)\)',lambda m:'url(#'+kind+'_'+m[1]+')',body)
        organ_bodies[kind]=body
    text='extends RefCounted\n# Authored source anatomy used by independent graft SVGs. Generated by build_fusion_plant_art.py.\nconst BODIES := '+json.dumps(organ_bodies,ensure_ascii=False,indent=1)+'\n'
    (ROOT/'scripts/data/fusion_organ_art.gd').write_text(text)
    print(f'Authored {len(organ_bodies)} botanical organ structures')
