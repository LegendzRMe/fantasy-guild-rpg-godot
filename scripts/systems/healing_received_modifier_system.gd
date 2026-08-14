extends RefCounted

static func apply(target:Dictionary,source_id:String,amount:float,duration:float=INF,owner_id:String="")->void:
	var sources:Array=target.get("healing_received_sources",[]).duplicate(true)
	for index in sources.size():
		if str(sources[index].get("source_id",""))==source_id:sources[index]={"source_id":source_id,"owner_id":owner_id,"amount":amount,"remaining":duration};target.healing_received_sources=sources;return
	sources.append({"source_id":source_id,"owner_id":owner_id,"amount":amount,"remaining":duration});target.healing_received_sources=sources

static func remove(target:Dictionary,source_id:String)->void:target.healing_received_sources=target.get("healing_received_sources",[]).filter(func(source):return str(source.get("source_id",""))!=source_id)
static func update(target:Dictionary,delta:float)->void:
	for source in target.get("healing_received_sources",[]):if float(source.get("remaining",INF))<INF:source.remaining=maxf(0.0,float(source.remaining)-delta)
	target.healing_received_sources=target.get("healing_received_sources",[]).filter(func(source):return float(source.get("remaining",INF))>0.0)
static func multiplier(target:Dictionary)->float:
	var positive:=0.0;var strongest_reduction:=0.0
	for source in target.get("healing_received_sources",[]):
		if float(source.get("remaining",INF))<=0.0:continue
		var amount:=float(source.get("amount",0.0));if amount>=0.0:positive+=amount
		else:strongest_reduction=minf(strongest_reduction,amount)
	return maxf(0.0,1.0+positive+strongest_reduction)
