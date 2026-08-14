extends RefCounted

const CLASS_ID := "beastmaster"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5

const SPACE := {
	"source_to_world":SOURCE_TO_WORLD,"basic_range":5.5*SOURCE_TO_WORLD,"movement_speed":4.8398*SOURCE_TO_WORLD,"combat_radius":0.875*SOURCE_TO_WORLD,
	"misha_range":1.5*SOURCE_TO_WORLD,"misha_radius":0.9375*SOURCE_TO_WORLD,"misha_acquisition":7.0*SOURCE_TO_WORLD,"misha_follow":3.5*SOURCE_TO_WORLD,"misha_leash":12.0*SOURCE_TO_WORLD,
	"swoop_length":12.0*SOURCE_TO_WORLD,"swoop_width":1.0*SOURCE_TO_WORLD,"lesser_spawn_offset":0.75*SOURCE_TO_WORLD,
	"charge_length":6.5*SOURCE_TO_WORLD,"charge_width":1.25*SOURCE_TO_WORLD,"greater_spawn_radius":1.5*SOURCE_TO_WORLD,
	"beast_range":2.0*SOURCE_TO_WORLD,"beast_acquisition":7.0*SOURCE_TO_WORLD,"greater_rally":8.5*SOURCE_TO_WORLD,
	"boar_range":20.0*SOURCE_TO_WORLD,"boar_width":6.0*SOURCE_TO_WORLD,"wildfire_radius":2.5*SOURCE_TO_WORLD,"pack_commander_leash":14.0*SOURCE_TO_WORLD
}

const VALUES := {
	"health":1810.0,"health_regeneration":3.7695,"basic_attack_damage":134.0,"basic_attack_interval":1.15,"threat_modifier":1.0,
	"misha_health":1520.0,"misha_health_growth":0.0475,"misha_regeneration":3.1718,"misha_damage":50.0,"misha_interval":1.2,"misha_speed":4.8398*SOURCE_TO_WORLD,"misha_passive_speed":0.15,"misha_retreat_speed":0.30,"misha_respawn":15.0,
	"swoop_damage":141.0,"swoop_slow":0.30,"swoop_slow_duration":2.0,"q_charges":2,"q_recharge":10.0,"army_recharge":20.0,
	"lesser_health":435.0,"lesser_decay":25.5882,"lesser_damage":53.0,"lesser_interval":1.0,"lesser_speed":3.6015*SOURCE_TO_WORLD,"lesser_lifetime":17.0,
	"charge_damage":150.0,"charge_stun":1.25,"charge_cooldown":10.0,
	"greater_cooldown":60.0,"greater_health":593.0,"greater_decay":28.2381,"greater_damage":52.0,"greater_interval":1.0,"greater_speed":3.25*SOURCE_TO_WORLD,"greater_lifetime":21.0,
	"coordinated_bonus":1.50,"fury_goal":225,"hunted_duration":3.0,"hunted_bonus":0.85,
	"block_interval":6.0,"block_max":2,"block_armor":75.0,"fresh_duration":2.0,"unhindered_multiplier":0.5,
	"bestial_cooldown":50.0,"bestial_duration":12.0,"bestial_bonus":2.0,"boar_cooldown":60.0,"boar_damage":110.0,"boar_slow":0.40,"boar_slow_duration":5.0,"boar_cap":5,
	"crippling_slow":0.50,"crippling_duration":3.5,"aspect_cdr":1.0,"chain_bonus":0.25,
	"hawk_speed":1.25,"hawk_duration":4.0,"hawk_extension":0.5,"dire_per_stack":0.15,"dire_max":10,"pack_vitality":0.25,
	"thrill_speed":0.25,"thrill_duration":2.0,"primal_suppression":0.20,"primal_duration":2.5,"protective_redirect":0.50,
	"spirit_duration":18.0,"spirit_heal":0.50,"kill_damage":0.50,"kill_root":1.5,
	"apex_health_per_second":2.0,"apex_per_stack":0.05,"apex_max":10,"wildfire_damage":14.0
}

const WORKING_NAMES := {
	"beastmaster_l9_1":"Army of Hell","beastmaster_l9_2":"Coordinated Assault","beastmaster_l9_3":"Fury of the Hunt",
	"beastmaster_l12_1":"Grizzled Fortitude","beastmaster_l12_2":"Fresh to the Hunt","beastmaster_l12_3":"Unhindered Hunter",
	"beastmaster_l15_r1":"Bestial Wrath","beastmaster_l15_r2":"Unleash the Boars",
	"beastmaster_l18_1":"Crippling Talons","beastmaster_l18_2":"Aspect of the Beast","beastmaster_l18_3":"Chain of Command",
	"beastmaster_l21_1":"Aspect of the Hawk","beastmaster_l21_2":"Dire Beast","beastmaster_l21_3":"Pack Vitality",
	"beastmaster_l24_1":"Thrill of the Hunt","beastmaster_l24_2":"Primal Intimidation","beastmaster_l24_3":"Protective Bond",
	"beastmaster_l27_r1":"Spirit Bond","beastmaster_l27_r2":"Kill Command",
	"beastmaster_l30_1":"Apex Companion","beastmaster_l30_2":"Pack Commander","beastmaster_l30_3":"Wildfire Pack"
}

const TALENT_DESCRIPTIONS := {
	"beastmaster_l9_1":"Spirit Swoop creates two Lesser Beasts; each charge recharges in 20 seconds.","beastmaster_l9_2":"Misha deals 150% increased Basic Attack damage while sharing her current target with a Lesser or Greater Beast.","beastmaster_l9_3":"225 encounter Fury from successful pack primary attacks unlocks independent 85% Beastmaster and Misha Hunted strikes after Charge.",
	"beastmaster_l12_1":"Every six seconds Beastmaster and Misha independently gain one shared-system Block charge, up to two.","beastmaster_l12_2":"New disposable beasts ignore external damage for two seconds while their natural Health decay continues.","beastmaster_l12_3":"Beastmaster suffers half Slow magnitude and half Slow duration.",
	"beastmaster_l15_r1":"Misha deals 200% increased Basic Attack damage for 12 seconds.","beastmaster_l15_r2":"Send up to five boars for 110 damage, Reveal, and a 40% Slow for five seconds.",
	"beastmaster_l18_1":"Spirit Swoop Slows 50% for 3.5 seconds.","beastmaster_l18_2":"Misha Basic Attacks reduce Charge cooldown by one second.","beastmaster_l18_3":"A Greater Beast rallies nearby Lessers for 25% increased damage; sources do not stack.",
	"beastmaster_l21_1":"A contacting Swoop grants Beastmaster 125% Attack Speed for four seconds; Misha attacks extend it by 0.5 seconds.","beastmaster_l21_2":"Beastmaster and Misha primary attacks add 15% to the next Charge, up to 150%.","beastmaster_l21_3":"Disposable beasts gain 25% maximum Health without increasing decay.",
	"beastmaster_l24_1":"Beastmaster primary attacks grant Beastmaster and Misha 25% Movement Speed for two seconds.","beastmaster_l24_2":"Enemies contacting any owned beast with a Basic Attack suffer 20% Attack Speed suppression for 2.5 seconds.","beastmaster_l24_3":"The healthier-percent Beastmaster/Misha partner redirects half hostile damage from the lower-percent partner before mitigation.",
	"beastmaster_l27_r1":"Bestial Wrath lasts 18 seconds and Misha attacks heal all living owned beasts for half resolved damage.","beastmaster_l27_r2":"Boars deal 50% more damage and Root for 1.5 seconds.",
	"beastmaster_l30_1":"In active combat Misha gains two maximum Health per living second and ramps 5% damage per same-target attack, up to 50%.","beastmaster_l30_2":"A successful Charge orders every disposable beast to rush, immediately Basic Attack, and focus its deterministic primary target.","beastmaster_l30_3":"Every Lesser and Greater Beast deals 14 damage per second to nearby enemies; distinct auras overlap."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["beastmaster_l9_1","beastmaster_l9_2","beastmaster_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["beastmaster_l12_1","beastmaster_l12_2","beastmaster_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["beastmaster_l15_r1","beastmaster_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["beastmaster_l18_1","beastmaster_l18_2","beastmaster_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["beastmaster_l21_1","beastmaster_l21_2","beastmaster_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["beastmaster_l24_1","beastmaster_l24_2","beastmaster_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["beastmaster_l27_r1","beastmaster_l27_r2"],"heroic_requirements":{"beastmaster_l27_r1":"beastmaster_l15_r1","beastmaster_l27_r2":"beastmaster_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["beastmaster_l30_1","beastmaster_l30_2","beastmaster_l30_3"]}
]

const TEST_BUILDS := [
	{"name":"Level 1 Baseline","level":1,"heroic":"","talents":{}},
	{"name":"Misha Focus","level":30,"heroic":"beastmaster_l15_r1","talents":{"tier_1":"beastmaster_l9_2","tier_2":"beastmaster_l12_1","tier_3":"beastmaster_l15_r1","tier_4":"beastmaster_l18_2","tier_5":"beastmaster_l21_2","tier_6":"beastmaster_l24_3","tier_7":"beastmaster_l27_r1","tier_8":"beastmaster_l30_1"}},
	{"name":"Swarm","level":30,"heroic":"beastmaster_l15_r2","talents":{"tier_1":"beastmaster_l9_1","tier_2":"beastmaster_l12_2","tier_3":"beastmaster_l15_r2","tier_4":"beastmaster_l18_3","tier_5":"beastmaster_l21_3","tier_6":"beastmaster_l24_2","tier_7":"beastmaster_l27_r2","tier_8":"beastmaster_l30_3"}},
	{"name":"Pack Commander","level":30,"heroic":"beastmaster_l15_r1","talents":{"tier_1":"beastmaster_l9_3","tier_2":"beastmaster_l12_1","tier_3":"beastmaster_l15_r1","tier_4":"beastmaster_l18_3","tier_5":"beastmaster_l21_2","tier_6":"beastmaster_l24_1","tier_7":"beastmaster_l27_r1","tier_8":"beastmaster_l30_2"}},
	{"name":"Fury Complete","level":30,"heroic":"beastmaster_l15_r1","talents":{"tier_1":"beastmaster_l9_3","tier_2":"beastmaster_l12_2","tier_3":"beastmaster_l15_r1","tier_4":"beastmaster_l18_2","tier_5":"beastmaster_l21_1","tier_6":"beastmaster_l24_3","tier_7":"beastmaster_l27_r1","tier_8":"beastmaster_l30_2"},"fury":225},
	{"name":"Apex Long Survival","level":30,"heroic":"beastmaster_l15_r1","talents":{"tier_1":"beastmaster_l9_2","tier_2":"beastmaster_l12_1","tier_3":"beastmaster_l15_r1","tier_4":"beastmaster_l18_2","tier_5":"beastmaster_l21_2","tier_6":"beastmaster_l24_3","tier_7":"beastmaster_l27_r1","tier_8":"beastmaster_l30_1"},"apex_seconds":120}
]

const CLASS_DEFINITION := {
	"class_id":"beastmaster","display_name":"Beastmaster","primary_role":"Ranged DPS","role":"Ranged DPS","basic_action_id":"beastmaster_basic_attack","trait_id":"beastmaster_misha_focus","q_ability_id":"beastmaster_spirit_swoop","w_ability_id":"beastmaster_misha_charge","e_ability_id":"beastmaster_greater_beast","heroic_option_ids":["beastmaster_l15_r1","beastmaster_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["ranged","basic_attack","summoner"],"color":Color("b58a52"),"ability":"Spirit Swoop",
	"base_health":VALUES.health,"health_growth":0.04,"base_power":VALUES.basic_attack_damage,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":VALUES.basic_attack_interval,"basic_action_range":SPACE.basic_range,"movement_speed":SPACE.movement_speed,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":VALUES.health_regeneration,"health_regeneration_growth":0.04,"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"mail","armor_proficiency":"mail","weapon_proficiencies":["bow","crossbow"],"uses_mana":false,"resource_id":""
}

static func scale(level:int,growth:float=SCALE_PER_LEVEL)->float:return pow(growth,maxi(0,level-1))
static func scaled(value:float,level:int,growth:float=SCALE_PER_LEVEL)->float:return value*scale(level,growth)
