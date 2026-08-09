extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const ProfessionData = preload("res://scripts/data/profession_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run(main:Node) -> Array:
	var errors:=[]
	main.state.selected_team=[0,1,4,2];main.state.active_team=[0,1,4,2]
	main.state.heroes[1].level=6
	main.show_testing_zone_menu();await main.get_tree().process_frame
	TestSupport.check(errors,main.screen=="combat_hall" and main.ui.find_child("TestingEndlessLevel",true,false)!=null and main.ui.find_child("TestingEndlessStart",true,false)!=null,"The Combat Hall should offer the Dummy Range and fixed-level Endless Arena launch controls.")
	var endless_level_label:Control=main.ui.find_child("TestingEndlessLevelLabel",true,false);var endless_level_picker:Control=main.ui.find_child("TestingEndlessLevel",true,false);var rogue_range_start:Control=main.ui.find_child("TestingRogueRangeStart",true,false);var endless_start:Control=main.ui.find_child("TestingEndlessStart",true,false)
	TestSupport.check(errors,endless_level_label!=null and endless_level_label.size.x>=120.0 and endless_level_label.size.y<=50.0 and endless_level_picker!=null and endless_level_picker.size.x>=135.0 and endless_level_picker.size.y<=50.0,"The Endless Arena level selector should remain a compact horizontal control instead of stretching or wrapping vertically.")
	TestSupport.check(errors,rogue_range_start!=null and endless_start!=null,"Every former Testing Zone launch action should remain available through the Combat Hall.")
	var custom_testing_party:Array=[4,5,7,8];main.state.selected_team=custom_testing_party.duplicate();main.state.active_team=custom_testing_party.duplicate()
	TestSupport.check(errors,main.testing_party_indices()==custom_testing_party,"Testing battles should resolve the currently selected team instead of silently substituting a fixed party.")
	main.state.selected_team=[0,1,2,3];main.state.active_team=[0,1,2,3];main.start_testing_zone()
	TestSupport.check(errors,main.testing_zone_active and main.enemies.size()==7 and main.enemies.filter(func(enemy):return bool(enemy.get("boss",false))).size()==2 and main.enemies.any(func(enemy):return float(enemy.get("control_profile",{}).get("blind_duration_multiplier",0.0))==0.5),"The testing range should retain its dummy layout and include default-immune and partially Blind-vulnerable Boss targets without waves.")
	var ranger_battle_index:int=main.heroes.find_custom(func(hero):return str(hero.get("class",""))=="Ranger")
	if ranger_battle_index>=0:
		var visual_ranger:Dictionary=main.heroes[ranger_battle_index];main.selected=ranger_battle_index
		var visual_enemy_states:Array=main.enemies.map(func(enemy):return {"pos":enemy.pos,"hp":enemy.hp});for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=Vector2(1100,100+enemy_index*70)
		var travel_dummy:Dictionary=main.enemies[0];travel_dummy.pos=visual_ranger.pos+Vector2.RIGHT*150.0;travel_dummy.hp=travel_dummy.max_hp;var q_health_before:float=travel_dummy.hp
		main.cast_ranger_q(visual_ranger,visual_ranger.pos+Vector2.RIGHT*400.0);main.update_ranger_runtime(.05)
		TestSupport.check(errors,is_equal_approx(travel_dummy.hp,q_health_before),"Hungering Arrow should not deal damage before its researched initial projectile travel time elapses.")
		main.update_ranger_runtime(.30);TestSupport.check(errors,travel_dummy.hp<q_health_before,"Hungering Arrow should resolve damage when its traveling projectile reaches the target.")
		visual_ranger.ranger_runtime.delayed_effects.clear();travel_dummy.hp=travel_dummy.max_hp;travel_dummy.pos=visual_ranger.pos+Vector2.RIGHT*100.0;var w_health_before:float=travel_dummy.hp
		main.cast_ranger_w(visual_ranger,visual_ranger.pos+Vector2.RIGHT*280.0);main.update_ranger_runtime(.05)
		TestSupport.check(errors,is_equal_approx(travel_dummy.hp,w_health_before),"Multishot should not deal damage before its expanding cone reaches the target.")
		main.update_ranger_runtime(.20);TestSupport.check(errors,travel_dummy.hp<w_health_before and main.effects.any(func(effect):return effect.kind=="ranger_arrow") and main.effects.any(func(effect):return effect.kind=="multishot"),"Ranger projectiles should synchronize readable battlefield effects with delayed impact damage.")
		main.effects.clear();visual_ranger.ranger_runtime.delayed_effects.clear();for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=visual_enemy_states[enemy_index].pos;main.enemies[enemy_index].hp=visual_enemy_states[enemy_index].hp
	else:TestSupport.check(errors,false,"The testing party should include a Ranger for combat-presentation coverage.")
	var mage_battle_index:int=main.heroes.find_custom(func(hero):return str(hero.get("class",""))=="Mage")
	if mage_battle_index>=0:
		var visual_mage:Dictionary=main.heroes[mage_battle_index];main.selected=mage_battle_index
		visual_mage.selected_talents={"tier_1":"mage_l9_1","tier_2":"mage_l12_2","tier_3":"mage_l15_r1","tier_4":"mage_l18_1","tier_5":"mage_l21_1","tier_6":"mage_l24_3","tier_7":"mage_l27_r1","tier_8":"mage_l30_3"};visual_mage.selected_heroic_id="mage_l15_r1";main.MageSystem.initialize_runtime(visual_mage,true)
		var mage_enemy_states:Array=main.enemies.map(func(enemy):return {"pos":enemy.pos,"hp":enemy.hp,"active_effects":enemy.active_effects.duplicate(true)})
		for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=Vector2(1100,80+enemy_index*75);main.enemies[enemy_index].hp=main.enemies[enemy_index].max_hp
		var flame_target:Dictionary=main.enemies[0];flame_target.pos=visual_mage.pos+Vector2.RIGHT*150.0;var flame_health_before:float=flame_target.hp
		main.cast_mage_q(visual_mage,flame_target.pos);main.update_mage_runtime(.9);TestSupport.check(errors,is_equal_approx(flame_target.hp,flame_health_before) and main.effects.any(func(effect):return effect.kind=="mage_flamestrike_warning" and float(effect.get("radius",0.0))>0.0),"Flamestrike should preserve and visibly represent its full one-second ground warning before damage.")
		main.update_mage_runtime(.2);TestSupport.check(errors,flame_target.hp<flame_health_before and main.effects.any(func(effect):return effect.kind=="mage_flamestrike_impact"),"Flamestrike should resolve with a visible impact at the chosen ground point.")
		main.focused_enemy_index=0;visual_mage.ability_cds[1]=0.0;var bomb_health_before:float=flame_target.hp;main.cast_mage_w(visual_mage);main.update_mage_runtime(3.1)
		TestSupport.check(errors,flame_target.hp<bomb_health_before and visual_mage.mage_runtime.telemetry.w_ticks==3 and visual_mage.mage_runtime.telemetry.w_explosions==1,"Living Bomb should deliver three periodic ticks and its host-centered explosion even across one large deterministic update.")
		var trait_charges_before:int=visual_mage.mage_runtime.trait.current_charges;main.begin_trait();TestSupport.check(errors,main.MageSystem.trait_is_armed(visual_mage) and visual_mage.mage_runtime.trait.current_charges==trait_charges_before-1,"Mage D input should arm Verdant Spheres and spend one stored charge.")
		visual_mage.ability_cds[1]=8.0;main.focused_enemy_index=0;main.use_ability(1);TestSupport.check(errors,visual_mage.ability_cds[1]==0.0 and visual_mage.mage_runtime.bomb_state.bombs_by_target.has(str(flame_target.combat_id)),"An armed Verdant Spheres should make Living Bomb usable through its ordinary cooldown without adding a new action slot.")
		var boss_target:Dictionary=main.enemies.filter(func(enemy):return bool(enemy.get("boss",false)))[0]
		for enemy in main.enemies:
			if enemy!=boss_target:enemy.pos=Vector2(1100,80+main.enemies.find(enemy)*70)
		boss_target.pos=visual_mage.pos+Vector2.RIGHT*160.0;visual_mage.ability_cds[2]=0.0;main.cast_mage_e(visual_mage,boss_target.pos);main.update_mage_runtime(1.0)
		TestSupport.check(errors,visual_mage.mage_runtime.telemetry.e_hits>=1 and visual_mage.mage_runtime.telemetry.stuns_resisted>=1 and not boss_target.active_effects.any(func(effect):return str(effect.get("control_type",""))=="stun"),"Gravity Lapse should collide with a Boss while the Boss resists Stun by default.")
		visual_mage.selected_heroic_id="mage_l15_r1";visual_mage.ability_cds[3]=0.0;var phoenix_destination:Vector2=Vector2(visual_mage.pos)+Vector2(90,80);TestSupport.check(errors,main.cast_phoenix(visual_mage,phoenix_destination),"Phoenix should accept a valid in-bounds launch destination.")
		main.update_mage_runtime(1.0);TestSupport.check(errors,not visual_mage.mage_runtime.phoenix.is_empty() and int(visual_mage.mage_runtime.phoenix.reposition_charges)==int(main.MageData.VALUES.rebirth_charges),"Rebirth should create three temporary R reposition charges after Phoenix arrives.")
		var reposition_before:int=visual_mage.mage_runtime.phoenix.reposition_charges;TestSupport.check(errors,not main.cast_phoenix(visual_mage,Vector2(visual_mage.mage_runtime.phoenix.pos)) and int(visual_mage.mage_runtime.phoenix.reposition_charges)==reposition_before,"An invalid no-movement Rebirth destination should consume no charge.")
		var reposition_destination:Vector2=phoenix_destination+Vector2(50,0);TestSupport.check(errors,main.cast_phoenix(visual_mage,reposition_destination) and int(visual_mage.mage_runtime.phoenix.reposition_charges)==reposition_before-1 and bool(visual_mage.mage_runtime.phoenix.traveling),"Rebirth should reuse R, consume one charge only for a valid destination, and enter relocation travel.")
		flame_target.pos=visual_mage.pos+Vector2.RIGHT*150.0;visual_mage.selected_heroic_id="mage_l15_r2";visual_mage.ability_cds[3]=0.0;main.focused_enemy_index=0;main.cast_pyroblast(visual_mage);main.issue_hero_move(visual_mage,visual_mage.pos+Vector2(20,0))
		TestSupport.check(errors,visual_mage.active_cast.is_empty() and is_equal_approx(visual_mage.ability_cds[3],main.CombatRulesV1.HEROIC_INTERRUPT_COOLDOWN),"Moving during Pyroblast's unreleased cast should apply the shared ten-second interrupted Heroic cooldown.")
		main.effects.clear();visual_mage.hp=visual_mage.max_hp;visual_mage.shield=0.0;visual_mage.shield_sources=[];main.MageSystem.initialize_runtime(visual_mage,true);for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=mage_enemy_states[enemy_index].pos;main.enemies[enemy_index].hp=mage_enemy_states[enemy_index].hp;main.enemies[enemy_index].active_effects=mage_enemy_states[enemy_index].active_effects
	else:TestSupport.check(errors,false,"The testing party should include a Mage for combat and presentation coverage.")
	var input_guardian:Dictionary=main.heroes[0];main.selected=0;input_guardian.selected_talents={"tier_6":"guardian_l24_2"};input_guardian.ability_cds[4]=0.0;main.begin_trait()
	TestSupport.check(errors,input_guardian.guardian_runtime.stoneform_remaining==10.0 and input_guardian.ability_cds[4]==60.0,"The existing D Trait input should activate Stoneform and expose its cooldown without another action slot.")
	input_guardian.guardian_runtime.stoneform_remaining=0.0
	input_guardian.selected_talents={"tier_8":"guardian_l30_3"};input_guardian.ability_cds[2]=0.0;var invalid_toss:bool=bool(main.cast_guardian_ability(2,Vector2(55,320)))
	TestSupport.check(errors,not invalid_toss and input_guardian.ability_cds[2]==0.0 and main.GuardianSystem.rewind_sequence_count(input_guardian,main.battle_time)==0,"An invalid Dwarf Toss should consume no cooldown and should not count toward Rewind.")
	var original_enemy_positions:Array=main.enemies.map(func(enemy):return enemy.pos)
	for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=Vector2(1100,100+enemy_index*70)
	input_guardian.ability_cds[1]=0.0
	var thunder_clap_cast:bool=bool(main.cast_guardian_ability(1,input_guardian.pos))
	TestSupport.check(errors,thunder_clap_cast and input_guardian.guardian_runtime.telemetry.thunder_clap_casts[-1]==0 and main.effects.any(func(effect):return effect.kind=="guardian_thunder_clap" and is_equal_approx(float(effect.get("radius",0.0)),float(main.GuardianData.SPACE.thunder_clap_radius))),"Thunder Clap should complete safely, record its per-cast target count, and visibly represent its actual area.")
	for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=original_enemy_positions[enemy_index]
	var defense_dummy:Dictionary=main.enemies[-1]
	main.heroes[0].pos=defense_dummy.pos+Vector2(100,0);main.heroes[0].dest=main.heroes[0].pos;main.heroes[0].suppress_auto_target=true
	var defense_health_before:float=main.heroes[0].hp
	defense_dummy.cooldown=0.0
	main._process(.5);main._process(.5);main._process(.5)
	TestSupport.check(errors,main.heroes[0].hp<defense_health_before,"The enabled defense dummy should attack a hero who enters its short stationary range.")
	main.toggle_testing_dummy_attacks()
	defense_dummy.cooldown=0.0
	var disabled_health_before:float=main.heroes[0].hp
	main._process(2.0)
	TestSupport.check(errors,main.heroes[0].hp>=disabled_health_before,"Disabling dummy attacks should cancel and prevent defense-dummy attacks.")
	main.heroes[0].target=0;main.heroes[0].suppress_auto_target=false;main.selected=0;main.drag_has_moved=true;main.drag_target_type="ground";main.drag_cursor=Vector2(300,300);main.finish_hero_drag()
	TestSupport.check(errors,main.heroes[0].target==-1 and main.heroes[0].suppress_auto_target,"An explicit movement order should cancel and suppress automatic enemy reacquisition.")
	main.heroes[0].pos=main.heroes[1].pos+Vector2(50,0);main.heroes[0].dest=main.heroes[0].pos;main.assign_hero_ally(1,0);main.heroes[0].hp=main.heroes[0].max_hp
	var combat_event_count_before_basic_heal:int=main.combat_events.size()
	main._process(.5);main._process(.5)
	TestSupport.check(errors,main.heroes[1].heal_target==0 and int(main.heroes[1].basic_action_phase)==main.CombatRulesV1.BasicActionPhase.RECOVERY,"A healer should keep and execute its assigned heal cycle even while the target is at full health.")
	var basic_heal_events:Array=main.combat_events.slice(combat_event_count_before_basic_heal)
	TestSupport.check(errors,basic_heal_events.any(func(event):return event.event_type=="basic_heal_done" and event.source_action=="basic_heal" and "basic_action" in event.action_tags),"The assigned Cleric Basic Heal should use the distinct Basic Heal source and shared Basic Action grouping tag.")
	main.assign_hero_enemy(0,0);main.heroes[0].ability_cds=[0.0,0.0,0.0,0.0,0.0];main.begin_unit_cast(main.heroes[0],0,1.0,false)
	main.issue_hero_move(main.heroes[0],main.heroes[0].pos+Vector2(20,0))
	TestSupport.check(errors,main.heroes[0].active_cast.is_empty() and is_equal_approx(main.heroes[0].ability_cds[0],0.0),"Movement should interrupt an unreleased Basic Ability without applying its full cooldown.")
	main.assign_hero_enemy(0,0);main.begin_unit_cast(main.heroes[0],3,1.0,true);main.issue_hero_move(main.heroes[0],main.heroes[0].pos+Vector2(20,0))
	TestSupport.check(errors,main.heroes[0].active_cast.is_empty() and is_equal_approx(main.heroes[0].ability_cds[3],main.CombatRulesV1.HEROIC_INTERRUPT_COOLDOWN),"Movement should interrupt an unreleased Heroic and apply the shared ten-second interrupted cooldown.")
	main.heroes[0].ability_cds[2]=0.0;main.assign_hero_enemy(0,0);main.begin_unit_cast(main.heroes[0],2,0.0,false,2.0,false,8.0);main.update_unit_casts(main.heroes[0],.01)
	var initial_channel_ratio:float=main.hero_channel_remaining_ratio(main.heroes[0]);TestSupport.check(errors,initial_channel_ratio>=.99 and initial_channel_ratio<=1.0,"An active channel should expose its remaining progress for the compact bar beneath the hero health bar.")
	var channel_cooldown:float=main.heroes[0].ability_cds[2];main.interrupt_unit_action(main.heroes[0],"test interrupt")
	TestSupport.check(errors,main.heroes[0].active_channel.is_empty() and is_equal_approx(channel_cooldown,8.0) and is_equal_approx(main.heroes[0].ability_cds[2],8.0),"An interrupted active channel should keep its full cooldown and stop future channel time.")
	TestSupport.check(errors,main.hero_channel_remaining_ratio(main.heroes[0])<0.0,"The channel bar should disappear as soon as its channel ends or is interrupted.")
	var regen_dummy:Dictionary=main.enemies[0];regen_dummy.hp=regen_dummy.max_hp*.5;regen_dummy.seconds_since_damage=main.TESTING_DUMMY_REGEN_DELAY
	main._process(1.0)
	TestSupport.check(errors,is_equal_approx(regen_dummy.hp,regen_dummy.max_hp*.6),"An undamaged testing dummy should regenerate ten percent of maximum health per second.")
	regen_dummy.hp=0.0;regen_dummy.respawn_timer=0.0
	main._process(main.TESTING_DUMMY_RESPAWN_TIME+.01)
	TestSupport.check(errors,is_equal_approx(regen_dummy.hp,regen_dummy.max_hp),"A defeated testing dummy should respawn at full health after five seconds.")
	var item_guardian:Dictionary=main.heroes[0];var item_cleric:Dictionary=main.heroes[1];var item_rogue:Dictionary=main.heroes[2]
	var rogue_stats:Dictionary=main.hero_final_stats(main.state.heroes[4])
	TestSupport.check(errors,item_guardian.max_hp>GameData.CLASSES.Guardian.base_health and int(item_cleric.q_charges)==2 and rogue_stats.basic_action_interval<GameData.CLASSES.Rogue.basic_action_interval,"Equipped health, Twin Incantation charges, and rapid Basic Action speed should be active in battle.")
	item_guardian.shield=0.0;item_guardian.shield_sources=[];item_guardian.hp=item_guardian.max_hp*.60
	var item_attacker:={"level":1,"critical_chance":0.0,"critical_damage":2.0,"damage_multiplier":1.0,"pos":Vector2.ZERO,"active_effects":[],"passive_cooldowns":{},"equipped_items":[]}
	main.deal_damage(item_attacker,item_guardian,item_guardian.max_hp*.20,"basic_attack","true","threshold_test")
	TestSupport.check(errors,item_guardian.shield>=item_guardian.max_hp*.74 and item_guardian.power>item_guardian.base_power,"Last Dawn should create its sourced Shield and Power bonus on a half-health crossing.")
	main.deal_damage(item_attacker,item_guardian,20.0,"basic_attack","physical","retribution_test")
	TestSupport.check(errors,not item_guardian.retribution_charges.is_empty(),"Resolved Physical Damage should store a Retribution charge.")
	var item_dummy:Dictionary=main.enemies[1];var nearby_item_dummy:Dictionary=main.enemies[2];item_dummy.hp=item_dummy.max_hp;nearby_item_dummy.hp=nearby_item_dummy.max_hp;item_dummy.active_effects=[];nearby_item_dummy.active_effects=[]
	item_guardian.critical_chance=1.0;item_guardian.ability_cds=[4.0,4.0,4.0,4.0,0.0]
	var original_hp_before_wake:float=item_dummy.hp;var nearby_hp_before_wake:float=nearby_item_dummy.hp
	main.deal_damage(item_guardian,item_dummy,item_guardian.damage,"basic_attack","physical","item_attack_test")
	TestSupport.check(errors,item_dummy.hp<original_hp_before_wake and item_dummy.active_effects.is_empty() and nearby_item_dummy.hp<nearby_hp_before_wake and nearby_item_dummy.active_effects.any(func(effect):return effect.id=="vulnerable") and item_guardian.ability_cds[0]<4.0,"Stormbreaker should spare the original target from its explosion, deal Magical Damage and apply Vulnerable nearby, and let the critical attack trigger Endless Momentum.")
	item_dummy.hp=1.0;item_dummy.item_defeat_processed=false
	main.deal_damage(item_guardian,item_dummy,50.0,"basic_attack","physical","soul_test")
	TestSupport.check(errors,item_guardian.soul_furnace_stacks>=1,"Soul Furnace should gain a battle-only stack when an enemy is defeated.")
	item_cleric.shield=0.0;item_cleric.shield_sources=[];item_cleric.hp=item_cleric.max_hp;item_cleric.critical_chance=1.0
	main.deal_healing(item_cleric,item_cleric,10.0,"basic_ability","overflow_test")
	TestSupport.check(errors,item_cleric.shield>0.0 and item_cleric.shield<=item_cleric.max_hp*.60,"Overflowing Grace should convert critical direct overhealing into a capped Shield.")
	main.selected=1;item_cleric.heal_target=0;item_cleric.ability_cds=[0.0,0.0,0.0,0.0,0.0]
	main.use_ability(0,item_cleric.pos);main.use_ability(0,item_cleric.pos);main.use_ability(0,item_cleric.pos)
	TestSupport.check(errors,int(item_cleric.q_charges)==0 and item_cleric.q_charge_timers.size()==2,"Twin Incantation should permit exactly two independently recharging Q casts.")
	main.use_ability(2,item_cleric.pos)
	TestSupport.check(errors,int(item_cleric.q_charges)==1 and item_cleric.q_charge_timers.size()==1,"Casting E should restore one missing Twin Incantation Q charge.")
	main.update_item_runtime(item_cleric,8.1);item_cleric.ability_cds[1]=0.0;main.use_ability(1,item_cleric.pos)
	TestSupport.check(errors,item_cleric.pending_repeats.size()==1 and not item_cleric.borrowed_time_armed,"Borrowed Time should arm after eight seconds and schedule one non-recursive repeat.")
	main.update_cleric_runtime(.01)
	TestSupport.check(errors,main.effects.any(func(effect):return effect.kind=="cloud_serpent_projectile"),"An active Cloud Serpent attack should launch its own visible projectile from the host marker.")
	main.effects.clear()
	# Ranger V1 deals substantially more Basic Attack damage than the old placeholder;
	# keep this item-proc fixture alive through all three attacks.
	item_dummy.max_hp=maxf(float(item_dummy.max_hp),5000.0);item_dummy.hp=item_dummy.max_hp;item_rogue.thousand_cuts_count=0;item_rogue.equipped_items=[main.ItemData.create_instance("test_gloves_thousand_cuts","thousand_cuts_regression_fixture")]
	var hp_before_three:float=item_dummy.hp
	main.deal_damage(item_rogue,item_dummy,item_rogue.damage,"basic_attack","physical","cut_one");main.deal_damage(item_rogue,item_dummy,item_rogue.damage,"basic_attack","physical","cut_two")
	var hp_before_third:float=item_dummy.hp;main.deal_damage(item_rogue,item_dummy,item_rogue.damage,"basic_attack","physical","cut_three")
	TestSupport.check(errors,int(item_rogue.thousand_cuts_count)==0 and hp_before_third-item_dummy.hp>(hp_before_three-hp_before_third)*.45,"Every third Basic Attack should trigger the two Thousand Cuts extra strikes without advancing its own counter.")
	var templar_save_index:int=main.state.heroes.find_custom(func(saved_hero):return str(saved_hero.get("class",""))=="Templar")
	if templar_save_index>=0:
		main.state.selected_team=[templar_save_index,1,2,3];main.state.active_team=main.state.selected_team.duplicate();main.start_templar_testing_zone()
		var templar_index:int=main.heroes.find_custom(func(runtime_hero):return str(runtime_hero.get("class",""))=="Templar");var templar:Dictionary=main.heroes[templar_index];main.selected=templar_index
		TestSupport.check(errors,main.testing_zone_mode=="templar_range" and main.enemies.any(func(enemy):return "elite" in enemy.combat_tags) and main.enemies.any(func(enemy):return bool(enemy.get("boss",false))),"Templar Range should expose target-category and Boss fixtures.")
		templar.selected_talents={"tier_4":"templar_l18_2"};main.TemplarSystem.initialize_runtime(templar,true);templar.ability_cds=[0.0,0.0,0.0,0.0,0.0]
		TestSupport.check(errors,main.cast_templar_e(templar),"Shield Ally should cast when another living ally is in range.")
		var bearer:Dictionary=main.heroes.filter(func(ally):return ally!=templar and not ally.get("templar_shield_links",[]).is_empty())[0];var linked_enemy:Dictionary=main.enemies[0];var threat_before:float=float(linked_enemy.threat.get(templar_index,0.0));main.deal_damage(bearer,linked_enemy,20.0,"basic_attack","physical","templar_link_test")
		TestSupport.check(errors,float(linked_enemy.threat.get(templar_index,0.0))>threat_before and float(templar.templar_runtime.together_bucket)>0.0,"Shield Ally bearer damage should duplicate threat to its exact Templar and feed Together We Are Strong.")
		templar.hp=float(templar.max_hp)*.70;templar.templar_runtime.trait_cooldown=0.0;var hostile:Dictionary=linked_enemy;main.deal_damage(hostile,templar,10.0,"basic_attack","true","templar_trait_test")
		TestSupport.check(errors,main.TemplarSystem.named_shield_amount(templar,"templar_shield_overload")>0.0 and bool(templar.templar_runtime.trait_active),"Hostile damage below 75% should activate the exact Shield Overload source.")
		var dash_origin:Vector2=templar.pos;linked_enemy.pos=dash_origin+Vector2.RIGHT*90.0;linked_enemy.hp=linked_enemy.max_hp;templar.ability_cds[0]=0.0;main.cast_templar_q(templar,dash_origin+Vector2.RIGHT*200.0);for step in 20:main.update_templar_runtime(.06)
		TestSupport.check(errors,templar.pos.distance_to(dash_origin)<1.0 and linked_enemy.hp<linked_enemy.max_hp and templar.templar_runtime.blade_dashes.is_empty(),"Blade Dash should sweep contacts outward and return the Templar to the saved origin.")
	else:TestSupport.check(errors,false,"The testing save should include a Templar runtime fixture.")
	main.state.selected_team=[0,1,3,2];main.state.active_team=[0,1,3,2];main.start_testing_endless(17)
	TestSupport.check(errors,main.testing_zone_mode=="endless" and main.testing_endless_level==17 and main.battle_hero_indices==main.state.selected_team and main.enemies.size()==4 and main.enemies.all(func(enemy):return int(enemy.level)==17 and bool(enemy.get("testing_endless_enemy",false)) and enemy.rewarded),"Endless Arena should use the selected team and begin with enemies scaled to the selected fixed level.")
	var endless_mage_index:int=main.heroes.find_custom(func(hero):return str(hero.get("class",""))=="Mage");main.selected=endless_mage_index;main.focused_enemy_index=-1;main.heroes[endless_mage_index].target=-1;main.toast="";main.begin_ability(1)
	TestSupport.check(errors,main.toast=="","An unavailable target-dependent combat ability should fail silently without adding HUD instructions.")
	main.selected=0;main.dragging_hero=true;main.drag_target_type="enemy";main.drag_target_index=3;main.focused_enemy_index=3;main.heroes[0].target=3
	for endless_enemy in main.enemies:endless_enemy.hp=0.0
	main.update_testing_endless(.8);main.update_testing_endless(.4)
	TestSupport.check(errors,main.testing_endless_defeated==4 and main.enemies.size()==1 and int(main.enemies[0].level)==17 and not main.dragging_hero and main.drag_target_index==-1 and main.focused_enemy_index==-1 and int(main.heroes[0].target)==-1,"Endless Arena should safely clear stale targeting state, replace defeated enemies continuously, and retain the selected enemy level.")
	return errors
