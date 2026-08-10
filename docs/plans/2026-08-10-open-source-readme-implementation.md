# Open-Source README Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace root release-note clutter with a detailed, visually polished README and explicit source-code/media licensing boundaries suitable for a future public repository.

**Architecture:** Keep the project homepage self-contained by referencing tracked artwork and one lightweight SVG accent. Use a Python quality test to treat required README sections, local asset references, repository identity, and license separation as repository contracts.

**Tech Stack:** Markdown, SVG, Python 3 standard library, GitHub Actions metadata, Godot 4.6 project documentation.

---

### Task 1: Add the failing README quality test

**Files:**
- Create: `tests/readme_quality_test.py`

**Step 1: Write the failing test**

Create a standard-library Python script that checks the following conditions and exits non-zero on failure:

- `README.md`, `LICENSE`, `ASSETS_LICENSE.md`, and `docs/readme/readme-accent.svg` exist.
- No root `RELEASE_NOTES_v*.md` remains.
- README contains Chinese project, features, installation, controls, development, testing, contribution, roadmap, and licensing sections plus an English summary.
- README points to `NightsReimu/pvz-godot` Releases and Pages.
- Every relative image reference in README resolves to an existing file.
- README and license documents do not contain old `HecreReed` GitHub URLs.
- `LICENSE` limits MIT to source code and `ASSETS_LICENSE.md` excludes music and Touhou derivative assets.

**Step 2: Run test to verify it fails**

Run: `python3 tests/readme_quality_test.py`

Expected: FAIL because the README and license files do not exist and release notes remain.

**Step 3: Commit the test**

```bash
git add tests/readme_quality_test.py
git commit -m "test: define readme quality requirements"
```

### Task 2: Build the project README and visual accent

**Files:**
- Create: `README.md`
- Create: `docs/readme/readme-accent.svg`

**Step 1: Add the local visual header**

Reference `art/home_ui/home_title_text.png` and add a decorative local SVG with a subtle scan highlight. Include accessible alt text and avoid external image dependencies.

**Step 2: Document players' entry points**

Add the current version, GitHub Pages URL, GitHub Releases URL, supported platforms, Chinese overview, short English summary, feature matrix, Touhou Boss content, controls, and platform-specific install notes.

**Step 3: Document contributors' entry points**

Add Godot 4.6 requirements, clone/import/run commands, architecture table, representative tests, export information, contribution process, known limitations, roadmap, and project contacts.

**Step 4: Run the quality test**

Run: `python3 tests/readme_quality_test.py`

Expected: FAIL only on missing licenses and existing release notes.

### Task 3: Add split licensing documents

**Files:**
- Create: `LICENSE`
- Create: `ASSETS_LICENSE.md`
- Modify: `README.md`

**Step 1: Add the code license**

Add the MIT License for original source code, with an explicit preface that bundled media and third-party intellectual property are excluded.

**Step 2: Add the media notice**

Document asset categories, Touhou derivative-work status, official guideline link, original Touhou music redistribution uncertainty, noncommercial/unofficial status, contributor requirements, and takedown contact path.

**Step 3: Link the license documents from README**

State prominently that source code is open source while bundled media is not, and that public distributors must verify music authorization or replace the tracks.

### Task 4: Remove root release notes

**Files:**
- Delete: `RELEASE_NOTES_v1.0.65.md` through `RELEASE_NOTES_v1.0.92.md`

**Step 1: Delete all root version notes**

Remove files matching `RELEASE_NOTES_v*.md`. Do not touch gameplay code, project version, tags, or GitHub Releases.

**Step 2: Point history readers to GitHub Releases**

Confirm README links to `https://github.com/NightsReimu/pvz-godot/releases` as the canonical version history.

### Task 5: Verify and commit documentation normalization

**Files:**
- Test: `tests/readme_quality_test.py`
- Test: `tests/release_workflow_test.py`

**Step 1: Run documentation checks**

Run: `python3 tests/readme_quality_test.py`

Expected: PASS.

**Step 2: Run release workflow regression**

Run: `python3 tests/release_workflow_test.py`

Expected: PASS.

**Step 3: Check repository identity and whitespace**

Run: `rg -n -i 'github\.com/HecreReed|hecrereed\.github\.io' README.md LICENSE ASSETS_LICENSE.md docs`

Expected: no matches.

Run: `git diff --check`

Expected: no output.

**Step 4: Commit**

```bash
git add README.md LICENSE ASSETS_LICENSE.md docs/readme/readme-accent.svg tests/readme_quality_test.py RELEASE_NOTES_v*.md
git commit -m "docs: prepare repository for open source"
```

**Step 5: Push main**

Run: `git push origin main`

Expected: the documentation commits are available at `NightsReimu/pvz-godot`; no release tag is created.
