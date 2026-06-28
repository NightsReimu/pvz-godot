# Home Image2 Elements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the Godot home screen from separate Image2-generated UI elements so it resembles the supplied garden-style reference while preserving editable text and existing navigation.

**Architecture:** Generated raster assets live under `art/home_ui/` and are composited by `scripts/game.gd`. Existing click rectangles from `_home_action_rects()` remain the interaction source of truth, while generated frames replace the current hand-drawn panel shells with code fallbacks if assets are missing.

**Tech Stack:** Godot 4.6 GDScript, Image2-generated PNG/WebP assets, existing headless Godot tests, Web export screenshot verification.

---

### Task 1: Establish Asset Manifest Tests

**Files:**
- Modify: `tests/world_navigation_test.gd`
- Later modify: `scripts/game.gd`

**Step 1: Write the failing test**

Add a new test call in `_run()` after `_test_home_terminal_mode_entries_are_inside_viewport()`:

```gdscript
failed = not _test_home_image2_asset_manifest_is_declared() or failed
```

Add this test:

```gdscript
func _test_home_image2_asset_manifest_is_declared() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_home_ui_asset_paths"), "home screen should expose Image2 UI asset paths")
	if passed:
		var paths: Dictionary = game.call("_home_ui_asset_paths")
		for key_variant in ["logo", "main_board", "card_daily", "card_entertainment", "card_base", "card_enhance", "card_gacha", "card_almanac", "card_locked", "resource_bar", "lock_badge"]:
			var key := String(key_variant)
			passed = _assert_true(paths.has(key), "home Image2 manifest should include %s" % key) and passed
			if paths.has(key):
				var path := String(paths[key])
				passed = _assert_true(path.begins_with("res://art/home_ui/"), "%s should live under art/home_ui" % key) and passed
				passed = _assert_true(path.ends_with(".png") or path.ends_with(".webp"), "%s should be a PNG or WebP asset" % key) and passed
	_free_game(game)
	return passed
```

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/world_navigation_test.gd
```

Expected: FAIL because `_home_ui_asset_paths` does not exist.

**Step 3: Write minimal implementation**

In `scripts/game.gd`, near the home constants/helpers, add:

```gdscript
const HOME_UI_ASSETS := {
	"logo": "res://art/home_ui/home_logo.png",
	"main_board": "res://art/home_ui/home_board_main.png",
	"card_daily": "res://art/home_ui/home_card_blue.png",
	"card_entertainment": "res://art/home_ui/home_card_red.png",
	"card_base": "res://art/home_ui/home_card_teal.png",
	"card_enhance": "res://art/home_ui/home_card_gold.png",
	"card_gacha": "res://art/home_ui/home_card_purple.png",
	"card_almanac": "res://art/home_ui/home_card_green.png",
	"card_locked": "res://art/home_ui/home_card_locked.png",
	"resource_bar": "res://art/home_ui/home_resource_bar.png",
	"lock_badge": "res://art/home_ui/home_lock_badge.png",
}
```

Add:

```gdscript
func _home_ui_asset_paths() -> Dictionary:
	return HOME_UI_ASSETS.duplicate()
```

**Step 4: Run test to verify it passes**

Run:

```bash
godot --headless --path . -s res://tests/world_navigation_test.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/game.gd tests/world_navigation_test.gd
git commit -m "test: declare home image asset manifest"
```

### Task 2: Generate Image2 Asset Set

**Files:**
- Create: `art/home_ui/home_logo.png`
- Create: `art/home_ui/home_board_main.png`
- Create: `art/home_ui/home_card_blue.png`
- Create: `art/home_ui/home_card_red.png`
- Create: `art/home_ui/home_card_teal.png`
- Create: `art/home_ui/home_card_gold.png`
- Create: `art/home_ui/home_card_purple.png`
- Create: `art/home_ui/home_card_green.png`
- Create: `art/home_ui/home_card_locked.png`
- Create: `art/home_ui/home_resource_bar.png`
- Create: `art/home_ui/home_lock_badge.png`
- Optional create: `art/home_ui/home_corner_foliage.png`

**Step 1: Generate assets**

Use the image generation skill in built-in mode. Use the user's reference image as style reference. Generate each asset separately. Keep all button/card interiors free of text.

Use prompts shaped like:

```text
Use case: stylized-concept
Asset type: game UI element
Primary request: a standalone painterly wooden garden UI card frame inspired by a bright Plants-vs-Zombies-like garden menu.
Input images: reference image for style, mood, colors, and material treatment only.
Subject: rounded wooden board frame with vines, leaves, small white flowers, beveled edges, soft shadow, empty dark green inner panel for code-rendered text.
Style/medium: polished 2D mobile game UI, painterly, high quality, friendly garden fantasy.
Composition/framing: centered isolated UI element, generous padding, no perspective distortion.
Constraints: no readable text, no letters, no numbers, no watermark, no full-screen scene, element only.
```

For transparent-like assets, generate on a flat chroma-key background if the built-in tool cannot directly provide alpha, then remove the background locally.

**Step 2: Inspect generated outputs**

Use image viewing tools to inspect each file.

Expected:

- No baked Chinese text.
- No full-screen background.
- Element edges are clean.
- Inner panel has enough empty space for code text.

**Step 3: Save project-bound files**

Move/copy final chosen images into `art/home_ui/`.

**Step 4: Commit**

```bash
git add art/home_ui
git commit -m "art: add home image2 ui elements"
```

### Task 3: Add Texture Loading and Fallback Drawing

**Files:**
- Modify: `scripts/game.gd`
- Test: `tests/world_navigation_test.gd`

**Step 1: Write the failing test**

Add a test for drawable asset helper presence:

```gdscript
failed = not _test_home_image2_asset_helpers_exist() or failed
```

Add:

```gdscript
func _test_home_image2_asset_helpers_exist() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_home_ui_texture"), "home screen should load Image2 UI textures through a helper") \
		and _assert_true(game.has_method("_draw_home_asset_panel"), "home screen should draw Image2 panels through a helper")
	_free_game(game)
	return passed
```

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/world_navigation_test.gd
```

Expected: FAIL because helpers are missing.

**Step 3: Implement texture cache and fallback panel helper**

In `scripts/game.gd`, add a cache variable near other state:

```gdscript
var home_ui_texture_cache: Dictionary = {}
```

Add helper methods near home helpers:

```gdscript
func _home_ui_texture(asset_key: String) -> Texture2D:
	if home_ui_texture_cache.has(asset_key):
		return home_ui_texture_cache[asset_key]
	var path := String(HOME_UI_ASSETS.get(asset_key, ""))
	if path == "" or not ResourceLoader.exists(path):
		home_ui_texture_cache[asset_key] = null
		return null
	var texture := load(path) as Texture2D
	home_ui_texture_cache[asset_key] = texture
	return texture


func _draw_home_asset_panel(asset_key: String, rect: Rect2, fallback_fill: Color, fallback_border: Color, disabled: bool = false) -> void:
	var texture := _home_ui_texture(asset_key)
	if texture != null:
		ThemeLib.draw_soft_shadow(self, rect, Color(0.0, 0.0, 0.0, 0.22), 4, 16.0, 10.0)
		draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, 0.72 if disabled else 1.0))
	else:
		_draw_panel_shell(rect, fallback_fill, fallback_border, 0.20, 0.14)
```

**Step 4: Run test to verify it passes**

Run:

```bash
godot --headless --path . -s res://tests/world_navigation_test.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/game.gd tests/world_navigation_test.gd
git commit -m "feat: add home ui asset drawing helpers"
```

### Task 4: Replace Home Panels With Image2 Elements

**Files:**
- Modify: `scripts/game.gd`
- Test: `tests/world_navigation_test.gd`

**Step 1: Write the failing layout expectation**

Extend the existing home layout test to assert the main card leaves a large text-safe area:

```gdscript
var mainline_rect := Rect2(action_rects["mainline"])
passed = _assert_true(mainline_rect.size.x >= 520.0 and mainline_rect.size.y >= 320.0, "mainline Image2 board should be large enough for title, copy, chips, and progress") and passed
```

If the intended final layout keeps exact current sizes, instead add a helper test for text-safe rects:

```gdscript
passed = _assert_true(game.has_method("_home_entry_text_rect"), "home entries should expose text-safe rects")
```

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/world_navigation_test.gd
```

Expected: FAIL until layout/text-safe helper is updated.

**Step 3: Update layout and drawing**

Modify `_home_action_rects()` to better match the reference:

- `mainline`: larger left board, about `Rect2(86, 184, 510, 360)`.
- `daily`: middle card, about `Rect2(630, 252, 320, 142)`.
- `entertainment`: middle card, about `Rect2(630, 420, 320, 142)`.
- `events`: wide locked lower board, about `Rect2(86, 620, 720, 138)`.
- right column cards: about `Rect2(1018, 184, 430, 122)` stacked with 20 px gap.

Keep all rects inside `BASE_VIEWPORT_SIZE`.

Update `_draw_home_entry()`:

- Pick asset key by entry id:
  - `mainline -> main_board`
  - `daily -> card_daily`
  - `entertainment -> card_entertainment`
  - `events -> card_locked`
  - `base -> card_base`
  - `enhance -> card_enhance`
  - `gacha -> card_gacha`
  - `almanac -> card_almanac`
- Draw `_draw_home_asset_panel()` first.
- Keep existing hover glow, text, icons, and disabled overlay.
- Adjust title/subtitle positions to fit generated interiors.
- Draw lock badge asset for disabled `events` if available.

Update `_draw_home_scene()`:

- Draw `home_logo.png` centered near the top if available.
- Draw fallback text logo if not.
- Draw resource bar texture if available, fallback to rounded panel otherwise.

**Step 4: Run focused tests**

Run:

```bash
godot --headless --path . -s res://tests/world_navigation_test.gd
godot --headless --path . -s res://tests/mobile_ui_scale_test.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/game.gd tests/world_navigation_test.gd
git commit -m "feat: compose home screen from image elements"
```

### Task 5: Visual Verification and Polish

**Files:**
- Modify as needed: `scripts/game.gd`
- Modify as needed: `art/home_ui/*`

**Step 1: Export Web build locally**

Run:

```bash
mkdir -p build/releases/web
godot --headless --path . --export-release Web build/releases/web/index.html
```

Expected: exit 0. Existing UID or Android daemon warnings may appear; record only blocking errors.

**Step 2: Serve and screenshot**

Run a local server:

```bash
python3 -m http.server 8099 --directory build/releases/web
```

Capture screenshots at:

- `1280x720`
- `1600x900`
- mobile landscape such as `844x390` if supported

Expected:

- No blank WebGL canvas.
- Logo, panels, resource bar, text, and click regions align.
- No AI-baked text conflicts with code text.
- Home screen resembles the supplied reference through separate elements.

**Step 3: Polish only targeted issues**

If visual issues appear:

- Adjust card rects, text rects, or icon centers.
- Regenerate only the problematic asset if needed.
- Do not redesign unrelated modes.

**Step 4: Run final verification**

Run:

```bash
godot --headless --path . -s res://tests/world_navigation_test.gd
godot --headless --path . -s res://tests/mobile_ui_scale_test.gd
godot --headless --path . -s res://tests/web_font_test.gd
godot --headless --path . -s res://tests/ui_theme_test.gd
godot --headless --path . -s res://tests/game_boot_test.gd
```

Expected: all exit 0.

**Step 5: Commit**

```bash
git add scripts/game.gd tests/world_navigation_test.gd art/home_ui
git commit -m "polish: refine image2 home screen layout"
```

### Task 6: Final Review

**Files:**
- Review: `scripts/game.gd`
- Review: `tests/world_navigation_test.gd`
- Review: `art/home_ui/*`
- Review: `docs/plans/2026-06-28-home-image2-elements-design.md`
- Review: `docs/plans/2026-06-28-home-image2-elements.md`

**Step 1: Check git status**

Run:

```bash
git status --short
```

Expected: only intentional files modified or clean after commits.

**Step 2: Review diff**

Run:

```bash
git log --oneline --decorate -5
git diff origin/main...HEAD --stat
git diff origin/main...HEAD -- scripts/game.gd tests/world_navigation_test.gd
```

Expected: scope limited to home UI asset composition, tests, docs, and new home assets.

**Step 3: Prepare final response**

Summarize:

- Which Image2 elements were generated.
- Which Godot files were changed.
- Which tests and visual checks passed.
- Any non-blocking warnings.
