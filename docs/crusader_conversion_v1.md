# Crusader conversion v1

## Scope and source audit

Crusader is a testing-only, mechanics-first conversion of current Johanna into Fantasy Guild RPG's AoE Tank. The implementation is based on HeroesToolChest `heroes-data2` build **2.55.17.97771**, reconciled with Blizzard's **July 20, 2026** live notes. The live-note changes used here are Shield Glare's 13-second cooldown and Blessed Shield's 65-second cooldown. The normalized build provides the authoritative current chassis, damage, duration, and cooldown records. It does not expose dependable cast-shape polygons, so geometry is source-calibrated and centralized separately.

Source chassis at level 1: 2,625 Health, 5.4687 Health regeneration/sec, 99 Basic Attack damage, 1.1-second Basic Attack interval, 1.5 source-unit Basic Attack range, 0.75 source-unit radius, and 4.8398 source-unit movement speed. Project identity: Tank, 1.5 Threat modifier, no Mana or other resource, one-handed weapon plus shield.

The conversion uses the project's standard `value * 1.04^(level - 1)` scaling for flat Health, damage, healing, Shields, and Level-1 Armor values. Percentages and durations do not scale.

## Baseline kit

| Action | Implemented mechanics |
| --- | --- |
| Basic Attack | 99 physical damage every 1.1 seconds at source melee range. It is the primary attack used by Divine Fortress, Eternal Retaliation, and Sins Exposed. |
| Q — Punish | 113 physical damage, 8-second cooldown, wide 160-degree frontal area, 50% Slow for two seconds that linearly decays. |
| W — Condemn | One-second mobile preparation, then 55 magical damage in a 5-source-unit radius, safe inward displacement, and 0.25-second Stun; 10-second cooldown. Control profiles and blockers decide displacement success. The source-only +200% Minion/Mercenary damage is deliberately removed. |
| E — Shield Glare | 59 magical damage and 1.5-second Blind in a long 35-degree cone; 13-second recharge. Uses the shared sequential charge system. Blind immunity does not prevent damage or count as a successful Blind for Blinding Authority. |
| D — Iron Skin | 810 Shield for four seconds and source-owned Unstoppable while that exact Shield exists; 22-second cooldown. The Shield is created before Unstoppable. Early depletion immediately removes only Iron Skin's Unstoppable. |

## Heroics

Falling Sword has a 50-second cooldown. Crusader becomes invulnerable/untargetable and airborne for two seconds, cancels her Basic Attack, cannot cast, remains player-steerable, ignores ground blockers, and grants source-owned Unstoppable to allies under the 4-source-unit aura. Landing deals 225 magical damage and applies a 0.25-second Stun when control succeeds. Current source data has no retained landing Slow.

Blessed Shield has a 65-second cooldown. It selects deterministically from aim, deals 114 damage and Stuns the first target for 1.5 seconds, then bounces twice for 57 damage and 0.75-second Stuns. Bounce selection is nearest-first with combat-ID tie-breaking.

## Talent conversion

| Guild tier | Choice | Mechanics |
| --- | --- | --- |
| 9 | Zealous Glare | Two E charges and +70% E damage. |
| 9 | Divine Fortress | Primary Basic Attacks grant 25 Level-1 Universal Armor for four seconds, stacking to 100; no Gambit/Loan Health. |
| 9 | Laws of Hope | D activation schedules 20% maximum-Health healing over five seconds; no extra action. |
| 12 | Subdue | Q hitting 2+ applies a non-decaying 70% Slow. One four-contact Q completes the binary encounter quest, empowering later single-target Qs. |
| 12 | Eternal Retaliation | W source-owns independent ten-second marks. A primary Basic Attack consumes only its target's mark for one second of W cooldown reduction; no Mana or execute. |
| 12 | Hold Your Ground | D Shield +40%; D cooldown -2 seconds. |
| 18 | Sins Exposed | Q applies -35% Healing Received for three seconds; primary Basic Attacks refresh the owner-scoped target effect. |
| 18 | Conviction | +10% movement normally, replaced by +20% during W preparation. |
| 18 | Steed Charge | No mount button. D starts two seconds longer. Each legitimate E cast while the D Shield exists adds two seconds once per cast, including zero-hit casts, with no arbitrary cap and no Shield restoration. |
| 21 | Roar | Q damage +50% at one contact, replaced by +150% at 2+ contacts. |
| 21 | Holy Fury | Passive 15 Level-1 magical damage/sec nearby. W contacts add +40% for five seconds, capped at five contacts (+200%, 45 base damage/sec). |
| 21 | Blinding Authority | Replaces Blessed Hammer. One E that successfully Blinds 3+ enemies immediately gives 4x final Crusader Threat against those exact targets for their Blind duration. The qualifying E damage packet benefits. |
| 24 | Shrinking Vacuum | W grants 5% incoming damage reduction per contact for four seconds, capped at 25%; this is not Armor. |
| 24 | Holy Renewal | E contacts reduce active E recharge by one second, or 1.5 seconds against this Crusader's unconsumed three-second Condemned tags from W; five-contact cap and no healing. |
| 24 | Blessed Momentum | Q contacts reduce D cooldown one second each, capped at five and never banked below ready. |
| 27 | Heaven's Fury | While airborne, eight 0.25-second barrages each damage up to three nearby enemies for 50 Level-1 damage and heal up to three nearby allied Heroes for 68 Level-1. Each successful enemy impact reduces Falling Sword cooldown one second, with no project-only aggregate cap. |
| 27 | Radiating Faith | Blessed Shield reaches five total targets and uses a 1.75-second Stun on every controllable target. |
| 30 | Indestructible | A fatal hostile packet instead creates a 100%-maximum-Health Shield for four seconds; 120-second ICD and no recursive trigger. |
| 30 | Blinded by the Light | A ready W resolution Shields nearby eligible allied Heroes for 25% of each recipient's own maximum Health for three seconds; 60-second ICD. E contacts remove eight seconds each, capped at 40 seconds. |
| 30 | Unbreakable Crusade | While D's Shield exists, successful Q/W/E damage restores 5% of its modified maximum per contact, capped at 25% per cast. It cannot overshield, resurrect a broken Shield, or extend time. |

## Interactions and ordering

The runtime plans contacts before resolving each damage packet. This lets Roar use the same-cast count, Blinding Authority affect the qualifying E, and Q/W/E restoration use only successful damage contacts. Zealous Glare plus Steed Charge permits two independent +2-second extensions. Holy Renewal plus Condemned accelerates further E availability without consuming the tag. Hold Your Ground increases both D's maximum and Unbreakable Crusade's restoration basis. Blessed Momentum speeds the next D but does not alter an existing Shield. Holy Fury refreshes its five-second contact snapshot on each W.

Bosses take normal ability damage and Threat. Their authored control profile can resist Slow duration, Blind, Stun, or displacement; the Crusader does not add a hidden boss penalty. Summons, temporary combat objects, and training objects follow the shared immediate-target category filter.

## Geometry

All geometry is in `CrusaderData.SPACE` and uses the established `185 / 5.5` source-to-world calibration. Current choices are: radius 0.75, melee range 1.5, Q radius 3.5 with 80-degree half-angle, W radius 5 with 1.5 pull stand-off, E range 12 with 17.5-degree half-angle, Falling Sword landing/allied aura radius 4, Blessed Shield initial range 10 and bounce range 8, and Holy Fury radius 3.5 (all before calibration).

The normalized source export does not carry reliable authored cone/bounce polygons. Q/E angles and several radii are therefore explicit source-calibrated project geometry, not claimed byte-exact source fields. Falling Sword is a self-cast airborne movement state, so it has no artificial initial cast-distance cap; steering is bounded only to the combat arena. These should receive manual feel testing.

## Shared systems and testing

Shared changes add source-owned Unstoppable, timed decaying control amounts, Crusader final-Threat multiplication, fatal-damage Shield interception, Iron Skin Shield synchronization, and airborne blocker traversal. Existing Armor, incoming-reduction, healing-received, Shield, Blind, control-profile, safe-placement, target-category, and `AbilitySlotSystem` foundations remain authoritative.

The testing save adds placeholder **Johanna**, level 30, without adding Crusader to recruitment, campaign progression, starter rosters, or story unlocks. Crusader Testing Range includes 1/2/3/4/5+ groups, standard/elite/named/Boss/training categories, Blind-immune, displacement-immune, Unstoppable, resistant, allied healing, and blocker fixtures. Four predefined builds exercise baseline, Iron Skin loops, Blind/Threat loops, and Fortress/Vacuum interactions. `Shift+1` through `Shift+4` load those builds live; `Ctrl+C` resets Crusader cooldowns, Shield Glare charges, and capstone ICDs without changing the build.

F3 exposes chassis, all cooldowns, W preparation, E charges/recharge, selected Heroic/talents, Iron Skin state, marks/tags, Subdue, Holy Fury, Authority, mitigation, ICDs, airborne state, and telemetry. Telemetry includes cast/contact totals and averages, AoE thresholds, defense/Shield/mitigation values, control success/resistance, cooldown loops, normal/multi-target/Authority Threat, and current highest-Threat targets.

## Deliberate deviations and remaining verification

- Class presentation is Crusader rather than Johanna and is testing-only.
- Condemn's +200% Minion/Mercenary damage, Laws of Hope activator, Steed Charge mount activator, Blessed Hammer, Holy Renewal healing, and source Mana/execute clauses are intentionally removed or replaced by the approved brief.
- Project-standard deterministic targeting replaces nondeterministic engine search order.
- Heaven's Fury uses the audited eight-barrage, three-enemy/three-ally deterministic representation; target selection is combat-ID ordered because the project has no HotS random bolt presentation layer.
- A desktop interactive pass confirmed Condemn preparation/contact presentation, Shield Glare's five-target cone telemetry, Iron Skin Shield/Unstoppable readability, live build switching/reset, Falling Sword activation, and Blessed Shield's visible multi-target path. Follow up on blocker-edge feel, Falling Sword touch steering, party-Shield readability, Steed extension loops, Holy Fury/Heaven's Fury density, AoE Threat feel, and longer survival sessions at 1/3/5 enemies.
