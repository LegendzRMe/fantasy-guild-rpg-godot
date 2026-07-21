extends "res://scripts/runtime/shared_combat_runtime.gd"

func item_feedback(text_value:String,position:Vector2,color:Color=C_GOLD)->void:
	if not is_testing_save():return
	item_feedback_feed.append(text_value)
	if item_feedback_feed.size()>5:item_feedback_feed.pop_front()
	add_effect("cast",position,position,text_value,color)

func current_damage_taken_multiplier(unit:Dictionary)->float:
	var multiplier:float=float(unit.get("damage_taken_multiplier",1.0))
	for effect in unit.get("active_effects",[]):
		if str(effect.get("id",""))=="vulnerable":multiplier*=float(effect.get("damage_taken_multiplier",1.15))
	return multiplier

func refresh_item_combat_stats(hero:Dictionary)->void:
	var soul_multiplier:float=1.0+float(hero.get("soul_furnace_stacks",0))*0.05
	var last_dawn_active:bool=false
	for shield_source in hero.get("shield_sources",[]):
		if str(shield_source.get("source_id",""))=="last_dawn" and float(shield_source.get("amount",0.0))>0:last_dawn_active=true;break
	hero.power=float(hero.get("base_power",hero.get("power",0.0)))*soul_multiplier*(1.5 if last_dawn_active else 1.0)
	hero.basic_action_amount=hero.power*float(hero.get("basic_action_power_ratio",1.0));hero.damage=hero.basic_action_amount
	if str(hero.get("basic_action_type","attack"))=="heal":hero.basic_heal_amount=hero.basic_action_amount
	var interval:float=float(hero.get("base_basic_action_interval",1.25))/maxf(0.1,1.0+float(hero.get("soul_furnace_stacks",0))*0.05)
	hero.basic_attack_interval=interval;hero.basic_heal_interval=interval

func apply_passive_trigger(owner:Dictionary,event:Dictionary,target:Dictionary)->void:
	for proc in CombatSystem.evaluate_passives(owner,event,owner.get("equipped_items",[]),ItemData.PASSIVE_EFFECTS,battle_time):
		var passive:Dictionary=proc.passive;var result:Dictionary=passive.effect_result;var passive_id:String=str(passive.id)
		match passive_id:
			"grace":
				var bonus:=CombatSystem.resolve_healing(owner,target,{"amount":float(result.get("amount",0.0)),"source_action":"basic_ability","can_crit":false})
				combat_events.append(CombatSystem.create_event("healing_done",owner,target,bonus,{"action_tags":["basic_ability"],"originating_effect_id":passive_id,"origin":proc.item_instance_id}))
				if bonus.effective_amount>0:add_effect("heal",owner.pos,target.pos,"+%d"%int(bonus.effective_amount),C_GREEN)
			"bloodletting":
				var stack:={"remaining_duration":4.0,"tick_timer":1.0,"amount":7.5,"source_unit":owner,"source_index":int(owner.get("battle_index",-1))}
				if not target.has("bloodletting_stacks"):target["bloodletting_stacks"]=[]
				if target.bloodletting_stacks.size()>=5:
					for stack_index in target.bloodletting_stacks.size():target.bloodletting_stacks[stack_index].remaining_duration=4.0
				else:target.bloodletting_stacks.append(stack)
				item_feedback("Bloodletting %d/5"%target.bloodletting_stacks.size(),target.pos,Color("d96a72"))
			"thunder_wake":
				for foe in enemies:
					if foe==target or foe.hp<=0 or foe.pos.distance_to(target.pos)>float(result.get("radius",145.0)):continue
					deal_damage(owner,foe,float(event.get("amount",0.0)),"basic_ability","magical","Thunder Wake",false,passive_id,[passive_id])
					foe.active_effects=CombatSystem.apply_named_effect(foe.get("active_effects",[]),{"id":"vulnerable","damage_taken_multiplier":1.15,"remaining_duration":4.0})
				item_feedback("Thunder Wake",target.pos,Color("70b9ff"))
			"last_dawn":
				var shield_amount:float=float(owner.max_hp)*0.75
				apply_unit_shield(owner,owner,shield_amount,"Last Dawn","last_dawn")
				refresh_item_combat_stats(owner);item_feedback("Last Dawn",owner.pos,C_GOLD)
			"overflowing_grace":
				var shield_amount:float=float(event.get("overhealing",0.0))*(2.0 if bool(event.get("critical",false)) and "direct" in event.get("action_tags",[]) else 1.0)
				var shield_cap:float=float(target.max_hp)*0.60
				var applied:=apply_unit_shield(owner,target,shield_amount,"Overflowing Grace","overflowing_grace",shield_cap)
				if float(applied.get("amount",0.0))>0:item_feedback("Overflowing Grace +%d"%int(applied.amount),target.pos,C_GREEN)
			"thousand_cuts":
				owner.thousand_cuts_count=int(owner.get("thousand_cuts_count",0))+1
				if owner.thousand_cuts_count>=3:
					owner.thousand_cuts_count=0;item_feedback("Thousand Cuts",target.pos,Color("e6b35f"))
					for extra_strike in 2:deal_damage(owner,target,float(owner.get("basic_action_amount",owner.get("damage",0.0)))*0.60,"basic_attack",str(event.get("damage_or_healing_type","physical")),"Thousand Cuts",false,passive_id,[passive_id])
			"retribution":
				owner.retribution_charges=CombatSystem.store_charge(owner.get("retribution_charges",[]),float(event.get("amount",0.0))*0.50,3)
				item_feedback("Retribution %d/3"%owner.retribution_charges.size(),owner.pos,Color("ef9e56"))

			"endless_momentum":
				owner.ability_cds=CombatSystem.reduce_cooldowns(owner.ability_cds,1.0,0.25)
				if hero_has_passive(owner,"twin_incantation"):
					for charge_index in owner.get("q_charge_timers",[]).size():owner.q_charge_timers[charge_index]=maxf(0.0,float(owner.q_charge_timers[charge_index])-1.0)
					owner.ability_cds[0]=0.0 if int(owner.get("q_charges",0))>0 else (float(owner.q_charge_timers[0]) if not owner.q_charge_timers.is_empty() else 0.0)
				item_feedback("Endless Momentum",owner.pos,Color("b381ff"))
			"soul_furnace":
				var defeated:Dictionary=event.target_unit;var gained:=1 if bool(defeated.get("summoned_unit",false)) else 5 if "boss" in defeated.get("combat_tags",[]) else 3 if "elite" in defeated.get("combat_tags",[]) or "heavy" in defeated.get("combat_tags",[]) else 1
				owner.soul_furnace_stacks=int(owner.get("soul_furnace_stacks",0))+gained;refresh_item_combat_stats(owner);item_feedback("Soul Furnace +%d"%gained,owner.pos,Color("d16ca8"))
			_:
				if str(result.get("category",""))=="buff":
					var named_effect:=result.duplicate(true);named_effect["remaining_duration"]=float(passive.get("duration",0.0));owner.active_effects=CombatSystem.apply_named_effect(owner.get("active_effects",[]),named_effect)

func deal_damage(source:Dictionary,target:Dictionary,amount:float,source_action:String,damage_type:String,origin=null,source_is_summon:bool=false,originating_effect_id:String="",trigger_chain:Array=[],can_crit_override=null)->Dictionary:
	var resolved_amount:=amount;var retribution_bonus:float=0.0
	if str(source.get("class",""))=="Cleric" and source_action=="basic_attack" and ClericSystem.has_talent(source,"cleric_l21_2") and CombatSystem.is_blinded(target):resolved_amount*=2.0
	var guardian_basic_result:={}
	if str(source.get("class",""))=="Guardian" and source_action=="basic_attack" and not source.get("guardian_runtime",{}).is_empty():
		guardian_basic_result=GuardianSystem.on_basic_attack(source,target,battle_time);resolved_amount*=float(guardian_basic_result.damage_multiplier);resolved_amount+=amount*float(guardian_basic_result.bonus_damage_multiplier)
	if source_action=="basic_attack":
		for effect_index in range(source.get("active_effects",[]).size()-1,-1,-1):
			var active_effect:Dictionary=source.active_effects[effect_index]
			if str(active_effect.get("consume_on",""))=="basic_attack":resolved_amount+=float(active_effect.get("amount",0.0));source.active_effects.remove_at(effect_index)
		if originating_effect_id!="retribution" and not source.get("retribution_charges",[]).is_empty():
			retribution_bonus=float(source.retribution_charges.pop_front().amount)
	var before_ratio:float=float(target.get("hp",0.0))/maxf(1.0,float(target.get("max_hp",1.0)))
	var damage_request:={"amount":resolved_amount,"source_action":source_action,"damage_type":damage_type,"damage_taken_multiplier":current_damage_taken_multiplier(target)}
	if str(target.get("class",""))=="Guardian" and not target.get("guardian_runtime",{}).is_empty():
		var armor_sources:Array=target.guardian_runtime.temporary_armor_sources.duplicate(true)
		if damage_type=="physical" and source_action=="basic_attack" and int(target.guardian_runtime.block_charges)>0:armor_sources.append({"id":"dwarf_block","armor":GuardianData.VALUES.block_armor,"damage_type":"physical","source_action":"basic_attack","remaining":1.0})
		damage_request["armor_sources"]=armor_sources
	elif str(target.get("class",""))=="Cleric" and not target.get("cleric_runtime",{}).is_empty():
		var cleric_armor:=ClericSystem.active_armor(target)
		if cleric_armor>0.0:damage_request["armor_sources"]=[{"id":"safety_sprint","armor":cleric_armor,"remaining":1.0}]
	if can_crit_override!=null:damage_request["can_crit"]=bool(can_crit_override)
	var result:=CombatSystem.resolve_damage(source,target,damage_request)
	if str(target.get("class",""))=="Guardian" and not target.get("guardian_runtime",{}).is_empty():
		var consumed:=GuardianSystem.consume_block(target,damage_type,source_action,float(result.raw_amount))
		if consumed:GuardianSystem.telemetry_add(target,"block_prevented",float(result.armor_prevented))
		elif float(result.armor_prevented)>0.0:GuardianSystem.telemetry_add(target,"temporary_armor_prevented",float(result.armor_prevented))
		if float(result.resolved_damage)>0.0:GuardianSystem.note_damage(target,float(result.resolved_damage))
		if source_action=="basic_attack" and float(result.resolved_damage)>0.0:
			var imposing_amount:=GuardianSystem.imposing_presence_amount(target,battle_time)
			if imposing_amount>0.0:CombatSystem.apply_control(source,"attack_speed",2.5,imposing_amount)
		var after_ratio:float=float(target.get("hp",0.0))/maxf(1.0,float(target.get("max_hp",1.0)))
		GuardianSystem.try_hardened_shield(target,before_ratio,after_ratio,float(result.resolved_damage),battle_time)
	if str(target.get("class",""))=="Cleric" and not target.get("cleric_runtime",{}).is_empty() and float(result.resolved_damage)>0.0:ClericSystem.note_hostile_damage(target,float(result.resolved_damage))
	if str(source.get("class",""))=="Cleric" and source_action=="basic_attack" and float(result.resolved_damage)>0.0:ClericSystem.reduce_mistweaver(source,1.0)
	if str(source.get("class",""))=="Cleric" and source_action=="basic_attack" and not source.get("cleric_runtime",{}).is_empty():ClericSystem.telemetry_add(source,"offensive_basic_attacks");if float(result.resolved_damage)>0.0:ClericSystem.telemetry_add(source,"offensive_basic_attack_hits")
	if not guardian_basic_result.is_empty() and float(guardian_basic_result.stun)>0.0:CombatSystem.apply_control(target,"stun",float(guardian_basic_result.stun))
	if testing_zone_active and "training" in target.get("combat_tags",[]) and float(result.get("resolved_damage",0.0))>0.0:target["seconds_since_damage"]=0.0
	var crossed_below_half:bool=before_ratio>0.50 and float(target.get("hp",0.0))/maxf(1.0,float(target.get("max_hp",1.0)))<0.50
	var context:={"source_action":source_action,"damage_type":damage_type,"action_tags":[source_action],"origin":origin,"source_is_summon":source_is_summon,"originating_effect_id":originating_effect_id,"trigger_chain":trigger_chain,"crossed_below_half":crossed_below_half}
	var events:=CombatSystem.event_bundle_for_damage(source,target,result,context);combat_events.append_array(events)
	for event in events:
		if event.event_type=="damage_taken":apply_passive_trigger(target,event,target)
		elif event.event_type in ["basic_attack_hit","direct_damage_dealt","periodic_damage_dealt","critical_result"]:apply_passive_trigger(source,event,target)
	var enemy_index:int=enemies.find(target);var source_index:int=int(source.get("battle_index",-1))
	if enemy_index>=0 and source_index>=0:add_damage_threat(target,source_index,float(result.get("resolved_damage",0.0)))
	var living_enemy_count:int=enemies.filter(func(enemy):return enemy.hp>0 and not bool(enemy.get("ignores_tank_aggro",false))).size()
	for absorption in result.get("shield_absorptions",[]):
		var creator_index:int=int(absorption.get("creator_index",-1))
		if creator_index>=0:
			var per_enemy:=CombatSystem.distributed_threat(CombatSystem.shield_absorption_threat(float(absorption.amount),float(heroes[creator_index].get("threat_modifier",1.0))),living_enemy_count)
			for enemy in enemies:if enemy.hp>0:add_enemy_threat(enemy,creator_index,per_enemy)
	if retribution_bonus>0.0 and target.hp>0:
		deal_damage(source,target,retribution_bonus,"summon","true","Retribution",false,"retribution",["retribution"]);item_feedback("Retribution %d"%int(retribution_bonus),target.pos,Color("ef9e56"))
	if bool(result.get("defeated",false)) and not bool(target.get("item_defeat_processed",false)):
		target["item_defeat_processed"]=true
		var defeat_event:=CombatSystem.create_event("unit_defeated",source,target,result,context)
		for hero in heroes:
			if hero.hp>0:apply_passive_trigger(hero,defeat_event,target)
			if str(hero.get("class",""))=="Guardian" and not hero.get("guardian_runtime",{}).is_empty():GuardianSystem.process_marked_death(hero,str(target.get("combat_id","")),battle_time);GuardianSystem.process_haymaker_death(hero,str(target.get("combat_id","")),battle_time)
	return result

func deal_healing(source:Dictionary,target:Dictionary,amount:float,source_action:String="basic_ability",origin=null,originating_effect_id:String="")->Dictionary:
	var incoming_multiplier:=1.0
	for hero in heroes:
		if str(hero.get("class",""))!="Cleric" or not ClericSystem.has_talent(hero,"cleric_l24_3"):continue
		if hero.get("cleric_runtime",{}).get("serpents",[]).any(func(serpent):return str(serpent.get("host_id",""))==str(target.get("combat_id",""))):incoming_multiplier=maxf(incoming_multiplier,1.10)
	var result:=CombatSystem.resolve_healing(source,target,{"amount":amount,"source_action":source_action,"incoming_multiplier":incoming_multiplier})
	var context:={"source_action":source_action,"action_tags":[source_action,"healing"],"origin":origin,"originating_effect_id":originating_effect_id};var events:=CombatSystem.event_bundle_for_healing(source,target,result,context);combat_events.append_array(events)
	for event in events:
		if event.event_type=="overhealing_done" or float(event.get("effective_amount",0.0))>0.0 and event.event_type in ["direct_healing_done","periodic_healing_done","critical_result"]:apply_passive_trigger(source,event,target)
	var source_index:int=int(source.get("battle_index",-1))
	if source_index>=0:add_healing_threat(source_index,float(result.get("effective_amount",0.0)))
	return result

func apply_unit_shield(source:Dictionary,target:Dictionary,amount:float,origin=null,source_id:String="shield",cap:float=INF)->Dictionary:
	var result:=CombatSystem.apply_shield(target,amount,{"creator_index":int(source.get("battle_index",-1)),"source_id":source_id,"origin":origin,"cap":cap,"source_action":"basic_ability"});var event:=CombatSystem.create_event("shield_applied",source,target,result,{"source_action":"basic_ability","action_tags":["basic_ability","shield"],"origin":origin});combat_events.append(event);return result

func update_timed_combat_effects(unit:Dictionary,delta:float)->void:
	for effect_index in range(unit.get("active_effects",[]).size()-1,-1,-1):
		var active_effect:Dictionary=unit.active_effects[effect_index]
		if float(active_effect.get("remaining_duration",0.0))<=0.0:continue
		active_effect.remaining_duration=float(active_effect.remaining_duration)-delta
		if active_effect.remaining_duration<=0.0:unit.active_effects.remove_at(effect_index)
		else:unit.active_effects[effect_index]=active_effect
	if not unit.has("bloodletting_stacks"):return
	for stack_index in range(unit.bloodletting_stacks.size()-1,-1,-1):
		var stack:Dictionary=unit.bloodletting_stacks[stack_index];stack.remaining_duration=float(stack.remaining_duration)-delta;stack.tick_timer=float(stack.tick_timer)-delta
		if stack.tick_timer<=0.0 and unit.hp>0:
			stack.tick_timer+=1.0
			var dot_source:Dictionary=stack.source_unit
			var dot_result:=deal_damage(dot_source,unit,float(stack.amount),"periodic","physical","Bloodletting",false,"bloodletting",["bloodletting"],true)
			if float(dot_result.get("resolved_damage",0.0))>0:add_effect("hit",dot_source.get("pos",unit.pos),unit.pos,"-%d"%int(dot_result.resolved_damage),Color("d96a72"))
		if stack.remaining_duration<=0.0:unit.bloodletting_stacks.remove_at(stack_index)
		else:unit.bloodletting_stacks[stack_index]=stack

func update_item_runtime(hero:Dictionary,delta:float)->void:

	refresh_item_combat_stats(hero)
	if hero_has_passive(hero,"borrowed_time") and not bool(hero.get("borrowed_time_armed",false)):
		hero.borrowed_time_timer=float(hero.get("borrowed_time_timer",0.0))+delta
		if hero.borrowed_time_timer>=8.0:hero.borrowed_time_timer=0.0;hero.borrowed_time_armed=true;item_feedback("Borrowed Time Ready",hero.pos,Color("b8d5ff"))
	if hero_has_passive(hero,"twin_incantation"):
		for charge_index in range(hero.q_charge_timers.size()-1,-1,-1):
			hero.q_charge_timers[charge_index]=float(hero.q_charge_timers[charge_index])-delta
			if hero.q_charge_timers[charge_index]<=0.0:hero.q_charge_timers.remove_at(charge_index);hero.q_charges=mini(2,int(hero.q_charges)+1)
		hero.ability_cds[0]=0.0 if int(hero.q_charges)>0 else (float(hero.q_charge_timers[0]) if not hero.q_charge_timers.is_empty() else 0.0)
	for repeat_index in range(hero.get("pending_repeats",[]).size()-1,-1,-1):
		var repeat:Dictionary=hero.pending_repeats[repeat_index];repeat.remaining=float(repeat.remaining)-delta
		if repeat.remaining<=0.0:
			hero.pending_repeats.remove_at(repeat_index)
			var old_selected:int=selected;var old_focused:int=focused_enemy_index;var old_target:int=int(hero.target);var old_heal_target:int=int(hero.heal_target)
			selected=int(hero.get("battle_index",0));focused_enemy_index=int(repeat.enemy_target);hero.target=int(repeat.assigned_target);hero.heal_target=int(repeat.ally_target)
			use_ability(int(repeat.slot),repeat.position,true)
			selected=old_selected;focused_enemy_index=old_focused;hero.target=old_target;hero.heal_target=old_heal_target
		else:hero.pending_repeats[repeat_index]=repeat

func add_enemy_threat(enemy:Dictionary,hero_index:int,amount:float) -> void:
	if amount<=0 or hero_index<0 or hero_index>=heroes.size() or bool(enemy.get("ignores_tank_aggro",false)):return
	var threat_table:Dictionary=enemy.get("threat",{})
	threat_table[hero_index]=float(threat_table.get(hero_index,0.0))+amount
	enemy.threat=threat_table

func add_damage_threat(enemy:Dictionary,hero_index:int,damage_dealt:float) -> void:
	if damage_dealt<=0:return
	add_enemy_threat(enemy,hero_index,damage_dealt*CombatSystem.DAMAGE_THREAT_RATIO*float(heroes[hero_index].get("threat_modifier",1.0)))

func add_healing_threat(healer_index:int,effective_healing:float) -> void:
	if effective_healing<=0:return
	var living_count:int=enemies.filter(func(enemy):return enemy.hp>0 and not bool(enemy.get("ignores_tank_aggro",false))).size()
	var per_enemy:float=CombatSystem.distributed_threat(effective_healing*CombatSystem.HEALING_THREAT_RATIO*float(heroes[healer_index].get("threat_modifier",1.0)),living_count)
	for enemy in enemies:
		if enemy.hp>0:add_enemy_threat(enemy,healer_index,per_enemy)
