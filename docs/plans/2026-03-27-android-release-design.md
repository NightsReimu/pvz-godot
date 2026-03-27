# Android Release Design

**Date:** 2026-03-27

**Goal:** Extend the existing GitHub release pipeline so each release also publishes a signed Android test APK alongside the existing Windows, macOS, and Web assets.

## Chosen Approach

Use a fixed test signing keystore stored in GitHub Actions secrets, add an Android export preset to the project, and extend the existing release workflow with one additional build target that exports a release-signed APK.

This is intentionally a GitHub Release testing workflow, not a Play Store pipeline:
- Output format is `apk`, not `aab`.
- Signing uses a stable test keystore so users can install upgrades over previous builds.
- Keystore material stays out of the repository and is only injected through GitHub secrets at build time.

## Why This Approach

This preserves the current release flow and only adds one new platform asset. A fixed keystore avoids the bad UX of re-generating a new debug key every run, which would force uninstall/reinstall on Android devices. Keeping the key in GitHub secrets is cleaner than committing a keystore into the repository.

## Export Strategy

Use Godot's Android export platform with these constraints:
- Export format: `APK`
- Signed package: enabled
- Package id: fixed reverse-DNS identifier for upgrade compatibility
- Keystore path/user/password: injected through environment variables
- APK asset published directly as `pvz-godot-android.apk`

The workflow should stay on the prebuilt export-template path for Android instead of switching to a custom Gradle project. This keeps the CI surface smaller for a test APK release while still producing a signed installable package.

## CI Requirements

The Android export plugin in Godot requires Android SDK and Java SDK paths in editor settings, so the workflow must generate an editor settings file before export. The Android build job should:

1. Install Java 17.
2. Install Android command-line tools plus the required SDK packages.
3. Write a Godot `editor_settings-4.6.tres` file containing:
   - `export/android/java_sdk_path`
   - `export/android/android_sdk_path`
4. Decode the base64 keystore secret to a temporary file.
5. Export `Android` with `--export-release`.
6. Upload the resulting `.apk` as an artifact.
7. Include the APK in the publish job upload step.

## Secrets

The repository should store these GitHub Actions secrets:
- `ANDROID_KEYSTORE_RELEASE_BASE64`
- `ANDROID_KEYSTORE_RELEASE_USER`
- `ANDROID_KEYSTORE_RELEASE_PASSWORD`

The workflow will decode the keystore secret to a temporary file and then expose the file path and credentials to Godot using the official environment overrides:
- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER`
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`

## Versioning

The next release should bump the in-repo export version metadata and publish a new GitHub release tag so the APK and desktop assets all match one release version.

## Verification

Success means all of the following are true:
- Local Android export works from this machine.
- The `Release` workflow succeeds on a tag-triggered run with all four targets.
- The GitHub release page shows:
  - `pvz-godot-windows.zip`
  - `pvz-godot-macos.zip`
  - `pvz-godot-web.zip`
  - `pvz-godot-android.apk`
