extends RefCounted

const DEFAULT_SCROLL_POSITION := 390.0
const STARTING_UNLOCKED_ROOMS := ["public_entrance", "great_hall", "command_table", "infirmary", "front_gate", "guild_storage", "combat_hall"]
const OPTIONAL_ROOM_IDS := ["tavern", "trading_post", "workshop", "council_chamber", "lower_locked_3", "lower_locked_4"]

static func room_definitions() -> Array:
	return [
		{"id":"public_entrance", "name":"PUBLIC ENTRANCE", "description":"Visitors and applicants enter here.", "zone":"public", "position":Vector2(28,145), "size":Vector2(160,250), "unlocked":true, "newly_available":false, "target_screen":"tooltip", "icon":"IN", "future_system":true},
		{"id":"tavern", "name":"TAVERN", "description":"Welcome patrons, inspect applicants, and recruit members.", "zone":"public", "position":Vector2(205,18), "size":Vector2(360,180), "unlocked":false, "newly_available":false, "target_screen":"tavern", "icon":"T", "future_system":false},
		{"id":"trading_post", "name":"TRADING POST", "description":"Buy, sell, and meet merchants.", "zone":"public", "position":Vector2(205,215), "size":Vector2(360,205), "unlocked":false, "newly_available":false, "target_screen":"market", "icon":"TP", "future_system":false},
		{"id":"front_gate", "name":"FRONT GATE / BATTLE", "description":"Main entrance and expedition departure.", "zone":"core", "position":Vector2(690,18), "size":Vector2(280,82), "unlocked":true, "newly_available":false, "target_screen":"battle", "icon":"FG", "future_system":false},
		{"id":"great_hall", "name":"GREAT HALL", "description":"View guild members and heroes.", "zone":"core", "position":Vector2(615,118), "size":Vector2(430,160), "unlocked":true, "newly_available":false, "target_screen":"roster", "icon":"GH", "future_system":false},
		{"id":"command_table", "name":"COMMAND TABLE", "description":"Missions and guild orders.", "zone":"core", "position":Vector2(615,298), "size":Vector2(205,205), "unlocked":true, "newly_available":false, "target_screen":"command", "icon":"CT", "future_system":false},
		{"id":"infirmary", "name":"COUNCIL CHAMBER", "description":"Track factions, permanent outcomes, and rival guilds.", "zone":"core", "position":Vector2(838,298), "size":Vector2(207,205), "unlocked":true, "newly_available":false, "target_screen":"council", "icon":"CC", "future_system":false},
		{"id":"guild_storage", "name":"GUILD STORAGE", "description":"Protected Vault and Workshop-ready Depot.", "zone":"production", "position":Vector2(1090,118), "size":Vector2(250,200), "unlocked":true, "newly_available":false, "target_screen":"storage", "icon":"GS", "future_system":false},
		{"id":"workshop", "name":"WORKSHOP / AUTOMATION WING", "description":"Build, automate, and produce.", "zone":"production", "position":Vector2(1418,18), "size":Vector2(760,402), "unlocked":false, "newly_available":false, "target_screen":"workshop", "icon":"W", "future_system":true},
		{"id":"council_chamber", "name":"LOCKED ROOM", "description":"Purpose not yet determined.", "zone":"expansion", "position":Vector2(390,530), "size":Vector2(190,105), "unlocked":false, "newly_available":false, "target_screen":"locked", "icon":"X", "future_system":true},
		{"id":"combat_hall", "name":"COMBAT HALL", "description":"Practice ranges, guildmate scrimmages, raids, and arenas.", "zone":"expansion", "position":Vector2(595,530), "size":Vector2(190,105), "unlocked":true, "newly_available":false, "target_screen":"combat_hall", "icon":"CH", "future_system":false},
		{"id":"lower_locked_3", "name":"LOCKED ROOM", "description":"Purpose not yet determined.", "zone":"expansion", "position":Vector2(800,530), "size":Vector2(230,105), "unlocked":false, "newly_available":false, "target_screen":"locked", "icon":"X", "future_system":true},
		{"id":"lower_locked_4", "name":"LOCKED ROOM", "description":"Purpose not yet determined.", "zone":"expansion", "position":Vector2(1418,530), "size":Vector2(330,105), "unlocked":false, "newly_available":false, "target_screen":"locked", "icon":"X", "future_system":true}
	]

static func default_room_unlocks() -> Dictionary:
	var unlocks:Dictionary = {}
	for room_id in STARTING_UNLOCKED_ROOMS:
		unlocks[room_id] = true
	return unlocks

static func ensure_state(state:Dictionary) -> void:
	if not state.get("guild_hall_room_unlocks") is Dictionary:
		state["guild_hall_room_unlocks"] = default_room_unlocks()
	else:
		if not state.guild_hall_room_unlocks.has("guild_storage"):
			state.guild_hall_room_unlocks["guild_storage"] = bool(state.guild_hall_room_unlocks.get("guild_vault",true)) or bool(state.guild_hall_room_unlocks.get("materials_depot",false))
		for room_id in STARTING_UNLOCKED_ROOMS:
			if not state.guild_hall_room_unlocks.has(room_id):state.guild_hall_room_unlocks[room_id] = true
	state.guild_hall_room_unlocks["combat_hall"] = true
	state.guild_hall_room_unlocks["council_chamber"] = false
	if not state.get("guild_hall_new_rooms") is Array:state["guild_hall_new_rooms"] = []
	if "guild_vault" in state.guild_hall_new_rooms or "materials_depot" in state.guild_hall_new_rooms:
		state.guild_hall_new_rooms.erase("guild_vault");state.guild_hall_new_rooms.erase("materials_depot")
		if "guild_storage" not in state.guild_hall_new_rooms:state.guild_hall_new_rooms.append("guild_storage")
	if "ready_room" in state.guild_hall_new_rooms:
		state.guild_hall_new_rooms.erase("ready_room")
		if "infirmary" not in state.guild_hall_new_rooms:state.guild_hall_new_rooms.append("infirmary")
	for retired_room_id in ["training_yard","locked_room","future_expansion"]:state.guild_hall_new_rooms.erase(retired_room_id)
	if not state.has("guild_hall_scroll_position"):state["guild_hall_scroll_position"] = DEFAULT_SCROLL_POSITION
	if not state.has("guild_hall_tutorial_step"):state["guild_hall_tutorial_step"] = 0
	if not state.has("guild_hall_tutorial_complete"):state["guild_hall_tutorial_complete"] = false
	if not state.has("guild_hall_scroll_hint_dismissed"):state["guild_hall_scroll_hint_dismissed"] = false
