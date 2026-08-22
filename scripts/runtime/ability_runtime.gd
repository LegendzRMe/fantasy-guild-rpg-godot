extends "res://scripts/runtime/vitalist_runtime.gd"

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
	var protector_trait_input:bool=str(h.get("class",""))=="Protector" and slot==4 and ProtectorSystem.has_talent(h,"protector_l30_1")
	var sentinel_trait_input:bool=str(h.get("class",""))=="Sentinel" and slot==4
	var druid_trait_input:bool=str(h.get("class",""))=="Druid" and slot==4
	var warrior_trait_input:bool=str(h.get("class",""))=="Warrior" and slot==4 and WarriorSystem.has_talent(h,"warrior_l21_3")
	var death_knight_trait_input:bool=str(h.get("class",""))=="Death Knight" and slot==4
	var beastmaster_trait_input:bool=str(h.get("class",""))=="Beastmaster" and slot==4
	var monk_trait_input:bool=str(h.get("class",""))=="Monk" and slot==4
	var paladin_trait_input:bool=str(h.get("class",""))=="Paladin" and slot==4
	var crusader_trait_input:bool=str(h.get("class",""))=="Crusader" and slot==4
	var vanguard_trait_input:bool=str(h.get("class",""))=="Vanguard" and slot==4
	var vitalist_trait_input:bool=str(h.get("class",""))=="Vitalist" and slot==4
	if not protector_trait_input and not sentinel_trait_input and not druid_trait_input and not warrior_trait_input and not death_knight_trait_input and not beastmaster_trait_input and not monk_trait_input and not paladin_trait_input and not crusader_trait_input and not vanguard_trait_input and not vitalist_trait_input and not TalentSystem.ability_is_unlocked(int(state.heroes[battle_hero_indices[selected]].level),slot):return
	var ability_enemy_target:int=combat_enemy_target()
	if slot>=4 and h["class"] not in ["Protector","Sentinel","Druid","Warrior","Death Knight","Beastmaster","Monk","Paladin","Crusader","Vanguard","Vitalist"]:return
	if h.hp<=0:return
	if not item_repeat:
		if h["class"]=="Protector" and slot==0 and not h.get("protector_runtime",{}).get("q_sequence",{}).is_empty():pass
		elif h["class"]=="Protector" and slot==2 and AbilitySlotSystem.can_activate(h.protector_runtime.smite_slot):pass
		elif h["class"]=="Protector" and slot==4 and protector_trait_input:pass
		elif h["class"]=="Sentinel" and slot==4 and sentinel_trait_input:pass
		elif h["class"]=="Druid" and slot==4 and druid_trait_input:pass
		elif h["class"]=="Warrior" and slot==4 and warrior_trait_input:pass
		elif h["class"]=="Death Knight" and slot==4 and death_knight_trait_input:pass
		elif h["class"]=="Beastmaster" and slot==4 and beastmaster_trait_input:pass
		elif h["class"]=="Monk" and slot==4 and monk_trait_input:pass
		elif h["class"]=="Paladin" and slot==4 and paladin_trait_input:pass
		elif h["class"]=="Crusader" and slot==4 and crusader_trait_input:pass
		elif h["class"]=="Vanguard" and slot==4 and vanguard_trait_input:return
		elif h["class"]=="Vitalist" and slot==4 and vitalist_trait_input:pass
		elif h["class"]=="Monk" and slot in [1,2]:return
		elif h["class"]=="Monk" and slot==0:
			if not AbilitySlotSystem.can_activate(h.monk_runtime.q_slot):return
		elif h["class"]=="Warrior" and slot==3 and WarriorSystem.specialization(h)=="warrior_l12_r3":pass
		elif slot==0 and hero_has_passive(h,"twin_incantation"):
			if int(h.get("q_charges",0))<=0:return
		elif h["class"]=="Mage" and slot==1 and MageSystem.trait_is_armed(h):pass
		elif h["class"]=="Mage" and slot==3 and MageSystem.has_talent(h,"mage_l27_r1") and not h.mage_runtime.phoenix.is_empty() and int(h.mage_runtime.phoenix.get("reposition_charges",0))>0:pass
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
	if h["class"]=="Ranger":
		cast_ranger_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Mage":
		cast_mage_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Warlock":
		cast_warlock_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Rogue":
		cast_rogue_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Slayer":
		cast_slayer_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Priest":
		cast_priest_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Shaman":
		cast_shaman_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Templar":
		cast_templar_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Protector":
		cast_protector_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Sentinel":
		cast_sentinel_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Huntsman":
		cast_huntsman_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Druid":
		cast_druid_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Warrior":
		cast_warrior_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Death Knight":
		cast_death_knight_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Beastmaster":
		cast_beastmaster_ability(slot,cast_position,item_repeat)
		return
	if h["class"]=="Monk":
		cast_monk_ability(slot,cast_position)
		return
	if h["class"]=="Paladin":
		cast_paladin_ability(slot,cast_position)
		return
	if h["class"]=="Crusader":
		cast_crusader_ability(slot,cast_position)
		return
	if h["class"]=="Vanguard":
		cast_vanguard_ability(slot,cast_position)
		return
	if h["class"]=="Vitalist":
		cast_vitalist_ability(slot,cast_position)
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
	var display_name:=str(ABILITIES[h["class"]][slot]);var effect_color:Color=CLASSES[h["class"]].color
	if slot<3 and selected<battle_hero_indices.size():
		var saved_hero:Dictionary=state.heroes[battle_hero_indices[selected]];var ability_id:="%s:%s"%[str(saved_hero.class_id),["q","w","e"][slot]];var rune_presentation:Dictionary=ProfessionSystem.ability_presentation(state,str(saved_hero.hero_id),ability_id,display_name);display_name=str(rune_presentation.display_name);if str(rune_presentation.get("effect_tint",""))!="":effect_color=Color(str(rune_presentation.effect_tint))
	add_effect("heroic" if slot==3 else "cast",h.pos,h.pos,("ECHO: " if item_repeat else "")+display_name,effect_color)
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
	if not item_repeat and slot==2 and hero_has_passive(h,"twin_incantation") and int(h.q_charges)<2:
		h.q_charges=int(h.q_charges)+1
		if not h.q_charge_timers.is_empty():h.q_charge_timers.remove_at(0)
		h.ability_cds[0]=0.0;item_feedback("Q Charge Restored",h.pos,Color("b8d5ff"))
	if not item_repeat and slot<3 and hero_has_passive(h,"borrowed_time") and bool(h.get("borrowed_time_armed",false)):
		h.borrowed_time_armed=false;h.borrowed_time_timer=0.0
		h.pending_repeats.append({"remaining":0.4,"slot":slot,"position":resolved_point,"enemy_target":ability_enemy_target,"assigned_target":int(h.target),"ally_target":int(h.heal_target)})
		item_feedback("Borrowed Time",h.pos,Color("b8d5ff"))
	CombatRulesV1.restore_preserved_command(h,target_is_valid_for(h,unit_by_combat_id(str(h.get("preserved_target_id",""))),str(h.get("preserved_target_kind",""))))
