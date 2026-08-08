extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TavernFacilityData = preload("res://scripts/data/tavern_facility_data.gd")
const TavernFacilitySystem = preload("res://scripts/systems/tavern_facility_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func advance_minutes(state:Dictionary,minutes:float)->Array:
	state.game_clock.total_minutes=float(state.game_clock.total_minutes)+minutes
	return TavernFacilitySystem.advance(state,minutes)

static func run()->Array:
	var errors:=[]
	var state:=SaveManager.fresh_state();var first_id:=str(state.heroes[0].hero_id);var second_id:=str(state.heroes[1].hero_id)
	TestSupport.check(errors,state.has("tavern_facility") and state.heroes.all(func(hero):return hero.get("temporary_buffs") is Array),"Fresh and migrated guild data should include the shared Tavern facility and member buff fields.")
	TavernFacilitySystem.start_recovery(state,first_id,"minor");TavernFacilitySystem.start_recovery(state,second_id,"serious")
	TestSupport.check(errors,state.tavern_facility.recovery_cases.size()==2 and not TavernFacilitySystem.member_is_available(state,first_id),"The first recovery model should allow concurrent unlimited recovery stays and make those members unavailable.")
	advance_minutes(state,20.0)
	TestSupport.check(errors,TavernFacilitySystem.recovery_case(state,first_id).is_empty() and is_equal_approx(float(TavernFacilitySystem.recovery_case(state,second_id).remaining_minutes),40.0),"Minor injuries should recover in 20 minutes while serious injuries require 60 minutes.")

	TavernFacilitySystem.add_prepared_meals(state,"common_table_meal",1,second_id,30.0)
	var rest_result:=TavernFacilitySystem.start_rest(state,first_id);advance_minutes(state,TavernFacilityData.VOLUNTARY_REST_MINUTES)
	var buff:=TavernFacilitySystem.active_temporary_buff(state,first_id)
	TestSupport.check(errors,bool(rest_result.success) and not buff.is_empty() and is_equal_approx(float(buff.temporary_hp_percent),0.10) and is_equal_approx(float(buff.expires_at_game_minute)-float(state.game_clock.total_minutes),90.0),"A prepared meal should support ten minutes of voluntary rest and grant one-mission temporary HP with its maker-adjusted duration.")
	var consumed:=TavernFacilitySystem.consume_mission_buff(state,first_id)
	TestSupport.check(errors,not consumed.is_empty() and TavernFacilitySystem.active_temporary_buff(state,first_id).is_empty(),"Well Rested should be consumed when the member begins the next mission.")

	TavernFacilitySystem.add_prepared_meals(state,"common_table_meal",1);TavernFacilitySystem.start_rest(state,first_id);advance_minutes(state,10.0)
	TavernFacilitySystem.start_recovery(state,first_id,"defeated")
	TestSupport.check(errors,TavernFacilitySystem.active_temporary_buff(state,first_id).is_empty() and is_equal_approx(float(TavernFacilitySystem.recovery_case(state,first_id).remaining_minutes),10.0),"Defeat should clear temporary buffs, grant no replacement buff, and start ten-minute recovery.")

	var revived_state:=SaveManager.fresh_state();var revived_id:=str(revived_state.heroes[1].hero_id);var revived_runtime:={"hero_index":1,"hp":50.0,"was_defeated":true}
	var affected:=TavernFacilitySystem.record_battle_defeats(revived_state,[revived_runtime])
	TestSupport.check(errors,revived_id in affected and str(TavernFacilitySystem.recovery_case(revived_state,revived_id).recovery_type)=="defeated","A hero defeated and then resurrected during battle should still automatically enter Tavern recovery afterward.")
	return errors
