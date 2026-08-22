extends RefCounted

const CLASS_ID := "vitalist"
const SOURCE_BUILD := "2.55.17.97771"
const SOURCE_TO_WORLD := 185.0 / 5.5
const SPACE := {
	"combat_radius":0.6875*SOURCE_TO_WORLD,"basic_range":1.5*SOURCE_TO_WORLD,"fetid_range":5.5*SOURCE_TO_WORLD,
	"q_range":7.0*SOURCE_TO_WORLD,"q_spread_radius":4.5*SOURCE_TO_WORLD,"w_range":10.0*SOURCE_TO_WORLD,"w_radius":0.5*SOURCE_TO_WORLD,
	"reactive_radius":5.5*SOURCE_TO_WORLD,"e_range":5.5*SOURCE_TO_WORLD,"e_radius":2.5*SOURCE_TO_WORLD,
	"swipe_ranges":[4.0*SOURCE_TO_WORLD,5.5*SOURCE_TO_WORLD,7.0*SOURCE_TO_WORLD],"swipe_half_angle":deg_to_rad(50.0),
	"shove_range":10.0*SOURCE_TO_WORLD,"poppin_radius":2.5*SOURCE_TO_WORLD
}
const VALUES := {
	"health":1835.0,"health_regeneration":3.8242,"basic_attack_damage":261.0,"basic_attack_interval":1.5,"contact_cap":5,
	"q_cooldown":10.0,"q_total_heal":222.0,"q_duration":4.5,"q_tick":0.5,"q_spread_interval":0.75,
	"w_cooldown":10.0,"w_initial_damage":20.0,"w_expire_damage":88.0,"w_duration":3.0,"w_slow_start":0.05,"w_slow_end":0.50,
	"d_cooldown":16.0,"d_q_heal":435.0,"d_w_damage":100.0,"d_w_slow":0.70,"d_w_slow_duration":2.0,
	"e_cooldown":10.0,"e_dps":136.0,"e_tick":0.5,"fetid_slow":0.20,"fetid_slow_duration":1.5,"fetid_damage_multiplier":0.65,"fetid_quest":15,"fetid_cdr":5.0,
	"one_good_cdr":2.0,"biotic_armor":10.0,"biotic_burst_armor":50.0,"biotic_burst_duration":2.5,"vigorous_bonus":0.30,
	"long_pitch_rate":1.0,"long_pitch_duration":4.0,"growing_duration":2.5,"targeted_recharge":7.0,
	"swipe_cooldown":60.0,"swipe_duration":1.75,"swipe_damage":48.0,"swipe_displacement":2.75*SOURCE_TO_WORLD,
	"shove_cooldown":20.0,"shove_damage":190.0,"shove_stun":0.5,"shove_speed":8.0*SOURCE_TO_WORLD,
	"it_hungers_contacts":8,"superstrain_heal":300.0,"carrier_hot_multiplier":0.75,"pox_extension":3.0,
	"controlled_recharge":25.0,"push_slow":0.50,"push_slow_duration":4.0,"push_threshold":1.25,"push_cdr":15.0,
	"top_off_threshold":0.60,"top_off_bonus":0.30,"perfect_lockout":2.0
}
const WORKING_NAMES := {
	"vitalist_l9_1":"Fetid Touch","vitalist_l9_2":"Low Blow","vitalist_l9_3":"Reactive Ballistospores",
	"vitalist_l12_1":"One Good Spread","vitalist_l12_2":"Biotic Armor","vitalist_l12_3":"Vigorous Reuptake",
	"vitalist_l15_r1":"Flailing Swipe","vitalist_l15_r2":"Massive Shove",
	"vitalist_l18_1":"The Long Pitch","vitalist_l18_2":"Growing Infestation","vitalist_l18_3":"Targeted Excision",
	"vitalist_l21_1":"It Hungers","vitalist_l21_2":"Virulent Reaction","vitalist_l21_3":"Poppin' Pustules",
	"vitalist_l24_1":"Superstrain","vitalist_l24_2":"Universal Carrier","vitalist_l24_3":"Pox Populi",
	"vitalist_l27_r1":"Controlled Chaos","vitalist_l27_r2":"Push Comes to Shove",
	"vitalist_l30_1":"Top Off","vitalist_l30_2":"Bio-Explosion Switch","vitalist_l30_3":"Perfect Strain"
}
const TALENT_DESCRIPTIONS := {
	"vitalist_l9_1":"Basic Attacks permanently become ranged, Slow 20%, and deal 35% less damage. Encounter quest: 15 qualifying W hits reduce W cooldown by five seconds.",
	"vitalist_l9_2":"Lurking Arm deals 100% more damage to targets currently below 50% Health.",
	"vitalist_l9_3":"Below 50% Health, D recharges 100% faster and applies nearby W infections before its snapshot.",
	"vitalist_l12_1":"When one Q cast infects three allies, remove two seconds from Q cooldown once.",
	"vitalist_l12_2":"Q grants 10 Universal Armor; D upgrades it to 50 for 2.5 seconds.",
	"vitalist_l12_3":"D burst healing is 30% stronger when its snapshot contains at least three Q infections.",
	"vitalist_l15_r1":"Three expanding frontal swipes over 1.75 seconds deal damage and knock enemies away.",
	"vitalist_l15_r2":"Capture and shove one enemy until terrain, a blocker, or the encounter boundary.",
	"vitalist_l18_1":"W range +50%; detonating at least two W doubles Q/W/E/D recharge for four seconds.",
	"vitalist_l18_2":"Each E cast extends each infected ally inside it by 2.5 seconds once.",
	"vitalist_l18_3":"D with exactly one Q preserves it at full duration and gives the spent D use a seven-second recharge.",
	"vitalist_l21_1":"E range +30%; eight qualifying damage contacts reset E cooldown once per channel.",
	"vitalist_l21_2":"An ally inside E may receive the same original Q cast twice.",
	"vitalist_l21_3":"D's W detonation becomes AoE and applies replacement W infections after the snapshot resolves.",
	"vitalist_l24_1":"A newly applied Stun or Root heals an ally carrying this Vitalist's Q for 300 Level-1 Health.",
	"vitalist_l24_2":"Q may repeatedly spread through Vitalist; ordinary Q HoT is reduced by 25%.",
	"vitalist_l24_3":"D still burst-heals Q, preserves it, then adds three seconds remaining duration.",
	"vitalist_l27_r1":"Swipe has three sequential charges, one maximum-range swipe per use, and 25-second recharge.",
	"vitalist_l27_r2":"Shove collision Slows 50% for four seconds; pushing over 1.25 seconds removes 15 seconds from R cooldown.",
	"vitalist_l30_1":"Ordinary Q HoT is 30% stronger while its recipient is above 60% Health.",
	"vitalist_l30_2":"The selected Heroic may be used during E without cancelling E; Q/W remain locked.",
	"vitalist_l30_3":"D has two sequential charges and a two-second recast lockout."
}
const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["vitalist_l9_1","vitalist_l9_2","vitalist_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["vitalist_l12_1","vitalist_l12_2","vitalist_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["vitalist_l15_r1","vitalist_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["vitalist_l18_1","vitalist_l18_2","vitalist_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["vitalist_l21_1","vitalist_l21_2","vitalist_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["vitalist_l24_1","vitalist_l24_2","vitalist_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["vitalist_l27_r1","vitalist_l27_r2"],"heroic_requirements":{"vitalist_l27_r1":"vitalist_l15_r1","vitalist_l27_r2":"vitalist_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["vitalist_l30_1","vitalist_l30_2","vitalist_l30_3"]}
]
const TEST_BUILDS := [
	{"name":"Baseline Network","level":30,"heroic":"vitalist_l15_r1","talents":{}},
	{"name":"Persistent Pathogen","level":30,"heroic":"vitalist_l15_r1","talents":{"tier_1":"vitalist_l9_2","tier_2":"vitalist_l12_2","tier_3":"vitalist_l15_r1","tier_4":"vitalist_l18_3","tier_5":"vitalist_l21_2","tier_6":"vitalist_l24_3","tier_7":"vitalist_l27_r1","tier_8":"vitalist_l30_1"}},
	{"name":"Aggressive Detonation","level":30,"heroic":"vitalist_l15_r2","talents":{"tier_1":"vitalist_l9_3","tier_2":"vitalist_l12_3","tier_3":"vitalist_l15_r2","tier_4":"vitalist_l18_1","tier_5":"vitalist_l21_3","tier_6":"vitalist_l24_1","tier_7":"vitalist_l27_r2","tier_8":"vitalist_l30_3"}},
	{"name":"Arm Channel","level":30,"heroic":"vitalist_l15_r2","talents":{"tier_1":"vitalist_l9_1","tier_2":"vitalist_l12_1","tier_3":"vitalist_l15_r2","tier_4":"vitalist_l18_2","tier_5":"vitalist_l21_1","tier_6":"vitalist_l24_2","tier_7":"vitalist_l27_r2","tier_8":"vitalist_l30_2"}}
]
const CLASS_DEFINITION := {"class_id":"vitalist","display_name":"Vitalist","primary_role":"Healer","role":"Healer","basic_action_id":"vitalist_basic_attack","trait_id":"vitalist_bio_kill_switch","q_ability_id":"vitalist_healing_pathogen","w_ability_id":"vitalist_weighted_pustule","e_ability_id":"vitalist_lurking_arm","heroic_option_ids":["vitalist_l15_r1","vitalist_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["melee","healer","periodic","control"],"color":Color("85c77a"),"ability":"Healing Pathogen","base_health":VALUES.health,"health_growth":0.04,"base_power":VALUES.basic_attack_damage,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":VALUES.basic_attack_interval,"basic_action_range":SPACE.basic_range,"movement_speed":4.8398*SOURCE_TO_WORLD,"combat_radius":SPACE.combat_radius,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":VALUES.health_regeneration,"health_regeneration_growth":0.04,"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"cloth","armor_proficiency":"cloth","weapon_proficiencies":["two_handed"],"uses_mana":false,"resource_id":""}

static func scaled(value:float,level:int)->float:return value*pow(1.04,maxi(0,level-1))
