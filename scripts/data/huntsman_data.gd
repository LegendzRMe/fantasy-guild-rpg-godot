extends RefCounted

const CombatBalanceData = preload("res://scripts/data/combat_balance_data.gd")

const CLASS_ID := "huntsman"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5

const IDS := {
	"basic_attack": "huntsman_basic_attack",
	"trait": "huntsman_curse",
	"human_q": "huntsman_cocktail",
	"worgen_q": "huntsman_swipe",
	"w": "huntsman_inner_beast",
	"human_e": "huntsman_darkflight",
	"worgen_e": "huntsman_disengage",
	"r1": "huntsman_go_for_the_throat",
	"r2": "huntsman_marked_for_the_kill"
}

const SPACE := {
	"source_to_world": SOURCE_TO_WORLD,
	"human_basic_range": 5.5 * SOURCE_TO_WORLD,
	"worgen_basic_range": 1.25 * SOURCE_TO_WORLD,
	"movement_speed": 150.0,
	"combat_radius": 34.0,
	"cocktail_range": 8.0 * SOURCE_TO_WORLD,
	"cocktail_speed": 18.0 * SOURCE_TO_WORLD,
	"cocktail_width": 0.45 * SOURCE_TO_WORLD,
	"cocktail_cone_range": 4.5 * SOURCE_TO_WORLD,
	"cocktail_cone_half_angle": deg_to_rad(34.0),
	"swipe_distance": 2.0 * SOURCE_TO_WORLD,
	"swipe_radius": 1.75 * SOURCE_TO_WORLD,
	"darkflight_range": 6.5 * SOURCE_TO_WORLD,
	"disengage_range": 6.5 * SOURCE_TO_WORLD,
	"heroic_range": 7.5 * SOURCE_TO_WORLD,
	"marked_range": 11.0 * SOURCE_TO_WORLD,
	"marked_speed": 22.0 * SOURCE_TO_WORLD,
	"marked_width": 0.55 * SOURCE_TO_WORLD,
	"splash_radius": 2.25 * SOURCE_TO_WORLD,
	"cleave_radius": 2.0 * SOURCE_TO_WORLD
}

const VALUES := {
	"health": 1876.0,
	"health_regeneration": 3.9062,
	"basic_attack_damage": 148.0,
	"basic_attack_interval": 1.0,
	"worgen_basic_bonus": 0.40,
	"worgen_armor": 10.0,
	"thick_skin_armor": 50.0,
	"cocktail_impact": 55.0,
	"cocktail_explosion": 220.0,
	"cocktail_cooldown": 9.0,
	"swipe_damage": 126.0,
	"swipe_cooldown": 4.0,
	"inner_beast_cooldown": 20.0,
	"inner_beast_duration": 3.0,
	"inner_beast_attack_speed": 0.50,
	"inner_beast_basic_cdr": 0.5,
	"darkflight_damage": 88.0,
	"e_cooldown": 5.0,
	"r1_damage": 355.0,
	"r1_cooldown": 80.0,
	"r1_repeat_window": 10.0,
	"r2_damage": 190.0,
	"r2_cooldown": 60.0,
	"mark_duration": 5.0,
	"mark_stack_reduction": 15.0,
	"mark_stack_cap": 5,
	"roulette_duration": 3.0,
	"wizened_bonus": 0.30,
	"wizened_attacks": 3,
	"wizened_duration": 5.0
}

const WORKING_NAMES := {
	"huntsman_trait": "Curse of the Worgen",
	"huntsman_human_q": "Gilnean Cocktail",
	"huntsman_worgen_q": "Razor Swipe",
	"huntsman_w": "Inner Beast",
	"huntsman_human_e": "Darkflight",
	"huntsman_worgen_e": "Disengage",
	"huntsman_l9_1": "Wolfheart", "huntsman_l9_2": "Perfect Aim", "huntsman_l9_3": "Viciousness",
	"huntsman_l12_1": "Thick Skin", "huntsman_l12_2": "Eyes in the Dark", "huntsman_l12_3": "Insatiable",
	"huntsman_l15_r1": "Go for the Throat", "huntsman_l15_r2": "Marked for the Kill",
	"huntsman_l18_1": "Quicksilver Bullets", "huntsman_l18_2": "Incendiary Elixir", "huntsman_l18_3": "Pounce",
	"huntsman_l21_1": "Running Wild", "huntsman_l21_2": "Unfettered Assault", "huntsman_l21_3": "On the Prowl",
	"huntsman_l24_1": "Eager Wolf", "huntsman_l24_2": "Lord of His Pack", "huntsman_l24_3": "Alpha Killer",
	"huntsman_l27_r1": "Unleashed", "huntsman_l27_r2": "Gilnean Roulette",
	"huntsman_l30_1": "Blunderbuss", "huntsman_l30_2": "Tooth and Claw", "huntsman_l30_3": "Wizened Duelist"
}

const TALENT_DESCRIPTIONS := {
	"huntsman_l9_1": "Worgen Armor becomes 15 and successful Basic Attacks reduce Inner Beast's cooldown by 1.2 seconds total.",
	"huntsman_l9_2": "Gilnean Cocktail's range is increased by 30%.",
	"huntsman_l9_3": "Inner Beast lasts 4 seconds and successful ability damage refreshes it.",
	"huntsman_l12_1": "Darkflight grants two shared Block charges against hostile Basic Attacks.",
	"huntsman_l12_2": "Disengage grants Stealth for 3 seconds.",
	"huntsman_l12_3": "While Inner Beast is active, primary Basic Attacks heal for 0.5% maximum Health.",
	"huntsman_l15_r1": "Leap to an enemy as Worgen and deal heavy Physical damage. A kill grants one free repeat for 10 seconds.",
	"huntsman_l15_r2": "Fire a long projectile, Reveal and mark the first enemy hit. Qualifying actions deepen its Armor reduction.",
	"huntsman_l18_1": "Human Basic Attack range is increased by 1.1 source units.",
	"huntsman_l18_2": "Cocktail explosions gain encounter-scoped damage stacks. The quest reduces Cocktail's cooldown by 2 seconds, then 3 more when complete.",
	"huntsman_l18_3": "Darkflight deals no direct damage and triggers a free real Razor Swipe on landing.",
	"huntsman_l21_1": "Darkflight and Disengage range increase by 35% and their shared cooldown is reduced by 1 second.",
	"huntsman_l21_2": "Razor Swipe lunges 60% farther and Worgen Basic Attacks reduce its cooldown by 1.5 seconds.",
	"huntsman_l21_3": "After Inner Beast has remained active for 3 seconds, gain 30% Movement Speed.",
	"huntsman_l24_1": "After Inner Beast has remained active for 4 seconds, gain another 40% Attack Speed.",
	"huntsman_l24_2": "Attacking an enemy that is actually Slowed, Rooted, or Stunned grants Basic Attack damage for 3 seconds: 25% Human or 50% Worgen.",
	"huntsman_l24_3": "Worgen primary Basic Attacks deal 3% maximum-Health damage, reduced to 0.75% against Bosses.",
	"huntsman_l27_r1": "Go for the Throat deals 25% more damage and a kill resets its applicable ability cooldowns.",
	"huntsman_l27_r2": "Marked for the Kill has no stack cap, but its mark lasts 3 seconds and qualifying actions refresh it.",
	"huntsman_l30_1": "Human primary Basic Attacks splash for 100% damage behind the target.",
	"huntsman_l30_2": "Worgen primary Basic Attacks cleave for 100% damage and Razor Swipe deals 100% more damage.",
	"huntsman_l30_3": "Changing form empowers the next three primary Basic Attacks in the new form by 30% for up to 5 seconds."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["huntsman_l9_1","huntsman_l9_2","huntsman_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["huntsman_l12_1","huntsman_l12_2","huntsman_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["huntsman_l15_r1","huntsman_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["huntsman_l18_1","huntsman_l18_2","huntsman_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["huntsman_l21_1","huntsman_l21_2","huntsman_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["huntsman_l24_1","huntsman_l24_2","huntsman_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["huntsman_l27_r1","huntsman_l27_r2"],"heroic_requirements":{"huntsman_l27_r1":"huntsman_l15_r1","huntsman_l27_r2":"huntsman_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["huntsman_l30_1","huntsman_l30_2","huntsman_l30_3"]}
]

const TEST_BUILDS := [
	{"name":"Level 1 Human","level":1,"heroic":"","talents":{}},
	{"name":"Human Cocktail","level":30,"heroic":"huntsman_l15_r2","talents":{"tier_1":"huntsman_l9_2","tier_2":"huntsman_l12_2","tier_3":"huntsman_l15_r2","tier_4":"huntsman_l18_2","tier_5":"huntsman_l21_1","tier_6":"huntsman_l24_2","tier_7":"huntsman_l27_r2","tier_8":"huntsman_l30_1"}},
	{"name":"Worgen Brawler","level":30,"heroic":"huntsman_l15_r1","talents":{"tier_1":"huntsman_l9_1","tier_2":"huntsman_l12_3","tier_3":"huntsman_l15_r1","tier_4":"huntsman_l18_3","tier_5":"huntsman_l21_2","tier_6":"huntsman_l24_3","tier_7":"huntsman_l27_r1","tier_8":"huntsman_l30_2"}},
	{"name":"Wizened Forms","level":30,"heroic":"huntsman_l15_r2","talents":{"tier_1":"huntsman_l9_3","tier_2":"huntsman_l12_1","tier_3":"huntsman_l15_r2","tier_4":"huntsman_l18_1","tier_5":"huntsman_l21_3","tier_6":"huntsman_l24_1","tier_7":"huntsman_l27_r2","tier_8":"huntsman_l30_3"}},
	{"name":"Completed Cocktail Quest","level":30,"heroic":"huntsman_l15_r2","talents":{"tier_1":"huntsman_l9_2","tier_2":"huntsman_l12_2","tier_3":"huntsman_l15_r2","tier_4":"huntsman_l18_2","tier_5":"huntsman_l21_1","tier_6":"huntsman_l24_2","tier_7":"huntsman_l27_r2","tier_8":"huntsman_l30_1"},"quest_stacks":15}
]

const CLASS_DEFINITION := {
	"class_id":"huntsman", "display_name":"Huntsman", "primary_role":"Damage", "role":"Melee DPS",
	"basic_action_id":"huntsman_basic_attack", "trait_id":"huntsman_curse", "q_ability_id":"huntsman_cocktail",
	"w_ability_id":"huntsman_inner_beast", "e_ability_id":"huntsman_darkflight",
	"heroic_option_ids":["huntsman_l15_r1","huntsman_l15_r2"], "talent_tier_definitions":TALENT_TIERS,
	"ai_behavior_tags":["damage","hybrid_range","form_swap"], "color":Color("d9a96c"), "ability":"Gilnean Cocktail",
	"base_health":VALUES.health, "health_growth":0.04, "base_power":VALUES.basic_attack_damage, "power_growth":0.04,
	"base_armor":0.0, "basic_action_type":"attack", "basic_action_power_coefficient":1.0,
	"basic_action_interval":VALUES.basic_attack_interval, "basic_action_range":SPACE.human_basic_range,
	"movement_speed":SPACE.movement_speed, "base_critical_chance":0.05, "critical_damage":2.0,
	"health_regeneration":VALUES.health_regeneration, "health_regeneration_growth":0.04, "threat_modifier":1.0,
	"basic_action_damage_type":"physical", "armor_family":"leather", "armor_proficiency":"leather",
	"weapon_proficiencies":["firearm","one-handed"], "uses_mana":false, "resource_id":""
}

static func scale(level:int) -> float:
	return pow(SCALE_PER_LEVEL, maxi(0, level - 1))

static func scaled(value:float, level:int) -> float:
	return value * scale(level)
