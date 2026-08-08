extends "res://scripts/runtime/combat_runtime.gd"

func add_ashwood_recruit(choice_key:String) -> void:
	if not AshwoodData.RECRUITS.has(choice_key):return
	var recruit:Dictionary=AshwoodData.RECRUITS[choice_key]
	for existing in state.heroes:
		if existing.name==recruit.name:return
	var hero:=SaveManager.hero_state(str(recruit.name),str(recruit["class"]),1,10,"guild_recruit",false,0,{"signature_ability":recruit.signature})
	state.heroes.append(hero)
	var hero_index=state.heroes.size()-1
	if TeamManager.can_add_member(state.selected_team,hero_index,state.heroes):state.selected_team=TeamManager.add_member(state.selected_team,hero_index,state.heroes)
	if TeamManager.can_add_member(state.active_team,hero_index,state.heroes):state.active_team=TeamManager.add_member(state.active_team,hero_index,state.heroes)

func add_recruit_to_battle(choice_key:String,expected_encounter:String) -> void:
	if current_ashwood_encounter!=expected_encounter:return
	if not AshwoodData.RECRUITS.has(choice_key):return
	var recruit:Dictionary=AshwoodData.RECRUITS[choice_key]
	var recruit_existed:bool=state.heroes.any(func(hero):return hero.name==recruit.name)
	add_ashwood_recruit(choice_key)
	var hero_index:=-1
	for candidate_index in state.heroes.size():
		if state.heroes[candidate_index].name==recruit.name:
			hero_index=candidate_index
			break
	if hero_index<0 or hero_index in battle_hero_indices:return
	if not recruit_existed:ashwood_midfight_recruit_index=hero_index
	var data:Dictionary=state.heroes[hero_index]
	var runtime_stats:=hero_final_stats(data);var equipped:=hero_equipped_items(data)
	battle_hero_indices.append(hero_index)
	heroes.append({"name":data.name,"class":data["class"],"combat_affiliation":"allied_npc","independent":true,"pos":objective_actor_pos,"dest":objective_actor_pos-Vector2(85,0),"facing_direction":Vector2.LEFT,"stats":runtime_stats,"equipped_items":equipped,"active_effects":[],"passive_cooldowns":{},"hp":runtime_stats.health,"max_hp":runtime_stats.health,"power":runtime_stats.power,"armor":runtime_stats.armor,"damage":runtime_stats.basic_attack_damage,"basic_heal_amount":runtime_stats.basic_heal_amount,"range":runtime_stats.attack_range,"movement_speed":runtime_stats.movement_speed,"basic_attack_interval":runtime_stats.basic_attack_interval,"basic_heal_interval":runtime_stats.basic_heal_interval,"critical_chance":runtime_stats.critical_chance,"critical_damage":runtime_stats.critical_damage,"basic_attack_damage_type":runtime_stats.basic_attack_damage_type,"target":nearest_living_enemy(objective_actor_pos),"heal_target":-1,"cooldown":0.0,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"shield":0.0,"last_hit":0.0})
	add_effect("heroic",objective_actor_pos,objective_actor_pos,str(recruit.name).to_upper()+" JOINS",CLASSES[recruit["class"]].color)
	queue_redraw()

func add_first_recruit_to_battle() -> void:
	add_recruit_to_battle(str(state.zone0.first_recruit_choice),"first_recruit")

func add_second_recruit_to_battle() -> void:
	add_recruit_to_battle(str(state.zone0.second_recruit_choice),"second_recruit")

func complete_ashwood_ritual() -> void:
	var remaining_ratio:=clampf(float(battle_objective.get("enemy_health_remaining",.12)),.01,1.0)
	for enemy in enemies:
		if enemy.hp<=0:continue
		var health_before:float=enemy.hp
		enemy.hp=max(1.0,min(enemy.hp,enemy.max_hp*remaining_ratio))
		var ritual_damage:float=max(0.0,health_before-enemy.hp)
		if ritual_damage>0:add_effect("cast",objective_actor_pos,enemy.pos,"RITUAL -%d"%int(ritual_damage),Color("b381ff"))
	add_effect("heroic",objective_actor_pos,objective_actor_pos,"RITUAL ERUPTS",Color("b381ff"))
	add_second_recruit_to_battle()
	var recruit_key:=str(state.zone0.second_recruit_choice)
	var recruit_name:=str(AshwoodData.RECRUITS.get(recruit_key,{}).get("name","The caster"))
	set_objective_notice("The ritual devastates the attackers — %s joins the fight!"%recruit_name,4.0)

func rollback_midfight_recruit() -> void:
	if ashwood_midfight_recruit_index<0 or ashwood_midfight_recruit_index>=state.heroes.size():return
	var recruit_index:=ashwood_midfight_recruit_index
	state.heroes.remove_at(recruit_index)
	state.selected_team=state.selected_team.filter(func(member):return int(member)!=recruit_index)
	state.active_team=state.active_team.filter(func(member):return int(member)!=recruit_index)
	ashwood_midfight_recruit_index=-1

func add_special_hero(choice_key:String) -> void:
	if not AshwoodData.SPECIAL_HEROES.has(choice_key):return
	var candidate:Dictionary=AshwoodData.SPECIAL_HEROES[choice_key]
	for existing in state.heroes:
		if existing.get("special_identifier","")==candidate.identifier:return
	state.heroes.append(SaveManager.hero_state(str(candidate.name),str(candidate["class"]),3,14,"special_hero",true,1,{"named_hero_definition_id":str(candidate.identifier),"signature_ability":candidate.signature,"story_lead":candidate.lead,"special_identifier":candidate.identifier}))


func ashwood_item_from_spec(spec:Dictionary) -> Dictionary:
	var hero_class:="Guardian"
	if str(spec.get("family",""))=="guardian_cleric":
		hero_class=["Guardian","Cleric"].pick_random()
	else:
		var available_classes:=[]
		for hero_index in state.selected_team:
			var candidate_class=str(state.heroes[hero_index]["class"])
			if AshwoodData.LOOT_NAMES.has(candidate_class):available_classes.append(candidate_class)
		if not available_classes.is_empty():hero_class=available_classes.pick_random()
	var rarity:=str(spec.get("rarity","Common"))
	var item_id="ashwood_item_%d"%int(state.zone0.next_item_id)
	state.zone0.next_item_id=int(state.zone0.next_item_id)+1
	var legacy_shape:={"id":item_id,"name":AshwoodData.LOOT_NAMES[hero_class].pick_random(),"class":hero_class,"slot":"Weapon" if int(state.zone0.next_item_id)%2==0 else "Armor","rarity":rarity,"equipped_by":-1,"source":current_ashwood_encounter}
	var item:=ItemData.legacy_ashwood_instance(legacy_shape);item["source"]=current_ashwood_encounter
	return item

func unlocked_ashwood_encounters() -> Array:
	var result:=[]
	for encounter_key in AshwoodData.all_encounter_ids():
		if AshwoodManager.encounter_is_unlocked(state.zone0,encounter_key):result.append(encounter_key)
	return result

func grant_ashwood_rewards(encounter_data:Dictionary,first_clear:bool) -> Dictionary:
	var reward:Dictionary=(encounter_data.first_rewards if first_clear else encounter_data.repeat_rewards).duplicate(true)
	var previous_progress:={}
	for hero_index in battle_hero_indices:previous_progress[hero_index]={"level":int(state.heroes[hero_index].level),"xp":int(state.heroes[hero_index].xp)}
	state.gold+=int(reward.gold)
	for hero_index in battle_hero_indices:
		var hero=state.heroes[hero_index]
		hero.xp+=int(reward.xp)
		while hero.level<CombatSystem.LEVEL_CAP and hero.xp>=hero.level*100:
			hero.xp-=hero.level*100
			hero.level+=1
		if hero.level>=CombatSystem.LEVEL_CAP:hero.xp=mini(int(hero.xp),CombatSystem.LEVEL_CAP*100-1)
		hero.experience=int(hero.xp)
		state.class_talent_discovery=TalentSystem.record_class_discovery(state.class_talent_discovery,str(hero.class_id),int(hero.level))
	var item_specs:Array=reward.get("loot",[]).duplicate(true)
	if first_clear and current_ashwood_encounter=="raider_cache" and state.zone0.raiders_chased:item_specs.append({"rarity":"Common","family":"ashwood_arms"})
	if not first_clear and randf()<.38:
		var replay_rarity="Uncommon" if state.zone0.zone0_boss_defeated and randf()<.18 else "Common"
		item_specs.append({"rarity":replay_rarity,"family":"ashwood_arms"})
	var drops:=[]
	for spec in item_specs:
		var item=ashwood_item_from_spec(spec);var storage_result:=InventorySystem.add_equipment(state,item);var drop:=item.duplicate(true);drop["collected"]=bool(storage_result.get("success",false));drop["not_collected_reason"]=str(storage_result.get("reason",""));drop["name"]=str(drop.get("display_name","Item"))+("  —  NOT COLLECTED: VAULT FULL" if not drop.collected else "");drop["class"]=str(item.get("allowed_classes",["Equipment"])[0]) if not item.get("allowed_classes",[]).is_empty() else "Equipment";drops.append(drop)
	var profession_rewards:Array=[]
	if first_clear and current_ashwood_encounter=="raider_cache":ProfessionSystem.discover_recipe(state,"forge_ashwood_bulwark",true);profession_rewards.append("Ashwood Bulwark recipe")
	if first_clear and current_ashwood_encounter=="ruined_chapel":ProfessionSystem.discover_rune_pattern(state,"pattern_frostfall");profession_rewards.append("Frostfall Rune pattern")
	if first_clear and current_ashwood_encounter=="rune_servant":ProfessionSystem.discover_rune_pattern(state,"pattern_runic_bolt");profession_rewards.append("Runic Bolt Rune pattern")
	if first_clear and current_ashwood_encounter=="finale":ProfessionSystem.discover_recipe(state,"forge_marchwarden_evolution",true);profession_rewards.append("Marchwarden Evolution recipe")
	if bool(state.get("profession_debug",{}).get("guaranteed_world_recipe_drop",false)):
		ProfessionSystem.discover_recipe(state,"forge_marchwarden_evolution",true);profession_rewards.append("DEBUG guaranteed evolution recipe")
	if current_ashwood_encounter in ["caravan","raider_cache","crossing","finale"]:
		var profession_material:="ashwood_influence" if current_ashwood_encounter=="crossing" else "arcane_essence" if current_ashwood_encounter=="finale" else "ore";var profession_amount:=2 if first_clear else 1;var profession_result:=InventorySystem.add_material(state,profession_material,profession_amount);if bool(profession_result.success):profession_rewards.append("%d %s"%[profession_amount,profession_material.replace("_"," ").capitalize()])
	var level_ups:=[]
	var xp_progress:=[]
	for hero_index in previous_progress:
		var previous:Dictionary=previous_progress[hero_index]
		var current:Dictionary=state.heroes[hero_index]
		xp_progress.append({"hero_index":hero_index,"hero":current.name,"before_level":int(previous.level),"before_xp":int(previous.xp),"after_level":int(current.level),"after_xp":int(current.xp)})
		if current.level>previous.level:level_ups.append({"hero":current.name,"level":current.level,"hero_index":hero_index,"talent_tiers":TalentSystem.newly_unlocked_tiers(int(previous.level),int(current.level))})
	return {"gold":int(reward.gold),"xp":int(reward.xp),"drops":drops,"profession_rewards":profession_rewards,"level_ups":level_ups,"xp_progress":xp_progress}

func ashwood_story_is_pending(encounter_key:String) -> bool:
	var encounter_data:=AshwoodData.encounter(encounter_key,state.zone0)
	if not encounter_data.get("decisions",[]).is_empty():
		return str(state.zone0.encounters[encounter_key].decision)==""
	if bool(encounter_data.get("special_choice",false)):
		return str(state.zone0.special_hero_choice)==""
	return false

func resume_pending_ashwood_story(encounter_key:String) -> void:
	var encounter_data:=AshwoodData.encounter(encounter_key,state.zone0)
	pending_victory={"encounter":encounter_key,"first_clear":false,"story_pending":true,"rewards":{"gold":0,"xp":0,"drops":[],"level_ups":[]},"story":str(encounter_data.story),"recruit":""}
	screen="ashwood_victory"
	show_ashwood_decision_stage()

func centered_victory_position(hero_index:int,hero_count:int,spacing:float,y_position:float) -> Vector2:
	var lineup_width:float=max(0,hero_count-1)*spacing
	var first_x:float=W*.5-lineup_width*.5
	return Vector2(first_x+hero_index*spacing,y_position)

func start_ashwood_victory_sequence() -> void:
	screen="combat"
	ui.visible=false
	victory_talent_prompt_handled=false;victory_talent_queue.clear();victory_talent_choice_index=0;close_victory_talent_overlay()
	victory_sequence=true;victory_phase=0;victory_timer=0.0
	dragging_hero=false;drag_target_type="ground";drag_target_index=-1
	rune_active=false;objective_notice="";objective_notice_time=0;objective_banner_time=0
	for hero_index in heroes.size():heroes[hero_index].dest=centered_victory_position(hero_index,heroes.size(),125.0,445.0)
	queue_redraw()


func finish_ashwood_battle(win:bool) -> void:
	if not win:
		rollback_midfight_recruit()
		show_ashwood_defeat()
		return
	var encounter_data:=AshwoodData.encounter(current_ashwood_encounter,state.zone0)
	var first_clear:=not AshwoodManager.encounter_is_completed(state.zone0,current_ashwood_encounter)
	var before_unlocks:=unlocked_ashwood_encounters()
	var rewards:=grant_ashwood_rewards(encounter_data,first_clear)
	if first_clear and current_ashwood_encounter=="first_recruit":add_ashwood_recruit(str(state.zone0.first_recruit_choice))
	if first_clear and current_ashwood_encounter=="raider_cache":
		state.zone0.vault_unlocked=true;state.zone0.heroes_unlocked=true
	if first_clear and current_ashwood_encounter=="second_recruit":add_ashwood_recruit(str(state.zone0.second_recruit_choice))
	AshwoodManager.mark_victory(state.zone0,current_ashwood_encounter)
	for encounter_key in unlocked_ashwood_encounters():
		if encounter_key not in before_unlocks:pending_map_reveals.append(encounter_key)
	var story_pending:=first_clear or ashwood_story_is_pending(current_ashwood_encounter)
	pending_victory={"encounter":current_ashwood_encounter,"first_clear":first_clear,"story_pending":story_pending,"rewards":rewards,"story":str(encounter_data.story),"recruit":""}
	if first_clear and current_ashwood_encounter=="first_recruit":pending_victory.recruit=str(AshwoodData.RECRUITS[state.zone0.first_recruit_choice].name)+" — "+str(AshwoodData.RECRUITS[state.zone0.first_recruit_choice]["class"])
	if first_clear and current_ashwood_encounter=="second_recruit":pending_victory.recruit=str(AshwoodData.RECRUITS[state.zone0.second_recruit_choice].name)+" — "+str(AshwoodData.RECRUITS[state.zone0.second_recruit_choice]["class"])
	save_game()
	start_ashwood_victory_sequence()

func show_ashwood_defeat() -> void:
	screen="ashwood_defeat"
	combat_layer.visible=false;ui.visible=true
	var root=base_screen("DEFEAT")
	root.add_spacer(false)
	var box=panel();box.custom_minimum_size=Vector2(720,300);box.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;root.add_child(box)
	box.add_child(label("The guild withdraws from Ashwood.",30,C_RED));box.add_child(label("No XP, gold, or equipment was awarded. Completed progress remains intact.",18,C_MUTED));box.add_spacer(false)
	var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;actions.add_theme_constant_override("separation",14);box.add_child(actions)
	actions.add_child(button("Retry",func():start_ashwood_battle(current_ashwood_encounter),180));actions.add_child(button("Return to Map",func():show_zone_map(0),190))

func clear_ashwood_overlay() -> void:
	for child in ui.get_children():
		child.visible=false
		child.queue_free()
	ui.visible=true
	combat_layer.visible=true
	queue_redraw()

func ashwood_overlay(title_text:String,subtitle_text:String="",wide:bool=false) -> VBoxContainer:
	clear_ashwood_overlay()
	var veil:=ColorRect.new();veil.position=Vector2.ZERO;veil.size=Vector2(W,H);veil.color=Color(0.015,0.025,0.04,.42);veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(veil)
	var shell:=PanelContainer.new();shell.position=Vector2(80,48) if wide else Vector2(280,95);shell.size=Vector2(1120,624) if wide else Vector2(720,530);shell.add_theme_stylebox_override("panel",ui_box(Color("172131"),16,C_GOLD,3));ui.add_child(shell)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",11);shell.add_child(content)
	var title_label:=label(title_text,38,C_GOLD);title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(title_label)
	if subtitle_text!="":
		var subtitle_label:=label(subtitle_text,15,C_MUTED);subtitle_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(subtitle_label)
	content.add_child(rule())
	return content

func ashwood_recap_overlay(encounter_name:String) -> VBoxContainer:
	clear_ashwood_overlay()
	var veil:=ColorRect.new();veil.position=Vector2.ZERO;veil.size=Vector2(W,H);veil.color=Color(0.015,0.025,0.04,.28);veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(veil)
	var shell:=PanelContainer.new();shell.name="AshwoodRecap";shell.position=Vector2(360,145);shell.size=Vector2(560,430);shell.add_theme_stylebox_override("panel",ui_box(Color("172131"),14,C_GOLD,3));ui.add_child(shell)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",9);shell.add_child(content)
	var title_label:=label("VICTORY",30,C_GOLD);title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(title_label)
	var encounter_label:=label(encounter_name.to_upper(),13,C_MUTED);encounter_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(encounter_label)
	content.add_child(rule())
	return content

func complete_ashwood_reward_reveal() -> void:
	if ashwood_reward_tween and ashwood_reward_tween.is_valid():ashwood_reward_tween.kill()
	for reward_node in ashwood_reward_reveal_nodes:reward_node.modulate=Color.WHITE
	ashwood_reward_reveal_complete=true

func ashwood_primary_button(text_value:String,callback:Callable,width:float=240) -> Button:
	var result:=button(text_value,callback,width)
	result.add_theme_font_size_override("font_size",20)
	result.add_theme_color_override("font_color",Color("111827"))
	result.add_theme_color_override("font_hover_color",Color("111827"))
	result.add_theme_color_override("font_pressed_color",Color("111827"))
	result.add_theme_stylebox_override("normal",ui_box(C_GOLD,10,Color("fff0ad"),2))
	result.add_theme_stylebox_override("hover",ui_box(Color("ffe08a"),10,Color.WHITE,2))
	result.add_theme_stylebox_override("pressed",ui_box(Color("dba93b"),10,Color("fff0ad"),2))
	return result

func show_ashwood_victory() -> void:
	screen="ashwood_victory"

	ashwood_victory_stage="recap"
	ashwood_selected_decision_text=""
	var encounter_data:=AshwoodData.encounter(str(pending_victory.encounter),state.zone0)
	var content:=ashwood_recap_overlay(str(encounter_data.display_name))
	var reward:Dictionary=pending_victory.rewards
	content.add_child(label("●  %d Gold"%int(reward.gold),17,C_GOLD))
	content.add_child(label("+%d XP per deployed hero"%int(reward.xp),17,Color("6aa7ff")))
	if reward.drops.is_empty():content.add_child(label("No equipment drop",14,C_MUTED))
	else:
		for item in reward.drops.slice(0,2):content.add_child(label("%s  •  %s %s"%[item.name,item.rarity,item["class"]],15,AshwoodData.RARITY_COLORS[item.rarity]))
		if reward.drops.size()>2:content.add_child(label("+%d more item(s)"%(reward.drops.size()-2),13,C_MUTED))
	for profession_reward in reward.get("profession_rewards",[]):content.add_child(label("Profession discovery  •  %s"%str(profession_reward),14,Color("c692ff")))
	for level_up in reward.level_ups:
		var unlock_note:="  •  TALENT TIER UNLOCKED" if not level_up.get("talent_tiers",[]).is_empty() else ""
		content.add_child(label("%s reached Level %d%s"%[level_up.hero,level_up.level,unlock_note],15,C_GREEN))
	if str(pending_victory.recruit)!="":content.add_child(label("New member: "+str(pending_victory.recruit),15,C_GREEN))
	var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_child(spacer)
	var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;actions.add_theme_constant_override("separation",10);content.add_child(actions)
	if bool(pending_victory.get("story_pending",false)):
		actions.add_child(ashwood_primary_button("CONTINUE",show_ashwood_decision_stage,200))
	else:
		actions.add_child(ashwood_primary_button("AGAIN",replay_ashwood_encounter,170))
		actions.add_child(button("RETURN TO WORLD MAP",return_to_ashwood_map_after_victory,230))

func show_ashwood_decision_stage() -> void:
	if not bool(pending_victory.get("story_pending",false)):return
	complete_ashwood_reward_reveal()
	ashwood_victory_stage="decision"
	var encounter_data:=AshwoodData.encounter(str(pending_victory.encounter),state.zone0)
	var content:=ashwood_overlay("VICTORY",str(encounter_data.display_name).to_upper(),bool(encounter_data.get("special_choice",false)))
	var story_label:=label(str(pending_victory.story),20,C_TEXT);story_label.custom_minimum_size.y=90;story_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;story_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(story_label)
	if bool(encounter_data.get("special_choice",false)):
		show_special_hero_choices(content)
	elif not encounter_data.get("decisions",[]).is_empty():
		var decision_heading:=label("WHAT DOES THE GUILD DO?",15,C_GOLD);decision_heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(decision_heading)
		for decision in encounter_data.decisions:
			var choice:=Button.new();choice.text=str(decision.text);choice.custom_minimum_size=Vector2(650,76);choice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;choice.add_theme_font_size_override("font_size",16);choice.pressed.connect(func(id=decision.id):resolve_ashwood_decision(id));content.add_child(choice)
	else:
		show_ashwood_consequence_overlay(str(encounter_data.get("aftermath","The guild gathers itself and prepares to continue through Ashwood.")))

func next_ashwood_encounter_after(encounter_key:String) -> String:
	if not bool(pending_victory.get("story_pending",false)):return ""
	if encounter_key=="ruined_chapel" and AshwoodManager.encounter_is_unlocked(state.zone0,"rune_servant"):return "rune_servant"
	if encounter_key in AshwoodData.MANDATORY_ORDER:
		var position:=AshwoodData.MANDATORY_ORDER.find(encounter_key)
		if position>=0 and position+1<AshwoodData.MANDATORY_ORDER.size():
			var candidate:String=AshwoodData.MANDATORY_ORDER[position+1]
			if AshwoodManager.encounter_is_unlocked(state.zone0,candidate):return candidate
	for candidate in AshwoodData.MANDATORY_ORDER:
		if AshwoodManager.encounter_is_unlocked(state.zone0,candidate) and not AshwoodManager.encounter_is_completed(state.zone0,candidate):return candidate
	return ""

func ashwood_sentence_parts(text_value:String) -> Array[String]:
	var result:Array[String]=[]
	var raw_parts:=text_value.strip_edges().split(". ",false)
	for part_index in raw_parts.size():
		var sentence:=str(raw_parts[part_index]).strip_edges()
		if sentence=="":continue
		if not sentence.ends_with(".") and not sentence.ends_with("!") and not sentence.ends_with("?"):sentence+="."
		result.append(sentence)
	return result

func show_ashwood_consequence_overlay(text_value:String) -> void:
	ashwood_consequence_lines.clear()
	if ashwood_selected_decision_text!="":ashwood_consequence_lines.append_array(ashwood_sentence_parts(ashwood_selected_decision_text))
	ashwood_consequence_lines.append_array(ashwood_sentence_parts(text_value))
	if ashwood_consequence_lines.is_empty():ashwood_consequence_lines.append("The road through Ashwood changes.")
	ashwood_consequence_phase=1
	render_ashwood_consequence_overlay()

func advance_ashwood_consequence() -> void:
	if ashwood_consequence_phase<=0 or ashwood_consequence_phase>ashwood_consequence_lines.size():return
	ashwood_consequence_phase+=1
	render_ashwood_consequence_overlay()

func render_ashwood_consequence_overlay() -> void:
	ashwood_victory_stage="consequence"
	ashwood_next_encounter=next_ashwood_encounter_after(str(pending_victory.encounter))
	var overlay_title:="YOUR DECISION" if ashwood_selected_decision_text!="" else "AFTERMATH"
	var content:=ashwood_overlay(overlay_title,"THE ASHWOOD MARCHES")
	var revealed_text:=""
	for line_index in mini(ashwood_consequence_phase,ashwood_consequence_lines.size()):
		if revealed_text!="":revealed_text+="\n\n"

		revealed_text+=ashwood_consequence_lines[line_index]
	var consequence_label:=label(revealed_text,21,C_TEXT);consequence_label.custom_minimum_size.y=190;consequence_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;consequence_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(consequence_label)
	if ashwood_consequence_phase<=ashwood_consequence_lines.size():
		var reveal_prompt:=label("Tap to continue" if OS.has_feature("mobile") else "Click, tap, or press any key to continue",15,C_GOLD);reveal_prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(reveal_prompt)
		return
	content.add_child(rule())
	if ashwood_next_encounter!="":
		var next_data:=AshwoodData.encounter(ashwood_next_encounter,state.zone0)
		var next_label:=label("NEXT  •  "+str(next_data.display_name),16,C_GOLD);next_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(next_label)
		var next_story:=label(str(next_data.scenario),16,C_MUTED);next_story.custom_minimum_size.y=90;next_story.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(next_story)
	var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;actions.add_theme_constant_override("separation",16);content.add_child(actions)
	if ashwood_next_encounter!="":actions.add_child(ashwood_primary_button("CONTINUE",continue_ashwood_adventure,250))
	actions.add_child(button("RETURN TO WORLD MAP",return_to_ashwood_map_after_victory,250))

func replay_ashwood_encounter() -> void:
	var replay_encounter:=str(pending_victory.encounter)
	pending_victory={};ashwood_victory_stage="";ashwood_next_encounter="";ashwood_selected_decision_text="";ashwood_consequence_lines.clear();ashwood_consequence_phase=0
	start_ashwood_battle(replay_encounter)

func continue_ashwood_adventure() -> void:
	var next_encounter:=ashwood_next_encounter
	pending_victory={};ashwood_victory_stage="";ashwood_next_encounter="";ashwood_selected_decision_text="";ashwood_consequence_lines.clear();ashwood_consequence_phase=0
	if next_encounter!="":start_ashwood_battle(next_encounter)
	else:show_zone_map(0)

func return_to_ashwood_map_after_victory() -> void:
	pending_victory={};ashwood_victory_stage="";ashwood_next_encounter="";ashwood_selected_decision_text="";ashwood_consequence_lines.clear();ashwood_consequence_phase=0
	show_zone_map(0)

func resolve_ashwood_decision(decision_id:String) -> void:
	var before_unlocks:=unlocked_ashwood_encounters()
	var decision:=AshwoodManager.apply_decision(state.zone0,str(pending_victory.encounter),decision_id)
	ashwood_selected_decision_text=str(decision.get("text",""))
	for encounter_key in unlocked_ashwood_encounters():
		if encounter_key not in before_unlocks:pending_map_reveals.append(encounter_key)
	save_game()
	show_ashwood_consequence_overlay(str(decision.get("consequence","The road through Ashwood changes.")))

func show_special_hero_choices(content:VBoxContainer) -> void:
	content.add_child(label("CHOOSE ONE SPECIAL HERO",18,C_GOLD))
	content.add_child(label("The other survivors will leave to pursue separate leads. This choice is permanent for this guild.",15,C_MUTED))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);content.add_child(row)
	for choice_key in AshwoodData.SPECIAL_HEROES:
		var candidate:Dictionary=AshwoodData.SPECIAL_HEROES[choice_key]
		var card:=Button.new();card.custom_minimum_size=Vector2(350,205);card.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.add_theme_font_size_override("font_size",14);card.add_theme_color_override("font_color",CLASSES[candidate["class"]].color);card.add_theme_stylebox_override("normal",ui_box(Color("182536"),10,CLASSES[candidate["class"]].color,2));card.text="[%s]\n%s\n%s  •  %s\n%s\nSignature: %s\n%s"%[candidate.visual_identity,candidate.name,candidate["class"],candidate.role,candidate.personality,candidate.signature,candidate.reason];card.pressed.connect(func(id=choice_key):choose_special_hero(id));row.add_child(card)

func show_pending_special_choice() -> void:
	screen="ashwood_victory"
	var root=base_screen("THE ASHWOOD SURVIVORS","A PERMANENT CHOICE")
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",12);root.add_child(content)
	content.add_child(label("The servant is gone, but the lost party's traitor escaped. Three survivors now decide which lead to follow.",18,C_TEXT))
	show_special_hero_choices(content)

func choose_special_hero(choice_key:String) -> void:
	if str(state.zone0.special_hero_choice)!="":return
	var candidate:Dictionary=AshwoodData.SPECIAL_HEROES[choice_key]
	state.zone0.special_hero_choice=choice_key
	state.zone0.party_management_unlocked=true
	add_special_hero(choice_key)
	ashwood_selected_decision_text="%s will remain with the guild."%candidate.name
	save_game()
	show_ashwood_consequence_overlay("%s remains with the guild. The other two survivors depart to follow separate leads. Party Management is now available."%candidate.name)
