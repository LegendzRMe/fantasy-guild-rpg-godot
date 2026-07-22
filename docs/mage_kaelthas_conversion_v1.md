# Mage Kael'thas Conversion V1

This is the canonical implementation index for the Mage V1 conversion. The full source audit, chassis, formulas, kit behavior, Boss rules, provisional geometry, developer controls, and manual checks are recorded in [mage_hots_conversion_v1.md](mage_hots_conversion_v1.md). Focused shared-system contracts are in [ability_power_v1.md](ability_power_v1.md), [living_bomb_lineage_v1.md](living_bomb_lineage_v1.md), and [ability_geometry_calibration_v1.md](ability_geometry_calibration_v1.md).

## Stable IDs and actions

The class ID is `mage`; its Basic Action is the physical ranged `mage_basic_attack`. The five and only five player actions are `mage_trait` (D), `mage_q` (Q), `mage_w` (W), `mage_e` (E), and one selected Heroic through R (`mage_l15_r1` or `mage_l15_r2`). The Mage has no Mana or replacement resource.

Talent tiers unlock at Levels 9, 12, 15, 18, 21, 24, 27, and 30. The stable option IDs and working-reference names live only in `scripts/data/mage_data.gd`; combat and UI read that data rather than maintaining parallel talent lists.

## Encounter and Boss contracts

Convection lives in the Mage's encounter runtime, survives waves and same-encounter resurrection, and is reconstructed only when a new battle/run runtime is initialized. Qualifying contacts use tags and exclude scenery, objects, walls, harmless/trivial actors, noncombat actors, and non-opted-in summons.

Bosses are ordinary collision targets but resist Stun by default. A data-authored `control_profile` may opt a specific test or future Boss into reduced or full Stun. Gravity Crush is created only from the resolved successful-control result. Burned Flesh uses the explicit percentage-Health basis and the Boss coefficient, receives Armor/stage mitigation, and excludes Ability Power, Gravity Crush, and critical strikes.

## Limitations

All current art and effects are temporary. Public Blizzard sources did not safely expose exact geometry, so all spatial conversions remain centralized, configurable estimates. Rebirth relocation path damage is disabled pending reliable live verification. The implementation does not add Mana, ability AI, final identity/art/audio, new item balance, another action slot, or another class conversion.
