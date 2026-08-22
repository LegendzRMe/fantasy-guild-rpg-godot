# Vitalist geometry calibration

Vitalist uses one conversion scale: `185 / 5.5` world pixels per source unit. All runtime footprints are centralized in `VitalistData.SPACE`; runtime code does not embed ability pixels.

| Mechanic | Source-space value | Project-space intent |
| --- | ---: | --- |
| Combat radius | 0.6875 | Collision and safe displacement radius |
| Basic Attack | 1.5 | Melee baseline |
| Fetid Touch Basic Attack | 5.5 | Permanent ranged talent mode |
| Q cast / spread | 7.0 / 4.5 | Party target and automatic neighbor search |
| W range / radius | 10.0 / 0.5 | Directional capped contact segment |
| Reactive radius | 5.5 | Nearby pre-D infection search |
| E cast / zone radius | 5.5 / 2.5 | Placed channel and tick footprint |
| Swipe ranges | 4.0, 5.5, 7.0 | Three expanding 100-degree frontal arcs |
| Shove acquisition | 10.0 | Directional first-target segment |
| Poppin radius | 2.5 | Capped AoE detonation footprint |

The exact raw footprint representation varies among source XML fields, normalized definitions, and effect validators. The chosen values preserve relative reach and are exposed for tuning. Massive Shove movement itself is frame-driven at 8.0 source units per second and stops at collision-safe blocker or boundary endpoints. Tests assert centralized usage, target caps, increasing Swipe reach, and boundary/blocker behavior rather than relying on scattered pixel literals.
