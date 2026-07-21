extends "res://scripts/ui/hero_roster_screen.gd"

func compact_button(text:String, callback:Callable, width:float=100) -> Button:
	return UiFactory.compact_button(text,callback,width)


func select_team_slot(option:int) -> void:
	current_team_slot=option-1
	state.selected_team=TeamManager.sanitize_team(state.active_team if current_team_slot<0 else state.saved_teams[current_team_slot],state.heroes)
	if current_team_slot<0:state.active_team=state.selected_team.duplicate()
	else:state.saved_teams[current_team_slot]=state.selected_team.duplicate()
	save_game()
	save_game(); show_team()

func rename_current_team(value:String) -> void:
	var name_index:=clampi(current_team_slot+1,0,4)
	if value.strip_edges()!="":state.team_names[name_index]=value.strip_edges();save_game()

func show_team() -> void:
	current_team_slot=clampi(current_team_slot,-1,3)
	screen="team"; var root=base_screen("Team Builder")
	var chooser:=HBoxContainer.new(); chooser.add_theme_constant_override("separation",10); root.add_child(chooser)
	var teams:=OptionButton.new(); teams.name="TeamSelector"; teams.custom_minimum_size=Vector2(260,44)
	for option_index in 5:teams.add_item(str(state.team_names[option_index]))
	teams.select(clampi(current_team_slot+1,0,4)); teams.item_selected.connect(select_team_slot); chooser.add_child(teams)
	var rename:=LineEdit.new(); rename.placeholder_text="Team name"; rename.text=state.team_names[clampi(current_team_slot+1,0,4)]; rename.custom_minimum_size=Vector2(220,44); rename.text_submitted.connect(func(value): rename_current_team(value); show_team()); chooser.add_child(rename)
	var chooser_space:=Control.new(); chooser_space.size_flags_horizontal=Control.SIZE_EXPAND_FILL; chooser.add_child(chooser_space)
	var party_count:=label("%d / 4" % state.selected_team.size(),18,C_GOLD); party_count.custom_minimum_size.x=60; party_count.autowrap_mode=TextServer.AUTOWRAP_OFF; party_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; chooser.add_child(party_count)
	team_active_zone=VBoxContainer.new(); team_active_zone.custom_minimum_size=Vector2(1160,100); root.add_child(team_active_zone)
	team_active_row=HBoxContainer.new();team_active_row.name="TeamActiveRow";team_active_row.add_theme_constant_override("separation",12);team_active_zone.add_child(team_active_row)
	for slot_index in state.selected_team.size():team_active_row.add_child(make_team_card(state.selected_team[slot_index],"active",slot_index))
	var formation_names:=["Front","Top","Bottom","Back"]
	for slot_index in range(state.selected_team.size(),4):var empty:=Button.new();empty.text="%d  %s\nEmpty"%[slot_index+1,formation_names[slot_index].to_upper()];empty.tooltip_text="Party slot %d — %s position."%[slot_index+1,formation_names[slot_index]];empty.disabled=true;empty.custom_minimum_size=Vector2(180,100);empty.add_theme_stylebox_override("disabled",ui_box(Color("182231"),4,Color("2b394d"),1));team_active_row.add_child(empty)
	var party_roster_gap:=Control.new();party_roster_gap.custom_minimum_size.y=24;root.add_child(party_roster_gap)
	var roster_heading:=HBoxContainer.new(); root.add_child(roster_heading); var roster_title:=label("GUILD ROSTER",18,C_GOLD); roster_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; roster_heading.add_child(roster_title)
	root.add_child(filter_bar(show_team,true,true))
	team_reserve_zone=VBoxContainer.new(); team_reserve_zone.custom_minimum_size=Vector2(1160,180); team_reserve_zone.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(team_reserve_zone)
	var carousel:=HBoxContainer.new(); carousel.add_theme_constant_override("separation",8); team_reserve_zone.add_child(carousel)
	var previous_page:=compact_button("←",func(): team_roster_page=max(0,team_roster_page-1); show_team(),42);apply_sharp_compact_style(previous_page);carousel.add_child(previous_page)
	var reserves:=GridContainer.new();reserves.name="TeamReserveGrid";reserves.columns=5; reserves.add_theme_constant_override("h_separation",12); reserves.add_theme_constant_override("v_separation",12); reserves.size_flags_horizontal=Control.SIZE_EXPAND_FILL; carousel.add_child(reserves)
	var roster_indices=sorted_hero_indices().filter(func(idx):return not team_has_member(idx)); var page_count=max(1,int(ceil(roster_indices.size()/10.0))); team_roster_page=clampi(team_roster_page,0,page_count-1)
	for card_index in range(team_roster_page*10,min(roster_indices.size(),team_roster_page*10+10)):
		reserves.add_child(make_team_card(roster_indices[card_index],"reserve"))
	if roster_indices.is_empty(): var empty_message:=label("All available heroes are assigned to this team.",16,C_MUTED); empty_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; empty_message.size_flags_horizontal=Control.SIZE_EXPAND_FILL; reserves.add_child(empty_message)
	var next_page:=compact_button("→",func(): team_roster_page=min(page_count-1,team_roster_page+1); show_team(),42);apply_sharp_compact_style(next_page);carousel.add_child(next_page)
