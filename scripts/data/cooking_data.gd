extends RefCounted

# Cooking is intentionally data-driven.  The Tavern expansion may tune these
# values without changing profession, recruitment, recovery, or combat code.
const SAVE_VERSION := 1
const FAMILIAR_OFFER_DISCOUNT := 0.10
const FAMILIAR_OFFER_MAX_WAIT_MINUTES := 5.0
const REST_DURATION_MINUTES := 10.0
const DEFAULT_MEAL_DURATION_MINUTES := 60.0
const QUICK_RECOVERY_MULTIPLIER := 1.25
const SECOND_COURSE_EFFECT_SCALE := 0.50
const FEAST_SERVINGS := 6
const FEAST_DURATION_MINUTES := 180.0
const RANK_REQUIREMENTS := {
	1:{"xp":20,"prestige_rank":0,"milestones":["profession_introduction"]},
	2:{"xp":75,"prestige_rank":1,"milestones":["first_order"]},
	3:{"xp":175,"prestige_rank":2,"milestones":["pattern_mastered"]},
	4:{"xp":350,"prestige_rank":3,"milestones":["advanced_work"]},
	5:{"xp":600,"prestige_rank":4,"milestones":["signature_work"]}
}

const PROFESSION_CHOICES := [
	[{"id":"cooking_familiar_offer","style":0,"name":"Familiar Offer","description":"After a patron eats and completes a refresh, offer a 10% signing discount during their final five minutes."},{"id":"cooking_rested_and_ready","style":1,"name":"Rested and Ready","description":"Unlock mission meals and voluntary Tavern rest."}],
	[{"id":"cooking_table_talk","style":0,"name":"Table Talk","description":"Once per eligible patron, ask about one information category with full, partial, or guarded results."},{"id":"cooking_care_route","style":1,"name":"Care Route","description":"Choose Quick Recovery or Complete Rest for an injured Hero."}],
	[{"id":"cooking_campaign_menus","style":0,"name":"Campaign Menus","description":"Prepare one of four candidate-development dishes for a recruitment campaign hook."},{"id":"cooking_mission_meals","style":1,"name":"Mission Meals","description":"Prepare Fortifying, Hefty, Fatty, and Hasty meals for the next mission."}],
	[{"id":"cooking_room_and_board","style":0,"name":"Room & Board","description":"A locked patron can continue one meal-backed development opportunity per refresh."},{"id":"cooking_second_course","style":1,"name":"Second Course","description":"After a full rest, add a different reduced-strength meal effect."}],
	[{"id":"cooking_house_banquet","style":0,"name":"House Banquet","description":"Offer two selected campaign dishes as a multi-serving Tavern service."},{"id":"cooking_guild_feast","style":1,"name":"Guild Feast","description":"Offer two selected mission meals as a multi-serving guild service."}]
]

const COMMITMENTS := {
	"house_favorite":{"display_name":"House Favorite","description":"Four or five Hospitality choices; designate one locked patron and guide campaign-menu emphasis."},
	"special_guest":{"display_name":"Special Guest","description":"Four or five Guild Care choices; designate one Hero and select one Chef's Touch prototype."},
	"kitchen_improviser":{"display_name":"Kitchen Improviser","description":"A three/two split; once per Tavern refresh, convert one prepared meal to another known meal of the same category and tier."}
}

const MEALS := {
	"common_table_meal":{"display_name":"Common Table Meal","category":"guild_care","tier":1,"purpose":"rest","effect":{"temporary_hp_percent":0.10}},
	"restorative_broth":{"display_name":"Restorative Broth","category":"guild_care","tier":2,"purpose":"quick_recovery","effect":{"recovery_rate_multiplier":QUICK_RECOVERY_MULTIPLIER}},
	"adventurers_supper":{"display_name":"Adventurer's Supper","category":"hospitality","tier":3,"purpose":"candidate","development":"class_xp"},
	"hearthside_gathering":{"display_name":"Hearthside Gathering","category":"hospitality","tier":3,"purpose":"candidate","development":"disclosure"},
	"craftsfolks_table":{"display_name":"Craftsfolk's Table","category":"hospitality","tier":3,"purpose":"candidate","development":"profession_xp"},
	"travellers_welcome":{"display_name":"Traveller's Welcome","category":"hospitality","tier":3,"purpose":"candidate","development":"trait"},
	"fortifying_meal":{"display_name":"Fortifying Meal","category":"guild_care","tier":3,"purpose":"mission","effect":{"temporary_hp_percent":0.10}},
	"hefty_meal":{"display_name":"Hefty Meal","category":"guild_care","tier":3,"purpose":"mission","effect":{"damage_multiplier":1.08}},
	"fatty_meal":{"display_name":"Fatty Meal","category":"guild_care","tier":3,"purpose":"mission","effect":{"armor":15.0}},
	"hasty_meal":{"display_name":"Hasty Meal","category":"guild_care","tier":3,"purpose":"mission","effect":{"movement_speed":10.0,"basic_action_speed":0.08}},
	"house_banquet":{"display_name":"House Banquet","category":"hospitality","tier":5,"purpose":"service"},
	"guild_feast":{"display_name":"Guild Feast","category":"guild_care","tier":5,"purpose":"service"}
	,"simple_stew":{"display_name":"Simple Stew","category":"guild_care","tier":1,"purpose":"rest","effect":{"health_multiplier":1.05},"description":"A cheap meal granting 5% maximum Health for the next mission."}
	,"recovery_broth_hook":{"display_name":"Recovery Broth","category":"guild_care","tier":1,"purpose":"recovery_hook","effect":{"recovery_rate_multiplier":1.10},"description":"Stored for future Recovery Wing meal requests."}
	,"recruiters_platter":{"display_name":"Recruiter's Platter","category":"hospitality","tier":1,"purpose":"recruitment","effect":{"food_sales_multiplier":1.10},"description":"Adds 10% to Level 2 campaign food and drink sales while stocked."}
	,"expedition_rations":{"display_name":"Expedition Rations","category":"guild_care","tier":1,"purpose":"mission","effect":{"damage_multiplier":1.05},"description":"Grants 5% increased damage for the next mission after rest."}
}

const CHEFS_TOUCHES := {
	"second_wind":{"display_name":"Second Wind","description":"Prototype: gain a small shield when meal temporary HP is depleted."},
	"final_bite":{"display_name":"Final Bite","description":"Prototype: the first damaging class ability gains a small damage bonus."},
	"heavy_stomach":{"display_name":"Heavy Stomach","description":"Prototype: reduce one physical hit after the meal's protection is gone."},
	"quick_start":{"display_name":"Quick Start","description":"Prototype: the first damaging class ability briefly hastens the Hero."}
}

static func default_state() -> Dictionary:
	return {"refresh_serial":0,"active_campaign_menu":{},"active_house_banquet":{},"active_guild_feast":{},"house_favorite_candidate_id":"","special_guest_hero_id":"","activity_log":[]}

static func meal(meal_id:String) -> Dictionary:
	return MEALS.get(meal_id,{})

static func commitment(progress:Dictionary) -> String:
	if int(progress.get("profession_rank",0))<5 or progress.get("profession_choices",{}).size()<5:return ""
	var scores:Array=progress.get("profession_specialization_score",[0,0])
	if int(scores[0])>=4:return "house_favorite"
	if int(scores[1])>=4:return "special_guest"
	return "kitchen_improviser"
