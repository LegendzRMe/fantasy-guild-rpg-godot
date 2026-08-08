extends RefCounted

const TavernManagementData = preload("res://scripts/data/tavern_management_data.gd")
const CookingData = preload("res://scripts/data/cooking_data.gd")
const ProfessionData = preload("res://scripts/data/profession_data.gd")
const ProfessionSystem = preload("res://scripts/systems/profession_system.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const TavernFacilitySystem = preload("res://scripts/systems/tavern_facility_system.gd")
const RecruitmentSystem = preload("res://scripts/systems/recruitment_system.gd")

const SAVE_VERSION := TavernManagementData.SAVE_VERSION
const LOG_LIMIT := 30

static func ensure_state(state:Dictionary) -> void:
	if not state.get("component_versions") is Dictionary:state["component_versions"]={}
	state.component_versions["tavern_management"]=SAVE_VERSION
	var defaults:=TavernManagementData.default_state()
	if not state.get("tavern_management") is Dictionary:state["tavern_management"]=defaults.duplicate(true)
	for key in defaults:
		if not state.tavern_management.has(key):state.tavern_management[key]=defaults[key].duplicate(true) if defaults[key] is Array or defaults[key] is Dictionary else defaults[key]
	var tavern:Dictionary=state.tavern_management;tavern.tavern_level=clampi(int(tavern.get("tavern_level",1)),1,5)
	if not tavern.get("assignments") is Dictionary:tavern.assignments=defaults.assignments.duplicate(true)
	for key in defaults.assignments:
		if not tavern.assignments.has(key):tavern.assignments[key]=""
	var valid_ids:Dictionary={}
	for hero in state.get("heroes",[]):
		if hero is Dictionary:valid_ids[str(hero.get("hero_id",""))]=true
	var assigned:Dictionary={}
	for role in ["host","chef","steward"]:
		var key:="%s_id"%role;var hero_id:=str(tavern.assignments.get(key,""))
		if not valid_ids.has(hero_id) or assigned.has(hero_id) or role=="steward" and tavern.tavern_level<TavernManagementData.STEWARD_UNLOCK_LEVEL:tavern.assignments[key]=""
		elif hero_id!="":assigned[hero_id]=true
	if not tavern.get("rest_slots") is Array:tavern.rest_slots=[]
	var slot_count:=TavernManagementData.rest_slot_count(int(tavern.tavern_level));var rebuilt:Array=[];var rested_ids:Dictionary={}
	for slot_id in slot_count:
		var hero_id:=""
		for raw_slot in tavern.rest_slots:
			if raw_slot is Dictionary and int(raw_slot.get("slot_id",-1))==slot_id:hero_id=str(raw_slot.get("hero_id",""));break
		if not valid_ids.has(hero_id) or assigned.has(hero_id) or rested_ids.has(hero_id):hero_id=""
		elif hero_id!="":rested_ids[hero_id]=true
		rebuilt.append({"slot_id":slot_id,"hero_id":hero_id})
	tavern.rest_slots=rebuilt
	if state.get("tavern_facility") is Dictionary:
		for rest in state.tavern_facility.get("rest_assignments",[]).duplicate():
			if bool(rest.get("consume_on_completion",false)) and not rested_ids.has(str(rest.get("hero_id",""))):state.tavern_facility.paused_rest_progress[str(rest.hero_id)]=float(rest.remaining_minutes);state.tavern_facility.rest_assignments.erase(rest)
	for key in ["automation","manual_cooking","campaign","last_campaign_report"]:
		if not tavern.get(key) is Dictionary:tavern[key]=defaults[key].duplicate(true)
	if not tavern.get("activity_log") is Array:tavern.activity_log=[]
	tavern.activity_log=tavern.activity_log.filter(func(value):return value is String).slice(-LOG_LIMIT)

static func _log(state:Dictionary,message:String) -> void:
	ensure_state(state);state.tavern_management.activity_log.append(message)
	while state.tavern_management.activity_log.size()>LOG_LIMIT:state.tavern_management.activity_log.pop_front()

static func hero_index(state:Dictionary,hero_id:String) -> int:
	for index in state.get("heroes",[]).size():
		if str(state.heroes[index].get("hero_id",""))==hero_id:return index
	return -1

static func hero_name(state:Dictionary,hero_id:String) -> String:
	var index:=hero_index(state,hero_id);return str(state.heroes[index].get("display_name",state.heroes[index].get("name","Hero"))) if index>=0 else "Empty"

static func assigned_role(state:Dictionary,hero_id:String) -> String:
	ensure_state(state)
	for role in ["host","chef","steward"]:
		if str(state.tavern_management.assignments.get("%s_id"%role,""))==hero_id:return role
	return ""

static func rest_eligibility(state:Dictionary,hero_id:String) -> Dictionary:
	ensure_state(state);var index:=hero_index(state,hero_id)
	if index<0:return {"eligible":false,"reason":"Not a guild member."}
	if assigned_role(state,hero_id)!="":return {"eligible":false,"reason":"Assigned as Tavern %s."%assigned_role(state,hero_id).capitalize()}
	var hero:Dictionary=state.heroes[index]
	if str(hero.get("activity",""))!="":return {"eligible":false,"reason":"Currently assigned to %s."%str(hero.activity)}
	if str(hero.get("profession_progress",{}).get("current_profession_order_id",""))!="":return {"eligible":false,"reason":"Working on a profession order."}
	var recovery:=TavernFacilitySystem.recovery_case(state,hero_id)
	if not recovery.is_empty():return {"eligible":false,"reason":"Recovering from %s."%str(recovery.recovery_type)}
	if not TavernFacilitySystem.rest_assignment(state,hero_id).is_empty():return {"eligible":false,"reason":"Already resting."}
	return {"eligible":true,"reason":"Available"}

static func assignment_eligibility(state:Dictionary,hero_id:String,role:String) -> Dictionary:
	if role not in ["host","chef","steward"]:return {"eligible":false,"reason":"Unknown Tavern role."}
	ensure_state(state)
	if role=="steward" and int(state.tavern_management.tavern_level)<TavernManagementData.STEWARD_UNLOCK_LEVEL:return {"eligible":false,"reason":"Steward unlocks at Tavern Level 3."}
	var index:=hero_index(state,hero_id)
	if index<0:return {"eligible":false,"reason":"Not a guild member."}
	var existing:=assigned_role(state,hero_id)
	if existing!="" and existing!=role:return {"eligible":false,"reason":"Already assigned as %s."%existing.capitalize()}
	var status:=TavernFacilitySystem.member_status(state,hero_id)
	if not bool(status.available) and existing!=role:return {"eligible":false,"reason":str(status.label)}
	if str(state.heroes[index].get("activity",""))!="":return {"eligible":false,"reason":"Member is busy."}
	return {"eligible":true,"reason":"Available"}

static func assign_member(state:Dictionary,role:String,hero_id:String) -> Dictionary:
	ensure_state(state);var check:=assignment_eligibility(state,hero_id,role)
	if not bool(check.eligible):return {"success":false,"reason":str(check.reason)}
	var key:="%s_id"%role;var previous:=str(state.tavern_management.assignments.get(key,""));state.tavern_management.assignments[key]=hero_id
	_log(state,"%s was assigned as Tavern %s."%[hero_name(state,hero_id),role.capitalize()]);return {"success":true,"reason":"Assignment updated.","previous_id":previous}

static func remove_assignment(state:Dictionary,role:String) -> Dictionary:
	ensure_state(state);var key:="%s_id"%role
	if not state.tavern_management.assignments.has(key):return {"success":false,"reason":"Unknown Tavern role."}
	var previous:=str(state.tavern_management.assignments[key]);state.tavern_management.assignments[key]=""
	return {"success":true,"reason":"Assignment removed.","hero_id":previous}

static func set_level(state:Dictionary,level:int) -> void:
	ensure_state(state);state.tavern_management.tavern_level=clampi(level,TavernManagementData.MIN_LEVEL,TavernManagementData.MAX_TEST_LEVEL);ensure_state(state)

static func assign_rest_slot(state:Dictionary,slot_id:int,hero_id:String) -> Dictionary:
	ensure_state(state)
	if slot_id<0 or slot_id>=state.tavern_management.rest_slots.size():return {"success":false,"reason":"Unknown rest slot."}
	var check:=rest_eligibility(state,hero_id)
	if not bool(check.eligible):return {"success":false,"reason":str(check.reason)}
	var result:=TavernFacilitySystem.start_slot_rest(state,hero_id,slot_id,TavernManagementData.REST_DURATION_MINUTES)
	if bool(result.success):state.tavern_management.rest_slots[slot_id].hero_id=hero_id;_log(state,"%s entered Rest Slot %d."%[hero_name(state,hero_id),slot_id+1])
	return result

static func remove_rest_slot(state:Dictionary,slot_id:int) -> Dictionary:
	ensure_state(state)
	if slot_id<0 or slot_id>=state.tavern_management.rest_slots.size():return {"success":false,"reason":"Unknown rest slot."}
	var hero_id:=str(state.tavern_management.rest_slots[slot_id].hero_id)
	if hero_id=="":return {"success":false,"reason":"The rest slot is empty."}
	var result:=TavernFacilitySystem.remove_slot_rest(state,hero_id);state.tavern_management.rest_slots[slot_id].hero_id="";return result

static func set_rest_meal(state:Dictionary,meal_id:String) -> Dictionary:
	ensure_state(state)
	if meal_id!="" and not CookingData.MEALS.has(meal_id):return {"success":false,"reason":"Unknown prepared meal."}
	state.tavern_management.selected_rest_meal_id=meal_id;return {"success":true,"reason":"Rest Meal updated."}

static func _material_quantity(state:Dictionary,material_id:String) -> int:
	var amount:=0
	for stack in state.get("material_stacks",[]):
		if str(stack.get("material_id",""))==material_id and InventorySystem.storage_location(stack)=="depot":amount+=int(stack.get("quantity",0))
	return amount

static func ingredient_status(state:Dictionary,recipe_id:String) -> Dictionary:
	var recipe:=ProfessionData.recipe(recipe_id);var missing:Array=[]
	for material in recipe.get("materials",[]):
		var available:=_material_quantity(state,str(material.material_id));var needed:=int(material.quantity)
		if available<needed:missing.append("%s %d/%d"%[str(material.material_id).replace("_"," ").capitalize(),available,needed])
	return {"available":missing.is_empty(),"missing":missing,"text":"Ready" if missing.is_empty() else ", ".join(missing)}

static func _consume_recipe_inputs(state:Dictionary,recipe_id:String) -> Dictionary:
	var status:=ingredient_status(state,recipe_id)
	if not bool(status.available):return {"success":false,"reason":"Missing: %s"%str(status.text)}
	for material in ProfessionData.recipe(recipe_id).get("materials",[]):
		var consumed:=InventorySystem.consume_material(state,str(material.material_id),int(material.quantity))
		if not bool(consumed.success):return consumed
	return {"success":true,"reason":""}

static func start_manual_cooking(state:Dictionary,recipe_id:String) -> Dictionary:
	ensure_state(state);var attempt:Dictionary=state.tavern_management.manual_cooking
	if bool(attempt.get("active",false)):return {"success":false,"reason":"Finish the current cooking attempt first."}
	if recipe_id not in TavernManagementData.PROTOTYPE_RECIPES:return {"success":false,"reason":"Choose a prototype Tavern recipe."}
	var chef_id:=str(state.tavern_management.assignments.chef_id)
	if chef_id=="":return {"success":false,"reason":"Assign a Chef first."}
	var consumed:=_consume_recipe_inputs(state,recipe_id)
	if not bool(consumed.success):return consumed
	state.tavern_management.manual_cooking={"active":true,"recipe_id":recipe_id,"chef_id":chef_id,"marker":0.0,"direction":1.0,"ingredients_consumed":true}
	return {"success":true,"reason":"Stop the marker in the center."}

static func stop_manual_cooking(state:Dictionary) -> Dictionary:
	ensure_state(state);var attempt:Dictionary=state.tavern_management.manual_cooking
	if not bool(attempt.get("active",false)):return {"success":false,"reason":"No cooking attempt is active."}
	var distance:=absf(float(attempt.marker)-0.5);var result_id:="perfect" if distance<=TavernManagementData.PERFECT_HALF_WIDTH else "cooked" if distance<=TavernManagementData.COOKED_HALF_WIDTH else "burned";var recipe:=ProfessionData.recipe(str(attempt.recipe_id));var servings:=0
	if result_id!="burned":
		servings=TavernFacilitySystem.add_prepared_meals(state,str(recipe.meal_id),2 if result_id=="perfect" else 1,str(attempt.chef_id));ProfessionSystem.record_recipe_success(state,str(attempt.recipe_id));if result_id=="perfect":ProfessionSystem.record_recipe_success(state,str(attempt.recipe_id))
		var progress:=ProfessionSystem.progress(state,str(attempt.chef_id));if str(progress.get("profession_id",""))=="cooking":ProfessionSystem.grant_xp(state,str(attempt.chef_id),int(recipe.get("xp",0)))
	state.tavern_management.manual_cooking={"active":false,"recipe_id":"","chef_id":"","marker":0.0,"direction":1.0,"ingredients_consumed":false};_log(state,"Manual cooking result: %s."%result_id.capitalize())
	return {"success":true,"reason":result_id.capitalize(),"result":result_id,"servings":servings}

static func set_automation(state:Dictionary,recipe_id:String,target:int) -> Dictionary:
	ensure_state(state);target=clampi(target,0,TavernManagementData.MAX_STOCK_TARGET)
	if target>0 and recipe_id not in TavernManagementData.PROTOTYPE_RECIPES:return {"success":false,"reason":"Choose a prototype Tavern recipe."}
	if target>0 and not ProfessionSystem.is_pattern_mastered(state,recipe_id):return {"success":false,"reason":"Master this recipe first."}
	var automation:Dictionary=state.tavern_management.automation
	if bool(automation.get("ingredients_reserved",false)) and (target==0 or str(automation.get("recipe_id",""))!=recipe_id):
		for material in ProfessionData.recipe(str(automation.recipe_id)).get("materials",[]):InventorySystem.add_material(state,str(material.material_id),int(material.quantity))
	state.tavern_management.automation={"recipe_id":recipe_id if target>0 else "","stock_target":target,"remaining_game_minutes":0.0,"ingredients_reserved":false,"status":"Waiting" if target>0 else "Stopped"}
	return {"success":true,"reason":"Stock target updated."}

static func start_campaign(state:Dictionary,campaign_id:String) -> Dictionary:
	ensure_state(state)
	if bool(state.tavern_management.campaign.get("active",false)):return {"success":false,"reason":"A recruitment campaign is already active."}
	var definition:Dictionary=TavernManagementData.CAMPAIGNS.get(campaign_id,{})
	if definition.is_empty():return {"success":false,"reason":"Unknown campaign."}
	if int(state.get("gold",0))<int(definition.gross_cost):return {"success":false,"reason":"Requires %d Gold."%int(definition.gross_cost)}
	state.gold=int(state.gold)-int(definition.gross_cost);RecruitmentSystem.set_budget(state,int(definition.budget));var campaign_check_minutes:=maxf(15.0,60.0-float(definition.budget)*6.0);state.recruitment.minutes_until_next_check=minf(float(state.recruitment.minutes_until_next_check),campaign_check_minutes)
	state.tavern_management.campaign={"active":true,"campaign_id":campaign_id,"gross_cost":int(definition.gross_cost),"remaining_minutes":TavernManagementData.CAMPAIGN_DURATION_MINUTES,"food_sales":0.0,"staying_fees":0.0,"income_claimed":false}
	return {"success":true,"reason":"%s started."%str(definition.display_name)}

static func end_campaign(state:Dictionary) -> Dictionary:
	ensure_state(state);var campaign:Dictionary=state.tavern_management.campaign
	if not bool(campaign.get("active",false)):return {"success":false,"reason":"No recruitment campaign is active."}
	var recovered:=int(floor(float(campaign.get("food_sales",0.0))+float(campaign.get("staying_fees",0.0))))
	if not bool(campaign.get("income_claimed",false)):state.gold=int(state.gold)+recovered;campaign.income_claimed=true
	var report:={"campaign_id":str(campaign.campaign_id),"gross_cost":int(campaign.gross_cost),"food_sales":int(floor(float(campaign.food_sales))),"staying_fees":int(floor(float(campaign.staying_fees))),"final_cost":maxi(0,int(campaign.gross_cost)-recovered),"income_granted":recovered}
	state.tavern_management.last_campaign_report=report;state.tavern_management.lifetime_food_sales=float(state.tavern_management.lifetime_food_sales)+float(campaign.food_sales);state.tavern_management.lifetime_staying_fees=float(state.tavern_management.lifetime_staying_fees)+float(campaign.staying_fees);state.tavern_management.campaign={"active":false};RecruitmentSystem.set_budget(state,0)
	return {"success":true,"reason":"Campaign ended.","report":report}

static func _advance_automation(state:Dictionary,game_minutes:float) -> Array:
	var events:Array=[];var tavern:Dictionary=state.tavern_management;var automation:Dictionary=tavern.automation
	if int(tavern.tavern_level)<2 or str(tavern.assignments.chef_id)=="" or int(automation.get("stock_target",0))<=0:automation.status="Paused";return events
	var recipe_id:=str(automation.recipe_id);var recipe:=ProfessionData.recipe(recipe_id);var current:=TavernFacilitySystem.meal_count(state,str(recipe.get("meal_id","")))
	if current>=int(automation.stock_target):automation.status="At target";return events
	if not bool(automation.get("ingredients_reserved",false)):
		var consumed:=_consume_recipe_inputs(state,recipe_id)
		if not bool(consumed.success):automation.status="Missing ingredients: %s"%str(ingredient_status(state,recipe_id).text);return events
		automation.ingredients_reserved=true;automation.remaining_game_minutes=maxf(0.1,float(recipe.get("duration",10.0))*TavernManagementData.AUTOMATION_RECIPE_SECONDS_TO_GAME_MINUTES)
	automation.status="Cooking";automation.remaining_game_minutes=maxf(0.0,float(automation.remaining_game_minutes)-game_minutes)
	if float(automation.remaining_game_minutes)<=0.0:
		TavernFacilitySystem.add_prepared_meals(state,str(recipe.meal_id),int(recipe.get("servings",1)),str(tavern.assignments.chef_id));automation.ingredients_reserved=false;ProfessionSystem.record_recipe_success(state,recipe_id);events.append({"type":"tavern_automation_complete","recipe_id":recipe_id})
	return events

static func _auto_fill_rest(state:Dictionary) -> void:
	if int(state.tavern_management.tavern_level)<2:return
	for slot in state.tavern_management.rest_slots:
		if str(slot.hero_id)!="":continue
		for hero in state.get("heroes",[]):
			var hero_id:=str(hero.get("hero_id",""));var check:=rest_eligibility(state,hero_id)
			if bool(check.eligible):assign_rest_slot(state,int(slot.slot_id),hero_id);break

static func _sync_rest_slots(state:Dictionary) -> void:
	for slot in state.tavern_management.rest_slots:
		var hero_id:=str(slot.hero_id)
		if hero_id!="" and TavernFacilitySystem.rest_assignment(state,hero_id).is_empty():slot.hero_id=""

static func _advance_campaign(state:Dictionary,game_minutes:float) -> Array:
	var events:Array=[];var campaign:Dictionary=state.tavern_management.campaign
	if not bool(campaign.get("active",false)):return events
	campaign.remaining_minutes=maxf(0.0,float(campaign.remaining_minutes)-game_minutes)
	if int(state.tavern_management.tavern_level)>=2:
		var hours:=game_minutes/60.0;var platter_multiplier:=1.10 if TavernFacilitySystem.meal_count(state,"recruiters_platter")>0 else 1.0;var sales_cap:=float(campaign.gross_cost)*TavernManagementData.FOOD_SALES_GROSS_CAP_FRACTION;campaign.food_sales=minf(sales_cap,float(campaign.food_sales)+float(campaign.gross_cost)*TavernManagementData.FOOD_SALES_HOURLY_FRACTION*hours*platter_multiplier)
		var candidate:=RecruitmentSystem.current_candidate(state)
		if not candidate.is_empty() and bool(candidate.get("locked",false)):
			var level:=int(candidate.hero_record.get("level",1));var hourly:=(TavernManagementData.STAY_FEE_BASE_PER_HOUR+level*TavernManagementData.STAY_FEE_PER_CANDIDATE_LEVEL+int(state.tavern_management.tavern_level)*TavernManagementData.STAY_FEE_PER_TAVERN_LEVEL)*TavernManagementData.HOST_BONUS_MULTIPLIER;var earned:=hourly*hours;campaign.staying_fees=float(campaign.staying_fees)+earned;candidate["current_stay_income"]=float(candidate.get("current_stay_income",0.0))+earned
	if float(campaign.remaining_minutes)<=0.0:var ended:=end_campaign(state);events.append({"type":"tavern_campaign_complete","report":ended.get("report",{})})
	return events

static func advance(state:Dictionary,game_minutes:float,allow_auto_rest:bool=true) -> Array:
	ensure_state(state);var events:Array=[];var attempt:Dictionary=state.tavern_management.manual_cooking
	if bool(attempt.get("active",false)):
		var next:=float(attempt.marker)+float(attempt.direction)*game_minutes*TavernManagementData.MANUAL_MARKER_SPEED
		while next>1.0 or next<0.0:
			if next>1.0:next=2.0-next;attempt.direction=-1.0
			elif next<0.0:next=-next;attempt.direction=1.0
		attempt.marker=clampf(next,0.0,1.0)
	events.append_array(_advance_automation(state,game_minutes));events.append_array(_advance_campaign(state,game_minutes));_sync_rest_slots(state)
	if allow_auto_rest:_auto_fill_rest(state)
	return events
