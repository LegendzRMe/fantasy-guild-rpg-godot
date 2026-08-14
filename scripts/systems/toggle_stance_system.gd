extends RefCounted

static func create(cooldown_on_exit:float,locked_slots:Array=[])->Dictionary:
	return {"active":false,"active_duration":0.0,"cooldown":0.0,"cooldown_on_exit":maxf(0.0,cooldown_on_exit),"locked_slots":locked_slots.duplicate(),"lock_bypassed":false}

static func can_activate(state:Dictionary)->bool:return not bool(state.get("active",false)) and float(state.get("cooldown",0.0))<=0.0
static func activate(state:Dictionary)->bool:
	if not can_activate(state):return false
	state.active=true;state.active_duration=0.0;return true
static func deactivate(state:Dictionary,cooldown_override:float=-1.0)->bool:
	if not bool(state.get("active",false)):return false
	state.active=false;state.cooldown=maxf(0.0,cooldown_override if cooldown_override>=0.0 else float(state.get("cooldown_on_exit",0.0)));return true
static func action_allowed(state:Dictionary,slot:int)->bool:
	return not bool(state.get("active",false)) or bool(state.get("lock_bypassed",false)) or slot not in state.get("locked_slots",[])
static func update(state:Dictionary,delta:float)->void:
	if bool(state.get("active",false)):state.active_duration=float(state.get("active_duration",0.0))+maxf(0.0,delta)
	else:state.cooldown=maxf(0.0,float(state.get("cooldown",0.0))-maxf(0.0,delta))
static func hard_reset(state:Dictionary)->void:state.active=false;state.active_duration=0.0;state.cooldown=0.0

