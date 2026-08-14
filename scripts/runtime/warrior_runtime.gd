extends "res://scripts/runtime/druid_runtime.gd"

func warrior_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Warrior.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func warrior_enemy_target(hero:Dictionary,max_range:float=INF):
	var index:=combat_enemy_target();if index<0 or index>=enemies.size():return null
	var target:Dictionary=enemies[index]
	if target.hp<=0.0 or hero.pos.distance_to(target.pos)>max_range:return null
	return target

func warrior_safe_landing(hero:Dictionary,target:Dictionary)->Vector2:
	var direction:=Vector2(hero.pos).direction_to(Vector2(target.pos));if direction==Vector2.ZERO:direction=Vector2.RIGHT
	for step in 12:
		var candidate:=Vector2(target.pos)-direction.rotated(step*TAU/12.0)*(float(target.get("combat_radius",28.0))+float(hero.get("combat_radius",42.0))+4.0)
		if CombatGeometry.valid_position(candidate,float(hero.get("combat_radius",42.0)),combat_blockers):return candidate
	return Vector2.INF

func warrior_contact_heal(hero:Dictionary,target:Dictionary)->float:
	var category:=TargetCategorySystem.category(target)
	if category=="boss":return WarriorSystem.scaled(hero,float(WarriorData.VALUES.q_boss_heal))*float(WarriorData.VALUES.lionheart_boss if WarriorSystem.has_talent(hero,"warrior_l15_1") else 1.0)
	if TargetCategorySystem.qualifies_quest(target) or category=="summon" and WarriorSystem.has_talent(hero,"warrior_l15_1"):return WarriorSystem.scaled(hero,float(WarriorData.VALUES.q_heal))
	return 0.0

func warrior_apply_anti_summon(hero:Dictionary,target:Dictionary)->void:
	var request:=WarriorSystem.anti_summon(hero,target)
	if float(request.damage)>0.0 and target.hp>0.0:deal_damage(hero,target,float(request.damage),"percentage_health","physical","Juggernaut",false,"warrior_anti_summon",[],false)

func cast_warrior_lions_fang(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[0])>0.0:return false
	var direction:=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var destination:=Vector2(hero.pos)+direction*float(WarriorData.SPACE.lions_fang_range);var contacts:Array=[]
	for target in enemies:
		if target.hp>0.0 and CombatGeometry.segment_hits_circle(hero.pos,destination,target.pos,float(WarriorData.SPACE.lions_fang_width)+float(target.get("combat_radius",28.0))):contacts.append(target)
	var plan:=WarriorSystem.lions_fang_plan(hero,contacts);hero.ability_cds[0]=float(WarriorData.VALUES.q_cooldown)
	for target in contacts:
		var result:=deal_damage(hero,target,float(plan.damage),"basic_ability","physical","Lion's Fang",false,"warrior_q",[],true);WarriorSystem.telemetry_add(hero,"q_damage",float(result.resolved_damage));CombatSystem.apply_control(target,"slow",float(plan.slow_duration),float(plan.slow));warrior_apply_anti_summon(hero,target)
		var raw_healing:=warrior_contact_heal(hero,target)
		if raw_healing>0.0:
			var healing:=deal_healing(hero,hero,raw_healing,"basic_ability","Lion's Fang","warrior_q_heal",["healing"]);WarriorSystem.telemetry_add(hero,"q_healing",float(healing.effective_amount))
	WarriorSystem.note_lions_fang_cast(hero,plan);warrior_visual("warrior_lions_fang",hero.pos,destination,.45,{"width":float(WarriorData.SPACE.lions_fang_width)});return true

func cast_warrior_parry(hero:Dictionary)->bool:
	if not WarriorSystem.cast_parry(hero):return false
	var state:=AbilitySlotSystem.ui_state(hero.warrior_runtime.w_slot);hero.ability_cds[1]=float(state.recharge) if int(state.charges)<=0 else 0.0;warrior_visual("warrior_parry",hero.pos,hero.pos,float(WarriorData.VALUES.w_duration));return true

func cast_warrior_charge(hero:Dictionary)->bool:
	if float(hero.ability_cds[2])>0.0:return false
	var target=null
	if WarriorSystem.has_talent(hero,"warrior_l18_2"):
		var ally_index:=int(hero.get("heal_target",-1));if ally_index>=0 and ally_index<heroes.size() and heroes[ally_index]!=hero:target=heroes[ally_index]
	if target==null:target=warrior_enemy_target(hero,float(WarriorData.SPACE.charge_range))
	if target==null or target.hp<=0.0 or hero.pos.distance_to(target.pos)>float(WarriorData.SPACE.charge_range):return false
	var landing:=warrior_safe_landing(hero,target);if landing==Vector2.INF:return false
	var origin:=Vector2(hero.pos);hero.pos=landing;hero.dest=landing;hero.ability_cds[2]=float(WarriorData.VALUES.warbringer_cooldown if WarriorSystem.has_talent(hero,"warrior_l18_2") else WarriorData.VALUES.e_cooldown)
	if target in enemies:
		var result:=deal_damage(hero,target,WarriorSystem.scaled(hero,float(WarriorData.VALUES.e_damage)),"basic_ability","physical","Charge",false,"warrior_e",[],true);CombatSystem.apply_control(target,"slow",float(WarriorData.VALUES.e_slow_duration),float(WarriorData.VALUES.e_slow));WarriorSystem.telemetry_add(hero,"e_enemy_casts");WarriorSystem.telemetry_add(hero,"e_damage",float(result.resolved_damage));WarriorSystem.telemetry_add(hero,"e_slows");warrior_apply_anti_summon(hero,target)
	else:WarriorSystem.telemetry_add(hero,"e_ally_casts")
	warrior_visual("warrior_charge",origin,landing,.25);return true

func cast_warrior_heroic(hero:Dictionary)->bool:
	var spec:=WarriorSystem.specialization(hero)
	if spec=="warrior_l12_r3":return false
	if float(hero.warrior_runtime.taunt_cooldown)>0.0:return false
	var target=warrior_enemy_target(hero,float(WarriorData.SPACE.taunt_range if spec=="warrior_l12_r1" else WarriorData.SPACE.colossus_range));if target==null:return false
	if spec=="warrior_l12_r1":
		ForcedTargetSystem.apply(target,int(hero.battle_index),"warrior_taunt:%s"%str(hero.combat_id),float(WarriorData.VALUES.taunt_duration),str(hero.combat_id));CombatSystem.apply_control(target,"silence",float(WarriorData.VALUES.taunt_duration));hero.warrior_runtime.taunt_cooldown=float(WarriorData.VALUES.taunt_cooldown);WarriorSystem.telemetry_add(hero,"taunt_casts");if TargetCategorySystem.category(target)=="boss":WarriorSystem.telemetry_add(hero,"boss_taunts");warrior_visual("warrior_taunt",hero.pos,target.pos,.4);return true
	if spec=="warrior_l12_r2":
		var landing:=warrior_safe_landing(hero,target);if landing==Vector2.INF:return false
		var targets:Array=[target]
		if WarriorSystem.has_talent(hero,"warrior_l27_r2"):
			for enemy in enemies:if enemy!=target and enemy.hp>0.0 and enemy.pos.distance_to(target.pos)<=float(WarriorData.SPACE.master_radius):targets.append(enemy)
		for enemy in targets:
			var result:=deal_damage(hero,enemy,WarriorSystem.scaled(hero,float(WarriorData.VALUES.colossus_damage)),"heroic","physical","Colossus Smash",false,"warrior_colossus",[],true);ArmorReductionSystem.apply(enemy,"warrior_colossus:%s"%str(hero.combat_id),WarriorSystem.scaled(hero,float(WarriorData.VALUES.colossus_armor)),float(WarriorData.VALUES.colossus_duration));WarriorSystem.telemetry_add(hero,"colossus_damage",float(result.resolved_damage));WarriorSystem.telemetry_add(hero,"colossus_armor")
		var origin:=Vector2(hero.pos);hero.pos=landing;hero.dest=landing;hero.warrior_runtime.taunt_cooldown=float(WarriorData.VALUES.master_cooldown if WarriorSystem.has_talent(hero,"warrior_l27_r2") else WarriorData.VALUES.colossus_cooldown);WarriorSystem.telemetry_add(hero,"colossus_casts");warrior_visual("warrior_colossus",origin,landing,.4);return true
	return false

func cast_warrior_trait(hero:Dictionary)->bool:
	if not WarriorSystem.has_talent(hero,"warrior_l21_3") or float(hero.warrior_runtime.shattering_cooldown)>0.0:return false
	var target=warrior_enemy_target(hero,float(WarriorData.SPACE.shattering_range));if target==null:return false
	var before:=float(target.get("shield",0.0));var result:=deal_damage(hero,target,WarriorSystem.scaled(hero,float(WarriorData.VALUES.shattering_damage)),"trait","physical","Shattering Throw",false,"warrior_shattering",[],true);var shield_bonus:=WarriorSystem.shield_only_damage(target,WarriorSystem.scaled(hero,float(WarriorData.VALUES.shattering_shield_damage)))
	hero.warrior_runtime.shattering_cooldown=float(WarriorData.VALUES.shattering_cooldown);WarriorSystem.telemetry_add(hero,"shattering_casts");WarriorSystem.telemetry_add(hero,"shield_damage",float(result.shield_damage)+shield_bonus)
	if before>0.0 and float(target.get("shield",0.0))<=0.0:WarriorSystem.telemetry_add(hero,"shields_broken")
	warrior_visual("warrior_shattering",hero.pos,target.pos,.45);return true

func cast_warrior_ability(slot:int,point:Vector2,_item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Warrior" or hero.get("warrior_runtime",{}).is_empty():return false
	match slot:
		0:return cast_warrior_lions_fang(hero,point)
		1:return cast_warrior_parry(hero)
		2:return cast_warrior_charge(hero)
		3:return cast_warrior_heroic(hero)
		4:return cast_warrior_trait(hero)
	return false

func warrior_refresh_banner_aura(hero:Dictionary,ally:Dictionary,delta:float)->void:
	var source_id:="warrior_banner:%s"%str(hero.combat_id)
	HealingReceivedModifierSystem.remove(ally,source_id);QuestProgressModifierSystem.remove(ally,source_id);ally.active_effects=ally.get("active_effects",[]).filter(func(effect):return str(effect.get("id",""))!=source_id);ally.temporary_armor_sources=ally.get("temporary_armor_sources",[]).filter(func(source):return str(source.get("id",""))!=source_id)
	if not WarriorSystem.in_banner(hero,ally):return
	var kind:=str(hero.warrior_runtime.banner_type);var duration:=maxf(.15,delta*2.0)
	if kind=="stormwind":ally.active_effects=CombatSystem.apply_named_effect(ally.get("active_effects",[]),{"id":source_id,"movement_speed_multiplier":1.0+float(WarriorData.VALUES.stormwind_speed),"remaining_duration":duration});WarriorSystem.telemetry_add(hero,"stormwind_uptime",delta)
	elif kind=="ironforge":ally.temporary_armor_sources=ally.get("temporary_armor_sources",[]).filter(func(source):return str(source.get("id",""))!=source_id);ally.temporary_armor_sources.append({"id":source_id,"armor":WarriorSystem.scaled(hero,float(WarriorData.VALUES.ironforge_armor)),"remaining":duration});WarriorSystem.telemetry_add(hero,"ironforge_armor",delta)
	elif kind=="dalaran":ally.active_effects=CombatSystem.apply_named_effect(ally.get("active_effects",[]),{"id":source_id,"ability_power_percent":float(WarriorData.VALUES.dalaran_power),"remaining_duration":duration});WarriorSystem.telemetry_add(hero,"dalaran_uptime",delta)
	if WarriorSystem.has_talent(hero,"warrior_l30_1"):HealingReceivedModifierSystem.apply(ally,source_id,float(WarriorData.VALUES.glory_healing),duration,str(hero.combat_id));ally.hp=minf(float(ally.max_hp),float(ally.hp)+float(ally.get("health_regeneration",0.0))*float(WarriorData.VALUES.glory_regen)*delta)
	if WarriorSystem.has_talent(hero,"warrior_l30_3") and float(hero.warrior_runtime.banner_remaining)>float(WarriorData.VALUES.banner_duration)-float(WarriorData.VALUES.banner_shared_window):QuestProgressModifierSystem.apply(ally,source_id,2.0,duration)
	WarriorSystem.telemetry_add(hero,"banner_ally_seconds",delta)

func update_warrior_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Warrior" or hero.get("warrior_runtime",{}).is_empty():continue
		var update:=WarriorSystem.update(hero,delta);hero.basic_attack_interval=WarriorSystem.attack_interval(hero);hero.ability_cds[1]=float(AbilitySlotSystem.ui_state(hero.warrior_runtime.w_slot).recharge) if int(AbilitySlotSystem.ui_state(hero.warrior_runtime.w_slot).charges)<=0 else 0.0;hero.ability_cds[3]=float(hero.warrior_runtime.taunt_cooldown);hero.ability_cds[4]=float(hero.warrior_runtime.shattering_cooldown) if WarriorSystem.has_talent(hero,"warrior_l21_3") else 0.0
		if bool(update.banner_activated) and WarriorSystem.has_talent(hero,"warrior_l30_2"):
			for target in enemies:if target.hp>0.0 and TargetCategorySystem.qualifies_immediate(target) and target.pos.distance_to(hero.pos)<=float(WarriorData.SPACE.banner_radius):OutgoingDamageReductionSystem.apply(target,"warrior_demoralizing:%s"%str(hero.combat_id),float(WarriorData.VALUES.demoralizing_reduction),float(WarriorData.VALUES.demoralizing_duration));WarriorSystem.telemetry_add(hero,"demoralizing_applications")
		for ally in heroes:warrior_refresh_banner_aura(hero,ally,delta)
