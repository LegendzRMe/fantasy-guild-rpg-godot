# Druid conversion V1

Druid is a mechanics-first, Malfurion-inspired proactive healer built with original project names, UI, presentation, and code. The class is intentionally mana-free: its decisions come from maintaining source-owned Regrowths, positioning Moonfire and Roots, choosing an Innervate recipient, and committing to one of two Heroics. Druid exists in the Testing save and is not added to starter, campaign, or recruitment content.

## Architecture

- `druid_data.gd` owns audited chassis values, geometry, tunable constants, working names, the eight-tier talent tree, and representative test builds.
- `druid_system.gd` owns deterministic healing-over-time, targeting, talent, charge, quest, and telemetry rules.
- `druid_runtime.gd` owns battlefield targeting, cast resolution, controls, Treant behavior, Heroic sequencing, and effects.
- `druid_ability_presenter.gd` owns player-facing ability cards and talent-aware descriptions.
- `periodic_status_system.gd` supplies class-neutral beneficial periodic instances, ownership, refresh, scheduled-healing queries, and bonus-tick snapshots.
- `test_druid_system.gd` covers the deterministic mechanics; the shared UI suite covers registration, persistence, range access, and presentation contracts.

All damage and healing enter the existing combat pipeline. Ability Power is applied before the generic outgoing-healing multiplier; healing-over-time multipliers are applied only to periodic healing. Effective healing and overhealing continue through normal threat, combat text, item hooks, and telemetry paths.

## Core mechanics

- A successful Basic Attack applies a source-owned 6-second mini-HoT to the designated living ally within 5.5 source units. Each attack creates an independent instance, so overlaps coexist and tick separately.
- Regrowth is a 5-second-cooldown, 7-range proactive HoT. Recasting refreshes only that Druid's instance on that ally. Different Druids coexist. Regrowth has no up-front heal unless Lifebloom is selected.
- Moonfire damages and reveals enemies in its area, then heals every ally carrying that Druid's active Regrowth once per cast. Qualifying enemy contacts are unique and capped at five for talent calculations.
- Entangling Roots grows from its initial radius over three seconds, damages each contact once, and asks the shared control system to apply Root. Boss immunity and duration profiles remain authoritative.
- Innervate uses two independently recharging charges. It increases the recipient's Q/W/E cooldown recovery rate by 50%; Revitalize applies that benefit to the casting Druid too.
- Tranquility follows the caster, healing allies each second for eight seconds. Regrowth recipients receive 10 Armor through the shared named-Armor system.
- Twilight Dream has its authored delay, damages and Silences nearby enemies, and refreshes the casting Druid's Regrowths. Astral Communion channels, teleports, fires a free Moonfire, then resolves Twilight Dream.

Nature's Swiftness transfers only actual Regrowth overhealing and cannot recursively trigger itself. Nature's Cure removes Stun, Root, and Slow only from the direct targeted Regrowth cast; generated Rejuvenation does not cleanse. Verdant Growth requests a timer-preserving bonus tick rather than resetting periodic cadence. Nature's Communion reads scheduled remaining Regrowth healing rather than reconstructing it from duration.

## Talent and progression contract

The Guild tree contains eight tiers at levels 9, 12, 15, 18, 21, 24, 27, and 30. Level 15 selects Tranquility or Twilight Dream. Level 27 Heroic upgrades enforce the matching Level 15 choice. All IDs and display strings are centralized, and the five Testing Range builds cover baseline, Regrowth throughput, Moonfire/Roots control, Tranquility, and Astral/Twilight play.

Vengeful Roots is encounter-scoped and uses the shared quest-qualified target policy. Training targets, summons, objects, and temporary combatants do not advance it. Completion is not persisted to permanent hero progression in V1.

## Source audit and deliberate conversion decisions

The current source snapshot is Heroes Tool Chest `heroes-data2` release `v2.55.17.97650` (live build `2.55.17.97650`, released 2026-07-25). It supplies the level-1 chassis, current base abilities, current talent identities, and Treant unit data. Blizzard's current hero page and official patch notes were used as authoritative human-readable checks.

Audit references: [Heroes Tool Chest data repository](https://github.com/HeroesToolChest/heroes-data2), [the exact data release](https://github.com/HeroesToolChest/heroes-data2/releases/tag/v2.55.17.97650), [Blizzard's Malfurion page](https://heroes-site-production-eks-prod-use1-01.heroesofthestorm.blizzard.com/en-us/heroes/malfurion/), [May 15, 2025 live notes](https://news.blizzard.com/en-us/article/24205005/heroes-of-the-storm-live-patch-notes-may-15-2025), and [May 9, 2018 patch notes](https://news.blizzard.com/en-us/article/21749146/heroes-of-the-storm-patch-notes-may-9-2018).

Source values retained include 1,525 health, 3.1796 health regeneration, 60 Basic Attack damage, 0.9-second Basic Attack interval, 5.5 attack range, universal 4% scaling, Regrowth's 380 total over 20 seconds, Moonfire's 90 damage / 2-second Reveal / 130 Regrowth heal, Roots' 117 damage / 1.25-second Root / 3-second growth, Tranquility's 80 per second for 8 seconds with 10 Armor, and Twilight Dream's 310 damage / 3-second Silence / 0.5-second delay.

The project brief deliberately overrides several current-source behaviors:

- Innervate has no mana requirement or mana restoration; it is a two-charge cooldown-recovery support action.
- Nature's Cure is a passive targeted-Regrowth cleanse instead of the source game's activated global Regrowth cleanse.
- Nature's Balance uses the brief's 75% Moonfire radius increase rather than the live source's smaller radius bonus.
- Deep Roots and Vengeful Roots use the authored Fantasy Guild progression and secondary-area rules rather than their current source quest/reward behavior.
- Tranquility healing follows the project's periodic-healing and threat rules, while Twilight uses shared Silence and boss-control profiles.
- Flat scalable values use the project's universal 4% per-level policy.

## Testing Range

Open the Testing save, Battle, Testing Zone, then **Druid Range**. It injects the Level 30 `Malfira Greenbough` fixture safely into a four-hero party and creates four wounded/control-ready allies, a five-target enemy cluster, an elite, a Root-immune Boss, summon/temporary fixtures, and a Stealthed target.

- `Shift+1-5` loads the representative builds.
- `F3` toggles source-owned Regrowths, mini-HoTs, Innervate state, cooldown rates, Roots, Treants, channels, quest state, and healing telemetry.
- Test-only `Ctrl` controls provide deterministic Regrowth recipients, cooldown reset, bonus tick, periodic-state clearing, one/four mini-HoTs, outgoing healing/HoT modifiers, health states, control fixtures, quest completion, Treant spawn, Twilight refresh, Tranquility, Lunar Shower, and Nature's Communion.

World-space effects distinguish Regrowth and mini-HoT ticks, Moonfire, growing Roots, Innervate, both Heroics, and Treants. Party portraits show source count for active Regrowths and a separate designation arc.

## Known V1 tuning risks

- Dense Regrowth coverage compounds Moonfire, Wild Growth, Serenity, and Nature's Swiftness; effective healing and overhealing telemetry should guide tuning.
- Multiple Druids' Innervates currently stack multiplicatively through the generic cooldown-rate pipeline.
- Treants are source-owned lightweight combat summons: they move and attack deterministically but are not yet full members of the enemy target-selection/threat entity graph.
- Geometry is centralized for calibration. See `druid_geometry_calibration.md` for the assumptions that still need visual playtesting.
