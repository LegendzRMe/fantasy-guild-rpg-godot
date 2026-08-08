extends RefCounted

const CLASS_ID := "rogue"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5
const IDS := {"basic_attack":"rogue_basic_attack","trait":"rogue_trait","q":"rogue_q","w":"rogue_w","e":"rogue_e","r1":"rogue_r1","r2":"rogue_r2","stealth_q":"rogue_stealth_q","stealth_w":"rogue_stealth_w","stealth_e":"rogue_stealth_e"}
const SPACE := {"source_to_world":SOURCE_TO_WORLD,"basic_range":1.2*SOURCE_TO_WORLD,"movement_speed":150.0,"sinister_range":4.0*SOURCE_TO_WORLD,"sinister_width":0.8*SOURCE_TO_WORLD,"sinister_speed":900.0,"mutilate_range_penalty":1.0*SOURCE_TO_WORLD,"blade_radius":2.25*SOURCE_TO_WORLD,"opener_range":1.5*SOURCE_TO_WORLD,"smoke_radius":2.75*SOURCE_TO_WORLD,"isolation_radius":180.0}
const VALUES := {
	"health":2129.0,"health_regeneration":4.4354,"basic_attack_damage":82.0,"basic_attacks_per_second":2.0,
	"combo_max":3,"vigor_combo_max":5,"vanish_cooldown":8.0,"vanish_speed":0.20,"vanish_threat_reduction":0.25,"vanish_unrevealable":1.0,"vanish_invisible_stationary":1.5,"vanish_teleport_ready":3.0,
	"q_damage":110.0,"q_cooldown":5.0,"q_hit_reduction":1.0,"w_damage":130.0,"w_cooldown":4.0,"e_per_point":85.0,"e_cooldown":1.0,
	"ambush_damage":130.0,"ambush_armor_reduction":10.0,"ambush_duration":5.0,"opener_cooldown":1.0,
	"cheap_damage":30.0,"cheap_stun":0.75,"cheap_blind":2.0,"garrote_initial":20.0,"garrote_periodic":140.0,"garrote_duration":7.0,"garrote_tick":1.0,"garrote_silence":2.5,
	"smoke_cooldown":60.0,"smoke_duration":5.0,"cloak_cooldown":15.0,"cloak_duration":1.5,"cloak_armor":75.0,
	"fatal_per_hit":6.0,"fatal_max_stacks":15,"combat_readiness_armor":75.0,"combat_readiness_max":3,"double_strike_chance":0.10,
	"initiative_speed":0.15,"initiative_duration":3.0,"slice_speed_multiplier":5.0,"slice_attacks":3,"slice_duration":3.0,"strangle_external_multiplier":0.60
}
const WORKING_NAMES := {
	"rogue_trait":"Vanish","rogue_q":"Sinister Strike","rogue_w":"Blade Flurry","rogue_e":"Eviscerate","rogue_stealth_q":"Ambush","rogue_stealth_w":"Cheap Shot","rogue_stealth_e":"Garrote","rogue_l15_r1":"Smoke Bomb","rogue_l15_r2":"Cloak of Shadows",
	"rogue_l9_1":"Combat Readiness","rogue_l9_2":"Subtlety","rogue_l9_3":"Double Strike","rogue_l12_1":"Relentless Strikes","rogue_l12_2":"Hemorrhage","rogue_l12_3":"Initiative","rogue_l18_1":"Mutilate","rogue_l18_2":"Fatal Finesse","rogue_l18_3":"Slice and Dice","rogue_l21_1":"Death From Above","rogue_l21_2":"Blind","rogue_l21_3":"Strangle","rogue_l24_1":"Seal Fate","rogue_l24_2":"Assassinate","rogue_l24_3":"Blade Fury","rogue_l27_r1":"Adrenaline Rush","rogue_l27_r2":"Enveloping Shadows","rogue_l30_1":"Rupture","rogue_l30_2":"Elusiveness","rogue_l30_3":"Vigor"
}
const TALENT_DESCRIPTIONS := {
	"rogue_l9_1":"Each Combo Point consumed by Eviscerate grants a Block charge, up to 3.","rogue_l9_2":"Vanish prepares long-range teleport openers after 1.5 seconds.","rogue_l9_3":"Successful original Basic Attacks have a 10% chance to generate a Combo Point.",
	"rogue_l12_1":"A Sinister Strike hit reduces its remaining cooldown by 1 additional second.","rogue_l12_2":"Basic Attacks against this Rogue's Garrote deal 40% more damage.","rogue_l12_3":"Openers generate 2 total Combo Points and grant 15% Movement Speed for 3 seconds.",
	"rogue_l18_1":"Sinister Strike deals 125% additional damage but has reduced range.","rogue_l18_2":"Each qualifying Blade Flurry target adds 6 damage for the encounter, up to 15 stacks.","rogue_l18_3":"A 3-point Eviscerate grants 400% bonus Attack Speed for 3 attacks or 3 seconds.",
	"rogue_l21_1":"A teleporting Ambush reduces Vanish's remaining cooldown by 4 seconds.","rogue_l21_2":"Cheap Shot's Blind lasts 2.5 seconds longer.","rogue_l21_3":"This Rogue's Garrote reduces external healing received by 40%.",
	"rogue_l24_1":"Sinister Strike deals 50% more damage and generates 2 points against Silenced, Rooted, or Stunned enemies.","rogue_l24_2":"Ambush deals 50% more damage to isolated enemies and its Armor reduction lasts 5 seconds longer.","rogue_l24_3":"Blade Flurry generates 2 points when it damages at least 3 valid enemies.",
	"rogue_l27_r1":"The first valid Eviscerate inside each Smoke Bomb consumes no Combo Points.","rogue_l27_r2":"Vanish also applies Cloak of Shadows without consuming the Heroic cooldown.",
	"rogue_l30_1":"Garrote's periodic damage is doubled; successful Basic Attacks refresh this Rogue's Garrote.","rogue_l30_2":"Vanish grants 40% total Movement Speed.","rogue_l30_3":"Store up to 5 Combo Points; Eviscerate still uses and consumes at most 3."
}
const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["rogue_l9_1","rogue_l9_2","rogue_l9_3"]},{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["rogue_l12_1","rogue_l12_2","rogue_l12_3"]},{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["rogue_l15_r1","rogue_l15_r2"]},{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["rogue_l18_1","rogue_l18_2","rogue_l18_3"]},{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["rogue_l21_1","rogue_l21_2","rogue_l21_3"]},{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["rogue_l24_1","rogue_l24_2","rogue_l24_3"]},{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["rogue_l27_r1","rogue_l27_r2"],"heroic_requirements":{"rogue_l27_r1":"rogue_l15_r1","rogue_l27_r2":"rogue_l15_r2"}},{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["rogue_l30_1","rogue_l30_2","rogue_l30_3"]}
]
const TEST_BUILDS := [
	{"name":"Level 1 Baseline","level":1,"heroic":"","talents":{}},
	{"name":"Ambush and Stealth","level":30,"heroic":"rogue_l15_r2","talents":{"tier_1":"rogue_l9_2","tier_2":"rogue_l12_3","tier_3":"rogue_l15_r2","tier_4":"rogue_l18_1","tier_5":"rogue_l21_1","tier_6":"rogue_l24_2","tier_7":"rogue_l27_r2","tier_8":"rogue_l30_2"}},
	{"name":"Garrote and Rupture","level":30,"heroic":"rogue_l15_r2","talents":{"tier_1":"rogue_l9_3","tier_2":"rogue_l12_2","tier_3":"rogue_l15_r2","tier_4":"rogue_l18_3","tier_5":"rogue_l21_3","tier_6":"rogue_l24_1","tier_7":"rogue_l27_r2","tier_8":"rogue_l30_1"}},
	{"name":"Blade Flurry and Combo","level":30,"heroic":"rogue_l15_r1","talents":{"tier_1":"rogue_l9_1","tier_2":"rogue_l12_1","tier_3":"rogue_l15_r1","tier_4":"rogue_l18_2","tier_5":"rogue_l21_2","tier_6":"rogue_l24_3","tier_7":"rogue_l27_r1","tier_8":"rogue_l30_3"}},
	{"name":"Smoke and Adrenaline","level":30,"heroic":"rogue_l15_r1","talents":{"tier_1":"rogue_l9_1","tier_2":"rogue_l12_3","tier_3":"rogue_l15_r1","tier_4":"rogue_l18_3","tier_5":"rogue_l21_1","tier_6":"rogue_l24_2","tier_7":"rogue_l27_r1","tier_8":"rogue_l30_3"}},
	{"name":"Cloak and Enveloping","level":30,"heroic":"rogue_l15_r2","talents":{"tier_1":"rogue_l9_2","tier_2":"rogue_l12_2","tier_3":"rogue_l15_r2","tier_4":"rogue_l18_1","tier_5":"rogue_l21_3","tier_6":"rogue_l24_1","tier_7":"rogue_l27_r2","tier_8":"rogue_l30_2"}}
]
const CLASS_DEFINITION := {"class_id":"rogue","display_name":"Rogue","primary_role":"DPS","role":"DPS","basic_action_id":"rogue_basic_attack","trait_id":"rogue_trait","q_ability_id":"rogue_q","w_ability_id":"rogue_w","e_ability_id":"rogue_e","heroic_option_ids":["rogue_l15_r1","rogue_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["damage","melee","mobile","stealth"],"color":Color("e6b35f"),"ability":"Sinister Strike","base_health":2129.0,"health_growth":0.04,"base_power":82.0,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":0.5,"basic_action_range":SPACE.basic_range,"movement_speed":SPACE.movement_speed,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":4.4354,"health_regeneration_growth":0.04,"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"leather","armor_proficiency":"leather","weapon_proficiencies":["dual_wield","one_handed"],"uses_mana":false,"resource_id":"combo_points"}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)
