# GitHub Pages Web Deployment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Publish the existing Godot Web export to GitHub Pages only when a `v*` release is created.

**Architecture:** Reuse the current release workflow as the single build source of truth. Add a Pages artifact upload and deployment path that consumes the Web release artifact from the same workflow run, then update repository settings to use the default Pages URL.

**Tech Stack:** GitHub Actions, GitHub Pages, `gh` CLI, Python workflow regression tests

---

### Task 1: Add a failing workflow regression test

**Files:**
- Modify: `tests/release_workflow_test.py`
- Test: `tests/release_workflow_test.py`

**Step 1: Write the failing test**

Add assertions that the release workflow:
- requests `pages: write` and `id-token: write` permissions
- uses `actions/upload-pages-artifact`
- uses `actions/deploy-pages`
- references the `github-pages` environment
- uploads a `.nojekyll` Pages payload that contains `index.html`

**Step 2: Run test to verify it fails**

Run: `python3 tests/release_workflow_test.py`  
Expected: FAIL because the current workflow does not yet include any Pages deployment steps.

**Step 3: Write minimal implementation**

Do not touch production workflow logic yet. Only complete the failing assertions.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `python3 tests/release_workflow_test.py`  
Expected: FAIL with a Pages-specific missing-workflow assertion.

**Step 5: Commit**

```bash
git add tests/release_workflow_test.py
git commit -m "test: cover pages deployment workflow"
```

### Task 2: Extend the release workflow to publish Pages

**Files:**
- Modify: `.github/workflows/release.yml`
- Test: `tests/release_workflow_test.py`

**Step 1: Implement Pages permissions and artifact preparation**

Add top-level workflow permissions for:
- `contents: write`
- `pages: write`
- `id-token: write`

Add a Web-only step in the build job that:
- unzips `dist/pvz-godot-web.zip` into a clean Pages staging directory
- touches a `.nojekyll` file
- verifies `index.html` exists
- uploads the staging directory with `actions/upload-pages-artifact@v4`

**Step 2: Add a dedicated Pages deployment job**

Create a `deploy_pages` job that:
- depends on `build`
- runs only for `v*` tags or manual release tags
- uses the `github-pages` environment
- calls `actions/deploy-pages@v4`

**Step 3: Run workflow regression test**

Run: `python3 tests/release_workflow_test.py`  
Expected: PASS

**Step 4: Run broader regression coverage**

Run: `python3 tests/android_export_preset_test.py`  
Expected: PASS

**Step 5: Commit**

```bash
git add .github/workflows/release.yml tests/release_workflow_test.py
git commit -m "feat: deploy web release to github pages"
```

### Task 3: Configure repository Pages metadata

**Files:**
- External repo settings via `gh`

**Step 1: Inspect current Pages configuration**

Run: `gh api repos/NightsReimu/pvz-godot/pages`
Expected: either existing Pages metadata or a 404 indicating Pages has not been configured yet.

**Step 2: Enable GitHub Pages for Actions if needed**

Run a `gh api` PATCH/POST request so the repository uses GitHub Actions as its Pages publishing source.

**Step 3: Set homepage URL**

Run: `gh repo edit --homepage https://nightsreimu.github.io/pvz-godot/`

**Step 4: Verify repository settings**

Run: `gh repo view --json homepageUrl`  
Expected: homepage URL is `https://nightsreimu.github.io/pvz-godot/`

### Task 4: Release and verify the live site

**Files:**
- Modify: `project.godot`
- Modify: `export_presets.cfg`

**Step 1: Bump version metadata**

Update app versions for the next release tag in:
- `project.godot`
- `export_presets.cfg`

**Step 2: Run verification suite**

Run:

```bash
python3 tests/release_workflow_test.py
python3 tests/android_export_preset_test.py
failed=0; for f in tests/*.gd; do godot --headless --path . -s "$f" >/tmp/test.out 2>&1 || { echo "FAILED:$f"; cat /tmp/test.out; failed=1; break; }; done; exit $failed
```

Expected: PASS

**Step 3: Publish release**

Run:

```bash
git add project.godot export_presets.cfg .github/workflows/release.yml tests/release_workflow_test.py docs/plans/2026-04-16-github-pages-web-design.md docs/plans/2026-04-16-github-pages-web-implementation.md
git commit -m "feat: publish web release to github pages"
git push origin main
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

**Step 4: Verify Actions deployment**

Run:

```bash
gh run list --limit 5
gh run watch <pages-release-run-id> --exit-status
gh release view vX.Y.Z --json url,assets
```

Expected:
- release workflow passes
- GitHub Release is published
- Pages deployment job succeeds

**Step 5: Verify live site**

Open: `https://nightsreimu.github.io/pvz-godot/`
Expected: the exported Godot Web build loads directly from GitHub Pages.
