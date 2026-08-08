# Priest V1 combat conversion

**Lifecycle:** Conversion specification.

Priest is a testing-only, resource-free ranged Healer. Its physical Basic Attack and automatic position-based ally resolution make it more active and positioning-sensitive than Cleric. Anduin supplies the chassis, Q/W/E, Heroics, Pursued by Grace, and most talents; selected Uther concepts supply Eternal Vanguard, Blessed Champion, Devotion, Tyr's Deliverance, Benediction, Guardian of Ancient Kings, and Redemption; Whitemane contributes only the reduced Zeal damage-to-healing idea. Priest does not use Tyrande mechanics, Mana, Energy, Desperation, Holy Power, Leap of Faith, or an extra action slot.

## Sources and conversion decisions

Current extracted values were checked against HeroesToolChest live build `2.55.9.93640`. Public official pages establish hero identity and ability structure; extracted game data resolves current numerical values and the stale Flash Heal webpage value. Geometry not exposed by public data is provisional and centralized in `PriestData.SPACE`.

| Mechanic | Source | Source value | Confidence | Priest conversion |
|---|---|---:|---|---|
| Chassis | Anduin extracted live data | 1665 Health, 85 Basic Attack, 1.0 sec, 5.5 range | High | Exact values with project world conversion and 4% level scaling |
| Flash Heal | Anduin extracted live data | 280 healing, 5 sec cooldown | High | Custom automatic completion-time ally selection; 0.75 sec cast |
| Pursued by Grace | Anduin official/live data | 32 healing | High | Most-wounded nearby living Hero after successful Basic Attack damage |
| Divine Star | Anduin live data | 140 damage, 130 healing, +25% per Hero | High | Outbound/return geometry; immediate-target contribution capped at five |
| Chastise | Anduin live data | 175 damage, 1.25 sec Root, 9 sec cooldown | High | Shared line/control rules |
| Salvation | Anduin official/live data | 0.5 sec startup, 3 sec channel, 30% maximum Health | High | Shared Protected; matching upgrade uses Invulnerable |
| Lightbomb | Anduin official/live data | 1.5 sec delay, 150 damage, 1.25 sec Stun, 165 Shield/contact | High | Closest-other/self fallback; five immediate-target Shield cap |
| Uther talents | Uther official/live history | Source structure varies by talent | Medium | Focused conversions only; no Paladin or melee requirement |
| Zeal | Whitemane official identity | Damage-to-healing relationship | Medium | Project-authored 6 sec mark and 25% conversion; no Whitemane resource loop |

Sources: [Anduin](https://heroesofthestorm.blizzard.com/en-us/heroes/anduin/), [Uther](https://heroesofthestorm.blizzard.com/en-us/heroes/uther/), [Whitemane](https://heroesofthestorm.blizzard.com/en-us/heroes/whitemane/), and [HeroesToolChest game data](https://github.com/HeroesToolChest/heroes-data).

The official Anduin page can still surface the older 270 Flash Heal value. Current extracted data and the later official balance change support 280, which this conversion uses.

## Chassis and scaling

Level-1 Priest has 1665 Health, 3.4687 Health regeneration, 85 Power/Basic Attack damage, a 1.0-second attack interval, 185 project-world range, no base Armor, cloth proficiency, and wand/one-handed weapon proficiency. Flat source values scale by `1.04^(level-1)`. Level 30 is approximately 5193 Health, 10.82 regeneration, and 265 Power before equipment. Power supplies the ordinary coefficient base; `ability_power_percent` is applied afterward only to eligible ability output. Piercing Light contributes up to +10% Ability Power and does not increase Basic Attacks, Pursued by Grace, Armor, percentage healing, or percentage Shields.

## Core actions

- `priest_basic_attack`: ranged Physical Basic Attack through shared Basic Action rules. Successful damage can trigger Priest Basic-Attack systems; tagged Surge attacks participate without recursively generating Surge.
- `priest_trait`: passive Pursued by Grace plus Eternal Vanguard. No D activation exists.
- `priest_q`: 0.75-second Flash Heal cast. At completion it chooses the living allied Hero in range with the lowest Health percentage, then nearest distance and stable combat ID. Full-Health targets and overhealing are valid.
- `priest_w`: traveling Divine Star. It damages each intersected enemy once outbound, returns toward Priest's current position, and heals each intersected allied Hero once. Up to five immediate combat contacts contribute +25% return healing each.
- `priest_e`: manually aimed Chastise line that damages and requests a Root through the target control profile.
- `priest_r1`: Salvation startup/channel with proportional percentage healing and real Protected state.
- `priest_r2`: Lightbomb locks the nearest other living ally in range, or Priest when none exists. Damage/Stun affects all contacts; qualifying Shield contacts cap at five.

## Spirit Form and shared states

Lethal damage is intercepted once per death and begins eight-second Spirit Form. The Spirit is visible, controllable, movable, Invulnerable/untargetable, and can Basic Attack and use Q/W/E after those cooldowns refresh. R remains blocked. Normal healing, Shields, and ally selection exclude the Spirit. Without ready Redemption it becomes normally defeated at expiry; ready Redemption revives at the spirit location with 50% Health and starts a 180-second cooldown. Protected prevents damage without consuming Shields or preventing normal control. Invulnerable additionally prevents hostile targeting.

## Talent tree

| Guild level | Options |
|---:|---|
| 9 | Evenhanded Blessings / Power Word: Shield / Blessed Champion |
| 12 | Moral Compass / Surge of Light / Piercing Light |
| 15 | Holy Word: Salvation / Lightbomb |
| 18 | Zeal / Blessed Recovery / Devotion |
| 21 | Speed of the Pious / Push Forward! / Tyr's Deliverance |
| 24 | Renew / Holy Nova / Benediction |
| 27 | Light of Stormwind / Inner Fire |
| 30 | Guardian of Ancient Kings / Redemption / Varian's Legacy |

Notable project rules: Devotion and Guardian of Ancient Kings trigger only from direct Q or normal W return healing; Tyr's Deliverance stores at most seven Basic-Attack stacks for the next W; Benediction arms after eight successful Basic Attacks and resets the next completed Q or valid W/E without adding a button; Renew uses source-owned periodic records; Varian's Legacy is source-aware periodic damage with 50% resolved-damage self-healing.

## Targets, Bosses, summons, and presentation

Automatic healing only searches the controlled Hero array, excluding summons, NPCs, defeated Heroes, and Spirit Form. Boss control requests use shared duration profiles, so damage still resolves when Root/Stun is reduced or immune. Summons and temporary combat targets count for immediate Divine Star/Lightbomb scaling but not Piercing Light quest progress. The roster exposes abilities and all eight tiers. Combat uses temporary cast, traveling-star, Chastise, Lightbomb, Salvation, channel, Shield, Root, and Spirit visuals without copyrighted assets.

## Testing and telemetry

The testing save receives level-30 Priest `Elowen`; live starting rosters and Ashwood rewards are unchanged. Testing > Priest Range provides mixed target categories, a control-resistant Boss, an attacking defensive fixture, damaged allies, three build presets (`Shift+1..3`), and Spirit/Redemption/Health controls (`Alt+K/V/R/H`). Telemetry covers Basic Attacks, automatic healing, casts, interruptions, damage/healing/overhealing, contact caps, controls, Piercing progress, talent triggers, protection, Spirit time/actions, and Redemption.

## Known limitations and manual checks

Final art/audio, exact visual geometry, advanced range widgets, and final balance are intentionally deferred. Hands-on validation remains necessary for four-Hero control load, expected Q/Lightbomb recipient readability, moving Divine Star return feel, five-target scaling, Spirit usefulness, Cleric differentiation, and each talent build. No claim of completed manual playtesting is made.
