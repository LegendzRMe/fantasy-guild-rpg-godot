extends "res://scripts/runtime/cleric_runtime.gd"

func clamped_cast_point(hero:Dictionary,point:Vector2,range_limit:float)->Vector2:
	if range_limit<=0:return hero.pos
	var offset=point-hero.pos
	if offset.length()<=range_limit:return point.clamp(Vector2(55,70),Vector2(1225,620))
	return (hero.pos+offset.normalized()*range_limit).clamp(Vector2(55,70),Vector2(1225,620))

func scaled_ability_amount(hero:Dictionary,level_one_amount:float)->float:
	return CombatSystem.calculate_power_scaled_amount(hero,level_one_amount/maxf(0.001,float(CLASSES[hero["class"]].base_power)))

func use_ability(slot:int,cast_position:Vector2=Vector2.INF,item_repeat:bool=false) -> void:
	if selected>=heroes.size():return
	var h=heroes[selected]
	if not TalentSystem.ability_is_unlocked(int(state.heroes[battle_hero_indices[selected]].level),slot):return
	var ability_enemy_target:int=combat_enemy_target()
	if slot>=4:return
	if h.hp<=0:return
	if not item_repeat:
		if slot==0 and hero_has_passive(h,"twin_incantation"):
			if int(h.get("q_charges",0))<=0:return
		elif h.ability_cds[slot]>0:return
	if tutorial_active and tutorial_step==7 and h["class"]=="Cleric" and slot==0:tutorial_ability_used=true
	if cast_position==Vector2.INF:cast_position=get_global_mouse_position()
	if h["class"]=="Guardian":
		cast_guardian_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Cleric":
		var cleric_cast_succeeded:=cast_cleric_ability(slot,item_repeat)
		if cleric_cast_succeeded and not item_repeat:
			if slot==0 and hero_has_passive(h,"twin_incantation"):
				h.q_charges=int(h.q_charges)-1;h.q_charge_timers.append(float(ClericData.VALUES.q_cooldown));h.ability_cds[0]=0.0 if h.q_charges>0 else float(ClericData.VALUES.q_cooldown)
			if slot==2 and hero_has_passive(h,"twin_incantation") and int(h.q_charges)<2:
				h.q_charges=int(h.q_charges)+1
				if not h.q_charge_timers.is_empty():h.q_charge_timers.remove_at(0)
				h.ability_cds[0]=0.0;item_feedback("Q Charge Restored",h.pos,Color("b8d5ff"))
			if slot<3 and hero_has_passive(h,"borrowed_time") and bool(h.get("borrowed_time_armed",false)):
				h.borrowed_time_armed=false;h.borrowed_time_timer=0.0;h.pending_repeats.append({"remaining":0.4,"slot":slot,"position":h.pos,"enemy_target":ability_enemy_target,"assigned_target":int(h.target),"ally_target":int(h.heal_target)})
		return
	var ability_range=float(ABILITY_RANGES[h["class"]][slot])
	var resolved_point=clamped_cast_point(h,cast_position,ability_range) if ability_range>0 else h.pos
	if resolved_point.distance_to(h.pos)>1:h.facing_direction=h.pos.direction_to(resolved_point)
	CombatRulesV1.preserve_command(h);h.command_state=CombatRulesV1.CommandState.CAST
	var base_cooldown:float=[4.0,7.0,8.0,18.0][slot]
	if not item_repeat:
		if slot==0 and hero_has_passive(h,"twin_incantation"):
			h.q_charges=int(h.q_charges)-1;h.q_charge_timers.append(base_cooldown);h.ability_cds[0]=0.0 if h.q_charges>0 else base_cooldown
		else:h.ability_cds[slot]=base_cooldown
	var ability_action:="heroic" if slot==3 else "basic_ability";var ability_damage_type:="magical" if h["class"] in ["Cleric","Mage","Warlock"] else "physical";combat_events.append(CombatSystem.create_event("heroic_cast" if slot==3 else "basic_ability_cast",h,h,{"amount":0.0,"critical":false,"source_action":ability_action},{"action_tags":[ability_action],"origin":ABILITIES[h["class"]][slot]}))
	add_effect("heroic" if slot==3 else "cast",h.pos,h.pos,("ECHO: " if item_repeat else "")+ABILITIES[h["class"]][slot],CLASSES[h["class"]].color)
	match h["class"]:
		"Guardian":
			if slot==0:
				apply_unit_shield(h,h,scaled_ability_amount(h,40.0),ABILITIES[h["class"]][slot])
			elif slot==1:
				for foe_challenge in enemies:
					if foe_challenge.hp>0:taunt_enemy(foe_challenge,selected);foe_challenge.pos=foe_challenge.pos.move_toward(h.pos,45)
			elif slot==2:
				h.pos=resolved_point;h.dest=h.pos
				for foe_rush in enemies:if foe_rush.hp>0 and foe_rush.pos.distance_to(h.pos)<105:deal_damage(h,foe_rush,scaled_ability_amount(h,38.0),ability_action,"physical",ABILITIES[h["class"]][slot])
			else:for ally_bastion in heroes:if ally_bastion.hp>0:apply_unit_shield(h,ally_bastion,scaled_ability_amount(h,30.0),ABILITIES[h["class"]][slot])
		"Ranger":
			if slot==0 and ability_enemy_target>=0:deal_damage(h,enemies[ability_enemy_target],scaled_ability_amount(h,65.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
			elif slot==1:h.pos=resolved_point;h.dest=h.pos
			elif slot==2:for foe_volley in enemies:if foe_volley.hp>0 and foe_volley.pos.distance_to(resolved_point)<140:deal_damage(h,foe_volley,scaled_ability_amount(h,42.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
			else:for foe_arrowstorm in enemies:if foe_arrowstorm.hp>0 and foe_arrowstorm.pos.distance_to(resolved_point)<180:deal_damage(h,foe_arrowstorm,scaled_ability_amount(h,72.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
		"Mage":
			if slot==0 and ability_enemy_target>=0:deal_damage(h,enemies[ability_enemy_target],scaled_ability_amount(h,78.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
			elif slot==1:h.pos=resolved_point;h.dest=h.pos
			elif slot==2:for foe_burst in enemies:if foe_burst.hp>0 and foe_burst.pos.distance_to(h.pos)<240:deal_damage(h,foe_burst,scaled_ability_amount(h,55.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
			else:for foe_starfall in enemies:if foe_starfall.hp>0 and foe_starfall.pos.distance_to(resolved_point)<190:deal_damage(h,foe_starfall,scaled_ability_amount(h,85.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
		"Rogue":
			if slot==0 and ability_enemy_target>=0:deal_damage(h,enemies[ability_enemy_target],scaled_ability_amount(h,72.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
			elif slot==1:h.pos=resolved_point;h.dest=h.pos
			elif slot==2:for foe_knives in enemies:if foe_knives.hp>0 and foe_knives.pos.distance_to(h.pos)<120:deal_damage(h,foe_knives,scaled_ability_amount(h,46.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
			elif ability_enemy_target>=0:deal_damage(h,enemies[ability_enemy_target],scaled_ability_amount(h,105.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])

		"Warlock":
			if slot==0 and ability_enemy_target>=0:deal_damage(h,enemies[ability_enemy_target],scaled_ability_amount(h,74.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
			elif slot==1:h.pos=resolved_point;h.dest=h.pos
			elif slot==2:for foe_wither in enemies:if foe_wither.hp>0 and foe_wither.pos.distance_to(resolved_point)<150:deal_damage(h,foe_wither,scaled_ability_amount(h,48.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
			else:for foe_soul in enemies:if foe_soul.hp>0 and foe_soul.pos.distance_to(h.pos)<260:deal_damage(h,foe_soul,scaled_ability_amount(h,78.0),ability_action,ability_damage_type,ABILITIES[h["class"]][slot])
	if not item_repeat and slot==2 and hero_has_passive(h,"twin_incantation") and int(h.q_charges)<2:
		h.q_charges=int(h.q_charges)+1
		if not h.q_charge_timers.is_empty():h.q_charge_timers.remove_at(0)
		h.ability_cds[0]=0.0;item_feedback("Q Charge Restored",h.pos,Color("b8d5ff"))
	if not item_repeat and slot<3 and hero_has_passive(h,"borrowed_time") and bool(h.get("borrowed_time_armed",false)):
		h.borrowed_time_armed=false;h.borrowed_time_timer=0.0
		h.pending_repeats.append({"remaining":0.4,"slot":slot,"position":resolved_point,"enemy_target":ability_enemy_target,"assigned_target":int(h.target),"ally_target":int(h.heal_target)})
		item_feedback("Borrowed Time",h.pos,Color("b8d5ff"))
	CombatRulesV1.restore_preserved_command(h,target_is_valid_for(h,unit_by_combat_id(str(h.get("preserved_target_id",""))),str(h.get("preserved_target_kind",""))))
