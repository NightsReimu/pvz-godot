# Auto Update Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a GitHub Releases based in-app updater with true desktop replacement flow, Android APK install handoff, Web fallback notification, and rename the app to `植物大战僵尸svg版`.

**Architecture:** Move update-specific logic into a dedicated system helper so `game.gd` only manages UI and event flow. Use GitHub's latest release API for metadata, `HTTPRequest` for runtime fetch/download, `ZIPReader` plus `DirAccess` for staging, and an external helper script for desktop replacement after the app exits.

**Tech Stack:** Godot 4.6, `HTTPRequest`, `JSON`, `ZIPReader`, `DirAccess`, `OS.create_process`, GitHub Actions, GitHub Releases API.

---

### Task 1: Add failing tests for update metadata and platform matching

**Files:**
- Create: `tests/update_manager_test.gd`
- Create: `scripts/system/update_manager.gd`

**Step 1: Write the failing test**

Cover:
- version comparison (`0.1.5` < `0.1.6`)
- GitHub latest release JSON parsing
- asset selection for `windows`, `macos`, `android`, `web`
- Web being marked as notification-only

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/update_manager_test.gd
```

Expected: fail because `update_manager.gd` behavior is not implemented.

**Step 3: Write minimal implementation**

Add a pure-logic helper with:
- repo constants
- current version normalization
- semver-ish comparison
- release JSON parsing
- platform asset lookup

**Step 4: Run test to verify it passes**

Run the same command and expect exit `0`.

### Task 2: Add failing tests for staged desktop update artifacts

**Files:**
- Modify: `tests/update_manager_test.gd`
- Modify: `scripts/system/update_manager.gd`

**Step 1: Write the failing test**

Cover:
- update staging path generation
- helper script text generation for Windows and Unix-like desktop platforms
- helper script includes wait/copy/relaunch steps

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/update_manager_test.gd
```

Expected: fail on missing helper script generation behavior.

**Step 3: Write minimal implementation**

Add methods that:
- derive `user://updates` paths
- compute destination directories
- emit helper script contents

**Step 4: Run test to verify it passes**

Run the same command and expect exit `0`.

### Task 3: Add runtime version metadata and rename the app

**Files:**
- Modify: `project.godot`

**Step 1: Set app name**

Change:
- `application/config/name` to `植物大战僵尸svg版`

**Step 2: Add app version**

Add:
- `application/config/version = "0.1.5"` as the in-repo base version

**Step 3: Verify Godot still boots**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/game_boot_test.gd
```

Expected: exit `0`.

### Task 4: Add update runtime state and HTTP nodes to the game

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Write failing UI-state test**

Create a focused test that instantiates `game.gd` and asserts update state is initialized cleanly.

**Step 2: Run test to verify it fails**

Run the targeted test and expect failure.

**Step 3: Add minimal runtime plumbing**

Implement:
- updater preload
- version-check `HTTPRequest`
- download `HTTPRequest`
- updater state fields
- startup check trigger after loading finishes

**Step 4: Run tests**

Run the targeted updater test plus `game_boot_test.gd`.

### Task 5: Add world-select updater UI and actions

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Write failing UI behavior test**

Cover:
- update chip text for latest/update-available/downloading/error states
- click routing for retry/download/install/open-release

**Step 2: Run test to verify it fails**

Run the targeted test and expect failure.

**Step 3: Add minimal implementation**

Implement:
- update status rects on world-select
- draw/update button copy
- input handling
- non-blocking status/toast paths

**Step 4: Run tests**

Run the updater tests and existing smoke tests.

### Task 6: Add desktop download, extraction, and helper launch flow

**Files:**
- Modify: `scripts/system/update_manager.gd`
- Modify: `scripts/game.gd`

**Step 1: Write failing filesystem-flow test**

Cover:
- archive destination paths
- extraction target path creation
- helper script path generation

**Step 2: Run test to verify it fails**

Run updater tests and expect failure.

**Step 3: Add minimal implementation**

Implement:
- save downloaded file
- unzip archives with `ZIPReader`
- clean/create stage directories
- write helper script
- launch helper via `OS.create_process`
- quit the app after successful handoff

**Step 4: Run tests**

Run updater tests and `game_boot_test.gd`.

### Task 7: Add Android and Web fallback behavior

**Files:**
- Modify: `scripts/system/update_manager.gd`
- Modify: `scripts/game.gd`

**Step 1: Write failing behavior test**

Cover:
- Android returns `install_handoff`
- Web returns `notify_only`

**Step 2: Run test to verify it fails**

Run updater tests and expect failure.

**Step 3: Add minimal implementation**

Implement:
- Android APK handoff using shell/open path
- Web open/download/refresh-only action mapping

**Step 4: Run tests**

Run updater tests again.

### Task 8: Stamp release versions in CI

**Files:**
- Modify: `.github/workflows/release.yml`

**Step 1: Write version-stamping step**

Before export:
- derive version from tag or workflow input
- update `project.godot` `application/config/version`

**Step 2: Verify workflow syntax**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
print(Path('.github/workflows/release.yml').read_text()[:400])
PY
```

Expected: file reads cleanly after edits.

### Task 9: Full verification

**Files:**
- Test: `tests/update_manager_test.gd`
- Test: `tests/game_boot_test.gd`

**Step 1: Run updater tests**

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/update_manager_test.gd
```

Expected: exit `0`.

**Step 2: Run boot smoke test**

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/game_boot_test.gd
```

Expected: exit `0`.

**Step 3: Run any integration test added for updater UI**

Expected: exit `0`.

**Step 4: Commit**

```bash
git add project.godot .github/workflows/release.yml scripts/system/update_manager.gd scripts/game.gd tests/update_manager_test.gd docs/plans/2026-04-07-auto-update-design.md docs/plans/2026-04-07-auto-update-implementation.md
git commit -m "feat: add in-app update flow"
```
