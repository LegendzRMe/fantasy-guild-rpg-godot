extends RefCounted

const CLASS_ID := "priest"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0/5.5
const IDS := {"basic_attack":"priest_basic_attack","trait":"priest_trait","q":"priest_q","w":"priest_w","e":"priest_e","r1":"priest_r1","r2":"priest_r2"}

# Collision widths and radii are not exposed by official public sources. Keep
# every provisional conversion here so Priest Range can tune them in one place.
const SPACE := {
	"source_to_world":SOURCE_TO_WORLD,"basic_range":5.5*SOURCE_TO_WORLD,"movement_speed":150.0,"combat_radius":42.0,
	"pursued_radius":6.5*SOURCE_TO_WORLD,"flash_heal_radius":8.0*SOURCE_TO_WORLD,
	"divine_star_distance":8.75*SOURCE_TO_WORLD,"divine_star_out_width":0.9*SOURCE_TO_WORLD,"divine_star_return_width":1.6*SOURCE_TO_WORLD,"divine_star_speed":520.0,
	"chastise_range":10.5*SOURCE_TO_WORLD,"chastise_width":0.65*SOURCE_TO_WORLD,"chastise_speed":680.0,
	"salvation_radius":4.5*SOURCE_TO_WORLD,"lightbomb_selection_range":8.0*SOURCE_TO_WORLD,"lightbomb_radius":4.5*SOURCE_TO_WORLD,
	"blessed_champion_radius":4.5*SOURCE_TO_WORLD,"holy_nova_radius":4.5*SOURCE_TO_WORLD
}

const VALUES := {
	"health":1665.0,"health_regeneration":3.4687,"basic_attack_damage":85.0,"basic_attack_interval":1.0,
	"pursued_heal":32.0,"spirit_duration":8.0,
	"q_heal":280.0,"q_cast":0.75,"q_cooldown":5.0,
	"w_damage":140.0,"w_heal":130.0,"w_cooldown":10.0,"w_bonus_per_enemy":0.25,"hero_hit_cap":5,
	"e_damage":175.0,"e_root":1.25,"e_cooldown":9.0,
	"r1_startup":0.5,"r1_channel":3.0,"r1_heal_fraction":0.30,"r1_cooldown":80.0,
	"r2_delay":1.5,"r2_damage":150.0,"r2_stun":1.25,"r2_shield":165.0,"r2_shield_duration":5.0,"r2_cooldown":60.0,
	"evenhanded_healing":0.15,"evenhanded_refund":0.40,"pws_ally":128.0,"pws_self":185.0,"pws_duration":4.0,
	"blessed_champion_rate":0.15,"blessed_champion_duration":5.0,"moral_range":1.1*SOURCE_TO_WORLD,"surge_reduction":0.75,
	"piercing_max":10,"zeal_duration":6.0,"zeal_rate":0.25,"blessed_recovery_threshold":0.08,"blessed_recovery_fraction":0.15,"blessed_recovery_duration":3.0,"blessed_recovery_cooldown":10.0,
	"devotion_ally":25.0,"devotion_self":15.0,"devotion_duration":2.0,"speed_pious_movement":0.30,"speed_pious_reduction":1.0,
	"push_speed":0.025,"push_pursued":0.05,"push_max":8,"push_duration":6.0,"push_e_rate":1.25,
	"tyr_base":0.10,"tyr_per_stack":0.10,"tyr_max":7,"renew_total":180.0,"renew_duration":6.0,"renew_tick":1.0,
	"holy_nova_heal":105.0,"holy_nova_damage":150.0,"benediction_attacks":8,
	"light_stormwind_refund":60.0,"inner_fire_speed":0.40,"inner_fire_armor":50.0,"inner_fire_duration":3.0,
	"guardian_armor":50.0,"guardian_duration":3.0,"redemption_health":0.50,"redemption_cooldown":180.0,
	"varian_damage":87.0,"varian_duration":3.0,"varian_tick":1.0,"varian_heal":0.50
}

const WORKING_NAMES := {
	"priest_trait":"Pursued by Grace / Eternal Vanguard","priest_q":"Flash Heal","priest_w":"Divine Star","priest_e":"Chastise","priest_r1":"Holy Word: Salvation","priest_r2":"Lightbomb",
	"priest_l9_1":"Evenhanded Blessings","priest_l9_2":"Power Word: Shield","priest_l9_3":"Blessed Champion",
	"priest_l12_1":"Moral Compass","priest_l12_2":"Surge of Light","priest_l12_3":"Piercing Light",
	"priest_l15_r1":"Holy Word: Salvation","priest_l15_r2":"Lightbomb",
	"priest_l18_1":"Zeal","priest_l18_2":"Blessed Recovery","priest_l18_3":"Devotion",
	"priest_l21_1":"Speed of the Pious","priest_l21_2":"Push Forward!","priest_l21_3":"Tyr's Deliverance",
	"priest_l24_1":"Renew","priest_l24_2":"Holy Nova","priest_l24_3":"Benediction",
	"priest_l27_r1":"Light of Stormwind","priest_l27_r2":"Inner Fire",
	"priest_l30_1":"Guardian of Ancient Kings","priest_l30_2":"Redemption","priest_l30_3":"Varian's Legacy"
}

const TALENT_DESCRIPTIONS := {
	"priest_l9_1":"Flash Heal heals 15% more and refunds 40% cooldown when its completed recipient differs from the previous completion.",
	"priest_l9_2":"Divine Star Shields allies on its outward path; hitting an enemy also Shields Priest.",
	"priest_l9_3":"For 5 seconds after Flash Heal, successful Basic Attacks heal Priest and nearby allies for 15% of its resolved amount.",
	"priest_l12_1":"Divine Star creates Basic Attacks near its apex and permanently increases Basic Attack range.",
	"priest_l12_2":"Successful Basic Attacks reduce Chastise's cooldown and can create one non-recursive bonus attack against its Rooted target.",
	"priest_l12_3":"Chastise pierces one enemy. Hitting two quest-qualified enemies in one cast grants 1% encounter Ability Power, up to 10%.",
	"priest_l15_r1":"Channel nearby protection and percentage healing.","priest_l15_r2":"Imbue the closest other ally, or Priest as fallback, with a delayed damaging, Stunning, Shielding burst.",
	"priest_l18_1":"Flash Heal marks one ally for 6 seconds; 25% of eligible Priest class damage heals that ally.",
	"priest_l18_2":"Losing more than 8% maximum Health at once restores 15% over 3 seconds; 10-second cooldown.",
	"priest_l18_3":"Direct Flash Heal and Divine Star return healing grants named Armor to allies and Priest.",
	"priest_l21_1":"Gain 30% Movement Speed during Divine Star; every ally contacted on return reduces its cooldown by 1 second.",
	"priest_l21_2":"Damaging enemies builds up to eight temporary Movement Speed and Pursued by Grace bonuses.",
	"priest_l21_3":"Divine Star gains 10% output; Basic Attacks bank up to seven more 10% bonuses for the next cast.",
	"priest_l24_1":"Flash Heal applies 180 healing over 6 seconds; successful Basic Attacks refresh owned Renew effects.",
	"priest_l24_2":"Catching Divine Star creates a nearby burst for 105 healing and 150 damage.",
	"priest_l24_3":"Eight successful Basic Attacks arm an immediate cooldown reset for the next completed Basic Ability.",
	"priest_l27_r1":"Salvation makes allies Invulnerable; a full channel refunds 60 seconds.","priest_l27_r2":"Lightbomb's recipient gains 40% Movement Speed and level-scaled 50 Armor for 3 seconds.",
	"priest_l30_1":"Direct Q/W healing grants level-scaled 50 Armor for 3 seconds to allies currently Stunned, Rooted, or Silenced.",
	"priest_l30_2":"At Spirit Form's end, revive at its location with 50% Health when the 180-second Redemption cooldown is ready.",
	"priest_l30_3":"Successful Basic Attacks apply 87 damage over 3 seconds and heal Priest for 50% of resolved periodic damage."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["priest_l9_1","priest_l9_2","priest_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["priest_l12_1","priest_l12_2","priest_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["priest_l15_r1","priest_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["priest_l18_1","priest_l18_2","priest_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["priest_l21_1","priest_l21_2","priest_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["priest_l24_1","priest_l24_2","priest_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["priest_l27_r1","priest_l27_r2"],"heroic_requirements":{"priest_l27_r1":"priest_l15_r1","priest_l27_r2":"priest_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["priest_l30_1","priest_l30_2","priest_l30_3"]}
]

const TEST_BUILDS := [
	{"name":"Level 1 Baseline","level":1,"heroic":"","talents":{}},
	{"name":"Salvation Protection","level":30,"heroic":"priest_l15_r1","talents":{"tier_1":"priest_l9_3","tier_2":"priest_l12_2","tier_3":"priest_l15_r1","tier_4":"priest_l18_3","tier_5":"priest_l21_3","tier_6":"priest_l24_3","tier_7":"priest_l27_r1","tier_8":"priest_l30_1"}},
	{"name":"Lightbomb Spirit","level":30,"heroic":"priest_l15_r2","talents":{"tier_1":"priest_l9_1","tier_2":"priest_l12_3","tier_3":"priest_l15_r2","tier_4":"priest_l18_1","tier_5":"priest_l21_2","tier_6":"priest_l24_1","tier_7":"priest_l27_r2","tier_8":"priest_l30_2"}}
]

const CLASS_DEFINITION := {"class_id":"priest","display_name":"Priest","primary_role":"Healer","role":"Healer","basic_action_id":"priest_basic_attack","trait_id":"priest_trait","q_ability_id":"priest_q","w_ability_id":"priest_w","e_ability_id":"priest_e","heroic_option_ids":["priest_l15_r1","priest_l15_r2"],"talent_tier_definitions":TALENT_TIERS,"ai_behavior_tags":["healer","ranged","positioning","support"],"color":Color("f4e8ad"),"ability":"Flash Heal","base_health":1665.0,"health_growth":0.04,"base_power":85.0,"power_growth":0.04,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.0,"basic_action_range":185.0,"movement_speed":150.0,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":3.4687,"health_regeneration_growth":0.04,"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"cloth","armor_proficiency":"cloth","weapon_proficiencies":["wand","one_handed"],"uses_mana":false,"resource_id":""}

static func scale(level:int)->float:return pow(SCALE_PER_LEVEL,maxi(0,level-1))
static func scaled(value:float,level:int)->float:return value*scale(level)
