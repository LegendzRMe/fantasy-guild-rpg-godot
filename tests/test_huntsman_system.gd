extends RefCounted

const TestSupport = preload("res://tests/test_support.gd")
const HuntsmanData = preload("res://scripts/data/huntsman_data.gd")
const HuntsmanSystem = preload("res://scripts/systems/huntsman_system.gd")
const ArmorReductionSystem = preload("res://scripts/systems/armor_reduction_system.gd")
const AlternateActionSetSystem = preload("res://scripts/systems/alternate_action_set_system.gd")

static func unit(talents:Dictionary={}) -> Dictionary:
	var hero := {"class":"Huntsman","combat_id":"hero:huntsman","level":1,"power":148.0,"base_power":148.0,"hp":1876.0,"max_hp":1876.0,"armor":0.0,"pos":Vector2(300,300),"range":float(HuntsmanData.SPACE.human_basic_range),"selected_talents":talents,"selected_heroic_id":str(talents.get("tier_3","")),"ability_cds":[0.0,0.0,0.0,0.0,0.0],"active_effects":[]}
	HuntsmanSystem.initialize_runtime(hero,true,"test:encounter")
	return hero

static func run() -> Array:
	var errors:Array = []
	var definition:Dictionary = HuntsmanData.CLASS_DEFINITION
	TestSupport.check(errors,is_equal_approx(float(definition.base_health),1876.0) and is_equal_approx(float(definition.base_power),148.0) and is_equal_approx(float(definition.basic_action_interval),1.0),"Huntsman should preserve its audited Level-1 chassis.")
	TestSupport.check(errors,is_equal_approx(float(definition.basic_action_range),5.5*float(HuntsmanData.SPACE.source_to_world)) and not bool(definition.uses_mana),"Human Huntsman should be resource-free with the audited range.")
	var hero:=unit()
	TestSupport.check(errors,str(hero.huntsman_runtime.form)=="human" and AlternateActionSetSystem.ability_id(hero,0)=="huntsman_cocktail","Huntsman should initialize in Human form with the Human action set.")
	hero.huntsman_runtime.human_q_cooldown=7.0;hero.huntsman_runtime.worgen_q_cooldown=2.0;hero.huntsman_runtime.shared_e_cooldown=4.0
	TestSupport.check(errors,HuntsmanSystem.change_form(hero,"worgen","test",1.25) and AlternateActionSetSystem.ability_id(hero,0)=="huntsman_swipe","Changing form should switch action sets.")
	TestSupport.check(errors,is_equal_approx(float(hero.huntsman_runtime.human_q_cooldown),7.0) and is_equal_approx(float(hero.huntsman_runtime.worgen_q_cooldown),2.0) and is_equal_approx(float(hero.huntsman_runtime.shared_e_cooldown),4.0),"Form changes must preserve independent Q and shared E cooldown state.")
	TestSupport.check(errors,is_equal_approx(float(hero.armor),10.0) and is_equal_approx(float(hero.range),float(HuntsmanData.SPACE.worgen_basic_range)),"Worgen form should apply Armor and melee range.")
	TestSupport.check(errors,hero.huntsman_runtime.form_events.size()==1 and hero.huntsman_runtime.form_events[0].previous_form=="human" and hero.huntsman_runtime.form_events[0].new_form=="worgen","Actual form changes should emit one auditable event.")
	TestSupport.check(errors,not HuntsmanSystem.change_form(hero,"worgen","duplicate",2.0) and hero.huntsman_runtime.form_events.size()==1,"No-op form requests must not emit duplicate events.")
	var wolf:=unit({"tier_1":"huntsman_l9_1"});HuntsmanSystem.change_form(wolf,"worgen","test")
	TestSupport.check(errors,is_equal_approx(float(wolf.armor),15.0),"Wolfheart should replace Worgen Armor with 15 before level scaling.")
	HuntsmanSystem.activate_inner_beast(wolf);HuntsmanSystem.update(wolf,2.9);HuntsmanSystem.resolve_basic_attack(wolf,100.0,false)
	TestSupport.check(errors,is_equal_approx(float(wolf.huntsman_runtime.inner_beast_remaining),HuntsmanSystem.inner_beast_duration(wolf)) and is_equal_approx(float(wolf.ability_cds[1]),0.0),"Successful Basic Attacks should refresh Inner Beast and safely reduce its cooldown.")
	var target:={"combat_id":"enemy:marked","armor":1000.0,"armor_reduction_sources":[]}
	HuntsmanSystem.apply_mark(hero,target)
	TestSupport.check(errors,int(hero.huntsman_runtime.mark_stacks)==1 and is_equal_approx(ArmorReductionSystem.effective(target),15.0),"The initial Marked for the Kill hit should create stack one.")
	HuntsmanSystem.update(hero,2.0);HuntsmanSystem.add_mark_stack(hero,target)
	TestSupport.check(errors,int(hero.huntsman_runtime.mark_stacks)==2 and is_equal_approx(float(hero.huntsman_runtime.mark_remaining),5.0) and is_equal_approx(ArmorReductionSystem.effective(target),30.0),"Marked for the Kill stacks should refresh the full timer and grow one source.")
	var replacement:={"combat_id":"enemy:replacement","armor":1000.0,"armor_reduction_sources":[]}
	HuntsmanSystem.apply_mark(hero,replacement)
	TestSupport.check(errors,ArmorReductionSystem.effective(target)==0.0 and int(hero.huntsman_runtime.mark_stacks)==1,"Applying a new prey should immediately remove the old Huntsman-owned Armor source.")
	target=replacement
	for ignored in 10:HuntsmanSystem.add_mark_stack(hero,target)
	TestSupport.check(errors,int(hero.huntsman_runtime.mark_stacks)==5,"Baseline Marked for the Kill should cap at five stacks.")
	var roulette:=unit({"tier_7":"huntsman_l27_r2"});HuntsmanSystem.apply_mark(roulette,target)
	for ignored in 8:HuntsmanSystem.add_mark_stack(roulette,target)
	TestSupport.check(errors,int(roulette.huntsman_runtime.mark_stacks)==9 and is_equal_approx(float(roulette.huntsman_runtime.mark_remaining),3.0),"Gilnean Roulette should preserve the initial stack, remove the raw cap, and refresh its three-second duration.")
	HuntsmanSystem.update(roulette,3.1);TestSupport.check(errors,str(roulette.huntsman_runtime.marked_target_id)=="" and int(roulette.huntsman_runtime.mark_stacks)==0,"Mark expiry should clear all Huntsman mark state.")
	var wizened:=unit({"tier_8":"huntsman_l30_3"});HuntsmanSystem.change_form(wizened,"worgen","test")
	var prepared:=HuntsmanSystem.prepare_basic_attack(wizened,{"active_effects":[]})
	TestSupport.check(errors,is_equal_approx(float(prepared.multiplier),1.70) and int(wizened.huntsman_runtime.wizened_attacks)==3,"Wizened Duelist should add to Worgen's Basic Attack bonus for the next three attacks.")
	HuntsmanSystem.resolve_basic_attack(wizened,100.0,true);TestSupport.check(errors,int(wizened.huntsman_runtime.wizened_attacks)==2,"Only successful prepared primary Basic Attacks should consume Wizened Duelist.")
	var innervated:=unit();innervated.huntsman_runtime.human_q_cooldown=10.0;innervated.huntsman_runtime.worgen_q_cooldown=10.0;innervated.huntsman_runtime.shared_e_cooldown=10.0;HuntsmanSystem.update(innervated,2.0,1.5,1.5)
	TestSupport.check(errors,is_equal_approx(float(innervated.huntsman_runtime.human_q_cooldown),7.0) and is_equal_approx(float(innervated.huntsman_runtime.worgen_q_cooldown),7.0) and is_equal_approx(float(innervated.huntsman_runtime.shared_e_cooldown),7.0),"External cooldown recovery should accelerate both form-specific Q timers and shared E.")
	TestSupport.check(errors,HuntsmanData.TALENT_TIERS.size()==8 and HuntsmanData.TEST_BUILDS.size()>=5,"Huntsman should expose every talent tier and representative test builds.")
	return errors
