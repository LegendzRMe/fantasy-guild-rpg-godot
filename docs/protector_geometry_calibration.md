# Protector Geometry Calibration

All tunable distances live in `ProtectorData.SPACE`. V1 uses the established conversion `185 / 5.5 = 33.636...` world pixels per source unit.

| Mechanic | Source units | World value |
| --- | ---: | ---: |
| Basic Attack range | 3.75 | 126.14 |
| Q throw | 9.0 | 302.73 |
| Q effect radius | 1.35 | 45.41 |
| Q knockback | 1.8 | 60.55 |
| W cast range | 9.0 | 302.73 |
| W wall length | 5.5 | 185.00 |
| W thickness | provisional | 18.00 |
| Restraining proximity | 1.1 | 37.00 |
| E path length | 5.5 | 185.00 |
| E half-width | 2.0 | 67.27 |
| Judgment range | 8.0 | 269.09 |
| Judgment secondary radius | 2.75 | 92.50 |
| Sanctification radius | 3.5 | 117.73 |
| Burning Halo radius | 2.25 | 75.68 |
| Archangel radius | 3.5 | 117.73 |

Force Wall is centered on the clamped ground target and oriented perpendicular to Protector-to-target direction. Zero direction uses facing. It is represented as a reusable segment/capsule with thickness, not an axis-aligned class-specific rectangle.

Smite currently uses a deterministic wide path around a central segment. Law and Order reflects both endpoints across the intersected wall centerline, preserves orientation, and shares the original cast's contact sets. Q and Judgment filter only the caster's own temporary wall when finding safe special-movement destinations; battle bounds, permanent terrain, and external blockers remain authoritative.

Wall length, thickness, Q radius, E shape, and special-movement landing offsets remain provisional visual/game-feel calibration points for manual testing with final character scale.
