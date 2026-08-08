# Ability Power V1

Raw Power and Ability Power are separate stats. Raw Power remains the scalable base used by ordinary formulas. `ability_power_percent` is an additive percentage applied afterward:

`final = raw_power_scaled_amount * (1 + total_ability_power_percent)`

`ability_power_system.gd` owns addition and final multiplication. `combat_system.gd` carries the stat through final-stat resolution so future items may declare `ability_power_percent` without Mage-specific item code. Class systems may contribute named temporary sources through `ability_power_sources`; Mage V1 combines item/base Ability Power, Fel Infusion, Arcane Dynamo, and Sunfire Enchantment.

Ability Power affects Mage Q, W ticks and explosion, E-generated normal damage if later added, Phoenix path/attack/splash, Pyroblast primary/splash, Sunfire damage, Fel Infusion healing, and ordinary talent-generated ability damage or healing. It does not affect Basic Attacks, Basic Heals, Shields, maximum Health, Armor, environment damage, generic item procs, or percentage-Health effects such as Burned Flesh.

Priest's Piercing Light contributes up to +10% encounter Ability Power. It affects ordinary Q/W/E output and eligible flat Heroic output, but not its Basic Attack, Pursued by Grace, Armor, Salvation's percentage healing, or percentage/damage-conversion values that would double-dip.

The modifier is locked at each resolution, not when an area is first previewed. A delayed effect therefore uses the Mage's current raw Power and Ability Power when it deals damage. Character Details displays persistent Ability Power; the test overlay displays total live Ability Power plus temporary source state. Optional telemetry time-weights the live total in test mode.
