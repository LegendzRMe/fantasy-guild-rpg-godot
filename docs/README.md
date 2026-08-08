# Documentation Index

Start with [`architecture.md`](architecture.md) for module ownership, dependency direction, save invariants, and refactoring rules.

## Current contracts

- [`shared_combat_rules_v1.md`](shared_combat_rules_v1.md): commands, Basic Actions, targeting, projectiles, casts, and interruption rules.
- [`balance_principles_v1.md`](balance_principles_v1.md) and [`balance_simulator.md`](balance_simulator.md): numerical balance assumptions and developer tooling.
- [`performance_and_builds.md`](performance_and_builds.md): repeatable validation, code/asset metrics, profiling, export templates, and release builds.
- Focused reusable mechanics: ability charges, Ability Power, alternate action sets, Armor reduction, automatic ally resolution, background channels, Blind, shared Block charges, Combo Points, Evasion, Fear/Silence, health-loss cooldown conversion, Living Bomb lineage, named Shields, percentage-Health damage, periodic statuses, Protected/Invulnerable, Spirit Form, stealth/detection, and combat target categories.

## Class conversion specifications

- Guardian: [`guardian_hots_conversion_v1.md`](guardian_hots_conversion_v1.md)
- Cleric: [`cleric_li_li_conversion_v1.md`](cleric_li_li_conversion_v1.md)
- Ranger: [`ranger_valla_conversion_v1.md`](ranger_valla_conversion_v1.md)
- Mage: [`mage_hots_conversion_v1.md`](mage_hots_conversion_v1.md), with the earlier implementation delta retained in [`mage_kaelthas_conversion_v1.md`](mage_kaelthas_conversion_v1.md)
- Warlock: [`warlock_conversion_v1.md`](warlock_conversion_v1.md)
- Rogue: [`rogue_conversion_v1.md`](rogue_conversion_v1.md)
- Slayer: [`slayer_conversion_v1.md`](slayer_conversion_v1.md)
- Priest: [`priest_conversion_v1.md`](priest_conversion_v1.md), with provisional space values in [`priest_geometry_calibration.md`](priest_geometry_calibration.md)

Geometry calibration documents are development records for provisional combat-space values. They are not final visual specifications.

## Document lifecycle

- **Current contract:** behavior that code and tests are expected to preserve.
- **Conversion specification:** mechanics-first class design; names and presentation may remain provisional.
- **Calibration note:** measured or estimated tuning inputs that may change after playtesting.
- **Historical note:** retained context that has been superseded by a newer document; the newer document should link to it explicitly.

New documents should identify their lifecycle near the top and be added to this index.
