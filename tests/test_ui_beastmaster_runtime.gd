extends RefCounted

const TestSupport=preload("res://tests/test_support.gd")

static func matrix_source(archetype_name:String,team:String="enemy")->Dictionary:
	return {"class":archetype_name,"combat_id":"matrix:%s:%s"%[team,archetype_name],"combat_affiliation":team,"combat_team":team,"level":1,"hp":1000.0,"max_hp":1000.0,"armor":0.0,"critical_chance":0.0,"critical_damage":2.0,"damage_multiplier":1.0,"healing_multiplier":1.0,"active_effects":[],"passive_cooldowns":{},"equipped_items":[]}

static func run(main:Node)->Array:
	var errors:Array=[]
	var save_index:int=main.state.heroes.find_custom(func(saved):return str(saved.get("class",""))=="Beastmaster")
	if save_index<0:TestSupport.check(errors,false,"The testing save should include a Beastmaster runtime fixture.");return errors
	var cleric_save_index:int=main.state.heroes.find_custom(func(saved):return str(saved.get("class",""))=="Cleric")
	var test_party:Array=[save_index];if cleric_save_index>=0:test_party.append(cleric_save_index)
	main.state.selected_team=test_party;main.state.active_team=test_party.duplicate();main.start_beastmaster_testing_zone();var hero:Dictionary=main.heroes.filter(func(member):return str(member.get("class",""))=="Beastmaster")[0];main.selected=main.heroes.find(hero)
	TestSupport.check(errors,main.testing_zone_mode=="beastmaster_range" and main.enemies.any(func(enemy):return str(enemy.get("target_category",""))=="standard") and main.enemies.any(func(enemy):return str(enemy.get("target_category",""))=="boss") and main.enemies.any(func(enemy):return str(enemy.get("type",""))=="Defense Dummy"),"Beastmaster Range should launch with ordinary, hostile Basic Attack, and Boss interaction fixtures.")
	for foe in main.enemies:foe.pos=Vector2(1100,650);foe.hp=10000.0;foe.max_hp=10000.0;foe.armor=0.0;foe.active_effects=[]
	var ordinary:Dictionary=main.enemies.filter(func(enemy):return str(enemy.get("target_category",""))=="standard")[0];hero.pos=Vector2(300,400);hero.dest=hero.pos;ordinary.pos=hero.pos+Vector2(80,0);main.focused_enemy_index=main.enemies.find(ordinary)

	main.load_beastmaster_test_build(hero,0);hero.critical_chance=0.0;var before:=float(ordinary.hp)
	TestSupport.check(errors,main.cast_beastmaster_swoop(hero,ordinary.pos) and float(ordinary.hp)<before and hero.beastmaster_runtime.lesser_beasts.size()==1 and int(main.BeastmasterSystem.q_state(hero).charges)==1,"Live Swoop should damage, Slow, spend one charge, and register a targetable Lesser Beast.")
	var lesser:Dictionary=hero.beastmaster_runtime.lesser_beasts[0];var hostile:Dictionary=ordinary;hostile.combat_affiliation="enemy";hostile.combat_team="enemy";lesser.pos=hero.pos+Vector2(10,0)
	TestSupport.check(errors,main.unit_by_combat_id(str(lesser.combat_id))==lesser and lesser in main.player_combat_summons() and main.enemy_target_entity(hostile,main.heroes.find(hero))==lesser,"The live registry should expose a nearer Lesser Beast to lookup and enemy targeting.")

	main.load_beastmaster_test_build(hero,2);main.cast_beastmaster_swoop(hero,ordinary.pos);lesser=hero.beastmaster_runtime.lesser_beasts[0];var fresh_hp:=float(lesser.hp);main.deal_damage(hostile,lesser,200.0,"basic_attack","physical","Fresh test")
	TestSupport.check(errors,is_equal_approx(float(lesser.hp),fresh_hp) and main.StatusEffectSystem.has_control(hostile,"attack_speed"),"Fresh should prevent hostile damage while Primal still triggers from Basic Attack contact.")
	main.BeastmasterSystem.advance(hero,1.0,true);TestSupport.check(errors,float(lesser.hp)<fresh_hp,"Fresh protection must not pause natural Health decay.")

	main.load_beastmaster_test_build(hero,1);hero.armor=0.0;hero.hp=hero.max_hp*.5;var misha:Dictionary=hero.beastmaster_runtime.misha;misha.hp=misha.max_hp;misha.armor=0.0;var hero_before:=float(hero.hp);var misha_before:=float(misha.hp);var bond:Dictionary=main.deal_damage(hostile,hero,100.0,"basic_ability","physical","Bond test",false,"",[],false)
	TestSupport.check(errors,is_equal_approx(hero_before-float(hero.hp),50.0) and is_equal_approx(misha_before-float(misha.hp),50.0) and is_equal_approx(float(bond.redirected_damage),50.0),"Protective Bond should split the pre-mitigation packet and resolve each half against its recipient.")
	misha.hp=misha.max_hp-100.0;var heal:Dictionary=main.deal_healing(hero,misha,60.0,"basic_heal","Ordinary heal");TestSupport.check(errors,is_equal_approx(float(heal.effective_amount),60.0) and misha in main.player_healable_units(),"Misha should participate in ordinary allied healing while disposable beasts remain excluded.")
	var cleric_index:int=main.heroes.find_custom(func(member):return str(member.get("class",""))=="Cleric")
	TestSupport.check(errors,cleric_index>=0,"The Beastmaster integration fixture should include a healer for manual companion targeting.")
	if cleric_index>=0:
		main.assign_hero_ally_unit(cleric_index,misha);TestSupport.check(errors,str(main.heroes[cleric_index].assigned_target_id)==str(misha.combat_id) and str(main.heroes[cleric_index].assigned_target_kind)=="ally","A healer should be able to manually designate Misha as its ordinary allied-healing target.")
	main.BlockChargeSystem.grant(hero,1,2);var charges_before:int=main.BlockChargeSystem.charges(hero);main.deal_damage(hostile,hero,100.0,"basic_attack","physical","Block test");TestSupport.check(errors,main.BlockChargeSystem.charges(hero)==charges_before-1,"A successful hostile Basic Attack should consume only Beastmaster's independent Block charge.")

	main.load_beastmaster_test_build(hero,1);misha=hero.beastmaster_runtime.misha;main.deal_damage(hostile,misha,float(misha.max_hp)+1.0,"basic_ability","magical","Misha defeat",false,"",[],false);TestSupport.check(errors,not main.BeastmasterSystem.misha_alive(hero) and is_equal_approx(float(hero.beastmaster_runtime.misha_respawn_remaining),15.0),"Live lethal damage should start Misha's 15-second respawn instead of removing the companion entity.")
	TestSupport.check(errors,main.cast_beastmaster_swoop(hero,ordinary.pos) and not main.cast_beastmaster_charge(hero,ordinary.pos) and not main.cast_beastmaster_greater(hero) and not main.BeastmasterSystem.cast_bestial(hero) and not main.cast_beastmaster_d(hero),"Misha's defeat should lock W, E, Bestial Wrath, and the command while leaving the Misha-independent Q usable.")
	main.update_beastmaster_runtime(15.0);TestSupport.check(errors,main.BeastmasterSystem.misha_alive(hero),"Misha should safely re-enter the live encounter after 15 seconds.")

	# Every registered class can participate in shared hostile-damage and allied-healing
	# packets involving Beastmaster entities without a class-specific resolver failure.
	main.load_beastmaster_test_build(hero,0);misha=hero.beastmaster_runtime.misha;lesser=main.BeastmasterSystem.create_beast(hero,"lesser",hero.pos);hero.beastmaster_runtime.lesser_beasts.append(lesser);lesser.fresh_remaining=0.0
	for archetype in main.CLASSES.keys():
		var enemy_source:=matrix_source(str(archetype));if str(archetype)=="Sentinel":main.SentinelSystem.initialize_runtime(enemy_source,false)
		var lesser_before:=float(lesser.hp);var damage_result:Dictionary=main.deal_damage(enemy_source,lesser,1.0,"basic_ability","true","Cross-class matrix",false,"matrix_damage",[],false)
		TestSupport.check(errors,is_equal_approx(float(damage_result.resolved_damage),1.0) and is_equal_approx(lesser_before-float(lesser.hp),1.0),"%s damage should resolve against a targetable Lesser Beast."%str(archetype))
		var healer_source:=matrix_source(str(archetype),"player");misha.hp=maxf(1.0,float(misha.max_hp)-10.0);var heal_result:Dictionary=main.deal_healing(healer_source,misha,1.0,"basic_heal","Cross-class matrix")
		TestSupport.check(errors,is_equal_approx(float(heal_result.effective_amount),1.0),"%s ordinary healing should resolve on Misha."%str(archetype))
		var forbidden:Dictionary=main.deal_healing(healer_source,lesser,10.0,"basic_heal","Cross-class matrix");TestSupport.check(errors,bool(forbidden.get("blocked",false)) and is_equal_approx(float(forbidden.effective_amount),0.0),"%s ordinary healing must not extend a disposable Beast."%str(archetype))

	# Shared controls must change autonomous summon behavior and expire normally.
	ordinary.hp=ordinary.max_hp;ordinary.pos=hero.pos+Vector2(200,0);lesser.pos=hero.pos;lesser.target_id=str(ordinary.combat_id);lesser.priority_target_id="";lesser.attack_cooldown=0.0
	main.CombatSystem.apply_control(lesser,"root",1.0);var rooted_position:=Vector2(lesser.pos);main.update_beast_ai(hero,lesser,"lesser",.25);TestSupport.check(errors,Vector2(lesser.pos)==rooted_position,"Root should stop a Lesser Beast from moving toward its target.")
	main.update_timed_combat_effects(lesser,1.0);TestSupport.check(errors,not main.StatusEffectSystem.has_control(lesser,"root"),"Disposable-beast control effects should expire through the shared timed-effect lifecycle.")
	ordinary.pos=lesser.pos+Vector2(20,0);var target_before:=float(ordinary.hp);main.CombatSystem.apply_control(lesser,"stun",1.0);main.update_beast_ai(hero,lesser,"lesser",.1);TestSupport.check(errors,is_equal_approx(float(ordinary.hp),target_before),"Stun should prevent a Lesser Beast Basic Attack.")
	main.update_timed_combat_effects(lesser,1.0);main.StatusEffectSystem.apply_blind(lesser,1.0);lesser.attack_cooldown=0.0;main.update_beast_ai(hero,lesser,"lesser",.1);TestSupport.check(errors,is_equal_approx(float(ordinary.hp),target_before) and float(lesser.attack_cooldown)>0.0,"Blind should make an autonomous Beast miss without granting a successful attack proc.")
	main.update_timed_combat_effects(lesser,1.0);main.StatusEffectSystem.apply_source_control(lesser,"matrix","attack_speed",2.5,.2);lesser.attack_cooldown=0.0;main.update_beast_ai(hero,lesser,"lesser",.1);TestSupport.check(errors,is_equal_approx(float(lesser.attack_cooldown),1.25),"Attack-speed suppression should lengthen a Lesser Beast's next one-second attack cadence to 1.25 seconds.")
	var normal_beast:Dictionary=main.BeastmasterSystem.create_beast(hero,"lesser",hero.pos);var slowed_beast:Dictionary=main.BeastmasterSystem.create_beast(hero,"lesser",hero.pos);normal_beast.target_id=str(ordinary.combat_id);slowed_beast.target_id=str(ordinary.combat_id);ordinary.pos=hero.pos+Vector2(200,0);main.CombatSystem.apply_control(slowed_beast,"slow",1.0,.5);main.update_beast_ai(hero,normal_beast,"lesser",.25);main.update_beast_ai(hero,slowed_beast,"lesser",.25);TestSupport.check(errors,Vector2(slowed_beast.pos).distance_to(hero.pos)<Vector2(normal_beast.pos).distance_to(hero.pos),"Slow magnitude should reduce autonomous Beast movement distance.")

	# Primal is a contact mechanic: it applies before Fresh/Block and works for all
	# four protected categories, refreshes by source, and respects Boss profiles.
	main.load_beastmaster_test_build(hero,2);misha=hero.beastmaster_runtime.misha;lesser=main.BeastmasterSystem.create_beast(hero,"lesser",hero.pos);var greater:Dictionary=main.BeastmasterSystem.create_beast(hero,"greater",hero.pos);hero.beastmaster_runtime.lesser_beasts=[lesser];hero.beastmaster_runtime.greater_beasts=[greater]
	for contacted in [hero,misha,lesser,greater]:
		var attacker:=matrix_source("Guardian");var contacted_before:=float(contacted.hp);main.deal_damage(attacker,contacted,10.0,"basic_attack","physical","Primal matrix",false,"",[],false)
		TestSupport.check(errors,main.StatusEffectSystem.has_control(attacker,"attack_speed"),"Primal should trigger when a hostile Basic Attack contacts %s."%str(contacted.get("beast_category","Beastmaster")))
		if str(contacted.get("beast_category","")) in ["lesser","greater"]:TestSupport.check(errors,is_equal_approx(float(contacted.hp),contacted_before),"Fresh should prevent damage after Primal contact without suppressing Primal.")
	var boss_attacker:=matrix_source("Guardian");boss_attacker.boss=true;main.deal_damage(boss_attacker,lesser,10.0,"basic_attack","physical","Primal Boss",false,"",[],false);var primal_effects:Array=boss_attacker.active_effects.filter(func(effect):return str(effect.get("source_id","")).begins_with("beastmaster_primal:"));main.deal_damage(boss_attacker,lesser,10.0,"basic_attack","physical","Primal Boss",false,"",[],false)
	TestSupport.check(errors,primal_effects.size()==1 and is_equal_approx(float(primal_effects[0].amount),.1) and is_equal_approx(float(primal_effects[0].remaining_duration),1.25) and boss_attacker.active_effects.size()==1,"Primal should refresh one source-aware Boss-profiled 10%/1.25-second suppression rather than stacking.")

	# Protective Bond must split raw damage before each recipient's independent
	# Armor, Block, Shield, and defeat handling, while excluding self damage.
	main.load_beastmaster_test_build(hero,1);misha=hero.beastmaster_runtime.misha;hero.armor=100.0;misha.armor=0.0;hero.hp=hero.max_hp*.5;misha.hp=misha.max_hp;var armored_before:=float(hero.hp);var unarmored_before:=float(misha.hp);var mitigated_bond:Dictionary=main.deal_damage(hostile,hero,200.0,"basic_ability","physical","Bond armor",false,"",[],false)
	TestSupport.check(errors,armored_before-float(hero.hp)<unarmored_before-float(misha.hp) and is_equal_approx(float(mitigated_bond.raw_amount),200.0),"Bond should preserve total raw damage while resolving each 100-point half against recipient-specific Armor.")
	hero.armor=0.0;hero.hp=hero.max_hp*.5;misha.hp=misha.max_hp;main.apply_unit_shield(hero,misha,40.0,"Bond shield","matrix_bond_shield",INF);var shield_before:=float(misha.shield);main.deal_damage(hostile,hero,100.0,"basic_ability","true","Bond shield",false,"",[],false);TestSupport.check(errors,is_equal_approx(shield_before-float(misha.shield),40.0),"The redirected half should independently consume the healthier partner's Shield.")
	hero.hp=hero.max_hp*.5;misha.hp=misha.max_hp;var self_before:=float(misha.hp);main.deal_damage(hero,hero,100.0,"basic_ability","true","Self damage",false,"",[],false);TestSupport.check(errors,is_equal_approx(float(misha.hp),self_before),"Protective Bond must not redirect non-hostile self damage.")

	# Heroic targeting, Pack Commander arrival attacks, and Wildfire overlap all
	# execute through the live resolver with their intended caps and exclusions.
	main.load_beastmaster_test_build(hero,2);hero.critical_chance=0.0;hero.pos=Vector2(300,400)
	for index in main.enemies.size():main.enemies[index].pos=hero.pos+Vector2(100+index*8,0);main.enemies[index].hp=12000.0;main.enemies[index].max_hp=12000.0;main.enemies[index].armor=0.0;main.enemies[index].active_effects=[]
	var damaged_before:Array=main.enemies.map(func(enemy):return float(enemy.hp));TestSupport.check(errors,main.cast_beastmaster_boars(hero,hero.pos+Vector2.RIGHT*500.0),"The live Boars Heroic should cast with eligible line targets.");var damaged_count:=0
	for index in main.enemies.size():if float(main.enemies[index].hp)<float(damaged_before[index]):damaged_count+=1
	TestSupport.check(errors,damaged_count==5,"Unleash the Boars should damage at most five qualifying immediate targets once each.")
	main.load_beastmaster_test_build(hero,3);ordinary=main.enemies[0];ordinary.pos=hero.pos+Vector2(30,0);ordinary.hp=12000.0;ordinary.armor=0.0;hero.beastmaster_runtime.lesser_beasts=[main.BeastmasterSystem.create_beast(hero,"lesser",ordinary.pos)];hero.beastmaster_runtime.greater_beasts=[main.BeastmasterSystem.create_beast(hero,"greater",ordinary.pos)];var commander_before:=float(ordinary.hp);var commander_plan:Dictionary=main.BeastmasterSystem.charge_plan(hero,[ordinary],str(ordinary.combat_id));main.update_beast_ai(hero,hero.beastmaster_runtime.lesser_beasts[0],"lesser",.01);main.update_beast_ai(hero,hero.beastmaster_runtime.greater_beasts[0],"greater",.01);TestSupport.check(errors,bool(commander_plan.cast) and float(ordinary.hp)<commander_before and main.BeastmasterSystem.disposable_beasts(hero).all(func(beast):return not bool(beast.pack_assault_pending) and str(beast.priority_target_id)==str(ordinary.combat_id)),"Pack Commander should give every disposable Beast one arrival Basic Attack and retain target priority.")
	main.load_beastmaster_test_build(hero,2);ordinary=main.enemies[0];ordinary.pos=hero.pos;ordinary.hp=12000.0;ordinary.armor=0.0;hero.beastmaster_runtime.lesser_beasts=[main.BeastmasterSystem.create_beast(hero,"lesser",ordinary.pos),main.BeastmasterSystem.create_beast(hero,"lesser",ordinary.pos)]
	for beast in hero.beastmaster_runtime.lesser_beasts:
		beast.attack_cooldown=99.0
	hero.beastmaster_runtime.misha.attack_cooldown=99.0
	hero.beastmaster_runtime.wildfire_tick=0.0
	var wildfire_before:=float(ordinary.hp)
	main.update_beastmaster_runtime(.01)
	var wildfire_expected:float=main.BeastmasterData.scaled(float(main.BeastmasterData.VALUES.wildfire_damage),int(hero.level))*2.0
	TestSupport.check(errors,is_equal_approx(wildfire_before-float(ordinary.hp),wildfire_expected) and int(hero.beastmaster_runtime.fury)==0,"Two distinct Wildfire sources should overlap exactly once each without granting Fury.")
	return errors
