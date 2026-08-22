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
		heroes.append({"name":data.name,"class":data["class"],"hero_index":battle_hero_indices[i],"battle_index":i,"level":runtime_stats.level,"combat_affiliation":"player","independent":false,"pos":start_position,"dest":start_position,"facing_direction":Vector2.RIGHT,"stats":runtime_stats,"equipped_items":equipped,"active_effects":[],"passive_cooldowns":{},"hp":runtime_stats.health,"max_hp":runtime_stats.health,"health_regeneration":runtime_stats.health_regeneration,"temporary_hp":temporary_hp,"temporary_hp_max":temporary_hp,"was_defeated":false,"base_power":runtime_stats.power,"power":runtime_stats.power,"armor":runtime_stats.armor,"basic_action_type":runtime_stats.basic_action_type,"basic_action_coefficient":runtime_stats.basic_action_power_coefficient,"basic_action_power_ratio":runtime_stats.basic_action_amount/maxf(0.001,runtime_stats.power),"basic_action_amount":runtime_stats.basic_action_amount,"damage":runtime_stats.basic_action_amount,"basic_heal_amount":runtime_stats.basic_heal_amount,"range":runtime_stats.basic_action_range,"movement_speed":runtime_stats.movement_speed,"base_basic_action_interval":runtime_stats.basic_action_interval,"basic_attack_interval":runtime_stats.basic_action_interval,"basic_heal_interval":runtime_stats.basic_action_interval,"critical_chance":runtime_stats.critical_chance,"critical_damage":runtime_stats.critical_damage,"threat_modifier":runtime_stats.threat_modifier,"damage_multiplier":runtime_stats.damage_multiplier,"healing_multiplier":runtime_stats.healing_multiplier,"damage_taken_multiplier":runtime_stats.damage_taken_multiplier,"healing_taken_multiplier":runtime_stats.healing_taken_multiplier,"basic_attack_damage_type":runtime_stats.basic_action_damage_type,"target":-1,"heal_target":-1,"suppress_auto_target":false,"cooldown":0.0,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"shield":0.0,"shield_sources":[],"last_hit":0.0,"bloodletting_stacks":[],"thousand_cuts_count":0,"retribution_charges":[],"soul_furnace_stacks":0,"last_dawn_ready":true,"borrowed_time_timer":0.0,"borrowed_time_armed":false,"pending_repeats":[],"q_charges":2 if has_item_passive(equipped,"twin_incantation") else 1,"q_charge_timers":[]})
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
		elif str(heroes[-1].get("class",""))=="Huntsman":HuntsmanSystem.initialize_runtime(heroes[-1],is_testing_save(),ProgressionScopeSystem.new_encounter_id("battle"))
		elif str(heroes[-1].get("class",""))=="Druid":DruidSystem.initialize_runtime(heroes[-1],is_testing_save(),ProgressionScopeSystem.new_encounter_id("battle"))
		elif str(heroes[-1].get("class",""))=="Warrior":WarriorSystem.initialize_runtime(heroes[-1],is_testing_save(),ProgressionScopeSystem.new_encounter_id("battle"))
		elif str(heroes[-1].get("class",""))=="Death Knight":DeathKnightSystem.initialize_runtime(heroes[-1],is_testing_save(),data.get("talent_mastery",{}),ProgressionScopeSystem.new_encounter_id("battle"))
		elif str(heroes[-1].get("class",""))=="Beastmaster":BeastmasterSystem.initialize_runtime(heroes[-1],is_testing_save(),ProgressionScopeSystem.new_encounter_id("battle"))
		elif str(heroes[-1].get("class",""))=="Monk":MonkSystem.initialize_runtime(heroes[-1],is_testing_save(),ProgressionScopeSystem.new_encounter_id("battle"))
		elif str(heroes[-1].get("class",""))=="Paladin":PaladinSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Crusader":CrusaderSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Vanguard":VanguardSystem.initialize_runtime(heroes[-1],is_testing_save(),ProgressionScopeSystem.new_encounter_id("battle"))
		elif str(heroes[-1].get("class",""))=="Vitalist":VitalistSystem.initialize_runtime(heroes[-1],is_testing_save(),ProgressionScopeSystem.new_encounter_id("battle"))
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

func start_huntsman_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Huntsman")
	if test_party.is_empty():flash("Huntsman fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="huntsman_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	var fixtures:=[
		{"position":Vector2(430,130),"type":"Raider","tags":["standard"],"armor":0.0},
		{"position":Vector2(535,130),"type":"Archer","tags":["enemy_hero"],"armor":35.0},
		{"position":Vector2(640,130),"type":"Swift","tags":["summon"],"summon":true},
		{"position":Vector2(745,130),"type":"Brute","tags":["elite"],"armor":75.0,"control":"slow"},
		{"position":Vector2(535,245),"type":"Dummy","tags":["training"]},
		{"position":Vector2(650,245),"type":"Raider","tags":["named"],"control":"root"},
		{"position":Vector2(765,245),"type":"Archer","tags":["standard"],"control":"stun"},
		{"position":Vector2(925,190),"type":"Boss","tags":["boss"],"armor":250.0,"detector":true},
		{"position":Vector2(1080,500),"type":"Defense Dummy","tags":["temporary_combat"],"temporary":true}
	]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);enemies[-1].passive_test_enemy=true
		for tag in fixture.tags:if tag not in enemies[-1].combat_tags:enemies[-1].combat_tags.append(tag)
		enemies[-1].armor=float(fixture.get("armor",enemies[-1].get("armor",0.0)));enemies[-1].summoned_unit=bool(fixture.get("summon",false));enemies[-1].temporary_combat=bool(fixture.get("temporary",false))
		if str(fixture.get("control",""))!="":CombatSystem.apply_control(enemies[-1],str(fixture.control),600.0,.30 if str(fixture.control)=="slow" else 1.0)
		if bool(fixture.get("detector",false)):enemies[-1].detection_profile={"detect_stealthed":true,"detect_invisible":true,"detection_radius":420.0,"reveal_duration":2.0}
		if fixture.type=="Boss":enemies[-1].control_profile={"slow_multiplier":.5,"stun_multiplier":.25,"displacement":false}
	for enemy in enemies:enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,10000.0);enemy.max_hp=enemy.hp
	for hero in heroes:if str(hero.get("class",""))=="Huntsman":hero.huntsman_runtime.telemetry_enabled=true
	queue_redraw()

func start_druid_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Druid")
	if test_party.is_empty():flash("Druid fixture unavailable.");show_combat_hall();return
	# Four testing heroes make every Regrowth/targeting interaction directly observable.
	var support:Array=[]
	for index in state.heroes.size():
		if index in test_party:continue
		if str(state.heroes[index].get("class","")) in ["Guardian","Cleric","Priest"]:support.append(index)
		if support.size()>=3:break
	start_battle(0,-1,[test_party[0]]+support);testing_zone_active=true;testing_zone_mode="druid_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	for hero in heroes:
		if str(hero.get("class",""))=="Druid":hero.druid_runtime.telemetry_enabled=true
	# Standard cluster, immediate-only categories, stealth, and authored Boss immunity.
	for position in [Vector2(520,145),Vector2(610,145),Vector2(565,225),Vector2(655,225),Vector2(700,175)]:spawn_enemy(position,"Dummy");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["target_category"]="standard"
	spawn_enemy(Vector2(805,150),"Brute");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["target_category"]="elite"
	spawn_enemy(Vector2(925,210),"Boss");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["control_profile"]={"root_multiplier":0.0,"silence_multiplier":0.25};enemies[-1]["target_category"]="boss"
	spawn_enemy(Vector2(1040,360),"Dummy");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["target_category"]="summon";StealthDetectionSystem.set_stealth_source(enemies[-1],"druid_range_stealth",true)
	spawn_enemy(Vector2(850,510),"Dummy");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["target_category"]="temporary_combat"
	for enemy in enemies:enemy.rewarded=true;enemy.hp=5000.0;enemy.max_hp=5000.0;enemy["seconds_since_damage"]=TESTING_DUMMY_REGEN_DELAY;enemy["respawn_timer"]=0.0
	# Wound allies to distinct thresholds and seed controls for Nature's Cure.
	var ratios:=[1.0,0.8,0.5,0.25]
	for index in mini(heroes.size(),ratios.size()):heroes[index].hp=float(heroes[index].max_hp)*float(ratios[index])
	if heroes.size()>1:for control in ["stun","root","slow","silence","fear"]:CombatSystem.apply_control(heroes[1],control,30.0,0.25)
	queue_redraw()

func start_warrior_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Warrior")
	if test_party.is_empty():flash("Warrior fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="warrior_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	var fixtures:=[
		{"position":Vector2(470,130),"type":"Raider","category":"standard","armor":0.0},{"position":Vector2(570,130),"type":"Brute","category":"elite","armor":50.0},{"position":Vector2(670,130),"type":"Archer","category":"named","armor":100.0},
		{"position":Vector2(510,235),"type":"Swift","category":"summon","summon":true},{"position":Vector2(630,235),"type":"Dummy","category":"temporary_combat"},{"position":Vector2(900,185),"type":"Boss","category":"boss","armor":250.0},
		{"position":Vector2(1030,480),"type":"Defense Dummy","category":"training","shield":1800.0}
	]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);var enemy:Dictionary=enemies[-1];enemy.passive_test_enemy=fixture.type!="Defense Dummy";enemy.target_category=str(fixture.category);enemy.armor=float(fixture.get("armor",0.0));enemy.summoned_unit=bool(fixture.get("summon",false));enemy.shield=float(fixture.get("shield",0.0));enemy.shield_sources=[{"source_id":"warrior_range_shield","amount":enemy.shield,"remaining_duration":0.0}] if enemy.shield>0.0 else []
		if enemy.summoned_unit:enemy.original_lifetime=25.0;enemy.remaining_lifetime=25.0
		if fixture.type=="Boss":enemy.control_profile={"silence_multiplier":1.0,"slow_multiplier":0.5,"displacement":false}
	for enemy in enemies:enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,10000.0);enemy.max_hp=enemy.hp
	combat_blockers.append(CombatGeometry.create_blocker("blocker:warrior_landing",Rect2(760,300,42,155)))
	for hero in heroes:if str(hero.get("class",""))=="Warrior":hero.warrior_runtime.telemetry_enabled=true
	queue_redraw()

func start_death_knight_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Death Knight")
	if test_party.is_empty():flash("Death Knight fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="death_knight_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	var fixtures:=[
		{"position":Vector2(445,120),"type":"Raider","category":"standard"},{"position":Vector2(535,120),"type":"Brute","category":"elite"},{"position":Vector2(625,120),"type":"Archer","category":"named"},{"position":Vector2(715,120),"type":"Swift","category":"enemy_hero"},
		{"position":Vector2(470,220),"type":"Swift","category":"summon","summon":true},{"position":Vector2(565,220),"type":"Dummy","category":"temporary_combat"},{"position":Vector2(660,220),"type":"Raider","category":"standard","control":"slow"},
		{"position":Vector2(850,170),"type":"Boss","category":"boss","profile":{"slow_multiplier":0.5,"attack_speed_multiplier":0.5,"root_multiplier":0.25,"stun_multiplier":0.25,"blind_immune":true,"displacement":false}},
		{"position":Vector2(965,260),"type":"Boss","category":"boss","profile":{"slow_multiplier":0.5,"attack_speed_multiplier":0.5,"root_multiplier":0.0,"stun_multiplier":0.0,"blind_immune":true,"displacement":false}},
		{"position":Vector2(1050,500),"type":"Defense Dummy","category":"training","healing":true}
	]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);var enemy:Dictionary=enemies[-1];enemy.passive_test_enemy=fixture.type!="Defense Dummy";enemy.target_category=str(fixture.category);enemy.summoned_unit=bool(fixture.get("summon",false));enemy.control_profile=fixture.get("profile",{}).duplicate(true);enemy["self_heal_test"]=bool(fixture.get("healing",false))
		if enemy.summoned_unit:enemy.original_lifetime=15.0;enemy.remaining_lifetime=15.0
		if str(fixture.get("control",""))!="":CombatSystem.apply_control(enemy,str(fixture.control),600.0,.30)
	for enemy in enemies:enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,10000.0);enemy.max_hp=enemy.hp
	for hero in heroes:if str(hero.get("class",""))=="Death Knight":hero.death_knight_runtime.telemetry_enabled=true
	for ally in heroes:if str(ally.get("class",""))!="Death Knight":ally.hp*=0.55
	queue_redraw()

func start_beastmaster_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Beastmaster")
	if test_party.is_empty():flash("Beastmaster fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="beastmaster_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	var fixtures:=[
		{"position":Vector2(440,115),"type":"Raider","category":"standard","passive":true},{"position":Vector2(530,115),"type":"Brute","category":"elite","passive":true},{"position":Vector2(620,115),"type":"Archer","category":"named","passive":true},{"position":Vector2(710,115),"type":"Boss","category":"boss","passive":true,"profile":{"slow_multiplier":0.5,"attack_speed_multiplier":0.5,"root_multiplier":0.25,"stun_multiplier":0.25}},
		{"position":Vector2(470,220),"type":"Defense Dummy","category":"standard","passive":false},{"position":Vector2(570,220),"type":"Swift","category":"standard","passive":false,"slow":true},{"position":Vector2(670,220),"type":"Brute","category":"elite","passive":true,"armor":100.0},
		{"position":Vector2(820,160),"type":"Dummy","category":"temporary_combat","passive":true},{"position":Vector2(890,160),"type":"Dummy","category":"temporary_combat","passive":true},{"position":Vector2(960,160),"type":"Dummy","category":"temporary_combat","passive":true},{"position":Vector2(1030,160),"type":"Dummy","category":"temporary_combat","passive":true},{"position":Vector2(1100,160),"type":"Dummy","category":"temporary_combat","passive":true},
		{"position":Vector2(1000,420),"type":"Archer","category":"standard","passive":false},{"position":Vector2(1080,500),"type":"Defense Dummy","category":"standard","passive":false,"aoe":true}
	]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);var enemy:Dictionary=enemies[-1];enemy.target_category=str(fixture.category);enemy.passive_test_enemy=bool(fixture.passive);enemy.control_profile=fixture.get("profile",{}).duplicate(true);enemy.armor=float(fixture.get("armor",0.0));enemy["slow_test_enemy"]=bool(fixture.get("slow",false));enemy["hostile_aoe_test"]=bool(fixture.get("aoe",false));enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,12000.0);enemy.max_hp=enemy.hp
	for hero in heroes:
		if str(hero.get("class",""))=="Beastmaster":hero.beastmaster_runtime.telemetry_enabled=true;hero.beastmaster_runtime.misha.hp*=0.55
		else:hero.hp*=0.55
	combat_blockers.append(CombatGeometry.create_blocker("blocker:beastmaster_endpoint",Rect2(760,285,56,165)))
	queue_redraw()

func start_monk_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Monk")
	if test_party.is_empty():flash("Monk fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="monk_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	var fixtures:=[
		{"position":Vector2(440,115),"type":"Raider","category":"standard","control":""},{"position":Vector2(535,115),"type":"Brute","category":"elite","control":"stun"},{"position":Vector2(630,115),"type":"Archer","category":"named","control":"root"},
		{"position":Vector2(735,115),"type":"Swift","category":"summon","control":""},{"position":Vector2(840,115),"type":"Dummy","category":"temporary_combat","control":""},{"position":Vector2(955,165),"type":"Boss","category":"boss","control":""},
		{"position":Vector2(520,245),"type":"Raider","category":"standard","control":""},{"position":Vector2(610,245),"type":"Raider","category":"standard","control":""},{"position":Vector2(700,245),"type":"Raider","category":"standard","control":""},{"position":Vector2(1080,500),"type":"Defense Dummy","category":"training","control":""}
	]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);var enemy:Dictionary=enemies[-1];enemy.target_category=str(fixture.category);enemy.passive_test_enemy=fixture.type!="Defense Dummy";enemy.summoned_unit=str(fixture.category)=="summon";enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,15000.0);enemy.max_hp=enemy.hp
		if str(fixture.control)!="":CombatSystem.apply_control(enemy,str(fixture.control),600.0,1.0)
		if fixture.type=="Boss":enemy.control_profile={"slow_multiplier":.5,"root_multiplier":.25,"stun_multiplier":.25,"displacement":false}
	for hero in heroes:
		if str(hero.get("class",""))=="Monk":hero.monk_runtime.telemetry_enabled=true
		else:hero.hp*=0.55
	combat_blockers.append(CombatGeometry.create_blocker("blocker:monk_endpoint",Rect2(780,300,50,155)))
	queue_redraw()

func start_paladin_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Paladin")
	if test_party.is_empty():flash("Paladin fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="paladin_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	var fixtures:=[{"position":Vector2(430,115),"type":"Raider","category":"standard"},{"position":Vector2(525,115),"type":"Brute","category":"elite"},{"position":Vector2(620,115),"type":"Archer","category":"named"},{"position":Vector2(735,115),"type":"Boss","category":"boss"},{"position":Vector2(500,245),"type":"Raider","category":"standard"},{"position":Vector2(575,245),"type":"Raider","category":"standard"},{"position":Vector2(650,245),"type":"Raider","category":"standard"},{"position":Vector2(980,185),"type":"Defense Dummy","category":"training"},{"position":Vector2(1060,260),"type":"Archer","category":"standard"}]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);var enemy:Dictionary=enemies[-1];enemy.target_category=str(fixture.category);enemy.passive_test_enemy=true;enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,15000.0);enemy.max_hp=enemy.hp
		if fixture.type=="Boss":enemy.control_profile={"slow_multiplier":.5,"root_multiplier":.25,"stun_multiplier":.25,"displacement":false}
	for hero in heroes:
		if str(hero.get("class",""))=="Paladin":hero.paladin_runtime.telemetry_enabled=true;hero.pos=Vector2(330,390)
		else:hero.hp*=.35
	if heroes.size()>1:CombatSystem.apply_control(heroes[1],"slow",600.0,.40)
	if heroes.size()>2:CombatSystem.apply_control(heroes[2],"root",600.0)
	if heroes.size()>3:CombatSystem.apply_control(heroes[3],"stun",600.0)
	combat_blockers.append(CombatGeometry.create_blocker("blocker:paladin_path",Rect2(780,300,55,165)));combat_blockers.append(CombatGeometry.create_blocker("blocker:paladin_displacement",Rect2(930,330,45,120)));queue_redraw()

func start_crusader_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Crusader")
	if test_party.is_empty():flash("Crusader fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="crusader_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	var fixtures:=[{"position":Vector2(455,120),"type":"Raider","category":"standard","group":1},{"position":Vector2(515,120),"type":"Raider","category":"standard","group":2},{"position":Vector2(575,120),"type":"Raider","category":"standard","group":3},{"position":Vector2(635,120),"type":"Raider","category":"standard","group":4},{"position":Vector2(695,120),"type":"Raider","category":"standard","group":5},{"position":Vector2(755,120),"type":"Brute","category":"elite","group":6},{"position":Vector2(825,120),"type":"Archer","category":"named","group":6},{"position":Vector2(900,120),"type":"Boss","category":"boss","group":1},{"position":Vector2(520,260),"type":"Raider","category":"standard","group":5},{"position":Vector2(580,260),"type":"Raider","category":"standard","group":5},{"position":Vector2(640,260),"type":"Raider","category":"standard","group":5},{"position":Vector2(700,260),"type":"Raider","category":"standard","group":5},{"position":Vector2(760,260),"type":"Raider","category":"standard","group":5},{"position":Vector2(1040,180),"type":"Defense Dummy","category":"training","group":1}]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);var enemy:Dictionary=enemies[-1];enemy.target_category=str(fixture.category);enemy.passive_test_enemy=true;enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,20000.0);enemy.max_hp=enemy.hp;enemy["crusader_group_size"]=int(fixture.group)
		if fixture.type=="Boss":enemy.control_profile={"slow_multiplier":.5,"root_multiplier":.25,"stun_multiplier":0.0,"blind_immune":true,"displacement":false}
	if enemies.size()>1:enemies[1].control_profile={"blind_immune":true}
	if enemies.size()>2:enemies[2].control_profile={"displacement":false}
	if enemies.size()>3:StatusEffectSystem.apply_source_unstoppable(enemies[3],"testing_crusader",600.0)
	for hero in heroes:
		if str(hero.get("class",""))=="Crusader":hero.crusader_runtime.telemetry_enabled=true;hero.pos=Vector2(330,400)
		else:hero.hp*=.45
	combat_blockers.append(CombatGeometry.create_blocker("blocker:crusader_pull",Rect2(850,300,55,170)));combat_blockers.append(CombatGeometry.create_blocker("blocker:crusader_falling",Rect2(995,300,55,170)));queue_redraw()

func start_vanguard_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Vanguard")
	if test_party.is_empty():flash("Vanguard fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="vanguard_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	var fixtures:=[{"position":Vector2(455,120),"type":"Raider","category":"standard","group":1},{"position":Vector2(515,120),"type":"Raider","category":"standard","group":2},{"position":Vector2(575,120),"type":"Raider","category":"standard","group":3},{"position":Vector2(635,120),"type":"Raider","category":"standard","group":4},{"position":Vector2(695,120),"type":"Raider","category":"standard","group":5},{"position":Vector2(755,120),"type":"Brute","category":"elite","group":6},{"position":Vector2(825,120),"type":"Archer","category":"named","group":6},{"position":Vector2(900,120),"type":"Boss","category":"boss","group":1},{"position":Vector2(520,260),"type":"Raider","category":"standard","group":5},{"position":Vector2(580,260),"type":"Raider","category":"standard","group":5},{"position":Vector2(640,260),"type":"Raider","category":"standard","group":5},{"position":Vector2(700,260),"type":"Raider","category":"standard","group":5},{"position":Vector2(760,260),"type":"Raider","category":"standard","group":5},{"position":Vector2(1040,180),"type":"Defense Dummy","category":"training","group":1}]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);var enemy:Dictionary=enemies[-1];enemy.target_category=str(fixture.category);enemy.passive_test_enemy=true;enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,20000.0);enemy.max_hp=enemy.hp;enemy["vanguard_group_size"]=int(fixture.group)
		if fixture.type=="Boss":enemy.control_profile={"slow_multiplier":.5,"root_multiplier":.25,"stun_multiplier":0.0,"blind_immune":true,"displacement":false}
	if enemies.size()>2:enemies[2].control_profile={"displacement":false}
	if enemies.size()>3:StatusEffectSystem.apply_source_unstoppable(enemies[3],"testing_vanguard",600.0)
	for hero in heroes:
		if str(hero.get("class",""))=="Vanguard":hero.vanguard_runtime.telemetry_enabled=true;hero.pos=Vector2(330,400)
		else:hero.hp*=.45
	combat_blockers.append(CombatGeometry.create_blocker("blocker:vanguard_slide",Rect2(680,300,55,170)));combat_blockers.append(CombatGeometry.create_blocker("blocker:vanguard_displacement",Rect2(900,300,55,170)));queue_redraw()

func start_vitalist_testing_zone() -> void:
	var test_party:Array=testing_party_for_class("Vitalist")
	if test_party.is_empty():flash("Vitalist fixture unavailable.");show_combat_hall();return
	start_battle(0,-1,test_party);testing_zone_active=true;testing_zone_mode="vitalist_range";testing_dummy_attacks_enabled=true;total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	var fixtures:=[{"position":Vector2(470,120),"type":"Raider","category":"standard"},{"position":Vector2(530,120),"type":"Raider","category":"standard"},{"position":Vector2(590,120),"type":"Raider","category":"standard"},{"position":Vector2(650,120),"type":"Raider","category":"standard"},{"position":Vector2(710,120),"type":"Raider","category":"standard"},{"position":Vector2(790,120),"type":"Brute","category":"elite"},{"position":Vector2(860,120),"type":"Archer","category":"named"},{"position":Vector2(940,120),"type":"Boss","category":"boss"},{"position":Vector2(570,275),"type":"Raider","category":"standard"},{"position":Vector2(630,275),"type":"Raider","category":"standard"},{"position":Vector2(690,275),"type":"Raider","category":"standard"},{"position":Vector2(1060,190),"type":"Defense Dummy","category":"training"}]
	for fixture in fixtures:
		spawn_enemy(fixture.position,fixture.type);var enemy:Dictionary=enemies[-1];enemy.target_category=str(fixture.category);enemy.passive_test_enemy=true;enemy.rewarded=true;enemy.seconds_since_damage=TESTING_DUMMY_REGEN_DELAY;enemy.respawn_timer=0.0;enemy.hp=maxf(enemy.hp,20000.0);enemy.max_hp=enemy.hp
		if fixture.type=="Boss":enemy.control_profile={"slow_multiplier":.5,"silence_multiplier":0.0,"stun_multiplier":0.0,"displacement":false}
	if enemies.size()>5:enemies[5].control_profile={"slow_multiplier":.5}
	if enemies.size()>6:enemies[6].control_profile={"silence_multiplier":0.0}
	if enemies.size()>7:enemies[7].control_profile={"displacement":false,"slow_multiplier":.5,"silence_multiplier":0.0,"stun_multiplier":0.0}
	for hero in heroes:
		if str(hero.get("class",""))=="Vitalist":hero.vitalist_runtime.telemetry_enabled=true;hero.pos=Vector2(325,420);hero.hp*=.45
		else:hero.hp*=.45
	combat_blockers.append(CombatGeometry.create_blocker("blocker:vitalist_arm",Rect2(810,320,55,185)));combat_blockers.append(CombatGeometry.create_blocker("blocker:vitalist_shove",Rect2(1040,285,55,235)));queue_redraw()

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
