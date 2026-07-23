extends "res://scripts/ui/team_builder_screen.gd"

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
	world_map_content=Control.new(); world_map_content.size=GameData.WORLD_MAP_SIZE; world_map_content.mouse_filter=Control.MOUSE_FILTER_PASS; world_map_view.add_child(world_map_content)
	var map_image:=TextureRect.new(); map_image.texture=load("res://assets/world_map.png"); map_image.position=Vector2.ZERO; map_image.size=world_map_content.size; map_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; map_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; map_image.modulate=Color(.86,.89,.95,1); map_image.mouse_filter=Control.MOUSE_FILTER_IGNORE; world_map_content.add_child(map_image)
	var active_region=GameData.WORLD_ACTIVE_REGION
	var completed_count:=0
	for encounter_key in AshwoodData.MANDATORY_ORDER:
		if AshwoodManager.encounter_is_completed(state.zone0,encounter_key):completed_count+=1
	var ashwood:=Button.new(); ashwood.position=active_region.position; ashwood.size=active_region.size; ashwood.text="%s\n%d / 7" % [active_region.name,completed_count]; ashwood.add_theme_font_size_override("font_size",19); ashwood.add_theme_color_override("font_color",C_GOLD); ashwood.add_theme_stylebox_override("normal",ui_box(Color(0.04,.08,.10,.92),12,C_GOLD,3)); ashwood.pressed.connect(func():show_zone_map(active_region.zone)); world_map_content.add_child(ashwood)
	if is_testing_save():
		var testing_region:=Button.new();testing_region.name="TestingWorldRegion";testing_region.position=Vector2(1110,165);testing_region.size=Vector2(220,82);testing_region.text="TESTING";testing_region.tooltip_text="Open testing battles and training tools.";testing_region.add_theme_font_size_override("font_size",22);testing_region.add_theme_color_override("font_color",Color("d9c2ff"));testing_region.add_theme_stylebox_override("normal",ui_box(Color("261d3d"),12,Color("b381ff"),3));testing_region.pressed.connect(show_testing_zone_menu);world_map_content.add_child(testing_region)
	for region in GameData.LOCKED_WORLD_REGIONS:
		var marker:=Button.new(); marker.position=region[1]; marker.size=Vector2(210,72); marker.text="🔒  %s" % region[0]; marker.disabled=true; marker.mouse_filter=Control.MOUSE_FILTER_IGNORE; marker.tooltip_text="Locked region"; marker.add_theme_font_size_override("font_size",15); marker.add_theme_stylebox_override("disabled",ui_box(Color(0.05,.07,.11,.88),10,Color("68778e"),2)); world_map_content.add_child(marker)
	var return_button:=button("Return",show_hall,130); return_button.position=Vector2(1116,22); world_map_view.add_child(return_button)
	var zoom_controls:=HBoxContainer.new(); zoom_controls.position=Vector2(995,24); zoom_controls.add_theme_constant_override("separation",6); world_map_view.add_child(zoom_controls); zoom_controls.add_child(compact_button("−",func():zoom_world_map(.85,world_map_view.size*.5),46));zoom_controls.add_child(compact_button("+",func():zoom_world_map(1.18,world_map_view.size*.5),46))

	if is_testing_save():
		var reset_story:=button("TEST: RESET ASHWOOD STORY",request_reset_testing_story,265);reset_story.name="TestingResetStoryButton";reset_story.position=Vector2(24,648);reset_story.tooltip_text="Reset Ashwood story progress while keeping testing heroes, levels, equipment, inventory, and guild resources.";reset_story.add_theme_color_override("font_color",Color("d9c2ff"));reset_story.add_theme_stylebox_override("normal",ui_box(Color("261d3d"),8,Color("b381ff"),2));world_map_view.add_child(reset_story)
	clamp_world_map_pan();call_deferred("clamp_world_map_pan")

func testing_mode_card(title:String,description:String) -> PanelContainer:
	var card:=PanelContainer.new()
	card.custom_minimum_size=Vector2(520,390)
	card.add_theme_stylebox_override("panel",ui_box(Color("182536"),12,Color("465b78"),2))
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",18);card.add_child(content)
	content.add_child(label(title,28,C_GOLD));content.add_child(label(description,17,C_TEXT))
	return card

func show_testing_zone_menu() -> void:
	if not is_testing_save():show_dungeons();return
	screen="testing_zone_menu"
	var root:=base_screen("Testing Zone")
	root.add_child(label("Choose a controlled space for combat testing.",17,C_MUTED))
	var modes:=HBoxContainer.new();modes.add_theme_constant_override("separation",22);modes.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(modes)
	var range_card:=testing_mode_card("Dummy Range","Use the existing stationary targets, defensive dummy, bosses, and combat telemetry to inspect individual abilities and interactions.")
	modes.add_child(range_card);var range_content:=range_card.get_child(0) as VBoxContainer;range_content.add_spacer(false)
	var enter_range:=button("Enter Dummy Range",start_testing_zone,240);enter_range.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;range_content.add_child(enter_range)
	var enter_warlock_range:=button("Enter Warlock Range",start_warlock_testing_zone,240);enter_warlock_range.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;range_content.add_child(enter_warlock_range)
	var enter_rogue_range:=button("Enter Rogue Range",start_rogue_testing_zone,240);enter_rogue_range.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;range_content.add_child(enter_rogue_range)
	var endless_card:=testing_mode_card("Endless Arena","Fight a continuous stream of enemies at one fixed level. Defeated enemies are replaced, and the selected level never increases automatically.")
	modes.add_child(endless_card);var endless_content:=endless_card.get_child(0) as VBoxContainer
	var level_row:=HBoxContainer.new();level_row.alignment=BoxContainer.ALIGNMENT_CENTER;level_row.add_theme_constant_override("separation",14);endless_content.add_child(level_row)
	level_row.add_child(label("Enemy Level",18,C_MUTED))
	var level_picker:=SpinBox.new();level_picker.name="TestingEndlessLevel";level_picker.min_value=1;level_picker.max_value=CombatSystem.LEVEL_CAP;level_picker.step=1;level_picker.allow_greater=false;level_picker.allow_lesser=false;level_picker.value=testing_endless_level;level_picker.custom_minimum_size=Vector2(120,46);level_picker.value_changed.connect(func(value:float):testing_endless_level=int(value));level_row.add_child(level_picker)
	endless_content.add_spacer(false)
	var enter_endless:=button("Begin Endless Arena",func():start_testing_endless(testing_endless_level),250);enter_endless.name="TestingEndlessStart";enter_endless.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;endless_content.add_child(enter_endless)

func show_zone_map(zone:int) -> void:
	if zone==0:
		show_ashwood_map()
		return
	screen="zone_map"; dungeon_id=zone; var root=base_screen(GameData.ZONE_NAMES[zone])
	var map:=Control.new(); map.custom_minimum_size=Vector2(1120,445); root.add_child(map)
	var node_names=GameData.ZONE_NODE_NAMES[zone]
	var positions=GameData.ZONE_NODE_POSITIONS
	for i in 9:
		var line:=Line2D.new(); line.width=5; line.default_color=C_GOLD if i<int(state.zone_progress[zone]) else Color("3d4a5d"); line.points=PackedVector2Array([positions[i]+Vector2(55,32),positions[i+1]+Vector2(55,32)]); map.add_child(line)
	for branch_data in GameData.ZONE_BRANCHES:
		var line:=Line2D.new(); line.width=4; line.default_color=Color("b381ff") if state.zone_branches[zone][branch_data[2]] else Color("3d4a5d"); line.points=PackedVector2Array([positions[branch_data[0]]+Vector2(55,32),positions[branch_data[1]]+Vector2(55,32)]); map.add_child(line)
	for node in 12:
		var is_branch=node>=10; var branch_index=node-10; var unlocked=node<=int(state.zone_progress[zone]) if not is_branch else int(state.zone_progress[zone])>=(3 if branch_index==0 else 6); var completed=node<int(state.zone_progress[zone]) if not is_branch else state.zone_branches[zone][branch_index]
		var encounter:=Button.new(); encounter.position=positions[node]; encounter.size=Vector2(110,64); encounter.text=("✓\n" if completed else "")+(node_names[node] if unlocked else "?"); encounter.disabled=not unlocked; encounter.add_theme_font_size_override("font_size",12); encounter.add_theme_color_override("font_color",Color("b381ff") if is_branch else C_GOLD if node==9 else C_TEXT); encounter.pressed.connect(func(i=node,z=zone):start_battle(z,i)); map.add_child(encounter)

func add_dotted_map_connection(map:Control,from_pos:Vector2,to_pos:Vector2,color:Color) -> Node2D:
	var trail:=Node2D.new();trail.name="OptionalPathTrail";map.add_child(trail)
	var path_length:float=from_pos.distance_to(to_pos)
	if path_length<=0:return trail
	var direction:Vector2=from_pos.direction_to(to_pos)
	var distance:=0.0
	while distance<path_length:
		var segment_end:float=min(distance+13.0,path_length)
		var segment:=Line2D.new();segment.width=4;segment.default_color=color;segment.points=PackedVector2Array([from_pos+direction*distance,from_pos+direction*segment_end]);trail.add_child(segment)
		distance+=23.0
	return trail

func show_ashwood_map() -> void:
	if state.zone0.zone0_boss_defeated and str(state.zone0.special_hero_choice)=="":
		show_pending_special_choice()
		return
	screen="zone_map"
	dungeon_id=0
	var root=base_screen("THE ASHWOOD MARCHES")
	var summary:="The servant has fallen. Completed locations now offer expanded patrols." if state.zone0.zone0_boss_defeated else "Choose a revealed location. Completed battles can be replayed for XP, gold, and loot."
	root.add_child(label(summary,15,C_MUTED))
	var map:=Control.new()
	map.custom_minimum_size=Vector2(1160,470)
	root.add_child(map)
	var optional_source_revealed:bool=AshwoodManager.encounter_is_unlocked(state.zone0,"raider_cache")
	var optional_branch_hidden:bool=not bool(state.zone0.optional_branch_discovered) and not bool(state.zone0.zone0_boss_defeated)
	for connection in AshwoodData.MAP_CONNECTIONS:
		var from_id:String=connection[0]
		var to_id:String=connection[1]
		if not AshwoodManager.encounter_is_unlocked(state.zone0,from_id) or not AshwoodManager.encounter_is_unlocked(state.zone0,to_id):continue
		var from_pos:Vector2=AshwoodData.ENCOUNTERS[from_id].map_position+Vector2(65,38)
		var to_pos:Vector2=AshwoodData.ENCOUNTERS[to_id].map_position+Vector2(65,38)
		var line:=Line2D.new()
		line.width=5
		line.default_color=Color("9a6bdb") if bool(AshwoodData.ENCOUNTERS[to_id].optional) else C_GOLD
		line.points=PackedVector2Array([from_pos,to_pos])
		map.add_child(line)
	if optional_source_revealed and optional_branch_hidden:
		var optional_from:Vector2=AshwoodData.ENCOUNTERS.raider_cache.map_position+Vector2(65,38)
		var optional_to:Vector2=AshwoodData.ENCOUNTERS.ruined_chapel.map_position+Vector2(65,38)
		add_dotted_map_connection(map,optional_from,optional_to,Color("76558f"))
	for encounter_key in AshwoodData.all_encounter_ids():
		if not AshwoodManager.encounter_is_unlocked(state.zone0,encounter_key):continue
		var encounter_data:=AshwoodData.encounter(encounter_key,state.zone0)
		var completed:=AshwoodManager.encounter_is_completed(state.zone0,encounter_key)
		var encounter_button:=Button.new()
		encounter_button.position=encounter_data.map_position
		encounter_button.size=Vector2(132,76)
		encounter_button.text=("✓  " if completed else "")+str(encounter_data.display_name)
		encounter_button.add_theme_font_size_override("font_size",13)
		encounter_button.add_theme_color_override("font_color",C_GREEN if completed else Color("c692ff") if encounter_data.optional else C_GOLD)
		encounter_button.add_theme_stylebox_override("normal",ui_box(Color("182536"),10,Color("9a6bdb") if encounter_data.optional else C_GOLD,2))
		encounter_button.pressed.connect(func(id=encounter_key):open_ashwood_encounter(id))
		map.add_child(encounter_button)
		if encounter_key in pending_map_reveals:
			encounter_button.modulate=Color(1.5,1.35,.75,1)
			var tween=create_tween();tween.tween_property(encounter_button,"modulate",Color.WHITE,.8)
	if optional_source_revealed and optional_branch_hidden:
		var clue:=Button.new()
		clue.name="OptionalPathHint"

		clue.position=Vector2(585,350);clue.size=Vector2(132,76)
		clue.text=("Ruined chapel?" if state.zone0.optional_clue else "?")+"\nOPTIONAL PATH"
		clue.disabled=not state.zone0.optional_available
		clue.tooltip_text="Complete the nearby route to investigate this optional trail." if clue.disabled else "Investigate the optional trail."
		clue.add_theme_font_size_override("font_size",13);clue.add_theme_color_override("font_color",Color("c692ff"));clue.add_theme_color_override("font_disabled_color",Color("876c9e"));clue.add_theme_stylebox_override("normal",ui_box(Color("151c29"),10,Color("8b63a8"),2));clue.add_theme_stylebox_override("disabled",ui_box(Color("121824"),10,Color("5f496f"),2));clue.pressed.connect(discover_ashwood_optional_branch);map.add_child(clue)
	pending_map_reveals.clear()

func discover_ashwood_optional_branch() -> void:
	if AshwoodManager.discover_optional_branch(state.zone0):
		pending_map_reveals=["ruined_chapel"]
		save_game()
		show_ashwood_consequence("The roots give way to a ruined chapel path. Something below is still drawing power from its runes.")

func open_ashwood_encounter(encounter_key:String) -> void:
	if not AshwoodManager.encounter_is_unlocked(state.zone0,encounter_key):return
	if AshwoodManager.encounter_is_completed(state.zone0,encounter_key) and ashwood_story_is_pending(encounter_key):
		resume_pending_ashwood_story(encounter_key)
		return
	if encounter_key=="first_battle":start_ashwood_battle(encounter_key)
	else:show_encounter_intro(encounter_key)

func show_encounter_intro(encounter_key:String) -> void:
	if not AshwoodManager.encounter_is_unlocked(state.zone0,encounter_key):return
	if AshwoodManager.encounter_is_completed(state.zone0,encounter_key) and ashwood_story_is_pending(encounter_key):
		resume_pending_ashwood_story(encounter_key)
		return
	if encounter_key=="first_battle":
		start_ashwood_battle(encounter_key)
		return
	current_ashwood_encounter=encounter_key
	screen="encounter_intro"
	var encounter_data:=AshwoodData.encounter(encounter_key,state.zone0)
	var completed:=AshwoodManager.encounter_is_completed(state.zone0,encounter_key)
	var root=base_screen(str(encounter_data.display_name),"REPLAY" if completed else "SCENARIO")
	var story_panel=panel();story_panel.custom_minimum_size=Vector2(900,250);story_panel.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;root.add_child(story_panel)
	story_panel.add_child(label(str(encounter_data.get("replay_scenario","Ashwood remains dangerous in the wake of the guild's earlier victory.")) if completed else str(encounter_data.scenario),19,C_TEXT))
	if not completed:
		for moment in encounter_data.get("story_moments",[]):
			story_panel.add_child(label(str(moment),15,Color("c6b6da")))
	story_panel.add_child(rule())
	story_panel.add_child(label("OBJECTIVE",13,C_MUTED));story_panel.add_child(label(str(encounter_data.objective.label),22,C_GOLD))
	var rewards:Dictionary=encounter_data.repeat_rewards if completed else encounter_data.first_rewards
	story_panel.add_child(label("Rewards: %d gold  •  %d XP%s"%[rewards.gold,rewards.xp,"  •  loot chance" if completed or not rewards.get("loot",[]).is_empty() else ""],16,C_GREEN))
	root.add_spacer(false)
	var begin:=button("Begin Replay" if completed else "Enter Encounter",func():start_ashwood_battle(encounter_key),240);begin.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;root.add_child(begin)

func show_command_table() -> void:
	screen="command"; var root=base_screen("Command Table")
	var mission_data=GameData.MISSIONS
	var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",18); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(columns)
	var missions:=VBoxContainer.new(); missions.custom_minimum_size.x=350; missions.add_theme_constant_override("separation",10); columns.add_child(missions); missions.add_child(label("AVAILABLE MISSIONS",14,C_MUTED))
	for i in mission_data.size():
		var mission_button:=Button.new(); mission_button.text="%s\n%s"%[mission_data[i][0],mission_data[i][1]]; mission_button.custom_minimum_size=Vector2(340,78); if i==selected_mission:mission_button.add_theme_stylebox_override("normal",ui_box(Color("26384e"),9,C_GOLD,2)); mission_button.pressed.connect(func(index=i):selected_mission=index;show_command_table()); missions.add_child(mission_button)
	var chosen=mission_data[selected_mission]; var details:=VBoxContainer.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",14); columns.add_child(details); details.add_child(label(chosen[0],30,C_TEXT)); details.add_child(label(chosen[1],18,C_GOLD)); details.add_child(label("REWARDS",13,C_MUTED)); details.add_child(label(chosen[2],20,C_GREEN)); details.add_child(label("ASSIGNED HEROES",13,C_MUTED)); var slots:=HBoxContainer.new(); details.add_child(slots); for i in 4:var slot:=Button.new();slot.text="+";slot.custom_minimum_size=Vector2(110,90);slots.add_child(slot); details.add_child(button("Assign Heroes",func(): flash("Hero assignment is the next automation step."),220))

func show_market() -> void:
	screen="market"; var root=base_screen("Merchant Contacts")
	var gold_row:=HBoxContainer.new(); root.add_child(gold_row)
	var gold_label:=label("●  %d" % state.gold,20,C_GOLD); gold_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; gold_row.add_child(gold_label)
	root.add_child(label("Discover merchants while exploring the world. Once you have made contact, they can provide goods, recipes, selling services, and trade contracts.",16,C_MUTED))
	var merchant_data=GameData.MERCHANTS
	var merchant_row:=HBoxContainer.new();merchant_row.add_theme_constant_override("separation",14);merchant_row.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(merchant_row)
	for merchant in merchant_data:
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(390,300);card.add_theme_stylebox_override("panel",ui_box(Color("182536"),12,Color("35445a"),1));merchant_row.add_child(card)
		var content:=VBoxContainer.new();content.add_theme_constant_override("separation",9);card.add_child(content);content.add_child(label(merchant[0],24,C_GOLD));content.add_child(label(merchant[1],16,C_TEXT));content.add_child(label("Location  •  "+merchant[2],14,C_MUTED));content.add_child(rule());content.add_child(label("Offers",13,C_MUTED));content.add_child(label(merchant[3],16,C_TEXT));content.add_spacer(false)
		var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",6);content.add_child(actions);actions.add_child(compact_button("View Wares",func(merchant_name=merchant[0]):show_merchant_wares(str(merchant_name)),105));actions.add_child(compact_button("View Contracts",func(merchant_name=merchant[0]):flash("%s's contracts will be added later."%merchant_name),120));actions.add_child(compact_button("Sell Items",func(merchant_name=merchant[0]):flash("Selling through %s will be added later."%merchant_name),100))

func merchant_wares()->Array:
	return [{"definition_id":"pinewatch_bow","price":90},{"definition_id":"pilgrims_vestment","price":110},{"definition_id":"marchwarden_plate","price":160}]

func merchant_item_fits(definition_id:String)->bool:
	var preview:=ItemData.create_instance(definition_id,"merchant_preview_%s"%definition_id)
	return bool(InventorySystem.simulate_inventory_transaction(state,[],[{"kind":"equipment","item":preview}]).get("success",false))

func purchase_merchant_item(definition_id:String,price:int,merchant_name:String)->Dictionary:
	if state.gold<price:return {"success":false,"reason":"Not enough gold"}
	if not merchant_item_fits(definition_id):return {"success":false,"reason":"Not Enough Storage Space"}
	var instance_id:=InventorySystem.next_item_instance_id(state,definition_id);var item:=ItemData.create_instance(definition_id,instance_id);var result:=InventorySystem.add_equipment(state,item)
	if not bool(result.get("success",false)):return result
	state.gold-=price;save_game();show_merchant_wares(merchant_name);flash("Purchase sent to Item Storage.")

	return {"success":true,"instance_id":instance_id}

func purchase_merchant_material(material_id:String,quantity:int,price:int)->Dictionary:
	if state.gold<price:return {"success":false,"reason":"Not enough gold"}
	var outputs:Array=[{"kind":"material","material_id":material_id,"quantity":quantity}];var simulation:=InventorySystem.simulate_inventory_transaction(state,[],outputs)
	if not bool(simulation.get("success",false)):return {"success":false,"reason":"Not Enough Storage Space"}
	var result:=InventorySystem.apply_inventory_transaction(state,[],outputs)
	if not bool(result.get("success",false)):return result
	state.gold-=price;save_game();return {"success":true,"collected":quantity}

func open_merchant_item_card(definition_id:String,price:int,merchant_name:String)->void:
	var preview:=ItemData.create_instance(definition_id,"merchant_preview_%s"%definition_id);var data:=ItemData.item_card_data(preview,state.heroes);data.status="Price  ● %d"%price
	var fits:=merchant_item_fits(definition_id);var actions:Array=[{"id":"purchase","label":"Purchase","enabled":fits and state.gold>=price,"reason":"Not Enough Storage Space" if not fits else "Not enough gold" if state.gold<price else ""}]
	var overlay:=create_item_overlay();var card:=ItemCardView.new();card.position=Vector2((W-460.0)*.5,50);card.size=Vector2(460,620);card.configure(data,actions);card.close_requested.connect(close_item_overlay);card.action_requested.connect(func(action):if action=="purchase":close_item_overlay();var result:=purchase_merchant_item(definition_id,price,merchant_name);if not bool(result.get("success",false)):flash(str(result.get("reason","Purchase failed"))));overlay.add_child(card)

func show_merchant_wares(merchant_name:String)->void:
	screen="merchant_wares";var root=base_screen("Merchant Contacts");var heading:=HBoxContainer.new();root.add_child(heading);var merchant_label:=label(merchant_name,24,C_GOLD);merchant_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(merchant_label);heading.add_child(compact_button("All Contacts",show_market,140));root.add_child(label("●  %d"%state.gold,18,C_GOLD))
	var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",14);root.add_child(row)
	for ware in merchant_wares():
		var item:=ItemData.create_instance(str(ware.definition_id),"merchant_preview");var fits:=merchant_item_fits(str(ware.definition_id));var card:=Button.new();card.custom_minimum_size=Vector2(330,250);card.text="%s\n\n%s\nTier %s • %s\n\n● %d\n%s"%[InventorySystem.fallback_glyph(str(item.fallback_icon_type)),item.display_name,ItemData.roman_tier(int(item.tier)),item.rarity,int(ware.price),"Inspect" if fits else "VAULT FULL"];card.add_theme_color_override("font_color",Color(ItemData.RARITY_COLORS.get(str(item.rarity),"e9f1ff")));card.tooltip_text=ItemData.item_tooltip(item);card.pressed.connect(func(definition_id=str(ware.definition_id),price=int(ware.price)):open_merchant_item_card(definition_id,price,merchant_name));row.add_child(card)

func show_crafting() -> void:
	screen="crafting"; var root=base_screen("Professions")
	var profession_data=GameData.PROFESSIONS
	var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",18); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(columns)
	var profession_scroll:=ScrollContainer.new(); profession_scroll.custom_minimum_size=Vector2(360,485); columns.add_child(profession_scroll); var profession_list:=VBoxContainer.new(); profession_list.custom_minimum_size.x=340; profession_list.add_theme_constant_override("separation",8); profession_scroll.add_child(profession_list)
	for i in profession_data.size():
		var entry:=Button.new(); entry.custom_minimum_size=Vector2(330,78); entry.text=profession_data[i][0]; entry.add_theme_color_override("font_color",C_GOLD if i==selected_profession else C_TEXT); if i==selected_profession:entry.add_theme_stylebox_override("normal",ui_box(Color("26384e"),9,C_GOLD,2)); entry.pressed.connect(func(index=i):selected_profession=index;show_crafting()); profession_list.add_child(entry)
	var details:=VBoxContainer.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",14); columns.add_child(details)
	var chosen=profession_data[selected_profession]; details.add_child(label(chosen[0],30,C_GOLD)); details.add_child(label("AVAILABLE RECIPE",13,C_MUTED)); details.add_child(label(chosen[1],24,C_TEXT)); details.add_child(label("Cost  •  "+chosen[2],17,C_MUTED)); details.add_child(button("Craft",func():craft(chosen[3],chosen[4],chosen[5]),190))

func craft(resource:String,cost:int,kind:String) -> void:
	var result:Dictionary
	if kind=="tonic":result=InventorySystem.apply_inventory_transaction(state,[{"kind":"material","material_id":resource,"quantity":cost}],[{"kind":"material","material_id":"tonics","quantity":1}])
	else:result=InventorySystem.consume_material(state,resource,cost)
	if not bool(result.get("success",false)):flash(str(result.get("reason","Missing materials.")));return
	if kind=="gear":for h in state.heroes:h["gear"]+=1
	save_game(); show_crafting(); flash("Craft complete!")
