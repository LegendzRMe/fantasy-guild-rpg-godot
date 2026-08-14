extends RefCounted

const CLASS_ID := "monk"
const SCALE_PER_LEVEL := 1.04
const SOURCE_BUILD := "2.55.17.97771"
const SOURCE_TO_WORLD := 185.0 / 5.5

# Non-chassis space values are centralized provisional conversions because the
# normalized public hero document does not expose every effect-search radius.
const SPACE := {
	"source_to_world":SOURCE_TO_WORLD,"basic_range":1.75*SOURCE_TO_WORLD,"movement_speed":4.8398*SOURCE_TO_WORLD,"combat_radius":0.625*SOURCE_TO_WORLD,
	"dash_range":6.0*SOURCE_TO_WORLD,"dash_landing_offset":0.9*SOURCE_TO_WORLD,"breath_radius":3.5*SOURCE_TO_WORLD,"deadly_range_multiplier":2.0,
	"trait_radius":6.0*SOURCE_TO_WORLD,"ally_placement_range":4.0*SOURCE_TO_WORLD,"ally_aura_radius":4.5*SOURCE_TO_WORLD,"ally_radius":0.5*SOURCE_TO_WORLD,
	"palm_range":3.0*SOURCE_TO_WORLD,"seven_sided_range":3.0*SOURCE_TO_WORLD,"hundred_fists_offset":0.55*SOURCE_TO_WORLD
}

const VALUES := {
	"health":2080.0,"health_regeneration":4.3333,"basic_attack_damage":64.0,"basic_attack_interval":0.5,"threat_modifier":1.0,
	"q_charges":2,"q_recharge":12.0,"q_intercast":0.25,"blinding_charges":3,"blinding_recharge":10.0,
	"breath_heal":295.0,"breath_cooldown":10.0,"breath_speed":0.15,"breath_speed_duration":3.0,
	"deadly_cooldown":10.0,"deadly_duration":2.0,"deadly_speed":1.0,"deadly_range":1.0,
	"trait_heal":104.0,"trait_bonus":1.10,"trait_speed":0.25,"trait_speed_duration":2.5,"insight_goal":100,"insight_cdr":1.75,
	"ally_cooldown":45.0,"ally_duration":10.0,"spirit_health":150.0,"earth_health":400.0,"air_health":300.0,"spirit_heal_fraction":0.02,"earth_armor":50.0,"air_ability_power":0.10,
	"palm_cooldown":50.0,"palm_duration":4.0,"palm_heal":1200.0,"peaceful_multiplier":1.75,"peaceful_failed_cooldown":5.0,
	"seven_cooldown":50.0,"seven_duration":2.0,"seven_strikes":7,"seven_normal":0.07,"seven_boss":0.005,"transgression_strikes":4,
	"heavenly_heal":0.50,"heavenly_speed":0.30,"blazing_cdr":0.75,"blazing_duration_multiplier":2.0,
	"breath_armor":50.0,"breath_armor_duration":3.0,"controlled_bonus":0.25,"sanctified_duration":1.0,
	"hundred_strikes":6,"hundred_damage":0.45,"echo_fraction":0.75,"echo_delay":3.0,
	"storm_fraction":0.20,"storm_duration":3.0,"storm_icd":45.0,"epiphany_icd":70.0
}

const WORKING_NAMES := {
	"monk_l9_1":"Transcendence","monk_l9_2":"Iron Fists","monk_l9_3":"Insight",
	"monk_l12_1":"Spirit Ally","monk_l12_2":"Earth Ally","monk_l12_3":"Air Ally",
	"monk_l15_r1":"Divine Palm","monk_l15_r2":"Seven-Sided Strike",
	"monk_l18_1":"Blinding Speed","monk_l18_2":"Heavenly Zeal","monk_l18_3":"Blazing Fists",
	"monk_l21_1":"Quicksilver","monk_l21_2":"Breath Armor","monk_l21_3":"Controlled Assault",
	"monk_l24_1":"Sanctified Dash","monk_l24_2":"Way of the Hundred Fists","monk_l24_3":"Echo of Heaven",
	"monk_l27_r1":"Peaceful Repose","monk_l27_r2":"Transgression",
	"monk_l30_1":"Fists of Legend","monk_l30_2":"Storm Shield","monk_l30_3":"Epiphany"
}

const TALENT_DESCRIPTIONS := {
	"monk_l9_1":"Every third qualifying Basic Attack heals the lowest-Health nearby eligible ally for 104 and grants 25% Movement Speed for 2.5 seconds.",
	"monk_l9_2":"Every third qualifying Basic Attack deals 110% bonus damage and grants 25% Movement Speed for 2.5 seconds.",
	"monk_l9_3":"Every third qualifying Basic Attack grants encounter Insight. At 100, later third hits reduce Q/W/E by 1.75 seconds.",
	"monk_l12_1":"D places a 150-Health Spirit Ally for 10 seconds; it heals nearby eligible allies for 2% maximum Health each second.",
	"monk_l12_2":"D places a 400-Health Earth Ally for 10 seconds; nearby eligible allies gain 50 level-one Universal Armor.",
	"monk_l12_3":"D places a 300-Health Air Ally for 10 seconds; nearby eligible allies gain 10% Ability Power.",
	"monk_l15_r1":"Protect an eligible ally from lethal damage for four seconds; a trigger heals 1200.",
	"monk_l15_r2":"Become Invulnerable and strike seven times over two seconds for 7% maximum Health, or 0.5% against Bosses.",
	"monk_l18_1":"Radiant Dash gains a third charge and recharges in 10 seconds.",
	"monk_l18_2":"The allied Dash target receives 50% additional Breath healing; Breath Movement Speed becomes 30%.",
	"monk_l18_3":"Deadly Reach lasts twice as long; every third Basic Attack reduces its cooldown by 0.75 seconds.",
	"monk_l21_1":"An allied Dash removes Stun and Root before Breath without granting Unstoppable.",
	"monk_l21_2":"Primary Breath grants 50 level-one Universal Armor for three seconds.",
	"monk_l21_3":"While Reach is active, Monk deals 25% more damage to currently Stunned or Rooted enemies.",
	"monk_l24_1":"An allied Dash grants its target Protected for one second without control immunity.",
	"monk_l24_2":"Enemy Dash follows its immediate attack with six 45%-damage qualifying Basic Attacks.",
	"monk_l24_3":"Breath heals 75% immediately and the same recipients for 75% after three seconds.",
	"monk_l27_r1":"Palm healing increases 75%; an untriggered Palm leaves only five seconds of cooldown.",
	"monk_l27_r2":"Seven-Sided Strike performs four additional strikes.",
	"monk_l30_1":"Every third hit gains half of each unchosen Trait's healing, damage, or completed Insight cooldown reduction.",
	"monk_l30_2":"Primary Breath grants affected eligible allies a 20%-maximum-Health Shield for three seconds; 45-second internal cooldown.",
	"monk_l30_3":"When a Dash spend leaves zero charges, refill to the current maximum; 70-second internal cooldown."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["monk_l9_1","monk_l9_2","monk_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["monk_l12_1","monk_l12_2","monk_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["monk_l15_r1","monk_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["monk_l18_1","monk_l18_2","monk_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["monk_l21_1","monk_l21_2","monk_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["monk_l24_1","monk_l24_2","monk_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["monk_l27_r1","monk_l27_r2"],"heroic_requirements":{"monk_l27_r1":"monk_l15_r1","monk_l27_r2":"monk_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["monk_l30_1","monk_l30_2","monk_l30_3"]}
]

const TEST_BUILDS := [
	{"name":"Level 1 Baseline","level":1,"heroic":"","talents":{}},
	{"name":"Transcendence Palm","level":30,"heroic":"monk_l15_r1","talents":{"tier_1":"monk_l9_1","tier_2":"monk_l12_1","tier_3":"monk_l15_r1","tier_4":"monk_l18_2","tier_5":"monk_l21_1","tier_6":"monk_l24_1","tier_7":"monk_l27_r1","tier_8":"monk_l30_2"}},
	{"name":"Iron Fists Seven","level":30,"heroic":"monk_l15_r2","talents":{"tier_1":"monk_l9_2","tier_2":"monk_l12_2","tier_3":"monk_l15_r2","tier_4":"monk_l18_3","tier_5":"monk_l21_3","tier_6":"monk_l24_2","tier_7":"monk_l27_r2","tier_8":"monk_l30_1"}},
	{"name":"Insight Echo","level":30,"heroic":"monk_l15_r1","talents":{"tier_1":"monk_l9_3","tier_2":"monk_l12_3","tier_3":"monk_l15_r1","tier_4":"monk_l18_1","tier_5":"monk_l21_2","tier_6":"monk_l24_3","tier_7":"monk_l27_r1","tier_8":"monk_l30_1"}},
	{"name":"Dash Spam","level":30,"heroic":"monk_l15_r2","talents":{"tier_1":"monk_l9_2","tier_2":"monk_l12_1","tier_3":"monk_l15_r2","tier_4":"monk_l18_1","tier_5":"monk_l21_1","tier_6":"monk_l24_2","tier_7":"monk_l27_r2","tier_8":"monk_l30_3"}}
]

const CLASS_DEFINITION := {
	"class_id":"monk","display_name":"Monk","primary_role":"Support","role":"Support","basic_action_id":"monk_basic_attack","trait_id":"monk_chosen_trait","q_ability_id":"monk_radiant_dash","w_ability_id":"monk_breath_of_heaven","e_ability_id":"monk_deadly_reach","heroic_option_ids":["monk_l15_r1","monk_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["melee","support","basic_attack"],"color":Color("d7b56d"),"ability":"Radiant Dash",
	"base_health":VALUES.health,"health_growth":0.04,"base_power":VALUES.basic_attack_damage,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":VALUES.basic_attack_interval,"basic_action_range":SPACE.basic_range,"movement_speed":SPACE.movement_speed,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":VALUES.health_regeneration,"health_regeneration_growth":0.04,"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"leather","armor_proficiency":"leather","weapon_proficiencies":["fist_weapon","staff"],"uses_mana":false,"resource_id":""
}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)
