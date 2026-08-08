extends "res://scripts/runtime/campaign_runtime.gd"

func finish_battle(win:bool)->void:
	for hero in heroes:
		if str(hero.get("class",""))=="Rogue" and not hero.get("rogue_runtime",{}).is_empty():RogueSystem.telemetry_add(hero,"combo_encounter_resets");RogueSystem.reset_encounter(hero)
	battle_over=true
	if not tutorial_active and not testing_zone_active:
		var recovery_members:=TavernFacilitySystem.record_battle_defeats(state,heroes)
		if not recovery_members.is_empty():save_game()
	victory_talent_prompt_handled=false;victory_talent_queue.clear();victory_talent_choice_index=0;close_victory_talent_overlay()
	if current_ashwood_encounter!="":
		finish_ashwood_battle(win)
		return
	if not current_campaign_battle.is_empty():
		finish_campaign_battle(win)
		return
	if win:
		var previous_levels:=[]
		for i in heroes.size():previous_levels.append(state.heroes[battle_hero_indices[i]].level)
		state.dungeon_clears[dungeon_id]+=1
		if encounter_id<10:
			state.zone_progress[dungeon_id]=max(int(state.zone_progress[dungeon_id]),min(10,encounter_id+1))
			if encounter_id==9 and dungeon_id==0:
				state.unlocked_dungeon=1
		elif encounter_id<12:
			state.zone_branches[dungeon_id][encounter_id-10]=true
		grant_rewards(dungeon_id,true); victory_level_ups.clear()
		for i in heroes.size():

			var hero_data=state.heroes[battle_hero_indices[i]]
			if hero_data.level>previous_levels[i]:victory_level_ups.append({"slot":i,"level":hero_data.level,"talent_tiers":TalentSystem.newly_unlocked_tiers(int(previous_levels[i]),int(hero_data.level))})
		save_game()
		dragging_hero=false;drag_target_type="ground";drag_target_index=-1;victory_sequence=true; victory_phase=0; victory_timer=0.0
		for i in heroes.size():heroes[i].dest=centered_victory_position(i,heroes.size(),105.0,465.0)
		queue_redraw(); return
	var overlay:=ColorRect.new(); overlay.color=Color(0.03,0.05,0.09,.96); overlay.position=Vector2(300,120); overlay.size=Vector2(680,480); ui.visible=true; ui.add_child(overlay)
	var box:=VBoxContainer.new(); box.position=Vector2(350,160); box.size=Vector2(580,400); box.add_theme_constant_override("separation",14); ui.add_child(box)
	box.add_child(label("VICTORY" if win else "DEFEAT",38,C_GOLD if win else C_RED)); box.add_child(label(("The guild returns richer and stronger." if win else "Recover, re-equip, and try a new formation."),18,C_MUTED)); if win:box.add_child(label("Rewards: %d gold • XP • materials • dungeon token"%(90+dungeon_id*55),18,C_GREEN)); box.add_spacer(false); box.add_child(button("Return to Guild Hall",show_hall,250))
	box.add_child(button("Retry Encounter",func():start_battle(dungeon_id,encounter_id),250))
	box.add_child(label("Enter / Esc: Guild Hall     R: Retry",15,C_MUTED))

func update_victory(delta:float) -> void:
	for fx in effects:fx.life-=delta
	effects=effects.filter(func(fx):return fx.life>0)
	victory_timer+=delta
	if victory_phase==0 and victory_timer>=1.2: victory_phase=1; victory_timer=0
	elif victory_phase==1:
		for h in heroes: h.pos=h.pos.move_toward(h.dest,115*delta)
		var gathered=heroes.all(func(h):return h.pos.distance_to(h.dest)<4)
		if gathered or victory_timer>=4.5:
			# Guarantee a clean lineup if a distant hero cannot finish walking
			# before the reward presentation advances.
			for h in heroes: h.pos=h.dest
			victory_phase=2; victory_timer=0
	elif victory_phase==2 and victory_timer>=1.3: victory_phase=3; victory_timer=0
	elif victory_phase==3 and victory_timer>=1.3: victory_phase=4; victory_timer=0
	elif victory_phase==4 and victory_timer>=1.2: victory_phase=5; victory_timer=0
	queue_redraw()

func victory_xp_animation_state(progress_data:Dictionary,xp_award:int,animation_progress:float) -> Dictionary:
	var shown_level:int=int(progress_data.get("before_level",1))
	var shown_xp:float=float(progress_data.get("before_xp",0))+xp_award*clampf(animation_progress,0.0,1.0)
	while shown_level<CombatSystem.LEVEL_CAP and shown_xp>=shown_level*100:shown_xp-=shown_level*100;shown_level+=1
	if shown_level>=CombatSystem.LEVEL_CAP:shown_xp=minf(shown_xp,CombatSystem.LEVEL_CAP*100-1)
	return {"level":shown_level,"xp":shown_xp,"ratio":shown_xp/max(1.0,shown_level*100.0)}

func victory_progress_center(hero_slot:int)->Vector2:
	if hero_slot>=0 and hero_slot<heroes.size():return heroes[hero_slot].pos
	return centered_victory_position(hero_slot,heroes.size(),105.0,465.0)

func victory_continue_prompt()->String:
	return "CLICK TO CONTINUE"

func grant_rewards(id:int,manual:bool)->void:
	var mod=1.0 if manual else .7; state.gold+=int((90+id*55)*mod);battle_material_results.clear()
	for material_reward in [["ore",int((3+id)*mod)],["herbs",int((2+id*2)*mod)],["dust",int(3*mod) if id==1 else 0]]:
		if int(material_reward[1])<=0:continue
		var material_result:=InventorySystem.add_material(state,str(material_reward[0]),int(material_reward[1]));material_result["material_id"]=material_reward[0];battle_material_results.append(material_result)
	for h in state.heroes:
		h.xp+=int((55+id*35)*mod)
		while h.level<CombatSystem.LEVEL_CAP and h.xp>=h.level*100: h.xp-=h.level*100; h.level+=1; h.gear+=1
		if h.level>=CombatSystem.LEVEL_CAP:h.xp=mini(int(h.xp),CombatSystem.LEVEL_CAP*100-1)
		h.experience=int(h.xp)
		state.class_talent_discovery=TalentSystem.record_class_discovery(state.class_talent_discovery,str(h.class_id),int(h.level))
