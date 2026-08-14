extends "res://scripts/runtime/death_knight_runtime.gd"

func beastmaster_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES["Beastmaster"].color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func beastmaster_target_by_id(id:String):
	for enemy in enemies:if str(enemy.get("combat_id",""))==id and float(enemy.get("hp",0.0))>0.0:return enemy
	return null

func beastmaster_selected_enemy():
	var index:=combat_enemy_target();return enemies[index] if index>=0 and index<enemies.size() and float(enemies[index].hp)>0.0 else null

func cast_beastmaster_d(hero:Dictionary)->bool:
	var target=beastmaster_selected_enemy();if target==null:target=hero
	var cast:=BeastmasterSystem.command_misha(hero,target);if cast:beastmaster_visual("beastmaster_focus" if target!=hero else "beastmaster_retreat",hero.pos,hero.beastmaster_runtime.misha.pos,.35)
	return cast

func cast_beastmaster_swoop(hero:Dictionary,point:Vector2)->bool:
	var direction:=Vector2(hero.pos).direction_to(point)
	if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var endpoint:=CombatGeometry.safe_endpoint(hero.pos,hero.pos+direction*float(BeastmasterData.SPACE.swoop_length),float(BeastmasterData.SPACE.combat_radius),combat_blockers)
	var contacts:Array=[];for enemy in enemies:if enemy.hp>0.0 and TargetCategorySystem.qualifies_immediate(enemy) and CombatGeometry.segment_hits_circle(hero.pos,endpoint,enemy.pos,float(BeastmasterData.SPACE.swoop_width)+float(enemy.get("combat_radius",28.0))):contacts.append(enemy)
	var plan:=BeastmasterSystem.cast_swoop(hero,endpoint,contacts);if not bool(plan.get("cast",false)):return false
	for target in contacts:deal_damage(hero,target,float(plan.damage),"basic_ability","physical","Spirit Swoop",false,"beastmaster_swoop",[],true);CombatSystem.apply_control(target,"slow",float(plan.slow_duration),float(plan.slow))
	beastmaster_visual("beastmaster_swoop",hero.pos,endpoint,.5,{"width":float(BeastmasterData.SPACE.swoop_width)});return true

func cast_beastmaster_charge(hero:Dictionary,point:Vector2)->bool:
	if not BeastmasterSystem.misha_alive(hero):return false
	var misha:Dictionary=hero.beastmaster_runtime.misha;var selected_target=beastmaster_selected_enemy();var direction:=Vector2(misha.pos).direction_to(point)
	if selected_target!=null:direction=Vector2(misha.pos).direction_to(Vector2(selected_target.pos))
	if direction==Vector2.ZERO:direction=Vector2.RIGHT
	var endpoint:=CombatGeometry.safe_endpoint(misha.pos,misha.pos+direction*float(BeastmasterData.SPACE.charge_length),float(misha.combat_radius),combat_blockers);var contacts:Array=[]
	for enemy in enemies:if enemy.hp>0.0 and TargetCategorySystem.qualifies_immediate(enemy) and CombatGeometry.segment_hits_circle(misha.pos,endpoint,enemy.pos,float(BeastmasterData.SPACE.charge_width)+float(enemy.get("combat_radius",28.0))):contacts.append(enemy)
	contacts.sort_custom(func(a,b):return Vector2(misha.pos).distance_squared_to(Vector2(a.pos))<Vector2(misha.pos).distance_squared_to(Vector2(b.pos)))
	var plan:=BeastmasterSystem.charge_plan(hero,contacts,str(selected_target.get("combat_id","")) if selected_target!=null else "");if not bool(plan.get("cast",false)):return false
	for target in contacts:var hit:=deal_damage(hero,target,float(plan.damage),"basic_ability","physical","Misha, Charge!",true,"beastmaster_charge",[],true);var stun:=CombatSystem.apply_control(target,"stun",float(plan.stun));if bool(stun.applied):BeastmasterSystem.telemetry_add(hero,"charge_stuns")
	misha.pos=endpoint;beastmaster_visual("beastmaster_charge",misha.pos,endpoint,.45,{"width":float(BeastmasterData.SPACE.charge_width)});return true

func cast_beastmaster_greater(hero:Dictionary)->bool:
	var result:=BeastmasterSystem.cast_greater(hero);if not bool(result.get("cast",false)):return false
	var misha:Dictionary=hero.beastmaster_runtime.misha;var direction:=Vector2(misha.get("facing_direction",hero.get("facing_direction",Vector2.RIGHT)))
	if direction==Vector2.ZERO:direction=Vector2.RIGHT
	result.beast.pos=CombatGeometry.safe_endpoint(misha.pos,misha.pos-direction.normalized()*float(BeastmasterData.SPACE.greater_spawn_radius),float(result.beast.combat_radius),combat_blockers)
	beastmaster_visual("beastmaster_greater",hero.beastmaster_runtime.misha.pos,hero.beastmaster_runtime.misha.pos,.55);return true

func cast_beastmaster_boars(hero:Dictionary,point:Vector2)->bool:
	if str(hero.selected_heroic_id)!="beastmaster_l15_r2" or float(hero.ability_cds[3])>0.0:return false
	var direction:=Vector2(hero.pos).direction_to(point)
	if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var endpoint:=Vector2(hero.pos)+direction*float(BeastmasterData.SPACE.boar_range);var contacts:Array=[]
	for target in enemies:if target.hp>0.0 and TargetCategorySystem.qualifies_immediate(target) and CombatGeometry.segment_hits_circle(hero.pos,endpoint,target.pos,float(BeastmasterData.SPACE.boar_width)+float(target.get("combat_radius",28.0))):contacts.append(target)
	contacts.sort_custom(func(a,b):return Vector2(hero.pos).distance_squared_to(Vector2(a.pos))<Vector2(hero.pos).distance_squared_to(Vector2(b.pos)));contacts=contacts.slice(0,int(BeastmasterData.VALUES.boar_cap));hero.ability_cds[3]=float(BeastmasterData.VALUES.boar_cooldown);BeastmasterSystem.telemetry_add(hero,"boar_casts");BeastmasterSystem.telemetry_add(hero,"boar_targets",contacts.size())
	for target in contacts:
		var amount:=BeastmasterData.scaled(float(BeastmasterData.VALUES.boar_damage),int(hero.level))*(1.0+float(BeastmasterData.VALUES.kill_damage) if BeastmasterSystem.has_talent(hero,"beastmaster_l27_r2") else 1.0);var result:=deal_damage(hero,target,amount,"heroic","physical","Unleash the Boars",false,"beastmaster_boars",[],true);target.revealed=true;CombatSystem.apply_control(target,"slow",float(BeastmasterData.VALUES.boar_slow_duration),float(BeastmasterData.VALUES.boar_slow));if BeastmasterSystem.has_talent(hero,"beastmaster_l27_r2"):CombatSystem.apply_control(target,"root",float(BeastmasterData.VALUES.kill_root));BeastmasterSystem.telemetry_add(hero,"boar_contacts");BeastmasterSystem.telemetry_add(hero,"boar_damage",float(result.resolved_damage));BeastmasterSystem.telemetry_add(hero,"boar_reveals");BeastmasterSystem.telemetry_add(hero,"boar_slows")
	beastmaster_visual("beastmaster_boars",hero.pos,endpoint,.75,{"width":float(BeastmasterData.SPACE.boar_width)});return true

func cast_beastmaster_ability(slot:int,point:Vector2,_item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Beastmaster" or hero.get("beastmaster_runtime",{}).is_empty():return false
	match slot:
		0:return cast_beastmaster_swoop(hero,point)
		1:return cast_beastmaster_charge(hero,point)
		2:return cast_beastmaster_greater(hero)
		3:return BeastmasterSystem.cast_bestial(hero) if str(hero.selected_heroic_id)=="beastmaster_l15_r1" else cast_beastmaster_boars(hero,point)
		4:return cast_beastmaster_d(hero)
	return false

func beastmaster_attack(hero:Dictionary,beast:Dictionary,target:Dictionary,kind:String)->void:
	var attack_speed_reduction:=clampf(CombatSystem.control_amount(beast,"attack_speed"),0.0,.9)
	if CombatSystem.is_blinded(beast):beast.attack_cooldown=float(beast.attack_interval)/maxf(.1,1.0-attack_speed_reduction);beastmaster_visual("beastmaster_%s_miss"%kind,beast.pos,target.pos,.2);return
	var amount:=float(beast.damage)
	if kind=="misha":var base_amount:=amount;amount*=BeastmasterSystem.misha_damage_multiplier(hero,str(target.combat_id));BeastmasterSystem.telemetry_add(hero,"bestial_damage",maxf(0.0,amount-base_amount) if float(hero.beastmaster_runtime.bestial_remaining)>0.0 else 0.0)
	elif kind=="lesser":amount*=BeastmasterSystem.chain_multiplier(hero,beast)
	var result:=deal_damage(hero,target,amount,"basic_attack","physical","Misha Basic Attack" if kind=="misha" else "%s Beast Basic Attack"%kind.capitalize(),true,"beastmaster_%s_attack"%kind,[],false);beast.attack_cooldown=float(beast.attack_interval)/maxf(.1,1.0-attack_speed_reduction);var proc:=BeastmasterSystem.note_primary_attack(hero,kind,str(target.combat_id),result)
	if float(proc.get("hunted_bonus",0.0))>0.0:deal_damage(hero,target,float(proc.hunted_bonus),"trait","physical","Hunted",true,"beastmaster_hunted_%s"%kind,[],false)
	if kind=="misha":BeastmasterSystem.spirit_bond_heal(hero,float(result.resolved_damage))
	else:BeastmasterSystem.telemetry_add(hero,"%s_attacks"%kind);BeastmasterSystem.telemetry_add(hero,"%s_damage"%kind,float(result.resolved_damage))
	beastmaster_visual("beastmaster_%s_attack"%kind,beast.pos,target.pos,.2)

func update_beast_ai(hero:Dictionary,beast:Dictionary,kind:String,delta:float)->void:
	if float(beast.hp)<=0.0:return
	if CombatSystem.is_stunned(beast):return
	if CombatSystem.is_feared(beast):
		var fear_origin:=Vector2(beast.get("fear_origin",hero.pos));var away:=fear_origin.direction_to(Vector2(beast.pos));if away==Vector2.ZERO:away=Vector2.RIGHT
		beast.pos=CombatGeometry.move_toward_safe(beast.pos,Vector2(beast.pos)+away*100.0,float(beast.movement_speed)*delta,float(beast.combat_radius),combat_blockers);return
	var target=beastmaster_target_by_id(str(beast.get("priority_target_id",beast.get("target_id",""))))
	var leash:=float(BeastmasterData.SPACE.misha_leash if kind=="misha" else BeastmasterData.SPACE.pack_commander_leash)
	var rooted:=StatusEffectSystem.has_control(beast,"root");var slow_multiplier:=1.0-clampf(CombatSystem.control_amount(beast,"slow"),0.0,.95)
	if Vector2(beast.pos).distance_to(Vector2(hero.pos))>leash:beast.target_id="";beast.priority_target_id="";if not rooted:beast.pos=CombatGeometry.move_toward_safe(beast.pos,hero.pos,float(beast.movement_speed)*slow_multiplier*delta,float(beast.combat_radius),combat_blockers);return
	if target!=null and Vector2(beast.pos).distance_to(Vector2(target.pos))>float(BeastmasterData.SPACE.misha_acquisition if kind=="misha" else BeastmasterData.SPACE.beast_acquisition):beast.target_id="";beast.priority_target_id="";target=null
	if target==null:
		var candidates:=enemies.filter(func(enemy):return enemy.hp>0.0 and TargetCategorySystem.qualifies_immediate(enemy) and Vector2(beast.pos).distance_to(Vector2(enemy.pos))<=float(BeastmasterData.SPACE.misha_acquisition if kind=="misha" else BeastmasterData.SPACE.beast_acquisition));candidates.sort_custom(func(a,b):var ad:=Vector2(beast.pos).distance_squared_to(Vector2(a.pos));var bd:=Vector2(beast.pos).distance_squared_to(Vector2(b.pos));return str(a.combat_id)<str(b.combat_id) if is_equal_approx(ad,bd) else ad<bd);if not candidates.is_empty():target=candidates[0];beast.target_id=str(target.combat_id)
	if target==null:
		if kind=="misha" and not rooted and Vector2(beast.pos).distance_to(Vector2(hero.pos))>float(BeastmasterData.SPACE.misha_follow):beast.pos=CombatGeometry.move_toward_safe(beast.pos,hero.pos,float(beast.movement_speed)*slow_multiplier*delta,float(beast.combat_radius),combat_blockers)
		return
	var distance:=Vector2(beast.pos).distance_to(Vector2(target.pos));var attack_distance:=float(beast.range)+float(beast.combat_radius)+float(target.get("combat_radius",28.0))
	if distance>attack_distance:if not rooted:beast.pos=CombatGeometry.move_toward_safe(beast.pos,target.pos,float(beast.movement_speed)*slow_multiplier*delta*(1.75 if bool(beast.get("pack_assault_pending",false)) else 1.0),float(beast.combat_radius),combat_blockers);return
	if float(beast.attack_cooldown)<=0.0:beastmaster_attack(hero,beast,target,kind);beast.pack_assault_pending=false

func update_beastmaster_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Beastmaster" or hero.get("beastmaster_runtime",{}).is_empty():continue
		if float(hero.get("hp",0.0))<=0.0:
			hero.beastmaster_runtime.misha.hp=0.0;hero.beastmaster_runtime.misha_respawn_remaining=float(BeastmasterData.VALUES.misha_respawn);hero.beastmaster_runtime.lesser_beasts=[];hero.beastmaster_runtime.greater_beasts=[];continue
		var active_combat:=enemies.any(func(enemy):return float(enemy.get("hp",0.0))>0.0 and not bool(enemy.get("passive_test_enemy",false)));BeastmasterSystem.advance(hero,delta,active_combat);var runtime:Dictionary=hero.beastmaster_runtime
		update_timed_combat_effects(runtime.misha,delta)
		for controlled_beast in BeastmasterSystem.disposable_beasts(hero):update_timed_combat_effects(controlled_beast,delta)
		if BeastmasterSystem.misha_alive(hero):
			runtime.misha.attack_cooldown=maxf(0.0,float(runtime.misha.attack_cooldown)-delta)
			if str(runtime.misha.command_mode)=="retreat":
				runtime.misha.target_id="";var stopped:=CombatSystem.is_stunned(runtime.misha) or StatusEffectSystem.has_control(runtime.misha,"root");var slow_multiplier:=1.0-clampf(CombatSystem.control_amount(runtime.misha,"slow"),0.0,.95);if not stopped:runtime.misha.pos=CombatGeometry.move_toward_safe(runtime.misha.pos,hero.pos,float(runtime.misha.movement_speed)*(1.0+float(BeastmasterData.VALUES.misha_retreat_speed))*slow_multiplier*delta,float(runtime.misha.combat_radius),combat_blockers)
				if Vector2(runtime.misha.pos).distance_to(Vector2(hero.pos))<=float(BeastmasterData.SPACE.misha_follow):runtime.misha.command_mode="follow"
			else:update_beast_ai(hero,runtime.misha,"misha",delta)
		for beast in runtime.lesser_beasts:update_beast_ai(hero,beast,"lesser",delta)
		for beast in runtime.greater_beasts:update_beast_ai(hero,beast,"greater",delta)
		if BeastmasterSystem.has_talent(hero,"beastmaster_l30_3") and float(runtime.wildfire_tick)<=0.0:
			runtime.wildfire_tick=1.0
			for beast in BeastmasterSystem.disposable_beasts(hero):
				for target in enemies:
					if target.hp>0.0 and TargetCategorySystem.qualifies_immediate(target) and Vector2(beast.pos).distance_to(Vector2(target.pos))<=float(BeastmasterData.SPACE.wildfire_radius)+float(target.get("combat_radius",28.0)):
						var tick:=deal_damage(hero,target,BeastmasterData.scaled(float(BeastmasterData.VALUES.wildfire_damage),int(hero.level)),"periodic","magical","Wildfire Pack",true,"beastmaster_wildfire:%s"%str(beast.combat_id),[],false);BeastmasterSystem.telemetry_add(hero,"wildfire_damage",float(tick.resolved_damage))
