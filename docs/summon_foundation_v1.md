# Summon foundation V1

Druid V1 introduces a deliberately small source-owned summon foundation for Vengeful Roots Treants.

Each Treant records a stable summon ID, owner/source ID, position, level-scaled health, maximum health, lifetime, health decay, movement speed, attack range, acquire range, attack interval, damage, target category, and test/progression tags. Runtime updates are deterministic: choose the nearest living enemy, break equal-distance ties by combat ID, move toward range, and attack through `deal_damage` with `summon` action identity and the Druid as owner.

The audited current unit values are 550 health, 50 health decay per second (an 11-second natural lifetime), 58 attack damage, 1-second attack interval, and 4.8007 source units/second movement. Health and damage use the project's universal 4% level scaling for consistency, even though the current source unit record reports no explicit Treant damage scaling field.

Treants are rendered with a persistent world marker and health bar, plus spawn and attack effects. Their damage is source-attributed for items and telemetry. They are categorized as summons and excluded by shared quest qualification.

Treants remain lightweight owner-runtime records and are not enemy-targetable in V1. Death Knight Ghouls and Beastmaster companions extend the shared combat-ID and player-summon registry: enemies can select, damage, and defeat a nearer owned Ghoul, Misha, Lesser Beast, or Greater Beast without placing transient summons in guild saves.

Beastmaster also adds the reusable Health-decay lifecycle. A disposable beast owns original Health, current Health, maximum Health, and decay per second; remaining natural lifetime is derived from current Health rather than maintained as a second hard timer. This prevents Fresh protection, hostile damage, healing exclusions, Pack Vitality, and Warrior anti-summon effects from producing two competing expiry clocks. Misha is permanent, ordinarily healable, and explicitly has neither decay nor a finite lifetime.

Current limitation: summon records are still owner-runtime entities rather than members of the top-level hero array. Shared lookup, enemy targeting, area damage, rendering, owner attribution, and defeat handling use the registry, but hero-index-only manual ally selection remains reserved for heroes. Pathing uses shared blocker-safe movement; threat remains attributed to the owning hero.
