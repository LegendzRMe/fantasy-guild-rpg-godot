# Spirit Weaver V1 geometry calibration

The conversion uses the established stack scalar `SOURCE_TO_WORLD = 185 / 5.5 = 33.63636...` pixels per source unit. Values are centralized in `SpiritWeaverData.SPACE`; runtime and previews consume those values rather than duplicating constants.

| Mechanic | Source units | Project units |
| --- | ---: | ---: |
| Combat radius | 0.75 | 25.23 |
| Melee Basic Attack | 1.5 | 50.45 |
| Basic Heal assignment | 6.5 | 218.64 |
| Basic Heal bounce | 4.5 | 151.36 |
| Ghost Wolf lunge | 2.25 | 75.68 |
| Chain Heal cast | 6.0 | 201.82 |
| Chain Heal bounce | 7.0 | 235.45 |
| Lightning Shield target | 8.0 | 269.09 |
| Lightning Shield radius | 2.5 | 84.09 |
| Earthbind cast | 6.0 | 201.82 |
| Earthbind radius | 2.5 | 84.09 |
| Purge target | 7.0 | 235.45 |
| Ancestral target | 6.0 | 201.82 |
| Bloodlust radius | 8.0 | 269.09 |
| Farseer area | 5.0 | 168.18 |

Stormcaller multiplies W radius by 1.25. Colossal Totem multiplies E radius and duration by 1.5. Gladiator's War Shout doubles Bloodlust radius and duration. Lunge and E use shared safe-endpoint/blocker handling; E placement and reposition reject invalid geometry, preserve authored battle bounds, and do not retrigger initial-placement Earthgrasp.

The `185 / 5.5` scalar is a project calibration rather than a value published by Blizzard. Heroes Tool Chest provides gameplay-unit values, while exact engine search ordering, footprint interaction, and several collision tolerances are not exposed as one portable canonical table. Those are the remaining geometry uncertainties and the reason every value is centralized.
