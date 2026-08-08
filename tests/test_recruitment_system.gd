extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const RecruitmentData = preload("res://scripts/data/recruitment_data.gd")
const RecruitmentSystem = preload("res://scripts/systems/recruitment_system.gd")
const GameClockSystem = preload("res://scripts/systems/game_clock_system.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func average(values:Array)->float:
	var total:=0.0
	for value in values:total+=float(value)
	return total/maxf(1.0,values.size())

static func run() -> Array:
	var errors:=[]
	var zero:=SaveManager.fresh_state();zero.gold=100;RecruitmentSystem.set_budget(zero,0);var zero_gold:=int(zero.gold);RecruitmentSystem.advance(zero,60.0)
	TestSupport.check(errors,RecruitmentSystem.current_candidate(zero).is_empty() and int(zero.gold)==zero_gold,"A zero hourly recruitment budget should create no candidate and spend no Gold.")
	var activity_before_budget_change:int=zero.recruitment.activity_log.size();RecruitmentSystem.set_budget(zero,5);RecruitmentSystem.set_budget(zero,2)
	TestSupport.check(errors,zero.recruitment.activity_log.size()==activity_before_budget_change,"Changing the Tavern Budget should not flood the patron activity log.")
	TestSupport.check(errors,RecruitmentSystem.set_tavern_name(zero,"  The Copper Kettle  ")=="The Copper Kettle" and zero.recruitment.tavern_name=="The Copper Kettle","The player should be able to personalize the saved Tavern name.")

	var state:=SaveManager.fresh_state();state.guild_name="Recruitment Test";state.gold=500
	for hero in state.heroes:hero.level=4
	RecruitmentSystem.set_budget(state,3);RecruitmentSystem.advance(state,59.0)
	TestSupport.check(errors,RecruitmentSystem.current_candidate(state).is_empty(),"A candidate should not arrive before the hourly check completes.")
	var arrival_events:=RecruitmentSystem.advance(state,1.0);var candidate:=RecruitmentSystem.current_candidate(state)
	TestSupport.check(errors,not candidate.is_empty() and arrival_events.any(func(event):return event.type=="candidate_arrived") and int(state.gold)==497,"A positive budget should spend the real Gold amount and create one candidate after one game hour.")
	TestSupport.check(errors,str(candidate.hero_record.class_id) in RecruitmentData.BEGINNER_CLASS_IDS and GameData.CLASSES.has(str(candidate.hero_record["class"])),"Recruitment should generate only registered beginner classes.")
	TestSupport.check(errors,str(candidate.origin_zone_id)==RecruitmentData.ORIGIN_ZONE_ID and str(candidate.origin_zone_id)=="ashwood_marches","Recruitment should use only the current Ashwood testing zone.")
	TestSupport.check(errors,int(candidate.hero_record.level)==1,"The Level 1 Tavern should generate only Level 1 candidates.")
	TestSupport.check(errors,candidate.hero_record.get("equipment_slots",{}).values().all(func(item_id):return item_id==null or str(item_id)=="") and str(candidate.hero_record.get("profession_progress",{}).get("profession_id",""))=="","Level 1 Tavern candidates should arrive without meaningful equipment or a learned profession.")
	TestSupport.check(errors,candidate.has("quality_score") and candidate.has("information_disclosure_score") and int(candidate.quality_score)!=int(candidate.information_disclosure_score),"Candidate quality and information disclosure should be stored as separate values.")

	var cheap_quality:Array=[];var rich_quality:Array=[];var cheap_disclosure:Array=[];var rich_disclosure:Array=[]
	for seed in 80:
		cheap_quality.append(int(RecruitmentSystem.generate_candidate(state,1,seed).quality_score));rich_quality.append(int(RecruitmentSystem.generate_candidate(state,5,seed).quality_score))
		cheap_disclosure.append(int(RecruitmentSystem.generate_candidate(state,1,seed).information_disclosure_score));rich_disclosure.append(int(RecruitmentSystem.generate_candidate(state,5,seed).information_disclosure_score))
	TestSupport.check(errors,average(rich_quality)>average(cheap_quality),"Higher Tavern Budgets should improve the candidate-quality distribution.")
	TestSupport.check(errors,average(rich_disclosure)>average(cheap_disclosure) and rich_disclosure.all(func(value):return int(value)<15),"Higher Tavern Budgets may improve hidden disclosure scores, but a Level 1 Tavern should reveal no detailed fields.")
	var low_prestige:=state.duplicate(true);low_prestige.guild_prestige_rank=1;var high_prestige:=state.duplicate(true);high_prestige.guild_prestige_rank=10;var low_quality:Array=[];var high_quality:Array=[];var low_info:Array=[];var high_info:Array=[]
	for seed in 80:
		var low:=RecruitmentSystem.generate_candidate(low_prestige,4,seed);var high:=RecruitmentSystem.generate_candidate(high_prestige,4,seed);low_quality.append(low.quality_score);high_quality.append(high.quality_score);low_info.append(low.information_disclosure_score);high_info.append(high.information_disclosure_score)
	TestSupport.check(errors,is_equal_approx(average(high_quality),average(low_quality)) and is_equal_approx(average(high_info),average(low_info)),"Level 1 Tavern candidate quality and disclosure should not bypass the testing limits through Guild Prestige.")

	var full_gold:=int(state.gold);RecruitmentSystem.advance(state,60.0)
	TestSupport.check(errors,int(state.gold)==full_gold and state.recruitment.candidates.size()==1,"A full Tavern, including an unlocked waiting candidate, should pause checks without spending Gold.")
	var remaining_before:=float(candidate.remaining_wait_minutes);RecruitmentSystem.toggle_candidate_lock(state);RecruitmentSystem.advance(state,300.0)
	TestSupport.check(errors,state.recruitment.candidates.size()==1 and is_equal_approx(float(candidate.remaining_wait_minutes),remaining_before),"Locking should stop candidate expiry while still occupying the Tavern.")
	RecruitmentSystem.toggle_candidate_lock(state);RecruitmentSystem.advance(state,1.0)
	TestSupport.check(errors,float(candidate.remaining_wait_minutes)<remaining_before,"Unlocking should resume the preserved departure timer.")
	RecruitmentSystem.reject_candidate(state)
	TestSupport.check(errors,RecruitmentSystem.current_candidate(state).is_empty(),"Rejecting should immediately remove the current candidate.")

	var hire_state:=SaveManager.fresh_state();hire_state.gold=500;for hero in hire_state.heroes:hero.level=4
	var hire_candidate:Dictionary=RecruitmentSystem.generate_candidate(hire_state,5,700);hire_state.recruitment.candidates=[hire_candidate];var snapshot:Dictionary=hire_candidate.hero_record.duplicate(true);var signing_cost:=int(hire_candidate.signing_cost);var roster_before:int=hire_state.heroes.size();var hire_result:=RecruitmentSystem.recruit_candidate(hire_state)
	TestSupport.check(errors,bool(hire_result.success) and hire_state.heroes.size()==roster_before+1 and int(hire_state.gold)==500-signing_cost,"Recruiting should use the real signing cost and append one real guild member.")
	TestSupport.check(errors,hire_state.heroes[-1]==snapshot and str(hire_state.heroes[-1].hero_id)==str(snapshot.hero_id),"Hiring should preserve the generated member ID and data without rerolling the candidate.")
	TestSupport.check(errors,RecruitmentSystem.current_candidate(hire_state).is_empty(),"A recruited candidate should leave the Tavern slot.")

	var clock_state:=SaveManager.fresh_state();clock_state.gold=100;RecruitmentSystem.set_budget(clock_state,2);GameClockSystem.set_paused(clock_state,true);var paused_minutes:=GameClockSystem.advance(clock_state,60.0);RecruitmentSystem.advance(clock_state,paused_minutes)
	TestSupport.check(errors,RecruitmentSystem.current_candidate(clock_state).is_empty() and paused_minutes==0.0,"Pausing the shared game clock should stop recruitment time.")
	GameClockSystem.set_paused(clock_state,false);GameClockSystem.set_speed(clock_state,2);var fast_minutes:=GameClockSystem.advance(clock_state,30.0);RecruitmentSystem.advance(clock_state,fast_minutes)
	TestSupport.check(errors,is_equal_approx(fast_minutes,60.0) and not RecruitmentSystem.current_candidate(clock_state).is_empty(),"Shared clock speed controls should accelerate recruitment checks deterministically.")

	var invalid:=SaveManager.fresh_state();invalid.recruitment={"hourly_budget":99,"tavern_name":"  ","minutes_until_next_check":-4,"candidates":[{"broken":true}],"activity_log":[4,"Hourly recruitment budget set to 5 Gold."],"next_candidate_id":0};RecruitmentSystem.ensure_state(invalid)
	TestSupport.check(errors,int(invalid.recruitment.hourly_budget)==5 and invalid.recruitment.tavern_name=="The Tavern" and invalid.recruitment.candidates.is_empty() and invalid.recruitment.activity_log.is_empty(),"Invalid and obsolete recruitment save fields should be repaired without breaking the guild state.")
	return errors
