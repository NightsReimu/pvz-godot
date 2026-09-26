# Combat detail polish — v1.0.123

The requested release polishes the existing vector art, battle UI and effects. Preserve combat rules, balance, save data and the recent Touhou content.

## Design

- Give puff, sun and fume mushrooms shaped caps, shaded undersides and readable faces. Give torchwood roots, carved bark and layered animated flames.
- Add jacket details and readable cone, bucket and newspaper wear to ordinary zombies. Show intact, damaged and destroyed equipment through the existing shield state.
- Share a compact card layout between selection and battle: measured name, larger portrait, separate cost and enhancement indicators. Keep cooldown feedback within the portrait so labels remain legible.
- Scale health bars with unit size, distinguish shield blue from health green, and reduce excessive bloom from routine impacts. Ice shards, fire sparks and shield sparks should be recognizable without continuous camera shake.

## Implementation and verification

1. Add failing regression checks for small card regions, elemental impact classification and routine fire-hit shake. Extend rendered armor-state checks.
2. Implement bounded shared vector drawing helpers, integrate them through the existing plant/zombie renderers, and update card layout and bars.
3. Capture unit galleries and desktop/mobile battles; inspect cooldowns, upgraded cards, damaged armor and elemental effects. Run relevant UI, combat, plant, boss and startup regressions with fresh logs.
4. Update release metadata and notes; publish v1.0.123 from the tested commit. Verify all four platform assets and the Pages deployment.

Baseline captures: `output/unit-identity/v123-before/`. Captures use preview scenes that do not load or save player progress.

## Results

- Implemented shared vector details, compact card regions, scaled health/sleep indicators, and element-specific local impacts. Pixel regression caught the legacy impact texture overriding new shapes; the vector branch now takes priority.
- All 14 selected headless regression scripts passed; displayed pixel tests passed 12 silhouette pairs, 10 state comparisons, 3 elemental comparisons and 3 action poses. Release workflow assertions passed.
- Exported a Windows-preset validation pack without errors/warnings. Packed startup, combat feedback, all-unit image routing and plant effect alignment passed.
- Inspected updated galleries and desktop/mobile screenshots in `output/unit-identity/v123-after/` and `output/combat-details/v123/`.
- Corrected two pre-existing test issues: an obsolete 18-boss assertion (now verify every calibrated character), and three temporary test games that were not freed.
