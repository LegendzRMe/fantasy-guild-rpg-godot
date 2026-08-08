extends RefCounted

const RecruitmentData = preload("res://scripts/data/recruitment_data.gd")
const VALID_SPEEDS := [1,2,4]

static func default_state() -> Dictionary:
	return {"total_minutes":0.0,"speed":1,"paused":false}

static func ensure_state(state:Dictionary) -> void:
	var defaults:=default_state()
	if not state.get("game_clock") is Dictionary:state["game_clock"]=defaults
	for key in defaults:
		if not state.game_clock.has(key):state.game_clock[key]=defaults[key]
	state.game_clock.total_minutes=maxf(0.0,float(state.game_clock.get("total_minutes",0.0)))
	state.game_clock.speed=int(state.game_clock.get("speed",1)) if int(state.game_clock.get("speed",1)) in VALID_SPEEDS else 1
	state.game_clock.paused=bool(state.game_clock.get("paused",false))

static func advance(state:Dictionary,real_delta:float,simulation_paused:bool=false) -> float:
	ensure_state(state)
	if simulation_paused or bool(state.game_clock.paused):return 0.0
	var minutes:=maxf(0.0,real_delta)*float(state.game_clock.speed)/float(RecruitmentData.CONFIG.real_seconds_per_game_minute)
	state.game_clock.total_minutes=float(state.game_clock.total_minutes)+minutes
	return minutes

static func set_speed(state:Dictionary,speed:int) -> bool:
	ensure_state(state)
	if speed not in VALID_SPEEDS:return false
	state.game_clock.speed=speed
	return true

static func set_paused(state:Dictionary,value:bool) -> void:
	ensure_state(state);state.game_clock.paused=value

static func clock_text(state:Dictionary) -> String:
	ensure_state(state)
	var total:=int(floor(float(state.game_clock.total_minutes)))
	var day:=total/(24*60)+1;var hour:=(total/60)%24;var minute:=total%60
	return "DAY %d  %02d:%02d"%[day,hour,minute]
