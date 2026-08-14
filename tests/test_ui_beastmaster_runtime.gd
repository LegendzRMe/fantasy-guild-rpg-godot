extends RefCounted

const TestSupport=preload("res://tests/test_support.gd")

static func run(main:Node)->Array:
	var errors:Array=[]
	var save_index:int=main.state.heroes.find_custom(func(saved):return str(saved.get("class",""))=="Beastmaster")
	if save_index<0:TestSupport.check(errors,false,"The testing save should include a Beastmaster runtime fixture.");return errors
	main.state.selected_team=[save_index];main.state.active_team=[save_index];main.start_beastmaster_testing_zone();var hero:Dictionary=main.heroes.filter(func(member):return str(member.get("class",""))=="Beastmaster")[0];main.selected=main.heroes.find(hero)
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
	main.BlockChargeSystem.grant(hero,1,2);var charges_before:int=main.BlockChargeSystem.charges(hero);main.deal_damage(hostile,hero,100.0,"basic_attack","physical","Block test");TestSupport.check(errors,main.BlockChargeSystem.charges(hero)==charges_before-1,"A successful hostile Basic Attack should consume only Beastmaster's independent Block charge.")

	main.load_beastmaster_test_build(hero,0);misha=hero.beastmaster_runtime.misha;main.deal_damage(hostile,misha,float(misha.max_hp)+1.0,"basic_ability","magical","Misha defeat",false,"",[],false);TestSupport.check(errors,not main.BeastmasterSystem.misha_alive(hero) and is_equal_approx(float(hero.beastmaster_runtime.misha_respawn_remaining),15.0),"Live lethal damage should start Misha's 15-second respawn instead of removing the companion entity.")
	main.update_beastmaster_runtime(15.0);TestSupport.check(errors,main.BeastmasterSystem.misha_alive(hero),"Misha should safely re-enter the live encounter after 15 seconds.")
	return errors
