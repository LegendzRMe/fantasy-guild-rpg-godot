# Druid geometry calibration

Druid uses the established conversion of `185 world pixels / 5.5 source units`, or approximately `33.63636` world pixels per source unit. Source hit tests include the target's authored combat radius where appropriate.

| Mechanic | Source-space target | Prototype world value | Calibration note |
|---|---:|---:|---|
| Basic Attack / mini-HoT recipient | 5.5 | 185.00 | Audited current Basic Attack range |
| Regrowth | 7.0 | 235.45 | Targeted ally cast; source/community geometry calibration |
| Moonfire cast | 8.0 | 269.09 | Ground cast clamp |
| Moonfire radius | 1.5 | 50.45 | Nature's Balance multiplies this by 1.75 per the project brief |
| Entangling Roots cast | 8.0 | 269.09 | Ground cast clamp |
| Roots initial radius | 1.0 | 33.64 | Expands continuously rather than jumping |
| Roots final radius | 3.0 | 100.91 | Reached after the authored 3-second growth |
| Tranquility | 5.5 | 185.00 | Follows the Druid while active |
| Twilight Dream | 5.0 | 168.18 | Centered on the caster at resolution |
| Astral Communion | 7.2 | 242.18 | Teleport clamp before its free Moonfire |
| Treant attack | 1.0 | 33.64 | Lightweight summon melee reach |

The source data directly exposes Basic Attack range but does not provide every cast radius in one stable machine-readable field. Regrowth, Moonfire, Roots, Tranquility, Twilight, and Astral values are explicit prototype interpretations cross-checked against current ability/talent data and community geometry references. They are not claimed as pixel-perfect source measurements.

All values live in `DruidData.SPACE`. Visual playtesting should focus on Moonfire's baseline radius, Roots' initial/final silhouette, whether target combat radii make the cluster too forgiving, and Astral Communion's teleport reach. Changing these constants must keep effects, targeting previews, hit tests, and documentation synchronized.
