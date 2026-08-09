# Sentinel geometry calibration

Sentinel uses the established conversion constant `185 / 5.5 = 33.636…` world pixels per source unit. These values are provisional gameplay calibration, not claims about exact source-engine geometry.

| Element | Source units | World value | Notes |
| --- | ---: | ---: | --- |
| Basic Attack range | 6.0 | 201.82 | Gains one source unit at 40 quest stacks. |
| Light of Elune range | 7.75 | 260.68 | Party-order target resolver; self included. |
| Hunter's Mark range | 7.0 | 235.45 | Huntress' Fury multiplies by 1.25. |
| Sentinel Shot authored flight | 24.0 | 807.27 | A returning Ranger projectile gets a second authored leg. |
| Sentinel Shot speed | 20.0/sec | 672.73/sec | Long enough to visibly read and dodge at range. |
| Sentinel Shot half-width proxy | 1.25 | 42.05 | Ranger multiplies by 1.25. |
| Lunar Flare range | 10.5 | 353.18 | Quest reward multiplies by 1.30. |
| Lunar Flare radius | 1.5 | 50.45 | Warning and impact use the same radius. |
| Mark of Mending radius | 8.5 | 285.91 | Centered on the marked enemy. |
| Starfall radius | 5.5 | 185.00 | Persistent six-second field. |

## Distance scaling

Sentinel Shot uses `bonus = min(global_cap, distance_units × leg_modifier)`, where the modifier is 1.0 outbound and 1.25 on Ranger's returning leg. At one complete baseline leg this is +100%; a full outbound-and-return route reaches the shared +250% ceiling. A return adds to total travel rather than restarting scaling. Collision checks use each frame's swept segment, stable distance ordering, a per-projectile unique target set, and explicit pierce count.

## Calibration follow-up

Final tuning should be performed at 1280×720 in the dedicated Sentinel Range. Verify travel readability at short and full range, mobile directional aiming, return visibility at the battlefield edge, collision width against small and Boss radii, and the 0.75-second Lunar Flare reaction window. Change the centralized values only; runtime code must not acquire duplicate geometry constants.
