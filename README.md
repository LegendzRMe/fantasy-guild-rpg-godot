# Fantasy Guild RPG — Godot Prototype

An original Godot 4 prototype combining manual party control, guild management, zone progression, professions, storage, and mission-table concepts.

## Run

1. Install Godot 4.7 or newer.
2. Import `project.godot`.
3. Press **F6/F5** or select **Run Project**.

## Current prototype

- Three live guild save slots plus a separate unlocked testing slot, all with deletion confirmation
- Guild Hall progression hub with chained previews for locked systems
- Hero roster with functional equipment comparison/equip flow, stats, abilities, tooltips, professions, and Hero Prestige
- Drag-and-drop team builder with named saved teams
- Full-screen world map and zone encounter paths
- Multi-wave real-time combat with manual movement and targeting
- Guardian, Cleric, Rogue, Ranger, Mage, and Warlock roles
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

In the testing save, select **TESTING** on the world map to choose the Dummy Range, a class range, or Endless Arena. The Rogue Range includes ordinary targets and a detector Boss for Combo Point, opener, Armor-reduction, and concealment testing. Endless Arena continuously replaces defeated enemies at the selected level without increasing that level or awarding test-fight resources.

The project uses original placeholder systems and artwork. Names, UI, game rules, and assets are subject to change during development.

## Development

Architecture, ownership boundaries, save invariants, and refactoring rules are documented in [`docs/architecture.md`](docs/architecture.md).

Run the complete local validation suite from PowerShell:

```powershell
.\tools\validate.ps1
```

The validator uses isolated Godot user data and does not modify normal guild saves.

Shared Combat Rules v1, its test-range layout, tuning values, and acceptance matrix are documented in [`docs/shared_combat_rules_v1.md`](docs/shared_combat_rules_v1.md).
