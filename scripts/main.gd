extends Node2D

const W := 1280.0
const H := 720.0
const SAVE_PATH := "user://guild_save.json"
const C_BG := Color("101827")
const C_PANEL := Color("1b2940")
const C_PANEL_2 := Color("243652")
const C_GOLD := Color("f5c451")
const C_TEXT := Color("e9f1ff")
const C_MUTED := Color("9fb1ca")
const C_GREEN := Color("54d69a")
const C_RED := Color("ef6571")
const CLASSES := {
	"Guardian": {"role":"Tank", "color":Color("5fa8ff"), "hp":230.0, "damage":15.0, "range":55.0, "ability":"Shield Wall"},
	"Cleric": {"role":"Healer", "color":Color("ffd86a"), "hp":150.0, "damage":10.0, "range":150.0, "ability":"Radiant Mend"},
	"Ranger": {"role":"DPS", "color":Color("65dc89"), "hp":165.0, "damage":24.0, "range":210.0, "ability":"Volley"},
	"Mage": {"role":"DPS", "color":Color("b381ff"), "hp":135.0, "damage":29.0, "range":190.0, "ability":"Arc Burst"}
}
const ABILITIES := {
	"Guardian": ["Shield Wall", "Challenge", "Shield Rush", "Last Bastion"],
	"Cleric": ["Radiant Mend", "Sanctuary", "Purifying Light", "Divine Renewal"],
	"Ranger": ["Piercing Shot", "Quickstep", "Volley", "Arrowstorm"],
	"Mage": ["Arc Bolt", "Blink", "Arc Burst", "Starfall"]
}
const TRAITS := {"Guardian":"Bulwark","Cleric":"Grace","Ranger":"Keen Eye","Mage":"Arcane Echo"}

var state := {}
var screen := "menu"
var ui := Control.new()
var combat_layer := Node2D.new()
var heroes := []
var enemies := []
var effects := []
var selected := 0
var dragging_hero := false
var drag_cursor := Vector2.ZERO
var drag_target_type := "ground"
var drag_target_index := -1
var team_dragging := false
var team_drag_index := -1
var team_drag_origin := ""
var team_active_zone: Control = null
var team_reserve_zone: Control = null
var team_drag_preview: Button = null
var team_roster_page := 0
var team_swipe_start := Vector2.ZERO
var team_swiping := false
var team_inspect_candidate := -1
var team_inspect_time := 0.0
var hero_search := ""
var hero_role_filter := "All roles"
var hero_class_filter := "All classes"
var roster_sort := "Name"
var roster_descending := false
var selected_roster_index := 0
var hero_roster_page := 0
var selected_profession := 0
var selected_mission := 0
var current_team_slot := -1
var current_save_slot := 0
var battle_time := 0.0
var spawn_timer := 0.0
var battle_over := false
var paused := false
var dungeon_id := 0
var encounter_id := 0
var wave_index := 0
var total_waves := 3
var wave_spawn_remaining := 0
var wave_break := 0.0
var waiting_wave := false
var victory_sequence := false
var victory_phase := 0
var victory_timer := 0.0
var world_map_view:Control = null
var world_map_content:Control = null
var world_map_zoom := 0.84
var world_map_pan := Vector2.ZERO
var world_map_dragging := false
var world_map_touches := {}
var toast := ""
var toast_time := 0.0

func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	ui.theme=build_ui_theme()
	ui.position = Vector2.ZERO
	ui.size = Vector2(W, H)
	add_child(combat_layer)
	add_child(ui)
	load_game()
	show_menu()

func ui_box(color:Color,radius:int=8,border_color:Color=Color.TRANSPARENT,border_width:int=0) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new(); box.bg_color=color; box.corner_radius_top_left=radius; box.corner_radius_top_right=radius; box.corner_radius_bottom_left=radius; box.corner_radius_bottom_right=radius
	box.border_color=border_color; box.border_width_left=border_width; box.border_width_right=border_width; box.border_width_top=border_width; box.border_width_bottom=border_width
	box.content_margin_left=14; box.content_margin_right=14; box.content_margin_top=10; box.content_margin_bottom=10; return box

func build_ui_theme() -> Theme:
	var theme:=Theme.new()
	theme.set_stylebox("normal","Button",ui_box(Color("202b3b"),8,Color("35445a"),1)); theme.set_stylebox("hover","Button",ui_box(Color("2b3b52"),8,C_GOLD,1)); theme.set_stylebox("pressed","Button",ui_box(Color("172131"),8,C_GOLD,2)); theme.set_stylebox("focus","Button",ui_box(Color.TRANSPARENT,8,C_GOLD,2)); theme.set_stylebox("disabled","Button",ui_box(Color("182231"),8,Color("2b394d"),1))
	theme.set_color("font_color","Button",C_TEXT); theme.set_color("font_hover_color","Button",Color.WHITE); theme.set_color("font_pressed_color","Button",C_GOLD); theme.set_color("font_disabled_color","Button",Color("7f8da1"))
	theme.set_stylebox("normal","LineEdit",ui_box(Color("131c29"),7,Color("35445a"),1)); theme.set_stylebox("focus","LineEdit",ui_box(Color("131c29"),7,C_GOLD,2)); theme.set_color("font_placeholder_color","LineEdit",C_MUTED)
	theme.set_stylebox("panel","Panel",ui_box(Color("162131"),12,Color("2d3b50"),1)); theme.set_font_size("font_size","Button",16); theme.set_font_size("font_size","LineEdit",16); return theme

func save_slot_path(slot:int) -> String:
	return "user://guild_save_%d.json" % (slot+1)

func slot_state(slot:int) -> Dictionary:
	var path=save_slot_path(slot)
	if slot==0 and not FileAccess.file_exists(path) and FileAccess.file_exists(SAVE_PATH): path=SAVE_PATH
	if not FileAccess.file_exists(path): return {}
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func fresh_state() -> Dictionary:
	return {"guild_name":"", "faction":"Ember Compact", "gold":180, "ore":8, "herbs":8, "dust":4, "tokens":0, "vault_level":1, "vault_limit":30, "dungeon_clears":[0,0], "zone_progress":[0,0], "zone_branches":[[false,false],[false,false]], "unlocked_dungeon":0, "selected_team":[0,1,2,3], "active_team":[0,1,2,3], "saved_teams":[[],[],[],[],[]], "team_names":["Team 1","Team 2","Team 3","Team 4","Team 5"], "heroes":[
		{"name":"Brann", "class":"Guardian", "level":1, "xp":0, "gear":10},
		{"name":"Sera", "class":"Cleric", "level":1, "xp":0, "gear":10},
		{"name":"Wren", "class":"Ranger", "level":1, "xp":0, "gear":10},
		{"name":"Nyx", "class":"Mage", "level":1, "xp":0, "gear":10}
	]}

func load_game() -> void:
	state = fresh_state()
	var path=save_slot_path(current_save_slot)
	if current_save_slot==0 and not FileAccess.file_exists(path) and FileAccess.file_exists(SAVE_PATH): path=SAVE_PATH
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary: state.merge(parsed, true)
	if not state.has("active_team"):
		state["active_team"] = state.selected_team.duplicate()
	if not state.has("saved_teams"):
		state["saved_teams"] = [[],[],[],[],[]]
	if not state.has("team_names"):
		state["team_names"] = ["Team 1","Team 2","Team 3","Team 4","Team 5"]
	if not state.has("zone_progress"):
		state["zone_progress"]=[0,0]
	if not state.has("zone_branches"):
		state["zone_branches"]=[[false,false],[false,false]]

func persist_current_team() -> void:
	if current_team_slot < 0: state.active_team=state.selected_team.duplicate()
	else: state.saved_teams[current_team_slot]=state.selected_team.duplicate()
	save_game()

func save_game() -> void:
	var f := FileAccess.open(save_slot_path(current_save_slot), FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(state))

func open_save_slot(slot:int) -> void:
	current_save_slot=slot; load_game()
	if state.guild_name=="": show_creation()
	else: show_hall()

func request_delete_save(slot:int) -> void:
	var saved=slot_state(slot)
	if saved.is_empty():return
	var dialog:=ConfirmationDialog.new(); dialog.title="Delete Saved Guild"; dialog.dialog_text="Are you sure you want to delete %s?\nThis cannot be undone." % saved.get("guild_name","this guild"); dialog.ok_button_text="Delete"
	dialog.confirmed.connect(func():
		var slot_file=ProjectSettings.globalize_path(save_slot_path(slot))
		if FileAccess.file_exists(save_slot_path(slot)):DirAccess.remove_absolute(slot_file)
		if slot==0 and FileAccess.file_exists(SAVE_PATH):DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		if current_save_slot==slot:state=fresh_state()
		show_menu())
	ui.add_child(dialog);dialog.popup_centered(Vector2i(460,210))

func team_has_member(idx:int) -> bool:
	for member in state.selected_team:
		if member == idx:
			return true
	return false

func team_is_active(idx:int) -> bool:
	return team_has_member(idx)

func active_team_index_of(idx:int) -> int:
	for i in state.selected_team.size():
		if state.selected_team[i] == idx:
			return i
	return -1

func reserve_team_indices() -> Array:
	var reserve := []
	for i in state.heroes.size():
		if not team_has_member(i):
			reserve.append(i)
	return reserve

func toggle_team_member(idx:int) -> void:
	if team_has_member(idx):
		var next_team := []
		for member in state.selected_team:
			if member != idx:
				next_team.append(member)
		state.selected_team = next_team
	elif state.selected_team.size() < 4:
		state.selected_team.append(idx)
	save_game()

func set_active_team() -> void:
	state.active_team = state.selected_team.duplicate()
	save_game()
	flash("Current party set as active.")

func load_active_team() -> void:
	state.selected_team = state.active_team.duplicate()
	save_game()
	flash("Loaded active party.")

func save_team_slot(slot:int) -> void:
	state.saved_teams[slot] = state.selected_team.duplicate()
	save_game()
	flash("Saved team %d." % (slot + 1))

func load_team_slot(slot:int) -> void:
	var team: Array = state.saved_teams[slot]
	if team is Array and team.size() > 0:
		state.selected_team = team.duplicate()
		save_game()
		flash("Loaded team %d." % (slot + 1))
	else:
		flash("Team %d is empty." % (slot + 1))

func team_slot_names(slot:int) -> String:
	var team: Array = state.active_team if slot < 0 else state.saved_teams[slot] if slot < state.saved_teams.size() else []
	if team.size() == 0:
		return "Empty"
	var names: PackedStringArray = []
	for member in team:
		names.append(state.heroes[member].name)
	return ", ".join(names)

func move_to_active_team(idx:int) -> void:
	if team_has_member(idx):
		return
	if state.selected_team.size() >= 4:
		flash("Active party is full.")
		return
	state.selected_team.append(idx)
	persist_current_team()

func move_to_reserve(idx:int) -> void:
	if not team_has_member(idx):
		return
	var next_team := []
	for member in state.selected_team:
		if member != idx:
			next_team.append(member)
	state.selected_team = next_team
	persist_current_team()

func start_team_drag(idx:int, origin:String) -> void:
	team_swiping=false
	team_dragging = true
	team_drag_index = idx
	team_drag_origin = origin
	team_drag_preview=Button.new(); team_drag_preview.text=team_card_text(idx); team_drag_preview.size=Vector2(180,100); team_drag_preview.mouse_filter=Control.MOUSE_FILTER_IGNORE; team_drag_preview.modulate=Color(1,1,1,.82); team_drag_preview.position=get_viewport().get_mouse_position()-Vector2(90,50); ui.add_child(team_drag_preview)
	queue_redraw()

func _input(event:InputEvent) -> void:
	if victory_sequence and victory_phase>=5 and (event is InputEventMouseButton and event.pressed or event is InputEventKey and event.pressed or event is InputEventScreenTouch and event.pressed):
		victory_sequence=false; show_zone_map(dungeon_id); return
	if screen=="team" and event is InputEventKey and event.pressed and not (get_viewport().gui_get_focus_owner() is LineEdit):
		if event.keycode==KEY_A: team_roster_page=max(0,team_roster_page-1); show_team()
		elif event.keycode==KEY_D: team_roster_page+=1; show_team()
	if screen=="team" and team_reserve_zone!=null:
		if event is InputEventScreenTouch:
			if event.pressed and Rect2(team_reserve_zone.global_position,team_reserve_zone.size).has_point(event.position): team_swipe_start=event.position; team_swiping=true
			elif not event.pressed and team_swiping: var dx=event.position.x-team_swipe_start.x; if abs(dx)>55: team_roster_page+=(-1 if dx>0 else 1); team_swiping=false; show_team()
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed and Rect2(team_reserve_zone.global_position,team_reserve_zone.size).has_point(event.position): team_swipe_start=event.position; team_swiping=true
			elif not event.pressed and team_swiping and not team_dragging: var dx=event.position.x-team_swipe_start.x; if abs(dx)>55: team_roster_page+=(-1 if dx>0 else 1); team_swiping=false; show_team()
	# Mouse release is usually received by the drop zone, not the card that began
	# the drag, so finish team drags at the viewport level.
	if team_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		end_team_drag(event.position)
	elif team_dragging and event is InputEventMouseMotion and team_drag_preview!=null:
		team_drag_preview.position=event.position-Vector2(90,50)

func hero_matches(idx:int) -> bool:
	var h = state.heroes[idx]
	var role:String = CLASSES[h["class"]]["role"]
	return (hero_search == "" or hero_search.to_lower() in str(h["name"]).to_lower()) and (hero_role_filter == "All roles" or role == hero_role_filter) and (hero_class_filter == "All classes" or h["class"] == hero_class_filter)

func sorted_hero_indices() -> Array:
	var result := []
	for i in state.heroes.size():
		if hero_matches(i): result.append(i)
	result.sort_custom(func(a,b):
		var ha=state.heroes[a]; var hb=state.heroes[b]
		var av = ha["name"] if roster_sort=="Name" else CLASSES[ha["class"]]["role"] if roster_sort=="Role" else ha["class"] if roster_sort=="Class" else ha["level"]
		var bv = hb["name"] if roster_sort=="Name" else CLASSES[hb["class"]]["role"] if roster_sort=="Role" else hb["class"] if roster_sort=="Class" else hb["level"]
		return av > bv if roster_descending else av < bv)
	return result

func filter_bar(refresh:Callable, include_sort:bool=false) -> HBoxContainer:
	var bar:=HBoxContainer.new(); bar.add_theme_constant_override("separation",8)
	var search:=LineEdit.new(); search.placeholder_text="Search"; search.text=hero_search; search.custom_minimum_size=Vector2(250,42); search.text_changed.connect(func(value): hero_search=value); search.text_submitted.connect(func(_value): refresh.call()); bar.add_child(search)
	var roles:=OptionButton.new(); roles.custom_minimum_size=Vector2(150,42)
	for value in ["All roles","Tank","Healer","DPS"]: roles.add_item(value)
	roles.select(["All roles","Tank","Healer","DPS"].find(hero_role_filter)); roles.item_selected.connect(func(i): hero_role_filter=roles.get_item_text(i); refresh.call()); bar.add_child(roles)
	var classes:=OptionButton.new(); classes.custom_minimum_size=Vector2(165,42)
	var class_values=["All classes","Guardian","Cleric","Ranger","Mage"]
	for value in class_values: classes.add_item(value)
	classes.select(class_values.find(hero_class_filter)); classes.item_selected.connect(func(i): hero_class_filter=classes.get_item_text(i); refresh.call()); bar.add_child(classes)
	if include_sort:
		var sorts:=OptionButton.new(); sorts.custom_minimum_size=Vector2(145,42)
		for value in ["Name","Role","Class","Level"]: sorts.add_item(value)
		sorts.select(["Name","Role","Class","Level"].find(roster_sort)); sorts.item_selected.connect(func(i): roster_sort=sorts.get_item_text(i); refresh.call()); bar.add_child(sorts)
		bar.add_child(button("↓" if roster_descending else "↑",func(): roster_descending=not roster_descending; refresh.call(),54))
	return bar

func end_team_drag(mouse_pos:Vector2) -> void:
	if not team_dragging:
		return
	var dropped_on_active := team_active_zone != null and mouse_pos.x >= team_active_zone.global_position.x and mouse_pos.x <= team_active_zone.global_position.x + team_active_zone.size.x and mouse_pos.y >= team_active_zone.global_position.y and mouse_pos.y <= team_active_zone.global_position.y + team_active_zone.size.y
	var dropped_on_reserve := team_reserve_zone != null and mouse_pos.x >= team_reserve_zone.global_position.x and mouse_pos.x <= team_reserve_zone.global_position.x + team_reserve_zone.size.x and mouse_pos.y >= team_reserve_zone.global_position.y and mouse_pos.y <= team_reserve_zone.global_position.y + team_reserve_zone.size.y
	if dropped_on_active:
		move_to_active_team(team_drag_index)
	elif dropped_on_reserve:
		move_to_reserve(team_drag_index)
	team_dragging = false
	team_drag_index = -1
	team_drag_origin = ""
	if team_drag_preview!=null: team_drag_preview.queue_free(); team_drag_preview=null
	save_game()
	show_team()

func team_card_text(idx:int) -> String:
	var h = state.heroes[idx]
	return "%s\n%s\n%s  •  Level %d" % [role_glyph(h["class"]),h.name,h["class"],h["level"]]

func role_glyph(hero_class:String) -> String:
	match hero_class:
		"Guardian": return "◈"
		"Cleric": return "✚"
		"Mage": return "✦━"
		_: return "➶"

func ability_tooltip(hero_class:String,slot:int) -> String:
	var descriptions={"Guardian":["Reduce incoming damage for a short time.","Force nearby enemies to focus the Guardian.","Rush forward and strike enemies in the path.","Protect the entire party with a powerful barrier."],"Cleric":["Deliver a strong heal to the most wounded ally.","Restore health to the full party.","Heal allies and damage nearby enemies.","Greatly restore the party during an emergency."],"Ranger":["Fire a powerful shot at the assigned target.","Quickly reposition away from danger.","Damage enemies across a wide area.","Rain arrows across the battlefield."],"Mage":["Strike the assigned target with arcane power.","Blink instantly toward the chosen position.","Damage enemies surrounding the Mage.","Call down arcane energy on every enemy."]}
	return descriptions[hero_class][slot]

func make_team_card(idx:int, origin:String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(180,100)
	b.text = team_card_text(idx)
	b.add_theme_font_size_override("font_size",16)
	var info_marker:=Label.new(); info_marker.text="ⓘ"; info_marker.position=Vector2(148,6); info_marker.size=Vector2(24,22); info_marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; info_marker.add_theme_font_size_override("font_size",14); info_marker.add_theme_color_override("font_color",C_MUTED); info_marker.mouse_filter=Control.MOUSE_FILTER_IGNORE; b.add_child(info_marker)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.focus_mode = Control.FOCUS_NONE
	if team_has_member(idx):
		b.add_theme_color_override("font_color", CLASSES[state.heroes[idx]["class"]].color)
		b.add_theme_stylebox_override("normal",ui_box(Color("24364b"),9,CLASSES[state.heroes[idx]["class"]].color,2))
	else:
		b.add_theme_color_override("font_color", C_TEXT)
	if team_inspect_candidate==idx:b.add_theme_stylebox_override("normal",ui_box(Color("2c4058"),9,C_GOLD,3))
	b.gui_input.connect(func(event): 
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if team_inspect_candidate==idx and team_inspect_time>0: selected_roster_index=idx; team_inspect_candidate=-1; team_inspect_time=0; show_roster()
			else: team_inspect_candidate=idx; team_inspect_time=3.0; start_team_drag(idx, origin)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			end_team_drag(get_viewport().get_mouse_position())
	)
	return b

func clear_all() -> void:
	for c in ui.get_children(): c.queue_free()
	for c in combat_layer.get_children(): c.queue_free()
	heroes.clear(); enemies.clear(); effects.clear()
	combat_layer.visible = false
	ui.visible = true
	queue_redraw()

func base_screen(title:String, subtitle:String="") -> VBoxContainer:
	clear_all()
	var bg := ColorRect.new(); bg.color=C_BG; bg.position=Vector2.ZERO; bg.size=Vector2(W,H); bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(bg)
	var root := VBoxContainer.new(); root.position=Vector2(32,22); root.size=Vector2(1216,676); root.add_theme_constant_override("separation",14); ui.add_child(root)
	var top := HBoxContainer.new(); root.add_child(top)
	var t := label(title,32,C_TEXT); t.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(t)
	if screen=="menu": top.add_child(button("×",func():get_tree().quit(),64))
	elif screen=="hall": top.add_child(button("×",show_menu,64))
	elif screen=="zone_map": top.add_child(button("Return",show_dungeons,130))
	else: top.add_child(button("Return",show_hall,130))
	if subtitle != "": root.add_child(label(subtitle,16,C_MUTED))
	var header_space:=Control.new(); header_space.custom_minimum_size.y=14; root.add_child(header_space)
	return root

func label(text:String, size:int=18, color:Color=C_TEXT) -> Label:
	var l:=Label.new(); l.text=text; l.add_theme_font_size_override("font_size",size); l.add_theme_color_override("font_color",color); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; return l

func rule() -> HSeparator:
	var r:=HSeparator.new(); r.add_theme_constant_override("separation",2); return r

func button(text:String, callback:Callable, width:float=180) -> Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size=Vector2(width,48); b.add_theme_font_size_override("font_size",17); b.pressed.connect(callback); return b

func panel() -> VBoxContainer:
	var p:=VBoxContainer.new(); p.add_theme_constant_override("separation",10); var sb:=StyleBoxFlat.new(); sb.bg_color=C_PANEL; sb.corner_radius_top_left=12; sb.corner_radius_top_right=12; sb.corner_radius_bottom_left=12; sb.corner_radius_bottom_right=12; sb.content_margin_left=20; sb.content_margin_right=20; sb.content_margin_top=16; sb.content_margin_bottom=16; p.add_theme_stylebox_override("panel",sb); return p

func show_menu() -> void:
	screen="menu"; var root=base_screen("FANTASY GUILD")
	root.add_spacer(false)
	var slots:=HBoxContainer.new(); slots.alignment=BoxContainer.ALIGNMENT_CENTER; slots.add_theme_constant_override("separation",22); root.add_child(slots)
	for slot in 3:
		var saved=slot_state(slot); var card:=Button.new(); card.custom_minimum_size=Vector2(300,210); card.add_theme_font_size_override("font_size",22)
		if saved.is_empty() or str(saved.get("guild_name",""))=="": card.text="SAVE %d\n\nNew Guild" % (slot+1)
		else:
			card.text="SAVE %d\n\n%s\n●  %d" % [slot+1,saved.get("guild_name","Unnamed Guild"),saved.get("gold",0)]
			var delete_button:=Button.new();delete_button.text="×";delete_button.position=Vector2(254,8);delete_button.size=Vector2(38,38);delete_button.add_theme_font_size_override("font_size",22);delete_button.tooltip_text="Delete saved guild";delete_button.mouse_filter=Control.MOUSE_FILTER_STOP;delete_button.pressed.connect(func(i=slot):request_delete_save(i));card.add_child(delete_button)
		card.pressed.connect(func(i=slot):open_save_slot(i)); slots.add_child(card)
	root.add_spacer(false)

func show_menu_legacy() -> void:
	screen="menu"; var root=base_screen("FANTASY GUILD")
	root.add_spacer(false)
	if state.guild_name!="":
		var profile:=label(state.guild_name,28,C_GOLD); profile.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; root.add_child(profile)
		var faction:=label(state.faction,16,C_MUTED); faction.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; root.add_child(faction)
	root.add_spacer(false)
	var row:=HBoxContainer.new(); row.alignment=BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation",16); root.add_child(row)
	if state.guild_name!="": row.add_child(button("Continue",show_hall,230))
	row.add_child(button("New Guild",show_creation,230)); row.add_child(button("Quit",func():get_tree().quit(),150))

func show_creation() -> void:
	screen="creation"; var root=base_screen("Create Your Guild")
	var box=panel(); box.custom_minimum_size=Vector2(650,400); box.size_flags_horizontal=Control.SIZE_SHRINK_CENTER; root.add_child(box)
	box.add_child(label("Guild name",18,C_GOLD)); var guild_name_input:=LineEdit.new(); guild_name_input.placeholder_text="The Dawnwardens"; guild_name_input.text="The Dawnwardens"; guild_name_input.custom_minimum_size.y=48; box.add_child(guild_name_input)
	box.add_child(label("Faction",18,C_GOLD)); var factions:=OptionButton.new(); factions.add_item("Ember Compact — +starting ore"); factions.add_item("Verdant Accord — +starting herbs"); factions.custom_minimum_size.y=48; box.add_child(factions)
	box.add_child(label("Four volunteers have answered your banner: a Guardian, Cleric, Ranger, and Mage.",16,C_MUTED))
	box.add_spacer(false); box.add_child(button("Found Guild",func():
		state=fresh_state(); state.guild_name=guild_name_input.text.strip_edges() if guild_name_input.text.strip_edges()!="" else "Unnamed Guild"; state.faction="Ember Compact" if factions.selected==0 else "Verdant Accord"; if factions.selected==0: state.ore+=4
		else: state.herbs+=4
		save_game(); show_hall(),240))

func nav(_root:VBoxContainer) -> void:
	pass

func hub_button(title:String, caption:String, callback:Callable) -> Button:
	var b:=Button.new(); b.text=title if caption=="" else "%s\n%s" % [title,caption]; b.custom_minimum_size=Vector2(260,125); b.add_theme_font_size_override("font_size",19); b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; b.pressed.connect(callback); return b

func show_hall() -> void:
	screen="hall"; var root=base_screen("Guild Hall"); nav(root)
	var battle:=Button.new(); battle.text="BATTLE"; battle.custom_minimum_size=Vector2(1170,120); battle.add_theme_font_size_override("font_size",34); battle.add_theme_color_override("font_color",C_GOLD); battle.pressed.connect(show_dungeons); root.add_child(battle)
	var destinations:=GridContainer.new(); destinations.columns=3; destinations.add_theme_constant_override("h_separation",18); destinations.add_theme_constant_override("v_separation",18); destinations.size_flags_horizontal=Control.SIZE_SHRINK_CENTER; root.add_child(destinations)
	destinations.add_child(hub_button("Command Table","",show_command_table))
	destinations.add_child(hub_button("Heroes","",show_roster))
	destinations.add_child(hub_button("Team Builder","",show_team))
	destinations.add_child(hub_button("Professions","",show_crafting))
	destinations.add_child(hub_button("Item Storage","",show_vault))
	destinations.add_child(hub_button("Market","",show_market))

func show_hall_legacy() -> void:
	screen="hall"; var root=base_screen("Guild Hall", "%s • Build team → fight → loot → upgrade → automate" % state.faction); nav(root)
	var stats:=HBoxContainer.new(); stats.add_theme_constant_override("separation",14); root.add_child(stats)
	for x in [["GOLD",state.gold,C_GOLD],["ORE",state.ore,Color("a9b5c7")],["HERBS",state.herbs,C_GREEN],["ARCANE DUST",state.dust,Color("b381ff")],["TOKENS",state.tokens,Color("6ed9ef")]]:
		var stat_panel=panel(); stat_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; stat_panel.add_child(label(str(x[0]),14,C_MUTED)); stat_panel.add_child(label(str(x[1]),28,x[2])); stats.add_child(stat_panel)
	var grid:=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",14); grid.add_theme_constant_override("v_separation",14); root.add_child(grid)
	var expedition_panel=panel(); expedition_panel.custom_minimum_size=Vector2(570,160); expedition_panel.add_child(label("Next Expedition",22,C_GOLD)); expedition_panel.add_child(label("Ashwood Pass" if state.unlocked_dungeon==0 else "Mirefang Warren is now available.",17)); expedition_panel.add_child(button("Choose Dungeon",show_dungeons,210)); grid.add_child(expedition_panel)
	var q=panel(); q.custom_minimum_size=Vector2(570,160); q.add_child(label("Guild Progress",22,C_GOLD)); q.add_child(label("Roster: %d heroes  •  Total clears: %d\nVault: %d / %d slots" % [state.heroes.size(),state.dungeon_clears[0]+state.dungeon_clears[1],vault_used(),state.vault_limit],17)); grid.add_child(q)

func make_roster_card(idx:int) -> Button:
	var h=state.heroes[idx]
	var card:=Button.new(); card.custom_minimum_size=Vector2(170,108); card.text="%s\n%s\n%s  •  Level %d" % [role_glyph(h["class"]),h["name"],h["class"],h["level"]]
	card.add_theme_font_size_override("font_size",15); card.add_theme_color_override("font_color",CLASSES[h["class"]].color if idx==selected_roster_index else C_TEXT)
	if idx==selected_roster_index: card.add_theme_stylebox_override("normal",ui_box(Color("26384e"),9,CLASSES[h["class"]].color,2))
	card.pressed.connect(func():selected_roster_index=idx;show_roster())
	return card

func show_roster() -> void:
	screen="roster"; var root=base_screen("Hero Roster"); nav(root)
	root.add_child(filter_bar(show_roster,true))
	var carousel:=HBoxContainer.new(); carousel.add_theme_constant_override("separation",8); root.add_child(carousel)
	carousel.add_child(compact_button("←",func():hero_roster_page=max(0,hero_roster_page-1);show_roster(),48))
	var cards:=GridContainer.new(); cards.columns=6; cards.add_theme_constant_override("h_separation",10); cards.size_flags_horizontal=Control.SIZE_EXPAND_FILL; carousel.add_child(cards)
	var indices=sorted_hero_indices(); var pages=max(1,int(ceil(indices.size()/6.0))); hero_roster_page=clampi(hero_roster_page,0,pages-1)
	for card_index in range(hero_roster_page*6,min(indices.size(),hero_roster_page*6+6)):cards.add_child(make_roster_card(indices[card_index]))
	carousel.add_child(compact_button("→",func():hero_roster_page=min(pages-1,hero_roster_page+1);show_roster(),48))
	if selected_roster_index>=state.heroes.size():selected_roster_index=0
	var hero=state.heroes[selected_roster_index]; var info=CLASSES[hero["class"]]
	var detail:=HBoxContainer.new(); detail.add_theme_constant_override("separation",34); detail.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(detail)
	var character:=VBoxContainer.new(); character.custom_minimum_size.x=510; character.add_theme_constant_override("separation",8); detail.add_child(character)
	character.add_child(label(hero["name"],32,info.color));character.add_child(label("Level %d %s"%[hero.level,hero["class"]],16,C_MUTED))
	var equipment_row:=HBoxContainer.new();equipment_row.add_theme_constant_override("separation",12);character.add_child(equipment_row)
	var left_slots:=VBoxContainer.new();left_slots.add_theme_constant_override("separation",8);equipment_row.add_child(left_slots)
	for slot in ["Head","Chest","Weapon"]:var gear:=Button.new();gear.text=slot;gear.disabled=true;gear.custom_minimum_size=Vector2(105,70);left_slots.add_child(gear)
	var portrait:=Button.new();portrait.text=role_glyph(hero["class"]);portrait.disabled=true;portrait.custom_minimum_size=Vector2(230,220);portrait.add_theme_font_size_override("font_size",64);equipment_row.add_child(portrait)
	var right_slots:=VBoxContainer.new();right_slots.add_theme_constant_override("separation",8);equipment_row.add_child(right_slots)
	for slot in ["Neck","Hands","Trinket"]:var gear:=Button.new();gear.text=slot;gear.disabled=true;gear.custom_minimum_size=Vector2(105,70);right_slots.add_child(gear)
	var management:=VBoxContainer.new();management.custom_minimum_size.x=330;management.add_theme_constant_override("separation",9);detail.add_child(management);var management_offset:=Control.new();management_offset.custom_minimum_size.y=40;management.add_child(management_offset)
	management.add_child(label("Guild Rank   Recruit",16));management.add_child(label("Prestige   ★☆☆☆☆",18,C_GOLD));management.add_child(label("Gear Score   %d"%hero.gear,16));management.add_child(label("Experience   %d / %d"%[hero.xp,hero.level*100],16));management.add_child(label("Health   %d     Power   %d"%[int(info.hp),int(info.damage)],16))
	var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",7);management.add_child(tabs);for section in ["Talents","Profession","History"]:tabs.add_child(compact_button(section,func(section_name=section):flash("%s management is coming next."%section_name),100))
	var abilities:=VBoxContainer.new();abilities.custom_minimum_size.x=245;abilities.add_theme_constant_override("separation",8);detail.add_child(abilities);var abilities_offset:=Control.new();abilities_offset.custom_minimum_size.y=40;abilities.add_child(abilities_offset);abilities.add_child(label("ABILITIES",13,C_MUTED))
	for slot in 4:var ability:=Button.new();ability.text=["Q","W","E","R"][slot]+"   "+ABILITIES[hero["class"]][slot];ability.custom_minimum_size=Vector2(235,52);ability.tooltip_text=ability_tooltip(hero["class"],slot);abilities.add_child(ability)

func show_roster_previous() -> void:
	screen="roster"; var root=base_screen("Hero Roster"); nav(root)
	root.add_child(filter_bar(show_roster,true))
	var carousel:=HBoxContainer.new(); carousel.add_theme_constant_override("separation",8); root.add_child(carousel)
	carousel.add_child(compact_button("←",func():hero_roster_page=max(0,hero_roster_page-1);show_roster(),48))
	var cards:=GridContainer.new(); cards.columns=6; cards.add_theme_constant_override("h_separation",10); cards.size_flags_horizontal=Control.SIZE_EXPAND_FILL; carousel.add_child(cards)
	var indices=sorted_hero_indices(); var pages=max(1,int(ceil(indices.size()/6.0))); hero_roster_page=clampi(hero_roster_page,0,pages-1)
	for card_index in range(hero_roster_page*6,min(indices.size(),hero_roster_page*6+6)):cards.add_child(make_roster_card(indices[card_index]))
	carousel.add_child(compact_button("→",func():hero_roster_page=min(pages-1,hero_roster_page+1);show_roster(),48))
	var roster_gap:=Control.new(); roster_gap.custom_minimum_size.y=12; root.add_child(roster_gap)
	if selected_roster_index>=state.heroes.size():selected_roster_index=0
	var hero=state.heroes[selected_roster_index]; var info=CLASSES[hero["class"]]; var detail:=HBoxContainer.new(); detail.add_theme_constant_override("separation",22); detail.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(detail)
	var identity:=VBoxContainer.new(); identity.custom_minimum_size.x=230; detail.add_child(identity); identity.add_child(label(hero["name"],28,info.color)); identity.add_child(label("Level %d %s"%[hero.level,hero["class"]],16,C_MUTED)); var portrait:=Button.new(); portrait.text=role_glyph(hero["class"]); portrait.disabled=true; portrait.custom_minimum_size=Vector2(210,190); portrait.add_theme_font_size_override("font_size",56); identity.add_child(portrait)
	var equipment:=GridContainer.new(); equipment.columns=2; equipment.add_theme_constant_override("h_separation",8); equipment.add_theme_constant_override("v_separation",8); detail.add_child(equipment)
	for slot in ["Head","Neck","Chest","Hands","Weapon","Trinket"]:var gear:=Button.new();gear.text=slot;gear.disabled=true;gear.custom_minimum_size=Vector2(105,70);equipment.add_child(gear)
	var stats:=VBoxContainer.new(); stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL; stats.add_theme_constant_override("separation",7); detail.add_child(stats)
	stats.add_child(label("Guild Rank   Recruit",16));stats.add_child(label("Prestige   ★☆☆☆☆",18,C_GOLD));stats.add_child(label("Gear Score   %d"%hero.gear,16));stats.add_child(label("Experience   %d / %d"%[hero.xp,hero.level*100],16));stats.add_child(label("Health   %d     Power   %d"%[int(info.hp),int(info.damage)],16))
	var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",7);stats.add_child(tabs);for section in ["Talents","Profession","History"]:tabs.add_child(compact_button(section,func(section_name=section):flash("%s management is coming next."%section_name),110))
	stats.add_child(label("ABILITIES",13,C_MUTED));var ability_grid:=GridContainer.new();ability_grid.columns=2;ability_grid.add_theme_constant_override("h_separation",7);ability_grid.add_theme_constant_override("v_separation",7);stats.add_child(ability_grid)
	for slot in 4:var ability:=Button.new();ability.text=["Q","W","E","R"][slot]+"  "+ABILITIES[hero["class"]][slot];ability.custom_minimum_size=Vector2(190,44);ability.tooltip_text=ability_tooltip(hero["class"],slot);ability_grid.add_child(ability)

func show_roster_legacy_current() -> void:
	screen="roster"; var root=base_screen("Hero Roster"); nav(root)
	root.add_child(filter_bar(show_roster,true))
	var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",18); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(columns)
	var list:=VBoxContainer.new(); list.custom_minimum_size.x=350; list.add_theme_constant_override("separation",7); columns.add_child(list)
	for idx in sorted_hero_indices():
		var h=state.heroes[idx]; var c=CLASSES[h["class"]]; var card:=Button.new(); card.custom_minimum_size=Vector2(350,64); card.alignment=HORIZONTAL_ALIGNMENT_LEFT; var activity=str(h.get("activity","")); card.text="  %s%s\n  %s  |  Level %d" % [h["name"],"\n  "+activity if activity!="" else "",h["class"],h["level"]]; card.add_theme_color_override("font_color",c["color"] if idx==selected_roster_index else C_TEXT); card.pressed.connect(func(i=idx): selected_roster_index=i; show_roster()); list.add_child(card)
	var detail:=VBoxContainer.new(); detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL; detail.add_theme_constant_override("separation",10); columns.add_child(detail)
	if selected_roster_index>=state.heroes.size(): selected_roster_index=0
	var hero=state.heroes[selected_roster_index]; var info=CLASSES[hero["class"]]
	detail.add_child(label(hero["name"],29,info["color"])); detail.add_child(label("Level %d %s  |  %s" % [hero["level"],hero["class"],info["role"]],17,C_MUTED)); detail.add_child(rule())
	var overview:=HBoxContainer.new(); overview.add_theme_constant_override("separation",24); detail.add_child(overview)
	var left_gear:=VBoxContainer.new(); left_gear.add_theme_constant_override("separation",7); overview.add_child(left_gear)
	for slot in ["Head","Chest","Weapon"]: var gear:=Button.new(); gear.text=slot; gear.disabled=true; gear.custom_minimum_size=Vector2(92,54); left_gear.add_child(gear)
	var portrait:=Button.new(); portrait.text="%s\n\n%s\n%s  •  Level %d" % [role_glyph(hero["class"]),hero["name"],hero["class"],hero["level"]]; portrait.disabled=true; portrait.custom_minimum_size=Vector2(210,210); portrait.add_theme_font_size_override("font_size",22); overview.add_child(portrait)
	var right_gear:=VBoxContainer.new(); right_gear.add_theme_constant_override("separation",7); overview.add_child(right_gear)
	for slot in ["Neck","Hands","Trinket"]: var gear:=Button.new(); gear.text=slot; gear.disabled=true; gear.custom_minimum_size=Vector2(92,54); right_gear.add_child(gear)
	var stats:=VBoxContainer.new(); stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL; overview.add_child(stats)
	stats.add_child(label("Guild Rank   Recruit",16)); stats.add_child(label("Prestige   ★☆☆☆☆",18,C_GOLD)); stats.add_child(label("Gear Score   %d" % hero["gear"],16)); stats.add_child(label("Experience   %d / %d" % [hero["xp"],hero["level"]*100],16)); stats.add_child(label("Health   %d" % int(info["hp"]),16)); stats.add_child(label("Power   %d" % int(info["damage"]),16))
	var sections:=HBoxContainer.new(); sections.add_theme_constant_override("separation",10); detail.add_child(sections)
	for section in ["Talents","Profession","History"]: sections.add_child(compact_button(section,func(section_name=section): flash("%s management is coming next." % section_name),120))

func show_roster_legacy() -> void:
	screen="roster"; var root=base_screen("Hero Roster"); nav(root)
	root.add_child(filter_bar(show_roster,true))
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",12); root.add_child(row)
	for idx in sorted_hero_indices():
		var h=state.heroes[idx]
		var p=panel(); p.size_flags_horizontal=Control.SIZE_EXPAND_FILL; var c=CLASSES[h["class"]]; p.add_child(label(h["name"],24,c["color"])); p.add_child(label("%s • %s" % [h["class"],c["role"]],16)); p.add_child(label("Level %d\nXP %d / %d\nGear %d" % [h["level"],h["xp"],h["level"]*100,h["gear"]],17,C_MUTED)); p.add_child(label(c["ability"],15,C_GOLD)); row.add_child(p)

func compact_button(text:String, callback:Callable, width:float=100) -> Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size=Vector2(width,34); b.add_theme_font_size_override("font_size",14); b.pressed.connect(callback); return b

func select_team_slot(option:int) -> void:
	current_team_slot=option-1
	state.selected_team=(state.active_team if current_team_slot<0 else state.saved_teams[current_team_slot]).duplicate()
	save_game(); show_team()

func rename_current_team(value:String) -> void:
	if current_team_slot>=0 and value.strip_edges()!="": state.team_names[current_team_slot]=value.strip_edges(); save_game()

func show_team() -> void:
	screen="team"; var root=base_screen("Team Builder"); nav(root)
	var chooser:=HBoxContainer.new(); chooser.add_theme_constant_override("separation",10); root.add_child(chooser)
	var teams:=OptionButton.new(); teams.custom_minimum_size=Vector2(260,44); teams.add_item("Active Party")
	for team_name in state.team_names: teams.add_item(team_name)
	teams.select(current_team_slot+1); teams.item_selected.connect(select_team_slot); chooser.add_child(teams)
	if current_team_slot>=0:
		var rename:=LineEdit.new(); rename.placeholder_text="Team name"; rename.text=state.team_names[current_team_slot]; rename.custom_minimum_size=Vector2(220,44); rename.text_submitted.connect(func(value): rename_current_team(value); show_team()); chooser.add_child(rename)
	var chooser_space:=Control.new(); chooser_space.size_flags_horizontal=Control.SIZE_EXPAND_FILL; chooser.add_child(chooser_space)
	var party_count:=label("%d / 4" % state.selected_team.size(),18,C_GOLD); party_count.custom_minimum_size.x=60; party_count.autowrap_mode=TextServer.AUTOWRAP_OFF; party_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; chooser.add_child(party_count)
	team_active_zone=VBoxContainer.new(); team_active_zone.custom_minimum_size=Vector2(1160,100); root.add_child(team_active_zone)
	var active:=HBoxContainer.new(); active.add_theme_constant_override("separation",12); team_active_zone.add_child(active)
	for idx in state.selected_team: active.add_child(make_team_card(idx,"active"))
	for _slot in range(4-state.selected_team.size()): var empty:=Button.new(); empty.text="Empty"; empty.disabled=true; empty.custom_minimum_size=Vector2(180,100); active.add_child(empty)
	var party_roster_gap:=Control.new();party_roster_gap.custom_minimum_size.y=24;root.add_child(party_roster_gap)
	var roster_heading:=HBoxContainer.new(); root.add_child(roster_heading); var roster_title:=label("GUILD ROSTER",18,C_GOLD); roster_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; roster_heading.add_child(roster_title)
	root.add_child(filter_bar(show_team,true))
	team_reserve_zone=VBoxContainer.new(); team_reserve_zone.custom_minimum_size=Vector2(1160,180); team_reserve_zone.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(team_reserve_zone)
	var carousel:=HBoxContainer.new(); carousel.add_theme_constant_override("separation",8); team_reserve_zone.add_child(carousel)
	carousel.add_child(compact_button("←",func(): team_roster_page=max(0,team_roster_page-1); show_team(),48))
	var reserves:=GridContainer.new(); reserves.columns=5; reserves.add_theme_constant_override("h_separation",12); reserves.add_theme_constant_override("v_separation",12); reserves.size_flags_horizontal=Control.SIZE_EXPAND_FILL; carousel.add_child(reserves)
	var roster_indices=sorted_hero_indices().filter(func(idx):return not team_has_member(idx)); var page_count=max(1,int(ceil(roster_indices.size()/10.0))); team_roster_page=clampi(team_roster_page,0,page_count-1)
	for card_index in range(team_roster_page*10,min(roster_indices.size(),team_roster_page*10+10)):
		reserves.add_child(make_team_card(roster_indices[card_index],"reserve"))
	if roster_indices.is_empty(): var empty_message:=label("All available heroes are assigned to this team.",16,C_MUTED); empty_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; empty_message.size_flags_horizontal=Control.SIZE_EXPAND_FILL; reserves.add_child(empty_message)
	carousel.add_child(compact_button("→",func(): team_roster_page=min(page_count-1,team_roster_page+1); show_team(),48))

func show_team_previous() -> void:
	screen="team"; var root=base_screen("Team Builder"); nav(root)
	var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",22); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(columns)

	var builder:=VBoxContainer.new(); builder.custom_minimum_size.x=810; builder.size_flags_horizontal=Control.SIZE_EXPAND_FILL; builder.add_theme_constant_override("separation",10); columns.add_child(builder)
	var party_header:=HBoxContainer.new(); builder.add_child(party_header)
	var party_title:=label("ACTIVE PARTY",18,C_GOLD); party_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; party_header.add_child(party_title)
	party_header.add_child(label("%d / 4" % state.selected_team.size(),16,C_MUTED))
	team_active_zone=VBoxContainer.new(); team_active_zone.custom_minimum_size=Vector2(810,92); builder.add_child(team_active_zone)
	var active_row:=HBoxContainer.new(); active_row.add_theme_constant_override("separation",10); team_active_zone.add_child(active_row)
	for idx in state.selected_team: active_row.add_child(make_team_card(idx,"active"))
	for _slot in range(4-state.selected_team.size()):
		var empty:=Button.new(); empty.text="Drop hero here"; empty.disabled=true; empty.custom_minimum_size=Vector2(180,72); active_row.add_child(empty)

	var reserve_header:=HBoxContainer.new(); builder.add_child(reserve_header)
	var reserve_title:=label("RESERVES",18,C_GOLD); reserve_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; reserve_header.add_child(reserve_title)
	reserve_header.add_child(label("Drag up to add",14,C_MUTED))
	builder.add_child(filter_bar(show_team,false))
	team_reserve_zone=VBoxContainer.new(); team_reserve_zone.size_flags_vertical=Control.SIZE_EXPAND_FILL; team_reserve_zone.custom_minimum_size=Vector2(810,155); builder.add_child(team_reserve_zone)
	var reserve_grid:=GridContainer.new(); reserve_grid.columns=4; reserve_grid.add_theme_constant_override("h_separation",10); reserve_grid.add_theme_constant_override("v_separation",10); team_reserve_zone.add_child(reserve_grid)
	var reserve_count:=0
	for idx in sorted_hero_indices():
		if not team_has_member(idx): reserve_grid.add_child(make_team_card(idx,"reserve")); reserve_count+=1
	if reserve_count==0: reserve_grid.add_child(label("Every matching hero is currently in the party.",15,C_MUTED))

	var presets:=VBoxContainer.new(); presets.custom_minimum_size.x=300; presets.add_theme_constant_override("separation",8); columns.add_child(presets)
	presets.add_child(label("PARTY PRESETS",18,C_GOLD)); presets.add_child(label("Save this party for quick selection later.",14,C_MUTED)); presets.add_child(rule())
	var default_row:=HBoxContainer.new(); default_row.add_theme_constant_override("separation",6); presets.add_child(default_row)
	var default_text:=VBoxContainer.new(); default_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL; default_text.add_child(label("Active default",16,C_GREEN)); default_text.add_child(label(team_slot_names(-1),12,C_MUTED)); default_row.add_child(default_text)
	default_row.add_child(compact_button("Set",func(): set_active_team(); show_team(),55)); default_row.add_child(compact_button("Load",func(): load_active_team(); show_team(),60))
	presets.add_child(rule())
	for slot in 5:
		var slot_box:=VBoxContainer.new(); slot_box.add_theme_constant_override("separation",3); presets.add_child(slot_box)
		var slot_top:=HBoxContainer.new(); slot_box.add_child(slot_top)
		var slot_name:=label("Team %d" % (slot+1),16,C_TEXT); slot_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL; slot_top.add_child(slot_name)
		slot_top.add_child(compact_button("Save",func(i=slot): save_team_slot(i); show_team(),58)); slot_top.add_child(compact_button("Load",func(i=slot): load_team_slot(i); show_team(),58))
		var members:=label(team_slot_names(slot),12,C_MUTED); members.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; members.autowrap_mode=TextServer.AUTOWRAP_OFF; slot_box.add_child(members)
		presets.add_child(rule())

func show_team_legacy() -> void:
	var root=base_screen("Team Builder","Drag heroes into the active party at the top. Everything else stays in reserve."); nav(root)
	root.add_child(filter_bar(show_team,false))
	var header:=HBoxContainer.new(); header.add_theme_constant_override("separation",10); root.add_child(header)
	var active_heading:=label("ACTIVE PARTY (%d / 4)" % state.selected_team.size(),18,C_GOLD); active_heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(active_heading)
	header.add_child(button("Set As Active Party",set_active_team,190))
	header.add_child(button("Load Active Party",load_active_team,180))
	team_active_zone = VBoxContainer.new()
	team_active_zone.custom_minimum_size = Vector2(1160,115)
	team_active_zone.add_theme_constant_override("separation",10)
	var active_panel:=panel(); active_panel.custom_minimum_size = Vector2(1160,115); active_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var active_row:=HBoxContainer.new(); active_row.add_theme_constant_override("separation",10); active_panel.add_child(active_row)
	for idx in state.selected_team:
		active_row.add_child(make_team_card(idx,"active"))
	for _slot in range(4 - state.selected_team.size()):
		var empty_slot:=panel(); empty_slot.custom_minimum_size=Vector2(180,72); empty_slot.add_child(label("Empty slot",16,C_MUTED)); active_row.add_child(empty_slot)
	team_active_zone.add_child(active_panel)
	root.add_child(team_active_zone)
	root.add_child(label("RESERVE ROSTER",16,C_GOLD))
	team_reserve_zone = VBoxContainer.new()
	team_reserve_zone.custom_minimum_size = Vector2(1160,115)
	var reserve_panel:=panel(); reserve_panel.custom_minimum_size = Vector2(1160,115); reserve_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reserve_grid:=GridContainer.new(); reserve_grid.columns=6; reserve_grid.add_theme_constant_override("h_separation",10); reserve_panel.add_child(reserve_grid)
	for i in sorted_hero_indices():
		if not team_has_member(i):
			reserve_grid.add_child(make_team_card(i,"reserve"))
	team_reserve_zone.add_child(reserve_panel)
	root.add_child(team_reserve_zone)
	root.add_child(label("SAVED TEAMS",16,C_GOLD))
	var slots:=HBoxContainer.new(); slots.add_theme_constant_override("separation",10); root.add_child(slots)
	var active_card:=VBoxContainer.new(); active_card.custom_minimum_size=Vector2(220,120); active_card.add_theme_constant_override("separation",6)
	active_card.add_child(label("Active Party",20,C_GREEN))
	active_card.add_child(label("Used first by default",15,C_MUTED))
	active_card.add_child(label("Members: %s" % team_slot_names(-1),15,C_MUTED))
	active_card.add_child(button("Load",load_active_team,100))
	slots.add_child(active_card)
	for slot in 5:
		var card:=VBoxContainer.new(); card.custom_minimum_size=Vector2(220,120); card.add_theme_constant_override("separation",6)
		card.add_child(label("Slot %d" % (slot + 1),20,C_TEXT))
		card.add_child(label("Members: %s" % team_slot_names(slot),15,C_MUTED))
		var load_btn:=button("Load",func(idx=slot): load_team_slot(idx); show_team(),100)
		var save_btn:=button("Save",func(idx=slot): save_team_slot(idx); show_team(),100)
		var row_btns:=HBoxContainer.new(); row_btns.add_theme_constant_override("separation",8); row_btns.add_child(load_btn); row_btns.add_child(save_btn)
		card.add_child(row_btns)
		slots.add_child(card)
	root.add_child(label("Drag between active party and reserves. Saved teams remain presets you can restore anytime.",17,C_GREEN))

func clamp_world_map_pan() -> void:
	if world_map_view==null or world_map_content==null:return
	var content_size=world_map_content.size*world_map_zoom; var view_size=world_map_view.size
	world_map_pan.x=(view_size.x-content_size.x)*.5 if content_size.x<=view_size.x else clamp(world_map_pan.x,view_size.x-content_size.x,0.0)
	world_map_pan.y=(view_size.y-content_size.y)*.5 if content_size.y<=view_size.y else clamp(world_map_pan.y,view_size.y-content_size.y,0.0)
	world_map_content.position=world_map_pan; world_map_content.scale=Vector2.ONE*world_map_zoom

func zoom_world_map(amount:float,focus:Vector2) -> void:
	var old_zoom=world_map_zoom; world_map_zoom=clamp(world_map_zoom*amount,.84,2.2)
	var map_point=(focus-world_map_pan)/old_zoom; world_map_pan=focus-map_point*world_map_zoom; clamp_world_map_pan()

func handle_world_map_input(event:InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:zoom_world_map(1.12,event.position)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:zoom_world_map(.89,event.position)
		elif event.button_index==MOUSE_BUTTON_LEFT:world_map_dragging=event.pressed
	elif event is InputEventMouseMotion and world_map_dragging:
		world_map_pan+=event.relative;clamp_world_map_pan()
	elif event is InputEventScreenTouch:
		if event.pressed:world_map_touches[event.index]=event.position
		else:world_map_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		var old_positions=world_map_touches.duplicate();world_map_touches[event.index]=event.position
		if world_map_touches.size()==1:world_map_pan+=event.relative;clamp_world_map_pan()
		elif world_map_touches.size()>=2:
			var ids=world_map_touches.keys();var old_a=old_positions.get(ids[0],world_map_touches[ids[0]]);var old_b=old_positions.get(ids[1],world_map_touches[ids[1]]);var new_a=world_map_touches[ids[0]];var new_b=world_map_touches[ids[1]];var old_distance=old_a.distance_to(old_b);var new_distance=new_a.distance_to(new_b)
			if old_distance>1:zoom_world_map(new_distance/old_distance,(new_a+new_b)*.5)

func show_dungeons() -> void:
	screen="dungeons"; clear_all()
	world_map_view=Control.new(); world_map_view.position=Vector2.ZERO; world_map_view.size=Vector2(W,H); world_map_view.clip_contents=true; world_map_view.mouse_filter=Control.MOUSE_FILTER_STOP; world_map_view.gui_input.connect(handle_world_map_input); ui.add_child(world_map_view)
	world_map_content=Control.new(); world_map_content.size=Vector2(1536,864); world_map_content.mouse_filter=Control.MOUSE_FILTER_PASS; world_map_view.add_child(world_map_content)
	var map_image:=TextureRect.new(); map_image.texture=load("res://assets/world_map.png"); map_image.position=Vector2.ZERO; map_image.size=world_map_content.size; map_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; map_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; map_image.modulate=Color(.86,.89,.95,1); map_image.mouse_filter=Control.MOUSE_FILTER_IGNORE; world_map_content.add_child(map_image)
	var ashwood:=Button.new(); ashwood.position=Vector2(345,405); ashwood.size=Vector2(250,94); ashwood.text="ASHWOOD MARCHES\n%d / 10" % min(10,int(state.zone_progress[0])); ashwood.add_theme_font_size_override("font_size",19); ashwood.add_theme_color_override("font_color",C_GOLD); ashwood.add_theme_stylebox_override("normal",ui_box(Color(0.04,.08,.10,.92),12,C_GOLD,3)); ashwood.pressed.connect(func():show_zone_map(0)); world_map_content.add_child(ashwood)
	var locked_regions=[["EMBER WASTES",Vector2(155,175)],["FROSTPEAK",Vector2(760,105)],["MIREFANG WILDS",Vector2(1010,410)],["SUN COAST",Vector2(760,655)],["DREAD ISLE",Vector2(135,655)]]
	for region in locked_regions:
		var marker:=Button.new(); marker.position=region[1]; marker.size=Vector2(210,72); marker.text="🔒  %s" % region[0]; marker.disabled=true; marker.mouse_filter=Control.MOUSE_FILTER_IGNORE; marker.tooltip_text="Locked region"; marker.add_theme_font_size_override("font_size",15); marker.add_theme_stylebox_override("disabled",ui_box(Color(0.05,.07,.11,.88),10,Color("68778e"),2)); world_map_content.add_child(marker)
	var return_button:=button("Return",show_hall,130); return_button.position=Vector2(1116,22); world_map_view.add_child(return_button)
	var zoom_controls:=HBoxContainer.new(); zoom_controls.position=Vector2(995,24); zoom_controls.add_theme_constant_override("separation",6); world_map_view.add_child(zoom_controls); zoom_controls.add_child(compact_button("−",func():zoom_world_map(.85,world_map_view.size*.5),46));zoom_controls.add_child(compact_button("+",func():zoom_world_map(1.18,world_map_view.size*.5),46))
	clamp_world_map_pan();call_deferred("clamp_world_map_pan")

func show_zone_map(zone:int) -> void:
	screen="zone_map"; dungeon_id=zone; var zone_names=["Ashwood Marches","Mirefang Wilds"]; var root=base_screen(zone_names[zone]); nav(root)
	var map:=Control.new(); map.custom_minimum_size=Vector2(1120,445); root.add_child(map)
	var ashwood=["Old Road","Bandit Camp","Timber Run","Broken Bridge","Wolf Hollow","Forest Shrine","Watchtower","Burned Village","Keep Approach","Ashwood Keep","Hidden Grove","Smuggler Cave"]
	var mirefang=["Fen Trail","Spore Hollow","Reed Crossing","Sunken Ruin","Bog Camp","Witch Pool","Rotwood","Drowned Court","Den Approach","Mirefang Den","Moonwell","Buried Temple"]
	var node_names=ashwood if zone==0 else mirefang
	var positions=[Vector2(25,245),Vector2(130,175),Vector2(235,245),Vector2(340,155),Vector2(445,235),Vector2(550,145),Vector2(655,225),Vector2(760,135),Vector2(865,215),Vector2(970,145),Vector2(350,330),Vector2(675,330)]
	for i in 9:
		var line:=Line2D.new(); line.width=5; line.default_color=C_GOLD if i<int(state.zone_progress[zone]) else Color("3d4a5d"); line.points=PackedVector2Array([positions[i]+Vector2(55,32),positions[i+1]+Vector2(55,32)]); map.add_child(line)
	for branch_data in [[3,10,0],[6,11,1]]:
		var line:=Line2D.new(); line.width=4; line.default_color=Color("b381ff") if state.zone_branches[zone][branch_data[2]] else Color("3d4a5d"); line.points=PackedVector2Array([positions[branch_data[0]]+Vector2(55,32),positions[branch_data[1]]+Vector2(55,32)]); map.add_child(line)
	for node in 12:
		var is_branch=node>=10; var branch_index=node-10; var unlocked=node<=int(state.zone_progress[zone]) if not is_branch else int(state.zone_progress[zone])>=(3 if branch_index==0 else 6); var completed=node<int(state.zone_progress[zone]) if not is_branch else state.zone_branches[zone][branch_index]
		var encounter:=Button.new(); encounter.position=positions[node]; encounter.size=Vector2(110,64); encounter.text=("✓\n" if completed else "")+(node_names[node] if unlocked else "?"); encounter.disabled=not unlocked; encounter.add_theme_font_size_override("font_size",12); encounter.add_theme_color_override("font_color",Color("b381ff") if is_branch else C_GOLD if node==9 else C_TEXT); encounter.pressed.connect(func(i=node,z=zone):start_battle(z,i)); map.add_child(encounter)

func show_zone_map_legacy(zone:int) -> void:
	screen="zone_map"; dungeon_id=zone; var zone_names=["Ashwood Marches","Mirefang Wilds"]; var root=base_screen(zone_names[zone]); nav(root)
	var map:=Control.new(); map.custom_minimum_size=Vector2(1120,430); root.add_child(map)
	var node_names=[["Old Road","Bandit Camp","Broken Bridge","Forest Shrine","Ashwood Keep"],["Fen Trail","Spore Hollow","Sunken Ruin","Witch Pool","Mirefang Den"]][zone]
	var positions=[Vector2(70,285),Vector2(270,180),Vector2(475,265),Vector2(690,130),Vector2(900,230)]
	for i in 4:
		var line:=Line2D.new(); line.width=6; line.default_color=C_GOLD if i<int(state.zone_progress[zone]) else Color("3d4a5d"); line.points=PackedVector2Array([positions[i]+Vector2(70,40),positions[i+1]+Vector2(70,40)]); map.add_child(line)
	for node in 5:
		var unlocked=node<=int(state.zone_progress[zone]); var encounter:=Button.new(); encounter.position=positions[node]; encounter.size=Vector2(145,82); encounter.text="%d\n%s" % [node+1,node_names[node]] if unlocked else "?"; encounter.disabled=not unlocked; encounter.add_theme_color_override("font_color",C_GOLD if node==4 else C_TEXT); encounter.pressed.connect(func(i=node,z=zone):start_battle(z,i)); map.add_child(encounter)

func show_dungeons_legacy() -> void:
	screen="dungeons"; var root=base_screen("Battle Map"); nav(root)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",16); root.add_child(row)
	for i in 2:
		var p=panel(); p.size_flags_horizontal=Control.SIZE_EXPAND_FILL; var unlocked=i<=state.unlocked_dungeon; var names=["Ashwood Pass","Mirefang Warren"]; p.add_child(label(names[i],25,C_GOLD if unlocked else C_MUTED)); p.add_child(label(("Level 1 • Gear 10" if i==0 else "Level 2 • Gear 13")+"\nManual clears: %d / 3 mastery"%state.dungeon_clears[i],17,C_MUTED)); p.add_child(label("Rewards: gold, XP, %s, dungeon tokens" % ("ore" if i==0 else "herbs + arcane dust"),16));
		if unlocked: p.add_child(button("Enter Manually",func(idx=i):start_battle(idx),210)); if state.dungeon_clears[i]>=3: p.add_child(button("Auto-run (40 gold)",func(idx=i):auto_run(idx),210))
		else: p.add_child(label("LOCKED — clear Ashwood Pass twice",16,C_RED))
		row.add_child(p)

func show_command_table() -> void:
	screen="command"; var root=base_screen("Command Table"); nav(root)
	var mission_data=[["Ashwood Patrol","2 hours","Ore and ●"],["Supply Run","45 minutes","Crafting Materials"],["Scout Mirefang","4 hours","Map Intel"]]
	var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",18); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(columns)
	var missions:=VBoxContainer.new(); missions.custom_minimum_size.x=350; missions.add_theme_constant_override("separation",10); columns.add_child(missions); missions.add_child(label("AVAILABLE MISSIONS",14,C_MUTED))
	for i in mission_data.size():
		var mission_button:=Button.new(); mission_button.text="%s\n%s"%[mission_data[i][0],mission_data[i][1]]; mission_button.custom_minimum_size=Vector2(340,78); if i==selected_mission:mission_button.add_theme_stylebox_override("normal",ui_box(Color("26384e"),9,C_GOLD,2)); mission_button.pressed.connect(func(index=i):selected_mission=index;show_command_table()); missions.add_child(mission_button)
	var chosen=mission_data[selected_mission]; var details:=VBoxContainer.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",14); columns.add_child(details); details.add_child(label(chosen[0],30,C_TEXT)); details.add_child(label(chosen[1],18,C_GOLD)); details.add_child(label("REWARDS",13,C_MUTED)); details.add_child(label(chosen[2],20,C_GREEN)); details.add_child(label("ASSIGNED HEROES",13,C_MUTED)); var slots:=HBoxContainer.new(); details.add_child(slots); for i in 4:var slot:=Button.new();slot.text="+";slot.custom_minimum_size=Vector2(110,90);slots.add_child(slot); details.add_child(button("Assign Heroes",func(): flash("Hero assignment is the next automation step."),220))

func auto_run(i:int) -> void:
	if state.gold<40: flash("Not enough gold."); return
	state.gold-=40; grant_rewards(i,false); save_game(); flash("Expedition complete. Reduced auto-run rewards delivered."); show_dungeons()

func show_market() -> void:
	screen="market"; var root=base_screen("Market"); nav(root)
	var gold_row:=HBoxContainer.new(); root.add_child(gold_row)
	var gold_label:=label("●  %d" % state.gold,20,C_GOLD); gold_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; gold_row.add_child(gold_label)
	var tabs:=HBoxContainer.new(); tabs.add_theme_constant_override("separation",10); root.add_child(tabs)
	for tab in ["Browse","Sell","My Listings"]: tabs.add_child(button(tab,func(tab_name=tab): flash("%s will be added with the economy system." % tab_name),150))
	root.add_child(rule())
	var categories:=GridContainer.new(); categories.columns=3; categories.add_theme_constant_override("h_separation",18); categories.add_theme_constant_override("v_separation",18); categories.size_flags_horizontal=Control.SIZE_SHRINK_CENTER; root.add_child(categories)
	for category in ["Weapons","Armor","Crafting Materials","Consumables","Recipes","Guild Supplies"]:
		categories.add_child(hub_button(category,"",func(category_name=category): flash("No %s listings yet." % category_name)))

func show_crafting() -> void:
	screen="crafting"; var root=base_screen("Professions"); nav(root)
	var profession_data=[["Alchemy","Field Tonics","3 Herbs","herbs",3,"tonic"],["Blacksmithing","Tempered Arms","4 Ore","ore",4,"gear"],["Enchanting","Arcane Reinforcement","3 Arcane Dust","dust",3,"gear"],["Engineering","Practice Mechanism","4 Ore","ore",4,"gear"],["Herbalism","Gathering Route","No cost","herbs",0,"tonic"],["Leatherworking","Reinforced Leather","3 Herbs","herbs",3,"gear"],["Mining","Ore Survey","No cost","ore",0,"gear"],["Skinning","Field Dressing","No cost","ore",0,"gear"],["Tailoring","Traveling Cloak","3 Arcane Dust","dust",3,"gear"],["Jewelcrafting","Cut Gem","3 Ore","ore",3,"gear"],["Inscription","Arcane Glyph","2 Herbs","herbs",2,"gear"],["Archaeology","Recovered Relic","No cost","ore",0,"gear"],["Cooking","Guild Feast","3 Herbs","herbs",3,"tonic"],["First Aid","Heavy Bandages","2 Herbs","herbs",2,"tonic"],["Fishing","Quiet Waters","No cost","herbs",0,"tonic"]]
	var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",18); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(columns)
	var profession_scroll:=ScrollContainer.new(); profession_scroll.custom_minimum_size=Vector2(360,485); columns.add_child(profession_scroll); var profession_list:=VBoxContainer.new(); profession_list.custom_minimum_size.x=340; profession_list.add_theme_constant_override("separation",8); profession_scroll.add_child(profession_list)
	for i in profession_data.size():
		var entry:=Button.new(); entry.custom_minimum_size=Vector2(330,78); entry.text=profession_data[i][0]; entry.add_theme_color_override("font_color",C_GOLD if i==selected_profession else C_TEXT); if i==selected_profession:entry.add_theme_stylebox_override("normal",ui_box(Color("26384e"),9,C_GOLD,2)); entry.pressed.connect(func(index=i):selected_profession=index;show_crafting()); profession_list.add_child(entry)
	var details:=VBoxContainer.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",14); columns.add_child(details)
	var chosen=profession_data[selected_profession]; details.add_child(label(chosen[0],30,C_GOLD)); details.add_child(label("AVAILABLE RECIPE",13,C_MUTED)); details.add_child(label(chosen[1],24,C_TEXT)); details.add_child(label("Cost  •  "+chosen[2],17,C_MUTED)); details.add_child(button("Craft",func():craft(chosen[3],chosen[4],chosen[5]),190))

func show_crafting_legacy() -> void:
	screen="crafting"; var root=base_screen("Profession Workshop"); nav(root)
	var recipes=[
		["Blacksmithing","Tempered Arms","4 ore",func():craft("ore",4,"gear")],
		["Alchemy","Field Tonics","3 herbs",func():craft("herbs",3,"tonic")],
		["Enchanting","Arcane Reinforcement","3 dust",func():craft("dust",3,"gear")]
	]
	for r in recipes:
		var p=panel(); var line:=HBoxContainer.new(); p.add_child(line); var desc=VBoxContainer.new(); desc.size_flags_horizontal=Control.SIZE_EXPAND_FILL; desc.add_child(label(r[0],15,C_MUTED)); desc.add_child(label(r[1],22,C_GOLD)); desc.add_child(label("Cost: "+r[2],16)); line.add_child(desc); line.add_child(button("Craft",r[3],150)); root.add_child(p)

func craft(resource:String,cost:int,kind:String) -> void:
	if state[resource]<cost: flash("Missing materials."); return
	state[resource]-=cost
	if kind=="gear": for h in state.heroes: h["gear"]+=1
	else: state["tonics"]=state.get("tonics",0)+1
	save_game(); show_crafting(); flash("Craft complete!")

func vault_used()->int: return state.ore+state.herbs+state.dust+state.get("tonics",0)
func request_bag_unlock(slot:int) -> void:
	if slot<state.vault_level:return
	var cost=120*state.vault_level; var dialog:=ConfirmationDialog.new(); dialog.title="Unlock Bag Slot"; dialog.dialog_text="Unlock this bag slot for ● %d?" % cost; dialog.ok_button_text="Unlock"
	dialog.confirmed.connect(func():
		if state.gold>=cost: state.gold-=cost; state.vault_level+=1; state.vault_limit=min(180,state.vault_limit+10); save_game(); show_vault()
		else: flash("Not enough gold."))
	ui.add_child(dialog); dialog.popup_centered(Vector2i(420,180))

func show_vault() -> void:
	screen="vault"; var root=base_screen("Item Storage"); nav(root)
	var toolbar:=HBoxContainer.new(); toolbar.custom_minimum_size.y=44; toolbar.size_flags_vertical=Control.SIZE_SHRINK_BEGIN; root.add_child(toolbar)
	var vault_gold:=label("●  %d" % state.gold,18,C_GOLD); vault_gold.custom_minimum_size.x=220; vault_gold.autowrap_mode=TextServer.AUTOWRAP_OFF; toolbar.add_child(vault_gold)
	var spacer:=Control.new(); spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL; toolbar.add_child(spacer)
	var organize:=compact_button("▦↕",func(): flash("Vault organized by item type."),58); organize.custom_minimum_size.y=42; organize.size_flags_vertical=Control.SIZE_SHRINK_CENTER; organize.tooltip_text="Auto Organize"; toolbar.add_child(organize)
	var item_grid:=GridContainer.new(); item_grid.columns=10; item_grid.add_theme_constant_override("h_separation",6); item_grid.add_theme_constant_override("v_separation",6); item_grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER; root.add_child(item_grid)
	var contents=[{"name":"Ore","count":state.ore,"color":Color("a9b5c7")},{"name":"Herbs","count":state.herbs,"color":C_GREEN},{"name":"Dust","count":state.dust,"color":Color("b381ff")},{"name":"Tonics","count":state.get("tonics",0),"color":Color("6ed9ef")}]
	for slot in state.vault_limit:
		var cell:=Button.new(); cell.custom_minimum_size=Vector2(68,62)
		if slot<contents.size() and contents[slot].count>0: cell.text="%s\n%d" % [contents[slot].name,contents[slot].count]; cell.add_theme_color_override("font_color",contents[slot].color)
		else: cell.text=""
		item_grid.add_child(cell)
	var bags:=HBoxContainer.new(); bags.add_theme_constant_override("separation",8); bags.alignment=BoxContainer.ALIGNMENT_CENTER; root.add_child(bags)
	for slot in 6:
		var bag:=Button.new(); bag.custom_minimum_size=Vector2(76,64); bag.text="▣" if slot<state.vault_level else "▧"; bag.add_theme_font_size_override("font_size",30); bag.modulate=Color.WHITE if slot<state.vault_level else Color(.35,.38,.45,1); bag.tooltip_text="Installed bag" if slot<state.vault_level else "Locked bag slot"; bag.pressed.connect(func(i=slot):request_bag_unlock(i)); bags.add_child(bag)

func show_vault_legacy() -> void:
	screen="vault"; var root=base_screen("Guild Vault"); nav(root)
	var p=panel(); root.add_child(p); p.add_child(label("Storage %d / %d"%[vault_used(),state.vault_limit],27,C_GOLD)); p.add_child(label("Ore: %d    Herbs: %d    Arcane Dust: %d    Field Tonics: %d"%[state.ore,state.herbs,state.dust,state.get("tonics",0)],18)); p.add_child(label("Upgrade cost: %d gold  •  +15 storage"%(120*state.vault_level),16,C_MUTED)); p.add_child(button("Upgrade Vault",func():
		var cost=120*state.vault_level
		if state.gold>=cost: state.gold-=cost; state.vault_level+=1; state.vault_limit+=15; save_game(); show_vault()
		else: flash("Not enough gold."),210))

func start_battle(id:int,node:int=0) -> void:
	dungeon_id=id; encounter_id=node; clear_all(); ui.visible=false; combat_layer.visible=true; screen="combat"; battle_time=0; spawn_timer=0; battle_over=false; paused=false; selected=0; wave_index=0; total_waves=3+(1 if node>=3 else 0); wave_spawn_remaining=0; wave_break=.8; waiting_wave=false
	var starts=[Vector2(295,190),Vector2(295,285),Vector2(295,380),Vector2(295,475)]
	for i in min(4,state.selected_team.size()):
		var data=state.heroes[state.selected_team[i]]; var c=CLASSES[data["class"]]; heroes.append({"name":data.name,"class":data["class"],"pos":starts[i],"dest":starts[i],"hp":c.hp+data.level*15,"max_hp":c.hp+data.level*15,"damage":(c.damage+data.gear*.5)*.78,"range":c.range,"target":-1,"heal_target":-1,"cooldown":0.0,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"shield":0.0,"last_hit":0.0})
	queue_redraw()

func begin_next_wave() -> void:
	wave_index+=1; wave_spawn_remaining=2+int(encounter_id/2.0)+(1 if dungeon_id>0 else 0); spawn_timer=.2
	if wave_index==total_waves: wave_spawn_remaining+=1

func spawn_wave_enemy() -> void:
	var roles=["Raider","Swift","Archer","Raider","Shaman","Brute"]
	var is_boss=wave_index==total_waves and wave_spawn_remaining==1
	var role="Boss" if is_boss else roles[(wave_index+wave_spawn_remaining+encounter_id)%roles.size()]
	var side=(wave_index+wave_spawn_remaining)%4; var entry=[Vector2(950,165+(wave_spawn_remaining*73)%315),Vector2(390+(wave_spawn_remaining*97)%430,140),Vector2(950,490-(wave_spawn_remaining*61)%260),Vector2(410+(wave_spawn_remaining*67)%400,525)][side]
	spawn_enemy(entry,role); wave_spawn_remaining-=1; spawn_timer=.65

func spawn_enemy(pos:Vector2,type:String) -> void:
	var boss=type=="Boss"; var base_hp=360.0 if boss else 115.0 if type=="Brute" else 82.0
	enemies.append({"type":type,"pos":pos,"hp":base_hp*(1+dungeon_id*.25),"max_hp":base_hp*(1+dungeon_id*.25),"damage":16.0+dungeon_id*4+(10 if boss else 0),"cooldown":1.0,"telegraph":0.0,"target":0,"special":"","special_index":0,"danger_pos":pos,"summoned":false,"enraged":false,"revealed":false})

func _process(delta:float) -> void:
	if toast_time>0: toast_time-=delta; queue_redraw()
	if team_inspect_time>0:
		team_inspect_time-=delta
		if team_inspect_time<=0:team_inspect_candidate=-1;if screen=="team":show_team()
	if victory_sequence: update_victory(delta); return
	if screen!="combat" or battle_over or paused: return
	battle_time+=delta
	spawn_timer=max(0,spawn_timer-delta); wave_break=max(0,wave_break-delta)
	if wave_index==0 and wave_break<=0: begin_next_wave()
	if wave_spawn_remaining>0 and spawn_timer<=0: spawn_wave_enemy()
	if wave_spawn_remaining==0 and wave_index<total_waves and enemies.size()>0 and enemies.all(func(foe):return foe.hp<=0):
		if not waiting_wave: waiting_wave=true; wave_break=2.2
		elif wave_break<=0: waiting_wave=false; begin_next_wave()
	for fx in effects: fx.life-=delta
	effects=effects.filter(func(fx):return fx.life>0)
	for i in heroes.size():
		var h=heroes[i]; if h.hp<=0: continue
		h.cooldown=max(0,h.cooldown-delta); h.shield=max(0,h.shield-delta)
		h.last_hit=max(0,h.last_hit-delta)
		for slot in 5: h.ability_cds[slot]=max(0,h.ability_cds[slot]-delta)
		var hero_speed=86.0 if h["class"]=="Guardian" else 96.0 if h["class"]=="Cleric" else 100.0
		var d=h.pos.distance_to(h.dest); if d>4: h.pos=h.pos.move_toward(h.dest,hero_speed*delta)
		var healed=false
		if h["class"]=="Cleric":
			var low=h.heal_target if h.heal_target>=0 and h.heal_target<heroes.size() and heroes[h.heal_target].hp>0 else -1
			if low>=0 and heroes[low].hp<heroes[low].max_hp*.82 and h.cooldown<=0:
				heroes[low].hp=min(heroes[low].max_hp,heroes[low].hp+32);add_effect("heal",h.pos,heroes[low].pos,"+32",C_GREEN);h.cooldown=1.7;healed=true
		if not healed:
			if h.target>=0 and (h.target>=enemies.size() or enemies[h.target].hp<=0):h.target=-1
			if h.target>=0 and h.target<enemies.size() and enemies[h.target].hp>0:
				var target_enemy=enemies[h.target];var attack_distance=h.pos.distance_to(target_enemy.pos)
				if attack_distance>h.range*.88 and d<=4:h.pos=h.pos.move_toward(target_enemy.pos,hero_speed*.78*delta);h.dest=h.pos
				elif attack_distance<=h.range and h.cooldown<=0:
					target_enemy.hp-=h.damage; target_enemy.revealed=true; add_effect("projectile" if h.range>100 else "slash",h.pos,target_enemy.pos,"-%d"%int(h.damage),CLASSES[h["class"]].color);h.cooldown=1.25 if h["class"]=="Guardian" else 1.4 if h["class"]=="Cleric" else 1.1
	for enemy_index in enemies.size():
		var e=enemies[enemy_index]
		if e.hp<=0: continue
		e.cooldown=max(0,e.cooldown-delta)
		if e.type=="Shaman" and e.cooldown<=0:
			var wounded=-1; var lowest=1.0
			for ally_i in enemies.size():
				if enemies[ally_i].hp>0 and enemies[ally_i].hp/enemies[ally_i].max_hp<lowest: lowest=enemies[ally_i].hp/enemies[ally_i].max_hp; wounded=ally_i
			if wounded>=0 and lowest<.8: enemies[wounded].hp=min(enemies[wounded].max_hp,enemies[wounded].hp+30); add_effect("heal",e.pos,enemies[wounded].pos,"+30",C_GREEN); e.cooldown=3.2; continue
		var ti=preferred_enemy_target(e); if ti<0: finish_battle(false); return
		e.target=ti; var dist=e.pos.distance_to(heroes[ti].pos)
		if e.type=="Boss" and not e.summoned and e.hp<e.max_hp*.55: e.summoned=true; spawn_enemy(e.pos+Vector2(-70,-60),"Swift"); spawn_enemy(e.pos+Vector2(-70,60),"Raider"); add_effect("cast",e.pos,e.pos,"SUMMON",C_RED)
		if e.type=="Boss" and e.hp<e.max_hp*.25: e.enraged=true
		if e.type=="Boss" and e.cooldown<=0 and e.telegraph<=0:
			e.special=["cleave","charge","danger"][e.special_index%3]; e.special_index+=1; e.telegraph=1.5; e.danger_pos=heroes[ti].pos
		if e.telegraph>0:
			e.telegraph-=delta
			if e.telegraph<=0:
				if e.special=="basic":
					if ti<heroes.size() and heroes[ti].hp>0: var basic_dealt=e.damage if heroes[ti].shield<=0 else e.damage*.35; heroes[ti].hp-=basic_dealt; heroes[ti].last_hit=3.0; add_effect("projectile" if e.type=="Archer" else "hit",e.pos,heroes[ti].pos,"-%d"%int(basic_dealt),C_RED)
				elif e.special=="charge": e.pos=e.pos.move_toward(e.danger_pos,220); for hero_charge in heroes: if hero_charge.hp>0 and hero_charge.pos.distance_to(e.pos)<65: hero_charge.hp-=e.damage*1.25; add_effect("hit",e.pos,hero_charge.pos,"CHARGE",C_RED)
				else:
					var impact=e.danger_pos if e.special=="danger" else e.pos; var radius=78.0 if e.special=="danger" else 115.0
					for struck_hero in heroes:
						if struck_hero.hp>0 and struck_hero.pos.distance_to(impact)<radius: var dealt=e.damage*1.4 if struck_hero.shield<=0 else e.damage*.45; struck_hero.hp-=dealt; add_effect("hit",impact,struck_hero.pos,"-%d"%int(dealt),C_RED)
				e.cooldown=(1.55 if e.type!="Boss" else 2.7 if e.enraged else 4.0)
		elif dist>(185 if e.type=="Archer" or e.type=="Shaman" else 44):
			var enemy_speed=100.0 if e.type=="Swift" else 42.0 if e.type=="Boss" or e.type=="Brute" else 58.0; e.pos=e.pos.move_toward(heroes[ti].pos,enemy_speed*delta)
		elif e.cooldown<=0:
			e.special="basic"; e.telegraph=.48; e.danger_pos=heroes[ti].pos
			if heroes[ti].target<0:heroes[ti].target=enemy_index;heroes[ti].heal_target=-1
	if wave_index==total_waves and wave_spawn_remaining==0 and enemies.size()>0 and enemies.all(func(e):return e.hp<=0): finish_battle(true)
	queue_redraw()

func lowest_hero()->int:
	var idx=-1; var ratio=2.0
	for i in heroes.size(): if heroes[i].hp>0 and heroes[i].hp/heroes[i].max_hp<ratio: ratio=heroes[i].hp/heroes[i].max_hp; idx=i
	return idx
func nearest_living_hero(pos:Vector2)->int:
	var idx=-1; var dist=99999.0
	for i in heroes.size():
		if heroes[i].hp>0:
			var d=pos.distance_to(heroes[i].pos)*(0.55 if heroes[i]["class"]=="Guardian" else 1.0); if d<dist:dist=d;idx=i
	return idx

func preferred_enemy_target(enemy:Dictionary)->int:
	if enemy.type=="Swift" or enemy.type=="Boss" and enemy.special_index%3==1:
		var best=-1; var distance=99999.0
		for i in heroes.size():
			if heroes[i].hp>0 and (heroes[i]["class"]=="Cleric" or heroes[i]["class"]=="Mage"):
				var d=enemy.pos.distance_to(heroes[i].pos); if d<distance: distance=d; best=i
		if best>=0:return best
	return nearest_living_hero(enemy.pos)

func _unhandled_input(event:InputEvent) -> void:
	if screen!="combat":return
	if victory_sequence and victory_phase>=5:
		if event is InputEventMouseButton and event.pressed or event is InputEventKey and event.pressed: victory_sequence=false; show_zone_map(dungeon_id)
		return
	if battle_over:
		if event is InputEventKey and event.pressed:
			if event.keycode==KEY_ESCAPE or event.keycode==KEY_ENTER: show_hall()
			elif event.keycode==KEY_R: start_battle(dungeon_id,encounter_id)
		return
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_SPACE:paused=!paused;queue_redraw()
		if event.keycode==KEY_TAB: selected=(selected+1)%heroes.size(); queue_redraw(); get_viewport().set_input_as_handled()
		if event.keycode>=KEY_1 and event.keycode<=KEY_4: selected=event.keycode-KEY_1; queue_redraw()
		if event.keycode==KEY_Q: use_ability(0)
		if event.keycode==KEY_W: use_ability(1)
		if event.keycode==KEY_E: use_ability(2)
		if event.keycode==KEY_R: use_ability(3)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var p=event.position
		if p.x>1190 and p.y<70: paused=true; queue_redraw(); return
		if paused:
			if Rect2(490,285,300,58).has_point(p):paused=false;queue_redraw()
			elif Rect2(490,360,300,58).has_point(p):paused=false;show_zone_map(dungeon_id)
			return
		if p.y>575 and p.y<635 and p.x>420 and p.x<875: selected=clampi(int((p.x-424)/54),0,heroes.size()-1); queue_redraw(); return
		if p.y>635 and p.x>445 and p.x<835: use_ability(clampi(int((p.x-445)/78),0,4)); return
		for i in heroes.size():
			if heroes[i].pos.distance_to(p)<50:
				selected=i;dragging_hero=true;drag_cursor=p;drag_target_type="ground";drag_target_index=-1;queue_redraw();return
		for i in enemies.size(): if enemies[i].hp>0 and enemies[i].pos.distance_to(p)<50: heroes[selected].target=i;heroes[selected].heal_target=-1;queue_redraw();return
		heroes[selected].dest=Vector2(clamp(p.x,220.0,950.0),clamp(p.y,140.0,525.0));heroes[selected].target=-1;queue_redraw()
	if event is InputEventMouseMotion and dragging_hero:
		drag_cursor=event.position;drag_target_type="ground";drag_target_index=-1
		for i in enemies.size():
			if enemies[i].hp>0 and enemies[i].pos.distance_to(drag_cursor)<45:drag_target_type="enemy";drag_target_index=i;break
		if drag_target_type=="ground" and heroes[selected]["class"]=="Cleric":
			for i in heroes.size():
				if heroes[i].hp>0 and heroes[i].pos.distance_to(drag_cursor)<42:drag_target_type="ally";drag_target_index=i;break
		queue_redraw()
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and dragging_hero:
		dragging_hero=false
		if drag_target_type=="enemy":heroes[selected].target=drag_target_index;heroes[selected].heal_target=-1
		elif drag_target_type=="ally" and heroes[selected]["class"]=="Cleric":heroes[selected].heal_target=drag_target_index;heroes[selected].target=-1
		else:heroes[selected].dest=Vector2(clamp(drag_cursor.x,220.0,950.0),clamp(drag_cursor.y,140.0,525.0));heroes[selected].target=-1
		queue_redraw()

func use_ability(slot:int) -> void:
	if selected>=heroes.size():return
	var h=heroes[selected]
	if slot>=4:return
	if h.hp<=0 or h.ability_cds[slot]>0:return
	h.ability_cds[slot]=[4.0,7.0,8.0,18.0][slot]
	add_effect("heroic" if slot==3 else "cast",h.pos,h.pos,ABILITIES[h["class"]][slot],CLASSES[h["class"]].color)
	match h["class"]:
		"Guardian":
			if slot==0:h.shield=4.0
			elif slot==1:for foe_challenge in enemies:if foe_challenge.hp>0:foe_challenge.target=selected;foe_challenge.pos=foe_challenge.pos.move_toward(h.pos,45)
			elif slot==2:
				h.pos=h.pos.move_toward(get_global_mouse_position(),100);h.dest=h.pos
				for foe_rush in enemies:if foe_rush.hp>0 and foe_rush.pos.distance_to(h.pos)<105:foe_rush.hp-=38
			else:for ally_bastion in heroes:if ally_bastion.hp>0:ally_bastion.shield=5.0
		"Cleric":
			if slot==0:
				var low=lowest_hero();if low>=0:heroes[low].hp=min(heroes[low].max_hp,heroes[low].hp+72)
			elif slot==1:for ally_sanctuary in heroes:if ally_sanctuary.hp>0:ally_sanctuary.hp=min(ally_sanctuary.max_hp,ally_sanctuary.hp+38)
			elif slot==2:
				for ally_purify in heroes:if ally_purify.hp>0:ally_purify.hp=min(ally_purify.max_hp,ally_purify.hp+24)
				for foe_purify in enemies:if foe_purify.hp>0 and foe_purify.pos.distance_to(h.pos)<180:foe_purify.hp-=30
			else:for ally_renewal in heroes:if ally_renewal.hp>0:ally_renewal.hp=min(ally_renewal.max_hp,ally_renewal.hp+110)
		"Ranger":
			if slot==0 and h.target>=0 and h.target<enemies.size():enemies[h.target].hp-=65
			elif slot==1:h.pos=h.pos.move_toward(get_global_mouse_position(),120);h.dest=h.pos
			elif slot==2:for foe_volley in enemies:if foe_volley.hp>0 and foe_volley.pos.distance_to(h.pos)<280:foe_volley.hp-=42
			else:for foe_arrowstorm in enemies:if foe_arrowstorm.hp>0:foe_arrowstorm.hp-=72
		"Mage":
			if slot==0 and h.target>=0 and h.target<enemies.size():enemies[h.target].hp-=78
			elif slot==1:h.pos=get_global_mouse_position().clamp(Vector2(55,100),Vector2(1225,620));h.dest=h.pos
			elif slot==2:for foe_burst in enemies:if foe_burst.hp>0 and foe_burst.pos.distance_to(h.pos)<240:foe_burst.hp-=55
			else:for foe_starfall in enemies:if foe_starfall.hp>0:foe_starfall.hp-=85

func finish_battle(win:bool)->void:
	battle_over=true
	if win:
		state.dungeon_clears[dungeon_id]+=1
		if encounter_id<10:
			state.zone_progress[dungeon_id]=max(int(state.zone_progress[dungeon_id]),min(10,encounter_id+1))
			if encounter_id==9 and dungeon_id==0:
				state.unlocked_dungeon=1
		elif encounter_id<12:
			state.zone_branches[dungeon_id][encounter_id-10]=true
		grant_rewards(dungeon_id,true); save_game()
		effects.clear(); victory_sequence=true; victory_phase=0; victory_timer=0.0
		for i in heroes.size(): heroes[i].dest=Vector2(470+i*105,390)
		queue_redraw(); return
	var overlay:=ColorRect.new(); overlay.color=Color(0.03,0.05,0.09,.96); overlay.position=Vector2(300,120); overlay.size=Vector2(680,480); ui.visible=true; ui.add_child(overlay)
	var box:=VBoxContainer.new(); box.position=Vector2(350,160); box.size=Vector2(580,400); box.add_theme_constant_override("separation",14); ui.add_child(box)
	box.add_child(label("VICTORY" if win else "DEFEAT",38,C_GOLD if win else C_RED)); box.add_child(label(("The guild returns richer and stronger." if win else "Recover, re-equip, and try a new formation."),18,C_MUTED)); if win:box.add_child(label("Rewards: %d gold • XP • materials • dungeon token"%(90+dungeon_id*55),18,C_GREEN)); box.add_spacer(false); box.add_child(button("Return to Guild Hall",show_hall,250))
	box.add_child(button("Retry Encounter",func():start_battle(dungeon_id,encounter_id),250))
	box.add_child(label("Enter / Esc: Guild Hall     R: Retry",15,C_MUTED))

func update_victory(delta:float) -> void:
	victory_timer+=delta
	if victory_phase==0 and victory_timer>=1.2: victory_phase=1; victory_timer=0
	elif victory_phase==1:
		for h in heroes: h.pos=h.pos.move_toward(h.dest,115*delta)
		var gathered=heroes.all(func(h):return h.pos.distance_to(h.dest)<4)
		if gathered or victory_timer>=4.5: victory_phase=2; victory_timer=0
	elif victory_phase==2 and victory_timer>=1.3: victory_phase=3; victory_timer=0
	elif victory_phase==3 and victory_timer>=1.3: victory_phase=4; victory_timer=0
	elif victory_phase==4 and victory_timer>=1.2: victory_phase=5; victory_timer=0
	queue_redraw()

func grant_rewards(id:int,manual:bool)->void:
	var mod=1.0 if manual else .7; state.gold+=int((90+id*55)*mod); state.tokens+=1; state.ore+=int((3+id)*mod); state.herbs+=int((2+id*2)*mod); if id==1:state.dust+=int(3*mod)
	for h in state.heroes:
		h.xp+=int((55+id*35)*mod)
		while h.xp>=h.level*100: h.xp-=h.level*100; h.level+=1; h.gear+=1

func octagon_points(center:Vector2,radius:float) -> PackedVector2Array:
	var points:=PackedVector2Array()
	for i in 8: points.append(center+Vector2(cos(PI/8+i*PI/4),sin(PI/8+i*PI/4))*radius)
	return points

func draw_octagon(center:Vector2,radius:float,fill:Color,outline:Color,width:float=3.0) -> void:
	var points=octagon_points(center,radius); draw_colored_polygon(points,fill); points.append(points[0]); draw_polyline(points,outline,width)

func _draw() -> void:
	if screen!="combat":return
	draw_rect(Rect2(0,0,W,H),Color("18283a"))
	for x in range(60,1240,80): draw_line(Vector2(x,85),Vector2(x,630),Color(1,1,1,.025),1)
	for y in range(100,630,80): draw_line(Vector2(35,y),Vector2(1245,y),Color(1,1,1,.025),1)
	for i in enemies.size():
		var e=enemies[i]; if e.hp<=0:continue
		if e.telegraph>0:
			var warning_pos=e.danger_pos if e.special=="danger" or e.special=="charge" or e.special=="basic" else e.pos; var warning_radius=38.0 if e.special=="basic" else 78.0 if e.special=="danger" else 115.0
			draw_circle(warning_pos,warning_radius,Color(1,.15,.12,.16));draw_arc(warning_pos,warning_radius,0,TAU,48,C_RED,3)
			if e.special=="charge": draw_dashed_line(e.pos,e.danger_pos,C_RED,5,10)
		var enemy_color={"Raider":Color("bd4d58"),"Swift":Color("e05f8f"),"Archer":Color("8f68d8"),"Shaman":Color("58a878"),"Brute":Color("d97a45"),"Boss":Color("e5863f")}.get(e.type,Color("bd4d58"))
		draw_circle(e.pos,41,enemy_color); draw_circle(e.pos,46,Color.WHITE if heroes.size()>selected and heroes[selected].target==i else Color("5f2931"),4); if not victory_sequence and (e.revealed or e.hp<e.max_hp):health_bar(e.pos+Vector2(-48,-62),96,e.hp/e.max_hp,C_RED); draw_string(ThemeDB.fallback_font,e.pos+Vector2(-36,6),e.type.substr(0,7),HORIZONTAL_ALIGNMENT_CENTER,72,14,C_TEXT)
	for i in heroes.size():
		var h=heroes[i]; var col=CLASSES[h["class"]].color; if h.hp<=0:col=Color("455067")
		if i==selected:
			draw_circle(h.pos,58,Color(C_GOLD,.18));draw_circle(h.pos,52,C_GOLD,4)
		if h.shield>0:draw_circle(h.pos,56,Color("5fa8ff"),4)
		draw_circle(h.pos,42,col);draw_role_icon(h.pos,h["class"]);if not victory_sequence and (h.hp<h.max_hp or h.last_hit>0):health_bar(h.pos+Vector2(-48,-62),96,max(0,h.hp/h.max_hp),C_GREEN)
	if dragging_hero:
		draw_dashed_line(heroes[selected].pos,drag_cursor,Color(C_GOLD,.75),6,8)
		var preview_color=C_GREEN if drag_target_type=="ally" else (C_RED if drag_target_type=="enemy" else C_GOLD)
		var preview_pos=drag_cursor
		if drag_target_type=="enemy":preview_pos=enemies[drag_target_index].pos
		elif drag_target_type=="ally":preview_pos=heroes[drag_target_index].pos
		draw_circle(preview_pos,42,Color(preview_color,.14));draw_arc(preview_pos,42,0,TAU,40,preview_color,4)
	for fx in effects: draw_combat_effect(fx)
	for i in 8:
		var center=Vector2(451+i*54,604); var occupied=i<heroes.size(); draw_octagon(center,26,C_PANEL_2 if occupied else Color(0.06,.08,.12,.65),C_GOLD if i==selected and occupied else Color("536178"),3)
		if occupied: draw_role_icon(center-Vector2(0,4),heroes[i]["class"]); draw_string(ThemeDB.fallback_font,center+Vector2(-8,20),str(i+1),HORIZONTAL_ALIGNMENT_CENTER,16,11,C_GOLD)
	if heroes.size()>selected:
		var active=heroes[selected];var keys=["Q","W","E","R",""]
		for slot in 5:
			var center=Vector2(484+slot*78,674); draw_octagon(center,37,Color("263a57") if slot<3 else Color("59402b"),C_MUTED,3); draw_string(ThemeDB.fallback_font,center+Vector2(-34,-4),(ABILITIES[active["class"]][slot] if slot<4 else TRAITS[active["class"]]).substr(0,10),HORIZONTAL_ALIGNMENT_CENTER,68,10,C_TEXT); draw_string(ThemeDB.fallback_font,center+Vector2(-28,25),keys[slot],HORIZONTAL_ALIGNMENT_CENTER,56,14,C_GOLD)
			if active.ability_cds[slot]>0:draw_octagon(center,37,Color(0,0,0,.62),C_MUTED,2);draw_string(ThemeDB.fallback_font,center+Vector2(-18,7),"%.1f"%active.ability_cds[slot],HORIZONTAL_ALIGNMENT_CENTER,36,15,C_TEXT)
	draw_circle(Vector2(1235,42),25,Color(0.08,.11,.16,.9)); draw_string(ThemeDB.fallback_font,Vector2(1222,50),"Ⅱ",HORIZONTAL_ALIGNMENT_LEFT,-1,22,C_TEXT)
	if paused:
		draw_rect(Rect2(390,190,500,300),Color(0.03,.05,.08,.94)); draw_string(ThemeDB.fallback_font,Vector2(565,250),"PAUSED",HORIZONTAL_ALIGNMENT_LEFT,-1,34,C_GOLD); draw_rect(Rect2(490,285,300,58),C_PANEL_2); draw_string(ThemeDB.fallback_font,Vector2(600,322),"RESUME",HORIZONTAL_ALIGNMENT_LEFT,-1,20,C_TEXT); draw_rect(Rect2(490,360,300,58),C_PANEL_2); draw_string(ThemeDB.fallback_font,Vector2(600,397),"RETREAT",HORIZONTAL_ALIGNMENT_LEFT,-1,20,C_RED)
	if victory_sequence:
		draw_string(ThemeDB.fallback_font,Vector2(400,92),"VICTORY",HORIZONTAL_ALIGNMENT_CENTER,480,72,C_GOLD)
		if victory_phase>=2:draw_string(ThemeDB.fallback_font,Vector2(420,185),"●  +%d"%(90+dungeon_id*55),HORIZONTAL_ALIGNMENT_CENTER,440,42,C_GOLD)
		if victory_phase>=3:draw_string(ThemeDB.fallback_font,Vector2(390,235),"MATERIALS COLLECTED",HORIZONTAL_ALIGNMENT_CENTER,500,30,C_GREEN)
		if victory_phase>=4:draw_string(ThemeDB.fallback_font,Vector2(390,280),"SPECIAL REWARD",HORIZONTAL_ALIGNMENT_CENTER,500,30,Color("b381ff"))
		if victory_phase>=5:
			for i in heroes.size(): var xp_data=state.heroes[state.selected_team[i]]; var xp_ratio=float(xp_data.xp)/max(1,xp_data.level*100)*clamp(victory_timer/2.0,0,1); health_bar(Vector2(425+i*105,435),90,xp_ratio,Color("6aa7ff"))
			draw_string(ThemeDB.fallback_font,Vector2(440,540),"Click To Continue",HORIZONTAL_ALIGNMENT_CENTER,400,24,C_MUTED)
	if toast_time>0:draw_string(ThemeDB.fallback_font,Vector2(480,680),toast,HORIZONTAL_ALIGNMENT_LEFT,-1,17,C_GOLD)

func health_bar(pos:Vector2,width:float,ratio:float,color:Color)->void:
	draw_rect(Rect2(pos,Vector2(width,7)),Color("11151e"));draw_rect(Rect2(pos,Vector2(width*clamp(ratio,0,1),7)),color)
func add_effect(kind:String,from:Vector2,to:Vector2,text_value:String,color:Color)->void:
	effects.append({"kind":kind,"from":from,"to":to,"text":text_value,"color":color,"life":.75 if kind!="heroic" else 1.25,"max_life":.75 if kind!="heroic" else 1.25})
func draw_combat_effect(fx:Dictionary)->void:
	var progress=1.0-fx.life/fx.max_life
	var alpha=clamp(fx.life*2.0,0.0,1.0)
	var col=Color(fx.color,alpha)
	match fx.kind:
		"projectile":
			var p=fx.from.lerp(fx.to,clamp(progress*1.8,0.0,1.0));draw_line(p-Vector2(12,0),p+Vector2(8,0),col,5);draw_circle(p,5,Color.WHITE)
		"slash":
			draw_line(fx.to+Vector2(-22,-18),fx.to+Vector2(22,18),col,7);draw_line(fx.to+Vector2(-16,22),fx.to+Vector2(18,-16),Color.WHITE,3)
		"hit":
			draw_circle(fx.to,28+progress*22,Color(col,.16));draw_line(fx.from,fx.to,col,4)
		"heal":
			draw_line(fx.from,fx.to,col,4);draw_circle(fx.to,25+progress*30,Color(col,.18));draw_arc(fx.to,25+progress*30,0,TAU,30,col,3)
		"cast":
			draw_arc(fx.from,30+progress*18,0,TAU,32,col,4)
		"heroic":
			draw_circle(fx.from,38+progress*80,Color(col,.14));draw_arc(fx.from,38+progress*80,0,TAU,40,col,6)
	if fx.text!="":
		var text_pos=fx.to+Vector2(-28,-48-progress*30)
		draw_string(ThemeDB.fallback_font,text_pos,fx.text,HORIZONTAL_ALIGNMENT_CENTER,90,17,col)
func draw_role_icon(pos:Vector2,hero_class:String)->void:
	var ink=Color("101827")
	if hero_class=="Guardian":
		var shield=PackedVector2Array([pos+Vector2(-11,-13),pos+Vector2(11,-13),pos+Vector2(9,5),pos+Vector2(0,15),pos+Vector2(-9,5)])
		draw_colored_polygon(shield,ink);draw_polyline(shield+PackedVector2Array([shield[0]]),Color.WHITE,2)
	elif hero_class=="Cleric":
		draw_rect(Rect2(pos+Vector2(-5,-15),Vector2(10,30)),ink);draw_rect(Rect2(pos+Vector2(-15,-5),Vector2(30,10)),ink)
	elif hero_class=="Mage":
		draw_line(pos+Vector2(-11,13),pos+Vector2(8,-8),ink,5);draw_circle(pos+Vector2(11,-11),6,ink);draw_circle(pos+Vector2(11,-11),2,Color.WHITE)
	else:
		# Ranged DPS use a bow marker. Future melee classes can use crossed swords.
		draw_arc(pos+Vector2(-3,0),15,-PI/2,PI/2,18,ink,4);draw_line(pos+Vector2(-3,-15),pos+Vector2(-3,15),ink,2);draw_line(pos+Vector2(-3,0),pos+Vector2(15,0),ink,3);draw_colored_polygon(PackedVector2Array([pos+Vector2(15,0),pos+Vector2(8,-5),pos+Vector2(8,5)]),ink)
func flash(msg:String)->void:toast=msg;toast_time=2.5;queue_redraw()
