extends RefCounted

const CLASS_ID := "vanguard"
const SOURCE_BUILD := "2.55.17.97771"
const SOURCE_TO_WORLD := 185.0 / 5.5
const SPACE := {
	"combat_radius":0.9375 * SOURCE_TO_WORLD,
	"basic_range":1.5 * SOURCE_TO_WORLD,
	"q_range":8.5 * SOURCE_TO_WORLD,
	"q_half_width":1.25 * SOURCE_TO_WORLD,
	"w_radius":4.0 * SOURCE_TO_WORLD,
	"w_displacement":2.5 * SOURCE_TO_WORLD,
	"e_range":2.0 * SOURCE_TO_WORLD,
	"e_behind_offset":1.25 * SOURCE_TO_WORLD,
	"support_radius":4.0 * SOURCE_TO_WORLD,
	"mosh_radius":4.0 * SOURCE_TO_WORLD,
	"lightning_range":7.5 * SOURCE_TO_WORLD,
	"lightning_half_angle":deg_to_rad(35.0),
	"echo_radius":4.0 * SOURCE_TO_WORLD
}
const VALUES := {
	"health":2280.0,"health_regeneration":4.75,"basic_attack_damage":99.0,"basic_attack_interval":0.8,
	"q_damage":105.0,"q_cooldown":12.0,"q_stun":1.25,"q_speed":14.0 * SOURCE_TO_WORLD,
	"w_damage":68.0,"w_cooldown":10.0,"e_damage":80.0,"e_cooldown":12.0,"e_stun":0.25,
	"rockstar_basic":25.0,"rockstar_heroic":50.0,"rockstar_duration":2.0,
	"stun_extension":0.25,"prog_requirement":20,"prog_heal":50.0,"prog_duration":4.0,"contact_cap":5,
	"block_max":2,"crowd_surfer_cdr":6.0,"loud_multiplier":1.5,"wall_move":0.20,"wall_move_duration":2.5,"wall_damage":140.0,"wall_stun":1.0,
	"mosh_cooldown":120.0,"mosh_windup":0.75,"mosh_duration":4.0,
	"lightning_cooldown":90.0,"lightning_windup":0.5,"lightning_duration":4.0,"lightning_damage":50.0,"lightning_tick":0.25,"lightning_slow":0.04,"lightning_slow_max":0.40,"lightning_slow_duration":2.0,
	"pinball_duration":2.0,"pinball_bonus":3.0,"hammer_bonus":0.12,"echo_damage":18.0,"echo_second_delay":2.0,
	"mic_check_cdr":6.0,"encore_delay":2.0,"encore_heroic_fraction":0.04,
	"show_root":1.0,"dissonance_silence":1.0,"e_lockout":2.0,
	"tour_extension":2.0,"hellstorm_duration":12.0,"hellstorm_slow":0.08,"hellstorm_slow_max":0.80,
	"encore_taunt":2.0,"horde_basic":50.0,"horde_heroic":75.0,
	"death_metal_duration":4.0,"death_metal_survival":0.35
}
const WORKING_NAMES := {
	"vanguard_l9_1":"Stunning Performance","vanguard_l9_2":"Prog Rock","vanguard_l9_3":"Block Party",
	"vanguard_l12_1":"Crowd Surfer","vanguard_l12_2":"Loud Speakers","vanguard_l12_3":"Wall of Sound",
	"vanguard_l15_r1":"Mosh Pit","vanguard_l15_r2":"Lightning Breath",
	"vanguard_l18_1":"Pinball Wizard","vanguard_l18_2":"Hammer-On","vanguard_l18_3":"Echo Pedal",
	"vanguard_l21_1":"Mic Check","vanguard_l21_2":"Encore","vanguard_l21_3":"Face Smelt",
	"vanguard_l24_1":"Show Stopper","vanguard_l24_2":"Dissonance","vanguard_l24_3":"Overpowering Nightmare",
	"vanguard_l27_r1":"Tour Bus","vanguard_l27_r2":"Hellstorm",
	"vanguard_l30_1":"Encore Performance","vanguard_l30_2":"Power of the Horde","vanguard_l30_3":"Death Metal"
}
const TALENT_DESCRIPTIONS := {
	"vanguard_l9_1":"Primary Basic Attacks extend an existing Stun by 0.25 seconds.",
	"vanguard_l9_2":"Encounter quest: land 20 qualifying Q/E Stuns. Later Vanguard Stuns create independent four-second party healing areas.",
	"vanguard_l9_3":"Basic and Heroic casts grant one shared Block charge to Vanguard and nearby eligible allies, maximum two.",
	"vanguard_l12_1":"Powerslide crosses terrain; a zero-contact cast reduces its remaining cooldown by six seconds.",
	"vanguard_l12_2":"Face Melt radius and displacement are increased by 50%.",
	"vanguard_l12_3":"Powerslide pushes enemies forward and grants 20% movement speed. Terrain collisions deal 140 Level-1 damage and sequence an additional one-second Stun.",
	"vanguard_l15_r1":"After 0.75 seconds, channel a four-second moving-center Stun aura. Interruptible unless created by Death Metal.",
	"vanguard_l15_r2":"After 0.5 seconds, channel frontal damage every 0.25 seconds while Unstoppable. Vanguard-specific movement commands rotate the cone.",
	"vanguard_l18_1":"Powerslide marks targets for two seconds; their next Face Melt takes 300% additional damage.",
	"vanguard_l18_2":"Primary Basic Attacks deal 12% more damage against currently Stunned enemies.",
	"vanguard_l18_3":"Basic and Heroic casts release 18 Level-1 AoE damage immediately and again after two seconds.",
	"vanguard_l21_1":"Face Melt hitting at least two qualifying enemies reduces its remaining cooldown by six seconds once.",
	"vanguard_l21_2":"Face Melt leaves an Amp that repeats displacement after two seconds; each original or Amp contact removes 4% of selected Heroic maximum cooldown.",
	"vanguard_l21_3":"Face Melt pulls inward instead of knocking outward.",
	"vanguard_l24_1":"After Powerslide's owned Stun ends, attempt a one-second Root.",
	"vanguard_l24_2":"Face Melt applies a one-second Silence after displacement.",
	"vanguard_l24_3":"Overpower has three sequentially recharging charges with a two-second inter-cast lockout.",
	"vanguard_l27_r1":"Mosh Pit refreshes Q; Q may be used during Mosh and extends it by two seconds while carrying the aura.",
	"vanguard_l27_r2":"Lightning Breath lasts 12 seconds and adds 8% Slow per hit, to 80%.",
	"vanguard_l30_1":"After selected-Heroic control ends, affected enemies are forced to target Vanguard for two seconds.",
	"vanguard_l30_2":"Rockstar affects nearby eligible allies and becomes 50 Armor for Basic casts or 75 for Heroics.",
	"vanguard_l30_3":"Fatal damage starts the unselected baseline Heroic for four seconds and holds Vanguard at one Health; survive at 35% Health or be defeated."
}
const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["vanguard_l9_1","vanguard_l9_2","vanguard_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["vanguard_l12_1","vanguard_l12_2","vanguard_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["vanguard_l15_r1","vanguard_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["vanguard_l18_1","vanguard_l18_2","vanguard_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["vanguard_l21_1","vanguard_l21_2","vanguard_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["vanguard_l24_1","vanguard_l24_2","vanguard_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["vanguard_l27_r1","vanguard_l27_r2"],"heroic_requirements":{"vanguard_l27_r1":"vanguard_l15_r1","vanguard_l27_r2":"vanguard_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["vanguard_l30_1","vanguard_l30_2","vanguard_l30_3"]}
]
const TEST_BUILDS := [
	{"name":"Baseline Pack","level":30,"heroic":"vanguard_l15_r1","talents":{}},
	{"name":"Touring Control","level":30,"heroic":"vanguard_l15_r1","talents":{"tier_1":"vanguard_l9_2","tier_2":"vanguard_l12_3","tier_3":"vanguard_l15_r1","tier_4":"vanguard_l18_1","tier_5":"vanguard_l21_2","tier_6":"vanguard_l24_1","tier_7":"vanguard_l27_r1","tier_8":"vanguard_l30_1"}},
	{"name":"Hellstorm Party","level":30,"heroic":"vanguard_l15_r2","talents":{"tier_1":"vanguard_l9_3","tier_2":"vanguard_l12_2","tier_3":"vanguard_l15_r2","tier_4":"vanguard_l18_3","tier_5":"vanguard_l21_1","tier_6":"vanguard_l24_2","tier_7":"vanguard_l27_r2","tier_8":"vanguard_l30_2"}},
	{"name":"Death Metal Nightmare","level":30,"heroic":"vanguard_l15_r2","talents":{"tier_1":"vanguard_l9_1","tier_2":"vanguard_l12_1","tier_3":"vanguard_l15_r2","tier_4":"vanguard_l18_2","tier_5":"vanguard_l21_3","tier_6":"vanguard_l24_3","tier_7":"vanguard_l27_r2","tier_8":"vanguard_l30_3"}}
]
const CLASS_DEFINITION := {"class_id":"vanguard","display_name":"Vanguard","primary_role":"Tank","role":"Tank","basic_action_id":"vanguard_basic_attack","trait_id":"vanguard_rockstar","q_ability_id":"vanguard_powerslide","w_ability_id":"vanguard_face_melt","e_ability_id":"vanguard_overpower","heroic_option_ids":["vanguard_l15_r1","vanguard_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["melee","tank","mobility","control"],"color":Color("cf4c4c"),"ability":"Powerslide","base_health":VALUES.health,"health_growth":0.04,"base_power":VALUES.basic_attack_damage,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":VALUES.basic_attack_interval,"basic_action_range":SPACE.basic_range,"movement_speed":4.8398*SOURCE_TO_WORLD,"combat_radius":SPACE.combat_radius,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":VALUES.health_regeneration,"health_regeneration_growth":0.04,"threat_modifier":1.5,"basic_action_damage_type":"physical","armor_family":"plate","armor_proficiency":"plate","weapon_proficiencies":["two_handed"],"uses_mana":false,"resource_id":""}

static func scaled(value:float,level:int)->float:return value*pow(1.04,maxi(0,level-1))
