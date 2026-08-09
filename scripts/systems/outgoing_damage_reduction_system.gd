extends RefCounted

static func apply(unit:Dictionary,source_id:String,amount:float,duration:float)->void:
	unit["active_effects"]=unit.get("active_effects",[]).filter(func(effect):return not (str(effect.get("effect_family",""))=="outgoing_damage_reduction" and str(effect.get("source_id",""))==source_id))
	unit.active_effects.append({"id":"outgoing_reduction:%s"%source_id,"effect_family":"outgoing_damage_reduction","source_id":source_id,"amount":clampf(amount,0.0,1.0),"remaining_duration":maxf(0.0,duration)})

static func strongest(unit:Dictionary)->float:
	var result:=0.0
	for effect in unit.get("active_effects",[]):
		if str(effect.get("effect_family",""))=="outgoing_damage_reduction" and float(effect.get("remaining_duration",0.0))>0.0:result=maxf(result,float(effect.get("amount",0.0)))
	return clampf(result,0.0,1.0)

static func multiplier(unit:Dictionary)->float:return 1.0-strongest(unit)
