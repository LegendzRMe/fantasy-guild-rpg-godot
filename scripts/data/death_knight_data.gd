extends RefCounted

const CLASS_ID := "death_knight"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5

const SPACE := {
	"source_to_world":SOURCE_TO_WORLD,"basic_range":2.0*SOURCE_TO_WORLD,"death_coil_range":7.0*SOURCE_TO_WORLD,
	"howling_range":9.0*SOURCE_TO_WORLD,"howling_radius":2.5*SOURCE_TO_WORLD,"howling_path_width":1.25*SOURCE_TO_WORLD,"howling_speed":16.0*SOURCE_TO_WORLD,
	"tempest_radius":3.5*SOURCE_TO_WORLD,"frost_strike_radius":2.0*SOURCE_TO_WORLD,"army_death_radius":13.5*SOURCE_TO_WORLD,
	"ghoul_acquisition":7.0*SOURCE_TO_WORLD,"sindragosa_range":20.0*SOURCE_TO_WORLD,"sindragosa_width":4.0*SOURCE_TO_WORLD,
	"deathlord_range":8.0*SOURCE_TO_WORLD,"movement_speed":150.0,"combat_radius":42.0
}

const VALUES := {
	"health":2100.0,"health_regeneration":4.3752,"basic_attack_damage":95.0,"basic_attack_interval":1.1,
	"frostmourne_damage":71.0,"frostmourne_cooldown":12.0,"frostmourne_damage_per_stack":3.0,"frostmourne_basic_per_stack":0.75,
	"death_coil_damage":164.0,"death_coil_heal":275.0,"death_coil_cooldown":9.0,
	"howling_damage":68.0,"howling_cooldown":10.0,"howling_root":1.25,
	"tempest_damage":36.0,"tempest_tick":1.0,"tempest_increment":0.10,"tempest_cap":0.40,"tempest_linger":1.5,"tempest_cooldown":8.0,
	"frost_presence_radius":0.20,"frost_presence_range":0.20,"frost_presence_first":15,"frost_presence_second":30,"frost_presence_mastery":50,"frost_presence_slow":0.50,"frost_presence_slow_duration":1.25,"frost_presence_cast_cap":5,
	"borean_delay":2.0,"borean_move":0.10,"borean_linger":0.5,"borean_cooldown":1.0,
	"rime_reduction":0.75,"rime_duration":5.0,"control_extension":0.50,"icy_per_contact":0.03,"icy_cap":0.60,"icy_contact_cap":5,
	"frost_strike_damage":115.0,"frost_strike_slow":0.20,"frost_strike_slow_duration":2.0,
	"army_charge_cooldown":18.0,"army_max_charges":6,"ghoul_lifetime":15.0,"ghoul_health":1200.0,"ghoul_damage":20.0,"ghoul_interval":1.0,"ghoul_speed":155.0,"army_death_cdr":1.0,
	"sindragosa_damage":230.0,"sindragosa_cooldown":100.0,"sindragosa_slow":0.60,"sindragosa_slow_duration":4.0,"sindragosa_blind":4.0,
	"immortal_self_bonus":0.75,"immortal_self_cdr":3.0,"immortal_healing_reduction":0.25,"immortal_healing_reduction_duration":3.0,
	"rune_passive":0.05,"rune_attacks":3,"rune_per_stack":0.05,"rune_max":5,
	"icebound_stun":1.25,"icebound_slow":0.75,"icebound_slow_duration":3.0,"icebound_cdr":2.0,"icebound_contact_cap":5,
	"deathlord_max_bonus":0.50,"deathchill_per_stack":2.0,"deathchill_root":0.25,"biting_per_tick":0.15,"biting_cap":0.75,
	"remorseless_exposure":2.5,"remorseless_root":1.25,"remorseless_icd":8.0,"feeds_cdr":6.0,"feeds_control_cdr":1.0,
	"anti_magic_duration_multiplier":0.75,"legion_cdr":5.0,"absolute_root":2.5,"death_pact_start":10,"death_pact_gain":2,
	"eternal_increment":0.20,"dominion_normal":0.25,"dominion_controlled":0.40,"dominion_duration":3.0
}

const WORKING_NAMES := {
	"death_knight_l9_1":"Frost Presence","death_knight_l9_2":"Borean Winds","death_knight_l9_3":"Rime",
	"death_knight_l12_1":"Shattered Armor","death_knight_l12_2":"Icy Talons","death_knight_l12_3":"Frost Strike",
	"death_knight_l15_r1":"Army of the Dead","death_knight_l15_r2":"Summon Sindragosa",
	"death_knight_l18_1":"Immortal Coil","death_knight_l18_2":"Rune Tap","death_knight_l18_3":"Icebound Fortitude",
	"death_knight_l21_1":"Deathlord","death_knight_l21_2":"Deathchill","death_knight_l21_3":"Biting Cold",
	"death_knight_l24_1":"Remorseless Winter","death_knight_l24_2":"Frostmourne Feeds","death_knight_l24_3":"Anti-Magic Shell",
	"death_knight_l27_r1":"Legion of Northrend","death_knight_l27_r2":"Absolute Zero",
	"death_knight_l30_1":"Death Pact","death_knight_l30_2":"Eternal Winter","death_knight_l30_3":"Death's Dominion"
}

const TALENT_DESCRIPTIONS := {
	"death_knight_l9_1":"Howling Blast gains 20% area and an encounter quest whose 50-point completion permanently masters its path, range, and Death Coil Slow rewards.",
	"death_knight_l9_2":"After two seconds Frozen Tempest grants 10% Movement Speed; suppression lingers 0.5 seconds longer and its cooldown is seven seconds.",
	"death_knight_l9_3":"Successful incoming Slow, Root, or Stun grants 75% source-aware damage reduction for five seconds.",
	"death_knight_l12_1":"Howling Blast extends every pre-existing Slow, Root, and Stun by 50% before applying its own controls.",
	"death_knight_l12_2":"Frozen Tempest gains 3% Attack Speed per unique tick contact, up to 60%, until it ends.",
	"death_knight_l12_3":"Frostmourne Hungers deals 115 area Ability damage and Slows 20% for two seconds.",
	"death_knight_l15_r1":"Store six 18-second charges; consume all available charges to summon one 15-second Ghoul per charge.",
	"death_knight_l15_r2":"Launch Sindragosa for 230 damage, 60% Slow for four seconds, and four seconds of Blind.",
	"death_knight_l18_1":"Enemy Death Coil also heals you and reduces enemy healing received; self-cast heals 75% more and cools down three seconds faster.",
	"death_knight_l18_2":"Gain 5% healing received; every third Tempest Basic Attack builds a 5% nearby-party healing aura, up to 25% until Tempest ends.",
	"death_knight_l18_3":"Howling Blast also attempts a 1.25-second Stun and 75% Slow, reducing its cooldown two seconds per unique target, up to five.",
	"death_knight_l21_1":"Enemy Death Coil launches once at a distinct nearby enemy and deals up to 50% more damage as Health falls.",
	"death_knight_l21_2":"Howling Blast gains two level-one damage per Frostmourne stack and 0.25 seconds of Root.",
	"death_knight_l21_3":"Continuous Frozen Tempest damage ramps 15% per target per second, up to 75%.",
	"death_knight_l24_1":"After 2.5 continuous Tempest seconds, Root a target for 1.25 seconds; eight-second per-target cooldown.",
	"death_knight_l24_2":"Frostmourne cooldown becomes six seconds, or five when the struck target was already controlled.",
	"death_knight_l24_3":"Passive Blind immunity and 25% shorter incoming Stun, Root, and Slow durations.",
	"death_knight_l27_r1":"Army charge cooldown becomes 13 seconds and every consumed charge summons two Ghouls.",
	"death_knight_l27_r2":"Sindragosa travels twice as far and Roots for 2.5 seconds before its Slow.",
	"death_knight_l30_1":"Begin every encounter with ten Frostmourne stacks and gain two from each qualifying event.",
	"death_knight_l30_2":"Frozen Tempest no longer locks D/Q/W/R and suppression ramps 20 percentage points per second, still capped at 40%.",
	"death_knight_l30_3":"Enemy Death Coil reduces outgoing damage 25%, or 40% if already controlled, for three seconds; Howling Blast refreshes it."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["death_knight_l9_1","death_knight_l9_2","death_knight_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["death_knight_l12_1","death_knight_l12_2","death_knight_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["death_knight_l15_r1","death_knight_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["death_knight_l18_1","death_knight_l18_2","death_knight_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["death_knight_l21_1","death_knight_l21_2","death_knight_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["death_knight_l24_1","death_knight_l24_2","death_knight_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["death_knight_l27_r1","death_knight_l27_r2"],"heroic_requirements":{"death_knight_l27_r1":"death_knight_l15_r1","death_knight_l27_r2":"death_knight_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["death_knight_l30_1","death_knight_l30_2","death_knight_l30_3"]}
]

const TEST_BUILDS := [
	{"name":"Level 1 Baseline","level":1,"heroic":"","talents":{}},
	{"name":"Frozen Tempest Suppression","level":30,"heroic":"death_knight_l15_r2","talents":{"tier_1":"death_knight_l9_2","tier_2":"death_knight_l12_2","tier_3":"death_knight_l15_r2","tier_4":"death_knight_l18_2","tier_5":"death_knight_l21_3","tier_6":"death_knight_l24_1","tier_7":"death_knight_l27_r2","tier_8":"death_knight_l30_2"}},
	{"name":"Frostmourne Weapon","level":30,"heroic":"death_knight_l15_r1","talents":{"tier_1":"death_knight_l9_3","tier_2":"death_knight_l12_3","tier_3":"death_knight_l15_r1","tier_4":"death_knight_l18_2","tier_5":"death_knight_l21_2","tier_6":"death_knight_l24_2","tier_7":"death_knight_l27_r1","tier_8":"death_knight_l30_1"}},
	{"name":"Howling Blast Controller","level":30,"heroic":"death_knight_l15_r2","talents":{"tier_1":"death_knight_l9_1","tier_2":"death_knight_l12_1","tier_3":"death_knight_l15_r2","tier_4":"death_knight_l18_3","tier_5":"death_knight_l21_2","tier_6":"death_knight_l24_3","tier_7":"death_knight_l27_r2","tier_8":"death_knight_l30_3"}},
	{"name":"Death Coil Suppressor","level":30,"heroic":"death_knight_l15_r1","talents":{"tier_1":"death_knight_l9_1","tier_2":"death_knight_l12_1","tier_3":"death_knight_l15_r1","tier_4":"death_knight_l18_1","tier_5":"death_knight_l21_1","tier_6":"death_knight_l24_3","tier_7":"death_knight_l27_r1","tier_8":"death_knight_l30_3"}},
	{"name":"Frost Presence Mastered","level":30,"heroic":"death_knight_l15_r2","talents":{"tier_1":"death_knight_l9_1","tier_2":"death_knight_l12_1","tier_3":"death_knight_l15_r2","tier_4":"death_knight_l18_3","tier_5":"death_knight_l21_2","tier_6":"death_knight_l24_3","tier_7":"death_knight_l27_r2","tier_8":"death_knight_l30_3"},"mastered":true}
]

const CLASS_DEFINITION := {
	"class_id":"death_knight","display_name":"Death Knight","primary_role":"Melee DPS","role":"Melee DPS",
	"basic_action_id":"death_knight_basic_attack","trait_id":"death_knight_frostmourne","q_ability_id":"death_knight_death_coil","w_ability_id":"death_knight_howling_blast","e_ability_id":"death_knight_frozen_tempest",
	"heroic_option_ids":["death_knight_l15_r1","death_knight_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["melee","basic_attack","debuffer"],"color":Color("75b8dc"),"ability":"Death Coil",
	"base_health":VALUES.health,"health_growth":0.04,"base_power":VALUES.basic_attack_damage,"power_growth":0.04,"base_armor":0.0,
	"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":VALUES.basic_attack_interval,"basic_action_range":SPACE.basic_range,
	"movement_speed":SPACE.movement_speed,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":VALUES.health_regeneration,"health_regeneration_growth":0.04,
	"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"plate","armor_proficiency":"plate","weapon_proficiencies":["two_handed"],"uses_mana":false,"resource_id":""
}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)
