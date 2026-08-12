# Summon foundation V1

Druid V1 introduces a deliberately small source-owned summon foundation for Vengeful Roots Treants.

Each Treant records a stable summon ID, owner/source ID, position, level-scaled health, maximum health, lifetime, health decay, movement speed, attack range, acquire range, attack interval, damage, target category, and test/progression tags. Runtime updates are deterministic: choose the nearest living enemy, break equal-distance ties by combat ID, move toward range, and attack through `deal_damage` with `summon` action identity and the Druid as owner.

The audited current unit values are 550 health, 50 health decay per second (an 11-second natural lifetime), 58 attack damage, 1-second attack interval, and 4.8007 source units/second movement. Health and damage use the project's universal 4% level scaling for consistency, even though the current source unit record reports no explicit Treant damage scaling field.

Treants are rendered with a persistent world marker and health bar, plus spawn and attack effects. Their damage is source-attributed for items and telemetry. They are categorized as summons and excluded by shared quest qualification.

V1 limitation: Treants are lightweight owner-runtime records rather than first-class entries in the hero/enemy entity arrays. Enemy threat selection cannot target or damage them yet, and they do not path around blockers. A future shared summon entity graph should preserve owner attribution, category tags, deterministic targeting, defeat hooks, and serialization boundaries before broadening this foundation to other classes.
