extends RefCounted

static func apply(source:Dictionary,source_id:String,amount:float,duration:float)->void:
	var entries:Array=source.get("healing_done_sources",[]).duplicate(true)
	for index in entries.size():
		if str(entries[index].get("source_id",""))==source_id:entries[index]={"source_id":source_id,"amount":amount,"remaining":duration};source.healing_done_sources=entries;return
	entries.append({"source_id":source_id,"amount":amount,"remaining":duration});source.healing_done_sources=entries
static func update(source:Dictionary,delta:float)->void:
	for entry in source.get("healing_done_sources",[]):entry.remaining=maxf(0.0,float(entry.remaining)-delta)
	source.healing_done_sources=source.get("healing_done_sources",[]).filter(func(entry):return float(entry.remaining)>0.0)
static func multiplier(source:Dictionary)->float:
	var bonus:=0.0
	for entry in source.get("healing_done_sources",[]):if float(entry.get("remaining",0.0))>0.0:bonus+=float(entry.get("amount",0.0))
	return maxf(0.0,1.0+bonus)
