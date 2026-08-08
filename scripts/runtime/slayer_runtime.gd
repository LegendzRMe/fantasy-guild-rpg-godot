extends "res://scripts/runtime/rogue_runtime.gd"

func slayer_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Slayer.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func slayer_damage(hero:Dictionary,target:Dictionary,amount:float,origin:String,effect_id:String="",can_crit:bool=true)->Dictionary:
	var result:=deal_damage(hero,target,amount,"heroic" if effect_id in ["slayer_r1","slayer_r2"] else "basic_ability","physical",origin,false,effect_id,[],can_crit)
	if SlayerSystem.has_talent(hero,"slayer_l18_3") and effect_id in ["slayer_q","slayer_w","slayer_immolation"] and float(result.get("resolved_damage",0.0))>0.0:
		var major:=TargetCategorySystem.category(target) in ["elite","named","boss","enemy_hero"];var rate:=float(SlayerData.VALUES.hunters_onslaught_hero if major else SlayerData.VALUES.hunters_onslaught_nonhero)
		var healing:=deal_healing(hero,hero,float(result.resolved_damage)*rate,"basic_heal","Hunter's Onslaught","slayer_hunters_onslaught");SlayerSystem.telemetry_add(hero,"hunter_healing",float(healing.effective_amount))
	return result

func slayer_enemy_target(hero:Dictionary,max_range:float=INF):
	var index:=combat_enemy_target();if index<0 or index>=enemies.size():return null
	var target:Dictionary=enemies[index]
	if target.hp<=0.0 or hero.pos.distance_to(target.pos)>max_range:return null
	return target

func slayer_clamped_point(hero:Dictionary,point:Vector2,range_limit:float)->Vector2:
	var offset:Vector2=point-Vector2(hero.pos)
	if offset.length()>range_limit:point=Vector2(hero.pos)+offset.normalized()*range_limit
	return point.clamp(Vector2(55,70),Vector2(1225,620))

func safe_dive_landing(hero:Dictionary,target:Dictionary)->Vector2:
	var direction:Vector2=Vector2(hero.pos).direction_to(Vector2(target.pos));if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var desired:Vector2=Vector2(target.pos)+direction*float(SlayerData.SPACE.dive_landing_offset)
	if CombatGeometry.valid_position(desired,42.0,combat_blockers):return desired
	for step in 12:
		var candidate:Vector2=Vector2(target.pos)+direction.rotated(step*TAU/12.0)*float(SlayerData.SPACE.dive_landing_offset)
		if CombatGeometry.valid_position(candidate,42.0,combat_blockers):return candidate
	return Vector2.INF

func cast_slayer_dive(hero:Dictionary)->bool:
	var base_range:=float(SlayerData.SPACE.dive_range)*(1.0+float(SlayerData.VALUES.friend_or_foe_range) if SlayerSystem.has_talent(hero,"slayer_l12_2") else 1.0)
	if SlayerSystem.has_talent(hero,"slayer_l12_2") and int(hero.get("heal_target",-1))>=0 and int(hero.heal_target)<heroes.size() and int(hero.heal_target)!=selected:
		var ally:Dictionary=heroes[int(hero.heal_target)];if ally.hp<=0.0 or hero.pos.distance_to(ally.pos)>base_range:return false
		var landing:=safe_dive_landing(hero,ally);if landing==Vector2.INF:return false
		var origin:Vector2=hero.pos;hero.pos=landing;hero.dest=hero.pos;hero.ability_cds[0]=float(SlayerData.VALUES.q_cooldown);SlayerSystem.grant_dive_block(hero);slayer_visual("slayer_dive",origin,hero.pos,0.18);return true
	var target=slayer_enemy_target(hero,base_range);if target==null:return false
	var landing:=safe_dive_landing(hero,target);if landing==Vector2.INF:SlayerSystem.telemetry_add(hero,"dive_invalid");return false
	var target_id:=str(target.combat_id);var rapid_recast:=SlayerSystem.rapid_target_valid(hero,target_id)
	if float(hero.ability_cds[0])>0.0 and not rapid_recast:return false
	var origin:Vector2=hero.pos;var amount:=SlayerSystem.scaled(hero,float(SlayerData.VALUES.q_damage))
	if SlayerSystem.marked_bonus(hero,target):amount+=SlayerSystem.scaled(hero,float(SlayerData.VALUES.marked_damage));SlayerSystem.telemetry_add(hero,"marked_activations")
	var result:=slayer_damage(hero,target,amount,"Dive","slayer_q")
	if not SlayerSystem.successful(result):return false
	hero.pos=landing;hero.dest=hero.pos;SlayerSystem.note_dive(hero,target);SlayerSystem.grant_dive_block(hero)
	if rapid_recast:SlayerSystem.consume_rapid_recast(hero)
	else:SlayerSystem.begin_rapid_chase(hero,target_id)
	slayer_visual("slayer_dive",origin,hero.pos,0.18);return true

func cast_slayer_sweep(hero:Dictionary,point:Vector2)->bool:
	if not AbilitySlotSystem.spend(hero.slayer_runtime.w_slot):return false
	var direction:Vector2=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var origin:Vector2=hero.pos;var destination:Vector2=(origin+direction*float(SlayerData.SPACE.sweep_range)).clamp(Vector2(55,70),Vector2(1225,620))
	if not SlayerSystem.has_talent(hero,"slayer_l12_3"):destination=CombatGeometry.move_toward_safe(origin,destination,origin.distance_to(destination),42.0,combat_blockers)
	var contacts:Array=[]
	for target in enemies:
		if target.hp<=0.0 or not CombatGeometry.segment_hits_circle(origin,destination,target.pos,float(SlayerData.SPACE.sweep_width)+float(target.get("combat_radius",28.0))):continue
		var result:=slayer_damage(hero,target,SlayerSystem.scaled(hero,float(SlayerData.VALUES.w_damage)),"Sweeping Strike","slayer_w")
		if SlayerSystem.successful(result):contacts.append(target)
	hero.pos=destination;hero.dest=destination;hero.ability_cds[1]=float(hero.slayer_runtime.w_slot.timers[0]) if not hero.slayer_runtime.w_slot.timers.is_empty() else 0.0;SlayerSystem.note_sweep(hero,contacts);slayer_visual("slayer_sweep",origin,destination,0.22,{"width":float(SlayerData.SPACE.sweep_width)});return true

func cast_slayer_evasion(hero:Dictionary)->bool:
	if float(hero.ability_cds[2])>0.0:return false
	EvasionSystem.activate(hero,float(SlayerData.VALUES.e_duration),"slayer_e");hero.ability_cds[2]=float(SlayerData.VALUES.e_cooldown);SlayerSystem.telemetry_add(hero,"evasion_casts")
	if SlayerSystem.has_talent(hero,"slayer_l21_3"):remove_named_shield(hero,"slayer_shadow_shield");apply_unit_shield(hero,hero,float(hero.max_hp)*float(SlayerData.VALUES.shadow_shield_fraction),"Shadow Shield","slayer_shadow_shield",INF,float(SlayerData.VALUES.shadow_shield_duration))
	slayer_visual("slayer_evasion",hero.pos,hero.pos,float(SlayerData.VALUES.e_duration),{"radius":54.0});return true

func cast_slayer_heroic(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[3])>0.0:return false
	var heroic_id:=str(hero.get("selected_heroic_id",""))
	if heroic_id=="slayer_l15_r1":
		var center:Vector2=slayer_clamped_point(hero,point,float(SlayerData.SPACE.metamorphosis_range));var contacts:=0
		for target in enemies:
			if target.hp<=0.0 or target.pos.distance_to(center)>float(SlayerData.SPACE.metamorphosis_radius):continue
			slayer_damage(hero,target,SlayerSystem.scaled(hero,float(SlayerData.VALUES.r1_damage)),"Metamorphosis","slayer_r1");if TargetCategorySystem.qualifies_immediate(target):contacts+=1
		hero.pos=center;hero.dest=center;SlayerSystem.begin_metamorphosis(hero,contacts);hero.ability_cds[3]=float(SlayerData.VALUES.r1_cooldown);slayer_visual("slayer_metamorphosis",center,center,0.6,{"radius":float(SlayerData.SPACE.metamorphosis_radius)});return true
	if heroic_id=="slayer_l15_r2":
		var target=slayer_enemy_target(hero);if target==null:return false
		var landing:=safe_dive_landing(hero,target);if landing==Vector2.INF:return false
		var origin:Vector2=hero.pos;var amount:=SlayerSystem.scaled(hero,float(SlayerData.VALUES.r2_damage));var executing:=SlayerSystem.has_talent(hero,"slayer_l27_r2") and float(target.hp)/maxf(1.0,float(target.max_hp))<float(SlayerData.VALUES.nowhere_threshold);if executing:amount*=2.0
		var result:=slayer_damage(hero,target,amount,"The Hunt","slayer_r2");hero.pos=landing;hero.dest=hero.pos;CombatSystem.apply_control(target,"stun",float(SlayerData.VALUES.r2_stun));hero.ability_cds[3]=0.0 if executing and bool(result.get("defeated",false)) else float(SlayerData.VALUES.r2_cooldown);SlayerSystem.telemetry_add(hero,"hunt_casts");if bool(result.get("defeated",false)):SlayerSystem.telemetry_add(hero,"hunt_kills");slayer_visual("slayer_hunt",origin,hero.pos,0.32);return true
	return false

func cast_slayer_ability(slot:int,point:Vector2,_item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Slayer" or hero.get("slayer_runtime",{}).is_empty():return false
	match slot:
		0:return cast_slayer_dive(hero)
		1:return cast_slayer_sweep(hero,point)
		2:return cast_slayer_evasion(hero)
		3:return cast_slayer_heroic(hero,point)
	return false

func use_slayer_trait(hero:Dictionary)->bool:
	if not SlayerSystem.has_talent(hero,"slayer_l30_2") or float(hero.ability_cds[4])>0.0:return false
	hero.ability_cds[0]=0.0;hero.ability_cds[2]=0.0;hero.ability_cds[3]=0.0;hero.slayer_runtime.w_slot.current_charges=int(hero.slayer_runtime.w_slot.max_charges);hero.slayer_runtime.w_slot.timers.clear();hero.slayer_runtime.rapid_remaining=0.0;hero.slayer_runtime.rapid_recast_available=false;hero.ability_cds[1]=0.0;hero.ability_cds[4]=float(SlayerData.VALUES.thrill_cooldown);SlayerSystem.telemetry_add(hero,"thrill_casts");return true

func update_slayer_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Slayer" or hero.get("slayer_runtime",{}).is_empty():continue
		hero.slayer_runtime.unending_thirst_shield=named_shield_amount(hero,"slayer_unending_thirst")
		var update:=SlayerSystem.update(hero,delta);hero.basic_attack_interval=SlayerSystem.attack_interval(hero);hero.ability_cds[1]=float(hero.slayer_runtime.w_slot.timers[0]) if not hero.slayer_runtime.w_slot.timers.is_empty() else 0.0
		if float(update.thirst_decay)>0.0:reduce_named_shield(hero,"slayer_unending_thirst",float(update.thirst_decay))
		if bool(update.immolation_tick):
			for target in enemies:
				if target.hp<=0.0 or target.pos.distance_to(hero.pos)>float(hero.range):continue
				var result:=slayer_damage(hero,target,SlayerSystem.scaled(hero,float(SlayerData.VALUES.immolation_dps)),"Immolation","slayer_immolation",false);SlayerSystem.telemetry_add(hero,"immolation_damage",float(result.resolved_damage))

func remove_named_shield(unit:Dictionary,source_id:String)->void:
	for index in range(unit.get("shield_sources",[]).size()-1,-1,-1):
		if str(unit.shield_sources[index].get("source_id",""))!=source_id:continue
		unit.shield=maxf(0.0,float(unit.shield)-float(unit.shield_sources[index].amount));unit.shield_sources.remove_at(index)

func named_shield_amount(unit:Dictionary,source_id:String)->float:
	var amount:=0.0
	for source in unit.get("shield_sources",[]):
		if str(source.get("source_id",""))==source_id:amount+=float(source.get("amount",0.0))
	return amount

func reduce_named_shield(unit:Dictionary,source_id:String,amount:float)->void:
	var remaining:=maxf(0.0,amount)
	for index in range(unit.get("shield_sources",[]).size()-1,-1,-1):
		if str(unit.shield_sources[index].get("source_id",""))!=source_id:continue
		var consumed:=minf(remaining,float(unit.shield_sources[index].amount));unit.shield_sources[index].amount=float(unit.shield_sources[index].amount)-consumed;unit.shield=maxf(0.0,float(unit.shield)-consumed);remaining-=consumed
		if float(unit.shield_sources[index].amount)<=0.0001:unit.shield_sources.remove_at(index)
		if remaining<=0.0:return
