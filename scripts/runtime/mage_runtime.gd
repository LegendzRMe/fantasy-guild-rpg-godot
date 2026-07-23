extends "res://scripts/runtime/ranger_runtime.gd"

func mage_target_at(point:Vector2,max_distance:float=80.0):
	var best=null;var best_distance:=max_distance
	for foe in enemies:
		if foe.hp<=0:continue
		var distance:float=foe.pos.distance_to(point)
		if distance<best_distance:best=foe;best_distance=distance
	return best

func mage_is_qualifying_target(target:Dictionary)->bool:
	var tags:Array=target.get("combat_tags",[])
	if float(target.get("hp",0.0))<=0.0 or bool(target.get("object",false)) or tags.any(func(tag):return tag in ["non_qualifying","scenery","damageable_object","destructible_wall","harmless_summon","trivial_swarm","noncombat"]):return false
	if bool(target.get("summoned_unit",false)) and "qualifying_enemy" not in tags and "eligible_hostile_summon" not in tags:return false
	return true

func mage_clamped_point(hero:Dictionary,point:Vector2,range_limit:float)->Vector2:
	var offset:Vector2=point-Vector2(hero.pos)
	var destination:=point if offset.length()<=range_limit else Vector2(hero.pos)+offset.normalized()*range_limit
	return destination.clamp(Vector2(55,70),Vector2(1225,620))

func mage_amount(hero:Dictionary,value:float,pyro:bool=false)->float:
	return MageSystem.scaled_ability_amount(hero,value,pyro)

func mage_flamestrike_amount(hero:Dictionary)->float:
	return MageSystem.flamestrike_amount(hero)

func mage_damage(hero:Dictionary,target:Dictionary,amount:float,action:String,origin:String,can_crit=true)->Dictionary:
	return deal_damage(hero,target,amount,action,"magical" if action!="percentage_health" else "physical",origin,false,"",[],can_crit)

func mage_visual(kind:String,from:Vector2,to:Vector2,duration:float,text_value:String="")->void:
	var life:=maxf(0.08,duration);effects.append({"kind":kind,"from":from,"to":to,"text":text_value,"color":CLASSES["Mage"].color,"life":life,"max_life":life})

func mage_flamestrike_visual(kind:String,center:Vector2,radius:float,duration:float,repeat:bool=false)->void:
	var life:=maxf(0.08,duration)
	effects.append({"kind":kind,"from":center,"to":center,"text":"","color":CLASSES["Mage"].color,"life":life,"max_life":life,"radius":radius,"repeat":repeat})

func mage_presence_reduction(hero:Dictionary,count:int)->void:
	if not MageSystem.has_talent(hero,"mage_l27_r2") or count<=0:return
	var applications:=mini(int(MageData.VALUES.presence_event_ceiling),count);hero.ability_cds[3]=maxf(0.0,float(hero.ability_cds[3])-10.0*applications)

func cast_mage_q(hero:Dictionary,point:Vector2,item_repeat:bool=false)->bool:
	if not item_repeat and float(hero.ability_cds[0])>0.0:return false
	var empowered:bool=false if item_repeat else MageSystem.consume_empowerment(hero,"Q")
	var center:Vector2=mage_clamped_point(hero,point,MageSystem.flamestrike_range(hero));var radius:float=MageSystem.flamestrike_radius(hero,empowered)
	hero.mage_runtime.delayed_effects.append({"kind":"flamestrike","remaining":float(MageData.VALUES.q_warning),"center":center,"radius":radius,"repeat":false})
	mage_flamestrike_visual("mage_flamestrike_warning",center,radius,float(MageData.VALUES.q_warning))
	if not item_repeat:hero.ability_cds[0]=float(MageData.VALUES.q_cooldown);MageSystem.commit_basic_ability(hero)
	MageSystem.telemetry_add(hero,"q_casts");MageSystem.telemetry_add(hero,"q_empowered_casts" if empowered else "q_normal_casts");return true

func apply_living_bomb(hero:Dictionary,target:Dictionary,manual:bool=true,parent:Dictionary={})->Dictionary:
	var state:Dictionary=hero.mage_runtime.bomb_state;var target_id:=str(target.combat_id)
	if manual and LivingBombLineageSystem.has_bomb(state,target_id):detonate_living_bomb(hero,target_id)
	var bomb:=LivingBombLineageSystem.create_primary(state,str(hero.combat_id),target_id,float(MageData.VALUES.w_duration),true) if manual else LivingBombLineageSystem.create_spread(state,parent,target_id,float(MageData.VALUES.w_duration),MageSystem.has_talent(hero,"mage_l30_2"))
	if not bomb.is_empty():
		bomb["last_position"]=target.pos;bomb["damage_multiplier"]=1.35 if bool(bomb.is_spread_bomb) and MageSystem.grants_level_18(hero,"mage_l18_2") else 1.0
		state.bombs_by_target[target_id]=bomb
		MageSystem.telemetry_add(hero,"maximum_concurrent_bombs",0)
		if bool(hero.mage_runtime.telemetry_enabled):hero.mage_runtime.telemetry.maximum_concurrent_bombs=maxi(int(hero.mage_runtime.telemetry.maximum_concurrent_bombs),state.bombs_by_target.size())
	return bomb

func detonate_living_bomb(hero:Dictionary,target_id:String)->int:
	var state:Dictionary=hero.mage_runtime.bomb_state;var bomb:=LivingBombLineageSystem.remove_bomb(state,target_id,true)
	if bomb.is_empty():return 0
	var host=unit_by_combat_id(target_id);var center:Vector2=host.pos if host!=null else Vector2(bomb.get("last_position",hero.pos));var radius:float=MageSystem.bomb_radius(hero)
	var damaged:Array=[]
	for foe in enemies:
		if foe.hp>0 and foe.pos.distance_to(center)<=radius:
			mage_damage(hero,foe,mage_amount(hero,float(MageData.VALUES.w_explosion_damage))*float(bomb.get("damage_multiplier",1.0)),"basic_ability","Living Bomb Explosion");damaged.append(foe)
			if MageSystem.has_talent(hero,"mage_l21_2"):CombatSystem.apply_control(foe,"slow",2.0,0.30)
	MageSystem.telemetry_add(hero,"w_explosions");mage_visual("cast",center,center,0.45,"BOMB")
	var infections:=0
	if bool(bomb.get("may_spread",false)):
		for foe in damaged:
			var candidate_id:=str(foe.combat_id)
			if candidate_id==target_id or not mage_is_qualifying_target(foe) or not LivingBombLineageSystem.can_infect_from(state,bomb,candidate_id):continue
			if not apply_living_bomb(hero,foe,false,bomb).is_empty():infections+=1
	MageSystem.telemetry_add(hero,"spread_infections",infections);mage_presence_reduction(hero,infections)
	LivingBombLineageSystem.cleanup_lineage(state,str(bomb.lineage_id))
	return infections

func cast_mage_w(hero:Dictionary,item_repeat:bool=false)->bool:
	var target_index:=combat_enemy_target()
	if target_index<0 or target_index>=enemies.size():return false
	var target:Dictionary=enemies[target_index]
	if hero.pos.distance_to(target.pos)>float(MageData.SPACE.w_cast_range) or not CombatGeometry.has_line_of_sight(hero.pos,target.pos,combat_blockers):return false
	var empowered:bool=false if item_repeat else MageSystem.trait_is_armed(hero)
	if not item_repeat and not empowered and float(hero.ability_cds[1])>0.0:return false
	if not item_repeat and empowered:
		if float(hero.ability_cds[1])>0.0:MageSystem.telemetry_add(hero,"empowered_w_during_cooldown")
		MageSystem.consume_empowerment(hero,"W");MageSystem.telemetry_add(hero,"w_empowered_casts")
	apply_living_bomb(hero,target,true)
	if not item_repeat:hero.ability_cds[1]=0.0 if empowered else float(MageData.VALUES.w_cooldown);MageSystem.commit_basic_ability(hero)
	MageSystem.telemetry_add(hero,"w_casts");return true

func cast_mage_e(hero:Dictionary,point:Vector2,item_repeat:bool=false)->bool:
	if not item_repeat and float(hero.ability_cds[2])>0.0:return false
	var empowered:bool=false if item_repeat else MageSystem.consume_empowerment(hero,"E")
	var direction:=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var range_limit:float=MageSystem.gravity_range(hero);var candidates:Array=[]
	for foe in enemies:
		if foe.hp<=0:continue
		var offset:Vector2=foe.pos-hero.pos;var projection:=offset.dot(direction)
		if projection>=0.0 and projection<=range_limit and absf(offset.cross(direction))<=float(MageData.SPACE.e_width)*0.5 and CombatGeometry.first_blocker(hero.pos,foe.pos,combat_blockers,"blocks_projectiles")<0:candidates.append({"unit":foe,"projection":projection})
	candidates.sort_custom(func(a,b):return float(a.projection)<float(b.projection) or is_equal_approx(float(a.projection),float(b.projection)) and str(a.unit.combat_id)<str(b.unit.combat_id))
	var maximum_hits:=int(MageData.VALUES.e_empowered_hits) if empowered else 1;var hits:=mini(maximum_hits,candidates.size())
	for index in hits:
		var target:Dictionary=candidates[index].unit;var travel:=float(candidates[index].projection)/maxf(1.0,float(MageData.SPACE.e_speed))
		hero.mage_runtime.delayed_effects.append({"kind":"gravity_lapse","remaining":travel,"target_id":str(target.combat_id),"stun":float(MageData.VALUES.e_empowered_stun if empowered else MageData.VALUES.e_stun),"nether_roil_reduce":index==0})
	mage_visual("mage_gravity",hero.pos,hero.pos+direction*range_limit,range_limit/maxf(1.0,float(MageData.SPACE.e_speed)))
	if not item_repeat:hero.ability_cds[2]=float(MageData.VALUES.e_cooldown);MageSystem.commit_basic_ability(hero)
	MageSystem.telemetry_add(hero,"e_casts");return true

func cast_phoenix(hero:Dictionary,point:Vector2)->bool:
	if not hero.mage_runtime.phoenix.is_empty() and MageSystem.has_talent(hero,"mage_l27_r1") and int(hero.mage_runtime.phoenix.get("reposition_charges",0))>0:
		var destination:=mage_clamped_point(hero,point,float(MageData.SPACE.phoenix_cast_range))
		if not CombatGeometry.valid_position(destination,18.0,combat_blockers) or destination.distance_to(Vector2(hero.mage_runtime.phoenix.pos))<=1.0:return false
		hero.mage_runtime.phoenix.reposition_charges=int(hero.mage_runtime.phoenix.reposition_charges)-1;hero.mage_runtime.phoenix.destination=destination;hero.mage_runtime.phoenix.traveling=true;MageSystem.telemetry_add(hero,"phoenix_repositions");mage_visual("mage_phoenix",hero.mage_runtime.phoenix.pos,destination,Vector2(hero.mage_runtime.phoenix.pos).distance_to(destination)/maxf(1.0,float(MageData.SPACE.phoenix_speed)));return true
	if float(hero.ability_cds[3])>0.0:return false
	var destination:Vector2=mage_clamped_point(hero,point,float(MageData.SPACE.phoenix_cast_range));var duration:float=hero.pos.distance_to(destination)/maxf(1.0,float(MageData.SPACE.phoenix_speed));var hit_ids:={}
	if not CombatGeometry.valid_position(destination,18.0,combat_blockers) or destination.distance_to(hero.pos)<=1.0:return false
	var direction:Vector2=hero.pos.direction_to(destination);var distance:float=hero.pos.distance_to(destination)
	for foe in enemies:
		var projection:float=(foe.pos-hero.pos).dot(direction)
		if mage_is_qualifying_target(foe) and projection>=0.0 and projection<=distance and foe.pos.distance_to(hero.pos+direction*projection)<=float(MageData.SPACE.phoenix_path_width)*0.5:hit_ids[str(foe.combat_id)]=true
	hero.mage_runtime.delayed_effects.append({"kind":"phoenix_arrive","remaining":duration,"destination":destination,"hit_ids":hit_ids})
	mage_visual("mage_phoenix",hero.pos,destination,duration);hero.ability_cds[3]=float(MageData.VALUES.r1_cooldown);MageSystem.telemetry_add(hero,"phoenix_casts");return true

func cast_pyroblast(hero:Dictionary)->bool:
	var target_index:=combat_enemy_target()
	if target_index<0 or target_index>=enemies.size() or float(hero.ability_cds[3])>0.0:return false
	if hero.pos.distance_to(enemies[target_index].pos)>float(MageData.SPACE.pyro_cast_range) or not CombatGeometry.has_line_of_sight(hero.pos,enemies[target_index].pos,combat_blockers):return false
	begin_unit_cast(hero,3,float(MageData.VALUES.r2_cast),true,0.0,true,float(MageData.VALUES.r2_cooldown))
	hero.active_cast.target_id=str(enemies[target_index].combat_id)
	hero.mage_runtime.delayed_effects.append({"kind":"pyro_release","remaining":float(MageData.VALUES.r2_cast),"target_id":str(enemies[target_index].combat_id),"requires_cast":true})
	MageSystem.telemetry_add(hero,"pyro_casts");return true

func cast_mage_heroic(hero:Dictionary,point:Vector2)->bool:
	return cast_phoenix(hero,point) if str(hero.get("selected_heroic_id",""))=="mage_l15_r1" else cast_pyroblast(hero) if str(hero.get("selected_heroic_id",""))=="mage_l15_r2" else false

func cast_mage_ability(slot:int,point:Vector2,item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected]
	if str(hero.get("class",""))!="Mage" or hero.get("mage_runtime",{}).is_empty():return false
	return cast_mage_q(hero,point,item_repeat) if slot==0 else cast_mage_w(hero,item_repeat) if slot==1 else cast_mage_e(hero,point,item_repeat) if slot==2 else cast_mage_heroic(hero,point)

func resolve_flamestrike(hero:Dictionary,effect:Dictionary)->void:
	mage_flamestrike_visual("mage_flamestrike_impact",Vector2(effect.center),float(effect.radius),0.5,bool(effect.get("repeat",false)))
	var hits:Array=[]
	for foe in enemies:
		if foe.hp>0 and foe.pos.distance_to(Vector2(effect.center))<=float(effect.radius):hits.append(foe)
	var qualifying:=hits.filter(func(target):return mage_is_qualifying_target(target))
	if bool(hero.mage_runtime.telemetry_enabled):
		hero.mage_runtime.telemetry.q_targets_per_resolution.append(hits.size())
		if hits.is_empty():MageSystem.telemetry_add(hero,"q_misses")
	var base_amount:=mage_flamestrike_amount(hero)
	for foe in hits:mage_damage(hero,foe,base_amount,"basic_ability","Flamestrike");MageSystem.telemetry_add(hero,"q_hits")
	MageSystem.add_convection_hits(hero,qualifying.size());mage_presence_reduction(hero,mini(int(MageData.VALUES.presence_event_ceiling),qualifying.size()))
	if MageSystem.grants_level_18(hero,"mage_l18_1") and qualifying.size()>=2:
		for target in qualifying:var request:Dictionary=MageSystem.burned_flesh_request(target);mage_damage(hero,target,float(request.amount),"percentage_health","Burned Flesh",false)
	if MageSystem.has_talent(hero,"mage_l30_1") and qualifying.size()>=2:hero.ability_cds[0]=maxf(0.0,float(hero.ability_cds[0])-4.0)
	if MageSystem.has_talent(hero,"mage_l24_2") and not qualifying.is_empty():
		var ignite_candidates:=qualifying.filter(func(target):return target.hp>0 and not LivingBombLineageSystem.has_bomb(hero.mage_runtime.bomb_state,str(target.combat_id)))
		ignite_candidates.sort_custom(func(a,b):return a.pos.distance_squared_to(Vector2(effect.center))<b.pos.distance_squared_to(Vector2(effect.center)) or a.pos.distance_squared_to(Vector2(effect.center))==b.pos.distance_squared_to(Vector2(effect.center)) and str(a.combat_id)<str(b.combat_id))
		if not ignite_candidates.is_empty():apply_living_bomb(hero,ignite_candidates[0],true)
	if MageSystem.has_talent(hero,"mage_l24_1") and not bool(effect.get("repeat",false)):
		hero.mage_runtime.delayed_effects.append({"kind":"flamestrike","remaining":1.5,"center":effect.center,"radius":effect.radius,"repeat":true})
		mage_flamestrike_visual("mage_flamestrike_warning",Vector2(effect.center),float(effect.radius),1.5,true)

func resolve_gravity_lapse(hero:Dictionary,effect:Dictionary)->void:
	var target=unit_by_combat_id(str(effect.target_id));if target==null or target.hp<=0:return
	var result:=CombatSystem.apply_control(target,"stun",float(effect.stun));MageSystem.telemetry_add(hero,"e_hits")
	if bool(result.applied):
		MageSystem.telemetry_add(hero,"stuns_applied")
		if MageSystem.has_talent(hero,"mage_l30_3"):target.active_effects=CombatSystem.apply_named_effect(target.get("active_effects",[]),{"id":"mage_gravity_crush","owner_id":str(hero.combat_id),"remaining_duration":float(MageData.VALUES.gravity_crush_duration)})
	else:MageSystem.telemetry_add(hero,"stuns_resisted")
	if MageSystem.has_talent(hero,"mage_l12_1") and bool(effect.get("nether_roil_reduce",false)):hero.ability_cds[2]=maxf(0.0,float(hero.ability_cds[2])-8.0)

func resolve_pyroblast(hero:Dictionary,effect:Dictionary)->void:
	var target=unit_by_combat_id(str(effect.target_id));if target==null or target.hp<=0:return
	var primary:=mage_amount(hero,float(MageData.VALUES.r2_primary),true);var splash:=mage_amount(hero,float(MageData.VALUES.r2_splash),true);var radius:=float(MageData.SPACE.pyro_splash_radius)*(1.5 if MageSystem.has_talent(hero,"mage_l27_r2") else 1.0)
	mage_damage(hero,target,primary,"heroic","Pyroblast")
	for foe in enemies:if foe.hp>0 and foe!=target and foe.pos.distance_to(target.pos)<=radius:mage_damage(hero,foe,splash,"heroic","Pyroblast Splash")
	mage_visual("heroic",target.pos,target.pos,0.65,"PYROBLAST")

func update_living_bombs(hero:Dictionary,delta:float)->void:
	var state:Dictionary=hero.mage_runtime.bomb_state
	for target_id in state.bombs_by_target.keys().duplicate():
		if not state.bombs_by_target.has(target_id):continue
		var bomb:Dictionary=state.bombs_by_target[target_id];var target=unit_by_combat_id(str(target_id))
		if target!=null:bomb.last_position=target.pos
		bomb.remaining=float(bomb.remaining)-delta;bomb.tick_remaining=float(bomb.tick_remaining)-delta
		if target==null or target.hp<=0:state.bombs_by_target[target_id]=bomb;detonate_living_bomb(hero,str(target_id));continue
		while float(bomb.tick_remaining)<=0.0:
			bomb.tick_remaining=float(bomb.tick_remaining)+float(MageData.VALUES.w_tick);var tick_result:=mage_damage(hero,target,mage_amount(hero,float(MageData.VALUES.w_tick_damage))*float(bomb.damage_multiplier),"periodic","Living Bomb");MageSystem.telemetry_add(hero,"w_ticks")
			if MageSystem.has_talent(hero,"mage_l21_1") and float(tick_result.get("resolved_damage",0.0))>0.0:
				for slot in 3:hero.ability_cds[slot]=maxf(0.0,float(hero.ability_cds[slot])-float(MageData.VALUES.pyromaniac_reduction))
				MageSystem.telemetry_add(hero,"pyromaniac_reduction",float(MageData.VALUES.pyromaniac_reduction))
			if target.hp<=0:break
		state.bombs_by_target[target_id]=bomb
		if target.hp<=0 or float(bomb.remaining)<=0.0:detonate_living_bomb(hero,str(target_id))

func update_phoenix(hero:Dictionary,delta:float)->void:
	var phoenix:Dictionary=hero.mage_runtime.phoenix;if phoenix.is_empty():return
	phoenix.remaining=float(phoenix.remaining)-delta;phoenix.attack_timer=float(phoenix.attack_timer)-delta
	if float(phoenix.remaining)<=0.0:hero.mage_runtime.phoenix={};return
	phoenix.pos=Vector2(phoenix.pos).move_toward(Vector2(phoenix.destination),float(MageData.SPACE.phoenix_speed)*delta)
	if bool(phoenix.get("traveling",false)):
		if Vector2(phoenix.pos).distance_to(Vector2(phoenix.destination))<=1.0:phoenix.traveling=false
		hero.mage_runtime.phoenix=phoenix;return
	while float(phoenix.attack_timer)<=0.0 and float(phoenix.remaining)>0.0:
		phoenix.attack_timer=float(phoenix.attack_timer)+float(MageData.VALUES.r1_attack_interval);var candidates:=enemies.filter(func(foe):return mage_is_qualifying_target(foe) and foe.pos.distance_to(Vector2(phoenix.pos))<=float(MageData.SPACE.phoenix_attack_radius))
		var assigned_id:=""
		if int(hero.get("target",-1))>=0 and int(hero.target)<enemies.size() and enemies[int(hero.target)].hp>0:assigned_id=str(enemies[int(hero.target)].combat_id)
		candidates.sort_custom(func(a,b):
			var a_priority:=0 if str(a.combat_id)==assigned_id and assigned_id!="" else 1 if "boss" in a.get("combat_tags",[]) else 2 if "elite" in a.get("combat_tags",[]) or "named" in a.get("combat_tags",[]) else 4 if bool(a.get("summoned_unit",false)) else 3
			var b_priority:=0 if str(b.combat_id)==assigned_id and assigned_id!="" else 1 if "boss" in b.get("combat_tags",[]) else 2 if "elite" in b.get("combat_tags",[]) or "named" in b.get("combat_tags",[]) else 4 if bool(b.get("summoned_unit",false)) else 3
			return a_priority<b_priority or a_priority==b_priority and (a.pos.distance_squared_to(Vector2(phoenix.pos))<b.pos.distance_squared_to(Vector2(phoenix.pos)) or a.pos.distance_squared_to(Vector2(phoenix.pos))==b.pos.distance_squared_to(Vector2(phoenix.pos)) and str(a.combat_id)<str(b.combat_id)))
		if not candidates.is_empty():
			var target:Dictionary=candidates[0];mage_damage(hero,target,mage_amount(hero,float(MageData.VALUES.r1_attack_damage)),"heroic","Phoenix")
			for foe in enemies:if foe!=target and mage_is_qualifying_target(foe) and foe.pos.distance_to(target.pos)<=float(MageData.SPACE.phoenix_splash_radius):mage_damage(hero,foe,mage_amount(hero,float(MageData.VALUES.r1_splash_damage)),"heroic","Phoenix Splash")
			MageSystem.telemetry_add(hero,"phoenix_hits")
	if float(phoenix.remaining)<=0.0:hero.mage_runtime.phoenix={}
	else:hero.mage_runtime.phoenix=phoenix

func update_pyro_projectiles(hero:Dictionary,delta:float)->void:
	for projectile_index in range(hero.mage_runtime.pyro_projectiles.size()-1,-1,-1):
		var projectile:Dictionary=hero.mage_runtime.pyro_projectiles[projectile_index];var target=unit_by_combat_id(str(projectile.target_id))
		if target==null or target.hp<=0:MageSystem.telemetry_add(hero,"pyro_target_invalidations");hero.mage_runtime.pyro_projectiles.remove_at(projectile_index);continue
		projectile.pos=Vector2(projectile.pos).move_toward(Vector2(target.pos),float(MageData.SPACE.pyro_speed)*delta)
		if Vector2(projectile.pos).distance_to(Vector2(target.pos))<=8.0:
			resolve_pyroblast(hero,projectile);hero.mage_runtime.pyro_projectiles.remove_at(projectile_index)
		else:hero.mage_runtime.pyro_projectiles[projectile_index]=projectile

func update_mage_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Mage" or hero.get("mage_runtime",{}).is_empty():continue
		if hero.hp>0:MageSystem.update(hero,delta)
		else:MageSystem.clear_temporary_state(hero)
		update_living_bombs(hero,delta);update_phoenix(hero,delta);update_pyro_projectiles(hero,delta)
		for effect_index in range(hero.mage_runtime.delayed_effects.size()-1,-1,-1):
			var effect:Dictionary=hero.mage_runtime.delayed_effects[effect_index];effect.remaining=float(effect.remaining)-delta
			if float(effect.remaining)>0.0:hero.mage_runtime.delayed_effects[effect_index]=effect;continue
			match str(effect.kind):
				"flamestrike":resolve_flamestrike(hero,effect)
				"gravity_lapse":resolve_gravity_lapse(hero,effect)
				"phoenix_arrive":
					for target_id in effect.hit_ids:var target=unit_by_combat_id(str(target_id));if target!=null and target.hp>0:mage_damage(hero,target,mage_amount(hero,float(MageData.VALUES.r1_travel_damage)),"heroic","Phoenix Path")
					hero.mage_runtime.phoenix={"pos":effect.destination,"destination":effect.destination,"remaining":14.0 if MageSystem.has_talent(hero,"mage_l27_r1") else float(MageData.VALUES.r1_duration),"attack_timer":0.0,"reposition_charges":int(MageData.VALUES.rebirth_charges) if MageSystem.has_talent(hero,"mage_l27_r1") else 0}
				"pyro_release":
					if hero.get("active_cast",{}).is_empty():MageSystem.telemetry_add(hero,"pyro_interrupts")
					else:
						var target=unit_by_combat_id(str(effect.target_id))
						if target!=null and target.hp>0:hero.mage_runtime.pyro_projectiles.append({"pos":hero.pos,"target_id":effect.target_id});MageSystem.telemetry_add(hero,"pyro_projectiles_released")
			hero.mage_runtime.delayed_effects.remove_at(effect_index)
