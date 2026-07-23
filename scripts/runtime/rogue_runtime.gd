extends "res://scripts/runtime/warlock_runtime.gd"

func rogue_visual(kind:String,from:Vector2,to:Vector2,duration:float,text_value:String="",extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":text_value,"color":CLASSES.Rogue.color,"life":maxf(0.08,duration),"max_life":maxf(0.08,duration)};effect.merge(extra,true);effects.append(effect)

func rogue_damage(hero:Dictionary,target:Dictionary,amount:float,action:String,origin:String,can_crit:bool=true)->Dictionary:
	return deal_damage(hero,target,amount,action,"physical",origin,false,"",[],can_crit)

func rogue_target(hero:Dictionary,max_range:float):
	var target_index:=combat_enemy_target()
	if target_index<0 or target_index>=enemies.size():return null
	var target:Dictionary=enemies[target_index]
	if not target_is_valid_for(hero,target,"enemy") or hero.pos.distance_to(target.pos)>max_range:return null
	return target

func rogue_controlled(target:Dictionary)->bool:
	return target.get("active_effects",[]).any(func(effect):return str(effect.get("control_type","")) in ["stun","root","silence"] and float(effect.get("remaining_duration",0.0))>0.0)

func cast_rogue_sinister(hero:Dictionary,point:Vector2,item_repeat:bool=false)->bool:
	if not item_repeat and float(hero.ability_cds[0])>0.0:return false
	var range_limit:=float(RogueData.SPACE.sinister_range)-(float(RogueData.SPACE.mutilate_range_penalty) if RogueSystem.has_talent(hero,"rogue_l18_1") else 0.0)
	var direction:Vector2=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var first=null;var first_projection:=INF
	for target in enemies:
		if target.hp<=0:continue
		var offset:Vector2=target.pos-hero.pos;var projection:=offset.dot(direction)
		if projection<0.0 or projection>range_limit or absf(offset.cross(direction))>float(RogueData.SPACE.sinister_width):continue
		if CombatGeometry.first_blocker(hero.pos,target.pos,combat_blockers,"blocks_movement")>=0:continue
		if projection<first_projection:first=target;first_projection=projection
	if first==null:return false
	CombatRulesV1.preserve_command(hero);hero.ability_cds[0]=float(RogueData.VALUES.q_cooldown)
	var controlled:=rogue_controlled(first);var amount:=RogueSystem.scaled(hero,float(RogueData.VALUES.q_damage))
	if RogueSystem.has_talent(hero,"rogue_l18_1"):amount*=2.25
	if RogueSystem.has_talent(hero,"rogue_l24_1") and controlled:amount*=1.5
	var result:=rogue_damage(hero,first,amount,"basic_ability","Sinister Strike")
	if ComboPointSystem.successful_hit(result):
		hero.pos=first.pos+first.pos.direction_to(hero.pos)*46.0;hero.dest=hero.pos;hero.ability_cds[0]=maxf(0.01,float(hero.ability_cds[0])-1.0-(1.0 if RogueSystem.has_talent(hero,"rogue_l12_1") else 0.0));RogueSystem.gain_points(hero,2 if RogueSystem.has_talent(hero,"rogue_l24_1") and controlled else 1);RogueSystem.telemetry_add(hero,"sinister_hits")
	CombatRulesV1.issue_move(hero,hero.pos);CombatRulesV1.restore_preserved_command(hero,false);RogueSystem.telemetry_add(hero,"sinister_casts");rogue_visual("rogue_dash",hero.pos,first.pos,0.18);return true

func cast_rogue_blade(hero:Dictionary,item_repeat:bool=false)->bool:
	if not item_repeat and float(hero.ability_cds[1])>0.0:return false
	hero.ability_cds[1]=float(RogueData.VALUES.w_cooldown);var amount:=RogueSystem.scaled(hero,float(RogueData.VALUES.w_damage)+float(RogueData.VALUES.fatal_per_hit)*int(hero.rogue_runtime.fatal_finesse_stacks));var successful:Array=[]
	for target in enemies:
		if target.hp<=0 or target.pos.distance_to(hero.pos)>float(RogueData.SPACE.blade_radius):continue
		var result:=rogue_damage(hero,target,amount,"basic_ability","Blade Flurry")
		if ComboPointSystem.successful_hit(result):successful.append(target)
	if not successful.is_empty():RogueSystem.gain_points(hero,2 if successful.size()>=3 and RogueSystem.has_talent(hero,"rogue_l24_3") else 1)
	if RogueSystem.has_talent(hero,"rogue_l18_2"):
		var progress:=successful.filter(func(target):return not bool(target.get("summoned_unit",false)) and not bool(target.get("object",false)) and "training" not in target.get("combat_tags",[])).size();hero.rogue_runtime.fatal_finesse_stacks=mini(int(RogueData.VALUES.fatal_max_stacks),int(hero.rogue_runtime.fatal_finesse_stacks)+progress);RogueSystem.telemetry_add(hero,"fatal_finesse_progress",progress)
	RogueSystem.telemetry_add(hero,"blade_casts");RogueSystem.telemetry_add(hero,"blade_hits",successful.size());rogue_visual("rogue_blade_flurry",hero.pos,hero.pos,0.30,"",{"radius":float(RogueData.SPACE.blade_radius)});return true

func cast_rogue_eviscerate(hero:Dictionary,item_repeat:bool=false)->bool:
	if not item_repeat and float(hero.ability_cds[2])>0.0 or ComboPointSystem.current(hero)<=0:return false
	var target=rogue_target(hero,float(RogueData.SPACE.opener_range));if target==null:return false
	var used:=ComboPointSystem.eviscerate_snapshot(hero);var result:=rogue_damage(hero,target,RogueSystem.scaled(hero,float(RogueData.VALUES.e_per_point)*used),"basic_ability","Eviscerate")
	if not ComboPointSystem.successful_hit(result):return false
	var free:=false
	for cloud in hero.rogue_runtime.smoke_clouds:
		if float(cloud.remaining)>0.0 and hero.pos.distance_to(Vector2(cloud.center))<=float(cloud.radius) and not bool(hero.rogue_runtime.smoke_free_used.get(str(cloud.cast_id),false)) and RogueSystem.has_talent(hero,"rogue_l27_r1"):free=true;hero.rogue_runtime.smoke_free_used[str(cloud.cast_id)]=true;break
	var spent:=ComboPointSystem.spend(hero,used,free);hero.ability_cds[2]=float(RogueData.VALUES.e_cooldown)
	var finisher_event_result:=result.duplicate(true);finisher_event_result.merge(spent,true);combat_events.append(CombatSystem.create_event("rogue_eviscerate_resolved",hero,target,finisher_event_result,{"source_action":"basic_ability","origin":"Eviscerate"}))
	if RogueSystem.has_talent(hero,"rogue_l9_1"):hero.rogue_runtime.block_charges=mini(3,int(hero.rogue_runtime.block_charges)+int(spent.combo_points_consumed))
	if RogueSystem.has_talent(hero,"rogue_l18_3") and used==3:hero.rogue_runtime.slice_attacks=3;hero.rogue_runtime.slice_remaining=float(RogueData.VALUES.slice_duration)
	RogueSystem.telemetry_add(hero,"eviscerate_casts");RogueSystem.telemetry_add(hero,"eviscerate_points_used",used);RogueSystem.telemetry_add(hero,"eviscerate_points_consumed",int(spent.combo_points_consumed));rogue_visual("rogue_eviscerate",hero.pos,target.pos,0.20,"-%d"%int(result.resolved_damage));return true

func cast_rogue_opener(hero:Dictionary,slot:int)->bool:
	var opener_id:String=["rogue_stealth_q","rogue_stealth_w","rogue_stealth_e"][slot]
	if float(hero.get("alternate_cooldowns",{}).get(opener_id,0.0))>0.0:return false
	var target=rogue_target(hero,RogueSystem.opener_range(hero));if target==null:return false
	var teleported:=bool(hero.rogue_runtime.opener_ready)
	if teleported:hero.pos=target.pos+target.pos.direction_to(hero.pos)*46.0;hero.dest=hero.pos;RogueSystem.telemetry_add(hero,"teleport_openers")
	var result:Dictionary
	if slot==0:
		var isolated:=enemies.filter(func(other):return other!=target and other.hp>0 and not bool(other.get("object",false)) and other.pos.distance_to(target.pos)<=float(RogueData.SPACE.isolation_radius)).is_empty();var amount:=RogueSystem.scaled(hero,float(RogueData.VALUES.ambush_damage))*(1.5 if isolated and RogueSystem.has_talent(hero,"rogue_l24_2") else 1.0);result=rogue_damage(hero,target,amount,"basic_ability","Ambush")
		if ComboPointSystem.successful_hit(result):ArmorReductionSystem.apply(target,"ambush:%s"%str(hero.combat_id),RogueSystem.scaled(hero,float(RogueData.VALUES.ambush_armor_reduction)),float(RogueData.VALUES.ambush_duration)+(5.0 if isolated and RogueSystem.has_talent(hero,"rogue_l24_2") else 0.0));if teleported and RogueSystem.has_talent(hero,"rogue_l21_1"):hero.ability_cds[4]=maxf(0.0,float(hero.ability_cds[4])-4.0)
	elif slot==1:
		result=rogue_damage(hero,target,RogueSystem.scaled(hero,float(RogueData.VALUES.cheap_damage)),"basic_ability","Cheap Shot")
		if ComboPointSystem.successful_hit(result):var stun:=CombatSystem.apply_control(target,"stun",float(RogueData.VALUES.cheap_stun));hero.rogue_runtime.delayed_effects.append({"kind":"cheap_blind","remaining":float(stun.duration),"target_id":str(target.combat_id),"duration":float(RogueData.VALUES.cheap_blind)+(2.5 if RogueSystem.has_talent(hero,"rogue_l21_2") else 0.0)})
	else:
		result=rogue_damage(hero,target,RogueSystem.scaled(hero,float(RogueData.VALUES.garrote_initial)),"basic_ability","Garrote")
		if ComboPointSystem.successful_hit(result):
			var cast_id:="garrote:%s:%d"%[str(hero.combat_id),int(hero.rogue_runtime.get("next_cast_id",1))];hero.rogue_runtime["next_cast_id"]=int(hero.rogue_runtime.get("next_cast_id",1))+1
			var instance:=PeriodicStatusSystem.make_instance("rogue_garrote",str(hero.combat_id),str(target.combat_id),float(RogueData.VALUES.garrote_duration),float(RogueData.VALUES.garrote_tick),{"family":"garrote","cast_id":cast_id,"damage":RogueSystem.scaled(hero,float(RogueData.VALUES.garrote_periodic))*(2.0 if RogueSystem.has_talent(hero,"rogue_l30_1") else 1.0),"damage_over_time":true,"color":Color("9b6bd6")});hero.rogue_runtime.garrotes=hero.rogue_runtime.garrotes.filter(func(old):return not (str(old.owner_id)==str(hero.combat_id) and str(old.target_id)==str(target.combat_id)));hero.rogue_runtime.garrotes.append(instance);CombatSystem.apply_control(target,"silence",float(RogueData.VALUES.garrote_silence))
	if not ComboPointSystem.successful_hit(result):return false
	RogueSystem.note_opener(hero);hero.alternate_cooldowns[opener_id]=float(RogueData.VALUES.opener_cooldown);rogue_visual("rogue_opener",hero.pos,target.pos,0.20);return true

func rogue_apply_cloak(hero:Dictionary,source_id:String)->void:
	for owner in heroes:
		if str(owner.get("class",""))=="Rogue" and not owner.get("rogue_runtime",{}).is_empty():owner.rogue_runtime.garrotes=owner.rogue_runtime.garrotes.filter(func(instance):return str(instance.get("target_id",""))!=str(hero.get("combat_id","")))
	RogueSystem.apply_cloak(hero,source_id)

func cast_rogue_heroic(hero:Dictionary)->bool:
	if float(hero.ability_cds[3])>0.0:return false
	if str(hero.get("selected_heroic_id",""))=="rogue_l15_r1":
		var cast_id:="smoke:%s:%d"%[str(hero.combat_id),int(hero.rogue_runtime.get("next_cast_id",1))];hero.rogue_runtime.next_cast_id=int(hero.rogue_runtime.get("next_cast_id",1))+1;hero.rogue_runtime.smoke_clouds.append({"cast_id":cast_id,"center":hero.pos,"radius":float(RogueData.SPACE.smoke_radius),"remaining":float(RogueData.VALUES.smoke_duration)});hero.ability_cds[3]=float(RogueData.VALUES.smoke_cooldown);RogueSystem.telemetry_add(hero,"smoke_casts");return true
	if str(hero.get("selected_heroic_id",""))=="rogue_l15_r2":rogue_apply_cloak(hero,"rogue_cloak");hero.ability_cds[3]=float(RogueData.VALUES.cloak_cooldown);RogueSystem.telemetry_add(hero,"cloak_casts");return true
	return false

func cast_rogue_ability(slot:int,point:Vector2,item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Rogue" or hero.get("rogue_runtime",{}).is_empty():return false
	if bool(hero.rogue_runtime.vanish_active) and slot<3:return cast_rogue_opener(hero,slot)
	match slot:
		0:return cast_rogue_sinister(hero,point,item_repeat)
		1:return cast_rogue_blade(hero,item_repeat)
		2:return cast_rogue_eviscerate(hero,item_repeat)
		3:return cast_rogue_heroic(hero)
	return false

func use_rogue_trait(hero:Dictionary)->bool:
	var result:=RogueSystem.activate_vanish(hero)
	if result and RogueSystem.has_talent(hero,"rogue_l27_r2") and str(hero.get("selected_heroic_id",""))=="rogue_l15_r2":rogue_apply_cloak(hero,"rogue_cloak")
	return result

func update_rogue_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Rogue" or hero.get("rogue_runtime",{}).is_empty():continue
		RogueSystem.update(hero,delta);hero.basic_attack_interval=RogueSystem.attack_interval(hero)
		for index in range(hero.rogue_runtime.smoke_clouds.size()-1,-1,-1):
			var cloud:Dictionary=hero.rogue_runtime.smoke_clouds[index];cloud.remaining=float(cloud.remaining)-delta;var inside:bool=Vector2(hero.pos).distance_to(Vector2(cloud.center))<=float(cloud.radius);StealthDetectionSystem.set_source(hero,str(cloud.cast_id),inside,true,true)
			if float(cloud.remaining)<=0.0:StealthDetectionSystem.set_source(hero,str(cloud.cast_id),false);hero.rogue_runtime.smoke_clouds.remove_at(index)
			else:hero.rogue_runtime.smoke_clouds[index]=cloud
		for index in range(hero.rogue_runtime.delayed_effects.size()-1,-1,-1):
			var effect:Dictionary=hero.rogue_runtime.delayed_effects[index];effect.remaining=float(effect.remaining)-delta
			if float(effect.remaining)<=0.0:
				var target=unit_by_combat_id(str(effect.target_id))
				if target!=null:CombatSystem.apply_blind(target,float(effect.duration))
				hero.rogue_runtime.delayed_effects.remove_at(index)
			else:hero.rogue_runtime.delayed_effects[index]=effect
		for index in range(hero.rogue_runtime.garrotes.size()-1,-1,-1):
			var instance:=PeriodicStatusSystem.advance(hero.rogue_runtime.garrotes[index],delta);var target=unit_by_combat_id(str(instance.target_id))
			if target!=null:
				for tick in int(instance.due_ticks):rogue_damage(hero,target,float(instance.payload.damage)/7.0,"periodic","Garrote",false);RogueSystem.telemetry_add(hero,"garrote_ticks")
			if bool(instance.expired) or target==null or target.hp<=0.0:hero.rogue_runtime.garrotes.remove_at(index)
			else:hero.rogue_runtime.garrotes[index]=instance
