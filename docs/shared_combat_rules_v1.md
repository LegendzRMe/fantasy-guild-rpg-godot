# Shared Combat Rules v1

This layer makes the current dictionary-based combat prototype predictable without redesigning class kits or replacing the scene architecture.

## Runtime flow

`battle_setup.gd` creates heroes and enemies with stable combat IDs and explicit command/Basic Action state. Player drag input assigns an attack, heal, or move command. `shared_combat_runtime.gd` validates stable targets, resolves pursuit and line of sight, advances wind-up/recovery timers, and releases melee damage, healing, or a physical projectile. Focused runtime layers then own item/combat resolution, enemy encounters, temporary abilities, and combat input; `combat_runtime.gd` only coordinates the live update. `combat_presentation.gd` draws the shared blockers, projectiles, wind-up feedback, downed markers, and optional debug overlay.

## Commands and Basic Actions

Player heroes use `IDLE`, `MOVE`, `ATTACK`, `HEAL`, `CAST`, `CHANNEL`, and `INCAPACITATED`. An assignment stores a stable target ID and kind. Movement immediately clears the assignment and cancels only an unreleased wind-up. A released action enters recovery and keeps its original next-ready time even if the unit moves or is hit.

Idle self-defense only looks inside `IDLE_MELEE_DEFENSE_RADIUS`. It never chases outside that radius and never casts an ability. Clerics do not automatically select a wounded ally; a player-assigned ally remains selected at full Health and produces only overhealing until Health is missing.

## Geometry and projectiles

Rectangular blockers independently flag movement, line of sight, and projectiles. An established assignment is cancelled when sight is broken. A newly issued blocked assignment probes nearby positions for a reachable range-and-sight angle, then fails cleanly after the path timeout. Straight physical projectiles remain in world space and test every travelled segment, so a newly created wall can block an arrow already in flight. Destructible blockers receive configured obstacle damage.

## Tuning

All v1 constants live in `scripts/combat/combat_rules_v1.gd`:

- `IDLE_MELEE_DEFENSE_RADIUS = 72`
- `RANGE_TOLERANCE = 8`
- `PATH_FAILURE_TIMEOUT = 1.25`
- `HEROIC_INTERRUPT_COOLDOWN = 10`
- `DEFAULT_BASIC_ACTION_WINDUP_RATIO = 0.30`
- `DEFAULT_HIT_NUDGE_DISTANCE = 5`
- `DEFAULT_PROJECTILE_SPEED = 560`
- `LINE_OF_SIGHT_PROBE_SPACING = 32`
- `DEBUG_COMBAT_OVERLAY_ENABLED = false`

Press F3 in the testing range to display the selected hero's combat ID, command, assignment, Basic Action phase/timer, next-ready time, range/LOS state, cast/channel, and incapacitation state. Blocker flags are shown there as well.

## Test range

The existing testing-save World Map entry now opens the requested shared-rules range with Guardian, Cleric, Ranger, and Mage when available. It includes a passive melee test unit, an aggressive Raider, an Archer, ordinary and durable dummies, a solid pillar, a destructible projectile wall, and a deliberately injured ally.

## Acceptance matrix

Status meanings: **Automated** is directly asserted by headless tests; **Covered** is exercised by the existing runtime smoke test or follows the same tested shared path; **Manual** still needs an in-editor visual playtest.

| # | Check | Result |
|---:|---|---|
| 1 | Assigned melee pursuit and attack | Covered |
| 2 | Ranged stop near maximum range | Covered |
| 3 | Assigned target retreat causes pursuit | Covered |
| 4 | Ranged hero does not auto-kite | Covered |
| 5 | Movement clears target, moves, then idles | Automated |
| 6 | Dead target clears without reacquisition | Covered |
| 7 | Idle enemy in defense radius is attacked | Covered |
| 8 | Self-defense stops outside radius | Covered |
| 9 | Prefer attacker, otherwise closest | Covered |
| 10 | Distant ranged attack causes no retaliation | Covered |
| 11 | Explicit commands override self-defense | Covered |
| 12 | Assigned Cleric follows and heals | Covered |
| 13 | Full-Health target remains assigned; effective healing is zero | Automated |
| 14 | Cleric self-target | Covered |
| 15 | Cleric movement clears healing assignment | Automated |
| 16 | Movement during wind-up cancels release | Automated |
| 17 | Movement after release preserves ready time | Automated |
| 18 | Repeated movement cannot speed Basic Actions | Automated |
| 19 | Ordinary damage does not cancel wind-up | Covered |
| 20 | Small nudge does not cancel wind-up | Covered |
| 21 | Instant ability preserves assignment | Covered |
| 22 | Invalid preserved target restores to idle | Covered |
| 23 | Movement interrupts unfinished cast | Covered |
| 24 | Interrupted Basic pre-cast has no full cooldown | Covered |
| 25 | Interrupted Heroic pre-cast receives ten seconds | Covered |
| 26 | Interrupted channel keeps full cooldown and stops future time | Covered |
| 27 | Ordinary damage does not interrupt cast | Covered |
| 28 | New wall breaks an established assignment | Covered |
| 29 | New blocked command seeks range plus sight | Covered |
| 30 | Removed wall does not restore cancelled assignment | Covered |
| 31 | LOS loss before heal/cast release prevents the effect | Covered |
| 32 | New wall blocks an arrow already in flight | Automated |
| 33 | Destructible wall receives projectile damage | Covered |
| 34 | Healing resolves at release and uses a cosmetic pulse | Covered |
| 35 | Repeated damage nudges accumulate | Covered |
| 36 | Cosmetic nudge does not interrupt casts | Covered |
| 37 | Nudge cannot cross solid obstacle | Automated |
| 38 | Nudge remains inside arena bounds | Automated |
| 39 | Zero-Health hero becomes incapacitated | Automated |
| 40 | Victory permits and records a downed hero without reward penalty | Covered; Manual visual check |
| 41 | Full-party incapacitation reaches current defeat flow | Covered |
| 42 | Pause freezes simulation, projectiles, timers, and effects | Covered; Manual visual check |

Run `tools/validate.ps1` for parser, automated, startup, runtime-log, and whitespace checks. Visual feel—especially stopping distance, wind-up readability, firing-angle movement, and downed/victory presentation—should still be evaluated in the Godot test range before merging.

## Known v1 limitations

- Current temporary class abilities remain instant. The reusable pre-cast/channel hooks are present for rebuilt classes, but this task does not invent cast times for the temporary kits.
- Firing-angle movement uses small deterministic probes rather than full dynamic navigation.
- Straight projectiles use their release destination; homing, piercing, bouncing, returning, and advanced unit collision remain future extensions.
- Independent story allies preserve their existing lightweight autonomy; the no-auto-battler rule applies to player-controlled party heroes.
