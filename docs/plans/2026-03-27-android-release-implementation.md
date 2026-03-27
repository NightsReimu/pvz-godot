# Android Release Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Android APK export to the existing GitHub release pipeline and publish a new release with Windows, macOS, Web, and Android assets.

**Architecture:** Reuse the existing Godot 4.6 export-template-based release pipeline, add one Android export preset, create a stable test keystore stored in GitHub secrets, and extend the matrix workflow with one Linux-based Android build target that exports a signed APK.

**Tech Stack:** Godot 4.6 export presets, GitHub Actions, GitHub CLI, Java 17, Android SDK command-line tools, keytool, apk export.

---

### Task 1: Add Android export preset and version metadata

**Files:**
- Modify: `export_presets.cfg`

**Step 1: Add an Android preset**

Add a new `Android` preset with:
- `export_path="build/releases/android/pvz-godot.apk"`
- `package/signed=true`
- `package/unique_name="com.hecrereed.pvzgodot"`
- `gradle_build/export_format=0`
- Android ARM architectures enabled
- release keystore fields left blank so environment overrides can supply them

**Step 2: Align version strings**

Update preset version metadata so Windows, macOS, and Android exports all use the same release version.

**Step 3: Verify preset syntax**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot --quit
```

Expected: exit `0`

### Task 2: Create Android CI support and APK publishing

**Files:**
- Modify: `.github/workflows/release.yml`

**Step 1: Extend the build matrix**

Add an `android` build target that runs on `ubuntu-latest` and publishes:

```text
pvz-godot-android.apk
```

**Step 2: Install Android toolchain in CI**

Add steps that:
- install Java 17
- install Android command-line tools
- install SDK components needed by Godot export
- generate `editor_settings-4.6.tres` with Android SDK and Java SDK paths

**Step 3: Inject signing credentials**

Add steps that:
- decode `ANDROID_KEYSTORE_RELEASE_BASE64`
- export `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`
- export `GODOT_ANDROID_KEYSTORE_RELEASE_USER`
- export `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`

**Step 4: Export and upload APK**

Run the Android export and upload the `.apk` artifact.

**Step 5: Update publish step**

Allow the publish job to upload both `*.zip` and `*.apk` assets.

### Task 3: Create fixed Android test signing credentials

**Files:**
- Create: temporary local keystore under `/tmp` or project-local ignored build directory
- Modify: GitHub repository secrets via CLI

**Step 1: Generate a stable test keystore**

Create a release keystore with `keytool` and a fixed alias.

**Step 2: Encode and upload secrets**

Set GitHub secrets:
- `ANDROID_KEYSTORE_RELEASE_BASE64`
- `ANDROID_KEYSTORE_RELEASE_USER`
- `ANDROID_KEYSTORE_RELEASE_PASSWORD`

**Step 3: Verify secret presence**

Run:

```bash
gh secret list
```

Expected: the three Android signing secrets are present.

### Task 4: Verify local Android export

**Files:**
- Create: `build/releases/android/...`

**Step 1: Prepare local Godot editor settings**

Point local Godot editor settings to a valid Java 17 path and Android SDK path.

**Step 2: Export Android APK locally**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot --export-release "Android" build/releases/android/pvz-godot.apk
```

Expected: exit `0` and a signed APK exists at the target path.

### Task 5: Publish and verify the new release

**Files:**
- Create: Git tag and GitHub release metadata

**Step 1: Commit Android release pipeline**

Commit preset and workflow changes.

**Step 2: Publish a new release tag**

Create and push a new semantic version tag.

**Step 3: Verify workflow success**

Run:

```bash
gh run list --workflow Release --limit 5
```

Expected: the release-triggered run for the new tag completes successfully.

**Step 4: Verify release assets**

Run:

```bash
gh release view <tag>
```

Expected: the release contains:
- `pvz-godot-windows.zip`
- `pvz-godot-macos.zip`
- `pvz-godot-web.zip`
- `pvz-godot-android.apk`
