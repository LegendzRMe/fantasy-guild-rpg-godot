# Warlock Conversion V1

Warlock V1 is a mechanics-first ranged damage class using Gul'dan as a temporary reference. Names and visuals are placeholders. The implementation is split into data, pure rules, runtime execution, and roster presentation so later identity work does not require rewriting combat coordination.

## Chassis

- Level 1 Health: 1700; regeneration: 3.54 per second; universal Armor: 0.
- Basic Attack: 60 Physical damage, one-second interval, 5.5 source-range equivalent.
- Health, damage, healing, and ordinary ability values use four-percent level scaling unless the centrally configured value explicitly differs.
- Warlock has no Mana or replacement resource. Life Tap on D is the class economy.

## Kit

- Q Fel Flame: three-second cooldown and a manually aimed expanding wave. One cast hits each target at most once.
- W Drain Life: twenty-second cooldown and a three-second hostile channel. It resolves independent damage and healing four times per second.
- E Corruption: twenty-eight-second cooldown and three sequential forward bursts. Each hit creates an independently timed six-second periodic stack, up to three per target.
- R Horrify: eighty-second cooldown, half-second warning, damage, Fear, and Silence.
- R Rain of Destruction: seventy-second cooldown, 1.5-second precast, seven-second persistent arena rain, seeded meteor warnings, and independent impacts.

All talents from Guild Levels 9 through 30 are defined in `warlock_data.gd`. Encounter quests are runtime state and therefore survive rooms and waves but reset with a new battle runtime.

## Sources and confidence

Base ability values and current identities come from Blizzard's official Gul'dan hero page. Recent changes use Blizzard's December 1 and December 12, 2025 patch notes and April 20, 2026 live notes. Geometry and cadence without official numeric publication remain centrally configurable and provisional; see `warlock_geometry_calibration.md`.

## Known calibration risks

Fel Flame width/travel, Corruption spacing, Rain meteor count/distribution, and forced Fear speed need hands-on comparison. No final balance claim is made. The dedicated Warlock Range exists specifically for those adjustments.
