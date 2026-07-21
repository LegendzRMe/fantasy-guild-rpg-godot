extends "res://scripts/runtime/combat_input_runtime.gd"

func _process(delta:float) -> void:
	if screen=="roster":update_roster_party_press(delta)
	if screen=="vault" and vault_press_active:
		vault_press_time+=delta
		if not vault_dragging and vault_press_time>=InventorySystem.LONG_PRESS_DURATION:begin_vault_drag()
		if vault_dragging:update_vault_drag_visual()
	if toast_time>0: toast_time-=delta; queue_redraw()
	update_objective_notice(delta)
	if victory_sequence: update_victory(delta); return
	if screen!="combat" or battle_over or paused: return
	if tutorial_active:
		update_tutorial(delta)
		if tutorial_step==8:return
		recover_tutorial_state()
	battle_time+=delta
	spawn_timer=max(0,spawn_timer-delta); wave_break=max(0,wave_break-delta)
	if not tutorial_active and not testing_zone_active and wave_index==0 and wave_break<=0: begin_next_wave()
	if not tutorial_active and not testing_zone_active and wave_spawn_remaining>0 and spawn_timer<=0: spawn_wave_enemy()
	if not tutorial_active and not testing_zone_active and wave_spawn_remaining==0 and wave_index<total_waves and enemies.size()>0 and enemies.all(func(foe):return foe.hp<=0):
		if not waiting_wave: waiting_wave=true; wave_break=2.2
		elif wave_break<=0: waiting_wave=false; begin_next_wave()
	if not tutorial_active and current_ashwood_encounter!="":update_ashwood_objective(delta)
	if current_ashwood_encounter!="":update_objective_banner(delta)
	for fx in effects: fx.life-=delta
	effects=effects.filter(func(fx):return fx.life>0)
	update_combat_projectiles(delta)
	update_guardian_runtime(delta)
	update_cleric_runtime(delta)
	for timed_hero in heroes:update_timed_combat_effects(timed_hero,delta)
	for timed_enemy in enemies:update_timed_combat_effects(timed_enemy,delta)
	for i in heroes.size():
		var h=heroes[i]
		h.last_hit=max(0,h.last_hit-delta)
		for slot in 5:
			var cooldown_rate:=1.0
			if str(h.get("class",""))=="Cleric" and not h.get("cleric_runtime",{}).is_empty() and slot<3:cooldown_rate=ClericSystem.w_cooldown_rate(h) if slot==1 else ClericSystem.qwe_cooldown_rate(h)
			h.ability_cds[slot]=max(0,h.ability_cds[slot]-delta*cooldown_rate)
		if h.hp>0:update_item_runtime(h,delta)
		update_shared_hero(h,delta)
	if not heroes.is_empty() and heroes.all(func(hero):return hero.hp<=0):finish_battle(false);return
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
					var kill_gold=12 if bool(e.get("boss",false)) else 5 if e.type=="Brute" else 2;state.gold+=kill_gold;battle_gold_earned+=kill_gold;add_effect("cast",e.pos,e.pos,"â— +%d"%kill_gold,C_GOLD);save_game()
				elif str(e.type).begins_with("Controlled "):
					add_effect("cast",e.pos,e.pos,"SUBDUED",C_GREEN)
			continue
		if e.type=="Dummy":continue
		if bool(e.get("passive_test_enemy",false)):continue
		if CombatSystem.is_stunned(e):continue
		if e.type=="Defense Dummy" and not testing_dummy_attacks_enabled:continue
		e.cooldown=max(0,e.cooldown-delta);e.taunt_time=max(0.0,float(e.get("taunt_time",0.0))-delta)
		if e.type=="Shaman" and e.cooldown<=0:
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
		if ti<0 and ti!=OBJECTIVE_THREAT_TARGET: finish_battle(false); return
		var targets_objective:bool=ti==OBJECTIVE_THREAT_TARGET
		var target_pos:Vector2=objective_actor_pos if targets_objective else heroes[ti].pos
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
					elif ti<heroes.size() and heroes[ti].hp>0:
						if bool(e.get("ranged",false)) and str(e.get("basic_attack_damage_type","physical"))=="physical":spawn_basic_projectile(e,heroes[ti],float(e.damage),str(e.basic_attack_damage_type),"enemy_basic_attack")
						else:
							if CombatSystem.is_blinded(e):record_blind_miss(e,heroes[ti])
							else:var basic_result:=deal_damage(e,heroes[ti],e.damage,"basic_attack",e.basic_attack_damage_type,"enemy_basic_attack");heroes[ti].last_hit=3.0;apply_hit_nudge(e,heroes[ti]);add_effect("hit",e.pos,heroes[ti].pos,"-%d"%int(basic_result.health_damage+basic_result.shield_damage),C_RED)
				elif e.special=="charge":e.pos=e.pos.move_toward(e.danger_pos,220);for hero_charge in heroes:if hero_charge.hp>0 and hero_charge.pos.distance_to(e.pos)<65:var charge_result:=deal_damage(e,hero_charge,e.damage*1.25,"basic_ability",e.basic_attack_damage_type,"boss_charge");add_effect("hit",e.pos,hero_charge.pos,"-%d"%int(charge_result.health_damage+charge_result.shield_damage),C_RED)
				else:
					var impact=e.danger_pos if e.special=="danger" else e.pos; var radius=78.0 if e.special=="danger" else 115.0
					for struck_hero in heroes:
						if struck_hero.hp>0 and struck_hero.pos.distance_to(impact)<radius:var area_result:=deal_damage(e,struck_hero,e.damage*1.4,"basic_ability",e.basic_attack_damage_type,"boss_area");add_effect("hit",impact,struck_hero.pos,"-%d"%int(area_result.health_damage+area_result.shield_damage),C_RED)
				var attack_speed_reduction:=clampf(CombatSystem.control_amount(e,"attack_speed"),0.0,0.9)
				e.cooldown=e.basic_attack_interval*(.68 if e.enraged else 1.0)/maxf(0.1,1.0-attack_speed_reduction)
		elif dist>e.range:
			var enemy_speed=float(e.movement_speed)*(1.0-CombatSystem.control_amount(e,"slow"));e.facing_direction=e.pos.direction_to(target_pos);e.pos=e.pos.move_toward(target_pos,enemy_speed*delta)
		elif e.cooldown<=0:
			e.facing_direction=e.pos.direction_to(target_pos)
			e.special="basic"; e.telegraph=.48; e.danger_pos=target_pos
	if not testing_zone_active and ashwood_combat_complete():finish_battle(true)
	queue_redraw()
