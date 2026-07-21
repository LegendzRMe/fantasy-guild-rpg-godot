extends RefCounted

const TalentData = preload("res://scripts/data/talent_data.gd")

const CLASS_DEFINITION := {
	"class_id":"cleric", "display_name":"Cleric", "primary_role":"Healer", "role":"Healer",
	"basic_action_id":"cleric_basic_action", "trait_id":"cleric_trait",
	"q_ability_id":"cleric_q", "w_ability_id":"cleric_w", "e_ability_id":"cleric_e",
	"heroic_ability_ids":["cleric_r1", "cleric_r2"], "heroic_option_ids":["cleric_l15_r1", "cleric_l15_r2"],
	"ai_behavior_tags":["healer", "ranged", "support"], "color":Color("ffd86a"),
	"ability":"Healing Brew", "base_health":1500.0, "health_growth":0.04,
	"base_power":60.0, "power_growth":0.04, "base_armor":0.0,
	"basic_action_type":"heal", "basic_action_power_coefficient":1.0,
	"basic_action_interval":0.8, "basic_action_range":220.0,
	"movement_speed":150.0, "base_critical_chance":0.05, "critical_damage":2.0,
	"health_regeneration":3.125, "threat_modifier":1.0,
	"basic_action_damage_type":"physical", "armor_family":"mail", "armor_proficiency":"mail",
	"weapon_proficiencies":["one_handed", "focus", "staff", "wand"],
	"talent_tier_definitions":[
		{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["cleric_l9_1","cleric_l9_2","cleric_l9_3"]},
		{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["cleric_l12_1","cleric_l12_2","cleric_l12_3"]},
		{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["cleric_l15_r1","cleric_l15_r2"]},
		{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["cleric_l18_1","cleric_l18_2","cleric_l18_3"]},
		{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["cleric_l21_1","cleric_l21_2","cleric_l21_3"]},
		{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["cleric_l24_1","cleric_l24_2","cleric_l24_3"]},
		{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["cleric_l27_r1","cleric_l27_r2"],"heroic_requirements":{"cleric_l27_r1":"cleric_l15_r1","cleric_l27_r2":"cleric_l15_r2"}},
		{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["cleric_l30_1","cleric_l30_2","cleric_l30_3"]}
	]
}

const ACTION_NAMES := {"Q":"Healing Brew","W":"Cloud Serpent","E":"Blinding Wind","R1":"Jug of Healing","R2":"Water Dragon","D":"Fast Feet"}
const ACTION_KEYS := ["D","Q","W","E","R"]
const WORKING_NAMES := {
	"cleric_r1":"Jug of Healing", "cleric_r2":"Water Dragon", "cleric_l15_r1":"Jug of Healing", "cleric_l15_r2":"Water Dragon",
	"cleric_l9_1":"Free Drinks", "cleric_l9_2":"Serpent Sidekick", "cleric_l9_3":"Eager Adventurer",
	"cleric_l12_1":"Surging Winds", "cleric_l12_2":"Safety Sprint", "cleric_l12_3":"Let's Go!",
	"cleric_l18_1":"Good Stuff", "cleric_l18_2":"Wind Serpent", "cleric_l18_3":"Mass Vortex",
	"cleric_l21_1":"Lightning Serpent", "cleric_l21_2":"Gale Force", "cleric_l21_3":"Hindering Winds",
	"cleric_l24_1":"Two For One", "cleric_l24_2":"Pick Me Up", "cleric_l24_3":"Blessings of Yu'lon",
	"cleric_l27_r1":"Jug Upgrade", "cleric_l27_r2":"Double Dragon",
	"cleric_l30_1":"Mistweaver", "cleric_l30_2":"Shake It Off", "cleric_l30_3":"Kung Fu Hustle"
}

const VALUES := {
	"q_cooldown":4.0, "q_heal":210.0, "w_cooldown":11.0, "w_duration":8.0,
	"w_attack":26.0, "w_heal":20.0, "e_cooldown":12.0, "e_damage":133.0,
	"e_slow":0.15, "e_slow_duration":1.5, "e_blind_duration":1.5,
	"r1_base_cooldown":20.0, "r1_duration":6.0, "r1_tick":0.25, "r1_heal":75.0,
	"r2_cooldown":50.0, "r2_precast":2.0, "r2_damage":300.0, "r2_slow":0.70, "r2_slow_duration":4.0,
	"fast_feet_duration":1.0, "fast_feet_move":0.10, "fast_feet_qwe_rate":1.5
}

const TALENT_DESCRIPTIONS := {
	"cleric_r1":"Channel for up to 6 seconds, repeatedly healing the lowest-Health nearby ally. Each completed tick increases the resulting cooldown.",
	"cleric_r2":"After a 2-second precast, strike and heavily Slow the nearest enemy and nearby enemies.",
	"cleric_l15_r1":"Channel for up to 6 seconds, repeatedly healing the lowest-Health nearby ally. Each completed tick increases the resulting cooldown.",
	"cleric_l15_r2":"After a 2-second precast, strike and heavily Slow the nearest enemy and nearby enemies.",
	"cleric_l9_1":"Healing Brew on an ally below 50% Health reduces its remaining cooldown by 1 second.",
	"cleric_l9_2":"Fast Feet increases Cloud Serpent's cooldown rate by an additional 75%.",
	"cleric_l9_3":"Fast Feet lasts 2.5 seconds.",
	"cleric_l12_1":"Blinding Wind hitting at least 2 enemies reduces its cooldown by 2 seconds and grants 10% Spell Power for 10 seconds.",
	"cleric_l12_2":"Fast Feet grants 10 Armor. Activate D for 30% total Move Speed and 30 Armor for 3 seconds. 30 second cooldown.",
	"cleric_l12_3":"Activate D on another ally to heal 160, remove removable control, and grant Unstoppable for 1 second. 40 second cooldown.",
	"cleric_l18_1":"Healing Brew also heals over 3 seconds. The amount doubles when Fast Feet is active at application.",
	"cleric_l18_2":"Cloud Serpent grants Move Speed and attacks faster; Blinding Wind empowers the movement bonus for 3 seconds.",
	"cleric_l18_3":"Blinding Wind targets 3 enemies. Hitting 3 distinct enemies increases all of its damage by 75%.",
	"cleric_l21_1":"Cloud Serpent attacks bounce to 2 nearby enemies and heal its host for each bounce.",
	"cleric_l21_2":"Blind lasts 0.75 seconds longer; Basic Attacks deal 100% more damage to Blinded targets.",
	"cleric_l21_3":"Blinding Wind Slows by 30% for 2 seconds.",
	"cleric_l24_1":"Healing Brew heals the 2 lowest-Health allies and has a 5 second base cooldown.",
	"cleric_l24_2":"Healing Brew heals allies below 50% Health for 33% more.",
	"cleric_l24_3":"Cloud Serpent's host receives 10% more healing and heals for 0.5% maximum Health after each base Serpent attack.",
	"cleric_l27_r1":"Each Jug tick heals the 2 lowest-Health distinct allies.",
	"cleric_l27_r2":"Water Dragon summons a second dragon 0.5 seconds after the first impact.",
	"cleric_l30_1":"Ready Healing Brews also pulse nearby allies for 149. Offensive Basic Attacks and Serpent sequences reduce its 30 second readiness.",
	"cleric_l30_2":"Cloud Serpent gains 2 independently recharging charges and two active Serpents can grant 35 Armor when their host is controlled.",
	"cleric_l30_3":"Fast Feet makes Q, W, and E cooldowns recover at 3x speed."
}
