extends RefCounted

const DEFEATED_RECOVERY_MINUTES := 10.0
const MINOR_INJURY_MINUTES := 20.0
const SERIOUS_INJURY_MINUTES := 60.0
const VOLUNTARY_REST_MINUTES := 10.0
const WELL_RESTED_DURATION_MINUTES := 60.0
const WELL_RESTED_TEMPORARY_HP_PERCENT := 0.10
const RECOVERY_MEAL_RATE_MULTIPLIER := 1.25
const RECOVERY_LOG_LIMIT := 20
const PREPARED_MEAL_LIMIT := 50

const MEALS := {
	"common_table_meal":{"display_name":"Common Table Meal","purpose":"rest","description":"Supports ten minutes of voluntary rest and grants Well Rested."},
	"restorative_broth":{"display_name":"Restorative Broth","purpose":"recovery","description":"Increases the recovery rate for one current stay."}
}

static func default_state() -> Dictionary:
	return {
		"recovery_cases":[],"rest_assignments":[],"prepared_meals":[],"next_meal_id":1,
		"activity_log":[],"paused_rest_progress":{}
	}
