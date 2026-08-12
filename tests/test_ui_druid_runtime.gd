extends RefCounted

const TestSupport=preload("res://tests/test_support.gd")

static func run(main:Node)->Array:
	var errors:Array=[]
	var druid_save_index:int=main.state.heroes.find_custom(func(saved):return str(saved.get("class",""))=="Druid")
	if druid_save_index<0:
		TestSupport.check(errors,false,"The testing save should include a Druid runtime fixture.")
		return errors
	main.state.selected_team=[druid_save_index];main.state.active_team=main.state.selected_team.duplicate();main.start_druid_testing_zone()
	var druid_index:int=main.heroes.find_custom(func(hero):return str(hero.get("class",""))=="Druid");var druid:Dictionary=main.heroes[druid_index];main.selected=druid_index
	TestSupport.check(errors,main.testing_zone_mode=="druid_range" and main.heroes.size()==4 and main.enemies.any(func(enemy):return bool(enemy.get("boss",false))),"Druid Range should launch with four allies and authored target-category fixtures.")

	# D is a real combat input, and world dragging can designate the Druid's Basic-Heal ally.
	var ally_index:int=0 if druid_index!=0 else 1;var ally:Dictionary=main.heroes[ally_index];ally.pos=druid.pos+Vector2(30,0);main.assign_hero_ally(druid_index,ally_index)
	var charges_before:int=int(druid.druid_runtime.d_slot.current_charges);main.begin_trait()
	TestSupport.check(errors,int(druid.druid_runtime.d_slot.current_charges)==charges_before-1 and float(druid.druid_runtime.innervates.get(str(ally.combat_id),0.0))>0.0,"D input should spend Innervate and apply it to the assigned living ally.")
	main.dragging_hero=true;main.drag_start=druid.pos;main.update_hero_drag(ally.pos)
	TestSupport.check(errors,main.drag_target_type=="ally" and main.drag_target_index==ally_index,"Dragging a Druid onto an ally should recognize the ally designation target.")
	main.dragging_hero=false

	# Nature's Swiftness transfers the already-resolved overheal exactly once.
	druid.selected_talents={"tier_5":"druid_l21_1"};main.DruidSystem.initialize_runtime(druid,true,"ui:druid:swiftness");druid.healing_multiplier=1.5;druid.critical_chance=0.0
	var hot_target:Dictionary=ally;var transfer_target:Dictionary=main.heroes.filter(func(candidate):return candidate!=druid and candidate!=hot_target)[0]
	hot_target.pos=druid.pos+Vector2(60,0);transfer_target.pos=hot_target.pos+Vector2(1,0);hot_target.hp=hot_target.max_hp-1.0;transfer_target.hp=transfer_target.max_hp-100.0;transfer_target.healing_taken_multiplier=0.5
	for candidate in main.heroes:
		if candidate!=hot_target and candidate!=transfer_target:candidate.pos=hot_target.pos+Vector2(500+main.heroes.find(candidate)*20,0)
	main.DruidSystem.apply_regrowth(druid,hot_target,false);var transfer_before:float=transfer_target.hp;var expected_overheal:float=float(main.DruidSystem.regrowth_tick_request(druid))*1.5-1.0
	main.druid_resolve_regrowth_tick(druid,druid.druid_runtime.regrowths[0],false)
	TestSupport.check(errors,is_equal_approx(transfer_target.hp-transfer_before,expected_overheal),"Nature's Swiftness should transfer exact resolved Regrowth overheal without reapplying outgoing healing or critical chance.")

	# Unrevealable targets still take Moonfire damage but do not gain the source marker used by Celestial Alignment.
	var moon_target:Dictionary=main.enemies[0];moon_target.pos=druid.pos+Vector2(100,0);moon_target.hp=moon_target.max_hp;moon_target.active_effects=[];main.StealthDetectionSystem.set_source(moon_target,"ui_unrevealable",true,true)
	var moon_hp_before:float=moon_target.hp;main.druid_resolve_moonfire(druid,moon_target.pos,false)
	TestSupport.check(errors,moon_target.hp<moon_hp_before and not moon_target.active_effects.any(func(effect):return str(effect.get("id",""))=="druid_moonfire_reveal:%s"%str(druid.combat_id)),"Moonfire should damage an unrevealable target without falsely granting its source reveal marker.")
	main.StealthDetectionSystem.set_source(moon_target,"ui_unrevealable",false)

	# Astral Communion uses the shared interruptible cast state and only resolves after completion.
	druid.selected_talents={"tier_3":"druid_l15_r2","tier_7":"druid_l27_r2"};druid.selected_heroic_id="druid_l15_r2";main.DruidSystem.initialize_runtime(druid,true,"ui:druid:astral");druid.ability_cds=[0.0,7.0,0.0,0.0,0.0];var origin:Vector2=druid.pos;var destination:=origin+Vector2(180,40)
	TestSupport.check(errors,main.cast_druid_ability(3,destination) and not druid.active_cast.is_empty(),"Astral Communion should begin a real one-second shared Heroic cast.")
	main.issue_hero_move(druid,origin+Vector2(10,0));main.update_druid_runtime(1.1)
	TestSupport.check(errors,druid.active_cast.is_empty() and is_equal_approx(druid.ability_cds[3],main.CombatRulesV1.HEROIC_INTERRUPT_COOLDOWN) and druid.pos.distance_to(destination)>1.0,"Movement should interrupt Astral Communion, apply the shared interrupted-Heroic cooldown, and prevent teleport resolution.")
	druid.pos=origin;druid.dest=origin;druid.ability_cds[3]=0.0;druid.ability_cds[1]=7.0;main.cast_druid_ability(3,destination);main.update_unit_casts(druid,1.01);main.update_druid_runtime(.01)
	TestSupport.check(errors,druid.pos.distance_to(destination)<1.0 and is_equal_approx(druid.ability_cds[1],7.0) and float(druid.druid_runtime.twilight_pending)>0.0,"A completed Astral Communion should teleport, cast a genuinely free Moonfire, and queue Twilight Dream without changing W cooldown.")

	# Twin Incantation is an internal charge timer; Innervate must accelerate it too.
	var cleric_index:int=main.heroes.find_custom(func(hero):return str(hero.get("class",""))=="Cleric")
	if cleric_index>=0:
		var cleric:Dictionary=main.heroes[cleric_index];druid.druid_runtime.innervates[str(cleric.combat_id)]=5.0;cleric.q_charges=0;cleric.q_charge_timers=[8.0];cleric.equipped_items=[main.ItemData.create_instance("test_crown_twin_incantations","druid_audit_twin")]
		main.update_item_runtime(cleric,2.0)
		TestSupport.check(errors,is_equal_approx(float(cleric.q_charge_timers[0]),5.0),"Innervate should accelerate Twin Incantation's internal Q charge timer by 50%.")
	else:TestSupport.check(errors,false,"Druid Range should include a Cleric for Innervate charge-timer coverage.")
	return errors
