extends RefCounted

const TestSupport=preload("res://tests/test_support.gd")
const SentinelData=preload("res://scripts/data/sentinel_data.gd")
const SentinelSystem=preload("res://scripts/systems/sentinel_system.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")
const ArmorReductionSystem=preload("res://scripts/systems/armor_reduction_system.gd")
const OutgoingDamageReductionSystem=preload("res://scripts/systems/outgoing_damage_reduction_system.gd")

static func unit(talents:Dictionary={})->Dictionary:
	var hero:={"class":"Sentinel","combat_id":"hero:sentinel","battle_index":0,"level":1,"power":55.0,"base_power":55.0,"hp":1511.0,"max_hp":1511.0,"armor":0.0,"pos":Vector2(300,300),"range":float(SentinelData.SPACE.basic_range),"selected_talents":talents,"selected_heroic_id":str(talents.get("tier_3","")),"ability_cds":[0.0,0.0,0.0,0.0,0.0],"active_effects":[]}
	SentinelSystem.initialize_runtime(hero,true,"test:encounter");return hero

static func run()->Array:
	var errors:Array=[];var definition:Dictionary=SentinelData.CLASS_DEFINITION
	TestSupport.check(errors,is_equal_approx(float(definition.base_health),1511.0) and is_equal_approx(float(definition.base_power),55.0) and is_equal_approx(float(definition.basic_action_interval),.75),"Sentinel should preserve the audited Level-1 chassis.")
	TestSupport.check(errors,is_equal_approx(float(definition.basic_action_range),6.0*float(SentinelData.SPACE.source_to_world)) and not bool(definition.uses_mana) and is_equal_approx(float(definition.threat_modifier),1.0),"Sentinel should be a resource-free ranged non-tank.")
	var slot:=AbilitySlotSystem.create(2,16.0,AbilitySlotSystem.RechargeMode.FULL_REFILL);AbilitySlotSystem.spend(slot);AbilitySlotSystem.spend(slot);AbilitySlotSystem.update(slot,15.9)
	TestSupport.check(errors,int(slot.current_charges)==0,"Full-refill slots should remain empty until the one recharge completes.")
	AbilitySlotSystem.update(slot,.1);TestSupport.check(errors,int(slot.current_charges)==2 and slot.timers.is_empty(),"Full-refill completion should restore the entire charge pair once.")
	var allies:=[{"combat_id":"b","hp":50.0,"max_hp":100.0,"pos":Vector2(305,300)},{"combat_id":"a","hp":50.0,"max_hp":100.0,"pos":Vector2(500,300)}]
	TestSupport.check(errors,SentinelSystem.select_lowest(allies,Vector2(300,300),300.0)==allies[0],"Light of Elune ties should use party order before combat ID, not distance.")
	var sentinel:=unit();var target:={"combat_id":"enemy:1","armor":25.0,"armor_reduction_sources":[]}
	TestSupport.check(errors,SentinelSystem.apply_mark(sentinel,target,true) and is_equal_approx(float(sentinel.sentinel_runtime.d_cooldown),20.0) and is_equal_approx(ArmorReductionSystem.effective(target),15.0),"Hunter's Mark should apply its source-aware reduction and cooldown.")
	var basic:=SentinelSystem.note_basic_attack(sentinel,target,55.0);TestSupport.check(errors,is_equal_approx(float(basic.self_heal_fraction),.02),"Basic Attacks against the Sentinel's own mark should double self-healing.")
	var flare_target:={"combat_id":"enemy:quest","combat_tags":["regular"]};for hit in 100:SentinelSystem.note_e_hit(sentinel,flare_target,false)
	TestSupport.check(errors,is_equal_approx(SentinelSystem.e_multiplier(sentinel),3.5) and int(sentinel.sentinel_runtime.e_quest_stacks)==84,"Lunar Flare's encounter quest should cap at +250% rather than grow without bound.")
	var no_quest:=unit();SentinelSystem.note_e_hit(no_quest,{"combat_id":"dummy","combat_tags":["training"]},false);TestSupport.check(errors,int(no_quest.sentinel_runtime.e_quest_stacks)==0,"Training, summon, object, and temporary targets must not progress the encounter quest.")
	var reduced:={"active_effects":[]};OutgoingDamageReductionSystem.apply(reduced,"weak",.10,3.0);OutgoingDamageReductionSystem.apply(reduced,"strong",.35,3.0);TestSupport.check(errors,is_equal_approx(OutgoingDamageReductionSystem.multiplier(reduced),.65),"Shared outgoing reductions should use the strongest active source without multiplying.")
	TestSupport.check(errors,SentinelData.TALENT_TIERS.size()==8 and SentinelData.TEST_BUILDS.size()>=5,"Sentinel should expose all talent tiers and representative test builds.")
	return errors
