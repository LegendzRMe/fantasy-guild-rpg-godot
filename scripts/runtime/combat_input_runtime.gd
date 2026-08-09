extends "res://scripts/runtime/ability_runtime.gd"

func load_mage_test_build(hero:Dictionary,heroic_id:String)->void:
	var health_ratio:=float(hero.hp)/maxf(1.0,float(hero.max_hp));hero.level=30;hero.power=MageData.scaled(float(MageData.VALUES.basic_attack_damage),30);hero.base_power=hero.power;hero.max_hp=MageData.scaled(float(MageData.VALUES.health),30);hero.hp=maxf(1.0,hero.max_hp*health_ratio);hero.basic_action_amount=hero.power;hero.damage=hero.power
	var phoenix_build:bool=heroic_id=="mage_l15_r1"
	hero.selected_heroic_id=heroic_id;hero.selected_talents={"tier_1":"mage_l9_1","tier_2":"mage_l12_2" if phoenix_build else "mage_l12_3","tier_3":heroic_id,"tier_4":"mage_l18_2" if phoenix_build else "mage_l18_3","tier_5":"mage_l21_1","tier_6":"mage_l24_3" if phoenix_build else "mage_l24_2","tier_7":"mage_l27_r1" if phoenix_build else "mage_l27_r2","tier_8":"mage_l30_2" if phoenix_build else "mage_l30_3"};MageSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_level_one_mage_test(hero:Dictionary)->void:
	hero.level=1;hero.power=float(MageData.VALUES.basic_attack_damage);hero.base_power=hero.power;hero.max_hp=float(MageData.VALUES.health);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id="";hero.selected_talents={};MageSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_rogue_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=RogueData.TEST_BUILDS[clampi(build_index,0,RogueData.TEST_BUILDS.size()-1)];var level:int=int(build.level);hero.level=level;hero.power=RogueData.scaled(float(RogueData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=RogueData.scaled(float(RogueData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);RogueSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_slayer_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=SlayerData.TEST_BUILDS[clampi(build_index,0,SlayerData.TEST_BUILDS.size()-1)];var level:int=int(build.level);hero.level=level;hero.power=SlayerData.scaled(float(SlayerData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=SlayerData.scaled(float(SlayerData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);SlayerSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_priest_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=PriestData.TEST_BUILDS[clampi(build_index,0,PriestData.TEST_BUILDS.size()-1)];var level:int=int(build.level);hero.level=level;hero.power=PriestData.scaled(float(PriestData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=PriestData.scaled(float(PriestData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);PriestSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_shaman_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=ShamanData.TEST_BUILDS[clampi(build_index,0,ShamanData.TEST_BUILDS.size()-1)];var level:int=int(build.level);var mastery:Dictionary=hero.get("shaman_runtime",{}).get("mastery",{}).duplicate(true)
	hero.level=level;hero.power=ShamanData.scaled(float(ShamanData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=ShamanData.scaled(float(ShamanData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);ShamanSystem.initialize_runtime(hero,true,mastery);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_templar_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=TemplarData.TEST_BUILDS[clampi(build_index,0,TemplarData.TEST_BUILDS.size()-1)];var level:int=int(build.level)
	hero.level=level;hero.power=TemplarData.scaled(float(TemplarData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=TemplarData.scaled(float(TemplarData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);TemplarSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_protector_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=ProtectorData.TEST_BUILDS[clampi(build_index,0,ProtectorData.TEST_BUILDS.size()-1)]
	var level:int=int(build.level)
	hero.level=level;hero.power=ProtectorData.scaled(float(ProtectorData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=ProtectorData.scaled(float(ProtectorData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.range=float(ProtectorData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);ProtectorSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_sentinel_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=SentinelData.TEST_BUILDS[clampi(build_index,0,SentinelData.TEST_BUILDS.size()-1)];var level:int=int(build.level)
	hero.level=level;hero.power=SentinelData.scaled(float(SentinelData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=SentinelData.scaled(float(SentinelData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.range=float(SentinelData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);SentinelSystem.initialize_runtime(hero,true)
	hero.sentinel_runtime.e_quest_stacks=int(build.get("quest_stacks",0));hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func sentinel_range_hero():
	for hero in heroes:
		if str(hero.get("class",""))=="Sentinel":return hero
	return null

func handle_sentinel_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="sentinel_range":return false
	var hero=sentinel_range_hero();if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_5:
		var build_index:=int(event.keycode-KEY_1);load_sentinel_test_build(hero,build_index);flash("Sentinel build: %s"%str(SentinelData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.alt_pressed:return false
	match event.keycode:
		KEY_C:
			hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.sentinel_runtime.q_slot=AbilitySlotSystem.create(2,float(SentinelData.VALUES.q_cooldown),AbilitySlotSystem.RechargeMode.FULL_REFILL);hero.sentinel_runtime.w_slot=AbilitySlotSystem.create(2 if SentinelSystem.has_talent(hero,"sentinel_l30_1") else 1,SentinelSystem.w_cooldown(hero),AbilitySlotSystem.RechargeMode.INDEPENDENT);hero.sentinel_runtime.d_cooldown=0.0;hero.sentinel_runtime.trueshot_cooldown=0.0;flash("Sentinel cooldowns and charges reset")
		KEY_H:
			var ratios:=[1.0,.80,.50,.21,.19,.11,.09,.01]
			for ally_index in heroes.size():heroes[ally_index].hp=maxf(1.0,float(heroes[ally_index].max_hp)*float(ratios[ally_index%ratios.size()]))
			flash("Sentinel ally health ratios staged")
		KEY_Q:hero.sentinel_runtime.e_quest_stacks=84;flash("Lunar Flare quest completed")
		KEY_M:
			var target_index:=combat_enemy_target()
			if target_index>=0:SentinelSystem.apply_mark(hero,enemies[target_index],false);flash("Hunter's Mark applied")
		_:return false
	queue_redraw();return true

func protector_range_hero():
	for hero in heroes:
		if str(hero.get("class",""))=="Protector":return hero
	return null

func handle_protector_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="protector_range":return false
	var hero=protector_range_hero();if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_4:
		var build_index:=int(event.keycode-KEY_1);load_protector_test_build(hero,build_index);flash("Protector build: %s"%str(ProtectorData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.alt_pressed:return false
	match event.keycode:
		KEY_C:
			hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.protector_runtime.aspect_cooldown=0.0
			hero.protector_runtime.smite_slot=AbilitySlotSystem.create(2 if ProtectorSystem.has_talent(hero,"protector_l30_3") else 1,float(ProtectorData.VALUES.e_cooldown));flash("Protector cooldowns and Smite charges reset")
		KEY_K:hero.hp=0.0;hero.protector_runtime.wrath_resolved=false;flash("Archangel's Wrath triggered")
		KEY_H:for ally in heroes:ally.hp=ally.max_hp;flash("All allies restored")
		KEY_W:
			for blocker_index in range(combat_blockers.size()-1,-1,-1):
				if ProtectorSystem.own_wall(hero,combat_blockers[blocker_index]):combat_blockers.remove_at(blocker_index)
			hero.protector_runtime.walls.clear();flash("Protector walls reset")
		KEY_T:
			var target_index:=combat_enemy_target()
			if target_index>=0:
				for ally_index in heroes.size():enemies[target_index].threat[ally_index]=100.0+ally_index*250.0
				flash("Selected enemy Threat configured")
		_:return false
	queue_redraw();return true

func handle_templar_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="templar_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Templar":hero=candidate;break
	if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_4:
		var build_index:=int(event.keycode-KEY_1);load_templar_test_build(hero,build_index);flash("Templar build: %s"%str(TemplarData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.alt_pressed:return false
	match event.keycode:
		KEY_C:hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.templar_runtime.trait_cooldown=0.0;flash("Templar cooldowns reset")
		KEY_D:hero.hp=float(hero.max_hp)*.70;hero.templar_runtime.trait_cooldown=0.0;flash("Shield Overload armed")
		KEY_Q:hero.templar_runtime.protector_stacks=100;flash("Protector stacks: 100")
		KEY_E:for ally in heroes:if ally!=hero:ally.hp=maxf(1.0,float(ally.max_hp)*.35);flash("Allies damaged for Shield Ally testing")
		_:return false
	queue_redraw();return true

func shaman_range_hero():
	for hero in heroes:
		if str(hero.get("class",""))=="Shaman":return hero
	return null

func handle_shaman_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="shaman_range":return false
	var hero=shaman_range_hero();if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_0 and event.keycode<=KEY_9:
		var digit_index:int=9 if event.keycode==KEY_0 else int(event.keycode-KEY_1);var build_index:int=digit_index+(10 if event.ctrl_pressed else 0)
		if build_index<ShamanData.TEST_BUILDS.size():load_shaman_test_build(hero,build_index);flash("Shaman build: %s"%str(ShamanData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.alt_pressed:return false
	match event.keycode:
		KEY_F:ShamanSystem.add_frostwolf_stacks(hero,1,float(hero.hp));flash("Frostwolf stack added")
		KEY_T:resolve_shaman_frostwolf(hero,int(ShamanData.VALUES.trait_threshold));flash("Frostwolf threshold resolved")
		KEY_C:hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.shaman_runtime.q_slot=AbilitySlotSystem.create(ShamanSystem.q_max_charges(hero),ShamanSystem.q_cooldown(hero));flash("Shaman cooldowns reset")
		KEY_G:hero.shaman_runtime.gathering_stacks=int(ShamanData.VALUES.gathering_max);flash("Gathering Storm maxed")
		KEY_U:hero.shaman_runtime.thunder_stacks=int(ShamanData.VALUES.thunder_max);flash("Rolling Thunder maxed")
		KEY_A:hero.shaman_runtime.ancestral_stacks=int(ShamanData.VALUES.ancestral_max);hero.shaman_runtime.ancestral_ready=true;flash("Ancestral Wrath armed")
		KEY_N:ProgressionScopeSystem.begin_encounter(hero.shaman_runtime,ProgressionScopeSystem.new_encounter_id("shaman_test"));flash("New encounter scope")
		KEY_M:ProgressionScopeSystem.room_transition(hero.shaman_runtime,str(hero.shaman_runtime.encounter_id));flash("Room transition; encounter preserved")
		KEY_X:ProgressionScopeSystem.end_encounter(hero.shaman_runtime);flash("Encounter progress cleared")
		_:return false
	queue_redraw();return true

func priest_range_hero():
	for hero in heroes:
		if str(hero.get("class",""))=="Priest":return hero
	return null

func handle_priest_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="priest_range":return false
	var hero=priest_range_hero();if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_3:
		var build_index:=int(event.keycode-KEY_1);load_priest_test_build(hero,build_index);flash("Priest build: %s"%str(PriestData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.alt_pressed:return false
	match event.keycode:
		KEY_K:hero.hp=0.0;flash("Eternal Vanguard triggered")
		KEY_V:
			if PriestSystem.spirit_active(hero):hero.priest_runtime.spirit_remaining=0.01;flash("Spirit Form ending")
		KEY_R:hero.priest_runtime.redemption_ready_in=180.0 if float(hero.priest_runtime.redemption_ready_in)<=0.0 else 0.0;flash("Redemption cooldown: %d"%int(hero.priest_runtime.redemption_ready_in))
		KEY_H:
			for ally in heroes:ally.hp=ally.max_hp
			flash("All allies restored")
		_:
			return false
	queue_redraw();return true

func rogue_range_hero():
	for hero in heroes:
		if str(hero.get("class",""))=="Rogue":return hero
	return null

func handle_rogue_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="rogue_range" or not event.alt_pressed:return false
	var hero=rogue_range_hero();if hero==null:return false
	if event.keycode>=KEY_1 and event.keycode<=KEY_5:
		var values:=[0,1,2,3,5];hero.combo_points=mini(ComboPointSystem.maximum(hero),values[int(event.keycode-KEY_1)]);flash("Combo Points: %d"%int(hero.combo_points));queue_redraw();return true
	match event.keycode:
		KEY_V:
			RogueSystem.break_vanish(hero);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];for id in hero.alternate_cooldowns:hero.alternate_cooldowns[id]=0.0;flash("Vanish and cooldowns reset")
		KEY_S:
			RogueSystem.break_vanish(hero);hero.ability_cds[4]=0.0;RogueSystem.activate_vanish(hero);flash("Stealth forced")
		KEY_I:
			RogueSystem.break_vanish(hero);hero.ability_cds[4]=0.0;RogueSystem.activate_vanish(hero);hero.concealment.unrevealable_remaining=0.0;hero.concealment.invisible=true;hero.rogue_runtime.stationary_elapsed=float(RogueData.VALUES.vanish_invisible_stationary);flash("Invisible forced")
		KEY_R:
			hero.concealment.unrevealable_remaining=0.0;StealthDetectionSystem.reveal(hero,3.0);flash("Reveal applied")
		KEY_D:
			for enemy in enemies:
				if "detector" in enemy.get("combat_tags",[]):enemy.detection_profile={} if bool(enemy.get("detection_profile",{}).get("detect_stealthed",false)) else {"detect_stealthed":true,"detect_invisible":true,"detection_radius":210.0}
			flash("Detector profile toggled")
		KEY_P:
			hero.rogue_runtime.garrotes=[];for enemy in enemies:enemy.bloodletting_stacks=[];flash("Rogue periodic statuses removed")
		KEY_F:
			hero.rogue_runtime.fatal_finesse_stacks=0 if int(hero.rogue_runtime.fatal_finesse_stacks)>=int(RogueData.VALUES.fatal_max_stacks) else int(RogueData.VALUES.fatal_max_stacks);flash("Fatal Finesse: %d"%int(hero.rogue_runtime.fatal_finesse_stacks))
		KEY_B:
			BlockChargeSystem.grant_legacy(hero.rogue_runtime,3,3);flash("Combat Readiness: 3 Block")
		KEY_M:
			hero.selected_heroic_id="rogue_l15_r1";hero.ability_cds[3]=0.0;cast_rogue_heroic(hero);flash("Smoke Bomb triggered")
		KEY_C:
			hero.selected_heroic_id="rogue_l15_r2";hero.ability_cds[3]=0.0;cast_rogue_heroic(hero);flash("Cloak triggered")
		KEY_T:
			for enemy in enemies:
				if "boss" in enemy.get("combat_tags",[]):enemy.control_profile={"stun_multiplier":1.0,"blind_immune":false,"silence_multiplier":1.0} if bool(enemy.get("control_profile",{}).get("blind_immune",true)) else {"stun_multiplier":0.0,"blind_immune":true,"silence_multiplier":0.0}
			flash("Boss control profiles toggled")
		KEY_H:
			var healer=enemies.filter(func(enemy):return str(enemy.get("test_fixture",""))=="external_healer");var targets=enemies.filter(func(enemy):return str(enemy.get("test_fixture",""))=="healable_target");if not healer.is_empty() and not targets.is_empty():targets[0].hp=maxf(1.0,float(targets[0].hp)-300.0);deal_healing(healer[0],targets[0],250.0,"basic_heal","Rogue Range")
			flash("External healing triggered")
		KEY_J:
			var self_targets=enemies.filter(func(enemy):return bool(enemy.get("self_heal_test",false)));if not self_targets.is_empty():self_targets[0].hp=maxf(1.0,float(self_targets[0].hp)-300.0);deal_healing(self_targets[0],self_targets[0],250.0,"basic_heal","Rogue Range")
			flash("Self-healing triggered")
		_:
			return false
	queue_redraw();return true

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
	if not TalentSystem.ability_is_unlocked(hero_level,slot):return
	var category=ABILITY_TARGETING[heroes[selected]["class"]][slot]
	if heroes[selected]["class"]=="Guardian" and slot==3 and guardian_heroic_id(heroes[selected])=="guardian_l15_r2":category="enemy"
	if heroes[selected]["class"]=="Mage" and slot==3 and str(heroes[selected].get("selected_heroic_id",""))=="mage_l15_r2":category="enemy"
	if heroes[selected]["class"]=="Slayer" and slot==3 and str(heroes[selected].get("selected_heroic_id",""))=="slayer_l15_r2":category="enemy"
	var mode="instant" if category=="self" else str(state.casting_settings[device].get(category,"cursor"))
	if mode=="instant" or mode=="cursor" or mode=="facing" or mode=="target":
		if (category=="enemy" and combat_enemy_target()<0) or (category=="ally" and (heroes[selected].heal_target<0 or heroes[selected].heal_target>=heroes.size())):
			return
		var cast_point=get_global_mouse_position()
		if mode=="facing":cast_point=heroes[selected].pos+heroes[selected].facing_direction*ABILITY_RANGES[heroes[selected]["class"]][slot]
		use_ability(slot,cast_point);return
	ability_aiming=true;aimed_ability_slot=slot;aimed_ability_category=category;aimed_cast_mode=mode;aimed_from_touch=device=="mobile";ability_button_held=mode=="release";ability_aim_point=get_global_mouse_position();queue_redraw()

func begin_trait()->void:
	if selected<0 or selected>=heroes.size() or bool(heroes[selected].get("independent",false)):return
	var hero:Dictionary=heroes[selected]
	if str(hero.get("class",""))=="Guardian" and GuardianSystem.has_talent(hero,"guardian_l24_2"):
		use_guardian_trait(hero)
		queue_redraw()
	elif str(hero.get("class",""))=="Cleric":
		use_cleric_trait(hero)
		queue_redraw()
	elif str(hero.get("class",""))=="Ranger" and RangerSystem.has_talent(hero,"ranger_l21_3"):
		if float(hero.ranger_runtime.strafe_remaining)>0.0:return
		RangerSystem.activate_gloom(hero)
		queue_redraw()
	elif str(hero.get("class",""))=="Mage":
		if not MageSystem.activate_trait(hero,battle_time):return
		else:
			if MageSystem.has_talent(hero,"mage_l9_2"):deal_healing(hero,hero,MageSystem.scaled_ability_amount(hero,float(MageData.VALUES.fel_infusion_heal)),"basic_ability","Fel Infusion")
			add_effect("cast",hero.pos,hero.pos,"",CLASSES.Mage.color)
		queue_redraw()
	elif str(hero.get("class",""))=="Warlock":
		if use_warlock_trait(hero):queue_redraw()
	elif str(hero.get("class",""))=="Rogue":
		if use_rogue_trait(hero):queue_redraw()
	elif str(hero.get("class",""))=="Slayer":
		if use_slayer_trait(hero):queue_redraw()
	elif str(hero.get("class",""))=="Shaman":
		if use_shaman_trait(hero):queue_redraw()

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

func handle_combat_testing_shortcut(event:InputEventKey)->bool:
	if handle_sentinel_range_shortcut(event):return true
	if handle_protector_range_shortcut(event):return true
	if handle_templar_range_shortcut(event):return true
	if handle_shaman_range_shortcut(event):return true
	if handle_priest_range_shortcut(event):return true
	if handle_rogue_range_shortcut(event):return true
	if testing_zone_active and testing_zone_mode=="slayer_range" and event.shift_pressed and event.keycode>=KEY_0 and event.keycode<=KEY_9:
		var build_index:int=9 if event.keycode==KEY_0 else int(event.keycode-KEY_1)
		for hero in heroes:
			if str(hero.get("class",""))=="Slayer":load_slayer_test_build(hero,build_index)
		flash("Slayer build: %s"%str(SlayerData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if testing_zone_active and testing_zone_mode=="rogue_range" and event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_6:
		var build_index:int=int(event.keycode-KEY_1)
		for hero in heroes:
			if str(hero.get("class",""))=="Rogue":load_rogue_test_build(hero,build_index)
		flash("Rogue build: %s"%str(RogueData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if event.keycode==KEY_F3 and testing_zone_active:debug_combat_overlay=not debug_combat_overlay;queue_redraw();return true
	if event.keycode==KEY_F4 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Guardian":GuardianSystem.add_quest(hero,45,"testing_control",battle_time);flash("Guardian quest +45")
		return true
	if event.keycode==KEY_F5 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Guardian":hero.selected_heroic_id="guardian_l15_r2" if guardian_heroic_id(hero)=="guardian_l15_r1" else "guardian_l15_r1";hero.selected_talents["tier_3"]=hero.selected_heroic_id;flash("Heroic: %s"%GuardianData.WORKING_NAMES[hero.selected_heroic_id])
		return true
	if event.keycode==KEY_F6 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Guardian":hero.selected_talents={"tier_1":"guardian_l9_1","tier_2":"guardian_l12_2","tier_3":guardian_heroic_id(hero),"tier_4":"guardian_l18_2","tier_5":"guardian_l21_2","tier_6":"guardian_l24_1","tier_7":"guardian_l27_r1" if guardian_heroic_id(hero)=="guardian_l15_r1" else "guardian_l27_r2","tier_8":"guardian_l30_1"};hero.guardian_runtime.ability_charges=GuardianSystem.default_charges(hero);flash("Guardian test talents loaded")
		return true
	if event.keycode==KEY_F7 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Cleric":hero.selected_heroic_id="cleric_l15_r1";hero.selected_talents={"tier_1":"cleric_l9_1","tier_2":"cleric_l12_2","tier_3":"cleric_l15_r1","tier_4":"cleric_l18_1","tier_5":"cleric_l21_2","tier_6":"cleric_l24_1","tier_7":"cleric_l27_r1","tier_8":"cleric_l30_1"};ClericSystem.initialize_runtime(hero,true);flash("Cleric Jug test build loaded")
		return true
	if event.keycode==KEY_F8 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Cleric":hero.selected_heroic_id="cleric_l15_r2";hero.selected_talents={"tier_1":"cleric_l9_2","tier_2":"cleric_l12_3","tier_3":"cleric_l15_r2","tier_4":"cleric_l18_2","tier_5":"cleric_l21_1","tier_6":"cleric_l24_3","tier_7":"cleric_l27_r2","tier_8":"cleric_l30_2"};ClericSystem.initialize_runtime(hero,true);flash("Cleric Dragon test build loaded")
		return true
	if event.keycode==KEY_F9 and event.ctrl_pressed and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage":load_level_one_mage_test(hero)
		flash("Level 1 Mage baseline loaded");return true
	if event.keycode==KEY_F9 and event.shift_pressed and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage":load_mage_test_build(hero,"mage_l15_r1")
		flash("Level 30 Mage Phoenix chain build loaded");return true
	if event.keycode==KEY_F10 and event.shift_pressed and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage":load_mage_test_build(hero,"mage_l15_r2")
		flash("Level 30 Mage Pyro control build loaded");return true
	if event.keycode==KEY_F9 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage" and not hero.get("mage_runtime",{}).is_empty():hero.mage_runtime.trait.current_charges=hero.mage_runtime.trait.max_charges;hero.mage_runtime.trait.recharge_timers=[];hero.mage_runtime.trait.armed=false
		flash("Mage Trait charges reset");return true
	if event.keycode==KEY_F10 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage" and not hero.get("mage_runtime",{}).is_empty():hero.mage_runtime.arcane_dynamo_stacks=int(MageData.VALUES.arcane_dynamo_max);hero.mage_runtime.arcane_dynamo_remaining=float(MageData.VALUES.arcane_dynamo_duration);hero.mage_runtime.arcane_barrier_ready_in=0.0;MageSystem.refresh_ability_power(hero)
		flash("Mage Dynamo max; Barrier ready");return true
	if event.keycode==KEY_F11 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage" and not hero.get("mage_runtime",{}).is_empty():
				for foe in enemies:
					if foe.hp>0:apply_living_bomb(hero,foe,true)
		flash("Living Bomb cluster armed");return true
	if event.keycode==KEY_F12 and testing_zone_active:
		for foe in enemies:
			if foe.hp>0 and ("boss" in foe.get("combat_tags",[]) or "elite" in foe.get("combat_tags",[])):foe.hp=maxf(1.0,float(foe.max_hp)*0.10)
		flash("Boss and Elite targets set to 10% Health");return true
	return false

func handle_combat_key_pressed(event:InputEventKey)->void:
	if event.keycode==KEY_SPACE:paused=!paused;queue_redraw()
	if event.keycode==KEY_TAB and not event.echo:
		cycle_selected_enemy()
		get_viewport().set_input_as_handled()
	if event.keycode>=KEY_1 and event.keycode<=KEY_8:
		var selectable_heroes:Array=player_controlled_hero_indices()
		var requested_slot:int=event.keycode-KEY_1
		if requested_slot<selectable_heroes.size():selected=selectable_heroes[requested_slot];queue_redraw()
	if not event.echo and event.keycode==KEY_Q:begin_ability(0)
	if not event.echo and event.keycode==KEY_W:begin_ability(1)
	if not event.echo and event.keycode==KEY_E:begin_ability(2)
	if not event.echo and event.keycode==KEY_R:begin_ability(3)
	if not event.echo and event.keycode==KEY_D:begin_trait()

func handle_combat_mouse_press(event:InputEventMouseButton)->bool:
	if event.button_index==MOUSE_BUTTON_RIGHT:
		if ability_aiming:cancel_ability_aim()
		elif not paused:clear_selected_combat_target()
		get_viewport().set_input_as_handled();return true
	if event.button_index==MOUSE_BUTTON_WHEEL_UP:
		cycle_selected_hero(-1);get_viewport().set_input_as_handled();return true
	if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
		cycle_selected_hero(1);get_viewport().set_input_as_handled();return true
	if event.button_index!=MOUSE_BUTTON_LEFT:return false
	var point:=event.position
	if tutorial_active:
		tutorial_pointer_press(point,"pc");get_viewport().set_input_as_handled();return true
	if ability_aiming and aimed_cast_mode=="confirm":
		if confirm_aim_at(point):get_viewport().set_input_as_handled()
		return true
	if point.x>1190 and point.y<70:paused=true;queue_redraw();return true
	if paused:
		if Rect2(490,285,300,58).has_point(point):paused=false;queue_redraw()
		elif testing_zone_active and testing_zone_mode=="range" and Rect2(490,360,300,58).has_point(point):toggle_testing_dummy_attacks()
		elif Rect2(490,435 if testing_zone_active else 360,300,58).has_point(point):paused=false;show_combat_hall() if testing_zone_active else show_zone_map(dungeon_id)
		return true
	if point.y>575 and point.y<635 and point.x>420 and point.x<875:
		var selectable_heroes:Array=player_controlled_hero_indices();var requested_slot:int=clampi(int((point.x-424)/54),0,7)
		if requested_slot<selectable_heroes.size():selected=selectable_heroes[requested_slot];queue_redraw()
		return true
	if point.y>635 and point.x>445 and point.x<835:
		var action_slot:=clampi(int((point.x-445)/78),0,4)
		if action_slot==4:begin_trait()
		else:begin_ability(action_slot)
		return true
	for i in heroes.size():
		if not bool(heroes[i].get("independent",false)) and heroes[i].pos.distance_to(point)<58:
			selected=i;dragging_hero=true;drag_cursor=point;drag_start=point;drag_has_moved=false;drag_target_type="ground";drag_target_index=-1;queue_redraw();return true
	return false

func handle_combat_touch(event:InputEventScreenTouch)->bool:
	if tutorial_active:
		if event.pressed:tutorial_pointer_press(event.position,"mobile")
		elif dragging_hero:update_hero_drag(event.position);finish_hero_drag()
		get_viewport().set_input_as_handled();return true
	if event.pressed and ability_aiming and aimed_cast_mode=="confirm":confirm_aim_at(event.position);return true
	if event.pressed and event.position.y>635 and event.position.x>445 and event.position.x<835:
		var action_slot:=clampi(int((event.position.x-445)/78),0,4)
		if action_slot==4:begin_trait()
		else:begin_ability(action_slot,"mobile")
		return true
	if not event.pressed and ability_aiming and aimed_cast_mode=="release":confirm_aim_at(event.position);return true
	if event.pressed and not paused and event.position.y<635:clear_selected_combat_target()
	return false

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
		if handle_combat_testing_shortcut(event):get_viewport().set_input_as_handled();return
		if event.keycode==KEY_ESCAPE and ability_aiming:cancel_ability_aim();get_viewport().set_input_as_handled();return
		handle_combat_key_pressed(event)
	if event is InputEventKey and not event.pressed and ability_aiming and aimed_cast_mode=="release":
		var released_slot={KEY_Q:0,KEY_W:1,KEY_E:2,KEY_R:3}.get(event.keycode,-1)
		if released_slot==aimed_ability_slot:confirm_aim_at(get_global_mouse_position());return
	if event is InputEventMouseButton and event.pressed and handle_combat_mouse_press(event):return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and ability_aiming and aimed_cast_mode=="release":
		confirm_aim_at(event.position);return
	if event is InputEventMouseMotion and ability_aiming:ability_aim_point=event.position;queue_redraw()
	if event is InputEventScreenDrag and ability_aiming:ability_aim_point=event.position;queue_redraw();return

	if event is InputEventScreenTouch and handle_combat_touch(event):return
	if event is InputEventScreenDrag and tutorial_active and dragging_hero:update_hero_drag(event.position);return
	if event is InputEventMouseMotion and dragging_hero:update_hero_drag(event.position)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and dragging_hero:
		finish_hero_drag()
