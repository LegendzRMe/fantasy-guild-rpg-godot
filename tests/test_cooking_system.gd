extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const CookingData = preload("res://scripts/data/cooking_data.gd")
const CookingSystem = preload("res://scripts/systems/cooking_system.gd")
const ProfessionSystem = preload("res://scripts/systems/profession_system.gd")
const RecruitmentSystem = preload("res://scripts/systems/recruitment_system.gd")
const TavernFacilitySystem = preload("res://scripts/systems/tavern_facility_system.gd")
const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func cooking_progress(style_scores:Array,techniques:Array) -> Dictionary:
	var progress:=ProfessionSystem.default_progress();progress.profession_id="cooking";progress.profession_slots[0]="cooking";progress.profession_rank=5;progress.profession_xp=600;progress.profession_specialization_score=style_scores.duplicate();progress.known_personal_techniques=techniques.duplicate()
	for rank in 5:progress.profession_choices[str(rank+1)]="test_%d"%(rank+1)
	progress.profession_commitment=CookingData.commitment(progress);return progress

static func run() -> Array:
	var errors:=[];var state:=SaveManager.fresh_state();state.gold=500;var cook_id:=str(state.heroes[0].hero_id)
	state.heroes[0].profession_progress=cooking_progress([5,0],["cooking_familiar_offer","cooking_table_talk","cooking_campaign_menus","cooking_room_and_board","cooking_house_banquet"]);CookingSystem.ensure_state(state)
	TestSupport.check(errors,CookingSystem.commitment(state,cook_id)=="house_favorite" and CookingData.PROFESSION_CHOICES.size()==5,"Five Hospitality/Guild Care ranks should resolve the House Favorite commitment from the normal profession record.")
	var candidate:=RecruitmentSystem.generate_candidate(state,1,177);state.recruitment.candidates=[candidate];CookingSystem.ensure_state(state);TavernFacilitySystem.add_prepared_meals(state,"adventurers_supper",1,cook_id)
	var served:=CookingSystem.serve_candidate_meal(state,cook_id,"adventurers_supper");var refreshed:=CookingSystem.on_candidate_refresh(state);candidate.remaining_wait_minutes=5.0;var offer:=CookingSystem.familiar_offer_status(state);var talked:=CookingSystem.table_talk(state,"class",0.1)
	TestSupport.check(errors,bool(served.success) and bool(refreshed.success) and bool(offer.available) and int(offer.cost)==int(ceil(float(candidate.signing_cost)*0.9)),"Familiar Offer should require a served meal, a patron refresh, and the final five-minute window before applying its data-driven discount.")
	TestSupport.check(errors,bool(talked.success) and talked.outcome=="full" and RecruitmentSystem.field_is_revealed(candidate,"class") and not bool(CookingSystem.table_talk(state,"class",0.1).success),"Table Talk should target one category, support deterministic outcomes, and be limited to once per patron.")
	TestSupport.check(errors,not bool(CookingSystem.activate_campaign_menu(state,cook_id,"adventurers_supper","").success),"Campaign Menus must remain unavailable without an owning recruitment campaign instead of fabricating an event.")

	var care_state:=SaveManager.fresh_state();var care_cook:=str(care_state.heroes[0].hero_id);var resting_hero:=str(care_state.heroes[1].hero_id);care_state.heroes[0].profession_progress=cooking_progress([0,5],["cooking_rested_and_ready","cooking_care_route","cooking_mission_meals","cooking_second_course","cooking_guild_feast"]);CookingSystem.ensure_state(care_state)
	TavernFacilitySystem.add_prepared_meals(care_state,"fortifying_meal",1,care_cook);var rest:=TavernFacilitySystem.start_rest(care_state,resting_hero,"fortifying_meal");care_state.game_clock.total_minutes=10.0;TavernFacilitySystem.advance(care_state,10.0);var meal_buff:=TavernFacilitySystem.active_temporary_buff(care_state,resting_hero)
	TestSupport.check(errors,bool(rest.success) and float(meal_buff.get("temporary_hp_percent",0.0))==0.10 and int(meal_buff.remaining_missions)==1,"A Guild Care mission meal should finish through the shared Tavern rest queue and grant a visible, one-mission buff.")
	TavernFacilitySystem.start_recovery(care_state,resting_hero,"serious");TavernFacilitySystem.add_prepared_meals(care_state,"hefty_meal",1,care_cook);var complete:=TavernFacilitySystem.serve_complete_rest_meal(care_state,resting_hero,"hefty_meal");care_state.game_clock.total_minutes=70.0;TavernFacilitySystem.advance(care_state,60.0)
	TestSupport.check(errors,bool(complete.success) and not TavernFacilitySystem.active_temporary_buff(care_state,resting_hero).is_empty(),"Complete Rest should preserve the normal injury duration and grant its selected mission meal only after recovery finishes.")

	var target:={"hp":100.0,"max_hp":100.0,"shield":10.0,"shield_sources":[],"temporary_hp":20.0,"armor":0.0};var source:={"level":1,"power":10.0,"critical_chance":0.0,"damage_multiplier":1.0};var damage:=CombatSystem.resolve_damage(source,target,{"amount":35.0,"damage_type":"physical","source_action":"basic_attack"},1.0)
	TestSupport.check(errors,float(damage.shield_damage)==10.0 and float(damage.temporary_hp_damage)==20.0 and float(damage.health_damage)==5.0,"Meal temporary HP must remain behind shields and ahead of regular health in the shared damage resolver.")

	var improvised:=SaveManager.fresh_state();var improviser_id:=str(improvised.heroes[0].hero_id);improvised.heroes[0].profession_progress=cooking_progress([3,2],[]);CookingSystem.ensure_state(improvised);TavernFacilitySystem.add_prepared_meals(improvised,"hefty_meal",1,improviser_id);var prepared_id:=str(improvised.tavern_facility.prepared_meals[0].prepared_meal_id);var conversion:=CookingSystem.improviser_convert(improvised,improviser_id,prepared_id,"fatty_meal")
	TestSupport.check(errors,CookingSystem.commitment(improvised,improviser_id)=="kitchen_improviser" and bool(conversion.success) and str(improvised.tavern_facility.prepared_meals[0].meal_id)=="fatty_meal" and not bool(CookingSystem.improviser_convert(improvised,improviser_id,prepared_id,"hefty_meal").success),"Kitchen Improviser should convert only a same-category, same-tier known meal once per Tavern refresh.")
	return errors
