# Shaman Combat Conversion V1

Shaman is a melee Physical basic-attacker with no mana resource. Its ability power, health, and ability values use the shared 4% per-level scaling policy. The class definition, stable IDs, geometry constants, talents, and test builds live in `scripts/data/shaman_data.gd`; pure state transitions live in `scripts/systems/shaman_system.gd`; battle-world resolution lives in `scripts/runtime/shaman_runtime.gd`.

## Baseline kit

- **Frostwolf Resilience (D):** successful basic and ability events add stacks. Every five stacks independently resolves a heal, retaining overflow stacks.
- **Chain Lightning (Q):** deterministic nearest-target chaining with sequential charges and centralized quest attribution.
- **Feral Spirit (W):** a real traveling line entity that roots contacts and extends its remaining travel distance for successful contacts.
- **Windfury (E):** temporary movement speed and three accelerated basic attacks.
- **Sundering / Earthquake (R):** authored displacement/pathing and pulsing ground-control heroics.

## Talent and quest rules

The final talent tiers are defined at levels 9, 12, 15, 18, 21, 24, 27, and 30. Level-9 talents store two distinct scopes: permanent per-hero mastery and resettable encounter progress. A room or wave transition preserves encounter progress; ending or abandoning an encounter clears it. Summoned and temporary targets do not advance quest counters unless a talent explicitly says otherwise. Secondary and spawned effects use source tags so they cannot recursively trigger parent casts or double-award progress.

## Test range

The Shaman Range supplies clustered targets, named/elite/summon categories, a control-resistant Boss, a defensive dummy, and a movement blocker. `Shift+1..3` selects the level-1 baseline, Stormcaller Pack, and Fury Wolf builds. The `Alt` shortcuts described in the README expose thresholds and progression scopes without bypassing the production combat path.

## Source and tuning note

Baseline reference values were reconciled against the official 2025–2026 Heroes of the Storm patch notes and the current live extracted data in [HeroesToolChest/heroes-data](https://github.com/HeroesToolChest/heroes-data). Where the implementation brief specifies a different contract, the brief wins. All names and numbers remain prototype tuning data.
