extends "res://scripts/runtime/shaman_runtime.gd"

func templar_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Templar.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func templar_enemy_target(hero:Dictionary,max_range:float=INF):
	var index:=combat_enemy_target();if index<0 or index>=enemies.size():return null
	var target:Dictionary=enemies[index];return target if target.hp>0.0 and hero.pos.distance_to(target.pos)<=max_range else null

func templar_sorted_allies(hero:Dictionary)->Array:
	var candidates:=heroes.filter(func(ally):return ally!=hero and ally.hp>0.0 and hero.pos.distance_to(ally.pos)<=float(TemplarData.SPACE.e_range))
	candidates.sort_custom(func(a,b):var da:float=hero.pos.distance_squared_to(a.pos);var db:float=hero.pos.distance_squared_to(b.pos);if not is_equal_approx(da,db):return da<db;var aid:=str(a.get("combat_id",""));var bid:=str(b.get("combat_id",""));return int(a.get("battle_index",0))<int(b.get("battle_index",0)) if aid==bid else aid<bid)
	return candidates

func cast_templar_q(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[0])>0.0:return false
	var direction:=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	hero.templar_runtime.blade_dashes.append({"origin":Vector2(hero.pos),"pos":Vector2(hero.pos),"direction":direction,"phase":"out","remaining":float(TemplarData.SPACE.q_distance),"contact_ids":[]})
	hero.ability_cds[0]=float(TemplarData.VALUES.q_cooldown);TemplarSystem.telemetry_add(hero,"q_casts")
	if TemplarSystem.has_talent(hero,"templar_l24_2"):TemplarSystem.reduce_trait_cooldown(hero,float(TemplarData.VALUES.force_of_will_reduction))
	if TemplarSystem.has_talent(hero,"templar_l18_3"):hero.templar_runtime.final_cut_remaining=float(TemplarData.VALUES.final_cut_window)
	return true

func cast_templar_w(hero:Dictionary)->bool:
	if float(hero.ability_cds[1])>0.0:return false
	var target=templar_enemy_target(hero,float(TemplarData.SPACE.w_charge));if target==null:return false
	var nearby:=enemies.filter(func(enemy):return enemy.hp>0.0 and hero.pos.distance_to(enemy.pos)<=float(TemplarData.SPACE.w_radius)).size()
	var strikes:=int(TemplarData.VALUES.triple_strike_attacks if TemplarSystem.has_talent(hero,"templar_l21_2") else TemplarData.VALUES.w_attacks)
	hero.pos=CombatGeometry.move_toward_safe(hero.pos,target.pos,maxf(0.0,hero.pos.distance_to(target.pos)-float(hero.range)*.8),float(hero.get("combat_radius",42.0)),combat_blockers);hero.dest=hero.pos
	for strike in strikes:hero.templar_runtime.pending_w_strikes.append({"remaining":strike*.14,"target_id":str(target.combat_id),"strike":strike,"total":strikes,"amateur":nearby==1,"crosscut":bool(hero.templar_runtime.crosscut_remaining>0.0)})
	hero.templar_runtime.crosscut_remaining=0.0;hero.ability_cds[1]=float(TemplarData.VALUES.w_cooldown)+(float(TemplarData.VALUES.triple_strike_cooldown_bonus) if strikes==3 else 0.0);TemplarSystem.telemetry_add(hero,"w_casts")
	if TemplarSystem.has_talent(hero,"templar_l24_2"):TemplarSystem.reduce_trait_cooldown(hero,float(TemplarData.VALUES.force_of_will_reduction))
	if TemplarSystem.has_talent(hero,"templar_l18_3"):hero.templar_runtime.final_cut_remaining=float(TemplarData.VALUES.final_cut_window)
	return true

func cast_templar_e(hero:Dictionary)->bool:
	if float(hero.ability_cds[2])>0.0:return false
	var candidates:=templar_sorted_allies(hero);if candidates.is_empty():return false
	var count:=mini(candidates.size(),2 if TemplarSystem.has_talent(hero,"templar_l30_2") else 1);var cast_id:="%s:%f"%[str(hero.combat_id),battle_time];var snapshot_hp:=float(hero.max_hp)
	for index in count:
		var ally:Dictionary=candidates[index];var source_id:="templar_shield_ally:%s:%s"%[cast_id,str(ally.combat_id)];apply_unit_shield(hero,ally,TemplarSystem.e_shield_amount(hero),{"name":"templar_shield_ally","owner_id":str(hero.combat_id),"cast_id":cast_id,"bearer_id":str(ally.combat_id)},source_id,INF,float(TemplarData.VALUES.e_duration));ally["templar_shield_links"]=ally.get("templar_shield_links",[]);ally.templar_shield_links.append({"owner_id":str(hero.combat_id),"cast_id":cast_id,"remaining":float(TemplarData.VALUES.e_duration),"snapshot_hp":snapshot_hp});TemplarSystem.telemetry_add(hero,"e_targets");templar_visual("templar_shield_ally",hero.pos,ally.pos,.3)
	hero.ability_cds[2]=TemplarSystem.e_cooldown(hero);TemplarSystem.telemetry_add(hero,"e_casts")
	if TemplarSystem.has_talent(hero,"templar_l24_2"):TemplarSystem.reduce_trait_cooldown(hero,float(TemplarData.VALUES.force_of_will_reduction))
	if TemplarSystem.has_talent(hero,"templar_l18_3"):hero.templar_runtime.final_cut_remaining=float(TemplarData.VALUES.final_cut_window)
	return true

func cast_templar_heroic(hero:Dictionary,point:Vector2)->bool:
	var heroic:=str(hero.get("selected_heroic_id",""))
	if heroic=="templar_l15_r1":
		if int(hero.templar_runtime.r1_charges)<=0 or float(hero.templar_runtime.r1_interuse)>0.0:return false
		var center:Vector2=point.clamp(Vector2(55,70),Vector2(1225,620));for target in enemies:if target.hp>0.0 and target.pos.distance_to(center)<=float(TemplarData.SPACE.r1_radius):deal_damage(hero,target,TemplarSystem.ability_amount(hero,float(TemplarData.VALUES.r1_damage)),"heroic","magical","Suppression Pulse",false,"templar_r1",[],true);CombatSystem.apply_blind(target,float(TemplarData.VALUES.r1_blind));TemplarSystem.telemetry_add(hero,"r1_hits")
		hero.templar_runtime.r1_charges=int(hero.templar_runtime.r1_charges)-1;hero.templar_runtime.r1_recharge.append(float(TemplarData.VALUES.r1_cooldown));hero.templar_runtime.r1_interuse=float(TemplarData.VALUES.r1_interuse);hero.ability_cds[3]=float(hero.templar_runtime.r1_recharge[0]);TemplarSystem.telemetry_add(hero,"r1_casts");templar_visual("templar_suppression",center,center,.65,{"radius":float(TemplarData.SPACE.r1_radius)});return true
	if heroic=="templar_l15_r2":
		if float(hero.ability_cds[3])>0.0:return false
		var target=templar_enemy_target(hero);if target==null:return false
		hero.templar_runtime.beams.append({"target_id":str(target.combat_id),"pos":Vector2(target.pos),"remaining":float(TemplarData.VALUES.r2_duration),"tick":0.0});hero.ability_cds[3]=float(TemplarData.VALUES.r2_cooldown);TemplarSystem.telemetry_add(hero,"r2_casts");return true
	return false

func cast_templar_ability(slot:int,point:Vector2,_item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Templar" or hero.get("templar_runtime",{}).is_empty():return false
	match slot:
		0:return cast_templar_q(hero,point)
		1:return cast_templar_w(hero)
		2:return cast_templar_e(hero)
		3:return cast_templar_heroic(hero,point)
	return false

func update_templar_dash(hero:Dictionary,dash:Dictionary,delta:float)->bool:
	var previous:=Vector2(dash.pos);var destination:=Vector2(dash.origin)+Vector2(dash.direction)*float(TemplarData.SPACE.q_distance) if dash.phase=="out" else Vector2(dash.origin);var movement:=minf(float(TemplarData.SPACE.q_speed)*delta,previous.distance_to(destination));dash.pos=previous.move_toward(destination,movement);hero.pos=dash.pos;hero.dest=hero.pos
	for target in enemies:
		var key:="%s:%s"%[str(dash.phase),str(target.combat_id)];if target.hp<=0.0 or key in dash.contact_ids or not CombatGeometry.segment_hits_circle(previous,dash.pos,target.pos,float(TemplarData.SPACE.q_width)+float(target.get("combat_radius",28.0))):continue
		dash.contact_ids.append(key);var base:=float(TemplarData.VALUES.q_outward if dash.phase=="out" else TemplarData.VALUES.q_return);if dash.phase=="out" and TemplarSystem.has_talent(hero,"templar_l18_1"):base*=1.0+float(TemplarData.VALUES.solarite_bonus)
		var result:=deal_damage(hero,target,TemplarSystem.ability_amount(hero,base),"basic_ability","physical","Blade Dash",false,"templar_q_%s"%str(dash.phase),[],true);if float(result.get("resolved_damage",0.0))>0.0:var reduction:=TemplarSystem.q_contact_reduction(target);TemplarSystem.reduce_trait_cooldown(hero,reduction);TemplarSystem.telemetry_add(hero,"q_cooldown_reduced",reduction);if TemplarSystem.has_talent(hero,"templar_l9_1"):hero["templar_block"]={"charges":mini(2,int(hero.get("templar_block",{}).get("charges",0))+1),"maximum":2}
		TemplarSystem.telemetry_add(hero,"q_out_hits" if dash.phase=="out" else "q_return_hits")
	templar_visual("templar_blade_dash",previous,dash.pos,.12,{"returning":dash.phase=="return"})
	if dash.pos.distance_to(destination)>.5:return false
	if dash.phase=="out":dash.phase="return";return false
	hero.pos=Vector2(dash.origin);hero.dest=hero.pos;if TemplarSystem.has_talent(hero,"templar_l30_3"):hero.templar_runtime.crosscut_remaining=float(TemplarData.VALUES.crosscut_window)
	return true

func resolve_templar_w_strike(hero:Dictionary,strike:Dictionary)->void:
	var target=unit_by_combat_id(str(strike.target_id));if target==null or target.hp<=0.0:return
	var multiplier:=float(TemplarData.VALUES.amateur_multiplier if bool(strike.amateur) and TemplarSystem.has_talent(hero,"templar_l9_2") else 1.0);var amount:=float(hero.basic_action_amount)*multiplier+TemplarSystem.titan_bonus(hero,true)
	if float(hero.templar_runtime.final_cut_remaining)>0.0:amount+=float(hero.basic_action_amount)*(float(TemplarData.VALUES.final_cut_low_bonus) if float(hero.hp)/maxf(1.0,float(hero.max_hp))<.25 else float(TemplarData.VALUES.final_cut_bonus));hero.templar_runtime.final_cut_remaining=0.0
	var result:=deal_damage(hero,target,amount,"basic_attack","physical","Twin Blades",false,"templar_w_strike",[],true);if float(result.get("resolved_damage",0.0))<=0.0:return
	TemplarSystem.note_successful_basic_attack(hero,target,true);TemplarSystem.telemetry_add(hero,"w_strikes")
	if int(strike.strike)==int(strike.total)-1 and TemplarSystem.has_talent(hero,"templar_l30_1"):ArmorReductionSystem.apply(target,"templar_psionic_wound",float(TemplarData.VALUES.psionic_armor_reduction),float(TemplarData.VALUES.psionic_duration))
	if bool(strike.crosscut):
		var forward:Vector2=Vector2(hero.pos).direction_to(Vector2(target.pos));var candidates:=enemies.filter(func(enemy):return enemy.hp>0.0 and enemy!=target and target.pos.distance_to(enemy.pos)<=float(TemplarData.SPACE.crosscut_rear_arc) and forward.dot(target.pos.direction_to(enemy.pos))>0.15);candidates.sort_custom(func(a,b):return target.pos.distance_squared_to(a.pos)<target.pos.distance_squared_to(b.pos))
		if not candidates.is_empty():var rear:Dictionary=candidates[0];var rear_result:=deal_damage(hero,rear,amount,"basic_attack","physical","Crosscut",false,"templar_crosscut",[],true);if float(rear_result.get("resolved_damage",0.0))>0.0:TemplarSystem.note_successful_basic_attack(hero,rear,true);TemplarSystem.telemetry_add(hero,"crosscut_strikes")

func update_templar_beam(hero:Dictionary,beam:Dictionary,delta:float)->bool:
	beam.remaining=float(beam.remaining)-delta;beam.tick=float(beam.tick)-delta;var target=unit_by_combat_id(str(beam.target_id))
	if target==null or target.hp<=0.0:
		if not TemplarSystem.has_talent(hero,"templar_l27_r2"):return true
		var living:=enemies.filter(func(enemy):return enemy.hp>0.0);if living.is_empty():return true
		living.sort_custom(func(a,b):return hero.pos.distance_squared_to(a.pos)<hero.pos.distance_squared_to(b.pos));target=living[0];beam.target_id=str(target.combat_id)
	var speed:=float(TemplarData.SPACE.r2_speed)*(1.0+float(TemplarData.VALUES.target_purified_speed) if TemplarSystem.has_talent(hero,"templar_l27_r2") else 0.0);beam.pos=Vector2(beam.pos).move_toward(target.pos,speed*delta)
	if beam.tick<=0.0 and Vector2(beam.pos).distance_to(target.pos)<=55.0:deal_damage(hero,target,TemplarSystem.ability_amount(hero,float(TemplarData.VALUES.r2_dps)),"heroic","magical","Purifier Beam",false,"templar_r2",[],false);beam.tick+=1.0;TemplarSystem.telemetry_add(hero,"r2_ticks")
	templar_visual("templar_purifier_beam",Vector2(beam.pos)-Vector2(0,200),Vector2(beam.pos),.18);return beam.remaining<=0.0

func update_templar_links(delta:float)->void:
	for bearer in heroes:
		for index in range(bearer.get("templar_shield_links",[]).size()-1,-1,-1):bearer.templar_shield_links[index].remaining=float(bearer.templar_shield_links[index].remaining)-delta;if bearer.templar_shield_links[index].remaining<=0.0:bearer.templar_shield_links.remove_at(index)

func update_templar_runtime(delta:float)->void:
	update_templar_links(delta)
	for hero in heroes:
		if str(hero.get("class",""))!="Templar" or hero.get("templar_runtime",{}).is_empty():continue
		var trait_remaining:=TemplarSystem.named_shield_amount(hero,"templar_shield_overload");TemplarSystem.update(hero,delta,trait_remaining);hero.basic_attack_interval=float(hero.base_basic_action_interval)/(1.0+float(TemplarData.VALUES.blades_attack_speed) if TemplarSystem.has_talent(hero,"templar_l24_3") else 1.0)
		hero.ability_cds[3]=float(hero.templar_runtime.r1_recharge[0]) if str(hero.selected_heroic_id)=="templar_l15_r1" and not hero.templar_runtime.r1_recharge.is_empty() else hero.ability_cds[3]
		for index in range(hero.templar_runtime.blade_dashes.size()-1,-1,-1):if update_templar_dash(hero,hero.templar_runtime.blade_dashes[index],delta):hero.templar_runtime.blade_dashes.remove_at(index)
		for index in range(hero.templar_runtime.pending_w_strikes.size()-1,-1,-1):var strike:Dictionary=hero.templar_runtime.pending_w_strikes[index];strike.remaining=float(strike.remaining)-delta;if strike.remaining<=0.0:resolve_templar_w_strike(hero,strike);hero.templar_runtime.pending_w_strikes.remove_at(index)
		for index in range(hero.templar_runtime.beams.size()-1,-1,-1):if update_templar_beam(hero,hero.templar_runtime.beams[index],delta):hero.templar_runtime.beams.remove_at(index)
