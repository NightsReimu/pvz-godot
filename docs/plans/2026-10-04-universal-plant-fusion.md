# Universal plant fusion and functional ultimate skills

**Goal:** Any two native plants or grown fusion plants can combine, with original anatomy, working combat and observable ultimate effects. Publish v1.0.159 after verification.

**Architecture:** Keep named recipes, fill every unordered native pair, and derive recursive forms from a canonical bounded ingredient multiset. Native pairs have individual SVG files; recursive combinations build independent SVG geometry from authored botanical organs and cache a bounded set of textures. Combat style follows attacking ingredients instead of whichever passive base was selected. Each fusion has an explicit skill payload and description; gameplay and animation use the same payload.

**Tech stack:** Godot 4.6, GDScript, authored SVG, Python asset tooling, GitHub four-platform releases.

1. Add failing behavioral regressions for complete pair coverage, continued cross-fusion, passive no-op ultimates, solar attacks, pumpkin survival, and retained ranged attacks. Run them and record failures.
2. Implement symmetric ingredient composition, all native-pair definitions, incremental recursive registration, cached almanac lists, skill payloads and independent descriptions. Cap strength and ingredient weights, not pair compatibility.
3. Repair attack dispatch and merged armor/sleep state. Implement bombardments, laser sweeps, blade storms, defense/healing, sunlight, wake/haste, hypnosis, magnetic recovery, elemental control and combined skill effects. Run behavioral checks against actual enemy and plant state.
4. Author per-native organ geometry, individual models for all native pairs, recursive SVG composition, skill emblems and animations. Validate XML, geometry, rasterization, facing and resource bounds. Inspect desktop and mobile captures.
5. Run the complete game regression suite, update usage/release notes/version and publish. Verify tag, all four uploaded assets and final Pages deployment.

The user has explicitly delegated the creative decisions and publication; proceed within that scope without further approval gates. Preserve existing unrelated untracked files.
