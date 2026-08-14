extends "res://scripts/runtime/warrior_runtime.gd"

func death_knight_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES["Death Knight"].color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func death_knight_enemy_target(hero:Dictionary,max_range:float=INF):
	var index:=combat_enemy_target();if index<0 or index>=enemies.size():return null
	var target:Dictionary=enemies[index];if target.hp<=0.0 or not TargetCategorySystem.qualifies_immediate(target) or hero.pos.distance_to(target.pos)>max_range:return null
	return target

func death_knight_clamped_point(hero:Dictionary,point:Vector2,range_limit:float)->Vector2:
	var origin:=Vector2(hero.pos)
	return point if origin.distance_to(point)<=range_limit else origin+origin.direction_to(point)*range_limit

func cast_death_knight_frostmourne(hero:Dictionary)->bool:
	var target=death_knight_enemy_target(hero,float(DeathKnightData.SPACE.basic_range));if not DeathKnightSystem.activate_frostmourne(hero,target!=null):return false
	death_knight_visual("death_knight_frostmourne_ready",hero.pos,hero.pos,.35)
	if target!=null:deal_damage(hero,target,DeathKnightSystem.basic_attack_amount(hero),"basic_attack","physical","Frostmourne Hungers")
	return true

func death_coil_enemy_effect(hero:Dictionary,target:Dictionary,secondary:bool=false)->bool:
	if target==null or target.hp<=0.0 or hero.pos.distance_to(target.pos)>float(DeathKnightData.SPACE.death_coil_range):return false
	var precontrolled:=DeathKnightSystem.controlled(target);var result:=deal_damage(hero,target,DeathKnightSystem.death_coil_damage(hero),"basic_ability","magical","Death Coil",false,"death_knight_death_coil_secondary" if secondary else "death_knight_death_coil",[],true);DeathKnightSystem.telemetry_add(hero,"q_damage",float(result.resolved_damage));DeathKnightSystem.telemetry_add(hero,"q_enemy")
	if DeathKnightSystem.has_talent(hero,"death_knight_l9_1") and DeathKnightSystem.frost_presence_reward(hero,int(DeathKnightData.VALUES.frost_presence_second)):
		CombatSystem.apply_control(target,"slow",float(DeathKnightData.VALUES.frost_presence_slow_duration),float(DeathKnightData.VALUES.frost_presence_slow));DeathKnightSystem.telemetry_add(hero,"frost_presence_slows")
	if DeathKnightSystem.has_talent(hero,"death_knight_l18_1"):
		var healing:=deal_healing(hero,hero,DeathKnightSystem.death_coil_heal(hero,false),"basic_ability","Immortal Coil","death_knight_immortal",["healing"]);DeathKnightSystem.telemetry_add(hero,"immortal_healing",float(healing.effective_amount));HealingReceivedModifierSystem.apply(target,"death_knight_immortal:%s"%str(hero.combat_id),-float(DeathKnightData.VALUES.immortal_healing_reduction),float(DeathKnightData.VALUES.immortal_healing_reduction_duration),str(hero.combat_id));DeathKnightSystem.telemetry_add(hero,"healing_reductions")
	var dominion:=DeathKnightSystem.dominion_amount(hero,precontrolled)
	if dominion>0.0:OutgoingDamageReductionSystem.apply(target,"death_knight_dominion:%s"%str(hero.combat_id),dominion,float(DeathKnightData.VALUES.dominion_duration));hero.death_knight_runtime.recent_dominion[str(target.combat_id)]={"amount":dominion,"remaining":float(DeathKnightData.VALUES.dominion_duration)};DeathKnightSystem.telemetry_add(hero,"dominion_40" if precontrolled else "dominion_25")
	death_knight_visual("death_knight_death_coil",hero.pos,target.pos,.35)
	if not secondary and DeathKnightSystem.has_talent(hero,"death_knight_l21_1"):
		var candidates:=enemies.filter(func(enemy):return enemy!=target and enemy.hp>0.0 and TargetCategorySystem.qualifies_immediate(enemy) and enemy.pos.distance_to(target.pos)<=float(DeathKnightData.SPACE.deathlord_range));candidates.sort_custom(func(a,b):return a.pos.distance_to(target.pos)<b.pos.distance_to(target.pos))
		if not candidates.is_empty():death_coil_enemy_effect(hero,candidates[0],true);DeathKnightSystem.telemetry_add(hero,"deathlord_coils")
	return true

func cast_death_knight_death_coil(hero:Dictionary,target=null,self_cast:bool=false)->bool:
	if float(hero.ability_cds[0])>0.0 or not DeathKnightSystem.action_allowed(hero,0):return false
	if self_cast:
		var healing:=deal_healing(hero,hero,DeathKnightSystem.death_coil_heal(hero,true),"basic_ability","Death Coil","death_knight_death_coil_heal",["healing"]);hero.ability_cds[0]=DeathKnightSystem.death_coil_cooldown(hero,true);DeathKnightSystem.telemetry_add(hero,"q_self");DeathKnightSystem.telemetry_add(hero,"q_healing",float(healing.effective_amount));DeathKnightSystem.telemetry_add(hero,"q_overhealing",float(healing.overhealing));death_knight_visual("death_knight_death_coil_heal",hero.pos,hero.pos,.35);return true
	if target==null:target=death_knight_enemy_target(hero,float(DeathKnightData.SPACE.death_coil_range))
	if not death_coil_enemy_effect(hero,target,false):return false
	hero.ability_cds[0]=DeathKnightSystem.death_coil_cooldown(hero,false);return true

func refresh_dominion_from_howling(hero:Dictionary,target:Dictionary)->void:
	var id:=str(target.get("combat_id",""));var current:Dictionary=hero.death_knight_runtime.recent_dominion.get(id,{})
	if current.is_empty() or float(current.get("remaining",0.0))<=0.0:return
	OutgoingDamageReductionSystem.apply(target,"death_knight_dominion:%s"%str(hero.combat_id),float(current.amount),float(DeathKnightData.VALUES.dominion_duration));current.remaining=float(DeathKnightData.VALUES.dominion_duration);hero.death_knight_runtime.recent_dominion[id]=current;DeathKnightSystem.telemetry_add(hero,"dominion_refresh")

func cast_death_knight_howling_blast(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[1])>0.0 or not DeathKnightSystem.action_allowed(hero,1):return false
	var center:=death_knight_clamped_point(hero,point,DeathKnightSystem.howling_range(hero));var path_enabled:=DeathKnightSystem.has_talent(hero,"death_knight_l9_1") and DeathKnightSystem.frost_presence_reward(hero,int(DeathKnightData.VALUES.frost_presence_first));var path_contacts:Array=[];var final_contacts:Array=[];var unique:Dictionary={}
	for target in enemies:
		if target.hp<=0.0 or not TargetCategorySystem.qualifies_immediate(target):continue
		if path_enabled and CombatGeometry.segment_hits_circle(hero.pos,center,target.pos,float(DeathKnightData.SPACE.howling_path_width)+float(target.get("combat_radius",28.0))):path_contacts.append(target);unique[str(target.combat_id)]=target
		if target.pos.distance_to(center)<=DeathKnightSystem.howling_radius(hero)+float(target.get("combat_radius",28.0)):final_contacts.append(target);unique[str(target.combat_id)]=target
	hero.ability_cds[1]=float(DeathKnightData.VALUES.howling_cooldown);hero.death_knight_runtime.howling_cast_serial=int(hero.death_knight_runtime.howling_cast_serial)+1;DeathKnightSystem.telemetry_add(hero,"w_casts")
	for target in path_contacts:var path_result:=deal_damage(hero,target,DeathKnightSystem.howling_damage(hero),"basic_ability","magical","Howling Blast Path",false,"death_knight_howling_path",[],true);DeathKnightSystem.telemetry_add(hero,"w_path_hits");DeathKnightSystem.telemetry_add(hero,"w_damage",float(path_result.resolved_damage))
	for target in final_contacts:var final_result:=deal_damage(hero,target,DeathKnightSystem.howling_damage(hero),"basic_ability","magical","Howling Blast",false,"death_knight_howling",[],true);DeathKnightSystem.telemetry_add(hero,"w_final_hits");DeathKnightSystem.telemetry_add(hero,"w_damage",float(final_result.resolved_damage))
	var quest_ids:Array=[];var icebound_contacts:=0
	for id in unique:
		var target:Dictionary=unique[id];var extension:=DeathKnightSystem.extend_preexisting_controls(hero,target);for kind in extension:DeathKnightSystem.telemetry_add(hero,"control_extensions");DeathKnightSystem.telemetry_add(hero,"control_duration_added",float(extension[kind]))
		var root:=CombatSystem.apply_control(target,"root",DeathKnightSystem.howling_root(hero));DeathKnightSystem.telemetry_add(hero,"w_roots" if bool(root.applied) else "w_resists")
		if DeathKnightSystem.has_talent(hero,"death_knight_l18_3"):var stun:=CombatSystem.apply_control(target,"stun",float(DeathKnightData.VALUES.icebound_stun));CombatSystem.apply_control(target,"slow",float(DeathKnightData.VALUES.icebound_slow_duration),float(DeathKnightData.VALUES.icebound_slow));DeathKnightSystem.telemetry_add(hero,"icebound_stuns" if bool(stun.applied) else "w_resists");DeathKnightSystem.telemetry_add(hero,"icebound_slows");icebound_contacts+=1
		refresh_dominion_from_howling(hero,target);if TargetCategorySystem.qualifies_quest(target):quest_ids.append(id)
	DeathKnightSystem.add_frost_presence_progress(hero,quest_ids);hero.ability_cds[1]=maxf(0.0,float(hero.ability_cds[1])-mini(int(DeathKnightData.VALUES.icebound_contact_cap),icebound_contacts)*float(DeathKnightData.VALUES.icebound_cdr));DeathKnightSystem.telemetry_add(hero,"icebound_cdr",mini(int(DeathKnightData.VALUES.icebound_contact_cap),icebound_contacts)*float(DeathKnightData.VALUES.icebound_cdr));DeathKnightSystem.telemetry_add(hero,"w_unique_hits",unique.size());death_knight_visual("death_knight_howling",hero.pos,center,.55,{"radius":DeathKnightSystem.howling_radius(hero),"width":float(DeathKnightData.SPACE.howling_path_width)});return true

func cast_death_knight_tempest(hero:Dictionary)->bool:
	var result:=DeathKnightSystem.toggle_tempest(hero);if not bool(result.get("changed",false)):return false
	death_knight_visual("death_knight_tempest_on" if bool(result.active) else "death_knight_tempest_off",hero.pos,hero.pos,.4,{"radius":float(DeathKnightData.SPACE.tempest_radius)});return true

func cast_death_knight_heroic(hero:Dictionary,point:Vector2)->bool:
	if not DeathKnightSystem.action_allowed(hero,3):return false
	if str(hero.selected_heroic_id)=="death_knight_l15_r1":var created:=DeathKnightSystem.cast_army(hero);if created.is_empty():return false;death_knight_visual("death_knight_army",hero.pos,hero.pos,.6);return true
	if str(hero.selected_heroic_id)!="death_knight_l15_r2" or float(hero.ability_cds[3])>0.0:return false
	var direction:=Vector2(hero.pos).direction_to(point)
	if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var distance:=float(DeathKnightData.SPACE.sindragosa_range)*(2.0 if DeathKnightSystem.has_talent(hero,"death_knight_l27_r2") else 1.0)
	var destination:=Vector2(hero.pos)+direction*distance
	for target in enemies:
		if target.hp<=0.0 or not TargetCategorySystem.qualifies_immediate(target) or not CombatGeometry.segment_hits_circle(hero.pos,destination,target.pos,float(DeathKnightData.SPACE.sindragosa_width)+float(target.get("combat_radius",28.0))):continue
		var result:=deal_damage(hero,target,DeathKnightSystem.scaled(hero,float(DeathKnightData.VALUES.sindragosa_damage)),"heroic","magical","Summon Sindragosa",false,"death_knight_sindragosa",[],true);var root_duration:=0.0
		if DeathKnightSystem.has_talent(hero,"death_knight_l27_r2"):var root:=CombatSystem.apply_control(target,"root",float(DeathKnightData.VALUES.absolute_root));root_duration=float(root.duration);DeathKnightSystem.telemetry_add(hero,"absolute_roots",1 if bool(root.applied) else 0)
		if root_duration>0.0:
			if not hero.death_knight_runtime.has("delayed_effects"):hero.death_knight_runtime["delayed_effects"]=[]
			hero.death_knight_runtime.delayed_effects.append({"kind":"sindragosa_slow","remaining":root_duration,"target_id":str(target.combat_id)})
		else:CombatSystem.apply_control(target,"slow",float(DeathKnightData.VALUES.sindragosa_slow_duration),float(DeathKnightData.VALUES.sindragosa_slow))
		var blind:=CombatSystem.apply_blind(target,float(DeathKnightData.VALUES.sindragosa_blind));DeathKnightSystem.telemetry_add(hero,"sindragosa_hits");DeathKnightSystem.telemetry_add(hero,"sindragosa_damage",float(result.resolved_damage));DeathKnightSystem.telemetry_add(hero,"sindragosa_blinds",1 if bool(blind.applied) else 0)
	hero.ability_cds[3]=float(DeathKnightData.VALUES.sindragosa_cooldown);DeathKnightSystem.telemetry_add(hero,"sindragosa_casts");death_knight_visual("death_knight_sindragosa",hero.pos,destination,.8,{"width":float(DeathKnightData.SPACE.sindragosa_width)});return true

func cast_death_knight_ability(slot:int,point:Vector2,_item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Death Knight" or hero.get("death_knight_runtime",{}).is_empty():return false
	if slot!=2 and not DeathKnightSystem.action_allowed(hero,slot):return false
	match slot:
		0:
			var self_cast:=point.distance_to(Vector2(hero.pos))<=float(hero.get("combat_radius",DeathKnightData.SPACE.combat_radius))
			return cast_death_knight_death_coil(hero,null,self_cast)
		1:return cast_death_knight_howling_blast(hero,point)
		2:return cast_death_knight_tempest(hero)
		3:return cast_death_knight_heroic(hero,point)
		4:return cast_death_knight_frostmourne(hero)
	return false

func death_knight_refresh_rune_aura(hero:Dictionary,ally:Dictionary,delta:float)->void:
	var source_id:="death_knight_rune_aura:%s"%str(hero.combat_id);HealingReceivedModifierSystem.remove(ally,source_id)
	if not bool(hero.death_knight_runtime.tempest.active) or DeathKnightSystem.rune_aura_bonus(hero)<=0.0 or ally.hp<=0.0 or hero.pos.distance_to(ally.pos)>float(DeathKnightData.SPACE.tempest_radius):return
	HealingReceivedModifierSystem.apply(ally,source_id,DeathKnightSystem.rune_aura_bonus(hero),maxf(.15,delta*2.0),str(hero.combat_id))

func death_knight_tempest_tick(hero:Dictionary)->void:
	var contacts:=0
	for target in enemies:
		if target.hp<=0.0 or not TargetCategorySystem.qualifies_immediate(target) or hero.pos.distance_to(target.pos)>float(DeathKnightData.SPACE.tempest_radius):continue
		var plan:=DeathKnightSystem.tempest_tick_plan(hero,target);var result:=deal_damage(hero,target,float(plan.damage),"periodic","magical","Frozen Tempest",false,"death_knight_tempest",[],true);StatusEffectSystem.apply_source_control(target,"death_knight_tempest:%s"%str(hero.combat_id),"slow",DeathKnightSystem.tempest_linger(hero),float(plan.suppression));StatusEffectSystem.apply_source_control(target,"death_knight_tempest:%s"%str(hero.combat_id),"attack_speed",DeathKnightSystem.tempest_linger(hero),float(plan.suppression));if bool(plan.root):CombatSystem.apply_control(target,"root",float(DeathKnightData.VALUES.remorseless_root));DeathKnightSystem.telemetry_add(hero,"remorseless_roots")
		DeathKnightSystem.telemetry_add(hero,"tempest_damage",float(result.resolved_damage));contacts+=1
	DeathKnightSystem.note_tempest_contacts(hero,contacts);DeathKnightSystem.telemetry_add(hero,"tempest_ticks");DeathKnightSystem.telemetry_add(hero,"tempest_targets",contacts);death_knight_visual("death_knight_tempest_tick",hero.pos,hero.pos,.25,{"radius":float(DeathKnightData.SPACE.tempest_radius)})

func update_death_knight_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Death Knight" or hero.get("death_knight_runtime",{}).is_empty():continue
		if float(hero.get("hp",0.0))<=0.0:
			DeathKnightSystem.defeat(hero)
			continue
		var update:=DeathKnightSystem.update(hero,delta);hero.ability_cds[2]=float(hero.death_knight_runtime.tempest.cooldown);hero.ability_cds[4]=float(hero.death_knight_runtime.frostmourne_cooldown);hero.basic_action_amount=DeathKnightSystem.basic_attack_amount(hero);hero.damage=hero.basic_action_amount
		if str(hero.get("selected_heroic_id",""))=="death_knight_l15_r1":
			var army_state:=AbilitySlotSystem.ui_state(hero.death_knight_runtime.army_slot)
			hero.ability_cds[3]=0.0 if int(army_state.charges)>0 else float(army_state.recharge)
		if bool(update.tempest_tick):death_knight_tempest_tick(hero)
		for ally in heroes:death_knight_refresh_rune_aura(hero,ally,delta)
		for id in hero.death_knight_runtime.recent_dominion.keys():hero.death_knight_runtime.recent_dominion[id].remaining=maxf(0.0,float(hero.death_knight_runtime.recent_dominion[id].remaining)-delta);if float(hero.death_knight_runtime.recent_dominion[id].remaining)<=0.0:hero.death_knight_runtime.recent_dominion.erase(id)
		for delayed in hero.death_knight_runtime.get("delayed_effects",[]):
			delayed.remaining=float(delayed.remaining)-delta
			if float(delayed.remaining)<=0.0:
				var target=unit_by_combat_id(str(delayed.target_id))
				if target!=null:CombatSystem.apply_control(target,"slow",float(DeathKnightData.VALUES.sindragosa_slow_duration),float(DeathKnightData.VALUES.sindragosa_slow))
		hero.death_knight_runtime["delayed_effects"]=hero.death_knight_runtime.get("delayed_effects",[]).filter(func(effect):return float(effect.remaining)>0.0)
		for ghoul in hero.death_knight_runtime.ghouls:
			var targets:=enemies.filter(func(enemy):return enemy.hp>0.0 and TargetCategorySystem.qualifies_immediate(enemy) and Vector2(ghoul.pos).distance_to(Vector2(enemy.pos))<=float(DeathKnightData.SPACE.ghoul_acquisition));targets.sort_custom(func(a,b):return Vector2(a.pos).distance_to(Vector2(ghoul.pos))<Vector2(b.pos).distance_to(Vector2(ghoul.pos)))
			if targets.is_empty():ghoul.target_id="";continue
			ghoul.target_id=str(targets[0].combat_id)
			var attack_distance:=float(ghoul.range)+float(ghoul.combat_radius)+float(targets[0].get("combat_radius",28.0))
			if Vector2(ghoul.pos).distance_to(Vector2(targets[0].pos))>attack_distance:
				ghoul.pos=CombatGeometry.move_toward_safe(Vector2(ghoul.pos),Vector2(targets[0].pos),float(ghoul.movement_speed)*delta,float(ghoul.combat_radius),combat_blockers)
				continue
			if float(ghoul.attack_cooldown)>0.0:continue
			var ghoul_result:=deal_damage(hero,targets[0],float(ghoul.damage),"summon","physical","Army Ghoul",true,"death_knight_ghoul",[],true);ghoul.attack_cooldown=float(DeathKnightData.VALUES.ghoul_interval);DeathKnightSystem.telemetry_add(hero,"ghoul_attacks");DeathKnightSystem.telemetry_add(hero,"ghoul_damage",float(ghoul_result.resolved_damage));death_knight_visual("death_knight_ghoul_attack",Vector2(ghoul.pos),Vector2(targets[0].pos),.2)
