extends "res://scripts/runtime/ability_runtime.gd"

func player_controlled_hero_indices() -> Array:
	var result:=[]
	for hero_index in heroes.size():
		if not bool(heroes[hero_index].get("independent",false)):result.append(hero_index)
	return result

func cycle_selected_hero(direction:int)->void:
	if heroes.is_empty():return
	for offset in heroes.size():
		var candidate=posmod(selected+direction*(offset+1),heroes.size())
		if heroes[candidate].hp>0 and not bool(heroes[candidate].get("independent",false)):
			selected=candidate
			queue_redraw()
			return

func cycle_selected_enemy()->void:
	if heroes.is_empty():return
	var living_targets:=[]
	for i in enemies.size():
		if enemies[i].hp>0:living_targets.append(i)
	if living_targets.is_empty():
		focused_enemy_index=-1
		queue_redraw()
		return
	var current_position=living_targets.find(focused_enemy_index)
	var next_position=0 if current_position<0 else (current_position+1)%living_targets.size()
	focused_enemy_index=living_targets[next_position]
	queue_redraw()

func cancel_ability_aim()->void:
	ability_aiming=false;aimed_ability_slot=-1;aimed_ability_category="";aimed_cast_mode="";ability_button_held=false;queue_redraw()

func clear_selected_combat_target()->void:
	if selected<0 or selected>=heroes.size():return
	clear_hero_command(heroes[selected],"player cancelled")
	focused_enemy_index=-1
	queue_redraw()

func begin_ability(slot:int,device:String="pc")->void:
	if selected>=heroes.size() or bool(heroes[selected].get("independent",false)) or slot<0 or slot>=4:return
	if tutorial_active and (tutorial_step<7 or slot!=0):return
	if tutorial_active and tutorial_step==7 and heroes[selected]["class"]!="Cleric":return
	if tutorial_active and tutorial_step==7:use_ability(0,heroes[selected].pos);return
	var hero_level:=int(state.heroes[battle_hero_indices[selected]].level)
	if not TalentSystem.ability_is_unlocked(hero_level,slot):flash("This ability unlocks at Level %d."%int(TalentSystem.ABILITY_UNLOCK_LEVELS[slot]));return
	var category=ABILITY_TARGETING[heroes[selected]["class"]][slot]
	if heroes[selected]["class"]=="Guardian" and slot==3 and guardian_heroic_id(heroes[selected])=="guardian_l15_r2":category="enemy"
	var mode="instant" if category=="self" else str(state.casting_settings[device].get(category,"cursor"))
	if mode=="instant" or mode=="cursor" or mode=="facing" or mode=="target":
		if (category=="enemy" and combat_enemy_target()<0) or (category=="ally" and (heroes[selected].heal_target<0 or heroes[selected].heal_target>=heroes.size())):
			flash("Choose a valid %s target first."%category);return
		var cast_point=get_global_mouse_position()
		if mode=="facing":cast_point=heroes[selected].pos+heroes[selected].facing_direction*ABILITY_RANGES[heroes[selected]["class"]][slot]
		use_ability(slot,cast_point);return
	ability_aiming=true;aimed_ability_slot=slot;aimed_ability_category=category;aimed_cast_mode=mode;aimed_from_touch=device=="mobile";ability_button_held=mode=="release";ability_aim_point=get_global_mouse_position();queue_redraw()

func begin_trait()->void:
	if selected<0 or selected>=heroes.size() or bool(heroes[selected].get("independent",false)):return
	var hero:Dictionary=heroes[selected]
	if str(hero.get("class",""))=="Guardian" and GuardianSystem.has_talent(hero,"guardian_l24_2"):
		if not use_guardian_trait(hero):flash("Stoneform is not ready.")
		queue_redraw()
	elif str(hero.get("class",""))=="Cleric":
		if not use_cleric_trait(hero):flash("Fast Feet talent action is unavailable or not ready.")
		queue_redraw()

func confirm_aim_at(point:Vector2)->bool:
	if not ability_aiming:return false
	if aimed_ability_category=="enemy":
		for i in enemies.size():
			if enemies[i].hp>0 and enemies[i].pos.distance_to(point)<58:focused_enemy_index=i;var slot=aimed_ability_slot;cancel_ability_aim();use_ability(slot,point);return true
		return false
	if aimed_ability_category=="ally":
		for i in heroes.size():
			if heroes[i].hp>0 and heroes[i].pos.distance_to(point)<58:assign_hero_ally(selected,i);var slot=aimed_ability_slot;cancel_ability_aim();use_ability(slot,point);return true
		return false
	var slot=aimed_ability_slot;cancel_ability_aim();use_ability(slot,point);return true

func tutorial_allows_hero(hero_index:int)->bool:

	match tutorial_step:
		0,1:return hero_index>=0 and hero_index<heroes.size()
		2,3:return hero_index==0
		6:return hero_index==0 or hero_index==1
		4,7:return hero_index==1
	return false

func tutorial_pointer_press(point:Vector2,device:String="pc")->void:
	tutorial_input_device=device
	if tutorial_step==7:
		if point.y>575 and point.y<635 and point.x>420 and point.x<875:
			var portrait_index=clampi(int((point.x-424)/54),0,heroes.size()-1)
			if portrait_index==1:selected=1;tutorial_record_valid_action();queue_redraw()
			else:reject_tutorial_action("Only Sera can be selected for this step.")
			return
		if point.y>635 and point.x>445 and point.x<523:
			if selected==1:tutorial_record_valid_action();begin_ability(0,device)
			else:reject_tutorial_action("Select Sera before using Healing Brew.")
			return
	for hero_index in heroes.size():
		if heroes[hero_index].pos.distance_to(point)<58 and tutorial_allows_hero(hero_index):
			selected=hero_index;tutorial_record_valid_action()
			if tutorial_step==3:
				tutorial_hero_clicked=true
				dragging_hero=false
				queue_redraw()
				return
			if tutorial_step==7:
				queue_redraw()
				return
			dragging_hero=true;drag_cursor=point;drag_start=point;drag_has_moved=false;drag_target_type="ground";drag_target_index=-1;queue_redraw();return
	reject_tutorial_action()

func update_hero_drag(point:Vector2)->void:
	drag_cursor=point
	if drag_cursor.distance_to(drag_start)>12:drag_has_moved=true
	drag_target_type="ground";drag_target_index=-1
	if heroes[selected]["class"]=="Cleric":
		for hero_index in heroes.size():
			if heroes[hero_index].hp>0 and heroes[hero_index].pos.distance_to(drag_cursor)<42:drag_target_type="ally";drag_target_index=hero_index;break
	if drag_target_type=="ground":
		for enemy_index in enemies.size():
			if enemies[enemy_index].hp>0 and enemies[enemy_index].pos.distance_to(drag_cursor)<45:drag_target_type="enemy";drag_target_index=enemy_index;break
	queue_redraw()

func tutorial_drag_release_is_valid()->bool:
	match tutorial_step:
		0:
			return drag_target_type=="ground"
		1:
			return drag_target_type=="ground"
		2:
			return drag_target_type=="enemy" and drag_target_index>=0 and enemies[drag_target_index].type=="Dummy"
		4:
			return drag_target_type=="ally" and drag_target_index==0
		6:
			if selected==1:return drag_target_type=="ground"
			return drag_target_type=="enemy" and drag_target_index>=0 and enemies[drag_target_index].type=="Raider"
	return false

func finish_hero_drag()->void:
	dragging_hero=false
	if not drag_has_moved:return
	if tutorial_active and not tutorial_drag_release_is_valid():reject_tutorial_action();queue_redraw();return
	if tutorial_active:tutorial_record_valid_action()
	if drag_target_type=="enemy":assign_hero_enemy(selected,drag_target_index);heroes[selected].suppress_auto_target=false
	elif drag_target_type=="ally" and heroes[selected]["class"]=="Cleric":assign_hero_ally(selected,drag_target_index)
	else:issue_hero_move(heroes[selected],Vector2(clamp(drag_cursor.x,55.0,1225.0),clamp(drag_cursor.y,70.0,570.0)));heroes[selected].suppress_auto_target=true;focused_enemy_index=-1
	queue_redraw()

func _unhandled_input(event:InputEvent) -> void:
	if screen!="combat":return
	if victory_talent_overlay!=null and is_instance_valid(victory_talent_overlay):return
	if tutorial_active:
		if event is InputEventScreenTouch or event is InputEventScreenDrag:tutorial_input_device="mobile"
		elif not OS.has_feature("mobile") and (event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventKey):tutorial_input_device="pc"
	if tutorial_active and tutorial_step==8 and ((event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.pressed):
		tutorial_active=false;show_hall();return
	if victory_sequence:
		if victory_phase>=5 and ((event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.pressed):
			attempt_victory_continue()
		return
	if battle_over:
		if event is InputEventKey and event.pressed:
			if event.keycode==KEY_ESCAPE or event.keycode==KEY_ENTER: show_hall()
			elif event.keycode==KEY_R: start_battle(dungeon_id,encounter_id)
		return
	if tutorial_active and event is InputEventKey:
		var accepted=false
		if event.pressed and tutorial_step==7:
			if event.keycode==KEY_2:selected=1;tutorial_record_valid_action();queue_redraw();accepted=true
			elif not event.echo and event.keycode==KEY_Q and selected==1:tutorial_record_valid_action();begin_ability(0);accepted=true
		if event.pressed and not accepted:reject_tutorial_action()
		get_viewport().set_input_as_handled()
		return
	if tutorial_active and event is InputEventMouseButton and event.pressed and event.button_index!=MOUSE_BUTTON_LEFT:
		reject_tutorial_action()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE and ability_aiming:cancel_ability_aim();get_viewport().set_input_as_handled();return
		if event.keycode==KEY_F3 and testing_zone_active:debug_combat_overlay=not debug_combat_overlay;queue_redraw();return
		if event.keycode==KEY_F4 and testing_zone_active:
			for hero in heroes:
				if str(hero.get("class",""))=="Guardian":GuardianSystem.add_quest(hero,45,"testing_control",battle_time);flash("Guardian quest +45")
			return
		if event.keycode==KEY_F5 and testing_zone_active:
			for hero in heroes:
				if str(hero.get("class",""))=="Guardian":hero.selected_heroic_id="guardian_l15_r2" if guardian_heroic_id(hero)=="guardian_l15_r1" else "guardian_l15_r1";hero.selected_talents["tier_3"]=hero.selected_heroic_id;flash("Heroic: %s"%GuardianData.WORKING_NAMES[hero.selected_heroic_id])
			return
		if event.keycode==KEY_F6 and testing_zone_active:
			for hero in heroes:
				if str(hero.get("class",""))=="Guardian":hero.selected_talents={"tier_1":"guardian_l9_1","tier_2":"guardian_l12_2","tier_3":guardian_heroic_id(hero),"tier_4":"guardian_l18_2","tier_5":"guardian_l21_2","tier_6":"guardian_l24_1","tier_7":"guardian_l27_r1" if guardian_heroic_id(hero)=="guardian_l15_r1" else "guardian_l27_r2","tier_8":"guardian_l30_1"};hero.guardian_runtime.ability_charges=GuardianSystem.default_charges(hero);flash("Guardian test talents loaded")
			return
		if event.keycode==KEY_F7 and testing_zone_active:
			for hero in heroes:
				if str(hero.get("class",""))=="Cleric":hero.selected_heroic_id="cleric_l15_r1";hero.selected_talents={"tier_1":"cleric_l9_1","tier_2":"cleric_l12_2","tier_3":"cleric_l15_r1","tier_4":"cleric_l18_1","tier_5":"cleric_l21_2","tier_6":"cleric_l24_1","tier_7":"cleric_l27_r1","tier_8":"cleric_l30_1"};ClericSystem.initialize_runtime(hero,true);flash("Cleric Jug test build loaded")
			return
		if event.keycode==KEY_F8 and testing_zone_active:
			for hero in heroes:
				if str(hero.get("class",""))=="Cleric":hero.selected_heroic_id="cleric_l15_r2";hero.selected_talents={"tier_1":"cleric_l9_2","tier_2":"cleric_l12_3","tier_3":"cleric_l15_r2","tier_4":"cleric_l18_2","tier_5":"cleric_l21_1","tier_6":"cleric_l24_3","tier_7":"cleric_l27_r2","tier_8":"cleric_l30_2"};ClericSystem.initialize_runtime(hero,true);flash("Cleric Dragon test build loaded")
			return
		if event.keycode==KEY_SPACE:paused=!paused;queue_redraw()
		if event.keycode==KEY_TAB and not event.echo:
			cycle_selected_enemy()
			get_viewport().set_input_as_handled()
		if event.keycode>=KEY_1 and event.keycode<=KEY_4:
			var selectable_heroes:Array=player_controlled_hero_indices()
			var requested_slot:int=event.keycode-KEY_1
			if requested_slot<selectable_heroes.size():selected=selectable_heroes[requested_slot];queue_redraw()
		if not event.echo and event.keycode==KEY_Q:begin_ability(0)
		if not event.echo and event.keycode==KEY_W:begin_ability(1)
		if not event.echo and event.keycode==KEY_E:begin_ability(2)
		if not event.echo and event.keycode==KEY_R:begin_ability(3)
		if not event.echo and event.keycode==KEY_D:begin_trait()
	if event is InputEventKey and not event.pressed and ability_aiming and aimed_cast_mode=="release":
		var released_slot={KEY_Q:0,KEY_W:1,KEY_E:2,KEY_R:3}.get(event.keycode,-1)
		if released_slot==aimed_ability_slot:confirm_aim_at(get_global_mouse_position());return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			if ability_aiming:cancel_ability_aim()
			elif not paused:clear_selected_combat_target()
			get_viewport().set_input_as_handled();return
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:
			cycle_selected_hero(-1)
			get_viewport().set_input_as_handled()
			return
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			cycle_selected_hero(1)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var p=event.position
		if tutorial_active:
			tutorial_pointer_press(p,"pc")
			get_viewport().set_input_as_handled()
			return
		if ability_aiming and aimed_cast_mode=="confirm":
			if confirm_aim_at(p):get_viewport().set_input_as_handled()
			return
		if p.x>1190 and p.y<70: paused=true; queue_redraw(); return
		if paused:
			if Rect2(490,285,300,58).has_point(p):paused=false;queue_redraw()
			elif testing_zone_active and Rect2(490,360,300,58).has_point(p):toggle_testing_dummy_attacks()
			elif Rect2(490,435 if testing_zone_active else 360,300,58).has_point(p):paused=false;show_dungeons() if testing_zone_active else show_zone_map(dungeon_id)
			return
		if p.y>575 and p.y<635 and p.x>420 and p.x<875:
			var selectable_heroes:Array=player_controlled_hero_indices()
			var requested_slot:int=clampi(int((p.x-424)/54),0,7)
			if requested_slot<selectable_heroes.size():selected=selectable_heroes[requested_slot];queue_redraw()
			return
		if p.y>635 and p.x>445 and p.x<835:
			var action_slot:=clampi(int((p.x-445)/78),0,4)
			if action_slot==4:begin_trait()
			else:begin_ability(action_slot)
			return
		for i in heroes.size():
			if not bool(heroes[i].get("independent",false)) and heroes[i].pos.distance_to(p)<58:
				selected=i;if tutorial_active and tutorial_step==3:tutorial_hero_clicked=true
				dragging_hero=true;drag_cursor=p;drag_start=p;drag_has_moved=false;drag_target_type="ground";drag_target_index=-1;queue_redraw();return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and ability_aiming and aimed_cast_mode=="release":
		confirm_aim_at(event.position);return
	if event is InputEventMouseMotion and ability_aiming:ability_aim_point=event.position;queue_redraw()
	if event is InputEventScreenDrag and ability_aiming:ability_aim_point=event.position;queue_redraw();return

	if event is InputEventScreenTouch:
		if tutorial_active:
			if event.pressed:tutorial_pointer_press(event.position,"mobile")
			elif dragging_hero:update_hero_drag(event.position);finish_hero_drag()
			get_viewport().set_input_as_handled()
			return
		if event.pressed and ability_aiming and aimed_cast_mode=="confirm":confirm_aim_at(event.position);return
		if event.pressed and event.position.y>635 and event.position.x>445 and event.position.x<835:
			var action_slot:=clampi(int((event.position.x-445)/78),0,4)
			if action_slot==4:begin_trait()
			else:begin_ability(action_slot,"mobile")
			return
		if not event.pressed and ability_aiming and aimed_cast_mode=="release":confirm_aim_at(event.position);return
		if event.pressed and not paused and event.position.y<635:clear_selected_combat_target()
	if event is InputEventScreenDrag and tutorial_active and dragging_hero:update_hero_drag(event.position);return
	if event is InputEventMouseMotion and dragging_hero:update_hero_drag(event.position)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and dragging_hero:
		finish_hero_drag()
