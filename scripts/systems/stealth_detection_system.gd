extends RefCounted

const DEFAULT_DETECTION := {"detect_stealthed":false,"detect_invisible":false,"detection_radius":0.0,"reveal_duration":2.0,"acquisition_chance":1.0,"acquisition_interval":0.25}

static func initialize(unit:Dictionary) -> void:
	unit["concealment"]={"stealthed":false,"invisible":false,"revealed_remaining":0.0,"unrevealable_remaining":0.0,"unit_passing":false,"sources":{}}

static func state(unit:Dictionary) -> Dictionary:
	if not unit.has("concealment"):initialize(unit)
	return unit.concealment

static func set_vanish(unit:Dictionary,enabled:bool) -> void:
	var value:=state(unit);value.stealthed=enabled
	if not enabled:value.invisible=false;value.unrevealable_remaining=0.0;value.unit_passing=false

static func set_source(unit:Dictionary,source_id:String,active:bool,unrevealable:bool=false,unit_passing:bool=false) -> void:
	var value:=state(unit)
	if active:value.sources[source_id]={"unrevealable":unrevealable,"unit_passing":unit_passing}
	else:value.sources.erase(source_id)
	refresh_sources(value)

static func refresh_sources(value:Dictionary) -> void:
	var source_invisible:bool=not value.sources.is_empty();var source_unrevealable:bool=false;var source_passing:bool=false
	for source in value.sources.values():source_unrevealable=source_unrevealable or bool(source.get("unrevealable",false));source_passing=source_passing or bool(source.get("unit_passing",false))
	value["source_invisible"]=source_invisible;value["source_unrevealable"]=source_unrevealable;value["source_passing"]=source_passing

static func is_unrevealable(unit:Dictionary) -> bool:
	var value:=state(unit);return float(value.unrevealable_remaining)>0.0 or bool(value.get("source_unrevealable",false))

static func is_invisible(unit:Dictionary) -> bool:
	var value:=state(unit);return bool(value.invisible) or bool(value.get("source_invisible",false))

static func is_stealthed(unit:Dictionary) -> bool:return bool(state(unit).stealthed)

static func directly_targetable(observer:Dictionary,target:Dictionary,distance:float=INF) -> bool:
	var value:=state(target)
	if is_unrevealable(target):return false
	if float(value.revealed_remaining)>0.0:return true
	var profile:Dictionary=DEFAULT_DETECTION.duplicate(true);profile.merge(observer.get("detection_profile",{}),true)
	if float(profile.detection_radius)>0.0 and distance>float(profile.detection_radius):return false
	if is_invisible(target):return bool(profile.detect_invisible)
	if is_stealthed(target):return bool(profile.detect_stealthed)
	return true

static func reveal(unit:Dictionary,duration:float) -> bool:
	if is_unrevealable(unit):return false
	var value:=state(unit);value.revealed_remaining=maxf(float(value.revealed_remaining),maxf(0.0,duration));return true

static func update(unit:Dictionary,delta:float,moved:bool=false) -> void:
	var value:=state(unit);value.revealed_remaining=maxf(0.0,float(value.revealed_remaining)-delta);value.unrevealable_remaining=maxf(0.0,float(value.unrevealable_remaining)-delta)
	if moved and bool(value.invisible):value.invisible=false
