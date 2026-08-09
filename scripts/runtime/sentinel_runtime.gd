extends "res://scripts/runtime/protector_runtime.gd"

func sentinel_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Sentinel.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)
func sentinel_clamped_point(hero:Dictionary,point:Vector2,range_limit:float)->Vector2:
	var offset:Vector2=point-Vector2(hero.pos)
	if offset.length()>range_limit:point=Vector2(hero.pos)+offset.normalized()*range_limit
	return point.clamp(Vector2(55,70),Vector2(1225,620))
func sentinel_enemy_target(hero:Dictionary,max_range:float=INF,allow_concealed:bool=false):
	var index:=combat_enemy_target()
	if index>=0 and index<enemies.size() and enemies[index].hp>0.0 and hero.pos.distance_to(enemies[index].pos)<=max_range:return enemies[index]
	if not allow_concealed:return null
	var candidates:=enemies.filter(func(target):return target.hp>0.0 and hero.pos.distance_to(target.pos)<=max_range and not StealthDetectionSystem.is_unrevealable(target) and (StealthDetectionSystem.is_stealthed(target) or StealthDetectionSystem.is_invisible(target)))
	candidates.sort_custom(func(a,b):var da:float=hero.pos.distance_squared_to(a.pos);var db:float=hero.pos.distance_squared_to(b.pos);return da<db or is_equal_approx(da,db) and str(a.combat_id)<str(b.combat_id))
	return candidates[0] if not candidates.is_empty() else null
func sentinel_heal(hero:Dictionary,target:Dictionary,base_amount:float,origin:String,allow_overflow:bool=true)->Dictionary:
	var pre_ratio:=float(target.hp)/maxf(1.0,float(target.max_hp));var native:=SentinelSystem.ability_amount(hero,base_amount)
	if SentinelSystem.has_talent(hero,"sentinel_l24_1") and pre_ratio<.20:native*=1.5
	var bank:=float(hero.sentinel_runtime.overflow_bank) if allow_overflow and SentinelSystem.has_talent(hero,"sentinel_l30_3") else 0.0
	if bank>0.0:hero.sentinel_runtime.overflow_bank=0.0
	var result:=deal_healing(hero,target,native+bank,"basic_ability",origin,"sentinel_q")
	if allow_overflow and SentinelSystem.has_talent(hero,"sentinel_l30_3"):
		var missing_before:=maxf(0.0,float(target.max_hp)-float(target.hp)+float(result.get("effective_amount",0.0)));hero.sentinel_runtime.overflow_bank=maxf(0.0,native-missing_before)
	SentinelSystem.telemetry_add(hero,"q_effective_healing",float(result.get("effective_amount",0.0)));SentinelSystem.telemetry_add(hero,"q_overhealing",float(result.get("overhealing",0.0)));return result
func sentinel_cast_q(hero:Dictionary)->bool:
	if not AbilitySlotSystem.can_activate(hero.sentinel_runtime.q_slot):return false
	var initially_full:bool=int(hero.sentinel_runtime.q_slot.current_charges)==2;var target=SentinelSystem.select_lowest(heroes,hero.pos,float(SentinelData.SPACE.q_range));if target==null:return false
	var pre_ratio:=float(target.hp)/maxf(1.0,float(target.max_hp));if not SentinelSystem.spend_q(hero):return false
	sentinel_heal(hero,target,float(SentinelData.VALUES.q_heal),"Light of Elune");SentinelSystem.telemetry_add(hero,"q_casts");sentinel_visual("sentinel_q",hero.pos,target.pos,.5)
	if SentinelSystem.has_talent(hero,"sentinel_l12_1") and initially_full:
		var second=SentinelSystem.select_lowest(heroes,hero.pos,float(SentinelData.SPACE.q_range),str(target.combat_id));if second==null:second=target
		sentinel_heal(hero,second,float(SentinelData.VALUES.q_heal)*(1.8 if second!=target else 1.0),"Everlasting Light",false)
	if SentinelSystem.has_talent(hero,"sentinel_l18_2"):
		var source_id:="sentinel_kaldorei:%s"%str(hero.combat_id);var sources:Array=target.get("temporary_armor_sources",[]);var found:=false
		for source in sources:
			if str(source.get("id",""))==source_id:source.armor=float(source.get("armor",0.0))+10.0;source.remaining=7.5;found=true
		if not found:sources.append({"id":source_id,"armor":10.0,"remaining":7.5});target.temporary_armor_sources=sources
	if SentinelSystem.has_talent(hero,"sentinel_l21_1"):
		CombatSystem.remove_controls(target,["stun","silence","slow"])
		target.active_effects=CombatSystem.apply_named_effect(target.active_effects,{"id":"sentinel_quickening:%s"%str(hero.combat_id),"remaining_duration":3.0,"movement_speed_multiplier":1.25})
	if SentinelSystem.has_talent(hero,"sentinel_l12_3") and float(hero.sentinel_runtime.elune_chosen.get("cooldown",0.0))<=0.0:hero.sentinel_runtime.elune_chosen={"target_id":str(target.combat_id),"remaining":8.0,"cooldown":30.0}
	if SentinelSystem.has_talent(hero,"sentinel_l30_3") and pre_ratio<.10:hero.sentinel_runtime.q_slot.current_charges=mini(2,int(hero.sentinel_runtime.q_slot.current_charges)+1)
	return true
func sentinel_cast_w(hero:Dictionary,point:Vector2)->bool:
	if not AbilitySlotSystem.can_activate(hero.sentinel_runtime.w_slot):return false
	var direction:Vector2=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	AbilitySlotSystem.spend(hero.sentinel_runtime.w_slot);var max_hits:=2 if int(hero.sentinel_runtime.e_quest_stacks)>=20 else 1
	hero.sentinel_runtime.w_projectiles.append({"position":Vector2(hero.pos),"origin":Vector2(hero.pos),"direction":direction,"leg_traveled":0.0,"total_traveled":0.0,"returning":false,"hit_ids":[],"max_hits":max_hits});SentinelSystem.telemetry_add(hero,"w_casts");sentinel_visual("sentinel_w",hero.pos,hero.pos+direction*float(SentinelData.SPACE.w_range),.35,{"width":float(SentinelData.SPACE.w_width)*(1.25 if SentinelSystem.has_talent(hero,"sentinel_l9_1") else 1.0)});return true
func sentinel_cast_e(hero:Dictionary,point:Vector2,automatic:bool=false)->bool:
	if not automatic and float(hero.ability_cds[2])>0.0:return false
	var range_limit:=SentinelSystem.e_range(hero);var center:Vector2=sentinel_clamped_point(hero,point,range_limit);hero.sentinel_runtime.pending_flares.append({"center":center,"remaining":float(SentinelData.VALUES.e_delay),"automatic":automatic})
	if not automatic:hero.ability_cds[2]=float(SentinelData.VALUES.e_cooldown);SentinelSystem.telemetry_add(hero,"e_casts")
	sentinel_visual("sentinel_flare_warning",center,center,float(SentinelData.VALUES.e_delay),{"radius":float(SentinelData.SPACE.e_radius)});return true
func sentinel_cast_heroic(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[3])>0.0:return false
	var heroic:=str(hero.get("selected_heroic_id",""))
	if heroic=="sentinel_l15_r1":
		hero.ability_cds[3]=float(SentinelData.VALUES.r1_cooldown);hero.sentinel_runtime.shadowstalk={"remaining":float(SentinelData.VALUES.r1_duration),"tick":0.0,"stationary":{}}
		for ally in heroes:if ally.hp>0.0:StealthDetectionSystem.set_stealth_source(ally,"sentinel_shadowstalk:%s"%str(hero.combat_id),true);hero.sentinel_runtime.shadowstalk.stationary[str(ally.combat_id)]={"time":0.0,"last_pos":Vector2(ally.pos)}
		if SentinelSystem.has_talent(hero,"sentinel_l27_r1"):for enemy in enemies:StealthDetectionSystem.reveal(enemy,10.0)
		SentinelSystem.telemetry_add(hero,"r1_casts");return true
	if heroic=="sentinel_l15_r2":hero.ability_cds[3]=float(SentinelData.VALUES.r2_cooldown);hero.sentinel_runtime.starfalls.append({"center":sentinel_clamped_point(hero,point,float(SentinelData.SPACE.e_range)),"remaining":float(SentinelData.VALUES.r2_duration),"tick":0.0});SentinelSystem.telemetry_add(hero,"r2_casts");return true
	return false
func sentinel_cast_trait(hero:Dictionary)->bool:
	if SentinelSystem.has_talent(hero,"sentinel_l30_2") and float(hero.sentinel_runtime.d_cooldown)>0.0:
		if float(hero.sentinel_runtime.trueshot_cooldown)>0.0:return false
		for ally in heroes:if ally.hp>0.0 and ally.pos.distance_to(hero.pos)<=float(SentinelData.SPACE.d_range):ally.active_effects=CombatSystem.apply_named_effect(ally.active_effects,{"id":"sentinel_trueshot:%s"%str(hero.combat_id),"remaining_duration":float(SentinelData.VALUES.trueshot_duration),"basic_attack_damage_multiplier":1.0+float(SentinelData.VALUES.trueshot_bonus)})
		hero.sentinel_runtime.trueshot_cooldown=float(SentinelData.VALUES.trueshot_cooldown);hero.sentinel_runtime.d_cooldown=0.0;SentinelSystem.telemetry_add(hero,"trueshot_casts");return true
	var target=sentinel_enemy_target(hero,SentinelSystem.mark_range(hero),true);if target==null:return false
	return SentinelSystem.apply_mark(hero,target,true)
func cast_sentinel_ability(slot:int,point:Vector2,_item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Sentinel" or hero.get("sentinel_runtime",{}).is_empty():return false
	match slot:
		0:return sentinel_cast_q(hero)
		1:return sentinel_cast_w(hero,point)
		2:return sentinel_cast_e(hero,point)
		3:return sentinel_cast_heroic(hero,point)
		4:return sentinel_cast_trait(hero)
	return false
func resolve_sentinel_flare(hero:Dictionary,flare:Dictionary)->void:
	var hit_any:=false
	for target in enemies:
		if target.hp<=0.0 or target.pos.distance_to(flare.center)>float(SentinelData.SPACE.e_radius):continue
		var result:=deal_damage(hero,target,SentinelSystem.ability_amount(hero,float(SentinelData.VALUES.e_damage))*SentinelSystem.e_multiplier(hero),"basic_ability","magical","Lunar Flare",false,"sentinel_e_auto" if bool(flare.automatic) else "sentinel_e",[],true);if float(result.get("resolved_damage",0.0))<=0.0:continue
		hit_any=true;CombatSystem.apply_control(target,"stun",1.5 if SentinelSystem.has_talent(hero,"sentinel_l21_3") else float(SentinelData.VALUES.e_stun));SentinelSystem.note_e_hit(hero,target,bool(flare.automatic));SentinelSystem.telemetry_add(hero,"e_hits");SentinelSystem.telemetry_add(hero,"e_damage",float(result.resolved_damage))
	if hit_any and SentinelSystem.has_talent(hero,"sentinel_l18_1"):hero.active_effects=CombatSystem.apply_named_effect(hero.active_effects,{"id":"sentinel_elune_gift","remaining_duration":10.0,"ability_power_bonus":20.0})
	sentinel_visual("sentinel_flare",flare.center,flare.center,.55,{"radius":float(SentinelData.SPACE.e_radius)})
func update_sentinel_projectile(hero:Dictionary,p:Dictionary,delta:float)->bool:
	var previous:=Vector2(p.position);var step:=float(SentinelData.SPACE.w_speed)*delta;p.position=previous+Vector2(p.direction)*step;p.leg_traveled=float(p.leg_traveled)+step;p.total_traveled=float(p.total_traveled)+step
	var hit_width:=float(SentinelData.SPACE.w_width)*(1.25 if SentinelSystem.has_talent(hero,"sentinel_l9_1") else 1.0);var hits:=enemies.filter(func(target):return target.hp>0.0 and str(target.combat_id) not in p.hit_ids and CombatGeometry.segment_distance_to_point(previous,p.position,target.pos)<=hit_width+float(target.get("combat_radius",28.0)))
	hits.sort_custom(func(a,b):return previous.distance_squared_to(a.pos)<previous.distance_squared_to(b.pos))
	for target in hits:
		p.hit_ids.append(str(target.combat_id));var distance_units:=float(p.total_traveled)/maxf(1.0,float(SentinelData.SPACE.w_range));var bonus:=minf(2.5,distance_units*(1.25 if bool(p.returning) else 1.0));var result:=deal_damage(hero,target,SentinelSystem.ability_amount(hero,float(SentinelData.VALUES.w_damage))*(1.0+bonus),"basic_ability","magical","Sentinel Shot",false,"sentinel_w",[],true);StealthDetectionSystem.reveal(target,float(SentinelData.VALUES.w_reveal));hero.sentinel_runtime.w_reveals[str(target.combat_id)]={"remaining":float(SentinelData.VALUES.w_reveal),"reset_used":false};SentinelSystem.telemetry_add(hero,"w_hits");SentinelSystem.telemetry_add(hero,"w_damage",float(result.resolved_damage));SentinelSystem.telemetry_add(hero,"w_distance_bonus",bonus);if SentinelSystem.has_talent(hero,"sentinel_l21_2"):CombatSystem.apply_control(target,"slow",3.0,.35);OutgoingDamageReductionSystem.apply(target,"sentinel_harsh:%s"%str(hero.combat_id),.35,3.0);if SentinelSystem.has_talent(hero,"sentinel_l24_2"):var req:=PercentageHealthDamageSystem.request(hero,target,.06,.015,"Empower");deal_damage(hero,target,float(req.amount),"percentage_health","magical","Empower",false,"sentinel_empower",[],false)
		if p.hit_ids.size()>=int(p.max_hits):return false
	if float(p.leg_traveled)>=float(SentinelData.SPACE.w_range):
		if SentinelSystem.has_talent(hero,"sentinel_l9_1") and p.hit_ids.is_empty() and not bool(p.returning):p.returning=true;p.direction=-Vector2(p.direction);p.leg_traveled=0.0;return true
		return false
	return true
func update_sentinel_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Sentinel" or hero.get("sentinel_runtime",{}).is_empty():continue
		SentinelSystem.update(hero,delta);var rt:Dictionary=hero.sentinel_runtime
		for reveal_id in rt.w_reveals.keys():rt.w_reveals[reveal_id].remaining=float(rt.w_reveals[reveal_id].remaining)-delta;if float(rt.w_reveals[reveal_id].remaining)<=0.0:rt.w_reveals.erase(reveal_id)
		if not rt.elune_chosen.is_empty():
			rt.elune_chosen.remaining=maxf(0.0,float(rt.elune_chosen.get("remaining",0.0))-delta);rt.elune_chosen.cooldown=maxf(0.0,float(rt.elune_chosen.get("cooldown",0.0))-delta)
		for projectile_index in range(rt.w_projectiles.size()-1,-1,-1):
			if not update_sentinel_projectile(hero,rt.w_projectiles[projectile_index],delta):rt.w_projectiles.remove_at(projectile_index)
		for flare_index in range(rt.pending_flares.size()-1,-1,-1):
			var flare:Dictionary=rt.pending_flares[flare_index];flare.remaining=float(flare.remaining)-delta
			if float(flare.remaining)<=0.0:resolve_sentinel_flare(hero,flare);rt.pending_flares.remove_at(flare_index)
		for starfall_index in range(rt.starfalls.size()-1,-1,-1):
			var field:Dictionary=rt.starfalls[starfall_index];field.remaining=float(field.remaining)-delta;field.tick=float(field.tick)-delta
			if float(field.tick)<=0.0:
				field.tick=1.0
				for target in enemies:
					if target.hp<=0.0 or target.pos.distance_to(field.center)>float(SentinelData.SPACE.starfall_radius):continue
					var starfall_result:=deal_damage(hero,target,SentinelSystem.ability_amount(hero,float(SentinelData.VALUES.r2_dps)),"heroic","magical","Starfall",false,"sentinel_r2",[],true)
					CombatSystem.apply_control(target,"slow",1.1,.60 if SentinelSystem.has_talent(hero,"sentinel_l27_r2") else .20)
					if SentinelSystem.has_talent(hero,"sentinel_l27_r2"):SentinelSystem.apply_mark(hero,target,false)
					SentinelSystem.telemetry_add(hero,"r2_damage",float(starfall_result.resolved_damage))
			if float(field.remaining)<=0.0:rt.starfalls.remove_at(starfall_index)
		if not rt.shadowstalk.is_empty():
			rt.shadowstalk.remaining=float(rt.shadowstalk.remaining)-delta;rt.shadowstalk.tick=float(rt.shadowstalk.tick)-delta
			for tracked_ally in heroes:
				var state:Dictionary=rt.shadowstalk.stationary.get(str(tracked_ally.combat_id),{"time":0.0,"last_pos":Vector2(tracked_ally.pos)});var moved:=Vector2(state.last_pos).distance_to(tracked_ally.pos)>.5;state.time=0.0 if moved else float(state.time)+delta;state.last_pos=Vector2(tracked_ally.pos);rt.shadowstalk.stationary[str(tracked_ally.combat_id)]=state
				StealthDetectionSystem.set_source(tracked_ally,"sentinel_shadowstalk_invisible:%s"%str(hero.combat_id),float(state.time)>=float(SentinelData.VALUES.r1_invisible_delay))
			if float(rt.shadowstalk.tick)<=0.0:
				rt.shadowstalk.tick=1.0
				for shadow_ally in heroes:
					if shadow_ally.hp<=0.0:continue
					var shadow_result:=deal_healing(hero,shadow_ally,SentinelSystem.ability_amount(hero,float(SentinelData.VALUES.r1_total_heal)/10.0)*(1.75 if SentinelSystem.has_talent(hero,"sentinel_l27_r1") else 1.0),"periodic","Shadowstalk","sentinel_r1");SentinelSystem.telemetry_add(hero,"r1_healing",float(shadow_result.effective_amount))
			if float(rt.shadowstalk.remaining)<=0.0:
				for ending_ally in heroes:StealthDetectionSystem.set_stealth_source(ending_ally,"sentinel_shadowstalk:%s"%str(hero.combat_id),false);StealthDetectionSystem.set_source(ending_ally,"sentinel_shadowstalk_invisible:%s"%str(hero.combat_id),false)
				rt.shadowstalk={}
