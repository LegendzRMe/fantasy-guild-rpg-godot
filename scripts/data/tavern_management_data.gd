extends RefCounted

const SAVE_VERSION := 1
const MIN_LEVEL := 1
const MAX_TEST_LEVEL := 2
const STEWARD_UNLOCK_LEVEL := 3
const REST_SLOT_COUNT := {1:2,2:2,3:3,4:4,5:5}
const REST_DURATION_MINUTES := 10.0
const AUTOMATION_RECIPE_SECONDS_TO_GAME_MINUTES := 0.20
const MAX_STOCK_TARGET := 20
const HOST_BONUS_MULTIPLIER := 1.0
const STAY_FEE_BASE_PER_HOUR := 0.75
const STAY_FEE_PER_CANDIDATE_LEVEL := 0.12
const STAY_FEE_PER_TAVERN_LEVEL := 0.18
const CAMPAIGN_DURATION_MINUTES := 180.0
const FOOD_SALES_HOURLY_FRACTION := 0.035
const FOOD_SALES_GROSS_CAP_FRACTION := 0.22
const MANUAL_MARKER_SPEED := 0.42
const PERFECT_HALF_WIDTH := 0.10
const COOKED_HALF_WIDTH := 0.34

const CAMPAIGNS := {
	"local_notice":{"display_name":"Local Notice","gross_cost":50,"budget":1,"quality_note":"Basic local interest."},
	"guild_call":{"display_name":"Guild Call","gross_cost":150,"budget":3,"quality_note":"A broader call for beginner adventurers."},
	"grand_recruitment":{"display_name":"Grand Recruitment","gross_cost":300,"budget":5,"quality_note":"The strongest campaign available in the testing region."}
}

const PROTOTYPE_RECIPES := [
	"cooking_simple_stew","cooking_recovery_broth_hook","cooking_recruiters_platter","cooking_expedition_rations"
]

static func default_state() -> Dictionary:
	return {
		"tavern_level":1,
		"assignments":{"host_id":"","chef_id":"","steward_id":""},
		"selected_rest_meal_id":"",
		"rest_slots":[{"slot_id":0,"hero_id":""},{"slot_id":1,"hero_id":""}],
		"automation":{"recipe_id":"","stock_target":0,"remaining_game_minutes":0.0,"ingredients_reserved":false,"status":"Stopped"},
		"manual_cooking":{"active":false,"recipe_id":"","chef_id":"","marker":0.0,"direction":1.0,"ingredients_consumed":false},
		"campaign":{"active":false},
		"last_campaign_report":{},
		"lifetime_food_sales":0.0,
		"lifetime_staying_fees":0.0,
		"activity_log":[]
	}

static func rest_slot_count(level:int) -> int:
	return int(REST_SLOT_COUNT.get(clampi(level,1,5),2))
