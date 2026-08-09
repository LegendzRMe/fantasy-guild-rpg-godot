extends RefCounted
const TestSupport=preload("res://tests/test_support.gd")
const TemplarData=preload("res://scripts/data/templar_data.gd")
const TemplarSystem=preload("res://scripts/systems/templar_system.gd")

static func unit(talents:Dictionary={})->Dictionary:
	var hero:={"class":"Templar","combat_id":"hero:templar","level":1,"power":111.0,"base_power":111.0,"hp":2490.0,"max_hp":2490.0,"shield":0.0,"shield_sources":[],"selected_talents":talents,"ability_cds":[0.0,0.0,0.0,0.0,0.0]};TemplarSystem.initialize_runtime(hero,true,"test:templar");return hero

static func run()->Array:
	var errors:Array=[]
	TestSupport.check(errors,is_equal_approx(TemplarData.scaled(100.0,2),104.0),"Templar values should use 4% per-level scaling.")
	TestSupport.check(errors,TemplarData.CLASS_DEFINITION.uses_mana==false and str(TemplarData.CLASS_DEFINITION.resource_id)=="","Templar should be resource-free.")
	var hero:=unit();hero.hp=1800.0
	var activation:=TemplarSystem.try_activate_trait_after_damage(hero,10.0)
	TestSupport.check(errors,not activation.is_empty() and is_equal_approx(float(activation.amount),365.0),"Damage below 75% Health should activate Shield Overload.")
	TestSupport.check(errors,TemplarSystem.try_activate_trait_after_damage(hero,10.0).is_empty(),"Shield Overload should respect cooldown.")
	var no_damage:=unit();no_damage.hp=1000.0
	TestSupport.check(errors,TemplarSystem.try_activate_trait_after_damage(no_damage,0.0).is_empty(),"Zero damage must not activate Shield Overload.")
	var battery:=unit({"tier_2":"templar_l12_2"});battery.hp=1000.0;TemplarSystem.try_activate_trait_after_damage(battery,1.0);var before:=float(battery.templar_runtime.trait_cooldown);TemplarSystem.update(battery,1.0,10.0)
	TestSupport.check(errors,is_equal_approx(before-float(battery.templar_runtime.trait_cooldown),2.25),"Shield Battery should recharge Shield Overload 125% faster while active.")
	var quest:=unit({"tier_1":"templar_l9_3"});var enemy:={"combat_tags":["standard"],"summoned_unit":false,"object":false};TemplarSystem.note_successful_basic_attack(quest,enemy,false)
	TestSupport.check(errors,int(quest.templar_runtime.protector_stacks)==1 and is_equal_approx(TemplarSystem.basic_attack_multiplier(quest),1.001),"Protector of Aiur should add 0.1% per quest-valid Basic Attack.")
	var depletion:=unit({"tier_2":"templar_l12_1"});for count in 20:TemplarSystem.note_e_depletion(depletion)
	TestSupport.check(errors,is_equal_approx(float(depletion.templar_runtime.give_twenty_bonus),300.0) and is_equal_approx(TemplarSystem.e_cooldown(depletion),10.0),"Give Me Twenty should cap at +300 and set E to 10 seconds after 20 depletions.")
	var titan:=unit({"tier_6":"templar_l24_1"});titan.templar_runtime.trait_active=true;titan.shield_sources=[{"source_id":"templar_shield_overload","amount":100.0}]
	TestSupport.check(errors,is_equal_approx(TemplarSystem.titan_bonus(titan,false),(2490.0+100.0)*0.005),"Titan Killer should use Templar max Health plus remaining exact D Shield.")
	TestSupport.check(errors,TemplarSystem.q_contact_reduction({"combat_tags":["boss"]})==2.0 and TemplarSystem.q_contact_reduction({"combat_tags":["standard"]})==1.0,"Blade Dash cooldown reduction should distinguish priority categories.")
	return errors
