extends RefCounted

static func initialize(owner:Dictionary, maximum:int=3) -> void:
	owner["combo_points"]=clampi(int(owner.get("combo_points",0)),0,maximum)
	owner["combo_point_maximum"]=maxi(1,maximum)

static func maximum(owner:Dictionary) -> int:
	return maxi(1,int(owner.get("combo_point_maximum",3)))

static func current(owner:Dictionary) -> int:
	return clampi(int(owner.get("combo_points",0)),0,maximum(owner))

static func successful_hit(result:Dictionary) -> bool:
	return not bool(result.get("immune",false)) and (float(result.get("health_damage",0.0))>0.0 or float(result.get("shield_damage",0.0))>0.0)

static func gain(owner:Dictionary, amount:int) -> Dictionary:
	var before:=current(owner);var after:=mini(maximum(owner),before+maxi(0,amount));owner.combo_points=after
	return {"before":before,"after":after,"gained":after-before,"wasted":maxi(0,amount-(after-before))}

static func eviscerate_snapshot(owner:Dictionary) -> int:
	return mini(3,current(owner))

static func spend(owner:Dictionary, requested:int, free:bool=false) -> Dictionary:
	var before:=current(owner);var used:=mini(3,mini(before,maxi(0,requested)));var consumed:=0 if free else used
	owner.combo_points=before-consumed
	return {"combo_points_used_for_scaling":used,"combo_points_consumed":consumed,"before":before,"after":int(owner.combo_points)}

static func reset(owner:Dictionary) -> void:
	owner.combo_points=0
