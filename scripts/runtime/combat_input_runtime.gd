extends "res://scripts/runtime/ability_runtime.gd"

func load_mage_test_build(hero:Dictionary,heroic_id:String)->void:
	var health_ratio:=float(hero.hp)/maxf(1.0,float(hero.max_hp));hero.level=30;hero.power=MageData.scaled(float(MageData.VALUES.basic_attack_damage),30);hero.base_power=hero.power;hero.max_hp=MageData.scaled(float(MageData.VALUES.health),30);hero.hp=maxf(1.0,hero.max_hp*health_ratio);hero.basic_action_amount=hero.power;hero.damage=hero.power
	var phoenix_build:bool=heroic_id=="mage_l15_r1"
	hero.selected_heroic_id=heroic_id;hero.selected_talents={"tier_1":"mage_l9_1","tier_2":"mage_l12_2" if phoenix_build else "mage_l12_3","tier_3":heroic_id,"tier_4":"mage_l18_2" if phoenix_build else "mage_l18_3","tier_5":"mage_l21_1","tier_6":"mage_l24_3" if phoenix_build else "mage_l24_2","tier_7":"mage_l27_r1" if phoenix_build else "mage_l27_r2","tier_8":"mage_l30_2" if phoenix_build else "mage_l30_3"};MageSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_level_one_mage_test(hero:Dictionary)->void:
	hero.level=1;hero.power=float(MageData.VALUES.basic_attack_damage);hero.base_power=hero.power;hero.max_hp=float(MageData.VALUES.health);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id="";hero.selected_talents={};MageSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_rogue_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=RogueData.TEST_BUILDS[clampi(build_index,0,RogueData.TEST_BUILDS.size()-1)];var level:int=int(build.level);hero.level=level;hero.power=RogueData.scaled(float(RogueData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=RogueData.scaled(float(RogueData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);RogueSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_slayer_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=SlayerData.TEST_BUILDS[clampi(build_index,0,SlayerData.TEST_BUILDS.size()-1)];var level:int=int(build.level);hero.level=level;hero.power=SlayerData.scaled(float(SlayerData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=SlayerData.scaled(float(SlayerData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);SlayerSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_priest_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=PriestData.TEST_BUILDS[clampi(build_index,0,PriestData.TEST_BUILDS.size()-1)];var level:int=int(build.level);hero.level=level;hero.power=PriestData.scaled(float(PriestData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=PriestData.scaled(float(PriestData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);PriestSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_shaman_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=ShamanData.TEST_BUILDS[clampi(build_index,0,ShamanData.TEST_BUILDS.size()-1)];var level:int=int(build.level);var mastery:Dictionary=hero.get("shaman_runtime",{}).get("mastery",{}).duplicate(true)
	hero.level=level;hero.power=ShamanData.scaled(float(ShamanData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=ShamanData.scaled(float(ShamanData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);ShamanSystem.initialize_runtime(hero,true,mastery);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_templar_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=TemplarData.TEST_BUILDS[clampi(build_index,0,TemplarData.TEST_BUILDS.size()-1)];var level:int=int(build.level)
	hero.level=level;hero.power=TemplarData.scaled(float(TemplarData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=TemplarData.scaled(float(TemplarData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);TemplarSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_protector_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=ProtectorData.TEST_BUILDS[clampi(build_index,0,ProtectorData.TEST_BUILDS.size()-1)]
	var level:int=int(build.level)
	hero.level=level;hero.power=ProtectorData.scaled(float(ProtectorData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=ProtectorData.scaled(float(ProtectorData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.range=float(ProtectorData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);ProtectorSystem.initialize_runtime(hero,true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_sentinel_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=SentinelData.TEST_BUILDS[clampi(build_index,0,SentinelData.TEST_BUILDS.size()-1)];var level:int=int(build.level)
	hero.level=level;hero.power=SentinelData.scaled(float(SentinelData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=SentinelData.scaled(float(SentinelData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.range=float(SentinelData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);SentinelSystem.initialize_runtime(hero,true)
	hero.sentinel_runtime.e_quest_stacks=int(build.get("quest_stacks",0));hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_huntsman_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=HuntsmanData.TEST_BUILDS[clampi(build_index,0,HuntsmanData.TEST_BUILDS.size()-1)];var level:int=int(build.level)
	hero.level=level;hero.power=HuntsmanData.scaled(float(HuntsmanData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=HuntsmanData.scaled(float(HuntsmanData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.range=float(HuntsmanData.SPACE.human_basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);HuntsmanSystem.initialize_runtime(hero,true,"testing:hunt")
	hero.huntsman_runtime.cocktail_quest_stacks=int(build.get("quest_stacks",0));hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func load_druid_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=DruidData.TEST_BUILDS[clampi(build_index,0,DruidData.TEST_BUILDS.size()-1)];var level:int=int(build.level)
	hero.level=level;hero.power=DruidData.scaled(float(DruidData.VALUES.basic_attack_damage),level);hero.base_power=hero.power;hero.max_hp=DruidData.scaled(float(DruidData.VALUES.health),level);hero.hp=hero.max_hp;hero.basic_action_amount=hero.power;hero.damage=hero.power;hero.range=float(DruidData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);DruidSystem.initialize_runtime(hero,true,"testing:druid");hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func handle_druid_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="druid_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Druid":hero=candidate;break
	if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_5:
		var build_index:=int(event.keycode-KEY_1);load_druid_test_build(hero,build_index);flash("Druid build: %s"%str(DruidData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.ctrl_pressed:return false
	match event.keycode:
		KEY_1,KEY_2,KEY_3,KEY_4:
			var index:=int(event.keycode-KEY_1)
			if index<heroes.size():DruidSystem.apply_regrowth(hero,heroes[index],true);flash("Regrowth applied to ally %d"%(index+1))
		KEY_C:hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.druid_runtime.d_slot=AbilitySlotSystem.create(2 if DruidSystem.has_talent(hero,"druid_l12_3") else 1,float(DruidData.VALUES.innervate_cooldown),AbilitySlotSystem.RechargeMode.INDEPENDENT);flash("Druid cooldowns and Innervate charges reset")
		KEY_Q:
			if hero.druid_runtime.regrowths.is_empty():DruidSystem.apply_regrowth(hero,hero,false)
			for tick in DruidSystem.bonus_regrowth_ticks(hero):druid_resolve_regrowth_tick(hero,tick,true)
			flash("Regrowth bonus tick triggered")
		KEY_X:hero.druid_runtime.regrowths.clear();hero.druid_runtime.mini_hots.clear();flash("Druid HoTs cleared")
		KEY_M:
			var target:Dictionary=heroes[1] if heroes.size()>1 else hero;DruidSystem.designate_basic_healing_target(hero,target);DruidSystem.note_basic_attack(hero,enemies[0] if not enemies.is_empty() else {},{"resolved_damage":60.0},heroes);flash("Basic healing target and one mini-HoT staged")
		KEY_O:
			var target:Dictionary=heroes[1] if heroes.size()>1 else hero;DruidSystem.designate_basic_healing_target(hero,target);for ignored in 4:DruidSystem.note_basic_attack(hero,enemies[0] if not enemies.is_empty() else {},{"resolved_damage":60.0},heroes);flash("Four overlapping mini-HoTs staged")
		KEY_G:hero.healing_multiplier=1.20 if is_equal_approx(float(hero.get("healing_multiplier",1.0)),1.0) else 1.0;flash("Generic healing multiplier: %.2f"%float(hero.healing_multiplier))
		KEY_T:hero.healing_over_time_multiplier=1.20 if is_equal_approx(float(hero.get("healing_over_time_multiplier",1.0)),1.0) else 1.0;flash("Generic HoT multiplier: %.2f"%float(hero.healing_over_time_multiplier))
		KEY_H:hero.hp=float(hero.max_hp)*(.20 if DruidSystem.health_ratio(hero)>.75 else .80);flash("Druid Health: %.0f%%"%(DruidSystem.health_ratio(hero)*100.0))
		KEY_S:
			if heroes.size()>1:for control in ["stun","root","slow","silence","fear"]:CombatSystem.apply_control(heroes[1],control,30.0,.25);flash("All Nature's Cure control fixtures applied")
		KEY_V:hero.druid_runtime.vengeful_quest_stacks=10;flash("Vengeful quest stacks: 10")
		KEY_P:hero.druid_runtime.treants.append(DruidSystem.create_treant(hero,hero.pos+Vector2(80,0)));flash("Treant summoned")
		KEY_R:DruidSystem.refresh_all_regrowths(hero);flash("Twilight refresh triggered")
		KEY_A:hero.druid_runtime.tranquility_remaining=float(DruidData.VALUES.tranquility_duration);hero.druid_runtime.tranquility_tick=0.0;flash("Tranquility active")
		KEY_L:hero.druid_runtime.lunar_shower_stacks=3;hero.druid_runtime.lunar_shower_remaining=6.0;flash("Lunar Shower: +60%")
		KEY_N:
			if heroes.size()>1:DruidSystem.apply_regrowth(hero,heroes[1],false);var result:=DruidSystem.cast_innervate(hero,heroes[1]);if float(result.get("communion",0.0))>0.0:druid_heal(hero,heroes[1],float(result.communion),"basic_ability","Nature's Communion","druid_nature_communion",["healing"])
			flash("Nature's Communion staged")
		_:return false
	queue_redraw();return true

func load_warrior_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=WarriorData.TEST_BUILDS[clampi(build_index,0,WarriorData.TEST_BUILDS.size()-1)];var level:=int(build.level)
	var banner_source:="warrior_banner:%s"%str(hero.get("combat_id",""))
	for unit in heroes:
		unit.active_effects=unit.get("active_effects",[]).filter(func(effect):return not str(effect.get("source_id",effect.get("id",""))).begins_with("warrior_") and str(effect.get("id",""))!=banner_source);unit.temporary_armor_sources=unit.get("temporary_armor_sources",[]).filter(func(source):return not str(source.get("id",""))==banner_source);HealingReceivedModifierSystem.remove(unit,banner_source);QuestProgressModifierSystem.remove(unit,banner_source)
	hero.level=level;hero.base_power=WarriorData.scaled(float(WarriorData.VALUES.basic_attack_damage),level);hero.power=hero.base_power;hero.max_hp=WarriorData.scaled(float(WarriorData.VALUES.health),level);hero.warrior_base_max_hp=hero.max_hp;hero.hp=hero.max_hp;hero.health_regeneration=WarriorData.scaled(float(WarriorData.VALUES.health_regeneration),level);hero.base_basic_action_interval=float(WarriorData.VALUES.basic_attack_interval);hero.range=float(WarriorData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);WarriorSystem.initialize_runtime(hero,true,"testing:warrior");hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]
	if bool(build.get("complete_high_king",false)):for key in ["high_weapon","high_honors","high_endurance"]:hero.warrior_runtime.encounter_progress[key]={"high_weapon":50,"high_honors":5,"high_endurance":15}[key]

func handle_warrior_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="warrior_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Warrior":hero=candidate;break
	if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_6:
		var build_index:=int(event.keycode-KEY_1);load_warrior_test_build(hero,build_index);flash("Warrior build: %s"%str(WarriorData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.ctrl_pressed:return false
	match event.keycode:
		KEY_C:hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.warrior_runtime.heroic_strike_cooldown=0.0;hero.warrior_runtime.taunt_cooldown=0.0;hero.warrior_runtime.shattering_cooldown=0.0;hero.warrior_runtime.w_slot=AbilitySlotSystem.create(1 if WarriorSystem.has_talent(hero,"warrior_l18_1") else 2,5.0 if WarriorSystem.has_talent(hero,"warrior_l18_1") else 10.0);flash("Warrior cooldowns reset")
		KEY_Q:hero.warrior_runtime.lions_maw=25;flash("Lion's Maw complete")
		KEY_K:for key in ["high_weapon","high_honors","high_endurance"]:hero.warrior_runtime.encounter_progress[key]={"high_weapon":50,"high_honors":5,"high_endurance":15}[key];flash("High King's Quest complete")
		KEY_B:hero.warrior_runtime.banner_cooldown=0.0;flash("Banner ready")
		KEY_H:hero.hp=float(hero.max_hp)*(.25 if float(hero.hp)/float(hero.max_hp)>.5 else .85);flash("Warrior Health: %d%%"%int(100.0*hero.hp/hero.max_hp))
		KEY_S:
			var target=warrior_enemy_target(hero);if target!=null:apply_unit_shield(hero,target,1800.0,"Warrior Range","warrior_range_manual");flash("Target shield applied")
		_:return false
	queue_redraw();return true

func load_death_knight_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=DeathKnightData.TEST_BUILDS[clampi(build_index,0,DeathKnightData.TEST_BUILDS.size()-1)];var level:=int(build.level);var mastery:Dictionary=hero.get("death_knight_runtime",{}).get("mastery",{}).duplicate(true)
	if bool(build.get("mastered",false)):mastery["death_knight_l9_1"]=int(DeathKnightData.VALUES.frost_presence_mastery)
	for unit in heroes:
		unit.active_effects=unit.get("active_effects",[]).filter(func(effect):return not str(effect.get("source_id",effect.get("id",""))).begins_with("death_knight_"));unit.healing_received_sources=unit.get("healing_received_sources",[]).filter(func(source):return not str(source.get("source_id","")).begins_with("death_knight_"))
	hero.level=level;hero.base_power=DeathKnightData.scaled(float(DeathKnightData.VALUES.basic_attack_damage),level);hero.power=hero.base_power;hero.max_hp=DeathKnightData.scaled(float(DeathKnightData.VALUES.health),level);hero.hp=hero.max_hp;hero.health_regeneration=DeathKnightData.scaled(float(DeathKnightData.VALUES.health_regeneration),level);hero.base_basic_action_interval=float(DeathKnightData.VALUES.basic_attack_interval);hero.basic_attack_interval=hero.base_basic_action_interval;hero.range=float(DeathKnightData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);DeathKnightSystem.initialize_runtime(hero,true,mastery,"testing:death_knight");hero.ability_cds=[0.0,0.0,0.0,0.0,0.0]

func handle_death_knight_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="death_knight_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Death Knight":hero=candidate;break
	if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_6:
		var build_index:=int(event.keycode-KEY_1);load_death_knight_test_build(hero,build_index);flash("Death Knight build: %s"%str(DeathKnightData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.ctrl_pressed:return false
	match event.keycode:
		KEY_C:hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.death_knight_runtime.frostmourne_cooldown=0.0;hero.death_knight_runtime.tempest.cooldown=0.0;hero.death_knight_runtime.army_slot.current_charges=int(DeathKnightData.VALUES.army_max_charges);hero.death_knight_runtime.army_slot.timers=[];flash("Death Knight cooldowns reset")
		KEY_F:hero.death_knight_runtime.frostmourne_stacks=int(hero.death_knight_runtime.frostmourne_stacks)+1;flash("Frostmourne stack +1")
		KEY_Q:DeathKnightSystem.add_frost_presence_progress(hero,["test"]);flash("Frost Presence progress +1")
		KEY_M:hero.death_knight_runtime.mastery["death_knight_l9_1"]=50;flash("Frost Presence MASTERED")
		KEY_E:cast_death_knight_tempest(hero);flash("Frozen Tempest toggled")
		KEY_G:hero.death_knight_runtime.army_slot.current_charges=6;flash("Army charges: 6")
		KEY_S:if not enemies.is_empty():CombatSystem.apply_control(enemies[0],"slow",30.0,.30);flash("Target Slowed")
		KEY_R:if not enemies.is_empty():CombatSystem.apply_control(hero,"stun",3.0);flash("Rime Stun test")
		KEY_B:CombatSystem.apply_blind(hero,4.0);flash("Blind attempted")
		_:return false
	queue_redraw();return true

func handle_huntsman_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="huntsman_range":return false
	var hero=null
	for candidate in heroes:if str(candidate.get("class",""))=="Huntsman":hero=candidate;break
	if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_5:
		var build_index:=int(event.keycode-KEY_1);load_huntsman_test_build(hero,build_index);flash("Huntsman build: %s"%str(HuntsmanData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.ctrl_pressed:return false
	var target=huntsman_debug_target()
	match event.keycode:
		KEY_H:HuntsmanSystem.change_form(hero,"human","Testing shortcut",battle_time);flash("Huntsman: Human")
		KEY_W:HuntsmanSystem.change_form(hero,"worgen","Testing shortcut",battle_time);flash("Huntsman: Worgen")
		KEY_C:hero.huntsman_runtime.human_q_cooldown=0.0;hero.huntsman_runtime.worgen_q_cooldown=0.0;hero.huntsman_runtime.shared_e_cooldown=0.0;hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];flash("Huntsman cooldowns reset")
		KEY_I:HuntsmanSystem.activate_inner_beast(hero);hero.ability_cds[1]=0.0;flash("Inner Beast active and ready")
		KEY_B:
			if BlockChargeSystem.charges(hero,"huntsman_block")>0:hero.huntsman_block={"charges":0,"maximum":2}
			else:BlockChargeSystem.grant(hero,2,2,"huntsman_block")
			flash("Block charges: %d"%BlockChargeSystem.charges(hero,"huntsman_block"))
		KEY_S:
			var stealth_on:=not StealthDetectionSystem.is_stealthed(hero);StealthDetectionSystem.set_stealth_source(hero,"huntsman_testing",stealth_on);flash("Stealth: %s"%str(stealth_on))
		KEY_Q:
			var quest_values:=[0,14,15];var quest_index:=(quest_values.find(int(hero.huntsman_runtime.cocktail_quest_stacks))+1)%quest_values.size();hero.huntsman_runtime.cocktail_quest_stacks=quest_values[quest_index];flash("Cocktail quest: %d / 15"%int(hero.huntsman_runtime.cocktail_quest_stacks))
		KEY_M:
			if str(hero.huntsman_runtime.marked_target_id)!="":HuntsmanSystem.clear_mark(hero);flash("Mark cleared")
			elif target!=null:HuntsmanSystem.apply_mark(hero,target);flash("Marked %s"%str(target.get("display_name",target.get("type","target"))))
		KEY_R:hero.huntsman_runtime.marked_reactivation=not bool(hero.huntsman_runtime.marked_reactivation);flash("Mark reactivation: %s"%str(hero.huntsman_runtime.marked_reactivation))
		KEY_G:
			if HuntsmanSystem.has_talent(hero,"huntsman_l27_r2"):hero.selected_talents.erase("tier_7")
			else:hero.selected_heroic_id="huntsman_l15_r2";hero.selected_talents["tier_3"]="huntsman_l15_r2";hero.selected_talents["tier_7"]="huntsman_l27_r2"
			flash("Gilnean Roulette: %s"%str(HuntsmanSystem.has_talent(hero,"huntsman_l27_r2")))
		KEY_P:hero.selected_talents["tier_4"]="huntsman_l18_3";flash("Pounce enabled")
		KEY_V:
			hero.huntsman_runtime.wizened_attacks=(int(hero.huntsman_runtime.wizened_attacks)+1)%4;hero.huntsman_runtime.wizened_remaining=5.0 if int(hero.huntsman_runtime.wizened_attacks)>0 else 0.0;flash("Wizened charges: %d"%int(hero.huntsman_runtime.wizened_attacks))
		KEY_L:
			if target==null:return true
			var controls:=["slow","root","stun"];var control_index:=int(hero.huntsman_runtime.get("testing_control_index",-1))+1;hero.huntsman_runtime.testing_control_index=control_index%controls.size();CombatSystem.apply_control(target,controls[hero.huntsman_runtime.testing_control_index],10.0,.30 if controls[hero.huntsman_runtime.testing_control_index]=="slow" else 1.0);flash("Applied %s"%controls[hero.huntsman_runtime.testing_control_index])
		KEY_A:
			if target==null:return true
			var armor_values:=[0.0,75.0,250.0];var armor_index:=(armor_values.find(float(target.get("armor",0.0)))+1)%armor_values.size();target.armor=armor_values[armor_index];flash("Target Armor: %d"%int(target.armor))
		KEY_1,KEY_2,KEY_3,KEY_4,KEY_5:
			if target==null:return true
			var stack_values:=[1,4,5,10,25];HuntsmanSystem.apply_mark(hero,target);hero.huntsman_runtime.mark_stacks=stack_values[int(event.keycode-KEY_1)];HuntsmanSystem.refresh_mark_source(hero,target);flash("Mark stacks: %d"%int(hero.huntsman_runtime.mark_stacks))
		_:return false
	queue_redraw();return true

func huntsman_debug_target():
	var enemy_index:=combat_enemy_target()
	if enemy_index>=0 and enemy_index<enemies.size() and enemies[enemy_index].hp>0.0:return enemies[enemy_index]
	for enemy in enemies:if enemy.hp>0.0:return enemy
	return null
	return false

func load_beastmaster_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=BeastmasterData.TEST_BUILDS[clampi(build_index,0,BeastmasterData.TEST_BUILDS.size()-1)];var level:=int(build.level)
	hero.level=level;hero.base_power=BeastmasterData.scaled(float(BeastmasterData.VALUES.basic_attack_damage),level);hero.power=hero.base_power;hero.max_hp=BeastmasterData.scaled(float(BeastmasterData.VALUES.health),level);hero.hp=hero.max_hp;hero.health_regeneration=BeastmasterData.scaled(float(BeastmasterData.VALUES.health_regeneration),level);hero.base_basic_action_interval=float(BeastmasterData.VALUES.basic_attack_interval);hero.basic_attack_interval=hero.base_basic_action_interval;hero.range=float(BeastmasterData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];BeastmasterSystem.initialize_runtime(hero,true,"testing:beastmaster")
	if int(build.get("fury",0))>=int(BeastmasterData.VALUES.fury_goal):hero.beastmaster_runtime.fury=int(BeastmasterData.VALUES.fury_goal);hero.beastmaster_runtime.fury_complete=true
	if float(build.get("apex_seconds",0.0))>0.0:BeastmasterSystem.advance(hero,float(build.apex_seconds),true)

func load_monk_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=MonkData.TEST_BUILDS[clampi(build_index,0,MonkData.TEST_BUILDS.size()-1)];var level:=int(build.level)
	hero.level=level;hero.base_power=MonkData.scaled(float(MonkData.VALUES.basic_attack_damage),level);hero.power=hero.base_power;hero.max_hp=MonkData.scaled(float(MonkData.VALUES.health),level);hero.hp=hero.max_hp;hero.health_regeneration=MonkData.scaled(float(MonkData.VALUES.health_regeneration),level);hero.base_basic_action_interval=float(MonkData.VALUES.basic_attack_interval);hero.basic_attack_interval=hero.base_basic_action_interval;hero.range=float(MonkData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];MonkSystem.initialize_runtime(hero,true,"testing:monk")

func load_crusader_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=CrusaderData.TEST_BUILDS[clampi(build_index,0,CrusaderData.TEST_BUILDS.size()-1)];var level:=int(build.level)
	hero.level=level;hero.base_power=CrusaderData.scaled(float(CrusaderData.VALUES.basic_attack_damage),level);hero.power=hero.base_power;hero.damage=hero.base_power;hero.max_hp=CrusaderData.scaled(float(CrusaderData.VALUES.health),level);hero.hp=hero.max_hp;hero.health_regeneration=CrusaderData.scaled(float(CrusaderData.VALUES.health_regeneration),level);hero.base_basic_action_interval=float(CrusaderData.VALUES.basic_attack_interval);hero.basic_attack_interval=hero.base_basic_action_interval;hero.range=float(CrusaderData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.shield=0.0;hero.shield_sources=[];CrusaderSystem.initialize_runtime(hero,true)

func load_vanguard_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=VanguardData.TEST_BUILDS[clampi(build_index,0,VanguardData.TEST_BUILDS.size()-1)];var level:=int(build.level)
	hero.level=level;hero.base_power=VanguardData.scaled(float(VanguardData.VALUES.basic_attack_damage),level);hero.power=hero.base_power;hero.damage=hero.base_power;hero.max_hp=VanguardData.scaled(float(VanguardData.VALUES.health),level);hero.hp=hero.max_hp;hero.health_regeneration=VanguardData.scaled(float(VanguardData.VALUES.health_regeneration),level);hero.base_basic_action_interval=float(VanguardData.VALUES.basic_attack_interval);hero.basic_attack_interval=hero.base_basic_action_interval;hero.range=float(VanguardData.SPACE.basic_range);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.active_effects=[];hero.temporary_armor_sources=[];VanguardSystem.initialize_runtime(hero,true,"testing:vanguard")

func load_vitalist_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=VitalistData.TEST_BUILDS[clampi(build_index,0,VitalistData.TEST_BUILDS.size()-1)];var level:=int(build.level)
	hero.level=level;hero.base_power=VitalistData.scaled(float(VitalistData.VALUES.basic_attack_damage),level);hero.power=hero.base_power;hero.damage=hero.base_power;hero.max_hp=VitalistData.scaled(float(VitalistData.VALUES.health),level);hero.hp=hero.max_hp;hero.health_regeneration=VitalistData.scaled(float(VitalistData.VALUES.health_regeneration),level);hero.base_basic_action_interval=float(VitalistData.VALUES.basic_attack_interval);hero.basic_attack_interval=hero.base_basic_action_interval;hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.active_effects=[];hero.temporary_armor_sources=[];VitalistSystem.initialize_runtime(hero,true,"testing:vitalist")

func handle_vitalist_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="vitalist_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Vitalist":hero=candidate;break
	if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_4:
		var build_index:=int(event.keycode-KEY_1);load_vitalist_test_build(hero,build_index);flash("Vitalist build: %s"%str(VitalistData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if event.ctrl_pressed and event.keycode==KEY_C:
		var build_index:=0;for i in VitalistData.TEST_BUILDS.size():if str(VitalistData.TEST_BUILDS[i].heroic)==str(hero.selected_heroic_id) and VitalistData.TEST_BUILDS[i].talents==hero.selected_talents:build_index=i;break
		load_vitalist_test_build(hero,build_index);flash("Vitalist cooldowns, infections, and charges reset");queue_redraw();return true
	return false

func load_spiritweaver_test_build(hero:Dictionary,build_index:int)->void:
	var build:Dictionary=SpiritWeaverData.TEST_BUILDS[clampi(build_index,0,SpiritWeaverData.TEST_BUILDS.size()-1)];var level:=int(build.level);hero.level=level;hero.base_power=SpiritWeaverData.scaled(float(SpiritWeaverData.VALUES.basic_attack_damage),level);hero.power=hero.base_power;hero.damage=hero.base_power;hero.max_hp=SpiritWeaverData.scaled(float(SpiritWeaverData.VALUES.health),level);hero.hp=hero.max_hp;hero.health_regeneration=SpiritWeaverData.scaled(float(SpiritWeaverData.VALUES.health_regeneration),level);hero.base_basic_action_interval=float(SpiritWeaverData.VALUES.basic_attack_interval);hero.selected_heroic_id=str(build.heroic);hero.selected_talents=build.talents.duplicate(true);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.active_effects=[];hero.temporary_armor_sources=[];SpiritWeaverSystem.initialize_runtime(hero,true)
func handle_spiritweaver_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="spiritweaver_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Spirit Weaver":hero=candidate;break
	if hero==null:return false
	if event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4]:var build_index:=int(event.keycode-KEY_1);load_spiritweaver_test_build(hero,build_index);flash("Spirit Weaver build: %s"%str(SpiritWeaverData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if event.keycode==KEY_0:load_spiritweaver_test_build(hero,0);flash("Spirit Weaver runtime reset");queue_redraw();return true
	return false

func handle_vanguard_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="vanguard_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Vanguard":hero=candidate;break
	if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_4:
		var build_index:=int(event.keycode-KEY_1);load_vanguard_test_build(hero,build_index);flash("Vanguard build: %s"%str(VanguardData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if event.ctrl_pressed and event.keycode==KEY_C:
		hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.vanguard_runtime.e_slot=AbilitySlotSystem.create(3 if VanguardSystem.has_talent(hero,"vanguard_l24_3") else 1,float(VanguardData.VALUES.e_cooldown),AbilitySlotSystem.RechargeMode.SEQUENTIAL);hero.vanguard_runtime.death_metal_icd=0.0;flash("Vanguard cooldowns and charges reset");queue_redraw();return true
	return false

func handle_crusader_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="crusader_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Crusader":hero=candidate;break
	if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_4:
		var build_index:=int(event.keycode-KEY_1);load_crusader_test_build(hero,build_index);flash("Crusader build: %s"%str(CrusaderData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if event.ctrl_pressed and event.keycode==KEY_C:
		hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.crusader_runtime.e_slot=AbilitySlotSystem.create(2 if CrusaderSystem.has_talent(hero,"crusader_l9_1") else 1,float(CrusaderData.VALUES.e_cooldown),AbilitySlotSystem.RechargeMode.INDEPENDENT);hero.crusader_runtime.light_icd=0.0;hero.crusader_runtime.indestructible_icd=0.0;flash("Crusader cooldowns and charges reset");queue_redraw();return true
	return false

func handle_monk_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="monk_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Monk":hero=candidate;break
	if hero==null:return false
	if not event.ctrl_pressed and not event.alt_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_5:
		var build_index:=int(event.keycode-KEY_1);load_monk_test_build(hero,build_index);flash("Monk build: %s"%str(MonkData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if event.ctrl_pressed:
		match event.keycode:
			KEY_C:hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.monk_runtime.q_slot=AbilitySlotSystem.create(MonkSystem.q_max(hero),MonkSystem.q_recharge(hero),AbilitySlotSystem.RechargeMode.SEQUENTIAL);hero.monk_runtime.breath_cooldown=0.0;hero.monk_runtime.reach_cooldown=0.0;hero.monk_runtime.ally_cooldown=0.0;flash("Monk cooldowns reset")
			KEY_I:hero.monk_runtime.insight_progress=99;hero.monk_runtime.insight_complete=false;flash("Insight 99/100")
			KEY_P:hero.monk_runtime.insight_progress=100;hero.monk_runtime.insight_complete=true;flash("Insight complete")
			KEY_A:var point:Vector2=Vector2(hero.pos)+Vector2(110,0);cast_monk_ally(hero,point);flash("Selected Ally placed")
			KEY_K:if not hero.monk_runtime.ally.is_empty():hero.monk_runtime.ally.hp=0.0;flash("Selected Ally destroyed")
			KEY_S:if heroes.size()>1:CombatSystem.apply_control(heroes[1],"stun",8.0);CombatSystem.apply_control(heroes[1],"root",8.0);flash("Ally Stunned + Rooted")
			KEY_T:for enemy in enemies:if enemy.hp>0.0:CombatSystem.apply_control(enemy,"stun",8.0);break;flash("Enemy Stunned")
			_:return false
		queue_redraw();return true
	return false

func handle_beastmaster_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="beastmaster_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Beastmaster":hero=candidate;break
	if hero==null:return false
	if not event.ctrl_pressed and not event.alt_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_6:var build_index:=int(event.keycode-KEY_1);load_beastmaster_test_build(hero,build_index);flash("Beastmaster build: %s"%str(BeastmasterData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if event.ctrl_pressed:
		match event.keycode:
			KEY_K:BeastmasterSystem.defeat_misha(hero);flash("Misha defeated")
			KEY_J:BeastmasterSystem.respawn_misha(hero);flash("Misha respawned")
			KEY_T:hero.beastmaster_runtime.misha_respawn_remaining=1.0;flash("Misha respawn: 1 sec")
			KEY_D:hero.beastmaster_runtime.misha.hp=maxf(1.0,float(hero.beastmaster_runtime.misha.hp)-float(hero.beastmaster_runtime.misha.max_hp)*.25);flash("Misha damaged")
			KEY_H:deal_healing(hero,hero.beastmaster_runtime.misha,float(hero.beastmaster_runtime.misha.max_hp)*.25,"basic_heal","Beastmaster Range");flash("Misha healed")
			KEY_F:cast_beastmaster_d(hero);flash("Misha focus command")
			KEY_R:BeastmasterSystem.command_misha(hero,hero);flash("Misha retreat command")
			KEY_L:for index in 2:hero.beastmaster_runtime.lesser_beasts.append(BeastmasterSystem.create_beast(hero,"lesser",hero.pos+Vector2(70+index*35,0)));flash("Two Lesser Beasts spawned")
			KEY_X:for beast in BeastmasterSystem.disposable_beasts(hero):beast.hp=float(beast.max_hp)*.5;flash("Disposable Health: 50%")
			KEY_V:for beast in BeastmasterSystem.disposable_beasts(hero):beast.health_decay_rate*=2.0;flash("Disposable decay doubled")
			KEY_Z:BeastmasterSystem.advance(hero,10.0,true);flash("Beast decay +10 sec")
			KEY_E:var beasts:=BeastmasterSystem.disposable_beasts(hero);var target=beastmaster_selected_enemy();if not beasts.is_empty() and target!=null:deal_damage(target,beasts[0],200.0,"basic_attack","physical","Fresh Range");flash("External Fresh packet sent")
			KEY_Y:BeastmasterSystem.add_fury(hero,"beastmaster",1);flash("Fury +1")
			KEY_U:hero.beastmaster_runtime.fury=224;hero.beastmaster_runtime.fury_complete=false;flash("Fury 224/225")
			KEY_I:BeastmasterSystem.add_fury(hero,"beastmaster",225);flash("Fury completed")
			KEY_O:var target=beastmaster_selected_enemy();if target!=null:BeastmasterSystem.apply_hunted(hero,str(target.combat_id));flash("Hunted reset")
			KEY_B:BlockChargeSystem.grant(hero,1,2);flash("Beastmaster Block only")
			KEY_S:CombatSystem.apply_control(hero,"slow",4.0,.4);flash("40% Slow / 4 sec applied")
			KEY_Q:hero.beastmaster_runtime.dire_stacks=10;flash("Dire Beast: 10")
			KEY_W:hero.beastmaster_runtime.hawk_remaining=4.0;flash("Hawk: 4 sec")
			KEY_A:BeastmasterSystem.advance(hero,120.0,true);flash("Apex +120 sec")
			KEY_P:var target=beastmaster_selected_enemy();if target!=null:BeastmasterSystem.pack_commander(hero,str(target.combat_id));flash("Pack Commander order")
			_:return false
		queue_redraw();return true
	if event.alt_pressed:
		match event.keycode:
			KEY_B:BlockChargeSystem.grant(hero.beastmaster_runtime.misha,1,2);flash("Misha Block only")
			KEY_E:hero.hp=hero.max_hp*.5;hero.beastmaster_runtime.misha.hp=hero.beastmaster_runtime.misha.max_hp*.5;flash("Bond equal Health percentages")
			KEY_1:hero.hp=hero.max_hp;hero.beastmaster_runtime.misha.hp=hero.beastmaster_runtime.misha.max_hp*.5;flash("Bond: Misha lower")
			KEY_2:hero.hp=hero.max_hp*.5;hero.beastmaster_runtime.misha.hp=hero.beastmaster_runtime.misha.max_hp;flash("Bond: Beastmaster lower")
			KEY_N:var target=beastmaster_selected_enemy();if target!=null:BeastmasterSystem.note_primary_attack(hero,"beastmaster",str(target.combat_id),{"resolved_damage":100.0});flash("Beastmaster Hunted proc consumed")
			KEY_M:var target=beastmaster_selected_enemy();if target!=null:BeastmasterSystem.note_primary_attack(hero,"misha",str(target.combat_id),{"resolved_damage":100.0});flash("Misha Hunted proc consumed")
			KEY_W:for beast in BeastmasterSystem.disposable_beasts(hero):beast.pos=hero.pos;hero.beastmaster_runtime.wildfire_tick=0.0;flash("Wildfire sources overlapped")
			_:return false
		queue_redraw();return true
	match event.keycode:
		KEY_K:BeastmasterSystem.defeat_misha(hero);flash("Misha defeated")
		KEY_J:BeastmasterSystem.respawn_misha(hero);flash("Misha respawned")
		KEY_L:hero.beastmaster_runtime.lesser_beasts.append(BeastmasterSystem.create_beast(hero,"lesser",hero.pos+Vector2(90,0)));flash("Lesser Beast spawned")
		KEY_G:hero.beastmaster_runtime.greater_beasts.append(BeastmasterSystem.create_beast(hero,"greater",hero.beastmaster_runtime.misha.pos));flash("Greater Beast spawned")
		KEY_F:BeastmasterSystem.add_fury(hero,"beastmaster",1);flash("Fury %d/225"%int(hero.beastmaster_runtime.fury))
		KEY_H:var target=beastmaster_selected_enemy();if target!=null:BeastmasterSystem.apply_hunted(hero,str(target.combat_id));flash("Hunted applied")
		KEY_B:BlockChargeSystem.grant(hero,1,2);BlockChargeSystem.grant(hero.beastmaster_runtime.misha,1,2);flash("Independent Blocks granted")
		KEY_A:BeastmasterSystem.advance(hero,10.0,true);flash("Apex +10 seconds")
		KEY_P:var target=beastmaster_selected_enemy();if target!=null:BeastmasterSystem.pack_commander(hero,str(target.combat_id));flash("Pack Commander order")
		KEY_C:hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.beastmaster_runtime.q_slot.current_charges=2;hero.beastmaster_runtime.q_slot.timers=[];flash("Beastmaster cooldowns reset")
		_:return false
	queue_redraw();return true

func sentinel_range_hero():
	for hero in heroes:
		if str(hero.get("class",""))=="Sentinel":return hero
	return null

func handle_sentinel_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="sentinel_range":return false
	var hero=sentinel_range_hero();if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_5:
		var build_index:=int(event.keycode-KEY_1);load_sentinel_test_build(hero,build_index);flash("Sentinel build: %s"%str(SentinelData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.alt_pressed:return false
	match event.keycode:
		KEY_C:
			hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.sentinel_runtime.q_slot=AbilitySlotSystem.create(2,float(SentinelData.VALUES.q_cooldown),AbilitySlotSystem.RechargeMode.FULL_REFILL);hero.sentinel_runtime.w_slot=AbilitySlotSystem.create(2 if SentinelSystem.has_talent(hero,"sentinel_l30_1") else 1,SentinelSystem.w_cooldown(hero),AbilitySlotSystem.RechargeMode.INDEPENDENT);hero.sentinel_runtime.d_cooldown=0.0;hero.sentinel_runtime.trueshot_cooldown=0.0;flash("Sentinel cooldowns and charges reset")
		KEY_H:
			var ratios:=[1.0,.80,.50,.21,.19,.11,.09,.01]
			for ally_index in heroes.size():heroes[ally_index].hp=maxf(1.0,float(heroes[ally_index].max_hp)*float(ratios[ally_index%ratios.size()]))
			flash("Sentinel ally health ratios staged")
		KEY_Q:hero.sentinel_runtime.e_quest_stacks=84;flash("Lunar Flare quest completed")
		KEY_M:
			var target_index:=combat_enemy_target()
			if target_index>=0:SentinelSystem.apply_mark(hero,enemies[target_index],false);flash("Hunter's Mark applied")
		_:return false
	queue_redraw();return true

func protector_range_hero():
	for hero in heroes:
		if str(hero.get("class",""))=="Protector":return hero
	return null

func handle_protector_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="protector_range":return false
	var hero=protector_range_hero();if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_4:
		var build_index:=int(event.keycode-KEY_1);load_protector_test_build(hero,build_index);flash("Protector build: %s"%str(ProtectorData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.alt_pressed:return false
	match event.keycode:
		KEY_C:
			hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.protector_runtime.aspect_cooldown=0.0
			hero.protector_runtime.smite_slot=AbilitySlotSystem.create(2 if ProtectorSystem.has_talent(hero,"protector_l30_3") else 1,float(ProtectorData.VALUES.e_cooldown));flash("Protector cooldowns and Smite charges reset")
		KEY_K:hero.hp=0.0;hero.protector_runtime.wrath_resolved=false;flash("Archangel's Wrath triggered")
		KEY_H:for ally in heroes:ally.hp=ally.max_hp;flash("All allies restored")
		KEY_W:
			for blocker_index in range(combat_blockers.size()-1,-1,-1):
				if ProtectorSystem.own_wall(hero,combat_blockers[blocker_index]):combat_blockers.remove_at(blocker_index)
			hero.protector_runtime.walls.clear();flash("Protector walls reset")
		KEY_T:
			var target_index:=combat_enemy_target()
			if target_index>=0:
				for ally_index in heroes.size():enemies[target_index].threat[ally_index]=100.0+ally_index*250.0
				flash("Selected enemy Threat configured")
		_:return false
	queue_redraw();return true

func handle_templar_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="templar_range":return false
	var hero=null;for candidate in heroes:if str(candidate.get("class",""))=="Templar":hero=candidate;break
	if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_4:
		var build_index:=int(event.keycode-KEY_1);load_templar_test_build(hero,build_index);flash("Templar build: %s"%str(TemplarData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.alt_pressed:return false
	match event.keycode:
		KEY_C:hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.templar_runtime.trait_cooldown=0.0;flash("Templar cooldowns reset")
		KEY_D:hero.hp=float(hero.max_hp)*.70;hero.templar_runtime.trait_cooldown=0.0;flash("Shield Overload armed")
		KEY_Q:hero.templar_runtime.protector_stacks=100;flash("Protector stacks: 100")
		KEY_E:for ally in heroes:if ally!=hero:ally.hp=maxf(1.0,float(ally.max_hp)*.35);flash("Allies damaged for Shield Ally testing")
		_:return false
	queue_redraw();return true

func shaman_range_hero():
	for hero in heroes:
		if str(hero.get("class",""))=="Shaman":return hero
	return null

func handle_shaman_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="shaman_range":return false
	var hero=shaman_range_hero();if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_0 and event.keycode<=KEY_9:
		var digit_index:int=9 if event.keycode==KEY_0 else int(event.keycode-KEY_1);var build_index:int=digit_index+(10 if event.ctrl_pressed else 0)
		if build_index<ShamanData.TEST_BUILDS.size():load_shaman_test_build(hero,build_index);flash("Shaman build: %s"%str(ShamanData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.alt_pressed:return false
	match event.keycode:
		KEY_F:ShamanSystem.add_frostwolf_stacks(hero,1,float(hero.hp));flash("Frostwolf stack added")
		KEY_T:resolve_shaman_frostwolf(hero,int(ShamanData.VALUES.trait_threshold));flash("Frostwolf threshold resolved")
		KEY_C:hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];hero.shaman_runtime.q_slot=AbilitySlotSystem.create(ShamanSystem.q_max_charges(hero),ShamanSystem.q_cooldown(hero));flash("Shaman cooldowns reset")
		KEY_G:hero.shaman_runtime.gathering_stacks=int(ShamanData.VALUES.gathering_max);flash("Gathering Storm maxed")
		KEY_U:hero.shaman_runtime.thunder_stacks=int(ShamanData.VALUES.thunder_max);flash("Rolling Thunder maxed")
		KEY_A:hero.shaman_runtime.ancestral_stacks=int(ShamanData.VALUES.ancestral_max);hero.shaman_runtime.ancestral_ready=true;flash("Ancestral Wrath armed")
		KEY_N:ProgressionScopeSystem.begin_encounter(hero.shaman_runtime,ProgressionScopeSystem.new_encounter_id("shaman_test"));flash("New encounter scope")
		KEY_M:ProgressionScopeSystem.room_transition(hero.shaman_runtime,str(hero.shaman_runtime.encounter_id));flash("Room transition; encounter preserved")
		KEY_X:ProgressionScopeSystem.end_encounter(hero.shaman_runtime);flash("Encounter progress cleared")
		_:return false
	queue_redraw();return true

func priest_range_hero():
	for hero in heroes:
		if str(hero.get("class",""))=="Priest":return hero
	return null

func handle_priest_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="priest_range":return false
	var hero=priest_range_hero();if hero==null:return false
	if event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_3:
		var build_index:=int(event.keycode-KEY_1);load_priest_test_build(hero,build_index);flash("Priest build: %s"%str(PriestData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if not event.alt_pressed:return false
	match event.keycode:
		KEY_K:hero.hp=0.0;flash("Eternal Vanguard triggered")
		KEY_V:
			if PriestSystem.spirit_active(hero):hero.priest_runtime.spirit_remaining=0.01;flash("Spirit Form ending")
		KEY_R:hero.priest_runtime.redemption_ready_in=180.0 if float(hero.priest_runtime.redemption_ready_in)<=0.0 else 0.0;flash("Redemption cooldown: %d"%int(hero.priest_runtime.redemption_ready_in))
		KEY_H:
			for ally in heroes:ally.hp=ally.max_hp
			flash("All allies restored")
		_:
			return false
	queue_redraw();return true

func rogue_range_hero():
	for hero in heroes:
		if str(hero.get("class",""))=="Rogue":return hero
	return null

func handle_rogue_range_shortcut(event:InputEventKey)->bool:
	if not testing_zone_active or testing_zone_mode!="rogue_range" or not event.alt_pressed:return false
	var hero=rogue_range_hero();if hero==null:return false
	if event.keycode>=KEY_1 and event.keycode<=KEY_5:
		var values:=[0,1,2,3,5];hero.combo_points=mini(ComboPointSystem.maximum(hero),values[int(event.keycode-KEY_1)]);flash("Combo Points: %d"%int(hero.combo_points));queue_redraw();return true
	match event.keycode:
		KEY_V:
			RogueSystem.break_vanish(hero);hero.ability_cds=[0.0,0.0,0.0,0.0,0.0];for id in hero.alternate_cooldowns:hero.alternate_cooldowns[id]=0.0;flash("Vanish and cooldowns reset")
		KEY_S:
			RogueSystem.break_vanish(hero);hero.ability_cds[4]=0.0;RogueSystem.activate_vanish(hero);flash("Stealth forced")
		KEY_I:
			RogueSystem.break_vanish(hero);hero.ability_cds[4]=0.0;RogueSystem.activate_vanish(hero);hero.concealment.unrevealable_remaining=0.0;hero.concealment.invisible=true;hero.rogue_runtime.stationary_elapsed=float(RogueData.VALUES.vanish_invisible_stationary);flash("Invisible forced")
		KEY_R:
			hero.concealment.unrevealable_remaining=0.0;StealthDetectionSystem.reveal(hero,3.0);flash("Reveal applied")
		KEY_D:
			for enemy in enemies:
				if "detector" in enemy.get("combat_tags",[]):enemy.detection_profile={} if bool(enemy.get("detection_profile",{}).get("detect_stealthed",false)) else {"detect_stealthed":true,"detect_invisible":true,"detection_radius":210.0}
			flash("Detector profile toggled")
		KEY_P:
			hero.rogue_runtime.garrotes=[];for enemy in enemies:enemy.bloodletting_stacks=[];flash("Rogue periodic statuses removed")
		KEY_F:
			hero.rogue_runtime.fatal_finesse_stacks=0 if int(hero.rogue_runtime.fatal_finesse_stacks)>=int(RogueData.VALUES.fatal_max_stacks) else int(RogueData.VALUES.fatal_max_stacks);flash("Fatal Finesse: %d"%int(hero.rogue_runtime.fatal_finesse_stacks))
		KEY_B:
			BlockChargeSystem.grant_legacy(hero.rogue_runtime,3,3);flash("Combat Readiness: 3 Block")
		KEY_M:
			hero.selected_heroic_id="rogue_l15_r1";hero.ability_cds[3]=0.0;cast_rogue_heroic(hero);flash("Smoke Bomb triggered")
		KEY_C:
			hero.selected_heroic_id="rogue_l15_r2";hero.ability_cds[3]=0.0;cast_rogue_heroic(hero);flash("Cloak triggered")
		KEY_T:
			for enemy in enemies:
				if "boss" in enemy.get("combat_tags",[]):enemy.control_profile={"stun_multiplier":1.0,"blind_immune":false,"silence_multiplier":1.0} if bool(enemy.get("control_profile",{}).get("blind_immune",true)) else {"stun_multiplier":0.0,"blind_immune":true,"silence_multiplier":0.0}
			flash("Boss control profiles toggled")
		KEY_H:
			var healer=enemies.filter(func(enemy):return str(enemy.get("test_fixture",""))=="external_healer");var targets=enemies.filter(func(enemy):return str(enemy.get("test_fixture",""))=="healable_target");if not healer.is_empty() and not targets.is_empty():targets[0].hp=maxf(1.0,float(targets[0].hp)-300.0);deal_healing(healer[0],targets[0],250.0,"basic_heal","Rogue Range")
			flash("External healing triggered")
		KEY_J:
			var self_targets=enemies.filter(func(enemy):return bool(enemy.get("self_heal_test",false)));if not self_targets.is_empty():self_targets[0].hp=maxf(1.0,float(self_targets[0].hp)-300.0);deal_healing(self_targets[0],self_targets[0],250.0,"basic_heal","Rogue Range")
			flash("Self-healing triggered")
		_:
			return false
	queue_redraw();return true

func player_controlled_hero_indices() -> Array:
	var result:=[]
	for hero_index in heroes.size():
		if not bool(heroes[hero_index].get("independent",false)):result.append(hero_index)
	return result

func cycle_selected_hero(direction:int)->void:
	if heroes.is_empty():return
	for offset in heroes.size():
		var candidate=posmod(selected+direction*(offset+1),heroes.size())
		if heroes[candidate].hp>0 and not bool(heroes[candidate].get("independent",false)):
			selected=candidate
			queue_redraw()
			return

func cycle_selected_enemy()->void:
	if heroes.is_empty():return
	var living_targets:=[]
	for i in enemies.size():
		if enemies[i].hp>0:living_targets.append(i)
	if living_targets.is_empty():
		focused_enemy_index=-1
		queue_redraw()
		return
	var current_position=living_targets.find(focused_enemy_index)
	var next_position=0 if current_position<0 else (current_position+1)%living_targets.size()
	focused_enemy_index=living_targets[next_position]
	queue_redraw()

func cancel_ability_aim()->void:
	if selected>=0 and selected<heroes.size() and str(heroes[selected].get("class",""))=="Paladin" and not heroes[selected].get("paladin_runtime",{}).is_empty():PaladinSystem.manual_cancel(heroes[selected])
	ability_aiming=false;aimed_ability_slot=-1;aimed_ability_category="";aimed_cast_mode="";ability_button_held=false;queue_redraw()

func clear_selected_combat_target()->void:
	if selected<0 or selected>=heroes.size():return
	clear_hero_command(heroes[selected],"player cancelled")
	focused_enemy_index=-1
	queue_redraw()

func begin_ability(slot:int,device:String="pc")->void:
	if selected>=heroes.size() or bool(heroes[selected].get("independent",false)) or slot<0 or slot>=4:return
	if tutorial_active and (tutorial_step<7 or slot!=0):return
	if tutorial_active and tutorial_step==7 and heroes[selected]["class"]!="Cleric":return
	if tutorial_active and tutorial_step==7:use_ability(0,heroes[selected].pos);return
	var hero_level:=int(state.heroes[battle_hero_indices[selected]].level)
	if not TalentSystem.ability_is_unlocked(hero_level,slot):return
	if str(heroes[selected].get("class",""))=="Paladin" and slot in [0,1,2]:
		var paladin_category:="directional" if slot>0 else "self";var configured_mode:="release" if slot==0 else str(state.casting_settings[device].get(paladin_category,"cursor"));var charge_mode:="confirm" if configured_mode=="confirm" else "release";var initial_aim:=get_global_mouse_position()
		if configured_mode=="facing":initial_aim=Vector2(heroes[selected].pos)+Vector2(heroes[selected].facing_direction)*float(ABILITY_RANGES.Paladin[slot])
		if not cast_paladin_ability(slot,initial_aim):return
		heroes[selected].paladin_runtime.charge.input_mode=configured_mode;heroes[selected].paladin_runtime.charge.device=device;ability_aiming=true;aimed_ability_slot=slot;aimed_ability_category=paladin_category;aimed_cast_mode=charge_mode;aimed_from_touch=device=="mobile";ability_button_held=true;ability_aim_point=initial_aim;queue_redraw();return
	var category=ABILITY_TARGETING[heroes[selected]["class"]][slot]
	if heroes[selected]["class"]=="Guardian" and slot==3 and guardian_heroic_id(heroes[selected])=="guardian_l15_r2":category="enemy"
	if heroes[selected]["class"]=="Mage" and slot==3 and str(heroes[selected].get("selected_heroic_id",""))=="mage_l15_r2":category="enemy"
	if heroes[selected]["class"]=="Slayer" and slot==3 and str(heroes[selected].get("selected_heroic_id",""))=="slayer_l15_r2":category="enemy"
	if heroes[selected]["class"]=="Druid" and slot==3 and DruidSystem.has_talent(heroes[selected],"druid_l27_r2"):category="ground"
	var mode="instant" if category=="self" else str(state.casting_settings[device].get(category,"cursor"))
	if mode=="instant" or mode=="cursor" or mode=="facing" or mode=="target":
		if (category=="enemy" and combat_enemy_target()<0) or (category=="ally" and (heroes[selected].heal_target<0 or heroes[selected].heal_target>=heroes.size())):
			return
		var cast_point=get_global_mouse_position()
		if mode=="facing":cast_point=heroes[selected].pos+heroes[selected].facing_direction*ABILITY_RANGES[heroes[selected]["class"]][slot]
		use_ability(slot,cast_point);return
	ability_aiming=true;aimed_ability_slot=slot;aimed_ability_category=category;aimed_cast_mode=mode;aimed_from_touch=device=="mobile";ability_button_held=mode=="release";ability_aim_point=get_global_mouse_position();queue_redraw()

func begin_trait(device:String="pc")->void:
	if selected<0 or selected>=heroes.size() or bool(heroes[selected].get("independent",false)):return
	var hero:Dictionary=heroes[selected]
	if str(hero.get("class",""))=="Guardian" and GuardianSystem.has_talent(hero,"guardian_l24_2"):
		use_guardian_trait(hero)
		queue_redraw()
	elif str(hero.get("class",""))=="Cleric":
		use_cleric_trait(hero)
		queue_redraw()
	elif str(hero.get("class",""))=="Ranger" and RangerSystem.has_talent(hero,"ranger_l21_3"):
		if float(hero.ranger_runtime.strafe_remaining)>0.0:return
		RangerSystem.activate_gloom(hero)
		queue_redraw()
	elif str(hero.get("class",""))=="Mage":
		if not MageSystem.activate_trait(hero,battle_time):return
		else:
			if MageSystem.has_talent(hero,"mage_l9_2"):deal_healing(hero,hero,MageSystem.scaled_ability_amount(hero,float(MageData.VALUES.fel_infusion_heal)),"basic_ability","Fel Infusion")
			add_effect("cast",hero.pos,hero.pos,"",CLASSES.Mage.color)
		queue_redraw()
	elif str(hero.get("class",""))=="Warlock":
		if use_warlock_trait(hero):queue_redraw()
	elif str(hero.get("class",""))=="Rogue":
		if use_rogue_trait(hero):queue_redraw()
	elif str(hero.get("class",""))=="Slayer":
		if use_slayer_trait(hero):queue_redraw()
	elif str(hero.get("class",""))=="Shaman":
		if use_shaman_trait(hero):queue_redraw()
	elif str(hero.get("class",""))=="Protector" and ProtectorSystem.has_talent(hero,"protector_l30_1"):
		use_ability(4,hero.pos)
		queue_redraw()
	elif str(hero.get("class",""))=="Sentinel":
		use_ability(4,get_global_mouse_position())
		queue_redraw()
	elif str(hero.get("class",""))=="Druid":
		use_ability(4,hero.pos)
		queue_redraw()
	elif str(hero.get("class",""))=="Warrior":
		use_ability(4,get_global_mouse_position())
		queue_redraw()
	elif str(hero.get("class",""))=="Paladin":
		use_ability(4,hero.pos)
		queue_redraw()
	elif str(hero.get("class",""))=="Crusader":
		use_ability(4,hero.pos)
		queue_redraw()
	elif str(hero.get("class",""))=="Spirit Weaver":
		ability_aiming=true;aimed_ability_slot=4;aimed_ability_category="ally_or_enemy";aimed_cast_mode="confirm";aimed_from_touch=device=="mobile";ability_button_held=false;ability_aim_point=get_global_mouse_position();queue_redraw()

func confirm_aim_at(point:Vector2)->bool:
	if not ability_aiming:return false
	if selected>=0 and selected<heroes.size() and str(heroes[selected].get("class",""))=="Paladin" and not heroes[selected].get("paladin_runtime",{}).is_empty():
		heroes[selected].paladin_runtime.charge.aim_point=point;ability_aiming=false;aimed_ability_slot=-1;aimed_ability_category="";aimed_cast_mode="";ability_button_held=false;var committed:=resolve_paladin_charge(heroes[selected]);queue_redraw();return committed
	if aimed_ability_category=="enemy":
		for i in enemies.size():
			if enemies[i].hp>0 and enemies[i].pos.distance_to(point)<58:focused_enemy_index=i;var slot=aimed_ability_slot;cancel_ability_aim();use_ability(slot,point);return true
		return false
	if aimed_ability_category=="ally":
		for i in heroes.size():
			if heroes[i].hp>0 and heroes[i].pos.distance_to(point)<58:assign_hero_ally(selected,i);var slot=aimed_ability_slot;cancel_ability_aim();use_ability(slot,point);return true
		for ally in player_healable_units():
			if ally not in heroes and ally.pos.distance_to(point)<58:assign_hero_ally_unit(selected,ally);var slot=aimed_ability_slot;cancel_ability_aim();use_ability(slot,point);return true
		return false
	if aimed_ability_category=="ally_or_enemy":
		var nearest=null
		var nearest_distance:=58.0
		for candidate in heroes+enemies:
			if float(candidate.get("hp",0.0))<=0.0:continue
			var distance:=Vector2(candidate.pos).distance_to(point)
			if distance<=nearest_distance:nearest=candidate;nearest_distance=distance
		if nearest==null:return false
		var slot=aimed_ability_slot;var target_point:=Vector2(nearest.pos);cancel_ability_aim();use_ability(slot,target_point);return true
	var slot=aimed_ability_slot;cancel_ability_aim();use_ability(slot,point);return true

func tutorial_allows_hero(hero_index:int)->bool:

	match tutorial_step:
		0,1:return hero_index>=0 and hero_index<heroes.size()
		2,3:return hero_index==0
		6:return hero_index==0 or hero_index==1
		4,7:return hero_index==1
	return false

func tutorial_pointer_press(point:Vector2,device:String="pc")->void:
	tutorial_input_device=device
	if tutorial_step==7:
		if point.y>575 and point.y<635 and point.x>420 and point.x<875:
			var portrait_index=clampi(int((point.x-424)/54),0,heroes.size()-1)
			if portrait_index==1:selected=1;tutorial_record_valid_action();queue_redraw()
			else:reject_tutorial_action("Only Sera can be selected for this step.")
			return
		if point.y>635 and point.x>445 and point.x<523:
			if selected==1:tutorial_record_valid_action();begin_ability(0,device)
			else:reject_tutorial_action("Select Sera before using Healing Brew.")
			return
	for hero_index in heroes.size():
		if heroes[hero_index].pos.distance_to(point)<58 and tutorial_allows_hero(hero_index):
			selected=hero_index;tutorial_record_valid_action()
			if tutorial_step==3:
				tutorial_hero_clicked=true
				dragging_hero=false
				queue_redraw()
				return
			if tutorial_step==7:
				queue_redraw()
				return
			dragging_hero=true;drag_cursor=point;drag_start=point;drag_has_moved=false;drag_target_type="ground";drag_target_index=-1;queue_redraw();return
	reject_tutorial_action()

func update_hero_drag(point:Vector2)->void:
	drag_cursor=point
	if drag_cursor.distance_to(drag_start)>12:drag_has_moved=true
	drag_target_type="ground";drag_target_index=-1
	if heroes[selected]["class"] in ["Cleric","Druid","Spirit Weaver"]:
		for hero_index in heroes.size():
			if hero_index!=selected and heroes[hero_index].hp>0 and heroes[hero_index].pos.distance_to(drag_cursor)<42:drag_target_type="ally";drag_target_index=hero_index;break
		if drag_target_type=="ground":
			for owner_index in heroes.size():
				if str(heroes[owner_index].get("class",""))!="Beastmaster" or heroes[owner_index].get("beastmaster_runtime",{}).is_empty():continue
				var misha:Dictionary=heroes[owner_index].beastmaster_runtime.misha
				if BeastmasterSystem.misha_alive(heroes[owner_index]) and misha.pos.distance_to(drag_cursor)<42:drag_target_type="ally_companion";drag_target_index=owner_index;break
	if drag_target_type=="ground":
		for enemy_index in enemies.size():
			if enemies[enemy_index].hp>0 and enemies[enemy_index].pos.distance_to(drag_cursor)<45:drag_target_type="enemy";drag_target_index=enemy_index;break
	queue_redraw()

func tutorial_drag_release_is_valid()->bool:
	match tutorial_step:
		0:
			return drag_target_type=="ground"
		1:
			return drag_target_type=="ground"
		2:
			return drag_target_type=="enemy" and drag_target_index>=0 and enemies[drag_target_index].type=="Dummy"
		4:
			return drag_target_type=="ally" and drag_target_index==0
		6:
			if selected==1:return drag_target_type=="ground"
			return drag_target_type=="enemy" and drag_target_index>=0 and enemies[drag_target_index].type=="Raider"
	return false

func finish_hero_drag()->void:
	dragging_hero=false
	if not drag_has_moved:return
	if tutorial_active and not tutorial_drag_release_is_valid():reject_tutorial_action();queue_redraw();return
	if tutorial_active:tutorial_record_valid_action()
	if drag_target_type=="enemy":assign_hero_enemy(selected,drag_target_index);heroes[selected].suppress_auto_target=false
	elif drag_target_type=="ally" and heroes[selected]["class"] in ["Cleric","Druid","Spirit Weaver"]:assign_hero_ally(selected,drag_target_index)
	elif drag_target_type=="ally_companion" and heroes[selected]["class"] in ["Cleric","Druid","Spirit Weaver"] and drag_target_index>=0 and drag_target_index<heroes.size():assign_hero_ally_unit(selected,heroes[drag_target_index].beastmaster_runtime.misha)
	else:issue_hero_move(heroes[selected],Vector2(clamp(drag_cursor.x,55.0,1225.0),clamp(drag_cursor.y,70.0,570.0)));heroes[selected].suppress_auto_target=true;focused_enemy_index=-1
	queue_redraw()

func handle_combat_testing_shortcut(event:InputEventKey)->bool:
	if handle_vitalist_range_shortcut(event):return true
	if handle_spiritweaver_range_shortcut(event):return true
	if handle_vanguard_range_shortcut(event):return true
	if handle_crusader_range_shortcut(event):return true
	if handle_monk_range_shortcut(event):return true
	if handle_death_knight_range_shortcut(event):return true
	if handle_beastmaster_range_shortcut(event):return true
	if handle_warrior_range_shortcut(event):return true
	if handle_druid_range_shortcut(event):return true
	if handle_huntsman_range_shortcut(event):return true
	if handle_sentinel_range_shortcut(event):return true
	if handle_protector_range_shortcut(event):return true
	if handle_templar_range_shortcut(event):return true
	if handle_shaman_range_shortcut(event):return true
	if handle_priest_range_shortcut(event):return true
	if handle_rogue_range_shortcut(event):return true
	if testing_zone_active and testing_zone_mode=="slayer_range" and event.shift_pressed and event.keycode>=KEY_0 and event.keycode<=KEY_9:
		var build_index:int=9 if event.keycode==KEY_0 else int(event.keycode-KEY_1)
		for hero in heroes:
			if str(hero.get("class",""))=="Slayer":load_slayer_test_build(hero,build_index)
		flash("Slayer build: %s"%str(SlayerData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if testing_zone_active and testing_zone_mode=="rogue_range" and event.shift_pressed and event.keycode>=KEY_1 and event.keycode<=KEY_6:
		var build_index:int=int(event.keycode-KEY_1)
		for hero in heroes:
			if str(hero.get("class",""))=="Rogue":load_rogue_test_build(hero,build_index)
		flash("Rogue build: %s"%str(RogueData.TEST_BUILDS[build_index].name));queue_redraw();return true
	if event.keycode==KEY_F3 and testing_zone_active:debug_combat_overlay=not debug_combat_overlay;queue_redraw();return true
	if event.keycode==KEY_F4 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Guardian":GuardianSystem.add_quest(hero,45,"testing_control",battle_time);flash("Guardian quest +45")
		return true
	if event.keycode==KEY_F5 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Guardian":hero.selected_heroic_id="guardian_l15_r2" if guardian_heroic_id(hero)=="guardian_l15_r1" else "guardian_l15_r1";hero.selected_talents["tier_3"]=hero.selected_heroic_id;flash("Heroic: %s"%GuardianData.WORKING_NAMES[hero.selected_heroic_id])
		return true
	if event.keycode==KEY_F6 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Guardian":hero.selected_talents={"tier_1":"guardian_l9_1","tier_2":"guardian_l12_2","tier_3":guardian_heroic_id(hero),"tier_4":"guardian_l18_2","tier_5":"guardian_l21_2","tier_6":"guardian_l24_1","tier_7":"guardian_l27_r1" if guardian_heroic_id(hero)=="guardian_l15_r1" else "guardian_l27_r2","tier_8":"guardian_l30_1"};hero.guardian_runtime.ability_charges=GuardianSystem.default_charges(hero);flash("Guardian test talents loaded")
		return true
	if event.keycode==KEY_F7 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Cleric":hero.selected_heroic_id="cleric_l15_r1";hero.selected_talents={"tier_1":"cleric_l9_1","tier_2":"cleric_l12_2","tier_3":"cleric_l15_r1","tier_4":"cleric_l18_1","tier_5":"cleric_l21_2","tier_6":"cleric_l24_1","tier_7":"cleric_l27_r1","tier_8":"cleric_l30_1"};ClericSystem.initialize_runtime(hero,true);flash("Cleric Jug test build loaded")
		return true
	if event.keycode==KEY_F8 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Cleric":hero.selected_heroic_id="cleric_l15_r2";hero.selected_talents={"tier_1":"cleric_l9_2","tier_2":"cleric_l12_3","tier_3":"cleric_l15_r2","tier_4":"cleric_l18_2","tier_5":"cleric_l21_1","tier_6":"cleric_l24_3","tier_7":"cleric_l27_r2","tier_8":"cleric_l30_2"};ClericSystem.initialize_runtime(hero,true);flash("Cleric Dragon test build loaded")
		return true
	if event.keycode==KEY_F9 and event.ctrl_pressed and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage":load_level_one_mage_test(hero)
		flash("Level 1 Mage baseline loaded");return true
	if event.keycode==KEY_F9 and event.shift_pressed and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage":load_mage_test_build(hero,"mage_l15_r1")
		flash("Level 30 Mage Phoenix chain build loaded");return true
	if event.keycode==KEY_F10 and event.shift_pressed and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage":load_mage_test_build(hero,"mage_l15_r2")
		flash("Level 30 Mage Pyro control build loaded");return true
	if event.keycode==KEY_F9 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage" and not hero.get("mage_runtime",{}).is_empty():hero.mage_runtime.trait.current_charges=hero.mage_runtime.trait.max_charges;hero.mage_runtime.trait.recharge_timers=[];hero.mage_runtime.trait.armed=false
		flash("Mage Trait charges reset");return true
	if event.keycode==KEY_F10 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage" and not hero.get("mage_runtime",{}).is_empty():hero.mage_runtime.arcane_dynamo_stacks=int(MageData.VALUES.arcane_dynamo_max);hero.mage_runtime.arcane_dynamo_remaining=float(MageData.VALUES.arcane_dynamo_duration);hero.mage_runtime.arcane_barrier_ready_in=0.0;MageSystem.refresh_ability_power(hero)
		flash("Mage Dynamo max; Barrier ready");return true
	if event.keycode==KEY_F11 and testing_zone_active:
		for hero in heroes:
			if str(hero.get("class",""))=="Mage" and not hero.get("mage_runtime",{}).is_empty():
				for foe in enemies:
					if foe.hp>0:apply_living_bomb(hero,foe,true)
		flash("Living Bomb cluster armed");return true
	if event.keycode==KEY_F12 and testing_zone_active:
		for foe in enemies:
			if foe.hp>0 and ("boss" in foe.get("combat_tags",[]) or "elite" in foe.get("combat_tags",[])):foe.hp=maxf(1.0,float(foe.max_hp)*0.10)
		flash("Boss and Elite targets set to 10% Health");return true
	return false

func handle_combat_key_pressed(event:InputEventKey)->void:
	if event.keycode==KEY_SPACE:paused=!paused;queue_redraw()
	if event.keycode==KEY_TAB and not event.echo:
		cycle_selected_enemy()
		get_viewport().set_input_as_handled()
	if event.keycode>=KEY_1 and event.keycode<=KEY_8:
		var selectable_heroes:Array=player_controlled_hero_indices()
		var requested_slot:int=event.keycode-KEY_1
		if requested_slot<selectable_heroes.size():selected=selectable_heroes[requested_slot];queue_redraw()
	if not event.echo and event.keycode==KEY_Q:begin_ability(0)
	if not event.echo and event.keycode==KEY_W:begin_ability(1)
	if not event.echo and event.keycode==KEY_E:begin_ability(2)
	if not event.echo and event.keycode==KEY_R:begin_ability(3)
	if not event.echo and event.keycode==KEY_D:begin_trait()

func handle_combat_mouse_press(event:InputEventMouseButton)->bool:
	if event.button_index==MOUSE_BUTTON_RIGHT:
		if ability_aiming:cancel_ability_aim()
		elif not paused:clear_selected_combat_target()
		get_viewport().set_input_as_handled();return true
	if event.button_index==MOUSE_BUTTON_WHEEL_UP:
		cycle_selected_hero(-1);get_viewport().set_input_as_handled();return true
	if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
		cycle_selected_hero(1);get_viewport().set_input_as_handled();return true
	if event.button_index!=MOUSE_BUTTON_LEFT:return false
	var point:=event.position
	if tutorial_active:
		tutorial_pointer_press(point,"pc");get_viewport().set_input_as_handled();return true
	if ability_aiming and aimed_cast_mode=="confirm":
		if confirm_aim_at(point):get_viewport().set_input_as_handled()
		return true
	if point.x>1190 and point.y<70:paused=true;queue_redraw();return true
	if paused:
		if Rect2(490,285,300,58).has_point(point):paused=false;queue_redraw()
		elif testing_zone_active and testing_zone_mode=="range" and Rect2(490,360,300,58).has_point(point):toggle_testing_dummy_attacks()
		elif Rect2(490,435 if testing_zone_active else 360,300,58).has_point(point):paused=false;show_combat_hall() if testing_zone_active else show_zone_map(dungeon_id)
		return true
	if point.y>575 and point.y<635 and point.x>420 and point.x<875:
		var selectable_heroes:Array=player_controlled_hero_indices();var requested_slot:int=clampi(int((point.x-424)/54),0,7)
		if requested_slot<selectable_heroes.size():selected=selectable_heroes[requested_slot];queue_redraw()
		return true
	if point.y>635 and point.x>445 and point.x<835:
		var action_slot:=clampi(int((point.x-445)/78),0,4)
		if action_slot==4:begin_trait()
		else:begin_ability(action_slot)
		return true
	for i in heroes.size():
		if not bool(heroes[i].get("independent",false)) and heroes[i].pos.distance_to(point)<58:
			selected=i;dragging_hero=true;drag_cursor=point;drag_start=point;drag_has_moved=false;drag_target_type="ground";drag_target_index=-1;queue_redraw();return true
	return false

func handle_combat_touch(event:InputEventScreenTouch)->bool:
	if tutorial_active:
		if event.pressed:tutorial_pointer_press(event.position,"mobile")
		elif dragging_hero:update_hero_drag(event.position);finish_hero_drag()
		get_viewport().set_input_as_handled();return true
	if event.pressed and ability_aiming and aimed_cast_mode=="confirm":confirm_aim_at(event.position);return true
	if event.pressed and event.position.y>635 and event.position.x>445 and event.position.x<835:
		var action_slot:=clampi(int((event.position.x-445)/78),0,4)
		if action_slot==4:begin_trait("mobile")
		else:begin_ability(action_slot,"mobile")
		return true
	if not event.pressed and ability_aiming and aimed_cast_mode=="release":confirm_aim_at(event.position);return true
	if event.pressed and not paused and event.position.y<635:clear_selected_combat_target()
	return false

func _unhandled_input(event:InputEvent) -> void:
	if screen!="combat":return
	if victory_talent_overlay!=null and is_instance_valid(victory_talent_overlay):return
	if tutorial_active:
		if event is InputEventScreenTouch or event is InputEventScreenDrag:tutorial_input_device="mobile"
		elif not OS.has_feature("mobile") and (event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventKey):tutorial_input_device="pc"
	if tutorial_active and tutorial_step==8 and ((event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.pressed):
		tutorial_active=false;show_hall();return
	if victory_sequence:
		if victory_phase>=5 and ((event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.pressed):
			attempt_victory_continue()
		return
	if battle_over:
		if event is InputEventKey and event.pressed:
			if event.keycode==KEY_ESCAPE or event.keycode==KEY_ENTER: show_hall()
			elif event.keycode==KEY_R: start_battle(dungeon_id,encounter_id)
		return
	if tutorial_active and event is InputEventKey:
		var accepted=false
		if event.pressed and tutorial_step==7:
			if event.keycode==KEY_2:selected=1;tutorial_record_valid_action();queue_redraw();accepted=true
			elif not event.echo and event.keycode==KEY_Q and selected==1:tutorial_record_valid_action();begin_ability(0);accepted=true
		if event.pressed and not accepted:reject_tutorial_action()
		get_viewport().set_input_as_handled()
		return
	if tutorial_active and event is InputEventMouseButton and event.pressed and event.button_index!=MOUSE_BUTTON_LEFT:
		reject_tutorial_action()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed:
		if handle_combat_testing_shortcut(event):get_viewport().set_input_as_handled();return
		if event.keycode==KEY_ESCAPE and ability_aiming:cancel_ability_aim();get_viewport().set_input_as_handled();return
		handle_combat_key_pressed(event)
	if event is InputEventKey and not event.pressed and ability_aiming and aimed_cast_mode=="release":
		var released_slot={KEY_Q:0,KEY_W:1,KEY_E:2,KEY_R:3}.get(event.keycode,-1)
		if released_slot==aimed_ability_slot:confirm_aim_at(get_global_mouse_position());return
	if event is InputEventMouseButton and event.pressed and handle_combat_mouse_press(event):return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and ability_aiming and aimed_cast_mode=="release":
		confirm_aim_at(event.position);return
	if event is InputEventMouseMotion and ability_aiming:ability_aim_point=event.position;queue_redraw()
	if event is InputEventScreenDrag and ability_aiming:ability_aim_point=event.position;queue_redraw();return

	if event is InputEventScreenTouch and handle_combat_touch(event):return
	if event is InputEventScreenDrag and tutorial_active and dragging_hero:update_hero_drag(event.position);return
	if event is InputEventMouseMotion and dragging_hero:update_hero_drag(event.position)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and dragging_hero:
		finish_hero_drag()
