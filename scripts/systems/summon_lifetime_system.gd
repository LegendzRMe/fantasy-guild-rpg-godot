extends RefCounted

static func is_summon(target:Dictionary)->bool:return str(target.get("target_category",""))=="summon" or bool(target.get("summoned_unit",false)) or "summon" in target.get("combat_tags",[])
static func original_lifetime(target:Dictionary)->float:return float(target.get("original_lifetime",target.get("summon_original_lifetime",-1.0)))
static func remaining_lifetime(target:Dictionary)->float:return float(target.get("remaining_lifetime",target.get("summon_remaining_lifetime",target.get("lifetime",-1.0))))
static func reduce(target:Dictionary,fraction:float)->Dictionary:
	var original:=original_lifetime(target);var remaining:=remaining_lifetime(target)
	if original<=0.0 or remaining<0.0:return {"finite":false,"removed":0.0,"despawned":false}
	var removed:=minf(remaining,original*maxf(0.0,fraction));var next:=maxf(0.0,remaining-removed)
	if target.has("remaining_lifetime"):target.remaining_lifetime=next
	elif target.has("summon_remaining_lifetime"):target.summon_remaining_lifetime=next
	else:target.lifetime=next
	if next<=0.0:target["lifetime_expired"]=true;target["hp"]=0.0
	return {"finite":true,"removed":removed,"despawned":next<=0.0}
static func update(target:Dictionary,delta:float)->void:
	if not is_summon(target):return
	var remaining:=remaining_lifetime(target);if remaining<0.0:return
	var next:=maxf(0.0,remaining-maxf(0.0,delta))
	if target.has("remaining_lifetime"):target.remaining_lifetime=next
	elif target.has("summon_remaining_lifetime"):target.summon_remaining_lifetime=next
	else:target.lifetime=next
	if next<=0.0:target.lifetime_expired=true;target.hp=0.0
