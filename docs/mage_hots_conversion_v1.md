# Mage (Kael'thas-inspired) Conversion V1

This is an original prototype implementation of a fire Mage kit whose mechanical reference is Kael'thas in *Heroes of the Storm*. Names and temporary geometric effects are development placeholders; no Blizzard art, audio, or final presentation assets are included.

## Authoritative sources and confidence

The chassis and live ability text were checked against Blizzard's [Kael'thas hero page](https://heroes-site-production-eks-prod-use1-01.heroesofthestorm.blizzard.com/en-gb/heroes/kaelthas/) and official balance notes from [September 2021](https://news.blizzard.com/en-us/article/23725472/heroes-of-the-storm-balance-patch-notes-september-27-2021), [September 2025](https://news.blizzard.com/en-us/article/24229032/heroes-of-the-storm-live-patch-notes-september-30-2025), [February 2026](https://news.blizzard.com/en-us/article/24244446/heroes-of-the-storm-live-patch-notes-february-10-2026), [May 2018](https://news.blizzard.com/en-gb/article/21749146/heroes-of-the-storm-patch-notes-may-9-2018), [March 2016](https://news.blizzard.com/en-us/article/20060107/heroes-of-the-storm-ptr-patch-notes-march-21-2016), [July 2016](https://news.blizzard.com/en-us/article/20164442/heroes-of-the-storm-patch-notes-july-12-2016), and [August 2016](https://news.blizzard.com/en-us/article/20212896/heroes-of-the-storm-patch-notes-august-9-2016).

Public Blizzard text does not expose exact world geometry or projectile velocity. Those values are therefore provisional, centralized in `mage_data.gd`, and converted using `SOURCE_TO_WORLD = 185 / 5.5`. No screenshot produced a safe pixel-to-game-unit calibration, so screenshots informed only relative shape and readability.

## Chassis and scaling

- Level 1: 1,595 Health, 3.3164 Health regeneration, zero Armor, 65 physical ranged Basic Attack damage, 1.11 attacks per second, 185 world-unit range, and 150 movement speed.
- Normal authored Health, Basic Attack, and ability values scale by four percent per level. Pyroblast authored damage scales independently by five percent.
- Ability damage then scales by current raw Power relative to the expected level-scaled 65 Power and finally by total additive Ability Power.
- Basic Attacks remain physical and do not receive Ability Power. Burned Flesh remains percentage-Health physical damage and also excludes Ability Power.

## Kit

- **D — Verdant Spheres:** one charge, six-second sequential recharge, and one armed empowerment. Mana Tap starts recharge on activation; Twin Spheres stores two sequential charges. No extra action slot is created.
- **Q — Flamestrike:** a one-second warning at a clamped ground location. Empowerment increases radius. Convection counts qualifying enemies per encounter and repeats every twenty hits.
- **W — Living Bomb:** three periodic ticks followed by an explosion. Empowerment permits an immediate manual cast while W is cooling down and detonates an existing bomb before replacing it.
- **E — Gravity Lapse:** a travelling line collision. Empowerment raises hit count and Stun duration. Bosses collide but resist Stun unless their data profile opts in.
- **R — Phoenix:** travels along the cast path, damages crossed targets, then persists and attacks using assigned-target, Boss, Elite/Named, Standard, summon, distance, and stable-ID priority. It continues after the Mage is incapacitated. Rebirth grants three temporary R reposition charges and pauses attacks during relocation.
- **R — Pyroblast:** an interruptible 1.5-second cast followed by a genuinely homing projectile. It disappears if its target becomes invalid before impact.

## Living Bomb lineage

Every primary cast creates a lineage with an infection set. Spreads inherit that lineage and cannot reinfect a target already visited by it. The lineage remains alive while an explosion resolves and is cleaned only after its last active bomb. This prevents two-target loops without disabling Master of Flames generations. Ignite chooses the hit, unbombed target nearest the exact Flamestrike center.

## Ordering decisions

- Arcane Barrier previews the fully modified and armored incoming hostile hit with the same critical roll. If that result would be lethal, its four-second Shield is applied before the real hit and the 45-second cooldown begins.
- Pyromaniac reduces Q/W/E only after a Living Bomb tick deals positive Shield or Health damage.
- Gravity Crush requires a successful Stun. It affects Mage Basic Attacks and normal Mage-owned Q/W/E/R, periodic, and Sunfire damage, but excludes Burned Flesh, items, environment, allies, and other percentage damage.
- Presence of Mind has a five-application ceiling per Q resolution or explosion event. Periodic ticks never reduce R.

## Provisional geometry and playtest values

All are centralized in `MageData.SPACE` or `MageData.VALUES`: source-to-world scale; Q cast range and normal/empowered radius; W cast and explosion radius; E range, width, and speed; Phoenix cast range, path width, travel speed, attack radius/cadence, and splash radius; Pyroblast cast range, speed, and splash radius; Convection rewards; Arcane Barrier fraction/duration/cooldown; Arcane Dynamo value/maximum/duration; Burned Flesh coefficients; Pyromaniac reduction; Presence event ceiling; Gravity Crush amount/duration; and Rebirth charges.

Rebirth reposition path damage is deliberately `false` and configurable. Official public text confirmed reposition charges but did not safely establish whether relocated Phoenix path damage should repeat. Initial Phoenix path damage is implemented; a Rebirth relocation does not repeat it until live behavior can be verified.

## Developer range controls

- `F3`: shared geometry/debug overlay, including Q, W, and E outlines.
- `F9`: reset Verdant Spheres charges.
- `Ctrl+F9`: load the Level 1 baseline Mage.
- `F10`: set Arcane Dynamo to maximum and Arcane Barrier to ready.
- `Shift+F9`: load a Level 30 Phoenix/bomb-chain Mage build.
- `Shift+F10`: load a Level 30 Pyroblast/control Mage build.
- `F11`: apply a manual Living Bomb to every living test target.
- `F12`: set living Boss and Elite targets to ten percent Health.

Temporary lines, circles, labels, and projectiles intentionally stand in for final art. Manual checks should cover cast feel, warning readability, grouped-target ordering, Phoenix target priority, Pyroblast homing around moving targets, Rebirth placement near blockers, long Convection runs, and high-generation Master of Flames chains.
