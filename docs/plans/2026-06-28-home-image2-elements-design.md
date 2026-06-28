# Home Image2 Element Redesign

## Goal

Rebuild the home screen so it feels closer to the provided garden-style reference image while keeping the menu interactive, testable, and maintainable. The screen should be assembled from separate Image2-generated UI elements rather than one baked full-screen image.

## Direction

Use Image2 for reusable visual pieces:

- A top logo/title plate.
- A large mainline wooden board frame.
- A reusable smaller card frame for daily, entertainment, base, enhance, gacha, and almanac entries.
- A bottom locked activity board.
- Lightweight decoration assets such as vines, flowers, corner foliage, a lock badge, and a compact resource-bar badge.

Godot will still draw all text, progress numbers, hover glow, click targets, and state-dependent overlays. This avoids unstable AI-rendered Chinese text, keeps localization/editing simple, and preserves the existing `_home_action_rects()` interaction contract.

## Layout

The home screen keeps the same functional regions:

- Center top: logo/title art with the subtitle drawn below or on a small banner.
- Upper right: resource bar with coin count, base drone count, update status, and a settings-style icon area if needed.
- Left: large mainline board with world chips and progress bar.
- Middle: stacked daily and entertainment cards.
- Right: stacked base, enhance, gacha, and almanac cards.
- Bottom left/center: disabled activity card with lock badge.

The visual change is that these regions become layered art panels: painterly wood, soft edge highlights, plant ornaments, and richer shadows, matching the reference without flattening the whole interface into a single image.

## Asset Strategy

Create project-bound PNG/WebP assets under `art/home_ui/`.

Recommended initial assets:

- `home_logo.png`
- `home_board_main.png`
- `home_card_blue.png`
- `home_card_red.png`
- `home_card_teal.png`
- `home_card_gold.png`
- `home_card_purple.png`
- `home_card_green.png`
- `home_card_locked.png`
- `home_resource_bar.png`
- `home_lock_badge.png`
- `home_corner_foliage.png`

If true transparency is unavailable in the image tool, generate assets on a flat chroma-key background and remove the key locally before committing. Do not reference assets from a temporary generated-image directory.

## Code Architecture

Modify `scripts/game.gd` in the home-screen section only:

- Add constants for home UI image paths.
- Add a small texture loader/cache helper for home UI assets.
- Add `_draw_home_panel_asset()` or equivalent to draw a texture into a `Rect2`, falling back to the current code-drawn panel if the asset is missing.
- Keep `_home_action_rects()` as the single source of truth for clickable regions.
- Keep `_draw_home_entry()` responsible for drawing text, hover, disabled overlay, and icon placement.
- Replace panel shell backgrounds in `_draw_home_entry()` with Image2 frames where available.
- Replace the hand-drawn title treatment with the generated title asset where available, while keeping a text fallback.

## Testing

Use TDD before production code changes.

Add or extend `tests/world_navigation_test.gd` to verify:

- Home asset path definitions exist and are non-empty.
- Each home entry still has a non-overlapping hit rectangle inside `BASE_VIEWPORT_SIZE`.
- Text-safe areas inside each home card leave enough space for the current Chinese labels.
- Resource status text still fits the resource bar.

Run focused tests after each step:

- `godot --headless --path . -s res://tests/world_navigation_test.gd`
- `godot --headless --path . -s res://tests/mobile_ui_scale_test.gd`
- `godot --headless --path . -s res://tests/web_font_test.gd`

For visual verification, export or run the Web build and capture screenshots at desktop landscape and mobile landscape sizes. The top-level acceptance check is that the screen resembles the reference image through separately composited UI elements, while all text remains crisp and editable.

## Non-Goals

- Do not generate one full-screen background containing the entire UI.
- Do not bake Chinese button text into generated assets.
- Do not redesign underlying game navigation.
- Do not touch unrelated art changes already present in the user workspace.
