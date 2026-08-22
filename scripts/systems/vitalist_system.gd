extends RefCounted

const VitalistData=preload("res://scripts/data/vitalist_data.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func owner_id(unit:Dictionary)->String:return str(unit.get("combat_id","vitalist"))
static func telemetry_default()->Dictionary:
	var result:={}
	for key in ["q_casts","q_hot","q_effective","q_overheal","q_spreads","q_lifetime","q_longest","w_casts","w_damage","w_slow_time","e_casts","e_damage","e_silence","d_casts","d_q_count","d_w_count","d_healing","d_effective","d_overheal","superstrain_healing","vigorous_bonus","top_off_bonus","poppin_replacements","pox_extensions","growing_extensions","carrier_spreads","virulent_second","reactive_uses","targeted_uses","long_pitch_uses","d_lockout_attempts","basic_damage","swipe_damage","displaced","shove_duration","shove_distance","shove_collisions"]:result[key]=0.0
	return result
static func add(unit:Dictionary,key:String,amount:float=1.0)->void:
	if bool(unit.get("vitalist_runtime",{}).get("telemetry_enabled",false)):unit.vitalist_runtime.telemetry[key]=float(unit.vitalist_runtime.telemetry.get(key,0.0))+amount

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false,encounter_id:String="battle")->void:
	var d_charges:=2 if has_talent(unit,"vitalist_l30_3") else 1;var r_charges:=3 if has_talent(unit,"vitalist_l27_r1") and str(unit.get("selected_heroic_id",""))=="vitalist_l15_r1" else 1
	unit["vitalist_runtime"]={"next_cast_id":1,"q_infections":[],"w_infections":{},"d_slot":AbilitySlotSystem.create(d_charges,float(VitalistData.VALUES.d_cooldown),AbilitySlotSystem.RechargeMode.SEQUENTIAL),"r_slot":AbilitySlotSystem.create(r_charges,float(VitalistData.VALUES.controlled_recharge if r_charges>1 else VitalistData.VALUES.swipe_cooldown),AbilitySlotSystem.RechargeMode.SEQUENTIAL),"quest":{"encounter_id":encounter_id,"progress":0,"complete":false},"arm":{},"swipe":{},"shove":{},"long_pitch_remaining":0.0,"replacement_queue":[],"control_seen":{},"latest_snapshot":{"q":0,"w":0},"telemetry_enabled":telemetry_enabled,"telemetry":telemetry_default()}
	unit["base_basic_action_interval"]=float(VitalistData.VALUES.basic_attack_interval);unit["basic_attack_interval"]=float(VitalistData.VALUES.basic_attack_interval);unit["range"]=float(VitalistData.SPACE.fetid_range if has_talent(unit,"vitalist_l9_1") else VitalistData.SPACE.basic_range)

static func d_ui(unit:Dictionary)->Dictionary:return AbilitySlotSystem.ui_state(unit.vitalist_runtime.d_slot)
static func r_ui(unit:Dictionary)->Dictionary:return AbilitySlotSystem.ui_state(unit.vitalist_runtime.r_slot)
static func d_recharge_rate(unit:Dictionary)->float:
	var rate:=1.0
	if has_talent(unit,"vitalist_l9_3") and float(unit.get("hp",0.0))<float(unit.get("max_hp",1.0))*0.5:rate+=1.0
	if float(unit.vitalist_runtime.long_pitch_remaining)>0.0:rate+=1.0
	return rate
static func d_ui_cooldown(unit:Dictionary)->float:
	var ui:=d_ui(unit);return 0.0 if int(ui.charges)>0 and float(ui.intercast)<=0.0 else maxf(float(ui.recharge),float(ui.intercast))
static func heroic_ui_cooldown(unit:Dictionary)->float:
	if str(unit.get("selected_heroic_id",""))=="vitalist_l15_r1" and has_talent(unit,"vitalist_l27_r1"):
		var ui:=r_ui(unit);return 0.0 if int(ui.charges)>0 else float(ui.recharge)
	return float(unit.get("ability_cds",[0,0,0,0])[3])

static func create_q_cast(unit:Dictionary,target_id:String)->Dictionary:
	var cast_id:="%s:q:%d"%[owner_id(unit),int(unit.vitalist_runtime.next_cast_id)];unit.vitalist_runtime.next_cast_id=int(unit.vitalist_runtime.next_cast_id)+1;add(unit,"q_casts")
	var infection:={"owner_id":owner_id(unit),"cast_id":cast_id,"target_id":target_id,"remaining":float(VitalistData.VALUES.q_duration),"age":0.0,"tick":float(VitalistData.VALUES.q_tick),"spread":float(VitalistData.VALUES.q_spread_interval),"spread_counts":{target_id:1},"cast_state":{"one_good":false},"growing":{}}
	unit.vitalist_runtime.q_infections.append(infection);return infection
static func q_count_for(unit:Dictionary,cast_id:String,target_id:String)->int:
	for q in unit.vitalist_runtime.q_infections:
		if str(q.cast_id)==cast_id:return int(q.spread_counts.get(target_id,0))
	return 0
static func can_spread_to(unit:Dictionary,infection:Dictionary,target_id:String,target_inside_arm:bool=false)->bool:
	var limit:=2 if has_talent(unit,"vitalist_l21_2") and target_inside_arm else 999 if has_talent(unit,"vitalist_l24_2") and target_id==owner_id(unit) else 1
	return int(infection.spread_counts.get(target_id,0))<limit
static func spread_q(unit:Dictionary,infection:Dictionary,target_id:String,target_inside_arm:bool=false)->Dictionary:
	if not can_spread_to(unit,infection,target_id,target_inside_arm):return {}
	var prior:=int(infection.spread_counts.get(target_id,0));infection.spread_counts[target_id]=prior+1
	var child:={"owner_id":owner_id(unit),"cast_id":str(infection.cast_id),"target_id":target_id,"remaining":float(VitalistData.VALUES.q_duration),"age":0.0,"tick":float(VitalistData.VALUES.q_tick),"spread":float(VitalistData.VALUES.q_spread_interval),"spread_counts":infection.spread_counts,"cast_state":infection.cast_state,"growing":infection.growing}
	unit.vitalist_runtime.q_infections.append(child);add(unit,"q_spreads");if target_id==owner_id(unit) and has_talent(unit,"vitalist_l24_2"):add(unit,"carrier_spreads");if prior==1:add(unit,"virulent_second")
	var unique:int=infection.spread_counts.keys().size()
	if has_talent(unit,"vitalist_l12_1") and unique>=3 and not bool(infection.cast_state.one_good):infection.cast_state.one_good=true;unit.ability_cds[0]=maxf(0.0,float(unit.ability_cds[0])-float(VitalistData.VALUES.one_good_cdr))
	return child
static func apply_w(unit:Dictionary,target_id:String,qualifies_quest:bool=true,count_cast:bool=true)->Dictionary:
	var infection:={"owner_id":owner_id(unit),"target_id":target_id,"remaining":float(VitalistData.VALUES.w_duration),"age":0.0};unit.vitalist_runtime.w_infections[target_id]=infection;if count_cast:add(unit,"w_casts")
	if count_cast and has_talent(unit,"vitalist_l9_1") and qualifies_quest and not bool(unit.vitalist_runtime.quest.complete):unit.vitalist_runtime.quest.progress=mini(int(VitalistData.VALUES.fetid_quest),int(unit.vitalist_runtime.quest.progress)+1);if int(unit.vitalist_runtime.quest.progress)>=int(VitalistData.VALUES.fetid_quest):unit.vitalist_runtime.quest.complete=true
	return infection
static func w_slow(infection:Dictionary)->float:return lerpf(float(VitalistData.VALUES.w_slow_start),float(VitalistData.VALUES.w_slow_end),clampf(float(infection.age)/float(VitalistData.VALUES.w_duration),0.0,1.0))
static func w_cooldown(unit:Dictionary)->float:return float(VitalistData.VALUES.w_cooldown)-float(VitalistData.VALUES.fetid_cdr) if bool(unit.vitalist_runtime.quest.complete) else float(VitalistData.VALUES.w_cooldown)

static func d_snapshot(unit:Dictionary)->Dictionary:
	return {"q":unit.vitalist_runtime.q_infections.duplicate(),"w":unit.vitalist_runtime.w_infections.values().duplicate()}
static func detonate(unit:Dictionary)->Dictionary:
	if not AbilitySlotSystem.can_activate(unit.vitalist_runtime.d_slot):add(unit,"d_lockout_attempts");return {}
	var snapshot:Dictionary=d_snapshot(unit);var q_count:int=snapshot.q.size();var w_count:int=snapshot.w.size();unit.vitalist_runtime.latest_snapshot={"q":q_count,"w":w_count}
	var targeted:bool=has_talent(unit,"vitalist_l18_3") and q_count==1;unit.vitalist_runtime.d_slot.recharge_duration=float(VitalistData.VALUES.targeted_recharge if targeted else VitalistData.VALUES.d_cooldown)
	if not AbilitySlotSystem.spend(unit.vitalist_runtime.d_slot,float(VitalistData.VALUES.perfect_lockout) if has_talent(unit,"vitalist_l30_3") else 0.0):return {}
	add(unit,"d_casts");add(unit,"d_q_count",q_count);add(unit,"d_w_count",w_count);if targeted:add(unit,"targeted_uses")
	var vigorous:bool=has_talent(unit,"vitalist_l12_3") and q_count>=3;var q_multiplier:float=1.0+(float(VitalistData.VALUES.vigorous_bonus) if vigorous else 0.0)
	if w_count>=2 and has_talent(unit,"vitalist_l18_1"):unit.vitalist_runtime.long_pitch_remaining=float(VitalistData.VALUES.long_pitch_duration);add(unit,"long_pitch_uses")
	var preserve_all:bool=has_talent(unit,"vitalist_l24_3");var preserved:Array=[]
	for q in snapshot.q:
		if targeted:q.remaining=float(VitalistData.VALUES.q_duration)
		if preserve_all:q.remaining=float(q.remaining)+float(VitalistData.VALUES.pox_extension);add(unit,"pox_extensions")
		if targeted or preserve_all:preserved.append(q)
	unit.vitalist_runtime.q_infections=preserved
	unit.vitalist_runtime.w_infections={}
	return {"q":snapshot.q,"w":snapshot.w,"q_multiplier":q_multiplier,"vigorous":vigorous,"targeted":targeted,"poppin":has_talent(unit,"vitalist_l21_3")}

static func begin_arm(unit:Dictionary,position:Vector2)->void:unit.vitalist_runtime.arm={"position":position,"tick":0.0,"contacts":0,"reset":false,"cast_id":int(unit.vitalist_runtime.next_cast_id)};unit.vitalist_runtime.next_cast_id=int(unit.vitalist_runtime.next_cast_id)+1;add(unit,"e_casts")
static func interrupt_arm(unit:Dictionary)->bool:
	if unit.vitalist_runtime.arm.is_empty():return false
	unit.vitalist_runtime.arm={}
	return true
static func note_arm_contacts(unit:Dictionary,count:int)->bool:
	if unit.vitalist_runtime.arm.is_empty():return false
	unit.vitalist_runtime.arm.contacts=int(unit.vitalist_runtime.arm.contacts)+mini(int(VitalistData.VALUES.contact_cap),maxi(0,count))
	if has_talent(unit,"vitalist_l21_1") and int(unit.vitalist_runtime.arm.contacts)>=int(VitalistData.VALUES.it_hungers_contacts) and not bool(unit.vitalist_runtime.arm.reset):unit.vitalist_runtime.arm.reset=true;unit.ability_cds[2]=0.0;return true
	return false
static func grow_q_in_arm(unit:Dictionary,target_id:String)->bool:
	if not has_talent(unit,"vitalist_l18_2") or unit.vitalist_runtime.arm.is_empty():return false
	var cast_key:=str(unit.vitalist_runtime.arm.cast_id);var changed:bool=false
	for q in unit.vitalist_runtime.q_infections:
		if str(q.target_id)==target_id and not bool(q.growing.get(cast_key,false)):q.growing[cast_key]=true;q.remaining=float(q.remaining)+float(VitalistData.VALUES.growing_duration);changed=true;add(unit,"growing_extensions")
	return changed
static func spend_swipe(unit:Dictionary)->bool:
	if has_talent(unit,"vitalist_l27_r1"):return AbilitySlotSystem.spend(unit.vitalist_runtime.r_slot)
	if float(unit.ability_cds[3])>0.0:return false
	unit.ability_cds[3]=float(VitalistData.VALUES.swipe_cooldown);return true
static func begin_swipe(unit:Dictionary)->bool:
	if not spend_swipe(unit):return false
	unit.vitalist_runtime.swipe={"remaining":0.0,"index":2 if has_talent(unit,"vitalist_l27_r1") else 0,"controlled":has_talent(unit,"vitalist_l27_r1")};return true

static func advance(unit:Dictionary,delta:float)->Array:
	var events:Array=[];var rt:Dictionary=unit.vitalist_runtime
	rt.long_pitch_remaining=maxf(0.0,float(rt.long_pitch_remaining)-delta);AbilitySlotSystem.update(rt.d_slot,delta,d_recharge_rate(unit));AbilitySlotSystem.update(rt.r_slot,delta,1.0);unit.ability_cds[4]=d_ui_cooldown(unit)
	for q in rt.q_infections.duplicate():
		q.remaining=float(q.remaining)-delta;q.age=float(q.age)+delta;q.tick=float(q.tick)-delta;q.spread=float(q.spread)-delta
		while float(q.tick)<=0.0 and float(q.remaining)>=0.0:q.tick=float(q.tick)+float(VitalistData.VALUES.q_tick);events.append({"kind":"q_tick","infection":q})
		if float(q.spread)<=0.0 and float(q.remaining)>0.0:q.spread=float(q.spread)+float(VitalistData.VALUES.q_spread_interval);events.append({"kind":"q_spread","infection":q})
		if float(q.remaining)<=0.0:add(unit,"q_lifetime",float(q.age));unit.vitalist_runtime.telemetry.q_longest=maxf(float(unit.vitalist_runtime.telemetry.q_longest),float(q.age))
	rt.q_infections=rt.q_infections.filter(func(q):return float(q.remaining)>0.0)
	for target_id in rt.w_infections.keys():var w:Dictionary=rt.w_infections[target_id];w.remaining=float(w.remaining)-delta;w.age=float(w.age)+delta;if float(w.remaining)<=0.0:events.append({"kind":"w_expire","infection":w});rt.w_infections.erase(target_id)
	if not rt.arm.is_empty():rt.arm.tick=float(rt.arm.tick)-delta;while float(rt.arm.tick)<=0.0:rt.arm.tick=float(rt.arm.tick)+float(VitalistData.VALUES.e_tick);events.append({"kind":"arm_tick"})
	if not rt.swipe.is_empty():
		rt.swipe.remaining=float(rt.swipe.remaining)-delta
		if float(rt.swipe.remaining)<=0.0:
			events.append({"kind":"swipe","index":int(rt.swipe.index)})
			if bool(rt.swipe.controlled) or int(rt.swipe.index)>=2:
				rt.swipe={}
			else:
				rt.swipe.index=int(rt.swipe.index)+1
				rt.swipe.remaining=float(VitalistData.VALUES.swipe_duration)/2.0
	return events
