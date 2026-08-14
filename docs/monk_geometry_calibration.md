# Monk geometry calibration

Lifecycle: provisional calibration note.

The conversion uses the audited 5.5 ranged baseline as the project's stable bridge: one source unit equals `185 / 5.5`, approximately 33.636 world units. The public normalized source document does not expose every search radius, so non-chassis space values remain centralized and provisional in `monk_data.gd`.

| Element | Source-space input | Initial world-space treatment |
| --- | ---: | ---: |
| Basic Attack range | 1.75 | 58.86 |
| Monk radius | 0.625 | 21.02 |
| Radiant Dash range | provisional 6.0 | 201.82 |
| Dash landing offset | provisional 0.9 | 30.27 |
| Breath radius | provisional 3.5 | 117.73 |
| Reach range multiplier | 2.0 | 117.73 active range |
| Trait ally search | provisional 6.0 | 201.82 |
| Ally placement | provisional 4.0 | 134.55 |
| Ally aura | provisional 4.5 | 151.36 |
| Palm / Seven-Sided | provisional 3.0 | 100.91 |

Dash and Ally placement use the shared blocker-safe endpoint helper. Equal-distance target selection breaks ties by combat ID; Seven-Sided first sorts highest current Health, then combat ID. Playtesting should inspect crowded Dash anchors, blocker edges, Misha/Ally overlap, Breath edges, aura entry/exit, and Seven-Sided target switching. Geometry changes must remain isolated to named `SPACE` constants and their assertions.
