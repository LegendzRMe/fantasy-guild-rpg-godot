extends RefCounted

enum Mode { MOST_WOUNDED, CLOSEST_OTHER }

static func _valid(candidate:Dictionary, origin:Dictionary, radius:float, include_origin:bool, exclude_spirit:bool)->bool:
	if float(candidate.get("hp",0.0))<=0.0 or bool(candidate.get("incapacitated",false)):return false
	if exclude_spirit and bool(candidate.get("spirit_form",false)):return false
	if not include_origin and str(candidate.get("combat_id",""))==str(origin.get("combat_id","")):return false
	return Vector2(origin.get("pos",Vector2.ZERO)).distance_to(Vector2(candidate.get("pos",Vector2.ZERO)))<=radius

static func resolve(allies:Array, origin:Dictionary, radius:float, mode:int, include_origin:bool=true, exclude_spirit:bool=true):
	var candidates:Array=[]
	for index in allies.size():
		var candidate:Dictionary=allies[index]
		if not _valid(candidate,origin,radius,include_origin,exclude_spirit):continue
		candidates.append({"unit":candidate,"index":index,"ratio":float(candidate.hp)/maxf(1.0,float(candidate.max_hp)),"distance":Vector2(origin.pos).distance_to(Vector2(candidate.pos)),"stable":str(candidate.get("combat_id",index))})
	if candidates.is_empty():return null
	candidates.sort_custom(func(a,b):
		if mode==Mode.MOST_WOUNDED and not is_equal_approx(float(a.ratio),float(b.ratio)):return float(a.ratio)<float(b.ratio)
		if not is_equal_approx(float(a.distance),float(b.distance)):return float(a.distance)<float(b.distance)
		return str(a.stable)<str(b.stable))
	return candidates[0].unit

static func most_wounded(allies:Array,origin:Dictionary,radius:float,include_origin:bool=true,exclude_spirit:bool=true):
	return resolve(allies,origin,radius,Mode.MOST_WOUNDED,include_origin,exclude_spirit)

static func closest_other_or_self(allies:Array,origin:Dictionary,radius:float):
	var other=resolve(allies,origin,radius,Mode.CLOSEST_OTHER,false,true)
	if other!=null:return other
	return origin if _valid(origin,origin,radius,true,true) else null
