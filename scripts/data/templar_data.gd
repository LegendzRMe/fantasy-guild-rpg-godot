extends RefCounted

const CombatBalanceData = preload("res://scripts/data/combat_balance_data.gd")

const CLASS_ID := "templar"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5
const IDS := {"basic_attack":"templar_basic_attack","trait":"templar_shield_overload","q":"templar_q","w":"templar_w","e":"templar_e","r1":"templar_r1","r2":"templar_r2"}

const SPACE := {
	"source_to_world":SOURCE_TO_WORLD,"basic_range":1.25*SOURCE_TO_WORLD,"movement_speed":140.0,"combat_radius":42.0,
	"q_distance":6.0*SOURCE_TO_WORLD,"q_width":0.72*SOURCE_TO_WORLD,"q_speed":400.0,
	"w_charge":3.5*SOURCE_TO_WORLD,"w_radius":1.65*SOURCE_TO_WORLD,"e_range":10.0*SOURCE_TO_WORLD,
	"r1_radius":3.0*SOURCE_TO_WORLD,"r2_speed":150.0,"crosscut_rear_arc":2.5*SOURCE_TO_WORLD
}

const VALUES := {
	"health":2490.0,"health_regeneration":5.1875,"basic_attack_damage":111.0,"basic_attack_interval":1.0,
	"trait_threshold":0.75,"trait_shield":365.0,"trait_duration":5.0,"trait_cooldown":24.0,"trait_attack_reduction":4.0,
	"q_outward":57.0,"q_return":171.0,"q_cooldown":10.0,"q_standard_reduction":1.0,"q_priority_reduction":2.0,
	"w_attacks":2,"w_cooldown":4.0,"e_shield":420.0,"e_duration":3.0,"e_cooldown":12.0,
	"r1_damage":114.0,"r1_blind":4.0,"r1_cooldown":70.0,"r1_interuse":10.0,
	"r2_dps":184.0,"r2_duration":8.0,"r2_cooldown":70.0,
	"reactive_parry_charges":2,"reactive_parry_armor":50.0,"amateur_multiplier":2.5,"protector_per_hit":0.001,
	"give_twenty_increment":15.0,"give_twenty_cap":300.0,"give_twenty_goal":20,"give_twenty_cooldown":10.0,
	"shield_battery_cooldown_reduction":4.0,"shield_battery_recharge_bonus":1.25,"shield_surge_bonus":0.80,
	"solarite_bonus":1.75,"together_threshold":0.05,"final_cut_bonus":0.40,"final_cut_low_bonus":0.60,"final_cut_window":6.0,
	"zeal_q_reduction":5.0,"triple_strike_attacks":3,"triple_strike_cooldown_bonus":1.0,"phase_bulwark_armor":50.0,"phase_bulwark_after":2.0,
	"titan_normal":0.005,"titan_w":0.015,"force_of_will_reduction":5.0,"blades_attack_speed":0.20,"blades_slow":0.20,"blades_slow_duration":1.25,
	"target_purified_speed":0.15,"psionic_armor_reduction":25.0,"psionic_duration":2.0,"crosscut_window":4.0
}

const WORKING_NAMES := {
	"templar_trait":"Shield Overload","templar_q":"Blade Dash","templar_w":"Twin Blades","templar_e":"Shield Ally","templar_r1":"Suppression Pulse","templar_r2":"Purifier Beam",
	"templar_l9_1":"Reactive Parry","templar_l9_2":"Amateur Opponent","templar_l9_3":"Protector of Aiur",
	"templar_l12_1":"Give Me Twenty","templar_l12_2":"Shield Battery","templar_l12_3":"Shield Surge",
	"templar_l15_r1":"Suppression Pulse","templar_l15_r2":"Purifier Beam",
	"templar_l18_1":"Solarite Reaper","templar_l18_2":"Together We Are Strong","templar_l18_3":"Final Cut",
	"templar_l21_1":"Templar's Zeal","templar_l21_2":"Triple Strike","templar_l21_3":"Phase Bulwark",
	"templar_l24_1":"Titan Killer","templar_l24_2":"Force of Will","templar_l24_3":"Blades of a Templar",
	"templar_l27_r1":"Orbital Bombardment","templar_l27_r2":"Target Purified",
	"templar_l30_1":"Psionic Wound","templar_l30_2":"Shield Network","templar_l30_3":"Crosscut"
}

const TALENT_DESCRIPTIONS := {
	"templar_l9_1":"Twin Blades strikes and unique Blade Dash contacts grant Block charges, up to 2.","templar_l9_2":"Twin Blades deals 150% bonus damage when exactly one enemy is in its combat radius when cast.","templar_l9_3":"Quest-valid Basic Attacks permanently increase Basic Attack damage by 0.1% for this encounter.",
	"templar_l12_1":"When Shield Ally is fully depleted by hostile damage, future Shield Ally casts gain 15 Shield, up to 300. After 20 depletions its cooldown becomes 10 seconds.","templar_l12_2":"Shield Overload's cooldown is reduced by 4 seconds and recharges 125% faster while its Shield remains.","templar_l12_3":"Shield Overload grants 80% more Shield while below 25% Health.",
	"templar_l15_r1":"Damage and Blind enemies in a global target area for 4 seconds.","templar_l15_r2":"Call a beam that follows one enemy, dealing damage each second for 8 seconds.",
	"templar_l18_1":"Blade Dash's outward hit deals 175% more damage.","templar_l18_2":"Damage dealt by Shield Ally bearers during its 3-second link reduces Shield Overload's cooldown by 1 second per 5% of snapshotted maximum Health.","templar_l18_3":"After using an Ability, the next Basic Attack within 6 seconds deals 40% more damage, or 60% below 25% Health.",
	"templar_l21_1":"Shield Overload activation reduces Blade Dash's cooldown by 5 seconds.","templar_l21_2":"Twin Blades strikes 3 times and its cooldown is increased by 1 second.","templar_l21_3":"Gain 50 Armor while Shield Overload remains and for 2 seconds afterward.",
	"templar_l24_1":"Basic Attacks deal bonus damage equal to 0.5% of the Templar's Health basis; Twin Blades strikes deal 1.5%.","templar_l24_2":"Successful Blade Dash, Twin Blades, and Shield Ally casts reduce Shield Overload's cooldown by 5 seconds.","templar_l24_3":"Gain 20% Basic Attack speed; successful Basic Attacks Slow by 20% for 1.25 seconds.",
	"templar_l27_r1":"Suppression Pulse gains a second charge with a 10-second inter-use restriction.","templar_l27_r2":"Purifier Beam moves 15% faster and retargets when its target is defeated.",
	"templar_l30_1":"The final Twin Blades strike reduces Armor by 25 for 2 seconds.","templar_l30_2":"Shield Ally affects the two closest valid allies.","templar_l30_3":"Completing Blade Dash arms Crosscut for 4 seconds; the next Twin Blades strike also hits the closest distinct enemy behind its target."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["templar_l9_1","templar_l9_2","templar_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["templar_l12_1","templar_l12_2","templar_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["templar_l15_r1","templar_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["templar_l18_1","templar_l18_2","templar_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["templar_l21_1","templar_l21_2","templar_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["templar_l24_1","templar_l24_2","templar_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["templar_l27_r1","templar_l27_r2"],"heroic_requirements":{"templar_l27_r1":"templar_l15_r1","templar_l27_r2":"templar_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["templar_l30_1","templar_l30_2","templar_l30_3"]}
]

const TEST_BUILDS := [
	{"name":"Level 1 Baseline","level":1,"heroic":"","talents":{}},
	{"name":"Suppression Bruiser","level":30,"heroic":"templar_l15_r1","talents":{"tier_1":"templar_l9_3","tier_2":"templar_l12_2","tier_3":"templar_l15_r1","tier_4":"templar_l18_1","tier_5":"templar_l21_2","tier_6":"templar_l24_3","tier_7":"templar_l27_r1","tier_8":"templar_l30_1"}},
	{"name":"Shield Network","level":30,"heroic":"templar_l15_r2","talents":{"tier_1":"templar_l9_1","tier_2":"templar_l12_1","tier_3":"templar_l15_r2","tier_4":"templar_l18_2","tier_5":"templar_l21_3","tier_6":"templar_l24_2","tier_7":"templar_l27_r2","tier_8":"templar_l30_2"}},
	{"name":"Crosscut Titan","level":30,"heroic":"templar_l15_r1","talents":{"tier_1":"templar_l9_2","tier_2":"templar_l12_3","tier_3":"templar_l15_r1","tier_4":"templar_l18_3","tier_5":"templar_l21_2","tier_6":"templar_l24_1","tier_7":"templar_l27_r1","tier_8":"templar_l30_3"}}
]

const CLASS_DEFINITION := {"class_id":"templar","display_name":"Templar","primary_role":"Tank","role":"Tank","basic_action_id":"templar_basic_attack","trait_id":"templar_shield_overload","q_ability_id":"templar_q","w_ability_id":"templar_w","e_ability_id":"templar_e","heroic_option_ids":["templar_l15_r1","templar_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["melee","tank","shield_support"],"color":Color("e3b33e"),"ability":"Blade Dash","base_health":2490.0,"health_growth":0.04,"base_power":111.0,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.0,"basic_action_range":1.25*SOURCE_TO_WORLD,"movement_speed":140.0,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":5.1875,"health_regeneration_growth":0.04,"threat_modifier":CombatBalanceData.TANK_THREAT_MODIFIER,"basic_action_damage_type":"physical","armor_family":"plate","armor_proficiency":"plate","weapon_proficiencies":["one_handed","two_handed"],"uses_mana":false,"resource_id":""}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)
