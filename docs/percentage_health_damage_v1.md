# Percentage-Health Damage V1

`percentage_health_damage_system.gd` creates a neutral request using `percent_damage_health_basis` when supplied, falling back to current maximum Health. The basis is captured before difficulty/runtime multipliers. Callers explicitly provide ordinary and Boss fractions.

Percentage-health requests cannot critically strike, do not inherit outgoing damage multipliers, and do not provide lifesteal. They still pass through the ordinary target Armor/stage resolver. Ranger Manticore is the first consumer: 4% for ordinary units and 1% for Bosses every third consecutive Basic Attack against the same target.

