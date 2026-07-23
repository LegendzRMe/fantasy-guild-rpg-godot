# Periodic Damage Status Hooks

`periodic_status_system.gd` supplies JSON-safe runtime records for independently timed effects. Each record owns an effect ID, owner, target, cast lineage, remaining duration, tick interval, presentation metadata, and payload.

Stack limits are evaluated per effect, owner, and target. Replacing an oldest stack therefore never consumes a different target's stack allowance. `advance()` reports due ticks without resolving damage; the owning runtime remains responsible for target validation, mitigation, death, and derived healing.

Corruption stores each application as a separate six-second instance. Each tick uses current eligible damage modifiers and ordinary universal Armor. Echoed Corruption's Mythic healing uses actual resolved Health-and-Shield damage returned by combat resolution and then passes through ordinary restoration modifiers.

The battlefield currently represents Corruption stacks with one purple marker per active instance. The record also exposes icon, tint, outline, priority, and health-bar marker fields for later final UI.
