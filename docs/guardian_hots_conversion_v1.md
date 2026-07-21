# Guardian HotS Conversion V1

## Purpose

Guardian V1 replaces the temporary Shield Wall/Challenge/Shield Rush/Last Bastion kit. Muradin is the mechanical reference only. Names in this document and data are temporary working metadata; final names, lore, art, audio, icons, and VFX remain postponed.

## IDs and source chassis

Stable IDs are `guardian_basic_attack`, `guardian_trait`, `guardian_q`, `guardian_w`, `guardian_e`, `guardian_r1`, and `guardian_r2`. Talent IDs use `guardian_l<guild level>_<option>` with `r1`/`r2` for Heroics and their upgrades.

Level 1 uses 2765 Health, 0 base Armor, 88 Basic Attack damage, 1.11 attacks per second, short melee range, and 135 project movement speed. Scalable values use:

`level_value = level_1_value × 1.04^(level - 1)`

Calculations remain floating point internally. `guardian_data.gd` owns source values and explicit Godot-space conversions.

## Base kit

- **Second Wind:** after four seconds without resolved damage, heals 55 per second, or 111 below 40% Health. Shield-absorbed damage is resolved damage and resets the delay. State lasts through waves in one battle and is discarded when the encounter runtime is rebuilt.
- **Storm Bolt:** 110 Physical damage, 1.25-second Stun, 10-second cooldown, moving line projectile. It can miss, hit destructible blockers, and uses shared line collision and control profiles. It preserves the Basic Action assignment.
- **Thunder Clap:** 96 Physical area damage, 30% Slow and Basic Action speed reduction for 2.5 seconds, eight-second cooldown. It preserves assignment.
- **Dwarf Toss:** valid ground leap, 59 landing damage, 30 Armor for two seconds, ten-second cooldown. A valid cast clears assignment and leaves Guardian idle; invalid casts do nothing and consume nothing.
- **Avatar:** 90-second cooldown, 20-second duration, +1000 scaled maximum/current Health, larger visible combat radius, unchanged navigation footprint, safe expiry, and no Taunt.
- **Haymaker:** 40-second cooldown and 319 Physical damage. Normal targets are displaced; Boss targets use universal mitigation and a short stagger without displacement.

## Storm Bolt encounter quest

Quest progress is stored in the Guardian encounter runtime. Slowed qualifying targets grant one stack on a Basic Attack, Stunned targets grant two, and targets dying within three seconds of a Storm Bolt marker grant five with no last-hit requirement. Training/non-qualifying targets are excluded by classification in authored data or runtime fallback.

At 45 stacks, Storm Bolt pierces one additional target and Basic Attacks reduce its cooldown by 0.5 seconds. At 160, range increases 50%, width doubles, and it pierces all valid targets. Progress survives waves because one battle keeps one runtime; the current prototype has no persistent multi-room dungeon runtime, so room-to-room persistence is a documented limitation.

## Talent tree

| Guild level | Option 1 | Option 2 | Option 3 |
|---|---|---|---|
| 9 | Dwarf Block | Third Wind | Give 'em the Axe! |
| 12 | Sledgehammer | Reverberation | Thunder Burn |
| 15 | Avatar | Haymaker | — |
| 18 | Perfect Storm | Heavy Impact | Skullcracker |
| 21 | Bronzebeard Rage | Healing Static | Thunder Strike |
| 24 | Dwarf Launch | Stoneform | Imposing Presence |
| 27 | Unstoppable Force (Avatar only) | Grand Slam (Haymaker only) | — |
| 30 | Mountain King | Hardened Shield | Rewind |

Selection remains one option per tier. The shared talent system validates that a Level 27 upgrade matches the Level 15 Heroic. Rewind resets Q/W/E normal cooldowns only; it does not reset Heroics, items, or itself. In this prototype, charge restoration is separate from cooldown reset and Rewind does not restore spent charges.

## Armor, Block, controls, and classification

Equipment and temporary Armor enter `CombatSystem.strongest_armor`; the strongest applicable source wins. Dwarf Block stores up to three charges and contributes 75 Physical Armor to one qualifying hostile Physical Basic Attack. It is not added to equipment or Dwarf Toss Armor, and abilities do not consume it.

Guardian sends ordinary Stun, Slow, attack-speed, displacement, and stagger requests through the shared control profile. Bosses decide duration/magnitude resistance and displacement immunity there. Haymaker's Boss stagger is the explicit exception. Sledgehammer uses configurable target classifications with a safe non-Boss `non_heroic` fallback until all enemy definitions author classifications explicitly.

## Telemetry and testing range

Optional runtime telemetry records Storm Bolt casts/hits/misses, quest sources and milestone times, cooldown reductions, Thunder Clap target counts, Healing Static and Bronzebeard results, Block, temporary Armor, Dwarf Toss validity/assignment clearing, Avatar, Haymaker, Grand Slam, and capstone use. It is enabled for the testing save/range and lightweight elsewhere.

The shared testing range retains all prior heroes and dummies, adds a passive Boss-tagged control target, a projectile-blocking destructible wall, and uses existing debug shapes. Manual checks should cover projectile misses/walls, 45/160 milestones, one/many-target Thunder Clap, valid/invalid leaps, Block versus multiple Armor sources, Avatar size/expiry, Haymaker normal/Boss behavior, Heroic interruption, every talent tier, and all capstones.

Testing shortcuts: `F3` toggles the shared debug overlay, `F4` adds 45 quest stacks, `F5` swaps the selected Guardian Heroic, `F6` loads a representative legal test build, `F7` activates Stoneform when authored, and `F8` activates Rewind when authored.

## Known limitations and postponed work

- Final presentation, names, icons, art, race, weapons, audio, and polished VFX are intentionally absent.
- The current project has no persistent multi-room dungeon encounter object, so quest state currently persists through waves but not a scene-level room transition.
- Haymaker V1 displaces its chosen normal target; full launched-target collision chains and damageable-object targeting need a reusable physics target layer.
- Heroic pre-release interruption and multi-charge UI need the current instant-cast prototype to gain a general cast/charge presentation before they can be fully exercised manually.
- Stoneform, Hardened Shield, and Rewind have reusable runtime actions, but the current four-button action bar has no finalized extra-active input surface.
- Imposing Presence active/passive and full Grand Slam death-marker charge recovery remain data/system follow-ups; no Boss-specific code should be added when completing them.
- Numbers live in `guardian_data.gd` and should be tuned only after playtesting.
