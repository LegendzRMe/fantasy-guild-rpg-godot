extends RefCounted

const CLASS_ID := "mage"
const SCALE_PER_LEVEL := 1.04
const PYRO_SCALE_PER_LEVEL := 1.05
const SOURCE_TO_WORLD := 185.0/5.5
const IDS := {"basic_attack":"mage_basic_attack","trait":"mage_trait","q":"mage_q","w":"mage_w","e":"mage_e","r1":"mage_r1","r2":"mage_r2"}

# Geometry not exposed by Blizzard's public ability pages remains deliberately
# configurable and provisional. Source ratios are preserved through one shared scale.
const SPACE := {
	"source_to_world":SOURCE_TO_WORLD,"basic_range":5.5*SOURCE_TO_WORLD,
	"q_cast_range":9.5*SOURCE_TO_WORLD,"q_radius":2.0*SOURCE_TO_WORLD,"q_empowered_radius":3.0*SOURCE_TO_WORLD,
	"w_cast_range":5.5*SOURCE_TO_WORLD,"w_explosion_radius":3.0*SOURCE_TO_WORLD,
	"e_range":10.0*SOURCE_TO_WORLD,"e_width":1.0*SOURCE_TO_WORLD,"e_speed":14.0*SOURCE_TO_WORLD,
	"phoenix_cast_range":10.0*SOURCE_TO_WORLD,"phoenix_speed":12.0*SOURCE_TO_WORLD,"phoenix_path_width":1.5*SOURCE_TO_WORLD,
	"phoenix_attack_radius":8.0*SOURCE_TO_WORLD,"phoenix_splash_radius":2.0*SOURCE_TO_WORLD,
	"pyro_cast_range":10.5*SOURCE_TO_WORLD,"pyro_speed":4.0*SOURCE_TO_WORLD,"pyro_splash_radius":3.0*SOURCE_TO_WORLD,
	"movement_speed":150.0
}

const VALUES := {
	"health":1595.0,"health_regeneration":3.3164,"basic_attack_damage":65.0,"basic_attacks_per_second":1.11,
	"trait_charges":1,"trait_recharge":6.0,
	"q_cooldown":7.0,"q_damage":345.0,"q_warning":1.0,
	"fel_infusion_heal":94.0,"sunfire_damage":115.0,
	"w_cooldown":10.0,"w_duration":3.0,"w_tick":1.0,"w_tick_damage":42.0,"w_explosion_damage":215.0,
	"e_cooldown":12.0,"e_stun":1.0,"e_empowered_stun":1.5,"e_empowered_hits":3,
	"r1_cooldown":60.0,"r1_travel_damage":84.0,"r1_attack_damage":84.0,"r1_splash_damage":42.0,"r1_duration":7.0,"r1_attack_interval":1.0,
	"r2_cooldown":100.0,"r2_cast":1.5,"r2_primary":810.0,"r2_splash":405.0,
	"convection_required":20,"convection_damage":200.0,"convection_health":100.0,
	"arcane_barrier_fraction":0.50,"arcane_barrier_duration":4.0,"arcane_barrier_cooldown":45.0,
	"arcane_dynamo_per_stack":0.01,"arcane_dynamo_max":5,"arcane_dynamo_duration":5.0,
	"burned_flesh_normal":0.08,"burned_flesh_boss":0.04,"pyromaniac_reduction":0.5,
	"presence_event_ceiling":5,"gravity_crush":0.25,"gravity_crush_duration":4.0,"rebirth_charges":3,"rebirth_path_damage_on_reposition":false
}

const WORKING_NAMES := {
	"mage_trait":"Verdant Spheres","mage_q":"Flamestrike","mage_w":"Living Bomb","mage_e":"Gravity Lapse","mage_r1":"Phoenix","mage_r2":"Pyroblast",
	"mage_l9_1":"Convection","mage_l9_2":"Fel Infusion","mage_l9_3":"Mana Addict",
	"mage_l12_1":"Nether Roil","mage_l12_2":"Mana Tap","mage_l12_3":"Arcane Dynamo",
	"mage_l15_r1":"Phoenix","mage_l15_r2":"Pyroblast",
	"mage_l18_1":"Burned Flesh","mage_l18_2":"Sun King's Fury","mage_l18_3":"Sunfire Enchantment",
	"mage_l21_1":"Pyromaniac","mage_l21_2":"Backdraft","mage_l21_3":"Fission Bomb",
	"mage_l24_1":"Fury of the Sunwell","mage_l24_2":"Ignite","mage_l24_3":"Twin Spheres",
	"mage_l27_r1":"Rebirth","mage_l27_r2":"Presence of Mind",
	"mage_l30_1":"Flamethrower","mage_l30_2":"Master of Flames","mage_l30_3":"Gravity Crush"
}

const TALENT_DESCRIPTIONS := {
	"mage_l9_1":"Every 20 distinct qualifying Flamestrike hits during this encounter grants +200 Flamestrike damage and +100 maximum and current Health.",
	"mage_l9_2":"Gain 4% Ability Power. Activating Verdant Spheres heals Mage for 94 at Level 1.",
	"mage_l9_3":"Incoming lethal hostile damage automatically creates a 50% maximum-Health Shield for 4 seconds. Cooldown: 45 seconds.",
	"mage_l12_1":"Gravity Lapse has 30% more range. Hitting an enemy reduces its cooldown by 8 seconds once per cast.",
	"mage_l12_2":"Verdant Spheres begins recharging when activated instead of after the empowered Ability is cast.",
	"mage_l12_3":"Valid Q, W, or E casts grant 1% Ability Power for 5 seconds, stacking to 5%.",
	"mage_l15_r1":"Launch a persistent Phoenix. Cooldown: 60 seconds.","mage_l15_r2":"Cast a slow homing Pyroblast. Cooldown: 100 seconds.",
	"mage_l18_1":"Flamestrike hitting at least two enemies deals 8% reference Health to ordinary targets and 4% to Bosses. Armor applies.",
	"mage_l18_2":"Living Bombs created by spread deal 35% increased periodic and explosion damage.",
	"mage_l18_3":"Activating Verdant Spheres arms two Basic Attacks for bonus Ability damage; two hits grant 15% Ability Power for 10 seconds.",
	"mage_l21_1":"Every successful Living Bomb periodic tick reduces Q, W, and E cooldowns by 0.5 seconds. This is uncapped.",
	"mage_l21_2":"Living Bomb explosions Slow damaged enemies by 30% for 2 seconds.","mage_l21_3":"Living Bomb explosion and spread radius increases by 20%.",
	"mage_l24_1":"Flamestrike repeats at the same center and radius after 1.5 seconds.","mage_l24_2":"Each Flamestrike applies one Living Bomb to the eligible hit nearest its exact center.",
	"mage_l24_3":"Verdant Spheres stores 2 sequential charges and also grants all Level 18 talent effects.",
	"mage_l27_r1":"Phoenix lasts 14 seconds and R gains 3 temporary reposition charges while it persists.","mage_l27_r2":"Pyroblast has 50% more splash radius; qualifying Q hits and new bomb spreads reduce its cooldown by 10 seconds, up to 5 per event.",
	"mage_l30_1":"Flamestrike has 40% more cast range. Hitting two enemies reduces Q cooldown by 4 seconds.",
	"mage_l30_2":"Every Living Bomb generation may spread, with lineage tracking preventing reinfection and infinite loops.",
	"mage_l30_3":"Enemies successfully Stunned by Gravity Lapse take 25% more Mage-owned normal damage for 4 seconds."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["mage_l9_1","mage_l9_2","mage_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["mage_l12_1","mage_l12_2","mage_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["mage_l15_r1","mage_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["mage_l18_1","mage_l18_2","mage_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["mage_l21_1","mage_l21_2","mage_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["mage_l24_1","mage_l24_2","mage_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["mage_l27_r1","mage_l27_r2"],"heroic_requirements":{"mage_l27_r1":"mage_l15_r1","mage_l27_r2":"mage_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["mage_l30_1","mage_l30_2","mage_l30_3"]}
]

const CLASS_DEFINITION := {
	"class_id":"mage","display_name":"Mage","primary_role":"DPS","role":"DPS","basic_action_id":"mage_basic_attack","trait_id":"mage_trait",
	"q_ability_id":"mage_q","w_ability_id":"mage_w","e_ability_id":"mage_e","heroic_option_ids":["mage_l15_r1","mage_l15_r2"],
	"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["damage","ranged","area"],"color":Color("b381ff"),"ability":"Flamestrike",
	"base_health":1595.0,"health_growth":0.04,"base_power":65.0,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack",
	"basic_action_power_coefficient":1.0,"basic_action_interval":1.0/1.11,"basic_action_range":SPACE.basic_range,"movement_speed":150.0,
	"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":3.3164,"threat_modifier":1.0,"basic_action_damage_type":"physical",
	"armor_family":"cloth","armor_proficiency":"cloth","weapon_proficiencies":["wand","focus","staff"],"ability_power_percent":0.0
}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)
static func pyro_scaled(value:float,level:int)->float:return value*pow(PYRO_SCALE_PER_LEVEL,maxi(0,level-1))
