extends RefCounted

const CLASS_ID := "warrior"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5

const SPACE := {
	"source_to_world":SOURCE_TO_WORLD,"basic_range":1.25*SOURCE_TO_WORLD,
	"lions_fang_range":12.0*SOURCE_TO_WORLD,"lions_fang_width":1.25*SOURCE_TO_WORLD,"lions_fang_speed":18.0*SOURCE_TO_WORLD,
	"charge_range":4.0*SOURCE_TO_WORLD,"colossus_range":5.0*SOURCE_TO_WORLD,"master_radius":2.0*SOURCE_TO_WORLD,
	"taunt_range":2.0*SOURCE_TO_WORLD,"banner_radius":10.5*SOURCE_TO_WORLD,"shattering_range":8.0*SOURCE_TO_WORLD,
	"victory_radius":12.0*SOURCE_TO_WORLD,"movement_speed":150.0,"combat_radius":42.0
}

const VALUES := {
	"health":2220.0,"health_regeneration":4.625,"basic_attack_damage":74.0,"basic_attack_interval":0.8,
	"heroic_strike_cooldown":18.0,"heroic_strike_damage":125.0,"heroic_strike_cdr":3.0,"twin_cdr":7.0,
	"q_damage":150.0,"q_cooldown":8.0,"q_slow":0.35,"q_slow_duration":1.5,"q_heal":35.0,"q_boss_heal":140.0,
	"w_duration":1.25,"w_recharge":10.0,"w_charges":2,"e_damage":50.0,"e_cooldown":12.0,"e_slow":0.75,"e_slow_duration":1.0,
	"lions_maw_per":7.0,"lions_maw_goal":25,"lions_maw_cap":175.0,"lions_maw_slow":0.50,"lions_maw_duration":2.0,
	"overpower_bonus":0.40,"high_weapon_goal":50,"high_honors_goal":5,"high_endurance_goal":15,"high_objective_reward":10.0,"high_final_reward":30.0,
	"taunt_cooldown":16.0,"taunt_duration":1.25,"taunt_armor_effectiveness":0.10,"taunt_healing_received":0.10,
	"colossus_damage":185.0,"colossus_cooldown":20.0,"colossus_armor":25.0,"colossus_duration":3.0,"colossus_health":0.90,"colossus_basic":2.0,
	"twin_speed":1.0,"twin_basic":0.75,"twin_move":0.30,"twin_move_duration":2.0,
	"lionheart_boss":1.75,"second_wind":0.01,"victory_heal":350.0,"victory_cooldown":30.0,"victory_death_cdr":10.0,
	"shield_wall_recharge":5.0,"shield_wall_charges":1,"warbringer_cooldown":4.0,
	"summon_percent":0.04,"summon_lifetime":0.04,"mortal_reduction":0.40,"mortal_duration":4.0,
	"shattering_cooldown":30.0,"shattering_damage":50.0,"shattering_shield_damage":1400.0,"shattering_basic_shield_bonus":2.0,
	"banner_cooldown":25.0,"banner_duration":12.0,"banner_shared_window":8.0,"stormwind_speed":0.25,"ironforge_armor":20.0,"dalaran_power":0.10,
	"vigilance_cdr":1.0,"master_cooldown":10.0,"frenzy_damage":0.25,"frenzy_move":0.40,
	"glory_regen":0.50,"glory_healing":0.50,"demoralizing_reduction":0.40,"demoralizing_duration":5.0
}

const WORKING_NAMES := {
	"warrior_l9_1":"Lion's Maw","warrior_l9_2":"Overpower","warrior_l9_3":"High King's Quest",
	"warrior_l12_r1":"Taunt","warrior_l12_r2":"Colossus Smash","warrior_l12_r3":"Twin Blades of Fury",
	"warrior_l15_1":"Lionheart","warrior_l15_2":"Second Wind","warrior_l15_3":"Victory Rush",
	"warrior_l18_1":"Shield Wall","warrior_l18_2":"Warbringer",
	"warrior_l21_1":"Juggernaut","warrior_l21_2":"Mortal Strike","warrior_l21_3":"Shattering Throw",
	"warrior_l24_1":"Banner of Stormwind","warrior_l24_2":"Banner of Ironforge","warrior_l24_3":"Banner of Dalaran",
	"warrior_l27_r1":"Vigilance","warrior_l27_r2":"Master at Arms","warrior_l27_r3":"Frenzy",
	"warrior_l30_1":"Glory to the Alliance","warrior_l30_2":"Demoralizing Shout","warrior_l30_3":"Shared Legacy"
}

const TALENT_DESCRIPTIONS := {
	"warrior_l9_1":"Lion's Fang gains 7 level-one damage per qualifying contact, to 25; completion improves its Slow.",
	"warrior_l9_2":"Parried Basic Attack contacts refresh and empower the next Heroic Strike by 40%.",
	"warrior_l9_3":"Complete Weapon Mastery, Battle Honors, and Endurance for up to 60 level-one Basic Attack damage.",
	"warrior_l12_r1":"Become a Tank: 1.5 Threat, +10% healing received and +10% positive Armor effectiveness; R Taunts.",
	"warrior_l12_r2":"Double Basic Attack damage, lose 10% maximum Health; R smashes for 185 and scaled -25 Armor.",
	"warrior_l12_r3":"Passive R: double Attack Speed, -25% Basic Attack damage, 7-second Heroic Strike CDR and movement.",
	"warrior_l15_1":"Lion's Fang heals 245 against Bosses and can heal from Summon contacts.",
	"warrior_l15_2":"Successful Heroic Strikes heal 1% maximum Health; never progresses Endurance.",
	"warrior_l15_3":"Every 30 seconds the next primary Basic Attack heals 350; nearby deaths reduce the cooldown.",
	"warrior_l18_1":"Parry becomes Protected, has one charge and a 5-second recharge.",
	"warrior_l18_2":"Charge has a 4-second cooldown and may safely target allied Heroes.",
	"warrior_l21_1":"Lion's Fang and Charge deal 4% Summon maximum Health and remove 4% original lifetime.",
	"warrior_l21_2":"Heroic Strike reduces target healing received by 40% for 4 seconds.",
	"warrior_l21_3":"D becomes Shattering Throw; Basic Attacks and the active deal shield-only bonus damage.",
	"warrior_l24_1":"Automatic 12-second rally every 25 seconds: +25% Movement Speed.",
	"warrior_l24_2":"Automatic 12-second rally every 25 seconds: 20 scaled Armor.",
	"warrior_l24_3":"Automatic 12-second rally every 25 seconds: +10% Ability Power.",
	"warrior_l27_r1":"Taunt upgrade: hostile Basic Attack contacts reduce Taunt by 1 second.",
	"warrior_l27_r2":"Colossus upgrade: 10-second cooldown and affects enemies within a 2-unit radius.",
	"warrior_l27_r3":"Twin Blades upgrade: +25% Heroic Strike damage and movement increases to 40%.",
	"warrior_l30_1":"Banner aura grants +50% regeneration and healing received.",
	"warrior_l30_2":"Banner activation snapshots nearby enemies for 40% reduced outgoing damage for 5 seconds.",
	"warrior_l30_3":"For the first 8 seconds, Banner allies receive double numeric combat-talent quest progress."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["warrior_l9_1","warrior_l9_2","warrior_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"heroic","option_ids":["warrior_l12_r1","warrior_l12_r2","warrior_l12_r3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"talent","option_ids":["warrior_l15_1","warrior_l15_2","warrior_l15_3"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["warrior_l18_1","warrior_l18_2"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["warrior_l21_1","warrior_l21_2","warrior_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["warrior_l24_1","warrior_l24_2","warrior_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["warrior_l27_r1","warrior_l27_r2","warrior_l27_r3"],"heroic_requirements":{"warrior_l27_r1":"warrior_l12_r1","warrior_l27_r2":"warrior_l12_r2","warrior_l27_r3":"warrior_l12_r3"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["warrior_l30_1","warrior_l30_2","warrior_l30_3"]}
]

const TEST_BUILDS := [
	{"name":"Level 1 Baseline","level":1,"heroic":"","talents":{}},
	{"name":"Taunt Tank","level":30,"heroic":"warrior_l12_r1","talents":{"tier_1":"warrior_l9_3","tier_2":"warrior_l12_r1","tier_3":"warrior_l15_3","tier_4":"warrior_l18_1","tier_5":"warrior_l21_2","tier_6":"warrior_l24_2","tier_7":"warrior_l27_r1","tier_8":"warrior_l30_1"}},
	{"name":"Colossus Burst","level":30,"heroic":"warrior_l12_r2","talents":{"tier_1":"warrior_l9_3","tier_2":"warrior_l12_r2","tier_3":"warrior_l15_3","tier_4":"warrior_l18_2","tier_5":"warrior_l21_2","tier_6":"warrior_l24_3","tier_7":"warrior_l27_r2","tier_8":"warrior_l30_3"}},
	{"name":"Twin Blades DPS","level":30,"heroic":"warrior_l12_r3","talents":{"tier_1":"warrior_l9_3","tier_2":"warrior_l12_r3","tier_3":"warrior_l15_2","tier_4":"warrior_l18_2","tier_5":"warrior_l21_3","tier_6":"warrior_l24_1","tier_7":"warrior_l27_r3","tier_8":"warrior_l30_3"}},
	{"name":"Anti-Summon Counter","level":30,"heroic":"warrior_l12_r2","talents":{"tier_1":"warrior_l9_1","tier_2":"warrior_l12_r2","tier_3":"warrior_l15_1","tier_4":"warrior_l18_2","tier_5":"warrior_l21_1","tier_6":"warrior_l24_3","tier_7":"warrior_l27_r2","tier_8":"warrior_l30_2"}},
	{"name":"Completed High King","level":30,"heroic":"warrior_l12_r3","talents":{"tier_1":"warrior_l9_3","tier_2":"warrior_l12_r3","tier_3":"warrior_l15_3","tier_4":"warrior_l18_2","tier_5":"warrior_l21_3","tier_6":"warrior_l24_1","tier_7":"warrior_l27_r3","tier_8":"warrior_l30_3"},"complete_high_king":true}
]

const CLASS_DEFINITION := {
	"class_id":"warrior","display_name":"Warrior","primary_role":"Melee DPS","role":"Melee DPS",
	"basic_action_id":"warrior_basic_attack","trait_id":"warrior_heroic_strike","q_ability_id":"warrior_lions_fang","w_ability_id":"warrior_parry","e_ability_id":"warrior_charge",
	"heroic_option_ids":["warrior_l12_r1","warrior_l12_r2","warrior_l12_r3"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["melee","basic_attack","flexible"],"color":Color("c98a45"),"ability":"Lion's Fang",
	"base_health":VALUES.health,"health_growth":0.04,"base_power":VALUES.basic_attack_damage,"power_growth":0.04,"base_armor":0.0,
	"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":VALUES.basic_attack_interval,"basic_action_range":SPACE.basic_range,
	"movement_speed":SPACE.movement_speed,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":VALUES.health_regeneration,"health_regeneration_growth":0.04,
	"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"plate","armor_proficiency":"plate","weapon_proficiencies":["one_handed","two_handed","dual_wield","weapon_and_shield"],"uses_mana":false,"resource_id":""
}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)
