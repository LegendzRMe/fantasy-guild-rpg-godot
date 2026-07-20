extends RefCounted

# Progression structure lives here so future talent work never has to search
# combat, roster, save, or world-data files for unlock levels.
const ABILITY_UNLOCK_LEVELS := {0:1,1:3,2:6,3:15}
const TIER_LEVELS := {"tier_1":9,"tier_2":12,"tier_3":15,"tier_4":18,"tier_5":21,"tier_6":24,"tier_7":27,"tier_8":30}
const TIER_DEFINITIONS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":[]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":[]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":[]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":[]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":[]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":[]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":[],"heroic_requirements":{}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":[]}
]
