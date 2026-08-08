extends RefCounted

const TestSupport=preload("res://tests/test_support.gd")
const SlayerData=preload("res://scripts/data/slayer_data.gd")
const SlayerSystem=preload("res://scripts/systems/slayer_system.gd")
const EvasionSystem=preload("res://scripts/systems/evasion_system.gd")
const BlockChargeSystem=preload("res://scripts/systems/block_charge_system.gd")
const TargetCategorySystem=preload("res://scripts/systems/combat_target_category_system.gd")

static func slayer(talents:Dictionary={},level:int=1)->Dictionary:
	var hero:={"class":"Slayer","combat_id":"hero:slayer","combat_affiliation":"player","level":level,"hp":SlayerData.scaled(1725.0,level),"max_hp":SlayerData.scaled(1725.0,level),"power":SlayerData.scaled(78.0,level),"ability_cds":[6.0,8.0,15.0,100.0,0.0],"selected_talents":talents,"selected_heroic_id":"slayer_l15_r1","base_basic_action_interval":1.0/1.82,"active_effects":[],"pos":Vector2.ZERO}
	SlayerSystem.initialize_runtime(hero,true);return hero

static func run()->Array:
	var errors:=[]
	TestSupport.check(errors,SlayerData.IDS.values()==["slayer_basic_attack","slayer_trait","slayer_q","slayer_w","slayer_e","slayer_r1","slayer_r2"],"Slayer should expose stable public combat IDs.")
	TestSupport.check(errors,SlayerData.TALENT_TIERS.size()==8 and SlayerData.TALENT_TIERS[2].option_ids==["slayer_l15_r1","slayer_l15_r2"],"Slayer should expose the approved eight-tier tree and Heroic fork.")
	TestSupport.check(errors,SlayerData.CLASS_DEFINITION.base_health==1725.0 and is_equal_approx(1.0/float(SlayerData.CLASS_DEFINITION.basic_action_interval),1.82) and SlayerData.CLASS_DEFINITION.armor_family=="leather","Slayer should use the verified Level 1 chassis.")
	TestSupport.check(errors,is_equal_approx(SlayerData.scaled(78.0,30),243.2548),"Slayer should apply four-percent level scaling.")

	var hero:=slayer();EvasionSystem.activate(hero,2.5,"slayer_e")
	TestSupport.check(errors,EvasionSystem.should_evade(hero,"basic_attack",true) and EvasionSystem.should_evade(hero,"basic_attack",true) and not EvasionSystem.should_evade(hero,"basic_ability",true),"Evasion should avoid every hostile damaging Basic Action but not abilities.")
	EvasionSystem.update(hero,2.6);TestSupport.check(errors,not EvasionSystem.is_active(hero),"Evasion should expire deterministically.")

	hero=slayer({"tier_4":"slayer_l18_1"});SlayerSystem.grant_dive_block(hero)
	TestSupport.check(errors,BlockChargeSystem.charges(hero,"slayer_block")==3 and not BlockChargeSystem.armor_source(hero,75.0,"test","slayer_block").has("damage_type"),"Reflexive Block should grant three universal Block charges.")
	TestSupport.check(errors,not BlockChargeSystem.consume(hero,"basic_attack",0.0,false,"slayer_block") and BlockChargeSystem.consume(hero,"basic_attack",10.0,false,"slayer_block") and BlockChargeSystem.charges(hero,"slayer_block")==2,"Block should consume only on a positive non-evaded Basic Action.")

	hero=slayer({"tier_1":"slayer_l9_2"});SlayerSystem.note_sweep(hero,[{"combat_tags":[]},{"combat_tags":[]}]);TestSupport.check(errors,is_equal_approx(float(hero.slayer_runtime.sweep_bonus),1.25) and is_equal_approx(float(hero.slayer_runtime.sweep_bonus_remaining),5.0),"Battered Assault should require two contacts and grant its five-second bonus.")
	hero=slayer({"tier_2":"slayer_l12_1"});SlayerSystem.begin_rapid_chase(hero,"enemy:a");TestSupport.check(errors,hero.ability_cds[0]==0.0 and SlayerSystem.rapid_target_valid(hero,"enemy:b") and not SlayerSystem.rapid_target_valid(hero,"enemy:a"),"Rapid Chase should offer one different-target recast.")
	SlayerSystem.update(hero,3.1);TestSupport.check(errors,is_equal_approx(float(hero.ability_cds[0]),float(SlayerData.VALUES.q_cooldown)) and not bool(hero.slayer_runtime.rapid_recast_available),"Rapid Chase should defer Q cooldown until its recast window expires.")
	hero=slayer({"tier_2":"slayer_l12_3"})
	var quest_targets:=[]
	for index in 15:
		quest_targets.append({"combat_id":"enemy:%d"%index,"combat_tags":[]})
	SlayerSystem.note_sweep(hero,quest_targets)
	TestSupport.check(errors,bool(hero.slayer_runtime.unbound_complete) and int(hero.slayer_runtime.w_slot.max_charges)==2,"Unbound should grant a second W charge at fifteen qualifying contacts.")
	hero=slayer({"tier_4":"slayer_l18_2"});hero.slayer_runtime.sweep_bonus_remaining=2.0;hero.hp-=100.0;var trait_result:=SlayerSystem.note_basic_attack(hero,{}, {"resolved_damage":100.0});TestSupport.check(errors,is_equal_approx(float(trait_result.raw_healing),50.0) and hero.ability_cds[0]==5.0 and hero.ability_cds[2]==14.0,"A successful Basic Attack should heal and reduce Q/E/Heroic cooldowns.")
	hero=slayer({"tier_6":"slayer_l24_2"});var brand_target:={"combat_id":"enemy:brand","combat_tags":[]};TestSupport.check(errors,not SlayerSystem.prepare_basic_attack(hero,brand_target) and not SlayerSystem.prepare_basic_attack(hero,brand_target) and SlayerSystem.prepare_basic_attack(hero,brand_target),"Fiery Brand should prime on every third consecutive attack against one target.")

	var summon:={"summoned_unit":true,"combat_tags":[]};var boss:={"boss":true,"combat_tags":["boss"]};var training:={"combat_tags":["training"]}
	TestSupport.check(errors,TargetCategorySystem.qualifies_immediate(summon) and not TargetCategorySystem.qualifies_quest(summon) and TargetCategorySystem.qualifies_quest(boss) and not TargetCategorySystem.qualifies_immediate(training),"Shared target categories should separate immediate effects from encounter progress.")
	hero=slayer({"tier_8":"slayer_l30_3"});var gained:=SlayerSystem.add_unending_thirst(hero,9999.0);TestSupport.check(errors,is_equal_approx(gained,hero.max_hp*.25),"Unending Thirst should cap at twenty-five percent current maximum Health.")
	hero=slayer();var base_max:=float(hero.max_hp);var meta_bonus:=SlayerSystem.begin_metamorphosis(hero,99);TestSupport.check(errors,is_equal_approx(meta_bonus,SlayerSystem.scaled(hero,float(SlayerData.VALUES.r1_health_per_target))*int(SlayerData.VALUES.r1_target_cap)) and hero.max_hp>base_max,"Metamorphosis should cap temporary Health at five valid contacts.");SlayerSystem.end_metamorphosis(hero);TestSupport.check(errors,is_equal_approx(float(hero.max_hp),base_max),"Metamorphosis should safely remove only its temporary Health.")
	hero=slayer({"tier_7":"slayer_l27_r1"});TestSupport.check(errors,is_equal_approx(SlayerSystem.attack_interval(hero),(1.0/1.82)/1.2) and hero.control_duration_multipliers.stun==.5,"Demonic Form should apply attack speed and shared Stun/Root duration modifiers.")
	return errors
