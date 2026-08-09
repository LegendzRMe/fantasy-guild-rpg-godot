# Protector V1 Combat Conversion

Protector is a resource-free, short-ranged Tank built from Tyrael's current combat chassis and Tassadar's Force Wall geometry. Its project identity is deliberately fragile: low durability and personal damage are exchanged for Tank Threat, mobility, temporary terrain, displacement, and ally setup. It has no baseline Shield, sustain, passive living damage reduction, or movement resource.

## Chassis and base kit

- Level 1: 1,850 Health, 0 Armor, 65 Physical Basic Attack, 1.0-second interval, 3.75 source-unit range, normal 150 world-unit movement speed, 4% per-level scaling, and no resource.
- Tank damage Threat uses the shared `CombatBalanceData.TANK_THREAT_MODIFIER` of 1.5.
- **D — Archangel's Wrath:** defeat automatically creates a four-second, controllable movement-only spirit. It is Invulnerable, gains 20% Movement Speed, and causes nearby enemies to deal 50% less damage. It then explodes for 450 level-1 damage, leaves the same reduction for three seconds on enemies hit, and remains defeated.
- **Q — El'druin's Might:** throw for 110 damage and a 30% Slow for 2.5 seconds, leaving the sword for five seconds. Recast teleports to the sword, reapplies the Slow, and knocks enemies away without bonus damage. Q may cross the caster's own Force Wall but not permanent or unrelated blockers.
- **W — Force Wall:** after 0.5 seconds, creates an indestructible movement-only oriented wall for two seconds on an 18-second cooldown. It blocks every unit category, but never attacks, projectiles, line of sight, Q, E, or Judgment.
- **E — Smite:** a wide 150-damage path on a six-second cooldown. Its three-second field grants Protector and allied Heroes 25% Movement Speed for two seconds.
- **R1 — Judgment:** 0.75-second warning, charge, 150 primary damage and 1.5-second Stun, plus 75 damage and displacement around the target; 70-second cooldown. It can cross the caster's Force Wall.
- **R2 — Sanctification:** 0.5-second cast, three-second Invulnerable field including Protector, 85-second cooldown.

## Final talent table

| Guild level | Options |
| ---: | --- |
| 9 | Pursuit of Justice; Restraining Field; Radiant Path |
| 12 | Stalwart Angel; Rebuke; Radiant Reach |
| 15 | Judgment; Sanctification |
| 18 | Burning Halo; Crossing Fire; Purge Evil |
| 21 | Sword of Justice; Piercing Justice; Law and Order |
| 24 | Bound by Law; Horadric Reforging; Smite the Wicked |
| 27 | Angel of Justice (Judgment); Holy Arena (Sanctification) |
| 30 | Aspect of Justice; Force Barrier; Seal of El'druin |

Talent numbers and player-facing descriptions are centralized in `ProtectorData`. Important semantics:

- Stalwart Angel is one conditional 25 universal Armor source while the sword is active and for three seconds after teleport.
- Burning Halo deals modest 12-per-second level-1 pressure around Protector and the active sword. Teleport temporarily adds the audited 125% bonus to Protector's aura.
- Crossing Fire requires a successful damaging Basic Attack whose direct line intersects one of the caster's walls. It Slows once and removes 0.5 seconds from W.
- Sword of Justice permits exactly two teleports. Piercing Justice marks only an original throw crossing the caster's wall; every valid teleport gains 25% radius and removes five seconds from W.
- Law and Order reflects one additional fully talented Smite field across the first intersected own wall. Original and duplicate share a cast ID, damaged IDs, and Purge IDs, so an enemy takes damage and is purged at most once per cast. It never recursively duplicates.
- Smite the Wicked uses the shared charge timer at 125% recharge speed while El'druin is active and for two seconds after teleport.
- Aspect of Justice makes D manually usable while alive: 1.25-second channel, normal four-second Wrath, return at saved Health, fixed 120-second cooldown. Actual death still triggers baseline D independently.
- Force Barrier changes W to 2.5 seconds, 150% range, and an eight-second cooldown. Seal of El'druin gives two sequential E charges, both initially available.

## Threat, ownership, and Boss rules

Purge Evil acts independently on every enemy legitimately damaged by Smite. It excludes the caster, finds the highest positive Threat among other living allied Heroes using party index as the deterministic tie break, and sets only that entry to zero. Threat is not transferred; Protector Threat, forced targets, unrelated enemies, damage ownership, and kill credit remain unchanged. Original and Law and Order fields purge each enemy once per cast ID.

Every wall records owner combat ID, cast ID, geometry, flags, and remaining duration. Restraining Field, Rebuke, Crossing Fire, Piercing Justice, Law and Order, and Force Barrier inspect only the casting Protector's wall. Multiple Protectors therefore cannot borrow talents or multiply identical Archangel reductions. Outgoing reduction uses strongest-source semantics.

Bosses are blocked by temporary terrain. Their authored Slow, Stun, and displacement profiles still apply; displacement-immune Bosses are not moved and cannot trigger Rebuke from denied movement. Purge Evil and Archangel outgoing reduction remain valid against Bosses.

## Testing and telemetry

The Testing Guild migration adds exactly one level-30 Protector fixture. Combat Hall's Protector Range automatically creates a Protector-plus-three-allies party and includes ordinary melee/ranged, elite, named, summon, temporary, attacking dummy, Boss, permanent blocker, open space, and wall-crossing fixtures.

- `Shift+1..4`: baseline, Teleport/Disruption, Force Wall/Setup, and Smite/Party presets.
- `Alt+C`: cooldowns and Smite charges; `Alt+K`: death Trait; `Alt+H`: restore allies; `Alt+W`: clear owned walls; `Alt+T`: seed selected-enemy Threat.
- `F3`: IDs, Threat, Q state, wall ownership, Smite charges/fields, Aspect/Wrath state, and related runtime values.

Testing-only telemetry records Basic Attacks; Q throws, hits, teleports, knockbacks and reductions; wall casts/crossings; Smite casts, hits and purged Threat; Heroics; Wrath; and Burning Halo damage. It remains dormant outside explicit testing telemetry.

## Source audit and project overrides

Current extracted Heroes data and official Blizzard patch history were used because the legacy hero page can contain stale values. The March 2, 2021 notes establish the modern four-second 450-damage Archangel's Wrath and 50% outgoing reduction. July 29, 2025 notes establish the modern El'druin/Bound-by-Law family. December 1, 2025 notes establish current Burning Halo, 85-second Sanctification, and 1.25-second Aspect cast values. Current extracted data establishes Q/W/E and Heroic geometry/cooldowns.

The implementation brief deliberately wins where it differs: W replaces Righteousness; Q teleport gains a no-damage knockback; Purge Evil is Threat manipulation; Law and Order is a reflected Smite; Seal grants E charges; Aspect uses a fixed cooldown; and death-timer reduction/resurrection are omitted. Temporary working names are mechanics references only; no Blizzard assets are included.

Sources:

- Blizzard March 2, 2021 balance patch: https://news.blizzard.com/en-us/article/23623169/heroes-of-the-storm-balance-patch-notes-march-2-2021
- Blizzard July 29, 2025 live patch: https://news.blizzard.com/en-us/article/24224135/heroes-of-the-storm-live-patch-notes-july-29-2025
- Blizzard December 1, 2025 live patch: https://news.blizzard.com/en-us/article/24246292/heroes-of-the-storm-live-patch-notes-december-1-2025
- HeroesToolChest extracted live data: https://github.com/HeroesToolChest/heroes-data2
