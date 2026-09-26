#!/usr/bin/env python3
"""Authored SVG geometry for the unit art pass. No network or raster processing.
Run from any directory to reproducibly rebuild art/vector/plants and its manifest.
Every recipe is chosen for the species; gameplay state variants share its anatomy.
"""
from pathlib import Path
import math

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art/vector/plants'
INK = '#283e35'

def path(d, fill, stroke=INK, width=1.7, **attrs):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round" '+ ' '.join(f'{k.replace("_", "-")}="{v}"' for k,v in attrs.items())+'/>'

def ell(x,y,rx,ry,fill,stroke='none',width=1.4):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'

def group(body, transform): return f'<g transform="{transform}">{body}</g>'
def line(d,col=INK,w=1.3): return path(d,'none',col,w)
def leaf(x,y,angle=0,length=24,col='url(#leaf)'):
    return group(path(f'M0 0 Q{-length*.8} {-length*.4} {-length} 0 Q{-length*.5} {length*.63} 0 0Z',col)+line(f'M-2 1 Q{-length*.45} 0 {-length*.84} 0','#488343',.8),f'translate({x} {y}) rotate({angle})')

def base(stem=True,col='url(#leaf)'):
    body=ell(0,35,27,4,'#233e2b',width=0).replace('fill="#233e2b"','fill="#233e2b" opacity=".14"')
    if stem: body+=path('M-4 32 Q1 17 -3 -5 L4 -5 Q7 13 3 32Z',col)+line('M-1 27 Q3 16 0 4','#a6cd6b',1.5)
    return body+leaf(-1,31,8,27,col)+leaf(2,32,170,27,col)+leaf(0,34,-35,15,col)

def eye(x,y,rx=2.4,ry=4):
    return ell(x,y,rx,ry,INK)+ell(x-.65,y-1.6,.75,1.1,'#fffbed')

def face(x=0,y=0,mood='smile',spacing=6):
    body=eye(x-spacing,y)+eye(x+spacing,y)
    if mood=='stern': body+=line(f'M{x-11} {y-6} l8 2 M{x+3} {y-4} l8 -2',INK,1.8)
    if mood=='worried': body+=line(f'M{x-10} {y-7} l6 -2 M{x+4} {y-9} l6 2')
    if mood=='sleep': return line(f'M{x-10} {y} q4 4 8 0 M{x+3} {y} q4 4 8 0 M{x-2} {y+9} q3 -2 5 0',INK,1.8)
    body+=line(f'M{x-4} {y+9} q4 {3 if mood=="smile" else -1} 8 0',INK,1.4)
    return body

def star(x,y,r,col='#ffe59b'):
    pts=[]
    for i in range(10):
        a=-math.pi/2+i*math.pi/5; rr=r if i%2==0 else r*.47
        pts.append(f'{x+math.cos(a)*rr:.2f},{y+math.sin(a)*rr:.2f}')
    return path('M'+' L'.join(pts)+'Z',col,INK,1.1)

def crystal(x,y,h=18,col='url(#ice)',angle=0):
    return group(path(f'M-5 0 L-7 {-h*.55} L0 {-h} L7 {-h*.55} L5 0Z',col)+line(f'M0 {-h+3} V-1 M-6 {-h*.55} L0 {-h*.43} L6 {-h*.55}','#e7ffff',.85),f'translate({x} {y}) rotate({angle})')

def petal(x,y,a,length=23,width=8,col='url(#gold)'):
    return group(path(f'M0 0 C{-width} -8 {-width} {-length+5} 0 {-length} C{width} {-length+5} {width} -8 0 0Z',col,INK,1.25)+line(f'M0 -5 V{-length+6}','#fff3c8',.75),f'translate({x} {y}) rotate({a})')

def pea(kind,col='url(#pea)'):
    h=path('M-17 -11 C-30 -18 -27 -34 -11 -36 C1 -40 14 -30 15 -21 L27 -24 Q35 -23 35 -14 Q35 -3 26 -3 L11 -8 C7 5 -10 9 -19 -1 Q-23 -6 -17 -11Z',col)
    h+=path('M-21 -17 Q-21 -31 -10 -31 Q-3 -33 -1 -29 Q-14 -28 -15 -17Z','#d2ed93','none')
    h+=ell(29,-14,7,10,col,INK)+ell(31,-14,3.6,6,'#294e37')+ell(31,-16,1.4,2.4,'#112f2a')+eye(-9,-22,2.7,4.8)
    h+=line('M-17 -7 Q-11 -3 -4 -6','#437347',1)
    if kind in ['repeater','shadow_pea','prism_pea','plasma_shooter','split_pea']:
        h+=leaf(-16,-32,50,15,col)+leaf(-14,-33,80,16,col)+line('M-14 -28 L-6 -26',INK,1.8)
    if kind=='snow_pea':
        h+=crystal(-15,-31,12,angle=-20)+crystal(-6,-34,13)+star(-16,-12,3,'#efffff')
    if kind=='amber_shooter': h+=ell(-15,-11,4,5,'#f7ac42',INK)+line('M-17 -13 l3 -2','#fff0ad',1.5)
    if kind=='shadow_pea': h+=path('M-18 -38 Q-31 -33 -26 -20 Q-38 -35 -18 -38Z','#bca6ee')
    if kind=='prism_pea': h+=crystal(-21,-19,18,angle=-30)+crystal(-16,-31,13,angle=20)
    if kind=='plasma_shooter': h+=path('M14 -24 Q9 -14 14 -4 M21 -25 Q16 -14 21 -3','none','#62dceb',3)+ell(31,-14,2.8,5,'#b3fcf2')
    if kind=='threepeater':
        b=base()+path('M-1 21 Q-22 14 -22 -1 M2 21 Q24 9 23 -1','none','#355c35',6)
        return b+group(h,'translate(-19 8) scale(.62)')+group(h,'translate(18 6) scale(.66)')+group(h,'translate(0 -17) scale(.8)')
    if kind=='split_pea': return base()+group(h,'translate(-9 11) scale(-.55 .55)')+h
    return base()+h

def sunflower(kind='sunflower',petals='url(#gold)',core='url(#sun)'):
    b=base(); count=12
    for i in range(count): b+=petal(0,-12,i*360/count+15,33,6.5,petals)
    for i in range(count): b+=petal(0,-12,i*360/count,29,6.8,petals)
    b+=ell(0,-12,17,17,core,INK,1.8)+path('M-13 -17 Q-11 -26 -2 -26','none','#ffe6a1',2.5)+face(0,-15)
    b+=ell(-10,-9,3,1.7,'#df8653')+ell(10,-9,3,1.7,'#df8653')
    if kind=='marigold': b=group(b,'translate(0 7) scale(.8)')+leaf(-2,20,45,19)+leaf(2,22,140,20)
    if kind=='galaxy_sunflower': b+=star(-28,-38,4,'#e4baf9')+star(28,-32,3,'#c4deff')+line('M-32 4 Q-11 20 31 -9','#b3a3e3',1.5)
    if kind=='thermal_sunflower': b+=path('M-12 -37 Q-21 -44 -16 -50 Q-10 -45 -12 -37 M10 -38 Q16 -49 11 -52 Q23 -45 10 -38','#f5b357','none')
    return b

def nut(kind,state=''):
    tall=kind in ['tallnut','brick_guard','holo_nut']
    c='url(#bark)' if kind not in ['crystal_nut','holo_nut','glitch_walnut'] else ('url(#ice)' if kind=='crystal_nut' else 'url(#mint)')
    top=-49 if tall else -32
    b=ell(0,35,25,4,'#233e2b').replace('/>',' opacity=".14"/>')
    b+=path(f'M-24 25 Q-29 2 -22 {top+10} Q-18 {top-4} 0 {top} Q22 {top-4} 25 {top+16} Q31 13 22 32 Q1 40 -20 32Z',c,INK,2)
    if kind=='crystal_nut':
        b+=crystal(-12,-15,26)+crystal(1,-26,24)+crystal(15,-10,27)
        b+=line('M-21 5 L-6 -4 L8 5 L24 1 M-6 -4 L-4 30 M8 5 L16 29','#bcf8ff',1.1)
    elif kind in ['holo_nut','glitch_walnut']:
        b+=line('M-20 -15 H20 M-24 3 H25 M-21 24 H22','#bcffea',1)
        b+=path('M-25 0 h8 v-5 h-10 M22 17 h8 v4 h-12','none','#737dbf',2.8)
    elif kind=='brick_guard':
        b+=line('M-21 -27 H21 M-25 -8 H26 M-25 13 H25 M-6 -45 V-27 M8 -27 V-8 M-10 -8 V13 M6 13 V32','#754b37',1.2)
    else:
        b+=path(f'M-20 15 Q-25 -8 -15 {top+11} Q-10 {top+3} -7 {top+8} Q-18 -6 -15 14Z','#eac78a','none')
        for d in ['M-19 17 q-5 5 1 10','M16 -17 q5 2 4 7','M-11 -22 q-5 4 -3 8','M16 18 q6 3 0 9','M-4 29 q5 -3 9 0']: b+=line(d,'#9a713e',1)
    b+=face(0,-8 if tall else -5,'worried' if state else 'smile',7)
    if state:
        b+=line(f'M-6 {top} l-3 11 8 6 -9 10 8 8', '#684737',2.4)
        if state=='critical': b+=path('M24 8 L14 13 L20 21 L11 29 L20 33','#74513a',INK,1.2)+line('M-22 18 l7 4 -2 9','#684737',2)
    return b

def shroom(kind,state=''):
    colours={'puff_shroom':'url(#violet)','sun_shroom':'url(#gold)','fume_shroom':'url(#plum)','hypno_shroom':'url(#violet)','scaredy_shroom':'url(#plum)','ice_shroom':'url(#ice)','doom_shroom':'url(#night)','sea_shroom':'url(#mint)','magnet_shroom':'url(#rose)','nether_shroom':'url(#night)','void_shroom':'url(#night)','mirror_shroom':'url(#ice)','plasma_shroom':'url(#violet)','chaos_shroom':'url(#rose)'}
    col=colours[kind]; w=31 if kind in ['fume_shroom','doom_shroom','hypno_shroom'] else 25
    tall=kind=='scaredy_shroom'; y=-13 if tall else -3
    b=ell(0,35,22,4,'#233e2b').replace('/>',' opacity=".14"/>')
    b+=path(f'M-10 {y-3} Q-4 16 -14 28 Q-19 36 -5 35 L8 35 Q19 36 12 28 Q6 16 11 {y-3}Z','url(#cream)')
    b+=path(f'M-10 {y+1} Q-3 21 -13 30 L-7 33 Q0 11 -2 {y+1}Z','#d4c297','none')
    b+=ell(0,y,w,8,'#77576c',INK)+line(f'M-18 {y} L-6 {y+4} M-8 {y-1} L-2 {y+5} M8 {y-1} L3 {y+5} M18 {y} L7 {y+4}','#e7c9c4',1)
    if kind=='scaredy_shroom':
        cap='M-19 -15 Q-22 -42 -8 -46 Q5 -51 14 -38 Q20 -24 19 -15 Q3 -7 -19 -15Z'
    elif kind=='ice_shroom': cap='M-28 -5 L-24 -19 L-17 -17 L-10 -33 L0 -24 L10 -35 L17 -16 L25 -22 L28 -5 Q0 3 -28 -5Z'
    elif kind=='mirror_shroom': cap='M-29 -5 L-18 -30 L2 -39 L23 -26 L29 -5 L3 1Z'
    elif kind=='doom_shroom': cap='M-32 -4 C-34 -16 -29 -31 -18 -30 Q-12 -40 0 -32 Q12 -39 20 -29 Q34 -27 32 -4 Q0 6 -32 -4Z'
    else: cap=f'M{-w} {y-2} C{-w-2} {y-20} -17 {y-36} 0 {y-34} C18 {y-36} {w+3} {y-17} {w} {y-2} Q0 {y+5} {-w} {y-2}Z'
    b+=path(cap,col,INK,2)
    if kind not in ['ice_shroom','mirror_shroom']:
        b+=path(f'M{-w+6} {y-9} Q{-w+6} {y-25} -8 {y-28}', 'none','#ffffff',2,opacity='.32')
    if kind in ['ice_shroom','mirror_shroom']:
        b+=line('M-18 -28 L-5 -9 L-25 -9 M-5 -9 L2 -34 L14 -7 L-5 -9 L1 -1 M14 -7 L24 -20','#e5ffff',1.2)
    elif kind=='hypno_shroom':
        for x,yy,rx in [(-14,-20,6),(4,-29,6),(19,-15,5)]: b+=ell(x,yy,rx,rx*.65,'#72c7c2',INK,.8)+ell(x,yy,rx*.5,rx*.34,'#f5b9c5')
    elif kind in ['void_shroom','nether_shroom']:
        b+=path('M9 -30 Q-8 -22 5 -11 Q-16 -13 -10 -26 Q-4 -35 9 -30Z','#baa2df','none')
    elif kind=='plasma_shroom':
        b+=path('M-13 -24 L1 -28 L-3 -19 L12 -22 L-2 -8 L0 -17 L-12 -14Z','#d0f8ff',INK,1)
        b+=ell(-27,-30,3,3,'#99e9ff')+ell(27,-34,4,4,'#c3a5f1')
    elif kind=='chaos_shroom':
        b+=star(-13,-22,6,'#ffe393')+path('M6 -30 q13 -3 12 6 q0 5 -6 6 v4 M12 -10 v1','none','#b5efdd',2.5)
    elif kind=='doom_shroom':
        b+=line('M-23 -17 l8 -6 3 8 M7 -28 l-1 9 8 5','#9c6674',2)
    else:
        for x,yy,rx in [(-13,y-16,4),(4,y-26,5),(17,y-11,3)]: b+=ell(x,yy,rx,rx*.7,'#f3e3c2',width=0)
    if kind in ['hypno_shroom','chaos_shroom']:
        for x in [-6,6]: b+=ell(x,13,4,5,'#eee3c9',INK,1)+line(f'M{x} 10 q-5 0 -3 5 q4 5 6 0 q1 -4 -3 -3 q-2 1 0 2','#b15f83',1.1)
        b+=line('M-3 24 q3 2 6 0')
    elif state=='hiding': b+=face(0,17,'sleep')
    else: b+=face(0,13,'stern' if kind in ['doom_shroom','ice_shroom'] else ('worried' if tall else 'smile'),5)
    if kind in ['puff_shroom','fume_shroom','sea_shroom']:
        reach=27 if kind=='fume_shroom' else 20
        b+=path(f'M7 14 Q16 8 {reach} 10 L{reach} 23 Q15 25 8 21Z',col)+ell(reach,16.5,4,7,col,INK)+ell(reach+1,17,2,4,'#463347')
    if kind=='void_shroom': b+=ell(0,-23,10,6,'#262e45','#bba5d3',1.5)+line('M-18 -25 Q0 -41 21 -24','#b8a5c7',1)
    if kind=='magnet_shroom':
        b+=path('M-13 -33 V-44 H-5 V-33 Q0 -26 5 -33 V-44 H13 V-33 Q0 -12 -13 -33Z','#d86761')+path('M-13 -40 V-46 H-5 V-40 M5 -40 V-46 H13 V-40','#d8e2d4')
    if state=='young': b=group(b,'translate(0 12) scale(.66)')
    if state=='hiding': b=group(b,'translate(0 14) scale(1 .60)')
    return b

def flower(kind,col='url(#rose)',mode='petals'):
    b=base(); y=-12
    if mode=='lotus':
        b=base(False)+ell(0,30,30,8,'url(#leaf)',INK)
        for x,a in [(-13,-62),(13,62),(-7,-30),(7,30),(0,0)]: b+=petal(x,15,a,45,12,col)
        b+=ell(0,13,15,10,'url(#gold)',INK)+face(0,9,spacing=5)
    elif mode=='orchid':
        for a,l,w in [(-65,37,12),(65,37,12),(-130,29,12),(130,29,12),(0,34,8)]: b+=petal(0,-7,a,l,w,col)
        b+=path('M-8 -12 Q0 -16 8 -12 Q17 2 6 8 Q0 13 -6 8 Q-17 2 -8 -12Z','url(#cream)')+face(0,-6,spacing=4)
    elif mode=='rose':
        for a in range(0,360,60): b+=petal(0,y,a,28,15,col)
        b+=path('M-17 -23 Q-2 -35 13 -22 Q26 -8 10 7 Q-7 10 -19 -2 Q-27 -15 -10 -21 Q5 -23 10 -10 Q5 -1 -4 -7 Q-9 -11 -3 -14',col,INK,1.4)+face(0,-5,spacing=5)
    else:
        count=6 if mode=='lily' else 9
        for i in range(count): b+=petal(0,y,i*360/count,32,9 if count==6 else 7,col)
        b+=ell(0,y,14,15,'url(#cream)',INK)+face(0,y-3,spacing=5)
    # Small, anchored signature details; never place an effect across the eyes.
    if kind=='magnet_orchid': b+=path('M-9 -41 V-50 H-3 V-43 Q0 -39 3 -43 V-50 H9 V-41 Q0 -29 -9 -41Z','#c66a78')+line('M-9 -48 h6 M3 -48 h6','#eff7e8',2.5)
    if kind=='time_rose':
        b+=ell(18,21,10,10,'#e1bd75',INK)+ell(18,21,7.5,7.5,'#faf0ca',INK,.8)+line('M18 16 v5 l4 2','#604a44',1.4)
    elif kind=='soul_flower': b+=path('M-31 -31 Q-37 -20 -29 -20 Q-22 -23 -26 -29 L-28 -38Z','#b7d5e5')+eye(-29,-26,1,1.4)
    elif kind=='magnet_daisy': b+=path('M-13 -41 V-50 H-6 V-43 Q0 -36 6 -43 V-50 H13 V-41 Q0 -23 -13 -41Z','#c86575')+line('M-13 -47 H-6 M6 -47 H13','#dff5ed',3)
    elif kind=='honey_blossom':
        b+=path('M12 20 l6 -4 6 4 v7 l-6 4 -6 -4Z','#c28a35')+ell(18,23,2,4,'#f5d578')
    elif kind=='hive_flower':
        b+=path('M17 -32 Q34 -26 26 -10 L13 -14Z','url(#gold)')+line('M17 -26 l12 3 M15 -20 l12 3','#8c612f',2)
    elif kind=='chain_lotus':
        for i in range(5): b+=ell(-26+i*12,31-abs(2-i)*3,5,2.8,'none','#a87c42',1.8)
    elif kind=='bubble_lotus':
        for x,y,r in [(-28,-19,6),(26,-33,5),(32,-8,3)]: b+=ell(x,y,r,r,'#bfe4eb','#5999b8',1)+line(f'M{x-r*.5} {y} q0 {-r*.5} {r*.5} {-r*.6}','#f7ffff',1.3)
    elif kind=='holy_lotus' or kind=='holy_flower': b+=ell(0,-40,15,4,'none','#d4b26d',2)
    elif kind=='laser_lily': b+=crystal(18,-17,17,'url(#rose)',65)+ell(31,-24,3,3,'#fbe7d4')
    elif kind=='aurora_orchid': b+=line('M-30 -25 Q-40 -2 -23 14 M31 -25 Q41 -4 26 9','#b4cfdc',2)
    elif kind=='meteor_flower': b+=path('M22 -35 Q25 -43 16 -52 Q35 -46 31 -29Z','url(#fire)')+star(26,-34,5,'#fff2a8')
    elif kind=='core_blossom': b+=path('M-17 -6 L-24 -10 L-26 0 L-18 7 M17 -6 L24 -10 L26 0 L18 7','url(#stone)')+line('M-10 3 l6 4 -2 8 M10 3 l-2 5 3 7','#e47739',2)
    elif kind=='solar_emperor': b+=path('M-13 -30 L-18 -44 L-5 -36 L0 -48 L5 -36 L18 -44 L13 -30Z','url(#gold)')+ell(0,-34,2.5,3.2,'#ce6f4a')
    elif kind=='thunder_god': b+=path('M-3 -45 L-14 -27 L-3 -27 L-7 -16 L12 -34 H2 L9 -45Z','url(#gold)')
    elif kind=='ice_queen': b+=crystal(-14,-22,21,angle=-25)+crystal(0,-29,22)+crystal(14,-22,21,angle=25)
    elif kind=='seraph_flower':
        b=path('M-10 -12 Q-31 -28 -39 -19 Q-35 -1 -14 10 M10 -12 Q31 -28 39 -19 Q35 -1 14 10','#e8eadc')+b+ell(0,-44,13,3,'none','#d5b57a',2)
    return group(b,'translate(0 4) scale(.86)') if mode=='lotus' else b

def tree(kind,col='url(#leaf)'):
    b=base(False)+path('M-10 33 Q-4 8 -10 -17 L10 -17 Q3 11 14 33 L4 30 L-1 35 L-5 30Z','url(#bark)')+line('M-4 25 Q2 13 -1 2','#745738',1)
    if kind in ['frost_cypress','thunder_pine','thunder_god']:
        for x,y,r in [(0,-32,23),(0,-17,30),(0,0,34)]: b+=path(f'M{x} {y-18} Q{x-9} {y-2} {x-r} {y+9} Q{x-12} {y+14} {x} {y+11} Q{x+12} {y+14} {x+r} {y+9} Q{x+9} {y-2} {x} {y-18}Z',col)+line(f'M{x-10} {y+5} L{x+9} {y+5}','#cee6be',1)
        b+=face(0,18,spacing=4)
        if kind!='frost_cypress': b+=path('M0 -46 L-8 -32 H0 L-4 -20 L12 -37 H4 L10 -46Z','#ffe39a')
    elif kind=='phoenix_tree':
        b+=path('M-5 2 Q-38 -1 -39 -35 Q-28 -13 -19 -18 Q-32 -28 -21 -45 Q-17 -24 -7 -22 Q-11 -43 4 -50 Q-3 -27 9 -20 Q20 -26 23 -40 Q34 -21 19 -11 Q31 -11 39 -29 Q43 -1 13 9Z','url(#fire)')
        b+=petal(0,6,0,41,10,'url(#gold)')+face(0,-8,'stern',5)
    elif kind=='destiny_tree':
        for x,y,angle in [(-25,-15,-50),(25,-15,50),(0,-37,0)]:
            b+=path(f'M0 11 Q{x} 6 {x} {y}','none','#98764b',5)+leaf(x,y,angle,21,'url(#gold)')+star(x,y-7,5,'#f5d98a')
        b+=leaf(-5,-13,12,24,'url(#gold)')+leaf(5,-15,166,24,'url(#gold)')+face(0,13,spacing=4)
    else:
        for x,y,r in [(-19,-15,17),(18,-19,19),(0,-31,21),(0,-8,20)]: b+=ell(x,y,r,r*.85,col,INK)
        b+=face(0,-9,'stern' if kind=='vine_emperor' else 'smile')
        if kind=='mamba_tree': b+=path('M-19 12 Q-31 -3 -21 -10 Q-9 -18 -8 -5 Q-7 8 -1 9','none','#b59653',5)+eye(-20,-9,1.3,2)
        elif kind=='vine_emperor': b+=path('M-22 -30 L-18 -45 L-10 -36 L0 -48 L10 -36 L18 -45 L22 -30Z','url(#gold)')
    return b

def fern(kind,col='url(#leaf)'):
    b=base(False)
    for x,y in [(-25,-4),(-15,-25),(0,-40),(18,-27),(30,-7)]:
        b+=path(f'M0 31 Q{x*.3} 5 {x} {y}','none','#3b7050',3)
        for t in [.35,.6,.85]:
            xx=x*t; yy=31+(y-31)*t
            b+=leaf(xx,yy,-25,12,col)+leaf(xx,yy,195,12,col)
    b+=ell(0,23,9,10,col,INK)+face(0,20,spacing=3)
    if kind=='anchor_fern': b+=line('M-25 14 Q-26 24 -13 24 M-22 11 l-3 3 -2 -4','#547d7d',2.4)
    if kind in ['glowvine','glow_ivy']:
        for x,y in [(-22,-6),(14,-19),(0,-39)]: b+=ell(x,y,3.5,5,'url(#gold)' if kind=='glowvine' else 'url(#mint)',INK,1)+ell(x-1,y-1,1,2,'#f7f1c7')
    if kind=='signal_ivy': b+=line('M21 -35 Q31 -31 31 -22 M22 -40 Q37 -34 37 -20','#86c8a7',1.8)
    if kind=='echo_fern': b+=line('M-30 -34 Q-37 -28 -33 -19 M-35 -40 Q-45 -29 -40 -15','#82b8a3',1.5)
    return b

def bamboo(kind,col='url(#leaf)'):
    b=base(False)
    for x,y,h in [(-15,29,54),(0,32,76),(15,29,61)]:
        b+=path(f'M{x-5} {y} V{y-h+5} Q{x} {y-h-2} {x+5} {y-h+5} V{y}Z',col)
        for yy in range(int(y-h+17),y,17): b+=line(f'M{x-5} {yy} H{x+5}','#d4e3ab',2)
        b+=leaf(x,y-h+12,-25,18,col)
    if kind=='pressure_bamboo': b+=ell(19,3,10,10,'url(#cream)',INK)+line('M19 3 l4 -5 M14 8 h10','#605e45',1.5)
    if kind=='storm_reed': b+=path('M-3 -51 L-14 -34 L-6 -34 L-12 -20 L5 -39 H-3 L3 -51Z','url(#gold)')
    if kind=='spiral_bamboo': b+=path('M-24 -22 Q14 -42 24 -20 Q31 -9 -20 4 Q-32 15 21 24','none','#b3c96e',3)
    b+=face(0,8,spacing=3)
    return b

def fruit(kind,col='url(#rose)'):
    b=base(False)
    b+=path('M0 -27 C-22 -38 -35 -15 -27 8 Q-20 33 0 31 Q25 33 29 5 C36 -20 20 -37 0 -27Z',col,INK,2)
    b+=path('M-22 -6 Q-27 -24 -9 -24','none','#fff2d5',3,opacity='.6')+leaf(0,-27,-22,18)+leaf(0,-27,180,16)+face(0,-3,'stern' if kind=='blast_pomegranate' else 'smile')
    if kind in ['dragon_fruit','blast_pomegranate']:
        for x,y,a in [(-24,-14,-65),(22,-14,65),(-20,9,-90),(20,9,90)]: b+=petal(x,y,a,12,4,'url(#leaf)' if kind=='dragon_fruit' else 'url(#gold)')
        b+=path('M-8 -29 L-11 -39 L-3 -34 L1 -41 L6 -33 L11 -37 L8 -27Z','url(#gold)')
    elif kind=='rock_armor_fruit':
        b+=path('M-27 -14 L-17 -27 L-4 -24 L-7 -10 L-26 -3 M26 -14 L19 -25 L7 -24 L9 -10 L28 -4 M-24 16 L-14 12 L-8 26 L-16 30 M23 16 L13 12 L8 27 L15 30','url(#stone)')
    elif kind=='honey_blossom': pass
    return b

def cactus(kind,state=""):
    b=base(False)+path('M-10 30 V-19 Q-10 -34 1 -34 Q13 -34 13 -20 V29Z','url(#leaf)')
    b+=path('M-9 12 H-22 Q-29 11 -29 3 V-9 Q-24 -16 -20 -9 V3 H-9 M12 3 H23 V-17 Q27 -23 31 -17 V4 Q31 13 23 13 H12','url(#leaf)')
    b+=line('M-4 -25 V26 M6 -25 V28 M-25 -6 V5 M27 -12 V7','#b6d684',1)
    for x,y,a in [(-11,-17,-1),(13,-12,1),(-10,17,-1),(13,20,1),(-27,-8,-1),(30,-6,1)]: b+=line(f'M{x} {y} l{a*5} -3','#e7daa0',1.5)
    b+=face(1,-10,spacing=4)
    if kind=='thorn_cactus': b+=flower_small(0,-34,'url(#rose)')+leaf(-17,-9,45,11)+leaf(20,-16,130,11)
    if kind=='cactus_guard': b+=path('M-22 7 L-7 12 L-9 30 L-20 36 L-31 26 L-33 12Z','url(#bark)')+line('M-27 15 l3 10 9 -7','#dac797',2)
    if state: b+=line('M-25 11 l6 6 -7 5 7 7','#72523a',2)
    if state=='critical': b+=path('M-32 12 L-22 18 L-28 25 L-20 34 L-30 27Z','#72523a')
    return b

def flower_small(x,y,col):
    return group(''.join(petal(0,0,a,10,4,col) for a in range(0,360,72))+ell(0,0,3,3,'#f6d183',INK,1),f'translate({x} {y})')

def weapon(kind,col='url(#leaf)'):
    b=base()
    if 'boomerang' in kind or kind=='wind_orchid' or kind=='frost_fan':
        b+=ell(0,3,14,18,col,INK)+face(0,-1,spacing=5)
        for a in ([-40,70,180] if kind=='cluster_boomerang' else [-40]):
            b+=group(path('M-27 -9 Q-23 -25 -6 -38 L-1 -27 Q12 -39 30 -31 L28 -24 Q13 -24 0 -13 Q-14 -20 -22 -6Z','url(#ice)' if kind=='frost_boomerang' else 'url(#bark)')+line('M-20 -13 Q-15 -24 -7 -30 M5 -21 Q16 -28 25 -27','#f3daa5',1.3),f'rotate({a} 0 -13) scale(.85)')
    elif kind in ['pepper_mortar','chimney_pepper','corn_cannon','gator_cannon','chambord_sniper']:
        b+=path('M-20 14 Q-24 -7 -7 -12 L17 -16 L21 -25 L38 -19 L32 9 Q24 19 5 18Z',col,INK,2)+ell(31,-9,8,13,'#425543',INK)+ell(32,-9,4,8,'#253c35')+eye(-10,0,2.8,4)
        b+=line('M-17 6 Q-3 11 13 7','#b5d685',1.3)
        if kind=='gator_cannon': b+=path('M17 12 L21 18 L24 10 L28 16 L31 7','#f5e7c4')
        if kind=='chambord_sniper': b+=path('M6 -17 V-29 H29 V-20Z','#536a61')+ell(29,-25,3,5,'#bed5c8',INK)
        if kind=='chimney_pepper': b+=path('M-18 -10 L-21 -31 H-5 L-4 -9Z','url(#bark)')+line('M-24 -31 H-3 M-18 -24 H-6 M-18 -36 q-7 -7 1 -13','#9caaa3',2)
        if kind=='corn_cannon': b+=path('M-19 -10 Q-31 -35 -16 -36 Q0 -28 6 -8Z','url(#gold)')+line('M-21 -28 l12 6 M-23 -21 l16 6','#ac7b39',1)
    elif kind in ['lotus_lancer','heather_shooter']:
        b+=ell(0,2,15,17,col,INK)+face(0,-2,spacing=5)+path('M12 4 L28 -32 L34 -43 L36 -28 L18 8Z','url(#mint)')+leaf(-10,-9,50,25,col)
    else:
        b+=pea('repeater',col).replace(base(),'')
        if kind=='sakura_shooter': b+=flower_small(-18,-31,'url(#rose)')
    if kind=='heather_shooter': b+=flower_small(-15,-25,'url(#violet)')+flower_small(-22,-16,'url(#rose)')
    if kind=='frost_fan':
        b=base()+path('M-32 -19 Q0 -57 32 -19 L0 11Z','url(#ice)')+line('M-28 -19 L0 11 L-15 -32 M0 11 L0 -39 M0 11 L15 -32 M0 11 L28 -19','#eafaff',1.2)+face(0,-12,spacing=5)
    return b

def pult(kind,col='url(#leaf)'):
    b=base(False)+path('M-26 29 Q-31 12 -16 4 L9 2 Q27 7 25 28 Q5 37 -26 29Z',col)+face(-4,16,spacing=5)
    b+=path('M-13 11 Q-2 -3 14 -17 L8 -29 Q17 -41 32 -31 L32 -25 Q24 -12 17 -16 L-6 16Z','url(#bark)')+line('M-10 11 L14 -13','#e7ca8c',1.8)
    if kind=='kernel_pult' or kind=='corn_cannon':
        b+=path('M12 -30 Q9 -49 20 -49 Q30 -45 31 -27Z','url(#gold)')
        for yy in [-42,-36,-30]: b+=line(f'M15 {yy} l12 3','#b78439',1)
        b+=line('M21 -46 L23 -28','#b78439',1)
    elif kind in ['melon_pult','skylight_melon','fumarole_melon']:
        b+=ell(19,-35,15,12,col,INK)+line('M11 -45 Q2 -34 12 -25 M20 -46 Q12 -35 21 -24 M27 -43 Q21 -32 28 -27','#407650',2)
    elif kind=='cabbage_pult':
        b+=ell(19,-35,14,13,col,INK)+path('M7 -34 Q10 -42 19 -39 Q23 -48 29 -38 M9 -27 Q19 -23 20 -34 Q29 -39 31 -30','none','#bad39b',1.7)
    else:
        b+=ell(19,-36,14,13,col,INK)+ell(14,-41,4,2.5,'#ecf3d3')
        if kind=='dragon_bubble_pult': b+=petal(14,-43,-35,12,5,'url(#rose)')+petal(26,-44,35,13,5,'url(#rose)')
    return b

def special(kind,state=''):
    b=base()
    if kind=='starfruit':
        b=base()+path('M0 -40 Q4 -42 7 -25 L10 -20 L28 -20 Q35 -20 27 -12 L15 -1 L19 18 Q20 24 13 20 L0 10 L-14 20 Q-21 24 -18 15 L-14 -1 L-29 -14 Q-34 -21 -24 -21 L-9 -22Z','url(#gold)',INK,2)+face(0,-9,spacing=5)+line('M0 -32 L-4 -22 M-24 -16 L-13 -13','#fff1bd',2)
    elif kind=='pumpkin':
        b=ell(0,31,34,4,'#8e7141').replace('/>',' opacity=".2"/>')+path('M-4 -15 L-2 -28 Q7 -31 9 -26 L3 -15Z','url(#leaf)')
        for x,y,rx in [(-19,8,17),(19,8,17),(-8,6,19),(8,6,19),(0,6,17)]: b+=ell(x,y,rx,23,'url(#fire)',INK,1.3)
        b+=path('M-20 -1 L-5 5 L-20 9Z M20 -1 L5 5 L20 9Z M-19 16 L-9 20 L-6 15 L0 21 L5 16 L9 20 L20 16 Q5 34 -12 26Z','#59432e',INK,1)
        if state: b+=line('M-9 -14 l4 9 -7 7 5 11','#72523a',2)
        if state=='critical': b+=path('M31 2 L24 5 L28 14 L20 21 L28 26 L34 16Z','#80603b')
    elif kind=='pumice_wall':
        b=nut('wallnut',state).replace('url(#bark)','url(#stone)').replace('#eac78a','#c7c8b1')
        for x,y,r in [(-18,-12,3),(13,-23,3.5),(18,17,3),(-15,22,4),(5,28,2)]: b+=ell(x,y,r,r*.7,'#727d6f')+line(f'M{x-r/2} {y+1} h{r}','#c9cdb9',.8)
    elif kind=='snow_bloom':
        b=base()+''.join(petal(0,-12,a,30,7,'url(#ice)') for a in range(0,360,60))+ell(0,-12,10,11,'url(#cream)',INK)+face(0,-15,spacing=3)
    elif kind=='magma_stream':
        b=base(False)+path('M-26 25 Q-25 7 -10 10 L-12 -18 L12 -18 L9 10 Q24 5 28 26 Q0 35 -26 25Z','url(#stone)')+path('M-8 9 Q-20 -7 -6 -18 Q-12 -31 3 -44 Q1 -27 14 -19 Q28 -3 12 9Z','url(#fire)')+path('M-1 6 Q-10 -5 2 -20 Q12 -5 6 6Z','url(#gold)')+face(0,19,spacing=5)
    elif kind=='cyclone_grass':
        b=base(False)+path('M-9 31 Q-35 1 -9 -12 Q20 -30 32 -11 Q-1 -26 -6 -2 Q-8 13 9 17 Q-1 4 13 -2 Q34 -11 38 6 Q21 -1 16 13 Q10 35 -9 31Z','url(#leaf)')+line('M-27 -20 Q-40 -4 -29 14 M16 -34 Q34 -32 38 -22','#92b3a2',2)+face(0,22,spacing=4)
    elif kind=='origami_blossom':
        for a in [-90,0,90,180]:
            b+=group(path('M0 -9 L-9 -33 L3 -45 L18 -28 L11 -12Z','url(#cream)')+path('M0 -9 L3 -45 L8 -23Z','#d5afcf')+line('M8 -23 L18 -28','#7a7685',1),f'rotate({a} 0 -9)')
        b+=path('M-8 -16 L7 -17 L10 -3 L-4 2 L-11 -6Z','#db94a4')+face(0,-11,spacing=3)
    elif kind=='cotton_candy':
        for x,y,r in [(-17,-7,15),(14,-10,18),(-3,-22,18),(0,-4,20)]: b+=ell(x,y,r,r*.95,'url(#rose)',INK)
        b+=path('M-27 -8 Q-28 -18 -19 -18 M-15 -24 Q-12 -35 -2 -33','none','#fff1ec',2)+face(0,-9)
    elif kind=='cherry_bomb':
        b=base(False)+path('M-12 -2 Q-17 -29 7 -34 Q19 -16 14 2','none','#42734b',4)+leaf(6,-31,12,22)
        for x,y in [(-13,12),(15,14)]: b+=ell(x,y,17,20,'url(#rose)',INK,1.8)+ell(x-6,y-8,4,6,'#ffdbc9')+face(x,y-1,'stern',4)
        b+=path('M5 -34 Q15 -46 26 -38','none','#a98451',2)+star(27,-38,5,'#f7cd77')
    elif kind=='potato_mine':
        b=ell(0,32,29,5,'#947958',INK)
        if state=='unarmed': return b+path('M-12 31 Q-6 21 2 25 Q13 21 17 31Z','url(#bark)')+ell(1,24,4,3,'#aa6e58',INK)
        b+=path('M-26 26 Q-33 11 -20 3 Q-15 -9 1 -4 Q16 -9 23 5 Q32 13 27 28 Q0 40 -26 26Z','url(#bark)')+face(0,12,spacing=7)
        b+=path('M-2 -4 V-16 H3 V-4Z','#908979')+ell(0,-18,7,6,'url(#rose)',INK)+ell(-2,-20,2,1.5,'#fff4d3')
        for x,y in [(-20,14),(17,4),(18,24),(-10,30)]: b+=ell(x,y,1.5,1,'#a37446')
    elif kind in ['chomper','grave_buster']:
        col='url(#plum)' if kind=='chomper' else 'url(#leaf)'
        b+=path('M-20 -7 Q-34 -32 -9 -39 Q14 -47 29 -24 L8 -15 L31 -2 Q27 17 1 18 Q-18 18 -20 -7Z',col,INK,2)
        if state=='chewing': b+=line('M-20 -3 Q8 8 29 -4','#463d52',2.8)+ell(20,0,3,4,'#dcccbb')
        else: b+=path('M27 -24 L9 -15 L31 -2 L6 -1 L-7 -12 L10 -28Z','#3c3040')+path('M11 -27 L9 -18 L3 -23 M22 -24 L18 -16 L13 -19 M26 -3 L21 -10 L19 -2 M10 -1 L7 -9 L3 -4Z','#fff0d7',INK,1)
        b+=eye(-13,-24,2.7,5)+leaf(-21,-20,40,18,col)+leaf(-19,-30,75,17,col)
    elif kind in ['vine_lasher','abyss_tentacle','tangle_kelp','root_snare']:
        col='url(#plum)' if kind=='abyss_tentacle' else 'url(#leaf)'
        b=base(False)
        for sign in [-1,1]:
            b+=path(f'M{sign*5} 28 C{sign*40} 15 {sign*13} -11 {sign*31} -27 Q{sign*38} -39 {sign*22} -35 Q{sign*31} -33 {sign*22} -25 C{sign*2} -6 {sign*22} 11 {sign*5} 28Z',col)
        b+=path('M-12 27 Q-17 6 -7 -18 Q-3 -37 10 -38 Q2 -27 7 -15 Q20 13 12 29Z',col)+face(0,9,spacing=5)
        if kind=='vine_lasher': b+=crystal(14,-15,20,angle=55)
        elif kind=='abyss_tentacle': b+=eye(0,-3,4,5)+ell(-25,-15,2,3,'#c8a0d3')+ell(23,-17,2,3,'#c8a0d3')
        elif kind=='root_snare': b+=line('M-25 29 Q-35 17 -25 13 M25 29 Q36 17 24 12','#987448',3)
    elif kind=='shadow_assassin':
        b+=path('M-24 22 L-19 -17 Q-13 -37 0 -43 Q15 -33 20 -17 L26 25 L11 20 L0 27 L-11 21Z','url(#night)')
        b+=path('M-15 -10 Q0 -24 15 -10 L10 3 H-10Z','#cbbfae')+face(0,-7,'stern',5)
        for x,sgn in [(-21,-1),(21,1)]: b+=path(f'M{x} 8 L{x+sgn*10} -10 L{x+sgn*12} 1 L{x+sgn*2} 15Z','url(#ice)')
    elif kind in ['lantern_bloom','plantern']:
        b+=path('M-17 12 L-19 -19 L-11 -31 H12 L20 -19 L16 13 L0 21Z','url(#gold)',INK,2)
        b+=path('M-18 -19 H19 M-16 12 H16 M-9 -23 L-6 11 M9 -23 L6 11','none','#58774e',2.5)+face(0,-9,spacing=4)
        b+=path('M-22 -20 Q0 -41 22 -20Z','url(#leaf)')+leaf(0,-34,140,16)
        if kind=='lantern_bloom': b+=petal(-17,-8,-65,19,7,'url(#gold)')+petal(17,-8,65,19,7,'url(#gold)')
    elif kind=='pulse_bulb':
        b+=path('M-14 13 Q-29 -4 -22 -21 Q-15 -38 2 -35 Q25 -34 26 -14 Q27 3 12 14 L8 21 H-9Z','url(#gold)')+face(0,-13)
        b+=path('M-9 15 H10 V22 H-9Z','#7f9980')+line('M-15 -21 Q-17 -11 -12 -7','#fff3ce',2)+line('M-25 -34 l-4 -5 M25 -35 l4 -6 M0 -42 v-6','#d7ac54',2)
    elif kind in ['prism_grass','obsidian_artichoke']:
        b=base(False)
        for x,y,h,a in [(-17,23,39,-20),(17,23,39,20),(-8,18,48,-9),(8,18,48,9),(0,18,57,0)]: b+=crystal(x,y,h,'url(#night)' if kind=='obsidian_artichoke' else 'url(#mint)',a)
        b+=face(0,12,spacing=5)
    elif kind in ['sun_bean','coffee_bean','garlic','healing_gourd','meteor_gourd','mango_bowling','resonance_beet','sulfur_pod']:
        col={'sun_bean':'url(#gold)','coffee_bean':'url(#bark)','garlic':'url(#cream)','healing_gourd':'url(#mint)','meteor_gourd':'url(#fire)','mango_bowling':'url(#gold)','resonance_beet':'url(#rose)','sulfur_pod':'url(#gold)'}[kind]
        if 'gourd' in kind:
            b+=path('M-10 -18 Q-18 -34 -2 -37 Q15 -39 13 -23 Q10 -15 17 -9 Q31 9 19 26 Q0 38 -20 24 Q-30 8 -17 -8Z',col)
        elif kind=='garlic': b+=path('M-24 19 Q-29 3 -9 -14 L-4 -34 H3 L6 -15 Q30 1 25 20 Q19 35 1 32 Q-17 35 -24 19Z',col)+line('M-4 -13 Q-16 9 -10 28 M4 -12 Q17 9 11 29','#b7b796',1)
        else: b+=path('M-19 17 Q-32 -12 -13 -28 Q8 -44 22 -20 Q34 2 17 24 Q-5 41 -19 17Z',col)
        b+=face(0,3,spacing=5)
        if kind=='coffee_bean': b+=line('M-6 -25 Q8 -14 -1 -6 M-2 17 Q-9 26 0 30','#815233',2)
        if kind=='healing_gourd': b+=path('M-5 -26 H1 V-20 H7 V-14 H1 V-8 H-5 V-14 H-11 V-20 H-5Z','#f4eac4','none')
        if kind=='resonance_beet': b+=line('M-31 -7 Q-37 2 -31 11 M32 -7 Q38 2 32 11','#a687ac',2)
        if kind=='sulfur_pod':
            for x,y in [(-11,-18),(2,-23),(13,-15)]: b+=ell(x,y,3,2,'#a4974f')
            b+=path('M21 -25 Q33 -31 24 -39 M-20 -29 Q-29 -34 -22 -40','none','#b5c08a',2)
        if kind=='sun_bean': b+=flower_small(-11,-26,'url(#gold)')
    elif kind in ['lily_pad','flower_pot','brine_pot','cork_plug']:
        b=base(False)
        if kind=='lily_pad': b+=path('M-30 18 C-39 -8 34 -9 33 16 Q29 39 -30 18Z','url(#leaf)')+path('M-2 11 L-14 27 L11 27Z','#4d7e4e','none')+line('M-23 9 Q-10 0 13 5','#bad498',1.5)
        else:
            b+=path('M-22 -4 L-17 29 Q0 38 17 29 L23 -4Z','url(#bark)')+ell(0,-4,25,8,'url(#bark)',INK)+ell(0,-5,19,4,'#70583e')+face(0,12,spacing=5)
            if kind=='brine_pot': b+=path('M-9 -7 Q-17 -29 -8 -36 Q-14 -18 -3 -9 M7 -7 Q20 -17 11 -32 Q26 -27 17 -7Z','url(#mint)')
            if kind=='cork_plug': b+=path('M-15 -25 L-12 -5 Q0 1 12 -5 L15 -25Z','#b6a480')+ell(0,-25,15,5,'#dbcb9d',INK)
    elif kind in ['blover','umbrella_leaf','steam_clover','cyclone_grass','roof_vane']:
        for a in [0,90,180,270]: b+=group(leaf(0,-9,-25,31)+leaf(0,-9,25,31),f'rotate({a} 0 -9)')
        b+=ell(0,-9,10,11,'url(#leaf)',INK)+face(0,-12,spacing=3)
        if kind=='steam_clover': b+=line('M-26 -29 q-7 -7 0 -14 M26 -28 q7 -7 0 -13','#b1c3ba',2)
        if kind=='roof_vane': b+=path('M-3 -16 V-45 L27 -37 L-3 -31','url(#bark)')
        if kind=='umbrella_leaf': b+=path('M-37 -10 Q0 -52 37 -10 L22 -16 L10 -9 L0 -15 L-12 -9 L-24 -16Z','url(#leaf)')
    elif kind in ['spikeweed','leyline']:
        b=base(False)
        for i in range(7):
            x=-27+i*9; h=13+(i%3)*7
            b+=path(f'M{x-5} 26 Q{x-9} {26-h} {x+3} {23-h} L{x+4} 29Z','url(#leaf)')
        b+=face(0,25,spacing=4)
        if kind=='leyline': b+=line('M-25 34 L-12 27 L2 34 L15 27 L26 32','#b4a3d0',2)
    elif kind in ['squash','jalapeno']:
        col='url(#fire)' if kind=='jalapeno' else 'url(#leaf)'
        b+=path('M-23 24 Q-26 -3 -13 -23 Q0 -44 15 -24 Q27 -10 13 8 Q8 29 30 21 Q25 40 -2 33 Q-19 37 -23 24Z',col)+face(-1,-6,'stern',5)+leaf(2,-30,145,16)
    elif kind in ['dream_drum','dream_disc','moonforge','mirror_reed','ice_cream']:
        if kind=='dream_drum': b+=path('M-23 -18 L-20 19 Q0 31 20 19 L23 -18Z','url(#rose)')+ell(0,-18,24,11,'url(#cream)',INK)+line('M-20 -9 l10 27 10 -20 10 20 10 -27','#f6d89d',2)
        elif kind=='ice_cream': b+=path('M-20 -5 L0 33 L20 -5Z','url(#bark)')+line('M-13 2 L7 19 M-5 1 L13 10 M12 2 L-6 20','#8c693e',1)+ell(-10,-13,14,15,'url(#cream)',INK)+ell(10,-15,15,17,'url(#rose)',INK)
        elif kind=='mirror_reed': b+=path('M-15 -32 L9 -39 L21 -7 L-4 2Z','url(#ice)')+line('M-7 -28 L7 -15 M-11 -21 L1 -8','#efffff',2)
        elif kind=='moonforge': b+=path('M-23 12 V-7 H-35 L-19 -23 H24 L34 -12 H16 V12Z','url(#stone)')+path('M-9 14 V-3 Q1 -16 10 -3 V14Z','url(#fire)')
        else: b+=ell(0,-12,30,21,'url(#violet)',INK)+ell(0,-12,20,14,'url(#plum)',INK)+ell(0,-12,9,7,'url(#gold)',INK)+line('M-25 -8 Q-22 -27 -1 -28','#e0d1ee',1.5)
        b+=face(0,3 if kind=='dream_drum' else -10,spacing=4)
    return b

# Recipes describe the plant, never a fallback random recolour.
RECIPES={}
def recipes(names,fn,*args):
    for name in names.split(): RECIPES[name]=(fn,args)
recipes('peashooter repeater threepeater split_pea',pea)
recipes('snow_pea',pea,'url(#ice)'); recipes('amber_shooter',pea,'url(#gold)')
recipes('shadow_pea',pea,'url(#plum)'); recipes('prism_pea plasma_shooter',pea,'url(#mint)')
recipes('sunflower marigold',sunflower); recipes('thermal_sunflower',sunflower,'url(#fire)')
recipes('galaxy_sunflower',sunflower,'url(#violet)','url(#cream)')
recipes('wallnut tallnut brick_guard holo_nut glitch_walnut crystal_nut',nut)
recipes('puff_shroom sun_shroom fume_shroom hypno_shroom scaredy_shroom ice_shroom doom_shroom sea_shroom magnet_shroom nether_shroom void_shroom mirror_shroom plasma_shroom chaos_shroom',shroom)
recipes('time_rose',flower,'url(#rose)','rose')
recipes('moon_lotus bubble_lotus holy_lotus chain_lotus sand_lotus caldera_lotus',flower,'url(#rose)','lotus')
recipes('mist_orchid aurora_orchid magnet_orchid',flower,'url(#violet)','orchid')
recipes('soul_flower',flower,'url(#violet)'); recipes('laser_lily tesla_tulip',flower,'url(#rose)','lily')
recipes('magnet_daisy honey_blossom hive_flower solar_emperor',flower,'url(#gold)')
recipes('seraph_flower holy_flower',flower,'url(#cream)','lily')
recipes('ice_queen',flower,'url(#ice)','lily')
recipes('meteor_flower core_blossom orange_bloom',flower,'url(#fire)')
recipes('thunder_pine thunder_god vine_emperor mamba_tree destiny_tree phoenix_tree',tree)
recipes('frost_cypress',tree,'url(#ice)')
recipes('anchor_fern echo_fern signal_ivy glow_ivy glowvine',fern)
recipes('spiral_bamboo storm_reed pressure_bamboo',bamboo)
recipes('dragon_fruit blast_pomegranate',fruit)
recipes('rock_armor_fruit',fruit,'url(#stone)')
recipes('cactus cactus_guard thorn_cactus',cactus)
recipes('boomerang_shooter cluster_boomerang frost_boomerang wind_orchid frost_fan heather_shooter lotus_lancer',weapon)
recipes('pepper_mortar chimney_pepper',weapon,'url(#fire)')
recipes('corn_cannon gator_cannon',weapon)
recipes('chambord_sniper',weapon,'url(#plum)'); recipes('sakura_shooter',weapon,'url(#rose)')
recipes('cabbage_pult kernel_pult melon_pult',pult)
recipes('skylight_melon dragon_bubble_pult',pult,'url(#ice)'); recipes('fumarole_melon',pult,'url(#stone)'); recipes('toxic_gum_pult',pult,'url(#violet)')

recipes('origami_blossom cotton_candy cherry_bomb potato_mine chomper grave_buster vine_lasher abyss_tentacle tangle_kelp root_snare shadow_assassin lantern_bloom plantern pulse_bulb prism_grass obsidian_artichoke sun_bean coffee_bean garlic healing_gourd meteor_gourd mango_bowling resonance_beet sulfur_pod lily_pad flower_pot brine_pot cork_plug blover umbrella_leaf steam_clover cyclone_grass roof_vane spikeweed leyline squash jalapeno dream_drum dream_disc moonforge mirror_reed ice_cream',special)
# Individual palettes reinforce water, moonlight, fire and healing roles.
recipes('bubble_lotus',flower,'url(#ice)','lotus')
recipes('moon_lotus',flower,'url(#violet)','lotus')
recipes('sand_lotus',flower,'url(#bark)','lotus')
recipes('caldera_lotus',flower,'url(#fire)','lotus')
recipes('holy_lotus',flower,'url(#cream)','lotus')
recipes('chain_lotus',flower,'url(#gold)','lotus')

recipes('wind_orchid',flower,'url(#mint)','orchid')
recipes('starfruit pumpkin pumice_wall snow_bloom magma_stream cyclone_grass',special)
recipes('thunder_god',flower,'url(#gold)','lily')
DEFS='<defs>'
for name,c1,c2 in [('pea','#b7dc7a','#55904d'),('leaf','#88b758','#3d774b'),('gold','#fbe4a0','#d6953f'),('sun','#f0bd65','#bf813d'),('cream','#fff3d4','#d9be99'),('bark','#dcb474','#aa783f'),('ice','#d7f5f4','#72abc8'),('mint','#bfe8cb','#599993'),('rose','#f3b6bd','#c36282'),('violet','#d9c2e9','#997bb7'),('plum','#a995c5','#665c8a'),('night','#6e6b88','#35394e'),('fire','#fbc478','#dc7243'),('stone','#b3bbae','#747f7b')]:
    DEFS+=f'<linearGradient id="{name}" x1=".2" y1="0" x2=".8" y2="1"><stop stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>'
DEFS+='</defs>'

def write(name,body):
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="192" height="224" viewBox="-48 -60 96 112">{DEFS}{body}</svg>\n'
    (OUT/(name+'.svg')).write_text(svg)

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    for name,(fn,args) in RECIPES.items():
        write(name,fn(name,*args))
        if fn==nut or name in ['pumpkin','pumice_wall','cactus_guard']:
            for state in ['damaged','critical']: write(name+'_'+state,fn(name,state))
        if name=='potato_mine': write(name+'_unarmed',special(name,'unarmed'))
        if name=='chomper': write(name+'_chewing',special(name,'chewing'))
        if name=='sun_shroom': write(name+'_young',shroom(name,'young'))
        if name=='scaredy_shroom': write(name+'_hiding',shroom(name,'hiding'))
    manifest='extends RefCounted\n\n# Generated by scripts/tools/build_vector_unit_art.py.\nconst KINDS := '+str(list(RECIPES)).replace("'",'"')+'\n'
    (ROOT/'scripts/data/vector_plant_manifest.gd').write_text(manifest)
    print(f'Authored {len(RECIPES)} plant models and their gameplay variants.')
if __name__=='__main__': main()
