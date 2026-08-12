extends RefCounted

const CLASS_ID := "druid"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5

const IDS := {
	"basic_attack":"druid_basic_attack", "basic_hot":"druid_basic_hot", "d":"druid_innervate",
	"q":"druid_regrowth", "w":"druid_moonfire", "e":"druid_entangling_roots",
	"r1":"druid_tranquility", "r2":"druid_twilight_dream"
}

# Source-unit geometry from live data/community inspection. Values are kept here so
# calibration changes never require touching combat code.
const SPACE := {
	"source_to_world":SOURCE_TO_WORLD, "basic_range":5.5*SOURCE_TO_WORLD,
	"regrowth_range":7.0*SOURCE_TO_WORLD, "moonfire_range":8.0*SOURCE_TO_WORLD,
	"moonfire_radius":1.5*SOURCE_TO_WORLD, "roots_range":8.0*SOURCE_TO_WORLD,
	"roots_initial_radius":1.0*SOURCE_TO_WORLD, "roots_max_radius":3.0*SOURCE_TO_WORLD,
	"tranquility_radius":5.5*SOURCE_TO_WORLD, "twilight_radius":5.0*SOURCE_TO_WORLD,
	"astral_range":7.2*SOURCE_TO_WORLD, "treant_attack_range":1.0*SOURCE_TO_WORLD,
	"treant_acquire_range":8.0*SOURCE_TO_WORLD, "movement_speed":150.0, "combat_radius":42.0
}

const VALUES := {
	"health":1525.0, "health_regeneration":3.1796, "basic_attack_damage":60.0, "basic_attack_interval":0.9,
	"regrowth_total":380.0, "regrowth_duration":20.0, "regrowth_tick":19.0, "regrowth_interval":1.0, "q_cooldown":5.0,
	"basic_hot_total":60.0, "basic_hot_duration":2.0, "basic_hot_tick":30.0, "basic_hot_interval":1.0,
	"moonfire_damage":90.0, "moonfire_heal":130.0, "w_cooldown":3.0, "moonfire_reveal":2.0, "moonfire_cap":5,
	"roots_damage":117.0, "e_cooldown":12.0, "roots_duration":1.25, "roots_growth":3.0, "roots_persistence":1.25,
	"innervate_cooldown":25.0, "innervate_duration":5.0, "innervate_rate_bonus":0.50,
	"tranquility_tick":80.0, "tranquility_duration":8.0, "tranquility_cooldown":80.0, "tranquility_armor":10.0,
	"twilight_damage":310.0, "twilight_delay":0.5, "twilight_silence":3.0, "twilight_cooldown":90.0,
	"deep_roots_size":0.25, "deep_roots_persistence":0.40, "vengeful_per_root":7.0,
	"emerald_cdr":1.0, "emerald_cap":5, "rejuvenation_duration":0.50, "celestial_reveal":3.0, "celestial_basic_damage":0.85,
	"shando_regrowth_rate":0.25, "wild_growth_seconds":1.0, "wild_growth_cap":5,
	"lunar_roots_cdr":1.0, "lunar_roots_cap":3, "ysera_bonus":0.75, "nature_balance_duration":5.0,
	"nature_balance_area":0.75, "moonlit_base":0.20, "moonlit_per_regrowth":0.15,
	"serenity_cdr":3.0, "serenity_cap":5, "serenity_base":0.25, "serenity_per_regrowth":0.10,
	"astral_channel":1.0, "astral_silence_bonus":2.0, "lifebloom_missing":0.10,
	"lunar_shower_cdr":1.0, "lunar_shower_bonus":0.20, "lunar_shower_max":3, "lunar_shower_window":6.0,
	"nature_communion_remaining":0.50,
	"treant_health":550.0, "treant_health_decay":50.0, "treant_damage":58.0, "treant_interval":1.0, "treant_speed":4.8007*SOURCE_TO_WORLD
}

const WORKING_NAMES := {
	"druid_l9_1":"Deep Roots", "druid_l9_2":"Vengeful Roots", "druid_l9_3":"Emerald Dreams",
	"druid_l12_1":"Rejuvenation", "druid_l12_2":"Celestial Alignment", "druid_l12_3":"Shan'do's Clarity",
	"druid_l15_r1":"Tranquility", "druid_l15_r2":"Twilight Dream",
	"druid_l18_1":"Wild Growth", "druid_l18_2":"Verdant Pulse", "druid_l18_3":"Nature's Cure",
	"druid_l21_1":"Nature's Swiftness", "druid_l21_2":"Lunar Roots", "druid_l21_3":"Revitalize",
	"druid_l24_1":"Ysera's Gift", "druid_l24_2":"Nature's Balance", "druid_l24_3":"Moonlit Harmony",
	"druid_l27_r1":"Serenity", "druid_l27_r2":"Astral Communion",
	"druid_l30_1":"Lifebloom", "druid_l30_2":"Lunar Shower", "druid_l30_3":"Nature's Communion"
}

const TALENT_DESCRIPTIONS := {
	"druid_l9_1":"Entangling Roots grows 25% larger and persists 40% longer. Deaths in the primary area create one untalented Roots cast.",
	"druid_l9_2":"Primary Roots summons a Treant. Each quest-category enemy successfully Rooted adds 7 level-one damage for this encounter.",
	"druid_l9_3":"Each unique successful primary Root reduces Innervate by 1 second, up to 5.",
	"druid_l12_1":"Regrowth on another ally also applies a half-duration Regrowth to Druid.",
	"druid_l12_2":"Moonfire Reveals for 5 seconds; Basic Attacks deal 85% more damage to enemies Revealed by this Druid.",
	"druid_l12_3":"Innervate has two charges and recharges 25% faster per living ally with this Druid's Regrowth.",
	"druid_l15_r1":"Heal nearby allied Heroes every second for 8 seconds. Own-Regrowth allies in the area gain 10 Armor.",
	"druid_l15_r2":"After 0.5 seconds, damage and Silence nearby enemies, then globally refresh this Druid's Regrowths.",
	"druid_l18_1":"Each qualifying Moonfire contact extends every own Regrowth by 1 second, up to 5.",
	"druid_l18_2":"A primary Roots cast that successfully Roots triggers one bonus tick on every own Regrowth.",
	"druid_l18_3":"Direct Regrowth casts remove every Stun, Root, and Slow from their target.",
	"druid_l21_1":"Regrowth tick overhealing transfers exactly once to the closest other living ally.",
	"druid_l21_2":"Moonfire reduces Roots by 1 second per unique qualifying contact, up to 3.",
	"druid_l21_3":"Innervating an ally also accelerates Druid's Q/W/E by 50% for 5 seconds.",
	"druid_l24_1":"Above 75% Health, Regrowth heals 75% more. Below 25%, Moonfire's Regrowth healing heals 75% more.",
	"druid_l24_2":"Moonfire radius increases 75% and Regrowth lasts 25 seconds with 25 ticks.",
	"druid_l24_3":"Moonfire healing gains 20% plus 15% per living own-Regrowth ally.",
	"druid_l27_r1":"Moonfire reduces Tranquility by 3 seconds per contact; Tranquility healing gains 25% plus 10% per own-Regrowth ally.",
	"druid_l27_r2":"Channel 1 second, teleport, cast a free Moonfire and Twilight Dream; Silence lasts 5 seconds.",
	"druid_l30_1":"Direct Regrowth immediately heals 10% of the target's missing Health.",
	"druid_l30_2":"Moonfire contact reduces its cooldown by 1 second and empowers the next cast within 6 seconds, stacking to +60% damage.",
	"druid_l30_3":"Innervating an own-Regrowth ally heals 50% of its remaining scheduled healing, then fully refreshes it."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["druid_l9_1","druid_l9_2","druid_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["druid_l12_1","druid_l12_2","druid_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["druid_l15_r1","druid_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["druid_l18_1","druid_l18_2","druid_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["druid_l21_1","druid_l21_2","druid_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["druid_l24_1","druid_l24_2","druid_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["druid_l27_r1","druid_l27_r2"],"heroic_requirements":{"druid_l27_r1":"druid_l15_r1","druid_l27_r2":"druid_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["druid_l30_1","druid_l30_2","druid_l30_3"]}
]

const TEST_BUILDS := [
	{"name":"Level 1 Baseline","level":1,"heroic":"","talents":{}},
	{"name":"Regrowth Healer","level":30,"heroic":"druid_l15_r1","talents":{"tier_1":"druid_l9_3","tier_2":"druid_l12_1","tier_3":"druid_l15_r1","tier_4":"druid_l18_1","tier_5":"druid_l21_1","tier_6":"druid_l24_1","tier_7":"druid_l27_r1","tier_8":"druid_l30_1"}},
	{"name":"Roots and Treant","level":30,"heroic":"druid_l15_r1","talents":{"tier_1":"druid_l9_2","tier_2":"druid_l12_2","tier_3":"druid_l15_r1","tier_4":"druid_l18_2","tier_5":"druid_l21_2","tier_6":"druid_l24_2","tier_7":"druid_l27_r1","tier_8":"druid_l30_2"}},
	{"name":"Moonfire Twilight","level":30,"heroic":"druid_l15_r2","talents":{"tier_1":"druid_l9_1","tier_2":"druid_l12_2","tier_3":"druid_l15_r2","tier_4":"druid_l18_3","tier_5":"druid_l21_2","tier_6":"druid_l24_3","tier_7":"druid_l27_r2","tier_8":"druid_l30_2"}},
	{"name":"Innervate HoT Engine","level":30,"heroic":"druid_l15_r2","talents":{"tier_1":"druid_l9_3","tier_2":"druid_l12_3","tier_3":"druid_l15_r2","tier_4":"druid_l18_3","tier_5":"druid_l21_3","tier_6":"druid_l24_2","tier_7":"druid_l27_r2","tier_8":"druid_l30_3"}}
]

const CLASS_DEFINITION := {
	"class_id":"druid","display_name":"Druid","primary_role":"Healer","role":"Healer",
	"basic_action_id":"druid_basic_attack","trait_id":"druid_innervate","q_ability_id":"druid_regrowth","w_ability_id":"druid_moonfire","e_ability_id":"druid_entangling_roots",
	"heroic_option_ids":["druid_l15_r1","druid_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["healing","proactive","periodic"],"color":Color("77c66e"),"ability":"Regrowth",
	"base_health":VALUES.health,"health_growth":0.04,"base_power":VALUES.basic_attack_damage,"power_growth":0.04,"base_armor":0.0,
	"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":VALUES.basic_attack_interval,"basic_action_range":SPACE.basic_range,
	"movement_speed":SPACE.movement_speed,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":VALUES.health_regeneration,"health_regeneration_growth":0.04,
	"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"leather","armor_proficiency":"leather","weapon_proficiencies":["staff","one_handed"],"uses_mana":false,"resource_id":""
}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)
