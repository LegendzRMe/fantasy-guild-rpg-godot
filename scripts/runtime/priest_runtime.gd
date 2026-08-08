extends "res://scripts/runtime/slayer_runtime.gd"

func priest_visual(kind:String,from:Vector2,to:Vector2,duration:float,extra:Dictionary={})->void:
	var effect:={"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Priest.color,"life":duration,"max_life":duration};effect.merge(extra,true);effects.append(effect)

func priest_damage(hero:Dictionary,target:Dictionary,amount:float,origin:String,effect_id:String,action:String="basic_ability")->Dictionary:
	var result:=deal_damage(hero,target,amount,action,"magical",origin,false,effect_id,[],true)
	if float(result.get("resolved_damage",0.0))>0.0 and PriestSystem.has_talent(hero,"priest_l18_1") and str(hero.priest_runtime.zeal_target)!="" and float(hero.priest_runtime.zeal_remaining)>0.0:
		var zeal_target=unit_by_combat_id(str(hero.priest_runtime.zeal_target))
		if zeal_target!=null and zeal_target.hp>0.0:
			var zeal:=deal_healing(hero,zeal_target,float(result.resolved_damage)*float(PriestData.VALUES.zeal_rate),"basic_heal","Zeal","priest_zeal");PriestSystem.telemetry_add(hero,"zeal_damage",float(result.resolved_damage));PriestSystem.telemetry_add(hero,"zeal_healing",float(zeal.effective_amount))
	return result

func priest_direct_heal(hero:Dictionary,target:Dictionary,amount:float,origin:String,effect_id:String)->Dictionary:
	if PriestSystem.spirit_active(target):return {"effective_amount":0.0,"overhealing":amount,"raw_amount":amount}
	var result:=deal_healing(hero,target,amount,"basic_ability",origin,effect_id)
	var direct_core_heal:=effect_id in ["priest_q","priest_w"]
	if direct_core_heal and PriestSystem.has_talent(hero,"priest_l18_3"):
		PriestSystem.add_named_armor(target,"priest_devotion",PriestSystem.scaled(hero,float(PriestData.VALUES.devotion_ally)),float(PriestData.VALUES.devotion_duration));PriestSystem.add_named_armor(hero,"priest_devotion_self",PriestSystem.scaled(hero,float(PriestData.VALUES.devotion_self)),float(PriestData.VALUES.devotion_duration));PriestSystem.telemetry_add(hero,"devotion_applications")
	if direct_core_heal and PriestSystem.has_talent(hero,"priest_l30_1") and target.get("active_effects",[]).any(func(effect):return str(effect.get("control_type","")) in ["stun","root","silence"] and float(effect.get("remaining_duration",0.0))>0.0):PriestSystem.add_named_armor(target,"priest_guardian",PriestSystem.scaled(hero,float(PriestData.VALUES.guardian_armor)),float(PriestData.VALUES.guardian_duration));PriestSystem.telemetry_add(hero,"guardian_triggers")
	return result

func cast_priest_q(hero:Dictionary)->bool:
	if float(hero.ability_cds[0])>0.0 or bool(hero.priest_runtime.q_pending):return false
	PriestSystem.begin_flash_heal(hero);begin_unit_cast(hero,0,float(PriestData.VALUES.q_cast),false,0.0,false,float(PriestData.VALUES.q_cooldown));priest_visual("priest_flash_cast",hero.pos,hero.pos,float(PriestData.VALUES.q_cast));return true

func complete_priest_q(hero:Dictionary)->void:
	var target=PriestSystem.most_wounded(heroes,hero,float(PriestData.SPACE.flash_heal_radius))
	if target==null:hero.priest_runtime.q_pending=false;return
	var amount:=PriestSystem.flash_heal_amount(hero,target);var result:=priest_direct_heal(hero,target,amount,"Flash Heal","priest_q");var completion:=PriestSystem.complete_flash_heal(hero,target,float(result.get("raw_amount",amount)))
	PriestSystem.telemetry_add(hero,"q_effective",float(result.effective_amount));PriestSystem.telemetry_add(hero,"q_overhealing",float(result.overhealing));if float(target.hp)>=float(target.max_hp):PriestSystem.telemetry_add(hero,"q_full_health")
	if bool(completion.renew):
		hero.priest_runtime.periodic_heals=hero.priest_runtime.periodic_heals.filter(func(instance):return str(instance.get("id",""))!="priest_renew" or str(instance.get("target_id",""))!=str(target.combat_id))
		hero.priest_runtime.periodic_heals.append(PeriodicStatusSystem.create("priest_renew",str(hero.combat_id),str(target.combat_id),PriestSystem.ability_amount(hero,float(PriestData.VALUES.renew_total))/float(PriestData.VALUES.renew_duration),float(PriestData.VALUES.renew_duration),float(PriestData.VALUES.renew_tick)))
	PriestSystem.consume_benediction(hero,0);priest_visual("priest_flash_heal",hero.pos,target.pos,.4)

func cast_priest_w(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[1])>0.0:return false
	var direction:=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var multiplier:=PriestSystem.divine_star_multiplier(hero);hero.priest_runtime.divine_stars.append({"origin":Vector2(hero.pos),"pos":Vector2(hero.pos),"direction":direction,"distance":0.0,"phase":"out","enemy_ids":[],"ally_ids":[],"shield_ids":[],"qualifying_count":0,"multiplier":float(multiplier.multiplier)});hero.priest_runtime.divine_star_moving=true;hero.ability_cds[1]=float(PriestData.VALUES.w_cooldown);PriestSystem.telemetry_add(hero,"w_casts");priest_visual("priest_star",hero.pos,hero.pos,.4);return true

func cast_priest_e(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[2])>0.0:return false
	var direction:=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var end:=Vector2(hero.pos)+direction*float(PriestData.SPACE.chastise_range);var candidates:Array=[]
	for target in enemies:
		if target.hp>0.0 and CombatGeometry.segment_hits_circle(hero.pos,end,target.pos,float(PriestData.SPACE.chastise_width)+float(target.get("combat_radius",28.0))):candidates.append(target)
	candidates.sort_custom(func(a,b):return hero.pos.distance_squared_to(a.pos)<hero.pos.distance_squared_to(b.pos))
	var contacts:Array=[];var maximum:=2 if PriestSystem.has_talent(hero,"priest_l12_3") else 1
	for target in candidates.slice(0,maximum):
		var result:=priest_damage(hero,target,PriestSystem.ability_amount(hero,float(PriestData.VALUES.e_damage)),"Chastise","priest_e")
		if PriestSystem.successful(result):
			PriestSystem.telemetry_add(hero,"e_hits");var control:=CombatSystem.apply_control(target,"root",float(PriestData.VALUES.e_root));if bool(control.applied):target.active_effects.append({"id":"priest_chastise_root","owner_id":str(hero.combat_id),"remaining_duration":float(control.duration)});PriestSystem.telemetry_add(hero,"e_roots")
			if not bool(control.applied) or float(control.duration)<float(PriestData.VALUES.e_root):PriestSystem.telemetry_add(hero,"e_resisted")
			contacts.append(target)
	hero.ability_cds[2]=float(PriestData.VALUES.e_cooldown);PriestSystem.note_piercing_cast(hero,contacts);PriestSystem.consume_benediction(hero,2);PriestSystem.telemetry_add(hero,"e_casts");priest_visual("priest_chastise",hero.pos,end,.35,{"width":float(PriestData.SPACE.chastise_width)});return true

func cast_priest_heroic(hero:Dictionary)->bool:
	if PriestSystem.spirit_active(hero) or float(hero.ability_cds[3])>0.0:return false
	if str(hero.selected_heroic_id)=="priest_l15_r1":
		begin_unit_cast(hero,3,float(PriestData.VALUES.r1_startup),true,float(PriestData.VALUES.r1_channel),false,float(PriestData.VALUES.r1_cooldown));hero.priest_runtime.salvation_started=false;PriestSystem.telemetry_add(hero,"salvation_casts");return true
	if str(hero.selected_heroic_id)=="priest_l15_r2":
		var target=PriestSystem.lightbomb_recipient(heroes,hero);if target==null:return false
		hero.priest_runtime.delayed_effects.append({"kind":"lightbomb","remaining":float(PriestData.VALUES.r2_delay),"target_id":str(target.combat_id)});hero.ability_cds[3]=float(PriestData.VALUES.r2_cooldown);PriestSystem.telemetry_add(hero,"lightbomb_casts");if target==hero:PriestSystem.telemetry_add(hero,"lightbomb_self");priest_visual("priest_lightbomb_warning",target.pos,target.pos,float(PriestData.VALUES.r2_delay),{"radius":float(PriestData.SPACE.lightbomb_radius)});return true
	return false

func cast_priest_ability(slot:int,point:Vector2,_item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Priest" or hero.get("priest_runtime",{}).is_empty():return false
	if PriestSystem.spirit_active(hero) and slot==3:PriestSystem.telemetry_add(hero,"heroics_blocked");return false
	var casted:=false
	match slot:
		0:casted=cast_priest_q(hero)
		1:casted=cast_priest_w(hero,point)
		2:casted=cast_priest_e(hero,point)
		3:casted=cast_priest_heroic(hero)
	if casted and slot<3 and PriestSystem.spirit_active(hero):PriestSystem.telemetry_add(hero,"spirit_basic_abilities")
	return casted

func update_priest_star(hero:Dictionary,star:Dictionary,delta:float)->bool:
	var previous:=Vector2(star.pos);var movement:=float(PriestData.SPACE.divine_star_speed)*delta;star.distance=float(star.distance)+movement
	if star.phase=="out":
		star.pos=Vector2(star.pos)+Vector2(star.direction)*movement
		for target in enemies:
			var id:=str(target.combat_id);if target.hp<=0.0 or id in star.enemy_ids or not CombatGeometry.segment_hits_circle(previous,star.pos,target.pos,float(PriestData.SPACE.divine_star_out_width)+float(target.get("combat_radius",28.0))):continue
			star.enemy_ids.append(id);var result:=priest_damage(hero,target,PriestSystem.ability_amount(hero,float(PriestData.VALUES.w_damage))*float(star.multiplier),"Divine Star","priest_w");PriestSystem.telemetry_add(hero,"w_outbound",float(result.get("resolved_damage",0.0)));if TargetCategorySystem.qualifies_immediate(target) and int(star.qualifying_count)<int(PriestData.VALUES.hero_hit_cap):star.qualifying_count+=1;PriestSystem.telemetry_add(hero,"w_qualifying");if int(star.qualifying_count)==int(PriestData.VALUES.hero_hit_cap):PriestSystem.telemetry_add(hero,"w_capped")
			if PriestSystem.has_talent(hero,"priest_l9_2"):apply_unit_shield(hero,hero,PriestSystem.ability_amount(hero,float(PriestData.VALUES.pws_self)),"Power Word: Shield","priest_pws_self",INF,float(PriestData.VALUES.pws_duration))
		if PriestSystem.has_talent(hero,"priest_l9_2"):
			for ally in heroes:
				var ally_id:=str(ally.combat_id);if ally.hp<=0.0 or ally_id in star.shield_ids or not CombatGeometry.segment_hits_circle(previous,star.pos,ally.pos,float(PriestData.SPACE.divine_star_out_width)+float(ally.get("combat_radius",42.0))):continue
				star.shield_ids.append(ally_id);apply_unit_shield(hero,ally,PriestSystem.ability_amount(hero,float(PriestData.VALUES.pws_ally)),"Power Word: Shield","priest_pws_ally",INF,float(PriestData.VALUES.pws_duration))
		if float(star.distance)>=float(PriestData.SPACE.divine_star_distance):
			star.phase="return";star.distance=0.0
			if PriestSystem.has_talent(hero,"priest_l12_1"):
				for target in enemies:if target.hp>0.0 and target.pos.distance_to(star.pos)<=float(hero.range):deal_damage(hero,target,float(hero.damage),"basic_attack","physical","Moral Compass")
	else:
		var destination:=Vector2(hero.pos);star.pos=Vector2(star.pos).move_toward(destination,movement)
		for target in heroes:
			var id:=str(target.combat_id);if target.hp<=0.0 or id in star.ally_ids or not CombatGeometry.segment_hits_circle(previous,star.pos,target.pos,float(PriestData.SPACE.divine_star_return_width)+float(target.get("combat_radius",42.0))):continue
			star.ally_ids.append(id);var return_multiplier:=float(star.multiplier)*(1.0+int(star.qualifying_count)*float(PriestData.VALUES.w_bonus_per_enemy));var healing:=priest_direct_heal(hero,target,PriestSystem.ability_amount(hero,float(PriestData.VALUES.w_heal))*return_multiplier,"Divine Star","priest_w");PriestSystem.telemetry_add(hero,"w_return_allies");PriestSystem.telemetry_add(hero,"w_healing",float(healing.effective_amount));PriestSystem.telemetry_add(hero,"w_overhealing",float(healing.overhealing));if PriestSystem.has_talent(hero,"priest_l21_1"):hero.ability_cds[1]=maxf(0.0,float(hero.ability_cds[1])-float(PriestData.VALUES.speed_pious_reduction))
		if star.pos.distance_to(destination)<=4.0:
			if PriestSystem.has_talent(hero,"priest_l24_2"):
				for ally in heroes:if ally.hp>0.0 and ally.pos.distance_to(hero.pos)<=float(PriestData.SPACE.holy_nova_radius):priest_direct_heal(hero,ally,PriestSystem.ability_amount(hero,float(PriestData.VALUES.holy_nova_heal)),"Holy Nova","priest_holy_nova")
				for enemy in enemies:if enemy.hp>0.0 and enemy.pos.distance_to(hero.pos)<=float(PriestData.SPACE.holy_nova_radius):priest_damage(hero,enemy,PriestSystem.ability_amount(hero,float(PriestData.VALUES.holy_nova_damage)),"Holy Nova","priest_holy_nova")
			PriestSystem.consume_benediction(hero,1);return true
	priest_visual("priest_star",previous,star.pos,.12);return false

func update_priest_salvation(hero:Dictionary,delta:float)->void:
	var channel:Dictionary=hero.get("active_channel",{})
	if int(channel.get("slot",-1))!=3:
		if bool(hero.priest_runtime.get("salvation_started",false)):
			hero.priest_runtime.salvation_started=false
			if PriestSystem.has_talent(hero,"priest_l27_r1"):hero.ability_cds[3]=maxf(0.0,float(hero.ability_cds[3])-float(PriestData.VALUES.light_stormwind_refund))
		return
	hero.priest_runtime.salvation_started=true;var tick_fraction:=float(PriestData.VALUES.r1_heal_fraction)*delta/float(PriestData.VALUES.r1_channel)
	for ally in heroes:
		if ally.hp<=0.0 or ally.pos.distance_to(hero.pos)>float(PriestData.SPACE.salvation_radius):continue
		var salvation_heal:=priest_direct_heal(hero,ally,float(ally.max_hp)*tick_fraction,"Holy Word: Salvation","priest_r1");PriestSystem.telemetry_add(hero,"salvation_healing",float(salvation_heal.effective_amount));ally.active_effects=CombatSystem.apply_named_effect(ally.get("active_effects",[]),{"id":"protected","owner_id":str(hero.combat_id),"remaining_duration":delta+.08});if PriestSystem.has_talent(hero,"priest_l27_r1") and ally!=hero:ally.active_effects=CombatSystem.apply_named_effect(ally.active_effects,{"id":"invulnerable","owner_id":str(hero.combat_id),"remaining_duration":delta+.08})
	priest_visual("priest_salvation",hero.pos,hero.pos,.12,{"radius":float(PriestData.SPACE.salvation_radius)})

func update_priest_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Priest" or hero.get("priest_runtime",{}).is_empty():continue
		PriestSystem.update_named_armor(hero,delta)
		var update:=PriestSystem.update(hero,delta)
		if bool(hero.priest_runtime.q_pending) and hero.get("active_cast",{}).is_empty() and int(hero.priest_runtime.q_completed_token)<int(hero.priest_runtime.q_cast_token):complete_priest_q(hero)
		for index in range(hero.priest_runtime.divine_stars.size()-1,-1,-1):if update_priest_star(hero,hero.priest_runtime.divine_stars[index],delta):hero.priest_runtime.divine_stars.remove_at(index)
		hero.priest_runtime.divine_star_moving=not hero.priest_runtime.divine_stars.is_empty()
		for index in range(hero.priest_runtime.delayed_effects.size()-1,-1,-1):
			var delayed:Dictionary=hero.priest_runtime.delayed_effects[index];delayed.remaining=float(delayed.remaining)-delta
			if delayed.remaining>0.0:continue
			var recipient=unit_by_combat_id(str(delayed.target_id));if recipient!=null and recipient.hp>0.0:
				var contacts:Array=[]
				for enemy in enemies:
					if enemy.hp<=0.0 or enemy.pos.distance_to(recipient.pos)>float(PriestData.SPACE.lightbomb_radius):continue
					contacts.append(enemy);priest_damage(hero,enemy,PriestSystem.ability_amount(hero,float(PriestData.VALUES.r2_damage)),"Lightbomb","priest_r2");CombatSystem.apply_control(enemy,"stun",float(PriestData.VALUES.r2_stun));PriestSystem.telemetry_add(hero,"lightbomb_hits")
				var shield_contacts:=PriestSystem.capped_immediate_contacts(contacts)
				if shield_contacts>0:apply_unit_shield(hero,recipient,PriestSystem.ability_amount(hero,float(PriestData.VALUES.r2_shield))*shield_contacts,"Lightbomb","priest_lightbomb",INF,float(PriestData.VALUES.r2_shield_duration))
				PriestSystem.telemetry_add(hero,"lightbomb_shield_contacts",shield_contacts)
				if PriestSystem.has_talent(hero,"priest_l27_r2"):PriestSystem.add_named_armor(recipient,"priest_inner_fire",PriestSystem.scaled(hero,float(PriestData.VALUES.inner_fire_armor)),float(PriestData.VALUES.inner_fire_duration));recipient.active_effects=CombatSystem.apply_named_effect(recipient.get("active_effects",[]),{"id":"priest_inner_fire_speed","movement_speed_multiplier":1.0+float(PriestData.VALUES.inner_fire_speed),"remaining_duration":float(PriestData.VALUES.inner_fire_duration)})
			hero.priest_runtime.delayed_effects.remove_at(index)
		for tick in update.renew_ticks:
			var target=unit_by_combat_id(str(tick.target_id))
			if target!=null and target.hp>0.0:
				var is_blessed_recovery:=str(tick.get("id",""))=="priest_blessed_recovery"
				deal_healing(hero,target,float(tick.tick_amount),"periodic","Blessed Recovery" if is_blessed_recovery else "Renew",str(tick.get("id","priest_renew")))
				if not is_blessed_recovery:PriestSystem.telemetry_add(hero,"renew_ticks")
		for tick in update.varian_ticks:
			var target=unit_by_combat_id(str(tick.target_id));if target!=null and target.hp>0.0:var result:=priest_damage(hero,target,float(tick.tick_amount),"Varian's Legacy","priest_varian","periodic");var varian_heal:=deal_healing(hero,hero,float(result.resolved_damage)*float(PriestData.VALUES.varian_heal),"periodic","Varian's Legacy","priest_varian");PriestSystem.telemetry_add(hero,"varian_damage",float(result.resolved_damage));PriestSystem.telemetry_add(hero,"varian_healing",float(varian_heal.effective_amount))
		update_priest_salvation(hero,delta)
		if bool(update.spirit_expired):
			if PriestSystem.has_talent(hero,"priest_l30_2") and float(hero.priest_runtime.redemption_ready_in)<=0.0:hero.priest_runtime.spirit_form=false;hero.spirit_form=false;hero.hp=float(hero.max_hp)*float(PriestData.VALUES.redemption_health);hero.priest_runtime.redemption_ready_in=float(PriestData.VALUES.redemption_cooldown);PriestSystem.telemetry_add(hero,"redemptions")
			else:hero.priest_runtime.spirit_form=false;hero.spirit_form=false;hero.hp=0.0;PriestSystem.telemetry_add(hero,"spirit_expiry")
