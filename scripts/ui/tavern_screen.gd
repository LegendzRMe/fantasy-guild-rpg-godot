extends "res://scripts/ui/profession_screen.gd"

var tavern_scroll_positions: Dictionary = {}


func remember_tavern_scroll_positions() -> void:
	for scroll_name in [
		"TavernOverviewScroll",
		"TavernRecruitmentPageScroll",
		"TavernActivityScroll",
		"TavernKitchenScroll",
		"TavernRestAreaScroll",
		"TavernRecoveryPageScroll",
		"TavernRecoveryScroll",
	]:
		var scroll := ui.find_child(scroll_name, true, false) as ScrollContainer
		if scroll != null:
			tavern_scroll_positions[scroll_name] = scroll.scroll_vertical


func restore_tavern_scroll_positions() -> void:
	await get_tree().process_frame
	for scroll_name in tavern_scroll_positions:
		var scroll := ui.find_child(str(scroll_name), true, false) as ScrollContainer
		if scroll != null:
			scroll.scroll_vertical = int(tavern_scroll_positions[scroll_name])


func tavern_refresh_is_safe() -> bool:
	for control in ui.find_children("*", "OptionButton", true, false):
		var option := control as OptionButton
		if option != null and option.get_popup().visible:
			return false
	for control in ui.find_children("*", "LineEdit", true, false):
		if control.has_focus():
			return false
	return true


func tavern_time_text(minutes:float) -> String:
	var total:=maxi(0,int(ceil(minutes)));return "%dh %02dm"%[total/60,total%60]

func set_recruitment_budget(value:float) -> void:
	RecruitmentSystem.set_budget(state,int(value));save_game();show_tavern()

func confirm_tavern_rename(field:LineEdit,previous_name:String) -> void:
	var renamed:=RecruitmentSystem.set_tavern_name(state,field.text)
	if renamed==previous_name:
		show_tavern();return
	if save_game():
		show_tavern();flash("The Tavern is now named %s."%renamed);return
	RecruitmentSystem.set_tavern_name(state,previous_name)
	show_tavern();flash("The Tavern name could not be saved.")

func request_rename_tavern() -> void:
	var previous_name:=str(state.recruitment.tavern_name)
	var dialog:=ConfirmationDialog.new();dialog.name="RenameTavernDialog";dialog.title="NAME THE TAVERN";dialog.dialog_text="Choose the name shown throughout the Guild Hall.\n\n\n";dialog.ok_button_text="Save Name";dialog.min_size=Vector2i(520,250)
	var field:=LineEdit.new();field.name="TavernNameInput";field.text=previous_name;field.placeholder_text="The Tavern";field.position=Vector2(24,92);field.size=Vector2(472,42);field.max_length=32;field.tooltip_text="Up to 32 characters.";dialog.add_child(field);dialog.register_text_enter(field)
	dialog.confirmed.connect(confirm_tavern_rename.bind(field,previous_name))
	ui.add_child(dialog);dialog.popup_centered(Vector2i(520,250));field.grab_focus();field.select_all()

func inspect_tavern_candidate() -> void:
	var candidate:=RecruitmentSystem.current_candidate(state)
	if candidate.is_empty():return
	recruitment_preview_candidate_id=str(candidate.candidate_id);show_recruitment_candidate_preview(candidate)

func recruit_tavern_candidate() -> void:
	var result:=RecruitmentSystem.recruit_candidate(state)
	if bool(result.success):save_game();show_tavern();flash(str(result.reason))
	else:flash(str(result.reason))

func recruit_tavern_candidate_familiar() -> void:
	var result:=RecruitmentSystem.recruit_candidate(state,true)
	if bool(result.success):save_game();show_tavern();flash(str(result.reason))
	else:flash(str(result.reason))

func start_tavern_campaign(campaign_id:String) -> void:
	var result:=TavernManagementSystem.start_campaign(state,campaign_id)
	if bool(result.success):save_game();show_tavern();flash(str(result.reason))
	else:flash(str(result.reason))

func end_tavern_campaign() -> void:
	var result:=TavernManagementSystem.end_campaign(state)
	if bool(result.success):save_game();show_tavern();flash("Campaign report finalized.")
	else:flash(str(result.reason))

func debug_add_locked_tavern_candidate() -> void:
	if RecruitmentSystem.current_candidate(state).is_empty():RecruitmentSystem.debug_spawn(state)
	var candidate:=RecruitmentSystem.current_candidate(state);if not candidate.is_empty():candidate.locked=true
	save_game();show_tavern()

func tavern_table_talk(category:String) -> void:
	var result:=CookingSystem.table_talk(state,category)
	if bool(result.success):save_game();show_tavern();flash(str(result.reason))
	else:flash(str(result.reason))

func serve_tavern_patron_meal(meal_id:String) -> void:
	var result:=CookingSystem.serve_candidate_meal(state,selected_tavern_cook_id,meal_id)
	if bool(result.success):save_game();show_tavern();flash(str(result.reason))
	else:flash(str(result.reason))

func reject_tavern_candidate() -> void:
	var result:=RecruitmentSystem.reject_candidate(state)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func lock_tavern_candidate() -> void:
	var result:=RecruitmentSystem.toggle_candidate_lock(state)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func debug_advance_recruitment(minutes:float) -> void:
	GameClockSystem.ensure_state(state);state.game_clock.total_minutes=float(state.game_clock.total_minutes)+maxf(0.0,minutes)
	RecruitmentSystem.advance(state,minutes);TavernFacilitySystem.advance(state,minutes);save_game();show_tavern()

func debug_complete_recruitment_hour() -> void:
	debug_advance_recruitment(float(state.recruitment.minutes_until_next_check))

func debug_spawn_recruitment_candidate() -> void:
	var result:=RecruitmentSystem.debug_spawn(state)
	if not bool(result.success):flash(str(result.reason));return
	save_game();show_tavern()

func debug_clear_recruitment_candidate() -> void:
	state.recruitment.candidates.clear();save_game();show_tavern()

func debug_set_recruitment_disclosure(score:int) -> void:
	if RecruitmentSystem.debug_set_disclosure(state,score):save_game();show_tavern()

func debug_add_recruitment_gold() -> void:
	state.gold=int(state.gold)+250;save_game();show_tavern()

func debug_expire_recruitment_candidate() -> void:
	var candidate:=RecruitmentSystem.current_candidate(state)
	if candidate.is_empty():return
	if bool(candidate.locked):flash("Unlock the candidate before expiring them.");return
	debug_advance_recruitment(float(candidate.remaining_wait_minutes))

func make_tavern_status_card(title:String,value:String,accent:Color=C_TEXT)->PanelContainer:
	var card:=PanelContainer.new();card.custom_minimum_size=Vector2(285,72);card.add_theme_stylebox_override("panel",ui_box(Color("182334"),6,Color("35445a"),1))
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;card.add_child(content);var heading:=label(title,12,C_MUTED);heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(heading);var amount:=label(value,18,accent);amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(amount);return card

func populate_tavern_candidate(container:VBoxContainer,candidate:Dictionary) -> void:
	var hero:Dictionary=candidate.hero_record;var class_revealed:=RecruitmentSystem.field_is_revealed(candidate,"class");var level_revealed:=RecruitmentSystem.field_is_revealed(candidate,"exact_level")
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",14);container.add_child(header)
	var portrait:=Button.new();portrait.name="TavernCandidatePortrait";portrait.disabled=true;portrait.text="?";portrait.custom_minimum_size=Vector2(112,112);portrait.add_theme_font_size_override("font_size",40);portrait.add_theme_stylebox_override("disabled",ui_box(Color("1a2332"),56,C_MUTED,3));header.add_child(portrait)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(identity);identity.add_child(label(str(hero.display_name),27,C_TEXT));identity.add_child(label(str(candidate.broad_role),16,C_TEXT));identity.add_child(label("Level %d"%int(hero.level) if level_revealed else "Level not disclosed",15,C_MUTED));if class_revealed:identity.add_child(label(str(hero["class"]),14,C_MUTED))
	var disclosure:=VBoxContainer.new();disclosure.custom_minimum_size.x=255;header.add_child(disclosure);disclosure.add_child(label("INFORMATION REVEALED",12,C_GOLD));disclosure.add_child(label("%d of %d"%[int(candidate.revealed_field_count),int(candidate.total_revealable_field_count)],22,C_TEXT));var meter:=ProgressBar.new();meter.name="TavernDisclosureMeter";meter.max_value=100;meter.value=int(candidate.information_disclosure_score);meter.show_percentage=true;meter.custom_minimum_size=Vector2(240,24);disclosure.add_child(meter)
	container.add_child(rule());var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;actions.add_theme_constant_override("separation",9);container.add_child(actions)
	var inspect:=compact_button("Inspect Candidate",inspect_tavern_candidate,175);inspect.name="TavernInspectCandidate";actions.add_child(inspect)
	var recruit:=compact_button("Recruit  •  %d Gold"%int(candidate.signing_cost),recruit_tavern_candidate,190);recruit.name="TavernRecruitCandidate";recruit.disabled=int(state.gold)<int(candidate.signing_cost);recruit.tooltip_text="Signing cost is separate from the Tavern Budget.";actions.add_child(recruit)
	var familiar:=CookingSystem.familiar_offer_status(state);var familiar_button:=compact_button("Familiar  •  %d Gold"%int(familiar.get("cost",candidate.signing_cost)),recruit_tavern_candidate_familiar,170);familiar_button.name="TavernFamiliarOffer";familiar_button.disabled=not bool(familiar.get("available",false)) or int(state.gold)<int(familiar.get("cost",candidate.signing_cost));familiar_button.tooltip_text=str(familiar.get("reason",""));actions.add_child(familiar_button)
	var reject:=compact_button("Reject",reject_tavern_candidate,105);reject.name="TavernRejectCandidate";actions.add_child(reject)
	var lock:=compact_button("Unlock" if bool(candidate.locked) else "Lock",lock_tavern_candidate,105);lock.name="TavernLockCandidate";actions.add_child(lock)
	container.add_child(label("Current staying income: %d Gold"%int(floor(float(candidate.get("current_stay_income",0.0)))),13,C_GREEN if bool(candidate.locked) and int(state.tavern_management.tavern_level)>=2 else C_MUTED))
	container.add_child(label("%s  •  %s"%["LOCKED — departure timer stopped" if bool(candidate.locked) else "Leaves in %s"%tavern_time_text(float(candidate.remaining_wait_minutes)),"Signing cost %d Gold"%int(candidate.signing_cost)],14,C_GOLD if bool(candidate.locked) else C_MUTED))

func populate_recruitment_debug(container:VBoxContainer) -> void:
	var debug_panel:=PanelContainer.new();debug_panel.name="RecruitmentDebugPanel";debug_panel.custom_minimum_size.y=52;debug_panel.add_theme_stylebox_override("panel",ui_box(Color("171d2b"),5,Color("69568f"),1));container.add_child(debug_panel)
	var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",6);debug_panel.add_child(row);var heading:=label("TEST TOOLS",11,Color("c6a8ff"));heading.custom_minimum_size.x=76;heading.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(heading)
	for entry in [["Complete Wait",debug_complete_recruitment_hour,116],["Spawn",debug_spawn_recruitment_candidate,82],["Clear",debug_clear_recruitment_candidate,76],["+250 Gold",debug_add_recruitment_gold,92],["Expire",debug_expire_recruitment_candidate,76]]:
		var action:=compact_button(str(entry[0]),entry[1],float(entry[2]));action.custom_minimum_size.y=30;action.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(action)
	var disclosure:=OptionButton.new();disclosure.name="RecruitmentDebugDisclosure";disclosure.custom_minimum_size=Vector2(170,30);disclosure.add_item("Disclosure…");disclosure.add_item("Low disclosure");disclosure.set_item_metadata(1,20);disclosure.add_item("Medium disclosure");disclosure.set_item_metadata(2,55);disclosure.add_item("Full disclosure");disclosure.set_item_metadata(3,100);disclosure.item_selected.connect(func(index):if index>0:debug_set_recruitment_disclosure(int(disclosure.get_item_metadata(index))));row.add_child(disclosure)

func add_tavern_title_controls(root:VBoxContainer) -> void:
	var title_row:HBoxContainer=root.get_child(0);title_row.custom_minimum_size.y=48;title_row.add_theme_constant_override("separation",8);var title_label:Label=title_row.get_child(0);title_label.name="TavernTitleLabel";title_label.custom_minimum_size.x=280;title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_label.autowrap_mode=TextServer.AUTOWRAP_OFF;title_label.clip_text=true;title_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var return_button:Control=title_row.get_child(title_row.get_child_count()-1)
	return_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var rename:=compact_button("Rename Tavern",request_rename_tavern,120);rename.name="RenameTavernButton";rename.size_flags_vertical=Control.SIZE_SHRINK_CENTER;title_row.add_child(rename);title_row.move_child(rename,1)
	var level_badge:=label("TAVERN LEVEL %d"%int(state.get("tavern_management",{}).get("tavern_level",1)),12,C_GOLD);level_badge.name="TavernLevelBadge";level_badge.custom_minimum_size=Vector2(125,34);level_badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;level_badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;level_badge.add_theme_stylebox_override("normal",ui_box(Color("241f18"),12,Color("705f35"),1));title_row.add_child(level_badge);title_row.move_child(level_badge,2)
	var spacer:=Control.new();spacer.name="TavernHeaderSpacer";spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_row.add_child(spacer);title_row.move_child(spacer,3)
	var gold:=label("Gold  •  %d"%int(state.gold),13,C_MUTED);gold.name="TavernGoldReadout";gold.custom_minimum_size=Vector2(105,34);gold.autowrap_mode=TextServer.AUTOWRAP_OFF;gold.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;gold.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;gold.size_flags_vertical=Control.SIZE_SHRINK_CENTER;title_row.add_child(gold);title_row.move_child(gold,return_button.get_index())

func set_tavern_section(section:String) -> void:
	remember_tavern_scroll_positions();tavern_section=section;show_tavern()

func add_tavern_sections(root:VBoxContainer) -> void:
	var tabs:=HBoxContainer.new();tabs.name="TavernSectionTabs";tabs.alignment=BoxContainer.ALIGNMENT_CENTER;tabs.add_theme_constant_override("separation",8);root.add_child(tabs)
	for section in ["Overview","Recruitment","Kitchen","Rest Area"]:
		var tab:=compact_button(section,func(value=section):set_tavern_section(value),180);tab.name="TavernSection%s"%section.replace(" ","").replace("&","")
		if tavern_section==section:tab.add_theme_color_override("font_color",C_GOLD);tab.add_theme_stylebox_override("normal",ui_box(Color("2b3b52"),5,C_GOLD,2))
		tabs.add_child(tab)

func set_tavern_assignment(role:String,hero_id:String) -> void:
	var result:=TavernManagementSystem.remove_assignment(state,role) if hero_id=="" else TavernManagementSystem.assign_member(state,role,hero_id)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func set_tavern_level_debug(level:int) -> void:
	TavernManagementSystem.set_level(state,level);save_game();show_tavern()

func clear_tavern_income_debug() -> void:
	state.tavern_management.lifetime_food_sales=0.0;state.tavern_management.lifetime_staying_fees=0.0;state.tavern_management.last_campaign_report={};if bool(state.tavern_management.campaign.get("active",false)):state.tavern_management.campaign.food_sales=0.0;state.tavern_management.campaign.staying_fees=0.0
	save_game();show_tavern()

func populate_tavern_assignment(container:VBoxContainer,role:String,description:String) -> void:
	var key:="%s_id"%role;var assigned_id:=str(state.tavern_management.assignments.get(key,""));var locked:=role=="steward" and int(state.tavern_management.tavern_level)<TavernManagementData.STEWARD_UNLOCK_LEVEL
	var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",ui_box(Color("172234"),6,Color("35445a"),1));container.add_child(card);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);card.add_child(row);var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(copy);copy.add_child(label(role.to_upper()+("  •  LOCKED UNTIL LEVEL 3" if locked else ""),14,C_GOLD if not locked else C_MUTED));copy.add_child(label(TavernManagementSystem.hero_name(state,assigned_id) if assigned_id!="" else "Empty slot",17,C_TEXT));var note:=label(description,12,C_MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;copy.add_child(note)
	var selector:=OptionButton.new();selector.name="Tavern%sAssignment"%role.capitalize();selector.custom_minimum_size=Vector2(210,40);selector.disabled=locked;selector.add_item("Empty");selector.set_item_metadata(0,"")
	for hero in state.heroes:
		var hero_id:=str(hero.hero_id);var check:=TavernManagementSystem.assignment_eligibility(state,hero_id,role)
		if bool(check.eligible) or hero_id==assigned_id:selector.add_item(str(hero.display_name));selector.set_item_metadata(selector.item_count-1,hero_id);if hero_id==assigned_id:selector.select(selector.item_count-1)
	selector.item_selected.connect(func(index):set_tavern_assignment(role,str(selector.get_item_metadata(index))));row.add_child(selector)

func _populate_tavern_overview_legacy(root:VBoxContainer) -> void:
	var scroll:=ScrollContainer.new();scroll.name="TavernOverviewScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll);var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",10);scroll.add_child(content)
	var heading:=HBoxContainer.new();content.add_child(heading);var title:=label("TAVERN LEVEL %d"%int(state.tavern_management.tavern_level),22,C_GOLD);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title);heading.add_child(label("Open Taproom" if int(state.tavern_management.tavern_level)>=2 else "Guild Kitchen",16,C_TEXT))
	populate_tavern_assignment(content,"host","Hosts will later influence candidate stays, revealed information, visitor spending, and recruitment results.")
	populate_tavern_assignment(content,"chef","The Chef handles manual meals and one mastered automated stock target.")
	populate_tavern_assignment(content,"steward","Future rest priorities, meal duration, food waste, and Recovery Wing delivery.")
	content.add_child(rule());content.add_child(label("CURRENT SERVICE",15,C_GOLD));var selected_meal:=str(state.tavern_management.selected_rest_meal_id);content.add_child(label("Rest Meal: %s"%str(CookingData.MEALS.get(selected_meal,{}).get("display_name","None selected")),15,C_TEXT));content.add_child(label("Food & drink sales: %d Gold  •  Candidate staying fees: %d Gold"%[int(floor(float(state.tavern_management.lifetime_food_sales))),int(floor(float(state.tavern_management.lifetime_staying_fees)))],14,C_MUTED))
	if is_testing_save():
		content.add_child(rule());var debug:=HBoxContainer.new();debug.alignment=BoxContainer.ALIGNMENT_CENTER;debug.add_theme_constant_override("separation",8);content.add_child(debug);debug.add_child(label("TAVERN TEST",11,Color("c6a8ff")));debug.add_child(compact_button("Level 1",func():set_tavern_level_debug(1),90));debug.add_child(compact_button("Level 2",func():set_tavern_level_debug(2),90));debug.add_child(compact_button("Clear Income",clear_tavern_income_debug,120))

func assign_tavern_rest_slot(slot_id:int,hero_id:String) -> void:
	var result:=TavernManagementSystem.assign_rest_slot(state,slot_id,hero_id)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func remove_tavern_rest_slot(slot_id:int) -> void:
	var result:=TavernManagementSystem.remove_rest_slot(state,slot_id)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func select_management_rest_meal(meal_id:String) -> void:
	var result:=TavernManagementSystem.set_rest_meal(state,meal_id)
	if bool(result.success):save_game();show_tavern()

func debug_complete_management_rest() -> void:
	for rest in state.tavern_facility.rest_assignments:
		if bool(rest.get("consume_on_completion",false)):rest.remaining_minutes=0.01
	debug_advance_recruitment(0.02)

func populate_tavern_rest_area(root:VBoxContainer) -> void:
	var scroll:=ScrollContainer.new();scroll.name="TavernRestAreaScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll);var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",10);scroll.add_child(content)
	var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",10);content.add_child(controls);var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_child(text);text.add_child(label("REST AREA",20,C_GOLD));text.add_child(label("Healthy, inactive members rest for 10 minutes. Removing them pauses their progress without punishment.",13,C_MUTED));var meal_select:=OptionButton.new();meal_select.name="TavernRestMealSelector";meal_select.custom_minimum_size=Vector2(285,42);meal_select.add_item("No Rest Meal");meal_select.set_item_metadata(0,"")
	var selected:=str(state.tavern_management.selected_rest_meal_id)
	for meal_id in CookingData.MEALS:
		var definition:Dictionary=CookingData.MEALS[meal_id]
		if str(definition.get("purpose","")) not in ["rest","mission"]:continue
		meal_select.add_item("%s  •  %d"%[str(definition.display_name),TavernFacilitySystem.meal_count(state,str(meal_id))]);meal_select.set_item_metadata(meal_select.item_count-1,str(meal_id));if str(meal_id)==selected:meal_select.select(meal_select.item_count-1)
	meal_select.item_selected.connect(func(index):select_management_rest_meal(str(meal_select.get_item_metadata(index))));controls.add_child(meal_select)
	content.add_child(label("Automatic assignment: %s"%("ON — first eligible inactive member" if int(state.tavern_management.tavern_level)>=2 else "OFF — unlocks at Tavern Level 2"),13,C_GREEN if int(state.tavern_management.tavern_level)>=2 else C_MUTED))
	for slot in state.tavern_management.rest_slots:
		var slot_id:=int(slot.slot_id);var hero_id:=str(slot.hero_id);var card:=PanelContainer.new();card.custom_minimum_size.y=78;card.add_theme_stylebox_override("panel",ui_box(Color("172234"),6,Color("35445a"),1));content.add_child(card);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);card.add_child(row);var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(copy);copy.add_child(label("REST SLOT %d"%(slot_id+1),13,C_GOLD));copy.add_child(label(TavernManagementSystem.hero_name(state,hero_id) if hero_id!="" else "Empty",18,C_TEXT))
		if hero_id!="":var assignment:=TavernFacilitySystem.rest_assignment(state,hero_id);copy.add_child(label("%s remaining"%tavern_time_text(float(assignment.get("remaining_minutes",0.0))),13,C_MUTED));row.add_child(compact_button("Remove",func(id=slot_id):remove_tavern_rest_slot(id),100))
		else:
			var selector:=OptionButton.new();selector.custom_minimum_size=Vector2(230,40);selector.add_item("Choose member…");selector.set_item_metadata(0,"")
			for hero in state.heroes:
				var check:=TavernManagementSystem.rest_eligibility(state,str(hero.hero_id));if bool(check.eligible):selector.add_item(str(hero.display_name));selector.set_item_metadata(selector.item_count-1,str(hero.hero_id))
			selector.item_selected.connect(func(index):if index>0:assign_tavern_rest_slot(slot_id,str(selector.get_item_metadata(index))));row.add_child(selector)
	content.add_child(rule());var recovery_note:=label("Recovery Broth is stored in the Tavern meal inventory for a future Recovery Wing request. Normal Tavern rest never accepts defeated, injured, or recovering members.",13,C_MUTED);recovery_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(recovery_note)
	if is_testing_save():content.add_child(compact_button("Complete Rest Timers",debug_complete_management_rest,190))

func start_tavern_rest(hero_id:String) -> void:
	var result:=TavernFacilitySystem.start_rest(state,hero_id)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func start_tavern_rest_meal(hero_id:String,meal_id:String) -> void:
	var result:=TavernFacilitySystem.start_rest(state,hero_id,meal_id)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func serve_tavern_recovery_meal(hero_id:String) -> void:
	var result:=TavernFacilitySystem.serve_recovery_meal(state,hero_id)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func serve_tavern_complete_rest(hero_id:String,meal_id:String) -> void:
	var result:=TavernFacilitySystem.serve_complete_rest_meal(state,hero_id,meal_id)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func start_tavern_second_course(hero_id:String,meal_id:String) -> void:
	var result:=TavernFacilitySystem.start_second_course(state,hero_id,meal_id)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func select_tavern_facility_hero(index:int) -> void:
	selected_tavern_facility_hero=clampi(index,0,maxi(0,state.heroes.size()-1))

func debug_tavern_injury(recovery_type:String) -> void:
	if state.heroes.is_empty():return
	var hero_id:=str(state.heroes[clampi(selected_tavern_facility_hero,0,state.heroes.size()-1)].hero_id);var result:=TavernFacilitySystem.start_recovery(state,hero_id,recovery_type)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func debug_add_tavern_provisions() -> void:
	InventorySystem.add_material(state,"provisions",20);save_game();show_tavern()

func populate_tavern_recovery(root:VBoxContainer) -> void:
	var page_scroll:=ScrollContainer.new();page_scroll.name="TavernRecoveryPageScroll";page_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(page_scroll)
	var page:=VBoxContainer.new();page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;page.add_theme_constant_override("separation",10);page_scroll.add_child(page)
	var production:=VBoxContainer.new();production.name="TavernRecoveryProduction";production.custom_minimum_size.y=500;production.size_flags_horizontal=Control.SIZE_EXPAND_FILL;production.add_theme_constant_override("separation",10);page.add_child(production)
	var summary:=HBoxContainer.new();summary.add_theme_constant_override("separation",10);production.add_child(summary)
	summary.add_child(make_tavern_status_card("RECOVERING",str(state.tavern_facility.recovery_cases.size()),C_GREEN));summary.add_child(make_tavern_status_card("RESTING",str(state.tavern_facility.rest_assignments.size()),C_GOLD));summary.add_child(make_tavern_status_card("TABLE MEALS",str(TavernFacilitySystem.meal_count(state,"common_table_meal")),C_TEXT));summary.add_child(make_tavern_status_card("RECOVERY BROTH",str(TavernFacilitySystem.meal_count(state,"restorative_broth")),C_TEXT))
	var note:=label("Defeated Heroes recover automatically for 10 minutes. Voluntary rest requires a Common Table Meal and grants +10% temporary HP for the next mission. Shields absorb damage before temporary HP.",13,C_MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;production.add_child(note)
	var scroll:=ScrollContainer.new();scroll.name="TavernRecoveryScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;production.add_child(scroll);var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",7);scroll.add_child(list)
	for hero in state.heroes:
		var hero_id:=str(hero.hero_id);var status:=TavernFacilitySystem.member_status(state,hero_id);var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",ui_box(Color("172234"),6,Color("35445a"),1));list.add_child(card);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);card.add_child(row);var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(copy);copy.add_child(label(str(hero.display_name)+"  •  "+str(hero["class"]),17,CLASSES[str(hero["class"])].color));copy.add_child(label(str(status.label),13,C_GREEN if str(status.status) in ["available","well_rested"] else C_GOLD))
		if str(status.status)=="recovering":
			var recovery:=TavernFacilitySystem.recovery_case(state,hero_id);var serve:=compact_button("Serve Broth",func(id=hero_id):serve_tavern_recovery_meal(id),125);serve.disabled=TavernFacilitySystem.meal_count(state,"restorative_broth")<=0 or float(recovery.recovery_rate_multiplier)>1.0;serve.tooltip_text="Increases this stay's recovery speed by 25%.";row.add_child(serve)
			var complete:=OptionButton.new();complete.custom_minimum_size=Vector2(175,38);complete.add_item("Complete Rest…")
			for meal_id in ["fortifying_meal","hefty_meal","fatty_meal","hasty_meal"]:
				complete.add_item("%s (%d)"%[str(CookingData.MEALS[meal_id].display_name),TavernFacilitySystem.meal_count(state,meal_id)]);complete.set_item_metadata(complete.item_count-1,meal_id)
			complete.item_selected.connect(func(index):if index>0:serve_tavern_complete_rest(hero_id,str(complete.get_item_metadata(index))));row.add_child(complete)
		elif str(status.status)=="available":
			var rest:=compact_button("Rest 10m",func(id=hero_id):start_tavern_rest(id),110);rest.disabled=TavernFacilitySystem.meal_count(state,"common_table_meal")<=0 or str(hero.profession_progress.get("current_profession_order_id",""))!="";rest.tooltip_text="Consumes one Common Table Meal.";row.add_child(rest)
			var meal_rest:=OptionButton.new();meal_rest.custom_minimum_size=Vector2(165,38);meal_rest.add_item("Mission Meal…")
			for meal_id in ["fortifying_meal","hefty_meal","fatty_meal","hasty_meal"]:
				meal_rest.add_item("%s (%d)"%[str(CookingData.MEALS[meal_id].display_name),TavernFacilitySystem.meal_count(state,meal_id)]);meal_rest.set_item_metadata(meal_rest.item_count-1,meal_id)
			meal_rest.item_selected.connect(func(index):if index>0:start_tavern_rest_meal(hero_id,str(meal_rest.get_item_metadata(index))));row.add_child(meal_rest)
		elif str(status.status)=="well_rested":
			var second:=OptionButton.new();second.custom_minimum_size=Vector2(175,38);second.add_item("Second Course…")
			for meal_id in ["fortifying_meal","hefty_meal","fatty_meal","hasty_meal"]:
				second.add_item("%s (%d)"%[str(CookingData.MEALS[meal_id].display_name),TavernFacilitySystem.meal_count(state,meal_id)]);second.set_item_metadata(second.item_count-1,meal_id)
			second.item_selected.connect(func(index):if index>0:start_tavern_second_course(hero_id,str(second.get_item_metadata(index))));row.add_child(second)
	if is_testing_save():
		page.add_child(rule());var debug:=PanelContainer.new();debug.name="TavernRecoveryDebug";debug.custom_minimum_size.y=52;debug.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;debug.add_theme_stylebox_override("panel",ui_box(Color("171d2b"),5,Color("69568f"),1));page.add_child(debug);var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",7);debug.add_child(row);var debug_title:=label("RECOVERY TEST",11,Color("c6a8ff"));debug_title.custom_minimum_size.x=110;debug_title.autowrap_mode=TextServer.AUTOWRAP_OFF;debug_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(debug_title);var member:=OptionButton.new();member.name="TavernRecoveryDebugHero";member.custom_minimum_size=Vector2(180,30);member.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		for index in state.heroes.size():member.add_item(str(state.heroes[index].display_name));member.set_item_metadata(index,index)
		member.select(clampi(selected_tavern_facility_hero,0,maxi(0,state.heroes.size()-1)));member.item_selected.connect(func(index):select_tavern_facility_hero(int(member.get_item_metadata(index))));row.add_child(member)
		for action_data in [["Minor 20m",func():debug_tavern_injury("minor"),110],["Serious 60m",func():debug_tavern_injury("serious"),120],["Advance 10m",func():debug_advance_recruitment(10.0),125],["+20 Provisions",debug_add_tavern_provisions,135]]:
			var action:=compact_button(str(action_data[0]),action_data[1],float(action_data[2]));action.custom_minimum_size.y=30;action.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(action)

func open_cooking_training_roster() -> void:
	hero_roster_section="Professions";show_roster()

func select_tavern_cook(hero_id:String) -> void:
	selected_tavern_cook_id=hero_id;show_tavern()

func start_tavern_cooking_order(hero_id:String,recipe_id:String) -> void:
	var result:=ProfessionSystem.start_profession_order(state,hero_id,recipe_id)
	if bool(result.success):save_game();show_tavern();flash("Cooking order started.")
	else:flash(str(result.reason))

func tavern_cooking_order_action(order_id:String,action:String) -> void:
	var result:=ProfessionSystem.cancel_profession_order(state,order_id) if action=="cancel" else ProfessionSystem.pause_profession_order(state,order_id,action=="pause") if action in ["pause","resume"] else ProfessionSystem.complete_profession_order(state,order_id)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func debug_cooking_patron_refresh() -> void:
	var result:=CookingSystem.on_candidate_refresh(state,"debug_campaign")
	if bool(result.success):save_game();show_tavern();flash(str(result.reason))
	else:flash(str(result.reason))

func debug_add_prepared_cooking_meals() -> void:
	for meal_id in CookingData.MEALS:
		if str(CookingData.MEALS[meal_id].get("purpose",""))!="service":TavernFacilitySystem.add_prepared_meals(state,str(meal_id),2,selected_tavern_cook_id)
	save_game();show_tavern()

func start_tavern_manual_cooking(recipe_id:String) -> void:
	var result:=TavernManagementSystem.start_manual_cooking(state,recipe_id)
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func stop_tavern_manual_cooking() -> void:
	var result:=TavernManagementSystem.stop_manual_cooking(state)
	if bool(result.success):save_game();show_tavern();flash("Cooking result: %s"%str(result.reason))
	else:flash(str(result.reason))

func set_tavern_stock_target(recipe_id:String,value:float) -> void:
	var result:=TavernManagementSystem.set_automation(state,recipe_id,int(value))
	if bool(result.success):save_game();show_tavern()
	else:flash(str(result.reason))

func debug_tavern_recipe_mastery(mastered:bool) -> void:
	for recipe_id in TavernManagementData.PROTOTYPE_RECIPES:
		if mastered:
			ProfessionSystem.discover_recipe(state,recipe_id,true);state.guild_recipes[recipe_id].success_count=int(ProfessionData.RECIPES[recipe_id].mastery_required);state.guild_recipes[recipe_id].knowledge_state="pattern_mastered";state.guild_recipes[recipe_id].automation_eligible=true
		else:state.guild_recipes.erase(recipe_id)
	save_game();show_tavern()

func debug_clear_tavern_meals() -> void:
	state.tavern_facility.prepared_meals.clear();save_game();show_tavern()

func debug_complete_manual_cooking() -> void:
	if bool(state.tavern_management.manual_cooking.get("active",false)):state.tavern_management.manual_cooking.marker=0.5;stop_tavern_manual_cooking()

func debug_complete_tavern_automation() -> void:
	if bool(state.tavern_management.automation.get("ingredients_reserved",false)):state.tavern_management.automation.remaining_game_minutes=0.01;TavernManagementSystem.advance(state,0.02,false)
	save_game();show_tavern()

func add_tavern_ingredients_debug() -> void:
	InventorySystem.add_material(state,"provisions",50);save_game();show_tavern()

func _populate_tavern_management_kitchen_legacy(content:VBoxContainer) -> void:
	content.add_child(label("PLAYABLE KITCHEN",18,C_GOLD));var chef_id:=str(state.tavern_management.assignments.chef_id);content.add_child(label("Assigned Chef: %s"%TavernManagementSystem.hero_name(state,chef_id),14,C_TEXT));content.add_child(label("Ingredients are pulled directly from the Workshop Depot in Guild Storage.",12,C_MUTED))
	var attempt:Dictionary=state.tavern_management.manual_cooking
	if bool(attempt.get("active",false)):
		var minigame:=PanelContainer.new();minigame.add_theme_stylebox_override("panel",ui_box(Color("241f18"),6,C_GOLD,2));content.add_child(minigame);var game_row:=HBoxContainer.new();game_row.add_theme_constant_override("separation",10);minigame.add_child(game_row);var game_copy:=VBoxContainer.new();game_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;game_row.add_child(game_copy);game_copy.add_child(label("COOKING  •  %s"%str(ProfessionData.recipe(str(attempt.recipe_id)).display_name),15,C_GOLD));var marker:=ProgressBar.new();marker.name="TavernCookingMarker";marker.min_value=0;marker.max_value=100;marker.value=float(attempt.marker)*100.0;marker.show_percentage=false;marker.custom_minimum_size=Vector2(650,32);game_copy.add_child(marker);game_copy.add_child(label("Center = Perfect  •  Middle band = Cooked  •  Outer edge = Burned",12,C_MUTED));var stop:=compact_button("STOP",stop_tavern_manual_cooking,150);stop.custom_minimum_size.y=64;game_row.add_child(stop)
	else:
		for recipe_id in TavernManagementData.PROTOTYPE_RECIPES:
			var recipe:Dictionary=ProfessionData.recipe(recipe_id);var record:Dictionary=state.guild_recipes.get(recipe_id,{});var successes:=int(record.get("success_count",0));var requirement:=int(recipe.get("mastery_required",3));var mastered:=ProfessionSystem.is_pattern_mastered(state,recipe_id);var row:=HBoxContainer.new();row.custom_minimum_size.y=54;row.add_theme_constant_override("separation",8);content.add_child(row);var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(copy);copy.add_child(label(str(recipe.display_name),15,C_TEXT));copy.add_child(label("%s  •  Mastery %d/%d%s"%[TavernManagementSystem.ingredient_status(state,recipe_id).text,mini(successes,requirement),requirement,"  •  MASTERED" if mastered else ""],12,C_GREEN if mastered else C_MUTED));var cook:=compact_button("Cook",func(id=recipe_id):start_tavern_manual_cooking(id),95);cook.disabled=chef_id=="" or not bool(TavernManagementSystem.ingredient_status(state,recipe_id).available);cook.tooltip_text="Assign a Chef and add the listed ingredients.";row.add_child(cook)
			if mastered:
				var target:=SpinBox.new();target.min_value=0;target.max_value=TavernManagementData.MAX_STOCK_TARGET;target.step=1;target.custom_minimum_size=Vector2(82,40);target.value=int(state.tavern_management.automation.stock_target) if str(state.tavern_management.automation.recipe_id)==recipe_id else 0;target.value_changed.connect(func(value,id=recipe_id):set_tavern_stock_target(id,value));row.add_child(target)
	content.add_child(label("Automation: %s"%str(state.tavern_management.automation.status),13,C_MUTED));content.add_child(label("Tavern meal inventory: %d / %d servings"%[state.tavern_facility.prepared_meals.size(),TavernFacilityData.PREPARED_MEAL_LIMIT],13,C_TEXT));content.add_child(rule())
	if is_testing_save():
		var debug:=HBoxContainer.new();debug.alignment=BoxContainer.ALIGNMENT_CENTER;debug.add_theme_constant_override("separation",6);content.add_child(debug);debug.add_child(label("KITCHEN TEST",11,Color("c6a8ff")));debug.add_child(compact_button("+50 Provisions",add_tavern_ingredients_debug,135));debug.add_child(compact_button("Master All",func():debug_tavern_recipe_mastery(true),105));debug.add_child(compact_button("Reset Mastery",func():debug_tavern_recipe_mastery(false),125));debug.add_child(compact_button("Perfect Current",debug_complete_manual_cooking,130));debug.add_child(compact_button("Finish Auto",debug_complete_tavern_automation,105));debug.add_child(compact_button("Clear Meals",debug_clear_tavern_meals,110));content.add_child(rule())

func _populate_tavern_kitchen_legacy(root:VBoxContainer) -> void:
	var header:=PanelContainer.new();header.custom_minimum_size.y=72;header.add_theme_stylebox_override("panel",ui_box(Color("241f18"),6,Color("705f35"),1));root.add_child(header);var header_row:=HBoxContainer.new();header_row.add_theme_constant_override("separation",12);header.add_child(header_row);var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header_row.add_child(copy);copy.add_child(label("TAVERN KITCHEN",20,C_GOLD));copy.add_child(label("Prepare meals here. Heroes learn Cooking from the Professions tab in the Hero Roster.",13,C_MUTED));var provisions:=label("PROVISIONS  •  %d"%int(state.get("provisions",0)),16,C_TEXT);provisions.name="TavernProvisionsReadout";provisions.custom_minimum_size=Vector2(170,38);provisions.autowrap_mode=TextServer.AUTOWRAP_OFF;provisions.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;provisions.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;header_row.add_child(provisions)
	var scroll:=ScrollContainer.new();scroll.name="TavernKitchenScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll);var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",9);scroll.add_child(content)
	_populate_tavern_management_kitchen_legacy(content)
	var cooking_orders:Array=state.profession_orders.filter(func(order):return str(order.get("profession",""))=="cooking" and str(order.get("status","")) not in ["complete","cancelled"])
	content.add_child(label("CURRENT COOKING",15,C_GOLD))
	if cooking_orders.is_empty():content.add_child(label("No meal is currently being prepared.",14,C_MUTED))
	for order in cooking_orders:
		var order_row:=HBoxContainer.new();content.add_child(order_row);var recipe:Dictionary=ProfessionData.recipe(str(order.recipe_id));var order_text:=label("%s  •  %s  •  %.1fs"%[ProfessionSystem.hero_name(state,str(order.assigned_member_id)),str(recipe.display_name),float(order.remaining_time)],14,C_TEXT);order_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;order_row.add_child(order_text);order_row.add_child(compact_button("Resume" if bool(order.paused) else "Pause",func(id=str(order.order_id),paused=bool(order.paused)):tavern_cooking_order_action(id,"resume" if paused else "pause"),90));order_row.add_child(compact_button("Cancel",func(id=str(order.order_id)):tavern_cooking_order_action(id,"cancel"),85))
	content.add_child(rule());content.add_child(label("MEAL PREPARATION",15,C_GOLD));var cooks:Array=state.heroes.filter(func(hero):return str(hero.get("profession_progress",{}).get("profession_id",""))=="cooking")
	if cooks.is_empty():
		var empty:=HBoxContainer.new();empty.add_theme_constant_override("separation",12);content.add_child(empty);var empty_text:=label("No guild member knows Cooking yet. Train Cooking from that Hero's Professions tab.",14,C_MUTED);empty_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;empty.add_child(empty_text);var roster_link:=compact_button("Open Hero Roster",open_cooking_training_roster,160);roster_link.name="OpenCookingTrainingRoster";empty.add_child(roster_link);return
	if not cooks.any(func(hero):return str(hero.hero_id)==selected_tavern_cook_id):selected_tavern_cook_id=str(cooks[0].hero_id)
	var cook_row:=HBoxContainer.new();cook_row.add_theme_constant_override("separation",10);content.add_child(cook_row);var cook_label:=label("Cook",14,C_MUTED);cook_label.custom_minimum_size.x=45;cook_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;cook_row.add_child(cook_label);var cook_select:=OptionButton.new();cook_select.name="TavernCookSelector";cook_select.custom_minimum_size=Vector2(260,38)
	for cook in cooks:
		cook_select.add_item("%s  •  Rank %d"%[str(cook.display_name),int(cook.profession_progress.profession_rank)]);cook_select.set_item_metadata(cook_select.item_count-1,str(cook.hero_id));if str(cook.hero_id)==selected_tavern_cook_id:cook_select.select(cook_select.item_count-1)
	cook_select.item_selected.connect(func(index):select_tavern_cook(str(cook_select.get_item_metadata(index))));cook_row.add_child(cook_select);var selected_index:=ProfessionSystem.hero_index(state,selected_tavern_cook_id);var selected_cook:Dictionary=state.heroes[selected_index];var lean:=label(ProfessionSystem.specialization_lean(selected_cook.profession_progress),14,C_GOLD);lean.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;cook_row.add_child(lean)
	for recipe_id in ProfessionData.RECIPES:
		var recipe:Dictionary=ProfessionData.RECIPES[recipe_id];if str(recipe.profession)!="cooking":continue
		var recipe_row:=HBoxContainer.new();recipe_row.custom_minimum_size.y=44;content.add_child(recipe_row);var recipe_text:=label("%s  •  1 Provision  •  %.0fs"%[str(recipe.display_name),float(recipe.duration)],14,C_TEXT);recipe_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;recipe_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;recipe_row.add_child(recipe_text);var check:=ProfessionSystem.can_start_order(state,selected_tavern_cook_id,recipe_id);var start:=compact_button("Prepare",func(member=selected_tavern_cook_id,id=recipe_id):start_tavern_cooking_order(member,id),100);start.disabled=not bool(check.success);start.tooltip_text=str(check.reason);recipe_row.add_child(start)

	content.add_child(rule());content.add_child(label("PREPARED MEALS & SERVICES",15,C_GOLD));var commitment_id:=CookingSystem.commitment(state,selected_tavern_cook_id);content.add_child(label("Commitment: %s"%str(CookingData.COMMITMENTS.get(commitment_id,{}).get("display_name","Not yet committed")),14,C_TEXT))
	var stocks:Array=[]
	for meal_id in CookingData.MEALS:
		var count:=TavernFacilitySystem.meal_count(state,str(meal_id))
		if count>0:stocks.append("%s ×%d"%[str(CookingData.MEALS[meal_id].display_name),count])
	content.add_child(label(", ".join(stocks) if not stocks.is_empty() else "No prepared meals.",13,C_MUTED))
	var candidate:=CookingSystem.current_candidate(state)
	if not candidate.is_empty():
		var patron_row:=HBoxContainer.new();patron_row.add_theme_constant_override("separation",7);content.add_child(patron_row);var patron_copy:=label("Serve %s"%str(candidate.hero_record.display_name),14,C_TEXT);patron_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;patron_row.add_child(patron_copy)
		for meal_id in ["adventurers_supper","hearthside_gathering","craftsfolks_table","travellers_welcome"]:
			var serve:=compact_button(str(CookingData.MEALS[meal_id].display_name),func(id=meal_id):serve_tavern_patron_meal(id),155);serve.disabled=TavernFacilitySystem.meal_count(state,meal_id)<=0;patron_row.add_child(serve)
	var hook_note:=label("Campaign Menus and House Banquets expose service hooks but cannot start recruitment campaigns until the separate campaign scheduler exists. Guild Feasts remain local meal services and do not create events.",13,C_MUTED);hook_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(hook_note)
	if is_testing_save():
		content.add_child(rule());var debug_row:=HBoxContainer.new();debug_row.alignment=BoxContainer.ALIGNMENT_CENTER;debug_row.add_theme_constant_override("separation",8);content.add_child(debug_row);debug_row.add_child(label("COOKING TEST",11,Color("c6a8ff")));debug_row.add_child(compact_button("Add Meal Set",debug_add_prepared_cooking_meals,130));debug_row.add_child(compact_button("Patron Refresh",debug_cooking_patron_refresh,140))

func _populate_tavern_recruitment_legacy(root:VBoxContainer) -> void:
	var page_scroll:=ScrollContainer.new();page_scroll.name="TavernRecruitmentPageScroll";page_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(page_scroll);var page:=VBoxContainer.new();page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;page.add_theme_constant_override("separation",10);page_scroll.add_child(page);var production:=VBoxContainer.new();production.name="TavernRecruitmentProduction";production.custom_minimum_size.y=500;production.size_flags_horizontal=Control.SIZE_EXPAND_FILL;production.add_theme_constant_override("separation",10);page.add_child(production)
	var campaign_panel:=PanelContainer.new();campaign_panel.add_theme_stylebox_override("panel",ui_box(Color("172234"),6,Color("35445a"),1));production.add_child(campaign_panel);var campaign_content:=VBoxContainer.new();campaign_content.add_theme_constant_override("separation",7);campaign_panel.add_child(campaign_content);campaign_content.add_child(label("RECRUITMENT CAMPAIGN",15,C_GOLD));var campaign:Dictionary=state.tavern_management.campaign
	if bool(campaign.get("active",false)):
		var definition:Dictionary=TavernManagementData.CAMPAIGNS.get(str(campaign.campaign_id),{});var campaign_row:=HBoxContainer.new();campaign_content.add_child(campaign_row);var campaign_copy:=label("%s  •  %s remaining  •  Gross %d Gold  •  Sales +%d  •  Stay +%d"%[str(definition.get("display_name","Campaign")),tavern_time_text(float(campaign.remaining_minutes)),int(campaign.gross_cost),int(floor(float(campaign.food_sales))),int(floor(float(campaign.staying_fees)))],14,C_TEXT);campaign_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;campaign_row.add_child(campaign_copy);campaign_row.add_child(compact_button("End & Report",end_tavern_campaign,135))
	else:
		var campaign_row:=HBoxContainer.new();campaign_row.add_theme_constant_override("separation",8);campaign_content.add_child(campaign_row)
		for campaign_id in TavernManagementData.CAMPAIGNS:
			var definition:Dictionary=TavernManagementData.CAMPAIGNS[campaign_id];var launch:=compact_button("%s  •  %d Gold"%[str(definition.display_name),int(definition.gross_cost)],func(id=campaign_id):start_tavern_campaign(id),220);launch.disabled=int(state.gold)<int(definition.gross_cost);campaign_row.add_child(launch)
	var report:Dictionary=state.tavern_management.last_campaign_report
	if not report.is_empty():campaign_content.add_child(label("Last report — Cost %d  •  Food +%d  •  Staying +%d  •  Final %d Gold"%[int(report.gross_cost),int(report.food_sales),int(report.staying_fees),int(report.final_cost)],13,C_GREEN))
	if int(state.tavern_management.tavern_level)<2:campaign_content.add_child(label("Food sales and locked-candidate staying fees unlock at Tavern Level 2.",12,C_MUTED))
	if is_testing_save():campaign_content.add_child(compact_button("Add Locked Candidate",debug_add_locked_tavern_candidate,180))
	var status:=HBoxContainer.new();status.add_theme_constant_override("separation",10);production.add_child(status)
	var budget_card:=PanelContainer.new();budget_card.custom_minimum_size=Vector2(340,72);budget_card.add_theme_stylebox_override("panel",ui_box(Color("182334"),6,C_GOLD,1));status.add_child(budget_card);var budget_row:=HBoxContainer.new();budget_card.add_child(budget_row);var budget_copy:=VBoxContainer.new();budget_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;budget_row.add_child(budget_copy);budget_copy.add_child(label("TAVERN BUDGET",12,C_MUTED));budget_copy.add_child(label("0–5 Gold per patron search",14,C_GOLD));var budget:=SpinBox.new();budget.name="TavernHourlyBudget";budget.min_value=0;budget.max_value=int(RecruitmentData.CONFIG.max_hourly_budget);budget.step=1;budget.value=int(state.recruitment.hourly_budget);budget.custom_minimum_size=Vector2(80,40);budget.value_changed.connect(set_recruitment_budget);budget_row.add_child(budget)
	var expected_text:="Paused  •  %s remaining"%tavern_time_text(float(state.recruitment.minutes_until_next_check)) if not state.recruitment.candidates.is_empty() else tavern_time_text(float(state.recruitment.minutes_until_next_check))
	status.add_child(make_tavern_status_card("NEXT EXPECTED PATRON",expected_text,C_GOLD))
	var status_note:=label("The search pauses while a patron is waiting.\nLocked patrons keep their place without advancing departure time.",13,C_MUTED);status_note.size_flags_horizontal=Control.SIZE_EXPAND_FILL;status_note.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;status.add_child(status_note)
	var body:=HBoxContainer.new();body.add_theme_constant_override("separation",12);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;production.add_child(body)
	var candidate_panel:=PanelContainer.new();candidate_panel.name="TavernCandidatePanel";candidate_panel.custom_minimum_size=Vector2(810,0);candidate_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL;candidate_panel.add_theme_stylebox_override("panel",ui_box(Color("172234"),8,Color("35445a"),2));body.add_child(candidate_panel);var candidate_content:=VBoxContainer.new();candidate_content.add_theme_constant_override("separation",8);candidate_panel.add_child(candidate_content)
	var candidate:=RecruitmentSystem.current_candidate(state)
	if candidate.is_empty():candidate_content.alignment=BoxContainer.ALIGNMENT_CENTER;var empty:=label("No patron is currently waiting.\nSet a Tavern Budget and the next expected patron will arrive when the timer completes.",19,C_MUTED);empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;candidate_content.add_child(empty)
	else:populate_tavern_candidate(candidate_content,candidate)
	var log_panel:=PanelContainer.new();log_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;log_panel.add_theme_stylebox_override("panel",ui_box(Color("151f30"),8,Color("35445a"),1));body.add_child(log_panel);var log_content:=VBoxContainer.new();log_content.add_theme_constant_override("separation",6);log_panel.add_child(log_content);log_content.add_child(label("TAVERN ACTIVITY",15,C_GOLD));log_content.add_child(rule());var log_scroll:=ScrollContainer.new();log_scroll.name="TavernActivityScroll";log_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;log_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;log_content.add_child(log_scroll);var log_entries:=VBoxContainer.new();log_entries.add_theme_constant_override("separation",5);log_entries.size_flags_horizontal=Control.SIZE_EXPAND_FILL;log_scroll.add_child(log_entries)
	var entries:Array=state.recruitment.activity_log
	if entries.is_empty():log_entries.add_child(label("No activity yet.",14,C_MUTED))
	else:
		for index in range(entries.size()-1,-1,-1):log_entries.add_child(label("• "+str(entries[index]),13,C_TEXT))
	if is_testing_save():page.add_child(rule());populate_recruitment_debug(page)

func make_tavern_overview_service(title:String,value:String,accent:Color) -> PanelContainer:
	var card:=PanelContainer.new();card.custom_minimum_size=Vector2(0,72);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",ui_box(Color("172234"),6,Color("35445a"),1))
	var copy:=VBoxContainer.new();copy.alignment=BoxContainer.ALIGNMENT_CENTER;card.add_child(copy);var heading:=label(title,11,C_MUTED);heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;copy.add_child(heading);var result:=label(value,16,accent);result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;copy.add_child(result);return card


func populate_tavern_compact_assignment(container:VBoxContainer,role:String,caption:String) -> void:
	var key:="%s_id"%role;var assigned_id:=str(state.tavern_management.assignments.get(key,""));var card:=PanelContainer.new();card.custom_minimum_size.y=58;card.add_theme_stylebox_override("panel",ui_box(Color("172234"),6,Color("35445a"),1));container.add_child(card)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);card.add_child(row);var name:=label(caption,15,C_TEXT);name.custom_minimum_size.x=120;name.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(name);var current:=label(TavernManagementSystem.hero_name(state,assigned_id) if assigned_id!="" else "Unassigned",13,C_MUTED);current.size_flags_horizontal=Control.SIZE_EXPAND_FILL;current.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(current)
	var selector:=OptionButton.new();selector.name="Tavern%sAssignment"%role.capitalize();selector.custom_minimum_size=Vector2(220,38);selector.add_item("Unassigned");selector.set_item_metadata(0,"")
	for hero in state.heroes:
		var hero_id:=str(hero.hero_id);var check:=TavernManagementSystem.assignment_eligibility(state,hero_id,role)
		if bool(check.eligible) or hero_id==assigned_id:selector.add_item(str(hero.display_name));selector.set_item_metadata(selector.item_count-1,hero_id);if hero_id==assigned_id:selector.select(selector.item_count-1)
	selector.item_selected.connect(func(index):set_tavern_assignment(role,str(selector.get_item_metadata(index))));row.add_child(selector)


func populate_tavern_overview(root:VBoxContainer) -> void:
	var scroll:=ScrollContainer.new();scroll.name="TavernOverviewScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll)
	var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",12);scroll.add_child(content)
	var intro:=PanelContainer.new();intro.add_theme_stylebox_override("panel",ui_box(Color("1c2a3d"),6,Color("35445a"),1));content.add_child(intro);var intro_copy:=VBoxContainer.new();intro_copy.add_theme_constant_override("separation",3);intro.add_child(intro_copy);intro_copy.add_child(label("TAVERN OVERVIEW",18,C_GOLD));intro_copy.add_child(label("Manage the people and everyday services available in the Tavern.",13,C_MUTED))
	var services:=HBoxContainer.new();services.add_theme_constant_override("separation",10);content.add_child(services);services.add_child(make_tavern_overview_service("RECRUITMENT","Open",C_GREEN));services.add_child(make_tavern_overview_service("KITCHEN","Manual cooking",C_TEXT));services.add_child(make_tavern_overview_service("REST AREA","%d spaces"%state.tavern_management.rest_slots.size(),C_GOLD))
	content.add_child(label("STAFF",14,C_GOLD));populate_tavern_compact_assignment(content,"host","Host");populate_tavern_compact_assignment(content,"chef","Chef")
	var future:=label("Additional staff positions unlock with later Tavern progression.",12,C_MUTED);future.name="TavernFutureStaffNote";future.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(future)
	if is_testing_save():
		content.add_child(rule());var debug:=HBoxContainer.new();debug.alignment=BoxContainer.ALIGNMENT_CENTER;debug.add_theme_constant_override("separation",8);content.add_child(debug);debug.add_child(label("TAVERN TEST",11,Color("c6a8ff")));debug.add_child(compact_button("Level 1",func():set_tavern_level_debug(1),90));debug.add_child(compact_button("Level 2",func():set_tavern_level_debug(2),90))


func select_tavern_automation_recipe(recipe_id:String) -> void:
	var target:=int(state.tavern_management.automation.stock_target)
	set_tavern_stock_target(recipe_id,0 if recipe_id=="" else maxi(1,target if target>0 else 5))


func populate_tavern_kitchen(root:VBoxContainer) -> void:
	var chef_id:=str(state.tavern_management.assignments.chef_id)
	var header:=PanelContainer.new()
	header.name="TavernKitchenHeader"
	header.custom_minimum_size.y=64
	header.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	header.add_theme_stylebox_override("panel",ui_box(Color("241f18"),6,Color("705f35"),1))
	root.add_child(header)
	var header_row:=HBoxContainer.new()
	header_row.add_theme_constant_override("separation",12)
	header.add_child(header_row)
	var heading:=label("KITCHEN",19,C_GOLD)
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(heading)
	var chef:=label("Chef: %s"%TavernManagementSystem.hero_name(state,chef_id),13,C_MUTED)
	chef.name="TavernKitchenChef"
	chef.custom_minimum_size=Vector2(190,36)
	chef.autowrap_mode=TextServer.AUTOWRAP_OFF
	chef.clip_text=true
	chef.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	chef.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	chef.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header_row.add_child(chef)
	var provisions:=label("Provisions  %d"%TavernManagementSystem._material_quantity(state,"provisions"),15,C_TEXT)
	provisions.name="TavernProvisionsReadout"
	provisions.custom_minimum_size=Vector2(170,36)
	provisions.autowrap_mode=TextServer.AUTOWRAP_OFF
	provisions.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	provisions.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	provisions.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header_row.add_child(provisions)
	var roster_link:=compact_button("Train Cooking",open_cooking_training_roster,130)
	roster_link.name="OpenCookingTrainingRoster"
	roster_link.custom_minimum_size.y=38
	roster_link.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header_row.add_child(roster_link)
	var scroll:=ScrollContainer.new();scroll.name="TavernKitchenScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll);var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",10);scroll.add_child(content)
	var attempt:Dictionary=state.tavern_management.manual_cooking
	if bool(attempt.get("active",false)):
		var game:=PanelContainer.new();game.add_theme_stylebox_override("panel",ui_box(Color("241f18"),6,C_GOLD,2));content.add_child(game);var game_row:=HBoxContainer.new();game_row.add_theme_constant_override("separation",12);game.add_child(game_row);var game_copy:=VBoxContainer.new();game_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;game_row.add_child(game_copy);game_copy.add_child(label(str(ProfessionData.recipe(str(attempt.recipe_id)).display_name),17,C_GOLD));var marker:=ProgressBar.new();marker.name="TavernCookingMarker";marker.min_value=0;marker.max_value=100;marker.value=float(attempt.marker)*100.0;marker.show_percentage=false;marker.custom_minimum_size=Vector2(650,34);game_copy.add_child(marker);game_copy.add_child(label("Stop near the center for the best result.",12,C_MUTED));var stop:=compact_button("STOP",stop_tavern_manual_cooking,150);stop.custom_minimum_size.y=66;game_row.add_child(stop)
	else:
		content.add_child(label("RECIPES",14,C_GOLD));var recipes:=GridContainer.new();recipes.columns=2;recipes.add_theme_constant_override("h_separation",10);recipes.add_theme_constant_override("v_separation",10);content.add_child(recipes)
		for recipe_id in TavernManagementData.PROTOTYPE_RECIPES:
			var recipe:Dictionary=ProfessionData.recipe(recipe_id);var record:Dictionary=state.guild_recipes.get(recipe_id,{});var successes:=int(record.get("success_count",0));var requirement:=int(recipe.get("mastery_required",3));var meal_id:=str(recipe.get("meal_id",""));var card:=PanelContainer.new();card.custom_minimum_size=Vector2(0,86);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",ui_box(Color("172234"),6,Color("35445a"),1));recipes.add_child(card);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);card.add_child(row);var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(copy);copy.add_child(label(str(recipe.display_name),15,C_TEXT));copy.add_child(label("%d provision%s  •  Stock %d  •  Mastery %d/%d"%[int(recipe.materials[0].quantity),"s" if int(recipe.materials[0].quantity)!=1 else "",TavernFacilitySystem.meal_count(state,meal_id),mini(successes,requirement),requirement],12,C_MUTED));var cook:=compact_button("Cook",func(id=recipe_id):start_tavern_manual_cooking(id),90);cook.disabled=chef_id=="" or not bool(TavernManagementSystem.ingredient_status(state,recipe_id).available);cook.tooltip_text="Assign a Chef and provide the required provisions.";row.add_child(cook)
	if int(state.tavern_management.tavern_level)>=2:
		content.add_child(rule());content.add_child(label("KITCHEN AUTOMATION",14,C_GOLD));var auto_row:=HBoxContainer.new();auto_row.add_theme_constant_override("separation",10);content.add_child(auto_row);var auto_select:=OptionButton.new();auto_select.custom_minimum_size=Vector2(250,38);auto_select.add_item("Off");auto_select.set_item_metadata(0,"");var active_recipe:=str(state.tavern_management.automation.recipe_id)
		for recipe_id in TavernManagementData.PROTOTYPE_RECIPES:
			if ProfessionSystem.is_pattern_mastered(state,recipe_id):auto_select.add_item(str(ProfessionData.recipe(recipe_id).display_name));auto_select.set_item_metadata(auto_select.item_count-1,recipe_id);if recipe_id==active_recipe:auto_select.select(auto_select.item_count-1)
		auto_select.item_selected.connect(func(index):select_tavern_automation_recipe(str(auto_select.get_item_metadata(index))));auto_row.add_child(auto_select);var target:=SpinBox.new();target.min_value=1;target.max_value=TavernManagementData.MAX_STOCK_TARGET;target.value=maxi(1,int(state.tavern_management.automation.stock_target));target.custom_minimum_size=Vector2(85,38);target.disabled=active_recipe=="";target.value_changed.connect(func(value):if active_recipe!="":set_tavern_stock_target(active_recipe,value));auto_row.add_child(target);var auto_status:=label(str(state.tavern_management.automation.status),13,C_MUTED);auto_status.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;auto_row.add_child(auto_status)
	if is_testing_save():
		content.add_child(rule());var debug:=HFlowContainer.new();debug.alignment=FlowContainer.ALIGNMENT_CENTER;debug.add_theme_constant_override("h_separation",6);debug.add_theme_constant_override("v_separation",6);content.add_child(debug);debug.add_child(label("KITCHEN TEST",11,Color("c6a8ff")));debug.add_child(compact_button("+50 Provisions",add_tavern_ingredients_debug,130));debug.add_child(compact_button("Master All",func():debug_tavern_recipe_mastery(true),100));debug.add_child(compact_button("Reset Mastery",func():debug_tavern_recipe_mastery(false),120));debug.add_child(compact_button("Perfect Current",debug_complete_manual_cooking,125));debug.add_child(compact_button("Finish Auto",debug_complete_tavern_automation,100));debug.add_child(compact_button("Clear Meals",debug_clear_tavern_meals,105))


func populate_tavern_recruitment(root:VBoxContainer) -> void:
	var page_scroll:=ScrollContainer.new();page_scroll.name="TavernRecruitmentPageScroll";page_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(page_scroll);var page:=VBoxContainer.new();page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;page.add_theme_constant_override("separation",10);page_scroll.add_child(page);var production:=VBoxContainer.new();production.name="TavernRecruitmentProduction";production.custom_minimum_size.y=500;production.size_flags_horizontal=Control.SIZE_EXPAND_FILL;production.add_theme_constant_override("separation",10);page.add_child(production)
	var status:=HBoxContainer.new();status.add_theme_constant_override("separation",10);production.add_child(status);var budget_card:=PanelContainer.new();budget_card.custom_minimum_size=Vector2(340,72);budget_card.add_theme_stylebox_override("panel",ui_box(Color("182334"),6,C_GOLD,1));status.add_child(budget_card);var budget_row:=HBoxContainer.new();budget_card.add_child(budget_row);var budget_copy:=VBoxContainer.new();budget_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;budget_row.add_child(budget_copy);budget_copy.add_child(label("TAVERN BUDGET",12,C_MUTED));budget_copy.add_child(label("0–5 Gold per patron search",14,C_GOLD));var budget:=SpinBox.new();budget.name="TavernHourlyBudget";budget.min_value=0;budget.max_value=int(RecruitmentData.CONFIG.max_hourly_budget);budget.step=1;budget.value=int(state.recruitment.hourly_budget);budget.custom_minimum_size=Vector2(80,40);budget.value_changed.connect(set_recruitment_budget);budget_row.add_child(budget)
	var expected_text:="Paused  •  %s remaining"%tavern_time_text(float(state.recruitment.minutes_until_next_check)) if not state.recruitment.candidates.is_empty() else tavern_time_text(float(state.recruitment.minutes_until_next_check));status.add_child(make_tavern_status_card("NEXT EXPECTED PATRON",expected_text,C_GOLD));var status_note:=label("Search pauses while a patron is waiting.",13,C_MUTED);status_note.size_flags_horizontal=Control.SIZE_EXPAND_FILL;status_note.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;status.add_child(status_note)
	var body:=HBoxContainer.new();body.add_theme_constant_override("separation",12);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;production.add_child(body);var candidate_panel:=PanelContainer.new();candidate_panel.name="TavernCandidatePanel";candidate_panel.custom_minimum_size=Vector2(810,0);candidate_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL;candidate_panel.add_theme_stylebox_override("panel",ui_box(Color("172234"),8,Color("35445a"),2));body.add_child(candidate_panel);var candidate_content:=VBoxContainer.new();candidate_content.add_theme_constant_override("separation",8);candidate_panel.add_child(candidate_content);var candidate:=RecruitmentSystem.current_candidate(state)
	if candidate.is_empty():candidate_content.alignment=BoxContainer.ALIGNMENT_CENTER;var empty:=label("No patron is currently waiting.\nSet a Tavern Budget to begin the next search.",19,C_MUTED);empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;candidate_content.add_child(empty)
	else:populate_tavern_candidate(candidate_content,candidate)
	var log_panel:=PanelContainer.new();log_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;log_panel.add_theme_stylebox_override("panel",ui_box(Color("151f30"),8,Color("35445a"),1));body.add_child(log_panel);var log_content:=VBoxContainer.new();log_content.add_theme_constant_override("separation",6);log_panel.add_child(log_content);log_content.add_child(label("TAVERN ACTIVITY",15,C_GOLD));log_content.add_child(rule());var log_scroll:=ScrollContainer.new();log_scroll.name="TavernActivityScroll";log_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;log_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;log_content.add_child(log_scroll);var log_entries:=VBoxContainer.new();log_entries.add_theme_constant_override("separation",5);log_entries.size_flags_horizontal=Control.SIZE_EXPAND_FILL;log_scroll.add_child(log_entries);var entries:Array=state.recruitment.activity_log
	if entries.is_empty():log_entries.add_child(label("No activity yet.",14,C_MUTED))
	else:for index in range(entries.size()-1,-1,-1):log_entries.add_child(label("• "+str(entries[index]),13,C_TEXT))
	if is_testing_save():page.add_child(rule());populate_recruitment_debug(page)


func show_tavern() -> void:
	remember_tavern_scroll_positions();RecruitmentSystem.ensure_state(state);GameClockSystem.ensure_state(state);TavernFacilitySystem.ensure_state(state);ProfessionSystem.ensure_state(state);CookingSystem.ensure_state(state);TavernManagementSystem.ensure_state(state);screen="tavern";var root:=base_screen(str(state.recruitment.tavern_name));add_tavern_title_controls(root);add_tavern_sections(root)
	if tavern_section=="Overview":populate_tavern_overview(root)
	elif tavern_section=="Rest Area":populate_tavern_rest_area(root)
	elif tavern_section=="Recovery & Rest":populate_tavern_recovery(root) # Legacy testing route; no longer shown as a Tavern tab.
	elif tavern_section=="Kitchen":populate_tavern_kitchen(root)
	else:populate_tavern_recruitment(root)
	call_deferred("restore_tavern_scroll_positions")
