extends "res://scripts/runtime/combat_input_runtime.gd"

func _process(delta:float) -> void:
	update_meta_systems(delta)
	if not prepare_combat_frame(delta):return
	advance_encounter_frame(delta)
	update_combat_runtime_layers(delta)
	if update_combat_heroes(delta):return
	if update_combat_enemies(delta):return
	if not testing_zone_active and ashwood_combat_complete():finish_battle(true)
	queue_redraw()

func update_meta_systems(delta:float) -> void:
	var advanced_game_minutes:=GameClockSystem.advance(state,delta,paused if screen=="combat" else false)
	var recruitment_events:Array=RecruitmentSystem.advance(state,advanced_game_minutes)
	var tavern_events:Array=TavernFacilitySystem.advance(state,advanced_game_minutes)
	var tavern_management_events:Array=TavernManagementSystem.advance(state,advanced_game_minutes,screen!="combat")
	if advanced_game_minutes>0.0:mark_save_dirty()
	persistence.advance(delta)
	if screen=="tavern" and advanced_game_minutes>0.0:
		tavern_ui_refresh_elapsed+=delta
		if tavern_ui_refresh_elapsed>=0.5 and tavern_refresh_is_safe():tavern_ui_refresh_elapsed=0.0;call_deferred("show_tavern")
	else:tavern_ui_refresh_elapsed=0.0
	if not recruitment_events.is_empty() or not tavern_events.is_empty() or not tavern_management_events.is_empty() or persistence.should_flush(SAVE_DEBOUNCE_SECONDS):
		flush_pending_save()
		if screen=="tavern" and tavern_refresh_is_safe() and (not recruitment_events.is_empty() or not tavern_events.is_empty() or not tavern_management_events.is_empty()):call_deferred("show_tavern")
	var completed_profession_orders:Array=ProfessionSystem.process_orders(state,delta)
	if not completed_profession_orders.is_empty():save_game();if screen in ["crafting","roster"] or (screen=="tavern" and tavern_refresh_is_safe()):call_deferred("show_crafting" if screen=="crafting" else "show_roster" if screen=="roster" else "show_tavern")
	if screen=="roster":update_roster_party_press(delta)
	if screen=="vault" and vault_press_active:
		vault_press_time+=delta
		if not vault_dragging and vault_press_time>=InventorySystem.LONG_PRESS_DURATION:begin_vault_drag()
		if vault_dragging:update_vault_drag_visual()
	if toast_time>0: toast_time-=delta; queue_redraw()

func prepare_combat_frame(delta:float) -> bool:
	update_objective_notice(delta)
	if victory_sequence:
		update_victory(delta)
		return false
	if screen!="combat" or battle_over or paused:return false
	if tutorial_active:
		update_tutorial(delta)
		if tutorial_step==8:return false
		recover_tutorial_state()
	return true

func advance_encounter_frame(delta:float) -> void:
	battle_time+=delta
	spawn_timer=max(0,spawn_timer-delta); wave_break=max(0,wave_break-delta)
	if testing_zone_active and testing_zone_mode=="endless":update_testing_endless(delta)
	if not tutorial_active and not testing_zone_active and wave_index==0 and wave_break<=0: begin_next_wave()
	if not tutorial_active and not testing_zone_active and wave_spawn_remaining>0 and spawn_timer<=0: spawn_wave_enemy()
	if not tutorial_active and not testing_zone_active and wave_spawn_remaining==0 and wave_index<total_waves and enemies.size()>0 and enemies.all(func(foe):return foe.hp<=0):
		if not waiting_wave: waiting_wave=true; wave_break=2.2
		elif wave_break<=0: waiting_wave=false; begin_next_wave()
	if not tutorial_active and current_ashwood_encounter!="":update_ashwood_objective(delta)
	if current_ashwood_encounter!="":update_objective_banner(delta)
	for fx in effects: fx.life-=delta
	effects=effects.filter(func(fx):return fx.life>0)

func update_combat_runtime_layers(delta:float) -> void:
	update_combat_projectiles(delta)
	update_guardian_runtime(delta)
	update_cleric_runtime(delta)
	update_ranger_runtime(delta)
	update_mage_runtime(delta)
	update_warlock_runtime(delta)
	update_rogue_runtime(delta)
	update_slayer_runtime(delta)
	update_priest_runtime(delta)
	update_shaman_runtime(delta)
	update_templar_runtime(delta)
	update_protector_runtime(delta)
	update_sentinel_runtime(delta)
	update_huntsman_runtime(delta)
	update_druid_runtime(delta)
	update_warrior_runtime(delta)
	update_death_knight_runtime(delta)
	for timed_hero in heroes:update_timed_combat_effects(timed_hero,delta)
	for timed_enemy in enemies:update_timed_combat_effects(timed_enemy,delta)

func update_combat_heroes(delta:float) -> bool:
	for i in heroes.size():
		var h=heroes[i]
		h.last_hit=max(0,h.last_hit-delta)
		for slot in 5:
			var cooldown_rate:=1.0
			if str(h.get("class",""))=="Cleric" and not h.get("cleric_runtime",{}).is_empty() and slot<3:cooldown_rate=ClericSystem.w_cooldown_rate(h) if slot==1 else ClericSystem.qwe_cooldown_rate(h)
			elif str(h.get("class",""))=="Ranger" and not h.get("ranger_runtime",{}).is_empty() and slot==1 and RangerSystem.has_talent(h,"ranger_l24_1") and int(h.ranger_runtime.hatred)>=int(RangerData.VALUES.hatred_max):cooldown_rate=1.5
			elif str(h.get("class",""))=="Warlock" and not h.get("warlock_runtime",{}).is_empty() and slot==1 and WarlockSystem.has_talent(h,"warlock_l12_1") and not h.get("active_channel",{}).is_empty():cooldown_rate=2.0
			elif str(h.get("class",""))=="Priest" and not h.get("priest_runtime",{}).is_empty() and slot==2 and PriestSystem.has_talent(h,"priest_l21_2") and int(h.priest_runtime.push_stacks)>=int(PriestData.VALUES.push_max):cooldown_rate=float(PriestData.VALUES.push_e_rate)
			elif str(h.get("class",""))=="Shaman" and slot==0:cooldown_rate=0.0
			if slot<3:cooldown_rate*=DruidSystem.cooldown_rate_from_innervate(h,heroes.filter(func(unit):return str(unit.get("class",""))=="Druid"),slot)
			h.ability_cds[slot]=max(0,h.ability_cds[slot]-delta*cooldown_rate)
		if str(h.get("class",""))=="Warlock" and not h.get("warlock_runtime",{}).is_empty():h.ability_cds[4]=float(h.warlock_runtime.life_tap_lockout)
		if str(h.get("class",""))=="Templar" and not h.get("templar_runtime",{}).is_empty():h.ability_cds[4]=float(h.templar_runtime.trait_cooldown)
		if str(h.get("class",""))=="Sentinel" and not h.get("sentinel_runtime",{}).is_empty():h.ability_cds[4]=float(h.sentinel_runtime.trueshot_cooldown) if SentinelSystem.has_talent(h,"sentinel_l30_2") and float(h.sentinel_runtime.d_cooldown)>0.0 else float(h.sentinel_runtime.d_cooldown)
		if str(h.get("class",""))=="Huntsman" and not h.get("huntsman_runtime",{}).is_empty():h.basic_attack_interval=float(h.base_basic_action_interval)*HuntsmanSystem.basic_attack_interval_multiplier(h)
		if str(h.get("class",""))=="Druid" and not h.get("druid_runtime",{}).is_empty():var d_ui:=AbilitySlotSystem.ui_state(h.druid_runtime.d_slot);h.ability_cds[4]=float(d_ui.recharge) if int(d_ui.charges)<=0 else 0.0
		if str(h.get("class",""))=="Warrior" and not h.get("warrior_runtime",{}).is_empty():h.basic_attack_interval=WarriorSystem.attack_interval(h)
		if h.hp>0:h.hp=minf(float(h.max_hp),float(h.hp)+float(h.get("health_regeneration",0.0))*delta);update_item_runtime(h,delta)
		update_shared_hero(h,delta)
	if not heroes.is_empty() and heroes.all(func(hero):return hero.hp<=0):
		finish_battle(false)
		return true
	return false

func update_combat_enemies(delta:float) -> bool:
	for enemy_index in enemies.size():
		var e=enemies[enemy_index]
		if testing_zone_active and "training" in e.get("combat_tags",[]):
			if e.hp<=0:

				e.respawn_timer=float(e.get("respawn_timer",0.0))+delta
				if e.respawn_timer>=TESTING_DUMMY_RESPAWN_TIME:
					e.hp=e.max_hp;e.respawn_timer=0.0;e.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;e.cooldown=1.0;e.telegraph=0.0;e.special="";e.threat={};e.target=-1;e.revealed=false
				continue
			e.respawn_timer=0.0;e.seconds_since_damage=float(e.get("seconds_since_damage",0.0))+delta
			if e.seconds_since_damage>=TESTING_DUMMY_REGEN_DELAY and e.hp<e.max_hp:e.hp=min(e.max_hp,e.hp+e.max_hp*TESTING_DUMMY_REGEN_RATE*delta)
		if e.hp<=0:
			if not e.rewarded:
				e.rewarded=true
				if current_ashwood_encounter=="":
					var kill_gold=12 if bool(e.get("boss",false)) else 5 if e.type=="Brute" else 2;state.gold+=kill_gold;battle_gold_earned+=kill_gold;add_effect("cast",e.pos,e.pos,"● +%d"%kill_gold,C_GOLD);mark_save_dirty()
				elif str(e.type).begins_with("Controlled "):
					add_effect("cast",e.pos,e.pos,"SUBDUED",C_GREEN)
			continue
			if e.type=="Dummy":continue
			if bool(e.get("passive_test_enemy",false)):continue
		if CombatSystem.is_stunned(e):continue
		if CombatSystem.is_feared(e):
			e.telegraph=0.0;e.special="";e.target=-1
			var fear_origin:=Vector2(e.get("fear_origin",e.pos-Vector2.RIGHT));var fear_direction:=fear_origin.direction_to(e.pos)
			if fear_direction==Vector2.ZERO:fear_direction=Vector2.RIGHT
			e.facing_direction=fear_direction;e.pos=CombatGeometry.move_toward_safe(e.pos,e.pos+fear_direction*100.0,float(e.movement_speed)*delta,42.0,combat_blockers);continue
		if e.type=="Defense Dummy" and not testing_dummy_attacks_enabled:continue
		e.cooldown=max(0,e.cooldown-delta);e.taunt_time=max(0.0,float(e.get("taunt_time",0.0))-delta)
		if e.type=="Shaman" and e.cooldown<=0 and not CombatSystem.is_silenced(e):
			var wounded=-1; var lowest=1.0
			for ally_i in enemies.size():
				if enemies[ally_i].hp>0 and enemies[ally_i].hp/enemies[ally_i].max_hp<lowest: lowest=enemies[ally_i].hp/enemies[ally_i].max_hp; wounded=ally_i
			if wounded>=0 and lowest<.8:var shaman_heal:=deal_healing(e,enemies[wounded],30,"basic_ability","shaman_heal");add_effect("heal",e.pos,enemies[wounded].pos,"+%d"%int(shaman_heal.effective_amount),C_GREEN);e.cooldown=e.basic_attack_interval;continue
		var ti=nearest_hero_in_range(e.pos,e.range) if e.type=="Defense Dummy" else preferred_enemy_target(e)
		if e.type=="Defense Dummy" and ti<0:continue
		if tutorial_active and tutorial_step==6 and e.has("tutorial_opening_target"):
			var opening_target=int(e.tutorial_opening_target)
			if opening_target<heroes.size() and heroes[opening_target].hp>0 and (heroes.is_empty() or heroes[0].target!=enemy_index):ti=opening_target
			else:e.erase("tutorial_opening_target")
		if ti<0 and ti!=OBJECTIVE_THREAT_TARGET:
			finish_battle(false)
			return true
		var targets_objective:bool=ti==OBJECTIVE_THREAT_TARGET
		var target_unit= null if targets_objective else enemy_target_entity(e,ti)
		var target_pos:Vector2=objective_actor_pos if targets_objective else Vector2(target_unit.pos)
		e.target=ti; var dist=e.pos.distance_to(target_pos)
		if bool(e.get("boss",false)) and not e.summoned and e.hp<e.max_hp*.55:
			e.summoned=true;spawn_enemy(e.pos+Vector2(-70,-60),"Swift");enemies[-1].summoned_unit=true;spawn_enemy(e.pos+Vector2(-70,60),"Raider");enemies[-1].summoned_unit=true;add_effect("cast",e.pos,e.pos,"PHASE TWO",C_RED)
		if bool(e.get("boss",false)) and e.hp<e.max_hp*.25: e.enraged=true
		if bool(e.get("boss",false)) and e.cooldown<=0 and e.telegraph<=0:
			e.special=["cleave","charge","danger"][e.special_index%3]; e.special_index+=1; e.telegraph=1.5; e.danger_pos=target_pos
		if e.telegraph>0:
			e.telegraph-=delta
			if e.telegraph<=0:
				if e.special=="basic":
					if targets_objective and objective_is_threat_target():
						damage_battle_objective(float(e.damage),e.pos)
					elif target_unit!=null and float(target_unit.hp)>0.0:
						if bool(e.get("ranged",false)) and str(e.get("basic_attack_damage_type","physical"))=="physical":spawn_basic_projectile(e,target_unit,float(e.damage),str(e.basic_attack_damage_type),"enemy_basic_attack")
						else:
							if CombatSystem.is_blinded(e):record_blind_miss(e,target_unit)
							else:var basic_result:=deal_damage(e,target_unit,e.damage,"basic_attack",e.basic_attack_damage_type,"enemy_basic_attack");target_unit["last_hit"]=3.0;apply_hit_nudge(e,target_unit);add_effect("hit",e.pos,target_unit.pos,"-%d"%int(basic_result.resolved_damage),C_RED)
				elif e.special=="charge":e.pos=CombatGeometry.move_toward_safe(e.pos,e.danger_pos,220.0,float(e.get("combat_radius",28.0)),combat_blockers);for hero_charge in heroes+player_combat_summons():if hero_charge.hp>0 and hero_charge.pos.distance_to(e.pos)<65:var charge_result:=deal_damage(e,hero_charge,e.damage*1.25,"basic_ability",e.basic_attack_damage_type,"boss_charge");add_effect("hit",e.pos,hero_charge.pos,"-%d"%int(charge_result.resolved_damage),C_RED)
				else:
					var impact=e.danger_pos if e.special=="danger" else e.pos; var radius=78.0 if e.special=="danger" else 115.0
					for struck_hero in heroes+player_combat_summons():
						if struck_hero.hp>0 and struck_hero.pos.distance_to(impact)<radius:var area_result:=deal_damage(e,struck_hero,e.damage*1.4,"basic_ability",e.basic_attack_damage_type,"boss_area");add_effect("hit",impact,struck_hero.pos,"-%d"%int(area_result.resolved_damage),C_RED)
				var attack_speed_reduction:=clampf(CombatSystem.control_amount(e,"attack_speed"),0.0,0.9)
				e.cooldown=e.basic_attack_interval*(.68 if e.enraged else 1.0)/maxf(0.1,1.0-attack_speed_reduction)
		elif dist>e.range:
			var enemy_speed=float(e.movement_speed)*(1.0-CombatSystem.control_amount(e,"slow"));e.facing_direction=e.pos.direction_to(target_pos);e.pos=CombatGeometry.move_toward_safe(e.pos,target_pos,enemy_speed*delta,float(e.get("combat_radius",28.0)),combat_blockers)
		elif e.cooldown<=0:
			e.facing_direction=e.pos.direction_to(target_pos)
			e.special="basic"; e.telegraph=.48; e.danger_pos=target_pos
	return false

func update_testing_endless(delta:float) -> void:
	for enemy_index in range(enemies.size()-1,-1,-1):
		var enemy:Dictionary=enemies[enemy_index]
		if not bool(enemy.get("testing_endless_enemy",false)) or enemy.hp>0 or not enemy.rewarded:continue
		enemy.defeated_clear_time=float(enemy.get("defeated_clear_time",0.0))+delta
		if enemy.defeated_clear_time>=TESTING_ENDLESS_DEFEATED_CLEAR_TIME:
			remove_testing_endless_enemy_at(enemy_index);testing_endless_defeated+=1
	var living_count:int=enemies.filter(func(enemy):return enemy.hp>0 and bool(enemy.get("testing_endless_enemy",false))).size()
	testing_endless_spawn_timer=maxf(0.0,testing_endless_spawn_timer-delta)
	if living_count<TESTING_ENDLESS_ACTIVE_LIMIT and testing_endless_spawn_timer<=0.0:
		spawn_testing_endless_enemy();testing_endless_spawn_timer=TESTING_ENDLESS_SPAWN_INTERVAL

func remap_enemy_index_after_removal(value:int,removed_index:int)->int:
	return -1 if value==removed_index else value-1 if value>removed_index else value

func remove_testing_endless_enemy_at(enemy_index:int)->void:
	if enemy_index<0 or enemy_index>=enemies.size():return
	for hero in heroes:
		hero.target=remap_enemy_index_after_removal(int(hero.get("target",-1)),enemy_index)
		for repeat in hero.get("pending_repeats",[]):
			if repeat.has("enemy_target"):repeat.enemy_target=remap_enemy_index_after_removal(int(repeat.enemy_target),enemy_index)
	focused_enemy_index=remap_enemy_index_after_removal(focused_enemy_index,enemy_index)
	if drag_target_type=="enemy":
		if drag_target_index==enemy_index:dragging_hero=false;drag_target_type="ground";drag_target_index=-1
		elif drag_target_index>enemy_index:drag_target_index-=1
	enemies.remove_at(enemy_index)
