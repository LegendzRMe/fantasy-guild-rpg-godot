extends "res://scripts/runtime/monk_runtime.gd"

func paladin_units()->Array:
	var result:Array=[]
	for unit in player_healable_units():
		if float(unit.get("hp",0.0))>0.0 and (not bool(unit.get("summoned_unit",false)) or bool(unit.get("ordinary_heal_eligible",false))):result.append(unit)
	return result

func paladin_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES["Paladin"].color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func paladin_arc_hit(hero:Dictionary,target:Dictionary)->bool:
	var offset:=Vector2(target.pos)-Vector2(hero.pos);if offset.length()>float(PaladinData.SPACE.hammer_reach):return false
	var facing:=Vector2(hero.get("facing_direction",Vector2.RIGHT));if facing==Vector2.ZERO:facing=Vector2.RIGHT
	return absf(facing.angle_to(offset.normalized()))<=float(PaladinData.SPACE.hammer_half_angle)

func resolve_paladin_charge(hero:Dictionary)->bool:
	var cast:=PaladinSystem.commit_charge(hero);if not bool(cast.get("cast",false)):return false
	if bool(cast.get("divine_purpose",false)) and PaladinSystem.has_talent(hero,"paladin_l30_3"):CombatSystem.apply_unstoppable(hero,float(PaladinData.VALUES.seraphim_duration));hero.paladin_runtime.seraphim_remaining=float(PaladinData.VALUES.seraphim_duration)
	var slot:=int(cast.slot);var maximum:=bool(cast.maximum_charge);var damaged:Array=[]
	if slot==0:
		var targets:=enemies.filter(func(enemy):return float(enemy.get("hp",0.0))>0.0 and Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=PaladinSystem.vindication_radius(hero))
		var values:=PaladinSystem.q_values(hero,maximum,targets.size())
		for enemy in targets:var hit:=deal_damage(hero,enemy,float(values.damage),"basic_ability","magical","Vindication",false,"paladin_q",[],false);if float(hit.resolved_damage)>0.0:damaged.append(str(enemy.combat_id))
		var self_heal:=deal_healing(hero,hero,float(values.healing),"basic_ability","Vindication","paladin_q",["healing"]);PaladinSystem.add(hero,"self_healing",float(self_heal.effective_amount))
		if PaladinSystem.has_talent(hero,"paladin_l18_3"):
			for ally in paladin_units():if ally!=hero and Vector2(ally.pos).distance_to(Vector2(hero.pos))<=PaladinSystem.vindication_radius(hero):var heal:=deal_healing(hero,ally,float(values.healing)*float(PaladinData.VALUES.merciful_fraction),"basic_ability","Merciful Vindication","paladin_q_merciful",["healing","secondary"]);PaladinSystem.add(hero,"party_healing",float(heal.effective_amount))
		if PaladinSystem.has_talent(hero,"paladin_l12_3"):
			var recipients:=paladin_units().filter(func(ally):return ally!=hero and Vector2(ally.pos).distance_to(Vector2(hero.pos))<=PaladinSystem.vindication_radius(hero))
			if not recipients.is_empty():
				for ally in recipients:ally.active_effects=CombatSystem.apply_named_effect(ally.get("active_effects",[]),{"id":"paladin_freedom:%s"%str(hero.combat_id),"movement_speed_multiplier":1.0+float(PaladinData.VALUES.freedom_speed),"remaining_duration":float(PaladinData.VALUES.freedom_duration)})
				if float(hero.paladin_runtime.hand_icd)<=0.0:for ally in recipients:StatusEffectSystem.remove_controls(ally,["slow","root"]);hero.paladin_runtime.hand_icd=float(PaladinData.VALUES.freedom_icd);PaladinSystem.add(hero,"cleanse_events")
	elif slot==1:
		var targets:=enemies.filter(func(enemy):return float(enemy.get("hp",0.0))>0.0 and paladin_arc_hit(hero,enemy));var values:=PaladinSystem.w_values(hero,maximum,targets.size())
		for enemy in targets:
			var hit:=deal_damage(hero,enemy,float(values.damage),"basic_ability","physical","Righteous Hammer",false,"paladin_w",[],false);if float(hit.resolved_damage)>0.0:damaged.append(str(enemy.combat_id))
			var destination:=Vector2(enemy.pos)+Vector2(hero.pos).direction_to(Vector2(enemy.pos))*float(values.knockback);var exception:="";var sacred:Dictionary=hero.paladin_runtime.sacred
			if not sacred.is_empty() and Vector2(enemy.pos).distance_to(Vector2(sacred.center))>float(PaladinData.SPACE.sacred_radius) and destination.distance_to(Vector2(sacred.center))<float(PaladinData.SPACE.sacred_radius):exception="paladin_hammer_inward"
			if bool(CombatSystem.default_control_profile(enemy).get("displacement",true)):enemy.pos=CombatGeometry.safe_endpoint(enemy.pos,destination,float(enemy.get("combat_radius",32.0)),combat_blockers,str(enemy.get("combat_id","")),exception)
			if float(values.stun)>0.0:CombatSystem.apply_control(enemy,"stun",float(values.stun)+(float(PaladinData.VALUES.repentance_stun_bonus) if PaladinSystem.has_talent(hero,"paladin_l21_2") else 0.0));PaladinSystem.add(hero,"w_stuns")
			if float(values.armor_reduction)>0.0:ArmorReductionSystem.apply(enemy,"paladin_verdict:%s"%str(hero.combat_id),float(values.armor_reduction),float(PaladinData.VALUES.verdict_duration));PaladinSystem.add(hero,"armor_applications")
		PaladinSystem.add(hero,"hammer_hits",targets.size())
		if PaladinSystem.has_talent(hero,"paladin_l12_1"):
			for ally in paladin_units():if paladin_arc_hit(hero,ally):HealingReceivedModifierSystem.apply(ally,"paladin_grace:%s"%str(hero.combat_id),float(PaladinData.VALUES.grace_healing_received),float(PaladinData.VALUES.grace_duration),str(hero.combat_id))
	elif slot==2:
		var from:=Vector2(hero.pos);var direction:=from.direction_to(Vector2(cast.aim_point));if direction==Vector2.ZERO:direction=Vector2(hero.get("facing_direction",Vector2.RIGHT))
		var values:=PaladinSystem.e_values(hero,float(cast.percentage),maximum,0);var landing:=CombatGeometry.safe_endpoint(from,from+direction*float(values.range),float(PaladinData.SPACE.combat_radius),combat_blockers,str(hero.combat_id));hero.pos=landing;hero.dest=landing
		var targets:=enemies.filter(func(enemy):return float(enemy.get("hp",0.0))>0.0 and Vector2(enemy.pos).distance_to(landing)<=float(PaladinData.SPACE.avenging_radius));values=PaladinSystem.e_values(hero,float(cast.percentage),maximum,targets.size())
		for enemy in targets:var hit:=deal_damage(hero,enemy,float(values.damage),"basic_ability","magical","Avenging Wrath",false,"paladin_e",[],false);CombatSystem.apply_control(enemy,"slow",float(values.slow_duration),float(values.slow));if PaladinSystem.has_talent(hero,"paladin_l21_1"):OutgoingDamageReductionSystem.apply(enemy,"paladin_aldor:%s"%str(hero.combat_id),float(PaladinData.VALUES.aldor_reduction),float(PaladinData.VALUES.aldor_duration));if float(hit.resolved_damage)>0.0:damaged.append(str(enemy.combat_id))
		if bool(values.holy_avenger):hero.ability_cds[2]=float(PaladinData.VALUES.holy_avenger_cooldown);PaladinSystem.add(hero,"holy_avenger_procs")
		if bool(cast.get("hallowed_started_inside",false)):PaladinSystem.relocate_sacred(hero,landing)
		PaladinSystem.add(hero,"avenging_hits",targets.size())
	var post:=PaladinSystem.after_basic_cast(hero,maximum,damaged)
	if bool(post.beacon):
		for ally in paladin_units():if Vector2(ally.pos).distance_to(Vector2(hero.pos))<=PaladinSystem.vindication_radius(hero):apply_unit_shield(hero,ally,float(ally.max_hp)*float(PaladinData.VALUES.beacon_shield),"Beacon of Hope","paladin_beacon:%s"%str(hero.combat_id),INF,float(PaladinData.VALUES.beacon_duration));PaladinSystem.add(hero,"shield_applications");PaladinSystem.add(hero,"shield_amount",float(ally.max_hp)*float(PaladinData.VALUES.beacon_shield))
		hero.paladin_runtime.beacon_icd=float(PaladinData.VALUES.beacon_icd)
	if bool(post.dauntless):
		for ally in paladin_units():if Vector2(ally.pos).distance_to(Vector2(hero.pos))<=PaladinSystem.vindication_radius(hero):ally.temporary_armor_sources=ally.get("temporary_armor_sources",[]).filter(func(source):return str(source.get("id",""))!="paladin_dauntless:%s"%str(hero.combat_id));ally.temporary_armor_sources.append({"id":"paladin_dauntless:%s"%str(hero.combat_id),"armor":PaladinData.scaled(float(PaladinData.VALUES.dauntless_armor),int(hero.level)),"remaining":float(PaladinData.VALUES.dauntless_duration)});PaladinSystem.add(hero,"armor_applications")
	paladin_visual(["paladin_q","paladin_w","paladin_e"][slot],hero.pos,Vector2(cast.aim_point),.45,{"maximum":maximum});return true

func cast_paladin_ability(slot:int,point:Vector2)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Paladin" or hero.get("paladin_runtime",{}).is_empty():return false
	if slot in [0,1,2]:
		if bool(hero.paladin_runtime.charge.active):hero.paladin_runtime.charge.aim=point;return resolve_paladin_charge(hero)
		var started:=PaladinSystem.start_charge(hero,slot,point)
		if started:
			hero.paladin_runtime.charge["hallowed_started_inside"]=slot==2 and not hero.paladin_runtime.sacred.is_empty() and Vector2(hero.pos).distance_to(Vector2(hero.paladin_runtime.sacred.center))<=float(PaladinData.SPACE.sacred_radius)
		return started
	if slot==3:return PaladinSystem.start_ardent(hero) if str(hero.selected_heroic_id)=="paladin_l15_r1" else PaladinSystem.start_sacred(hero,hero.pos)
	if slot==4:
		var activated:=PaladinSystem.activate_divine_purpose(hero)
		if activated and PaladinSystem.has_talent(hero,"paladin_l12_2"):
			var candidates:=paladin_units().filter(func(ally):return ally!=hero and Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(PaladinData.SPACE.support_radius));candidates.sort_custom(func(a,b):var ar:=float(a.hp)/maxf(1.0,float(a.max_hp));var br:=float(b.hp)/maxf(1.0,float(b.max_hp));return str(a.combat_id)<str(b.combat_id) if is_equal_approx(ar,br) else ar<br)
			if not candidates.is_empty():var gifted:=deal_healing(hero,candidates[0],PaladinData.scaled(float(PaladinData.VALUES.gift_heal),int(hero.level)),"trait","Gift of the Naaru","paladin_gift",["healing"]);PaladinSystem.add(hero,"party_healing",float(gifted.effective_amount))
		return activated
	return false

func resolve_paladin_basic_attack(hero:Dictionary,target:Dictionary,result:Dictionary)->void:
	if float(result.get("resolved_damage",0.0))<=0.0:return
	if bool(hero.paladin_runtime.maraad_primed):hero.paladin_runtime.maraad_primed=false;var healed:=deal_healing(hero,hero,PaladinData.scaled(float(PaladinData.VALUES.maraad_heal),int(hero.level)),"trait","Maraad's Insight","paladin_maraad",["healing"]);PaladinSystem.add(hero,"self_healing",float(healed.effective_amount))
	if bool(hero.paladin_runtime.holy_wrath_primed):
		hero.paladin_runtime.holy_wrath_primed=false
		for enemy in enemies:if enemy!=target and float(enemy.get("hp",0.0))>0.0 and Vector2(enemy.pos).distance_to(Vector2(target.pos))<=float(PaladinData.SPACE.holy_wrath_radius):var splash:=deal_damage(hero,enemy,float(result.raw_amount)*float(PaladinData.VALUES.holy_wrath_splash),"basic_attack","magical","Holy Wrath",false,"paladin_holy_wrath",[],false);PaladinSystem.add(hero,"holy_wrath_damage",float(splash.resolved_damage))

func update_paladin_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Paladin" or hero.get("paladin_runtime",{}).is_empty():continue
		PaladinSystem.advance(hero,delta);var rt:Dictionary=hero.paladin_runtime
		if bool(rt.charge.active) and str(rt.charge.input_mode)!="facing":ChargedCastSystem.update(rt.charge,0.0,get_global_mouse_position())
		for control in ["stun","silence","fear"]:if StatusEffectSystem.has_control(hero,control):PaladinSystem.external_interrupt(hero,control)
		combat_blockers=combat_blockers.filter(func(blocker):return str(blocker.get("combat_id",""))!="paladin_sacred:%s"%str(hero.combat_id))
		if not rt.sacred.is_empty():
			combat_blockers.append(CombatGeometry.create_ring_blocker("paladin_sacred:%s"%str(hero.combat_id),Vector2(rt.sacred.center),float(PaladinData.SPACE.sacred_radius),float(PaladinData.SPACE.sacred_wall_thickness),{"owner_combat_id":str(hero.combat_id),"crossing_exception":"paladin_hammer_inward","remaining_duration":float(rt.sacred.remaining)}));rt.sacred_tick=float(rt.sacred_tick)-delta
			while float(rt.sacred_tick)<=0.0:rt.sacred_tick=float(rt.sacred_tick)+1.0;for enemy in enemies:if float(enemy.get("hp",0.0))>0.0 and Vector2(enemy.pos).distance_to(Vector2(rt.sacred.center))<=float(PaladinData.SPACE.sacred_radius):var tick:=deal_damage(hero,enemy,PaladinData.scaled(float(PaladinData.VALUES.sacred_damage),int(hero.level)),"heroic","magical","Sacred Ground",false,"paladin_sacred",[],false);PaladinSystem.add(hero,"sacred_ticks");PaladinSystem.add(hero,"sacred_damage",float(tick.resolved_damage))
