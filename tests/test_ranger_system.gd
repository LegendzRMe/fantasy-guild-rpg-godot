extends RefCounted

const RangerData = preload("res://scripts/data/ranger_data.gd")
const RangerSystem = preload("res://scripts/systems/ranger_system.gd")
const RangerAbilityPresenter = preload("res://scripts/data/ranger_ability_presenter.gd")
const AbilitySlotSystem = preload("res://scripts/systems/ability_slot_system.gd")
const PercentageHealthDamageSystem = preload("res://scripts/systems/percentage_health_damage_system.gd")
const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func ranger(talents:Array=[])->Dictionary:
	var selected:={}
	for i in talents.size():selected["tier_%d"%(i+1)]=talents[i]
	var hero:={"class":"Ranger","level":1,"hp":1340.0,"max_hp":1340.0,"armor":0.0,"range":185.0,"movement_speed":145.0,"base_basic_action_interval":1.0/1.67,"basic_attack_interval":1.0/1.67,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"selected_talents":selected,"selected_heroic_id":"","active_effects":[]}
	RangerSystem.initialize_runtime(hero,true);return hero

static func run()->Array:
	var errors:=[];var definition:=RangerData.CLASS_DEFINITION
	TestSupport.check(errors,definition.base_health==1340.0 and definition.base_power==70.0 and is_equal_approx(1.0/definition.basic_action_interval,1.67) and definition.base_armor==0.0,"Ranger V1 should expose the locked Level 1 chassis.")
	TestSupport.check(errors,is_equal_approx(RangerData.scaled(100.0,4),100.0*pow(1.04,3)) and is_equal_approx(RangerData.SPACE.basic_range,185.0),"Ranger scalable values and source-to-world fallback should be explicit and deterministic.")
	var tier_three:=TalentSystem.tier_definition(definition,"tier_3");var tier_seven:=TalentSystem.tier_definition(definition,"tier_7")
	TestSupport.check(errors,tier_three.option_ids==["ranger_l15_r1","ranger_l15_r2"] and tier_seven.heroic_requirements.ranger_l27_r2=="ranger_l15_r2","Ranger Heroic upgrades should enforce the matching Level 15 choice.")
	var hero:=ranger();var target:={"combat_id":"enemy:a","hp":1000.0,"max_hp":1000.0,"active_effects":[],"combat_tags":[]}
	for i in 12:RangerSystem.add_hatred(hero,1)
	TestSupport.check(errors,hero.ranger_runtime.hatred==10 and is_equal_approx(hero.ranger_movement_multiplier,1.10) and is_equal_approx(RangerSystem.basic_attack_multiplier(hero,target),1.8),"Hatred should cap at 10 and grant 8% Basic Attack damage and 1% Movement Speed per stack.")
	RangerSystem.update(hero,4.9);RangerSystem.add_hatred(hero,1);RangerSystem.update(hero,4.9)
	TestSupport.check(errors,hero.ranger_runtime.hatred==10,"A successful Basic Attack should refresh the shared Hatred timer.")
	RangerSystem.update(hero,0.2);TestSupport.check(errors,hero.ranger_runtime.hatred==0,"Hatred should expire together after five unrefreshed seconds.")
	var creed:=ranger(["ranger_l9_3"])
	for i in 300:RangerSystem.on_basic_attack_resolved(creed,{"resolved_damage":1.0},false,false)
	TestSupport.check(errors,is_equal_approx(creed.ranger_runtime.creed_bonus,0.06),"Creed of the Hunter should cap at six one-percent upgrades after 300 successful Basic Attacks.")
	var controlled_target:=target.duplicate(true);controlled_target.active_effects=[{"control_type":"slow","remaining_duration":1.0}];var executioner:=ranger(["","","","","","","","ranger_l30_3"])
	RangerSystem.on_basic_attack_released(executioner,controlled_target);TestSupport.check(errors,executioner.ranger_runtime.executioner_remaining==3.0,"Executioner should trigger after the qualifying Basic Attack checks live control.")
	var manticore:=ranger(["","","","","","ranger_l24_3"]);var first:=RangerSystem.on_basic_attack_released(manticore,target);var second:=RangerSystem.on_basic_attack_released(manticore,target);var third:=RangerSystem.on_basic_attack_released(manticore,target)
	TestSupport.check(errors,first.percent_request.is_empty() and second.percent_request.is_empty() and is_equal_approx(float(third.percent_request.amount),40.0),"Manticore should trigger every third Basic Attack for four percent against ordinary targets.")
	var boss:=target.duplicate(true);boss.boss=true;boss.percent_damage_health_basis=5000.0;var boss_request:=PercentageHealthDamageSystem.request(manticore,boss,0.04,0.01,"Manticore")
	TestSupport.check(errors,boss_request.amount==50.0 and boss_request.health_basis==5000.0 and not boss_request.allows_lifesteal,"Percentage-health damage should use the explicit pre-difficulty basis and boss fraction without lifesteal.")
	var sequential:=AbilitySlotSystem.create(2,10.0,AbilitySlotSystem.RechargeMode.SEQUENTIAL);AbilitySlotSystem.spend(sequential);AbilitySlotSystem.spend(sequential);AbilitySlotSystem.update(sequential,10.0)
	TestSupport.check(errors,sequential.current_charges==1 and sequential.timers.size()==1,"Sequential charges should restore one charge and begin the next recharge.")
	AbilitySlotSystem.reduce_active_recharge(sequential,5.0);AbilitySlotSystem.update(sequential,5.0);TestSupport.check(errors,sequential.current_charges==2,"Direct recharge reduction should affect only the active sequential timer.")
	var independent:=AbilitySlotSystem.create(2,10.0,AbilitySlotSystem.RechargeMode.INDEPENDENT);AbilitySlotSystem.spend(independent);AbilitySlotSystem.spend(independent);AbilitySlotSystem.update(independent,10.0)
	TestSupport.check(errors,independent.current_charges==2 and independent.timers.is_empty(),"Independent charges should recharge concurrently for Cleric-compatible effects.")
	var presenter:=RangerAbilityPresenter.details(hero,"Q");TestSupport.check(errors,str(presenter.description).contains("140") and not str(presenter.description).contains("140."),"Ranger player-facing damage should be rounded down to whole numbers.")
	return errors

