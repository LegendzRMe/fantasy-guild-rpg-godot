extends RefCounted

const GuardianData = preload("res://scripts/data/guardian_data.gd")
const GuardianSystem = preload("res://scripts/systems/guardian_system.gd")
const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const CombatGeometry = preload("res://scripts/combat/combat_geometry.gd")
const ClassData = preload("res://scripts/data/class_data.gd")
const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func guardian(talents:Array=[])->Dictionary:
	var selected:Dictionary={}
	for index in talents.size():selected["tier_%d"%(index+1)]=talents[index]
	var unit:={"class":"Guardian","level":1,"hp":2765.0,"max_hp":2765.0,"armor":20.0,"combat_radius":42.0,"ability_cds":[10.0,8.0,10.0,40.0,0.0],"selected_talents":selected,"active_effects":[]}
	GuardianSystem.initialize_runtime(unit,true)
	return unit

static func run()->Array:
	var errors:=[]
	var definition:Dictionary=ClassData.CLASSES.Guardian
	TestSupport.check(errors,definition.base_health==2765.0 and definition.base_power==88.0 and is_equal_approx(1.0/definition.basic_action_interval,1.11),"Guardian V1 should use the source Level 1 chassis.")
	TestSupport.check(errors,is_equal_approx(GuardianData.scaled(100.0,4),100.0*pow(1.04,3)),"Guardian scalable values should use four-percent exponential level scaling.")
	var names:String=" ".join(ClassData.ABILITIES.Guardian)
	TestSupport.check(errors,not names.contains("Shield Wall") and not names.contains("Challenge") and not names.contains("Shield Rush") and not names.contains("Last Bastion"),"The placeholder Guardian kit should be removed.")

	var hero:=guardian();hero.hp=1000.0
	var before:=GuardianSystem.update_timers(hero,3.99);var active:=GuardianSystem.update_timers(hero,0.02)
	TestSupport.check(errors,before.second_wind_heal==0.0 and active.second_wind_heal>0.0 and hero.guardian_runtime.second_wind_active,"Second Wind should activate after four seconds without damage.")
	hero.hp=500.0;var low:=GuardianSystem.update_timers(hero,1.0)
	TestSupport.check(errors,is_equal_approx(low.second_wind_heal,111.0),"Second Wind should use its enhanced rate below forty percent Health.")
	GuardianSystem.note_damage(hero,1.0)
	TestSupport.check(errors,hero.guardian_runtime.seconds_since_damage==0.0 and not hero.guardian_runtime.second_wind_active,"Any resolved damage, including Shield absorption routed by runtime, should reset Second Wind.")
	var third:=guardian(["guardian_l9_2"]);third.hp=1500.0;third.guardian_runtime.seconds_since_damage=4.0
	TestSupport.check(errors,is_equal_approx(GuardianSystem.update_timers(third,1.0).second_wind_heal,180.0),"Third Wind should use 90/180 regeneration and its sixty-percent threshold.")
	third.guardian_runtime.stoneform_remaining=2.0
	TestSupport.check(errors,GuardianSystem.update_timers(third,1.0).second_wind_heal==0.0,"Stoneform should suppress Second Wind while active.")

	var block_hero:=guardian(["guardian_l9_1"]);GuardianSystem.grant_block(block_hero)
	TestSupport.check(errors,block_hero.guardian_runtime.block_charges==3 and GuardianSystem.active_armor(block_hero)==75.0,"Dwarf Block should store three charges and use the stronger 75 Physical Armor source.")
	GuardianSystem.add_armor_source(block_hero,"dwarf_toss",30.0,2.0)
	TestSupport.check(errors,GuardianSystem.active_armor(block_hero)==75.0 and GuardianSystem.consume_block(block_hero,"physical","basic_attack",10.0) and block_hero.guardian_runtime.block_charges==2,"Block and Dwarf Toss Armor should resolve by strongest source, not addition.")
	TestSupport.check(errors,not GuardianSystem.consume_block(block_hero,"physical","basic_ability",10.0),"Ability damage should not consume Block.")
	TestSupport.check(errors,CombatSystem.strongest_armor(20.0,[{"armor":30.0},{"armor":75.0}],"physical","basic_attack")==75.0,"The universal Armor resolver should deterministically choose the strongest source.")

	var quest:=guardian();var slowed:={"combat_id":"enemy:1","active_effects":[{"control_type":"slow","remaining_duration":2.0}]}
	GuardianSystem.on_basic_attack(quest,slowed,0.0);slowed.active_effects=[{"control_type":"stun","remaining_duration":2.0}];GuardianSystem.on_basic_attack(quest,slowed,0.1)
	GuardianSystem.mark_storm_bolt(quest,"enemy:1",0.0);GuardianSystem.process_marked_death(quest,"enemy:1",2.0)
	TestSupport.check(errors,quest.guardian_runtime.quest_stacks==8,"Storm Bolt quest should count controlled Basic Attacks and marked deaths without a last-hit requirement.")
	GuardianSystem.add_quest(quest,37,"test",3.0)
	TestSupport.check(errors,quest.guardian_runtime.quest_first_reached and quest.guardian_runtime.telemetry.quest_milestones.has("first"),"The first quest reward should unlock at 45 stacks and record its time.")
	GuardianSystem.add_quest(quest,115,"test",4.0)
	TestSupport.check(errors,quest.guardian_runtime.quest_mythic_reached,"The Mythic quest reward should unlock at 160 stacks.")

	var avatar:=guardian();var base_radius:float=float(avatar.combat_radius);GuardianSystem.begin_avatar(avatar)
	TestSupport.check(errors,avatar.max_hp==3765.0 and avatar.hp==3765.0 and avatar.combat_radius>base_radius,"Avatar should add scaled Health and enlarge the combat hitbox.")
	GuardianSystem.end_avatar(avatar)
	TestSupport.check(errors,avatar.max_hp==2765.0 and avatar.hp>0.0 and avatar.combat_radius==42.0,"Avatar expiration should safely revert Health and size without killing Guardian.")
	TestSupport.check(errors,CombatGeometry.segment_hits_circle(Vector2.ZERO,Vector2(100,0),Vector2(50,10),11.0),"Shared projectile geometry should detect swept circle hits.")

	var tier_three:=TalentSystem.tier_definition(definition,"tier_3");var tier_seven:=TalentSystem.tier_definition(definition,"tier_7");var tier_eight:=TalentSystem.tier_definition(definition,"tier_8")
	TestSupport.check(errors,tier_three.option_ids==["guardian_l15_r1","guardian_l15_r2"] and tier_seven.heroic_requirements.guardian_l27_r1=="guardian_l15_r1","Guardian Heroic selection and matching upgrade eligibility should remain data-driven.")
	TestSupport.check(errors,tier_eight.option_ids==["guardian_l30_1","guardian_l30_2","guardian_l30_3"],"Level 30 should offer Mountain King, Hardened Shield, and Rewind.")
	return errors
