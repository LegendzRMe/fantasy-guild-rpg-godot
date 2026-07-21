# Cleric Li Li Conversion V1

This is a mechanical prototype conversion. Li Li and the current ability/talent names are temporary working references; final identity, art, icons, audio, weapons, lore, and balance are out of scope.

## Stable IDs and chassis

The class ID is `cleric`. The repeating contextual action is `cleric_basic_action`; D/Q/W/E are `cleric_trait`, `cleric_q`, `cleric_w`, and `cleric_e`; runtime Heroics are `cleric_r1` and `cleric_r2`. Talent selections use `cleric_l9_*` through `cleric_l30_*`, including `cleric_l15_r1/r2` and matching `cleric_l27_r1/r2` upgrades.

Level 1 values:

- Health: 1500; regeneration: 3.125 per second; Armor: 0.
- Power and offensive Basic Attack: 60.
- Basic Action interval: 0.8 seconds (1.25 actions per second).
- Basic Heal: 60, using the same Power/equipment pipeline.
- Ranged Basic Action range: 220; movement speed: 150.

Health, Power, Basic Attacks, Basic Heals, ability damage, and ability healing use four-percent exponential level scaling: `level_one_value * 1.04^(level - 1)`. Current Power, equipment, and temporary Spell Power are reflected by roster detail values.

## Contextual Basic Action and Fast Feet

An enemy assignment repeats physical Basic Attacks; an ally assignment repeats Basic Heals. The assignment remains until the player moves, retargets, or the target becomes invalid. A full-Health ally remains assigned and produces overhealing; the Cleric never switches healing targets automatically.

Fast Feet is D's baseline passive. Positive hostile damage to Health or Shields grants 10% movement and 1.5x Q/W/E cooldown recovery for one second. Reapplication refreshes rather than stacks. Blind misses and zero damage do not trigger it. Heroic, item, passive, and encounter timers remain unaffected.

## Base abilities

- Q — Healing Brew (4 seconds): automatically heals the lowest-percentage wounded ally in range for 210. Self is valid. Ties resolve by percentage, distance, then stable combat ID. No target means no cooldown.
- W — Cloud Serpent (11 seconds): attaches to a manually selected ally or self for 8 seconds. Once per second, if an enemy exists, it deals 26 to the nearest enemy and heals its host for 20. One Serpent can occupy a host; recasting refreshes/replaces it.
- E — Blinding Wind (12 seconds): selects up to two nearest distinct enemies, deals 133, Slows 15% for 1.5 seconds, and requests 1.5 seconds of shared Blind. Boss damage, Slow, and Blind resolve independently.
- R1 — Jug of Healing: channels up to 6 seconds and every 0.25 seconds heals the lowest-percentage nearby ally for 75. Its resulting cooldown is 20 seconds plus 2 per completed tick, capped at 70. Movement, true control, or R cancellation ends it; ordinary damage does not.
- R2 — Water Dragon (50 seconds): requires an enemy, prepares for 2 seconds, then damages the nearest primary and nearby enemies for 300 and requests a 70% Slow for 4 seconds. Pre-release movement/control uses the shared 10-second interrupted-Heroic cooldown.

Automatic selections are deterministic. Q/Jug use Health percentage, distance, and stable ID; E and Water Dragon use distance and stable ID. The testing overlay exposes Fast Feet cooldown rates, while lightweight class telemetry is enabled only for testing actors.

## Talent tiers

The project uses the approved swapped tier order: Level 9, 12, Heroic at 15, then 18, 21, 24, matching Heroic upgrade at 27, and capstone at 30.

- Level 9: Free Drinks (Q reduction below 50%); Serpent Sidekick (W rate +0.75 during Fast Feet); Eager Adventurer (Fast Feet 2.5 seconds).
- Level 12: Surging Winds (two E targets, E reduction and 10% Spell Power); Safety Sprint (D self activation, movement/Armor); Let's Go! (D other-ally heal, cleanse, and Unstoppable).
- Level 15: Jug of Healing or Water Dragon.
- Level 18: Good Stuff (locked-at-application HoT); Wind Serpent (host movement and 0.75 attack cadence); Mass Vortex (three targets and 75% damage when all three are distinct).
- Level 21: Lightning Serpent (two distinct bounces and host healing); Gale Force (longer Blind and doubled offensive Basic Attack against blinded targets); Hindering Winds (30% Slow for 2 seconds).
- Level 24: Two For One (two Q targets, 5-second cooldown); Pick Me Up (33% Q bonus below 50%); Blessings of Yu'lon (host healing received and max-Health sustain).
- Level 27: Jug heals two distinct allies per tick, or Double Dragon adds a second automatic impact after 0.5 seconds. Only the matching selected Heroic upgrade is legal.
- Level 30: Mistweaver attaches a 149 nearby heal pulse and 30-second readiness to Q; Shake It Off gives W two independently recovering charges and conditional 35 Armor; Kung Fu Hustle raises Fast Feet Q/W/E recovery to 3x.

The exact cooldown rates are 1.0 normal, 1.5 baseline Fast Feet, 2.25 W with Serpent Sidekick, 3.0 with Kung Fu Hustle, and 3.75 for their W combination. Direct reductions remain separate. Pause freezes all of these simulation timers.

## D and action-bar rule

D remains passive Fast Feet unless the chosen Level 12 talent supplies one activated behavior. Safety Sprint and Let's Go! are mutually exclusive and share D. Mistweaver is attached to Q; Shake It Off and Kung Fu Hustle are passive. The combat interface never expands beyond D/Q/W/E and the one selected R.

## Ownership and configuration

`cleric_data.gd` owns values, IDs, working names, and talent definitions. `cleric_system.gd` owns deterministic targeting, runtime state, rate math, charges, and lightweight telemetry. `cleric_runtime.gd` owns live ability effects and delegates damage, healing, Blind, Unstoppable, commands, and projectiles to shared systems. `cleric_ability_presenter.gd` owns detailed roster text.

## Manual playtest checklist

- Compare enemy/ally Basic Action assignment and a full-Health persistent heal target.
- Verify Q selection with multiple wounded percentages and self-target eligibility.
- Test W with no enemy, refresh, two hosts, movement bonuses, bounces, and charges.
- Test E against one/two/three enemies, default immune Boss, and half-duration Boss.
- Confirm Fast Feet rates after Health and Shield damage, plus D variants.
- Interrupt/cancel Jug and Water Dragon, and verify command restoration.
- Exercise both Heroics, matching upgrades, every tier, and all Level 30 capstones.

Known prototype limitations: presentation uses temporary circles/text; advanced telemetry is intentionally lightweight; final balance and final names require playtesting; autonomous player ability use remains prohibited.
