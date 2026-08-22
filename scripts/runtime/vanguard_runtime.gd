extends "res://scripts/runtime/crusader_runtime.gd"

func vanguard_targets()->Array:return enemies.filter(func(enemy):return float(enemy.get("hp",0.0))>0.0 and TargetCategorySystem.qualifies_immediate(enemy))
func vanguard_allies()->Array:return player_healable_units().filter(func(ally):return float(ally.get("hp",0.0))>0.0 and (not bool(ally.get("summoned_unit",false)) or bool(ally.get("ordinary_heal_eligible",false))))
func vanguard_facing(hero:Dictionary,point:Vector2)->Vector2:
	var facing:=Vector2(hero.pos).direction_to(point);if facing==Vector2.ZERO:facing=Vector2(hero.get("facing_direction",Vector2.RIGHT));if facing==Vector2.ZERO:facing=Vector2.RIGHT
	return facing.normalized()
func vanguard_cone_hit(hero:Dictionary,target:Dictionary,reach:float,half_angle:float)->bool:
	var offset:=Vector2(target.pos)-Vector2(hero.pos);return offset.length()<=reach and offset.length()>0.0 and absf(Vector2(hero.get("facing_direction",Vector2.RIGHT)).angle_to(offset.normalized()))<=half_angle
func vanguard_visual(kind:String,from:Vector2,to:Vector2,duration:float=.45,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Vanguard.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)
func vanguard_safe_crossing_endpoint(from:Vector2,intended:Vector2,radius:float,mover_id:String)->Vector2:
	for step in range(20,-1,-1):
		var candidate:=from.lerp(intended,float(step)/20.0)
		if CombatGeometry.valid_position(candidate,radius,combat_blockers,mover_id):return candidate
	return from
func vanguard_apply_armor(target:Dictionary,owner:Dictionary,amount:float,duration:float)->void:
	var source_id:="vanguard_rockstar:%s"%str(owner.combat_id);var existing:Array=target.get("temporary_armor_sources",[]).filter(func(source):return str(source.get("id",""))==source_id)
	if existing.is_empty():target.temporary_armor_sources=target.get("temporary_armor_sources",[]);target.temporary_armor_sources.append({"id":source_id,"armor":amount,"remaining":duration})
	else:
		if amount>float(existing[0].armor):existing[0].armor=amount
		existing[0].remaining=maxf(float(existing[0].remaining),duration)
func vanguard_commit(hero:Dictionary,heroic:bool)->void:
	var plan:=VanguardSystem.commit_ability(hero,heroic);var recipients:Array=[hero]
	if bool(plan.party):recipients=vanguard_allies().filter(func(ally):return Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(VanguardData.SPACE.support_radius));if hero not in recipients:recipients.append(hero)
	for recipient in recipients:vanguard_apply_armor(recipient,hero,float(plan.armor),float(plan.duration))
	if bool(plan.block_party):
		var block_recipients:=vanguard_allies();if hero not in block_recipients:block_recipients.append(hero)
		for recipient in block_recipients:
			if Vector2(recipient.pos).distance_to(Vector2(hero.pos))<=float(VanguardData.SPACE.support_radius):VanguardSystem.add(hero,"block_grants",BlockChargeSystem.grant(recipient,1,int(VanguardData.VALUES.block_max)))

func vanguard_apply_stun(hero:Dictionary,target:Dictionary,source:String,duration:float,quest_ability:String,qualifies_quest:bool=true)->Dictionary:
	var result:=StatusEffectSystem.apply_source_control(target,"vanguard_%s:%s"%[source,str(hero.combat_id)],"stun",duration)
	if bool(result.applied):VanguardSystem.note_stun(hero,quest_ability,str(target.combat_id),qualifies_quest and TargetCategorySystem.qualifies_quest(target))
	else:VanguardSystem.add(hero,"resisted_control")
	return result
func vanguard_displace(hero:Dictionary,target:Dictionary,direction:Vector2,distance:float)->Dictionary:
	var control:=CombatSystem.apply_control(target,"displacement",.05)
	if not bool(control.applied):VanguardSystem.add(hero,"resisted_displacement");return {"moved":false,"collided":false}
	var intended:=Vector2(target.pos)+direction.normalized()*distance;var endpoint:=CombatGeometry.safe_endpoint(target.pos,intended,float(target.get("combat_radius",28.0)),combat_blockers,str(target.combat_id));var moved:=Vector2(endpoint)!=Vector2(target.pos);var collided:=Vector2(endpoint).distance_to(intended)>1.0;target.pos=endpoint
	if moved:VanguardSystem.add(hero,"w_displacements")
	return {"moved":moved,"collided":collided}

func cast_vanguard_q(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[0])>0.0:return false
	var during_mosh:bool=not hero.vanguard_runtime.mosh.is_empty()
	if during_mosh and not VanguardSystem.tour_bus_slide(hero):return false
	var from:=Vector2(hero.pos);var direction:=vanguard_facing(hero,point);hero.facing_direction=direction;var intended:=from+direction*minf(float(VanguardData.SPACE.q_range),from.distance_to(point));var cross:=VanguardSystem.has_talent(hero,"vanguard_l12_1");var endpoint:=vanguard_safe_crossing_endpoint(from,intended,float(hero.get("combat_radius",32.0)),str(hero.combat_id)) if cross else CombatGeometry.safe_endpoint(from,intended,float(hero.get("combat_radius",32.0)),combat_blockers,str(hero.combat_id));var targets:=vanguard_targets().filter(func(enemy):return CombatGeometry.segment_hits_circle(from,endpoint,Vector2(enemy.pos),float(VanguardData.SPACE.q_half_width)+float(enemy.get("combat_radius",24.0))))
	var plan:=VanguardSystem.q_plan(hero,targets.size());hero.ability_cds[0]=float(VanguardData.VALUES.q_cooldown);vanguard_commit(hero,false)
	for enemy in targets.slice(0,int(VanguardData.VALUES.contact_cap)):
		deal_damage(hero,enemy,float(plan.damage),"basic_ability","physical","Powerslide",false,"vanguard_q",[],true);var stun:=vanguard_apply_stun(hero,enemy,"q",float(plan.stun),"Q");VanguardSystem.mark_pinball(hero,str(enemy.combat_id))
		if bool(plan.push):
			var displacement:=vanguard_displace(hero,enemy,direction,float(VanguardData.SPACE.w_displacement))
			if bool(displacement.collided):deal_damage(hero,enemy,VanguardData.scaled(float(VanguardData.VALUES.wall_damage),int(hero.level)),"basic_ability","physical","Wall of Sound",false,"vanguard_wall",[],true);VanguardSystem.add(hero,"wall_collisions");VanguardSystem.add(hero,"wall_damage",VanguardData.scaled(float(VanguardData.VALUES.wall_damage),int(hero.level)));var wall:=vanguard_apply_stun(hero,enemy,"wall",float(VanguardData.VALUES.wall_stun),"Wall",false);if bool(wall.applied):for effect in enemy.active_effects:if str(effect.get("source_id",""))=="vanguard_q:%s"%str(hero.combat_id):effect.remaining_duration=float(effect.remaining_duration)+float(wall.duration)
		if VanguardSystem.has_talent(hero,"vanguard_l24_1"):
			var root_delay:=float(stun.get("duration",VanguardData.VALUES.q_stun)) if bool(stun.get("applied",false)) else float(VanguardData.VALUES.q_stun)
			for effect in enemy.get("active_effects",[]):if str(effect.get("source_id",""))=="vanguard_q:%s"%str(hero.combat_id):root_delay=float(effect.remaining_duration)
			hero.vanguard_runtime.delayed_roots.append({"target_id":str(enemy.combat_id),"remaining":root_delay})
	hero.pos=endpoint;hero.dest=endpoint;hero.move_destination=endpoint;VanguardSystem.finish_q(hero,targets.size());vanguard_visual("vanguard_q",from,endpoint,maxf(.12,from.distance_to(endpoint)/float(VanguardData.VALUES.q_speed)),{"contacts":targets.size()});return true

func resolve_vanguard_face_melt(hero:Dictionary,center:Vector2,amp:bool=false)->int:
	var radius:=float(VanguardData.SPACE.w_radius)*(float(VanguardData.VALUES.loud_multiplier) if VanguardSystem.has_talent(hero,"vanguard_l12_2") else 1.0);var targets:=vanguard_targets().filter(func(enemy):return Vector2(enemy.pos).distance_to(center)<=radius);var ids:Array=targets.map(func(enemy):return str(enemy.combat_id));var plan:=VanguardSystem.w_plan(hero,ids) if not amp else {"damage":0.0,"contacts":VanguardSystem.contact_count(targets.size()),"empowered":[],"displacement":float(VanguardData.SPACE.w_displacement)*(float(VanguardData.VALUES.loud_multiplier) if VanguardSystem.has_talent(hero,"vanguard_l12_2") else 1.0),"pull":VanguardSystem.has_talent(hero,"vanguard_l21_3")}
	for enemy in targets.slice(0,int(VanguardData.VALUES.contact_cap)):
		if not amp:var multiplier:=1.0+float(VanguardData.VALUES.pinball_bonus) if str(enemy.combat_id) in plan.empowered else 1.0;var hit:=deal_damage(hero,enemy,float(plan.damage)*multiplier,"basic_ability","magical","Face Melt",false,"vanguard_w",[],true);if multiplier>1.0:VanguardSystem.add(hero,"pinball_hits");VanguardSystem.add(hero,"w_contacts",0.0 if float(hit.resolved_damage)>0.0 else 0.0)
		var direction:=Vector2(enemy.pos).direction_to(center) if bool(plan.pull) else center.direction_to(Vector2(enemy.pos));vanguard_displace(hero,enemy,direction,float(plan.displacement))
		if VanguardSystem.has_talent(hero,"vanguard_l24_2"):var silence:=StatusEffectSystem.apply_source_control(enemy,"vanguard_dissonance:%s"%str(hero.combat_id),"silence",float(VanguardData.VALUES.dissonance_silence));if bool(silence.applied):VanguardSystem.add(hero,"silences")
	if VanguardSystem.has_talent(hero,"vanguard_l21_2"):
		var reduction:=float(VanguardData.VALUES.encore_heroic_fraction)*float(VanguardData.VALUES.mosh_cooldown if str(hero.selected_heroic_id)=="vanguard_l15_r1" else VanguardData.VALUES.lightning_cooldown)*float(VanguardSystem.contact_count(targets.size()));var actual:=minf(float(hero.ability_cds[3]),reduction);hero.ability_cds[3]-=actual;VanguardSystem.add(hero,"encore_heroic_cdr",actual);if amp:VanguardSystem.add(hero,"encore_amp_contacts",VanguardSystem.contact_count(targets.size()))
	return targets.size()
func cast_vanguard_w(hero:Dictionary)->bool:
	if float(hero.ability_cds[1])>0.0:return false
	hero.ability_cds[1]=float(VanguardData.VALUES.w_cooldown);vanguard_commit(hero,false);resolve_vanguard_face_melt(hero,hero.pos,false)
	if VanguardSystem.has_talent(hero,"vanguard_l21_2"):hero.vanguard_runtime.amps.append({"remaining":float(VanguardData.VALUES.encore_delay),"position":Vector2(hero.pos)})
	vanguard_visual("vanguard_w",hero.pos,hero.pos,.5);return true

func cast_vanguard_e(hero:Dictionary,point:Vector2)->bool:
	var direction:=vanguard_facing(hero,point);hero.facing_direction=direction;var candidates:=vanguard_targets().filter(func(enemy):return Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=float(VanguardData.SPACE.e_range));candidates.sort_custom(func(a,b):return Vector2(a.pos).distance_to(point)<Vector2(b.pos).distance_to(point))
	if candidates.is_empty():return false
	if not VanguardSystem.spend_overpower(hero):return false
	var target:Dictionary=candidates[0];vanguard_commit(hero,false);var displacement:=CombatSystem.apply_control(target,"displacement",.05)
	if bool(displacement.applied):var intended:=Vector2(hero.pos)-direction*(float(VanguardData.SPACE.e_behind_offset)+float(target.get("combat_radius",24.0)));target.pos=CombatGeometry.safe_endpoint(target.pos,intended,float(target.get("combat_radius",24.0)),combat_blockers,str(target.combat_id));VanguardSystem.add(hero,"e_flips")
	else:VanguardSystem.add(hero,"resisted_displacement")
	var plan:=VanguardSystem.e_plan(hero);deal_damage(hero,target,float(plan.damage),"basic_ability","physical","Overpower",false,"vanguard_e",[],true);vanguard_apply_stun(hero,target,"e",float(plan.stun),"E");hero.ability_cds[2]=VanguardSystem.e_ui_cooldown(hero);vanguard_visual("vanguard_e",hero.pos,target.pos,.4);return true

func cast_vanguard_heroic(hero:Dictionary)->bool:
	if not VanguardSystem.begin_heroic(hero,str(hero.selected_heroic_id)):return false
	vanguard_commit(hero,true);CombatRulesV1.cancel_basic_windup(hero);hero.command_state=CombatRulesV1.CommandState.IDLE;hero.dest=hero.pos;hero.move_destination=hero.pos;vanguard_visual("vanguard_heroic_windup",hero.pos,hero.pos,float(hero.vanguard_runtime.heroic_windup.remaining));return true
func cast_vanguard_ability(slot:int,point:Vector2)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Vanguard" or hero.get("vanguard_runtime",{}).is_empty():return false
	var active:bool=not hero.vanguard_runtime.heroic_windup.is_empty() or not hero.vanguard_runtime.lightning.is_empty() or not hero.vanguard_runtime.mosh.is_empty()
	if active and not (slot==0 and not hero.vanguard_runtime.mosh.is_empty() and VanguardSystem.has_talent(hero,"vanguard_l27_r1")):return false
	match slot:
		0:return cast_vanguard_q(hero,point)
		1:return cast_vanguard_w(hero)
		2:return cast_vanguard_e(hero,point)
		3:return cast_vanguard_heroic(hero)
	return false

func resolve_vanguard_basic_attack(hero:Dictionary,target:Dictionary,result:Dictionary)->void:VanguardSystem.note_basic_attack(hero,target,float(result.get("resolved_damage",0.0))>0.0)
func vanguard_lightning_tick(hero:Dictionary)->void:
	var rt:Dictionary=hero.vanguard_runtime;var per_hit:=float(VanguardData.VALUES.hellstorm_slow if VanguardSystem.has_talent(hero,"vanguard_l27_r2") and not bool(rt.lightning.get("emergency",false)) else VanguardData.VALUES.lightning_slow);var maximum:=float(VanguardData.VALUES.hellstorm_slow_max if VanguardSystem.has_talent(hero,"vanguard_l27_r2") and not bool(rt.lightning.get("emergency",false)) else VanguardData.VALUES.lightning_slow_max);rt.lightning["slows"]=rt.lightning.get("slows",{})
	var targets:=vanguard_targets().filter(func(enemy):return vanguard_cone_hit(hero,enemy,float(VanguardData.SPACE.lightning_range),float(VanguardData.SPACE.lightning_half_angle)));targets.sort_custom(func(a,b):return str(a.combat_id)<str(b.combat_id))
	for enemy in targets.slice(0,int(VanguardData.VALUES.contact_cap)):
		var hit:=deal_damage(hero,enemy,VanguardData.scaled(float(VanguardData.VALUES.lightning_damage),int(hero.level)),"heroic","magical","Lightning Breath",false,"vanguard_lightning",[],false);if float(hit.resolved_damage)<=0.0:continue
		var id:=str(enemy.combat_id);var slow:=minf(maximum,float(rt.lightning.slows.get(id,0.0))+per_hit);rt.lightning.slows[id]=slow;var applied:=StatusEffectSystem.apply_source_control(enemy,"vanguard_lightning:%s"%str(hero.combat_id),"slow",float(VanguardData.VALUES.lightning_slow_duration),slow);if bool(applied.applied):VanguardSystem.add(hero,"lightning_hits");VanguardSystem.add(hero,"lightning_slow_points",per_hit*100.0);if VanguardSystem.has_talent(hero,"vanguard_l30_1"):hero.vanguard_runtime.encore_marks[id]=float(applied.duration)
func vanguard_mosh_tick(hero:Dictionary)->void:
	hero.vanguard_runtime.mosh["affected"]=hero.vanguard_runtime.mosh.get("affected",{})
	var targets:=vanguard_targets().filter(func(enemy):return Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=float(VanguardData.SPACE.mosh_radius));targets.sort_custom(func(a,b):return str(a.combat_id)<str(b.combat_id))
	for enemy in targets.slice(0,int(VanguardData.VALUES.contact_cap)):
		var applied:=StatusEffectSystem.apply_source_control(enemy,"vanguard_mosh:%s"%str(hero.combat_id),"stun",.2)
		if bool(applied.applied):var id:=str(enemy.combat_id);if not hero.vanguard_runtime.mosh.affected.has(id):VanguardSystem.note_stun(hero,"Mosh",id,TargetCategorySystem.qualifies_quest(enemy));VanguardSystem.add(hero,"mosh_stuns");hero.vanguard_runtime.mosh.affected[id]=true

func resolve_vanguard_event(hero:Dictionary,event:Dictionary)->void:
	match str(event.kind):
		"heroic_activate":
			var active:=VanguardSystem.activate_heroic(hero);if active.is_empty():return
			if str(active.id)=="vanguard_l15_r2":StatusEffectSystem.apply_source_unstoppable(hero,"vanguard_lightning:%s"%str(hero.combat_id),float(hero.vanguard_runtime.lightning.duration));vanguard_visual("vanguard_lightning",hero.pos,hero.pos+Vector2(hero.facing_direction)*float(VanguardData.SPACE.lightning_range),float(hero.vanguard_runtime.lightning.duration))
			else:vanguard_visual("vanguard_mosh",hero.pos,hero.pos,float(hero.vanguard_runtime.mosh.duration))
		"lightning_tick":vanguard_lightning_tick(hero)
		"root":var target=unit_by_combat_id(str(event.target_id));if target!=null:var applied:=StatusEffectSystem.apply_source_control(target,"vanguard_show:%s"%str(hero.combat_id),"root",float(VanguardData.VALUES.show_root));if bool(applied.applied):VanguardSystem.add(hero,"roots")
		"amp":resolve_vanguard_face_melt(hero,Vector2(event.position),true);vanguard_visual("vanguard_amp",event.position,event.position,.4)
		"echo":VanguardSystem.add(hero,"echo_pulses");for enemy in vanguard_targets():if Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=float(VanguardData.SPACE.echo_radius):var hit:=deal_damage(hero,enemy,VanguardData.scaled(float(VanguardData.VALUES.echo_damage),int(hero.level)),"talent","magical","Echo Pedal",false,"vanguard_echo",[],false);if float(hit.resolved_damage)>0.0:VanguardSystem.add(hero,"echo_hits")
		"prog_heal":for ally in vanguard_allies():if ally!=hero and Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(VanguardData.SPACE.support_radius):var healed:=deal_healing(hero,ally,VanguardData.scaled(float(VanguardData.VALUES.prog_heal),int(hero.level)),"periodic","Prog Rock","vanguard_prog",["healing"]);VanguardSystem.add(hero,"prog_healing",float(healed.effective_amount))
		"encore_taunt":var target=unit_by_combat_id(str(event.target_id));if target!=null:ForcedTargetSystem.apply(target,int(hero.battle_index),"vanguard_encore:%s"%str(hero.combat_id),float(VanguardData.VALUES.encore_taunt),str(hero.combat_id));VanguardSystem.add(hero,"encore_taunts")
		"mosh_end":if VanguardSystem.has_talent(hero,"vanguard_l30_1") and str(hero.selected_heroic_id)=="vanguard_l15_r1":for target_id in event.targets:hero.vanguard_runtime.encore_marks[str(target_id)]=.2
		"death_metal_end":
			StatusEffectSystem.remove_source_unstoppable(hero,"vanguard_lightning:%s"%str(hero.combat_id));var survives:=float(hero.hp)>=float(hero.max_hp)*float(VanguardData.VALUES.death_metal_survival);hero.vanguard_runtime.death_metal={};hero.vanguard_runtime.mosh={};hero.vanguard_runtime.lightning={};if survives:VanguardSystem.add(hero,"death_metal_survives")
			else:hero.hp=0.0;hero["was_defeated"]=true;VanguardSystem.add(hero,"death_metal_defeats")

func update_vanguard_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Vanguard" or hero.get("vanguard_runtime",{}).is_empty():continue
		for event in VanguardSystem.advance(hero,delta):resolve_vanguard_event(hero,event)
		hero.ability_cds[2]=VanguardSystem.e_ui_cooldown(hero)
		if not hero.vanguard_runtime.mosh.is_empty():vanguard_mosh_tick(hero)
		if not hero.vanguard_runtime.lightning.is_empty():StatusEffectSystem.apply_source_unstoppable(hero,"vanguard_lightning:%s"%str(hero.combat_id),.2)
		else:StatusEffectSystem.remove_source_unstoppable(hero,"vanguard_lightning:%s"%str(hero.combat_id))
