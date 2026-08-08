# Slayer Conversion V1

**Lifecycle:** Conversion specification. Names and presentation are working metadata; all art remains original placeholder work.

## Identity and sources

Slayer is a manually controlled, resource-free melee DPS built around frequent Basic Attacks, sustain, short movement commitments, and defensive timing. Mechanical reference values were audited against Blizzard's official sources:

| Source | Used for | Confidence/correction |
|---|---|---|
| [Current Illidan hero page](https://heroes-site-production-eks-prod-use1-01.heroesofthestorm.blizzard.com/en-gb/heroes/illidan/) | Current Q/W/E, Heroics, trait, attack speed | High; preferred over old task values |
| [April 2016 balance update](https://news.blizzard.com/en-gb/article/20090404/heroes-of-the-storm-balance-update-notes-april-12-2016) | Historical baseline and redesign context | High historical confidence |
| [November 2016 patch](https://news.blizzard.com/en-gb/article/20372990/heroes-of-the-storm-patch-notes-november-16-2016) | Talent interaction history | High historical confidence |
| [July 2019 balance patch](https://news.blizzard.com/en-us/article/23057727/heroes-of-the-storm-balance-patch-notes-july-10-2019) | Talent corrections | High |
| [August 2024 live patch](https://news.blizzard.com/en-us/heroes-of-the-storm/24126146/heroes-of-the-storm-live-patch-notes-august-12-2024) | Immolation/Hunter's Onslaught interaction | High |
| [September 2025 PTR notes](https://news.blizzard.com/en-us/article/24232472/heroes-of-the-storm-ptr-patch-notes-september-2-2025) | Latest Fiery Brand ordering wording | Medium-high; PTR-specific wording documented explicitly |

The live audit corrected the working implementation to 1.82 attacks per second, 30% trait healing, 66 Dive damage, 119 Sweeping Strike damage, 2.5-second Evasion, Metamorphosis at 46 damage plus 220 Health per target for 18 seconds, and The Hunt at 251 damage with a one-second Stun. Exact geometry, travel timing, and collision widths remain provisional and centralized.

## Chassis and scaling

Level 1: 1,725 Health, 3.59375 Health regeneration, 78 Basic Attack damage, 1.82 attacks per second, 150 movement speed, melee range, Leather Armor family, dual-wield/one-handed proficiency, and no Mana, Energy, Fury, or other resource. Health, regeneration, Basic Attack damage, and ability amounts scale by `1.04^(level - 1)` through Level 30.

Basic Attack ordering is `(base attack + Unending Hatred flat damage) × (1 + additive percentage bonuses)`. Fiery Brand is a separate percentage-Health event before the primary hit. A successful primary hit heals through Betrayer's Thirst for 30% of resolved damage and reduces Q, W's active recharge, E, and the selected R by one second. Miss, Evasion, immunity, and zero damage do none of those things.

## Abilities

- **D — Betrayer's Thirst:** passive healing and cooldown reduction. Thrill of Battle makes D active at Level 30.
- **Q — Dive:** manually targets an enemy, resolves damage, and lands safely beyond it. Invalid targets/landings spend nothing.
- **W — Sweeping Strike:** manually chooses a direction, damages each distinct swept contact, repositions, and grants a temporary Basic Attack bonus.
- **E — Evasion:** 2.5 seconds of deterministic hostile-Basic-Attack avoidance; no automatic cast.
- **R1 — Metamorphosis:** location cast, damages immediate valid targets, and gains temporary maximum/current Health for up to five contacts for 18 seconds.
- **R2 — The Hunt:** manually charges any valid enemy on the active battlefield, damages, requests a one-second Stun, and requires a safe landing.

## Talent tree

| Level | Options |
|---:|---|
| 9 | Immolation / Battered Assault / Unending Hatred |
| 12 | Rapid Chase / Friend or Foe / Unbound |
| 15 | Metamorphosis / The Hunt |
| 18 | Reflexive Block / Thirsting Blade / Hunter's Onslaught |
| 21 | Nimble Defender / Elusive Strike / Shadow Shield |
| 24 | Marked for Death / Fiery Brand / Blades of Azzinoth |
| 27 | Demonic Form (Metamorphosis only) / Nowhere to Hide (The Hunt only) |
| 30 | Nexus Blades / Thrill of Battle / Unending Thirst |

Rapid Chase defers Q's cooldown until its three-second different-target recast window ends. Friend or Foe permits explicit allied Dive. Unbound earns a second sequential W charge at 15 qualifying encounter contacts. Immolation ticks once per second for four seconds using current Basic Attack range. Reflexive Block uses the shared Block system. Shadow Shield replaces only itself. Fiery Brand triggers on every third consecutive successful primary attack for 7% maximum Health, converted to 1.75% against Bosses. Blades activates automatically at five qualifying W contacts. Demonic Form changes attack speed/control duration; Nowhere to Hide doubles Hunt below 25% and resets it on a defeat. Unending Thirst converts trait overhealing into its own capped, decaying Shield.

## Ordering, targets, and encounters

Source miss → Evasion → immunity → Block → damage is the defensive order. Fiery Brand percentage damage precedes the primary attack; it cannot crit, receive ordinary outgoing multipliers, heal Slayer, or produce Shield directly. Ordinary summons count for immediate effects but not Unending Hatred/Unbound encounter progression. Unending Hatred participation survives waves within one battle and resets with the encounter runtime.

Boss Basic Attacks remain Evadable unless explicitly tagged to bypass. Boss control profiles govern Hunt's requested Stun. Fiery Brand uses its Boss conversion. Metamorphosis still counts a valid Boss once and respects the five-target cap.

## UI, telemetry, and testing

Roster and combat use the Slayer class icon and Q/W/E/R/D presentation. The action bar exposes W charges/recharge, Evasion duration, Block charges, transformation state, and capstone state without adding another slot. Battlefield cues cover Dive, Sweep, Evasion, Heroics, Immolation, Shields, and movement buffs.

Telemetry records Basic Attacks, trait healing/overhealing/CDR, Dive/Sweep contacts, Evasion, Block, Heroics, encounter talents, Fiery Brand, Blades, and capstones. The dedicated Slayer Range supplies ordinary, elite, Boss, summon, training, blocker, allied-target, low-Health, and multi-target fixtures. `Shift+1..9` and `Shift+0` load the ten builds.

## Known limitations and manual checks

Geometry, animation timing, VFX, and authored enemy Evasion-bypass attacks remain provisional. Manually verify edge landings, rapid double-Dive input, mobile ally selection, W width/blockers, Evasion clarity versus Armor, Boss control, temporary-Health removal, summon exclusions, Shield coexistence/decay, all action-bar states, and all ten range presets. No copyrighted art/audio, story unlock, automatic casting, or extra resource/action slot is included.
