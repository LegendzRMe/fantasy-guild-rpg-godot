extends RefCounted

const CLASS_ID := "guardian"
const SCALE_PER_LEVEL := 1.04
const ACTION_KEYS := ["D","Q","W","E","R"]

const IDS := {
	"basic_attack":"guardian_basic_attack","trait":"guardian_trait","q":"guardian_q","w":"guardian_w","e":"guardian_e","r1":"guardian_r1","r2":"guardian_r2"
}

# Godot-space conversion values are deliberately explicit and independent from
# Heroes of the Storm world units.
const SPACE := {
	"basic_range":55.0,"storm_bolt_range":390.0,"storm_bolt_width":18.0,
	"dwarf_toss_range":235.0,"thunder_clap_radius":145.0,"landing_radius":105.0,
	"aura_radius":125.0,"haymaker_launch":190.0,"movement_speed":135.0
}

const VALUES := {
	"health":2765.0,"basic_attack_damage":88.0,"basic_attacks_per_second":1.11,
	"second_wind_delay":4.0,"second_wind_normal":55.0,"second_wind_low":111.0,"second_wind_threshold":0.40,
	"storm_bolt_damage":110.0,"storm_bolt_cooldown":10.0,"storm_bolt_stun":1.25,"storm_bolt_projectile_speed":560.0,
	"quest_first":45,"quest_mythic":160,"quest_death_window":3.0,
	"thunder_clap_damage":96.0,"thunder_clap_cooldown":8.0,"thunder_clap_slow":0.30,"thunder_clap_duration":2.5,
	"dwarf_toss_damage":59.0,"dwarf_toss_cooldown":10.0,"dwarf_toss_armor":30.0,"dwarf_toss_armor_duration":2.0,
	"avatar_cooldown":90.0,"avatar_duration":20.0,"avatar_health":1000.0,"avatar_hitbox_multiplier":1.28,
	"haymaker_cooldown":40.0,"haymaker_damage":319.0,"haymaker_stagger":0.50,
	"block_charges":3,"block_armor":75.0,"perfect_storm_icd":8.5,
	"bronzebeard_damage":15.0,"stoneform_fraction":0.30,"stoneform_duration":10.0,
	"stoneform_cooldown":60.0,"imposing_presence_cooldown":20.0,
	"hardened_shield_armor":75.0,"hardened_shield_duration":4.0,"capstone_cooldown":60.0,
	"rewind_window":8.0,"rewind_cooldown":60.0
}

const WORKING_NAMES := {
	"guardian_trait":"Second Wind","guardian_q":"Storm Bolt","guardian_w":"Thunder Clap","guardian_e":"Dwarf Toss",
	"guardian_r1":"Avatar","guardian_r2":"Haymaker",
	"guardian_l9_1":"Dwarf Block","guardian_l9_2":"Third Wind","guardian_l9_3":"Give 'em the Axe!",
	"guardian_l12_1":"Sledgehammer","guardian_l12_2":"Reverberation","guardian_l12_3":"Thunder Burn",
	"guardian_l15_r1":"Avatar","guardian_l15_r2":"Haymaker",
	"guardian_l18_1":"Perfect Storm","guardian_l18_2":"Heavy Impact","guardian_l18_3":"Skullcracker",
	"guardian_l21_1":"Bronzebeard Rage","guardian_l21_2":"Healing Static","guardian_l21_3":"Thunder Strike",
	"guardian_l24_1":"Dwarf Launch","guardian_l24_2":"Stoneform","guardian_l24_3":"Imposing Presence",
	"guardian_l27_r1":"Unstoppable Force","guardian_l27_r2":"Grand Slam",
	"guardian_l30_1":"Mountain King","guardian_l30_2":"Hardened Shield","guardian_l30_3":"Rewind"
}

const TALENT_DESCRIPTIONS := {
	"guardian_l15_r1":"Gain maximum and current Health for 20 seconds and increase visible combat size. Cooldown: 90 seconds.",
	"guardian_l15_r2":"Strike a chosen enemy for heavy Physical damage and launch ordinary enemies backward. Bosses are staggered instead. Cooldown: 40 seconds.",
	"guardian_l24_2":"Press D to heal for 30% maximum Health over 10 seconds. Second Wind pauses during Stoneform. Cooldown: 60 seconds.",
	"guardian_l24_3":"Enemies that hit Guardian with Basic Actions have their Basic Action speed reduced by 20% for 2.5 seconds. Once every 20 seconds, this reduction is increased to 50%.",
	"guardian_l30_2":"Falling below 30% maximum Health grants 75 Armor for 4 seconds. Hardened Shield can trigger only once every 60 seconds.",
	"guardian_l30_3":"Casting Storm Bolt, Thunder Clap, and Dwarf Toss within 8 seconds resets the cooldowns of all three abilities. Rewind can trigger only once every 60 seconds."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["guardian_l9_1","guardian_l9_2","guardian_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["guardian_l12_1","guardian_l12_2","guardian_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["guardian_l15_r1","guardian_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["guardian_l18_1","guardian_l18_2","guardian_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["guardian_l21_1","guardian_l21_2","guardian_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["guardian_l24_1","guardian_l24_2","guardian_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["guardian_l27_r1","guardian_l27_r2"],"heroic_requirements":{"guardian_l27_r1":"guardian_l15_r1","guardian_l27_r2":"guardian_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["guardian_l30_1","guardian_l30_2","guardian_l30_3"]}
]

const CLASS_DEFINITION := {
	"class_id":"guardian","display_name":"Guardian","primary_role":"Tank","role":"Tank",
	"basic_action_id":"guardian_basic_attack","trait_id":"guardian_trait","q_ability_id":"guardian_q","w_ability_id":"guardian_w","e_ability_id":"guardian_e",
	"heroic_option_ids":["guardian_l15_r1","guardian_l15_r2"],"talent_tier_definitions":TALENT_TIERS,
	"ai_behavior_tags":["tank","melee","high_threat"],"color":Color("5fa8ff"),"ability":"Storm Bolt",
	"base_health":2765.0,"health_growth":0.04,"base_power":88.0,"power_growth":0.04,"base_armor":0.0,
	"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.0/1.11,"basic_action_range":55.0,
	"movement_speed":135.0,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":0.0,"threat_modifier":5.0,
	"basic_action_damage_type":"physical","armor_family":"plate","armor_proficiency":"plate","weapon_proficiencies":["one_handed","two_handed","weapon_and_shield"]
}

static func scale(level:int)->float:
	return pow(SCALE_PER_LEVEL,maxi(0,level-1))

static func scaled(value:float,level:int)->float:
	return value*scale(level)

static func power_scaled(value:float,current_power:float)->float:
	return maxf(0.0,current_power)*(value/float(VALUES.basic_attack_damage))
