# Project Architecture

This project intentionally uses one main scene and a small set of stateless helper modules. `main.gd` remains the runtime coordinator while low-state and pure responsibilities are extracted gradually.

## Ownership

### `scripts/main.gd`

Owns live scene state and coordinates the prototype:

- Screen navigation and current menu composition
- Guild creation and save-slot routing
- Team drag-and-drop presentation
- World-map and zone-map interaction
- Ashwood encounter presentation, combat state, simulation, input, targeting, drawing, and the battlefield-preserving rewards/decision/consequence overlay flow
- Tutorial state, restrictions, recovery, prompts, and tutorial-specific drawing
- Forwarding functions that keep existing call sites stable while delegating pure work

Combat and tutorial behavior deliberately remain together because tutorial restrictions currently cross combat input, simulation, targeting, and drawing.

### `scripts/data/game_data.gd`

Owns immutable prototype definitions:

- Classes, abilities, targeting categories, ranges, and descriptions
- Enemy definitions and enemy construction defaults
- World-map and zone-map definitions
- Mission, merchant, profession, and storage definitions

Runtime progress does not belong in this file.

### `scripts/data/ashwood_data.gd`

Owns immutable Zone Zero definitions: encounter order and map positions, scenarios, objectives, enemy waves, first-clear and repeat rewards, narrative decisions, recruits, Special Hero candidates, rarity colours, and equipment names. Narrative consequences are data, not UI conditionals.

### `scripts/systems/ashwood_manager.gd`

Owns pure Ashwood progression defaults, compatibility migration, encounter unlock/completion state, decision effects, optional-branch discovery, replay counters, and finale composition. It does not own combat nodes, screen composition, random rewards, or persistence.

### `scripts/systems/save_manager.gd`

Owns save paths, live and testing defaults, JSON persistence, compatibility migration, and deletion.

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

Do not replace the dictionary-based save format with Godot resources unless a separately planned migration protects existing JSON saves.

### `scripts/systems/team_manager.gd`

Owns pure team-membership and saved-team array operations. It does not own drag-and-drop, UI nodes, or persistence.

Team invariants:

- Hero indices refer to entries in the save's `heroes` array.
- Active teams contain at most four heroes.
- Pure operations return copied arrays rather than mutating their inputs.

### `scripts/systems/roster_manager.gd`

Owns pure hero filtering and sorting. Filter controls, selected roster state, pagination, and roster screen composition remain in `main.gd`.

### `scripts/ui/ui_factory.gd`

Owns small reusable Godot control and theme constructors. Complete menus and screen-specific layouts remain in `main.gd` until they have a stable interface worth extracting.

### `tests/` and `tools/validate.ps1`

The tests protect save defaults and migration, per-save settings, team behavior, roster queries, Ashwood progression and data shape, guild-system locks, and the four-card save menu. The validator runs tests with an isolated `APPDATA`, so it cannot modify normal Godot user saves.

## Dependency Direction

`main.gd` may depend on data, systems, and UI helpers. Pure systems may depend on immutable data when necessary, but they must not depend on `main.gd` or live scene nodes.

```text
main.gd
  |-- data/game_data.gd
  |-- data/ashwood_data.gd
  |-- systems/ashwood_manager.gd
  |-- systems/save_manager.gd
  |-- systems/team_manager.gd
  |-- systems/roster_manager.gd
  `-- ui/ui_factory.gd
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

- Preserve public forwarding functions when moving behavior out of `main.gd`.
- Extract pure or low-state behavior before stateful scene coordination.
- Add or update a focused test before changing save, team, roster, tutorial, or combat invariants.
- Reformat only the functions being changed; avoid repository-wide formatting diffs.
- Keep gameplay tuning, tutorial flow, controls, visual layout, and save migration outside cleanup-only changes.
- Track each `.gd.uid` file with its corresponding GDScript so Godot resource identities remain stable.
