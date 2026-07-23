extends RefCounted

const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func unit(extra:Dictionary={}) -> Dictionary:
	var result:={"active_effects":[]}
	result.merge(extra,true)
	return result

static func run()->Array:
	var errors:=[]
	var ordinary:=unit();var applied:=CombatSystem.apply_blind(ordinary,1.5)
	TestSupport.check(errors,applied.applied and CombatSystem.is_blinded(ordinary) and is_equal_approx(applied.duration,1.5),"Ordinary units should receive full-duration Blind.")
	CombatSystem.apply_blind(ordinary,0.5)
	TestSupport.check(errors,is_equal_approx(ordinary.active_effects[0].remaining_duration,1.5),"A weaker Blind reapplication must not shorten the active Blind.")
	var boss:=unit({"boss":true});var resisted:=CombatSystem.apply_blind(boss,2.0)
	TestSupport.check(errors,resisted.resisted and not CombatSystem.is_blinded(boss),"Bosses should be Blind-immune by default through their shared control profile.")
	var partial:=unit({"boss":true,"control_profile":{"blind_immune":false,"blind_duration_multiplier":0.5}});var partial_result:=CombatSystem.apply_blind(partial,2.0)
	TestSupport.check(errors,partial_result.applied and is_equal_approx(partial_result.duration,1.0),"Per-unit profiles should support partial boss Blind duration without display-name checks.")
	var protected:=unit({"active_effects":[{"id":"control_stun","control_type":"stun","remaining_duration":2.0},{"id":"damage_over_time","remaining_duration":3.0}]})
	var unstoppable:=CombatSystem.apply_unstoppable(protected,1.0);var blocked:=CombatSystem.apply_control(protected,"root",2.0)
	TestSupport.check(errors,unstoppable.removed==["stun"] and protected.active_effects.any(func(effect):return effect.id=="damage_over_time") and blocked.resisted,"Unstoppable should cleanse and prevent removable control without removing damage effects.")
	var fear_blocked:=CombatSystem.apply_control(protected,"fear",2.0)
	TestSupport.check(errors,fear_blocked.resisted and not CombatSystem.is_feared(protected),"Unstoppable should prevent Fear through the shared control pipeline.")
	var feared:=unit();var fear_result:=CombatSystem.apply_control(feared,"fear",2.0);var silence_result:=CombatSystem.apply_control(feared,"silence",2.0)
	TestSupport.check(errors,fear_result.applied and silence_result.applied and CombatSystem.is_feared(feared) and CombatSystem.is_silenced(feared),"Ordinary units should expose reusable Fear and Silence state.")
	var fear_immune_boss:=unit({"boss":true});var boss_fear:=CombatSystem.apply_control(fear_immune_boss,"fear",2.0)
	TestSupport.check(errors,boss_fear.resisted and not CombatSystem.is_feared(fear_immune_boss),"Default Boss profiles should be Fear immune.")
	var reduced_fear_boss:=unit({"boss":true,"control_profile":{"fear_multiplier":0.25}});var reduced_fear:=CombatSystem.apply_control(reduced_fear_boss,"fear",2.0)
	TestSupport.check(errors,reduced_fear.applied and is_equal_approx(float(reduced_fear.duration),0.5),"Boss profiles should support explicitly reduced Fear duration.")
	var miss_events:=CombatSystem.event_bundle_for_basic_action_miss(unit(),unit(),{"damage_type":"physical"})
	TestSupport.check(errors,miss_events.map(func(event):return event.event_type)==["basic_action_missed","blind_miss","basic_action_completed"],"Blind misses should emit completion telemetry without hit or damage events.")
	var attack_event:=CombatSystem.create_event("basic_attack_hit",unit(),unit(),{"resolved_damage":1.0,"source_action":"basic_attack","result_category":"damage"});var heal_event:=CombatSystem.create_event("basic_heal_done",unit(),unit(),{"effective_amount":1.0,"source_action":"basic_heal","result_category":"healing"});var ability_event:=CombatSystem.create_event("basic_ability_cast",unit(),unit(),{"amount":0.0,"source_action":"basic_ability","result_category":"buff"});var trait_event:=CombatSystem.create_event("trait_cast",unit(),unit(),{"amount":0.0,"source_action":"trait","result_category":"buff"})
	TestSupport.check(errors,"basic_action" in attack_event.action_tags and "basic_action" in heal_event.action_tags and "basic_action" not in ability_event.action_tags and "basic_ability" not in trait_event.action_tags and trait_event.source_action=="trait","Shared events should preserve Basic Action, Basic Ability, Heroic, and Trait taxonomy without parallel categories.")
	return errors
