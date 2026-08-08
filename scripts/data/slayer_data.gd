extends RefCounted

const CLASS_ID := "slayer"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5
const IDS := {"basic_attack":"slayer_basic_attack","trait":"slayer_trait","q":"slayer_q","w":"slayer_w","e":"slayer_e","r1":"slayer_r1","r2":"slayer_r2"}

# Public sources do not expose exact collision geometry. These values use the
# project's established 5.5 source-range = 185 world-unit calibration and are
# intentionally centralized for Range testing.
const SPACE := {
	"source_to_world":SOURCE_TO_WORLD,"basic_range":1.2*SOURCE_TO_WORLD,"movement_speed":150.0,
	"dive_range":4.5*SOURCE_TO_WORLD,"dive_landing_offset":52.0,"dive_search_radius":84.0,
	"sweep_range":3.25*SOURCE_TO_WORLD,"sweep_width":1.25*SOURCE_TO_WORLD,"sweep_speed":760.0,
	"metamorphosis_range":4.0*SOURCE_TO_WORLD,"metamorphosis_radius":2.5*SOURCE_TO_WORLD,
	"hunt_speed":1050.0,"hunt_landing_offset":48.0
}

const VALUES := {
	"health":1725.0,"health_regeneration":3.59375,"basic_attack_damage":78.0,"basic_attacks_per_second":1.82,
	"trait_healing":0.30,"trait_cooldown_reduction":1.0,
	"q_damage":66.0,"q_cooldown":6.0,"q_travel_duration":0.18,
	"w_damage":119.0,"w_cooldown":8.0,"w_attack_bonus":0.35,"w_buff_duration":3.0,
	"e_duration":2.5,"e_cooldown":15.0,
	"r1_damage":46.0,"r1_health_per_target":220.0,"r1_target_cap":5,"r1_duration":18.0,"r1_cooldown":120.0,
	"r2_damage":251.0,"r2_stun":1.0,"r2_cooldown":100.0,
	"immolation_dps":22.0,"immolation_duration":4.0,"immolation_tick":1.0,
	"battered_bonus":1.25,"battered_duration":5.0,
	"unending_hatred_per_defeat":1.0,"unending_hatred_milestone":20,"unending_hatred_reward":20.0,
	"rapid_chase_speed":0.20,"rapid_chase_duration":3.0,"friend_or_foe_range":0.20,"unbound_goal":15,
	"reflexive_block_grant":3,"reflexive_block_max":4,"block_armor":75.0,
	"thirsting_blade_healing":0.50,"hunters_onslaught_nonhero":0.25,"hunters_onslaught_hero":0.50,
	"nimble_armor":25.0,"nimble_duration":2.0,"elusive_reduction":3.0,"shadow_shield_fraction":0.10,"shadow_shield_duration":5.0,
	"marked_damage":180.0,"marked_duration":10.0,"fiery_brand_fraction":0.07,"fiery_brand_boss_fraction":0.0175,"fiery_brand_goal":3,"fiery_brand_lifetime":300.0,
	"blades_goal":5,"blades_bonus":0.75,"blades_duration":8.0,
	"demonic_attack_speed":0.20,"demonic_stun_root_duration_multiplier":0.50,"nowhere_threshold":0.25,"nowhere_bonus":1.0,
	"nexus_bonus":0.20,"nexus_slow":0.20,"nexus_duration":1.0,"thrill_cooldown":70.0,
	"unending_thirst_cap":0.25,"unending_thirst_grace":3.0,"unending_thirst_decay":0.02
}

const WORKING_NAMES := {
	"slayer_trait":"Betrayer's Thirst","slayer_q":"Dive","slayer_w":"Sweeping Strike","slayer_e":"Evasion","slayer_r1":"Metamorphosis","slayer_r2":"The Hunt",
	"slayer_l9_1":"Immolation","slayer_l9_2":"Battered Assault","slayer_l9_3":"Unending Hatred",
	"slayer_l12_1":"Rapid Chase","slayer_l12_2":"Friend or Foe","slayer_l12_3":"Unbound",
	"slayer_l15_r1":"Metamorphosis","slayer_l15_r2":"The Hunt",
	"slayer_l18_1":"Reflexive Block","slayer_l18_2":"Thirsting Blade","slayer_l18_3":"Hunter's Onslaught",
	"slayer_l21_1":"Nimble Defender","slayer_l21_2":"Elusive Strike","slayer_l21_3":"Shadow Shield",
	"slayer_l24_1":"Marked for Death","slayer_l24_2":"Fiery Brand","slayer_l24_3":"Blades of Azzinoth",
	"slayer_l27_r1":"Demonic Form","slayer_l27_r2":"Nowhere to Hide",
	"slayer_l30_1":"Nexus Blades","slayer_l30_2":"Thrill of Battle","slayer_l30_3":"Unending Thirst"
}

const TALENT_DESCRIPTIONS := {
	"slayer_l9_1":"Sweeping Strike ignites enemies inside current Basic Attack range for 22 Physical damage per second for 4 seconds.",
	"slayer_l9_2":"Sweeping Strike's attack bonus lasts 5 seconds; hitting at least two enemies replaces it with 125%.",
	"slayer_l9_3":"Qualifying encounter defeats add level-scaled Basic Attack damage; the twentieth grants 20 more.",
	"slayer_l12_1":"Enemy Dive grants 20% Movement Speed and one different-target Dive during a 3-second window.",
	"slayer_l12_2":"Dive gains 20% range and may manually target allied heroes.",
	"slayer_l12_3":"Sweeping Strike crosses blockers. At 15 qualifying contacts it gains a second charge for the encounter.",
	"slayer_l15_r1":"Transform at a location, damage nearby enemies, and gain temporary Health for up to five hostile contacts.",
	"slayer_l15_r2":"Charge any valid enemy on the active battlefield, deal Physical damage, and request a 1-second Stun.",
	"slayer_l18_1":"Each valid Dive grants 3 level-scaled Block charges, up to 4.",
	"slayer_l18_2":"While Sweeping Strike's attack bonus is active, Betrayer's Thirst heals for 50% instead of 30%.",
	"slayer_l18_3":"Resolved Dive, Sweeping Strike, and Immolation damage heals for 25%, doubled against major enemies.",
	"slayer_l21_1":"Sweeping Strike damage grants level-scaled 25 Armor for 2 seconds.",
	"slayer_l21_2":"Each distinct Sweeping Strike contact reduces Evasion's cooldown by 3 seconds.",
	"slayer_l21_3":"Casting Evasion grants a 5-second Shield equal to 10% of current maximum Health.",
	"slayer_l24_1":"Dive deals 180 additional level-scaled damage to a target Dived within the previous 10 seconds.",
	"slayer_l24_2":"Every third consecutive successful Basic Attack deals 7% maximum-Health damage (1.75% to Bosses).",
	"slayer_l24_3":"Five qualifying Sweeping Strike contacts automatically grant 75% Basic Attack damage for 8 seconds.",
	"slayer_l27_r1":"Remain in Demon Form, gain 20% Attack Speed, and halve incoming Stun and Root duration.",
	"slayer_l27_r2":"The Hunt deals double damage below 25% Health and resets its cooldown when it defeats the target.",
	"slayer_l30_1":"Basic Attacks deal 20% additional damage and Slow by 20% for 1 second.",
	"slayer_l30_2":"D becomes active: reset Q, W, E, and the selected Heroic. Cooldown: 70 seconds.",
	"slayer_l30_3":"Excess trait healing becomes a Shield up to 25% maximum Health and decays after 3 seconds without attacking."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["slayer_l9_1","slayer_l9_2","slayer_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["slayer_l12_1","slayer_l12_2","slayer_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["slayer_l15_r1","slayer_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["slayer_l18_1","slayer_l18_2","slayer_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["slayer_l21_1","slayer_l21_2","slayer_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["slayer_l24_1","slayer_l24_2","slayer_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["slayer_l27_r1","slayer_l27_r2"],"heroic_requirements":{"slayer_l27_r1":"slayer_l15_r1","slayer_l27_r2":"slayer_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["slayer_l30_1","slayer_l30_2","slayer_l30_3"]}
]

const TEST_BUILDS := [
	{"name":"Level 1 Baseline Slayer","level":1,"heroic":"","talents":{}},
	{"name":"Immolation and Ability Healing","level":30,"heroic":"slayer_l15_r1","talents":{"tier_1":"slayer_l9_1","tier_2":"slayer_l12_2","tier_3":"slayer_l15_r1","tier_4":"slayer_l18_3","tier_5":"slayer_l21_1","tier_6":"slayer_l24_3","tier_7":"slayer_l27_r1","tier_8":"slayer_l30_3"}},
	{"name":"Battered Assault and Blades","level":30,"heroic":"slayer_l15_r1","talents":{"tier_1":"slayer_l9_2","tier_2":"slayer_l12_3","tier_3":"slayer_l15_r1","tier_4":"slayer_l18_2","tier_5":"slayer_l21_2","tier_6":"slayer_l24_3","tier_7":"slayer_l27_r1","tier_8":"slayer_l30_1"}},
	{"name":"Dive and Marked for Death","level":30,"heroic":"slayer_l15_r2","talents":{"tier_1":"slayer_l9_3","tier_2":"slayer_l12_1","tier_3":"slayer_l15_r2","tier_4":"slayer_l18_1","tier_5":"slayer_l21_3","tier_6":"slayer_l24_1","tier_7":"slayer_l27_r2","tier_8":"slayer_l30_2"}},
	{"name":"Evasion and Shield","level":30,"heroic":"slayer_l15_r1","talents":{"tier_1":"slayer_l9_1","tier_2":"slayer_l12_2","tier_3":"slayer_l15_r1","tier_4":"slayer_l18_1","tier_5":"slayer_l21_3","tier_6":"slayer_l24_2","tier_7":"slayer_l27_r1","tier_8":"slayer_l30_3"}},
	{"name":"Metamorphosis and Demonic Form","level":30,"heroic":"slayer_l15_r1","talents":{"tier_1":"slayer_l9_2","tier_2":"slayer_l12_2","tier_3":"slayer_l15_r1","tier_4":"slayer_l18_2","tier_5":"slayer_l21_3","tier_6":"slayer_l24_2","tier_7":"slayer_l27_r1","tier_8":"slayer_l30_1"}},
	{"name":"Hunt Execute","level":30,"heroic":"slayer_l15_r2","talents":{"tier_1":"slayer_l9_3","tier_2":"slayer_l12_1","tier_3":"slayer_l15_r2","tier_4":"slayer_l18_2","tier_5":"slayer_l21_2","tier_6":"slayer_l24_1","tier_7":"slayer_l27_r2","tier_8":"slayer_l30_1"}},
	{"name":"Unending Hatred Dungeon","level":30,"heroic":"slayer_l15_r2","talents":{"tier_1":"slayer_l9_3","tier_2":"slayer_l12_3","tier_3":"slayer_l15_r2","tier_4":"slayer_l18_1","tier_5":"slayer_l21_1","tier_6":"slayer_l24_3","tier_7":"slayer_l27_r2","tier_8":"slayer_l30_1"}},
	{"name":"Thrill of Battle Reset","level":30,"heroic":"slayer_l15_r1","talents":{"tier_1":"slayer_l9_1","tier_2":"slayer_l12_1","tier_3":"slayer_l15_r1","tier_4":"slayer_l18_3","tier_5":"slayer_l21_2","tier_6":"slayer_l24_1","tier_7":"slayer_l27_r1","tier_8":"slayer_l30_2"}},
	{"name":"Unending Thirst Sustain","level":30,"heroic":"slayer_l15_r1","talents":{"tier_1":"slayer_l9_2","tier_2":"slayer_l12_2","tier_3":"slayer_l15_r1","tier_4":"slayer_l18_2","tier_5":"slayer_l21_3","tier_6":"slayer_l24_2","tier_7":"slayer_l27_r1","tier_8":"slayer_l30_3"}}
]

const CLASS_DEFINITION := {"class_id":"slayer","display_name":"Slayer","primary_role":"DPS","role":"DPS","basic_action_id":"slayer_basic_attack","trait_id":"slayer_trait","q_ability_id":"slayer_q","w_ability_id":"slayer_w","e_ability_id":"slayer_e","heroic_option_ids":["slayer_l15_r1","slayer_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["damage","melee","mobile","sustain"],"color":Color("6fdb9a"),"ability":"Dive","base_health":1725.0,"health_growth":0.04,"base_power":78.0,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.0/1.82,"basic_action_range":SPACE.basic_range,"movement_speed":SPACE.movement_speed,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":3.59375,"health_regeneration_growth":0.04,"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"leather","armor_proficiency":"leather","weapon_proficiencies":["dual_wield","one_handed"],"uses_mana":false,"resource_id":""}

static func scale(level:int) -> float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int) -> float:return value*scale(level)
