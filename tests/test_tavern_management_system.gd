extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TavernManagementData = preload("res://scripts/data/tavern_management_data.gd")
const TavernManagementSystem = preload("res://scripts/systems/tavern_management_system.gd")
const TavernFacilitySystem = preload("res://scripts/systems/tavern_facility_system.gd")
const ProfessionSystem = preload("res://scripts/systems/profession_system.gd")
const RecruitmentSystem = preload("res://scripts/systems/recruitment_system.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run() -> Array:
	var errors:=[];var state:=SaveManager.testing_state();var host_id:=str(state.heroes[0].hero_id);var chef_id:=str(state.heroes[1].hero_id)
	TavernManagementSystem.ensure_state(state);var host:=TavernManagementSystem.assign_member(state,"host",host_id);var chef:=TavernManagementSystem.assign_member(state,"chef",chef_id);var steward:=TavernManagementSystem.assign_member(state,"steward",str(state.heroes[2].hero_id))
	TestSupport.check(errors,bool(host.success) and bool(chef.success) and not bool(steward.success) and str(TavernFacilitySystem.member_status(state,host_id).status)=="tavern_assignment","Level 1 should save Host and Chef assignments, mark them unavailable through the shared member status, and keep Steward locked.")
	TavernManagementSystem.remove_assignment(state,"host");TestSupport.check(errors,bool(TavernFacilitySystem.member_status(state,host_id).available),"Removing a Tavern assignment should immediately restore normal availability.")

	var cooking:=SaveManager.fresh_state();var cooking_chef:=str(cooking.heroes[0].hero_id);TavernManagementSystem.assign_member(cooking,"chef",cooking_chef);InventorySystem.add_material(cooking,"provisions",10);var provisions_before:=TavernManagementSystem._material_quantity(cooking,"provisions");var started:=TavernManagementSystem.start_manual_cooking(cooking,"cooking_simple_stew");cooking.tavern_management.manual_cooking.marker=0.5;var perfect:=TavernManagementSystem.stop_manual_cooking(cooking)
	TestSupport.check(errors,bool(started.success) and perfect.result=="perfect" and int(perfect.servings)==2 and TavernManagementSystem._material_quantity(cooking,"provisions")==provisions_before-1,"Manual cooking should consume Depot ingredients exactly once and a Perfect stop should add one bonus serving.")
	TavernManagementSystem.start_manual_cooking(cooking,"cooking_simple_stew");cooking.tavern_management.manual_cooking.marker=0.6;TavernManagementSystem.stop_manual_cooking(cooking)
	TestSupport.check(errors,ProfessionSystem.is_pattern_mastered(cooking,"cooking_simple_stew"),"Perfect and Cooked results should use the shared three-success recipe mastery record.")
	var target:=TavernManagementSystem.set_automation(cooking,"cooking_simple_stew",4);TavernManagementSystem.set_level(cooking,2);TavernManagementSystem.advance(cooking,5.0,false);TavernManagementSystem.advance(cooking,5.0,false)
	TestSupport.check(errors,bool(target.success) and TavernFacilitySystem.meal_count(cooking,"simple_stew")>=4 and str(cooking.tavern_management.automation.status) in ["Cooking","At target"],"A Level 2 assigned Chef should automate a mastered recipe from Guild Storage until its stock target is reached.")
	TavernManagementSystem.remove_assignment(cooking,"chef");var stock_before:=TavernFacilitySystem.meal_count(cooking,"simple_stew");TavernManagementSystem.advance(cooking,20.0,false);TestSupport.check(errors,TavernFacilitySystem.meal_count(cooking,"simple_stew")==stock_before and str(cooking.tavern_management.automation.status)=="Paused","Removing the Chef should pause automated cooking without producing meals.")

	var resting:=SaveManager.testing_state();var rest_id:=str(resting.heroes[0].hero_id);TavernManagementSystem.set_rest_meal(resting,"simple_stew");TavernFacilitySystem.add_prepared_meals(resting,"simple_stew",1);var placed:=TavernManagementSystem.assign_rest_slot(resting,0,rest_id);TavernFacilitySystem.advance(resting,4.0);var paused:=TavernManagementSystem.remove_rest_slot(resting,0);var paused_remaining:=float(resting.tavern_facility.paused_rest_progress.get(rest_id,0.0));TavernManagementSystem.assign_rest_slot(resting,0,rest_id);TavernFacilitySystem.advance(resting,paused_remaining);TavernManagementSystem.advance(resting,0.0,false)
	TestSupport.check(errors,bool(placed.success) and bool(paused.success) and paused_remaining<10.0 and TavernFacilitySystem.meal_count(resting,"simple_stew")==0 and not TavernFacilitySystem.active_temporary_buff(resting,rest_id).is_empty(),"Manual rest should pause on removal, consume the selected meal only on completion, and grant one shared meal buff.")
	var auto_rest:=SaveManager.testing_state();TavernManagementSystem.set_level(auto_rest,2);TavernManagementSystem.advance(auto_rest,0.1,true);TestSupport.check(errors,auto_rest.tavern_management.rest_slots.any(func(slot):return str(slot.hero_id)!=""),"Level 2 should automatically fill empty rest slots with eligible inactive members.")

	var campaign_state:=SaveManager.fresh_state();campaign_state.gold=500;TavernManagementSystem.set_level(campaign_state,2);var campaign_start:=TavernManagementSystem.start_campaign(campaign_state,"grand_recruitment");RecruitmentSystem.debug_spawn(campaign_state);RecruitmentSystem.current_candidate(campaign_state).locked=true;TavernManagementSystem.advance(campaign_state,60.0,false);var before_end:=int(campaign_state.gold);var ended:=TavernManagementSystem.end_campaign(campaign_state);var second_end:=TavernManagementSystem.end_campaign(campaign_state)
	TestSupport.check(errors,bool(campaign_start.success) and bool(ended.success) and not bool(second_end.success) and int(ended.report.food_sales)>0 and int(ended.report.staying_fees)>0 and int(ended.report.final_cost)>0 and int(campaign_state.gold)==before_end+int(ended.report.income_granted),"Level 2 campaigns should report food sales and locked-candidate fees, retain a meaningful final cost, and grant recovered Gold exactly once.")
	return errors
