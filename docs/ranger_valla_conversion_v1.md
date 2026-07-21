# Ranger V1 — Temporary Valla Mechanical Conversion

This is a mechanics-first prototype reference. Names, tuning, effects, and visual identity are temporary and must be replaced with original final game content.

## Runtime ownership

- `ranger_data.gd` owns stable IDs, level-one values, spatial conversion, descriptions, and the eight talent tiers.
- `ranger_system.gd` owns Hatred, talent rules, encounter quest counters, Ranger slot state, derived movement/range/attack-speed values, and telemetry.
- `ranger_runtime.gd` owns combat-world targeting, casts, impacts, hazards, and Heroic ticking.
- `ranger_ability_presenter.gd` owns player-facing roster text and rounds damage/healing down to whole numbers.

The Ranger uses the stable actions `ranger_basic_attack`, `ranger_trait`, `ranger_q`, `ranger_w`, `ranger_e`, `ranger_r1`, and `ranger_r2`. Its level-one chassis is 1,340 Health, 2.793 regeneration, 70 Basic Attack damage, 1.67 attacks per second, zero Armor, 185 world-unit range, and 145 movement speed. Health, regeneration, Basic Attack damage, and ability amounts scale exponentially by 4% per level.

## Interaction contract

Manual drag assignment remains authoritative. Q, W, and Heroics preserve the Ranger's current assignment. Vault clamps to a valid range, moves through units but not the arena's solid geometry, and clears the assignment. Hatred gains only from successful eligible Basic Attacks and expires as one shared stack after five seconds; Strafe pauses that timer.

Quest counters are held in Ranger runtime state so their lifetime follows the current combat encounter. Dungeon/raid orchestration may retain this dictionary between rooms/boss phases when those persistent encounter contexts are introduced; leaving the context must initialize a new runtime.

## Current visual test limits

The prototype resolves Hungering Arrow seeks and Multishot expansion deterministically at cast time, while preserving their final targeting and per-target rules. Rain uses one delayed rectangle pass rather than six separately animated subareas. These are deliberate temporary presentation limitations, not data-model limitations. Telemetry and tests cover the mechanical outcomes while final projectile and subarea visuals remain pending original art and animation work.

