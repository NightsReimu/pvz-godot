# Wind God danmaku pressure implementation plan

**Goal:** Increase the actual bullet density and multi-lane pressure of 4-19 and 4-20 finales against fusion formations.

**Architecture:** Apply role-scoped emission tuning to complete Minoriko/Hina cast sessions. Keep their canonical geometry and board mechanics, increase fan/ring density, strengthen quiet mechanism-card accompaniment, and honor explicit firing schedules without the shared fallback adding another wait. Road and other-character sessions retain their existing cadence and density.

**Tech stack:** Godot 4.6 / GDScript, native real-dispatch and swept-collision probes, full campaign simulations, four-platform release workflow.

## 1. Measure and reproduce sparse emission

- Record every Minoriko/Hina E/N/H/L card's actual emissions, inter-wave gaps, peak live objects and armed on-board collision pressure at v1.0.175.
- Include Shizuha/Hina road casts and representative other-character casts as unchanged controls.
- Reproduce the extra shared scheduler wait after a character emitter already sets its own next wave; low board-mechanic volleys currently contain only three bullets.

## 2. Strengthen complete roles

- Update `scripts/runtime/touhou_danmaku_runtime.gd`, `aki_danmaku.gd` and `hina_danmaku.gd` with explicit full-role session tuning and pattern-aware multi-lane volleys. Cover the v175 finale additions as well as the original cards.
- Target roughly twice the ordinary finale launch rate, with a larger relative correction for sparse board-mechanic cards. Preserve the identity of leaf/grain patterns and Hina's ofuda/needle/fire/doll families.
- Preserve readable one-second-or-longer arming, mirror counterplay, time stop and owner cleanup. Maintain the 480-bullet/72-beam budgets and check actual emitted objects are not silently lost to saturation.
- Preserve spell lists, stage health, conveyor cadence and reinforcement policy; this request concerns bullets.
- Normalize full-role motion in grid space on wide, shallow viewports. Preserve normalized rotations, thaw and redirects, physical reflected returns, original TTL and arming. Fixed middle/rear targets must receive actual swept hits, not merely a higher live particle count.

## 3. Verify and publish v1.0.176

- Verify actual baseline-relative emission and collision pressure, exact unchanged road/control behavior, valid poses and desktop/mobile rendering.
- Run native empty-board 4-19 and 4-20 in all four difficulties with real conveyor/paid planting, campaign fusion enemies and earned ultimates. Keep the v175 policy and diagnose failures before changing tuning.
- Run affected danmaku, phase, collision, role and custom-boss regressions. Independently review the final diff.
- Stamp v1.0.176, commit and push the annotated tag. Verify all four build logs, public release assets and the deployed PCK's actual version and changed modules.

## Evidence and balance interpretation

- The frozen v175 source reproduces all 86 captured casts exactly. The normal-grid paired sample measures 2.05–2.31× total emission and increased actual swept hits; 10 road casts and 30 other-character controls retain their original behavior.
- The viewport regression covers 380 actual casts across three fixed cell geometries and native 844×390 / 1600×900 layouts. It checks real cols 2–4 damage, harmless arming, budget saturation, reflection, time stop and cleanup.
- Keep the unchanged-policy eight-route baseline, including its genuine Aki Lunatic collapse. A separate legal emergency-card policy may demonstrate completion without silently replacing the failed comparison or weakening production tuning.

- The separate Aki Lunatic emergency policy completed all eight phases in 1056.5s with zero used mowers, genuine sun/cooldowns and native cherry/cactus/blover actions. The original failure remains recorded as the unchanged-policy baseline.
- All 38 affected regression entries pass. The signature-ultimate fixture now stops its SFX playback and gives the mixer time to release it at teardown; gameplay assertions and audio behavior are unchanged. Final Godot editor import, README and Android preset checks pass.
