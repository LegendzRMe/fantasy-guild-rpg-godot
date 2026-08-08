# Fantasy Guild RPG — Godot Prototype

An original Godot 4 prototype combining manual party control, guild management, zone progression, professions, storage, and mission-table concepts.

## Run

1. Install Godot 4.7 or newer.
2. Double-click `Launch Game.cmd`, or run `./tools/run.ps1` from PowerShell.

You can also import `project.godot` in the Godot editor and press **F6/F5**.

## Current prototype

- Three live guild save slots plus a separate unlocked testing slot, all with deletion confirmation
- Guild Hall progression hub with chained previews for locked systems
- Hero roster with functional equipment comparison/equip flow, stats, abilities, tooltips, professions, and Hero Prestige
- Drag-and-drop team builder with named saved teams
- Full-screen world map and zone encounter paths
- Multi-wave real-time combat with manual movement and targeting
- Guardian, Cleric, Rogue, Ranger, Mage, Warlock, Slayer, and testing-only Priest roles
- A data-driven, replayable Ashwood Marches campaign with seven mandatory encounters and a two-encounter optional branch
- Narrative recruit decisions, objective battles, equipment rewards, and a permanent Special Hero choice
- Enemy roles, boss telegraphs, and staged victory rewards
- Command Table foundation for automated hero missions
- Classic-era profession list and crafting placeholders
- Item storage grid, bags, capacity upgrades, and organization controls
- Merchant Contacts foundation
- A dedicated testing Vault containing ten unequipped Legendary items for combat-system validation
- A testing-zone launcher with the general Dummy Range, dedicated Warlock and Rogue ranges, and a fixed-level Endless Arena

## Combat controls

- Drag a hero to reposition them or assign a target.
- Clerics can target allies to heal.
- **Q/W/E/R** activate abilities.
- **Mouse wheel** cycles selected heroes; **Tab** cycles living enemy targets.
- **F3** toggles the Shared Combat Rules debug overlay in the testing range.
- Click the pause button to resume or retreat.

In the testing save, select **TESTING** on the world map to choose the Dummy Range, a class range, or Endless Arena. The Rogue Range includes ordinary targets and a detector Boss for Combo Point, opener, Armor-reduction, and concealment testing. Slayer Range includes target-category, safe-landing, blocker, multi-target, Evasion, and sustain fixtures; `Shift+1..9` and `Shift+0` load its ten representative builds. Priest Range includes mixed target categories, automatic-heal positioning fixtures, Spirit controls, and three representative builds on `Shift+1..3`. Endless Arena continuously replaces defeated enemies at the selected level without increasing that level or awarding test-fight resources.

The project uses original placeholder systems and artwork. Names, UI, game rules, and assets are subject to change during development.

## Development

Architecture, ownership boundaries, save invariants, and refactoring rules are documented in [`docs/architecture.md`](docs/architecture.md). The complete documentation catalog is in [`docs/README.md`](docs/README.md).

Run the complete local validation suite from PowerShell:

```powershell
.\tools\validate.ps1
```

The validator uses isolated Godot user data and does not modify normal guild saves.

Generate a maintainability and asset-size snapshot with:

```powershell
.\tools\audit.ps1
```

Capture repeatable Guild Hall, testing-range, and busy Endless Arena update-time baselines with:

```powershell
.\tools\profile.ps1
```

Capture visible, uncapped renderer throughput, draw calls, primitives, memory, and graphics-adapter details with:

```powershell
.\tools\profile-graphics.ps1
```

To produce a validated Windows release, install the matching official export templates once and then build:

```powershell
.\tools\install_export_templates.ps1
.\tools\build.ps1
```

The release is written to `build/windows` with a `build-info.json` containing the project version, Git build ID, engine version, and UTC build time. `Launch Build.cmd` provides the same build path by double-click. GitHub Actions runs the complete validator and preserves the audit report for every push and pull request.

Shared Combat Rules v1, its test-range layout, tuning values, and acceptance matrix are documented in [`docs/shared_combat_rules_v1.md`](docs/shared_combat_rules_v1.md).
