extends "res://scripts/runtime/app_core.gd"

const AbilityKeyBadge = preload("res://scripts/ui/ability_key_badge.gd")
const GuardianAbilityPresenter = preload("res://scripts/data/guardian_ability_presenter.gd")
const ClericAbilityPresenter = preload("res://scripts/data/cleric_ability_presenter.gd")
const RangerAbilityPresenter = preload("res://scripts/data/ranger_ability_presenter.gd")
const MageAbilityPresenter = preload("res://scripts/data/mage_ability_presenter.gd")
const WarlockAbilityPresenter = preload("res://scripts/data/warlock_ability_presenter.gd")
const TalentTierView = preload("res://scripts/ui/talent_tier_view.gd")
const EquipmentSlotSilhouette = preload("res://scripts/ui/equipment_slot_silhouette.gd")

func make_roster_ability_row(key_text:String,title:String,description:String,accent:Color,locked:bool=false,details_action:Callable=Callable())->PanelContainer:
	var card:=PanelContainer.new();card.name="RosterTrait" if key_text=="D" else "RosterAbility%s"%key_text;card.custom_minimum_size=Vector2(600,58);card.add_theme_stylebox_override("panel",ui_box(Color("182334") if not locked else Color("151e2c"),6,Color("35445a"),1))
	if not locked and details_action.is_valid():
		card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		card.gui_input.connect(func(event):
			if (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):details_action.call())
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);card.add_child(row)
	var badge:=AbilityKeyBadge.new();badge.name="AbilityKeyBadge";badge.configure(key_text,accent,locked);row.add_child(badge)
	var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.alignment=BoxContainer.ALIGNMENT_CENTER;copy.add_theme_constant_override("separation",2);row.add_child(copy)
	var heading:=label(title,16,C_MUTED if locked else C_TEXT);copy.add_child(heading)
	var body:=label(description,13,C_MUTED);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_child(body)
	return card

func close_roster_ability_details(overlay:Control)->void:
	if overlay!=null and is_instance_valid(overlay):overlay.queue_free()

func fit_roster_ability_details(panel:PanelContainer,scroll:ScrollContainer,body:VBoxContainer)->void:
	await get_tree().process_frame
	if not is_instance_valid(panel) or not is_instance_valid(scroll) or not is_instance_valid(body):return
	var body_height:=body.get_combined_minimum_size().y
	var desired_height:=clampf(body_height+160.0,230.0,580.0)
	panel.size=Vector2(680,desired_height)
	panel.position=Vector2((W-panel.size.x)*.5,(H-panel.size.y)*.5)
	scroll.custom_minimum_size.y=minf(body_height,desired_height-160.0)

func open_roster_ability_details(hero:Dictionary,action_key:String,heroic_id:String="")->void:
	var details:Dictionary
	if str(hero.get("class",""))=="Guardian":details=GuardianAbilityPresenter.details(hero,action_key,heroic_id,float(hero_final_stats(hero).power))
	elif str(hero.get("class",""))=="Cleric":
		var presenter_hero:=hero.duplicate(true);presenter_hero["power"]=float(hero_final_stats(hero).power)
		if not presenter_hero.has("cleric_runtime"):ClericSystem.initialize_runtime(presenter_hero,false)
		details=ClericAbilityPresenter.details(presenter_hero,action_key,heroic_id)
	elif str(hero.get("class",""))=="Ranger":
		var presenter_hero:=hero.duplicate(true);presenter_hero["ranger_runtime"]=hero.get("ranger_runtime",{})
		if presenter_hero.ranger_runtime.is_empty():RangerSystem.initialize_runtime(presenter_hero,is_testing_save())
		details=RangerAbilityPresenter.details(presenter_hero,action_key,heroic_id)
	elif str(hero.get("class",""))=="Mage":
		var presenter_hero:=hero.duplicate(true);var presenter_stats:=hero_final_stats(hero);presenter_hero["power"]=float(presenter_stats.power);presenter_hero["stats"]=presenter_stats;presenter_hero["base_ability_power_percent"]=float(presenter_stats.get("ability_power_percent",0.0))
		if presenter_hero.get("mage_runtime",{}).is_empty():MageSystem.initialize_runtime(presenter_hero,is_testing_save())
		details=MageAbilityPresenter.details(presenter_hero,action_key,heroic_id)
	elif str(hero.get("class",""))=="Warlock":
		var presenter_hero:=hero.duplicate(true);var presenter_stats:=hero_final_stats(hero);presenter_hero["power"]=float(presenter_stats.power);presenter_hero["stats"]=presenter_stats;presenter_hero["max_hp"]=float(presenter_stats.health);presenter_hero["hp"]=float(presenter_stats.health);presenter_hero["ability_cds"]=[0.0,0.0,0.0,0.0,0.0]
		WarlockSystem.initialize_runtime(presenter_hero,false)
		details=WarlockAbilityPresenter.details(presenter_hero,action_key,heroic_id)
	else:
		var action_keys:Array=["Q","W","E","R"];var slot:=action_keys.find(action_key)
		details={"key":action_key,"title":str(TRAITS[hero["class"]]) if action_key=="D" else str(ABILITIES[hero["class"]][slot]),"meta":"Passive Trait" if action_key=="D" else "Ability","description":"Passive Trait" if action_key=="D" else ability_tooltip(hero["class"],slot),"sections":[],"note":""}
	var overlay:=Control.new();overlay.name="RosterAbilityDetailsOverlay";overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_STOP;ui.add_child(overlay)
	var backdrop:=Button.new();backdrop.name="RosterAbilityDetailsBackdrop";backdrop.flat=true;backdrop.focus_mode=Control.FOCUS_NONE;backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.add_theme_stylebox_override("normal",ui_box(Color(0.01,0.02,0.04,.78),0));backdrop.pressed.connect(func():close_roster_ability_details(overlay));overlay.add_child(backdrop)
	var panel:=PanelContainer.new();panel.name="RosterAbilityDetailsCard";panel.position=Vector2(300,230);panel.size=Vector2(680,260);panel.add_theme_stylebox_override("panel",ui_box(Color("1b283a"),10,CLASSES[hero["class"]].color,2));overlay.add_child(panel)
	var margin:=MarginContainer.new();margin.add_theme_constant_override("margin_left",26);margin.add_theme_constant_override("margin_right",26);margin.add_theme_constant_override("margin_top",24);margin.add_theme_constant_override("margin_bottom",24);panel.add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);margin.add_child(column)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",16);column.add_child(header)
	var badge:=AbilityKeyBadge.new();badge.name="RosterAbilityDetailsBadge";badge.configure(str(details.key),CLASSES[hero["class"]].color,false);header.add_child(badge)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(identity)
	identity.add_child(label(str(details.title),27,CLASSES[hero["class"]].color))
	identity.add_child(label(str(details.meta),14,C_MUTED))
	column.add_child(rule())
	var scroll:=ScrollContainer.new();scroll.name="RosterAbilityDetailsScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",13);scroll.add_child(body)
	var description:=label(str(details.description),16,C_TEXT);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(description)
	for section in details.sections:
		body.add_child(label(str(section.heading),14,C_GOLD))
		var section_body:=label(str(section.body),14,C_MUTED);section_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;section_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(section_body)
	if str(details.note)!="":
		body.add_child(rule())
		var note:=label(str(details.note),12,C_MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(note)
	fit_roster_ability_details(panel,scroll,body)

func guardian_talent_name(talent_id:String)->String:
	if talent_id.begins_with("cleric_"):return str(ClericData.WORKING_NAMES.get(talent_id,talent_id.replace("_"," ").capitalize()))
	if talent_id.begins_with("ranger_"):return str(RangerData.WORKING_NAMES.get(talent_id,talent_id.replace("_"," ").capitalize()))
	if talent_id.begins_with("mage_"):return str(MageData.WORKING_NAMES.get(talent_id,talent_id.replace("_"," ").capitalize()))
	if talent_id.begins_with("warlock_"):return str(WarlockData.WORKING_NAMES.get(talent_id,talent_id.replace("_"," ").capitalize()))
	return str(GuardianData.WORKING_NAMES.get(talent_id,talent_id.replace("_"," ").capitalize()))

func roster_talent_description(hero_class:String,option_id:String)->String:
	if hero_class=="Guardian":return str(GuardianData.TALENT_DESCRIPTIONS.get(option_id,"Talent details are still being developed."))
	if hero_class=="Cleric":return str(ClericData.TALENT_DESCRIPTIONS.get(option_id,"Talent details are still being developed."))
	if hero_class=="Ranger":return str(RangerData.TALENT_DESCRIPTIONS.get(option_id,"Talent details are still being developed."))
	if hero_class=="Mage":return str(MageData.TALENT_DESCRIPTIONS.get(option_id,"Talent details are still being developed."))
	if hero_class=="Warlock":return str(WarlockData.TALENT_DESCRIPTIONS.get(option_id,"Talent details are still being developed."))
	return "Talent details are still being developed."

func remember_roster_scroll()->void:
	var scroll:=ui.find_child("RosterSectionScroll",true,false) as ScrollContainer
	if scroll!=null:
		hero_roster_scroll_positions["%d:%s"%[selected_roster_index,hero_roster_section]]=scroll.scroll_vertical

func restore_roster_scroll(scroll:ScrollContainer,key:String)->void:
	await get_tree().process_frame
	if is_instance_valid(scroll):scroll.scroll_vertical=int(hero_roster_scroll_positions.get(key,0))

func refresh_roster_preserving_scroll()->void:
	remember_roster_scroll();show_roster()

func plan_roster_talent(hero_index:int,tier_id:String,option_id:String,refresh:bool=true)->void:
	if hero_index<0 or hero_index>=state.heroes.size():return
	var hero:Dictionary=state.heroes[hero_index];var definition:=GameData.class_definition(str(hero.get("class","")))
	var planned_id:=str(hero.get("planned_talents",{}).get(tier_id,""))
	state.heroes[hero_index]=TalentSystem.clear_planned_option(hero,tier_id) if planned_id==option_id else TalentSystem.plan_option(hero,definition,tier_id,option_id)
	save_game()
	if refresh:hero_roster_section="Talents";refresh_roster_preserving_scroll()

func confirm_roster_talent(hero_index:int,tier_id:String,option_id:String,refresh:bool=true)->bool:
	if hero_index<0 or hero_index>=state.heroes.size():return false
	var hero:Dictionary=state.heroes[hero_index];var definition:=GameData.class_definition(str(hero.get("class","")))
	var result:=TalentSystem.select_option(hero,definition,tier_id,option_id)
	if not bool(result.get("success",false)):
		flash(str(result.get("reason","That talent cannot be selected.")));return false
	state.heroes[hero_index]=result.hero;save_game()
	if refresh:hero_roster_section="Talents";refresh_roster_preserving_scroll()
	return true

func open_roster_talent_details(hero_index:int,tier_id:String,option_id:String)->void:
	if hero_index<0 or hero_index>=state.heroes.size():return
	var hero:Dictionary=state.heroes[hero_index]
	var overlay:=Control.new();overlay.name="RosterTalentDetailsOverlay";overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_STOP;ui.add_child(overlay)
	var backdrop:=Button.new();backdrop.name="RosterTalentDetailsBackdrop";backdrop.flat=true;backdrop.focus_mode=Control.FOCUS_NONE;backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.add_theme_stylebox_override("normal",ui_box(Color(0.01,0.02,0.04,.78),0));backdrop.pressed.connect(func():overlay.queue_free());overlay.add_child(backdrop)
	var panel:=PanelContainer.new();panel.name="RosterTalentDetailsCard";panel.position=Vector2(340,145);panel.size=Vector2(600,430);panel.add_theme_stylebox_override("panel",ui_box(Color("1b283a"),10,CLASSES[hero["class"]].color,2));overlay.add_child(panel)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	panel.add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);margin.add_child(column)
	var tier_number:=int(tier_id.trim_prefix("tier_"));column.add_child(label("TIER %d  •  LEVEL %d"%[tier_number,int(TalentSystem.TIER_LEVELS.get(tier_id,0))],13,C_GOLD))
	column.add_child(label(guardian_talent_name(option_id).to_upper(),25,CLASSES[hero["class"]].color));column.add_child(rule())
	var description:=label(roster_talent_description(str(hero.get("class","")),option_id),16,C_TEXT);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(description)
	var selected:=str(hero.get("selected_talents",{}).get(tier_id,""))==option_id
	var required_level:=int(TalentSystem.TIER_LEVELS.get(tier_id,999))
	var footer_text:="SELECTED" if selected else "Hold this talent on the tree to choose it." if int(hero.get("level",1))>=required_level else "UNLOCKS AT LEVEL %d"%required_level
	if footer_text!="":
		var footer:=label(footer_text,14,C_GOLD if selected else C_MUTED);footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(footer)

func victory_talent_unlocks()->Array:
	var unlocks:Array=[]
	var level_ups:Array=pending_victory.get("rewards",{}).get("level_ups",[]) if current_ashwood_encounter!="" else victory_level_ups
	for level_up in level_ups:
		var hero_index:=int(level_up.get("hero_index",-1))
		if hero_index<0 and level_up.has("slot"):
			var slot:=int(level_up.slot);hero_index=int(battle_hero_indices[slot]) if slot>=0 and slot<battle_hero_indices.size() else -1
		if hero_index<0 or hero_index>=state.heroes.size():continue
		for tier_id in level_up.get("talent_tiers",[]):
			if str(state.heroes[hero_index].get("selected_talents",{}).get(str(tier_id),""))=="":unlocks.append({"hero_index":hero_index,"tier_id":str(tier_id)})
	return unlocks

func open_victory_talent_choices()->bool:
	if victory_talent_prompt_handled:return false
	victory_talent_prompt_handled=true;victory_talent_queue=victory_talent_unlocks();victory_talent_choice_index=0
	if victory_talent_queue.is_empty():return false
	show_victory_talent_choice();return true

func close_victory_talent_overlay()->void:
	if victory_talent_overlay!=null and is_instance_valid(victory_talent_overlay):victory_talent_overlay.queue_free()
	victory_talent_overlay=null

func advance_victory_talent_choice()->void:
	victory_talent_choice_index+=1
	if victory_talent_choice_index>=victory_talent_queue.size():
		close_victory_talent_overlay();ui.visible=false;complete_victory_sequence_navigation();return
	show_victory_talent_choice()

func victory_plan_talent(hero_index:int,tier_id:String,option_id:String)->void:
	plan_roster_talent(hero_index,tier_id,option_id,false);show_victory_talent_choice()

func victory_confirm_talent(hero_index:int,tier_id:String,option_id:String)->void:
	if confirm_roster_talent(hero_index,tier_id,option_id,false):advance_victory_talent_choice()

func show_victory_talent_choice()->void:
	close_victory_talent_overlay()
	if victory_talent_choice_index<0 or victory_talent_choice_index>=victory_talent_queue.size():return
	var entry:Dictionary=victory_talent_queue[victory_talent_choice_index];var hero_index:=int(entry.hero_index);var tier_id:=str(entry.tier_id);var hero:Dictionary=state.heroes[hero_index]
	var class_definition:=GameData.class_definition(str(hero.get("class","")));var class_id:=str(class_definition.get("class_id",GameData.class_id_for(str(hero.get("class","")))));var tier_number:=int(tier_id.trim_prefix("tier_"))
	ui.visible=true
	var overlay:=Control.new();overlay.name="VictoryTalentChoiceOverlay";overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_STOP;ui.add_child(overlay);victory_talent_overlay=overlay
	var shade:=ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(0.01,0.02,0.04,.82);shade.mouse_filter=Control.MOUSE_FILTER_STOP;overlay.add_child(shade)
	var panel:=PanelContainer.new();panel.position=Vector2(210,105);panel.size=Vector2(860,510);panel.add_theme_stylebox_override("panel",ui_box(Color("172234"),10,CLASSES[hero["class"]].color,2));overlay.add_child(panel)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,26)
	panel.add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);margin.add_child(column)
	var heading:=HBoxContainer.new();column.add_child(heading)
	var heading_copy:=VBoxContainer.new();heading_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(heading_copy);heading_copy.add_child(label("NEW TALENT TIER",28,C_GOLD));heading_copy.add_child(label("%s  •  Level %d %s"%[str(hero.get("name","Hero")),int(hero.get("level",1)),str(hero.get("class",""))],16,C_MUTED))
	var counter:=label("%d / %d"%[victory_talent_choice_index+1,victory_talent_queue.size()],14,C_MUTED);counter.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;heading.add_child(counter)
	column.add_child(rule())
	var tier_view:=make_roster_talent_tier(hero,class_definition,class_id,state.get("class_talent_discovery",{}),tier_number,hero_index) as TalentTierView
	# Replace roster-refresh actions with victory-specific actions.
	for connection in tier_view.plan_toggled.get_connections():tier_view.plan_toggled.disconnect(connection.callable)
	for connection in tier_view.selection_confirmed.get_connections():tier_view.selection_confirmed.disconnect(connection.callable)
	tier_view.plan_toggled.connect(func(requested_tier:String,requested_option:String):victory_plan_talent(hero_index,requested_tier,requested_option))
	tier_view.selection_confirmed.connect(func(requested_tier:String,requested_option:String):victory_confirm_talent(hero_index,requested_tier,requested_option))
	column.add_child(tier_view)
	var help:=label("Tap a talent for details. Hold it until the bar fills to choose it.",14,C_MUTED);help.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(help)
	var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(spacer)
	var later:=compact_button("DECIDE LATER",advance_victory_talent_choice,190);later.name="VictoryTalentDecideLater";later.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;column.add_child(later)

func make_roster_talent_tier(hero:Dictionary,class_definition:Dictionary,class_id:String,discovery:Dictionary,tier_number:int,hero_index:int=-1)->Control:
	var tier_id:="tier_%d"%tier_number;var tier_definition:=TalentSystem.tier_definition(class_definition,tier_id)
	if tier_definition.is_empty():return Control.new()
	var required_level:=int(tier_definition.get("unlock_level",TalentSystem.TIER_LEVELS.get(tier_id,999)));var revealed:=TalentSystem.tier_is_revealed(discovery,class_id,tier_id,is_testing_save());var hero_level:=int(hero.get("level",1));var selected_id:=str(hero.get("selected_talents",{}).get(tier_id,""));var planned_id:=str(hero.get("planned_talents",{}).get(tier_id,""));var options:Array=[]
	for raw_option_id in tier_definition.get("option_ids",[]):
		var option_id:=str(raw_option_id);var available:=true;var unavailable_reason:=""
		if hero_level>=required_level:
			var validation:=TalentSystem.validate_selection(hero,class_definition,tier_id,option_id);available=bool(validation.valid) or option_id==selected_id;unavailable_reason=str(validation.reason)
		options.append({"id":option_id,"display_name":guardian_talent_name(option_id) if str(hero.get("class","")) in ["Guardian","Cleric"] else option_id.replace("_"," ").capitalize(),"description":roster_talent_description(str(hero.get("class","")),option_id),"selected":option_id==selected_id,"planned":option_id==planned_id,"available":available,"unavailable_reason":unavailable_reason,"class_name":str(hero.get("class","Hero"))})
	var resolved_index:=selected_roster_index if hero_index<0 else hero_index
	var view:=TalentTierView.new();view.configure(tier_id,tier_number,required_level,str(tier_definition.get("kind","talent")),hero_level,revealed,options,CLASSES[hero["class"]].color,C_TEXT,C_MUTED,C_GOLD)
	view.details_requested.connect(func(requested_tier:String,requested_option:String):open_roster_talent_details(resolved_index,requested_tier,requested_option))
	view.plan_toggled.connect(func(requested_tier:String,requested_option:String):plan_roster_talent(resolved_index,requested_tier,requested_option))
	view.selection_confirmed.connect(func(requested_tier:String,requested_option:String):confirm_roster_talent(resolved_index,requested_tier,requested_option))
	return view

func make_roster_card(idx:int) -> Button:

	var h=state.heroes[idx]
	var card:=Button.new(); card.custom_minimum_size=Vector2(132,74); card.text="%s\n%s\n%s  •  Level %d" % [role_glyph(h["class"]),h["name"],h["class"],h["level"]];card.focus_mode=Control.FOCUS_NONE
	card.add_theme_font_size_override("font_size",13); card.add_theme_color_override("font_color",CLASSES[h["class"]].color if idx==selected_roster_index else C_TEXT)
	card.add_theme_stylebox_override("normal",ui_box(Color("202d42"),4,Color("35445a"),1));card.add_theme_stylebox_override("hover",ui_box(Color("293a53"),4,CLASSES[h["class"]].color,1));card.add_theme_stylebox_override("pressed",ui_box(Color("172131"),4,CLASSES[h["class"]].color,2))
	var is_party_member:=hero_is_on_active_team(idx)
	var active_star:=Button.new();active_star.name="ActiveTeamStar";active_star.text="★" if is_party_member else "☆";active_star.position=Vector2(94,0);active_star.size=Vector2(36,34);active_star.flat=true;active_star.focus_mode=Control.FOCUS_NONE;active_star.tooltip_text="Remove from selected party" if is_party_member else "Add to selected party";active_star.add_theme_font_size_override("font_size",20);active_star.add_theme_color_override("font_color",C_GOLD if is_party_member else C_MUTED)
	active_star.gui_input.connect(func(event,i=idx):
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:begin_roster_party_press(i,"reserve",event.position)
		elif event is InputEventScreenTouch and event.pressed:begin_roster_party_press(i,"reserve",event.position))
	card.add_child(active_star)
	if idx==selected_roster_index: card.add_theme_stylebox_override("normal",ui_box(Color("26384e"),4,CLASSES[h["class"]].color,2))
	card.pressed.connect(func():remember_roster_scroll();selected_roster_index=idx;show_roster())
	return card

func select_roster_team_option(option:int)->void:
	current_team_slot=clampi(option,0,4)-1
	state.selected_team=TeamManager.sanitize_team(state.active_team if current_team_slot<0 else state.saved_teams[current_team_slot],state.heroes)
	if current_team_slot<0:state.active_team=state.selected_team.duplicate()
	else:state.saved_teams[current_team_slot]=state.selected_team.duplicate()
	hero_roster_page=0;save_game();show_roster()

func make_roster_party_summary()->VBoxContainer:
	var summary:=VBoxContainer.new();summary.name="RosterPartySummary";summary.custom_minimum_size.x=220;summary.add_theme_constant_override("separation",3)
	var teams:=OptionButton.new();teams.name="RosterTeamSelector";teams.custom_minimum_size=Vector2(142,30);teams.size_flags_horizontal=Control.SIZE_SHRINK_END
	for option_index in 5:teams.add_item(str(state.team_names[option_index]))
	teams.select(clampi(current_team_slot+1,0,4));teams.item_selected.connect(select_roster_team_option);apply_sharp_compact_style(teams);summary.add_child(teams)
	var party_name:=str(state.team_names[clampi(current_team_slot+1,0,4)]).to_upper()
	var title:=label("★  %s  %d / 4"%[party_name,state.selected_team.size()],14,C_GOLD);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;summary.add_child(title)
	var members:=HBoxContainer.new();members.name="RosterPartyMembers";members.alignment=BoxContainer.ALIGNMENT_END;members.add_theme_constant_override("separation",5);summary.add_child(members);team_active_zone=members;team_active_row=members
	for hero_index_value in state.selected_team:
		var hero_index:=int(hero_index_value)
		if hero_index<0 or hero_index>=state.heroes.size():continue
		var hero:Dictionary=state.heroes[hero_index]
		var member:=Button.new();member.name="RosterPartyMember%d"%hero_index;member.text=role_glyph(str(hero.get("class","")));member.custom_minimum_size=Vector2(46,40);member.focus_mode=Control.FOCUS_NONE;member.tooltip_text="%s — click to remove, or hold and drag to reorder"%str(hero.get("name","Hero"));member.add_theme_font_size_override("font_size",17);member.add_theme_color_override("font_color",CLASSES[hero["class"]].color);member.add_theme_stylebox_override("normal",ui_box(Color("202d42"),4,CLASSES[hero["class"]].color,2));member.add_theme_stylebox_override("hover",ui_box(Color("293a53"),4,C_GOLD,2));member.gui_input.connect(func(event,i=hero_index):
			if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:begin_roster_party_press(i,"active",event.position)
			elif event is InputEventScreenTouch and event.pressed:begin_roster_party_press(i,"active",event.position));members.add_child(member)
	for empty_slot in range(state.selected_team.size(),4):
		var empty:=Button.new();empty.disabled=true;empty.custom_minimum_size=Vector2(46,40);empty.add_theme_stylebox_override("disabled",ui_box(Color("172131"),4,Color("35445a"),1));members.add_child(empty)
	return summary

func roster_display_indices()->Array:
	var filtered_sorted:Array=sorted_hero_indices()
	var party_members:Array=[]
	for hero_index_value in state.selected_team:
		var hero_index:=int(hero_index_value)
		if hero_index in filtered_sorted and hero_index not in party_members:party_members.append(hero_index)
	var reserves:Array=filtered_sorted.filter(func(hero_index):return int(hero_index) not in party_members)
	return party_members+reserves

func make_hero_experience_bar(hero:Dictionary,width:float=330,height:float=24) -> Control:
	var experience_max:int=max(1,int(hero.level)*100)
	var experience_value:int=clampi(int(hero.get("xp",0)),0,experience_max)
	var container:=Control.new();container.name="HeroExperience";container.custom_minimum_size=Vector2(width,height)
	var bar:=ProgressBar.new();bar.name="HeroExperienceBar";bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bar.max_value=experience_max;bar.value=experience_value;bar.show_percentage=false;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;bar.add_theme_stylebox_override("background",ui_box(Color("111a28"),4,Color("2c3a4e"),1));bar.add_theme_stylebox_override("fill",ui_box(Color("326fae"),4));container.add_child(bar)
	var amount:=Label.new();amount.name="HeroExperienceText";amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);amount.text="XP   %d / %d"%[experience_value,experience_max];amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;amount.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;amount.mouse_filter=Control.MOUSE_FILTER_IGNORE;amount.add_theme_font_size_override("font_size",12);amount.add_theme_color_override("font_color",C_MUTED);container.add_child(amount)
	return container

func select_roster_section(section:String) -> void:
	remember_roster_scroll()
	hero_roster_section=section
	show_roster()

func make_roster_section_button(section:String) -> Button:
	var section_button:=compact_button(section,func():select_roster_section(section),125)
	section_button.name="RosterSection"+section
	apply_sharp_compact_style(section_button)
	if hero_roster_section==section:
		section_button.add_theme_color_override("font_color",C_GOLD)
		section_button.add_theme_stylebox_override("normal",ui_box(Color("2b3b52"),4,C_GOLD,2))
	return section_button

func hero_equipped_items(hero:Dictionary)->Array:
	return ItemData.equipped_instances(hero,state.get("item_instances",[]))

func has_item_passive(items:Array,passive_id:String)->bool:
	for item in items:
		if passive_id in item.get("passive_effect_ids",[]):return true
	return false

func hero_has_passive(hero:Dictionary,passive_id:String)->bool:
	return has_item_passive(hero.get("equipped_items",[]),passive_id)

func equipped_item_in_slot(hero:Dictionary,slot:String)->Dictionary:
	var instance_id=hero.get("equipment_slots",{}).get(slot,null)
	if instance_id==null:return {}
	for item in state.get("item_instances",[]):
		if str(item.get("instance_id",""))==str(instance_id):return item
	return {}

func hero_final_stats(hero:Dictionary)->Dictionary:
	return CombatSystem.calculate_final_stats(CLASSES[hero["class"]],int(hero.get("level",1)),hero_equipped_items(hero))

func select_equipment_slot(slot:String)->void:
	equipment_selected_slot=slot
	equipment_candidate_id=""
	var current:=equipped_item_in_slot(state.heroes[selected_roster_index],slot)
	if current.is_empty():show_equipment_carousel(selected_roster_index,slot)
	else:open_item_card(str(current.get("instance_id","")),"roster_slot")

func close_item_overlay()->void:
	if item_card_overlay!=null and is_instance_valid(item_card_overlay):item_card_overlay.queue_free()
	item_card_overlay=null
	item_overlay_mode=""
	item_overlay_back_action=Callable()
	item_overlay_confirmation_active=false
	item_carousel_swiping=false
	item_carousel_drag_offset=0.0
	item_carousel_transitioning=false

func navigate_item_overlay_back()->void:
	if item_overlay_confirmation_active:return
	if item_overlay_back_action.is_valid():
		var back_action:=item_overlay_back_action
		item_overlay_back_action=Callable()
		back_action.call()
	else:close_item_overlay()

func create_item_overlay(back_action:Callable=Callable())->Control:
	close_item_overlay()
	item_overlay_back_action=back_action
	var overlay:=Control.new();overlay.name="ItemOverlay";overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_STOP;ui.add_child(overlay);item_card_overlay=overlay
	var backdrop:=Button.new();backdrop.name="ItemCardBackdrop";backdrop.flat=true;backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.focus_mode=Control.FOCUS_NONE;backdrop.add_theme_stylebox_override("normal",ui_box(Color(0.01,0.02,0.04,.76),0));backdrop.pressed.connect(func():
		if not item_overlay_confirmation_active:close_item_overlay())

	overlay.add_child(backdrop)
	if back_action.is_valid():
		var back:=compact_button("Back",navigate_item_overlay_back,104);back.name="ItemOverlayBack";back.position=Vector2(24,20);back.custom_minimum_size=Vector2(104,44);overlay.add_child(back)
	return overlay

func equipment_comparison(instance_id:String,hero_index:int)->Dictionary:
	if hero_index<0 or hero_index>=state.heroes.size():return {}
	var item:=ItemData.item_by_instance_id(state.get("item_instances",[]),instance_id)
	if item.is_empty():return {}
	var before:=hero_final_stats(state.heroes[hero_index]);var simulated:Dictionary=state.duplicate(true)
	var result:=ItemData.equip_in_state(simulated,hero_index,instance_id,CLASSES)
	if not bool(result.get("success",false)):return {"summary":str(result.get("reason","Cannot equip"))}
	var simulated_items:=ItemData.equipped_instances(simulated.heroes[hero_index],simulated.item_instances)
	var after:=CombatSystem.calculate_final_stats(CLASSES[simulated.heroes[hero_index]["class"]],int(simulated.heroes[hero_index].get("level",1)),simulated_items)
	var rows:Array=[]
	var comparisons:=[
		["Health",float(before.health),float(after.health),false],
		["Power",float(before.power),float(after.power),false],
		["Armor",float(before.armor),float(after.armor),false],
		["Armor Reduction",float(before.armor_reduction)*100.0,float(after.armor_reduction)*100.0,true],
		["Basic Action",float(before.basic_action_amount),float(after.basic_action_amount),false],
		["Action Interval",float(before.basic_action_interval),float(after.basic_action_interval),false],
		["Critical Chance",float(before.critical_chance)*100.0,float(after.critical_chance)*100.0,true]
	]
	for comparison in comparisons:
		if is_equal_approx(comparison[1],comparison[2]):continue
		var suffix:="%" if comparison[3] else (" sec" if comparison[0]=="Action Interval" else "")
		var direction:="faster" if comparison[0]=="Action Interval" and comparison[2]<comparison[1] else "slower" if comparison[0]=="Action Interval" else "increased" if comparison[2]>comparison[1] else "decreased"
		var before_text:=str(int(floor(float(comparison[1])))) if comparison[0]=="Basic Action" else "%.1f"%comparison[1]
		var after_text:=str(int(floor(float(comparison[2])))) if comparison[0]=="Basic Action" else "%.1f"%comparison[2]
		rows.append("%s   %s%s  →  %s%s  (%s)"%[comparison[0],before_text,suffix,after_text,suffix,direction])
	var current:=equipped_item_in_slot(state.heroes[hero_index],str(item.get("slot","")))
	var old_passives:Array=current.get("passive_effect_ids",[]) if not current.is_empty() else []
	var new_passives:Array=item.get("passive_effect_ids",[])
	for passive_id in old_passives:
		if passive_id not in new_passives:rows.append("Passive lost: %s"%ItemData.PASSIVE_EFFECTS.get(passive_id,{"display_name":passive_id}).display_name)
	for passive_id in new_passives:
		if passive_id not in old_passives:rows.append("Passive gained: %s"%ItemData.PASSIVE_EFFECTS.get(passive_id,{"display_name":passive_id}).display_name)
	var previous_owner:=int(item.get("equipped_hero_index",-1))
	if previous_owner>=0 and previous_owner!=hero_index:rows.push_front("Currently equipped by %s. Moving it leaves that slot empty."%state.heroes[previous_owner].name)
	if rows.is_empty():rows.append("No resolved combat values change.")
	return {"summary":"\n".join(rows)}

func item_card_actions(item:Dictionary,origin:String)->Array:
	if bool(item.get("is_material",false)):return []
	if origin=="equipment_preview":
		var current:=equipped_item_in_slot(state.heroes[pending_item_hero_index],str(item.get("slot",""))) if pending_item_hero_index>=0 else {}
		var previous_owner:=int(item.get("equipped_hero_index",-1));var label_text:="Move Item" if previous_owner>=0 and previous_owner!=pending_item_hero_index else "Replace" if not current.is_empty() and str(current.get("instance_id",""))!=str(item.get("instance_id","")) else "Equip"
		return [{"id":"confirm_equip","label":label_text},{"id":"cancel_preview","label":"Cancel"}]
	var owner:=int(item.get("equipped_hero_index",-1))
	if origin=="roster_slot":return [{"id":"unequip_item","label":"Unequip"},{"id":"change_equipment","label":"Change Equipment"}]
	if owner<0:return [{"id":"choose_hero","label":"Choose Hero"}]
	if origin=="vault":return [{"id":"unequip_item","label":"Unequip"},{"id":"change_hero","label":"Change Hero"}]
	return [{"id":"view_hero","label":"View Hero"},{"id":"change_hero","label":"Change Hero"},{"id":"unequip_item","label":"Unequip"}]

func open_item_card(entry_id:String,origin:String="vault",comparison:Dictionary={},back_action:Callable=Callable())->void:
	var entry:=InventorySystem.entry_by_id(state,entry_id)
	if entry.is_empty():return
	var data:=InventorySystem.material_card_data(entry) if bool(entry.get("is_material",false)) else ItemData.item_card_data(entry,state.heroes)
	var overlay:=create_item_overlay(back_action);item_overlay_mode="item_card";var card:=ItemCardView.new();card.name="SharedItemCard";card.position=Vector2((W-460.0)*.5,50);card.size=Vector2(460,620);card.configure(data,item_card_actions(entry,origin),comparison);card.close_requested.connect(navigate_item_overlay_back);card.action_requested.connect(func(action):handle_item_card_action(action,entry_id));overlay.add_child(card)

func handle_item_card_action(action:String,entry_id:String)->void:
	var item:=InventorySystem.entry_by_id(state,entry_id)
	if item.is_empty():close_item_overlay();return
	match action:
		"choose_hero","change_hero":show_item_hero_selector(entry_id)
		"change_equipment":show_equipment_carousel(selected_roster_index,str(item.get("slot","")),str(item.get("instance_id","")))
		"view_hero":
			var owner:=int(item.get("equipped_hero_index",-1))
			if owner>=0:selected_roster_index=owner
			equipment_selected_slot="";close_item_overlay();show_roster()
		"unequip_item":
			var owner:=int(item.get("equipped_hero_index",-1))
			if owner>=0:ItemData.unequip_from_state(state,owner,str(item.get("slot","")))
			save_game();close_item_overlay()
			if screen=="vault":show_vault()
			else:show_roster()
		"confirm_equip":confirm_item_equip(entry_id,pending_item_hero_index,pending_item_origin)
		"cancel_preview":navigate_item_overlay_back()

func item_icon_control(item:Dictionary,icon_size:Vector2)->Control:
	var definition:=ItemData.definition_for_instance(item)

	var icon_path:=str(definition.get("icon_path",item.get("icon_path","")))
	if icon_path!="" and ResourceLoader.exists(icon_path):
		var icon:=TextureRect.new()
		icon.texture=load(icon_path);icon.custom_minimum_size=icon_size;icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		return icon
	var fallback:=label(InventorySystem.fallback_glyph(str(definition.get("fallback_icon_type",item.get("fallback_icon_type",item.get("slot","item"))))),24,Color(ItemData.RARITY_COLORS.get(str(item.get("rarity","Common")),"e9f1ff")))
	fallback.custom_minimum_size=icon_size;fallback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;fallback.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;fallback.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return fallback

func create_item_carousel_track(overlay:Control)->Control:
	var track:=Control.new();track.name="ItemCarouselTrack";track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);track.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(track)
	return track

func carousel_can_shift(direction:int)->bool:
	if item_overlay_mode=="equipment_carousel":return item_carousel_index+direction>=0 and item_carousel_index+direction<item_carousel_items.size()
	if item_overlay_mode=="hero_carousel":return hero_carousel_index+direction>=0 and hero_carousel_index+direction<hero_carousel_indices.size()
	return false

func update_item_carousel_drag(offset:float)->void:
	var track:Control=item_card_overlay.find_child("ItemCarouselTrack",true,false) if item_card_overlay!=null else null
	if track==null:return
	var direction:=-1 if offset>0.0 else 1
	var resistance:=1.0 if carousel_can_shift(direction) else 0.22
	item_carousel_drag_offset=clampf(offset*resistance,-300.0,300.0);track.position.x=item_carousel_drag_offset

func finish_item_carousel_drag(offset:float)->void:
	var track:Control=item_card_overlay.find_child("ItemCarouselTrack",true,false) if item_card_overlay!=null else null
	if track==null:return
	var overlay_ref:=item_card_overlay
	var direction:=-1 if offset>0.0 else 1
	if absf(offset)<55.0 or not carousel_can_shift(direction):
		item_carousel_transitioning=true
		var reset:=create_tween();reset.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);reset.tween_property(track,"position:x",0.0,.14);reset.finished.connect(func():item_carousel_transitioning=false;item_carousel_drag_offset=0.0)
		return
	item_carousel_transitioning=true
	var slide:=create_tween();slide.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);slide.tween_property(track,"position:x",-float(direction)*W,.16);slide.finished.connect(func():item_carousel_transitioning=false;item_carousel_drag_offset=0.0;if item_card_overlay==overlay_ref:shift_active_item_carousel(direction))

func animate_item_carousel_shift(direction:int)->void:
	if item_carousel_transitioning or not carousel_can_shift(direction):return
	finish_item_carousel_drag(-80.0 if direction>0 else 80.0)

func make_item_carousel_peek(item:Dictionary,direction:int)->Button:
	var rarity_color:=Color(ItemData.RARITY_COLORS.get(str(item.get("rarity","Common")),"e9f1ff"))
	var peek:=Button.new();peek.name="ItemCarouselPeekLeft" if direction<0 else "ItemCarouselPeekRight";peek.position=Vector2(292,150) if direction<0 else Vector2(768,150);peek.size=Vector2(220,420);peek.clip_contents=true;peek.modulate=Color(0.62,0.62,0.67,0.72);peek.add_theme_stylebox_override("normal",ui_box(Color("111b2a"),10,rarity_color,2));peek.pressed.connect(func():animate_item_carousel_shift(direction))
	var content:=VBoxContainer.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,12);content.alignment=BoxContainer.ALIGNMENT_CENTER;content.mouse_filter=Control.MOUSE_FILTER_IGNORE;peek.add_child(content)
	content.add_child(item_icon_control(item,Vector2(180,300)))
	return peek

func show_equipment_carousel(hero_index:int,slot:String,return_instance_id:String="",preferred_index:int=0)->void:
	if hero_index<0 or hero_index>=state.heroes.size():return
	var hero:Dictionary=state.heroes[hero_index]
	var candidates:Array=[]
	for item in state.get("item_instances",[]):
		if str(item.get("slot",""))!=slot or str(item.get("instance_id",""))==return_instance_id:continue
		if ItemData.compatibility_reason(item,CLASSES[hero["class"]],str(hero["class"]))=="":candidates.append(item)
	candidates.sort_custom(func(a,b):return str(a.get("display_name",""))<str(b.get("display_name","")))
	item_carousel_items=candidates;item_carousel_index=clampi(preferred_index,0,maxi(0,candidates.size()-1));item_carousel_hero_index=hero_index;item_carousel_slot=slot;item_carousel_return_instance_id=return_instance_id
	var return_action:Callable=Callable()
	if return_instance_id!="":return_action=func(id=return_instance_id):open_item_card(id,"roster_slot")
	var overlay:=create_item_overlay(return_action);item_overlay_mode="equipment_carousel"
	var heading:=label("%s EQUIPMENT  •  %s"%[slot.to_upper(),str(hero.get("name","Hero"))],18,C_GOLD);heading.position=Vector2(150,24);heading.size=Vector2(300,40);overlay.add_child(heading)
	if candidates.is_empty():
		var empty_panel:=PanelContainer.new();empty_panel.name="EquipmentCarouselEmpty";empty_panel.position=Vector2(390,205);empty_panel.size=Vector2(500,250);empty_panel.add_theme_stylebox_override("panel",ui_box(Color("172234"),12,Color("35445a"),2));overlay.add_child(empty_panel)
		var empty_text:=label("No compatible %s items are currently stored."%slot.capitalize(),20,C_MUTED);empty_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;empty_panel.add_child(empty_text)
		return
	var current:Dictionary=candidates[item_carousel_index]
	var track:=create_item_carousel_track(overlay)
	if item_carousel_index>0:track.add_child(make_item_carousel_peek(candidates[item_carousel_index-1],-1))
	if item_carousel_index<candidates.size()-1:track.add_child(make_item_carousel_peek(candidates[item_carousel_index+1],1))
	var card:=ItemCardView.new();card.name="EquipmentCarouselCard";card.position=Vector2((W-460.0)*.5,50);card.size=Vector2(460,620);card.configure(ItemData.item_card_data(current,state.heroes),[{"id":"equip_carousel_item","label":"Equip"}]);card.action_requested.connect(func(_action):equip_item_carousel_candidate());track.add_child(card)
	var tap_target:=Button.new();tap_target.name="EquipmentCarouselTapTarget";tap_target.position=Vector2((W-460.0)*.5,50);tap_target.size=Vector2(460,275);tap_target.flat=true;tap_target.focus_mode=Control.FOCUS_NONE;tap_target.add_theme_stylebox_override("normal",ui_box(Color(0,0,0,0),12));tap_target.add_theme_stylebox_override("hover",ui_box(Color(1,1,1,.035),12,C_GOLD,1));tap_target.pressed.connect(equip_item_carousel_candidate);track.add_child(tap_target)
	var previous:=compact_button("←",func():animate_item_carousel_shift(-1),58);previous.name="EquipmentCarouselPrevious";previous.position=Vector2(218,330);previous.custom_minimum_size=Vector2(58,58);previous.disabled=item_carousel_index==0;overlay.add_child(previous)
	var next:=compact_button("→",func():animate_item_carousel_shift(1),58);next.name="EquipmentCarouselNext";next.position=Vector2(1004,330);next.custom_minimum_size=Vector2(58,58);next.disabled=item_carousel_index==candidates.size()-1;overlay.add_child(next)

func equip_item_carousel_candidate()->void:
	if item_carousel_items.is_empty():return
	var item:Dictionary=item_carousel_items[item_carousel_index]
	var previous_owner:=int(item.get("equipped_hero_index",-1))
	if previous_owner>=0 and previous_owner!=item_carousel_hero_index:
		item_overlay_confirmation_active=true
		var dialog:=ConfirmationDialog.new();dialog.name="MoveEquipmentConfirmation";dialog.title="Move Equipment?";dialog.dialog_text="%s is equipped by %s. Move it to %s?"%[str(item.get("display_name","This item")),str(state.heroes[previous_owner].get("name","another hero")),str(state.heroes[item_carousel_hero_index].get("name","this hero"))];dialog.ok_button_text="Move Item";item_card_overlay.add_child(dialog)
		dialog.confirmed.connect(func():item_overlay_confirmation_active=false;complete_item_carousel_equip(str(item.get("instance_id",""))))
		dialog.canceled.connect(func():item_overlay_confirmation_active=false)
		dialog.close_requested.connect(func():item_overlay_confirmation_active=false)
		dialog.popup_centered(Vector2i(480,210))
		return
	complete_item_carousel_equip(str(item.get("instance_id","")))

func complete_item_carousel_equip(instance_id:String)->void:
	var hero_index:=item_carousel_hero_index
	var result:=ItemData.equip_in_state(state,hero_index,instance_id,CLASSES)
	if bool(result.get("success",false)):save_game();toast="Equipment updated";equipment_selected_slot="";equipment_candidate_id=""
	else:toast=str(result.get("reason","Cannot equip this item"))
	toast_time=2.5;close_item_overlay();selected_roster_index=hero_index;show_roster()

func make_hero_carousel_card(hero_index:int,focused:bool,direction:int=0)->Button:
	var hero:Dictionary=state.heroes[hero_index]
	var item:=ItemData.item_by_instance_id(state.get("item_instances",[]),hero_carousel_item_id);var slot:=str(item.get("slot",""));var current:=equipped_item_in_slot(hero,slot);var current_name:="None" if current.is_empty() else str(current.get("display_name","Item"))
	var card:=Button.new();card.name="HeroCarouselCard" if focused else "HeroCarouselPeekLeft" if direction<0 else "HeroCarouselPeekRight";card.position=Vector2(390,145) if focused else Vector2(282,205) if direction<0 else Vector2(778,205);card.size=Vector2(500,430) if focused else Vector2(220,310);card.text="%s\n\n%s\n%s  •  Level %d\n\nCurrent %s\n%s\n\n%s"%[role_glyph(str(hero.get("class",""))),str(hero.get("name","Hero")),str(hero.get("class","Hero")),int(hero.get("level",1)),slot.capitalize(),current_name,"SELECT HERO" if focused else ""];card.add_theme_font_size_override("font_size",24 if focused else 16);card.add_theme_color_override("font_color",CLASSES[str(hero.get("class","Guardian"))].color);card.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.modulate=Color.WHITE if focused else Color(0.62,0.62,0.67,0.72);card.add_theme_stylebox_override("normal",ui_box(Color("172234"),12,C_GOLD if focused else Color("35445a"),3 if focused else 2))
	return card

func show_item_hero_selector(instance_id:String,preferred_index:int=0)->void:
	var item:=ItemData.item_by_instance_id(state.get("item_instances",[]),instance_id)
	if item.is_empty():return
	var compatible:Array=[]
	for hero_index in state.heroes.size():
		var hero:Dictionary=state.heroes[hero_index]
		if str(hero.get("activity",""))=="" and ItemData.compatibility_reason(item,CLASSES[hero["class"]],str(hero["class"]))=="":compatible.append(hero_index)
	hero_carousel_indices=compatible;hero_carousel_index=clampi(preferred_index,0,maxi(0,compatible.size()-1));hero_carousel_item_id=instance_id
	var overlay:=create_item_overlay();item_overlay_mode="hero_carousel"
	var heading:=label("CHOOSE HERO  •  %s"%str(item.get("display_name","Item")),18,C_GOLD);heading.position=Vector2(150,24);heading.size=Vector2(600,40);overlay.add_child(heading)
	if compatible.is_empty():

		var empty:=label("No available hero can equip this item.",20,C_MUTED);empty.position=Vector2(390,320);empty.size=Vector2(500,80);empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;overlay.add_child(empty)
		return
	var track:=create_item_carousel_track(overlay)
	if hero_carousel_index>0:
		var left:=make_hero_carousel_card(compatible[hero_carousel_index-1],false,-1);left.pressed.connect(func():animate_item_carousel_shift(-1));track.add_child(left)
	if hero_carousel_index<compatible.size()-1:
		var right:=make_hero_carousel_card(compatible[hero_carousel_index+1],false,1);right.pressed.connect(func():animate_item_carousel_shift(1));track.add_child(right)
	var focus:=make_hero_carousel_card(compatible[hero_carousel_index],true);focus.pressed.connect(func():open_equipment_preview(instance_id,compatible[hero_carousel_index],"vault"));track.add_child(focus)
	var previous:=compact_button("←",func():animate_item_carousel_shift(-1),58);previous.name="HeroCarouselPrevious";previous.position=Vector2(210,330);previous.custom_minimum_size=Vector2(58,58);previous.disabled=hero_carousel_index==0;overlay.add_child(previous)
	var next:=compact_button("→",func():animate_item_carousel_shift(1),58);next.name="HeroCarouselNext";next.position=Vector2(1012,330);next.custom_minimum_size=Vector2(58,58);next.disabled=hero_carousel_index==compatible.size()-1;overlay.add_child(next)

func shift_active_item_carousel(direction:int)->void:
	if item_overlay_mode=="equipment_carousel":
		var next_index:=clampi(item_carousel_index+direction,0,maxi(0,item_carousel_items.size()-1))
		if next_index!=item_carousel_index:show_equipment_carousel(item_carousel_hero_index,item_carousel_slot,item_carousel_return_instance_id,next_index)
	elif item_overlay_mode=="hero_carousel":
		var next_index:=clampi(hero_carousel_index+direction,0,maxi(0,hero_carousel_indices.size()-1))
		if next_index!=hero_carousel_index:show_item_hero_selector(hero_carousel_item_id,next_index)

func open_equipment_preview(instance_id:String,hero_index:int,origin:String)->void:
	pending_item_instance_id=instance_id;pending_item_hero_index=hero_index;pending_item_origin=origin;equipment_candidate_id=instance_id
	var back_action:Callable
	if origin=="vault":back_action=func():show_item_hero_selector(instance_id,hero_carousel_index)
	else:
		var preview_item:=ItemData.item_by_instance_id(state.get("item_instances",[]),instance_id)
		back_action=func():show_equipment_carousel(hero_index,str(preview_item.get("slot","")),item_carousel_return_instance_id,item_carousel_index)
	open_item_card(instance_id,"equipment_preview",equipment_comparison(instance_id,hero_index),back_action)

func confirm_item_equip(instance_id:String,hero_index:int,origin:String)->void:
	var result:=ItemData.equip_in_state(state,hero_index,instance_id,CLASSES)
	if bool(result.get("success",false)):save_game();toast="Equipment updated";toast_time=2.5
	else:toast=str(result.get("reason","Cannot equip this item"));toast_time=2.5
	close_item_overlay();pending_item_instance_id="";pending_item_hero_index=-1;equipment_candidate_id=""
	if origin=="roster":selected_roster_index=hero_index;show_roster()
	else:show_vault()

func make_roster_detail_row(caption:String,value:String,value_color:Color=C_TEXT)->HBoxContainer:
	var row:=HBoxContainer.new();row.name="RosterDetailRow"+caption.replace(" ","").replace("&","");row.custom_minimum_size.y=21;row.add_theme_constant_override("separation",8)
	var caption_label:=label(caption,12,C_MUTED);caption_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;caption_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(caption_label)
	var value_label:=label(value,13,value_color);value_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;value_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;value_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;value_label.custom_minimum_size.x=90;row.add_child(value_label)
	return row

func make_roster_detail_card(card_name:String,title:String,rows:Array)->PanelContainer:
	var card:=PanelContainer.new();card.name="RosterDetails"+card_name;card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.custom_minimum_size=Vector2(280,0);card.add_theme_stylebox_override("panel",ui_box(Color("1b283a"),6,Color("35445a"),1))
	var card_content:=VBoxContainer.new();card_content.add_theme_constant_override("separation",3);card.add_child(card_content)
	var heading:=label(title,13,C_GOLD);heading.name="RosterDetails"+card_name+"Heading";heading.add_theme_color_override("font_outline_color",Color("111827"));heading.add_theme_constant_override("outline_size",2);card_content.add_child(heading)
	card_content.add_child(rule())
	for row_data in rows:card_content.add_child(make_roster_detail_row(str(row_data.caption),str(row_data.value),row_data.get("color",C_TEXT)))
	return card

func append_roster_detail_group(card:PanelContainer,group_name:String,title:String,rows:Array)->void:
	var card_content:VBoxContainer=card.get_child(0);var group_gap:=Control.new();group_gap.custom_minimum_size.y=6;card_content.add_child(group_gap)
	var heading:=label(title,15,C_GOLD);heading.name="RosterDetails"+group_name+"Heading";heading.add_theme_color_override("font_outline_color",Color("111827"));heading.add_theme_constant_override("outline_size",2);card_content.add_child(heading)
	card_content.add_child(rule())
	for row_data in rows:card_content.add_child(make_roster_detail_row(str(row_data.caption),str(row_data.value),row_data.get("color",C_TEXT)))

func populate_roster_workspace(content:VBoxContainer,hero:Dictionary,info:Dictionary) -> void:
	var resolved_stats:=hero_final_stats(hero)
	content.add_theme_constant_override("separation",10)
	match hero_roster_section:
		"Abilities":
			var trait_name:String="Stoneform" if hero["class"]=="Guardian" and GuardianSystem.has_talent(hero,"guardian_l24_2") else str(TRAITS[hero["class"]])
			if hero["class"]=="Cleric" and ClericSystem.has_talent(hero,"cleric_l12_2"):trait_name="Safety Sprint"
			elif hero["class"]=="Cleric" and ClericSystem.has_talent(hero,"cleric_l12_3"):trait_name="Let's Go!"
			var trait_text:String=GuardianData.TALENT_DESCRIPTIONS.guardian_l24_2 if trait_name=="Stoneform" else "Passive Trait"
			if hero["class"]=="Cleric" and trait_name=="Safety Sprint":trait_text=str(ClericData.TALENT_DESCRIPTIONS.cleric_l12_2)
			elif hero["class"]=="Cleric" and trait_name=="Let's Go!":trait_text=str(ClericData.TALENT_DESCRIPTIONS.cleric_l12_3)
			var class_color:Color=CLASSES[hero["class"]].color
			for slot in 3:
				var required_level:=int(TalentSystem.ABILITY_UNLOCK_LEVELS[slot]);var locked:=int(hero.get("level",1))<required_level;var description:=ability_tooltip(hero["class"],slot)
				if locked:description="Unlocks at Level %d  •  %s"%[required_level,description]
				var action_key:String=["Q","W","E"][slot]
				content.add_child(make_roster_ability_row(action_key,str(ABILITIES[hero["class"]][slot]),description,class_color,locked,func(key=action_key):open_roster_ability_details(hero,key)))
			var selected_heroic_id:=str(hero.get("selected_heroic_id",""));var heroic_unlocked:=TalentSystem.ability_is_unlocked(int(hero.get("level",1)),3)
			if heroic_unlocked and selected_heroic_id!="":
				var heroic_name:=guardian_talent_name(selected_heroic_id) if hero["class"] in ["Guardian","Cleric","Ranger","Mage"] else str(ABILITIES[hero["class"]][3])
				var heroic_description:=str(GuardianData.TALENT_DESCRIPTIONS.get(selected_heroic_id,ability_tooltip(hero["class"],3))) if hero["class"]=="Guardian" else str(ClericData.TALENT_DESCRIPTIONS.get(selected_heroic_id,ability_tooltip(hero["class"],3))) if hero["class"]=="Cleric" else str(RangerData.TALENT_DESCRIPTIONS.get(selected_heroic_id,ability_tooltip(hero["class"],3))) if hero["class"]=="Ranger" else str(MageData.TALENT_DESCRIPTIONS.get(selected_heroic_id,ability_tooltip(hero["class"],3))) if hero["class"]=="Mage" else ability_tooltip(hero["class"],3)
				content.add_child(make_roster_ability_row("R",heroic_name,heroic_description,class_color,false,func(heroic=selected_heroic_id):open_roster_ability_details(hero,"R",heroic)))
			else:
				content.add_child(make_roster_ability_row("R","Heroic Ability","Choose your Heroic at Level %d."%int(TalentSystem.ABILITY_UNLOCK_LEVELS[3]),class_color,true))
			content.add_child(make_roster_ability_row("D",trait_name,trait_text,class_color,false,func():open_roster_ability_details(hero,"D")))
		"Talents":
			var class_definition:Dictionary=GameData.class_definition(str(hero["class"]));var class_id:=str(class_definition.get("class_id",GameData.class_id_for(str(hero["class"]))));var discovery:Dictionary=state.get("class_talent_discovery",{})
			for tier_number in range(1,9):content.add_child(make_roster_talent_tier(hero,class_definition,class_id,discovery,tier_number,selected_roster_index))
		"Professions":
			pass
		_:
			var action_is_heal:bool=str(resolved_stats.basic_action_type)=="heal";var action_title:="BASIC HEAL" if action_is_heal else "BASIC ATTACK"
			var action_rows:Array=[{"caption":"Healing" if action_is_heal else "Damage","value":str(int(floor(float(resolved_stats.basic_action_amount)))),"color":C_GREEN if action_is_heal else C_TEXT},{"caption":"Interval","value":"%.2f sec"%resolved_stats.basic_action_interval},{"caption":"Range","value":str(int(resolved_stats.basic_action_range))}]
			if not action_is_heal:action_rows.append({"caption":"Damage Type","value":str(resolved_stats.basic_action_damage_type).capitalize()})
			if hero["class"]=="Mage":
				var roster_ability_power:=float(resolved_stats.get("ability_power_percent",0.0))+(0.04 if "mage_l9_2" in hero.get("selected_talents",{}).values() else 0.0)
				action_rows.append({"caption":"Ability Power","value":"%.0f%%"%(roster_ability_power*100.0),"color":CLASSES.Mage.color})
			var defense_rows:Array=[{"caption":"Armor Rating","value":"%.0f"%resolved_stats.armor},{"caption":"Damage Reduction","value":"%d%%"%int(round(resolved_stats.armor_reduction*100.0)),"color":Color("e6b85c")},{"caption":"Movement Speed","value":str(int(resolved_stats.movement_speed))},{"caption":"Threat Generation","value":"%.2fx"%resolved_stats.threat_modifier}]
			if float(resolved_stats.health_regeneration)>0.0:defense_rows.append({"caption":"Health Regeneration","value":str(int(floor(float(resolved_stats.health_regeneration)))),"color":C_GREEN})
			var critical_rows:Array=[{"caption":"Chance","value":"%.1f%%"%(resolved_stats.critical_chance*100.0)},{"caption":"Critical Result","value":"%.0f%%"%(resolved_stats.critical_damage*100.0)}]
			var concise_weapon_names:Dictionary={"weapon_and_shield":"Shield","one_handed":"1-Handed","two_handed":"2-Handed","dual_wield":"Dual Wield"}
			var weapon_names:Array=resolved_stats.weapon_proficiencies.map(func(weapon):return str(concise_weapon_names.get(str(weapon),str(weapon).replace("_"," ").capitalize())))
			var proficiency_rows:Array=[{"caption":"Armor","value":str(resolved_stats.armor_family).capitalize()},{"caption":"Weapons","value":", ".join(weapon_names)}]
			var details_grid:=GridContainer.new();details_grid.name="RosterDetailsGrid";details_grid.columns=2;details_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details_grid.add_theme_constant_override("h_separation",10);details_grid.add_theme_constant_override("v_separation",8);content.add_child(details_grid)
			details_grid.add_child(make_roster_detail_card("Action",action_title,action_rows))
			details_grid.add_child(make_roster_detail_card("Defense","DEFENSE & MOVEMENT",defense_rows))
			details_grid.add_child(make_roster_detail_card("Critical","CRITICALS",critical_rows))
			details_grid.add_child(make_roster_detail_card("Proficiencies","PROFICIENCIES",proficiency_rows))
			var equipped:=hero_equipped_items(hero)
			if not equipped.is_empty():
				content.add_child(label("ACTIVE ITEM EFFECTS",14,C_GOLD))
				var effect_grid:=GridContainer.new();effect_grid.name="RosterItemEffects";effect_grid.columns=2;effect_grid.add_theme_constant_override("h_separation",10);effect_grid.add_theme_constant_override("v_separation",8);content.add_child(effect_grid)
				for item in equipped:
					var passive_names:Array=item.get("passive_effect_ids",[]).map(func(passive_id):return str(ItemData.PASSIVE_EFFECTS.get(passive_id,{}).get("display_name",passive_id)))
					var effect_card:=Label.new();effect_card.text="%s\n%s"%[item.display_name," • ".join(passive_names) if not passive_names.is_empty() else "No passive effect"];effect_card.custom_minimum_size=Vector2(280,52);effect_card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;effect_card.add_theme_font_size_override("font_size",13);effect_card.add_theme_color_override("font_color",Color(ItemData.RARITY_COLORS.get(str(item.get("rarity","Common")),"e9f1ff")));effect_card.add_theme_stylebox_override("normal",ui_box(Color("182334"),5,Color("35445a"),1));effect_grid.add_child(effect_card)
			if is_testing_save():
				content.add_child(rule())
				content.add_child(label("TESTING TOOLS",13,Color("b381ff")))
				var level_row:=HBoxContainer.new();level_row.add_theme_constant_override("separation",12);content.add_child(level_row)
				var level_caption:=label("Hero Level",15,C_TEXT);level_caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;level_caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;level_row.add_child(level_caption)
				var level_picker:=SpinBox.new();level_picker.name="TestingHeroLevel";level_picker.min_value=1;level_picker.max_value=TESTING_MAX_HERO_LEVEL;level_picker.step=1;level_picker.allow_greater=false;level_picker.allow_lesser=false;level_picker.value=int(hero.level);level_picker.custom_minimum_size=Vector2(105,40);level_picker.value_changed.connect(func(value,hero_index=selected_roster_index):set_testing_hero_level(hero_index,value));level_row.add_child(level_picker)
				content.add_child(compact_button("Toggle Special Hero",func():toggle_test_special_hero(selected_roster_index),190))

func make_roster_equipment_slot(hero:Dictionary,slot:String)->Button:
	var gear:=Button.new();gear.name="HeroEquipmentSlot"+slot.capitalize();gear.custom_minimum_size=Vector2(105,70);gear.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;gear.size_flags_vertical=Control.SIZE_SHRINK_CENTER;gear.text="";gear.focus_mode=Control.FOCUS_NONE
	var equipped_item:=equipped_item_in_slot(hero,slot)
	gear.pressed.connect(func():select_equipment_slot(slot))
	var frame_color:=Color("35445a") if equipped_item.is_empty() else Color(ItemData.RARITY_COLORS.get(str(equipped_item.get("rarity","Common")),"e9f1ff"))
	gear.add_theme_stylebox_override("normal",ui_box(Color("202d42"),4,frame_color,2 if not equipped_item.is_empty() else 1));gear.add_theme_stylebox_override("hover",ui_box(Color("26364e"),4,frame_color,3 if not equipped_item.is_empty() else 2))
	var slot_icon:Control
	if equipped_item.is_empty():
		var silhouette:=EquipmentSlotSilhouette.new();silhouette.configure(slot);slot_icon=silhouette;slot_icon.position=Vector2(13,5);slot_icon.size=Vector2(78,60)
	else:
		slot_icon=item_icon_control(equipped_item,Vector2(78,60));slot_icon.position=Vector2(13,5);slot_icon.size=Vector2(78,60)
	slot_icon.name="HeroEquipmentIcon";slot_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;gear.add_child(slot_icon)
	return gear

func show_roster() -> void:
	screen="roster"; var root=base_screen("Hero Roster")
	var roster_header:=Control.new();roster_header.name="RosterHeader";roster_header.custom_minimum_size.y=140;root.add_child(roster_header)
	var roster_filters:=filter_bar(show_roster,true,true,true);roster_filters.position=Vector2.ZERO;roster_filters.size=Vector2(826,32);roster_header.add_child(roster_filters)
	for filter_control in roster_filters.get_children():filter_control.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var party_summary:=make_roster_party_summary();party_summary.position=Vector2(996,0);party_summary.size=Vector2(220,116);roster_header.add_child(party_summary)
	var carousel:=HBoxContainer.new(); carousel.position=Vector2(0,54);carousel.size=Vector2(940,74);carousel.add_theme_constant_override("separation",8); roster_header.add_child(carousel);team_reserve_zone=carousel
	var previous_page:=compact_button("←",func():hero_roster_page=max(0,hero_roster_page-1);show_roster(),42);apply_sharp_compact_style(previous_page);carousel.add_child(previous_page)
	var cards:=GridContainer.new(); cards.columns=6; cards.custom_minimum_size.x=832;cards.add_theme_constant_override("h_separation",8); cards.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN; carousel.add_child(cards)
	var indices=roster_display_indices(); var pages=max(1,int(ceil(indices.size()/6.0))); hero_roster_page=clampi(hero_roster_page,0,pages-1)
	if not indices.is_empty() and not indices.has(selected_roster_index):selected_roster_index=indices[0]
	for card_index in range(hero_roster_page*6,min(indices.size(),hero_roster_page*6+6)):cards.add_child(make_roster_card(indices[card_index]))
	var next_page:=compact_button("→",func():hero_roster_page=min(pages-1,hero_roster_page+1);show_roster(),42);apply_sharp_compact_style(next_page);carousel.add_child(next_page)
	if indices.is_empty():var empty_result:=label("No heroes match the current filters.",18,C_MUTED);empty_result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;root.add_child(empty_result);return
	if selected_roster_index>=state.heroes.size():selected_roster_index=0
	var hero=state.heroes[selected_roster_index]; var info=CLASSES[hero["class"]];var resolved_stats:=hero_final_stats(hero)
	var roster_detail_gap:=Control.new();roster_detail_gap.name="RosterDetailGap";roster_detail_gap.custom_minimum_size.y=16;root.add_child(roster_detail_gap)
	var detail:=HBoxContainer.new(); detail.add_theme_constant_override("separation",28); detail.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(detail)
	var character:=VBoxContainer.new(); character.custom_minimum_size.x=510; character.add_theme_constant_override("separation",8); detail.add_child(character)
	var identity_row:=HBoxContainer.new();identity_row.name="HeroIdentityRow";identity_row.add_theme_constant_override("separation",12);character.add_child(identity_row)
	var hero_name:=label(hero["name"],30,info.color);hero_name.name="HeroName";hero_name.autowrap_mode=TextServer.AUTOWRAP_OFF;hero_name.custom_minimum_size.x=95;hero_name.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;identity_row.add_child(hero_name)
	var level_class:=label("Level %d %s"%[hero.level,hero["class"]],16,C_MUTED);level_class.name="HeroLevelClass";level_class.autowrap_mode=TextServer.AUTOWRAP_OFF;level_class.custom_minimum_size.x=155;level_class.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;identity_row.add_child(level_class)
	var identity_space:=Control.new();identity_space.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity_row.add_child(identity_space)
	var prestige:=label(PrestigeSystem.stars(hero),16,C_GOLD);prestige.name="HeroPrestige";prestige.tooltip_text="Prestige";prestige.autowrap_mode=TextServer.AUTOWRAP_OFF;prestige.custom_minimum_size.x=70;prestige.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;prestige.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;identity_row.add_child(prestige)
	var experience_row:=HBoxContainer.new();experience_row.name="HeroExperienceRow";experience_row.custom_minimum_size.x=464;experience_row.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;experience_row.alignment=BoxContainer.ALIGNMENT_CENTER;character.add_child(experience_row)
	var experience:=make_hero_experience_bar(hero,330,24);experience_row.add_child(experience)
	var equipment_row:=HBoxContainer.new();equipment_row.add_theme_constant_override("separation",12);character.add_child(equipment_row)
	var left_slots:=VBoxContainer.new();left_slots.add_theme_constant_override("separation",8);equipment_row.add_child(left_slots)
	for slot in ["head","chest","weapon"]:left_slots.add_child(make_roster_equipment_slot(hero,slot))
	var portrait:=Button.new();portrait.name="HeroPortrait";portrait.text=role_glyph(hero["class"]);portrait.disabled=true;portrait.custom_minimum_size=Vector2(230,220);portrait.add_theme_font_size_override("font_size",64)
	portrait.add_theme_stylebox_override("disabled",ui_box(Color("1a2332"),4,Color("35445a"),1))
	if bool(hero.get("is_special_hero",false)):portrait.tooltip_text="Prestige hero";portrait.add_theme_stylebox_override("disabled",ui_box(Color("1a2332"),110,C_GOLD,6))
	equipment_row.add_child(portrait)
	var right_slots:=VBoxContainer.new();right_slots.add_theme_constant_override("separation",8);equipment_row.add_child(right_slots)
	for slot in ["neck","hands","trinket"]:right_slots.add_child(make_roster_equipment_slot(hero,slot))
	var stats_row:=HBoxContainer.new();stats_row.name="HeroStats";stats_row.custom_minimum_size.x=464;stats_row.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;stats_row.add_theme_constant_override("separation",0);character.add_child(stats_row)
	var stats_indent:=Control.new();stats_indent.custom_minimum_size.x=117;stats_row.add_child(stats_indent)
	var stats_group:=HBoxContainer.new();stats_group.name="HeroStatsGroup";stats_group.custom_minimum_size=Vector2(230,54);stats_group.add_theme_constant_override("separation",8);stats_row.add_child(stats_group)
	var stat_values:=[{"title":"HEALTH","value":int(resolved_stats.health),"color":Color("69d69f")},{"title":"POWER","value":int(resolved_stats.power),"color":Color("65adff")},{"title":"ARMOR","value":"%d%%"%int(round(resolved_stats.armor_reduction*100.0)),"color":Color("e6b85c")}]
	for stat in stat_values:
		var tile:=PanelContainer.new();tile.name="HeroStat"+str(stat.title).capitalize();tile.custom_minimum_size=Vector2(71,54);tile.add_theme_stylebox_override("panel",ui_box(Color("1b283a"),4,Color("35445a"),1));stats_group.add_child(tile)
		var tile_content:=VBoxContainer.new();tile_content.alignment=BoxContainer.ALIGNMENT_CENTER;tile_content.add_theme_constant_override("separation",0);tile.add_child(tile_content)
		var stat_title:=label(str(stat.title),10,C_MUTED);stat_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tile_content.add_child(stat_title)
		var stat_value:=label(str(stat.value),18,stat.color);stat_value.name="HeroStat"+str(stat.title).capitalize()+"Value";stat_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tile_content.add_child(stat_value)
	var workspace:=VBoxContainer.new();workspace.name="RosterWorkspace";workspace.custom_minimum_size.x=635;workspace.size_flags_horizontal=Control.SIZE_EXPAND_FILL;workspace.size_flags_vertical=Control.SIZE_EXPAND_FILL;workspace.add_theme_constant_override("separation",10);detail.add_child(workspace)
	var tabs:=HBoxContainer.new();tabs.alignment=BoxContainer.ALIGNMENT_CENTER;tabs.add_theme_constant_override("separation",7);workspace.add_child(tabs)
	for section in ["Details","Talents","Abilities","Professions"]:tabs.add_child(make_roster_section_button(section))
	var workspace_panel:=PanelContainer.new();workspace_panel.name="RosterWorkspacePanel";workspace_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL;workspace_panel.add_theme_stylebox_override("panel",ui_box(Color("172234"),4,Color("35445a"),1));workspace.add_child(workspace_panel)
	var workspace_margin:=MarginContainer.new();workspace_margin.add_theme_constant_override("margin_left",18);workspace_margin.add_theme_constant_override("margin_right",18);workspace_margin.add_theme_constant_override("margin_top",14);workspace_margin.add_theme_constant_override("margin_bottom",14);workspace_panel.add_child(workspace_margin)
	var section_scroll:=ScrollContainer.new();section_scroll.name="RosterSectionScroll";section_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;section_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;section_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;workspace_margin.add_child(section_scroll)
	var section_content:=VBoxContainer.new();section_content.name="RosterSectionContent";section_content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;section_scroll.add_child(section_content);populate_roster_workspace(section_content,hero,info)
	restore_roster_scroll(section_scroll,"%d:%s"%[selected_roster_index,hero_roster_section])
