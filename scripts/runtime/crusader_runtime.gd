extends "res://scripts/runtime/paladin_runtime.gd"

func crusader_targets()->Array:return enemies.filter(func(enemy):return float(enemy.get("hp",0.0))>0.0 and TargetCategorySystem.qualifies_immediate(enemy))
func crusader_allies()->Array:return player_healable_units().filter(func(ally):return float(ally.get("hp",0.0))>0.0 and (not bool(ally.get("summoned_unit",false)) or bool(ally.get("ordinary_heal_eligible",false))))
func crusader_facing(hero:Dictionary,point:Vector2)->Vector2:
	var facing:=Vector2(hero.pos).direction_to(point);if facing==Vector2.ZERO:facing=Vector2(hero.get("facing_direction",Vector2.RIGHT));if facing==Vector2.ZERO:facing=Vector2.RIGHT
	return facing.normalized()
func crusader_cone_hit(hero:Dictionary,target:Dictionary,reach:float,half_angle:float)->bool:
	var offset:=Vector2(target.pos)-Vector2(hero.pos);return offset.length()<=reach and offset.length()>0.0 and absf(crusader_facing(hero,Vector2(hero.pos)+Vector2(hero.get("facing_direction",Vector2.RIGHT))).angle_to(offset.normalized()))<=half_angle
func crusader_visual(kind:String,from:Vector2,to:Vector2,duration:float=.45,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Crusader.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)
func crusader_named_shield(hero:Dictionary,source_id:String)->Dictionary:
	for source in hero.get("shield_sources",[]):if str(source.get("source_id",""))==source_id:return source
	return {}
func crusader_remove_named_shield(hero:Dictionary,source_id:String)->void:
	for index in range(hero.get("shield_sources",[]).size()-1,-1,-1):
		if str(hero.shield_sources[index].get("source_id",""))==source_id:hero.shield=maxf(0.0,float(hero.shield)-float(hero.shield_sources[index].amount));hero.shield_sources.remove_at(index)
func crusader_restore_iron(hero:Dictionary,contacts:int)->float:
	var restored:=CrusaderSystem.restore_iron_skin(hero,contacts);if restored<=0.0:return 0.0
	var source_id:="crusader_iron:%s"%str(hero.combat_id)
	for source in hero.get("shield_sources",[]):if str(source.get("source_id",""))==source_id:source.amount=float(source.amount)+restored;hero.shield=float(hero.shield)+restored;return restored
	return 0.0
func crusader_sync_iron(hero:Dictionary)->void:
	var source_id:="crusader_iron:%s"%str(hero.combat_id);var source:=crusader_named_shield(hero,source_id);var active:=CrusaderSystem.sync_iron_skin(hero,float(source.get("amount",0.0)),float(source.get("remaining_duration",0.0)))
	if active:StatusEffectSystem.apply_source_unstoppable(hero,source_id,maxf(.1,float(source.get("remaining_duration",0.0))))
	else:StatusEffectSystem.remove_source_unstoppable(hero,source_id)
func crusader_extend_iron_source(hero:Dictionary)->void:
	if not bool(hero.crusader_runtime.iron_skin.active):return
	var source_id:="crusader_iron:%s"%str(hero.combat_id)
	for source in hero.get("shield_sources",[]):if str(source.get("source_id",""))==source_id:source.remaining_duration=float(source.get("remaining_duration",0.0))+float(CrusaderData.VALUES.steed_extension);hero.crusader_runtime.iron_skin.remaining=float(source.remaining_duration);return
func crusader_apply_slow(hero:Dictionary,target:Dictionary,amount:float,duration:float,decays:bool)->Dictionary:
	var result:=StatusEffectSystem.apply_source_control(target,"crusader_punish:%s"%str(hero.combat_id),"slow",duration,amount)
	if bool(result.get("applied",false)):
		for effect in target.active_effects:if str(effect.get("id",""))=="control_slow:crusader_punish:%s"%str(hero.combat_id):effect["decays"]=decays;effect["initial_duration"]=float(result.duration)
	return result
func crusader_apply_basic_restoration(hero:Dictionary,contacts:int)->void:crusader_restore_iron(hero,contacts)

func cast_crusader_q(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[0])>0.0:return false
	hero.facing_direction=crusader_facing(hero,point);var targets:=crusader_targets().filter(func(enemy):return crusader_cone_hit(hero,enemy,float(CrusaderData.SPACE.punish_radius),float(CrusaderData.SPACE.punish_half_angle)));var plan:=CrusaderSystem.q_plan(hero,targets.size());hero.ability_cds[0]=float(CrusaderData.VALUES.q_cooldown);var successful:=0
	for enemy in targets:
		var hit:=deal_damage(hero,enemy,float(plan.damage),"basic_ability","physical","Punish",false,"crusader_q",[],true);if float(hit.resolved_damage)>0.0:successful+=1;CrusaderSystem.mark_sins(hero,str(enemy.combat_id));if CrusaderSystem.has_talent(hero,"crusader_l18_1"):HealingReceivedModifierSystem.apply(enemy,"crusader_sins:%s"%str(hero.combat_id),-float(CrusaderData.VALUES.sins_reduction),float(CrusaderData.VALUES.sins_duration),str(hero.combat_id))
		var slowed:=crusader_apply_slow(hero,enemy,float(plan.slow),float(plan.slow_duration),bool(plan.decays));if bool(slowed.applied):CrusaderSystem.add(hero,"punish_slows")
	crusader_apply_basic_restoration(hero,successful);crusader_visual("crusader_q",hero.pos,hero.pos+hero.facing_direction*float(CrusaderData.SPACE.punish_radius),.4,{"contacts":targets.size()});return true

func resolve_crusader_condemn(hero:Dictionary)->void:
	var targets:=crusader_targets().filter(func(enemy):return Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=float(CrusaderData.SPACE.condemn_radius));var plan:=CrusaderSystem.w_plan(hero,targets.size());var ids:Array=[];var successful:=0
	for enemy in targets:
		var hit:=deal_damage(hero,enemy,float(plan.damage),"basic_ability","magical","Condemn",false,"crusader_w",[],false);if float(hit.resolved_damage)>0.0:successful+=1;ids.append(str(enemy.combat_id))
		var displacement:=CombatSystem.apply_control(enemy,"displacement",.05)
		if bool(displacement.applied):var direction:=Vector2(enemy.pos).direction_to(Vector2(hero.pos));var destination:=Vector2(hero.pos)-direction*float(CrusaderData.SPACE.condemn_pull_radius);enemy.pos=CombatGeometry.safe_endpoint(enemy.pos,destination,float(enemy.get("combat_radius",28.0)),combat_blockers,str(enemy.combat_id));CrusaderSystem.add(hero,"condemn_pulls")
		else:CrusaderSystem.add(hero,"resisted_displacement")
		var stun:=CombatSystem.apply_control(enemy,"stun",float(CrusaderData.VALUES.w_stun));if bool(stun.applied):CrusaderSystem.add(hero,"condemn_stuns")
	CrusaderSystem.mark_condemn(hero,ids)
	if float(plan.reduction)>0.0:IncomingDamageReductionSystem.apply(hero,"crusader_shrinking:%s"%str(hero.combat_id),float(plan.reduction),float(CrusaderData.VALUES.shrinking_duration))
	if CrusaderSystem.has_talent(hero,"crusader_l30_2") and float(hero.crusader_runtime.light_icd)<=0.0:
		for ally in crusader_allies():if Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(CrusaderData.SPACE.condemn_radius):var shield:=float(ally.max_hp)*float(CrusaderData.VALUES.light_fraction);apply_unit_shield(hero,ally,shield,"Blinded by the Light","crusader_light:%s"%str(hero.combat_id),INF,float(CrusaderData.VALUES.light_duration));CrusaderSystem.add(hero,"light_shields",shield)
		hero.crusader_runtime.light_icd=float(CrusaderData.VALUES.light_icd)
	crusader_apply_basic_restoration(hero,successful);crusader_visual("crusader_w",hero.pos,hero.pos,.55,{"contacts":targets.size()})

func cast_crusader_e(hero:Dictionary,point:Vector2)->bool:
	if not CrusaderSystem.spend_glare(hero):return false
	hero.facing_direction=crusader_facing(hero,point);if CrusaderSystem.has_talent(hero,"crusader_l18_3"):crusader_extend_iron_source(hero)
	var targets:=crusader_targets().filter(func(enemy):return crusader_cone_hit(hero,enemy,float(CrusaderData.SPACE.glare_range),float(CrusaderData.SPACE.glare_half_angle)));var blinded:Array=[];var condemned_hits:=0
	for enemy in targets:
		if CrusaderSystem.is_condemned(hero,str(enemy.combat_id)):condemned_hits+=1
		var blind:=CombatSystem.apply_blind(enemy,float(CrusaderData.VALUES.e_blind));if bool(blind.applied):blinded.append(str(enemy.combat_id));CrusaderSystem.add(hero,"glare_blinds")
		else:CrusaderSystem.add(hero,"blind_immune_contacts")
	CrusaderSystem.set_authority(hero,blinded);var plan:=CrusaderSystem.e_plan(hero,targets.size(),condemned_hits);var successful:=0
	for enemy in targets:
		var hit:=deal_damage(hero,enemy,float(plan.damage),"basic_ability","magical","Shield Glare",false,"crusader_e",[],false);if float(hit.resolved_damage)>0.0:successful+=1
	crusader_apply_basic_restoration(hero,successful);hero.ability_cds[2]=CrusaderSystem.glare_ui_cooldown(hero);crusader_visual("crusader_e",hero.pos,hero.pos+hero.facing_direction*float(CrusaderData.SPACE.glare_range),.45,{"contacts":targets.size()});return true

func cast_crusader_d(hero:Dictionary)->bool:
	var plan:=CrusaderSystem.iron_skin_plan(hero);if plan.is_empty():return false
	var source_id:="crusader_iron:%s"%str(hero.combat_id);crusader_remove_named_shield(hero,source_id);apply_unit_shield(hero,hero,float(plan.maximum),"Iron Skin",source_id,float(plan.maximum),float(plan.duration));StatusEffectSystem.apply_source_unstoppable(hero,source_id,float(plan.duration));crusader_visual("crusader_iron",hero.pos,hero.pos,float(plan.duration),{"shield":float(plan.maximum)});return true

func crusader_blessed_targets(hero:Dictionary,point:Vector2)->Array:
	var facing:=crusader_facing(hero,point);var first_candidates:=crusader_targets().filter(func(enemy):var offset:=Vector2(enemy.pos)-Vector2(hero.pos);return offset.length()<=float(CrusaderData.SPACE.blessed_range) and facing.dot(offset.normalized())>=.9659)
	first_candidates.sort_custom(func(a,b):var ad:=Vector2(a.pos).distance_to(Vector2(hero.pos));var bd:=Vector2(b.pos).distance_to(Vector2(hero.pos));return str(a.combat_id)<str(b.combat_id) if is_equal_approx(ad,bd) else ad<bd)
	if first_candidates.is_empty():return []
	var result:Array=[first_candidates[0]];var limit:=int(CrusaderData.VALUES.radiating_targets) if CrusaderSystem.has_talent(hero,"crusader_l27_r2") else 3
	while result.size()<limit:
		var previous:Dictionary=result[-1]
		var options:Array=crusader_targets().filter(func(enemy):return enemy not in result and Vector2(enemy.pos).distance_to(Vector2(previous.pos))<=float(CrusaderData.SPACE.blessed_bounce))
		options.sort_custom(func(a,b):var ad:=Vector2(a.pos).distance_to(Vector2(previous.pos));var bd:=Vector2(b.pos).distance_to(Vector2(previous.pos));return str(a.combat_id)<str(b.combat_id) if is_equal_approx(ad,bd) else ad<bd)
		if options.is_empty():break
		result.append(options[0])
	return result
func cast_crusader_heroic(hero:Dictionary,point:Vector2)->bool:
	if str(hero.selected_heroic_id)=="crusader_l15_r1":
		if not CrusaderSystem.begin_falling(hero):return false
		CombatRulesV1.cancel_basic_windup(hero);CombatRulesV1.issue_move(hero,point.clamp(Vector2(55,70),Vector2(1225,620)));hero.active_effects=CombatSystem.apply_named_effect(hero.active_effects,{"id":"invulnerable","source_id":"crusader_falling:%s"%str(hero.combat_id),"remaining_duration":float(CrusaderData.VALUES.falling_duration)});crusader_visual("crusader_falling",hero.pos,point,float(CrusaderData.VALUES.falling_duration));return true
	if float(hero.ability_cds[3])>0.0:return false
	var targets:=crusader_blessed_targets(hero,point);if targets.is_empty():return false
	hero.ability_cds[3]=float(CrusaderData.VALUES.blessed_cooldown);var radiating:=CrusaderSystem.has_talent(hero,"crusader_l27_r2")
	for index in targets.size():var enemy:Dictionary=targets[index];var amount:=float(CrusaderData.VALUES.blessed_first if index==0 else CrusaderData.VALUES.blessed_secondary);deal_damage(hero,enemy,CrusaderData.scaled(amount,int(hero.level)),"heroic","magical","Blessed Shield",false,"crusader_blessed",[],true);var stun:=CombatSystem.apply_control(enemy,"stun",float(CrusaderData.VALUES.radiating_stun if radiating else CrusaderData.VALUES.blessed_first_stun if index==0 else CrusaderData.VALUES.blessed_secondary_stun));if bool(stun.applied):CrusaderSystem.add(hero,"blessed_stuns");if radiating:CrusaderSystem.add(hero,"radiating_targets")
	crusader_visual("crusader_blessed",hero.pos,Vector2(targets[-1].pos),.65,{"targets":targets.size()});return true

func cast_crusader_ability(slot:int,point:Vector2)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Crusader" or hero.get("crusader_runtime",{}).is_empty():return false
	if not hero.crusader_runtime.falling.is_empty():return false
	match slot:
		0:return cast_crusader_q(hero,point)
		1:return CrusaderSystem.begin_condemn(hero)
		2:return cast_crusader_e(hero,point)
		3:return cast_crusader_heroic(hero,point)
		4:return cast_crusader_d(hero)
	return false

func resolve_crusader_basic_attack(hero:Dictionary,target:Dictionary,result:Dictionary)->void:
	var note:=CrusaderSystem.note_basic_attack(hero,str(target.combat_id),float(result.get("resolved_damage",0.0))>0.0);if note.is_empty():return
	if float(note.get("fortress_armor",0.0))>0.0:hero.temporary_armor_sources=hero.get("temporary_armor_sources",[]).filter(func(source):return str(source.get("id",""))!="crusader_fortress:%s"%str(hero.combat_id));hero.temporary_armor_sources.append({"id":"crusader_fortress:%s"%str(hero.combat_id),"armor":float(note.fortress_armor),"remaining":float(CrusaderData.VALUES.fortress_duration)})
	if bool(note.get("refresh_sins",false)):HealingReceivedModifierSystem.apply(target,"crusader_sins:%s"%str(hero.combat_id),-float(CrusaderData.VALUES.sins_reduction),float(CrusaderData.VALUES.sins_duration),str(hero.combat_id))

func crusader_heavens_barrage(hero:Dictionary)->void:
	var foes:=crusader_targets().filter(func(enemy):return Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=float(CrusaderData.SPACE.falling_ally_radius));foes.sort_custom(func(a,b):return str(a.combat_id)<str(b.combat_id));var allies:=crusader_allies().filter(func(ally):return Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(CrusaderData.SPACE.falling_ally_radius));allies.sort_custom(func(a,b):return str(a.combat_id)<str(b.combat_id))
	for enemy in foes.slice(0,int(CrusaderData.VALUES.heavens_enemy_cap)):var hit:=deal_damage(hero,enemy,CrusaderData.scaled(float(CrusaderData.VALUES.heavens_damage),int(hero.level)),"heroic","magical","Heaven's Fury",false,"crusader_heavens",[],false);if float(hit.resolved_damage)>0.0:var reduction:=minf(float(hero.ability_cds[3]),float(CrusaderData.VALUES.heavens_cdr));hero.ability_cds[3]-=reduction;CrusaderSystem.add(hero,"heavens_cdr",reduction)
	for ally in allies.slice(0,int(CrusaderData.VALUES.heavens_ally_cap)):deal_healing(hero,ally,CrusaderData.scaled(float(CrusaderData.VALUES.heavens_heal),int(hero.level)),"heroic","Heaven's Fury","crusader_heavens",["healing"])

func update_crusader_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Crusader" or hero.get("crusader_runtime",{}).is_empty():continue
		CrusaderSystem.advance(hero,delta);hero.ability_cds[2]=CrusaderSystem.glare_ui_cooldown(hero);var rt:Dictionary=hero.crusader_runtime
		if CrusaderSystem.take_condemn_resolution(hero):resolve_crusader_condemn(hero)
		if float(rt.laws.remaining)>0.0:rt.laws.remaining=maxf(0.0,float(rt.laws.remaining)-delta);rt.laws.tick=float(rt.laws.tick)-delta;while float(rt.laws.tick)<=0.0 and float(rt.laws.remaining)>=0.0:rt.laws.tick=float(rt.laws.tick)+1.0;var healed:=deal_healing(hero,hero,float(rt.laws.per_tick),"periodic","Laws of Hope","crusader_laws",["healing"]);CrusaderSystem.add(hero,"laws_healing",float(healed.effective_amount))
		if CrusaderSystem.has_talent(hero,"crusader_l21_2"):rt.holy_fury_tick=float(rt.holy_fury_tick)-delta;while float(rt.holy_fury_tick)<=0.0:rt.holy_fury_tick=float(rt.holy_fury_tick)+1.0;var aura:=CrusaderData.scaled(float(CrusaderData.VALUES.holy_fury_damage),int(hero.level))*(1.0+float(rt.holy_fury_stacks)*float(CrusaderData.VALUES.holy_fury_per_hit));for enemy in crusader_targets():if Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=float(CrusaderData.SPACE.holy_fury_radius):deal_damage(hero,enemy,aura,"periodic","magical","Holy Fury",false,"crusader_holy_fury",[],false)
		if not rt.falling.is_empty():
			hero.active_effects=CombatSystem.apply_named_effect(hero.active_effects,{"id":"invulnerable","source_id":"crusader_falling:%s"%str(hero.combat_id),"remaining_duration":.15});for ally in crusader_allies():if Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(CrusaderData.SPACE.falling_ally_radius):StatusEffectSystem.apply_source_unstoppable(ally,"crusader_falling:%s"%str(hero.combat_id),.2)
			if CrusaderSystem.has_talent(hero,"crusader_l27_r1"):while float(rt.falling.barrage)<=0.0 and int(rt.falling.barrages)<int(CrusaderData.VALUES.heavens_barrages):rt.falling.barrage=float(rt.falling.barrage)+float(CrusaderData.VALUES.heavens_interval);rt.falling.barrages=int(rt.falling.barrages)+1;crusader_heavens_barrage(hero)
			if bool(rt.falling.landing_ready):
				hero.active_effects=hero.active_effects.filter(func(effect):return not (str(effect.get("id",""))=="invulnerable" and str(effect.get("source_id",""))=="crusader_falling:%s"%str(hero.combat_id)))
				for ally in crusader_allies():StatusEffectSystem.remove_source_unstoppable(ally,"crusader_falling:%s"%str(hero.combat_id))
				for enemy in crusader_targets():
					if Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=float(CrusaderData.SPACE.falling_radius):
						deal_damage(hero,enemy,CrusaderData.scaled(float(CrusaderData.VALUES.falling_damage),int(hero.level)),"heroic","magical","Falling Sword",false,"crusader_falling",[],true)
						var control:=CombatSystem.apply_control(enemy,"stun",float(CrusaderData.VALUES.falling_stun));if bool(control.applied):CrusaderSystem.add(hero,"falling_controls")
				rt.falling={};crusader_visual("crusader_landing",hero.pos,hero.pos,.6)
		crusader_sync_iron(hero)
		if bool(rt.telemetry_enabled):
			var held:=0;var hero_index:=int(hero.get("battle_index",-1))
			for enemy in enemies:
				var table:Dictionary=enemy.get("threat",{});if table.is_empty():continue
				var highest:float=table.values().max();if is_equal_approx(float(table.get(hero_index,-INF)),highest):held+=1
			rt.telemetry.current_highest_threat_targets=held

func sync_crusader_runtime_states()->void:
	for hero in heroes:if str(hero.get("class",""))=="Crusader" and not hero.get("crusader_runtime",{}).is_empty():crusader_sync_iron(hero)
