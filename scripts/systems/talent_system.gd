extends RefCounted

const TalentData = preload("res://scripts/data/talent_data.gd")
const ABILITY_UNLOCK_LEVELS := TalentData.ABILITY_UNLOCK_LEVELS
const TIER_LEVELS := TalentData.TIER_LEVELS

static func ability_is_unlocked(level:int,slot:int)->bool:
	return level>=int(ABILITY_UNLOCK_LEVELS.get(slot,999))

static func unlocked_tier_ids(level:int)->Array:
	var result:Array=[]
	for tier_id in TIER_LEVELS:
		if level>=int(TIER_LEVELS[tier_id]):result.append(tier_id)
	return result

static func newly_unlocked_tiers(before_level:int,after_level:int)->Array:
	var result:Array=[]
	for tier_id in TIER_LEVELS:
		var required_level:int=int(TIER_LEVELS[tier_id])
		if before_level<required_level and after_level>=required_level:result.append(tier_id)
	return result

static func record_class_discovery(discovery:Dictionary,class_id:String,level:int)->Dictionary:
	var next:=discovery.duplicate(true)
	next[class_id]=maxi(int(next.get(class_id,0)),clampi(level,1,30))
	return next

static func tier_is_revealed(discovery:Dictionary,class_id:String,tier_id:String,testing_save:bool=false)->bool:
	return testing_save or int(discovery.get(class_id,0))>=int(TIER_LEVELS.get(tier_id,999))

static func tier_definition(class_definition:Dictionary,tier_id:String)->Dictionary:
	for definition in class_definition.get("talent_tier_definitions",[]):
		if str(definition.get("tier_id",""))==tier_id:
			var resolved:Dictionary=definition.duplicate(true)
			if tier_id=="tier_3" and resolved.get("option_ids",[]).is_empty():resolved["option_ids"]=class_definition.get("heroic_option_ids",[]).duplicate()
			elif tier_id=="tier_7":
				if not resolved.get("option_ids",[]).is_empty():return resolved
				var options:Array=[];var requirements:Dictionary={}
				for heroic_id in class_definition.get("heroic_option_ids",[]):
					var upgrade_id:="%s_upgrade"%str(heroic_id);options.append(upgrade_id);requirements[upgrade_id]=heroic_id
				resolved["option_ids"]=options;resolved["heroic_requirements"]=requirements
			return resolved
	return {}

static func option_ids_for_tier(class_definition:Dictionary,tier_id:String)->Array:
	var definition:=tier_definition(class_definition,tier_id)
	return definition.get("option_ids",[]).duplicate() if not definition.is_empty() else []

static func validate_selection(hero:Dictionary,class_definition:Dictionary,tier_id:String,option_id:String)->Dictionary:
	var required_level:int=int(TIER_LEVELS.get(tier_id,999))
	if int(hero.get("level",1))<required_level:return {"valid":false,"reason":"Talent tier is not unlocked"}
	var definition:=tier_definition(class_definition,tier_id)
	if definition.is_empty():return {"valid":false,"reason":"Unknown talent tier"}
	if option_id not in definition.get("option_ids",[]):return {"valid":false,"reason":"Talent is not available in this tier"}
	if tier_id=="tier_7":
		var selected_heroic_id:=str(hero.get("selected_heroic_id",""))
		if selected_heroic_id=="":return {"valid":false,"reason":"Choose a Heroic before its upgrade"}
		var upgrade_requirements:Dictionary=definition.get("heroic_requirements",{})
		if str(upgrade_requirements.get(option_id,""))!=selected_heroic_id:return {"valid":false,"reason":"Upgrade does not match the selected Heroic"}
	return {"valid":true,"reason":""}

static func select_option(hero:Dictionary,class_definition:Dictionary,tier_id:String,option_id:String)->Dictionary:
	var validation:=validate_selection(hero,class_definition,tier_id,option_id)
	if not validation.valid:return {"success":false,"reason":validation.reason,"hero":hero.duplicate(true)}
	var next:=hero.duplicate(true)
	if not next.get("selected_talents") is Dictionary:next["selected_talents"]={}
	next.selected_talents[tier_id]=option_id
	if tier_id=="tier_3":next["selected_heroic_id"]=option_id
	if not next.get("planned_talents") is Dictionary:next["planned_talents"]={}
	next.planned_talents.erase(tier_id)
	return {"success":true,"reason":"","hero":next}

static func plan_option(hero:Dictionary,class_definition:Dictionary,tier_id:String,option_id:String)->Dictionary:
	var definition:=tier_definition(class_definition,tier_id)
	if definition.is_empty() or option_id not in definition.get("option_ids",[]):return hero.duplicate(true)
	var next:=hero.duplicate(true)
	if not next.get("planned_talents") is Dictionary:next["planned_talents"]={}
	next.planned_talents[tier_id]=option_id
	return next

static func clear_planned_option(hero:Dictionary,tier_id:String)->Dictionary:
	var next:=hero.duplicate(true)
	if next.get("planned_talents") is Dictionary:next.planned_talents.erase(tier_id)
	return next

static func clear_tier(hero:Dictionary,tier_id:String)->Dictionary:
	var next:=hero.duplicate(true)
	if next.get("selected_talents") is Dictionary:next.selected_talents.erase(tier_id)
	if tier_id=="tier_3":
		next["selected_heroic_id"]=""
		if next.get("selected_talents") is Dictionary:next.selected_talents.erase("tier_7")
	return next

static func clear_all(hero:Dictionary)->Dictionary:
	var next:=hero.duplicate(true)
	next["selected_talents"]={};next["selected_heroic_id"]=""
	return next

static func generate_legal_build(hero:Dictionary,class_definition:Dictionary)->Dictionary:
	var result:Dictionary={}
	var working:=hero.duplicate(true)
	for tier_id in TIER_LEVELS:
		if int(working.get("level",1))<int(TIER_LEVELS[tier_id]):continue
		for option_id in option_ids_for_tier(class_definition,tier_id):
			var validation:=validate_selection(working,class_definition,tier_id,str(option_id))
			if validation.valid:
				result[tier_id]=option_id;working.selected_talents=result.duplicate()
				if tier_id=="tier_3":working.selected_heroic_id=option_id
				break
	return result
