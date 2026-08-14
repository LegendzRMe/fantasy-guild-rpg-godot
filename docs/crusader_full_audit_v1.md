# Crusader full audit v1

This audit is the verification companion to `crusader_conversion_v1.md`.

## Coverage matrix

- Baseline: chassis, no resource, 1.5 Threat, Basic Attack, Q/W/E/D values, cooldowns, delays, cones/radii, decaying Slow, pull safety, control immunity, Blind immunity, charge UI, Shield ownership, and removed PvE multiplier.
- Every talent: all 22 choices across eight tiers have deterministic system assertions; live runtime tests cover representative damage, control, Shield, recharge, Threat, boss, and Heroic paths.
- Quests and state: Subdue's binary encounter completion, owner-scoped Eternal/Condemned/Sins/Authority maps, expiry, non-consumption, and Basic Attack refresh/consumption rules.
- AoE scaling: 1/2/3/4/5+ contact thresholds, shared five-contact caps, Roar replacement math, Holy Fury snapshot, Shrinking Vacuum, both cooldown loops, Light ICD, and Unbreakable restoration.
- Heroics: Falling Sword entry/landing, steering state, action suppression, blocker traversal, ally Unstoppable, Heaven's Fury cadence/caps/CDR; Blessed Shield deterministic bounce and Radiating Faith target/control rules.
- Defense: Universal Armor stacks, scheduled healing, named Shield and early break, incoming reduction, lethal intercept, capstone party Shields, modified Shield maximum, and no resurrection/overshield.
- Cross-class/shared regression: the complete suite runs every established class and shared combat rule. Source-owned Unstoppable is additive and removal is source-specific; decaying Slow is opt-in metadata, leaving existing controls unchanged.
- Persistence/UI: testing-state creation/migration, full class registration, roster talent and ability copy, campaign testing button, HUD charge/state display, F3 telemetry, source startup, export startup, and runtime-log scan.

## Risk review

The intentional balance risks are pack-amplified: 100 scaled Universal Armor, long E-extended Iron Skin windows, 25% incoming reduction, 45 base Holy Fury damage/sec, rapid E/D cycling, 4x target-specific Threat, Heaven's Fury CDR in dense packs, 40-second Light ICD reduction, and 25% Shield restoration per Basic Ability. None is silently reduced. Single-target Crusader is expected to be less explosive than five-target Crusader.

The main residual risk is presentation/feel rather than deterministic state: cone width, pull stand-off, airborne steering, dense bolt readability, and party-Shield readability require a human session. Automated validation is not described as a manual playtest.
