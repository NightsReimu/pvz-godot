from pathlib import Path
import hashlib

ROOT=Path(__file__).resolve().parents[2]
P=ROOT/'art/image2/projectiles'
E=ROOT/'art/image2/effects'
OUTP=ROOT/'art/vector/combat_projectiles'
OUTE=ROOT/'art/vector/combat_effects'
EXTRA=['dragon_bubble','toxic_gum','gator_orb','snow_pea','fire_pea','phoenix_flame']

def keys(folder, extra=()): return sorted({p.stem for p in folder.glob('*.png')} | set(extra))

def palette(key, family):
    h=int(hashlib.sha256(key.encode()).hexdigest()[:6],16)
    themes=[('#73e6a5','#d9fff0'),('#62b9ff','#e8f6ff'),('#ff9b5d','#fff0bc'),('#d48cff','#f8e0ff'),('#ff6e9d','#ffe1ef'),('#f5cf57','#fff7c2'),('#72d7d0','#e0fffb')]
    a,b=themes[h%len(themes)]
    if 'frost' in key or 'ice' in key or 'snow' in key: a,b='#62c9ff','#e9fbff'
    if any(x in key for x in ['fire','pepper','meteor','flame','lava']): a,b='#ff7043','#fff0a8'
    if any(x in key for x in ['toxic','thorn','shadow','dark']): a,b='#a875e8','#e6d2ff'
    if 'sakura' in key: a,b='#f08caf','#fff0f7'
    return a,b

def svg(key, family):
    a,b=palette(key,family); h=int(hashlib.sha256(key.encode()).hexdigest()[:8],16)
    mode=h%6
    sig=hashlib.sha1((family+':'+key).encode()).hexdigest()[:16]
    if family=='projectile':
        if any(x in key for x in ['boomerang','lotus','ring']):
            body=f'<path d="M18 50 Q32 {18+mode*2} 50 28 Q74 {18+mode*2} 82 50 Q74 42 50 42 Q28 42 18 50Z" fill="url(#g)" stroke="{b}" stroke-width="3"/><circle cx="50" cy="38" r="7" fill="{b}" opacity=".9"/>'
        elif any(x in key for x in ['origami','plane']):
            body=f'<path d="M10 48 L88 18 L60 82 L48 53Z" fill="url(#g)" stroke="{b}" stroke-width="3"/><path d="M48 53 L88 18 L58 54Z" fill="{b}" opacity=".7"/>'
        elif any(x in key for x in ['spear','thorn','heather']):
            body=f'<path d="M12 50 L72 23 L91 50 L72 77Z" fill="url(#g)" stroke="{b}" stroke-width="3"/><path d="M28 50 L73 50" stroke="{b}" stroke-width="4"/>'
        elif any(x in key for x in ['star','prism','shard','fragment']):
            pts=' '.join(f'{50+34*__import__("math").cos(i*3.14159/4):.1f},{50+34*__import__("math").sin(i*3.14159/4):.1f}' for i in range(8))
            body=f'<polygon points="{pts}" fill="url(#g)" stroke="{b}" stroke-width="3"/><circle cx="50" cy="50" r="10" fill="{b}"/>'
        elif any(x in key for x in ['cabbage','kernel','butter','melon','mango','bubble','gum']):
            body=f'<path d="M18 58 Q20 27 50 20 Q80 27 82 58 Q66 82 50 84 Q34 82 18 58Z" fill="url(#g)" stroke="{b}" stroke-width="3"/><path d="M30 48 Q50 32 70 48" fill="none" stroke="{b}" stroke-width="4"/>'
        else:
            body=f'<path d="M14 50 Q28 {20+mode*3} 58 24 Q82 30 86 50 Q82 70 58 76 Q28 80 14 50Z" fill="url(#g)" stroke="{b}" stroke-width="3"/><circle cx="36" cy="40" r="7" fill="{b}" opacity=".85"/><path d="M24 60 Q50 72 74 55" fill="none" stroke="{b}" stroke-width="3"/>'
    else:
        shape=mode
        if shape==0: body=f'<circle cx="50" cy="50" r="35" fill="none" stroke="{a}" stroke-width="8" opacity=".8"/><circle cx="50" cy="50" r="16" fill="{b}" opacity=".8"/>'
        elif shape==1: body=f'<path d="M10 70 L30 42 L42 60 L61 22 L90 70" fill="none" stroke="{a}" stroke-width="7"/><path d="M18 72 L82 72" stroke="{b}" stroke-width="3"/>'
        elif shape==2: body=f'<path d="M18 70 Q50 12 82 70" fill="none" stroke="{a}" stroke-width="11"/><path d="M28 70 Q50 28 72 70" fill="none" stroke="{b}" stroke-width="4"/>'
        elif shape==3: body=f'<path d="M50 10 L58 39 L88 42 L65 59 L72 88 L50 70 L28 88 L35 59 L12 42 L42 39Z" fill="url(#g)" stroke="{b}" stroke-width="3"/>'
        elif shape==4: body=f'<ellipse cx="50" cy="54" rx="35" ry="22" fill="{a}" opacity=".72"/><ellipse cx="38" cy="44" rx="18" ry="10" fill="{b}" opacity=".65"/><path d="M18 70 Q50 86 82 70" fill="none" stroke="{b}" stroke-width="4"/>'
        else: body=f'<path d="M14 72 Q30 18 50 58 Q70 18 86 72" fill="none" stroke="{a}" stroke-width="9"/><circle cx="50" cy="60" r="11" fill="{b}"/>'
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100" data-art-key="{key}" data-art-family="{family}" data-art-signature="{sig}"><defs><radialGradient id="g" cx="35%" cy="30%"><stop stop-color="{b}"/><stop offset=".45" stop-color="{a}"/><stop offset="1" stop-color="{a}" stop-opacity=".48"/></radialGradient></defs><g>{body}</g></svg>'''

for folder,out,fam,extra in [(P,OUTP,'projectile',EXTRA),(E,OUTE,'effect',[])]:
    out.mkdir(parents=True,exist_ok=True)
    for key in keys(folder,extra): (out/(key+'.svg')).write_text(svg(key,fam),encoding='utf8')
print('generated',len(keys(P,EXTRA)),'projectiles and',len(keys(E)),'effects')
