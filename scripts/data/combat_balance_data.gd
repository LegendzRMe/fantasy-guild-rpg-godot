extends RefCounted

# Shared role-level combat policy. Class kits may manipulate threat explicitly,
# but ordinary damage/healing uses these canonical role multipliers.
const TANK_THREAT_MODIFIER := 1.5
