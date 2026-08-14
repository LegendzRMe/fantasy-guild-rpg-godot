# Beastmaster (Rexxar) conversion V1

Lifecycle: conversion specification and implementation audit. Implemented on `feature/beastmaster-rexxar-summons-conversion-v1`.

## Outcome and source audit

Beastmaster is a resource-free Ranged DPS class built around Rexxar and a permanent, independently targetable Misha. The live-source baseline was rechecked against HeroesToolChest `heroes-data2` release [`v2.55.17.97771`](https://github.com/HeroesToolChest/heroes-data2/releases/tag/v2.55.17.97771), published 2026-08-14.

The implementation preserves Rexxar's 1,810 Health, 3.7695 regeneration, 134 Basic Attack damage, 1.15-second interval, 5.5 range, 4.8398 movement speed, and 0.875 radius. Misha preserves 1,520 Health with 4.75% scaling, 3.1718 regeneration, 50 damage, 1.2-second interval, 1.5 range, 4.8398 movement, and 0.9375 radius. The Fantasy Guild conversion deliberately removes Mana and uses the requested Ranged DPS role.

The prompt is authoritative where it intentionally differs from the current source:

- Spirit Swoop uses two independently recharging charges at 10 seconds and creates a Lesser Beast; current Rexxar Swoop is a seven-second cooldown without these summons.
- Misha's D command supports focus and self-target retreat only; point movement and hold-position behavior are excluded.
- E summons a Greater Beast instead of Bestial Wrath. Bestial Wrath is a Heroic option.
- Aspect of the Hawk extends by 0.5 seconds per Misha attack as authored, rather than the source's current 0.75 seconds.
- Spirit Bond heals Misha and living disposable beasts, never Rexxar.
- Wildfire Pack is a per-disposable-beast aura with the authored 14-damage tick and independent overlap.

## Runtime contract

Misha is a permanent companion record with stable combat and owner IDs. She can be selected by enemy threat, damaged, controlled, and healed by the ordinary healing resolver. At zero Health she remains owned but unavailable; Charge, Greater Beast, and Misha orders lock for 15 seconds. Respawn creates a safe nearby companion without altering Rexxar's cooldowns. Misha has no finite lifetime or Health decay.

Lesser and Greater Beasts are first-class targetable summon records in the shared combat registry. Lesser values are 435 Health, 25.5882 Health decay/second, 53 damage, one-second attacks, and 3.6015 movement, producing a natural 17-second baseline. Greater values are 593 Health, 28.2381 decay, 52 damage, one-second attacks, and 3.25 movement, producing 21 seconds. Hostile damage and natural decay are tracked separately. Ordinary allied healing excludes both disposable categories.

Health decay is the sole natural expiry mechanism. Warrior anti-summon logic may deal its summon damage, but it does not also shorten these beasts with the hard-lifetime system. Misha is likewise never assigned an invented lifetime.

## Ability and talent interaction audit

- D deterministically focuses the selected living enemy or retreats Misha to Rexxar on self-target. Misha's passive and retreat movement bonuses do not alter other beasts.
- Q damages and Slows every qualifying line contact, spends one independent charge, and creates one Lesser at the blocker-safe endpoint. Army of Hell creates two independent records and changes each charge recharge to 20 seconds.
- W moves Misha along a blocker-safe line, damages and Stuns each contact, and chooses the selected contact—or nearest line contact—as its deterministic primary target. Dire Beast consumes all stored stacks on that cast. Pack Commander issues its rush/attack/focus order only after a successful contact.
- E requires living Misha, spawns one Greater at her location, and starts the 60-second cooldown. It has no inherited demonic Smite behavior.
- Fury accepts successful primary Basic Attacks from Rexxar, Misha, Lesser, and Greater only. It grants no incremental stats, caps at 225 for the encounter, and unlocks independent one-use Rexxar/Misha Hunted strikes after Charge. Misses, protection, Wildfire, ability damage, and triggered packets do not progress it.
- Grizzled Fortitude uses the shared Block service but stores Rexxar and Misha charges independently. Each gains one every six seconds, caps at two, and only the contacted unit consumes a charge.
- Fresh to the Hunt prevents external damage for two seconds without preventing control or natural Health decay.
- Unhindered Hunter halves both Slow magnitude and duration through shared control metadata, so every Slow entry point obeys it.
- Coordinated Assault checks current target identity and grants one non-stacking +150% Misha modifier if any living disposable beast shares that target.
- Aspect of the Beast reduces W by one second only after a successful Misha primary attack. Chain of Command grants a single +25% Lesser modifier if at least one living Greater is within rally range.
- Aspect of the Hawk grants Rexxar +125% Attack Speed for four seconds only when Q contacts an enemy. Successful Misha primaries extend the live window by 0.5 seconds. Dire Beast accepts Rexxar/Misha primary attacks only and caps at ten +15% stacks.
- Thrill of the Hunt refreshes a two-second +25% movement window for Rexxar and Misha only. Primal Intimidation applies source-keyed attack-speed suppression on hostile Basic Attack contact before Fresh or other prevention resolves.
- Protective Bond snapshots current Health percentages, redirects exactly half of a hostile pre-mitigation packet from the lower-percent partner to the living higher-percent partner, then resolves both halves independently. Equal percentages do not redirect, redirected packets cannot recurse, and telemetry records source/recipient/resolved amount.
- Bestial Wrath grants Misha +200% Basic Attack damage for 12 seconds. Spirit Bond extends it to 18 seconds and heals every living owned beast for 50% of Misha's resolved attack damage. Unleash the Boars caps contacts at five, Reveals, Slows 40% for five seconds, and Kill Command adds +50% damage and a 1.5-second Root.
- Apex Companion gains two Misha maximum Health per second only while she is alive in active combat. Current Health is not filled by growth. Its same-target damage ramp resets on target change, caps at ten stacks, and resets on death.
- Wildfire Pack ticks once per living disposable beast. Separate aura instances overlap, do not award Fury, and retain owner attribution.

## Persistence, presentation, and telemetry

The class definition, ability/trait catalogs, talent tiers, roster descriptions, save-class discovery, testing fixture, action bar, summon rendering, dead-Misha lock state, Q charge state, and F3 audit overlay are data-driven. Runtime summon entities are encounter state and are not serialized into guild saves. Existing saves discover the class without duplicate fixtures.

Telemetry covers casts, contacts, primary attacks, damage, natural and hostile summon deaths, Fury/Hunted progress, Block, Fresh prevention, rally/Hawk/Thrill uptime, Heroic results, Apex growth/ramp, Pack Commander, Wildfire, and Bond redirection.

## Acceptance coverage

Pure tests cover the complete chassis, summon lifecycles, every talent branch, both Heroics and upgrades, quest scope, source exclusions, independent state, target switching, caps, misses/protection helpers, health decay, and Warrior anti-summon behavior. Live UI/runtime tests cover Range creation, Swoop, registry targeting, Fresh plus Primal ordering, natural decay, Protective Bond, ordinary Misha healing, Block consumption, lethal damage, and respawn. The full project validator additionally reruns all existing classes, save migration, UI smoke, startup, export-pack startup, source hygiene, and runtime-log checks.

Known calibration risk is limited to provisional world-space geometry and presentation readability under very large packs; mechanics and source-space constants remain isolated from those tuning values.
