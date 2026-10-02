# 东方符卡插画特效 Implementation Plan

Goal: Generate six transparent spell illustrations, animate them in live Touhou skill rendering, and publish v1.0.155.

Architecture: A cached read-only TouhouSpellArt renderer consumes existing cast ages and effect lifetimes. Illustration layers render before danmaku and character silhouettes. Existing warning geometry, collision, density and damage remain driven by the current combat runtime. Missing textures return safely to current rendering.

Tech Stack: Built-in image generation, transparent PNG, Godot 4.6 CanvasItem, GDScript and existing regression tools.

1. Generate crimson seal, golden stars, frost crystal, sakura spirit, phoenix fire and boundary gap as separate transparent illustrations; preserve alpha and save prompt/source hashes.
2. Add a texture cache and deterministic transforms based on existing cast/effect progress. Attach the cast renderer ahead of bullet and boss rendering, and targeted spell artwork ahead of existing effect geometry.
3. Verify pause/expiry/nonspell behavior, missing assets, runtime prewarming, transparent import and immutable gameplay state. Capture desktop/mobile real spells through the native Godot renderer.
4. Run animation, spell contract, balance, lifecycle, boot and release checks. Update version155 and release notes. Publish all four platforms after actual packaged PNG/hash/native rendering validation.
