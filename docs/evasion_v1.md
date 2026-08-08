# Evasion V1

**Lifecycle:** Current contract.

`evasion_system.gd` provides deterministic, class-neutral avoidance for eligible hostile Basic Attacks while an Evasion window is active. Authored attacks may explicitly bypass it; being a Boss does not bypass it automatically.

Evasion is different from Blind: Blind is a source-side miss condition, while Evasion is a target-side defense. Resolution order is source miss, Evasion, immunity, then Block and ordinary damage. An Evaded action deals no Health or Shield damage, consumes no Block, produces no threat, and triggers no on-hit, quest, healing, slow, or percentage-damage behavior.

The result is a reusable miss record with `evaded=true`, zero resolved damage, and the original action type. UI may show a short dodge/Evasion cue; telemetry records Evasion casts and avoided attacks. Future heroes and enemies should reuse this contract rather than adding class-name checks to damage resolution.

