# Templar V1 Combat Conversion

Templar is a resource-free melee Tank built from the current Artanis combat chassis, plus the narrowly scoped Shield Ally concept. It does not use Tyrael abilities or Phase Prism.

## Identity and scaling

- Level-1 Health: 2,490; regeneration: 5.1875 per second.
- Level-1 Basic Attack: 111 Physical damage every 1.0 second at melee range.
- Health, regeneration, Basic Attack damage, Shielding, healing, and Ability damage use 4% per-level scaling.
- The class uses the project's shared threat, target-category, named-Shield, Block, Armor-reduction, control, and encounter-progression systems.

## Base kit

- **D — Shield Overload:** After hostile damage leaves the Templar below 75% Health, apply a 365 Shield for 5 seconds on a 24-second cooldown. Each successful Basic Attack reduces that cooldown by 4 seconds.
- **Q — Blade Dash:** Travel outward through a swept collision path for 57 damage, then return to the cast origin for 171. Unique contacts reduce D by 1 second, or 2 seconds for elite, named, boss, and enemy-Hero targets.
- **W — Twin Blades:** Charge up to 3.5 source units and execute two real Basic Attack strikes.
- **E — Shield Ally:** Shield the closest other living ally within 10 source units for 420 for 3 seconds. During the full link, the bearer's positive damage generates an equal duplicate of its normal damage threat for the exact casting Templar against the damaged enemy. Invalid casts do not start cooldown.
- **R1 — Suppression Pulse:** Global ground-targeted 114 damage and 4-second Blind.
- **R2 — Purifier Beam:** Global enemy-targeted beam that follows for 8 seconds and deals 184 damage per second while it catches its target.

## Talent contract

The eight talent tiers and IDs are data-driven in `templar_data.gd`. Runtime rules preserve encounter scoping and source ownership:

- Protector of Aiur and Give Me Twenty are encounter-scoped.
- Give Me Twenty advances only when the exact Shield Ally source is completely consumed by hostile damage.
- Shield Ally links carry owner, bearer, and cast identity, so two Templars cannot redirect threat or progression to one another.
- Together We Are Strong uses a single damage bucket per casting Templar and carries fractional remainder.
- Titan Killer uses the Templar's maximum Health plus remaining exact Shield Overload Shield while active; it never reads enemy maximum Health.
- Crosscut creates one rear strike for each real Twin Blades strike and reevaluates a distinct rear-arc target each time.
- Psionic Wound uses the shared strongest-source Armor reduction system and refreshes rather than stacking.

## Testing

The Testing Guild includes Aurex, a level-30 Templar. Combat Hall exposes a dedicated Templar Range with standard, elite, named, summon, temporary, boss, and attacking-defense fixtures.

- `Shift+1` through `Shift+4`: load baseline and representative level-30 builds.
- `Alt+C`: reset cooldowns.
- `Alt+D`: place the Templar below 75% and arm Shield Overload.
- `Alt+Q`: set Protector of Aiur to 100 encounter stacks.
- `Alt+E`: damage allies for Shield Ally testing.
- `F3`: show combat IDs, Templar runtime values, and per-hero threat on the inspected enemy.

Automated coverage lives in `tests/test_templar_system.gd` and the project-wide regression suite.

## Source audit and deliberate project overrides

Primary values were checked against Blizzard's current Artanis hero page and official balance notes. The current hero page still shows an older Shield Overload value, so the official March 29, 2022 patch note is used for the current 365 Shield value. Official July 20, 2021 notes provide the 3.5 Twin Blades charge range, 70-second Purifier Beam cooldown, current Reactive Parry shape, Shield Battery rate, and Final Cut/Blades values.

The conversion brief deliberately changes or clarifies these source mechanics:

- Phase Bulwark is universal 50 Armor rather than Spell Armor.
- Templar's Zeal uses the task-locked 5-second Q cooldown reduction.
- Titan Killer uses the Templar Health basis defined by the brief rather than the source game's enemy-Health formulation.
- Shield Ally is an original project mechanic and is not presented as an Artanis ability.

Sources:

- Blizzard Artanis hero page: https://heroes-site-production-eks-prod-use1-01.heroesofthestorm.blizzard.com/en-us/heroes/artanis/
- Blizzard March 29, 2022 balance patch: https://news.blizzard.com/en-us/heroes-of-the-storm/23787368/heroes-of-the-storm-balance-patch-notes-march-29-2022
- Blizzard July 20, 2021 balance patch: https://news.blizzard.com/en-us/heroes-of-the-storm/23686848/heroes-of-the-storm-balance-patch-notes-july-20-2021
- Blizzard July 25, 2018 balance patch: https://news.blizzard.com/en-us/heroes-of-the-storm/21966705/heroes-of-the-storm-balance-patch-notes-july-25-2018
