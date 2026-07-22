# Ability Geometry Calibration V1

Blizzard's public Kael'thas page and official balance notes expose ability behavior and many numerical values but not dependable world radii, collision widths, or projectile velocities. No available screenshot provided a trustworthy pixel-to-game-unit measurement. Geometry is therefore a provisional playtest layer, not a claimed extraction.

The shared conversion is `SOURCE_TO_WORLD = 185 / 5.5`, preserving the known Basic Attack reference as 185 prototype world units. `MageData.SPACE` exposes every estimate:

- Flamestrike: 9.5 source-unit cast range; 2.0 normal and 3.0 empowered radius.
- Living Bomb: 5.5 cast range and 3.0 explosion/spread radius.
- Gravity Lapse: 10.0 range, 1.0 width, and 14.0 source units per second.
- Phoenix: 10.0 cast range, 12.0 travel speed, 1.5 path width, 8.0 attack radius, and 2.0 splash radius. Cadence is separately configurable in `MageData.VALUES`.
- Pyroblast: 10.5 cast range, 4.0 travel speed, and 3.0 splash radius.

Nether Roil, empowered Flamestrike, Fission Bomb, Flamethrower, and Presence of Mind derive from these bases rather than duplicating absolute geometry. `F3` draws the relevant ranges in the test area. Rebirth relocation uses the same Phoenix movement speed, validates battle bounds and blockers before consuming a charge, pauses attacks while moving, and currently repeats no path damage because that live detail was unsafe to infer.

Confidence is high for behavior and documented multipliers, medium for relative shape, and low for absolute spatial calibration. Playtests should tune the centralized values without changing runtime algorithms.
