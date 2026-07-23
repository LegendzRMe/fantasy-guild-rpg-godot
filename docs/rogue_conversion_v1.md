# Rogue Conversion V1

## Architecture

The Rogue is a no-Energy melee DPS class built around rapid Physical Basic Actions, owner-held Combo Points, Vanish, and a temporary Q/W/E opener set. Canonical IDs, tuning, talent definitions, and provisional geometry live in `scripts/data/rogue_data.gd`; pure state and calculations live in `scripts/systems/rogue_system.gd`; battlefield orchestration lives in `scripts/runtime/rogue_runtime.gd`; roster copy lives in `scripts/data/rogue_ability_presenter.gd`.

Reusable mechanics are intentionally separate: `combo_point_system.gd`, `alternate_action_set_system.gd`, `stealth_detection_system.gd`, and `armor_reduction_system.gd`. Runtime state is encounter-scoped and is not written to guild saves. Selected talents and the selected Heroic continue to use the existing save contract.

## Source audit (July 23, 2026)

| Mechanic | Current live reference | Official source | Confidence | Fantasy Guild RPG conversion |
| --- | --- | --- | --- | --- |
| Chassis | 2,129 Health; 4.4354 regeneration; 82 attack; 2 attacks/sec; melee | [Valeera hero page](https://heroes-site-production-eks-prod-use1-01.heroesofthestorm.blizzard.com/en-gb/heroes/valeera/) and live data reflected by the page | High | Exact values, 4% project scaling |
| Vanish | 8 sec; Stealth, movement, opener replacement and prepared teleport | [December 2017 rework](https://news.blizzard.com/en-us/article/21307436/heroes-of-the-storm-patch-notes-december-12-2017) | High | Exact structure; no Energy |
| Sinister Strike | 110 damage, 5 sec base cooldown; live hit behavior drives a very short cooldown | [January 2021 notes](https://news.blizzard.com/en-us/article/23591147/heroes-of-the-storm-balance-patch-notes-january-19-2021) | High | Modified: a hit subtracts 1 sec from remaining cooldown; Relentless subtracts 1 more |
| Slice and Dice | Three releases or 3 sec with 400% Attack Speed wording | [September 2025 rework](https://news.blizzard.com/en-us/article/24229032/heroes-of-the-storm-live-patch-notes-september-30-2025) | High | Modified only to remove Energy; interpreted as +400%, or 5x rate |
| Ambush and talents | Armor reduction and modern talent interactions | [January 2018 notes](https://news.blizzard.com/en-us/article/21464985/heroes-of-the-storm-patch-notes-january-24-2018), [July 2019 notes](https://news.blizzard.com/en-us/article/23057727/heroes-of-the-storm-balance-patch-notes-july-10-2019) | High | Armor reduction scales and uses strongest-source rules |
| Reveal/Stealth fixes | Modern Reveal interactions | [November 2023 notes](https://news.blizzard.com/en-us/article/24031812/heroes-of-the-storm-patch-notes-november-16-2023) | Medium | Shared deterministic concealment/detection contract |
| Smoke Bomb | 5 sec; live versions include defensive Armor | [January 2021 notes](https://news.blizzard.com/en-us/article/23591147/heroes-of-the-storm-balance-patch-notes-january-19-2021) | High | Modified: no Armor; direct selection blocked, area/collision damage allowed |
| Cloak of Shadows | DoT removal, Unstoppable, defensive Armor | [Valeera hero page](https://heroes-site-production-eks-prod-use1-01.heroesofthestorm.blizzard.com/en-gb/heroes/valeera/) | High | Modified to level-scaled universal Armor under the project formula |
| July 2026 checkpoint | No later Valeera balance changes | [July 20, 2026 live notes](https://news.blizzard.com/en-us/article/24291432/heroes-of-the-storm-live-patch-notes-july-20-2026) | High | No correction required |
| Exact spatial geometry | Not fully exposed by public pages | Official pages above | Low/medium | Provisional, centralized, and documented in `rogue_geometry_calibration.md` |

Locked project rules override source behavior: no Energy, no poison buttons, no Thistle Tea, fixed Sinister Strike cooldown reductions, no Smoke Bomb Armor, and universal rather than Spell Armor for Cloak.

## Chassis and scaling

Level 1 uses 2,129 Health, 4.4354 Health regeneration/sec, 82 Power and Physical Basic Attack damage, 0.5-sec Basic Action interval, zero Armor, leather armor family, dual-wield/one-handed proficiency, and standard 150 movement. Normal authored values scale by `1.04^(level - 1)` exactly once. Level 30 sanity values are 6,639.61 Health, 13.8325 regeneration/sec, and 255.729 Power.

## Actions and event order

- Basic Action: fast melee Physical attack. Hemorrhage is owner-specific; Double Strike rolls only after an original successful hit; Rupture refreshes cadence without creating an immediate tick; Slice and Dice consumes one accelerated release even when Blind makes it deal zero.
- D, Vanish: state-only and assignment-preserving. It grants +20% movement (+40% with Elusiveness), one second of Unrevealable/unit passing, Invisible after 1.5 stationary seconds, and prepared double-range teleport openers after 3 seconds (1.5 with Subtlety).
- Q, Sinister Strike: manually aimed assignment-clearing dash. Validate geometry, start 5-sec cooldown, resolve the first valid collision, then reduce remaining cooldown and grant points only after a successful hit.
- W, Blade Flurry: assignment-preserving area attack. All damage resolves before one baseline point (two with Blade Fury) and before per-target Fatal Finesse progress.
- E, Eviscerate: assignment-preserving melee finisher. Validate, snapshot up to three points, damage, apply point-used effects, determine consumption, grant Combat Readiness from consumed points only, update UI, and start cooldown. Events expose both `combo_points_used_for_scaling` and `combo_points_consumed`.
- Stealth Q/W/E: Ambush, Cheap Shot, and Garrote. A valid opener optionally teleports, resolves damage/statuses, grants points, exits Vanish, and restores the normal action set. Invalid attempts do none of those things.
- R1, Smoke Bomb: five-second caster-only zone that grants Invisible, Unrevealable, and unit passing without changing the action set. Direct attacks cannot newly select the Rogue; area and collision attacks remain valid.
- R2, Cloak of Shadows: immediately removes harmful damage-over-time records, grants shared Unstoppable and level-scaled 75 universal Armor for 1.5 sec, and does not break Vanish.

Ambush damage resolves before its reduction is applied. Armor reductions keep independent source records; only the strongest active value applies, equal values have deterministic ordering, and effective Armor cannot fall below zero. Cheap Shot requests Stun through the shared control profile and schedules Blind after the actual resolved Stun duration. Garrote is an owner/cast/target-scoped seven-tick periodic record; multiple Rogues remain independent.

## Talent table

| Guild level | Options |
| ---: | --- |
| 9 | Combat Readiness — consumed points grant up to three Block charges; Subtlety — prepared teleport at 1.5 sec; Double Strike — 10% successful-original-Basic-Attack point proc |
| 12 | Relentless Strikes — one more second of Q cooldown reduction; Hemorrhage — +40% Basic Attack damage against this Rogue's Garrote; Initiative — openers grant two total points and +15% movement for 3 sec |
| 15 | Smoke Bomb or Cloak of Shadows |
| 18 | Mutilate — +125% Q damage with one source-unit less range; Fatal Finesse — +6 scaled W damage per qualifying encounter target, max 15; Slice and Dice — three accelerated attacks or 3 sec |
| 21 | Death From Above — teleporting Ambush reduces Vanish cooldown 4 sec; Blind — +2.5 sec; Strangle — external healing x0.60 while this Rogue's Garrote persists |
| 24 | Seal Fate — controlled target gives +50% Q damage and two total points; Assassinate — isolated Ambush +50% and 10-sec reduction; Blade Fury — W gives two total points at three successful targets |
| 27 | Adrenaline Rush for selected Smoke Bomb — first valid Eviscerate per cloud is free; Enveloping Shadows for selected Cloak — Vanish applies a source-tagged Cloak package |
| 30 | Rupture — double Garrote periodic damage and owner-specific refresh; Elusiveness — Vanish totals +40% movement; Vigor — five stored points while Eviscerate remains capped at three |

Removed source talents and all Energy effects are intentionally absent. The level-27 choice is constrained by the selected Heroic through the existing talent contract.

## Bosses, UI, and encounter lifetime

Boss control profiles determine resolved Stun, Blind, and Silence. Reduced controls remain valid for Seal Fate; fully resisted controls do not. Detector profiles may acquire Stealthed or Invisible targets in range, but Unrevealable always wins. Scripted mechanics are not interrupted unless the profile permits it.

Battle presentation shows three Combo Point pips (five with Vigor), Eviscerate unavailability at zero, transparent Stealth/Invisible state, the Smoke boundary, and compact status/debug information. The action bar remains D/Q/W/E/R; only Q/W/E swap while Vanished. No Energy widget or extra action button exists.

Combo Points survive target swaps, Vanish, waves, and rooms in one encounter. They reset on defeat and full encounter end. Fatal Finesse survives defeat inside the encounter but resets at encounter end. Smoke, Garrote, cooldown, and concealment state are runtime-only.

## Telemetry and test range

Testing-only telemetry is initialized for Combo Point gain/use/waste, concealment time and breaks, action-set swaps, attacks and abilities, Armor reduction, periodic effects, Heroics, and talent triggers. The Rogue Range supplies clustered enemies, armored targets, detector and non-detector Bosses, control profiles, healing fixtures, a summon, a non-qualifying target, a Defense Dummy, a wall, and six representative builds on Shift+1 through Shift+6. F3 toggles the shared debug overlay.

Test-only shortcuts: Alt+1 through Alt+5 set 0/1/2/3/5 Combo Points; Alt+V resets Vanish and all Rogue cooldowns; Alt+S and Alt+I force Stealth and Invisible; Alt+R applies Reveal; Alt+D toggles detector capability; Alt+P removes Rogue periodic statuses; Alt+F fills/resets Fatal Finesse; Alt+B grants three Block charges; Alt+M and Alt+C trigger Smoke/Cloak; Alt+T toggles Boss control profiles; Alt+H and Alt+J trigger external and self-healing fixtures. Normal battle controls are unchanged.

## Known limitations and manual checks

Temporary shapes, circles, transparency, pips, and text stand in for final art, sound, animation, and status icons. Public geometry is incomplete, so collision widths, stopping distance, opener range, and Smoke radius require manual feel calibration. The automated suite covers the reusable state contracts and class scaling; a four-hero interactive playthrough is still required to judge readability, action-set clarity, detection feedback, Smoke versus area attacks, accelerated attack recovery, isolation clarity, multi-debuff readability, and total attention load.
