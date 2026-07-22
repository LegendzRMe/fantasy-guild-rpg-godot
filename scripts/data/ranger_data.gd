extends RefCounted

const CLASS_ID := "ranger"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5
const IDS := {"basic_attack":"ranger_basic_attack","trait":"ranger_trait","q":"ranger_q","w":"ranger_w","e":"ranger_e","r1":"ranger_r1","r2":"ranger_r2"}

const SPACE := {
	"basic_range":185.0,"q_range":11.5*SOURCE_TO_WORLD,"q_hitbox":1.25*SOURCE_TO_WORLD,
	"q_speed":20.0*SOURCE_TO_WORLD,"q_seek_speed":8.0*SOURCE_TO_WORLD,"q_seek_radius":3.0*SOURCE_TO_WORLD,
	"w_start_radius":3.0*SOURCE_TO_WORLD,"w_end_radius":8.75*SOURCE_TO_WORLD,"e_range":5.0*SOURCE_TO_WORLD,
	"strafe_radius":10.0*SOURCE_TO_WORLD,"rain_width":2.8*SOURCE_TO_WORLD,"rain_length":9.8*SOURCE_TO_WORLD,
	"movement_speed":145.0
}

const VALUES := {
	"health":1340.0,"health_regeneration":2.793,"basic_attack_damage":70.0,"basic_attacks_per_second":1.67,
	"hatred_max":10,"hatred_duration":5.0,"hatred_damage_per_stack":0.08,"hatred_move_per_stack":0.01,
	"q_cooldown":10.0,"q_initial_damage":140.0,"q_seek_damage":80.0,"q_seek_count":2,
	"w_cooldown":13.0,"w_damage":159.0,"w_angle":50.0,"w_expansion":0.375,
	"e_cooldown":10.0,"e_speed":14.0*SOURCE_TO_WORLD,"e_empower_duration":2.0,"e_bonus_per_hatred":0.06,
	"r1_cooldown":60.0,"r1_duration":4.0,"r1_damage":70.0,"r1_shots_per_second":8.0,"r1_target_lockout":0.3125,
	"r2_charges":2,"r2_recharge":50.0,"r2_damage":250.0,"r2_stun":0.5,"r2_delay":0.25,"r2_traversal":0.5,
	"r2_interrupted_lockout":10.0
}

const WORKING_NAMES := {
	"ranger_trait":"Hatred","ranger_q":"Hungering Arrow","ranger_w":"Multishot","ranger_e":"Vault","ranger_r1":"Strafe","ranger_r2":"Rain of Vengeance",
	"ranger_l9_1":"Puncturing Arrow","ranger_l9_2":"Fire at Will","ranger_l9_3":"Creed of the Hunter",
	"ranger_l12_1":"Arsenal","ranger_l12_2":"Death Dealer","ranger_l12_3":"Repeating Arrow",
	"ranger_l15_r1":"Strafe","ranger_l15_r2":"Rain of Vengeance",
	"ranger_l18_1":"Monster Hunter","ranger_l18_2":"Frost Shot","ranger_l18_3":"Hot Pursuit",
	"ranger_l21_1":"Siphoning Arrow","ranger_l21_2":"Tempered by Discipline","ranger_l21_3":"Gloom",
	"ranger_l24_1":"Punishment","ranger_l24_2":"Seething Hatred","ranger_l24_3":"Manticore",
	"ranger_l27_r1":"Death Siphon","ranger_l27_r2":"Storm of Vengeance",
	"ranger_l30_1":"Acrobat","ranger_l30_2":"Farflight Quiver","ranger_l30_3":"Executioner"
}

const TALENT_DESCRIPTIONS := {
	"ranger_l9_1":"Hungering Arrow gains an additional seek. Its first qualifying hit permanently adds 6 damage for this encounter.",
	"ranger_l9_2":"Each distinct qualifying Multishot hit grants 2 Hatred and 2 encounter damage. At 20 hits, gain 40 additional damage.",
	"ranger_l9_3":"Every 50 successful Basic Attacks improves Hatred's Basic Attack bonus by 1%, up to 6% more.",
	"ranger_l12_1":"Multishot has 20% more range and launches three grenades that each deal damage once per enemy.",
	"ranger_l12_2":"Vault recharges in 5 seconds and its empowered Basic Attack gains 15% damage per Hatred. A primary kill resets one Vault charge.",
	"ranger_l12_3":"A valid Vault resets Hungering Arrow.",
	"ranger_l15_r1":"Strafe for 4 seconds, moving while rapidly firing at nearby enemies. Cooldown: 60 seconds.",
	"ranger_l15_r2":"Rain through a targeted rectangle, damaging and Stunning each enemy once. Stores 2 sequential charges.",
	"ranger_l18_1":"Hungering Arrow deals 100% more damage to ordinary hostile units.",
	"ranger_l18_2":"Multishot Slows by 20% for 2.5 seconds. Hungering Arrow deals 25% more damage to Slowed enemies.",
	"ranger_l18_3":"Hatred grants 2% Movement Speed per stack instead of 1%.",
	"ranger_l21_1":"Hungering Arrow heals 4% maximum Health per qualifying hit. Multishot heals 2% per distinct hit, up to 5.",
	"ranger_l21_2":"Basic Attacks heal for 10% plus 2 percentage points per Hatred of resolved primary damage.",
	"ranger_l21_3":"Gain 15 Armor and regenerate Health per Hatred. Press D to consume Hatred for 3 Armor per stack for 5 seconds.",
	"ranger_l24_1":"Multishot recharges 50% faster while at maximum Hatred.",
	"ranger_l24_2":"At maximum Hatred, Ranger-owned normal damage is increased by 10%.",
	"ranger_l24_3":"Every third consecutive Basic Attack deals percentage maximum-Health damage to the same target.",
	"ranger_l27_r1":"Strafe hits extend its duration against ordinary units and launch additional piercing bolts.",
	"ranger_l27_r2":"Basic Attacks reduce Rain's active recharge by 5 seconds and Hatred grants Attack Speed.",
	"ranger_l30_1":"Vault stores 3 sequential charges and leaves three slowing caltrops along its path.",
	"ranger_l30_2":"Basic Attack range increases by 20%, or by 50% at maximum Hatred.",
	"ranger_l30_3":"Basic Attacking a Stunned, Rooted, or Slowed enemy grants 15% Basic Attack damage for 3 seconds."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["ranger_l9_1","ranger_l9_2","ranger_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["ranger_l12_1","ranger_l12_2","ranger_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["ranger_l15_r1","ranger_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["ranger_l18_1","ranger_l18_2","ranger_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["ranger_l21_1","ranger_l21_2","ranger_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["ranger_l24_1","ranger_l24_2","ranger_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["ranger_l27_r1","ranger_l27_r2"],"heroic_requirements":{"ranger_l27_r1":"ranger_l15_r1","ranger_l27_r2":"ranger_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["ranger_l30_1","ranger_l30_2","ranger_l30_3"]}
]

const CLASS_DEFINITION := {
	"class_id":"ranger","display_name":"Ranger","primary_role":"DPS","role":"DPS","basic_action_id":"ranger_basic_attack","trait_id":"ranger_trait",
	"q_ability_id":"ranger_q","w_ability_id":"ranger_w","e_ability_id":"ranger_e","heroic_option_ids":["ranger_l15_r1","ranger_l15_r2"],
	"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["damage","ranged","mobile"],"color":Color("65dc89"),"ability":"Hungering Arrow",
	"base_health":1340.0,"health_growth":0.04,"base_power":70.0,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack",
	"basic_action_power_coefficient":1.0,"basic_action_interval":1.0/1.67,"basic_action_range":185.0,"movement_speed":145.0,"base_critical_chance":0.05,
	"critical_damage":2.0,"health_regeneration":2.793,"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"light",
	"armor_proficiency":"light","weapon_proficiencies":["bow","crossbow"]
}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)

