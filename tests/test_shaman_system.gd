extends RefCounted
const TestSupport=preload("res://tests/test_support.gd")
const ShamanData=preload("res://scripts/data/shaman_data.gd")
const ShamanSystem=preload("res://scripts/systems/shaman_system.gd")
const ProgressionScopeSystem=preload("res://scripts/systems/progression_scope_system.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")

static func shaman(talents:Dictionary={},mastery:Dictionary={},level:int=1)->Dictionary:
	var hero:={"class":"Shaman","combat_id":"hero:shaman","combat_team":"player","level":level,"hp":ShamanData.scaled(float(ShamanData.VALUES.health),level),"max_hp":ShamanData.scaled(float(ShamanData.VALUES.health),level),"power":ShamanData.scaled(float(ShamanData.VALUES.basic_attack_damage),level),"ability_cds":[0.0,0.0,0.0,0.0,0.0],"selected_talents":talents,"selected_heroic_id":"","active_effects":[],"pos":Vector2.ZERO,"shield":0.0,"shield_sources":[]}
	ShamanSystem.initialize_runtime(hero,true,mastery,"test:1");return hero

static func hit(amount:float=100.0)->Dictionary:return {"resolved_damage":amount,"evaded":false,"immune":false}

static func run()->Array:
	var errors:=[]
	TestSupport.check(errors,ShamanData.IDS.values()==["shaman_basic_attack","shaman_trait","shaman_q","shaman_w","shaman_e","shaman_r1","shaman_r2"],"Shaman should expose stable public combat IDs.")
	TestSupport.check(errors,ShamanData.TALENT_TIERS.size()==8 and ShamanData.TALENT_TIERS[7].option_ids==["shaman_l30_1","shaman_l30_2","shaman_l30_3"],"Shaman should expose the locked eight-tier tree and final capstones.")
	TestSupport.check(errors,not bool(ShamanData.CLASS_DEFINITION.uses_mana) and str(ShamanData.CLASS_DEFINITION.resource_id)=="" and str(ShamanData.CLASS_DEFINITION.basic_action_damage_type)=="physical","Shaman should be a resource-free melee Physical attacker.")
	TestSupport.check(errors,is_equal_approx(ShamanData.scaled(100.0,2),104.0),"Shaman values should use four-percent level scaling.")

	var hero:=shaman();var activations:=ShamanSystem.add_frostwolf_stacks(hero,12)
	TestSupport.check(errors,activations.size()==2 and int(hero.shaman_runtime.frostwolf_stacks)==2,"Frostwolf should preserve overflow and allow multiple activations from one event.")
	hero=shaman({"tier_2":"shaman_l12_3"});hero.hp=hero.max_hp;activations=ShamanSystem.add_frostwolf_stacks(hero,5,float(hero.hp));var overflow:=ShamanSystem.overflow_shield_request(hero,activations[0],{"overhealing":200.0})
	TestSupport.check(errors,is_equal_approx(float(overflow.amount),100.0) and is_equal_approx(float(overflow.cap),float(hero.max_hp)*.10),"Overflowing Resilience should convert half of actual overhealing and cap at ten percent maximum Health.")

	hero=shaman({"tier_1":"shaman_l9_2"});for cast_index in 30:ShamanSystem.note_chain_cast(hero,"a",["a","b","c"])
	TestSupport.check(errors,ShamanSystem.reward_active(hero,"crash_1") and ShamanSystem.reward_active(hero,"crash_2") and ShamanSystem.mastery_progress(hero,"shaman_l9_2")==30,"Crash should progress once per qualifying cast and earn both encounter rewards at 30.")
	ShamanSystem.reset_encounter(hero,"test:2")
	TestSupport.check(errors,not ShamanSystem.reward_active(hero,"crash_1") and ShamanSystem.mastery_progress(hero,"shaman_l9_2")==30,"Encounter reset should clear Crash rewards without clearing character mastery.")
	hero=shaman({"tier_1":"shaman_l9_2"});ShamanSystem.note_chain_cast(hero,"summon:a",["summon:a","summon:b","summon:c"],"player_chain",[])
	TestSupport.check(errors,ShamanSystem.encounter_progress(hero,"crash")==0,"Immediate summon contacts should remain valid combat hits without advancing quest-category progress.")

	hero=shaman({"tier_1":"shaman_l9_1"});hero.shaman_runtime.echo_assists["enemy:a"]=2.0
	TestSupport.check(errors,ShamanSystem.note_echo_defeat(hero,"enemy:a") and ShamanSystem.encounter_progress(hero,"echo")==1 and not ShamanSystem.note_echo_defeat(hero,"enemy:a"),"Echo should award one assisted defeat inside its participation window and consume the credit.")
	hero=shaman({"tier_1":"shaman_l9_3"});ShamanSystem.begin_windfury(hero)
	for attack_index in 3:ShamanSystem.note_basic_attack(hero,"enemy:%d"%attack_index,hit(),"windfury_attack_%d"%(attack_index+1))
	TestSupport.check(errors,ShamanSystem.encounter_progress(hero,"maelstrom")==3 and ShamanSystem.mastery_progress(hero,"shaman_l9_3")==3,"Maelstrom should progress encounter and mastery from successful Windfury-window attacks.")
	ShamanSystem.note_basic_attack(hero,"enemy:x",hit(),"tempest_fury_subhit")
	TestSupport.check(errors,ShamanSystem.encounter_progress(hero,"maelstrom")==3,"Tempest Fury subhits should not progress Maelstrom.")

	hero=shaman({"tier_2":"shaman_l12_2"});for cast_index in 5:ShamanSystem.note_feral_cast(hero,1)
	ShamanSystem.note_feral_cast(hero,0);TestSupport.check(errors,ShamanSystem.encounter_progress(hero,"frostwolf_pack")==0,"An unfinished Frostwolf Pack quest should reset when Feral Spirit misses.")
	for cast_index in 6:ShamanSystem.note_feral_cast(hero,1)
	TestSupport.check(errors,ShamanSystem.reward_active(hero,"frostwolf_pack") and is_equal_approx(ShamanSystem.feral_cooldown(hero),5.0),"Six successful Feral Spirit casts should halve W cooldown for the encounter.")

	hero=shaman({"tier_4":"shaman_l18_1","tier_5":"shaman_l21_3"});ShamanSystem.mark_rolling(hero,"enemy:a");var basic:=ShamanSystem.note_basic_attack(hero,"enemy:a",hit(120.0))
	TestSupport.check(errors,bool(basic.rolling) and is_equal_approx(float(basic.bonus_damage),30.0) and int(basic.frostwolf_stacks)==1 and int(hero.shaman_runtime.gathering_stacks)==1,"Rolling Thunder and Gathering Storm should share successful Basic Attack resolution without percentage-Health damage.")
	TestSupport.check(errors,is_equal_approx(ShamanSystem.gathering_snapshot(hero),1.005) and int(hero.shaman_runtime.gathering_stacks)==0,"A damaging Basic Ability should snapshot and consume Gathering Storm.")

	hero=shaman({"tier_4":"shaman_l18_2"});for stack in 8:ShamanSystem.add_frostwolf_stacks(hero,5)
	TestSupport.check(errors,bool(hero.shaman_runtime.ancestral_ready) and ShamanSystem.note_ability_contacts(hero,2) and is_equal_approx(float(hero.shaman_runtime.ancestral_remaining),3.0),"Eight Frostwolf activations should arm Ancestral Wrath for the next two-target Basic Ability.")
	TestSupport.check(errors,is_equal_approx(ShamanSystem.note_damage(hero,100.0),150.0),"Ancestral Wrath should request healing equal to 150 percent of resolved Shaman damage.")

	hero=shaman({"tier_6":"shaman_l24_2"});ShamanSystem.note_chain_cast(hero,"a",["a"]);ShamanSystem.note_chain_cast(hero,"a",["a"]);ShamanSystem.note_chain_cast(hero,"b",["b"])
	TestSupport.check(errors,int(hero.shaman_runtime.thunder_stacks)==2,"Thunderstorm should progress only when the primary target changes and never erase stacks on repeats.")
	hero=shaman({"tier_6":"shaman_l24_3"});ShamanSystem.mark_alpha(hero,"boss");TestSupport.check(errors,is_equal_approx(ShamanSystem.alpha_multiplier(hero,"boss"),1.05),"Alpha Wolf should be one non-stacking five-percent Shaman-only multiplier, including on Bosses.")

	hero=shaman({"tier_8":"shaman_l30_1"});var storm:=ShamanSystem.note_chain_cast(hero,"a",["a","b","c","d","e"]);var echo:=ShamanSystem.note_chain_cast(hero,"e",["e","f"],"stormcaller_chain")
	TestSupport.check(errors,bool(storm.stormcaller) and not bool(echo.stormcaller),"Stormcaller should trigger at five unique contacts and never recurse from its generated chain.")
	hero=shaman({"tier_8":"shaman_l30_2"});ShamanSystem.begin_windfury(hero);var final:Dictionary={}
	for target_id in ["a","b","c"]:final=ShamanSystem.note_basic_attack(hero,target_id,hit(),"windfury_attack_1")
	TestSupport.check(errors,bool(final.fury_recast),"Fury of the Winds should recast only after three successful empowered attacks hit three distinct combat IDs.")

	var saved:={};ProgressionScopeSystem.add_mastery(saved,"shaman_l9_1",7);var runtime:={};ProgressionScopeSystem.begin_encounter(runtime,"dungeon:1");ProgressionScopeSystem.add_encounter_progress(runtime,"quest",4);ProgressionScopeSystem.room_transition(runtime,"dungeon:1")
	TestSupport.check(errors,int(runtime.encounter_progress.quest)==4 and ProgressionScopeSystem.mastery_progress(saved,"shaman_l9_1")==7,"Room transitions should preserve encounter progress and persistent mastery.")
	ProgressionScopeSystem.end_encounter(runtime);TestSupport.check(errors,runtime.encounter_progress.is_empty() and ProgressionScopeSystem.mastery_progress(saved,"shaman_l9_1")==7,"Encounter end should clear encounter progress only.")
	hero=shaman();AbilitySlotSystem.spend(hero.shaman_runtime.q_slot);var q_before:float=float(hero.shaman_runtime.q_slot.timers[0]);ShamanSystem.update(hero,2.0,1.5);TestSupport.check(errors,is_equal_approx(float(hero.shaman_runtime.q_slot.timers[0]),q_before-3.0),"External cooldown recovery should accelerate Shaman's internal Q charge slot.")
	return errors
