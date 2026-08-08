extends RefCounted

const TavernFacilityData = preload("res://scripts/data/tavern_facility_data.gd")
const CookingData = preload("res://scripts/data/cooking_data.gd")

const SAVE_VERSION := 2

static func hero_index(state:Dictionary,hero_id:String) -> int:
	for index in state.get("heroes",[]).size():
		if str(state.heroes[index].get("hero_id",""))==hero_id:return index
	return -1

static func hero_name(state:Dictionary,hero_id:String) -> String:
	var index:=hero_index(state,hero_id)
	return str(state.heroes[index].get("display_name",state.heroes[index].get("name","Hero"))) if index>=0 else "Hero"

static func ensure_state(state:Dictionary) -> void:
	if not state.get("component_versions") is Dictionary:state["component_versions"]={}
	state.component_versions["tavern_facility"]=SAVE_VERSION
	var defaults:=TavernFacilityData.default_state()
	if not state.get("tavern_facility") is Dictionary:state["tavern_facility"]=defaults.duplicate(true)
	for key in defaults:
		if not state.tavern_facility.has(key):state.tavern_facility[key]=defaults[key].duplicate(true) if defaults[key] is Array or defaults[key] is Dictionary else defaults[key]
	for key in ["recovery_cases","rest_assignments","prepared_meals","activity_log"]:
		if not state.tavern_facility.get(key) is Array:state.tavern_facility[key]=[]
	if not state.tavern_facility.get("paused_rest_progress") is Dictionary:state.tavern_facility.paused_rest_progress={}
	state.tavern_facility.next_meal_id=maxi(1,int(state.tavern_facility.get("next_meal_id",1)))
	var valid_ids:Dictionary={}
	for hero in state.get("heroes",[]):
		if not hero is Dictionary:continue
		var hero_id:=str(hero.get("hero_id",""));if hero_id!="":valid_ids[hero_id]=true
		if not hero.get("temporary_buffs") is Array:hero["temporary_buffs"]=[]
		if not hero.get("cooking_meal_state") is Dictionary:hero["cooking_meal_state"]={"full_rest_completed":false,"last_main_meal_id":"","last_side_meal_id":"","chefs_touch_id":""}
		hero.temporary_buffs=hero.temporary_buffs.filter(func(buff):return buff is Dictionary and str(buff.get("buff_id",""))!="")
		for buff in hero.temporary_buffs:
			if str(buff.get("buff_id",""))=="well_rested":buff.buff_id="tavern_meal";buff["meal_id"]="common_table_meal";if not buff.has("temporary_hp_percent"):buff.temporary_hp_percent=TavernFacilityData.WELL_RESTED_TEMPORARY_HP_PERCENT
	var seen_recovery:Dictionary={};var recovery:Array=[]
	for raw_case in state.tavern_facility.recovery_cases:
		if not raw_case is Dictionary:continue
		var hero_id:=str(raw_case.get("hero_id",""))
		if not valid_ids.has(hero_id) or seen_recovery.has(hero_id):continue
		var recovery_type:=str(raw_case.get("recovery_type","defeated"))
		if recovery_type not in ["defeated","minor","serious"]:recovery_type="defeated"
		var remaining:=maxf(0.0,float(raw_case.get("remaining_minutes",0.0)))
		if remaining<=0.0:continue
		recovery.append({"hero_id":hero_id,"recovery_type":recovery_type,"remaining_minutes":remaining,"total_minutes":maxf(remaining,float(raw_case.get("total_minutes",remaining))),"recovery_rate_multiplier":maxf(1.0,float(raw_case.get("recovery_rate_multiplier",1.0))),"started_at_game_minute":maxf(0.0,float(raw_case.get("started_at_game_minute",0.0))),"care_route":str(raw_case.get("care_route","")),"pending_meal":raw_case.get("pending_meal",{}).duplicate(true)})
		seen_recovery[hero_id]=true
	state.tavern_facility.recovery_cases=recovery
	var seen_rest:Dictionary={};var rests:Array=[]
	for raw_rest in state.tavern_facility.rest_assignments:
		if not raw_rest is Dictionary:continue
		var hero_id:=str(raw_rest.get("hero_id",""))
		if not valid_ids.has(hero_id) or seen_recovery.has(hero_id) or seen_rest.has(hero_id):continue
		var remaining:=maxf(0.0,float(raw_rest.get("remaining_minutes",0.0)))
		if remaining<=0.0:continue
		rests.append({"hero_id":hero_id,"remaining_minutes":remaining,"buff_duration_minutes":maxf(1.0,float(raw_rest.get("buff_duration_minutes",TavernFacilityData.WELL_RESTED_DURATION_MINUTES))),"meal_id":str(raw_rest.get("meal_id","common_table_meal")),"meal_effect":raw_rest.get("meal_effect",{}).duplicate(true),"maker_id":str(raw_rest.get("maker_id","")),"is_second_course":bool(raw_rest.get("is_second_course",false)),"slot_id":int(raw_rest.get("slot_id",-1)),"consume_on_completion":bool(raw_rest.get("consume_on_completion",false))})
		seen_rest[hero_id]=true
	state.tavern_facility.rest_assignments=rests
	state.tavern_facility.prepared_meals=state.tavern_facility.prepared_meals.filter(func(meal):return meal is Dictionary and CookingData.MEALS.has(str(meal.get("meal_id","")))).slice(-TavernFacilityData.PREPARED_MEAL_LIMIT)
	state.tavern_facility.activity_log=state.tavern_facility.activity_log.filter(func(entry):return entry is String).slice(-TavernFacilityData.RECOVERY_LOG_LIMIT)

static func add_log(state:Dictionary,message:String) -> void:
	ensure_state(state);state.tavern_facility.activity_log.append(message)
	while state.tavern_facility.activity_log.size()>TavernFacilityData.RECOVERY_LOG_LIMIT:state.tavern_facility.activity_log.pop_front()

static func recovery_case(state:Dictionary,hero_id:String) -> Dictionary:
	ensure_state(state)
	for entry in state.tavern_facility.recovery_cases:
		if str(entry.hero_id)==hero_id:return entry
	return {}

static func rest_assignment(state:Dictionary,hero_id:String) -> Dictionary:
	ensure_state(state)
	for entry in state.tavern_facility.rest_assignments:
		if str(entry.hero_id)==hero_id:return entry
	return {}

static func active_temporary_buff(state:Dictionary,hero_id:String,buff_id:String="tavern_meal") -> Dictionary:
	ensure_state(state);var index:=hero_index(state,hero_id)
	if index<0:return {}
	var now:=float(state.get("game_clock",{}).get("total_minutes",0.0))
	for buff in state.heroes[index].temporary_buffs:
		if str(buff.get("buff_id",""))==buff_id and float(buff.get("expires_at_game_minute",0.0))>now:return buff
	return {}

static func clear_temporary_buffs(state:Dictionary,hero_id:String) -> void:
	ensure_state(state);var index:=hero_index(state,hero_id)
	if index>=0:state.heroes[index].temporary_buffs=[]

static func member_status(state:Dictionary,hero_id:String) -> Dictionary:
	var recovery:=recovery_case(state,hero_id)
	if not recovery.is_empty():return {"available":false,"status":"recovering","label":"%s recovery • %s"%[str(recovery.recovery_type).capitalize(),time_text(float(recovery.remaining_minutes))]}
	var rest:=rest_assignment(state,hero_id)
	if not rest.is_empty():return {"available":false,"status":"resting","label":"Resting • %s"%time_text(float(rest.remaining_minutes))}
	var assignments:Dictionary=state.get("tavern_management",{}).get("assignments",{})
	for role in ["host","chef","steward"]:
		if str(assignments.get("%s_id"%role,""))==hero_id:return {"available":false,"status":"tavern_assignment","label":"Tavern %s"%role.capitalize()}
	var buff:=active_temporary_buff(state,hero_id)
	if not buff.is_empty():
		var remaining:=maxf(0.0,float(buff.expires_at_game_minute)-float(state.game_clock.total_minutes))
		return {"available":true,"status":"well_rested","label":"Well Fed • %s • %s"%[str(CookingData.meal(str(buff.get("meal_id",""))).get("display_name","Meal benefit")),time_text(remaining)]}
	return {"available":true,"status":"available","label":"Available"}

static func member_is_available(state:Dictionary,hero_id:String) -> bool:
	return bool(member_status(state,hero_id).available)

static func time_text(minutes:float) -> String:
	var total:=maxi(0,int(ceil(minutes)))
	return "%dm"%total if total<60 else "%dh %02dm"%[total/60,total%60]

static func _meal_maker_has(meal:Dictionary,state:Dictionary,choice_id:String) -> bool:
	var maker_id:=str(meal.get("maker_id",""));var index:=hero_index(state,maker_id)
	return index>=0 and choice_id in state.heroes[index].get("profession_progress",{}).get("known_personal_techniques",[])

static func start_recovery(state:Dictionary,hero_id:String,recovery_type:String="defeated") -> Dictionary:
	ensure_state(state);if hero_index(state,hero_id)<0:return {"success":false,"reason":"Unknown guild member."}
	var durations:={"defeated":TavernFacilityData.DEFEATED_RECOVERY_MINUTES,"minor":TavernFacilityData.MINOR_INJURY_MINUTES,"serious":TavernFacilityData.SERIOUS_INJURY_MINUTES}
	if not durations.has(recovery_type):return {"success":false,"reason":"Unknown recovery type."}
	clear_temporary_buffs(state,hero_id)
	state.tavern_facility.rest_assignments=state.tavern_facility.rest_assignments.filter(func(entry):return str(entry.hero_id)!=hero_id)
	var existing:=recovery_case(state,hero_id);var duration:=float(durations[recovery_type])
	if existing.is_empty():
		state.tavern_facility.recovery_cases.append({"hero_id":hero_id,"recovery_type":recovery_type,"remaining_minutes":duration,"total_minutes":duration,"recovery_rate_multiplier":1.0,"started_at_game_minute":float(state.game_clock.total_minutes)})
	else:
		if duration>=float(existing.remaining_minutes):existing.recovery_type=recovery_type
		existing.remaining_minutes=maxf(float(existing.remaining_minutes),duration);existing.total_minutes=maxf(float(existing.total_minutes),duration);existing.recovery_rate_multiplier=1.0
	add_log(state,"%s entered %s recovery."%[hero_name(state,hero_id),recovery_type]);return {"success":true,"reason":"Recovery started."}

static func record_battle_defeats(state:Dictionary,runtime_heroes:Array) -> Array:
	ensure_state(state);var affected:Array=[]
	for runtime_hero in runtime_heroes:
		if not runtime_hero is Dictionary or not bool(runtime_hero.get("was_defeated",false)) and float(runtime_hero.get("hp",1.0))>0.0:continue
		var hero_index_value:=int(runtime_hero.get("hero_index",-1))
		if hero_index_value<0 or hero_index_value>=state.heroes.size():continue
		var hero_id:=str(state.heroes[hero_index_value].get("hero_id",""));var result:=start_recovery(state,hero_id,"defeated")
		if bool(result.success):affected.append(hero_id)
	return affected

static func add_prepared_meals(state:Dictionary,meal_id:String,quantity:int,maker_id:String="",duration_bonus_minutes:float=0.0) -> int:
	ensure_state(state);if not CookingData.MEALS.has(meal_id):return 0
	var added:=0
	for _index in maxi(0,quantity):
		if state.tavern_facility.prepared_meals.size()>=TavernFacilityData.PREPARED_MEAL_LIMIT:break
		var number:=int(state.tavern_facility.next_meal_id);state.tavern_facility.next_meal_id=number+1
		var definition:Dictionary=CookingData.meal(meal_id);var effect:Dictionary=definition.get("effect",{}).duplicate(true)
		state.tavern_facility.prepared_meals.append({"prepared_meal_id":"meal_%d"%number,"meal_id":meal_id,"maker_id":maker_id,"category":str(definition.get("category","")),"recipe_tier":int(definition.get("tier",1)),"effect":effect,"duration_minutes":CookingData.DEFAULT_MEAL_DURATION_MINUTES+maxf(0.0,duration_bonus_minutes),"recovery_rate_multiplier":float(effect.get("recovery_rate_multiplier",TavernFacilityData.RECOVERY_MEAL_RATE_MULTIPLIER))})
		added+=1
	return added

static func meal_count(state:Dictionary,meal_id:String) -> int:
	ensure_state(state);var count:=0
	for meal in state.tavern_facility.prepared_meals:
		if str(meal.meal_id)==meal_id:count+=1
	return count

static func take_meal(state:Dictionary,meal_id:String) -> Dictionary:
	ensure_state(state)
	for index in state.tavern_facility.prepared_meals.size():
		if str(state.tavern_facility.prepared_meals[index].meal_id)==meal_id:return state.tavern_facility.prepared_meals.pop_at(index)
	var now:=float(state.get("game_clock",{}).get("total_minutes",0.0))
	for service_key in ["active_house_banquet","active_guild_feast"]:
		var service:Dictionary=state.get("cooking",{}).get(service_key,{})
		if service.is_empty() or meal_id not in service.get("selections",[]) or int(service.get("servings",0))<=0 or float(service.get("expires_at_game_minute",0.0))<=now:continue
		service.servings=int(service.servings)-1;var definition:=CookingData.meal(meal_id)
		return {"prepared_meal_id":"%s_service_%d"%[service_key,int(service.servings)],"meal_id":meal_id,"maker_id":str(service.get("cook_id","")),"category":str(definition.get("category","")),"recipe_tier":int(definition.get("tier",1)),"effect":definition.get("effect",{}).duplicate(true),"duration_minutes":CookingData.DEFAULT_MEAL_DURATION_MINUTES,"recovery_rate_multiplier":float(definition.get("effect",{}).get("recovery_rate_multiplier",1.0))}
	return {}

static func request_recovery_wing_meal(state:Dictionary,meal_id:String="recovery_broth_hook") -> Dictionary:
	if str(CookingData.meal(meal_id).get("purpose","")) not in ["recovery","quick_recovery","recovery_hook"]:return {"success":false,"reason":"That meal is not routed to recovery."}
	var meal:=take_meal(state,meal_id)
	return {"success":not meal.is_empty(),"reason":"Meal supplied." if not meal.is_empty() else "No recovery meal is stocked.","meal":meal}

static func start_rest(state:Dictionary,hero_id:String,meal_id:String="common_table_meal") -> Dictionary:
	ensure_state(state);if hero_index(state,hero_id)<0:return {"success":false,"reason":"Unknown guild member."}
	if not recovery_case(state,hero_id).is_empty():return {"success":false,"reason":"This member is recovering from defeat or injury."}
	if not rest_assignment(state,hero_id).is_empty():return {"success":false,"reason":"This member is already resting."}
	var hero:Dictionary=state.heroes[hero_index(state,hero_id)]
	if str(hero.get("profession_progress",{}).get("current_profession_order_id",""))!="":return {"success":false,"reason":"This member is working on a profession order."}
	var definition:=CookingData.meal(meal_id)
	if str(definition.get("purpose","")) not in ["rest","mission"]:return {"success":false,"reason":"Choose a rest or mission meal."}
	var meal:=take_meal(state,meal_id)
	if meal.is_empty():return {"success":false,"reason":"Prepare %s first."%str(definition.get("display_name",meal_id))}
	var required_choice:="" if meal_id=="common_table_meal" else "cooking_mission_meals"
	if required_choice!="" and not _meal_maker_has(meal,state,required_choice):state.tavern_facility.prepared_meals.append(meal);return {"success":false,"reason":"The cook who prepared this meal requires %s."%required_choice.trim_prefix("cooking_").replace("_"," ").capitalize()}
	state.tavern_facility.rest_assignments.append({"hero_id":hero_id,"remaining_minutes":TavernFacilityData.VOLUNTARY_REST_MINUTES,"buff_duration_minutes":float(meal.duration_minutes),"meal_id":meal_id,"meal_effect":meal.get("effect",{}).duplicate(true),"maker_id":str(meal.get("maker_id","")),"is_second_course":false})
	add_log(state,"%s sat down for a meal and some rest."%hero_name(state,hero_id));return {"success":true,"reason":"Rest started."}

static func start_slot_rest(state:Dictionary,hero_id:String,slot_id:int,duration_minutes:float) -> Dictionary:
	ensure_state(state);if hero_index(state,hero_id)<0:return {"success":false,"reason":"Unknown guild member."}
	var status:=member_status(state,hero_id)
	if not bool(status.available):return {"success":false,"reason":str(status.label)}
	var remaining:=float(state.tavern_facility.paused_rest_progress.get(hero_id,duration_minutes));state.tavern_facility.paused_rest_progress.erase(hero_id)
	state.tavern_facility.rest_assignments.append({"hero_id":hero_id,"remaining_minutes":maxf(0.1,remaining),"buff_duration_minutes":TavernFacilityData.WELL_RESTED_DURATION_MINUTES,"meal_id":"","meal_effect":{},"maker_id":"","is_second_course":false,"slot_id":slot_id,"consume_on_completion":true})
	return {"success":true,"reason":"Rest started."}

static func remove_slot_rest(state:Dictionary,hero_id:String) -> Dictionary:
	var rest:=rest_assignment(state,hero_id)
	if rest.is_empty():return {"success":false,"reason":"This member is not resting."}
	state.tavern_facility.paused_rest_progress[hero_id]=float(rest.remaining_minutes);state.tavern_facility.rest_assignments.erase(rest)
	return {"success":true,"reason":"Rest paused without penalty."}

static func serve_recovery_meal(state:Dictionary,hero_id:String) -> Dictionary:
	var recovery:=recovery_case(state,hero_id)
	if recovery.is_empty():return {"success":false,"reason":"This member is not recovering."}
	if float(recovery.recovery_rate_multiplier)>1.0:return {"success":false,"reason":"A recovery meal is already active."}
	var meal:=take_meal(state,"restorative_broth")
	if meal.is_empty():return {"success":false,"reason":"Prepare Restorative Broth first."}
	if str(meal.get("maker_id",""))!="" and not _meal_maker_has(meal,state,"cooking_care_route"):state.tavern_facility.prepared_meals.append(meal);return {"success":false,"reason":"The serving cook requires Care Route."}
	recovery=recovery_case(state,hero_id)
	recovery.recovery_rate_multiplier=maxf(1.0,float(meal.recovery_rate_multiplier));add_log(state,"%s received Restorative Broth."%hero_name(state,hero_id));return {"success":true,"reason":"Recovery meal served."}

static func _grant_meal_buff(state:Dictionary,hero_id:String,meal_id:String,duration:float,effect:Dictionary,maker_id:String="",is_second_course:bool=false) -> void:
	var index:=hero_index(state,hero_id);if index<0:return
	var resolved:=effect.duplicate(true)
	if resolved.is_empty():resolved={"temporary_hp_percent":TavernFacilityData.WELL_RESTED_TEMPORARY_HP_PERCENT}
	if is_second_course:
		for key in resolved:resolved[key]=float(resolved[key])*CookingData.SECOND_COURSE_EFFECT_SCALE
	var existing:=active_temporary_buff(state,hero_id,"tavern_meal")
	if not existing.is_empty() and is_second_course:
		for key in resolved:existing[key]=float(existing.get(key,0.0))+float(resolved[key])
		existing["side_meal_id"]=meal_id;return
	state.heroes[index].temporary_buffs=state.heroes[index].temporary_buffs.filter(func(buff):return str(buff.get("buff_id","")) not in ["well_rested","tavern_meal"])
	var buff:={"buff_id":"tavern_meal","display_name":"Well Fed","meal_id":meal_id,"maker_id":maker_id,"expires_at_game_minute":float(state.game_clock.total_minutes)+duration,"remaining_missions":1}
	for key in resolved:buff[key]=resolved[key]
	state.heroes[index].temporary_buffs.append(buff)
	state.heroes[index].cooking_meal_state.full_rest_completed=true;state.heroes[index].cooking_meal_state.last_main_meal_id=meal_id

static func serve_complete_rest_meal(state:Dictionary,hero_id:String,meal_id:String) -> Dictionary:
	var recovery:=recovery_case(state,hero_id)
	if recovery.is_empty():return {"success":false,"reason":"This member is not recovering."}
	if str(CookingData.meal(meal_id).get("purpose",""))!="mission":return {"success":false,"reason":"Complete Rest requires a mission meal."}
	var meal:=take_meal(state,meal_id);if meal.is_empty():return {"success":false,"reason":"Prepare that mission meal first."}
	if str(meal.get("maker_id",""))!="" and not _meal_maker_has(meal,state,"cooking_care_route"):state.tavern_facility.prepared_meals.append(meal);return {"success":false,"reason":"The serving cook requires Care Route."}
	recovery=recovery_case(state,hero_id)
	recovery.care_route="complete";recovery.recovery_rate_multiplier=1.0;recovery.pending_meal=meal
	return {"success":true,"reason":"Complete Rest selected; the meal benefit is granted after recovery."}

static func start_second_course(state:Dictionary,hero_id:String,meal_id:String) -> Dictionary:
	ensure_state(state);var index:=hero_index(state,hero_id)
	if index<0:return {"success":false,"reason":"Unknown guild member."}
	var active:=active_temporary_buff(state,hero_id,"tavern_meal")
	if active.is_empty() or not bool(state.heroes[index].cooking_meal_state.get("full_rest_completed",false)):return {"success":false,"reason":"Complete a full rest first."}
	if str(active.get("meal_id",""))==meal_id:return {"success":false,"reason":"Second Course must be a different meal."}
	var meal:=take_meal(state,meal_id);if meal.is_empty():return {"success":false,"reason":"Prepare that meal first."}
	if not _meal_maker_has(meal,state,"cooking_second_course"):state.tavern_facility.prepared_meals.append(meal);return {"success":false,"reason":"The cook requires Second Course."}
	state.tavern_facility.rest_assignments.append({"hero_id":hero_id,"remaining_minutes":CookingData.REST_DURATION_MINUTES,"buff_duration_minutes":float(meal.duration_minutes),"meal_id":meal_id,"meal_effect":meal.effect.duplicate(true),"maker_id":str(meal.maker_id),"is_second_course":true})
	return {"success":true,"reason":"Second Course started."}

static func consume_mission_buff(state:Dictionary,hero_id:String,buff_id:String="tavern_meal") -> Dictionary:
	var buff:=active_temporary_buff(state,hero_id,buff_id)
	if buff.is_empty():return {}
	var index:=hero_index(state,hero_id);state.heroes[index].temporary_buffs.erase(buff);return buff

static func advance(state:Dictionary,game_minutes:float) -> Array:
	ensure_state(state);var events:Array=[];var elapsed:=maxf(0.0,game_minutes);var completed_recovery:Array=[];var completed_rest:Array=[]
	for recovery in state.tavern_facility.recovery_cases:
		recovery.remaining_minutes=maxf(0.0,float(recovery.remaining_minutes)-elapsed*maxf(1.0,float(recovery.recovery_rate_multiplier)))
		if float(recovery.remaining_minutes)<=0.0:completed_recovery.append(recovery)
	for recovery in completed_recovery:
		state.tavern_facility.recovery_cases.erase(recovery)
		if not recovery.get("pending_meal",{}).is_empty():var meal:Dictionary=recovery.pending_meal;_grant_meal_buff(state,str(recovery.hero_id),str(meal.meal_id),float(meal.duration_minutes),meal.get("effect",{}),str(meal.get("maker_id","")))
		var message:="%s finished recovery."%hero_name(state,str(recovery.hero_id));add_log(state,message);events.append({"type":"recovery_complete","hero_id":recovery.hero_id,"message":message})
	for rest in state.tavern_facility.rest_assignments:
		rest.remaining_minutes=maxf(0.0,float(rest.remaining_minutes)-elapsed)
		if float(rest.remaining_minutes)<=0.0:completed_rest.append(rest)
	for rest in completed_rest:
		state.tavern_facility.rest_assignments.erase(rest);var meal_id:=str(rest.meal_id);var effect:Dictionary=rest.get("meal_effect",{});var maker_id:=str(rest.get("maker_id",""));var meal_consumed:=not bool(rest.get("consume_on_completion",false))
		if bool(rest.get("consume_on_completion",false)):
			meal_id=str(state.get("tavern_management",{}).get("selected_rest_meal_id",""));var meal:=take_meal(state,meal_id) if meal_id!="" else {};meal_consumed=not meal.is_empty()
			if meal_consumed:effect=meal.get("effect",{});maker_id=str(meal.get("maker_id",""));rest.buff_duration_minutes=float(meal.get("duration_minutes",rest.buff_duration_minutes))
		if meal_consumed:_grant_meal_buff(state,str(rest.hero_id),meal_id,float(rest.buff_duration_minutes),effect,maker_id,bool(rest.get("is_second_course",false)))
		var message:="%s finished Tavern rest%s."%[hero_name(state,str(rest.hero_id))," and received %s"%str(CookingData.meal(meal_id).get("display_name","a meal buff")) if meal_consumed else " without a meal"];add_log(state,message);events.append({"type":"rest_complete","hero_id":rest.hero_id,"slot_id":int(rest.get("slot_id",-1)),"meal_consumed":meal_consumed,"message":message})
	var now:=float(state.game_clock.total_minutes)
	for hero in state.get("heroes",[]):
		if hero is Dictionary:hero.temporary_buffs=hero.get("temporary_buffs",[]).filter(func(buff):return float(buff.get("expires_at_game_minute",0.0))>now)
	return events
