"""What each species brings to a fusion.

form    how strongly its silhouette defines a hybrid (weapons and crop bodies win)
mat     how strongly its skin reads as a material (cherry gloss, nut shell, ice...)
pattern the surface its skin lends a partner
mood    the expression it lends the face
elems   the elemental aura it lends the hybrid
"""

T = {}


def kinds(names, form, mat, pattern, mood, elems):
    for name in names.split():
        T[name] = {'form': form, 'mat': mat, 'pattern': pattern, 'mood': mood, 'elems': elems.split()}


# --- shooters
kinds('peashooter', 72, .22, 'none', 'calm', 'nature')
kinds('repeater', 90, .28, 'none', 'stern', 'nature')
kinds('threepeater', 91, .28, 'none', 'calm', 'nature')
kinds('split_pea', 90, .28, 'none', 'worried', 'nature')
kinds('snow_pea', 90, .95, 'frost', 'frosty', 'frost')
kinds('amber_shooter', 90, .9, 'gloss', 'stern', 'fire light')
kinds('shadow_pea', 90, .95, 'wisps', 'fierce', 'shadow')
kinds('plasma_shooter', 90, .82, 'circuit', 'spark', 'shock')
kinds('prism_pea', 90, .88, 'facets', 'cool', 'light')
kinds('sakura_shooter', 90, .82, 'petals', 'happy', 'bloom')
kinds('heather_shooter', 90, .6, 'petals', 'calm', 'poison')
kinds('chambord_sniper', 95, .85, 'gloss', 'cool', 'metal')
kinds('corn_cannon', 96, .62, 'kernels', 'stern', 'blast')
kinds('gator_cannon', 96, .72, 'scales', 'fierce', 'water')
kinds('pepper_mortar', 94, .9, 'flames', 'angry', 'fire')
kinds('chimney_pepper', 94, .88, 'bricks', 'angry', 'fire smoke')
kinds('boomerang_shooter cluster_boomerang', 86, .3, 'none', 'stern', 'wind')
kinds('frost_boomerang', 86, .9, 'frost', 'frosty', 'frost')
kinds('lotus_lancer', 84, .35, 'none', 'stern', 'water')
kinds('frost_fan', 80, .9, 'facets', 'frosty', 'frost wind')
# --- lobbers
kinds('cabbage_pult', 92, .45, 'veins', 'happy', 'nature')
kinds('kernel_pult', 92, .85, 'kernels', 'happy', 'butter')
kinds('melon_pult', 93, .8, 'stripes', 'stern', 'nature')
kinds('skylight_melon', 93, .9, 'facets', 'calm', 'light')
kinds('dragon_bubble_pult', 92, .85, 'bubbles', 'fierce', 'water fire')
kinds('fumarole_melon', 93, .85, 'lava', 'stern', 'fire smoke')
kinds('toxic_gum_pult', 92, .9, 'bubbles', 'manic', 'poison')
kinds('sulfur_pod', 92, .85, 'speckle', 'sleepy', 'poison')
kinds('obsidian_artichoke', 92, .95, 'facets', 'fierce', 'shadow')
# --- walls
kinds('wallnut', 80, .85, 'cracks', 'stern', 'earth')
kinds('tallnut', 82, .85, 'cracks', 'stern', 'earth')
kinds('brick_guard', 82, .9, 'bricks', 'stern', 'earth')
kinds('holo_nut', 80, .9, 'glyph', 'cool', 'light')
kinds('glitch_walnut', 80, .9, 'glyph', 'manic', 'shock')
kinds('crystal_nut', 80, .95, 'facets', 'cool', 'frost')
kinds('pumice_wall', 80, .85, 'speckle', 'stern', 'earth fire')
kinds('rock_armor_fruit', 80, .85, 'speckle', 'stern', 'earth')
kinds('pumpkin', 30, .9, 'ribs', 'fierce', 'earth')
# --- mushrooms
kinds('puff_shroom', 75, .8, 'spots', 'sleepy', 'dream')
kinds('sun_shroom', 74, .85, 'spots', 'happy', 'sun')
kinds('fume_shroom', 78, .8, 'spots', 'stern', 'poison')
kinds('sea_shroom', 75, .85, 'bubbles', 'calm', 'water')
kinds('scaredy_shroom', 75, .75, 'spots', 'worried', 'dream')
kinds('hypno_shroom', 75, 1.0, 'swirl', 'hypno', 'dream')
kinds('ice_shroom', 75, 1.0, 'frost', 'frosty', 'frost')
kinds('doom_shroom', 76, 1.0, 'lava', 'fierce', 'shadow blast')
kinds('magnet_shroom', 75, .85, 'spots', 'stern', 'metal')
kinds('nether_shroom', 75, 1.0, 'stars', 'fierce', 'shadow')
kinds('void_shroom', 75, 1.0, 'stars', 'fierce', 'shadow')
kinds('mirror_shroom', 75, .9, 'facets', 'cool', 'light')
kinds('plasma_shroom', 75, .85, 'circuit', 'spark', 'shock')
kinds('chaos_shroom', 75, .9, 'swirl', 'manic', 'dream')
# --- sun makers and blossoms
kinds('sunflower', 70, .85, 'seeds', 'happy', 'sun')
kinds('marigold', 70, .85, 'petals', 'happy', 'sun fire')
kinds('galaxy_sunflower', 70, .95, 'stars', 'happy', 'sun shadow')
kinds('thermal_sunflower', 70, .9, 'flames', 'happy', 'sun fire')
kinds('solar_emperor', 72, .95, 'rays', 'cool', 'sun')
kinds('soul_flower', 68, .85, 'wisps', 'calm', 'shadow')
kinds('honey_blossom', 68, .85, 'honey', 'happy', 'sun')
kinds('sun_bean', 60, .8, 'seeds', 'happy', 'sun')
kinds('wind_orchid', 66, .5, 'veins', 'calm', 'wind')
kinds('mist_orchid', 66, .7, 'petals', 'sleepy', 'wind dream')
kinds('aurora_orchid', 66, .85, 'waves', 'calm', 'light heal')
kinds('magnet_orchid', 66, .75, 'petals', 'stern', 'metal')
kinds('tesla_tulip', 66, .8, 'circuit', 'spark', 'shock')
kinds('laser_lily', 68, .8, 'facets', 'cool', 'light')
kinds('time_rose', 66, .85, 'petals', 'calm', 'time')
kinds('seraph_flower', 66, .7, 'petals', 'happy', 'holy')
kinds('holy_flower', 66, .7, 'petals', 'happy', 'holy')
kinds('ice_queen', 68, 1.0, 'facets', 'frosty', 'frost')
kinds('meteor_flower', 66, .9, 'lava', 'fierce', 'fire')
kinds('core_blossom', 66, .95, 'lava', 'fierce', 'fire blast')
kinds('orange_bloom', 66, .85, 'seeds', 'happy', 'sun')
kinds('hive_flower', 66, .85, 'honey', 'stern', 'nature')
kinds('magnet_daisy', 66, .6, 'petals', 'stern', 'metal')
kinds('thunder_god', 70, .85, 'circuit', 'fierce', 'shock')
kinds('cotton_candy', 60, .9, 'fluff', 'happy', 'sweet')
kinds('snow_bloom', 62, .95, 'frost', 'frosty', 'frost')
kinds('origami_blossom', 64, .8, 'facets', 'calm', 'wind')
kinds('moon_lotus', 64, .8, 'stars', 'sleepy', 'shadow')
kinds('bubble_lotus', 64, .85, 'bubbles', 'calm', 'water')
kinds('sand_lotus', 64, .75, 'speckle', 'calm', 'earth')
kinds('holy_lotus', 64, .75, 'petals', 'calm', 'holy')
kinds('caldera_lotus', 64, .9, 'lava', 'calm', 'fire')
kinds('chain_lotus', 64, .75, 'rings', 'stern', 'shock')
kinds('plantern lantern_bloom', 68, .8, 'rays', 'happy', 'light')
kinds('pulse_bulb', 68, .85, 'rays', 'spark', 'shock light')
# --- trees, bamboo, mirrors
kinds('torchwood', 70, .95, 'flames', 'fierce', 'fire')
kinds('thunder_pine', 83, .6, 'veins', 'stern', 'shock')
kinds('mamba_tree', 83, .6, 'bark', 'stern', 'poison')
kinds('phoenix_tree', 83, .95, 'flames', 'fierce', 'fire')
kinds('frost_cypress', 83, .9, 'frost', 'frosty', 'frost')
kinds('destiny_tree', 83, .85, 'stars', 'calm', 'light')
kinds('vine_emperor', 83, .5, 'veins', 'stern', 'nature')
kinds('spiral_bamboo', 78, .55, 'rings', 'stern', 'wind')
kinds('pressure_bamboo', 78, .55, 'rings', 'stern', 'metal')
kinds('storm_reed', 78, .6, 'rings', 'spark', 'shock')
kinds('mirror_reed', 70, .85, 'facets', 'cool', 'light')
kinds('prism_grass', 70, .9, 'facets', 'cool', 'light')
kinds('leyline', 55, .7, 'circuit', 'calm', 'earth')
kinds('moonforge', 75, .85, 'speckle', 'stern', 'fire metal')
# --- vines, roots and jaws
kinds('vine_lasher', 62, .4, 'veins', 'fierce', 'nature')
kinds('tangle_kelp', 55, .6, 'veins', 'fierce', 'water')
kinds('root_snare', 58, .5, 'bark', 'stern', 'earth')
kinds('abyss_tentacle', 62, .9, 'spots', 'fierce', 'water shadow')
kinds('grave_buster', 60, .5, 'veins', 'fierce', 'earth')
kinds('shadow_assassin', 64, .95, 'wisps', 'fierce', 'shadow')
kinds('signal_ivy', 60, .5, 'veins', 'calm', 'light')
kinds('glow_ivy glowvine', 60, .6, 'veins', 'happy', 'light')
kinds('spikeweed', 50, .6, 'spines', 'angry', 'earth')
kinds('anchor_fern', 60, .5, 'veins', 'calm', 'water')
kinds('echo_fern', 60, .5, 'veins', 'calm', 'wind')
kinds('chomper', 88, .85, 'spots', 'fierce', 'bite')
kinds('dragon_fruit', 86, .9, 'scales', 'fierce', 'fire')
kinds('cactus', 84, .5, 'spines', 'calm', 'nature')
kinds('cactus_guard', 84, .55, 'spines', 'stern', 'earth')
kinds('thorn_cactus', 84, .6, 'spines', 'angry', 'nature')
# --- wind, stars, beans, bombs
kinds('blover', 64, .4, 'veins', 'happy', 'wind')
kinds('roof_vane', 60, .6, 'bark', 'calm', 'wind')
kinds('steam_clover', 64, .6, 'veins', 'calm', 'wind smoke')
kinds('cyclone_grass', 58, .55, 'swirl', 'manic', 'wind')
kinds('umbrella_leaf', 64, .5, 'veins', 'calm', 'nature')
kinds('starfruit', 65, .85, 'stars', 'happy', 'light')
kinds('coffee_bean', 58, .85, 'cracks', 'manic', 'tea')
kinds('garlic', 58, .75, 'ribs', 'stern', 'earth')
kinds('cork_plug', 55, .75, 'speckle', 'calm', 'earth')
kinds('ice_cream', 56, .9, 'drip', 'happy', 'frost sweet')
kinds('potato_mine', 62, .8, 'speckle', 'calm', 'blast')
kinds('squash', 66, .55, 'ribs', 'angry', 'earth')
kinds('meteor_gourd', 64, .9, 'lava', 'fierce', 'fire')
kinds('healing_gourd', 64, .8, 'gloss', 'happy', 'heal')
kinds('mango_bowling', 60, .85, 'gloss', 'happy', 'sun')
kinds('resonance_beet', 62, .85, 'rings', 'calm', 'shock')
kinds('brine_pot', 60, .7, 'bubbles', 'calm', 'water')
kinds('jalapeno', 58, 1.0, 'flames', 'angry', 'fire')
kinds('magma_stream', 58, 1.0, 'lava', 'angry', 'fire')
kinds('cherry_bomb', 55, 1.0, 'gloss', 'angry', 'blast fire')
kinds('blast_pomegranate', 60, .95, 'seeds', 'angry', 'blast')
kinds('dream_drum', 61, .8, 'zigzag', 'happy', 'dream')
kinds('dream_disc', 61, .85, 'swirl', 'sleepy', 'dream')
# --- ancient world
kinds('jasmine_tea', 79, .9, 'porcelain', 'calm', 'tea')
kinds('golden_milk', 40, .9, 'drip', 'happy', 'milk')
kinds('electric_bonk_choy', 82, .6, 'veins', 'fierce', 'shock')
kinds('dandelion', 67, .85, 'fluff', 'calm', 'wind')
kinds('samsara_eye', 62, .9, 'swirl', 'calm', 'dream light')

# A species' material as a partner sees it: light and deep tone of its skin.
# Most come from the species' main gradient; these read better as their icon colour.
MATERIAL = {
    'cherry_bomb': ('#ff9f9f', '#c8303f'), 'jalapeno': ('#ffa36c', '#d8432c'), 'blast_pomegranate': ('#ff9fa6', '#b8304a'),
    'melon_pult': ('#a6d77a', '#3f7d3c'), 'coffee_bean': ('#c99566', '#6e4227'), 'squash': ('#a9d27a', '#4c8a45'),
    'chomper': ('#b39bd6', '#5d4b86'), 'hypno_shroom': ('#e48bea', '#7b3b9b'), 'doom_shroom': ('#77729a', '#2c2f45'),
    'magma_stream': ('#ffb36a', '#c2432a'), 'meteor_gourd': ('#ffb072', '#cf5a33'), 'torchwood': ('#e2b06c', '#9a6332'),
    'phoenix_tree': ('#ffc27a', '#d9512f'), 'pumpkin': ('#ffbf6a', '#d2692c'), 'kernel_pult': ('#ffe58a', '#d9a03a'),
    'ice_shroom': ('#dff8ff', '#6fb2d8'), 'snow_pea': ('#d9f6ff', '#6eaed0'), 'shadow_pea': ('#9d8ccf', '#4a3f78'),
    'golden_milk': ('#fffdf5', '#e6dcc2'), 'dandelion': ('#ffffff', '#cfdce2'), 'electric_bonk_choy': ('#e9f7d0', '#8fc46a'),
    'dragon_fruit': ('#ff98bf', '#c3407a'), 'toxic_gum_pult': ('#cfa6ef', '#7a4fb0'), 'fumarole_melon': ('#b7c0b2', '#5f6a66'),
    'gator_cannon': ('#a8dcc0', '#3f8a6d'), 'nether_shroom': ('#6f6a90', '#30324a'), 'void_shroom': ('#6a6e95', '#2b2f48'),
}
