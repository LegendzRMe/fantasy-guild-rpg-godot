extends "res://scripts/runtime/beastmaster_runtime.gd"

func monk_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES["Monk"].color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func monk_allies()->Array:
	var result:Array=[]
	for monk in heroes:
		if str(monk.get("class",""))=="Monk" and not monk.get("monk_runtime",{}).is_empty() and not monk.monk_runtime.ally.is_empty() and float(monk.monk_runtime.ally.get("hp",0.0))>0.0:result.append(monk.monk_runtime.ally)
	return result

func monk_dash_candidates(hero:Dictionary)->Array:
	var result:Array=[]
	for ally in heroes:if ally!=hero and MonkSystem.valid_ally_anchor(hero,ally):result.append(ally)
	for companion in player_healable_units():if companion not in result and MonkSystem.valid_ally_anchor(hero,companion):result.append(companion)
	if not hero.monk_runtime.ally.is_empty() and MonkSystem.valid_ally_anchor(hero,hero.monk_runtime.ally):result.append(hero.monk_runtime.ally)
	for enemy in enemies:if TargetCategorySystem.qualifies_immediate(enemy) and MonkSystem.valid_enemy_anchor(hero,enemy):result.append(enemy)
	return result

func monk_target_near_point(hero:Dictionary,point:Vector2):
	var candidates:=monk_dash_candidates(hero).filter(func(target):return Vector2(hero.pos).distance_to(Vector2(target.pos))<=float(MonkData.SPACE.dash_range) and Vector2(target.pos).distance_to(point)<=65.0)
	candidates.sort_custom(func(a,b):var ad:=Vector2(a.pos).distance_squared_to(point);var bd:=Vector2(b.pos).distance_squared_to(point);return str(a.combat_id)<str(b.combat_id) if is_equal_approx(ad,bd) else ad<bd)
	return candidates[0] if not candidates.is_empty() else null

func monk_lowest_eligible(hero:Dictionary):
	var candidates:=player_healable_units().filter(func(ally):return float(ally.get("hp",0.0))>0.0 and Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(MonkData.SPACE.trait_radius))
	candidates.sort_custom(func(a,b):var ar:=float(a.hp)/maxf(1.0,float(a.max_hp));var br:=float(b.hp)/maxf(1.0,float(b.max_hp));return str(a.combat_id)<str(b.combat_id) if is_equal_approx(ar,br) else ar<br)
	return candidates[0] if not candidates.is_empty() else null

func resolve_monk_trait(hero:Dictionary,target:Dictionary,result:Dictionary)->void:
	var proc:=MonkSystem.note_basic_attack(hero,result);if not bool(proc.triggered):return
	if float(proc.healing)>0.0:
		var ally=monk_lowest_eligible(hero);if ally!=null:var healed:=deal_healing(hero,ally,float(proc.healing),"trait","Transcendence","monk_transcendence",["healing"]);MonkSystem.telemetry_add(hero,"transcendence_healing",float(healed.effective_amount))
	if float(proc.bonus_damage)>0.0 and float(target.get("hp",0.0))>0.0:var bonus:=deal_damage(hero,target,float(proc.bonus_damage),"trait","physical","Iron Fists",false,"monk_iron_fists",[],false);MonkSystem.telemetry_add(hero,"iron_damage",float(bonus.resolved_damage))

func monk_breath(hero:Dictionary,dash_target:Dictionary)->bool:
	if float(hero.monk_runtime.breath_cooldown)>0.0:MonkSystem.telemetry_add(hero,"breath_unavailable_dashes");return false
	hero.monk_runtime.breath_cooldown=float(MonkData.VALUES.breath_cooldown);MonkSystem.telemetry_add(hero,"breath_triggering_dashes");MonkSystem.telemetry_add(hero,"breath_casts")
	var recipients:Array=[];var base:=MonkData.scaled(float(MonkData.VALUES.breath_heal),int(hero.level));var echo:=MonkSystem.has_talent(hero,"monk_l24_3");var primary_fraction:=float(MonkData.VALUES.echo_fraction) if echo else 1.0
	for ally in player_healable_units():
		if float(ally.get("hp",0.0))<=0.0 or Vector2(ally.pos).distance_to(Vector2(hero.pos))>float(MonkData.SPACE.breath_radius):continue
		var targeted_multiplier:=1.0+float(MonkData.VALUES.heavenly_heal) if MonkSystem.has_talent(hero,"monk_l18_2") and str(ally.combat_id)==str(dash_target.combat_id) else 1.0;var requested:=base*primary_fraction*targeted_multiplier;var healed:=deal_healing(hero,ally,requested,"basic_ability","Breath of Heaven","monk_breath",["healing"]);MonkSystem.telemetry_add(hero,"breath_healing",float(healed.effective_amount));if targeted_multiplier>1.0:MonkSystem.telemetry_add(hero,"heavenly_bonus",base*primary_fraction*float(MonkData.VALUES.heavenly_heal))
		ally.active_effects=CombatSystem.apply_named_effect(ally.get("active_effects",[]),{"id":"monk_breath_speed:%s"%str(hero.combat_id),"source_id":"monk_breath_speed:%s"%str(hero.combat_id),"movement_speed_multiplier":1.0+float(MonkData.VALUES.heavenly_speed if MonkSystem.has_talent(hero,"monk_l18_2") else MonkData.VALUES.breath_speed),"remaining_duration":float(MonkData.VALUES.breath_speed_duration)})
		if MonkSystem.has_talent(hero,"monk_l21_2"):var armor:=MonkData.scaled(float(MonkData.VALUES.breath_armor),int(hero.level));ally["temporary_armor_sources"]=ally.get("temporary_armor_sources",[]).filter(func(source):return str(source.get("id",""))!="monk_breath_armor:%s"%str(hero.combat_id));ally.temporary_armor_sources.append({"id":"monk_breath_armor:%s"%str(hero.combat_id),"armor":armor,"remaining":float(MonkData.VALUES.breath_armor_duration)});MonkSystem.telemetry_add(hero,"breath_armor")
		recipients.append({"target_id":str(ally.combat_id),"amount":base*float(MonkData.VALUES.echo_fraction)*targeted_multiplier})
	if echo:hero.monk_runtime.echoes.append({"remaining":float(MonkData.VALUES.echo_delay),"recipients":recipients})
	if MonkSystem.has_talent(hero,"monk_l30_2") and float(hero.monk_runtime.storm_icd)<=0.0:
		for record in recipients:
			var shield_target=unit_by_combat_id(str(record.target_id));if shield_target!=null:apply_unit_shield(hero,shield_target,float(shield_target.max_hp)*float(MonkData.VALUES.storm_fraction),"Storm Shield","monk_storm:%s"%str(hero.combat_id),INF,float(MonkData.VALUES.storm_duration));MonkSystem.telemetry_add(hero,"storm_shields")
		hero.monk_runtime.storm_icd=float(MonkData.VALUES.storm_icd)
	monk_visual("monk_breath",hero.pos,hero.pos,.55,{"radius":float(MonkData.SPACE.breath_radius)});return true

func cast_monk_dash(hero:Dictionary,target:Dictionary)->bool:
	if Vector2(hero.pos).distance_to(Vector2(target.get("pos",hero.pos)))>float(MonkData.SPACE.dash_range):return false
	var plan:=MonkSystem.spend_dash(hero,target);if not bool(plan.cast):return false
	var from:=Vector2(hero.pos);var direction:=Vector2(target.pos).direction_to(from);if direction==Vector2.ZERO:direction=Vector2.LEFT
	var landing:=CombatGeometry.safe_endpoint(from,Vector2(target.pos)+direction.normalized()*float(MonkData.SPACE.dash_landing_offset),float(MonkData.SPACE.combat_radius),combat_blockers);hero.pos=landing;hero.dest=landing
	if bool(plan.allied):
		if str(target.get("monk_ally_owner_id",""))==str(hero.combat_id):MonkSystem.telemetry_add(hero,"ally_dashes_to_own")
		if MonkSystem.has_talent(hero,"monk_l21_1"):
			var removed:=StatusEffectSystem.remove_controls(target,["stun","root"]);MonkSystem.telemetry_add(hero,"cleanses",removed.size());MonkSystem.telemetry_add(hero,"stuns_removed",removed.count("stun"));MonkSystem.telemetry_add(hero,"roots_removed",removed.count("root"))
		if MonkSystem.has_talent(hero,"monk_l24_1"):target.active_effects=CombatSystem.apply_named_effect(target.get("active_effects",[]),{"id":"protected","owner_id":str(hero.combat_id),"remaining_duration":float(MonkData.VALUES.sanctified_duration)});MonkSystem.telemetry_add(hero,"protected_applications")
		monk_breath(hero,target)
	else:
		if MonkSystem.activate_reach(hero):MonkSystem.telemetry_add(hero,"reach_triggering_dashes")
		else:MonkSystem.telemetry_add(hero,"reach_unavailable_dashes")
		var immediate:=deal_damage(hero,target,float(hero.damage),"basic_attack","physical","Radiant Dash",false,"monk_dash_attack",[],true);MonkSystem.telemetry_add(hero,"dash_attacks");resolve_monk_trait(hero,target,immediate)
		if MonkSystem.has_talent(hero,"monk_l24_2"):
			for strike_index in int(MonkData.VALUES.hundred_strikes):
				if float(target.get("hp",0.0))<=0.0:break
				var fist:=deal_damage(hero,target,float(hero.damage)*float(MonkData.VALUES.hundred_damage),"basic_attack","physical","Way of the Hundred Fists",false,"monk_hundred_fists",[],false);resolve_monk_trait(hero,target,fist);MonkSystem.telemetry_add(hero,"hundred_strikes")
	monk_visual("monk_dash_ally" if bool(plan.allied) else "monk_dash_enemy",from,landing,.35);return true

func cast_monk_ally(hero:Dictionary,point:Vector2)->bool:
	var offset:=point-Vector2(hero.pos);var clamped_point:=point if offset.length()<=float(MonkData.SPACE.ally_placement_range) else Vector2(hero.pos)+offset.normalized()*float(MonkData.SPACE.ally_placement_range);clamped_point=clamped_point.clamp(Vector2(55,70),Vector2(1225,620))
	var endpoint:=CombatGeometry.safe_endpoint(hero.pos,clamped_point,float(MonkData.SPACE.ally_radius),combat_blockers);var result:=MonkSystem.cast_ally(hero,endpoint);if not bool(result.cast):return false
	monk_visual("monk_ally_%s"%str(result.ally.ally_kind),endpoint,endpoint,.6,{"radius":float(MonkData.SPACE.ally_aura_radius)});return true

func cast_monk_palm(hero:Dictionary,point:Vector2)->bool:
	var candidates:=player_healable_units().filter(func(ally):return float(ally.get("hp",0.0))>0.0 and Vector2(hero.pos).distance_to(Vector2(ally.pos))<=float(MonkData.SPACE.palm_range) and Vector2(ally.pos).distance_to(point)<=65.0 and (not bool(ally.get("summoned_unit",false)) or MonkSystem.is_major_companion(ally)))
	candidates.sort_custom(func(a,b):return Vector2(a.pos).distance_squared_to(point)<Vector2(b.pos).distance_squared_to(point));if candidates.is_empty():return false
	var target:Dictionary=candidates[0];if not MonkSystem.start_palm(hero,target):return false
	monk_visual("monk_palm",target.pos,target.pos,float(MonkData.VALUES.palm_duration));return true

func cast_monk_ability(slot:int,point:Vector2)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Monk" or hero.get("monk_runtime",{}).is_empty():return false
	match slot:
		0:var target=monk_target_near_point(hero,point);return cast_monk_dash(hero,target) if target!=null else false
		1,2:return false
		3:return cast_monk_palm(hero,point) if str(hero.selected_heroic_id)=="monk_l15_r1" else MonkSystem.start_seven(hero)
		4:return cast_monk_ally(hero,point)
	return false

func monk_resolve_palm(target:Dictionary)->float:
	for monk in heroes:
		if str(monk.get("class",""))!="Monk" or monk.get("monk_runtime",{}).is_empty():continue
		var amount:=MonkSystem.consume_palm_for(monk,str(target.get("combat_id","")))
		if amount>0.0:var missing:=maxf(0.0,float(target.max_hp)-float(target.hp));var actual:=minf(amount,missing);target.hp=float(target.hp)+actual;monk_visual("monk_palm_trigger",target.pos,target.pos,.7);return actual
	return 0.0

func monk_seven_tick(hero:Dictionary)->void:
	var rt:Dictionary=hero.monk_runtime.seven;var candidates:=enemies.filter(func(enemy):return float(enemy.get("hp",0.0))>0.0 and TargetCategorySystem.qualifies_immediate(enemy) and Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=float(MonkData.SPACE.seven_sided_range))
	candidates.sort_custom(func(a,b):var ah:=float(a.hp);var bh:=float(b.hp);return str(a.combat_id)<str(b.combat_id) if is_equal_approx(ah,bh) else ah>bh)
	if not candidates.is_empty():
		var target:Dictionary=candidates[0];var request:=PercentageHealthDamageSystem.request(hero,target,float(MonkData.VALUES.seven_normal),float(MonkData.VALUES.seven_boss),"Seven-Sided Strike");var hit:=deal_damage(hero,target,float(request.amount),"percentage_health","physical","Seven-Sided Strike",false,"monk_seven",[],false);rt.target_id=str(target.combat_id);MonkSystem.telemetry_add(hero,"seven_strikes");MonkSystem.telemetry_add(hero,"seven_boss_damage" if bool(request.is_boss) else "seven_normal_damage",float(hit.resolved_damage));monk_visual("monk_seven_strike",hero.pos,target.pos,.2)
	rt.strikes_left=int(rt.strikes_left)-1;rt.strike_number=int(rt.strike_number)+1;hero.monk_runtime.seven=rt

func update_monk_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Monk" or hero.get("monk_runtime",{}).is_empty():continue
		MonkSystem.advance(hero,delta);var rt:Dictionary=hero.monk_runtime;hero.basic_attack_interval=float(hero.base_basic_action_interval)/(1.0+float(MonkData.VALUES.deadly_speed) if MonkSystem.reach_active(hero) else 1.0);hero.range=float(MonkData.SPACE.basic_range)*(float(MonkData.SPACE.deadly_range_multiplier) if MonkSystem.reach_active(hero) else 1.0)
		if not rt.ally.is_empty():
			update_timed_combat_effects(rt.ally,delta);rt.ally_tick=float(rt.ally_tick)-delta;var recipients:=player_healable_units().filter(func(ally):return float(ally.get("hp",0.0))>0.0 and Vector2(ally.pos).distance_to(Vector2(rt.ally.pos))<=float(MonkData.SPACE.ally_aura_radius));rt.ally_aura_recipients=recipients.map(func(ally):return str(ally.combat_id))
			if str(rt.ally.ally_kind)=="earth":
				for ally in recipients:ally["temporary_armor_sources"]=ally.get("temporary_armor_sources",[]).filter(func(source):return str(source.get("id",""))!="monk_earth:%s"%str(hero.combat_id));ally.temporary_armor_sources.append({"id":"monk_earth:%s"%str(hero.combat_id),"armor":MonkData.scaled(float(MonkData.VALUES.earth_armor),int(hero.level)),"remaining":delta+.08});MonkSystem.telemetry_add(hero,"earth_recipients")
			elif str(rt.ally.ally_kind)=="air":
				for ally in recipients:ally.active_effects=CombatSystem.apply_named_effect(ally.get("active_effects",[]),{"id":"monk_air:%s"%str(hero.combat_id),"source_id":"monk_air:%s"%str(hero.combat_id),"ability_power_percent":float(MonkData.VALUES.air_ability_power),"remaining_duration":delta+.08});MonkSystem.telemetry_add(hero,"air_recipients")
			elif float(rt.ally_tick)<=0.0:
				rt.ally_tick+=1.0;for ally in recipients:var healed:=deal_healing(hero,ally,float(ally.max_hp)*float(MonkData.VALUES.spirit_heal_fraction),"summon","Spirit Ally","monk_spirit_ally",["healing"]);MonkSystem.telemetry_add(hero,"spirit_healing",float(healed.effective_amount))
		for echo_index in range(rt.echoes.size()-1,-1,-1):
			var echo:Dictionary=rt.echoes[echo_index];echo.remaining=float(echo.remaining)-delta
			if float(echo.remaining)<=0.0:
				for record in echo.recipients:var target=unit_by_combat_id(str(record.target_id));if target!=null and float(target.get("hp",0.0))>0.0:var healed:=deal_healing(hero,target,float(record.amount),"basic_ability","Echo of Heaven","monk_echo",["healing","secondary"]);MonkSystem.telemetry_add(hero,"echo_healing",float(healed.effective_amount))
				rt.echoes.remove_at(echo_index)
			else:rt.echoes[echo_index]=echo
		if not rt.seven.is_empty():
			hero.active_effects=CombatSystem.apply_named_effect(hero.get("active_effects",[]),{"id":"invulnerable","owner_id":str(hero.combat_id),"remaining_duration":delta+.08});rt.seven.remaining=maxf(0.0,float(rt.seven.remaining)-delta);rt.seven.tick=float(rt.seven.tick)-delta
			var interval:=float(MonkData.VALUES.seven_duration)/maxf(1.0,float(int(MonkData.VALUES.seven_strikes)+(int(MonkData.VALUES.transgression_strikes) if MonkSystem.has_talent(hero,"monk_l27_r2") else 0)))
			while not rt.seven.is_empty() and int(rt.seven.strikes_left)>0 and float(rt.seven.tick)<=0.0:rt.seven.tick=float(rt.seven.tick)+interval;monk_seven_tick(hero);rt=hero.monk_runtime
			if int(rt.seven.get("strikes_left",0))<=0 or float(rt.seven.get("remaining",0.0))<=0.0:rt.seven={};hero.active_effects=hero.get("active_effects",[]).filter(func(effect):return not (str(effect.get("id",""))=="invulnerable" and str(effect.get("owner_id",""))==str(hero.combat_id)))
