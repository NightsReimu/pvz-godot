# Release Pipeline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a reproducible GitHub release pipeline for this Godot project and publish an initial release with Windows, macOS, and Web artifacts.

**Architecture:** Use Godot export presets in-repo, a GitHub Actions workflow that exports the game on tag/release/manual trigger, and a matching local export layout so the first release can be built and uploaded immediately from this machine. Keep release assets simple: `pvz-godot-windows.zip`, `pvz-godot-macos.zip`, and `pvz-godot-web.zip`.

**Tech Stack:** Godot 4.6 export presets, GitHub Actions, GitHub CLI, macOS local export, zip packaging.

---

### Task 1: Define export targets

**Files:**
- Create: `export_presets.cfg`
- Modify: `.gitignore`

**Step 1: Write the export preset file**

Add presets for:
- Windows Desktop
- macOS
- Web

Use deterministic export paths under `build/releases/`.

**Step 2: Add local build output ignores**

Ignore:
- `build/`
- `dist/`
- `releases/`

**Step 3: Validate preset parsing**

Run:

```bash
HOME=/tmp/godot-home godot --headless --path /Users/hecrereed/project/pvz/pvz-godot --quit
```

Expected: exit `0`

### Task 2: Add CI release workflow

**Files:**
- Create: `.github/workflows/release.yml`

**Step 1: Add workflow triggers**

Support:
- `workflow_dispatch`
- tags matching `v*`
- published releases

**Step 2: Add build jobs**

Use one matrix job for:
- `windows`
- `macos`
- `web`

Each job should:
- check out the repo
- install Godot export templates
- export the project
- zip the platform artifact
- upload the zipped file as an artifact

**Step 3: Add release upload job**

Download matrix artifacts and upload them to the GitHub release when running from a tag/release event.

### Task 3: Produce the first release locally

**Files:**
- Create: `build/releases/...`

**Step 1: Install local export templates for Godot 4.6**

Expected location:

```bash
~/Library/Application Support/Godot/export_templates/4.6.stable
```

**Step 2: Export all three targets**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot --export-release "Windows Desktop" build/releases/windows/pvz-godot.exe
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot --export-release "macOS" build/releases/macos/pvz-godot.app
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot --export-release "Web" build/releases/web/index.html
```

**Step 3: Package release zips**

Produce:
- `build/releases/pvz-godot-windows.zip`
- `build/releases/pvz-godot-macos.zip`
- `build/releases/pvz-godot-web.zip`

### Task 4: Publish GitHub release

**Files:**
- Create: Git tag and GitHub release metadata

**Step 1: Commit release pipeline**

```bash
git add export_presets.cfg .github/workflows/release.yml .gitignore docs/plans/2026-03-27-release-pipeline.md
git commit -m "build: add release pipeline"
```

**Step 2: Tag release**

```bash
git tag v0.1.0
git push origin main --tags
```

**Step 3: Create or edit GitHub release**

Upload the three local zips with `gh release create` or `gh release upload`.

### Task 5: Verify release surface

**Files:**
- None

**Step 1: Check release metadata**

Run:

```bash
gh release view v0.1.0
```

Expected: release exists and lists three uploaded platform zips.

**Step 2: Check workflow presence**

Run:

```bash
gh workflow list
```

Expected: new release workflow is visible.
