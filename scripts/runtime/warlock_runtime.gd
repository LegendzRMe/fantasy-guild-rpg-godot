extends "res://scripts/runtime/mage_runtime.gd"

func warlock_visual(kind:String, from:Vector2, to:Vector2, duration:float, text_value:String="", extra:Dictionary={}) -> void:
	var effect:={"kind":kind,"from":from,"to":to,"text":text_value,"color":CLASSES.Warlock.color,"life":maxf(0.08,duration),"max_life":maxf(0.08,duration)}
	effect.merge(extra,true);effects.append(effect)

func warlock_damage(hero:Dictionary, target:Dictionary, amount:float, action:String, origin:String, can_crit=true) -> Dictionary:
	var result:=deal_damage(hero,target,amount,action,"magical",origin,false,"",[],can_crit)
	WarlockSystem.record_owned_damage(hero,float(result.get("resolved_damage",0.0)))
	return result

func warlock_clamped_point(hero:Dictionary, point:Vector2, range_limit:float) -> Vector2:
	var direction:=Vector2(hero.pos).direction_to(point)
	if direction==Vector2.ZERO:direction=Vector2(hero.get("facing_direction",Vector2.RIGHT))
	return (Vector2(hero.pos)+direction*minf(range_limit,Vector2(hero.pos).distance_to(point))).clamp(Vector2(55,70),Vector2(1225,620))

func warlock_targets_in_expanding_wave(hero:Dictionary, point:Vector2) -> Array:
	var direction:=Vector2(hero.pos).direction_to(point)
	if direction==Vector2.ZERO:direction=Vector2(hero.get("facing_direction",Vector2.RIGHT))
	var result:Array=[];var range_limit:=float(WarlockData.SPACE.q_range)
	var area_multiplier:=1.33 if bool(hero.warlock_runtime.pursuit_complete) else 1.0
	for foe in enemies:
		if foe.hp<=0:continue
		var offset:Vector2=foe.pos-hero.pos;var projection:=offset.dot(direction)
		if projection<0.0 or projection>range_limit:continue
		var progress:=projection/maxf(1.0,range_limit)
		var radius:=lerpf(float(WarlockData.SPACE.q_start_radius),float(WarlockData.SPACE.q_end_radius),progress)*area_multiplier
		if absf(offset.cross(direction))<=radius and CombatGeometry.first_blocker(hero.pos,foe.pos,combat_blockers,"blocks_projectiles")<0:
			result.append(foe)
	result.sort_custom(func(a,b):return a.pos.distance_squared_to(hero.pos)<b.pos.distance_squared_to(hero.pos))
	return result

func cast_warlock_q(hero:Dictionary, point:Vector2, item_repeat:bool=false) -> bool:
	if not item_repeat and float(hero.ability_cds[0])>0.0:return false
	var direction:=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var hits:=warlock_targets_in_expanding_wave(hero,point);var qualifying:=hits.filter(func(target):return WarlockSystem.qualifying_target(target))
	var rampant_before:=int(hero.warlock_runtime.rampant_stacks)
	var amount:=WarlockSystem.scaled_amount(hero,float(WarlockData.VALUES.q_damage),true)*(1.0+0.12*rampant_before)
	for target in hits:
		var travel_fraction:=clampf(Vector2(target.pos).distance_to(hero.pos)/maxf(1.0,float(WarlockData.SPACE.q_range)),0.0,1.0)
		hero.warlock_runtime.delayed_effects.append({"kind":"fel_flame_hit","remaining":maxf(0.01,float(WarlockData.SPACE.q_travel_time)*travel_fraction),"target_id":str(target.combat_id),"amount":amount})
	WarlockSystem.telemetry_add(hero,"q_casts");WarlockSystem.telemetry_add(hero,"q_hits",hits.size());WarlockSystem.telemetry_add(hero,"q_distinct_hits",qualifying.size())
	if WarlockSystem.has_talent(hero,"warlock_l9_1") and not bool(hero.warlock_runtime.pursuit_complete):
		hero.warlock_runtime.pursuit_progress=mini(int(WarlockData.VALUES.pursuit_requirement),int(hero.warlock_runtime.pursuit_progress)+qualifying.size())
		hero.warlock_runtime.pursuit_complete=int(hero.warlock_runtime.pursuit_progress)>=int(WarlockData.VALUES.pursuit_requirement)
		WarlockSystem.telemetry_add(hero,"pursuit_progress",qualifying.size())
	if WarlockSystem.has_talent(hero,"warlock_l18_1"):
		hero.ability_cds[2]=maxf(0.0,float(hero.ability_cds[2])-1.75*qualifying.size())
	if WarlockSystem.has_talent(hero,"warlock_l21_1") and not qualifying.is_empty():
		hero.warlock_runtime.fel_armor_stacks=int(hero.warlock_runtime.fel_armor_stacks)+qualifying.size();hero.warlock_runtime.fel_armor_remaining=float(WarlockData.VALUES.fel_armor_duration)
	if WarlockSystem.has_talent(hero,"warlock_l24_1") and not qualifying.is_empty():
		hero.warlock_runtime.rampant_stacks=mini(5,int(hero.warlock_runtime.rampant_stacks)+1);hero.warlock_runtime.rampant_remaining=5.0
	if not item_repeat:hero.ability_cds[0]=WarlockSystem.modified_base_cooldown(hero,0)
	warlock_visual("warlock_fel_flame",hero.pos,hero.pos+direction*float(WarlockData.SPACE.q_range),float(WarlockData.SPACE.q_travel_time),"",{"start_radius":float(WarlockData.SPACE.q_start_radius),"end_radius":float(WarlockData.SPACE.q_end_radius)*(1.33 if bool(hero.warlock_runtime.pursuit_complete) else 1.0)})
	return true

func cast_warlock_w(hero:Dictionary) -> bool:
	if float(hero.ability_cds[1])>0.0 or not hero.get("active_channel",{}).is_empty():return false
	var target_index:=combat_enemy_target();if target_index<0 or target_index>=enemies.size():return false
	var target:Dictionary=enemies[target_index];var cast_range:=float(WarlockData.SPACE.w_cast_range)*(1.25 if WarlockSystem.has_talent(hero,"warlock_l9_2") else 1.0)
	if hero.pos.distance_to(target.pos)>cast_range or not CombatGeometry.has_line_of_sight(hero.pos,target.pos,combat_blockers):return false
	CombatRulesV1.preserve_command(hero);hero.command_state=CombatRulesV1.CommandState.CHANNEL
	hero.active_channel={"slot":1,"remaining":float(WarlockData.VALUES.w_duration),"duration":float(WarlockData.VALUES.w_duration),"target_id":str(target.combat_id),"tick_remaining":0.0,"requires_line_of_sight":true,"background":WarlockSystem.has_talent(hero,"warlock_l30_3"),"successful":false}
	hero.ability_cds[1]=WarlockSystem.modified_base_cooldown(hero,1);WarlockSystem.telemetry_add(hero,"w_started");return true

func corruption_burst_targets(hero:Dictionary, center:Vector2) -> Array:
	return enemies.filter(func(foe):return foe.hp>0 and foe.pos.distance_to(center)<=float(WarlockData.SPACE.e_burst_radius) and CombatGeometry.first_blocker(hero.pos,foe.pos,combat_blockers,"blocks_projectiles")<0)

func cast_warlock_e(hero:Dictionary, point:Vector2, item_repeat:bool=false) -> bool:
	if not item_repeat and float(hero.ability_cds[2])>0.0:return false
	var direction:=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var cast_id:="corruption:%s:%d"%[str(hero.combat_id),int(hero.warlock_runtime.next_cast_id)];hero.warlock_runtime.next_cast_id=int(hero.warlock_runtime.next_cast_id)+1
	var sequence:Array=[1,2,3];if bool(hero.warlock_runtime.echoed_complete):sequence.append_array([2,1,0])
	for sequence_index in sequence.size():
		var step:int=int(sequence[sequence_index]);var center:=Vector2(hero.pos)+direction*float(WarlockData.SPACE.e_burst_spacing)*step
		hero.warlock_runtime.delayed_effects.append({"kind":"corruption_burst","remaining":float(WarlockData.SPACE.e_burst_delay)*sequence_index,"center":center,"cast_id":cast_id,"reverse":sequence_index>=3,"burst_number":sequence_index+1})
		warlock_visual("warlock_corruption_warning",center,center,maxf(0.12,float(WarlockData.SPACE.e_burst_delay)*sequence_index),"",{"radius":float(WarlockData.SPACE.e_burst_radius)})
	if not item_repeat:hero.ability_cds[2]=WarlockSystem.modified_base_cooldown(hero,2)
	WarlockSystem.telemetry_add(hero,"e_casts");return true

func cast_warlock_horrify(hero:Dictionary, point:Vector2) -> bool:
	if float(hero.ability_cds[3])>0.0:return false
	var center:=warlock_clamped_point(hero,point,float(WarlockData.SPACE.horrify_range))
	begin_unit_cast(hero,3,float(WarlockData.VALUES.r1_cast_delay),true,0.0,false,WarlockSystem.modified_base_cooldown(hero,3))
	hero.warlock_runtime.delayed_effects.append({"kind":"horrify","remaining":float(WarlockData.VALUES.r1_cast_delay),"center":center,"requires_cast":true})
	warlock_visual("warlock_horrify_warning",center,center,float(WarlockData.VALUES.r1_cast_delay),"",{"radius":float(WarlockData.SPACE.horrify_radius)});WarlockSystem.telemetry_add(hero,"horrify_casts");return true

func cast_warlock_rain(hero:Dictionary) -> bool:
	if float(hero.ability_cds[3])>0.0:return false
	begin_unit_cast(hero,3,float(WarlockData.VALUES.r2_cast_time),true,0.0,false,WarlockSystem.modified_base_cooldown(hero,3))
	hero.warlock_runtime.delayed_effects.append({"kind":"rain_release","remaining":float(WarlockData.VALUES.r2_cast_time),"requires_cast":true})
	WarlockSystem.telemetry_add(hero,"rain_casts");return true

func cast_warlock_heroic(hero:Dictionary, point:Vector2) -> bool:
	return cast_warlock_horrify(hero,point) if str(hero.get("selected_heroic_id",""))=="warlock_l15_r1" else cast_warlock_rain(hero) if str(hero.get("selected_heroic_id",""))=="warlock_l15_r2" else false

func warlock_foreground_allowed(hero:Dictionary, slot:int) -> bool:
	if hero.get("active_channel",{}).is_empty():return true
	return bool(hero.active_channel.get("background",false)) and slot in [0,2,3] and not bool(hero.warlock_runtime.foreground_action_active)

func cast_warlock_ability(slot:int, point:Vector2, item_repeat:bool=false) -> bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected]
	if str(hero.get("class",""))!="Warlock" or hero.get("warlock_runtime",{}).is_empty() or not warlock_foreground_allowed(hero,slot):return false
	var background:bool=not hero.get("active_channel",{}).is_empty()
	if background:hero.warlock_runtime.foreground_action_active=true
	var succeeded:=cast_warlock_q(hero,point,item_repeat) if slot==0 else cast_warlock_w(hero) if slot==1 else cast_warlock_e(hero,point,item_repeat) if slot==2 else cast_warlock_heroic(hero,point)
	if background:hero.warlock_runtime.foreground_action_active=false;if succeeded:WarlockSystem.telemetry_add(hero,"soul_conduit_foreground")
	return succeeded

func use_warlock_trait(hero:Dictionary) -> bool:
	var result:=WarlockSystem.use_life_tap(hero)
	if not bool(result.get("valid",false)):return false
	warlock_visual("warlock_life_tap",hero.pos,hero.pos,0.4,"",{"free":bool(result.free)});return true

func resolve_corruption_burst(hero:Dictionary, effect:Dictionary) -> void:
	var targets:=corruption_burst_targets(hero,Vector2(effect.center))
	for target in targets:
		WarlockSystem.apply_corruption(hero,target,str(effect.cast_id));WarlockSystem.telemetry_add(hero,"e_reverse_hits" if bool(effect.reverse) else "e_forward_hits");WarlockSystem.telemetry_add(hero,"e_applications")
		if WarlockSystem.has_talent(hero,"warlock_l9_3"):
			hero.warlock_runtime.echoed_progress=mini(int(WarlockData.VALUES.echoed_mythic_requirement),int(hero.warlock_runtime.echoed_progress)+1)
			hero.warlock_runtime.echoed_complete=int(hero.warlock_runtime.echoed_progress)>=int(WarlockData.VALUES.echoed_requirement)
			hero.warlock_runtime.echoed_mythic=int(hero.warlock_runtime.echoed_progress)>=int(WarlockData.VALUES.echoed_mythic_requirement)
		if WarlockSystem.has_talent(hero,"warlock_l24_2") and int(effect.burst_number) in [3,6]:
			warlock_damage(hero,target,WarlockSystem.scaled_amount(hero,217.8),"basic_ability","Ruinous Affliction",false)
	warlock_visual("warlock_corruption_impact",Vector2(effect.center),Vector2(effect.center),0.4,"",{"radius":float(WarlockData.SPACE.e_burst_radius)})

func resolve_horrify(hero:Dictionary, effect:Dictionary) -> void:
	for target in enemies:
		if target.hp<=0 or target.pos.distance_to(Vector2(effect.center))>float(WarlockData.SPACE.horrify_radius):continue
		warlock_damage(hero,target,WarlockSystem.scaled_amount(hero,float(WarlockData.VALUES.r1_damage),false,false),"heroic","Horrify")
		var duration:=float(WarlockData.VALUES.r1_fear_duration)+(1.0 if WarlockSystem.has_talent(hero,"warlock_l27_r1") else 0.0)
		var fear:=CombatSystem.apply_control(target,"fear",duration)
		if bool(fear.applied):
			target["fear_origin"]=Vector2(effect.center);CombatSystem.apply_control(target,"silence",float(fear.duration));WarlockSystem.telemetry_add(hero,"successful_fears")
			if WarlockSystem.has_talent(hero,"warlock_l27_r1"):target.active_effects=CombatSystem.apply_named_effect(target.active_effects,{"id":"warlock_haunt","remaining_duration":float(fear.duration),"damage_taken_multiplier":1.20})
		else:WarlockSystem.telemetry_add(hero,"fear_immune")
		WarlockSystem.telemetry_add(hero,"horrify_hits")
	warlock_visual("warlock_horrify_impact",Vector2(effect.center),Vector2(effect.center),0.6,"",{"radius":float(WarlockData.SPACE.horrify_radius)})

func start_rain(hero:Dictionary) -> void:
	var seed_value:=int(battle_time*1000.0)+int(hero.get("battle_index",0))*7919
	hero.warlock_runtime.rain_effects.append({"remaining":float(WarlockData.VALUES.r2_duration),"meteor_timer":0.0,"meteors_left":int(WarlockData.VALUES.r2_meteor_count),"seed":seed_value,"recent_targets":{}})

func choose_rain_position(hero:Dictionary, rain:Dictionary, meteor_index:int) -> Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=int(rain.seed)+meteor_index*104729
	var targeted:=WarlockSystem.has_talent(hero,"warlock_l27_r2") and rng.randf()<float(WarlockData.VALUES.deep_impact_targeted_ratio)
	var living:=enemies.filter(func(enemy):return enemy.hp>0)
	if targeted and not living.is_empty():
		living.sort_custom(func(a,b):return int(rain.recent_targets.get(str(a.combat_id),0))<int(rain.recent_targets.get(str(b.combat_id),0)))
		var chosen:Dictionary=living[rng.randi_range(0,mini(2,living.size()-1))];rain.recent_targets[str(chosen.combat_id)]=int(rain.recent_targets.get(str(chosen.combat_id),0))+1
		return {"position":Vector2(chosen.pos),"targeted":true}
	return {"position":Vector2(rng.randf_range(80.0,1200.0),rng.randf_range(90.0,590.0)),"targeted":false}

func update_rain(hero:Dictionary, delta:float) -> void:
	for rain_index in range(hero.warlock_runtime.rain_effects.size()-1,-1,-1):
		var rain:Dictionary=hero.warlock_runtime.rain_effects[rain_index];rain.remaining=float(rain.remaining)-delta;rain.meteor_timer=float(rain.meteor_timer)-delta
		while float(rain.meteor_timer)<=0.0 and int(rain.meteors_left)>0:
			var meteor_number:=int(WarlockData.VALUES.r2_meteor_count)-int(rain.meteors_left);var chosen:=choose_rain_position(hero,rain,meteor_number)
			hero.warlock_runtime.delayed_effects.append({"kind":"rain_impact","remaining":float(WarlockData.VALUES.r2_warning_time),"center":chosen.position,"targeted":chosen.targeted})
			warlock_visual("warlock_rain_warning",chosen.position,chosen.position,float(WarlockData.VALUES.r2_warning_time),"",{"radius":float(WarlockData.SPACE.rain_impact_radius)*(float(WarlockData.VALUES.deep_impact_radius_multiplier) if WarlockSystem.has_talent(hero,"warlock_l27_r2") else 1.0)})
			rain.meteors_left=int(rain.meteors_left)-1;rain.meteor_timer=float(rain.meteor_timer)+float(WarlockData.VALUES.r2_meteor_interval);WarlockSystem.telemetry_add(hero,"rain_meteors");WarlockSystem.telemetry_add(hero,"rain_targeted" if bool(chosen.targeted) else "rain_random")
		if float(rain.remaining)<=0.0 and int(rain.meteors_left)<=0:hero.warlock_runtime.rain_effects.remove_at(rain_index)
		else:hero.warlock_runtime.rain_effects[rain_index]=rain

func resolve_rain_impact(hero:Dictionary, effect:Dictionary) -> void:
	var radius:=float(WarlockData.SPACE.rain_impact_radius)*(float(WarlockData.VALUES.deep_impact_radius_multiplier) if WarlockSystem.has_talent(hero,"warlock_l27_r2") else 1.0)
	for target in enemies:
		if target.hp<=0 or target.pos.distance_to(Vector2(effect.center))>radius:continue
		warlock_damage(hero,target,WarlockSystem.scaled_amount(hero,float(WarlockData.VALUES.r2_meteor_damage),false,false),"heroic","Rain of Destruction");WarlockSystem.telemetry_add(hero,"rain_hits")
		if WarlockSystem.has_talent(hero,"warlock_l27_r2"):CombatSystem.apply_control(target,"slow",float(WarlockData.VALUES.deep_impact_slow_duration),float(WarlockData.VALUES.deep_impact_slow_percent))
	warlock_visual("warlock_rain_impact",Vector2(effect.center),Vector2(effect.center),0.55,"",{"radius":radius})

func update_warlock_channel(hero:Dictionary, delta:float) -> void:
	if hero.get("active_channel",{}).is_empty() or int(hero.active_channel.get("slot",-1))!=1:return
	var channel:Dictionary=hero.active_channel;var target=unit_by_combat_id(str(channel.target_id));var break_range:=float(WarlockData.SPACE.w_break_range)*(1.25 if WarlockSystem.has_talent(hero,"warlock_l9_2") else 1.0)
	if target==null or target.hp<=0.0:
		if target!=null and target.hp<=0.0:
			channel.successful=true;WarlockSystem.telemetry_add(hero,"w_target_deaths")
			if WarlockSystem.has_talent(hero,"warlock_l12_1"):hero.ability_cds[1]=0.0
		finish_warlock_channel(hero,channel,"target_death" if bool(channel.successful) else "invalid");return
	if hero.pos.distance_to(target.pos)>break_range:finish_warlock_channel(hero,channel,"range");return
	if not CombatGeometry.has_line_of_sight(hero.pos,target.pos,combat_blockers):finish_warlock_channel(hero,channel,"line_of_sight");return
	channel.remaining=float(channel.remaining)-delta;channel.tick_remaining=float(channel.tick_remaining)-delta
	while float(channel.tick_remaining)<=0.0 and float(channel.remaining)>=0.0 and target.hp>0.0:
		channel.tick_remaining=float(channel.tick_remaining)+float(WarlockData.VALUES.w_tick_interval)
		var damage_per_tick:=WarlockSystem.scaled_amount(hero,float(WarlockData.VALUES.w_damage_per_second)*float(WarlockData.VALUES.w_tick_interval))*(1.5 if WarlockSystem.has_talent(hero,"warlock_l18_2") else 1.0)
		var damage:=warlock_damage(hero,target,damage_per_tick,"basic_ability","Drain Life",false)
		var heal_per_tick:=WarlockSystem.scaled_amount(hero,float(WarlockData.VALUES.w_healing_per_second)*float(WarlockData.VALUES.w_tick_interval))*(1.75 if WarlockSystem.has_talent(hero,"warlock_l21_2") else 1.0)
		var healing:=deal_healing(hero,hero,heal_per_tick,"basic_ability","Drain Life")
		WarlockSystem.telemetry_add(hero,"w_ticks");WarlockSystem.telemetry_add(hero,"w_damage",float(damage.resolved_damage));WarlockSystem.telemetry_add(hero,"w_raw_healing",float(healing.amount));WarlockSystem.telemetry_add(hero,"w_actual_healing",float(healing.effective_amount));WarlockSystem.telemetry_add(hero,"w_overhealing",float(healing.overhealing))
		if WarlockSystem.has_talent(hero,"warlock_l18_2"):CombatSystem.apply_control(target,"slow",0.35,0.40)
		if target.hp<=0.0:channel.successful=true;WarlockSystem.telemetry_add(hero,"w_target_deaths");if WarlockSystem.has_talent(hero,"warlock_l12_1"):hero.ability_cds[1]=0.0;break
	warlock_visual("warlock_drain_tether",hero.pos,target.pos,0.08)
	if float(channel.remaining)<=0.0 or target.hp<=0.0:
		channel.successful=true;finish_warlock_channel(hero,channel,"complete")
	else:hero.active_channel=channel

func finish_warlock_channel(hero:Dictionary, channel:Dictionary, reason:String) -> void:
	var successful:=bool(channel.get("successful",false)) or reason in ["complete","target_death"]
	hero.active_channel={};CombatRulesV1.restore_preserved_command(hero,target_is_valid_for(hero,unit_by_combat_id(str(hero.get("preserved_target_id",""))),str(hero.get("preserved_target_kind",""))))
	if successful:
		WarlockSystem.telemetry_add(hero,"w_completed")
		if WarlockSystem.has_talent(hero,"warlock_l9_2"):
			hero.warlock_runtime.chaotic_progress=mini(int(WarlockData.VALUES.chaotic_energy_requirement),int(hero.warlock_runtime.chaotic_progress)+1)
			var was_complete:=bool(hero.warlock_runtime.chaotic_complete);hero.warlock_runtime.chaotic_complete=int(hero.warlock_runtime.chaotic_progress)>=int(WarlockData.VALUES.chaotic_energy_requirement)
			if was_complete:WarlockSystem.reduce_eligible_cooldowns(hero,0.10,"chaotic",false)
	else:WarlockSystem.telemetry_reason(hero,"w_interruptions",reason)

func update_warlock_periodic(hero:Dictionary, delta:float) -> void:
	for index in range(hero.warlock_runtime.periodic_effects.size()-1,-1,-1):
		var instance:=PeriodicStatusSystem.advance(hero.warlock_runtime.periodic_effects[index],delta);var target=unit_by_combat_id(str(instance.target_id))
		for due_tick in int(instance.due_ticks):
			if target==null or target.hp<=0.0:break
			var tick_count:=int(round(float(WarlockData.VALUES.e_duration)/float(WarlockData.VALUES.e_tick_interval)))
			var damage:=warlock_damage(hero,target,WarlockSystem.scaled_amount(hero,float(WarlockData.VALUES.e_damage),true)/maxi(1,tick_count),"periodic","Corruption",false)
			WarlockSystem.telemetry_add(hero,"e_ticks");WarlockSystem.telemetry_add(hero,"e_damage",float(damage.resolved_damage))
			if bool(hero.warlock_runtime.echoed_mythic) and float(damage.resolved_damage)>0.0:
				var healing:=deal_healing(hero,hero,float(damage.resolved_damage),"basic_ability","Echoed Corruption");WarlockSystem.telemetry_add(hero,"e_mythic_healing",float(healing.effective_amount))
		if bool(instance.expired) or target==null or target.hp<=0.0:hero.warlock_runtime.periodic_effects.remove_at(index)
		else:hero.warlock_runtime.periodic_effects[index]=instance

func update_warlock_runtime(delta:float) -> void:
	for hero in heroes:
		if str(hero.get("class",""))!="Warlock" or hero.get("warlock_runtime",{}).is_empty():continue
		var banished_before:=float(hero.warlock_runtime.banished_remaining)
		WarlockSystem.update(hero,delta)
		if banished_before>0.0 and float(hero.warlock_runtime.banished_remaining)<=0.0:
			hero.incapacitated=false;hero.hp=maxf(float(hero.hp),float(hero.max_hp)*float(WarlockData.VALUES.demonic_circle_return_health_percent))
			var nearest_ally=null;var nearest_distance:=INF
			for ally in heroes:
				if ally==hero or ally.hp<=0.0 or bool(ally.get("incapacitated",false)):continue
				var ally_distance:float=hero.pos.distance_squared_to(ally.pos)
				if ally_distance<nearest_distance:nearest_distance=ally_distance;nearest_ally=ally
			if nearest_ally!=null:hero.pos=CombatGeometry.move_toward_safe(nearest_ally.pos,nearest_ally.pos+Vector2(58,0),58.0,42.0,combat_blockers)
			clear_hero_command(hero,"demonic circle return")
		update_warlock_channel(hero,delta);update_warlock_periodic(hero,delta);update_rain(hero,delta)
		for effect_index in range(hero.warlock_runtime.delayed_effects.size()-1,-1,-1):
			var effect:Dictionary=hero.warlock_runtime.delayed_effects[effect_index];effect.remaining=float(effect.remaining)-delta
			if float(effect.remaining)>0.0:hero.warlock_runtime.delayed_effects[effect_index]=effect;continue
			match str(effect.kind):
				"fel_flame_hit":
					var fel_target=unit_by_combat_id(str(effect.target_id))
					if fel_target!=null and fel_target.hp>0.0:
						var consume_qualifying:=WarlockSystem.qualifying_target(fel_target);var fel_damage:=warlock_damage(hero,fel_target,float(effect.amount),"basic_ability","Fel Flame")
						if bool(fel_damage.get("defeated",false)) and consume_qualifying and WarlockSystem.has_talent(hero,"warlock_l12_3"):
							var consume:Dictionary=hero.warlock_runtime.internal_cooldowns.consume_soul
							if float(consume.remaining)<=0.0:
								deal_healing(hero,hero,WarlockSystem.scaled_amount(hero,float(WarlockData.VALUES.consume_soul_healing),false,false),"basic_ability","Consume Soul");consume.remaining=float(consume.modified_base)
				"corruption_burst":resolve_corruption_burst(hero,effect)
				"horrify":
					if hero.get("active_cast",{}).is_empty():pass
					else:resolve_horrify(hero,effect)
				"rain_release":
					if not hero.get("active_cast",{}).is_empty():start_rain(hero)
				"rain_impact":resolve_rain_impact(hero,effect)
			hero.warlock_runtime.delayed_effects.remove_at(effect_index)
