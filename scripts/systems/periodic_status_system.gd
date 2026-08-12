extends RefCounted

static func make_instance(effect_id:String, owner_id:String, target_id:String, duration:float, tick_interval:float, payload:Dictionary={}) -> Dictionary:
	var result := {
		"id":effect_id, "family":str(payload.get("family", effect_id)),
		"owner_id":owner_id, "target_id":target_id, "cast_id":str(payload.get("cast_id", "")),
		"remaining_duration":maxf(0.0, duration), "duration":maxf(0.0, duration),
		"tick_interval":maxf(0.001, tick_interval), "next_tick":maxf(0.001, tick_interval),
		"ticks_resolved":0, "stacks":int(payload.get("stacks", 1)),
		"max_stacks":int(payload.get("max_stacks", 1)), "beneficial":bool(payload.get("beneficial", false)),
		"crowd_control":bool(payload.get("crowd_control", false)), "icon_id":str(payload.get("icon_id", effect_id)),
		"color":payload.get("color", Color("b15cff")), "tint":payload.get("tint", Color("b15cff")),
		"outline":payload.get("outline", Color("e2b7ff")), "health_bar_marker":bool(payload.get("health_bar_marker", true)),
		"priority":int(payload.get("priority", 0)), "dispellable":bool(payload.get("dispellable", true)),
		"payload":payload.duplicate(true)
	}
	return result

static func create(effect_id:String,owner_id:String,target_id:String,tick_amount:float,duration:float,tick_interval:float)->Dictionary:
	var result:=make_instance(effect_id,owner_id,target_id,duration,tick_interval,{"tick_amount":tick_amount})
	result["tick_amount"]=tick_amount
	return result

static func create_healing(effect_id:String,owner_id:String,target_id:String,tick_amount:float,duration:float,tick_interval:float,tags:Array=[],payload:Dictionary={})->Dictionary:
	var healing_payload:=payload.duplicate(true)
	healing_payload["beneficial"]=true
	healing_payload["tick_amount"]=tick_amount
	healing_payload["effect_tags"]=_unique_tags(["healing","periodic_healing"]+tags)
	var result:=make_instance(effect_id,owner_id,target_id,duration,tick_interval,healing_payload)
	result["tick_amount"]=tick_amount
	result["effect_tags"]=healing_payload.effect_tags.duplicate()
	return result

static func _unique_tags(tags:Array)->Array:
	var result:Array=[]
	for tag in tags:
		var normalized:=str(tag).to_snake_case()
		if normalized!="" and normalized not in result:result.append(normalized)
	return result

static func refresh_owned(instances:Array,incoming:Dictionary)->Dictionary:
	var result:=instances.duplicate(true)
	for index in result.size():
		var current:Dictionary=result[index]
		if str(current.get("family",current.get("id","")))!=str(incoming.get("family",incoming.get("id",""))):continue
		if str(current.get("owner_id",""))!=str(incoming.get("owner_id","")) or str(current.get("target_id",""))!=str(incoming.get("target_id","")):continue
		result[index]=incoming.duplicate(true)
		return {"instances":result,"refreshed":true,"index":index}
	result.append(incoming.duplicate(true))
	return {"instances":result,"refreshed":false,"index":result.size()-1}

static func remaining_tick_count(instance:Dictionary)->int:
	var remaining:=maxf(0.0,float(instance.get("remaining_duration",0.0)))
	var next:=maxf(0.00001,float(instance.get("next_tick",instance.get("tick_interval",1.0))))
	if remaining+0.00001<next:return 0
	return 1+floori((remaining-next+0.00001)/maxf(0.001,float(instance.get("tick_interval",1.0))))

static func remaining_scheduled_amount(instance:Dictionary)->float:
	return remaining_tick_count(instance)*float(instance.get("tick_amount",instance.get("payload",{}).get("tick_amount",0.0)))

static func bonus_tick(instance:Dictionary)->Dictionary:
	var result:=instance.duplicate(true)
	result["bonus_tick"]=true
	result["due_ticks"]=1
	# A bonus tick is a snapshot only and must not alter ticks_resolved/next_tick.
	return result

static func add_stack(instances:Array, incoming:Dictionary, maximum:int) -> Array:
	var result := instances.duplicate(true)
	var matching:Array=[]
	for index in result.size():
		if str(result[index].get("id", "")) == str(incoming.get("id", "")) and str(result[index].get("owner_id", "")) == str(incoming.get("owner_id", "")) and str(result[index].get("target_id", "")) == str(incoming.get("target_id", "")):
			matching.append(index)
	if matching.size() >= maximum:
		var oldest_index:int=int(matching[0])
		for index in matching:
			if float(result[index].get("remaining_duration", 0.0)) < float(result[oldest_index].get("remaining_duration", 0.0)):
				oldest_index=index
		result[oldest_index]=incoming.duplicate(true)
	else:
		result.append(incoming.duplicate(true))
	return result

static func advance(instance:Dictionary, delta:float) -> Dictionary:
	var result:=instance.duplicate(true)
	result.remaining_duration=maxf(0.0, float(result.remaining_duration)-delta)
	result.next_tick=float(result.next_tick)-delta
	var ticks:=0
	while float(result.next_tick)<=0.00001 and float(result.remaining_duration)>=0.0:
		ticks+=1
		result.ticks_resolved=int(result.ticks_resolved)+1
		result.next_tick=float(result.next_tick)+float(result.tick_interval)
	result["due_ticks"]=ticks
	result["expired"]=float(result.remaining_duration)<=0.0
	return result
