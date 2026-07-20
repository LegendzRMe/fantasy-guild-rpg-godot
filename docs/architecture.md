# Project Architecture

This project uses one main scene with focused data, system, runtime, and screen modules. `main.gd` is intentionally a one-line scene entry point; the application is assembled from small inheritance layers so each feature can be found and edited without loading the entire game coordinator.

## Ownership

### `scripts/main.gd`

Extends `combat_presentation.gd` and is the stable script attached to the main scene. It should not accumulate feature implementations.

### `scripts/runtime/app_state.gd`

Owns mutable application, menu, map, tutorial, item-overlay, and combat state declarations inherited by `main.gd`. It contains no navigation or gameplay behavior. This separation keeps the coordinator searchable without changing its public API or scene ownership.

### Application and screen layers

- `scripts/runtime/app_core.gd`: startup, saves, shared controls, navigation, Guild Hall, settings, filters, and cross-screen input.
- `scripts/ui/hero_roster_screen.gd`: Hero Roster, equipment slots, item cards, equipment comparison, and item/hero selectors.
- `scripts/ui/team_builder_screen.gd`: active-team selection, naming, and Team Builder layout.
- `scripts/ui/world_map_screen.gd`: world/zone maps, Ashwood encounter selection, Command Table, Merchant Contacts, and Professions.
- `scripts/ui/item_storage_screen.gd`: Item Storage filters, sorting, bag unlocks, and vault layout.
- `scripts/runtime/app_shell.gd`: stable one-line bridge from screen layers into combat layers.

### Combat and story layers

- `scripts/runtime/battle_setup.gd`: battle initialization, formations, testing arena, and Ashwood encounter setup.
- `scripts/runtime/tutorial_controller.gd`: tutorial steps, prompts, recovery, and progression checks.
- `scripts/runtime/shared_combat_runtime.gd`: stable combat-ID lookup, explicit hero commands, Basic Action timing, casts/channels, projectiles, hit nudges, incapacitation, revive hooks, and narrow extension contracts.
- `scripts/runtime/item_combat_runtime.gd`: damage, healing, shields, threat creation, timed item effects, and passive item triggers.
- `scripts/runtime/enemy_combat_runtime.gd`: waves, spawning, encounter objectives, enemy target selection, and combat lookup helpers.
- `scripts/runtime/ability_runtime.gd`: temporary class ability execution and cast-position resolution.
- `scripts/runtime/combat_input_runtime.gd`: combat selection, drag commands, ability aiming, keyboard, mouse, touch, and tutorial input gates.
- `scripts/runtime/combat_runtime.gd`: thin live-combat update coordinator; feature behavior belongs in the focused layers above.
- `scripts/runtime/ashwood_runtime.gd`: recruits, Ashwood rewards, story decisions, and encounter-result overlays.
- `scripts/runtime/victory_runtime.gd`: generic victory sequencing, XP animation, and reward grants.
- `scripts/runtime/combat_presentation.gd`: battlefield, tutorial, effect, health-bar, role-icon, and victory drawing.

These layers preserve the original method API through narrow contracts. That lets existing callbacks and saves behave the same while keeping each combat concern searchable without loading a monolithic coordinator.

### `scripts/data/game_data.gd`

Owns immutable prototype definitions:

- Classes, abilities, targeting categories, ranges, and descriptions
- Enemy definitions and enemy construction defaults
- World-map and zone-map definitions
- Mission, merchant, profession, and storage definitions

Runtime progress does not belong in this file.

### `scripts/data/class_data.gd`

Owns the editable class and archetype authoring surface: stable IDs, roles, Basic Actions, traits, Q/W/E/Heroic IDs, combat chassis, AI tags, proficiencies, and temporary ability presentation. New class design should begin here without editing combat, saves, roster UI, or world data.

### `scripts/data/talent_data.gd`

Owns the shared ability and talent milestones plus tier structure. Future class-specific talent content can be added beside this foundation without duplicating unlock levels in UI or combat code. `game_data.gd` retains compatibility aliases so existing consumers do not need a broad rewrite.

### `scripts/data/ashwood_data.gd`

Owns immutable Zone Zero definitions: encounter order and map positions, scenarios, objectives, enemy waves, first-clear and repeat rewards, narrative decisions, recruits, Special Hero candidates, rarity colours, and equipment names. Narrative consequences are data, not UI conditionals.

### `scripts/systems/ashwood_manager.gd`

Owns pure Ashwood progression defaults, compatibility migration, encounter unlock/completion state, decision effects, optional-branch discovery, replay counters, and finale composition. It does not own combat nodes, screen composition, random rewards, or persistence.

### `scripts/systems/save_manager.gd`

Owns save paths, live and testing defaults, verified temporary writes, last-known-good backups, JSON persistence, compatibility migration, malformed-field repair, and deletion.

Save invariants:

- Slots 1–3 are live guild slots.
- Slot 4 is the dedicated testing slot.
- A new live guild starts with zero gold, Brann, Sera, and an incomplete tutorial.
- After the tutorial, a new live guild exposes Battle and Heroes. Other major systems remain visible beneath crossed chains and a centered padlock.
- The Vault unlocks after the Raider Cache. Party Management unlocks after the permanent Special Hero choice.
- The testing guild includes all current normal recruits and Special Hero candidates, with progression gates unlocked.
- Older four-hero testing saves that predate `major_systems_unlocked` migrate to the unlocked state.
- Casting preferences remain inside each guild save.
- `user://guild_save.json` remains a supported legacy load path for slot 1.
- Missing legacy fields are added without discarding fields already present in the save.
- Hero levels are clamped through the shared combat level cap during migration.
- Gold and `prestige_tokens` are the only guild currencies. The undefined prototype `tokens` value is discarded rather than converted during migration.
- Every hero owns a stable `hero_id`, stable `class_id`, Standard/Special identity metadata, one planned talent per tier, selected talents, six equipment-slot references, and canonical Prestige fields. Legacy `legacy_rank` remains readable and migrates into `prestige_rank`.
- `class_talent_discovery` permanently records the highest level reached by each class. The testing guild reveals every current class through Level 30.
- Saved parties are sanitized in order: invalid references, duplicate heroes, and later Heroes whose class is already present are removed.
- The ten Legendary foundation items are seeded only into the testing guild, one copy each, and always begin in the Vault rather than auto-equipped.

Do not replace the dictionary-based save format with Godot resources unless a separately planned migration protects existing JSON saves.

### `scripts/systems/team_manager.gd`

Owns pure team-membership, ordered-slot reordering, and saved-team array operations. It does not own drag-and-drop, formation UI, combat nodes, or persistence.

Team invariants:

- Hero indices refer to entries in the save's `heroes` array.
- Active teams contain at most four heroes.
- A roster may contain duplicate classes, but each four-Hero party contains at most one Hero of each class. Raids validate this rule independently for each party.
- Team array order is meaningful: slots one through four deploy at the front, top, bottom, and back of the combat diamond.
- Pure operations return copied arrays rather than mutating their inputs.

### `scripts/systems/roster_manager.gd`

Owns pure hero filtering and sorting. Filter controls, selected roster state, pagination, and roster composition live in the application/screen layers.

### `scripts/data/item_data.gd`

Owns immutable equipment and passive definitions, JSON-safe item-instance construction, equipment-slot compatibility checks, ownership reconciliation, atomic equip/unequip operations, and item tooltip composition. It does not own hero UI nodes or live combat actors.

Equipment slots are `weapon`, `head`, `chest`, `hands`, `neck`, and `trinket`. Item instances use `owner_state` plus `equipped_hero_index` as their saved ownership record; hero slot references remain the authoritative equipped layout. Compatibility is data-driven through armor families, weapon families, and narrowly declared testing exceptions.

### `scripts/systems/combat_system.gd`

Owns pure runtime stat resolution, the isolated level-aware Armor curve, weapon-family profiles, damage/healing/shield resolution, combat-event construction, passive trigger evaluation, per-item internal cooldowns, charge helpers, named-effect stacking, and shared threat math. It does not own encounter timing, targeting, animation, or scene-tree state.

Combat and UI consumers must use `calculate_final_stats()` rather than rebuilding class, level, equipment, buff, or debuff math locally. Legacy `gear` save values remain compatibility data and are not inputs to final combat stats.

Combat terminology is deliberately split between exact action sources and reusable grouping tags:

- `basic_attack` is an automatic attack against an enemy.
- `basic_heal` is an automatic heal on an ally.
- `basic_ability` covers Q, W, and E abilities; `heroic` covers R abilities.
- `basic_action` is an internal grouping tag attached to both Basic Attack and Basic Heal events. It is not an action source and should not normally appear in player-facing item text.
- Each class declares one canonical Basic Action type (`attack` or `heal`), coefficient, interval, and range. Items that modify Power or Basic Action speed therefore affect attacks and heals through the same stat pipeline without conflating their event names.

Combat invariants:

- The level cap is 30. Health and Power use three-percent exponential growth from level one.
- Weapon families modify only Basic Action amount and interval; Basic Abilities and Heroics scale from Power without inheriting weapon profiles.
- Armor reduction is `Armor / (Armor + 100 + 10 * attacker level)`, capped at 75 percent. True Damage bypasses Armor.
- Shields are removed before Health and preserve their creator so absorbed damage can generate creator threat.
- Resolved damage creates one threat per point. Effective healing creates 0.5 total threat and absorbed shielding creates 0.25 total threat, distributed across living threat-aware enemies.
- A nearby challenger needs 110 percent of the current target's threat; a distant challenger needs 130 percent. Guardian threat uses the class-defined five-times modifier.

### Shared Combat Rules v1

- `scripts/combat/combat_rules_v1.gd` owns command/Basic Action enums, runtime-field initialization, state transitions, and the central v1 tuning values.
- `scripts/combat/combat_geometry.gd` owns battle bounds, rectangular blockers, line-of-sight checks, collision-safe movement, firing-angle probes, and small physical nudges.
- `scripts/combat/combat_projectile.gd` owns the reusable straight world-space projectile record and travel progression.
- Runtime dictionaries remain the prototype representation. Stable `combat_id` values are authoritative for assignments and projectile targets; legacy array-index fields remain compatibility data for existing UI, abilities, threat, and story code.
- Player-controlled heroes never choose a distant target automatically. Only fully idle heroes may perform a Basic Action against an enemy inside the small self-defense radius. Independent story allies retain their existing autonomous behavior.
- Normal abilities preserve and restore the assigned Basic Action target. The shared runtime also exposes pre-effect cast and active-channel hooks with the v1 interruption cooldown rules; current temporary class kits remain instant.

### Balance simulation

- `scripts/data/simulation_data.gd` owns reusable benchmark scenarios and clearly labeled temporary prototype builds.
- `scripts/systems/balance_simulator.gd` runs deterministic, headless numerical damage/healing trials through `combat_system.gd`. It accepts future abilities and rotations as data and does not depend on scene nodes, combat animation, input, or saves.
- `scripts/systems/balance_reporter.gd` exports the resulting summaries and per-action breakdowns without owning simulation rules.
- `tools/run_balance_simulation.gd` and `tools/run_balance_simulation.ps1` provide the developer command. The PowerShell command writes `latest.json` and `latest.csv` to a sibling `WoW Battleheart Balance Reports` folder by default, outside Godot's asset scanner and Git worktree.
- `docs/balance_simulator.md` documents the build/action contract, output metrics, and interpretation limits for future class authoring.
- `balance_lab.tscn` is the standalone visual developer tool. Its focused files in `scripts/balance_lab/` own setup controls, build selection, result display, and thin orchestration; they do not duplicate combat math or alter the main game coordinator.

The numerical simulator measures output under controlled assumptions; it does not assign a value to utility, movement, crowd control, survivability, difficulty, or fun. A future automated battlefield simulator should reuse the same combat math but remain a separate layer.

### `scripts/systems/prestige_system.gd`

Owns canonical zero-to-five Hero Prestige access, requirement checks, team aggregation, and five-star presentation. Future unlock checks should call these helpers rather than reading `prestige_rank` directly.

### `scripts/systems/talent_system.gd`

Owns level milestones, permanent class-wide talent discovery, per-Hero planned hearts, tier selection/replacement/clearing, Heroic-upgrade validation, and legal-build generation. Planned hearts have no gameplay effect and disappear from a tier after its real talent is selected.

### `scripts/systems/prestige_reward_system.gd`

Owns editable Prestige reward/cache definitions, class-compatible cache filtering, non-retroactive Named/Special Hero reward floors, and atomic idempotent claims. A full Vault leaves the rank reward unclaimed and retryable.

### `scripts/ui/ui_factory.gd`

Owns small reusable Godot control and theme constructors. Complete layouts live in their focused screen modules.

### `scripts/ui/item_card_view.gd`

Owns the shared, viewport-bounded item-card presentation used by Item Storage, Hero Roster equipment, Merchant Contacts, and equipment-selection overlays. The view renders data and emits actions; item ownership and persistence remain in the data and system layers.

### `tests/` and `tools/validate.ps1`

The tests protect save defaults and migration, per-save settings, equipment ownership, canonical combat math and terminology, all ten Legendary item definitions and live runtime effects, Prestige helpers, team behavior, roster queries, Ashwood progression and data shape, guild-system locks, and the four-card save menu. The validator runs tests with an isolated `APPDATA`, so it cannot modify normal Godot user saves.

## Dependency Direction

Runtime and screen layers may depend on data, systems, and UI helpers. Pure systems may depend on immutable data when necessary, but they must not depend on runtime/screen layers or live scene nodes.

```text
main.gd -> runtime/combat_presentation.gd
  -> runtime/victory_runtime.gd
  -> runtime/ashwood_runtime.gd
  -> runtime/combat_runtime.gd
  -> runtime/combat_input_runtime.gd
  -> runtime/ability_runtime.gd
  -> runtime/enemy_combat_runtime.gd
  -> runtime/item_combat_runtime.gd
  -> runtime/shared_combat_runtime.gd
  -> runtime/tutorial_controller.gd
  -> runtime/battle_setup.gd
  -> runtime/app_shell.gd
  -> ui/item_storage_screen.gd
  -> ui/world_map_screen.gd
  -> ui/team_builder_screen.gd
  -> ui/hero_roster_screen.gd
  -> runtime/app_core.gd
  -> runtime/app_state.gd
  |-- data/game_data.gd
  |-- data/class_data.gd
  |-- data/talent_data.gd
  |-- data/ashwood_data.gd
  |-- data/item_data.gd
	|-- data/simulation_data.gd
  |-- systems/ashwood_manager.gd
  |-- systems/combat_system.gd
	|-- systems/balance_simulator.gd
	|-- systems/balance_reporter.gd
  |-- systems/prestige_system.gd
  |-- systems/prestige_reward_system.gd
  |-- systems/talent_system.gd
  |-- systems/save_manager.gd
  |-- systems/team_manager.gd
  |-- systems/roster_manager.gd
  |-- ui/ui_factory.gd
  `-- ui/item_card_view.gd
```

## Validation

From the project root in PowerShell:

```powershell
.\tools\validate.ps1
```

If Godot cannot be discovered automatically:

```powershell
.\tools\validate.ps1 -GodotPath "C:\Path\To\Godot.exe"
```

The validator performs:

1. Headless Godot editor parsing
2. Automated GDScript tests in isolated user data
3. A short headless project startup
4. Runtime-log error inspection
5. `git diff --check`

## Refactoring Rules

- Preserve public method contracts when moving behavior between application layers.
- Extract pure or low-state behavior before stateful scene coordination.
- Add or update a focused test before changing save, team, roster, tutorial, or combat invariants.
- Reformat only the functions being changed; avoid repository-wide formatting diffs.
- Keep gameplay tuning, tutorial flow, controls, visual layout, and save migration outside cleanup-only changes.
- Track each `.gd.uid` file with its corresponding GDScript so Godot resource identities remain stable.
