extends "res://scripts/runtime/app_shell.gd"

func battle_formation_position(slot_index:int) -> Vector2:
	var diamond_positions:=[Vector2(210,320),Vector2(145,215),Vector2(145,425),Vector2(90,320)]
	return diamond_positions[clampi(slot_index,0,diamond_positions.size()-1)]

func start_battle(id:int,node:int=0,party_override:Array=[]) -> void:
	var requested_party:Array=state.selected_team if party_override.is_empty() else party_override
	var validated_party:=TeamManager.sanitize_team(requested_party,state.heroes)
	if validated_party.is_empty():
		flash("Choose at least one hero before starting battle.")
		return
	if party_override.is_empty():
		state.selected_team=validated_party.duplicate()
		if current_team_slot<0:state.active_team=validated_party.duplicate()
	testing_zone_active=false
	current_ashwood_encounter=""
	battle_objective={};objective_progress=0;objective_health=0;objective_max_health=0;objective_complete=true;objective_pressure_spawned=false;objective_notice="";objective_notice_time=0;objective_banner_time=0;objective_combat_intro="";rune_active=false;rune_timer=0;rune_charge=0;rune_radius=0
	dungeon_id=id; encounter_id=node; clear_all();combat_events.clear();item_feedback_feed.clear();battle_material_results.clear();combat_blockers.clear();combat_projectiles.clear();incapacitated_hero_ids.clear();next_enemy_combat_id=1;next_projectile_combat_id=1;debug_combat_overlay=CombatRulesV1.DEBUG_COMBAT_OVERLAY_ENABLED; ui.visible=false; combat_layer.visible=true; screen="combat"; battle_time=0; spawn_timer=0; battle_over=false; paused=false; selected=0;focused_enemy_index=-1; wave_index=0; total_waves=3+(1 if node>=3 else 0); wave_spawn_remaining=0; wave_break=.8; waiting_wave=false; battle_gold_earned=0
	battle_hero_indices=validated_party.slice(0,4)
	for i in battle_hero_indices.size():
		var start_position:=battle_formation_position(i);var data=state.heroes[battle_hero_indices[i]];var runtime_stats:=hero_final_stats(data);var equipped:=hero_equipped_items(data);heroes.append({"name":data.name,"class":data["class"],"hero_index":battle_hero_indices[i],"battle_index":i,"level":runtime_stats.level,"combat_affiliation":"player","independent":false,"pos":start_position,"dest":start_position,"facing_direction":Vector2.RIGHT,"stats":runtime_stats,"equipped_items":equipped,"active_effects":[],"passive_cooldowns":{},"hp":runtime_stats.health,"max_hp":runtime_stats.health,"base_power":runtime_stats.power,"power":runtime_stats.power,"armor":runtime_stats.armor,"basic_action_type":runtime_stats.basic_action_type,"basic_action_coefficient":runtime_stats.basic_action_power_coefficient,"basic_action_power_ratio":runtime_stats.basic_action_amount/maxf(0.001,runtime_stats.power),"basic_action_amount":runtime_stats.basic_action_amount,"damage":runtime_stats.basic_action_amount,"basic_heal_amount":runtime_stats.basic_heal_amount,"range":runtime_stats.basic_action_range,"movement_speed":runtime_stats.movement_speed,"base_basic_action_interval":runtime_stats.basic_action_interval,"basic_attack_interval":runtime_stats.basic_action_interval,"basic_heal_interval":runtime_stats.basic_action_interval,"critical_chance":runtime_stats.critical_chance,"critical_damage":runtime_stats.critical_damage,"threat_modifier":runtime_stats.threat_modifier,"damage_multiplier":runtime_stats.damage_multiplier,"healing_multiplier":runtime_stats.healing_multiplier,"damage_taken_multiplier":runtime_stats.damage_taken_multiplier,"healing_taken_multiplier":runtime_stats.healing_taken_multiplier,"basic_attack_damage_type":runtime_stats.basic_action_damage_type,"target":-1,"heal_target":-1,"suppress_auto_target":false,"cooldown":0.0,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"shield":0.0,"shield_sources":[],"last_hit":0.0,"bloodletting_stacks":[],"thousand_cuts_count":0,"retribution_charges":[],"soul_furnace_stacks":0,"last_dawn_ready":true,"borrowed_time_timer":0.0,"borrowed_time_armed":false,"pending_repeats":[],"q_charges":2 if has_item_passive(equipped,"twin_incantation") else 1,"q_charge_timers":[]})
		var stable_hero_id:=str(data.get("hero_id",data.get("id",battle_hero_indices[i])))
		CombatRulesV1.initialize_unit(heroes[-1],"hero:%s"%stable_hero_id,"player")
		heroes[-1]["selected_talents"]=data.get("selected_talents",{}).duplicate(true)
		heroes[-1]["selected_heroic_id"]=str(data.get("selected_heroic_id",""))
		heroes[-1]["combat_radius"]=42.0
		if str(heroes[-1].get("class",""))=="Guardian":GuardianSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Cleric":ClericSystem.initialize_runtime(heroes[-1],is_testing_save())
		elif str(heroes[-1].get("class",""))=="Ranger":RangerSystem.initialize_runtime(heroes[-1],is_testing_save())
	queue_redraw()

func start_testing_zone() -> void:
	var test_party:Array=[]
	for wanted_class in ["Guardian","Cleric","Ranger","Mage"]:
		for hero_index in state.heroes.size():
			if state.heroes[hero_index]["class"]==wanted_class and hero_index not in test_party:test_party.append(hero_index);break
	if test_party.is_empty():test_party=state.selected_team.duplicate()
	start_battle(0,-1,test_party)
	testing_zone_active=true
	for hero in heroes:
		if str(hero.get("class",""))=="Guardian":hero.guardian_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Cleric":hero.cleric_runtime.telemetry_enabled=true
		elif str(hero.get("class",""))=="Ranger":hero.ranger_runtime.telemetry_enabled=true
	testing_dummy_attacks_enabled=true
	total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false
	spawn_enemy(Vector2(650,120),"Dummy");enemies[-1]["passive_test_enemy"]=true
	spawn_enemy(Vector2(610,525),"Raider")
	spawn_enemy(Vector2(720,525),"Archer")
	spawn_enemy(Vector2(665,555),"Dummy")
	spawn_enemy(Vector2(1050,170),"Boss");enemies[-1]["passive_test_enemy"]=true
	spawn_enemy(Vector2(1080,505),"Boss");enemies[-1]["passive_test_enemy"]=true;enemies[-1]["control_profile"]={"blind_immune":false,"blind_duration_multiplier":0.5,"slow_multiplier":0.5,"stun_multiplier":0.25,"displacement":false}
	spawn_enemy(Vector2(880,330),"Defense Dummy")
	combat_blockers.append(CombatGeometry.create_blocker("blocker:pillar",Rect2(570,250,74,145)))
	combat_blockers.append(CombatGeometry.create_blocker("blocker:wall",Rect2(760,210,38,165),{"destructible":true,"current_health":240.0,"maximum_health":240.0}))
	for enemy in enemies:
		if enemy.type in ["Dummy","Defense Dummy"]:enemy.hp=5000.0 if enemy.type=="Defense Dummy" else 2500.0;enemy.max_hp=enemy.hp
		enemy.rewarded=true;enemy["seconds_since_damage"]=TESTING_DUMMY_REGEN_DELAY;enemy["respawn_timer"]=0.0
	if heroes.size()>1:heroes[0].hp*=0.55
	if heroes.size()>2:heroes[2].hp*=0.75
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
