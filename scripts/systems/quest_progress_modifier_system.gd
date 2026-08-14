extends RefCounted

static func apply(unit:Dictionary,source_id:String,value:float,duration:float)->void:
	var sources:Array=unit.get("combat_quest_progress_sources",[]).filter(func(source):return str(source.get("source_id",""))!=source_id);sources.append({"source_id":source_id,"multiplier":value,"remaining":duration});unit.combat_quest_progress_sources=sources
static func remove(unit:Dictionary,source_id:String)->void:unit.combat_quest_progress_sources=unit.get("combat_quest_progress_sources",[]).filter(func(source):return str(source.get("source_id",""))!=source_id)
static func update(unit:Dictionary,delta:float)->void:
	for source in unit.get("combat_quest_progress_sources",[]):source.remaining=maxf(0.0,float(source.get("remaining",0.0))-delta)
	unit.combat_quest_progress_sources=unit.get("combat_quest_progress_sources",[]).filter(func(source):return float(source.get("remaining",0.0))>0.0)

static func multiplier(unit:Dictionary)->float:
	var strongest:=1.0
	for source in unit.get("combat_quest_progress_sources",[]):if float(source.get("remaining",0.0))>0.0:strongest=maxf(strongest,float(source.get("multiplier",1.0)))
	return strongest
static func amount(unit:Dictionary,base_amount:int)->int:return maxi(0,roundi(float(base_amount)*multiplier(unit)))
