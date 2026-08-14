extends RefCounted

static func apply(target:Dictionary,forced_index:int,source_id:String,duration:float,owner_id:String="",metadata:Dictionary={})->void:
	target["forced_target"]={"target_index":forced_index,"source_id":source_id,"owner_id":owner_id,"remaining":maxf(0.0,duration),"metadata":metadata.duplicate(true)}
	if forced_index>=0:target["target"]=forced_index
static func update(target:Dictionary,delta:float)->void:
	var forced:Dictionary=target.get("forced_target",{});if forced.is_empty():return
	forced.remaining=maxf(0.0,float(forced.remaining)-delta);target.forced_target=forced if float(forced.remaining)>0.0 else {}
static func preferred(target:Dictionary)->int:
	var forced:Dictionary=target.get("forced_target",{});return int(forced.get("target_index",-1)) if float(forced.get("remaining",0.0))>0.0 else -1
