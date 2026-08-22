# Vanguard conversion v1

## Scope and source audit

Vanguard is a testing-only, mechanics-first disruption Tank built from current E.T.C. with selected Diablo mechanics. The implementation uses HeroesToolChest `heroes-data2` build **2.55.17.97771**, whose version manifest was published August 13, 2026, and reconciles it with Blizzard's live notes. The May 15, 2025 notes establish Face Melt's 10-second cooldown, Rockstar's 25 Basic/50 Heroic Armor values, Crowd Surfer's six-second miss reduction, Hammer-On's 12% Basic Attack bonus, and Encore's 4% Heroic cooldown reduction. The July 20, 2026 notes update Diablo's Overpower to 80 damage and Shadow Charge terrain collision to 140 damage.

Primary sources:

- `https://github.com/HeroesToolChest/heroes-data2/tree/main/heroesdata/2.55.17.97771`
- `https://news.blizzard.com/en-gb/article/24205005/heroes-of-the-storm-live-patch-notes-may-15-2025`
- `https://news.blizzard.com/fr-fr/article/24291432/notes-de-mise-a-jour-de-heroes-of-the-storm-20-juillet-2026`

The level-one chassis is 2,280 Health, 4.75 Health regeneration/sec, 99 physical Basic Attack damage, a 0.8-second attack interval, 1.5 source-unit melee range, 0.9375 source-unit radius, and 4.8398 source-unit movement speed. Vanguard has a 1.5 Tank Threat modifier and no Mana, Souls, or replacement resource. Flat Health, damage, healing, and Level-1 Armor use `value * 1.04^(level - 1)`; percentages and durations do not scale.

## Baseline kit

| Action | Implemented mechanics |
| --- | --- |
| Basic Attack | 99 physical damage every 0.8 seconds at source melee range. It is the primary attack used by Stunning Performance and Hammer-On. |
| Q — Powerslide | 105 physical damage, 12-second cooldown, 8.5-source-unit directional slide, 1.25-source-unit half-width, and 1.25-second source-owned Stun. It passes through enemies, caps Hero-style contacts at five, and uses a safe endpoint. |
| W — Face Melt | 68 magical damage, 10-second cooldown, 4-source-unit radius, and safe 2.5-source-unit outward displacement. Damage and control immunity resolve independently. |
| E — Overpower | One valid nearby hostile target, 80 physical damage, 12-second recharge, safe flip behind Vanguard, and 0.25-second source-owned Stun. Displacement-immune targets still take the legitimate damage and independently attempt the Stun. |
| D — Rockstar | Passive indicator. A committed Basic Ability grants 25 Level-1 Universal Armor for two seconds; a Heroic grants 50. Applications are once per cast, not per contact/tick, and use strongest-active shared Armor behavior. |

Powerslide's source travel speed is represented in its effect timing while gameplay movement resolves deterministically to the audited safe endpoint. Guitar Solo and Stage Dive are removed entirely.

## Heroics and channel controls

Mosh Pit has a 120-second cooldown, 0.75-second windup, and four-second channel. It maintains a short source-owned Stun on up to five susceptible enemies in the moving radius. Ordinary hostile control and movement interrupt the baseline channel; ability input cannot cancel it. Boss immunity remains profile-driven.

Lightning Breath has a 90-second cooldown and 0.5-second windup. Vanguard becomes source-owned Unstoppable and remains stationary for four seconds while dealing 50 Level-1 magical damage every 0.25 seconds to up to five enemies in the frontal cone. Each target owns its Slow stack: +4 percentage points per hit, two-second refresh, maximum 40%. Commands issued specifically to selected Vanguard rotate the cone without movement or cancellation. Selecting/commanding other party members does not rotate it. The channel cannot be voluntarily cancelled.

## Talent conversion

| Guild tier | Choice | Mechanics |
| --- | --- | --- |
| 9 | Stunning Performance | A successful primary Basic Attack extends the currently effective any-source Stun by 0.25 seconds. It cannot create control. |
| 9 | Prog Rock | Encounter quest: 20 qualifying Q/E Stuns, with shared quest-progress modifiers capped at 2x. The completing and later qualifying Vanguard Stuns each create an independent four-second area that heals nearby allied Hero-equivalent recipients other than Vanguard for 50 Level-1 Health/sec. Five-contact convention applies. |
| 9 | Block Party | Each Basic/Heroic cast grants one shared Block charge to Vanguard and nearby eligible allies, maximum two per recipient and once per cast. Shared Block provides its normal 75 Physical Armor against the next successful physical Basic Attack. |
| 12 | Crowd Surfer | Q may cross blockers/terrain but must land safely. A zero-contact Q removes six seconds from remaining Q cooldown. |
| 12 | Loud Speakers | W radius and displacement are both multiplied by 1.5. |
| 12 | Wall of Sound | Q pushes targets forward and grants 20% movement speed for 2.5 seconds once per cast. A collision based on target radius/blocker geometry adds 140 Level-1 damage and sequences one additional second of Stun. |
| 18 | Pinball Wizard | Q source-owns a two-second target mark. That Vanguard's next W consumes it for 300% additional damage (four times baseline total). |
| 18 | Hammer-On | Primary Basic Attacks deal 12% more damage if the target is currently Stunned by any legitimate source. |
| 18 | Echo Pedal | Each Basic/Heroic cast schedules 18 Level-1 magical AoE damage immediately and two seconds later. No special PvE multiplier. |
| 21 | Mic Check | One W with at least two qualifying contacts removes six seconds from remaining W cooldown once. |
| 21 | Encore | W leaves a source-owned Amp at the original location; after two seconds it repeats displacement, not damage. Original and Amp contacts independently remove 4% of the selected Heroic's maximum cooldown, capped at five contacts per event. |
| 21 | Face Smelt | W reverses its displacement and safely pulls toward the event center; no Slow. |
| 24 | Show Stopper | Q schedules a one-second Root after its owned Stun sequence. A Stun-immune but Root-susceptible target still receives the authored Root attempt after the nominal Q window. Wall of Sound extension delays the Root correctly. |
| 24 | Dissonance | W and Amp contacts apply a one-second Silence after outward or inward displacement. |
| 24 | Overpowering Nightmare | E has three sequentially recharging charges, each with 12-second recharge, and a two-second inter-cast lockout. |
| 27 | Tour Bus | Mosh refreshes Q. Q is the sole cast exception during Mosh, carries the aura, adds two seconds, and retains every Q/Rockstar/Block/Echo talent interaction. |
| 27 | Hellstorm | Non-emergency Lightning Breath lasts 12 seconds total and uses +8% Slow per hit to an 80% cap. Rotation, stationary, Unstoppable, and no-cancel rules remain. |
| 30 | Encore Performance | Enemies actually controlled by the selected Heroic are marked. Mosh targets receive a two-second shared forced-target Taunt only after the final owned Stun ends; Lightning targets receive it after their last owned Slow expires. No Silence is copied from Warrior. |
| 30 | Power of the Horde | Replaces Rockstar with party pulses: 50 Level-1 Universal Armor for Basic casts and 75 for Heroics, for two seconds in the centralized support radius. |
| 30 | Death Metal | Fatal hostile damage starts the unselected baseline Heroic immediately for four seconds and starts a separate 120-second emergency-Mosh or 90-second emergency-Lightning ICD. Normal post-mitigation damage and healing still resolve; Health floors at one. At completion Vanguard survives at 35% current maximum Health or more, otherwise direct defeat occurs without recursion. Selected R cooldown/upgrades never affect it. |

## Ordering and ownership

All temporary marks include Vanguard's combat ID. Damage precedes displacement and Dissonance on W; Overpower displacement precedes damage and Stun; Show Stopper waits for Q's complete owned Stun sequence. Heroic control precedes Encore Performance Taunt. Echo and periodic Heroic ticks never retrigger Rockstar or Block Party. Power of the Horde uses the same four-source-unit centralized support radius as Prog Rock and Block Party.

The standard immediate target categories are `standard`, `elite`, `named`, `boss`, `enemy_hero`, `summon`, and `temporary_combat`; quest targets exclude disposable summons and temporary combat objects. Hero-style per-event contacts cap at five. Bosses take normal damage and Threat while their authored control profile controls Stun, Root, Slow, Silence, and displacement resistance.

## Testing Range, telemetry, and presentation

The testing save adds original placeholder member **Ettin Chieftain**, level 30, without recruitment, story, starter-roster, or campaign unlock changes. Vanguard Range includes 1/2/3/4/5+ packs, standard/elite/named/Boss/training targets, displacement immunity, Unstoppable, allies, and blocker fixtures. `Shift+1`–`Shift+4` load baseline, Tour Bus control, Hellstorm party, and Death Metal Nightmare builds; `Ctrl+C` resets cooldowns, E charges, and Death Metal ICD.

F3 exposes chassis, cooldowns, E charges/lockout, quest/areas, Block, owner marks, delayed Root/Amp/Echo state, both Heroic states, Encore marks, Death Metal/ICD, selected talents, and telemetry. Telemetry covers casts/contacts/control, displacement/collision, Armor/Block, quest healing, channel interruption/ticks, talent damage/CDR, Taunts, and lethal-intercept outcomes.

## Geometry uncertainty and deliberate deviations

Normalized public data exposes the chassis and textual mechanics but not every dependable cast-shape scalar. All provisional geometry is centralized in `VanguardData.SPACE` and documented in `vanguard_geometry_calibration.md`. It uses the established `185 / 5.5` project calibration and deterministic combat-ID ordering where the source engine's search order is not portable.

Project-approved deviations are the class identity, no resource, Overpower replacing Guitar Solo, Lightning Breath replacing Stage Dive, Level-1-scaled Rockstar Armor, quest-based Prog Rock, shared Block recipient addition, Wall of Sound, disruption tier, party Power of the Horde, and Death Metal survival rework. Automated verification covers deterministic mechanics and presentation/runtime wiring; blocker-edge feel, touch rotation, channel readability, and dense 12-second Hellstorm presentation still require a human device pass.
