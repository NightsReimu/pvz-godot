# Auto Update Design

**Date:** 2026-04-07

**Goal:** Add a cross-platform in-app update flow backed by GitHub Releases, with true self-update for desktop builds, APK download/install handoff on Android, and graceful notification-only behavior on Web.

## Current Context

The project is a single-scene Godot 4.6 game rooted at `res://scenes/main.tscn` with most UI and flow logic inside `res://scripts/game.gd`.

The repository already has a GitHub Actions release workflow in `.github/workflows/release.yml` that exports:
- Windows zip
- macOS zip
- Web zip
- Android APK

There is no existing version-check or update system in runtime code. The current project metadata also does not expose a runtime app version suitable for comparing against GitHub release tags.

## Requirements

- Use GitHub Releases as the update source.
- Detect updates in-app.
- Let the app download updates directly.
- Replace the app automatically on supported desktop platforms.
- Support Android by downloading the APK and handing off to the system installer.
- Support Web with a safe degraded experience rather than pretending true self-update exists.
- Rename the app to `植物大战僵尸svg版`.

## Options Considered

### Option A: Check-only updater

Show a new-version prompt and open GitHub Releases in the browser.

Pros:
- Very low risk
- Almost no platform-specific code

Cons:
- Does not satisfy the request for in-app download and replacement

### Option B: Hybrid updater by platform

Use one update UI and one GitHub-release metadata path, but apply different install behavior by platform:
- Windows/macOS: download archive, stage files, launch helper script, quit, replace app
- Android: download APK, open with system installer
- Web: notify user and offer refresh/download

Pros:
- Matches real platform capabilities
- Single UX entry point
- No fake promises on Web

Cons:
- Requires desktop staging/replacement logic
- Requires careful progress and failure handling

### Option C: Full in-process updater everywhere

Try to make the running app directly replace itself on all platforms.

Pros:
- Conceptually simple to describe

Cons:
- Not realistic for Web
- Fragile on desktop because the running executable/app bundle cannot safely overwrite itself in place
- Worse failure modes than a helper-driven design

## Chosen Approach

Use **Option B**.

This is the only approach that satisfies the product request while staying technically honest:
- one update surface in the game
- one release feed from GitHub
- platform-specific install behavior where required

## Runtime Design

### 1. Version source

Add explicit runtime version metadata via `project.godot`:
- `application/config/name = "植物大战僵尸svg版"`
- `application/config/version = "<repo version>"`

The game will compare this runtime version with the GitHub latest release tag.

### 2. Update logic split

Create a new helper script, separate from `game.gd`, for update-specific logic:
- release URL construction
- version normalization and comparison
- platform asset matching
- download target paths
- pending update manifest paths

Keep `game.gd` responsible only for:
- starting the version check
- rendering the update prompt and progress
- reacting to download/install events

### 3. GitHub API source

Use:
- `https://api.github.com/repos/NightsReimu/pvz-godot/releases/latest`

This returns:
- `tag_name`
- `html_url`
- asset list with download URLs

The game will match assets by platform name:
- `pvz-godot-windows.zip`
- `pvz-godot-macos.zip`
- `pvz-godot-web.zip`
- `pvz-godot-android.apk`

### 4. Desktop install strategy

The running app will:
1. Download the matching archive into `user://updates/`.
2. Extract it into a staged folder.
3. Write a platform-specific helper script:
   - Windows: `.bat`
   - macOS/Linux-compatible shell: `.sh`
4. Launch the helper process with:
   - current process id
   - source staging dir
   - destination app dir
   - executable relaunch target
5. Quit.

The helper script will:
1. Wait for the game process to exit.
2. Copy staged files over the existing install directory.
3. Relaunch the app.

This avoids in-process self-overwrite.

### 5. Android install strategy

The game will:
1. Download the APK into `user://updates/`.
2. Open the file using the OS handoff path.

Actual installation remains a system action, which is the correct Android behavior.

### 6. Web strategy

The game will:
- still check GitHub Releases
- show that a new version exists
- allow opening/downloading the web artifact
- optionally show a “refresh now” action

It will not claim that the browser build can replace itself.

## UI Design

The updater should live on the world-select screen because that is the first stable non-battle screen.

UI elements:
- a compact status chip on world select:
  - `检查更新中`
  - `已是最新版本`
  - `发现新版本 vX.Y.Z`
  - `下载中 42%`
  - `安装更新`
- an action panel when an update exists
- progress feedback during download
- clear failure message with retry

Do not reuse win/lose dialog copy for updater messaging. Use separate updater text/state.

## Failure Handling

- Network failure: show non-blocking retry state
- Release API parse failure: show non-blocking error
- No matching asset for platform: show a platform-specific unsupported message
- Archive extraction failure: keep existing app untouched
- Helper launch failure: keep staged files and show retry/install-later message

## Release Pipeline Changes

The release workflow should inject version metadata consistently so release builds report the same version as the GitHub tag.

At minimum:
- tagged releases should export with `application/config/version` matching the tag without the `v` prefix

This keeps runtime version comparison stable for auto-update.

## Verification

Success means:
- the app name shows as `植物大战僵尸svg版`
- startup or world-select triggers an update check
- a newer mocked/latest release is recognized
- matching platform asset selection works
- desktop update flow writes staged files and helper scripts
- Android update flow downloads an APK and reaches the install handoff path
- Web update flow stays in notification-only mode
