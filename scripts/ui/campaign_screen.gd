extends "res://scripts/ui/world_map_screen.gd"

const CAMPAIGN_STATUS_COLORS := {"undiscovered":Color("3d4a5d"),"discovered":Color("657b98"),"available":Color("f5c451"),"completed":Color("54d69a")}

func _campaign_scroll(root:VBoxContainer)->VBoxContainer:
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
	var content:=VBoxContainer.new();content.custom_minimum_size.x=1160;content.add_theme_constant_override("separation",12);scroll.add_child(content)
	return content

func _campaign_card(title:String,body:String,accent:Color=C_GOLD)->VBoxContainer:
	var card:=panel();card.add_theme_stylebox_override("panel",ui_box(Color("182536"),10,accent,2));card.add_child(label(title,22,accent))
	var copy:=label(body,15,C_TEXT);copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.add_child(copy)
	return card

func show_campaign_region(region_id:String)->void:
	CampaignSystem.ensure_state(state)
	if region_id not in CampaignData.REGION_ORDER or not bool(state.campaign.regions[region_id].unlocked):show_dungeons();return
	campaign_current_region=region_id;campaign_current_location="";screen="campaign_region"
	var region:=CampaignData.region(region_id);var region_state:Dictionary=state.campaign.regions[region_id]
	var root:=base_screen(str(region.name),"%s  •  LEVELS %d–%d  •  %s"%[region.act,int(CampaignData.REGION_MIN_LEVELS[region_id]),int(CampaignData.REGION_TARGET_LEVELS[region_id]),"REGION COMPLETE" if bool(region_state.completed) else "CAMPAIGN ACTIVE"])
	var lesson:=label("LESSON: %s"%str(region.lesson),16,Color("d9c2ff"));lesson.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(lesson)
	var map:=Control.new();map.name="CampaignRegionMap";map.custom_minimum_size=Vector2(1120,500);map.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(map)
	var rows:Array=region.locations
	for index in range(rows.size()-1):
		var from:Vector2=rows[index][3]+Vector2(75,32);var to:Vector2=rows[index+1][3]+Vector2(75,32);var line:=Line2D.new();line.width=4;line.default_color=Color("465b78");line.points=PackedVector2Array([from,to]);map.add_child(line)
	for row in rows:
		var location_id:=str(row[0]);var location_state:Dictionary=region_state.locations[location_id];var status:=str(location_state.status);var location_button:=Button.new()
		location_button.name="CampaignLocation_%s"%location_id;location_button.position=row[3];location_button.size=Vector2(155,66);location_button.disabled=status=="undiscovered";location_button.text="???\nUNDISCOVERED" if status=="undiscovered" else "%s\n%s"%[str(row[1]).to_upper(),status.to_upper()]
		var accent:Color=CAMPAIGN_STATUS_COLORS.get(status,C_MUTED);location_button.add_theme_font_size_override("font_size",12);location_button.add_theme_stylebox_override("normal",ui_box(Color("101827"),9,accent,2));location_button.add_theme_stylebox_override("hover",ui_box(Color("243652"),9,accent.lightened(.18),3));location_button.pressed.connect(func():show_campaign_location(region_id,location_id));map.add_child(location_button)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",10);root.add_child(footer)
	footer.add_child(button("Council Chamber",show_council_chamber,190));footer.add_child(button("Combat Hall",show_combat_hall,170))
	if is_testing_save():footer.add_child(button("Campaign Debug",show_campaign_debug,190))

func show_campaign_location(region_id:String,location_id:String)->void:
	CampaignSystem.ensure_state(state);var definition:=CampaignData.location(region_id,location_id);var location_state:=CampaignSystem.location_state(state,region_id,location_id)
	if definition.is_empty() or location_state.is_empty() or str(location_state.status)=="undiscovered":show_campaign_region(region_id);return
	campaign_current_region=region_id;campaign_current_location=location_id;screen="campaign_location"
	var root:=base_screen(str(definition.name),"%s  •  %s"%[CampaignData.region(region_id).name,str(definition.type).to_upper()]);var content:=_campaign_scroll(root)
	content.add_child(_campaign_card("LOCATION PURPOSE",str(definition.purpose),Color("75c8ff")))
	var status_text:="Campaign complete — repeatable work is now available." if bool(location_state.campaign_completed) else "Permanent location — %s."%str(location_state.status).capitalize()
	content.add_child(label(status_text,16,C_MUTED))
	if bool(location_state.returning_event_available) and not bool(state.campaign.regions[region_id].returning_event_completed):
		var callback:=_campaign_card("RETURNING CONSEQUENCE",str(CampaignData.region(region_id).callback),Color("b381ff"));callback.add_child(button("Resolve Returning Event",func():CampaignSystem.complete_callback(state,region_id);save_game();show_campaign_location(region_id,location_id),260));content.add_child(callback)
	match str(definition.type):
		"settlement":
			content.add_child(button("Enter Settlement",func():show_campaign_settlement(region_id,location_id),240))
		"main":
			if not bool(location_state.campaign_completed):
				if str(location_state.status)=="available":content.add_child(button("Begin Story Encounter",func():start_campaign_encounter(region_id,location_id,"campaign"),260))
				else:content.add_child(label("Continue the connected main path to unlock this encounter.",16,C_MUTED))
			else:_add_repeatable_actions(content,region_id,location_id)
		"faction":
			_add_faction_location(content,region_id,location_id,str(definition.faction_id))
		_:
			_add_repeatable_actions(content,region_id,location_id)

func _add_repeatable_actions(content:VBoxContainer,region_id:String,location_id:String)->void:
	var location_state:=CampaignSystem.location_state(state,region_id,location_id)
	if location_state.repeatable_pool.is_empty():location_state.repeatable_pool=CampaignSystem.repeatable_pool(region_id,location_id)
	content.add_child(label("ROTATING WORK",18,C_GOLD))
	for template in location_state.repeatable_pool:
		content.add_child(button(str(template),func():start_campaign_encounter(region_id,location_id,"repeatable"),230))

func _add_faction_location(content:VBoxContainer,region_id:String,location_id:String,faction_id:String)->void:
	var faction:=CampaignData.faction(faction_id);var access:=CampaignSystem.settlement_access(state,faction_id)
	content.add_child(_campaign_card(str(faction.name),"Reputation: %d (%s)"%[int(access.value),str(access.rank)],Color("54d69a") if bool(access.allowed) else C_RED))
	if bool(access.allowed):
		content.add_child(label("Normal access granted. Cooperative unlocks Council dialogue; Trusted grants a recruit and title.",15,C_MUTED));_add_repeatable_actions(content,region_id,location_id)
	else:
		content.add_child(label("ACCESS DENIED\nCurrent: %d (%s)\nRequired: %s"%[int(access.value),str(access.rank),str(access.required)],17,C_RED))
		var row:=HBoxContainer.new();content.add_child(row);row.add_child(button("Leave",func():show_campaign_region(region_id),150));row.add_child(button("Fight Guards",func():start_campaign_encounter(region_id,location_id,"guard",faction_id),180))

func show_campaign_settlement(region_id:String,location_id:String)->void:
	campaign_current_region=region_id;campaign_current_location=location_id;screen="campaign_settlement"
	var root:=base_screen(str(CampaignData.location(region_id,location_id).name),"PERMANENT SETTLEMENT HUB");var content:=_campaign_scroll(root)
	content.add_child(_campaign_card("SETTLEMENT SERVICES","Rest, review regional factions, sell campaign gear, and prepare support operations. Cities remain menu-based in this framework.",Color("75c8ff")))
	var services:=HBoxContainer.new();services.add_theme_constant_override("separation",10);content.add_child(services);services.add_child(button("Trading Post — Sell",func():show_campaign_trading_post(region_id,location_id),220));services.add_child(button("Guild Operations",func():show_campaign_operation(region_id),200));services.add_child(button("Council Chamber",show_council_chamber,200))
	content.add_child(label("REGIONAL FACTIONS",20,C_GOLD))
	for faction_id in CampaignData.region(region_id).factions:
		var faction:=CampaignData.faction(str(faction_id));var value:=CampaignSystem.reputation(state,str(faction_id));content.add_child(label("%s  •  %d  •  %s"%[faction.name,value,CampaignData.reputation_rank(value).name],16,C_TEXT))

func show_campaign_decision(region_id:String)->void:
	campaign_current_region=region_id;screen="campaign_decision";var decision:=CampaignData.decision(region_id);var root:=base_screen(str(decision.title),"PERMANENT REGIONAL DECISION — THIS CHOICE IS SAVED");var content:=_campaign_scroll(root)
	content.add_child(_campaign_card("CONSEQUENCE",str(CampaignData.region(region_id).lesson),Color("b381ff")))
	for option in decision.options:
		content.add_child(button(str(option[1]),func():_confirm_campaign_decision(region_id,str(option[0])),480))

func _confirm_campaign_decision(region_id:String,option_id:String)->void:
	var result:=CampaignSystem.apply_decision(state,region_id,option_id);save_game()
	if bool(result.get("success",false)):
		flash("Decision saved: %s"%str(result.outcome))
		if region_id=="grand_corruption_front":show_campaign_summary()
		else:show_campaign_region(region_id)
	else:flash(str(result.get("reason","Decision unavailable.")))

func show_campaign_summary()->void:
	CampaignSystem.ensure_state(state);screen="campaign_summary";var summary:=CampaignSystem.campaign_summary(state);state.campaign.final_summary=summary;save_game();var root:=base_screen("Campaign Summary","NAZARETH DEFEATED  •  THE TWILIGHT GATEWAY REMEMBERS EVERY CHOICE");var content:=_campaign_scroll(root)
	content.add_child(_campaign_card("THE GATEWAY",str(summary.gateway_outcome),Color("b381ff")));content.add_child(label("Regions completed: %d / 6\nReturning consequences resolved: %d\nTrusted factions: %d\nGuild roster: %d heroes\nGuild Renown: %d"%[int(summary.regions_completed),int(summary.callbacks_resolved),int(summary.trusted_factions),int(summary.roster_size),int(summary.renown)],18,C_TEXT));content.add_child(label("Titles: %s"%(", ".join(summary.faction_titles) if not summary.faction_titles.is_empty() else "None"),16,C_MUTED));content.add_child(label("PERMANENT OUTCOMES",20,C_GOLD))
	for entry in summary.decisions:content.add_child(label("%s — %s"%[str(CampaignData.region(str(entry.region_id)).name),str(entry.outcome)],16,C_TEXT))
	content.add_child(button("Return to World Map",show_dungeons,240))

func show_campaign_trading_post(region_id:String,location_id:String)->void:
	campaign_current_region=region_id;campaign_current_location=location_id;screen="campaign_settlement" if region_id!="" else "market";var root:=base_screen("Trading Post","SELL CAMPAIGN EQUIPMENT  •  GOLD %d"%int(state.gold));var content:=_campaign_scroll(root)
	var sellable:Array=state.item_instances.filter(func(item):return CampaignSystem.can_sell_item(item))
	content.add_child(label("SELLABLE EQUIPMENT (%d)"%sellable.size(),20,C_GOLD))
	if sellable.is_empty():content.add_child(label("No unequipped, unlocked campaign equipment can be sold.",16,C_MUTED))
	for item in sellable:
		var row:=HBoxContainer.new();content.add_child(row);var item_label:=label("%s  •  %s  •  iLvl %d"%[str(item.display_name),str(item.rarity),int(item.item_level)],16,C_TEXT);item_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(item_label);row.add_child(button("Sell — %d Gold"%int(item.sell_value),func():CampaignSystem.sell_item(state,str(item.instance_id));save_game();show_campaign_trading_post(region_id,location_id),170))
	var commons:Array=sellable.filter(func(item):return str(item.get("rarity",""))=="Common")
	if not commons.is_empty():content.add_child(button("Sell All Common (%d)"%commons.size(),func():_confirm_sell_all_common(region_id,location_id),240))

func _confirm_sell_all_common(region_id:String,location_id:String)->void:
	var dialog:=ConfirmationDialog.new();dialog.title="SELL ALL COMMON";dialog.dialog_text="Sell every unequipped, unlocked Common item with a sell value?";dialog.confirmed.connect(func():var result:=CampaignSystem.sell_all_common(state);save_game();flash("Sold %d items for %d Gold."%[int(result.sold),int(result.gold)]);show_campaign_trading_post(region_id,location_id));ui.add_child(dialog);dialog.popup_centered(Vector2i(520,240))

func show_council_chamber(tab:String="Factions")->void:
	CampaignSystem.ensure_state(state)
	campaign_council_tab=tab;screen="campaign_council";var root:=base_screen("Council Chamber","FACTIONS  •  REGIONAL OUTCOMES  •  RIVAL GUILDS");var tabs:=HBoxContainer.new();root.add_child(tabs)
	for tab_name in ["Factions","Regional Outcomes","Rival Guilds"]:tabs.add_child(button(tab_name,func():show_council_chamber(tab_name),210))
	var content:=_campaign_scroll(root)
	if tab=="Factions":
		for faction_id in CampaignData.FACTIONS:
			var faction:=CampaignData.faction(str(faction_id));var value:=CampaignSystem.reputation(state,str(faction_id));content.add_child(label("%s  •  %s  •  %d (%s)"%[faction.name,CampaignData.region(faction.region_id).name,value,CampaignData.reputation_rank(value).name],15,C_TEXT))
	elif tab=="Regional Outcomes":
		if state.campaign.decision_log.is_empty():content.add_child(label("No permanent regional decisions recorded.",16,C_MUTED))
		for entry in state.campaign.decision_log:content.add_child(_campaign_card(str(CampaignData.region(str(entry.region_id)).name),"%s\nOutcome: %s"%[str(entry.decision),str(entry.outcome)],Color("b381ff")))
	else:
		for rival_id in state.campaign.rivals:
			var rival:Dictionary=state.campaign.rivals[rival_id];var ratings:Array=[]
			for rating_id in rival.ratings:ratings.append("%s %d"%[str(rating_id).to_upper(),int(rival.ratings[rating_id])])
			content.add_child(_campaign_card("%s — Standing %d"%[str(rival.name),int(rival.standing)],"%s\n%s\nLatest: %s"%[str(rival.identity),"  •  ".join(ratings),str(rival.activity_log[0])],Color("ef6571")))

func show_campaign_operation(region_id:String)->void:
	campaign_current_region=region_id;screen="campaign_operation";var region_state:Dictionary=state.campaign.regions[region_id];campaign_support_draft={"support_team_a":region_state.support_team_a.duplicate(),"support_team_b":region_state.support_team_b.duplicate()}
	var root:=base_screen("Guild Operation","%s  •  SUPPORT TEAMS DO NOT SIMULATE OFF-SCREEN COMBAT"%CampaignData.region(region_id).name);var content:=_campaign_scroll(root)
	content.add_child(label("Assign up to four heroes to each team. A hero cannot appear twice. The result modifies the main-party operation.",15,C_MUTED))
	for team_key in ["support_team_a","support_team_b"]:
		content.add_child(label(str(team_key).replace("_"," ").to_upper(),19,C_GOLD))
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);content.add_child(row)
		for hero_index in state.heroes.size():
			var hero:Dictionary=state.heroes[hero_index];var selected_here:bool=hero_index in campaign_support_draft[team_key];var hero_button:=button(("✓ " if selected_here else "")+str(hero.display_name),func():_toggle_support_member(region_id,team_key,hero_index),145);hero_button.disabled=hero_index in campaign_support_draft["support_team_b" if team_key=="support_team_a" else "support_team_a"];row.add_child(hero_button)
	content.add_child(button("Resolve Support Operation",func():var result:=CampaignSystem.resolve_operation(state,region_id);save_game();flash("Support result: %s (score %d)"%[str(result.result),int(result.support_score)]);show_campaign_operation(region_id),280))

func _toggle_support_member(region_id:String,team_key:String,hero_index:int)->void:
	var draft:Array=campaign_support_draft[team_key]
	if hero_index in draft:draft.erase(hero_index)
	elif draft.size()<4:draft.append(hero_index)
	CampaignSystem.set_support_team(state,region_id,team_key,draft);save_game();show_campaign_operation(region_id)

func show_combat_hall()->void:
	CampaignSystem.ensure_state(state)
	screen="combat_hall";var root:=base_screen("Combat Hall","PRACTICE  •  SCRIMMAGES  •  NO CAMPAIGN REWARDS");var content:=_campaign_scroll(root)
	content.add_child(_campaign_card("TRAINING RANGES","Practice against stationary targets and use focused class telemetry to inspect abilities and interactions.",Color("54d69a")))
	var range_actions:=HBoxContainer.new();range_actions.add_theme_constant_override("separation",10);content.add_child(range_actions)
	var dummy_start:=button("Enter Dummy Range",start_testing_zone,220);dummy_start.name="TestingDummyRangeStart";range_actions.add_child(dummy_start)
	var warlock_start:=button("Warlock Range",start_warlock_testing_zone,200);warlock_start.name="TestingWarlockRangeStart";range_actions.add_child(warlock_start)
	var rogue_start:=button("Rogue Range",start_rogue_testing_zone,200);rogue_start.name="TestingRogueRangeStart";range_actions.add_child(rogue_start)
	var slayer_start:=button("Slayer Range",start_slayer_testing_zone,200);slayer_start.name="TestingSlayerRangeStart";range_actions.add_child(slayer_start)
	var priest_start:=button("Priest Range",start_priest_testing_zone,200);priest_start.name="TestingPriestRangeStart";range_actions.add_child(priest_start)
	var shaman_start:=button("Shaman Range",start_shaman_testing_zone,200);shaman_start.name="TestingShamanRangeStart";range_actions.add_child(shaman_start)
	var templar_start:=button("Templar Range",start_templar_testing_zone,200);templar_start.name="TestingTemplarRangeStart";range_actions.add_child(templar_start)
	content.add_child(_campaign_card("ENDLESS ARENA","Fight a continuous stream of enemies at one fixed level. Defeated enemies are replaced until the party retreats.",Color("f5c451")))
	var endless_row:=HBoxContainer.new();endless_row.name="TestingEndlessLevelRow";endless_row.add_theme_constant_override("separation",12);content.add_child(endless_row)
	var level_label:=label("Enemy Level",18,C_MUTED);level_label.name="TestingEndlessLevelLabel";level_label.custom_minimum_size=Vector2(125,46);level_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;endless_row.add_child(level_label)
	var level_picker:=SpinBox.new();level_picker.name="TestingEndlessLevel";level_picker.min_value=1;level_picker.max_value=CombatSystem.LEVEL_CAP;level_picker.step=1;level_picker.allow_greater=false;level_picker.allow_lesser=false;level_picker.value=testing_endless_level;level_picker.custom_minimum_size=Vector2(140,46);level_picker.value_changed.connect(func(value:float):testing_endless_level=int(value));endless_row.add_child(level_picker)
	var endless_start:=button("Begin Endless Arena",func():start_testing_endless(testing_endless_level),250);endless_start.name="TestingEndlessStart";endless_row.add_child(endless_start)
	content.add_child(_campaign_card("4v4 GUILDMATE SCRIMMAGE","Four controlled heroes practice against four members of your own guild. Results do not affect campaign or rival standing.",Color("ef6571")))
	var four_start:=button("Begin 4v4 Scrimmage",func():start_campaign_encounter("grand_corruption_front","gateway_site","scrimmage_4_test"),280);four_start.name="CombatHall4v4Start";content.add_child(four_start)
	content.add_child(_campaign_card("8v8 GUILDMATE SCRIMMAGE","Eight controlled heroes practice against eight members of your own guild. Guildmates fill both sides without using random outside rivals.",Color("ef6571")))
	var eight_start:=button("Begin 8v8 Scrimmage",func():start_campaign_encounter("grand_corruption_front","gateway_site","scrimmage_test"),280);eight_start.name="CombatHall8v8Start";content.add_child(eight_start)
	content.add_child(_campaign_card("8-HERO RAID TEST","Control eight guild heroes through multiple waves and a boss. Number keys 1–8 select heroes; click, touch, drag, and Q/W/E/R remain active.",Color("b381ff")))
	var raid_start:=button("Begin 8-Hero Raid Test",func():start_campaign_encounter("grand_corruption_front","gateway_site","raid_test"),280);raid_start.name="CombatHallRaidStart";content.add_child(raid_start)
	for placeholder in ["Reformation Grounds","Arena Ladder","Battleground Drills"]:content.add_child(label("🔒 %s — Placeholder"%placeholder,17,C_MUTED))

func show_campaign_debug()->void:
	if not is_testing_save():show_dungeons();return
	screen="campaign_debug";var root:=base_screen("Campaign Debug","TESTING SAVE ONLY");var content:=_campaign_scroll(root)
	content.add_child(button("Unlock All Regions",func():CampaignSystem.unlock_all_regions(state);save_game();show_campaign_debug(),220))
	content.add_child(button("Grant 100 Renown",func():state.guild_renown+=100;save_game();show_campaign_debug(),220))
	content.add_child(button("Grant Campaign Item",func():CampaignSystem.grant_campaign_item(state,"greyhaven_reach",5);save_game();show_campaign_debug(),220))
	for region_id in CampaignData.REGION_ORDER:
		var row:=HBoxContainer.new();content.add_child(row);row.add_child(label(str(CampaignData.region(region_id).name),16,C_TEXT));row.add_child(button("Open",func():show_campaign_region(region_id),110));row.add_child(button("Finish Region",func():CampaignSystem.complete_region(state,region_id);save_game();show_campaign_debug(),150))
