# Progression Scopes V1

`progression_scope_system.gd` separates persistent hero mastery from encounter state.

- `hero.talent_mastery`: save-backed, permanent, and copied into class runtime state at battle start.
- `runtime.encounter_progress`: reset when a new encounter begins or the current encounter ends.
- `runtime.encounter_rewards`: encounter-only unlock flags produced by thresholds.
- `runtime.encounter_id`: stable across rooms and waves within one encounter.

Victory, defeat, and retreat all copy persistent mastery back to the hero save record before leaving combat. Older saves receive an empty `talent_mastery` dictionary during migration. This foundation is class-neutral even though Shaman V1 is its first consumer.
