extends RefCounted

enum RechargeMode { SEQUENTIAL, INDEPENDENT }

static func create(max_charges:int=1,recharge:float=0.0,mode:RechargeMode=RechargeMode.SEQUENTIAL)->Dictionary:
	return {"max_charges":maxi(1,max_charges),"current_charges":maxi(1,max_charges),"recharge_duration":maxf(0.0,recharge),"recharge_mode":mode,"timers":[],"intercast_remaining":0.0,"lockout_remaining":0.0,"disabled":false,"unavailable":false}

static func can_activate(slot:Dictionary)->bool:
	return not bool(slot.get("disabled",false)) and not bool(slot.get("unavailable",false)) and float(slot.get("intercast_remaining",0.0))<=0.0 and float(slot.get("lockout_remaining",0.0))<=0.0 and int(slot.get("current_charges",0))>0

static func spend(slot:Dictionary,intercast:float=0.0)->bool:
	if not can_activate(slot):return false
	slot.current_charges=int(slot.current_charges)-1;slot.intercast_remaining=maxf(0.0,intercast)
	var duration:=float(slot.get("recharge_duration",0.0))
	if duration>0.0:
		if int(slot.get("recharge_mode",RechargeMode.SEQUENTIAL))==RechargeMode.INDEPENDENT:slot.timers.append(duration)
		elif slot.timers.is_empty():slot.timers.append(duration)
	return true

static func update(slot:Dictionary,delta:float,rate:float=1.0)->void:
	var step:=maxf(0.0,delta)*maxf(0.0,rate)
	slot.intercast_remaining=maxf(0.0,float(slot.get("intercast_remaining",0.0))-delta)
	slot.lockout_remaining=maxf(0.0,float(slot.get("lockout_remaining",0.0))-delta)
	var mode:=int(slot.get("recharge_mode",RechargeMode.SEQUENTIAL))
	if mode==RechargeMode.INDEPENDENT:
		for i in range(slot.timers.size()-1,-1,-1):
			slot.timers[i]=float(slot.timers[i])-step
			if float(slot.timers[i])<=0.0:slot.timers.remove_at(i);slot.current_charges=mini(int(slot.max_charges),int(slot.current_charges)+1)
	elif not slot.timers.is_empty():
		slot.timers[0]=float(slot.timers[0])-step
		while not slot.timers.is_empty() and float(slot.timers[0])<=0.0:
			var overflow:float=-float(slot.timers[0]);slot.current_charges=mini(int(slot.max_charges),int(slot.current_charges)+1);slot.timers.clear()
			if int(slot.current_charges)<int(slot.max_charges):slot.timers.append(maxf(0.0,float(slot.recharge_duration)-overflow))

static func reduce_active_recharge(slot:Dictionary,seconds:float)->float:
	if slot.get("timers",[]).is_empty():return 0.0
	var before:=float(slot.timers[0]);slot.timers[0]=maxf(0.0,before-maxf(0.0,seconds));return before-float(slot.timers[0])

static func set_lockout(slot:Dictionary,duration:float)->void:slot.lockout_remaining=maxf(float(slot.get("lockout_remaining",0.0)),duration)

static func ui_state(slot:Dictionary)->Dictionary:
	return {"charges":int(slot.get("current_charges",0)),"max_charges":int(slot.get("max_charges",1)),"recharge":float(slot.get("timers",[0.0])[0]) if not slot.get("timers",[]).is_empty() else 0.0,"intercast":float(slot.get("intercast_remaining",0.0)),"lockout":float(slot.get("lockout_remaining",0.0)),"disabled":bool(slot.get("disabled",false)),"unavailable":bool(slot.get("unavailable",false))}

