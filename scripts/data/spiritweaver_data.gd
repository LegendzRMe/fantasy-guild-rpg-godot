extends RefCounted

const CLASS_ID := "spiritweaver"
const SOURCE_BUILD := "2.55.17.97771"
const SOURCE_TO_WORLD := 185.0/5.5
const SPACE := {
	"combat_radius":0.75*SOURCE_TO_WORLD,"basic_range":1.5*SOURCE_TO_WORLD,"basic_heal_range":6.5*SOURCE_TO_WORLD,"basic_heal_bounce":4.5*SOURCE_TO_WORLD,
	"wolf_lunge":2.25*SOURCE_TO_WORLD,"q_range":6.0*SOURCE_TO_WORLD,"q_bounce":7.0*SOURCE_TO_WORLD,"w_range":8.0*SOURCE_TO_WORLD,"w_radius":2.5*SOURCE_TO_WORLD,
	"e_range":6.0*SOURCE_TO_WORLD,"e_radius":2.5*SOURCE_TO_WORLD,"purge_range":7.0*SOURCE_TO_WORLD,"bloodlust_radius":8.0*SOURCE_TO_WORLD,"ancestral_range":6.0*SOURCE_TO_WORLD,"farseer_radius":5.0*SOURCE_TO_WORLD
}
const VALUES := {
	"health":1900.0,"health_regeneration":3.957,"basic_attack_damage":110.0,"basic_attack_interval":0.9,"basic_heal":60.0,"basic_heal_bounce":0.50,
	"wolf_delay":3.0,"wolf_move":0.20,"wolf_attack_bonus":0.60,
	"q_cooldown":8.0,"q_heal":260.0,"q_bounces":2,
	"w_cooldown":8.0,"w_dps":64.0,"w_duration":5.0,"w_tick":0.5,
	"e_cooldown":15.0,"e_health":260.0,"e_duration":6.0,"e_slow":0.35,"e_tick":0.25,
	"d_cooldown":60.0,"d_unstoppable":0.5,"d_slow":0.80,"d_slow_duration":2.0,
	"ancestral_cooldown":100.0,"ancestral_delay":1.0,"ancestral_heal":1180.0,
	"bloodlust_cooldown":90.0,"bloodlust_duration":6.0,"bloodlust_move":0.35,"bloodlust_speed":0.40,"bloodlust_leech":0.30,
	"stormcaller_radius":0.25,"stormcaller_health":2.0,"stormcaller_max":200,
	"colossal_radius":0.50,"colossal_duration":0.50,"colossal_health":0.25,
	"feral_first_move":0.40,"feral_later_move":0.30,"feral_first_duration":1.0,"feral_armor":15.0,"feral_armor_duration":1.0,
	"earthliving_heal":160.0,"earthliving_duration":4.0,"earthliving_tick":1.0,
	"electric_heal":0.20,"electric_self_heal":0.40,"electric_move":0.10,
	"healing_totem_icd":30.0,"healing_totem_duration":10.0,"healing_totem_percent":0.02,"healing_totem_tick":1.0,
	"grounded_slow":0.45,"purification_heal":220.0,"purification_shield_damage":330.0,"purification_antiheal":0.40,"purification_duration":2.0,
	"tidal_cdr":1.0,"earth_shield":0.40,"earth_shield_duration":3.0,"wellspring_interval":2.0,"wellspring_multiplier":0.35,
	"rising_duration":3.0,"rising_per_contact":0.10,"rising_max":15,
	"earthgrasp_damage":90.0,"earthgrasp_slow":0.90,"earthgrasp_duration":1.0,
	"farseer_delay":1.5,"farseer_area_heal":590.0,"war_shout_multiplier":2.0,
	"cap_a_seconds":5.0,"cap_b_area_bonus":0.10,"cap_c_recharge":0.50
}
const WORKING_NAMES := {
	"spiritweaver_l9_1":"Stormcaller","spiritweaver_l9_2":"Colossal Totem","spiritweaver_l9_3":"Feral Heart",
	"spiritweaver_l12_1":"Earthliving Enchant","spiritweaver_l12_2":"Electric Charge","spiritweaver_l12_3":"Healing Totem",
	"spiritweaver_l15_r1":"Ancestral Healing","spiritweaver_l15_r2":"Bloodlust",
	"spiritweaver_l18_1":"Grounded Totem","spiritweaver_l18_2":"Purification","spiritweaver_l18_3":"Blood and Thunder",
	"spiritweaver_l21_1":"Tidal Waves","spiritweaver_l21_2":"Earth Shield","spiritweaver_l21_3":"Wellspring",
	"spiritweaver_l24_1":"Rising Storm","spiritweaver_l24_2":"Earthgrasp Totem","spiritweaver_l24_3":"Hunger of the Wolf",
	"spiritweaver_l27_r1":"Farseer's Blessing","spiritweaver_l27_r2":"Gladiator's War Shout",
	"spiritweaver_l30_1":"Stormbound Fang","spiritweaver_l30_2":"Spirit Confluence","spiritweaver_l30_3":"Cleansing Tempest"
}
const TALENT_DESCRIPTIONS := {
	"spiritweaver_l9_1":"Lightning Shield radius +25%; each qualifying contact grants its Hero bearer +2 encounter maximum Health, up to 200 stacks.",
	"spiritweaver_l9_2":"Earthbind area/duration +50% and Health +25%; reactivate E once to reposition the same Totem.",
	"spiritweaver_l9_3":"Wolf Move Speed is 40% for one second then 30%; entering and leaving grants 15 Level-1 Armor for one second.",
	"spiritweaver_l12_1":"Manual Chain Heal recipients below 50% Health receive 160 additional healing over four seconds.",
	"spiritweaver_l12_2":"Lightning Shield heals its bearer for 20% of damage (40% on Spirit Weaver) and grants 10% Move Speed while damaging.",
	"spiritweaver_l12_3":"Every ready 30-second ICD automatically empowers the next E to heal nearby Heroes for 2% maximum Health each second and last 10 seconds.",
	"spiritweaver_l15_r1":"After one second, heal another allied Hero for 1180.","spiritweaver_l15_r2":"Nearby Heroes gain 40% Basic Action speed, 35% Move Speed, and heal for 30% primary Basic Attack damage for six seconds.",
	"spiritweaver_l18_1":"Earthbind Slow becomes 45%, and Lightning Shield may target the active Totem.",
	"spiritweaver_l18_2":"Successful ally Purge removal heals 220; enemy Purge removes up to 330 Shield and reduces healing received 40% for two seconds.",
	"spiritweaver_l18_3":"Manual Chain Heal gains one additional Hero recipient.",
	"spiritweaver_l21_1":"Each Hero healed by manual Q removes one second from Q's remaining cooldown.",
	"spiritweaver_l21_2":"Lightning Shield on a Hero grants a 40% maximum-Health Shield for three seconds.",
	"spiritweaver_l21_3":"Every two seconds, active Earthbind casts a 35% baseline untalented Chain Heal.",
	"spiritweaver_l24_1":"Lightning Shield lasts three seconds longer and gains 10% damage per contact, up to 15 per instance.",
	"spiritweaver_l24_2":"Initial E placement deals 90 and Slows 90% for one second.",
	"spiritweaver_l24_3":"Manual Q may use Earthbind once as a free, unhealed relay.",
	"spiritweaver_l27_r1":"Ancestral recasts on its target after 1.5 seconds and heals nearby allies for 590.",
	"spiritweaver_l27_r2":"Bloodlust duration and radius are doubled.",
	"spiritweaver_l30_1":"A Wolf lunge while self-shielded deals one burst equal to five seconds of the current W damage rate.",
	"spiritweaver_l30_2":"Manual Q heals Heroes in E 10% more, prioritizes lowest Health bounces, and may use Spirit Weaver once as a free healed relay.",
	"spiritweaver_l30_3":"Purge recharges 50% faster, may self-target even while Stunned, and its Unstoppable retaliates against primary Basic Attackers with Purge Slow."
}
const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["spiritweaver_l9_1","spiritweaver_l9_2","spiritweaver_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["spiritweaver_l12_1","spiritweaver_l12_2","spiritweaver_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["spiritweaver_l15_r1","spiritweaver_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["spiritweaver_l18_1","spiritweaver_l18_2","spiritweaver_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["spiritweaver_l21_1","spiritweaver_l21_2","spiritweaver_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["spiritweaver_l24_1","spiritweaver_l24_2","spiritweaver_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["spiritweaver_l27_r1","spiritweaver_l27_r2"],"heroic_requirements":{"spiritweaver_l27_r1":"spiritweaver_l15_r1","spiritweaver_l27_r2":"spiritweaver_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["spiritweaver_l30_1","spiritweaver_l30_2","spiritweaver_l30_3"]}
]
const TEST_BUILDS := [
	{"name":"Baseline Generalist","level":30,"heroic":"spiritweaver_l15_r1","talents":{}},
	{"name":"Totem Relay","level":30,"heroic":"spiritweaver_l15_r1","talents":{"tier_1":"spiritweaver_l9_2","tier_2":"spiritweaver_l12_3","tier_3":"spiritweaver_l15_r1","tier_4":"spiritweaver_l18_1","tier_5":"spiritweaver_l21_3","tier_6":"spiritweaver_l24_3","tier_7":"spiritweaver_l27_r1","tier_8":"spiritweaver_l30_2"}},
	{"name":"Lightning Wolf","level":30,"heroic":"spiritweaver_l15_r2","talents":{"tier_1":"spiritweaver_l9_1","tier_2":"spiritweaver_l12_2","tier_3":"spiritweaver_l15_r2","tier_4":"spiritweaver_l18_3","tier_5":"spiritweaver_l21_2","tier_6":"spiritweaver_l24_1","tier_7":"spiritweaver_l27_r2","tier_8":"spiritweaver_l30_1"}},
	{"name":"Purge Control","level":30,"heroic":"spiritweaver_l15_r1","talents":{"tier_1":"spiritweaver_l9_3","tier_2":"spiritweaver_l12_1","tier_3":"spiritweaver_l15_r1","tier_4":"spiritweaver_l18_2","tier_5":"spiritweaver_l21_1","tier_6":"spiritweaver_l24_2","tier_7":"spiritweaver_l27_r1","tier_8":"spiritweaver_l30_3"}}
]
const CLASS_DEFINITION := {"class_id":"spiritweaver","display_name":"Spirit Weaver","primary_role":"Healer","role":"Healer","basic_action_id":"spiritweaver_basic_action","trait_id":"spiritweaver_ghost_wolf","q_ability_id":"spiritweaver_chain_heal","w_ability_id":"spiritweaver_lightning_shield","e_ability_id":"spiritweaver_earthbind_totem","heroic_option_ids":["spiritweaver_l15_r1","spiritweaver_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["melee","healer","support","deployable"],"color":Color("60b9d2"),"ability":"Chain Heal","base_health":VALUES.health,"health_growth":0.04,"base_power":VALUES.basic_attack_damage,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":VALUES.basic_attack_interval,"basic_action_range":SPACE.basic_range,"movement_speed":4.8398*SOURCE_TO_WORLD,"combat_radius":SPACE.combat_radius,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":VALUES.health_regeneration,"health_regeneration_growth":0.04,"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"mail","armor_proficiency":"mail","weapon_proficiencies":["one_handed","shield","focus"],"uses_mana":false,"resource_id":""}
static func scaled(value:float,level:int)->float:return value*pow(1.04,maxi(0,level-1))
