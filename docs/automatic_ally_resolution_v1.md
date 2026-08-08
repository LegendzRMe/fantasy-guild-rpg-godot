# Automatic ally resolution V1

**Lifecycle:** Current contract.

`automatic_ally_resolution_system.gd` owns deterministic position-based support selection. Most-wounded mode compares `current_health / maximum_health`, then distance to the caster, then stable combat ID. Closest-other mode excludes the caster, compares distance and stable ID, and falls back to the caster only when no valid other ally exists.

Candidates must be living, non-incapacitated, in radius, and—by default—not in Spirit Form. Callers pass only eligible allied Heroes, which prevents summons, story NPCs, and structures from entering Priest's automatic support resolution. Selection occurs at the ability-defined resolution time: Flash Heal at cast completion and Lightbomb at cast activation.
