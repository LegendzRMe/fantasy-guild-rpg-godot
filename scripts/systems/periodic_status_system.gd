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
