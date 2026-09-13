# Seven garden minigames

Add an independent, immediately available home entry and seven replayable modes. Reuse existing plant/zombie art, combat, card controls, pause, and audio. Keep campaign progression separate; save first-clear badges and award 200 coins once per mode.

- Rain: storm pool, falling seed packets collected into a six-slot free seed bank. Expiring packets, regular lily pads and guaranteed early attackers.
- Beghouled: adjacent swaps on a living 5×8 plant board. Three or more in a line clears and refills; 50 matched groups wins. Invalid swaps revert, hints and dead-board recovery are free. Zombies keep advancing.
- Invisible zombies: free conveyor; footprints and brief hit/status/lamp reveals. Targetability remains ordinary.
- Seeing Stars: occupy all marked cells with starfruit simultaneously while defending. Marked cells are shown throughout the match.
- Bare ground: flower pots restore planting spaces on stone; 5000 sun, no natural income, five waves with 250 sun and an explicit preparation break between them.
- Protect portals: keep two vulnerable portal cores alive. Linked rifts reroute zombies once; positions switch with advance warning. Cores cannot be shoveled or replaced.
- Column planting: roof conveyor; one card fills every valid empty position in a column. One card is consumed only if at least one placement succeeds. Pots use the support layer.

Implementation: curated level definitions, shared minigame runtime, separate match-3 model and drawing/menu modules, small lifecycle hooks in game.gd. Runtime owns minigame spawning and completion, preventing campaign extras or premature wins.

Validation: focused gameplay tests for all seven objectives and invalid actions, pause/restart/save isolation, desktop and phone captures, existing special-mode/conveyor/navigation regressions. Release with NightsReimu author/committer after checks pass.
