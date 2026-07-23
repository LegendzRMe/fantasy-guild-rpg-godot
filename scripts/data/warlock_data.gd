extends RefCounted

const CLASS_ID := "warlock"
const SCALE_PER_LEVEL := 1.04
const SOURCE_TO_WORLD := 185.0 / 5.5
const IDS := {
	"basic_attack":"warlock_basic_attack", "trait":"warlock_trait",
	"q":"warlock_q", "w":"warlock_w", "e":"warlock_e",
	"r1":"warlock_r1", "r2":"warlock_r2"
}

# Public Blizzard pages do not expose most geometry. Source-unit ratios from
# extracted live data are converted through the project's established scale.
const SPACE := {
	"source_to_world":SOURCE_TO_WORLD,
	"basic_range":5.5 * SOURCE_TO_WORLD,
	"q_range":10.5 * SOURCE_TO_WORLD,
	"q_start_radius":1.0 * SOURCE_TO_WORLD,
	"q_end_radius":2.45 * SOURCE_TO_WORLD,
	"q_travel_time":0.5625,
	"w_cast_range":7.0 * SOURCE_TO_WORLD,
	"w_break_range":10.5 * SOURCE_TO_WORLD,
	"e_range":10.0 * SOURCE_TO_WORLD,
	"e_burst_radius":1.25 * SOURCE_TO_WORLD,
	"e_burst_spacing":2.2 * SOURCE_TO_WORLD,
	"e_burst_delay":0.28,
	"horrify_range":10.0 * SOURCE_TO_WORLD,
	"horrify_radius":3.5 * SOURCE_TO_WORLD,
	"rain_impact_radius":1.5 * SOURCE_TO_WORLD,
	"movement_speed":148.0
}

const VALUES := {
	"health":1700.0, "health_regeneration":3.54,
	"basic_attack_damage":60.0, "basic_attacks_per_second":1.0,
	"life_tap_health_cost_ratio":222.0 / 1700.0,
	"life_tap_tooltip_percent":13, "life_tap_base_reduction_ratio":0.25,
	"life_tap_improved_reduction_ratio":0.40, "life_tap_input_lockout":0.5,
	"q_cooldown":3.0, "q_damage":210.0,
	"w_cooldown":20.0, "w_duration":3.0, "w_tick_interval":0.25,
	"w_damage_per_second":132.0, "w_healing_per_second":188.0,
	"e_cooldown":28.0, "e_damage":204.0, "e_duration":6.0,
	"e_tick_interval":1.0, "e_bursts":3, "e_max_stacks":3,
	"r1_cooldown":80.0, "r1_cast_delay":0.5, "r1_damage":120.0,
	"r1_fear_duration":2.0,
	"r2_cooldown":70.0, "r2_cast_time":1.5, "r2_duration":7.0,
	"r2_meteor_damage":165.0, "r2_meteor_count":14,
	"r2_meteor_interval":0.5, "r2_warning_time":0.45,
	"pursuit_requirement":30, "chaotic_energy_requirement":15,
	"echoed_requirement":40, "echoed_mythic_requirement":85,
	"consume_soul_healing":365.0, "consume_soul_internal_cooldown":50.0,
	"fel_armor_per_target":50.0, "fel_armor_duration":2.5,
	"dark_bargain_health_multiplier":1.40, "dark_bargain_cooldown_multiplier":1.10,
	"darkness_damage_requirement":600.0, "darkness_power_percent":0.25,
	"darkness_duration":5.0, "deep_impact_radius_multiplier":1.25,
	"deep_impact_targeted_ratio":0.70, "deep_impact_random_ratio":0.30,
	"deep_impact_slow_percent":0.90, "deep_impact_slow_duration":0.5,
	"demonic_circle_cooldown":120.0, "demonic_circle_banish_duration":3.0,
	"demonic_circle_return_health_percent":0.25,
	"dark_ritual_heroic_reduction_percent":0.05
}

const WORKING_NAMES := {
	"warlock_trait":"Life Tap", "warlock_q":"Fel Flame", "warlock_w":"Drain Life",
	"warlock_e":"Corruption", "warlock_l15_r1":"Horrify", "warlock_l15_r2":"Rain of Destruction",
	"warlock_l9_1":"Pursuit of Flame", "warlock_l9_2":"Chaotic Energy", "warlock_l9_3":"Echoed Corruption",
	"warlock_l12_1":"Health Funnel", "warlock_l12_2":"Improved Life Tap", "warlock_l12_3":"Consume Soul",
	"warlock_l18_1":"Bound by Shadow", "warlock_l18_2":"Curse of Exhaustion", "warlock_l18_3":"Hunger for Power",
	"warlock_l21_1":"Fel Armor", "warlock_l21_2":"Harvest Life", "warlock_l21_3":"Dark Bargain",
	"warlock_l24_1":"Rampant Hellfire", "warlock_l24_2":"Ruinous Affliction", "warlock_l24_3":"Darkness Within",
	"warlock_l27_r1":"Haunt", "warlock_l27_r2":"Deep Impact",
	"warlock_l30_1":"Demonic Circle", "warlock_l30_2":"Dark Ritual", "warlock_l30_3":"Soul Conduit"
}

const TALENT_DESCRIPTIONS := {
	"warlock_l9_1":"Quest: Hit 30 distinct qualifying enemies with Fel Flame during one encounter. Reward: future Fel Flames have 33% more area.",
	"warlock_l9_2":"Drain Life has 25% more cast and break range. Quest: complete 15 channels. Reward: later completions reduce eligible cooldowns by 10% of modified base cooldown.",
	"warlock_l9_3":"Quest: apply Corruption 40 times to add three reverse bursts. Mythic at 85: Corruption heals for 100% of actual damage dealt.",
	"warlock_l12_1":"Drain Life's cooldown recharges 100% faster during a valid channel. A target death refreshes Drain Life.",
	"warlock_l12_2":"Life Tap directly reduces eligible cooldowns by 40% of their modified base cooldown.",
	"warlock_l12_3":"A direct Fel Flame kill heals the Warlock. Internal cooldown: 50 seconds; reducible by Life Tap.",
	"warlock_l18_1":"Each distinct qualifying Fel Flame hit reduces Corruption's remaining cooldown by 1.75 seconds.",
	"warlock_l18_2":"Drain Life deals 50% more damage and Slows its target by 40% while tethered.",
	"warlock_l18_3":"Deal 15% more owned normal damage, receive 25% less healing, and take 15% more damage. Health costs and Shields are unchanged.",
	"warlock_l21_1":"Each distinct Fel Flame hit grants 50 universal Armor for 2.5 seconds. Stacks share and refresh one timer.",
	"warlock_l21_2":"Drain Life's raw healing is increased by 75%.",
	"warlock_l21_3":"Maximum Health increases by 40%, but every Warlock cooldown's modified base increases by 10%.",
	"warlock_l24_1":"Fel Flame casts that hit a qualifying target grant 12% Fel Flame damage for 5 seconds, up to 5 stacks. The triggering cast is not empowered by its new stack.",
	"warlock_l24_2":"Corruption's third and sixth bursts trigger Ruinous Affliction bonus damage using the corrected live value.",
	"warlock_l24_3":"After dealing 600 owned normal damage, the next Life Tap is free and grants 25% Q/W/E Power for 5 seconds.",
	"warlock_l27_r1":"Horrify's Fear lasts 1 second longer. Successfully Feared targets take 20% increased damage while Fear remains.",
	"warlock_l27_r2":"Rain impacts are 25% larger, Slow by 90% briefly, and use a 70% target-prioritized / 30% random meteor mix.",
	"warlock_l30_1":"Eligible lethal damage is fully prevented, then the Warlock is banished for 3 seconds and returns near an ally with at least 25% Health. Internal cooldown: 120 seconds; not reducible.",
	"warlock_l30_2":"A direct successful Life Tap also reduces the selected Heroic by 5% of its modified base cooldown.",
	"warlock_l30_3":"Drain Life becomes a background channel and permits one foreground Q, E, D, or selected Heroic action. Movement and Basic Attacks remain unavailable."
}

const TALENT_TIERS := [
	{"tier_id":"tier_1","tier_number":1,"unlock_level":9,"kind":"talent","option_ids":["warlock_l9_1","warlock_l9_2","warlock_l9_3"]},
	{"tier_id":"tier_2","tier_number":2,"unlock_level":12,"kind":"talent","option_ids":["warlock_l12_1","warlock_l12_2","warlock_l12_3"]},
	{"tier_id":"tier_3","tier_number":3,"unlock_level":15,"kind":"heroic","option_ids":["warlock_l15_r1","warlock_l15_r2"]},
	{"tier_id":"tier_4","tier_number":4,"unlock_level":18,"kind":"talent","option_ids":["warlock_l18_1","warlock_l18_2","warlock_l18_3"]},
	{"tier_id":"tier_5","tier_number":5,"unlock_level":21,"kind":"talent","option_ids":["warlock_l21_1","warlock_l21_2","warlock_l21_3"]},
	{"tier_id":"tier_6","tier_number":6,"unlock_level":24,"kind":"talent","option_ids":["warlock_l24_1","warlock_l24_2","warlock_l24_3"]},
	{"tier_id":"tier_7","tier_number":7,"unlock_level":27,"kind":"heroic_upgrade","option_ids":["warlock_l27_r1","warlock_l27_r2"],"heroic_requirements":{"warlock_l27_r1":"warlock_l15_r1","warlock_l27_r2":"warlock_l15_r2"}},
	{"tier_id":"tier_8","tier_number":8,"unlock_level":30,"kind":"capstone","option_ids":["warlock_l30_1","warlock_l30_2","warlock_l30_3"]}
]

const CLASS_DEFINITION := {
	"class_id":"warlock", "display_name":"Warlock", "primary_role":"DPS", "role":"DPS",
	"basic_action_id":"warlock_basic_attack", "trait_id":"warlock_trait",
	"q_ability_id":"warlock_q", "w_ability_id":"warlock_w", "e_ability_id":"warlock_e",
	"heroic_option_ids":["warlock_l15_r1","warlock_l15_r2"],
	"talent_tier_definitions":TALENT_TIERS, "ai_behavior_tags":["damage","ranged","periodic"],
	"color":Color("d16ca8"), "ability":"Fel Flame",
	"base_health":1700.0, "health_growth":0.04, "base_power":60.0, "power_growth":0.04,
	"base_armor":0.0, "basic_action_type":"attack", "basic_action_power_coefficient":1.0,
	"basic_action_interval":1.0, "basic_action_range":SPACE.basic_range,
	"movement_speed":SPACE.movement_speed, "base_critical_chance":0.05, "critical_damage":2.0,
	"health_regeneration":3.54, "threat_modifier":1.0, "basic_action_damage_type":"physical",
	"armor_family":"cloth", "armor_proficiency":"cloth", "weapon_proficiencies":["wand","focus","staff"],
	"ability_power_percent":0.0, "uses_mana":false, "resource_id":""
}

static func scale(level:int)->float:
	return pow(SCALE_PER_LEVEL, maxi(0, level - 1))

static func scaled(value:float, level:int)->float:
	return value * scale(level)
