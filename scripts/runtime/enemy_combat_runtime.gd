extends "res://scripts/runtime/item_combat_runtime.gd"

func begin_next_wave() -> void:
	wave_index+=1
	if current_ashwood_encounter!="":
		current_wave_roles=ashwood_wave_roles(wave_index)
		wave_spawn_remaining=current_wave_roles.size()
		spawn_timer=.2
		return
	wave_spawn_remaining=2+int(encounter_id/2.0)+(1 if dungeon_id>0 else 0); spawn_timer=.2
	if wave_index==total_waves: wave_spawn_remaining+=1

func ashwood_wave_roles(wave_number:int) -> Array:
	var encounter_data:=AshwoodData.encounter(current_ashwood_encounter,state.zone0)
	var roles:Array=[]
	if current_ashwood_encounter=="finale" and wave_number==1:
		roles=AshwoodManager.finale_opening_roles(state.zone0)
	elif wave_number>0 and wave_number<=encounter_data.waves.size():
		roles=encounter_data.waves[wave_number-1].duplicate()
	if state.zone0.raiders_chased and current_ashwood_encounter in ["crossing","finale"] and wave_number==2 and roles.size()>1:
		roles.pop_back()
	if current_ashwood_encounter=="caravan" and state.zone0.approach_choice=="investigate" and wave_number==2:
		roles.append("Swift")
	return roles

func spawn_wave_enemy() -> void:
	if current_ashwood_encounter!="":
		var role_index=current_wave_roles.size()-wave_spawn_remaining
		var ashwood_role:String=current_wave_roles[clampi(role_index,0,current_wave_roles.size()-1)]
		var encounter_data:=AshwoodData.encounter(current_ashwood_encounter,state.zone0)
		var ashwood_side:int=ashwood_spawn_count%4 if bool(encounter_data.get("spawn_all_sides",false)) else (wave_index+wave_spawn_remaining)%4
		var ashwood_entry=[Vector2(1200,130+(wave_spawn_remaining*97)%390),Vector2(300+(wave_spawn_remaining*151)%800,85),Vector2(80,540-(wave_spawn_remaining*89)%390),Vector2(320+(wave_spawn_remaining*127)%760,555)][ashwood_side]
		spawn_enemy(ashwood_entry,ashwood_role);ashwood_spawn_count+=1;wave_spawn_remaining-=1;spawn_timer=float(encounter_data.get("spawn_interval",.55))
		return
	var is_boss=wave_index==total_waves and wave_spawn_remaining==1
	var role="Boss" if is_boss else GameData.WAVE_ENEMY_ROLES[(wave_index+wave_spawn_remaining+encounter_id)%GameData.WAVE_ENEMY_ROLES.size()]
	var side=(wave_index+wave_spawn_remaining)%4; var entry=[Vector2(1200,120+(wave_spawn_remaining*97)%410),Vector2(260+(wave_spawn_remaining*151)%850,75),Vector2(1200,545-(wave_spawn_remaining*89)%410),Vector2(280+(wave_spawn_remaining*127)%820,565)][side]
	spawn_enemy(entry,role)
	if is_boss and str(current_campaign_battle.get("region_id",""))=="grand_corruption_front" and str(current_campaign_battle.get("location_id",""))=="gateway_site":enemies[-1].type="Nazareth";enemies[-1].name="Nazareth"
	wave_spawn_remaining-=1; spawn_timer=.65

func spawn_enemy(pos:Vector2,type:String) -> void:
	var enemy:=GameData.create_enemy(type,pos,dungeon_id)
	enemy=CombatRulesV1.initialize_unit(enemy,"enemy:%d"%next_enemy_combat_id,"enemy");next_enemy_combat_id+=1

	if current_ashwood_encounter!="":
		var encounter_data:=AshwoodData.encounter(current_ashwood_encounter,state.zone0)
		var health_overrides:Dictionary=encounter_data.get("enemy_health_overrides",{})
		if health_overrides.has(type):enemy.hp=float(health_overrides[type]);enemy.max_hp=enemy.hp
		else:
			var health_multiplier:=float(encounter_data.get("enemy_health_multiplier",1.0))
			enemy.hp*=health_multiplier;enemy.max_hp*=health_multiplier
		var objective_type:=str(battle_objective.get("type",""))
		var objective_aggro_chance:=float(battle_objective.get("objective_aggro_chance",1.0 if objective_type=="protect_task" else 0.0))
		if objective_type in ["protect_task","protect_caravan"] and not objective_complete and randf()<objective_aggro_chance:
			enemy.objective_threat=float(battle_objective.get("objective_threat",24.0))
			enemy.target=OBJECTIVE_THREAT_TARGET
			if bool(enemy.get("prefers_backline",false)):
				var backline_target:int=nearest_backline_hero(enemy.pos)
				if backline_target>=0:enemy.threat[backline_target]=30.0
	enemies.append(enemy)

func damage_battle_objective(amount:float,source_position:Vector2) -> void:
	if amount<=0 or not objective_is_threat_target():return
	if str(battle_objective.get("type",""))=="protect_caravan":
		objective_health=max(0.0,objective_health-amount)
		objective_progress=objective_health/max(1.0,objective_max_health)
		add_effect("hit",source_position,objective_actor_pos,"CARAVAN -%d"%int(amount),C_RED)
		if objective_health<=0 and not battle_over:
			set_objective_notice("The caravan has been destroyed!",3.5)
			finish_battle(false)
	else:
		objective_progress=max(0.0,objective_progress-.055)
		add_effect("hit",source_position,objective_actor_pos,"SIGNAL HIT",C_RED)

func update_ashwood_objective(delta:float) -> void:
	if current_ashwood_encounter=="" or battle_objective.is_empty():return
	var objective_type:=str(battle_objective.type)
	if objective_type in ["protect_task","ritual_defense"] and not objective_complete:
		var threatened:=false
		for enemy in enemies:
			if enemy.hp>0 and enemy.pos.distance_to(objective_actor_pos)<100:threatened=true;break
		if threatened:
			objective_progress=max(min(objective_progress,.08),objective_progress-delta*.018)
		else:
			objective_progress=min(1.0,objective_progress+delta/max(1.0,float(battle_objective.duration)))
		if objective_progress>=.75 and not objective_pressure_spawned:
			objective_pressure_spawned=true
			spawn_enemy(Vector2(1180,210),"Brute");spawn_enemy(Vector2(1180,455),"Swift")
			set_objective_notice("The final pressure wave has arrived!",3.0)
		if objective_progress>=1.0:
			objective_complete=true
			if objective_type=="ritual_defense":complete_ashwood_ritual()
			else:
				var rescue_source:={"name":"Signal Rescue","critical_chance":0.0,"critical_damage":2.0,"equipped_items":[],"active_effects":[],"passive_cooldowns":{},"pos":objective_actor_pos}
				for enemy in enemies:
					if enemy.hp>0:deal_damage(rescue_source,enemy,180.0,"basic_ability","physical","signal_rescue")
				add_first_recruit_to_battle()
				set_objective_notice("The signal is complete — the rescued fighter joins the attack!",3.5)
	elif objective_type=="survival" and not objective_complete:
		objective_progress=min(1.0,objective_progress+delta/max(1.0,float(battle_objective.duration)))
		if objective_progress>=1.0:
			objective_complete=true
			for enemy in enemies:enemy.hp=0
			set_objective_notice("The crossing holds. The remaining attackers break and flee.",3.5)
	if objective_type in ["rune_survival","rune_boss","finale","survival"] and (objective_type!="finale" or wave_index>=total_waves):
		update_ashwood_rune(delta)

func update_objective_banner(delta:float) -> void:
	objective_banner_time=max(0.0,objective_banner_time-delta)

func set_objective_notice(text_value:String,duration:float=3.5) -> void:
	objective_notice=text_value
	objective_notice_time=duration

func update_objective_notice(delta:float) -> void:
	if objective_notice_time<=0:return
	objective_notice_time=max(0.0,objective_notice_time-delta)
	if objective_notice_time<=0:objective_notice=""

func update_ashwood_rune(delta:float) -> void:
	if rune_active:
		rune_charge+=delta
		var warning_time:=3.1 if state.zone0.optional_mini_boss_defeated else 2.35
		rune_radius=lerp(24.0,118.0,clamp(rune_charge/warning_time,0.0,1.0))

		if rune_charge>=warning_time:
			var rune_source:={"name":"Ashwood Rune","critical_chance":0.0,"critical_damage":2.0,"equipped_items":[],"active_effects":[],"passive_cooldowns":{},"pos":rune_center}
			for hero in heroes:
				if hero.hp>0 and hero.pos.distance_to(rune_center)<118:
					var damage=58.0 if current_ashwood_encounter=="finale" else 46.0
					var rune_result:=deal_damage(rune_source,hero,damage,"periodic","magical","ashwood_rune");hero.last_hit=3;add_effect("hit",rune_center,hero.pos,"-%d"%int(rune_result.resolved_damage),C_RED)
			rune_active=false;rune_timer=0;rune_charge=0;rune_radius=0
		return
	rune_timer+=delta
	if rune_timer>=6.2 and not heroes.is_empty():
		rune_active=true;rune_charge=0;rune_center=heroes[(wave_index+selected)%heroes.size()].pos

func ashwood_combat_complete() -> bool:
	if current_ashwood_encounter=="":return wave_index==total_waves and wave_spawn_remaining==0 and enemies.size()>0 and enemies.all(func(enemy):return enemy.hp<=0)
	var all_waves_done=wave_index==total_waves and wave_spawn_remaining==0
	var all_enemies_down=not enemies.is_empty() and enemies.all(func(enemy):return enemy.hp<=0)
	if str(battle_objective.get("type",""))=="protect_caravan":return all_waves_done and all_enemies_down and objective_health>0
	return all_waves_done and all_enemies_down and objective_complete

func lowest_hero()->int:
	var idx=-1; var ratio=2.0
	for i in heroes.size(): if heroes[i].hp>0 and not bool(heroes[i].get("spirit_form",false)) and heroes[i].hp/heroes[i].max_hp<ratio: ratio=heroes[i].hp/heroes[i].max_hp; idx=i
	return idx

func nearest_wounded_hero(pos:Vector2)->int:
	var idx=-1;var distance=99999.0
	for i in heroes.size():
		if heroes[i].hp>0 and not bool(heroes[i].get("spirit_form",false)) and heroes[i].hp<heroes[i].max_hp:
			var ally_distance=pos.distance_to(heroes[i].pos)
			if ally_distance<distance:distance=ally_distance;idx=i
	return idx

func nearest_living_hero(pos:Vector2)->int:
	var idx=-1; var dist=99999.0
	for i in heroes.size():
		if heroes[i].hp>0 and not bool(heroes[i].get("spirit_form",false)):
			var d=pos.distance_to(heroes[i].pos)*(0.55 if heroes[i]["class"]=="Guardian" else 1.0); if d<dist:dist=d;idx=i
	return idx

func nearest_hero_in_range(pos:Vector2,range_limit:float)->int:

	var idx:=-1;var closest:=range_limit
	for i in heroes.size():
		if heroes[i].hp<=0 or bool(heroes[i].get("spirit_form",false)):continue
		var distance:=pos.distance_to(heroes[i].pos)
		if distance<=closest:closest=distance;idx=i
	return idx

func nearest_living_enemy(pos:Vector2,max_distance:float=INF)->int:
	var idx=-1;var distance=99999.0
	for i in enemies.size():
		if enemies[i].hp>0:
			var enemy_distance=pos.distance_to(enemies[i].pos)
			if enemy_distance<=max_distance and enemy_distance<distance:distance=enemy_distance;idx=i
	return idx

func nearest_backline_hero(pos:Vector2) -> int:
	var best:int=-1
	var distance:float=INF
	for hero_index in heroes.size():
		if heroes[hero_index].hp<=0 or bool(heroes[hero_index].get("spirit_form",false)) or heroes[hero_index]["class"]=="Guardian":continue
		var candidate_distance:float=pos.distance_to(heroes[hero_index].pos)
		if candidate_distance<distance:distance=candidate_distance;best=hero_index
	return best

func objective_is_threat_target() -> bool:
	if current_ashwood_encounter=="":return false
	var objective_type:=str(battle_objective.get("type",""))
	return objective_type=="protect_caravan" and objective_health>0 or objective_type=="protect_task" and not objective_complete

func enemy_target_threat(enemy:Dictionary,target_index:int) -> float:
	if target_index==OBJECTIVE_THREAT_TARGET:return float(enemy.get("objective_threat",0.0)) if objective_is_threat_target() else -1.0
	if target_index<0 or target_index>=heroes.size() or heroes[target_index].hp<=0 or bool(heroes[target_index].get("spirit_form",false)):return -1.0
	return float(enemy.get("threat",{}).get(target_index,0.0))

func reduce_hero_threat(hero_index:int,reduction:float)->void:
	if hero_index<0 or hero_index>=heroes.size():return
	var multiplier:float=1.0-clampf(reduction,0.0,1.0)
	for enemy in enemies:
		var threat_table:Dictionary=enemy.get("threat",{})
		if not threat_table.has(hero_index):continue
		threat_table[hero_index]=maxf(0.0,float(threat_table.get(hero_index,0.0))*multiplier)
		enemy.threat=threat_table

func taunt_enemy(enemy:Dictionary,hero_index:int) -> void:
	if bool(enemy.get("ignores_tank_aggro",false)):return
	var highest_threat:float=float(enemy.get("objective_threat",0.0))
	for threat_value in enemy.get("threat",{}).values():highest_threat=max(highest_threat,float(threat_value))
	var threat_table:Dictionary=enemy.get("threat",{})
	var nearby:bool=enemy.pos.distance_to(heroes[hero_index].pos)<=CombatSystem.AGGRO_DISTANCE_THRESHOLD
	threat_table[hero_index]=max(float(threat_table.get(hero_index,0.0)),CombatSystem.required_aggro_threat(highest_threat,nearby)+1.0)
	enemy.threat=threat_table;enemy.taunt_target=hero_index;enemy.taunt_time=CHALLENGE_TAUNT_DURATION;enemy.target=hero_index

func preferred_enemy_target(enemy:Dictionary)->int:
	var forced_index:=ForcedTargetSystem.preferred(enemy)
	if forced_index>=0 and forced_index<heroes.size() and heroes[forced_index].hp>0.0:return forced_index
	if bool(enemy.get("ignores_tank_aggro",false)):
		var fixate_target:int=nearest_backline_hero(enemy.pos)
		return fixate_target if fixate_target>=0 else nearest_living_hero(enemy.pos)
	var taunt_target:int=int(enemy.get("taunt_target",-1))
	if float(enemy.get("taunt_time",0.0))>0 and taunt_target>=0 and taunt_target<heroes.size() and heroes[taunt_target].hp>0:return taunt_target
	if not objective_is_threat_target() and enemy.get("threat",{}).is_empty() and bool(enemy.get("prefers_backline",false)):
		var opening_backline_target:int=nearest_backline_hero(enemy.pos)
		if opening_backline_target>=0:return opening_backline_target
	var best_target:int=OBJECTIVE_THREAT_TARGET if objective_is_threat_target() and float(enemy.get("objective_threat",0.0))>0 else -1
	var best_threat:float=enemy_target_threat(enemy,best_target)
	for hero_index in heroes.size():
		var hero_threat:float=enemy_target_threat(enemy,hero_index)
		if hero_threat>best_threat:best_threat=hero_threat;best_target=hero_index
	if best_target>=0 or best_target==OBJECTIVE_THREAT_TARGET:
		var current_target:int=int(enemy.get("target",-1))
		var current_threat:float=enemy_target_threat(enemy,current_target)
		var challenger_nearby:bool=best_target>=0 and enemy.pos.distance_to(heroes[best_target].pos)<=CombatSystem.AGGRO_DISTANCE_THRESHOLD
		if current_threat>0 and current_target!=best_target and best_threat<CombatSystem.required_aggro_threat(current_threat,challenger_nearby):return current_target
		return best_target

	if bool(enemy.get("prefers_backline",false)) or enemy.type=="Boss" and enemy.special_index%3==1:
		var backline_target:int=nearest_backline_hero(enemy.pos)
		if backline_target>=0:return backline_target
	return nearest_living_hero(enemy.pos)

func combat_enemy_target() -> int:
	if focused_enemy_index>=0 and focused_enemy_index<enemies.size() and enemies[focused_enemy_index].hp>0:return focused_enemy_index
	if selected>=0 and selected<heroes.size():
		var assigned_target:=int(heroes[selected].target)
		if assigned_target>=0 and assigned_target<enemies.size() and enemies[assigned_target].hp>0:return assigned_target
	return -1
