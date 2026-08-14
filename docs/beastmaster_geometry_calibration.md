# Beastmaster geometry calibration

Lifecycle: provisional calibration note.

The conversion uses Rexxar's audited 5.5 Basic Attack range as the stable bridge to the project's existing 185-world-unit ranged baseline: one source unit equals `185 / 5.5`, or approximately 33.636 world units. Source-space radii, ranges, and movement speeds remain named in `beastmaster_data.gd` so later visual tuning does not change mechanics silently.

| Element | Source-space input | Initial world-space treatment |
|---|---:|---:|
| Rexxar Basic Attack | 5.5 | 185 |
| Rexxar radius | 0.875 | 29.43 |
| Misha attack range | 1.5 | 50.45 |
| Misha radius | 0.9375 | 31.53 |
| Beast attack range | 2.0 | 67.27 |
| Swoop line | 12.0 long, 1.0 half-width | 403.64, 33.64 |
| Charge line | 6.5 long, 1.25 half-width | 218.64, 42.05 |
| Greater rally | 8.5 | 285.91 |
| Boar line | 20.0 long, 6.0 half-width | 672.73, 201.82 |
| Wildfire radius | 2.5 | 84.09 |

Endpoints use the shared blocker-safe geometry helper. Line contacts include the target combat radius, and deterministic sorting resolves equal-distance contacts by combat ID. Acquisition, follow, leash, spawn offset, and Pack Commander leash values are provisional gameplay-space choices because the normalized source records do not provide a directly portable equivalent for this project's arena scale.

Playtesting should specifically inspect narrow blocker approaches, Misha's follow/acquisition boundary, two-beast Swoop overlap, five-target Boar readability, Greater rally edge cases, and independent Wildfire overlap. Any adjustment should change only named `SPACE` constants and update geometry assertions; source chassis numbers must remain untouched.
