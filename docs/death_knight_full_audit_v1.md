# Death Knight V1 full audit

Lifecycle: **implementation audit and acceptance record**.

## Coverage matrix

| Area | Audited intent | Automated evidence |
| --- | --- | --- |
| Chassis | 2100 Health, proportional 4.3752 regeneration, 95 / 1.1s / 2-range Basic Attack, 0 Armor, no Mana, Threat 1, Plate Melee DPS | system test and class registration |
| Frostmourne | immediate primary attack, independent scaling packet, cooldown-on-consumption, standard-kill versus priority-hit progression, exclusions, encounter scope | deterministic and live tests |
| Death Coil | hostile damage, explicit manual self-cast, Immortal Coil, Deathlord, Frost Presence Slow, Dominion pre-control snapshot | deterministic and live tests |
| Howling Blast | clamped ground cast, path/final double contact, per-cast unique quest credit, Root, Shattered ordering, Icebound, Deathchill, Dominion refresh | deterministic helpers and live cast test |
| Frozen Tempest | delayed first tick, one-second cadence, per-source suppression and linger, lock lifecycle, Borean, Icy, Rune, Biting, Remorseless, Eternal | deterministic and live tests |
| Frost Presence | encounter scope, five-contact cap, Shared Legacy multiplication, 15/30/50 rewards, member mastery persistence | deterministic test, save persistence hook |
| Defensive interactions | Rime successful-control trigger, strongest incoming reduction, Anti-Magic duration multiplier/Blind immunity | deterministic tests and shared damage pipeline |
| Army | six starting charges, consume-all, sequential recharge, death CDR, exact Ghoul chassis/lifetime/cadence, Legion doubling | deterministic and live tests |
| Sindragosa | line damage, Slow, Blind, cooldown, Absolute range/Root-before-Slow, Boss immunity profiles | live test and dedicated Range fixtures |
| Cross-class systems | strongest outgoing reduction, additive healing bonuses, strongest healing reductions, Shared Legacy, Warrior finite-summon targeting contract | focused shared-system tests plus existing regression suites |
| Persistence/UI | two testing fixtures, mastered member, victory persistence, roster presenter, talent presenter, action lock/charge HUD, debug telemetry, Range button | save/UI smoke tests and parser/startup validation |

## Interaction findings resolved

1. Frostmourne Feeds now consumes a pre-hit control snapshot, preventing Frost Strike's own Slow from incorrectly granting the one-second bonus reduction.
2. Death's Dominion uses the same pre-cast snapshot rule and refreshes only a still-active instance owned by that caster.
3. Death Coil self-cast is manual and spatial: clicking the Death Knight invokes healing; ordinary enemy targeting cannot accidentally reuse healer ally-selection state.
4. Frozen Tempest cooldown starts only on exit or defeat. Activation remains unlimited-duration and does not spend a conventional cooldown.
5. Tempest suppression is source-keyed so multiple Death Knights coexist without overwriting or additively stacking one source's ramp.
6. Shattered Armor extends existing controls before Howling applies its own Root/Stun/Slow package.
7. Frost Presence counts one target once per cast even if both path and final area hit it, while damage correctly resolves per contact region.
8. Weapon progression deliberately bypasses Shared Legacy; Frost Presence quest progress deliberately uses it.
9. Anti-Magic Shell changes incoming durations, not magnitudes, and its Blind immunity follows the shared control profile.
10. Army death reduction changes only an active sequential recharge timer; it never creates a charge from nothing or reduces all future charges.
11. Ghouls use the shared summon target category and original/remaining lifetime fields required by anti-summon mechanics; combat-ID lookup, owner-threat targeting, Basic Attacks, projectiles, charges, and Boss areas can all resolve them as entities.
12. Defeat forcibly exits Tempest and clears its temporary attack-speed, aura, suppression, and per-target ramp state.
13. The shared controlled-damage entry point previews whether control can apply, activates Rime before resolving damage, then commits the control; resisted controls therefore neither reduce the triggering packet nor activate Rime.

## Acceptance status

The audit requires clean dependency loading, full editor parse, imported-texture check, all deterministic and live UI tests, startup smoke, Windows export-pack creation, exported-pack startup, clean runtime log, UTF-8 hygiene, and repository hygiene. Release evidence is recorded in the draft PR after two consecutive complete `tools/validate.ps1` passes.

Remaining V1 calibration risk is limited to non-chassis geometry that the public structured source does not expose canonically. Those values are centralized and documented; no unresolved rules ambiguity is hidden in runtime code.
