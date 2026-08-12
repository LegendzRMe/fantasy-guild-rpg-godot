extends "res://scripts/runtime/priest_runtime.gd"

func shaman_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Shaman.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func shaman_damage(hero:Dictionary,target:Dictionary,amount:float,origin:String,effect_id:String,action:String="basic_ability",source_tag:String="")->Dictionary:
	# Alpha Wolf is applied once by the shared damage pipeline so every Shaman
	# damage origin follows the same modifier order.
	var result:=deal_damage(hero,target,amount,action,"magical" if action!="basic_attack" else "physical",origin,false,effect_id,[source_tag] if source_tag!="" else [],true)
	if ShamanSystem.successful(result) and action!="basic_attack":
		resolve_shaman_frostwolf(hero,1)
	var ancestral_healing:=ShamanSystem.note_damage(hero,float(result.get("resolved_damage",0.0)))
	if ancestral_healing>0.0:
		var heal:=deal_healing(hero,hero,ancestral_healing,"basic_heal","Ancestral Wrath","shaman_ancestral_wrath");ShamanSystem.telemetry_add(hero,"ancestral_healing",float(heal.effective_amount))
	return result

func resolve_shaman_frostwolf(hero:Dictionary,stacks:int)->void:
	for activation in ShamanSystem.add_frostwolf_stacks(hero,stacks,float(hero.hp)):
		var healing:=deal_healing(hero,hero,float(activation.raw_healing),"basic_heal","Frostwolf Resilience","shaman_trait")
		ShamanSystem.telemetry_add(hero,"frostwolf_healing",float(healing.effective_amount));ShamanSystem.telemetry_add(hero,"frostwolf_overhealing",float(healing.overhealing))
		var shield_request:=ShamanSystem.overflow_shield_request(hero,activation,healing)
		if not shield_request.is_empty():
			var existing:=named_shield_amount(hero,str(shield_request.source_id));var room:=maxf(0.0,float(shield_request.cap)-existing);var applied:=apply_unit_shield(hero,hero,minf(room,float(shield_request.amount)),"Overflowing Resilience",str(shield_request.source_id),float(shield_request.cap),float(shield_request.duration));ShamanSystem.telemetry_add(hero,"overflow_shield",float(applied.get("amount",0.0)))

func shaman_enemy_target(hero:Dictionary,max_range:float=INF):
	var index:=combat_enemy_target();if index<0 or index>=enemies.size():return null
	var target:Dictionary=enemies[index];if target.hp<=0.0 or hero.pos.distance_to(target.pos)>max_range:return null
	return target

func deterministic_chain_targets(hero:Dictionary,primary:Dictionary,allow_repeats:bool=false,extra_fork:bool=false)->Array:
	var sequence:Array=[primary];var current:Dictionary=primary;var used:Dictionary={str(primary.combat_id):true};var stages:=int(ShamanData.VALUES.q_bounces)
	for stage in stages:
		var candidates:=enemies.filter(func(enemy):return enemy.hp>0.0 and enemy!=current and current.pos.distance_to(enemy.pos)<=float(ShamanData.SPACE.q_bounce_radius) and (allow_repeats or not used.has(str(enemy.combat_id))))
		candidates.sort_custom(func(a,b):var da:float=current.pos.distance_squared_to(a.pos);var db:float=current.pos.distance_squared_to(b.pos);return str(a.combat_id)<str(b.combat_id) if is_equal_approx(da,db) else da<db)
		if candidates.is_empty():break
		current=candidates[0];sequence.append(current);used[str(current.combat_id)]=true
		if extra_fork and candidates.size()>1:sequence.append(candidates[1]);used[str(candidates[1].combat_id)]=true;ShamanSystem.telemetry_add(hero,"q_forks")
	return sequence

func resolve_shaman_chain(hero:Dictionary,primary:Dictionary,source_tag:String="player_chain",effectiveness:float=1.0)->Dictionary:
	var repeat_mythic:=ShamanSystem.has_talent(hero,"shaman_l9_1") and ShamanSystem.mastery_unlocked(hero,"shaman_l9_1",int(ShamanData.VALUES.echo_mythic))
	var sequence:=deterministic_chain_targets(hero,primary,repeat_mythic,repeat_mythic);var qualifying_ids:Array=[];var quest_ids:Array=[];var final_target:Dictionary=primary;var gathering:=ShamanSystem.gathering_snapshot(hero) if source_tag=="player_chain" else 1.0
	var thunder_bonus:=float(ShamanData.VALUES.thunder_max_damage) if ShamanSystem.has_talent(hero,"shaman_l24_2") and int(hero.shaman_runtime.thunder_stacks)>=int(ShamanData.VALUES.thunder_max) else 0.0;var cast_damage:=0.0
	for hit_index in sequence.size():
		var target:Dictionary=sequence[hit_index];var amount:=ShamanSystem.ability_amount(hero,float(ShamanData.VALUES.q_initial if hit_index==0 else ShamanData.VALUES.q_bounce))
		if hit_index>0:amount+=ShamanSystem.chain_bounce_bonus(hero)
		var result:=shaman_damage(hero,target,amount*gathering*effectiveness*(1.0+thunder_bonus),"Stormcaller" if source_tag=="stormcaller_chain" else "Chain Lightning","shaman_q","basic_ability",source_tag)
		if ShamanSystem.successful(result):
			cast_damage+=float(result.resolved_damage)
			final_target=target;qualifying_ids.append(str(target.combat_id));if TargetCategorySystem.qualifies_quest(target):quest_ids.append(str(target.combat_id));ShamanSystem.mark_rolling(hero,str(target.combat_id));ShamanSystem.telemetry_add(hero,"stormcaller_hits" if source_tag=="stormcaller_chain" else "q_hits");if hit_index>0:ShamanSystem.telemetry_add(hero,"q_bounces")
			if source_tag=="player_chain" and ShamanSystem.has_talent(hero,"shaman_l9_1"):hero.shaman_runtime.echo_assists[str(target.combat_id)]=float(ShamanData.VALUES.q_kill_window)
			if hit_index==0 and ShamanSystem.has_talent(hero,"shaman_l24_2"):CombatSystem.apply_control(target,"slow",float(ShamanData.VALUES.thunder_duration),minf(0.95,int(hero.shaman_runtime.thunder_stacks)*float(ShamanData.VALUES.thunder_slow_per_stack)))
		shaman_visual("shaman_chain",hero.pos if hit_index==0 else sequence[hit_index-1].pos,target.pos,.18,{"source_tag":source_tag})
	var summary:=ShamanSystem.note_chain_cast(hero,str(primary.combat_id),qualifying_ids,source_tag,quest_ids);resolve_shaman_frostwolf(hero,int(summary.crash_bonus_stacks))
	if ShamanSystem.note_ability_contacts(hero,qualifying_ids.size()) and cast_damage>0.0:var opening_heal:=deal_healing(hero,hero,cast_damage*float(ShamanData.VALUES.ancestral_heal),"basic_heal","Ancestral Wrath","shaman_ancestral_wrath");ShamanSystem.telemetry_add(hero,"ancestral_healing",float(opening_heal.effective_amount))
	if bool(summary.stormcaller) and source_tag=="player_chain" and final_target.hp>0.0:
		ShamanSystem.telemetry_add(hero,"stormcaller_casts");resolve_shaman_chain(hero,final_target,"stormcaller_chain",float(ShamanData.VALUES.stormcaller_rate))
	return {"contacts":qualifying_ids,"final_target":final_target}

func cast_shaman_q(hero:Dictionary)->bool:
	var target=shaman_enemy_target(hero);if target==null:return false
	var slot:Dictionary=hero.shaman_runtime.q_slot;slot.max_charges=ShamanSystem.q_max_charges(hero);slot.recharge_duration=ShamanSystem.q_cooldown(hero);slot.current_charges=mini(int(slot.current_charges),int(slot.max_charges))
	if not AbilitySlotSystem.spend(slot):return false
	resolve_shaman_chain(hero,target);hero.ability_cds[0]=float(slot.timers[0]) if not slot.timers.is_empty() else 0.0;ShamanSystem.note_ability_cast(hero);return true

func cast_shaman_w(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[1])>0.0:return false
	if ShamanSystem.has_talent(hero,"shaman_l12_1"):hero["shaman_block"]={"charges":0,"maximum":int(ShamanData.VALUES.feral_resilience_block_charges)}
	var direction:=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var gathering:=ShamanSystem.gathering_snapshot(hero);hero.shaman_runtime.feral_spirits.append({"pos":Vector2(hero.pos),"direction":direction,"remaining":float(ShamanData.SPACE.w_base_distance),"base_distance":float(ShamanData.SPACE.w_base_distance),"contact_ids":[],"qualifying":0,"quest_qualifying":0,"damage_total":0.0,"damage_rate":1.0,"return_spirit":false,"gathering":gathering})
	hero.ability_cds[1]=ShamanSystem.feral_cooldown(hero);ShamanSystem.note_ability_cast(hero);ShamanSystem.telemetry_add(hero,"w_casts");shaman_visual("shaman_feral_spirit",hero.pos,hero.pos,.25);return true

func cast_shaman_e(hero:Dictionary,automatic:bool=false)->bool:
	if not automatic and float(hero.ability_cds[2])>0.0:return false
	ShamanSystem.begin_windfury(hero,automatic);hero.ability_cds[2]=float(ShamanData.VALUES.e_cooldown);ShamanSystem.note_ability_cast(hero,false);shaman_visual("shaman_windfury",hero.pos,hero.pos,float(ShamanData.VALUES.e_duration));return true

func cast_shaman_heroic(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[3])>0.0:return false
	var heroic:=str(hero.get("selected_heroic_id",""));var direction:=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	if heroic=="shaman_l15_r1":
		hero.shaman_runtime.delayed_effects.append({"kind":"sundering","remaining":float(ShamanData.VALUES.r1_delay),"origin":Vector2(hero.pos),"direction":direction});hero.ability_cds[3]=maxf(1.0,float(ShamanData.VALUES.r1_cooldown)-(float(ShamanData.VALUES.worldbreaker_cooldown_reduction) if ShamanSystem.has_talent(hero,"shaman_l27_r1") else 0.0));ShamanSystem.note_ability_cast(hero,false);return true
	if heroic=="shaman_l15_r2":
		hero.shaman_runtime.delayed_effects.append({"kind":"earthquake","remaining":float(ShamanData.VALUES.r2_delay),"center":Vector2(hero.pos)});hero.ability_cds[3]=float(ShamanData.VALUES.r2_cooldown);ShamanSystem.note_ability_cast(hero,false);return true
	return false

func cast_shaman_ability(slot:int,point:Vector2,_item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Shaman" or hero.get("shaman_runtime",{}).is_empty():return false
	match slot:
		0:return cast_shaman_q(hero)
		1:return cast_shaman_w(hero,point)
		2:return cast_shaman_e(hero)
		3:return cast_shaman_heroic(hero,point)
	return false

func use_shaman_trait(hero:Dictionary)->bool:
	var activation:=ShamanSystem.activate_frostwolf_grace(hero);if activation.is_empty():return false
	var healing:=deal_healing(hero,hero,float(activation.raw_healing),"basic_heal","Frostwolf's Grace","shaman_frostwolf_grace");var shield_request:=ShamanSystem.overflow_shield_request(hero,activation,healing)
	if not shield_request.is_empty():apply_unit_shield(hero,hero,float(shield_request.amount),"Overflowing Resilience",str(shield_request.source_id),float(shield_request.cap),float(shield_request.duration))
	return true

func update_shaman_feral(hero:Dictionary,spirit:Dictionary,delta:float)->bool:
	var previous:=Vector2(spirit.pos);var movement:=minf(float(spirit.remaining),float(ShamanData.SPACE.w_speed)*delta);spirit.pos=Vector2(spirit.pos)+Vector2(spirit.direction)*movement;spirit.remaining=float(spirit.remaining)-movement;ShamanSystem.telemetry_add(hero,"w_distance",movement)
	for target in enemies:
		var id:=str(target.combat_id);if target.hp<=0.0 or id in spirit.contact_ids or not CombatGeometry.segment_hits_circle(previous,spirit.pos,target.pos,float(ShamanData.SPACE.w_width)+float(target.get("combat_radius",28.0))):continue
		spirit.contact_ids.append(id);var result:=shaman_damage(hero,target,ShamanSystem.ability_amount(hero,float(ShamanData.VALUES.w_damage))*float(spirit.gathering)*float(spirit.damage_rate),"Spirit of the Pack" if spirit.return_spirit else "Feral Spirit","shaman_w","basic_ability","spirit_pack_return" if spirit.return_spirit else "player_feral")
		if not ShamanSystem.successful(result):continue
		spirit.damage_total=float(spirit.damage_total)+float(result.resolved_damage);spirit.qualifying=int(spirit.qualifying)+1;if TargetCategorySystem.qualifies_quest(target):spirit.quest_qualifying=int(spirit.quest_qualifying)+1;spirit.remaining=float(spirit.remaining)+float(spirit.base_distance)*float(ShamanData.VALUES.w_extension);ShamanSystem.telemetry_add(hero,"w_return_hits" if spirit.return_spirit else "w_hits");ShamanSystem.telemetry_add(hero,"w_extensions")
		var root_duration:=float(ShamanData.VALUES.alpha_root if ShamanSystem.has_talent(hero,"shaman_l24_3") else ShamanData.VALUES.w_root);var control:=CombatSystem.apply_control(target,"root",root_duration);ShamanSystem.telemetry_add(hero,"w_roots");if not bool(control.applied) or float(control.duration)<root_duration:ShamanSystem.telemetry_add(hero,"w_root_resisted")
		ShamanSystem.mark_alpha(hero,id)
	shaman_visual("shaman_feral_spirit",previous,spirit.pos,.12,{"return_spirit":bool(spirit.return_spirit)})
	if float(spirit.remaining)>0.0 and CombatGeometry.BATTLE_BOUNDS.has_point(spirit.pos):return false
	if not bool(spirit.return_spirit):
		ShamanSystem.note_feral_cast(hero,int(spirit.quest_qualifying));if ShamanSystem.note_ability_contacts(hero,int(spirit.qualifying)) and float(spirit.damage_total)>0.0:var opening_heal:=deal_healing(hero,hero,float(spirit.damage_total)*float(ShamanData.VALUES.ancestral_heal),"basic_heal","Ancestral Wrath","shaman_ancestral_wrath");ShamanSystem.telemetry_add(hero,"ancestral_healing",float(opening_heal.effective_amount))
		if ShamanSystem.has_talent(hero,"shaman_l12_1") and int(spirit.qualifying)>0:
			resolve_shaman_frostwolf(hero,mini(int(ShamanData.VALUES.feral_resilience_contacts),int(spirit.qualifying))*int(ShamanData.VALUES.feral_resilience_extra_stacks));BlockChargeSystem.grant(hero,int(ShamanData.VALUES.feral_resilience_block_charges),int(ShamanData.VALUES.feral_resilience_block_charges),"shaman_block")
		if ShamanSystem.has_talent(hero,"shaman_l30_3"):
			hero.shaman_runtime.feral_spirits.append({"pos":Vector2(spirit.pos),"direction":-Vector2(spirit.direction),"remaining":float(spirit.base_distance),"base_distance":float(spirit.base_distance),"contact_ids":[],"qualifying":0,"quest_qualifying":0,"damage_total":0.0,"damage_rate":float(ShamanData.VALUES.spirit_pack_rate),"return_spirit":true,"gathering":float(spirit.gathering)});ShamanSystem.telemetry_add(hero,"w_return_casts")
	return true

func resolve_sundering(hero:Dictionary,effect:Dictionary)->void:
	var end:=Vector2(effect.origin)+Vector2(effect.direction)*float(ShamanData.SPACE.r1_length)
	for target in enemies:
		if target.hp<=0.0 or not CombatGeometry.segment_hits_circle(effect.origin,end,target.pos,float(ShamanData.SPACE.r1_width)+float(target.get("combat_radius",28.0))):continue
		shaman_damage(hero,target,ShamanSystem.ability_amount(hero,float(ShamanData.VALUES.r1_damage)),"Sundering","shaman_r1","heroic","sundering");CombatSystem.apply_control(target,"stun",float(ShamanData.VALUES.r1_stun))
		if bool(target.get("control_profile",{}).get("displacement",true)):
			var side:=Vector2(effect.direction).orthogonal();target.pos=CombatGeometry.move_toward_safe(target.pos,target.pos+side*float(ShamanData.SPACE.r1_shove),float(ShamanData.SPACE.r1_shove),float(target.get("combat_radius",28.0)),combat_blockers)
	if ShamanSystem.has_talent(hero,"shaman_l27_r1"):
		var midpoint:Vector2=(Vector2(effect.origin)+end)*.5;var size:=Vector2(float(ShamanData.SPACE.r1_length),24.0);var blocker:=CombatGeometry.create_blocker("shaman_rift:%s:%f"%[str(hero.combat_id),battle_time],Rect2(midpoint-size*.5,size),{"blocks_movement":true,"blocks_line_of_sight":false,"blocks_projectiles":false});blocker["remaining_duration"]=float(ShamanData.VALUES.worldbreaker_duration);combat_blockers.append(blocker);ShamanSystem.telemetry_add(hero,"worldbreaker_casts")
	shaman_visual("shaman_sundering",effect.origin,end,.5,{"width":float(ShamanData.SPACE.r1_width)})

func earthquake_pulse(hero:Dictionary,quake:Dictionary)->void:
	for target in enemies:
		if target.hp<=0.0 or target.pos.distance_to(quake.center)>float(ShamanData.SPACE.r2_radius):continue
		shaman_damage(hero,target,ShamanSystem.ability_amount(hero,float(ShamanData.VALUES.r2_damage)),"Earthquake","shaman_r2","heroic","earthquake");CombatSystem.apply_control(target,"slow",float(ShamanData.VALUES.r2_slow_duration),float(ShamanData.VALUES.r2_slow))
	if ShamanSystem.has_talent(hero,"shaman_l27_r2"):
		for ally in heroes:
			if ally.hp>0.0 and ally.pos.distance_to(quake.center)<=float(ShamanData.SPACE.r2_radius):apply_unit_shield(hero,ally,float(ally.max_hp)*float(ShamanData.VALUES.earthen_shield),"Earthen Shields","shaman_earthen_shields",float(ally.max_hp)*float(ShamanData.VALUES.earthen_shield),float(ShamanData.VALUES.earthen_shield_duration));ShamanSystem.telemetry_add(hero,"earthen_shields")
	ShamanSystem.telemetry_add(hero,"earthquake_pulses");shaman_visual("shaman_earthquake",quake.center,quake.center,.6,{"radius":float(ShamanData.SPACE.r2_radius)})

func update_shaman_runtime(delta:float)->void:
	for blocker_index in range(combat_blockers.size()-1,-1,-1):
		if not combat_blockers[blocker_index].has("remaining_duration"):continue
		combat_blockers[blocker_index].remaining_duration=float(combat_blockers[blocker_index].remaining_duration)-delta
		if float(combat_blockers[blocker_index].remaining_duration)<=0.0:combat_blockers.remove_at(blocker_index)
	for hero in heroes:
		if str(hero.get("class",""))!="Shaman" or hero.get("shaman_runtime",{}).is_empty():continue
		var druids:=heroes.filter(func(unit):return str(unit.get("class",""))=="Druid")
		ShamanSystem.update(hero,delta,DruidSystem.cooldown_rate_from_innervate(hero,druids,0));hero.ability_cds[0]=float(hero.shaman_runtime.q_slot.timers[0]) if not hero.shaman_runtime.q_slot.timers.is_empty() else 0.0
		hero.basic_attack_interval=float(hero.base_basic_action_interval)/(1.0+float(ShamanData.VALUES.e_attack_speed) if int(hero.shaman_runtime.windfury_attacks)>0 else 1.0)
		for index in range(hero.shaman_runtime.feral_spirits.size()-1,-1,-1):if update_shaman_feral(hero,hero.shaman_runtime.feral_spirits[index],delta):hero.shaman_runtime.feral_spirits.remove_at(index)
		for index in range(hero.shaman_runtime.delayed_effects.size()-1,-1,-1):
			var delayed:Dictionary=hero.shaman_runtime.delayed_effects[index];delayed.remaining=float(delayed.remaining)-delta;if delayed.remaining>0.0:continue
			if str(delayed.kind)=="sundering":resolve_sundering(hero,delayed)
			elif str(delayed.kind)=="earthquake":hero.shaman_runtime.earthquakes.append({"center":Vector2(delayed.center),"remaining":float(ShamanData.VALUES.r2_interval)*(int(ShamanData.VALUES.r2_pulses)-1)+.01,"pulse_timer":0.0,"pulses":0})
			hero.shaman_runtime.delayed_effects.remove_at(index)
		for quake in hero.shaman_runtime.earthquakes:
			quake.remaining=float(quake.remaining)-delta;quake.pulse_timer=float(quake.pulse_timer)-delta
			if float(quake.pulse_timer)<=0.0 and int(quake.pulses)<int(ShamanData.VALUES.r2_pulses):earthquake_pulse(hero,quake);quake.pulses=int(quake.pulses)+1;quake.pulse_timer=float(ShamanData.VALUES.r2_interval)
		hero.shaman_runtime.earthquakes=hero.shaman_runtime.earthquakes.filter(func(quake):return int(quake.pulses)<int(ShamanData.VALUES.r2_pulses) or float(quake.remaining)>0.0)
