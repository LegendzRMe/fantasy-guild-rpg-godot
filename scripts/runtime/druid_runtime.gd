extends "res://scripts/runtime/huntsman_runtime.gd"

func druid_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Druid.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func druid_ally_by_id(id:String):
	for ally in heroes:if str(ally.get("combat_id",""))==id:return ally
	return null

func druid_selected_ally(hero:Dictionary,allow_self:bool=true):
	var index:=int(hero.get("heal_target",-1))
	if index<0 or index>=heroes.size():return null
	var ally:Dictionary=heroes[index]
	if ally.hp<=0.0 or (not allow_self and ally==hero) or hero.pos.distance_to(ally.pos)>float(DruidData.SPACE.regrowth_range):return null
	return ally

func druid_heal(hero:Dictionary,target:Dictionary,amount:float,action:String,origin:String,effect_id:String,tags:Array=[])->Dictionary:
	var result:=deal_healing(hero,target,amount,action,origin,effect_id,tags)
	hero.druid_runtime.recent_healing=float(result.effective_amount);hero.druid_runtime.recent_overhealing=float(result.overhealing)
	return result

func druid_resolve_regrowth_tick(hero:Dictionary,tick:Dictionary,bonus:bool=false)->void:
	var target=druid_ally_by_id(str(tick.target_id));if target==null or target.hp<=0.0:return
	var result:=druid_heal(hero,target,DruidSystem.regrowth_tick_request(hero),"periodic","Verdant Pulse" if bonus else "Regrowth","druid_regrowth",["healing_over_time","periodic_healing","regrowth"])
	DruidSystem.telemetry_add(hero,"verdant_ticks" if bonus else "regrowth_ticks");DruidSystem.telemetry_add(hero,"regrowth_healing",float(result.effective_amount));DruidSystem.telemetry_add(hero,"regrowth_overhealing",float(result.overhealing));druid_visual("druid_regrowth_tick",hero.pos,target.pos,.35)
	if DruidSystem.has_talent(hero,"druid_l21_1") and float(result.overhealing)>0.0:
		var candidates:=heroes.filter(func(ally):return ally!=target and ally.hp>0.0);candidates.sort_custom(func(left,right):var ld:float=Vector2(target.pos).distance_squared_to(Vector2(left.pos));var rd:float=Vector2(target.pos).distance_squared_to(Vector2(right.pos));return str(left.combat_id)<str(right.combat_id) if is_equal_approx(ld,rd) else ld<rd)
		if not candidates.is_empty():druid_heal(hero,candidates[0],float(result.overhealing),"basic_ability","Nature's Swiftness","druid_natures_swiftness",["healing"]);druid_visual("druid_swiftness",target.pos,candidates[0].pos,.35)

func druid_cast_regrowth(hero:Dictionary)->bool:
	if float(hero.ability_cds[0])>0.0:return false
	var target=druid_selected_ally(hero,true);if target==null:return false
	var snapshot_missing:=maxf(0.0,float(target.max_hp)-float(target.hp));var cast:=DruidSystem.apply_regrowth(hero,target,true)
	if float(cast.lifebloom_fraction)>0.0:druid_heal(hero,target,snapshot_missing*float(cast.lifebloom_fraction),"basic_ability","Lifebloom","druid_lifebloom",["healing"]);druid_visual("druid_lifebloom",hero.pos,target.pos,.35)
	DruidSystem.apply_rejuvenation(hero,target);hero.ability_cds[0]=float(DruidData.VALUES.q_cooldown);druid_visual("druid_regrowth",hero.pos,target.pos,.5,{"duration":float(cast.duration)});return true

func druid_resolve_moonfire(hero:Dictionary,point:Vector2,free_cast:bool=false)->Dictionary:
	var contacts:Array=[]
	for target in enemies:if target.hp>0.0 and target.pos.distance_to(point)<=DruidSystem.moonfire_radius(hero)+float(target.get("combat_radius",28.0)):contacts.append(target)
	var plan:=DruidSystem.moonfire_plan(hero,contacts,free_cast)
	for target in contacts:
		var result:=deal_damage(hero,target,float(plan.damage),"basic_ability","magical","Moonfire",false,"druid_moonfire",[],true);DruidSystem.telemetry_add(hero,"moonfire_damage",float(result.resolved_damage));StealthDetectionSystem.reveal(target,float(plan.reveal));target.active_effects=CombatSystem.apply_named_effect(target.get("active_effects",[]),{"id":"druid_moonfire_reveal:%s"%str(hero.combat_id),"owner_id":str(hero.combat_id),"remaining_duration":float(plan.reveal)});DruidSystem.telemetry_add(hero,"moonfire_reveals")
	if int(plan.count)>0:
		for regrowth in DruidSystem.active_regrowths(hero):
			var ally=druid_ally_by_id(str(regrowth.target_id));if ally!=null and ally.hp>0.0:var healing:=druid_heal(hero,ally,float(plan.combined_heal),"basic_ability","Moonfire","druid_moonfire_heal",["healing"]);DruidSystem.telemetry_add(hero,"moonfire_healing",float(healing.effective_amount));druid_visual("druid_moonfire_heal",point,ally.pos,.4)
		if float(plan.extension)>0.0:DruidSystem.extend_all_regrowths(hero,float(plan.extension));druid_visual("druid_wild_growth",hero.pos,hero.pos,.5)
		hero.ability_cds[2]=maxf(0.0,float(hero.ability_cds[2])-float(plan.roots_cdr));hero.ability_cds[3]=maxf(0.0,float(hero.ability_cds[3])-float(plan.serenity_cdr));DruidSystem.telemetry_add(hero,"lunar_roots_cdr",float(plan.roots_cdr));DruidSystem.telemetry_add(hero,"serenity_cdr",float(plan.serenity_cdr))
		if DruidSystem.has_talent(hero,"druid_l30_2") and not free_cast:hero.ability_cds[1]=maxf(0.0,float(hero.ability_cds[1])-float(DruidData.VALUES.lunar_shower_cdr));DruidSystem.telemetry_add(hero,"lunar_shower")
	druid_visual("druid_moonfire",point,point,.5,{"radius":DruidSystem.moonfire_radius(hero)});return plan

func druid_cast_moonfire(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[1])>0.0:return false
	var destination:Vector2=Vector2(hero.pos)+(point-Vector2(hero.pos)).limit_length(float(DruidData.SPACE.moonfire_range));hero.ability_cds[1]=float(DruidData.VALUES.w_cooldown);druid_resolve_moonfire(hero,destination,false);return true

func druid_cast_roots(hero:Dictionary,point:Vector2,secondary:bool=false)->bool:
	if not secondary and float(hero.ability_cds[2])>0.0:return false
	var destination:Vector2=Vector2(hero.pos)+(point-Vector2(hero.pos)).limit_length(float(DruidData.SPACE.roots_range));hero.druid_runtime.roots_areas.append(DruidSystem.create_roots_area(hero,destination,secondary))
	if not secondary:
		hero.ability_cds[2]=float(DruidData.VALUES.e_cooldown);DruidSystem.telemetry_add(hero,"roots_casts")
		if DruidSystem.has_talent(hero,"druid_l9_2"):hero.druid_runtime.treants.append(DruidSystem.create_treant(hero,destination));druid_visual("druid_treant",destination,destination,.8)
	else:DruidSystem.telemetry_add(hero,"deep_roots_casts")
	druid_visual("druid_roots",destination,destination,.6,{"radius":float(DruidData.SPACE.roots_initial_radius)});return true

func druid_cast_innervate(hero:Dictionary)->bool:
	var target=druid_selected_ally(hero,false);if target==null:return false
	var result:=DruidSystem.cast_innervate(hero,target);if not bool(result.cast):return false
	if float(result.communion)>0.0:var healing:=druid_heal(hero,target,float(result.communion),"basic_ability","Nature's Communion","druid_nature_communion",["healing"]);DruidSystem.telemetry_add(hero,"communion_healing",float(healing.effective_amount));druid_visual("druid_communion",hero.pos,target.pos,.6)
	druid_visual("druid_innervate",hero.pos,target.pos,.55);return true

func druid_resolve_twilight(hero:Dictionary,point:Vector2)->void:
	DruidSystem.refresh_all_regrowths(hero)
	var silence:=float(DruidData.VALUES.twilight_silence)+float(DruidData.VALUES.astral_silence_bonus if DruidSystem.has_talent(hero,"druid_l27_r2") else 0.0)
	for target in enemies:
		if target.hp<=0.0 or target.pos.distance_to(point)>float(DruidData.SPACE.twilight_radius)+float(target.get("combat_radius",28.0)):continue
		var damage:=deal_damage(hero,target,DruidSystem.power_scaled(hero,float(DruidData.VALUES.twilight_damage)),"heroic","magical","Twilight Dream",false,"druid_twilight",[],true);DruidSystem.telemetry_add(hero,"twilight_damage",float(damage.resolved_damage));var control:=CombatSystem.apply_control(target,"silence",silence);if bool(control.applied):DruidSystem.telemetry_add(hero,"twilight_silence")
	druid_visual("druid_twilight",point,point,.7,{"radius":float(DruidData.SPACE.twilight_radius)})

func druid_cast_heroic(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[3])>0.0:return false
	if str(hero.selected_heroic_id)=="druid_l15_r1":hero.ability_cds[3]=float(DruidData.VALUES.tranquility_cooldown);hero.druid_runtime.tranquility_remaining=float(DruidData.VALUES.tranquility_duration);hero.druid_runtime.tranquility_tick=1.0;druid_visual("druid_tranquility",hero.pos,hero.pos,.8,{"radius":float(DruidData.SPACE.tranquility_radius)});return true
	if str(hero.selected_heroic_id)=="druid_l15_r2":
		if DruidSystem.has_talent(hero,"druid_l27_r2"):
			hero.druid_runtime.astral_pending=float(DruidData.VALUES.astral_channel);hero.druid_runtime.astral_point=hero.pos+(point-hero.pos).limit_length(float(DruidData.SPACE.astral_range));hero.ability_cds[3]=float(DruidData.VALUES.twilight_cooldown);return true
		hero.druid_runtime.twilight_pending=float(DruidData.VALUES.twilight_delay);hero.druid_runtime.twilight_point=hero.pos;hero.ability_cds[3]=float(DruidData.VALUES.twilight_cooldown);return true
	return false

func cast_druid_ability(slot:int,point:Vector2,_item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Druid" or hero.get("druid_runtime",{}).is_empty():return false
	match slot:
		0:return druid_cast_regrowth(hero)
		1:return druid_cast_moonfire(hero,point)
		2:return druid_cast_roots(hero,point)
		3:return druid_cast_heroic(hero,point)
		4:return druid_cast_innervate(hero)
	return false

func update_druid_roots(hero:Dictionary,delta:float)->void:
	for index in range(hero.druid_runtime.roots_areas.size()-1,-1,-1):
		var area:Dictionary=hero.druid_runtime.roots_areas[index];area.elapsed=float(area.elapsed)+delta;area.remaining=float(area.remaining)-delta;var any_success:=false
		for target in enemies:
			var id:=str(target.combat_id);if target.hp<=0.0 or id in area.contact_ids or target.pos.distance_to(area.point)>DruidSystem.roots_radius(hero,float(area.elapsed),bool(area.secondary))+float(target.get("combat_radius",28.0)):continue
			area.contact_ids.append(id);var damage:=deal_damage(hero,target,DruidSystem.power_scaled(hero,float(DruidData.VALUES.roots_damage)),"basic_ability","magical","Entangling Roots",false,"druid_roots_secondary" if bool(area.secondary) else "druid_roots",[],true);var control:=CombatSystem.apply_control(target,"root",float(DruidData.VALUES.roots_duration));var root_result:=DruidSystem.note_root_result(hero,target,bool(control.applied),bool(area.secondary));any_success=any_success or bool(control.applied)
			if float(root_result.emerald)>0.0:var reduced:=minf(float(root_result.emerald),float(hero.druid_runtime.d_slot.timers[0]) if not hero.druid_runtime.d_slot.timers.is_empty() else 0.0);AbilitySlotSystem.reduce_active_recharge(hero.druid_runtime.d_slot,float(root_result.emerald));DruidSystem.telemetry_add(hero,"emerald_cdr",reduced)
		if any_success and not bool(area.verdant_fired) and not bool(area.secondary) and DruidSystem.has_talent(hero,"druid_l18_2"):
			area.verdant_fired=true;for tick in DruidSystem.bonus_regrowth_ticks(hero):druid_resolve_regrowth_tick(hero,tick,true);DruidSystem.telemetry_add(hero,"verdant_activations")
		if float(area.remaining)<=0.0:hero.druid_runtime.roots_areas.remove_at(index)
		else:hero.druid_runtime.roots_areas[index]=area

func update_druid_treants(hero:Dictionary,delta:float)->void:
	for index in range(hero.druid_runtime.treants.size()-1,-1,-1):
		var treant:Dictionary=hero.druid_runtime.treants[index];treant.lifetime=float(treant.lifetime)-delta;treant.hp=maxf(0.0,float(treant.hp)-DruidData.scaled(float(DruidData.VALUES.treant_health_decay),int(hero.level))*delta);treant.attack_cooldown=maxf(0.0,float(treant.attack_cooldown)-delta);DruidSystem.telemetry_add(hero,"treant_lifetime",delta)
		if float(treant.lifetime)<=0.0 or float(treant.hp)<=0.0:hero.druid_runtime.treants.remove_at(index);continue
		var candidates:=enemies.filter(func(target):return target.hp>0.0 and Vector2(target.pos).distance_to(Vector2(treant.pos))<=float(DruidData.SPACE.treant_acquire_range));candidates.sort_custom(func(left,right):var ld:float=Vector2(treant.pos).distance_squared_to(Vector2(left.pos));var rd:float=Vector2(treant.pos).distance_squared_to(Vector2(right.pos));return str(left.combat_id)<str(right.combat_id) if is_equal_approx(ld,rd) else ld<rd)
		if not candidates.is_empty():
			var target:Dictionary=candidates[0];var distance:float=Vector2(treant.pos).distance_to(Vector2(target.pos))
			if distance>float(DruidData.SPACE.treant_attack_range):treant.pos=treant.pos.move_toward(target.pos,float(DruidData.VALUES.treant_speed)*delta)
			elif float(treant.attack_cooldown)<=0.0:var result:=deal_damage(hero,target,DruidSystem.treant_damage(hero),"summon","physical","Treant",true,"druid_treant",[],false);treant.attack_cooldown=float(DruidData.VALUES.treant_interval);DruidSystem.telemetry_add(hero,"treant_attacks");DruidSystem.telemetry_add(hero,"treant_damage",float(result.resolved_damage));druid_visual("druid_treant_attack",treant.pos,target.pos,.25)
		hero.druid_runtime.treants[index]=treant

func update_druid_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Druid" or hero.get("druid_runtime",{}).is_empty():continue
		var update:=DruidSystem.advance(hero,delta)
		for tick in update.regrowth_ticks:druid_resolve_regrowth_tick(hero,tick,false)
		for tick in update.mini_hot_ticks:
			var target=druid_ally_by_id(str(tick.target_id));if target!=null and target.hp>0.0:var result:=druid_heal(hero,target,DruidSystem.basic_hot_tick_request(hero),"periodic","Druid Basic HoT","druid_basic_hot",["healing_over_time","periodic_healing","druid_basic_hot"]);DruidSystem.telemetry_add(hero,"mini_hot_ticks");DruidSystem.telemetry_add(hero,"mini_hot_healing",float(result.effective_amount));DruidSystem.telemetry_add(hero,"mini_hot_overhealing",float(result.overhealing));druid_visual("druid_basic_hot_tick",hero.pos,target.pos,.3)
		if float(hero.druid_runtime.tranquility_remaining)>0.0:
			hero.druid_runtime.tranquility_remaining=maxf(0.0,float(hero.druid_runtime.tranquility_remaining)-delta);hero.druid_runtime.tranquility_tick=float(hero.druid_runtime.tranquility_tick)-delta
			if float(hero.druid_runtime.tranquility_tick)<=0.0:
				hero.druid_runtime.tranquility_tick+=1.0;var regrowth_count:=DruidSystem.active_regrowths(hero).size();var multiplier:=1.0+(float(DruidData.VALUES.serenity_base)+regrowth_count*float(DruidData.VALUES.serenity_per_regrowth) if DruidSystem.has_talent(hero,"druid_l27_r1") else 0.0)
				for ally in heroes:
					if ally.hp<=0.0 or ally.pos.distance_to(hero.pos)>float(DruidData.SPACE.tranquility_radius):continue
					var healing:=druid_heal(hero,ally,DruidSystem.power_scaled(hero,float(DruidData.VALUES.tranquility_tick))*multiplier,"periodic","Tranquility","druid_tranquility",["periodic_healing"]);DruidSystem.telemetry_add(hero,"tranquility_healing",float(healing.effective_amount))
					if DruidSystem.regrowth_for(hero,str(ally.combat_id))!=null:PriestSystem.add_named_armor(ally,"druid_tranquility:%s"%str(hero.combat_id),float(DruidData.VALUES.tranquility_armor),1.1)
		if float(hero.druid_runtime.astral_pending)>0.0:
			hero.druid_runtime.astral_pending=maxf(0.0,float(hero.druid_runtime.astral_pending)-delta)
			if float(hero.druid_runtime.astral_pending)<=0.0:hero.pos=Vector2(hero.druid_runtime.astral_point);hero.dest=hero.pos;druid_resolve_moonfire(hero,hero.pos,true);DruidSystem.telemetry_add(hero,"astral_teleports");DruidSystem.telemetry_add(hero,"astral_free_moonfires");hero.druid_runtime.twilight_pending=float(DruidData.VALUES.twilight_delay);hero.druid_runtime.twilight_point=hero.pos
		if float(hero.druid_runtime.twilight_pending)>0.0:hero.druid_runtime.twilight_pending=maxf(0.0,float(hero.druid_runtime.twilight_pending)-delta);if float(hero.druid_runtime.twilight_pending)<=0.0:druid_resolve_twilight(hero,Vector2(hero.druid_runtime.twilight_point))
		update_druid_roots(hero,delta);update_druid_treants(hero,delta)
