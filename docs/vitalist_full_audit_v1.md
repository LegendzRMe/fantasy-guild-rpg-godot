# Vitalist full audit V1

Audit result: the class is wired through data, roster/talents, save migration, combat input/runtime, shared cooldown/control/Armor/displacement paths, presentation, Testing Range, F3, tests, and export loading. Vitalist remains testing-only and adds no campaign or recruitment unlock.

The interaction review specifically verified source ownership between duplicate Vitalists; Q per-cast spread history; no same-frame unlimited baseline bounce; Reactive-before-snapshot and Poppin-after-resolution ordering; Targeted/Pox duration order; Perfect Strain sequential recharge and lockout; additive Reactive/Long Pitch recharge without double frame ticking; Growing/Pox uncapped duration; Biotic strongest-active 50→10 behavior; Universal Carrier/Virulent recipient limits; Top Off/Carrier percentage order; E action locks and D/R exceptions; shared Stun/Root event triggering; Boss control profiles; and shove blocker/boundary interruption behavior.

Issues found and corrected during the audit:

- The initial Arm aiming preview referenced a nonexistent cursor local and failed parser validation.
- Generic and class-local cooldown loops both advanced Q/W/E/R, doubling recharge. Vitalist now uses the shared loop once; only D/R charge state remains class-owned.
- One Good Spread stored its once-only flag per infection sibling. It now shares original-cast state.
- Superstrain could observe a control event that predated Q application. Recipient serials are baselined when Q arrives.
- Talent-created Poppin/Reactive W infections could be counted as manual W casts and Fetid quest hits. Generated infections are now distinguished.
- Massive Shove originally resolved displacement in one frame. It now has explicit frame-driven channel state, collision/end resolution, action locking, and hostile-control interruption.

The final acceptance gate is two consecutive unchanged-tree `tools/validate.ps1` runs. Each includes Godot dependency priming, editor parse/import, texture-quality checks, the complete automated test registry, project startup, export preset and exported-pack startup, runtime log inspection, UTF-8 hygiene, and `git diff --check`. This document records automated verification only, not a manual playtest.
