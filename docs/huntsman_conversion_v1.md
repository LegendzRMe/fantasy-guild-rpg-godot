# Huntsman conversion V1

Huntsman is a mechanics-first, Greymane-inspired hybrid damage class built from original project names, UI, presentation, and implementation. It exists only in the Testing save and is not added to starter, campaign, or recruitment content.

## Architecture

- `huntsman_data.gd` owns audited chassis values, names, geometry constants, talent definitions, and test builds.
- `huntsman_system.gd` owns pure form, cooldown, Inner Beast, mark, talent, and telemetry rules.
- `huntsman_runtime.gd` owns battlefield targeting, projectiles, movement, damage calls, and temporary visuals.
- `huntsman_ability_presenter.gd` owns player-facing ability cards.
- `test_huntsman_system.gd` covers deterministic rules without requiring a live battle.

The class uses `AlternateActionSetSystem` rather than duplicating six ability slots. Human and Worgen Q have independent cooldown fields; both E actions read and write one shared cooldown. W persists through form changes. The passive Trait is not manually activatable.

## Source and project decisions

The current chassis and base abilities were audited against the current Heroes Tool Chest data and Blizzard's current Greymane page. Flat stats use the project's universal 4% per-level scaling even where the source game historically used a different health-growth rule.

Marked for the Kill is intentionally reconstructed as a hybrid test Heroic because Blizzard removed it in 2017. V1 uses the last official 190 flat damage value, the original reactivation-era 60-second cooldown, and a long 11-source-unit projectile range. Its custom stacking Armor reduction is original project behavior, not a claim about the historical source ability.

## Forms and cooldowns

- Human: ranged Basic Attack; Cocktail / Inner Beast / Darkflight.
- Worgen: melee Basic Attack, +40% additive Basic Attack damage, level-scaled Armor; Swipe / Inner Beast / Disengage.
- Darkflight and Go for the Throat can enter Worgen.
- Disengage and Marked for the Kill can enter Human.
- Form events are emitted only for actual changes and record previous/new form, source, cast ID, time, and combat ID.
- Gilnean Cocktail and Razor Swipe continue cooling down while hidden.
- Darkflight and Disengage always share one cooldown.

## Mark ownership

Each Huntsman owns at most one marked enemy. A new mark replaces its prior state. One source-aware Armor-reduction entry grows with the stack count, while different Huntsmen still follow the shared strongest-source rule. Baseline marks last 5 seconds and cap at 5 stacks. Gilnean Roulette removes the raw cap, changes duration to 3 seconds, and qualifying actions refresh that duration. Shared Armor floors still apply.

## Quest scope

Incendiary Elixir progression is encounter-scoped. Only shared quest-qualified targets count. Training targets, summons, objects, and temporary combatants are excluded. Completion is not written to permanent hero progression in V1.

## Testing controls

Open the Testing save, Battle, Testing Zone, then **Huntsman Range**.

- `Shift+1` Level 1 Human baseline
- `Shift+2` Human Cocktail / Mark build
- `Shift+3` Worgen brawler build
- `Shift+4` form-duration / Wizened build
- `Shift+5` completed Incendiary quest build
- `F3` toggles the shared combat debug overlay

Test-only `Ctrl` shortcuts: `H/W` force form, `C` resets cooldowns, `I` activates/readies Inner Beast, `B` toggles two Blocks, `S` toggles Stealth, `Q` cycles quest progress, `M` applies/clears Mark, `R` toggles its reactivation, `G` toggles Roulette, `P` enables Pounce, `V` cycles Wizened charges, `L` cycles target control, `A` cycles target Armor, and `1-5` set Mark stacks to 1/4/5/10/25. Shortcuts affect the focused enemy, or the first living fixture when none is focused.

The range contains standard, elite, named, Boss, enemy-Hero-style, summon, temporary, training, Armor, control, detector, and non-detector fixtures. Dummies remain displacement-immune through their existing profiles.
