extends RefCounted

static func health_basis(target:Dictionary)->float:
	return maxf(0.0,float(target.get("percent_damage_health_basis",target.get("max_hp",target.get("maximum_health",0.0)))))

static func request(source:Dictionary,target:Dictionary,normal_fraction:float,boss_fraction:float,origin:String)->Dictionary:
	var is_boss:bool=bool(target.get("boss",false)) or "boss" in target.get("combat_tags",[])
	var fraction:float=boss_fraction if is_boss else normal_fraction
	return {"amount":health_basis(target)*maxf(0.0,fraction),"health_basis":health_basis(target),"fraction":fraction,"is_boss":is_boss,"source_action":"percentage_health","damage_type":"physical","can_crit":false,"origin":origin,"ignores_outgoing_multipliers":true,"allows_lifesteal":false}
