extends "res://scripts/runtime/app_shell.gd"

func battle_formation_position(slot_index:int) -> Vector2:
	if slot_index>=4:
		var raid_positions:=[Vector2(205,160),Vector2(105,210),Vector2(205,285),Vector2(105,335),Vector2(205,410),Vector2(105,460),Vector2(205,535),Vector2(105,585)]
		return raid_positions[clampi(slot_index,0,raid_positions.size()-1)]
	var diamond_positions:=[Vector2(210,320),Vector2(145,215),Vector2(145,425),Vector2(90,320)]
	return diamond_positions[clampi(slot_index,0,diamond_positions.size()-1)]

func start_battle(id:int,node:int=0,party_override:Array=[],profession_conflict_resolved:bool=false,party_limit:int=4) -> void:
	var requested_party:Array=state.selected_team if party_override.is_empty() else party_override
	var validated_party:Array=[]
	if party_limit<=4:validated_party=TeamManager.sanitize_team(requested_party,state.heroes)
	else:
		for raw_index in requested_party:
			var hero_index:=int(raw_index)
			if hero_index>=0 and hero_index<state.heroes.size() and hero_index not in validated_party:validated_party.append(hero_index)
			if validated_party.size()>=party_limit:break
	if validated_party.is_empty():
		flash("Choose at least one hero before starting battle.")
		return
	var unavailable:Array=[]
	for hero_index in validated_party:
		var hero_id:=str(state.heroes[int(hero_index)].get("hero_id",""));var availability:=TavernFacilitySystem.member_status(state,hero_id)
		if not bool(availability.available):unavailable.append("%s (%s)"%[str(state.heroes[int(hero_index)].display_name),str(availability.label)])
	if not unavailable.is_empty():flash("Unavailable: "+", ".join(unavailable));return
	if not profession_conflict_resolved:
		var conflicting_orders:Array=[]
		for hero_index in validated_party:
			var order_id:=str(state.heroes[int(hero_index)].profession_progress.get("current_profession_order_id",""))
			if order_id!="":conflicting_orders.append(order_id)
		if not conflicting_orders.is_empty():
			var dialog:=ConfirmationDialog.new();dialog.title="ACTIVE PROFESSION ORDERS";dialog.dialog_text="One or more selected members are working on profession orders.\n\nPause their orders and begin the mission, or cancel the orders and return their reserved inputs. Nothing will be cancelled silently.";dialog.ok_button_text="Pause Orders and Begin";dialog.add_button("Cancel Orders and Begin",false,"cancel_orders")
			dialog.confirmed.connect(func():for order_id in conflicting_orders:ProfessionSystem.pause_profession_order(state,str(order_id),true);save_game();start_battle(id,node,party_override,true,party_limit))
			dialog.custom_action.connect(func(action):if action=="cancel_orders":for order_id in conflicting_orders:ProfessionSystem.cancel_profession_order(state,str(order_id));save_game();dialog.hide();start_battle(id,node,party_override,true,party_limit))
			ui.add_child(dialog);dialog.popup_centered(Vector2i(650,330));return
	if party_override.is_empty():
		state.selected_team=validated_party.duplicate()
		if current_team_slot<0:state.active_team=validated_party.duplicate()
	testing_zone_active=false
	testing_zone_mode="range"
	testing_endless_spawn_timer=0.0;testing_endless_spawn_count=0;testing_endless_defeated=0
	current_ashwood_encounter=""
	current_campaign_battle={}
	battle_objective={};objective_progress=0;objective_health=0;objective_max_health=0;objective_complete=true;objective_pressure_spawned=false;objective_notice="";objective_notice_time=0;objective_banner_time=0;objective_combat_intro="";rune_active=false;rune_timer=0;rune_charge=0;rune_radius=0
	dungeon_id=id; encounter_id=node; clear_all();combat_events.clear();item_feedback_feed.clear();battle_material_results.clear();combat_blockers.clear();combat_projectiles.clear();incapacitated_hero_ids.clear();next_enemy_combat_id=1;next_projectile_combat_id=1;debug_combat_overlay=CombatRulesV1.DEBUG_COMBAT_OVERLAY_ENABLED; ui.visible=false; combat_layer.visible=true; screen="combat"; battle_time=0; spawn_timer=0; battle_over=false; paused=false; selected=0;focused_enemy_index=-1; wave_index=0; total_waves=3+(1 if node>=3 else 0); wave_spawn_remaining=0; wave_break=.8; waiting_wave=false; battle_gold_earned=0
	battle_hero_indices=validated_party.slice(0,party_limit)
	var consumed_tavern_buff:=false
	for i in battle_hero_indices.size():
		var start_position:=battle_formation_position(i);var data=state.heroes[battle_hero_indices[i]];var equipped:=hero_equipped_items(data);var stable_hero_id:=str(data.get("hero_id",data.get("id",battle_hero_indices[i])));var rest_buff:=TavernFacilitySystem.consume_mission_buff(state,stable_hero_id)
		var meal_modifiers:={}
		for stat_id in ["health_multiplier","armor","movement_speed","basic_action_speed","damage_multiplier"]:
			if rest_buff.has(stat_id):meal_modifiers[stat_id]=rest_buff[stat_id]
		var runtime_stats:=hero_final_stats(data,[{"stat_modifiers":meal_modifiers}] if not meal_modifiers.is_empty() else []);var temporary_hp:=float(runtime_stats.health)*float(rest_buff.get("temporary_hp_percent",0.0));if not rest_buff.is_empty():consumed_tavern_buff=true
		heroes.append({"name":data.name,"class":data["class"],"hero_index":battle_hero_indices[i],"battle_index":i,"level":runtime_stats.level,"combat_affiliation":"player","independent":false,"pos":start_position,"dest":start_position,"facing_direction":Vector2.RIGHT,"stats":runtime_stats,"equipped_items":equipped,"active_effects":[],"passive_cooldowns":{},"hp":runtime_stats.health,"max_hp":runtime_stats.health,"temporary_hp":temporary_hp,"temporary_hp_max":temporary_hp,"was_defeated":false,"base_power":runtime_stats.power,"power":runtime_stats.power,"armor":runtime_stats.armor,"basic_action_type":runtime_stats.basic_action_type,"basic_action_coefficient":runtime_stats.basic_action_power_coefficient,"basic_action_power_ratio":runtime_stats.basic_action_amount/maxf(0.001,runtime_stats.power),"basic_action_amount":runtime_stats.basic_action_amount,"damage":runtime_stats.basic_action_amount,"basic_heal_amount":runtime_stats.basic_heal_amount,"range":runtime_stats.basic_action_range,"movement_speed":runtime_stats.movement_speed,"base_basic_action_interval":runtime_stats.basic_action_interval,"basic_attack_interval":runtime_stats.basic_action_interval,"basic_heal_interval":runtime_stats.basic_action_interval,"critical_chance":runtime_stats.critical_chance,"critical_damage":runtime_stats.critical_damage,"threat_modifier":runtime_stats.threat_modifier,"damage_multiplier":runtime_stats.damage_multiplier,"healing_multiplier":runtime_stats.healing_multiplier,"damage_taken_multiplier":runtime_stats.damage_taken_multiplier,"healing_taken_multiplier":runtime_stats.healing_taken_multiplier,"basic_attack_damage_type":runtime_stats.basic_action_damage_type,"target":-1,"heal_target":-1,"suppress_auto_target":false,"cooldown":0.0,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"shield":0.0,"shield_sources":[],"last_hit":0.0,"bloodletting_stacks":[],"thousand_cuts_count":0,"retribution_charges":[],"soul_furnace_stacks":0,"last_dawn_ready":true,"borrowed_time_timer":0.0,"borrowed_time_armed":false,"pending_repeats":[],"q_charges":2 if has_item_passive(equipped,"twin_incantation") else 1,"q_charge_timers":[]})
		heroes[-1]["tavern_meal"]=rest_buff.duplicate(true)
		heroes[-1]["chefs_touch_id"]=str(data.get("cooking_meal_state",{}).get("chefs_touch_id","")) if str(state.get("cooking",{}).get("special_guest_hero_id",""))==stable_hero_id else ""
		CombatRulesV1.initialize_unit(heroes[-1],"hero:%s"%stable_hero_id,"player")
		heroes[-1]["selected_talents"]=data.get("selected_talents",{}).duplicate(true)
		heroes[-1]["selected_heroic_id"]=str(data.get("selected_heroic_id",""))
		heroes[-1]["combat_radius"]=42.0
		if str(heroes[-1].get("class",""))=="Guardian":GuardianSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Cleric":ClericSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Ranger":RangerSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Mage":MageSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Warlock":WarlockSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Rogue":RogueSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Slayer":SlayerSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Priest":PriestSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Shaman":ShamanSystem.initialize_runtime(heroes[-1],is_testing_save(),data.get("talent_mastery",{}),ProgressionScopeSystem.new_encounter_id("battle"))
		elif str(heroes[-1].get("class",""))=="Templar":TemplarSystem.initialize_runtime(heroes[-1],is_testing_save(),ProgressionScopeSystem.new_encounter_id("battle"))
		elif str(heroes[-1].get("class",""))=="Protector":ProtectorSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Sentinel":SentinelSystem.initialize_runtime(heroes[-1],is_testing_save(),ProgressionScopeSystem.new_encounter_id("battle"))
	if consumed_tavern_buff:save_game()
	queue_redraw()

func start_warlock_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Warlock")
	if test_party.is_empty():flash("Warlock fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party)
	testing_zone_active=true;testing_zone_mode="warlock_range"
	for hero in heroes:
		if str(hero.get("class",""))=="Warlock":hero.warlock_runtime.telemetry_enabled=true
	testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	spawn_enemy(Vector2(610,145),"Dummy");enemies[-1]["passive_test_enemy"]=true
	spawn_enemy(Vector2(760,145),"Dummy");enemies[-1]["passive_test_enemy"]=true
	spawn_enemy(Vector2(920,260),"Defense Dummy")
	spawn_enemy(Vector2(720,510),"Boss");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["control_profile"]={"fear_multiplier":0.0,"silence_multiplier":0.0,"slow_multiplier":0.5}
	combat_blockers.append(CombatGeometry.create_blocker("blocker:warlock_pillar",Rect2(650,275,72,150)))
	for enemy in enemies:
		enemy.rewarded=true;enemy["seconds_since_damage"]=TESTING_DUMMY_REGEN_DELAY;enemy["respawn_timer"]=0.0
		if enemy.type in ["Dummy","Defense Dummy"]:enemy.hp=5000.0;enemy.max_hp=5000.0
	queue_redraw()

func start_rogue_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Rogue")
	if test_party.is_empty():flash("Rogue fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="rogue_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	for hero in heroes:
		if str(hero.get("class",""))=="Rogue":hero.rogue_runtime.telemetry_enabled=true
	# Ordinary cluster for Blade Flurry, Fatal Finesse, and isolation checks.
	for position in [Vector2(520,145),Vector2(610,145),Vector2(565,220),Vector2(655,220)]:spawn_enemy(position,"Dummy");enemies[-1]["passive_test_enemy"]=true
	spawn_enemy(Vector2(790,145),"Defense Dummy");enemies[-1]["passive_test_enemy"]=true;enemies[-1].armor=30.0;enemies[-1].combat_tags.append("armored")
	spawn_enemy(Vector2(930,145),"Brute");enemies[-1]["passive_test_enemy"]=true;enemies[-1].combat_tags.append("armored")
	# Detector and non-detector Bosses expose separate authored profiles.
	spawn_enemy(Vector2(1050,225),"Boss");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["detection_profile"]={"detect_stealthed":true,"detect_invisible":true,"detection_radius":210.0};enemies[-1]["control_profile"]={"stun_multiplier":0.25,"blind_immune":true,"silence_multiplier":0.5};enemies[-1].combat_tags.append("detector")
	spawn_enemy(Vector2(1040,475),"Boss");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["detection_profile"]={};enemies[-1]["control_profile"]={"stun_multiplier":0.0,"blind_immune":true,"silence_multiplier":1.0};enemies[-1].combat_tags.append("non_detector")
	# Healing, summon, and non-qualifying fixtures for Strangle and Fatal Finesse.
	spawn_enemy(Vector2(760,500),"Shaman");enemies[-1]["test_fixture"]="external_healer"
	spawn_enemy(Vector2(850,500),"Raider");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["test_fixture"]="healable_target"
	spawn_enemy(Vector2(650,500),"Brute");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["test_fixture"]="self_healer";enemies[-1]["self_heal_test"]=true
	spawn_enemy(Vector2(455,500),"Swift");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["summoned_unit"]=true
	spawn_enemy(Vector2(365,500),"Dummy");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["object"]=true;enemies[-1].combat_tags.append("temporary")
	combat_blockers.append(CombatGeometry.create_blocker("blocker:rogue_wall",Rect2(700,280,70,135)))
	for enemy in enemies:
		enemy.rewarded=true;enemy["seconds_since_damage"]=TESTING_DUMMY_REGEN_DELAY;enemy["respawn_timer"]=0.0;enemy.hp=6000.0;enemy.max_hp=6000.0
	queue_redraw()

func start_slayer_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Slayer")
	if test_party.is_empty():flash("Slayer fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="slayer_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	for hero in heroes:
		if str(hero.get("class",""))=="Slayer":hero.slayer_runtime.telemetry_enabled=true
	# Clusters cover Sweeping Strike, Immolation, Unbound, Blades, and Evasion.
	for position in [Vector2(500,145),Vector2(590,145),Vector2(545,225),Vector2(650,225)]:spawn_enemy(position,"Dummy");enemies[-1].passive_test_enemy=true
	spawn_enemy(Vector2(800,145),"Defense Dummy");enemies[-1].passive_test_enemy=true;enemies[-1].armor=35.0;enemies[-1].combat_tags.append("armored")
	spawn_enemy(Vector2(965,145),"Boss");enemies[-1].passive_test_enemy=true;enemies[-1].control_profile={"stun_multiplier":0.25,"slow_multiplier":0.5}
	spawn_enemy(Vector2(1010,430),"Boss");enemies[-1].passive_test_enemy=true;enemies[-1].hp*=0.20;enemies[-1].combat_tags.append("execute_fixture")
	spawn_enemy(Vector2(790,500),"Swift");enemies[-1].passive_test_enemy=true;enemies[-1].summoned_unit=true
	spawn_enemy(Vector2(620,500),"Dummy");enemies[-1].passive_test_enemy=true;enemies[-1].object=true;enemies[-1].combat_tags.append("temporary")
	combat_blockers.append(CombatGeometry.create_blocker("blocker:slayer_wall",Rect2(700,275,72,145)))
	for enemy in enemies:
		enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,6500.0);enemy.max_hp=enemy.hp
	queue_redraw()

func start_testing_zone() -> void:
	var test_party:Array=selected_party_indices()
	start_battle(0,-1,test_party)
	testing_zone_active=true
	testing_zone_mode="range"
	for hero in heroes:
		if str(hero.get("class",""))=="Guardian":hero.guardian_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Cleric":hero.cleric_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Ranger":hero.ranger_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Mage":hero.mage_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Warlock":hero.warlock_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Priest":hero.priest_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Shaman":hero.shaman_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Templar":hero.templar_runtime.telemetry_enabled=true
	testing_dummy_attacks_enabled=true
	total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	spawn_enemy(Vector2(650,120),"Dummy");enemies[-1]["passive_test_enemy"]=true
	spawn_enemy(Vector2(610,525),"Raider")
	spawn_enemy(Vector2(720,525),"Archer")
	spawn_enemy(Vector2(665,555),"Dummy")
	spawn_enemy(Vector2(1050,170),"Boss");enemies[-1]["passive_test_enemy"]=true;enemies[-1].max_hp*=1.5;enemies[-1].hp=enemies[-1].max_hp;enemies[-1]["percent_damage_health_basis"]=enemies[-1].max_hp;enemies[-1].combat_tags.append("difficulty_health_test")
	spawn_enemy(Vector2(1080,505),"Boss");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["damage_taken_multiplier"]=0.75;enemies[-1].combat_tags.append("phase_reduction_test");enemies[-1]["control_profile"]={"blind_immune":false,"blind_duration_multiplier":0.5,"slow_multiplier":0.5,"stun_multiplier":0.25,"displacement":false}
	spawn_enemy(Vector2(880,330),"Defense Dummy")
	combat_blockers.append(CombatGeometry.create_blocker("blocker:pillar",Rect2(570,250,74,145)))
	combat_blockers.append(CombatGeometry.create_blocker("blocker:wall",Rect2(760,210,38,165),{"destructible":true,"current_health":240.0,"maximum_health":240.0}))
	for enemy in enemies:
		if enemy.type in ["Dummy","Defense Dummy"]:enemy.hp=5000.0 if enemy.type=="Defense Dummy" else 2500.0;enemy.max_hp=enemy.hp
		enemy.rewarded=true;enemy["seconds_since_damage"]=TESTING_DUMMY_REGEN_DELAY;enemy["respawn_timer"]=0.0
	if heroes.size()>1:heroes[0].hp*=0.55
	if heroes.size()>2:heroes[2].hp*=0.75
	queue_redraw()

func start_priest_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Priest")
	if test_party.is_empty():flash("Priest fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="priest_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	for hero in heroes:if str(hero.get("class",""))=="Priest":hero.priest_runtime.telemetry_enabled=true
	var fixtures:=[
		{"position":Vector2(485,135),"type":"Raider","tags":[]},
		{"position":Vector2(575,135),"type":"Brute","tags":["elite"]},
		{"position":Vector2(665,135),"type":"Archer","tags":["named"]},
		{"position":Vector2(755,135),"type":"Swift","tags":["summon"]},
		{"position":Vector2(845,135),"type":"Raider","tags":["temporary_combat"]},
		{"position":Vector2(935,135),"type":"Dummy","tags":["training"]}
	]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);enemies[-1].passive_test_enemy=true
		for tag in fixture.tags:if tag not in enemies[-1].combat_tags:enemies[-1].combat_tags.append(tag)
	spawn_enemy(Vector2(1030,245),"Boss");enemies[-1].passive_test_enemy=true;enemies[-1].control_profile={"root_multiplier":0.25,"stun_multiplier":0.25}
	spawn_enemy(Vector2(910,500),"Defense Dummy");enemies[-1].passive_test_enemy=false
	for enemy in enemies:enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,6000.0);enemy.max_hp=enemy.hp
	for ally in heroes:if str(ally.get("class",""))!="Priest":ally.hp*=0.55
	queue_redraw()

func start_shaman_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Shaman")
	if test_party.is_empty():flash("Shaman fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="shaman_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	for hero in heroes:if str(hero.get("class",""))=="Shaman":hero.shaman_runtime.telemetry_enabled=true
	var fixtures:=[
		{"position":Vector2(500,135),"type":"Raider","tags":[]},{"position":Vector2(575,135),"type":"Brute","tags":["elite"]},{"position":Vector2(650,135),"type":"Archer","tags":["named"]},
		{"position":Vector2(530,225),"type":"Swift","tags":[]},{"position":Vector2(610,225),"type":"Raider","tags":[]},{"position":Vector2(690,225),"type":"Swift","tags":["summon"]},
		{"position":Vector2(830,180),"type":"Dummy","tags":["training"]},{"position":Vector2(1030,245),"type":"Boss","tags":["boss"]},{"position":Vector2(950,500),"type":"Defense Dummy","tags":["training"]}
	]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);enemies[-1].passive_test_enemy=true
		for tag in fixture.tags:if tag not in enemies[-1].combat_tags:enemies[-1].combat_tags.append(tag)
		if fixture.type=="Boss":enemies[-1].control_profile={"root_multiplier":0.25,"stun_multiplier":0.25,"slow_multiplier":0.5,"displacement":false}
	combat_blockers.append(CombatGeometry.create_blocker("blocker:shaman_worldbreaker_test",Rect2(760,280,32,150),{"blocks_movement":true,"blocks_line_of_sight":false,"blocks_projectiles":false}))
	for enemy in enemies:enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,7000.0);enemy.max_hp=enemy.hp
	queue_redraw()

func start_templar_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Templar")
	if test_party.is_empty():flash("Templar fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="templar_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	for hero in heroes:if str(hero.get("class",""))=="Templar":hero.templar_runtime.telemetry_enabled=true
	var fixtures:=[{"position":Vector2(500,135),"type":"Raider","tags":[]},{"position":Vector2(585,135),"type":"Brute","tags":["elite"]},{"position":Vector2(670,135),"type":"Archer","tags":["named"]},{"position":Vector2(500,230),"type":"Swift","tags":["summon"]},{"position":Vector2(585,230),"type":"Dummy","tags":["temporary_combat"]},{"position":Vector2(850,165),"type":"Boss","tags":["boss"]},{"position":Vector2(950,500),"type":"Defense Dummy","tags":["training"]}]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);enemies[-1].passive_test_enemy=true
		for tag in fixture.tags:if tag not in enemies[-1].combat_tags:enemies[-1].combat_tags.append(tag)
		if fixture.type=="Boss":enemies[-1].control_profile={"blind_duration_multiplier":0.5,"slow_multiplier":0.5,"displacement":false}
	for enemy in enemies:enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,8000.0);enemy.max_hp=enemy.hp
	for ally in heroes:if str(ally.get("class",""))!="Templar":ally.hp*=0.45
	queue_redraw()

func start_protector_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Protector")
	if test_party.is_empty():flash("Protector fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="protector_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	for hero in heroes:if str(hero.get("class",""))=="Protector":hero.protector_runtime.telemetry_enabled=true
	var fixtures:=[{"position":Vector2(480,130),"type":"Raider","tags":[]},{"position":Vector2(570,130),"type":"Archer","tags":[]},{"position":Vector2(660,130),"type":"Brute","tags":["elite"]},{"position":Vector2(490,235),"type":"Swift","tags":["summon"]},{"position":Vector2(620,235),"type":"Dummy","tags":["temporary_combat"]},{"position":Vector2(920,180),"type":"Boss","tags":["boss"]},{"position":Vector2(1010,485),"type":"Defense Dummy","tags":["training"]}]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);enemies[-1].passive_test_enemy=true
		for tag in fixture.tags:if tag not in enemies[-1].combat_tags:enemies[-1].combat_tags.append(tag)
		if fixture.type=="Boss":enemies[-1].control_profile={"slow_multiplier":0.5,"stun_multiplier":0.25,"displacement":false}
	combat_blockers.append(CombatGeometry.create_blocker("blocker:protector_permanent",Rect2(760,255,34,155)))
	for enemy in enemies:enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,9000.0);enemy.max_hp=enemy.hp
	for ally in heroes:if str(ally.get("class",""))!="Protector":ally.hp*=0.55
	queue_redraw()

func start_sentinel_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Sentinel")
	if test_party.is_empty():flash("Sentinel fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="sentinel_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	var fixtures:=[{"position":Vector2(440,120),"type":"Raider","tags":[]},{"position":Vector2(530,120),"type":"Archer","tags":["elite"]},{"position":Vector2(620,120),"type":"Swift","tags":["summon"]},{"position":Vector2(710,120),"type":"Dummy","tags":["training"]},{"position":Vector2(850,205),"type":"Boss","tags":["boss"]},{"position":Vector2(1110,500),"type":"Defense Dummy","tags":["training"]}]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);enemies[-1].passive_test_enemy=true
		for tag in fixture.tags:if tag not in enemies[-1].combat_tags:enemies[-1].combat_tags.append(tag)
		if fixture.type=="Boss":enemies[-1].control_profile={"slow_multiplier":.5,"stun_multiplier":.25,"displacement":false}
	for enemy in enemies:enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,9000.0);enemy.max_hp=enemy.hp
	var ratios:=[1.0,.80,.50,.21,.19,.11,.09,.01]
	for ally_index in heroes.size():heroes[ally_index].hp=maxf(1.0,float(heroes[ally_index].max_hp)*float(ratios[ally_index%ratios.size()]))
	for hero in heroes:if str(hero.get("class",""))=="Sentinel":hero.sentinel_runtime.telemetry_enabled=true
	queue_redraw()

func selected_party_indices() -> Array:
	return TeamManager.sanitize_team(state.selected_team,state.heroes)

func testing_party_for_class(requested_class:String)->Array:
	var selected_party:Array=selected_party_indices()
	if selected_party.any(func(hero_index):return str(state.heroes[hero_index].get("class",""))==requested_class):return selected_party
	var class_index:int=-1
	for hero_index in state.heroes.size():
		if str(state.heroes[hero_index].get("class",""))==requested_class:class_index=hero_index;break
	if class_index<0:return []
	var result:Array=[class_index]
	for hero_index in selected_party:
		if hero_index!=class_index and hero_index not in result:result.append(hero_index)
		if result.size()>=4:return result
	for hero_index in state.heroes.size():
		if hero_index!=class_index and hero_index not in result:result.append(hero_index)
		if result.size()>=4:break
	return result

func testing_party_indices() -> Array:
	return selected_party_indices()

func apply_testing_enemy_level(enemy:Dictionary,enemy_level:int) -> void:
	var safe_level:=CombatSystem.clamp_level(enemy_level)
	var resolved:=CombatSystem.calculate_final_stats(enemy.definition,safe_level)
	enemy.level=safe_level;enemy.stats=resolved;enemy.hp=resolved.health;enemy.max_hp=resolved.health;enemy.percent_damage_health_basis=resolved.health;enemy.power=resolved.power;enemy.armor=resolved.armor
	enemy.basic_action_power_coefficient=resolved.basic_action_power_coefficient;enemy.basic_action_amount=resolved.basic_action_amount;enemy.damage=resolved.basic_action_amount;enemy.basic_action_range=resolved.basic_action_range;enemy.attack_range=resolved.basic_action_range;enemy.range=resolved.basic_action_range
	enemy.basic_action_interval=resolved.basic_action_interval;enemy.basic_attack_interval=resolved.basic_action_interval;enemy.movement_speed=resolved.movement_speed;enemy.critical_chance=resolved.critical_chance;enemy.critical_damage=resolved.critical_damage
	enemy.rewarded=true;enemy["testing_endless_enemy"]=true;enemy["defeated_clear_time"]=0.0

func spawn_testing_endless_enemy() -> void:
	var role:String=GameData.WAVE_ENEMY_ROLES[testing_endless_spawn_count%GameData.WAVE_ENEMY_ROLES.size()]
	var side:int=testing_endless_spawn_count%4
	var offset:int=(testing_endless_spawn_count*83)%330
	var entry:Vector2=[Vector2(1215,150+offset),Vector2(410+offset*2,82),Vector2(65,520-offset),Vector2(410+offset*2,558)][side]
	spawn_enemy(entry,role);apply_testing_enemy_level(enemies[-1],testing_endless_level);testing_endless_spawn_count+=1

func start_testing_endless(enemy_level:int) -> void:
	start_battle(0,-1,testing_party_indices())
	testing_zone_active=true;testing_zone_mode="endless";testing_endless_level=CombatSystem.clamp_level(enemy_level);testing_dummy_attacks_enabled=false
	total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false;testing_endless_spawn_timer=TESTING_ENDLESS_SPAWN_INTERVAL;testing_endless_spawn_count=0;testing_endless_defeated=0
	for hero in heroes:
		if str(hero.get("class",""))=="Guardian":hero.guardian_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Cleric":hero.cleric_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Ranger":hero.ranger_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Mage":hero.mage_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Warlock":hero.warlock_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Priest":hero.priest_runtime.telemetry_enabled=true
	for initial_enemy in 4:spawn_testing_endless_enemy()
	queue_redraw()

func toggle_testing_dummy_attacks() -> void:
	testing_dummy_attacks_enabled=not testing_dummy_attacks_enabled
	if not testing_dummy_attacks_enabled:
		for enemy in enemies:
			if enemy.type=="Defense Dummy":enemy.telegraph=0.0;enemy.special="";enemy.target=-1
	queue_redraw()

func ashwood_party_indices(_encounter_key:String) -> Array:
	return state.selected_team.duplicate()

func start_ashwood_battle(encounter_key:String) -> void:
	var encounter_data:=AshwoodData.encounter(encounter_key,state.zone0)
	var index:=AshwoodData.all_encounter_ids().find(encounter_key)
	start_battle(0,max(0,index),ashwood_party_indices(encounter_key))
	current_ashwood_encounter=encounter_key
	battle_objective=encounter_data.objective.duplicate(true)
	objective_banner_time=5.5
	objective_combat_intro=str(encounter_data.get("combat_intro",""))
	objective_max_health=float(battle_objective.get("max_health",0.0))
	objective_health=clampf(float(battle_objective.get("starting_health",objective_max_health)),0.0,objective_max_health)
	objective_progress=objective_health/objective_max_health if objective_max_health>0 else 0.0
	objective_complete=str(battle_objective.type) in ["elimination","rune_survival","rune_boss","finale"]
	objective_pressure_spawned=false
	objective_actor_pos=Vector2(930,330)
	objective_notice="Rune pattern recognized — move before it reaches the outer ring." if state.zone0.optional_mini_boss_defeated and encounter_key=="finale" else ""
	objective_notice_time=5.5 if objective_notice!="" else 0.0
	ashwood_spawn_count=0
	ashwood_midfight_recruit_index=-1
	rune_active=false;rune_timer=0;rune_charge=0;rune_radius=0
	total_waves=encounter_data.waves.size()
	wave_index=0;wave_spawn_remaining=0;wave_break=.8;waiting_wave=false
	queue_redraw()

func show_ashwood_consequence(text_value:String) -> void:
	screen="ashwood_consequence"
	var root=base_screen("THE ASHWOOD MARCHES","CONSEQUENCE")
	root.add_spacer(false)
	var consequence_panel=panel();consequence_panel.custom_minimum_size=Vector2(850,260);consequence_panel.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;root.add_child(consequence_panel)
	consequence_panel.add_child(label(text_value,22,C_TEXT))
	consequence_panel.add_spacer(false)
	var continue_button:=button("Continue to Map",func():show_zone_map(0),230);continue_button.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;consequence_panel.add_child(continue_button)
	root.add_spacer(false)

# Implemented by the combat simulation layer.
func spawn_enemy(_pos:Vector2,_type:String)->void:pass
