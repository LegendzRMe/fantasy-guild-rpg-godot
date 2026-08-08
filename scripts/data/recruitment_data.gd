extends RefCounted

const AshwoodData = preload("res://scripts/data/ashwood_data.gd")

const CONFIG := {
	"max_hourly_budget":5,
	"candidate_capacity":1,
	"lock_capacity":1,
	"check_interval_minutes":60.0,
	"candidate_wait_minutes":180.0,
	"minimum_candidate_level":AshwoodData.RECRUITMENT_LEVEL_RANGE.minimum,
	"maximum_candidate_level":AshwoodData.RECRUITMENT_LEVEL_RANGE.maximum,
	"base_disclosure":12.0,
	"budget_disclosure_per_gold":11.0,
	"prestige_disclosure_per_rank":2.5,
	"disclosure_random_min":-10.0,
	"disclosure_random_max":10.0,
	"activity_log_limit":12,
	"real_seconds_per_game_minute":1.0
}

const ORIGIN_ZONE_ID := "ashwood_marches"
const ORIGIN_ZONE_NAME := "Ashwood Marches"
const BEGINNER_CLASS_IDS := ["guardian","cleric","rogue","ranger","mage","warlock"]
const NAMES := ["Adel","Bram","Cora","Dain","Elowen","Fenn","Galen","Hale","Iris","Jory","Kael","Lysa","Maren","Nell","Orin","Perrin","Quill","Rhea","Tamsin","Vale"]
const PERSONALITIES := {
	"open":{"display_name":"Open","disclosure_modifier":10.0},
	"measured":{"display_name":"Measured","disclosure_modifier":0.0},
	"guarded":{"display_name":"Guarded","disclosure_modifier":-10.0}
}
const REVEAL_ORDER := ["class","exact_level","profession","profession_level","positive_trait","equipment_summary","negative_trait","equipped_items","abilities_talents","title"]
const REVEAL_THRESHOLDS := {"class":15.0,"exact_level":25.0,"profession":35.0,"profession_level":45.0,"positive_trait":52.0,"equipment_summary":58.0,"negative_trait":68.0,"equipped_items":76.0,"abilities_talents":84.0,"title":94.0}

static func default_state() -> Dictionary:
	return {
		"tavern_name":"The Tavern","hourly_budget":0,"minutes_until_next_check":CONFIG.check_interval_minutes,"candidates":[],
		"activity_log":[],"next_candidate_id":1,"recruitment_level":1,
		"recruitment_officer_id":null,"recruitment_preference":null
	}
