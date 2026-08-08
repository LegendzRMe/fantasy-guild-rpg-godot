extends RefCounted
const TestSupport=preload("res://tests/test_support.gd")
const RogueData=preload("res://scripts/data/rogue_data.gd")
const RogueSystem=preload("res://scripts/systems/rogue_system.gd")
const ComboPointSystem=preload("res://scripts/systems/combo_point_system.gd")
const AlternateActionSetSystem=preload("res://scripts/systems/alternate_action_set_system.gd")
const StealthDetectionSystem=preload("res://scripts/systems/stealth_detection_system.gd")
const ArmorReductionSystem=preload("res://scripts/systems/armor_reduction_system.gd")

static func make_rogue(talents:Dictionary={})->Dictionary:
	var unit:={"class":"Rogue","combat_id":"hero:rogue","level":1,"hp":2129.0,"max_hp":2129.0,"power":82.0,"armor":0.0,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"selected_talents":talents,"selected_heroic_id":"rogue_l15_r1","pos":Vector2.ZERO,"base_basic_action_interval":0.5,"active_effects":[],"bloodletting_stacks":[]}
	RogueSystem.initialize_runtime(unit,true);return unit

static func run()->Array:
	var errors:=[]
	TestSupport.check(errors,RogueData.CLASS_DEFINITION.base_health==2129.0,"Rogue should use the verified Level 1 Health chassis.")
	TestSupport.check(errors,RogueData.CLASS_DEFINITION.basic_action_interval==0.5,"Rogue should attack twice per second.")
	TestSupport.check(errors,RogueData.CLASS_DEFINITION.basic_action_damage_type=="physical" and not bool(RogueData.CLASS_DEFINITION.uses_mana),"Rogue should use Physical attacks and no Mana or Energy field.")
	TestSupport.check(errors,RogueData.CLASS_DEFINITION.armor_family=="leather" and "dual_wield" in RogueData.CLASS_DEFINITION.weapon_proficiencies,"Rogue proficiencies should match the conversion chassis.")
	TestSupport.check(errors,is_equal_approx(RogueData.scaled(2129.0,30),6639.608),"Rogue Level 30 Health should use four-percent scaling.")
	TestSupport.check(errors,is_equal_approx(RogueData.scaled(4.4354,30),13.83247),"Rogue Level 30 regeneration should use four-percent scaling.")
	TestSupport.check(errors,is_equal_approx(RogueData.scaled(82.0,30),255.7294),"Rogue Level 30 Power should use four-percent scaling.")

	var rogue:=make_rogue();var gain:=ComboPointSystem.gain(rogue,4)
	TestSupport.check(errors,int(gain.gained)==3 and int(gain.wasted)==1 and int(rogue.combo_points)==3,"Combo Points should cap at three and report waste.")
	var spent:=ComboPointSystem.spend(rogue,3)
	TestSupport.check(errors,int(spent.combo_points_used_for_scaling)==3 and int(spent.combo_points_consumed)==3 and int(rogue.combo_points)==0,"Eviscerate should expose separate used and consumed values.")
	rogue=make_rogue({"tier_8":"rogue_l30_3"});ComboPointSystem.gain(rogue,5);spent=ComboPointSystem.spend(rogue,3)
	TestSupport.check(errors,int(rogue.combo_points)==2 and ComboPointSystem.maximum(rogue)==5,"Vigor should store five while Eviscerate consumes at most three.")
	ComboPointSystem.gain(rogue,1);spent=ComboPointSystem.spend(rogue,3,true)
	TestSupport.check(errors,int(spent.combo_points_used_for_scaling)==3 and int(spent.combo_points_consumed)==0 and int(rogue.combo_points)==3,"A free Eviscerate should scale without consuming points.")
	TestSupport.check(errors,ComboPointSystem.successful_hit({"health_damage":0.0,"shield_damage":5.0}),"Positive Shield damage should count as a successful hit.")
	TestSupport.check(errors,not ComboPointSystem.successful_hit({"health_damage":0.0,"shield_damage":0.0}),"A zero-damage result should not generate points.")
	TestSupport.check(errors,not ComboPointSystem.successful_hit({"health_damage":8.0,"immune":true}),"An immune result must not generate points.")
	ComboPointSystem.gain(rogue,2);ComboPointSystem.reset(rogue);TestSupport.check(errors,ComboPointSystem.current(rogue)==0,"Encounter and defeat callers must be able to reset owner-held points.")

	rogue=make_rogue();TestSupport.check(errors,RogueSystem.activate_vanish(rogue),"Ready Vanish should activate.")
	TestSupport.check(errors,is_equal_approx(float(RogueData.VALUES.vanish_threat_reduction),.25),"Vanish should define a twenty-five-percent current-threat reduction.")
	TestSupport.check(errors,str(rogue.active_action_set)=="stealth" and AlternateActionSetSystem.ability_id(rogue,0)=="rogue_stealth_q","Vanish should swap Q/W/E through the reusable action-set system.")
	RogueSystem.update(rogue,1.6);TestSupport.check(errors,bool(rogue.concealment.invisible),"A stationary Rogue should become Invisible after 1.5 seconds.")
	RogueSystem.update(rogue,1.5);TestSupport.check(errors,bool(rogue.rogue_runtime.opener_ready),"Baseline teleport openers should prepare after three seconds.")
	RogueSystem.break_vanish(rogue);TestSupport.check(errors,str(rogue.active_action_set)=="normal" and not StealthDetectionSystem.is_stealthed(rogue),"An opener should safely restore the normal action set.")
	rogue.alternate_cooldowns["rogue_stealth_q"]=2.0;AlternateActionSetSystem.update_hidden_cooldowns(rogue,0.75);TestSupport.check(errors,is_equal_approx(float(rogue.alternate_cooldowns.rogue_stealth_q),1.25),"Hidden alternate cooldowns should continue progressing.")
	rogue=make_rogue({"tier_1":"rogue_l9_2"});RogueSystem.activate_vanish(rogue);RogueSystem.update(rogue,1.5);TestSupport.check(errors,bool(rogue.rogue_runtime.opener_ready),"Subtlety should prepare teleport openers after 1.5 seconds.")

	var observer:={"pos":Vector2.ZERO,"detection_profile":{}};var concealed:=make_rogue();RogueSystem.activate_vanish(concealed)
	TestSupport.check(errors,not StealthDetectionSystem.directly_targetable(observer,concealed,20.0),"Ordinary observers should not directly target an Unrevealable Rogue.")
	observer.detection_profile={"detect_stealthed":true,"detect_invisible":true,"detection_radius":100.0};concealed.concealment.unrevealable_remaining=0.0
	TestSupport.check(errors,StealthDetectionSystem.directly_targetable(observer,concealed,20.0),"An authored detector should acquire Stealthed targets in range.")
	concealed.concealment.unrevealable_remaining=1.0;TestSupport.check(errors,not StealthDetectionSystem.reveal(concealed,2.0),"Reveal must not defeat Unrevealable.")
	concealed.concealment.unrevealable_remaining=0.0;TestSupport.check(errors,StealthDetectionSystem.reveal(concealed,2.0) and StealthDetectionSystem.directly_targetable({},concealed,20.0),"Reveal should temporarily permit ordinary direct targeting.")
	concealed.concealment.invisible=true;StealthDetectionSystem.update(concealed,0.1,true);TestSupport.check(errors,not bool(concealed.concealment.invisible) and bool(concealed.rogue_runtime.vanish_active),"Movement should leave Invisible without ending Vanish.")
	StealthDetectionSystem.set_source(concealed,"smoke:test",true,true,true);TestSupport.check(errors,StealthDetectionSystem.is_invisible(concealed) and StealthDetectionSystem.is_unrevealable(concealed) and str(concealed.active_action_set)=="stealth","A concealment source should not independently replace the current action set.")
	StealthDetectionSystem.set_source(concealed,"smoke:test",false);TestSupport.check(errors,not StealthDetectionSystem.is_unrevealable(concealed),"Leaving a concealment source should remove its protection.")

	var target:={"armor":50.0,"armor_reduction_sources":[]};ArmorReductionSystem.apply(target,"weak",10.0,10.0);ArmorReductionSystem.apply(target,"strong",20.0,2.0)
	TestSupport.check(errors,is_equal_approx(ArmorReductionSystem.effective(target),20.0) and is_equal_approx(ArmorReductionSystem.effective_armor(target),30.0),"Only the strongest Armor reduction should apply.")
	ArmorReductionSystem.update(target,3.0);TestSupport.check(errors,is_equal_approx(ArmorReductionSystem.effective(target),10.0),"A weaker source should become effective after the stronger source expires.")
	ArmorReductionSystem.apply(target,"weak",12.0,8.0);TestSupport.check(errors,target.armor_reduction_sources.size()==1 and is_equal_approx(ArmorReductionSystem.effective(target),12.0),"Reapplying one source should refresh rather than stack.")
	ArmorReductionSystem.apply(target,"equal",12.0,4.0);TestSupport.check(errors,target.armor_reduction_sources.size()==2 and is_equal_approx(ArmorReductionSystem.effective(target),12.0),"Equal reductions should remain separate deterministic source records without stacking.")
	target.armor=0.0;TestSupport.check(errors,is_equal_approx(ArmorReductionSystem.effective_armor(target),0.0),"Armor reduction must never create negative Armor.")
	ArmorReductionSystem.clear(target);TestSupport.check(errors,target.armor_reduction_sources.is_empty(),"Encounter cleanup should clear Armor-reduction sources.")

	rogue=make_rogue({"tier_1":"rogue_l9_3"});var proc:=RogueSystem.double_strike_roll(rogue,0.05)
	TestSupport.check(errors,bool(proc.success) and int(rogue.combo_points)==1,"Double Strike should support deterministic proc tests.")
	rogue.combo_points=3;proc=RogueSystem.double_strike_roll(rogue,0.0);TestSupport.check(errors,not bool(proc.attempted),"Double Strike should not roll while capped.")
	rogue=make_rogue({"tier_4":"rogue_l18_3"});rogue.rogue_runtime.slice_attacks=3;rogue.rogue_runtime.slice_remaining=3.0;TestSupport.check(errors,is_equal_approx(RogueSystem.attack_interval(rogue),0.1),"Slice and Dice should interpret 400% as a bonus and use five times the normal rate.")
	RogueSystem.consume_slice_attack(rogue);RogueSystem.consume_slice_attack(rogue);RogueSystem.consume_slice_attack(rogue);TestSupport.check(errors,is_equal_approx(RogueSystem.attack_interval(rogue),0.5),"The fourth release after Slice and Dice should use the normal interval.")
	rogue=make_rogue({"tier_8":"rogue_l30_2"});RogueSystem.activate_vanish(rogue);TestSupport.check(errors,is_equal_approx(RogueSystem.movement_multiplier(rogue),1.4),"Elusiveness should make Vanish's total movement bonus forty percent.")
	return errors
