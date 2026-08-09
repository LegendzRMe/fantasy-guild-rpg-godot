# Templar Geometry Calibration

All source-space distances are centralized in `TemplarData.SPACE`. The prototype uses the established project conversion of `185 / 5.5 = 33.636...` world pixels per source unit.

| Mechanic | Source distance | World-space value | Calibration purpose |
| --- | ---: | ---: | --- |
| Basic Attack | 1.25 | 42.05 | Melee contact radius |
| Blade Dash travel | 6.0 | 201.82 | Readable outward/return commitment |
| Twin Blades charge | 3.5 | 117.73 | Official current charge acquisition distance |
| Shield Ally | 10.0 | 336.36 | Deterministic closest-other-ally search |
| Crosscut rear search | 2.5 | 84.09 | Narrow rear-arc secondary-target window |

Blade Dash uses segment-to-circle collision between its previous and current positions, so frame rate does not create holes in the path. Each phase has a separate contact key: an enemy can be hit once outward and once returning, but never twice in the same phase. It is always snapped back to the saved cast origin at completion.

Twin Blades and Crosscut use live target positions for every strike. Crosscut candidates must be distinct from the primary target, within the rear search radius, and forward of the primary target relative to the Templar-to-primary direction. Candidate distance is reevaluated on each strike.

Purifier Beam has a tracked world position. It starts on its selected target, follows at the centralized beam speed, and deals its once-per-second tick only while within the calibrated 55-pixel contact radius. Target Purified increases follow speed by 15%.

These geometry constants are isolated from combat resolution so future arena scale, character model size, and authored collider changes can be recalibrated without rewriting talent logic.
