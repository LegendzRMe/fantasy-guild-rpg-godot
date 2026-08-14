extends RefCounted

static func positive_multiplier(target:Dictionary)->float:
	var additive:=0.0
	for source in target.get("positive_armor_effectiveness_sources",[]):if float(source.get("remaining",INF))>0.0:additive+=float(source.get("amount",0.0))
	return maxf(0.0,1.0+additive)
static func apply_positive(target:Dictionary,armor:float)->float:return armor*positive_multiplier(target) if armor>0.0 else armor
