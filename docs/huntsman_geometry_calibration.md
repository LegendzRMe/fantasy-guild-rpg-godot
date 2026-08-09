# Huntsman geometry calibration

Huntsman uses the project conversion of `185 world pixels / 5.5 source units`, shared with nearby ranged conversions.

| Mechanic | Source-space target | Prototype world value | Calibration note |
|---|---:|---:|---|
| Human Basic Attack | 5.5 | 185 | Audited current weapon range |
| Worgen Basic Attack | 1.25 | 42.05 | Audited current Worgen weapon range |
| Cocktail range | 8.0 | 269.09 | Long directional shot, below Heroic mark range |
| Cocktail cone | 4.5 | 151.36 | Wide rear cone; primary target explicitly excluded |
| Razor Swipe movement | 2.0 | 67.27 | Short commitment movement, not a teleport |
| Darkflight / Disengage | 6.5 | 218.64 | Shared baseline; Running Wild multiplies both by 1.35 |
| Go for the Throat | 7.5 | 252.27 | Targeted leap |
| Marked projectile | 11.0 | 370.00 | Reconstructed long-range value for V1 |

Projectile travel is visible rather than instant: Cocktail uses 18 source units/second and Marked uses 22. Widths include target combat radius through the shared segment-distance geometry helper.

These are explicit prototype calibration values. They are centralized in `HuntsmanData.SPACE` so later visual playtesting can change them without searching runtime logic.
