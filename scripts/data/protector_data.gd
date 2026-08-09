extends RefCounted

const CombatBalanceData=preload("res://scripts/data/combat_balance_data.gd")
const CLASS_ID:="protector"
const SCALE_PER_LEVEL:=1.04
const SOURCE_TO_WORLD:=185.0/5.5
const IDS:={"basic_attack":"protector_basic_attack","trait":"protector_archangels_wrath","q":"protector_q","w":"protector_w","e":"protector_e","r1":"protector_r1","r2":"protector_r2"}

const SPACE:={
	"source_to_world":SOURCE_TO_WORLD,"basic_range":3.75*SOURCE_TO_WORLD,"movement_speed":150.0,"combat_radius":42.0,
	"q_range":9.0*SOURCE_TO_WORLD,"q_radius":1.35*SOURCE_TO_WORLD,"q_knockback":1.8*SOURCE_TO_WORLD,
	"w_range":9.0*SOURCE_TO_WORLD,"w_length":5.5*SOURCE_TO_WORLD,"w_thickness":18.0,"w_near_radius":1.1*SOURCE_TO_WORLD,
	"e_range":5.5*SOURCE_TO_WORLD,"e_length":5.5*SOURCE_TO_WORLD,"e_half_width":2.0*SOURCE_TO_WORLD,
	"r1_range":8.0*SOURCE_TO_WORLD,"r1_secondary_radius":2.75*SOURCE_TO_WORLD,"r1_knockback":1.8*SOURCE_TO_WORLD,
	"r2_radius":3.5*SOURCE_TO_WORLD,"wrath_radius":3.5*SOURCE_TO_WORLD,"burning_radius":2.25*SOURCE_TO_WORLD
}

const VALUES:={
	"health":1850.0,"health_regeneration":3.8542,"basic_attack_damage":65.0,"basic_attack_interval":1.0,
	"trait_duration":4.0,"trait_speed":0.20,"trait_damage_reduction":0.50,"trait_linger":3.0,"trait_damage":450.0,
	"q_damage":110.0,"q_cooldown":12.0,"q_sword_duration":5.0,"q_slow":0.30,"q_slow_duration":2.5,"q_bound_slow":0.65,"q_bound_duration":1.0,"q_pursuit_speed":0.20,"q_pursuit_duration":3.0,"q_stalwart_armor":25.0,"q_stalwart_after":3.0,"q_rebuke_stun":0.5,"q_reforging_reduction":2.0,
	"w_delay":0.5,"w_duration":2.0,"w_cooldown":18.0,"w_restraining_slow":0.25,"w_restraining_linger":1.0,"w_crossing_slow":0.20,"w_crossing_duration":1.5,"w_crossing_reduction":0.5,
	"e_damage":150.0,"e_cooldown":6.0,"e_field_duration":3.0,"e_speed":0.25,"e_speed_duration":2.0,"e_radiant_bonus":2.0,"e_radiant_buff_bonus":1.0,"e_reach":1.0*SOURCE_TO_WORLD,"e_wicked_rate":1.25,
	"r1_windup":0.75,"r1_damage":150.0,"r1_stun":1.5,"r1_secondary_damage":75.0,"r1_cooldown":70.0,"r1_upgrade_range":0.50,"r1_upgrade_reduction":40.0,
	"r2_cast":0.5,"r2_duration":3.0,"r2_cooldown":85.0,"r2_upgrade_duration":1.0,"r2_upgrade_damage":0.25,
	"burning_dps":12.0,"burning_teleport_bonus":1.25,"burning_teleport_duration":2.0,"aspect_channel":1.25,"aspect_cooldown":120.0,"force_barrier_duration":0.5,"force_barrier_range":0.50,"force_barrier_reduction":10.0
}

const WORKING_NAMES:={
	"protector_trait":"Archangel's Wrath","protector_q":"El'druin's Might","protector_w":"Force Wall","protector_e":"Smite","protector_r1":"Judgment","protector_r2":"Sanctification",
	"protector_l9_1":"Pursuit of Justice","protector_l9_2":"Restraining Field","protector_l9_3":"Radiant Path",
	"protector_l12_1":"Stalwart Angel","protector_l12_2":"Rebuke","protector_l12_3":"Radiant Reach",
	"protector_l15_r1":"Judgment","protector_l15_r2":"Sanctification",
	"protector_l18_1":"Burning Halo","protector_l18_2":"Crossing Fire","protector_l18_3":"Purge Evil",
	"protector_l21_1":"Sword of Justice","protector_l21_2":"Piercing Justice","protector_l21_3":"Law and Order",
	"protector_l24_1":"Bound by Law","protector_l24_2":"Horadric Reforging","protector_l24_3":"Smite the Wicked",
	"protector_l27_r1":"Angel of Justice","protector_l27_r2":"Holy Arena",
	"protector_l30_1":"Aspect of Justice","protector_l30_2":"Force Barrier","protector_l30_3":"Seal of El'druin"
}

const TALENT_DESCRIPTIONS:={
	"protector_l9_1":"Teleporting grants 20% Movement Speed for 3 seconds.","protector_l9_2":"Enemies near your Force Wall are Slowed by 25%, lingering for 1 second.","protector_l9_3":"Smite's field lasts 2 seconds longer and its movement bonus lasts 1 second longer.",
	"protector_l12_1":"Gain 25 Armor while El'druin is available and for 3 seconds after teleporting.","protector_l12_2":"Enemies knocked into your own Force Wall by El'druin are Stunned for 0.5 seconds.","protector_l12_3":"Smite's movement blessing also grants 1 source unit of Basic Attack range.",
	"protector_l15_r1":"Charge an enemy, damaging and Stunning it while knocking nearby enemies away.","protector_l15_r2":"After a short cast, make allied Heroes in an area Invulnerable for 3 seconds.",
	"protector_l18_1":"The Protector and active sword deal 12 damage per second nearby; the sword aura is stronger after teleporting.","protector_l18_2":"Basic Attacks crossing your Force Wall Slow and reduce Force Wall's cooldown.","protector_l18_3":"Smite clears the highest non-Protector allied threat from each enemy it damages.",
	"protector_l21_1":"After teleporting, El'druin moves to the original position and may be teleported to once more.","protector_l21_2":"Throwing El'druin through your Force Wall empowers its knockback and each teleport reduces Force Wall's cooldown by 5 seconds.","protector_l21_3":"Smite crossing your Force Wall creates one mirrored field on its opposite side.",
	"protector_l24_1":"El'druin initially Slows by 65% for 1 second before returning to its normal Slow.","protector_l24_2":"Basic Attacks against enemies marked by your El'druin reduce its cooldown by 2 seconds.","protector_l24_3":"Smite recharges 125% faster while the sword is active and for 2 seconds after teleporting.",
	"protector_l27_r1":"Judgment gains 50% range and its cooldown is reduced by 40 seconds.","protector_l27_r2":"Sanctification lasts 1 second longer and allies inside deal 25% more damage.",
	"protector_l30_1":"Archangel's Wrath may be channeled while alive, returning you at the same Health after it ends.","protector_l30_2":"Force Wall lasts 0.5 seconds longer, gains 50% cast range, and has 10 seconds less cooldown.","protector_l30_3":"Smite has two sequential charges."
}

const TALENT_TIERS:=[
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["protector_l9_1","protector_l9_2","protector_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["protector_l12_1","protector_l12_2","protector_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["protector_l15_r1","protector_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["protector_l18_1","protector_l18_2","protector_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["protector_l21_1","protector_l21_2","protector_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["protector_l24_1","protector_l24_2","protector_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["protector_l27_r1","protector_l27_r2"],"heroic_requirements":{"protector_l27_r1":"protector_l15_r1","protector_l27_r2":"protector_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["protector_l30_1","protector_l30_2","protector_l30_3"]}
]

const TEST_BUILDS:=[
	{"name":"Level 1 Baseline","level":1,"heroic":"","talents":{}},
	{"name":"Teleport / Disruption","level":30,"heroic":"protector_l15_r1","talents":{"tier_1":"protector_l9_1","tier_2":"protector_l12_1","tier_3":"protector_l15_r1","tier_4":"protector_l18_1","tier_5":"protector_l21_1","tier_6":"protector_l24_1","tier_7":"protector_l27_r1","tier_8":"protector_l30_1"}},
	{"name":"Force Wall / Setup","level":30,"heroic":"protector_l15_r1","talents":{"tier_1":"protector_l9_2","tier_2":"protector_l12_2","tier_3":"protector_l15_r1","tier_4":"protector_l18_2","tier_5":"protector_l21_2","tier_6":"protector_l24_2","tier_7":"protector_l27_r1","tier_8":"protector_l30_2"}},
	{"name":"Smite / Party","level":30,"heroic":"protector_l15_r2","talents":{"tier_1":"protector_l9_3","tier_2":"protector_l12_3","tier_3":"protector_l15_r2","tier_4":"protector_l18_3","tier_5":"protector_l21_3","tier_6":"protector_l24_3","tier_7":"protector_l27_r2","tier_8":"protector_l30_3"}}
]

const CLASS_DEFINITION:={"class_id":"protector","display_name":"Protector","primary_role":"Tank","role":"Tank","basic_action_id":"protector_basic_attack","trait_id":"protector_archangels_wrath","q_ability_id":"protector_q","w_ability_id":"protector_w","e_ability_id":"protector_e","heroic_option_ids":["protector_l15_r1","protector_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["tank","melee","mobile","battlefield_control"],"color":Color("66d8ff"),"ability":"El'druin's Might","base_health":1850.0,"health_growth":0.04,"base_power":65.0,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.0,"basic_action_range":SPACE.basic_range,"movement_speed":SPACE.movement_speed,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":VALUES.health_regeneration,"health_regeneration_growth":0.04,"threat_modifier":CombatBalanceData.TANK_THREAT_MODIFIER,"basic_action_damage_type":"physical","armor_family":"plate","armor_proficiency":"plate","weapon_proficiencies":["one_handed","two_handed"],"uses_mana":false,"resource_id":""}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)
