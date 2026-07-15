extends RefCounted

const AshwoodManager = preload("res://scripts/systems/ashwood_manager.gd")
const LEGACY_SAVE_PATH := "user://guild_save.json"

static func save_slot_path(slot:int) -> String:
	return "user://guild_save_%d.json" % (slot+1)

static func resolved_load_path(slot:int) -> String:
	var path:=save_slot_path(slot)
	if slot==0 and not FileAccess.file_exists(path) and FileAccess.file_exists(LEGACY_SAVE_PATH):
		return LEGACY_SAVE_PATH
	return path

static func slot_state(slot:int) -> Dictionary:
	var path:=resolved_load_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func default_casting_settings() -> Dictionary:
	return {"pc":{"ground":"cursor","directional":"cursor","area":"instant","enemy":"target","ally":"target"},"mobile":{"ground":"facing","directional":"facing","area":"instant","enemy":"target","ally":"target"}}

static func fresh_state() -> Dictionary:
	return {"guild_name":"", "faction":"Unaffiliated", "guild_prestige_rank":1, "guild_renown":0, "tutorial_complete":false, "major_systems_unlocked":false, "seen_page_intros":{}, "zone0":AshwoodManager.default_progress(), "casting_settings":default_casting_settings(), "gold":0, "ore":8, "herbs":8, "dust":4, "tokens":0, "vault_level":1, "vault_limit":30, "dungeon_clears":[0,0], "zone_progress":[0,0], "zone_branches":[[false,false],[false,false]], "unlocked_dungeon":0, "selected_team":[0,1], "active_team":[0,1], "saved_teams":[[],[],[],[],[]], "team_names":["Team 1","Team 2","Team 3","Team 4","Team 5"], "heroes":[
		{"name":"Brann", "class":"Guardian", "level":1, "xp":0, "gear":10, "equipment":[], "member_type":"founding_recruit", "is_special_hero":false, "legacy_rank":0},
		{"name":"Sera", "class":"Cleric", "level":1, "xp":0, "gear":10, "equipment":[], "member_type":"founding_recruit", "is_special_hero":false, "legacy_rank":0}
	]}

static func testing_state() -> Dictionary:
	var state:=fresh_state()
	state.merge({
		"guild_name":"Testing Guild",
		"guild_prestige_rank":10,
		"guild_renown":1000,
		"tutorial_complete":true,
		"major_systems_unlocked":true,
		"zone0":AshwoodManager.testing_progress(),
		"gold":9999,
		"ore":999,
		"herbs":999,
		"dust":999,
		"tokens":99,
		"vault_level":6,
		"vault_limit":180,
		"dungeon_clears":[3,3],
		"zone_progress":[10,10],
		"zone_branches":[[true,true],[true,true]],
		"unlocked_dungeon":1,
		"selected_team":[0,1,2,3],
		"active_team":[0,1,2,3],
		"saved_teams":[[0,1,2,3],[],[],[],[]],
		"heroes":[
			{"name":"Brann", "class":"Guardian", "level":4, "xp":0, "gear":16, "equipment":[], "member_type":"founding_recruit", "is_special_hero":false, "legacy_rank":0},
			{"name":"Sera", "class":"Cleric", "level":4, "xp":0, "gear":16, "equipment":[], "member_type":"founding_recruit", "is_special_hero":false, "legacy_rank":0},
			{"name":"Wren", "class":"Ranger", "level":4, "xp":0, "gear":16, "equipment":[], "member_type":"guild_recruit", "is_special_hero":false, "legacy_rank":0},
			{"name":"Nyx", "class":"Mage", "level":4, "xp":0, "gear":16, "equipment":[], "member_type":"guild_recruit", "is_special_hero":false, "legacy_rank":0},
			{"name":"Kestrel", "class":"Rogue", "level":4, "xp":0, "gear":16, "equipment":[], "member_type":"guild_recruit", "is_special_hero":false, "legacy_rank":0},
			{"name":"Morrow", "class":"Warlock", "level":4, "xp":0, "gear":16, "equipment":[], "member_type":"guild_recruit", "is_special_hero":false, "legacy_rank":0},
			{"name":"Aldren Vale", "class":"Guardian", "level":4, "xp":0, "gear":18, "equipment":[], "member_type":"special_hero", "is_special_hero":true, "legacy_rank":1, "signature_ability":"Oath of Cinders", "story_lead":"The traitor's broken oath-seal"},
			{"name":"Mira Thorn", "class":"Ranger", "level":4, "xp":0, "gear":18, "equipment":[], "member_type":"special_hero", "is_special_hero":true, "legacy_rank":1, "signature_ability":"Ghostmark Volley", "story_lead":"Unnatural tracks leaving Ashwood"},
			{"name":"Ilyra Voss", "class":"Mage", "level":4, "xp":0, "gear":18, "equipment":[], "member_type":"special_hero", "is_special_hero":true, "legacy_rank":1, "signature_ability":"Runebreak", "story_lead":"The force inside the servant's runes"}
		]
	},true)
	return state

static func load_state(slot:int) -> Dictionary:
	var state:=fresh_state()
	var save_declared_tutorial:=false
	var save_declared_major_systems:=false
	var path:=resolved_load_path(slot)
	if FileAccess.file_exists(path):
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			save_declared_tutorial=parsed.has("tutorial_complete")
			save_declared_major_systems=parsed.has("major_systems_unlocked")
			state.merge(parsed,true)
			if not save_declared_major_systems:
				state.erase("major_systems_unlocked")
	return migrate_state(state,save_declared_tutorial)

static func migrate_state(state:Dictionary, save_declared_tutorial:bool) -> Dictionary:
	if state.guild_name!="" and not save_declared_tutorial:
		state["tutorial_complete"]=true
	if not state.has("active_team"):
		state["active_team"]=state.selected_team.duplicate()
	if not state.has("saved_teams"):
		state["saved_teams"]=[[],[],[],[],[]]
	if not state.has("team_names"):
		state["team_names"]=["Team 1","Team 2","Team 3","Team 4","Team 5"]
	if not state.has("zone_progress"):
		state["zone_progress"]=[0,0]
	if not state.has("zone_branches"):
		state["zone_branches"]=[[false,false],[false,false]]
	if not state.has("guild_prestige_rank"):
		state["guild_prestige_rank"]=1
	if not state.has("guild_renown"):
		state["guild_renown"]=0
	if not state.has("faction"):
		state["faction"]="Unaffiliated"
	if not state.has("major_systems_unlocked"):
		state["major_systems_unlocked"]=state.heroes.size()>=4
	if not state.has("seen_page_intros") or not state.seen_page_intros is Dictionary:
		state["seen_page_intros"]={}
	if not state.has("zone0"):
		state["zone0"]=AshwoodManager.testing_progress() if state.heroes.size()>=4 else AshwoodManager.default_progress()
	else:
		state["zone0"]=AshwoodManager.migrate_progress(state.zone0)
	if bool(state.get("tutorial_complete",false)):
		state.zone0.heroes_unlocked=true
	if not state.has("casting_settings"):
		state["casting_settings"]=default_casting_settings()
	else:
		var casting_defaults:=default_casting_settings()
		for device in casting_defaults:
			if not state.casting_settings.has(device):
				state.casting_settings[device]=casting_defaults[device].duplicate(true)
			else:
				for category in casting_defaults[device]:
					if not state.casting_settings[device].has(category):
						state.casting_settings[device][category]=casting_defaults[device][category]
	for hero in state.heroes:
		if not hero.has("member_type"):
			hero["member_type"]="founding_recruit"
		if not hero.has("is_special_hero"):
			hero["is_special_hero"]=false
		if not hero.has("legacy_rank"):
			hero["legacy_rank"]=0
		if not hero.has("equipment"):
			hero["equipment"]=[]
	return state

static func save_state(slot:int, state:Dictionary) -> void:
	var file:=FileAccess.open(save_slot_path(slot),FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state))

static func delete_slot(slot:int) -> void:
	var slot_path:=save_slot_path(slot)
	if FileAccess.file_exists(slot_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path))
	if slot==0 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH))
