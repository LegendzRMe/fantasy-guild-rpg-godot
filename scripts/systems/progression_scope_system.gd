extends RefCounted

static var _next_encounter_serial:int=1

static func new_encounter_id(prefix:String="encounter")->String:
	var value:="%s:%d"%[prefix,_next_encounter_serial];_next_encounter_serial+=1;return value

static func ensure_member_mastery(member:Dictionary)->Dictionary:
	if not member.has("talent_mastery") or not member.talent_mastery is Dictionary:member["talent_mastery"]={}
	return member.talent_mastery

static func mastery_progress(member:Dictionary,talent_id:String)->int:
	return maxi(0,int(ensure_member_mastery(member).get(talent_id,0)))

static func add_mastery(member:Dictionary,talent_id:String,amount:int=1)->int:
	var mastery:=ensure_member_mastery(member);mastery[talent_id]=maxi(0,int(mastery.get(talent_id,0))+amount);return int(mastery[talent_id])

static func begin_encounter(runtime:Dictionary,encounter_id:String)->void:
	runtime["encounter_id"]=encounter_id;runtime["encounter_progress"]={};runtime["encounter_rewards"]={}

static func room_transition(runtime:Dictionary,encounter_id:String)->void:
	# Rooms and waves preserve encounter progress; a mismatched ID means a new encounter.
	if str(runtime.get("encounter_id",""))!=encounter_id:begin_encounter(runtime,encounter_id)

static func end_encounter(runtime:Dictionary)->void:
	runtime["encounter_id"]="";runtime["encounter_progress"]={};runtime["encounter_rewards"]={}

static func add_encounter_progress(runtime:Dictionary,key:String,amount:int=1)->int:
	if not runtime.has("encounter_progress") or not runtime.encounter_progress is Dictionary:runtime["encounter_progress"]={}
	runtime.encounter_progress[key]=maxi(0,int(runtime.encounter_progress.get(key,0))+amount);return int(runtime.encounter_progress[key])

static func set_reward(runtime:Dictionary,key:String,value:bool=true)->void:
	if not runtime.has("encounter_rewards") or not runtime.encounter_rewards is Dictionary:runtime["encounter_rewards"]={}
	runtime.encounter_rewards[key]=value

static func reward_active(runtime:Dictionary,key:String)->bool:return bool(runtime.get("encounter_rewards",{}).get(key,false))
