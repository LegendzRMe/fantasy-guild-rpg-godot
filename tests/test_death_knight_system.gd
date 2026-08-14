extends RefCounted

const TestSupport=preload("res://tests/test_support.gd")
const DeathKnightData=preload("res://scripts/data/death_knight_data.gd")
const DeathKnightSystem=preload("res://scripts/systems/death_knight_system.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")
const HealingReceivedModifierSystem=preload("res://scripts/systems/healing_received_modifier_system.gd")
const IncomingDamageReductionSystem=preload("res://scripts/systems/incoming_damage_reduction_system.gd")
const QuestProgressModifierSystem=preload("res://scripts/systems/quest_progress_modifier_system.gd")
const StatusEffectSystem=preload("res://scripts/systems/status_effect_system.gd")
const WarriorSystem=preload("res://scripts/systems/warrior_system.gd")

static func unit(talents:Dictionary={},heroic:String="",level:int=1,mastery:Dictionary={})->Dictionary:
	var hero:={"class":"Death Knight","role":"Melee DPS","combat_id":"hero:death_knight","combat_affiliation":"player","battle_index":0,"level":level,"hp":DeathKnightData.scaled(float(DeathKnightData.VALUES.health),level),"max_hp":DeathKnightData.scaled(float(DeathKnightData.VALUES.health),level),"health_regeneration":DeathKnightData.scaled(float(DeathKnightData.VALUES.health_regeneration),level),"armor":0.0,"threat_modifier":1.0,"pos":Vector2.ZERO,"active_effects":[],"selected_talents":talents,"selected_heroic_id":heroic,"base_basic_action_interval":float(DeathKnightData.VALUES.basic_attack_interval),"basic_attack_interval":float(DeathKnightData.VALUES.basic_attack_interval),"ability_cds":[0.0,0.0,0.0,0.0,0.0]}
	DeathKnightSystem.initialize_runtime(hero,true,mastery,"test:death_knight")
	return hero

static func enemy(id:String,category:String="standard")->Dictionary:
	return {"combat_id":id,"combat_affiliation":"enemy","target_category":category,"combat_tags":[category],"hp":2000.0,"max_hp":2000.0,"pos":Vector2.ZERO,"active_effects":[]}

static func hit(amount:float=1.0)->Dictionary:return {"resolved_damage":amount,"evaded":false,"immune":false}

static func run()->Array:
	var errors:Array=[]
	var definition:=DeathKnightData.CLASS_DEFINITION
	TestSupport.check(errors,is_equal_approx(float(definition.base_health),2100.0) and is_equal_approx(float(definition.health_regeneration),4.3752) and is_equal_approx(float(definition.base_power),95.0),"Death Knight should use the audited level-one Health, regeneration, and Basic Attack anchors.")
	TestSupport.check(errors,is_equal_approx(float(definition.basic_action_interval),1.1) and is_equal_approx(float(definition.basic_action_range),2.0*float(DeathKnightData.SPACE.source_to_world)) and not bool(definition.uses_mana),"Death Knight should use the audited melee cadence/range and no mana resource.")
	TestSupport.check(errors,is_equal_approx(float(definition.base_armor),0.0) and is_equal_approx(float(definition.threat_modifier),1.0) and str(definition.primary_role)=="Melee DPS" and str(definition.armor_family)=="plate","Death Knight should preserve its intended role, threat, Armor, and Plate identity.")
	TestSupport.check(errors,is_equal_approx(DeathKnightData.scaled(2100.0,2),2184.0) and is_equal_approx(DeathKnightData.scaled(95.0,2),98.8),"Death Knight Health and damage should scale exactly four percent per level.")
	var expected:=[];for tier in DeathKnightData.TALENT_TIERS:expected.append_array(tier.option_ids)
	TestSupport.check(errors,expected.size()==22 and DeathKnightData.TALENT_TIERS.size()==8 and DeathKnightData.TEST_BUILDS.size()==6 and DeathKnightData.TALENT_TIERS[6].heroic_requirements=={"death_knight_l27_r1":"death_knight_l15_r1","death_knight_l27_r2":"death_knight_l15_r2"},"Death Knight should expose all 22 approved options, eight tiers, six Range builds, and matching heroic-upgrade gates.")

	var base:=unit();var standard:=enemy("standard");TestSupport.check(errors,DeathKnightSystem.activate_frostmourne(base,true),"Frostmourne should prime while ready.");var plan:=DeathKnightSystem.frostmourne_attack_plan(base,standard)
	TestSupport.check(errors,is_equal_approx(float(plan.bonus_damage),71.0) and not bool(plan.was_controlled),"Baseline Frostmourne should add an independent 71-damage packet.")
	DeathKnightSystem.resolve_frostmourne_attack(base,standard,hit(71.0),false,false);TestSupport.check(errors,int(base.death_knight_runtime.frostmourne_stacks)==0 and is_equal_approx(float(base.death_knight_runtime.frostmourne_cooldown),12.0),"A living standard enemy should start Frostmourne's cooldown without granting progression.")
	base.death_knight_runtime.frostmourne_cooldown=0.0;DeathKnightSystem.activate_frostmourne(base,true);DeathKnightSystem.resolve_frostmourne_attack(base,standard,hit(71.0),true,false);TestSupport.check(errors,int(base.death_knight_runtime.frostmourne_stacks)==1 and is_equal_approx(DeathKnightSystem.basic_attack_amount(base),95.75) and is_equal_approx(DeathKnightSystem.frostmourne_bonus(base),74.0),"A standard kill should grant one stack worth +0.75 Basic Attack and +3 Frostmourne damage.")
	for category in ["elite","named","boss","enemy_hero"]:base.death_knight_runtime.frostmourne_cooldown=0.0;DeathKnightSystem.activate_frostmourne(base,true);DeathKnightSystem.resolve_frostmourne_attack(base,enemy(category,category),hit(),false,false)
	TestSupport.check(errors,int(base.death_knight_runtime.frostmourne_stacks)==5,"Elite, named, Boss, and enemy-hero hits should progress Frostmourne without requiring kills.")
	for category in ["summon","temporary_combat"]:base.death_knight_runtime.frostmourne_cooldown=0.0;DeathKnightSystem.activate_frostmourne(base,true);DeathKnightSystem.resolve_frostmourne_attack(base,enemy(category,category),hit(),true,false)
	TestSupport.check(errors,int(base.death_knight_runtime.frostmourne_stacks)==5,"Summons and temporary-combat targets should never progress Frostmourne.")
	var pact:=unit({"tier_8":"death_knight_l30_1"});TestSupport.check(errors,int(pact.death_knight_runtime.frostmourne_stacks)==10,"Death Pact should begin each encounter at ten stacks.");DeathKnightSystem.activate_frostmourne(pact,true);DeathKnightSystem.resolve_frostmourne_attack(pact,enemy("elite","elite"),hit(),false,false);TestSupport.check(errors,int(pact.death_knight_runtime.frostmourne_stacks)==12,"Death Pact should double each qualifying Frostmourne gain.")
	QuestProgressModifierSystem.apply(pact,"shared",2.0,5.0);pact.death_knight_runtime.frostmourne_cooldown=0.0;DeathKnightSystem.activate_frostmourne(pact,true);DeathKnightSystem.resolve_frostmourne_attack(pact,enemy("boss","boss"),hit(),false,false);TestSupport.check(errors,int(pact.death_knight_runtime.frostmourne_stacks)==14,"Shared Legacy should not multiply Frostmourne weapon progression.")

	TestSupport.check(errors,is_equal_approx(DeathKnightSystem.death_coil_damage(base),164.0) and is_equal_approx(DeathKnightSystem.death_coil_heal(base,true),275.0) and is_equal_approx(DeathKnightSystem.death_coil_cooldown(base,true),9.0),"Death Coil should preserve its baseline damage, self-heal, and cooldown.")
	var immortal:=unit({"tier_4":"death_knight_l18_1"});TestSupport.check(errors,is_equal_approx(DeathKnightSystem.death_coil_heal(immortal,true),481.25) and is_equal_approx(DeathKnightSystem.death_coil_cooldown(immortal,true),6.0),"Immortal Coil should improve only the manual self-cast heal and cooldown.")
	var deathlord:=unit({"tier_5":"death_knight_l21_1"});deathlord.hp=deathlord.max_hp*.5;TestSupport.check(errors,is_equal_approx(DeathKnightSystem.death_coil_damage(deathlord),205.0),"Deathlord should interpolate to +25% damage at half Health.")
	var dominion:=unit({"tier_8":"death_knight_l30_3"});TestSupport.check(errors,is_equal_approx(DeathKnightSystem.dominion_amount(dominion,false),.25) and is_equal_approx(DeathKnightSystem.dominion_amount(dominion,true),.40),"Death's Dominion should choose 25% or 40% from the pre-cast control snapshot.")

	TestSupport.check(errors,is_equal_approx(DeathKnightSystem.howling_damage(base),68.0) and is_equal_approx(DeathKnightSystem.howling_root(base),1.25),"Howling Blast should preserve baseline damage and Root.")
	var deathchill:=unit({"tier_5":"death_knight_l21_2"});deathchill.death_knight_runtime.frostmourne_stacks=4;TestSupport.check(errors,is_equal_approx(DeathKnightSystem.howling_damage(deathchill),76.0) and is_equal_approx(DeathKnightSystem.howling_root(deathchill),1.5),"Deathchill should add two damage per weapon stack and 0.25 seconds of Root.")
	var shattered:=unit({"tier_2":"death_knight_l12_1"});var controlled:=enemy("controlled");StatusEffectSystem.apply_control(controlled,"slow",2.0,.5);StatusEffectSystem.apply_control(controlled,"root",1.0);var extension:=DeathKnightSystem.extend_preexisting_controls(shattered,controlled);TestSupport.check(errors,is_equal_approx(float(extension.slow),1.0) and is_equal_approx(float(extension.root),.5),"Shattered Armor should extend each pre-existing eligible control by 50%.")

	var tempest:=unit();var toggle:=DeathKnightSystem.toggle_tempest(tempest);TestSupport.check(errors,bool(toggle.active) and DeathKnightSystem.locked_slots(tempest)==[0,1,3,4] and not DeathKnightSystem.action_allowed(tempest,0),"Frozen Tempest should activate with D/Q/W/R locked.")
	DeathKnightSystem.update(tempest,.99);TestSupport.check(errors,not bool(DeathKnightSystem.update(tempest,0.0).tempest_tick),"Frozen Tempest should not tick before one second.");var tick_update:=DeathKnightSystem.update(tempest,.011);TestSupport.check(errors,bool(tick_update.tempest_tick),"Frozen Tempest's first tick should occur after the first one-second interval.")
	var tick_target:=enemy("tempest");var tick_plan:=DeathKnightSystem.tempest_tick_plan(tempest,tick_target);for _i in 4:tick_plan=DeathKnightSystem.tempest_tick_plan(tempest,tick_target)
	TestSupport.check(errors,is_equal_approx(float(tick_plan.suppression),.4) and is_equal_approx(float(tick_plan.damage),36.0),"Frozen Tempest suppression should ramp ten points per target and cap at 40% without changing baseline damage.")
	DeathKnightSystem.toggle_tempest(tempest);TestSupport.check(errors,is_equal_approx(float(tempest.death_knight_runtime.tempest.cooldown),8.0) and tempest.death_knight_runtime.suppression.is_empty(),"Turning Tempest off should begin its eight-second cooldown and clear encounter-local ramps.")
	var eternal:=unit({"tier_8":"death_knight_l30_2"});DeathKnightSystem.toggle_tempest(eternal);tick_plan=DeathKnightSystem.tempest_tick_plan(eternal,enemy("eternal"))
	TestSupport.check(errors,DeathKnightSystem.locked_slots(eternal).is_empty() and is_equal_approx(float(tick_plan.suppression),.2),"Eternal Winter should remove the slot lock and ramp suppression by 20 points per tick.")
	var borean:=unit({"tier_1":"death_knight_l9_2"});TestSupport.check(errors,is_equal_approx(DeathKnightSystem.tempest_cooldown(borean),7.0) and is_equal_approx(DeathKnightSystem.tempest_linger(borean),2.0),"Borean Winds should shorten cooldown and extend suppression linger by the intended values.")

	var presence:=unit({"tier_1":"death_knight_l9_1"});var ids:=[]
	for i in 8:ids.append("target%d"%i)
	DeathKnightSystem.add_frost_presence_progress(presence,ids);TestSupport.check(errors,DeathKnightSystem.frost_presence_progress(presence)==5,"Frost Presence should count unique quest-valid targets with a five-contact cast cap.")
	QuestProgressModifierSystem.apply(presence,"shared",2.0,8.0);DeathKnightSystem.add_frost_presence_progress(presence,ids);TestSupport.check(errors,DeathKnightSystem.frost_presence_progress(presence)==15 and DeathKnightSystem.frost_presence_reward(presence,15),"Shared Legacy should multiply Frost Presence quest progress and unlock the first reward.")
	for _i in 4:DeathKnightSystem.add_frost_presence_progress(presence,ids)
	TestSupport.check(errors,DeathKnightSystem.frost_presence_progress(presence)==50 and DeathKnightSystem.frost_presence_mastered(presence),"Frost Presence should cap at 50 and persist mastery.")
	DeathKnightSystem.reset_encounter(presence,"test:next");TestSupport.check(errors,DeathKnightSystem.frost_presence_progress(presence)==0 and DeathKnightSystem.frost_presence_mastered(presence),"A new encounter should clear Frost Presence run progress but retain member mastery.")

	var rime:=unit({"tier_1":"death_knight_l9_3"});StatusEffectSystem.apply_control(rime,"root",2.0);TestSupport.check(errors,is_equal_approx(IncomingDamageReductionSystem.multiplier(rime),.25),"Rime should trigger 75% source-aware damage reduction from a successful incoming Root.")
	var anti_magic:=unit({"tier_6":"death_knight_l24_3"});var anti_control:=StatusEffectSystem.apply_control(anti_magic,"stun",4.0);var anti_blind:=StatusEffectSystem.apply_blind(anti_magic,4.0);TestSupport.check(errors,is_equal_approx(float(anti_control.duration),3.0) and not bool(anti_blind.applied),"Anti-Magic Shell should shorten incoming hard control by 25% and grant Blind immunity.")
	var icy:=unit({"tier_2":"death_knight_l12_2"});DeathKnightSystem.toggle_tempest(icy);DeathKnightSystem.note_tempest_contacts(icy,5);TestSupport.check(errors,is_equal_approx(float(icy.death_knight_runtime.icy_talons),.15) and is_equal_approx(float(icy.basic_attack_interval),1.1/1.15),"Icy Talons should add 3% per unique tick contact and update attack cadence.")
	var rune:=unit({"tier_4":"death_knight_l18_2"});DeathKnightSystem.toggle_tempest(rune)
	for _i in 3:DeathKnightSystem.note_primary_basic_attack(rune,hit())
	TestSupport.check(errors,is_equal_approx(HealingReceivedModifierSystem.multiplier(rune),1.05) and is_equal_approx(DeathKnightSystem.rune_aura_bonus(rune),.05),"Rune Tap should grant its passive healing bonus and one aura stack every third successful Tempest Basic Attack.")
	var biting:=unit({"tier_5":"death_knight_l21_3"});var biting_target:=enemy("biting");var biting_plan:Dictionary={}
	for _i in 6:biting_plan=DeathKnightSystem.tempest_tick_plan(biting,biting_target)
	TestSupport.check(errors,is_equal_approx(float(biting_plan.damage),63.0),"Biting Cold should reach its 75% per-target damage cap after continuous exposure.")
	var remorseless:=unit({"tier_6":"death_knight_l24_1"});var rem_target:=enemy("remorseless");var roots:=0;for _i in 12:if bool(DeathKnightSystem.tempest_tick_plan(remorseless,rem_target).root):roots+=1
	TestSupport.check(errors,roots==1,"Remorseless Winter should Root once after 2.5 seconds and respect its per-target internal cooldown.")

	var army:=unit({},"death_knight_l15_r1");var ghouls:=DeathKnightSystem.cast_army(army);TestSupport.check(errors,ghouls.size()==6 and int(army.death_knight_runtime.army_slot.current_charges)==0 and is_equal_approx(float(ghouls[0].remaining_lifetime),15.0) and is_equal_approx(float(ghouls[0].damage),20.0) and str(ghouls[0].owner_id)==str(army.combat_id) and str(ghouls[0].source_id)!=str(ghouls[1].source_id),"Army should consume all six starting charges and create six exact, independently identified 15-second Ghouls.")
	var warrior:={"selected_talents":{"tier_5":"warrior_l21_1"},"warrior_runtime":{"recent_summon_lifetime_before":0.0,"recent_summon_lifetime_after":0.0,"telemetry_enabled":false}};var anti_summon:=WarriorSystem.anti_summon(warrior,ghouls[0]);TestSupport.check(errors,is_equal_approx(float(anti_summon.damage),48.0) and is_equal_approx(float(anti_summon.removed),.6) and is_equal_approx(float(ghouls[0].remaining_lifetime),14.4),"Army Ghouls should satisfy Warrior's generic summon Health and original-lifetime interface without class-specific handling.")
	DeathKnightSystem.note_nearby_enemy_death(army,0.0);TestSupport.check(errors,is_equal_approx(float(army.death_knight_runtime.army_slot.timers[0]),17.0),"A nearby enemy death should reduce Army's active charge timer by one second.")
	DeathKnightSystem.update(army,17.0);TestSupport.check(errors,int(army.death_knight_runtime.army_slot.current_charges)==1 and army.death_knight_runtime.ghouls.is_empty(),"Army charges should restore sequentially while Ghouls expire cleanly at 15 seconds.")
	var legion:=unit({"tier_7":"death_knight_l27_r1"},"death_knight_l15_r1");TestSupport.check(errors,DeathKnightSystem.cast_army(legion).size()==12 and is_equal_approx(float(legion.death_knight_runtime.army_slot.recharge_duration),13.0),"Legion of Northrend should create two Ghouls per charge and use a 13-second recharge.")
	var feeds:=unit({"tier_6":"death_knight_l24_2"});StatusEffectSystem.apply_control(standard,"slow",1.0,.2);DeathKnightSystem.activate_frostmourne(feeds,true);plan=DeathKnightSystem.frostmourne_attack_plan(feeds,standard);DeathKnightSystem.resolve_frostmourne_attack(feeds,standard,hit(),false,bool(plan.was_controlled));TestSupport.check(errors,is_equal_approx(float(feeds.death_knight_runtime.frostmourne_cooldown),5.0),"Frostmourne Feeds should use the pre-hit control snapshot for a five-second cooldown.")

	return errors
