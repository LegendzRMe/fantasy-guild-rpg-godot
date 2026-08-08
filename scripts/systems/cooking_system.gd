extends RefCounted

const CookingData = preload("res://scripts/data/cooking_data.gd")
const RecruitmentData = preload("res://scripts/data/recruitment_data.gd")
const ProfessionData = preload("res://scripts/data/profession_data.gd")
const ProfessionSystem = preload("res://scripts/systems/profession_system.gd")
const TavernFacilitySystem = preload("res://scripts/systems/tavern_facility_system.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")

const SAVE_VERSION := CookingData.SAVE_VERSION
const LOG_LIMIT := 40

static func ensure_state(state:Dictionary) -> void:
	if not state.get("component_versions") is Dictionary:state["component_versions"]={}
	state.component_versions["cooking"]=SAVE_VERSION
	var defaults:=CookingData.default_state()
	if not state.get("cooking") is Dictionary:state["cooking"]=defaults.duplicate(true)
	for key in defaults:
		if not state.cooking.has(key):state.cooking[key]=defaults[key].duplicate(true) if defaults[key] is Array or defaults[key] is Dictionary else defaults[key]
	if not state.cooking.get("activity_log") is Array:state.cooking.activity_log=[]
	state.cooking.activity_log=state.cooking.activity_log.filter(func(value):return value is String).slice(-LOG_LIMIT)
	for candidate in state.get("recruitment",{}).get("candidates",[]):
		if not candidate is Dictionary:continue
		var candidate_defaults:={"cooking_refresh_count":0,"hospitality_meals":[],"hospitality_cook_id":"","table_talk_used":false,"targeted_reveals":{},"development_history":[],"familiar_offer_available":false,"familiar_offer_used":false,"familiar_offer_cost":int(candidate.get("signing_cost",0)),"last_cooking_refresh":-1}
		for key in candidate_defaults:
			if not candidate.has(key):candidate[key]=candidate_defaults[key].duplicate(true) if candidate_defaults[key] is Array or candidate_defaults[key] is Dictionary else candidate_defaults[key]
	for hero in state.get("heroes",[]):
		if not hero is Dictionary:continue
		if not hero.get("cooking_meal_state") is Dictionary:hero["cooking_meal_state"]={"full_rest_completed":false,"last_main_meal_id":"","last_side_meal_id":"","chefs_touch_id":""}

static func _log(state:Dictionary,message:String) -> void:
	ensure_state(state);state.cooking.activity_log.append(message)
	while state.cooking.activity_log.size()>LOG_LIMIT:state.cooking.activity_log.pop_front()

static func _progress(state:Dictionary,cook_id:String) -> Dictionary:
	return ProfessionSystem.progress(state,cook_id)

static func has_choice(state:Dictionary,cook_id:String,choice_id:String) -> bool:
	return choice_id in _progress(state,cook_id).get("known_personal_techniques",[])

static func commitment(state:Dictionary,cook_id:String) -> String:
	return CookingData.commitment(_progress(state,cook_id))

static func current_candidate(state:Dictionary) -> Dictionary:
	ensure_state(state);var candidates:Array=state.get("recruitment",{}).get("candidates",[])
	return candidates[0] if not candidates.is_empty() else {}

static func serve_candidate_meal(state:Dictionary,cook_id:String,meal_id:String) -> Dictionary:
	ensure_state(state);var candidate:=current_candidate(state);var meal_data:=CookingData.meal(meal_id)
	if candidate.is_empty():return {"success":false,"reason":"There is no patron waiting."}
	if str(meal_data.get("category",""))!="hospitality":return {"success":false,"reason":"Choose a Hospitality meal."}
	var meal:=TavernFacilitySystem.take_meal(state,meal_id)
	if meal.is_empty():return {"success":false,"reason":"Prepare %s first."%str(meal_data.get("display_name",meal_id))}
	candidate.hospitality_meals.append(meal_id);candidate.hospitality_cook_id=cook_id
	_log(state,"%s served %s to %s."%[ProfessionSystem.hero_name(state,cook_id),str(meal_data.display_name),str(candidate.hero_record.display_name)])
	return {"success":true,"reason":"Meal served."}

static func familiar_offer_status(state:Dictionary) -> Dictionary:
	ensure_state(state);var candidate:=current_candidate(state)
	if candidate.is_empty():return {"available":false,"reason":"No patron is waiting."}
	if bool(candidate.familiar_offer_used):return {"available":false,"reason":"The offer was already used."}
	var cook_id:=str(candidate.hospitality_cook_id)
	if not has_choice(state,cook_id,"cooking_familiar_offer"):return {"available":false,"reason":"The serving cook does not know Familiar Offer."}
	if candidate.hospitality_meals.is_empty() or int(candidate.cooking_refresh_count)<1:return {"available":false,"reason":"The patron must eat and complete one Tavern refresh."}
	if float(candidate.remaining_wait_minutes)>CookingData.FAMILIAR_OFFER_MAX_WAIT_MINUTES:return {"available":false,"reason":"Available during the patron's final five minutes."}
	var cost:=maxi(1,int(ceil(float(candidate.signing_cost)*(1.0-CookingData.FAMILIAR_OFFER_DISCOUNT))))
	candidate.familiar_offer_available=true;candidate.familiar_offer_cost=cost
	return {"available":true,"reason":"Familiar Offer available.","cost":cost}

static func table_talk(state:Dictionary,category:String,roll:float=-1.0) -> Dictionary:
	ensure_state(state);var candidate:=current_candidate(state)
	if candidate.is_empty():return {"success":false,"reason":"There is no patron waiting."}
	if bool(candidate.table_talk_used):return {"success":false,"reason":"Table Talk was already used for this patron."}
	var cook_id:=str(candidate.hospitality_cook_id)
	if not has_choice(state,cook_id,"cooking_table_talk"):return {"success":false,"reason":"Serve this patron with a cook who knows Table Talk."}
	if candidate.hospitality_meals.is_empty() or int(candidate.cooking_refresh_count)<1:return {"success":false,"reason":"The patron must eat and complete one refresh first."}
	var categories:={"class":["class","exact_level"],"traits":["positive_trait","negative_trait"],"profession":["profession"],"equipment":["equipment"],"title":["title"]}
	if not categories.has(category):return {"success":false,"reason":"Unknown information category."}
	var resolved:=roll if roll>=0.0 else randf();var outcome:="full" if resolved<0.55 else "partial" if resolved<0.82 else "guarded"
	for field_id in categories[category]:candidate.targeted_reveals[field_id]=outcome
	candidate.table_talk_used=true
	_log(state,"Table Talk about %s ended %s."%[category.capitalize(),outcome])
	return {"success":true,"reason":"Table Talk result: %s."%outcome.capitalize(),"outcome":outcome,"category":category}

static func activate_campaign_menu(state:Dictionary,cook_id:String,meal_id:String,campaign_id:String) -> Dictionary:
	ensure_state(state)
	if not has_choice(state,cook_id,"cooking_campaign_menus"):return {"success":false,"reason":"Requires Campaign Menus."}
	if campaign_id.strip_edges()=="":return {"success":false,"reason":"Unavailable until a recruitment campaign supplies its campaign ID."}
	var meal:=CookingData.meal(meal_id)
	if str(meal.get("purpose",""))!="candidate":return {"success":false,"reason":"Choose a campaign dish."}
	state.cooking.active_campaign_menu={"cook_id":cook_id,"meal_id":meal_id,"campaign_id":campaign_id}
	return {"success":true,"reason":"Campaign Menu service is ready for campaign refresh hooks."}

static func _candidate_development(state:Dictionary,candidate:Dictionary,meal_id:String) -> Dictionary:
	var effect:=str(CookingData.meal(meal_id).get("development",""));var hero:Dictionary=candidate.hero_record;var result:={"effect":effect,"changed":false}
	match effect:
		"class_xp":
			hero["candidate_class_xp"]=int(hero.get("candidate_class_xp",0))+15;result.changed=true
		"disclosure":
			var hidden:=RecruitmentData.REVEAL_ORDER.filter(func(field_id):return not bool(candidate.targeted_reveals.has(str(field_id))))
			if not hidden.is_empty():candidate.targeted_reveals[str(hidden[0])]="full";result.changed=true
		"profession_xp":
			var progress:Dictionary=hero.get("profession_progress",{})
			if str(progress.get("profession_id",""))!="":progress.profession_xp=int(progress.get("profession_xp",0))+15;result.changed=true
		"trait":
			result["reason"]="No candidate trait-progression data exists yet; no trait was fabricated."
	candidate.development_history.append({"refresh":int(state.cooking.refresh_serial),"meal_id":meal_id,"changed":result.changed})
	return result

static func on_candidate_refresh(state:Dictionary,campaign_id:String="") -> Dictionary:
	ensure_state(state);state.cooking.refresh_serial=int(state.cooking.refresh_serial)+1;var candidate:=current_candidate(state)
	if candidate.is_empty():return {"success":false,"reason":"No patron is waiting."}
	candidate.cooking_refresh_count=int(candidate.cooking_refresh_count)+1;candidate.last_cooking_refresh=int(state.cooking.refresh_serial)
	var menu:Dictionary=state.cooking.active_campaign_menu
	if menu.is_empty() or campaign_id=="" or str(menu.get("campaign_id",""))!=campaign_id:
		familiar_offer_status(state);return {"success":true,"reason":"Patron refresh recorded; no campaign menu hook was active."}
	if bool(candidate.locked) and not has_choice(state,str(menu.cook_id),"cooking_room_and_board"):
		return {"success":false,"reason":"Locked patrons require Room & Board for continued development."}
	var meal:=TavernFacilitySystem.take_meal(state,str(menu.meal_id))
	if meal.is_empty():return {"success":false,"reason":"The selected campaign dish is not prepared."}
	var result:=_candidate_development(state,candidate,str(menu.meal_id));familiar_offer_status(state)
	return {"success":true,"reason":str(result.get("reason","Campaign dish resolved.")),"development":result}

static func on_candidate_arrived(state:Dictionary) -> Dictionary:
	ensure_state(state);var candidate:=current_candidate(state);var service:Dictionary=state.cooking.active_house_banquet
	if candidate.is_empty() or service.is_empty():return {"success":false,"reason":"No active House Banquet opportunity."}
	if int(service.get("servings",0))<=0 or float(service.get("expires_at_game_minute",0.0))<=float(state.get("game_clock",{}).get("total_minutes",0.0)):return {"success":false,"reason":"The House Banquet is no longer serving."}
	var selections:Array=service.get("selections",[]);if selections.is_empty():return {"success":false,"reason":"The House Banquet has no dishes selected."}
	var meal_id:=str(selections[int(state.cooking.refresh_serial)%selections.size()]);var meal:=TavernFacilitySystem.take_meal(state,meal_id)
	if meal.is_empty():return {"success":false,"reason":"The House Banquet serving could not be claimed."}
	candidate.hospitality_meals.append(meal_id);candidate.hospitality_cook_id=str(service.get("cook_id",""));var result:=_candidate_development(state,candidate,meal_id)
	return {"success":true,"reason":"House Banquet provided one arrival opportunity.","development":result}

static func designate_house_favorite(state:Dictionary,cook_id:String,candidate_id:String) -> Dictionary:
	ensure_state(state);var candidate:=current_candidate(state)
	if commitment(state,cook_id)!="house_favorite":return {"success":false,"reason":"Requires the House Favorite commitment."}
	if candidate.is_empty() or str(candidate.candidate_id)!=candidate_id or not bool(candidate.locked):return {"success":false,"reason":"Choose the currently locked patron."}
	state.cooking.house_favorite_candidate_id=candidate_id;return {"success":true,"reason":"House Favorite designated."}

static func designate_special_guest(state:Dictionary,cook_id:String,hero_id:String,touch_id:String) -> Dictionary:
	ensure_state(state)
	if commitment(state,cook_id)!="special_guest":return {"success":false,"reason":"Requires the Special Guest commitment."}
	if not CookingData.CHEFS_TOUCHES.has(touch_id):return {"success":false,"reason":"Unknown Chef's Touch."}
	for hero in state.get("heroes",[]):
		if str(hero.get("hero_id",""))==hero_id:state.cooking.special_guest_hero_id=hero_id;hero.cooking_meal_state.chefs_touch_id=touch_id;return {"success":true,"reason":"Special Guest designated."}
	return {"success":false,"reason":"Unknown guild member."}

static func activate_feast(state:Dictionary,cook_id:String,service_id:String,selections:Array) -> Dictionary:
	ensure_state(state);var choice_id:="cooking_house_banquet" if service_id=="house_banquet" else "cooking_guild_feast" if service_id=="guild_feast" else ""
	if choice_id=="" or not has_choice(state,cook_id,choice_id):return {"success":false,"reason":"The cook has not unlocked this service."}
	if selections.size()!=2 or str(selections[0])==str(selections[1]):return {"success":false,"reason":"Choose two different dishes."}
	var expected:="candidate" if service_id=="house_banquet" else "mission"
	for meal_id in selections:
		if str(CookingData.meal(str(meal_id)).get("purpose",""))!=expected:return {"success":false,"reason":"One selection does not belong to this service."}
	var token:=TavernFacilitySystem.take_meal(state,service_id)
	if token.is_empty():return {"success":false,"reason":"Prepare the feast service order first."}
	var record:={"cook_id":cook_id,"selections":selections.duplicate(),"servings":CookingData.FEAST_SERVINGS,"expires_at_game_minute":float(state.get("game_clock",{}).get("total_minutes",0.0))+CookingData.FEAST_DURATION_MINUTES}
	state.cooking["active_house_banquet" if service_id=="house_banquet" else "active_guild_feast"]=record
	return {"success":true,"reason":"Service activated; it does not start a campaign or event."}

static func improviser_convert(state:Dictionary,cook_id:String,prepared_meal_id:String,target_meal_id:String) -> Dictionary:
	ensure_state(state)
	if commitment(state,cook_id)!="kitchen_improviser":return {"success":false,"reason":"Requires Kitchen Improviser."}
	var marker:=int(_progress(state,cook_id).get("improviser_refresh",-1))
	if marker==int(state.cooking.refresh_serial):return {"success":false,"reason":"Already converted a meal this Tavern refresh."}
	var source_index:=-1
	for index in state.tavern_facility.prepared_meals.size():
		if str(state.tavern_facility.prepared_meals[index].prepared_meal_id)==prepared_meal_id:source_index=index;break
	if source_index<0:return {"success":false,"reason":"Prepared meal not found."}
	var source:Dictionary=state.tavern_facility.prepared_meals[source_index];var from_data:=CookingData.meal(str(source.meal_id));var to_data:=CookingData.meal(target_meal_id)
	if from_data.is_empty() or to_data.is_empty() or str(from_data.category)!=str(to_data.category) or int(from_data.tier)!=int(to_data.tier):return {"success":false,"reason":"Conversion requires the same category and recipe tier."}
	var recipe_id:="cooking_"+target_meal_id
	if not ProfessionData.RECIPES.has(recipe_id) or not ProfessionSystem.recipe_is_learned(state,recipe_id) and not bool(ProfessionData.RECIPES[recipe_id].get("auto_known",false)):return {"success":false,"reason":"The target recipe is not known."}
	source.meal_id=target_meal_id;source.effect=to_data.get("effect",{}).duplicate(true);_progress(state,cook_id)["improviser_refresh"]=int(state.cooking.refresh_serial)
	return {"success":true,"reason":"Prepared meal converted."}
