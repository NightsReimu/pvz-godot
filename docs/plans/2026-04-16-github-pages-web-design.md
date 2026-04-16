# GitHub Pages Web Deployment Design

**Date:** 2026-04-16  
**Status:** Approved

## Goal

Publish the Godot Web build to GitHub Pages so the game is directly playable at the repository site URL, with deployments tied only to official `v*` releases.

## Constraints

- The existing release workflow already builds Windows, macOS, Web, and Android artifacts.
- The playable website must always match an official release, not every `main` push.
- The repository should use the default GitHub Pages URL: `https://nightsreimu.github.io/pvz-godot/`.
- The deployment should reuse the existing Web export rather than introducing a second build pipeline.

## Recommended Approach

Extend the existing [release workflow](/Users/hecrereed/project/pvz/pvz-godot/.github/workflows/release.yml) with a Pages deployment job that runs only for `v*` tags. The workflow should reuse the same Web artifact produced for releases, unpack it into a Pages payload, add a `.nojekyll` marker, upload that payload through `actions/upload-pages-artifact`, and then publish it with `actions/deploy-pages`.

## Why This Approach

- It keeps the Web release ZIP and the live website in sync.
- It avoids maintaining a second workflow that could drift from the release pipeline.
- It avoids polluting a `gh-pages` branch with generated files.
- It keeps the deployment trigger predictable: only tagged releases update the live site.

## Deployment Flow

1. Release workflow builds the Web export into `build/releases/web`.
2. The existing packaging step continues producing `dist/pvz-godot-web.zip` for release downloads.
3. A new Pages preparation step downloads the Web artifact inside the same workflow run.
4. The artifact is unzipped into a clean Pages directory and `.nojekyll` is added.
5. The Pages directory is uploaded with `actions/upload-pages-artifact`.
6. A Pages deployment job publishes that artifact to the `github-pages` environment.

## Repository Settings

- GitHub Pages should use GitHub Actions as the publishing source.
- The repository homepage URL should be set to the Pages site URL for consistency in the repo UI.

## Validation

- Add a workflow regression test to assert the release workflow contains the Pages upload and deploy steps.
- Validate the Pages payload contains `index.html`.
- Publish a new tagged release and confirm that the Pages deployment succeeds and produces a live URL.
