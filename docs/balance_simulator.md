# Numerical Balance Simulator

The balance simulator is a developer tool. It runs combat math without loading the battlefield, drawing characters, waiting for animations, or changing a guild save. Its purpose is to compare numerical output quickly and repeatably while classes are authored.

## Run it

### Visual Balance Lab

Double-click `Launch Balance Lab.cmd` in the project folder. This opens a standalone Godot testing window where you can choose scenarios, prototype builds, hero level, run count, and random seed; run comparisons; inspect per-action results; and open the exported report folder. It does not open or modify a guild save.

The Balance Lab has its own scene (`balance_lab.tscn`) and small UI components under `scripts/balance_lab/`. It is intentionally independent from the main game coordinator and can later be exported as a standalone `.exe` without moving simulator logic into the UI.

### Command-line option

From the project root in PowerShell:

```powershell
.\tools\run_balance_simulation.ps1
```

Useful options:

```powershell
.\tools\run_balance_simulation.ps1 -Iterations 500 -Level 15 -Seed 1337
```

The command writes `latest.json` for detailed inspection and `latest.csv` for spreadsheets. By default, the external folder is created beside the project as `WoW Battleheart Balance Reports`; `-OutputDirectory` can override it. The seed makes repeated runs reproducible. Using the same seeds across builds also makes comparisons less noisy.

## Permanent and temporary parts

Permanent framework:

- Standard scenario timing and targets
- Seeded critical-hit randomness
- Shared final-stat, Armor, damage, and healing resolution from `combat_system.gd`
- Cooldowns, priority ordering, action lockouts, and multi-target action counts
- DPS/HPS, raw output, effective output, waste/overhealing, variance, percentiles, critical rate, casts, results, and per-action breakdowns
- JSON and CSV reports

Temporary data:

- Current prototype class chassis
- Current Basic Action values
- Any synthetic action used only by automated tests

The default report is named **Prototype Basic Action Baselines** and contains a warning so it cannot reasonably be mistaken for final class balance.

## Adding class actions later

A build supplies an `actions` array. Each action can declare:

```gdscript
{
	"action_id":"example_arc_bolt",
	"result_category":"damage", # damage or healing
	"source_action":"basic_ability", # basic_ability or heroic
	"power_coefficient":1.5,
	"flat_bonus":0.0,
	"cooldown":6.0,
	"initial_delay":0.0,
	"lockout":0.25,
	"priority":1,
	"damage_type":"magical",
	"can_crit":true,
	"max_targets":1
}
```

This is deliberately data, not class-specific simulator code. Later class resources, conditional priorities, periodic effects, summons, buffs, debuffs, talents, and item passives can extend the build/action contract without replacing report generation or the canonical combat calculations.

## Interpretation limits

The numerical simulator can compare damage and healing under controlled assumptions. It cannot decide whether crowd control, mobility, protection, threat, range, difficulty, utility, or a play style is fun. Those require separately designed scenarios, live playtesting, and eventually an automated battlefield simulator that includes movement and targeting.
