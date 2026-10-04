# Fusion model identity and native-only almanac

Goal: Remove fusion plants from the almanac and make fusion organisms distinguishable at battle scale, then publish v1.0.161.

User authorization: redesign the models and publish; preserve the v160 combat behavior.

Architecture: replace the common bowl plus miniature full plants with a unified botanical organism. Ingredient families choose actual torso topology, roots and palette; weapon organs and characteristic material details attach to that organism. Named recipes receive specific architecture choices, while all fixed and recursively grown combinations use the same deterministic SVG authoring path. The almanac lists the player's native collection only and repairs a saved fusion selection to a native plant.

Implementation:
1. Reproduce fusion entries in the almanac and add a meaningful silhouette regression that fails for the previous shared bowl models.
2. Filter fusion entries from collection visibility and remove fusion catalogue revision caching; update stale selection and scrolling tests.
3. Author a morphology renderer with distinct fruit, bastion, tree, bamboo, mushroom, flower, mirror, vine, aquatic and weapon anatomy, source-specific color and details, plus named recipe overrides. Use component information in actual geometry rather than label/signature jitter.
4. Generate all 10,921 static models through that renderer, and render recursive forms through the same path. Keep weapons facing right and rear-defense organs facing left only when appropriate.
5. Inspect side-by-side native captures of different pairs sharing a common ingredient, fixed named forms, further grafts, desktop and mobile gameplay, preparation and native-only almanac. Verify alpha-mask diversity at small battle sizes and absence of missing/unrenderable SVGs.
6. Run the focused tests and full game regression, update screenshots/version/release notes, commit and publish four builds plus Pages. Verify release assets and deployment SHA.
