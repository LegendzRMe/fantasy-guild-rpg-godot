extends "res://scripts/runtime/templar_runtime.gd"

func protector_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Protector.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func protector_enemy_target(hero:Dictionary,max_range:float=INF):
	var index:=combat_enemy_target();if index<0 or index>=enemies.size():return null
	var target:Dictionary=enemies[index];return target if target.hp>0.0 and hero.pos.distance_to(target.pos)<=max_range else null

func protector_blockers_without_own_wall(hero:Dictionary)->Array:
	return combat_blockers.filter(func(blocker):return not ProtectorSystem.own_wall(hero,blocker))

func protector_safe_special_destination(hero:Dictionary,point:Vector2)->Vector2:
	var desired:=point.clamp(CombatGeometry.BATTLE_BOUNDS.position+Vector2.ONE*float(hero.get("combat_radius",42.0)),CombatGeometry.BATTLE_BOUNDS.end-Vector2.ONE*float(hero.get("combat_radius",42.0)))
	var filtered:=protector_blockers_without_own_wall(hero)
	if CombatGeometry.valid_position(desired,float(hero.get("combat_radius",42.0)),filtered):return desired
	return CombatGeometry.move_toward_safe(hero.pos,desired,hero.pos.distance_to(desired),float(hero.get("combat_radius",42.0)),filtered)

func cast_protector_q(hero:Dictionary,point:Vector2)->bool:
	var runtime:Dictionary=hero.protector_runtime;var sequence:Dictionary=runtime.q_sequence
	if not sequence.is_empty() and float(sequence.get("remaining",0.0))>0.0:
		var origin:=Vector2(hero.pos);var landing:=protector_safe_special_destination(hero,Vector2(sequence.sword_pos));hero.pos=landing;hero.dest=landing;hero.facing_direction=origin.direction_to(landing)
		var empowered:=bool(sequence.get("empowered",false));var radius:=float(ProtectorData.SPACE.q_radius)*(1.25 if empowered else 1.0)
		for target in enemies:
			if target.hp<=0.0 or target.pos.distance_to(landing)>radius:continue
			protector_apply_q_slow(hero,target);protector_q_knockback(hero,target,landing,empowered);ProtectorSystem.telemetry_add(hero,"q_knockbacks")
		if ProtectorSystem.has_talent(hero,"protector_l9_1"):runtime.pursuit_remaining=float(ProtectorData.VALUES.q_pursuit_duration)
		if ProtectorSystem.has_talent(hero,"protector_l12_1"):runtime.stalwart_remaining=float(ProtectorData.VALUES.q_stalwart_after)
		if ProtectorSystem.has_talent(hero,"protector_l24_3"):runtime.wicked_remaining=2.0
		if empowered:hero.ability_cds[1]=maxf(0.0,float(hero.ability_cds[1])-5.0)
		if ProtectorSystem.has_talent(hero,"protector_l18_1"):runtime.burning_empowered_remaining=float(ProtectorData.VALUES.burning_teleport_duration)
		sequence.teleports=int(sequence.get("teleports",0))+1;ProtectorSystem.telemetry_add(hero,"q_teleports");protector_visual("protector_teleport",origin,landing,.35,{"radius":radius})
		if ProtectorSystem.has_talent(hero,"protector_l21_1") and int(sequence.teleports)==1:sequence.sword_pos=origin;sequence.remaining=float(ProtectorData.VALUES.q_sword_duration)
		else:runtime.q_sequence={}
		return true
	if float(hero.ability_cds[0])>0.0:return false
	var direction:Vector2=Vector2(hero.pos).direction_to(point)
	if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var sword_pos:=protector_safe_special_destination(hero,hero.pos+direction*minf(hero.pos.distance_to(point),float(ProtectorData.SPACE.q_range)))
	var cast_id:=ProtectorSystem.next_cast_id(hero,"protector_q");var empowered:=ProtectorSystem.crosses_own_wall(hero,hero.pos,sword_pos,combat_blockers)
	if empowered:
		ProtectorSystem.telemetry_add(hero,"q_wall_crossings")
		if ProtectorSystem.has_talent(hero,"protector_l21_2"):ProtectorSystem.telemetry_add(hero,"q_piercing_activations")
	sequence={"cast_id":cast_id,"sword_pos":sword_pos,"remaining":float(ProtectorData.VALUES.q_sword_duration),"teleports":0,"empowered":empowered,"marked_ids":[]};runtime.q_sequence=sequence
	for target in enemies:
		if target.hp<=0.0 or not CombatGeometry.segment_hits_circle(hero.pos,sword_pos,target.pos,float(ProtectorData.SPACE.q_radius)+float(target.get("combat_radius",28.0))):continue
		var result:=deal_damage(hero,target,ProtectorSystem.ability_amount(hero,float(ProtectorData.VALUES.q_damage)),"basic_ability","physical","El'druin's Might",false,"protector_q",[],true)
		if float(result.get("resolved_damage",0.0))>0.0:sequence.marked_ids.append(str(target.combat_id));protector_apply_q_slow(hero,target);ProtectorSystem.telemetry_add(hero,"q_hits")
	hero.ability_cds[0]=float(ProtectorData.VALUES.q_cooldown);ProtectorSystem.telemetry_add(hero,"q_throws");protector_visual("protector_sword_throw",hero.pos,sword_pos,.45,{"empowered":empowered});return true

func protector_apply_q_slow(hero:Dictionary,target:Dictionary)->void:
	if ProtectorSystem.has_talent(hero,"protector_l24_1"):CombatSystem.apply_control(target,"slow",float(ProtectorData.VALUES.q_bound_duration),float(ProtectorData.VALUES.q_bound_slow));target.active_effects.append({"id":"protector_q_slow_follow:%s"%str(hero.combat_id),"control_type":"slow","amount":float(ProtectorData.VALUES.q_slow),"remaining_duration":float(ProtectorData.VALUES.q_slow_duration)-float(ProtectorData.VALUES.q_bound_duration),"delay":float(ProtectorData.VALUES.q_bound_duration)})
	else:CombatSystem.apply_control(target,"slow",float(ProtectorData.VALUES.q_slow_duration),float(ProtectorData.VALUES.q_slow))

func protector_q_knockback(hero:Dictionary,target:Dictionary,center:Vector2,empowered:bool)->void:
	var profile:=CombatSystem.default_control_profile(target)
	if not bool(profile.get("displacement",true)):
		ProtectorSystem.telemetry_add(hero,"q_displacement_resisted")
		return
	var distance:=float(ProtectorData.SPACE.q_knockback)*(1.25 if empowered else 1.0);var direction:=center.direction_to(target.pos);if direction==Vector2.ZERO:direction=Vector2.RIGHT
	var desired:Vector2=Vector2(target.pos)+direction*distance
	var own_wall=ProtectorSystem.intersecting_own_wall(hero,target.pos,desired,combat_blockers)
	target.pos=CombatGeometry.move_toward_safe(target.pos,desired,distance,float(target.get("combat_radius",28.0)),combat_blockers)
	if own_wall!=null and ProtectorSystem.has_talent(hero,"protector_l12_2"):var stun:=CombatSystem.apply_control(target,"stun",float(ProtectorData.VALUES.q_rebuke_stun));if bool(stun.applied):ProtectorSystem.telemetry_add(hero,"q_rebuke_stuns")

func cast_protector_w(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[1])>0.0:return false
	var direction:Vector2=Vector2(hero.pos).direction_to(point)
	if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var center:Vector2=Vector2(hero.pos)+direction*minf(Vector2(hero.pos).distance_to(point),ProtectorSystem.wall_range(hero))
	var side:Vector2=direction.orthogonal()
	var half:=float(ProtectorData.SPACE.w_length)*.5
	var cast_id:=ProtectorSystem.next_cast_id(hero,"protector_w");hero.protector_runtime.walls.append({"cast_id":cast_id,"center":center,"from":center-side*half,"to":center+side*half,"remaining":float(ProtectorData.VALUES.w_delay),"active":false})
	hero.ability_cds[1]=ProtectorSystem.wall_cooldown(hero)
	ProtectorSystem.telemetry_add(hero,"walls_cast")
	if ProtectorSystem.has_talent(hero,"protector_l30_2"):ProtectorSystem.telemetry_add(hero,"force_barrier_casts")
	protector_visual("protector_wall_warning",center-side*half,center+side*half,float(ProtectorData.VALUES.w_delay))
	return true

func protector_smite_geometry_hit(origin:Vector2,end:Vector2,target:Vector2)->bool:return CombatGeometry.segment_distance_to_point(origin,end,target)<=float(ProtectorData.SPACE.e_half_width)
func cast_protector_e(hero:Dictionary,point:Vector2)->bool:
	var slot:Dictionary=hero.protector_runtime.smite_slot
	if not AbilitySlotSystem.can_activate(slot):return false
	var direction:Vector2=Vector2(hero.pos).direction_to(point)
	if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var origin:=Vector2(hero.pos)
	var end:Vector2=origin+direction*minf(maxf(40.0,origin.distance_to(point)),float(ProtectorData.SPACE.e_length))
	var cast_id:=ProtectorSystem.next_cast_id(hero,"protector_e")
	var fields:=[{"cast_id":cast_id,"origin":origin,"end":end,"remaining":ProtectorSystem.smite_duration(hero),"damaged_ids":[],"purged_ids":[],"duplicate":false}]
	var wall=ProtectorSystem.intersecting_own_wall(hero,origin,end,combat_blockers)
	if wall!=null and ProtectorSystem.has_talent(hero,"protector_l21_3"):
		var reflected_origin:Vector2=CombatGeometry.reflect_point_across_line(origin,Vector2(wall.from),Vector2(wall.to))
		var reflected_end:Vector2=CombatGeometry.reflect_point_across_line(end,Vector2(wall.from),Vector2(wall.to))
		fields.append({"cast_id":cast_id,"origin":reflected_origin,"end":reflected_end,"remaining":ProtectorSystem.smite_duration(hero),"damaged_ids":fields[0].damaged_ids,"purged_ids":fields[0].purged_ids,"duplicate":true})
		ProtectorSystem.telemetry_add(hero,"law_duplicate_casts")
	for field in fields:
		for target in enemies:
			var id:=str(target.combat_id);if target.hp<=0.0 or id in fields[0].damaged_ids or not protector_smite_geometry_hit(field.origin,field.end,target.pos):continue
			var result:=deal_damage(hero,target,ProtectorSystem.ability_amount(hero,float(ProtectorData.VALUES.e_damage)),"basic_ability","magical","Smite",false,"protector_e",[],true)
			if float(result.get("resolved_damage",0.0))>0.0:
				fields[0].damaged_ids.append(id);ProtectorSystem.telemetry_add(hero,"smite_hits")
				if ProtectorSystem.has_talent(hero,"protector_l18_3") and id not in fields[0].purged_ids:
					var living:Array=[];for ally in heroes:if ally.hp>0.0:living.append(int(ally.battle_index))
					var purge:=ProtectorSystem.clear_highest_other_ally_threat(target,int(hero.battle_index),living)
					fields[0].purged_ids.append(id)
					hero.protector_runtime.last_purge={"enemy_id":id,"hero_index":int(purge.hero_index),"amount":float(purge.amount)}
					if bool(purge.cleared):ProtectorSystem.telemetry_add(hero,"purged_threat",float(purge.amount))
	hero.protector_runtime.smite_fields.append_array(fields)
	AbilitySlotSystem.spend(slot)
	hero.ability_cds[2]=float(AbilitySlotSystem.ui_state(slot).recharge)
	ProtectorSystem.telemetry_add(hero,"smite_casts");ProtectorSystem.telemetry_add(hero,"smite_charge_uses")
	protector_visual("protector_smite",origin,end,.55,{"width":float(ProtectorData.SPACE.e_half_width)})
	return true

func cast_protector_heroic(hero:Dictionary,point:Vector2)->bool:
	var heroic:=str(hero.get("selected_heroic_id",""))
	if heroic=="protector_l15_r1":
		if float(hero.ability_cds[3])>0.0:return false
		var target=protector_enemy_target(hero,ProtectorSystem.judgment_range(hero));if target==null:return false
		hero.protector_runtime.judgment={"target_id":str(target.combat_id),"remaining":float(ProtectorData.VALUES.r1_windup)};hero.ability_cds[3]=ProtectorSystem.judgment_cooldown(hero);ProtectorSystem.telemetry_add(hero,"judgment_casts");protector_visual("protector_judgment_warning",hero.pos,target.pos,float(ProtectorData.VALUES.r1_windup));return true
	if heroic=="protector_l15_r2":
		if float(hero.ability_cds[3])>0.0:return false
		hero.protector_runtime.sanctification_fields.append({"center":Vector2(hero.pos),"remaining":ProtectorSystem.sanctification_duration(hero),"cast_remaining":float(ProtectorData.VALUES.r2_cast)});hero.ability_cds[3]=float(ProtectorData.VALUES.r2_cooldown);ProtectorSystem.telemetry_add(hero,"sanctification_casts");return true
	return false

func cast_protector_trait(hero:Dictionary)->bool:
	if not ProtectorSystem.has_talent(hero,"protector_l30_1") or float(hero.protector_runtime.aspect_cooldown)>0.0 or not hero.protector_runtime.wrath.is_empty():return false
	hero.protector_runtime.wrath={"remaining":float(ProtectorData.VALUES.aspect_channel),"phase":"channel","alive_cast":true,"saved_hp":float(hero.hp)};hero.protector_runtime.aspect_cooldown=float(ProtectorData.VALUES.aspect_cooldown);ProtectorSystem.telemetry_add(hero,"aspect_activations");return true

func cast_protector_ability(slot:int,point:Vector2,_item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Protector" or hero.get("protector_runtime",{}).is_empty():return false
	if not hero.protector_runtime.wrath.is_empty():return false
	match slot:
		0:return cast_protector_q(hero,point)
		1:return cast_protector_w(hero,point)
		2:return cast_protector_e(hero,point)
		3:return cast_protector_heroic(hero,point)
		4:return cast_protector_trait(hero)
	return false

func protector_activate_wall(hero:Dictionary,wall_state:Dictionary)->void:
	var blocker:=CombatGeometry.create_segment_blocker("protector_wall:%s"%str(wall_state.cast_id),wall_state.from,wall_state.to,float(ProtectorData.SPACE.w_thickness),{"owner_combat_id":str(hero.combat_id),"cast_id":str(wall_state.cast_id),"remaining_duration":ProtectorSystem.wall_duration(hero),"blocks_movement":true,"blocks_line_of_sight":false,"blocks_projectiles":false});combat_blockers.append(blocker);wall_state.active=true
	for unit in heroes+enemies:
		if unit.hp>0.0 and not CombatGeometry.valid_position(unit.pos,float(unit.get("combat_radius",28.0)),[blocker]):unit.pos=CombatGeometry.segment_blocker_push_out(unit.pos,float(unit.get("combat_radius",28.0)),blocker);unit.dest=unit.pos
	protector_visual("protector_force_wall",wall_state.from,wall_state.to,ProtectorSystem.wall_duration(hero))

func protector_begin_wrath(hero:Dictionary,alive_cast:bool=false,saved_hp:float=0.0)->void:
	hero.protector_runtime.wrath_resolved=true;hero.protector_runtime.wrath={"remaining":float(ProtectorData.VALUES.trait_duration),"phase":"active","alive_cast":alive_cast,"saved_hp":saved_hp,"source_id":str(hero.combat_id)};hero.spirit_form=true;hero.hp=maxf(1.0,hero.hp);clear_hero_command(hero,"Archangel's Wrath");ProtectorSystem.telemetry_add(hero,"wrath_activations");protector_visual("protector_wrath",hero.pos,hero.pos,float(ProtectorData.VALUES.trait_duration),{"radius":float(ProtectorData.SPACE.wrath_radius)})

func protector_finish_wrath(hero:Dictionary)->void:
	var wrath:Dictionary=hero.protector_runtime.wrath;var alive_cast:=bool(wrath.get("alive_cast",false));var saved_hp:=float(wrath.get("saved_hp",0.0));var source_id:=str(wrath.get("source_id",hero.combat_id))
	for target in enemies:
		if target.hp<=0.0 or target.pos.distance_to(hero.pos)>float(ProtectorData.SPACE.wrath_radius):continue
		var result:=deal_damage(hero,target,ProtectorSystem.ability_amount(hero,float(ProtectorData.VALUES.trait_damage)),"trait","magical","Archangel's Wrath",false,"protector_trait",[],true);if float(result.get("resolved_damage",0.0))>0.0:ProtectorSystem.apply_outgoing_reduction(target,source_id,float(ProtectorData.VALUES.trait_linger));ProtectorSystem.telemetry_add(hero,"wrath_hits")
	hero.spirit_form=false;hero.protector_runtime.wrath={};hero.hp=saved_hp if alive_cast else 0.0;protector_visual("protector_wrath_explosion",hero.pos,hero.pos,.8,{"radius":float(ProtectorData.SPACE.wrath_radius)})

func update_protector_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Protector" or hero.get("protector_runtime",{}).is_empty():continue
		ProtectorSystem.update(hero,delta);var runtime:Dictionary=hero.protector_runtime
		if hero.hp>0.0 and not bool(hero.get("spirit_form",false)):ProtectorSystem.telemetry_add(hero,"time_alive",delta)
		for blocker in combat_blockers:if ProtectorSystem.own_wall(hero,blocker):ProtectorSystem.telemetry_add(hero,"wall_active_seconds",delta)
		if hero.hp<=0.0 and runtime.wrath.is_empty() and not bool(runtime.get("wrath_resolved",false)):protector_begin_wrath(hero,false,0.0)
		if not runtime.wrath.is_empty():
			if str(runtime.wrath.phase)=="channel":runtime.wrath.remaining=float(runtime.wrath.remaining)-delta;if float(runtime.wrath.remaining)<=0.0:protector_begin_wrath(hero,true,float(runtime.wrath.saved_hp))
			else:
				runtime.wrath.remaining=float(runtime.wrath.remaining)-delta
				for target in enemies:if target.hp>0.0 and target.pos.distance_to(hero.pos)<=float(ProtectorData.SPACE.wrath_radius):ProtectorSystem.apply_outgoing_reduction(target,str(hero.combat_id),.15);ProtectorSystem.telemetry_add(hero,"wrath_enemy_seconds",delta)
				if float(runtime.wrath.remaining)<=0.0:protector_finish_wrath(hero)
		if not runtime.q_sequence.is_empty():runtime.q_sequence.remaining=float(runtime.q_sequence.remaining)-delta;if float(runtime.q_sequence.remaining)<=0.0:runtime.q_sequence={}
		if ProtectorSystem.has_talent(hero,"protector_l18_1"):
			runtime.burning_tick=float(runtime.burning_tick)-delta
			if float(runtime.burning_tick)<=0.0:
				runtime.burning_tick=1.0
				protector_burning_halo_tick(hero)
		for wall_index in range(runtime.walls.size()-1,-1,-1):var wall:Dictionary=runtime.walls[wall_index];wall.remaining=float(wall.remaining)-delta;if not bool(wall.active) and float(wall.remaining)<=0.0:protector_activate_wall(hero,wall);runtime.walls.remove_at(wall_index)
		for field_index in range(runtime.smite_fields.size()-1,-1,-1):var field:Dictionary=runtime.smite_fields[field_index];field.remaining=float(field.remaining)-delta;if float(field.remaining)<=0.0:runtime.smite_fields.remove_at(field_index);continue
		for ally in heroes:
			for field in runtime.smite_fields:
				if ally.hp>0.0 and protector_smite_geometry_hit(field.origin,field.end,ally.pos):ally.active_effects=CombatSystem.apply_named_effect(ally.active_effects,{"id":"protector_smite_speed:%s"%str(hero.combat_id),"amount":float(ProtectorData.VALUES.e_speed),"remaining_duration":ProtectorSystem.smite_buff_duration(hero),"movement_speed_multiplier":1.0+float(ProtectorData.VALUES.e_speed),"basic_attack_range_bonus":float(ProtectorData.VALUES.e_reach) if ProtectorSystem.has_talent(hero,"protector_l12_3") else 0.0})
		if not runtime.judgment.is_empty():runtime.judgment.remaining=float(runtime.judgment.remaining)-delta;if float(runtime.judgment.remaining)<=0.0:resolve_protector_judgment(hero);runtime.judgment={}
		for field_index in range(runtime.sanctification_fields.size()-1,-1,-1):var field:Dictionary=runtime.sanctification_fields[field_index];field.cast_remaining=float(field.cast_remaining)-delta;if float(field.cast_remaining)<=0.0:field.remaining=float(field.remaining)-delta;for ally in heroes:if ally.hp>0.0 and ally.pos.distance_to(field.center)<=float(ProtectorData.SPACE.r2_radius):ally.active_effects=CombatSystem.apply_named_effect(ally.active_effects,{"id":"protector_sanctification:%s"%str(hero.combat_id),"remaining_duration":.15,"damage_multiplier":1.0+float(ProtectorData.VALUES.r2_upgrade_damage) if ProtectorSystem.has_talent(hero,"protector_l27_r2") else 1.0});ally.active_effects=CombatSystem.apply_named_effect(ally.active_effects,{"id":"invulnerable","remaining_duration":.15});if float(field.remaining)<=0.0:runtime.sanctification_fields.remove_at(field_index)
		if ProtectorSystem.has_talent(hero,"protector_l9_2"):
			for target in enemies:
				for blocker in combat_blockers:if ProtectorSystem.own_wall(hero,blocker) and CombatGeometry.segment_distance_to_point(blocker.from,blocker.to,target.pos)<=float(ProtectorData.SPACE.w_near_radius):CombatSystem.apply_control(target,"slow",float(ProtectorData.VALUES.w_restraining_linger),float(ProtectorData.VALUES.w_restraining_slow));break

func protector_burning_halo_tick(hero:Dictionary)->void:
	var centers:Array=[{"position":Vector2(hero.pos),"multiplier":1.0+(float(ProtectorData.VALUES.burning_teleport_bonus) if float(hero.protector_runtime.burning_empowered_remaining)>0.0 else 0.0)}]
	if not hero.protector_runtime.q_sequence.is_empty():centers.append({"position":Vector2(hero.protector_runtime.q_sequence.sword_pos),"multiplier":1.0})
	for aura in centers:
		for target in enemies:
			if target.hp<=0.0 or Vector2(aura.position).distance_to(Vector2(target.pos))>float(ProtectorData.SPACE.burning_radius):continue
			var result:=deal_damage(hero,target,ProtectorSystem.ability_amount(hero,float(ProtectorData.VALUES.burning_dps))*float(aura.multiplier),"periodic","magical","Burning Halo",false,"protector_burning",[],false)
			if float(result.get("resolved_damage",0.0))>0.0:ProtectorSystem.telemetry_add(hero,"burning_damage",float(result.resolved_damage))

func resolve_protector_judgment(hero:Dictionary)->void:
	var target=unit_by_combat_id(str(hero.protector_runtime.judgment.target_id));if target==null or target.hp<=0.0:return
	var origin:=Vector2(hero.pos);hero.pos=protector_safe_special_destination(hero,target.pos+target.pos.direction_to(hero.pos)*float(hero.range)*.7);hero.dest=hero.pos
	deal_damage(hero,target,ProtectorSystem.ability_amount(hero,float(ProtectorData.VALUES.r1_damage)),"heroic","magical","Judgment",false,"protector_r1",[],true);CombatSystem.apply_control(target,"stun",float(ProtectorData.VALUES.r1_stun));ProtectorSystem.telemetry_add(hero,"judgment_hits")
	for secondary in enemies:
		if secondary==target or secondary.hp<=0.0 or secondary.pos.distance_to(target.pos)>float(ProtectorData.SPACE.r1_secondary_radius):continue
		deal_damage(hero,secondary,ProtectorSystem.ability_amount(hero,float(ProtectorData.VALUES.r1_secondary_damage)),"heroic","magical","Judgment",false,"protector_r1_secondary",[],true);protector_q_knockback(hero,secondary,target.pos,false)
	protector_visual("protector_judgment",origin,hero.pos,.45,{"radius":float(ProtectorData.SPACE.r1_secondary_radius)})
