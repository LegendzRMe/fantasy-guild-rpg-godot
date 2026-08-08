extends RefCounted

const CLASS_ID := "shaman"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5
const IDS := {"basic_attack":"shaman_basic_attack","trait":"shaman_trait","q":"shaman_q","w":"shaman_w","e":"shaman_e","r1":"shaman_r1","r2":"shaman_r2"}

# Source-space conversions are centralized here because public data does not
# expose every collision width used by the original client.
const SPACE := {
	"source_to_world":SOURCE_TO_WORLD,"basic_range":1.5*SOURCE_TO_WORLD,"movement_speed":150.0,"combat_radius":42.0,
	"q_bounce_radius":7.5*SOURCE_TO_WORLD,"w_base_distance":7.0*SOURCE_TO_WORLD,"w_width":0.75*SOURCE_TO_WORLD,"w_speed":480.0,
	"r1_length":12.0*SOURCE_TO_WORLD,"r1_width":1.25*SOURCE_TO_WORLD,"r1_shove":1.5*SOURCE_TO_WORLD,
	"r2_radius":6.0*SOURCE_TO_WORLD,"alpha_mark_duration":3.0
}

const VALUES := {
	"health":1946.0,"health_regeneration":4.0546,"basic_attack_damage":167.0,"basic_attack_interval":1.1,
	"trait_threshold":5,"trait_heal":240.0,
	"q_initial":170.0,"q_bounce":85.0,"q_bounces":3,"q_cooldown":7.0,"q_kill_window":2.0,
	"w_damage":153.0,"w_root":1.0,"w_cooldown":10.0,"w_extension":0.25,
	"e_speed":0.30,"e_duration":4.0,"e_attacks":3,"e_attack_speed":1.0,"e_cooldown":12.0,
	"r1_delay":0.5,"r1_damage":290.0,"r1_stun":1.0,"r1_cooldown":70.0,
	"r2_delay":0.5,"r2_damage":50.0,"r2_slow":0.50,"r2_slow_duration":2.0,"r2_pulses":3,"r2_interval":4.0,"r2_cooldown":100.0,
	"echo_reward_1":20,"echo_reward_2":50,"echo_mythic":200,"echo_cooldown_reduction":1.0,
	"crash_reward_1":15,"crash_reward_2":30,"crash_mythic":100,"crash_bounce_bonus":270.0,"crash_mythic_bonus":325.0,
	"maelstrom_reward_1":25,"maelstrom_reward_2":55,"maelstrom_mythic":100,"maelstrom_move_1":0.40,"maelstrom_damage_1":40.0,"maelstrom_damage_2":75.0,"maelstrom_move_2":0.15,
	"feral_resilience_contacts":5,"feral_resilience_extra_stacks":4,"feral_resilience_block_charges":2,"feral_resilience_block_armor":75.0,
	"frostwolf_pack_goal":6,"overflow_rate":0.50,"overflow_duration":4.0,"overflow_cap":0.10,
	"rolling_duration":8.0,"rolling_bonus":0.25,"ancestral_max":8,"ancestral_duration":3.0,"ancestral_heal":1.50,
	"elemental_duration":4.0,"elemental_bonus":0.45,"frostwolf_grace_cooldown":15.0,"frostwolf_grace_missing_bonus":1.0,
	"gathering_max":20,"gathering_per_stack":0.005,"tempest_subhits":2,"tempest_subhit_damage":0.75,
	"thunder_slow_per_stack":0.08,"thunder_max":5,"thunder_duration":2.0,"thunder_max_damage":0.30,
	"alpha_root":1.5,"alpha_bonus":0.05,"worldbreaker_cooldown_reduction":40.0,"worldbreaker_duration":3.0,
	"earthen_shield":0.15,"earthen_shield_duration":4.0,"stormcaller_threshold":5,"stormcaller_rate":0.50,"spirit_pack_rate":0.50
}

const WORKING_NAMES := {
	"shaman_trait":"Frostwolf Resilience","shaman_q":"Chain Lightning","shaman_w":"Feral Spirit","shaman_e":"Windfury","shaman_r1":"Sundering","shaman_r2":"Earthquake",
	"shaman_l9_1":"Echo of the Elements","shaman_l9_2":"Crash Lightning","shaman_l9_3":"Maelstrom Weapon",
	"shaman_l12_1":"Feral Resilience","shaman_l12_2":"Frostwolf Pack","shaman_l12_3":"Overflowing Resilience",
	"shaman_l15_r1":"Sundering","shaman_l15_r2":"Earthquake","shaman_l18_1":"Rolling Thunder","shaman_l18_2":"Ancestral Wrath","shaman_l18_3":"Elemental Assault",
	"shaman_l21_1":"Grace of Air","shaman_l21_2":"Frostwolf's Grace","shaman_l21_3":"Gathering Storm",
	"shaman_l24_1":"Tempest Fury","shaman_l24_2":"Thunderstorm","shaman_l24_3":"Alpha Wolf",
	"shaman_l27_r1":"Worldbreaker","shaman_l27_r2":"Earthen Shields",
	"shaman_l30_1":"Stormcaller","shaman_l30_2":"Fury of the Winds","shaman_l30_3":"Spirit of the Pack"
}

const TALENT_DESCRIPTIONS := {
	"shaman_l9_1":"Chain Lightning-assisted defeats earn encounter cooldown and charge rewards, plus character-persistent Mythic mastery.",
	"shaman_l9_2":"Three-target Chain Lightning casts earn encounter bounce and Frostwolf rewards, plus character-persistent Mythic mastery.",
	"shaman_l9_3":"Successful attacks during Windfury earn encounter movement and damage rewards, plus character-persistent Mythic mastery.",
	"shaman_l12_1":"Feral Spirit grants extra Frostwolf stacks and shared Block charges from up to five contacts.",
	"shaman_l12_2":"Six separate successful Feral Spirit casts halve its cooldown for this encounter; a miss resets unfinished progress.",
	"shaman_l12_3":"High-Health Frostwolf overhealing becomes a capped, four-second Shield.",
	"shaman_l15_r1":"Split enemies with a damaging line, sideways shove, and Stun.","shaman_l15_r2":"Create three damaging, heavily Slowing pulses.",
	"shaman_l18_1":"Chain Lightning marks enemies for a Frostwolf-generating, self-healing bonus Basic Attack.",
	"shaman_l18_2":"Eight Frostwolf activations arm three seconds of healing from Shaman damage after a multi-target Basic Ability.",
	"shaman_l18_3":"After an Ability, the next successful Basic Attack within four seconds deals 45% additional damage.",
	"shaman_l21_1":"Windfury attacks grant twice the normal Frostwolf stacks.","shaman_l21_2":"Activate D to heal without consuming passive stacks, increased by missing Health.",
	"shaman_l21_3":"Basic Attacks build up to 10% bonus damage for the next damaging Basic Ability.",
	"shaman_l24_1":"The final Windfury attack produces two additional 75%-damage subhits.",
	"shaman_l24_2":"Changing Chain Lightning primary targets builds Slow and a max-stack damage bonus for this encounter.",
	"shaman_l24_3":"Feral Spirit Roots longer and marks each contact to take 5% more Shaman damage for three seconds.",
	"shaman_l27_r1":"Sundering recharges faster and leaves a real three-second movement-blocking rift.",
	"shaman_l27_r2":"Every Earthquake pulse Shields allies in its area for 15% maximum Health.",
	"shaman_l30_1":"A five-target player Chain Lightning releases a non-recursive 50%-effectiveness second chain.",
	"shaman_l30_2":"Three successful Windfury attacks against three different enemies immediately recast Windfury.",
	"shaman_l30_3":"Feral Spirit's endpoint releases a 50%-damage return spirit that can extend independently."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["shaman_l9_1","shaman_l9_2","shaman_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["shaman_l12_1","shaman_l12_2","shaman_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["shaman_l15_r1","shaman_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["shaman_l18_1","shaman_l18_2","shaman_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["shaman_l21_1","shaman_l21_2","shaman_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["shaman_l24_1","shaman_l24_2","shaman_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["shaman_l27_r1","shaman_l27_r2"],"heroic_requirements":{"shaman_l27_r1":"shaman_l15_r1","shaman_l27_r2":"shaman_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["shaman_l30_1","shaman_l30_2","shaman_l30_3"]}
]

const TEST_BUILDS := [
	{"name":"Level 1 Baseline","level":1,"heroic":"","talents":{}},
	{"name":"Echo Chain Lightning","level":30,"heroic":"shaman_l15_r1","talents":{"tier_1":"shaman_l9_1","tier_2":"shaman_l12_2","tier_3":"shaman_l15_r1","tier_4":"shaman_l18_1","tier_5":"shaman_l21_3","tier_6":"shaman_l24_2","tier_7":"shaman_l27_r1","tier_8":"shaman_l30_1"}},
	{"name":"Crash Chain Lightning","level":30,"heroic":"shaman_l15_r1","talents":{"tier_1":"shaman_l9_2","tier_2":"shaman_l12_2","tier_3":"shaman_l15_r1","tier_4":"shaman_l18_1","tier_5":"shaman_l21_3","tier_6":"shaman_l24_2","tier_7":"shaman_l27_r1","tier_8":"shaman_l30_1"}},
	{"name":"Maelstrom Windfury","level":30,"heroic":"shaman_l15_r2","talents":{"tier_1":"shaman_l9_3","tier_2":"shaman_l12_1","tier_3":"shaman_l15_r2","tier_4":"shaman_l18_3","tier_5":"shaman_l21_1","tier_6":"shaman_l24_1","tier_7":"shaman_l27_r2","tier_8":"shaman_l30_2"}},
	{"name":"Feral Resilience","level":30,"heroic":"shaman_l15_r1","talents":{"tier_1":"shaman_l9_2","tier_2":"shaman_l12_1","tier_3":"shaman_l15_r1","tier_4":"shaman_l18_2","tier_5":"shaman_l21_2","tier_6":"shaman_l24_3","tier_7":"shaman_l27_r1","tier_8":"shaman_l30_3"}},
	{"name":"Overflowing Resilience","level":30,"heroic":"shaman_l15_r2","talents":{"tier_1":"shaman_l9_3","tier_2":"shaman_l12_3","tier_3":"shaman_l15_r2","tier_4":"shaman_l18_2","tier_5":"shaman_l21_2","tier_6":"shaman_l24_1","tier_7":"shaman_l27_r2","tier_8":"shaman_l30_2"}},
	{"name":"Rolling Thunder","level":30,"heroic":"shaman_l15_r1","talents":{"tier_1":"shaman_l9_1","tier_2":"shaman_l12_2","tier_3":"shaman_l15_r1","tier_4":"shaman_l18_1","tier_5":"shaman_l21_3","tier_6":"shaman_l24_2","tier_7":"shaman_l27_r1","tier_8":"shaman_l30_1"}},
	{"name":"Ancestral Wrath","level":30,"heroic":"shaman_l15_r2","talents":{"tier_1":"shaman_l9_3","tier_2":"shaman_l12_3","tier_3":"shaman_l15_r2","tier_4":"shaman_l18_2","tier_5":"shaman_l21_2","tier_6":"shaman_l24_3","tier_7":"shaman_l27_r2","tier_8":"shaman_l30_3"}},
	{"name":"Gathering Storm","level":30,"heroic":"shaman_l15_r1","talents":{"tier_1":"shaman_l9_2","tier_2":"shaman_l12_2","tier_3":"shaman_l15_r1","tier_4":"shaman_l18_3","tier_5":"shaman_l21_3","tier_6":"shaman_l24_2","tier_7":"shaman_l27_r1","tier_8":"shaman_l30_1"}},
	{"name":"Thunderstorm","level":30,"heroic":"shaman_l15_r1","talents":{"tier_1":"shaman_l9_1","tier_2":"shaman_l12_2","tier_3":"shaman_l15_r1","tier_4":"shaman_l18_1","tier_5":"shaman_l21_3","tier_6":"shaman_l24_2","tier_7":"shaman_l27_r1","tier_8":"shaman_l30_1"}},
	{"name":"Alpha Wolf","level":30,"heroic":"shaman_l15_r1","talents":{"tier_1":"shaman_l9_2","tier_2":"shaman_l12_1","tier_3":"shaman_l15_r1","tier_4":"shaman_l18_2","tier_5":"shaman_l21_1","tier_6":"shaman_l24_3","tier_7":"shaman_l27_r1","tier_8":"shaman_l30_3"}},
	{"name":"Worldbreaker","level":30,"heroic":"shaman_l15_r1","talents":{"tier_1":"shaman_l9_2","tier_2":"shaman_l12_2","tier_3":"shaman_l15_r1","tier_4":"shaman_l18_1","tier_5":"shaman_l21_3","tier_6":"shaman_l24_2","tier_7":"shaman_l27_r1","tier_8":"shaman_l30_1"}},
	{"name":"Earthen Shields","level":30,"heroic":"shaman_l15_r2","talents":{"tier_1":"shaman_l9_3","tier_2":"shaman_l12_3","tier_3":"shaman_l15_r2","tier_4":"shaman_l18_2","tier_5":"shaman_l21_2","tier_6":"shaman_l24_1","tier_7":"shaman_l27_r2","tier_8":"shaman_l30_2"}},
	{"name":"Stormcaller","level":30,"heroic":"shaman_l15_r1","talents":{"tier_1":"shaman_l9_1","tier_2":"shaman_l12_2","tier_3":"shaman_l15_r1","tier_4":"shaman_l18_1","tier_5":"shaman_l21_3","tier_6":"shaman_l24_2","tier_7":"shaman_l27_r1","tier_8":"shaman_l30_1"}},
	{"name":"Fury of the Winds","level":30,"heroic":"shaman_l15_r2","talents":{"tier_1":"shaman_l9_3","tier_2":"shaman_l12_3","tier_3":"shaman_l15_r2","tier_4":"shaman_l18_3","tier_5":"shaman_l21_1","tier_6":"shaman_l24_1","tier_7":"shaman_l27_r2","tier_8":"shaman_l30_2"}},
	{"name":"Spirit of the Pack","level":30,"heroic":"shaman_l15_r1","talents":{"tier_1":"shaman_l9_2","tier_2":"shaman_l12_1","tier_3":"shaman_l15_r1","tier_4":"shaman_l18_2","tier_5":"shaman_l21_1","tier_6":"shaman_l24_3","tier_7":"shaman_l27_r1","tier_8":"shaman_l30_3"}}
]

const CLASS_DEFINITION := {"class_id":"shaman","display_name":"Shaman","primary_role":"Melee DPS","role":"Melee DPS","basic_action_id":"shaman_basic_attack","trait_id":"shaman_trait","q_ability_id":"shaman_q","w_ability_id":"shaman_w","e_ability_id":"shaman_e","heroic_option_ids":["shaman_l15_r1","shaman_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["melee","damage","group_specialist"],"color":Color("55b8d4"),"ability":"Chain Lightning","base_health":1946.0,"health_growth":0.04,"base_power":167.0,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.1,"basic_action_range":1.5*SOURCE_TO_WORLD,"movement_speed":150.0,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":4.0546,"health_regeneration_growth":0.04,"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"mail","armor_proficiency":"mail","weapon_proficiencies":["one_handed","two_handed"],"uses_mana":false,"resource_id":""}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)
