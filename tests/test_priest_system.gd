extends RefCounted
const TestSupport=preload("res://tests/test_support.gd")
const PriestData=preload("res://scripts/data/priest_data.gd")
const PriestSystem=preload("res://scripts/systems/priest_system.gd")
const AutomaticAllyResolutionSystem=preload("res://scripts/systems/automatic_ally_resolution_system.gd")

static func priest(talents:Dictionary={},level:int=1)->Dictionary:
	var hero:={"class":"Priest","combat_id":"hero:priest","combat_team":"player","level":level,"hp":PriestData.scaled(1665.0,level),"max_hp":PriestData.scaled(1665.0,level),"power":PriestData.scaled(85.0,level),"ability_cds":[0.0,0.0,0.0,0.0,0.0],"selected_talents":talents,"selected_heroic_id":"","active_effects":[],"pos":Vector2.ZERO,"shield":0.0,"shield_sources":[]}
	PriestSystem.initialize_runtime(hero,true);return hero

static func run()->Array:
	var errors:=[]
	TestSupport.check(errors,PriestData.IDS.values()==["priest_basic_attack","priest_trait","priest_q","priest_w","priest_e","priest_r1","priest_r2"],"Priest should expose stable public combat IDs.")
	TestSupport.check(errors,PriestData.TALENT_TIERS.size()==8 and PriestData.TALENT_TIERS[2].option_ids==["priest_l15_r1","priest_l15_r2"],"Priest should expose the complete eight-tier tree and Heroic fork.")
	TestSupport.check(errors,PriestData.CLASS_DEFINITION.uses_mana==false and PriestData.CLASS_DEFINITION.basic_action_type=="attack" and PriestData.CLASS_DEFINITION.basic_action_range==185.0,"Priest should be a resource-free ranged physical Basic Attacker.")
	var hero:=priest();var farther:={"combat_id":"hero:b","combat_team":"player","hp":50.0,"max_hp":100.0,"pos":Vector2(40,0)};var nearer:={"combat_id":"hero:a","combat_team":"player","hp":50.0,"max_hp":100.0,"pos":Vector2(20,0)}
	TestSupport.check(errors,AutomaticAllyResolutionSystem.most_wounded([farther,nearer],hero,100.0)==nearer,"Most-wounded resolution should use deterministic distance tie-breaking.")
	var full:={"combat_id":"hero:full","combat_team":"player","hp":100.0,"max_hp":100.0,"pos":Vector2(10,0)}
	TestSupport.check(errors,PriestSystem.most_wounded([full],hero,100.0)==full,"Flash Heal should allow a full-Health completion target and overhealing.")
	hero=priest({"tier_1":"priest_l9_1"});hero.priest_runtime.previous_flash_target="hero:old";hero.ability_cds[0]=5.0;var amount:=PriestSystem.flash_heal_amount(hero,nearer);PriestSystem.complete_flash_heal(hero,nearer,amount)
	TestSupport.check(errors,is_equal_approx(amount,PriestSystem.ability_amount(hero,280.0)*1.15) and is_equal_approx(float(hero.ability_cds[0]),3.0),"Evenhanded Blessings should increase alternating healing and refund forty percent cooldown.")
	hero=priest({"tier_2":"priest_l12_2","tier_5":"priest_l21_2","tier_6":"priest_l24_3"});var target:={"combat_id":"enemy:a","active_effects":[{"id":"priest_chastise_root","owner_id":"hero:priest","remaining_duration":1.0}]};var basic:=PriestSystem.note_basic_attack(hero,target,{"resolved_damage":85.0})
	TestSupport.check(errors,basic.trigger_surge and hero.priest_runtime.push_stacks==1 and hero.priest_runtime.benediction_progress==1,"Successful Basic Attacks should route Surge, Push Forward, and Benediction through one trigger path.")
	var surge_basic:=PriestSystem.note_basic_attack(hero,target,{"resolved_damage":85.0},"priest_surge")
	TestSupport.check(errors,not surge_basic.trigger_surge and hero.priest_runtime.push_stacks==2 and hero.priest_runtime.benediction_progress==2,"Surge attacks should participate in Basic Attack triggers without recursively creating another Surge attack.")
	var lightbomb_contacts:Array=[]
	for index in 7:lightbomb_contacts.append({"combat_tags":[]})
	lightbomb_contacts.append({"combat_tags":["training"]})
	TestSupport.check(errors,PriestSystem.capped_immediate_contacts(lightbomb_contacts)==5,"Lightbomb Shield contribution should accept immediate combat targets, exclude training objects, and cap at five.")
	hero=priest({"tier_8":"priest_l30_2"},30);PriestSystem.enter_spirit(hero);var update:=PriestSystem.update(hero,8.1)
	TestSupport.check(errors,PriestSystem.spirit_active(hero) and update.spirit_expired and hero.ability_cds.slice(0,3)==[0.0,0.0,0.0],"Eternal Vanguard should provide eight-second Spirit Form with Q/W/E available.")
	return errors
