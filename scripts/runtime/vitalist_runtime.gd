extends "res://scripts/runtime/vanguard_runtime.gd"

func vitalist_enemies()->Array:return enemies.filter(func(enemy):return float(enemy.get("hp",0.0))>0.0 and TargetCategorySystem.qualifies_immediate(enemy))
func vitalist_allies()->Array:return player_healable_units().filter(func(ally):return float(ally.get("hp",0.0))>0.0 and (not bool(ally.get("summoned_unit",false)) or bool(ally.get("ordinary_heal_eligible",false))))
func vitalist_facing(hero:Dictionary,point:Vector2)->Vector2:
	var result:=Vector2(hero.pos).direction_to(point)
	if result==Vector2.ZERO:result=Vector2(hero.get("facing_direction",Vector2.RIGHT))
	return result.normalized() if result!=Vector2.ZERO else Vector2.RIGHT
func vitalist_clamped_point(hero:Dictionary,point:Vector2,range_limit:float)->Vector2:
	var offset:=point-Vector2(hero.pos)
	if offset.length()>range_limit:point=Vector2(hero.pos)+offset.normalized()*range_limit
	return point.clamp(Vector2(55,70),Vector2(1225,620))
func vitalist_visual(kind:String,from:Vector2,to:Vector2,duration:float=.45,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Vitalist.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)
func vitalist_apply_armor(target:Dictionary,hero:Dictionary,amount:float,duration:float)->void:
	var source_id:="vitalist_biotic:%s"%str(hero.combat_id);target["temporary_armor_sources"]=target.get("temporary_armor_sources",[]);var found=null
	for source in target.temporary_armor_sources:if str(source.get("id",""))==source_id:found=source;break
	if found==null:target.temporary_armor_sources.append({"id":source_id,"armor":amount,"remaining":duration})
	else:found.armor=maxf(float(found.armor),amount);found.remaining=maxf(float(found.remaining),duration)
func vitalist_has_q(hero:Dictionary,target_id:String)->bool:return hero.vitalist_runtime.q_infections.any(func(q):return str(q.target_id)==target_id and float(q.remaining)>0.0)
func vitalist_q_amount(hero:Dictionary,target:Dictionary)->float:
	var amount:=VitalistData.scaled(float(VitalistData.VALUES.q_total_heal),int(hero.level))*float(VitalistData.VALUES.q_tick)/float(VitalistData.VALUES.q_duration)
	if VitalistSystem.has_talent(hero,"vitalist_l24_2"):amount*=float(VitalistData.VALUES.carrier_hot_multiplier)
	if VitalistSystem.has_talent(hero,"vitalist_l30_1") and float(target.hp)>float(target.max_hp)*float(VitalistData.VALUES.top_off_threshold):var bonus:=amount*float(VitalistData.VALUES.top_off_bonus);amount+=bonus;VitalistSystem.add(hero,"top_off_bonus",bonus)
	return amount

func cast_vitalist_q(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[0])>0.0 or not hero.vitalist_runtime.arm.is_empty():return false
	var candidates:=vitalist_allies().filter(func(ally):return Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(VitalistData.SPACE.q_range))
	candidates.sort_custom(func(a,b):return Vector2(a.pos).distance_to(point)<Vector2(b.pos).distance_to(point))
	if candidates.is_empty():return false
	var target:Dictionary=candidates[0]
	VitalistSystem.create_q_cast(hero,str(target.combat_id));hero.vitalist_runtime.control_seen[str(target.combat_id)]=int(target.get("control_event_serial",0));hero.ability_cds[0]=float(VitalistData.VALUES.q_cooldown)
	if VitalistSystem.has_talent(hero,"vitalist_l12_2"):vitalist_apply_armor(target,hero,VitalistData.scaled(float(VitalistData.VALUES.biotic_armor),int(hero.level)),float(VitalistData.VALUES.q_duration))
	VitalistSystem.grow_q_in_arm(hero,str(target.combat_id));vitalist_visual("vitalist_q",hero.pos,target.pos,.4)
	return true
func cast_vitalist_w(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[1])>0.0 or not hero.vitalist_runtime.arm.is_empty():return false
	var direction:=vitalist_facing(hero,point);hero.facing_direction=direction;var reach:=float(VitalistData.SPACE.w_range)*(1.5 if VitalistSystem.has_talent(hero,"vitalist_l18_1") else 1.0);var endpoint:=Vector2(hero.pos)+direction*reach;var targets:=vitalist_enemies().filter(func(enemy):return CombatGeometry.segment_hits_circle(hero.pos,endpoint,enemy.pos,float(VitalistData.SPACE.w_radius)+float(enemy.get("combat_radius",24.0))));targets.sort_custom(func(a,b):return Vector2(a.pos).distance_to(Vector2(hero.pos))<Vector2(b.pos).distance_to(Vector2(hero.pos)))
	if targets.is_empty():return false
	hero.ability_cds[1]=VitalistSystem.w_cooldown(hero)
	for enemy in targets.slice(0,int(VitalistData.VALUES.contact_cap)):
		var result:=deal_damage(hero,enemy,VitalistData.scaled(float(VitalistData.VALUES.w_initial_damage),int(hero.level)),"basic_ability","magical","Weighted Pustule",false,"vitalist_w",[],true);VitalistSystem.add(hero,"w_damage",float(result.resolved_damage));VitalistSystem.apply_w(hero,str(enemy.combat_id),TargetCategorySystem.qualifies_quest(enemy))
	vitalist_visual("vitalist_w",hero.pos,endpoint,.5,{"contacts":targets.size()});return true
func cast_vitalist_e(hero:Dictionary,point:Vector2)->bool:
	if not hero.vitalist_runtime.arm.is_empty():VitalistSystem.interrupt_arm(hero);vitalist_visual("vitalist_e_cancel",point,point,.2);return true
	if float(hero.ability_cds[2])>0.0:return false
	var center:Vector2=vitalist_clamped_point(hero,point,float(VitalistData.SPACE.e_range)*(1.3 if VitalistSystem.has_talent(hero,"vitalist_l21_1") else 1.0));VitalistSystem.begin_arm(hero,center);hero.ability_cds[2]=float(VitalistData.VALUES.e_cooldown);hero.command_state=CombatRulesV1.CommandState.IDLE;hero.dest=hero.pos;hero.move_destination=hero.pos;vitalist_visual("vitalist_e",center,center,.6);return true

func vitalist_reactive_apply(hero:Dictionary)->void:
	if not VitalistSystem.has_talent(hero,"vitalist_l9_3") or float(hero.hp)>=float(hero.max_hp)*0.5:return
	var targets:=vitalist_enemies().filter(func(enemy):return Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=float(VitalistData.SPACE.reactive_radius));targets.sort_custom(func(a,b):return str(a.combat_id)<str(b.combat_id))
	for enemy in targets.slice(0,int(VitalistData.VALUES.contact_cap)):VitalistSystem.apply_w(hero,str(enemy.combat_id),TargetCategorySystem.qualifies_quest(enemy),false)
	VitalistSystem.add(hero,"reactive_uses")
func vitalist_detonate(hero:Dictionary)->bool:
	if not AbilitySlotSystem.can_activate(hero.vitalist_runtime.d_slot):VitalistSystem.add(hero,"d_lockout_attempts");return false
	vitalist_reactive_apply(hero);var plan:Dictionary=VitalistSystem.detonate(hero);if plan.is_empty():return false
	var replacement_ids:Array=[]
	for q in plan.q:
		var target=unit_by_combat_id(str(q.target_id));if target==null or float(target.get("hp",0.0))<=0.0:continue
		var amount:=VitalistData.scaled(float(VitalistData.VALUES.d_q_heal),int(hero.level))*float(plan.q_multiplier);var healed:=deal_healing(hero,target,amount,"trait","Bio-Kill Switch","vitalist_d_q",["healing"]);VitalistSystem.add(hero,"d_healing",amount);VitalistSystem.add(hero,"d_effective",float(healed.effective_amount));VitalistSystem.add(hero,"d_overheal",maxf(0.0,amount-float(healed.effective_amount)));if bool(plan.vigorous):VitalistSystem.add(hero,"vigorous_bonus",amount/float(plan.q_multiplier)*(float(plan.q_multiplier)-1.0));if VitalistSystem.has_talent(hero,"vitalist_l12_2"):vitalist_apply_armor(target,hero,VitalistData.scaled(float(VitalistData.VALUES.biotic_burst_armor),int(hero.level)),float(VitalistData.VALUES.biotic_burst_duration))
	for w in plan.w:
		var target=unit_by_combat_id(str(w.target_id));if target==null or float(target.get("hp",0.0))<=0.0:continue
		var affected:Array=[target]
		if bool(plan.poppin):affected=vitalist_enemies().filter(func(enemy):return Vector2(enemy.pos).distance_to(Vector2(target.pos))<=float(VitalistData.SPACE.poppin_radius));affected.sort_custom(func(a,b):return str(a.combat_id)<str(b.combat_id));affected=affected.slice(0,int(VitalistData.VALUES.contact_cap))
		for enemy in affected:
			var hit:=deal_damage(hero,enemy,VitalistData.scaled(float(VitalistData.VALUES.d_w_damage),int(hero.level)),"trait","magical","Bio-Kill Switch",false,"vitalist_d_w",[],true);VitalistSystem.add(hero,"w_damage",float(hit.resolved_damage));StatusEffectSystem.apply_source_control(enemy,"vitalist_d:%s"%str(hero.combat_id),"slow",float(VitalistData.VALUES.d_w_slow_duration),float(VitalistData.VALUES.d_w_slow));if bool(plan.poppin) and str(enemy.combat_id) not in replacement_ids:replacement_ids.append(str(enemy.combat_id))
	for target_id in replacement_ids:var target=unit_by_combat_id(target_id);if target!=null and float(target.get("hp",0.0))>0.0:VitalistSystem.apply_w(hero,target_id,TargetCategorySystem.qualifies_quest(target),false);VitalistSystem.add(hero,"poppin_replacements")
	vitalist_visual("vitalist_d",hero.pos,hero.pos,.55,{"q":plan.q.size(),"w":plan.w.size()});return true

func cast_vitalist_heroic(hero:Dictionary,point:Vector2)->bool:
	if not hero.vitalist_runtime.shove.is_empty():return false
	if not hero.vitalist_runtime.arm.is_empty() and not VitalistSystem.has_talent(hero,"vitalist_l30_2"):return false
	var heroic:=str(hero.selected_heroic_id);hero.facing_direction=vitalist_facing(hero,point)
	if heroic=="vitalist_l15_r1":
		if not VitalistSystem.begin_swipe(hero):return false
		vitalist_visual("vitalist_swipe_start",hero.pos,point,.3);return true
	if float(hero.ability_cds[3])>0.0:return false
	var direction:=Vector2(hero.facing_direction);var targets:=vitalist_enemies().filter(func(enemy):return CombatGeometry.segment_hits_circle(hero.pos,Vector2(hero.pos)+direction*float(VitalistData.SPACE.shove_range),enemy.pos,float(enemy.get("combat_radius",24.0))));targets.sort_custom(func(a,b):return Vector2(a.pos).distance_to(Vector2(hero.pos))<Vector2(b.pos).distance_to(Vector2(hero.pos)));if targets.is_empty():return false
	hero.ability_cds[3]=float(VitalistData.VALUES.shove_cooldown);var target:Dictionary=targets[0];var displacement:=CombatSystem.apply_control(target,"displacement",.05);var start:=Vector2(target.pos)
	var hit:=deal_damage(hero,target,VitalistData.scaled(float(VitalistData.VALUES.shove_damage),int(hero.level)),"heroic","physical","Massive Shove",false,"vitalist_shove",[],true)
	if bool(displacement.applied):hero.vitalist_runtime.shove={"target_id":str(target.combat_id),"direction":direction,"start":start,"elapsed":0.0,"distance":0.0};hero.command_state=CombatRulesV1.CommandState.CHANNEL;hero.dest=hero.pos;hero.move_destination=hero.pos;vitalist_visual("vitalist_shove_capture",hero.pos,start,.25)
	else:StatusEffectSystem.apply_source_control(target,"vitalist_shove:%s"%str(hero.combat_id),"stun",float(VitalistData.VALUES.shove_stun))
	return float(hit.resolved_damage)>0.0 or bool(displacement.applied)
func cast_vitalist_ability(slot:int,point:Vector2)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Vitalist" or hero.get("vitalist_runtime",{}).is_empty():return false
	if not hero.vitalist_runtime.shove.is_empty():return false
	if not hero.vitalist_runtime.arm.is_empty() and slot not in [2,4] and not (slot==3 and VitalistSystem.has_talent(hero,"vitalist_l30_2")):return false
	match slot:
		0:return cast_vitalist_q(hero,point)
		1:return cast_vitalist_w(hero,point)
		2:return cast_vitalist_e(hero,point)
		3:return cast_vitalist_heroic(hero,point)
		4:return vitalist_detonate(hero)
	return false

func vitalist_q_tick(hero:Dictionary,infection:Dictionary)->void:
	var target=unit_by_combat_id(str(infection.target_id));if target==null or float(target.get("hp",0.0))<=0.0:return
	var amount:=vitalist_q_amount(hero,target);var healed:=deal_healing(hero,target,amount,"periodic","Healing Pathogen","vitalist_q",["healing"]);VitalistSystem.add(hero,"q_hot",amount);VitalistSystem.add(hero,"q_effective",float(healed.effective_amount));VitalistSystem.add(hero,"q_overheal",maxf(0.0,amount-float(healed.effective_amount)))
	if VitalistSystem.has_talent(hero,"vitalist_l12_2"):vitalist_apply_armor(target,hero,VitalistData.scaled(float(VitalistData.VALUES.biotic_armor),int(hero.level)),float(VitalistData.VALUES.q_tick)+.1)
func vitalist_q_spread(hero:Dictionary,infection:Dictionary)->void:
	var source=unit_by_combat_id(str(infection.target_id));if source==null:return
	var candidates:=vitalist_allies().filter(func(ally):return Vector2(ally.pos).distance_to(Vector2(source.pos))<=float(VitalistData.SPACE.q_spread_radius) and VitalistSystem.can_spread_to(hero,infection,str(ally.combat_id),not hero.vitalist_runtime.arm.is_empty() and Vector2(ally.pos).distance_to(Vector2(hero.vitalist_runtime.arm.position))<=float(VitalistData.SPACE.e_radius)));candidates.sort_custom(func(a,b):return str(a.combat_id)<str(b.combat_id));if candidates.is_empty():return
	var target:Dictionary=candidates[0];var inside:bool=not hero.vitalist_runtime.arm.is_empty() and Vector2(target.pos).distance_to(Vector2(hero.vitalist_runtime.arm.position))<=float(VitalistData.SPACE.e_radius);VitalistSystem.spread_q(hero,infection,str(target.combat_id),inside);hero.vitalist_runtime.control_seen[str(target.combat_id)]=int(target.get("control_event_serial",0));VitalistSystem.grow_q_in_arm(hero,str(target.combat_id));vitalist_visual("vitalist_q_spread",source.pos,target.pos,.35)
func vitalist_arm_tick(hero:Dictionary)->void:
	var center:=Vector2(hero.vitalist_runtime.arm.position);var targets:=vitalist_enemies().filter(func(enemy):return Vector2(enemy.pos).distance_to(center)<=float(VitalistData.SPACE.e_radius));targets.sort_custom(func(a,b):return str(a.combat_id)<str(b.combat_id));targets=targets.slice(0,int(VitalistData.VALUES.contact_cap));VitalistSystem.note_arm_contacts(hero,targets.size())
	for enemy in targets:
		var amount:=VitalistData.scaled(float(VitalistData.VALUES.e_dps)*float(VitalistData.VALUES.e_tick),int(hero.level));if VitalistSystem.has_talent(hero,"vitalist_l9_2") and float(enemy.hp)<float(enemy.max_hp)*0.5:amount*=2.0
		var hit:=deal_damage(hero,enemy,amount,"periodic","magical","Lurking Arm",false,"vitalist_e",[],true);VitalistSystem.add(hero,"e_damage",float(hit.resolved_damage));var silence:=StatusEffectSystem.apply_source_control(enemy,"vitalist_arm:%s"%str(hero.combat_id),"silence",float(VitalistData.VALUES.e_tick)+.1);if bool(silence.applied):VitalistSystem.add(hero,"e_silence",float(silence.duration))
	for ally in vitalist_allies():if Vector2(ally.pos).distance_to(center)<=float(VitalistData.SPACE.e_radius):VitalistSystem.grow_q_in_arm(hero,str(ally.combat_id))
func vitalist_swipe(hero:Dictionary,index:int)->void:
	var reach:=float(VitalistData.SPACE.swipe_ranges[index]);var facing:=Vector2(hero.get("facing_direction",Vector2.RIGHT));var targets:=vitalist_enemies().filter(func(enemy):var offset:=Vector2(enemy.pos)-Vector2(hero.pos);return offset.length()<=reach and absf(facing.angle_to(offset.normalized()))<=float(VitalistData.SPACE.swipe_half_angle));targets.sort_custom(func(a,b):return str(a.combat_id)<str(b.combat_id))
	for enemy in targets.slice(0,int(VitalistData.VALUES.contact_cap)):
		var hit:=deal_damage(hero,enemy,VitalistData.scaled(float(VitalistData.VALUES.swipe_damage),int(hero.level)),"heroic","physical","Flailing Swipe",false,"vitalist_swipe",[],true);VitalistSystem.add(hero,"swipe_damage",float(hit.resolved_damage));var displacement:=CombatSystem.apply_control(enemy,"displacement",.05);if bool(displacement.applied):var intended:=Vector2(enemy.pos)+facing*float(VitalistData.VALUES.swipe_displacement);enemy.pos=CombatGeometry.safe_endpoint(enemy.pos,intended,float(enemy.get("combat_radius",24.0)),combat_blockers,str(enemy.combat_id));VitalistSystem.add(hero,"displaced")
	vitalist_visual("vitalist_swipe",hero.pos,hero.pos+facing*reach,.45,{"index":index})
func vitalist_w_expire(hero:Dictionary,infection:Dictionary)->void:
	var target=unit_by_combat_id(str(infection.target_id));if target==null or float(target.get("hp",0.0))<=0.0:return
	var hit:=deal_damage(hero,target,VitalistData.scaled(float(VitalistData.VALUES.w_expire_damage),int(hero.level)),"periodic","magical","Weighted Pustule Expiry",false,"vitalist_w_expire",[],true);VitalistSystem.add(hero,"w_damage",float(hit.resolved_damage))

func vitalist_finish_shove(hero:Dictionary,target,collided:bool)->void:
	var shove:Dictionary=hero.vitalist_runtime.shove
	if target!=null:
		StatusEffectSystem.apply_source_control(target,"vitalist_shove:%s"%str(hero.combat_id),"stun",float(VitalistData.VALUES.shove_stun))
		if collided and VitalistSystem.has_talent(hero,"vitalist_l27_r2"):StatusEffectSystem.apply_source_control(target,"vitalist_push:%s"%str(hero.combat_id),"slow",float(VitalistData.VALUES.push_slow_duration),float(VitalistData.VALUES.push_slow))
	VitalistSystem.add(hero,"shove_distance",float(shove.get("distance",0.0)));VitalistSystem.add(hero,"shove_duration",float(shove.get("elapsed",0.0)));if collided:VitalistSystem.add(hero,"shove_collisions")
	if float(shove.get("elapsed",0.0))>float(VitalistData.VALUES.push_threshold) and VitalistSystem.has_talent(hero,"vitalist_l27_r2"):hero.ability_cds[3]=maxf(0.0,float(hero.ability_cds[3])-float(VitalistData.VALUES.push_cdr))
	var endpoint:=Vector2(target.pos) if target!=null else Vector2(shove.get("start",hero.pos));hero.vitalist_runtime.shove={};hero.command_state=CombatRulesV1.CommandState.IDLE;vitalist_visual("vitalist_shove",Vector2(shove.get("start",endpoint)),endpoint,.3,{"collision":collided})

func vitalist_update_shove(hero:Dictionary,delta:float)->void:
	if hero.vitalist_runtime.shove.is_empty():return
	var shove:Dictionary=hero.vitalist_runtime.shove;var target=unit_by_combat_id(str(shove.target_id))
	if target==null or float(target.get("hp",0.0))<=0.0:hero.vitalist_runtime.shove={};hero.command_state=CombatRulesV1.CommandState.IDLE;return
	var start:=Vector2(target.pos);var radius:=float(target.get("combat_radius",24.0));var raw:=start+Vector2(shove.direction)*float(VitalistData.VALUES.shove_speed)*delta;var bounded:=raw.clamp(CombatGeometry.BATTLE_BOUNDS.position+Vector2.ONE*radius,CombatGeometry.BATTLE_BOUNDS.end-Vector2.ONE*radius);var endpoint:=CombatGeometry.safe_endpoint(start,bounded,radius,combat_blockers,str(target.combat_id));var moved:=start.distance_to(endpoint);target.pos=endpoint;shove.distance=float(shove.distance)+moved;shove.elapsed=float(shove.elapsed)+moved/float(VitalistData.VALUES.shove_speed);hero.vitalist_runtime.shove=shove;hero.dest=hero.pos;hero.move_destination=hero.pos;hero.command_state=CombatRulesV1.CommandState.CHANNEL
	var collided:=not raw.is_equal_approx(bounded) or moved+0.01<start.distance_to(bounded)
	if collided:vitalist_finish_shove(hero,target,true)

func update_vitalist_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Vitalist" or hero.get("vitalist_runtime",{}).is_empty():continue
		vitalist_update_shove(hero,delta)
		for event in VitalistSystem.advance(hero,delta):
			match str(event.kind):
				"q_tick":vitalist_q_tick(hero,event.infection)
				"q_spread":vitalist_q_spread(hero,event.infection)
				"w_expire":vitalist_w_expire(hero,event.infection)
				"arm_tick":vitalist_arm_tick(hero)
				"swipe":vitalist_swipe(hero,int(event.index))
		hero.ability_cds[4]=VitalistSystem.d_ui_cooldown(hero);if str(hero.selected_heroic_id)=="vitalist_l15_r1" and VitalistSystem.has_talent(hero,"vitalist_l27_r1"):hero.ability_cds[3]=VitalistSystem.heroic_ui_cooldown(hero)
		for target_id in hero.vitalist_runtime.w_infections.keys():
			var target=unit_by_combat_id(str(target_id));if target!=null:var infection:Dictionary=hero.vitalist_runtime.w_infections[target_id];var slow:=VitalistSystem.w_slow(infection);var applied:=StatusEffectSystem.apply_source_control(target,"vitalist_w:%s"%str(hero.combat_id),"slow",.2,slow);if bool(applied.applied):VitalistSystem.add(hero,"w_slow_time",delta)
		if VitalistSystem.has_talent(hero,"vitalist_l24_1"):
			for ally in vitalist_allies():
				var id:=str(ally.combat_id);var serial:=int(ally.get("control_event_serial",0));var seen:=int(hero.vitalist_runtime.control_seen.get(id,0));hero.vitalist_runtime.control_seen[id]=serial
				if serial>seen and vitalist_has_q(hero,id):var healed:=deal_healing(hero,ally,VitalistData.scaled(float(VitalistData.VALUES.superstrain_heal),int(hero.level)),"talent","Superstrain","vitalist_superstrain",["healing"]);VitalistSystem.add(hero,"superstrain_healing",float(healed.effective_amount))
		if not hero.vitalist_runtime.arm.is_empty():hero.dest=hero.pos;hero.move_destination=hero.pos;hero.command_state=CombatRulesV1.CommandState.IDLE
