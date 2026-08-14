extends RefCounted

static func is_disposable(unit:Dictionary)->bool:return bool(unit.get("summoned_unit",false)) and float(unit.get("health_decay_rate",0.0))>0.0
static func original_lifetime(unit:Dictionary)->float:
	var decay:=float(unit.get("health_decay_rate",0.0));return float(unit.get("original_health",unit.get("max_hp",0.0)))/decay if decay>0.0 else -1.0
static func remaining_lifetime(unit:Dictionary)->float:
	var decay:=float(unit.get("health_decay_rate",0.0));return float(unit.get("hp",0.0))/decay if decay>0.0 else -1.0
static func advance(unit:Dictionary,delta:float)->Dictionary:
	if not is_disposable(unit) or float(unit.get("hp",0.0))<=0.0:return {"expired":false,"lost":0.0}
	var lost:=minf(float(unit.hp),float(unit.health_decay_rate)*maxf(0.0,delta));unit.hp=float(unit.hp)-lost
	if float(unit.hp)<=0.0:unit["decay_expired"]=true
	return {"expired":float(unit.hp)<=0.0,"lost":lost}

