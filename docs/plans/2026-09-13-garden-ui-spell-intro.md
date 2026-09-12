# Garden UI and Spell Introduction Implementation Plan

**Goal:** Improve the home and menu presentation, especially world selection, and add a visible themed declaration effect to every Touhou spell card.

**Architecture:** Keep existing game state, character assets, save data and battle balance. Add a new world-scene atlas without overwriting old artwork. Centralize rounded surfaces/buttons in GameTheme, add a GardenMenu renderer for home/world scenes and themed scene previews, and derive spell-declaration visuals from the existing cast lifecycle so pause and owner cleanup remain automatic.

**Tech Stack:** Godot 4.6, GDScript, CanvasItem/StyleBoxFlat, existing character textures, native SubViewport captures.

## Design

- Warm paper, garden green, restrained gold, rounded surfaces and readable type. Preserve character artwork. Other menus retain appropriate night/magic/greenhouse palettes while sharing panel/button treatment.
- World selection: all seven worlds visible in a left navigation column; one large landscape preview, short world summary, real progress and representative plants; a clear enter action and compact home/update controls. Clicking a world previews it; enter opens its map. Arrows and swipe remain available.
- Home: one large adventure card, aligned daily/endless entries and four supporting feature cards; a modest inactive event entry; clear resource/title areas.
- Spell declaration: short expanding character-coloured magic circle, themed glyphs/particles and a readable sliding spell banner. No nonspell cut-in, whiteout, pause, extra damage, new invulnerability or input interception. End automatically and clear with the cast owner.

## Implementation and checks

1. Capture existing desktop/mobile menus with `scripts/tools/capture_ui_layout.gd`; preserve baseline images under ignored output.
2. Add `tests/menu_refresh_test.gd` for all-world visibility, hit-target separation, preview/enter routing and menu safe areas. Update obsolete image-frame-specific assertions while preserving touch, scroll, navigation and font-fitting coverage.
3. Implement `scripts/ui/garden_menus.gd`, wire home/world drawing and layout in `scripts/game.gd`, update `scripts/ui/game_theme.gd`, and replace ornate panel backgrounds in base/gacha with consistent surfaces while preserving their content and assets.
4. Add `scripts/runtime/spell_declaration_fx.gd` and `tests/spell_declaration_fx_test.gd`; call the renderer from TouhouDanmakuRuntime, using cast age/owner lifecycle. Check visibility, duration, nonspell suppression, pause and owner cleanup, and unchanged collision/timing.
5. Run targeted headless Godot regressions for menu, touch, world navigation, font/layout, base/gacha/almanac, spell/encounter/battle pause and the two recent boss battle flows.
6. Capture all menu pages at desktop and phone sizes, plus spell effects at startup/midpoint/fade. Inspect actual images and fix clipping, contrast or disconnected hit targets.
7. Export and test packed resources; update documentation/version and publish the next four-platform release under the existing project authorization after checks pass.
