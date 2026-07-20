# Balance Simulator Output

Run the headless numerical simulator from the project root:

```powershell
.\tools\run_balance_simulation.ps1
```

Its latest JSON and CSV reports are written beside the project in `WoW Battleheart Balance Reports`. Keeping them outside the Godot project prevents CSV output from being imported as a game asset. The reports contain local measurements, not game save data.

Current command options:

```powershell
.\tools\run_balance_simulation.ps1 -Iterations 500 -Level 15 -Seed 1337
```

The default builds are explicitly temporary Basic Action baselines. Final abilities, talents, rotations, class resources, positioning, passive effects, and utility must be added as their design data becomes authoritative.
