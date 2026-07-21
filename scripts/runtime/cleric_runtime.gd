extends "res://scripts/runtime/guardian_runtime.gd"

func cleric_enemy_by_id(combat_id:String):
	for foe in enemies:
		if str(foe.get("combat_id",""))==combat_id and foe.hp>0:return foe
	return null

func cleric_ally_by_id(combat_id:String):
	for ally in heroes:
		if str(ally.get("combat_id",""))==combat_id and ally.hp>0:return ally
	return null

func cleric_host_movement_multiplier(target:Dictionary)->float:
	var bonus:=0.0
	for owner in heroes:
		if str(owner.get("class",""))!="Cleric" or owner.get("cleric_runtime",{}).is_empty() or not ClericSystem.has_talent(owner,"cleric_l18_2"):continue
		for serpent in owner.cleric_runtime.serpents:
			if str(serpent.get("host_id",""))==str(target.get("combat_id","")):bonus=maxf(bonus,0.20 if float(serpent.get("wind_boost",0.0))>0.0 else 0.10)
	return 1.0+bonus

func cleric_heal(hero:Dictionary,target:Dictionary,base_amount:float,origin:String,source_action:String="basic_ability")->Dictionary:
	var result:=deal_healing(hero,target,ClericSystem.scaled_amount(hero,base_amount),source_action,origin)
	add_effect("heal",hero.pos,target.pos,"+%d"%int(result.effective_amount),C_GREEN)
	return result

func cast_cleric_q(hero:Dictionary)->bool:
	var target_limit:=2 if ClericSystem.has_talent(hero,"cleric_l24_1") else 1
	var targets:=ClericSystem.lowest_wounded_indices(heroes,target_limit,hero.pos,float(hero.get("range",220.0)))
	if targets.is_empty():ClericSystem.telemetry_add(hero,"q_failed");return false
	var base_cooldown:=5.0 if ClericSystem.has_talent(hero,"cleric_l24_1") else float(ClericData.VALUES.q_cooldown)
	hero.ability_cds[0]=base_cooldown
	for target_index in targets:
		var target:Dictionary=heroes[target_index];var before_ratio:=float(target.hp)/maxf(1.0,float(target.max_hp));var amount:=float(ClericData.VALUES.q_heal)
		if ClericSystem.has_talent(hero,"cleric_l24_2") and before_ratio<0.5:amount*=1.33;ClericSystem.telemetry_add(hero,"pick_me_up_activations")
		var q_result:=cleric_heal(hero,target,amount,"Healing Brew");ClericSystem.telemetry_add(hero,"q_effective_healing",float(q_result.effective_amount));ClericSystem.telemetry_add(hero,"q_overhealing",float(q_result.overhealing))
		if ClericSystem.has_talent(hero,"cleric_l9_1") and before_ratio<0.5:hero.ability_cds[0]=maxf(0.0,float(hero.ability_cds[0])-1.0);ClericSystem.telemetry_add(hero,"free_drinks_reductions")
		if ClericSystem.has_talent(hero,"cleric_l18_1"):
			hero.cleric_runtime.periodic_heals.append({"target_id":str(target.combat_id),"remaining":3.0,"tick":1.0,"amount":84.0 if ClericSystem.fast_feet_active(hero) else 42.0})
	if ClericSystem.has_talent(hero,"cleric_l30_1") and float(hero.cleric_runtime.mistweaver_ready_in)<=0.0:
		for ally in heroes:
			if ally.hp>0 and ally.pos.distance_to(hero.pos)<=240.0:cleric_heal(hero,ally,149.0,"Mistweaver")
		hero.cleric_runtime.mistweaver_ready_in=30.0
		ClericSystem.telemetry_add(hero,"mistweaver_activations")
	ClericSystem.telemetry_add(hero,"q_casts")
	return true

func cast_cleric_w(hero:Dictionary)->bool:
	var target_index:=int(hero.get("heal_target",-1))
	if target_index<0 or target_index>=heroes.size() or heroes[target_index].hp<=0:return false
	var target:Dictionary=heroes[target_index]
	if ClericSystem.has_talent(hero,"cleric_l30_2") and int(hero.cleric_runtime.get("w_charges",0))<=0:return false
	for serpent_index in range(hero.cleric_runtime.serpents.size()-1,-1,-1):
		if str(hero.cleric_runtime.serpents[serpent_index].host_id)==str(target.combat_id):hero.cleric_runtime.serpents.remove_at(serpent_index)
	var max_serpents:=2 if ClericSystem.has_talent(hero,"cleric_l30_2") else 1
	while hero.cleric_runtime.serpents.size()>=max_serpents:hero.cleric_runtime.serpents.pop_front()
	hero.cleric_runtime.serpents.append({"host_id":str(target.combat_id),"remaining":float(ClericData.VALUES.w_duration),"tick":0.0,"wind_boost":0.0})
	if ClericSystem.has_talent(hero,"cleric_l30_2"):
		hero.cleric_runtime.w_charges=int(hero.cleric_runtime.w_charges)-1;hero.cleric_runtime.w_recharge_timers.append(float(ClericData.VALUES.w_cooldown));hero.ability_cds[1]=0.0 if int(hero.cleric_runtime.w_charges)>0 else float(ClericData.VALUES.w_cooldown)
	else:hero.ability_cds[1]=float(ClericData.VALUES.w_cooldown)
	ClericSystem.telemetry_add(hero,"w_casts")
	return true

func cast_cleric_e(hero:Dictionary)->bool:
	var target_limit:=3 if ClericSystem.has_talent(hero,"cleric_l18_3") else 2
	var targets:=ClericSystem.nearest_enemy_indices(hero.pos,enemies,target_limit)
	if targets.is_empty():return false
	ClericSystem.telemetry_add(hero,"e_casts")
	var damage_multiplier:=1.75 if ClericSystem.has_talent(hero,"cleric_l18_3") and targets.size()>=3 else 1.0
	var blind_duration:=2.25 if ClericSystem.has_talent(hero,"cleric_l21_2") else float(ClericData.VALUES.e_blind_duration)
	var slow_amount:=0.30 if ClericSystem.has_talent(hero,"cleric_l21_3") else float(ClericData.VALUES.e_slow)
	var slow_duration:=2.0 if ClericSystem.has_talent(hero,"cleric_l21_3") else float(ClericData.VALUES.e_slow_duration)
	for target_index in targets:
		var target:Dictionary=enemies[target_index]
		deal_damage(hero,target,ClericSystem.scaled_amount(hero,float(ClericData.VALUES.e_damage))*damage_multiplier,"basic_ability","magical","Blinding Wind")
		CombatSystem.apply_control(target,"slow",slow_duration,slow_amount)
		var blind_result:=CombatSystem.apply_blind(target,blind_duration)
		combat_events.append(CombatSystem.create_event("blind_attempted",hero,target,{"amount":0.0,"source_action":"basic_ability","result_category":"debuff"},{"action_tags":["basic_ability","debuff"],"origin":"Blinding Wind"}))
		if bool(blind_result.applied):combat_events.append(CombatSystem.create_event("blind_applied",hero,target,{"amount":0.0,"source_action":"basic_ability","result_category":"debuff"},{"action_tags":["basic_ability","debuff"],"origin":"Blinding Wind"}));ClericSystem.telemetry_add(hero,"blind_applications")
		else:
			combat_events.append(CombatSystem.create_event("blind_resisted",hero,target,{"amount":0.0,"source_action":"basic_ability","result_category":"debuff"},{"action_tags":["basic_ability","debuff"],"origin":"Blinding Wind"}))
			ClericSystem.telemetry_add(hero,"blind_resistance")
			if testing_zone_active:add_effect("hit",hero.pos,target.pos,"IMMUNE",C_MUTED)
	if ClericSystem.has_talent(hero,"cleric_l12_1") and targets.size()>=2:
		hero.ability_cds[2]=maxf(0.0,float(ClericData.VALUES.e_cooldown)-2.0);hero.cleric_runtime.spell_power_remaining=10.0
		ClericSystem.telemetry_add(hero,"surging_winds_activations")
	else:hero.ability_cds[2]=float(ClericData.VALUES.e_cooldown)
	if ClericSystem.has_talent(hero,"cleric_l18_3") and targets.size()>=3:ClericSystem.telemetry_add(hero,"mass_vortex_activations")
	if ClericSystem.has_talent(hero,"cleric_l18_2"):
		for serpent in hero.cleric_runtime.serpents:serpent.wind_boost=3.0
	ClericSystem.telemetry_add(hero,"e_hits",targets.size())
	return true

func cast_cleric_heroic(hero:Dictionary)->bool:
	var heroic_id:=str(hero.get("selected_heroic_id",""))
	if heroic_id in ["cleric_r1","cleric_l15_r1"]:
		if bool(hero.cleric_runtime.jug_active):hero.ability_cds[3]=ClericSystem.stop_jug(hero);CombatRulesV1.restore_preserved_command(hero,true);return true
		CombatRulesV1.preserve_command(hero);hero.command_state=CombatRulesV1.CommandState.CHANNEL;ClericSystem.begin_jug(hero);return true
	if heroic_id not in ["cleric_r2","cleric_l15_r2"]:return false
	var targets:=ClericSystem.nearest_enemy_indices(hero.pos,enemies,1)
	if targets.is_empty():return false
	CombatRulesV1.preserve_command(hero);begin_unit_cast(hero,3,float(ClericData.VALUES.r2_precast),true,0.0,false,float(ClericData.VALUES.r2_cooldown))
	hero.cleric_runtime.delayed_effects.append({"kind":"water_dragon","remaining":float(ClericData.VALUES.r2_precast),"target_id":str(enemies[targets[0]].combat_id),"requires_cast":true})
	return true

func cast_cleric_ability(slot:int,item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected]
	if str(hero.get("class",""))!="Cleric" or hero.get("cleric_runtime",{}).is_empty():return false
	if slot==3 and bool(hero.cleric_runtime.jug_active):return cast_cleric_heroic(hero)
	if not item_repeat and float(hero.ability_cds[slot])>0.0 and not (slot==1 and ClericSystem.has_talent(hero,"cleric_l30_2") and int(hero.cleric_runtime.get("w_charges",0))>0):return false
	var prior_cooldown:=float(hero.ability_cds[slot])
	if item_repeat:hero.ability_cds[slot]=0.0
	var succeeded:=cast_cleric_q(hero) if slot==0 else cast_cleric_w(hero) if slot==1 else cast_cleric_e(hero) if slot==2 else cast_cleric_heroic(hero)
	if item_repeat:hero.ability_cds[slot]=prior_cooldown
	if succeeded:
		var action:="heroic" if slot==3 else "basic_ability";combat_events.append(CombatSystem.create_event("heroic_cast" if slot==3 else "basic_ability_cast",hero,hero,{"amount":0.0,"source_action":action,"result_category":"buff"},{"action_tags":[action],"origin":ClericData.ACTION_NAMES.get(["Q","W","E","R1"][slot],"")}))
	return succeeded

func cleric_water_dragon_impact(hero:Dictionary,target_id:String,allow_second:bool=true)->void:
	var target=cleric_enemy_by_id(target_id)
	if target==null:
		var nearest:=ClericSystem.nearest_enemy_indices(hero.pos,enemies,1);if nearest.is_empty():return
		target=enemies[nearest[0]]
	var center:Vector2=target.pos
	ClericSystem.telemetry_add(hero,"water_dragon_impacts")
	for foe in enemies:
		if foe.hp>0 and foe.pos.distance_to(center)<=120.0:
			deal_damage(hero,foe,ClericSystem.scaled_amount(hero,float(ClericData.VALUES.r2_damage)),"heroic","magical","Water Dragon");CombatSystem.apply_control(foe,"slow",float(ClericData.VALUES.r2_slow_duration),float(ClericData.VALUES.r2_slow))
	if allow_second and ClericSystem.has_talent(hero,"cleric_l27_r2"):hero.cleric_runtime.delayed_effects.append({"kind":"water_dragon_second","remaining":0.5,"target_id":"","requires_cast":false})

func use_cleric_trait(hero:Dictionary)->bool:
	if ClericSystem.has_talent(hero,"cleric_l12_2"):return ClericSystem.activate_safety_sprint(hero)
	if not ClericSystem.has_talent(hero,"cleric_l12_3") or float(hero.cleric_runtime.trait_cooldown)>0.0:return false
	var target_index:=int(hero.get("heal_target",-1))
	if target_index<0 or target_index>=heroes.size() or target_index==int(hero.get("battle_index",-1)) or heroes[target_index].hp<=0:return false
	cleric_heal(hero,heroes[target_index],160.0,"Let's Go!","trait");CombatSystem.apply_unstoppable(heroes[target_index],1.0);hero.cleric_runtime.trait_cooldown=40.0
	hero.ability_cds[4]=40.0
	combat_events.append(CombatSystem.create_event("trait_cast",hero,heroes[target_index],{"amount":0.0,"source_action":"trait","result_category":"buff"},{"action_tags":["trait"],"origin":"Let's Go!"}))
	return true

func update_cleric_runtime(delta:float)->void:
	for hero in heroes:
		if hero.hp<=0 or str(hero.get("class",""))!="Cleric" or hero.get("cleric_runtime",{}).is_empty():continue
		var has_true_control:bool=hero.get("active_effects",[]).any(func(effect):return str(effect.get("control_type","")) in ["stun","root","silence"] and float(effect.get("remaining_duration",0.0))>0.0)
		if has_true_control and (bool(hero.cleric_runtime.jug_active) or not hero.get("active_cast",{}).is_empty()):interrupt_unit_action(hero,"crowd control")
		ClericSystem.update_timers(hero,delta)
		for periodic_index in range(hero.cleric_runtime.periodic_heals.size()-1,-1,-1):
			var periodic:Dictionary=hero.cleric_runtime.periodic_heals[periodic_index];periodic.remaining-=delta;periodic.tick-=delta
			if periodic.tick<=0.0:
				periodic.tick+=1.0;var target=cleric_ally_by_id(str(periodic.target_id));if target!=null:cleric_heal(hero,target,float(periodic.amount)/3.0,"Good Stuff","periodic")
			if periodic.remaining<=0.0:hero.cleric_runtime.periodic_heals.remove_at(periodic_index)
			else:hero.cleric_runtime.periodic_heals[periodic_index]=periodic
		for serpent_index in range(hero.cleric_runtime.serpents.size()-1,-1,-1):
			var serpent:Dictionary=hero.cleric_runtime.serpents[serpent_index];serpent.remaining-=delta;serpent.tick-=delta;serpent.wind_boost=maxf(0.0,float(serpent.wind_boost)-delta)
			var host=cleric_ally_by_id(str(serpent.host_id))
			if host==null or serpent.remaining<=0.0:hero.cleric_runtime.serpents.remove_at(serpent_index);continue
			if serpent.tick<=0.0:
				serpent.tick+=0.75 if ClericSystem.has_talent(hero,"cleric_l18_2") else 1.0
				var targets:=ClericSystem.nearest_enemy_indices(host.pos,enemies,3 if ClericSystem.has_talent(hero,"cleric_l21_1") else 1)
				if not targets.is_empty():
					var serpent_damage:=deal_damage(hero,enemies[targets[0]],ClericSystem.scaled_amount(hero,float(ClericData.VALUES.w_attack)),"basic_ability","magical","Cloud Serpent");var serpent_heal:=cleric_heal(hero,host,float(ClericData.VALUES.w_heal),"Cloud Serpent");ClericSystem.telemetry_add(hero,"serpent_attacks");ClericSystem.telemetry_add(hero,"serpent_damage",float(serpent_damage.resolved_damage));ClericSystem.telemetry_add(hero,"serpent_healing",float(serpent_heal.effective_amount))
					for bounce_index in targets.slice(1):deal_damage(hero,enemies[bounce_index],ClericSystem.scaled_amount(hero,13.0),"basic_ability","magical","Lightning Serpent");cleric_heal(hero,host,10.0,"Lightning Serpent")
					ClericSystem.telemetry_add(hero,"serpent_bounces",maxi(0,targets.size()-1))
					if ClericSystem.has_talent(hero,"cleric_l24_3"):deal_healing(hero,host,float(host.max_hp)*0.005,"basic_ability","Blessings of Yu'lon")
					ClericSystem.reduce_mistweaver(hero,1.0)
				else:ClericSystem.telemetry_add(hero,"serpent_no_target")
			hero.cleric_runtime.serpents[serpent_index]=serpent
		if bool(hero.cleric_runtime.jug_active):
			hero.cleric_runtime.jug_remaining-=delta;hero.cleric_runtime.jug_tick_timer-=delta
			while float(hero.cleric_runtime.jug_tick_timer)<=0.0 and bool(hero.cleric_runtime.jug_active):
				hero.cleric_runtime.jug_tick_timer+=float(ClericData.VALUES.r1_tick);var targets:=ClericSystem.lowest_wounded_indices(heroes,2 if ClericSystem.has_talent(hero,"cleric_l27_r1") else 1,hero.pos,300.0,false)
				for target_index in targets:var jug_result:=cleric_heal(hero,heroes[target_index],float(ClericData.VALUES.r1_heal),"Jug of Healing","heroic");ClericSystem.telemetry_add(hero,"jug_healing",float(jug_result.effective_amount))
				hero.cleric_runtime.jug_completed_ticks+=1
				ClericSystem.telemetry_add(hero,"jug_ticks")
			if float(hero.cleric_runtime.jug_remaining)<=0.0:hero.ability_cds[3]=ClericSystem.stop_jug(hero);CombatRulesV1.restore_preserved_command(hero,true)
		for effect_index in range(hero.cleric_runtime.delayed_effects.size()-1,-1,-1):
			var effect:Dictionary=hero.cleric_runtime.delayed_effects[effect_index];effect.remaining-=delta
			if effect.remaining<=0.0:
				if not bool(effect.get("requires_cast",false)) or not hero.get("active_cast",{}).is_empty():cleric_water_dragon_impact(hero,str(effect.target_id),str(effect.kind)!="water_dragon_second")
				hero.cleric_runtime.delayed_effects.remove_at(effect_index)
			else:hero.cleric_runtime.delayed_effects[effect_index]=effect
