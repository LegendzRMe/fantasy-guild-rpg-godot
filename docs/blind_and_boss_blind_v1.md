# Blind and Boss Blind V1

Blind is a reusable shared status owned by `status_effect_system.gd`, exposed through `combat_system.gd`, and consumed by the shared Basic Action release path. It is not Cleric-specific; enemies, items, and later class conversions such as Valeera can use the same API.

## Action terminology

`basic_attack` and `basic_heal` are distinct action sources and both receive the internal `basic_action` grouping tag. Q/W/E are `basic_ability`, R is `heroic`, and D activations are `trait`. Blind affects only Basic Attacks. It never prevents Basic Heals, physical-damage abilities, Basic Abilities, Heroics, traits, periodic effects, or summons.

## Release timing and misses

Blind is checked when a Basic Attack releases, after its normal wind-up:

- A blinded melee attacker records a miss immediately.
- A ranged Basic Attack released while blinded creates a cosmetic projectile marked `will_miss`. It remains a miss even if Blind expires before impact.
- A projectile released before Blind remains valid and resolves normally even if its source becomes blinded in flight.
- The attacker still completes wind-up, release, recovery, and its normal next-ready time. Movement cannot accelerate a missed action.

A Blind miss emits `basic_action_missed`, `blind_miss`, and `basic_action_completed`. It emits no hit or damage event. Consequently it deals no damage, creates no threat or hit nudge, consumes no Block charge, cannot crit or bleed, and triggers no on-hit item, quest, or passive effect. `MISS` is temporary prototype feedback.

## Boss and unit profiles

Control behavior is data-driven through `control_profile`; display names are never inspected. Ordinary units default to full Blind vulnerability. Bosses default to:

- `blind_immune = true`
- `blind_duration_multiplier = 0.0`

A unit can override either field. For example, `blind_immune = false` plus `blind_duration_multiplier = 0.5` produces half-duration Blind. Blinding Wind damage and Slow resolve independently from Blind. A resisted application emits `blind_resisted`; the testing range also displays temporary `IMMUNE` feedback.

## Refresh, pause, and stacking

Blind is binary. Reapplication keeps the strongest instance and refreshes to the longer remaining duration; it never shortens an existing Blind. Status durations advance only inside the live, unpaused combat update, so pause freezes Blind. The same strongest-refresh helper remains available for reusable named effects.

## Testing

The testing range includes vulnerable melee/ranged enemies, a default Blind-immune Boss, and a second Boss with half-duration vulnerability. Automated coverage verifies default and overridden profiles, deterministic refresh, miss telemetry, action taxonomy, and Unstoppable coexistence.

Temporary limitations: the current miss projectile is cosmetic and uses the existing straight-projectile presentation; final art, sound, and target-state indicators are intentionally deferred.
