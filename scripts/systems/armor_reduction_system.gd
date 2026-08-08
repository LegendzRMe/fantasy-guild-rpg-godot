extends RefCounted

static func apply(target:Dictionary,source_id:String,amount:float,duration:float) -> void:
	var sources:Array=target.get("armor_reduction_sources",[]).duplicate(true)
	for index in sources.size():
		if str(sources[index].get("source_id",""))==source_id:
			sources[index]={"source_id":source_id,"amount":maxf(0.0,amount),"remaining":maxf(0.0,duration)};target.armor_reduction_sources=sources;return
	sources.append({"source_id":source_id,"amount":maxf(0.0,amount),"remaining":maxf(0.0,duration)});target.armor_reduction_sources=sources

static func update(target:Dictionary,delta:float) -> void:
	var sources:Array=target.get("armor_reduction_sources",[])
	for source in sources:source.remaining=maxf(0.0,float(source.remaining)-delta)
	target.armor_reduction_sources=sources.filter(func(source):return float(source.get("remaining",0.0))>0.0)

static func effective(target:Dictionary) -> float:
	var result:=0.0
	for source in target.get("armor_reduction_sources",[]):result=maxf(result,float(source.get("amount",0.0)))
	return minf(maxf(0.0,float(target.get("armor",0.0))),result)

static func effective_armor(target:Dictionary) -> float:
	return maxf(0.0,float(target.get("armor",0.0))-effective(target))

static func clear(target:Dictionary) -> void:
	target.armor_reduction_sources=[]
