# Warrior V1 full-system audit

Audit date: 2026-08-13 (America/Toronto)

Lifecycle: **current implementation audit and regression contract**.

This audit traces Warrior from source values and class registration through Basic Attack packet order, all four combat inputs, all 23 talents, three encounter quests, specialization role changes, shared combat systems, save migration, roster presentation, Testing Range controls, startup, and export. Every approved talent ID is registered exactly once; the three Guild-27 upgrades are explicitly gated to their matching specialization.

## Source result

Heroes Tool Chest `heroes-data2` release `v2.55.17.97771` is the newest available data snapshot. The extracted `Varian` object is byte-for-byte identical after normalized JSON serialization to `v2.55.17.97650`, so the implemented anchors remain 2220 Health, 4.625 regeneration, 74 Basic Attack damage, 0.8-second period, 1.25 range, and 4% scaling. Blizzard's current hero page remains stale at 2-second Heroic Strike reduction and 160/-20 Colossus values; Blizzard's March 29, 2022 notes establish the later 3-second, 185, and -25 values used here.

## Findings fixed during this audit

- Warrior Range build switching now removes Warrior-owned Protected, Banner, healing, Armor, and quest-multiplier effects. A prior Shield Wall build can no longer make baseline Parry block Ability damage.
- Shattering Throw's Basic Attack passive snapshots whether the target was Shielded at primary contact. It now applies its shield-only bonus when the primary packet breaks the remaining Shield and never spills unused bonus into Health.
- Banner entry and exit are exact: Stormwind/Dalaran effects and Ironforge Armor are removed immediately outside the aura rather than lingering for a refresh grace frame.
- Demoralizing Shout now filters through the shared immediate-combat target categories while retaining Boss eligibility and snapshot duration.
- Shared Legacy now feeds the common numeric quest-progress modifier into Warrior, Guardian, Ranger, Slayer, Templar, Sentinel, Huntsman, Druid, and Shaman combat-talent progression. Shaman encounter progress and character-persistent mastery receive the same multiplied numeric event; overlapping sources remain strongest-only 2x.

## Ability and talent coverage matrix

| Mechanic | Intended interaction | Executable coverage |
|---|---|---|
| Chassis | Melee DPS, Plate, no Mana, 0 Armor, Threat 1.0, exact 4% scaling | Data and system tests |
| Heroic Strike | Separate 125 packet; success CDR 3, Twin total 7; Blind/Evasion consume without success CDR | Unit and live damage tests |
| Lion's Fang | Line damage/Slow; per-contact normal/Boss healing; category exclusions and scaling | Unit plan plus live multi-contact test |
| Parry | Two sequential charges; Basic Attacks prevented, abilities unaffected | Charge/timer unit test and live damage test |
| Charge | Hostile damage/Slow, safe landing, 12 seconds | Live runtime test |
| Lion's Maw | Unique quest contacts, five-per-cast cap, +7 to +175, completion Slow, encounter reset | Unit quest tests |
| Overpower | Parry refresh/re-arm, one unstacked +40% Heroic Strike | Repeated-contact and consume tests |
| High King's Quest | Weapon 50, Honors 5, Endurance 15; category/window rules; +10/+10/+10/+30 ordering | Independent unit progression and specialization-order tests |
| Taunt | Tank role, Threat 1.5, no Health, +healing, positive-Armor-only effectiveness, Boss force/Silence | Unit modifiers plus live Boss test |
| Colossus Smash | DPS role, 185, scaled -25 Armor/3 seconds, x2 Basic Attack, -10% Health, stable reset | Unit specialization/stacking plus live Master at Arms test |
| Twin Blades | Passive R, 0.4-second attacks, x0.75 Basic Attack, 7-second CDR, movement | Unit and live passive/movement tests |
| Lionheart | Boss 245, summon 35, normal unchanged, Endurance still one per cast | Unit contact tests |
| Second Wind | 1% current max Health only on successful Heroic Strike; normal modifiers; Endurance excluded | Unit and live packet tests |
| Victory Rush | 350 scaled, next successful primary, 30 seconds, nearby-death -10, Endurance +1 | Unit and live healing-hook tests |
| Shield Wall | One charge/5 seconds, Protected all damage, contact still drives Overpower/Vigilance | Unit and live Protected tests |
| Warbringer | Same E slot, allied landing, 4 seconds, no ally damage/Slow | Live allied-Charge test |
| Juggernaut | Q/E summon-only 4% max Health and 4% original finite lifetime; permanent/short/Boss cases | Unit boundaries and live Q test |
| Mortal Strike | Successful Heroic Strike, source-aware strongest -40% for 4 seconds, shared healing pipeline | Unit stacking/expiry and live Boss application |
| Shattering Throw | D active, 30 seconds, 50 normal +1400 shield-only; Basic Attack shield-only passive | Unit and live active/passive tests |
| Three Banners | Immediate automatic 12/25 cadence; self/ally range; Stormwind, scaled Ironforge, Dalaran AP | Unit cadence and live aura tests |
| Vigilance / Master at Arms / Frenzy | Matching-specialization gates; BA-contact CDR; area Smash; +25% Heroic Strike/+40% move | Tree contract, unit, and live tests |
| Glory / Demoralizing / Shared Legacy | Regen/healing aura; five-second enemy snapshot; first-eight-second 2x quest progress | Unit strongest-source and live entry/exit/snapshot tests |

## Cross-class and lifecycle checks

- Taunt combines additively with Glory healing and multiplicatively with positive Ironforge Armor, while negative Armor is unchanged.
- High King's flat Level-1 reward is added before Colossus or Twin Basic Attack multipliers; Heroic Strike stays separate.
- Colossus and Huntsman Armor reductions share one strongest-source pool.
- Shared Legacy multiplies registered progress amounts, not kills, loot, rewards, XP, story, or campaign state.
- Warrior remains testing-only. Save migration inserts one fixture without changing starter, recruitment, or campaign availability.

## Remaining uncertainty

No known deterministic mechanics defect remains. Lion's Fang width/speed and several non-chassis radii are centralized calibration values because the public extracted hero object does not expose every behavior as a single scalar. Four-hero Banner positioning and the approved Twin/High-King, Taunt/Glory, and automatic-Banner combinations remain balance questions for telemetry, not correctness exceptions.

The native Windows pass reached Warrior Range, displayed telemetry, and loaded builds 1-4 before computer control was stopped. Builds 5-6 and every interaction are covered by the live Godot UI/runtime suite; additional subjective feel testing remains useful and is not represented as completed manual playtesting.

## Sources

- [Heroes Tool Chest release v2.55.17.97771](https://github.com/HeroesToolChest/heroes-data2/releases/tag/v2.55.17.97771)
- [Blizzard Varian hero page](https://heroes-site-production-eks-prod-use1-01.heroesofthestorm.blizzard.com/en-us/heroes/varian/)
- [Blizzard balance notes, March 29, 2022](https://news.blizzard.com/en-us/article/23787368/heroes-of-the-storm-balance-patch-notes-march-29-2022)
