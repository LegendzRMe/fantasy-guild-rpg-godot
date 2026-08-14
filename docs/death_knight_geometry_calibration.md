# Death Knight geometry calibration

Lifecycle: **calibration note**.

Death Knight uses the shared ratio of 185 world pixels per 5.5 source units. Centralized source-space values are: Basic Attack 2, Death Coil 7, Howling Blast range 9 / final radius 2.5 / path half-width 1.25 / speed 16, Frozen Tempest radius 3.5, Frost Strike radius 2, Army death radius 13.5, Ghoul acquisition 7, Sindragosa range 20 / half-width 4, and Deathlord bounce range 8.

The 2-unit Basic Attack range and 1.1-second weapon period are directly verified in Heroes Tool Chest build `2.55.17.97771`. Army charge metadata and Ghoul chassis/cadence/lifetime are also directly extracted. Public normalized hero data does not expose one authoritative scalar for every spell effect, so non-chassis ranges and radii are provisional audited estimates. All are isolated in `DeathKnightData.SPACE`; visual playtesting should calibrate those constants without changing mechanic code.

Frost Presence multiplies the final radius by 1.20 whenever selected and the cast range by 1.20 after its first reward. Absolute Zero multiplies Sindragosa's range by two. Target collision radii are added by the runtime rather than baked into these authored spell values.

