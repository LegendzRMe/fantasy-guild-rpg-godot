# Sentinel V1 combat conversion

## Scope and identity

Sentinel is a resource-free ranged Healer whose throughput is earned by attacking and exposing enemies. It has normal non-tank Threat. This conversion keeps data, pure state rules, live runtime orchestration, UI presentation, and tests separate so later balance work does not require searching the whole game runtime.

## Source audit

The reference chassis and ability timings were audited against Blizzard's February 10, February 19, April 20, and May 11 2026 live patch notes and the latest HeroesToolChest extracted game data available during implementation (`2.55.16.97039`). The project brief overrides reference data wherever it deliberately differs, notably Lunar Flare's encounter cap of +250%.

## Baseline

- 1,511 Health, 3.1484 regeneration, 4% level scaling.
- Ranged Physical Basic Attack: 55 damage, 0.75 second interval, 6 source-unit range.
- No mana or class resource.
- Normal damage and healing Threat. Sentinel is not a Tank.

## Abilities

### D — Hunter's Mark

Hunter's Mark Reveals one valid enemy for 4 seconds and applies the shared strongest-source 15 Armor reduction. It has a 20 second cooldown. A successful Basic Attack heals Sentinel for 1% maximum Health, doubled against its own active mark. Selection uses the player's valid target first and otherwise deterministically searches for the closest revealable concealed target in range. `Unrevealable` targets are skipped and a failed search spends no cooldown.

### Q — Light of Elune

Light of Elune has two charges, a 16 second recharge, and a 0.5 second inter-cast lockout. One recharge completion refills the entire pair through the class-neutral `FULL_REFILL` charge mode. It automatically chooses the lowest current Health-percentage living allied Hero in range, including self; ties use party order and then combat ID. Full-Health allies remain valid. Successful Basic Attacks reduce active recharge by 1.5 seconds.

### W — Sentinel Shot

Sentinel Shot is a manual long directional projectile. It damages and Reveals the first valid enemy. Damage grows linearly with total distance traveled and is capped by one centralized curve. The baseline reaches +100% at authored range; Ranger's returning flight may continue to the global +250% ceiling. At 20 Lunar Flare stacks it pierces the first unique target and ends on the second. It never hits one target twice. A target dying during this Sentinel owner's W Reveal resets one useful W charge once.

### E — Lunar Flare

Lunar Flare warns for 0.75 seconds, then deals damage and Stuns in a ground area. Its encounter-local quest receives one stack for each qualifying direct hit and another when that target dies within 3 seconds. Summons, objects, temporary combatants, and training targets do not qualify. Each stack adds 3% damage to the original baseline, capped at +250%. Rewards: 10 stacks gives +30% cast range, 20 gives W its first pierce, and 40 makes every eighth successful Basic Attack cast a non-recursive automatic flare and grants one source unit of Basic Attack range. Progress resets at encounter end.

### Heroics

- Shadowstalk: Stealths party Heroes and heals 380 over 10 seconds. Stationary allies may become Invisible after 1.5 seconds. It does not leave combat, clear Threat, or end the encounter. Detector and Reveal rules remain authoritative.
- Starfall: a six-second ground area dealing 92 damage per second and Slowing enemies by 20%.

## Talents

All eight tiers and their authored heroic dependencies live in `sentinel_data.gd`. Runtime implementations use shared Armor reduction, percentage-Health damage, concealment, control, temporary Armor, Ability Power, and strongest outgoing-damage-reduction primitives. Secondary splash, automatic flares, and periodic ticks are tagged so they cannot recursively trigger Basic-Attack or quest hooks.

Modifier ordering for New Light of Elune is deterministic: resolve the scaled native Q amount, multiply it by 1.5 when the target's pre-heal Health is below 20%, then add a previously snapshotted Overflowing Light bank. Only native current-cast overhealing can form the next bank; consumed bank healing cannot re-bank itself.

## Testing range

The testing save exposes `Testing > Sentinel Range`. If the selected team lacks a Sentinel, the fixture adds the test Sentinel and fills the remaining party slots. The range provides normal, ranged, elite, summon, training, defense, and Boss fixtures, long projectile lanes, and deliberately wounded allies. The testing roster includes one level-30 Sentinel and the five representative data presets cover baseline, healing/mark, projectile/flare, Basic-Attack/aura, and completed-quest states.

Controls: `Shift+1` through `Shift+5` load the five builds, `Alt+C` resets cooldowns and charges, `Alt+H` stages deterministic ally Health ratios, `Alt+Q` completes the encounter quest, `Alt+M` applies Hunter's Mark to the selected enemy, and `F3` toggles combat telemetry.

## Deliberate V1 boundaries

- Visuals are readable prototype shapes, warnings, trails, and concealment states, not final art.
- Source-unit spatial conversions and projectile calibration are provisional and centralized in `sentinel_data.gd`.
- Quest completion is encounter-local by design; no profile persistence was added.
- No mana mechanic was introduced.

## Regression contract

Automated coverage verifies registry/save compatibility, full-pair charge semantics, deterministic ally resolution, mark ownership, strongest-source reduction, quest exclusions, quest cap, talent data, and the existing class suite. Live runtime parsing is covered by the repository validation load gate.
