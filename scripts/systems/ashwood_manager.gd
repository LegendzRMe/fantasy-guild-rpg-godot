extends RefCounted

const AshwoodData = preload("res://scripts/data/ashwood_data.gd")

static func encounter_status(optional:bool=false) -> Dictionary:
	return {"unlocked":false,"first_clear_completed":false,"replay_count":0,"best_result":"","optional":optional,"current_loot_table":"base","rare_spawn_enabled":false,"decision":""}

static func default_progress() -> Dictionary:
	var encounters:={}
	for encounter_id in AshwoodData.all_encounter_ids():
		encounters[encounter_id]=encounter_status(encounter_id in AshwoodData.OPTIONAL_ORDER)
	encounters["first_battle"].unlocked=true
	return {
		"zone0_unlocked":true,"zone0_boss_defeated":false,
		"first_recruit_choice":"","approach_choice":"","merchant_decision":"",
		"merchant_helped":false,"raiders_chased":false,
		"vault_unlocked":false,"heroes_unlocked":false,"party_management_unlocked":false,
		"optional_available":false,"optional_clue":false,"optional_branch_discovered":false,
		"optional_branch_completed":false,"optional_mini_boss_defeated":false,
		"second_recruit_choice":"","special_hero_choice":"",
		"encounters":encounters,"inventory":[],"next_item_id":1
	}

static func testing_progress() -> Dictionary:
	var progress:=default_progress()
	progress.merge({"zone0_boss_defeated":true,"first_recruit_choice":"ranger","approach_choice":"investigate","merchant_decision":"chased","raiders_chased":true,"vault_unlocked":true,"heroes_unlocked":true,"party_management_unlocked":true,"optional_available":true,"optional_clue":true,"optional_branch_discovered":true,"optional_branch_completed":true,"optional_mini_boss_defeated":true,"second_recruit_choice":"mage","special_hero_choice":"survivor_a"},true)
	for encounter_id in progress.encounters:
		progress.encounters[encounter_id].unlocked=true
		progress.encounters[encounter_id].first_clear_completed=true
		progress.encounters[encounter_id].replay_count=1
		progress.encounters[encounter_id].best_result="victory"
		progress.encounters[encounter_id].rare_spawn_enabled=true
	return progress

static func migrate_progress(value) -> Dictionary:
	var progress:=default_progress()
	if value is Dictionary:
		var incoming:Dictionary=value
		for key in incoming:
			if key!="encounters":progress[key]=incoming[key]
		if incoming.get("encounters") is Dictionary:
			for encounter_id in progress.encounters:
				if incoming.encounters.get(encounter_id) is Dictionary:
					progress.encounters[encounter_id].merge(incoming.encounters[encounter_id],true)
	return progress

static func encounter_is_unlocked(progress:Dictionary,encounter_id:String) -> bool:
	return bool(progress.encounters.get(encounter_id,{}).get("unlocked",false))

static func encounter_is_completed(progress:Dictionary,encounter_id:String) -> bool:
	return bool(progress.encounters.get(encounter_id,{}).get("first_clear_completed",false))

static func unlock_encounter(progress:Dictionary,encounter_id:String) -> bool:
	if not progress.encounters.has(encounter_id) or progress.encounters[encounter_id].unlocked:return false
	progress.encounters[encounter_id].unlocked=true
	return true

static func mark_victory(progress:Dictionary,encounter_id:String) -> bool:
	var status:Dictionary=progress.encounters[encounter_id]
	var first_clear:=not bool(status.first_clear_completed)
	status.first_clear_completed=true
	status.replay_count=int(status.replay_count)+1
	status.best_result="victory"
	if encounter_id=="ruined_chapel":
		progress.optional_branch_completed=true
		unlock_encounter(progress,"rune_servant")
	elif encounter_id=="rune_servant":
		progress.optional_mini_boss_defeated=true
	elif encounter_id=="second_recruit":unlock_encounter(progress,"crossing")
	elif encounter_id=="crossing":unlock_encounter(progress,"finale")
	elif encounter_id=="finale":
		progress.zone0_boss_defeated=true
		for id in progress.encounters:
			if progress.encounters[id].first_clear_completed:progress.encounters[id].rare_spawn_enabled=true
	return first_clear

static func apply_decision(progress:Dictionary,encounter_id:String,decision_id:String) -> Dictionary:
	var encounter:Dictionary=AshwoodData.encounter(encounter_id,progress)
	for decision in encounter.get("decisions",[]):
		if decision.id!=decision_id:continue
		progress.encounters[encounter_id].decision=decision_id
		var effects:Dictionary=decision.get("effects",{})
		for key in effects:
			if key=="unlock":
				for target in effects[key]:unlock_encounter(progress,target)
			else:progress[key]=effects[key]
		return decision
	return {}

static func discover_optional_branch(progress:Dictionary) -> bool:
	if not progress.optional_available or progress.optional_branch_discovered:return false
	progress.optional_branch_discovered=true
	return unlock_encounter(progress,"ruined_chapel")

static func finale_opening_roles(progress:Dictionary) -> Array:
	var first="Controlled Rogue" if progress.first_recruit_choice=="ranger" else "Controlled Ranger"
	var second="Controlled Warlock" if progress.second_recruit_choice=="mage" else "Controlled Mage"
	return [first,second]
