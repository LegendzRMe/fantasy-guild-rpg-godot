extends RefCounted

static func hero_errors(hero:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	if str(hero.get("hero_id",""))=="":errors.append("hero_id is required")
	if str(hero.get("class_id",""))=="":errors.append("class_id is required")
	if str(hero.get("display_name",hero.get("name","")))=="":errors.append("display_name is required")
	if int(hero.get("level",0))<1:errors.append("level must be at least 1")
	if not hero.get("equipment_slots") is Dictionary:errors.append("equipment_slots must be a Dictionary")
	if not hero.get("selected_talents") is Dictionary:errors.append("selected_talents must be a Dictionary")
	return errors

static func inventory_entry_errors(entry:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	if str(entry.get("instance_id",""))=="":errors.append("instance_id is required")
	if bool(entry.get("is_material",false)):
		if str(entry.get("material_id",""))=="":errors.append("material_id is required")
		if int(entry.get("quantity",0))<=0:errors.append("material quantity must be positive")
	elif str(entry.get("definition_id",""))=="":errors.append("definition_id is required")
	if str(entry.get("storage_location","vault")) not in ["vault","depot"]:errors.append("storage_location is invalid")
	return errors

static func recruitment_candidate_errors(candidate:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	if str(candidate.get("candidate_id",""))=="":errors.append("candidate_id is required")
	if not candidate.get("hero_record") is Dictionary:errors.append("hero_record must be a Dictionary")
	elif not hero_errors(candidate.hero_record).is_empty():errors.append("hero_record is invalid")
	if not candidate.get("equipment_instances",[]) is Array:errors.append("equipment_instances must be an Array")
	if float(candidate.get("remaining_wait_minutes",0.0))<=0.0:errors.append("remaining_wait_minutes must be positive")
	return errors

static func profession_order_errors(order:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	for key in ["order_id","profession","recipe_id","assigned_member_id"]:
		if str(order.get(key,""))=="":errors.append("%s is required"%key)
	if str(order.get("status","")) not in ["active","paused","cancelled","complete"]:errors.append("status is invalid")
	if not order.get("input_items",[]) is Array or not order.get("input_materials",[]) is Array:errors.append("order inputs must be Arrays")
	if float(order.get("remaining_time",-1.0))<0.0:errors.append("remaining_time cannot be negative")
	return errors

static func combat_unit_errors(unit:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	if str(unit.get("combat_id",""))=="":errors.append("combat_id is required")
	if not unit.has("hp") or not unit.has("max_hp"):errors.append("hp and max_hp are required")
	elif float(unit.max_hp)<=0.0 or float(unit.hp)<0.0:errors.append("Health values are invalid")
	if not unit.get("pos") is Vector2:errors.append("pos must be a Vector2")
	return errors

static func combat_event_errors(event:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	if str(event.get("event_type",""))=="":errors.append("event_type is required")
	if not event.get("source_unit") is Dictionary or not event.get("target_unit") is Dictionary:errors.append("source_unit and target_unit must be Dictionaries")
	if not event.get("action_tags") is Array:errors.append("action_tags must be an Array")
	return errors
