extends RefCounted

static func create(max_time:float=1.5)->Dictionary:
	return {"active":false,"slot":-1,"elapsed":0.0,"max_time":maxf(.001,max_time),"aim_point":Vector2.ZERO,"aim_direction":Vector2.RIGHT,"instant_full":false,"input_mode":"release","device":"pc","latest_interrupt":"","maximum_charge":false}

static func start(state:Dictionary,slot:int,aim_point:Vector2,instant_full:bool=false,input_mode:String="release",device:String="pc")->bool:
	if bool(state.get("active",false)):return false
	state.active=true;state.slot=slot;state.elapsed=float(state.max_time) if instant_full else 0.0;state.aim_point=aim_point;state.instant_full=instant_full;state.input_mode=input_mode;state.device=device;state.latest_interrupt="";state.maximum_charge=instant_full
	return true

static func update(state:Dictionary,delta:float,aim_point:Vector2=Vector2.INF)->void:
	if not bool(state.get("active",false)):return
	state.elapsed=minf(float(state.max_time),float(state.elapsed)+maxf(0.0,delta));state.maximum_charge=float(state.elapsed)>=float(state.max_time)
	if aim_point!=Vector2.INF:state.aim_point=aim_point

static func percentage(state:Dictionary)->float:return clampf(float(state.get("elapsed",0.0))/maxf(.001,float(state.get("max_time",1.5))),0.0,1.0)
static func maximum(state:Dictionary)->bool:return bool(state.get("maximum_charge",false)) or percentage(state)>=1.0
static func commit(state:Dictionary)->Dictionary:
	if not bool(state.get("active",false)):return {"cast":false}
	var result:={"cast":true,"slot":int(state.slot),"percentage":percentage(state),"maximum_charge":maximum(state),"instant_full":bool(state.instant_full),"aim_point":Vector2(state.aim_point),"device":str(state.device),"input_mode":str(state.input_mode)}
	state.active=false;state.slot=-1;state.elapsed=0.0;state.instant_full=false;state.maximum_charge=false;return result
static func cancel(state:Dictionary)->bool:
	if not bool(state.get("active",false)):return false
	state.active=false;state.slot=-1;state.elapsed=0.0;state.instant_full=false;state.maximum_charge=false;return true
static func interrupt(state:Dictionary,reason:String)->bool:
	if reason not in ["stun","silence","fear","forced_displacement"] or not bool(state.get("active",false)):return false
	state.latest_interrupt=reason;return cancel(state)
