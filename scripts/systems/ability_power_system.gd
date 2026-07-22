extends RefCounted

# Shared percentage modifier applied after ordinary Power/flat scaling.
const STAT_ID := "ability_power_percent"

static func total_percent(source:Dictionary,extra_sources:Array=[])->float:
	var total:=float(source.get(STAT_ID,0.0))
	for entry in extra_sources:total+=float(entry.get(STAT_ID,entry.get("amount",0.0)))
	return total

static func apply(amount:float,source:Dictionary,extra_sources:Array=[])->float:
	return maxf(0.0,amount)*(1.0+total_percent(source,extra_sources))

static func source_breakdown(source:Dictionary)->Dictionary:
	var result:Dictionary=source.get("ability_power_sources",{}).duplicate(true)
	if result.is_empty() and float(source.get(STAT_ID,0.0))!=0.0:result["base"]=float(source.get(STAT_ID,0.0))
	return result
