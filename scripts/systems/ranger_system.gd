extends RefCounted

const RangerData = preload("res://scripts/data/ranger_data.gd")
const AbilitySlotSystem = preload("res://scripts/systems/ability_slot_system.gd")
const PercentageHealthDamageSystem = preload("res://scripts/systems/percentage_health_damage_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false)->void:
	var rain:=AbilitySlotSystem.create(int(RangerData.VALUES.r2_charges),float(RangerData.VALUES.r2_recharge),AbilitySlotSystem.RechargeMode.SEQUENTIAL)
	var vault_charges:=3 if has_talent(unit,"ranger_l30_1") else 1
	var vault:=AbilitySlotSystem.create(vault_charges,5.0 if has_talent(unit,"ranger_l12_2") else float(RangerData.VALUES.e_cooldown),AbilitySlotSystem.RechargeMode.SEQUENTIAL)
	unit["ranger_runtime"]={
		"hatred":0,"hatred_remaining":0.0,"q_encounter_bonus":0.0,"w_encounter_bonus":0.0,"w_quest_hits":0,"w_quest_rewarded":false,
		"basic_attack_quest":0,"creed_bonus":0.0,"vault_empower_remaining":0.0,"vault_hatred_snapshot":0,
		"executioner_remaining":0.0,"manticore_target":"","manticore_count":0,"gloom_remaining":0.0,
		"strafe_remaining":0.0,"strafe_tick":0.0,"strafe_locks":{},"strafe_extension":0.0,"piercing_tick":0.0,
		"delayed_effects":[],"caltrops":[],"slots":{"e":vault,"r":rain},
		"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()
	}
	refresh_derived_stats(unit)

static func default_telemetry()->Dictionary:
	return {"basic_attacks":0,"hatred_gained":0,"hatred_expired":0,"hatred_peak":0,"q_casts":0,"q_hits":0,"q_seeks":0,"w_casts":0,"w_hits":0,"vault_casts":0,"vault_resets":0,"strafe_shots":0,"rain_casts":0,"rain_hits":0,"quest_progress":{},"healing":0.0,"manticore_procs":0,"percentage_damage":0.0,"slot_recharge_reduced":0.0}

static func telemetry_add(unit:Dictionary,key:String,value=1)->void:
	var runtime:Dictionary=unit.get("ranger_runtime",{})
	if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=runtime.telemetry.get(key,0)+value

static func add_hatred(unit:Dictionary,amount:int)->void:
	var runtime:Dictionary=unit.ranger_runtime
	var before:=int(runtime.hatred);runtime.hatred=mini(int(RangerData.VALUES.hatred_max),before+maxi(0,amount));runtime.hatred_remaining=float(RangerData.VALUES.hatred_duration)
	telemetry_add(unit,"hatred_gained",int(runtime.hatred)-before);runtime.telemetry.hatred_peak=maxi(int(runtime.telemetry.get("hatred_peak",0)),int(runtime.hatred))
	refresh_derived_stats(unit)

static func hatred_damage_per_stack(unit:Dictionary)->float:return float(RangerData.VALUES.hatred_damage_per_stack)+float(unit.ranger_runtime.get("creed_bonus",0.0))
static func hatred_move_per_stack(unit:Dictionary)->float:return 0.02 if has_talent(unit,"ranger_l18_3") else float(RangerData.VALUES.hatred_move_per_stack)

static func refresh_derived_stats(unit:Dictionary)->void:
	if unit.get("ranger_runtime",{}).is_empty():return
	var stacks:=int(unit.ranger_runtime.hatred)
	unit["ranger_movement_multiplier"]=1.0+stacks*hatred_move_per_stack(unit)
	var range_multiplier:=1.0
	if has_talent(unit,"ranger_l30_2"):range_multiplier=1.5 if stacks>=int(RangerData.VALUES.hatred_max) else 1.2
	unit.range=float(RangerData.SPACE.basic_range)*range_multiplier
	var speed_bonus:=0.0
	if has_talent(unit,"ranger_l27_r2"):speed_bonus=stacks*0.02+(0.30 if stacks>=int(RangerData.VALUES.hatred_max) else 0.0)
	unit.basic_attack_interval=float(unit.get("base_basic_action_interval",1.0))/maxf(0.1,1.0+speed_bonus)

static func qualifying_target(target:Dictionary)->bool:return target.get("hp",0.0)>0.0 and "training" not in target.get("combat_tags",[]) and "non_qualifying" not in target.get("combat_tags",[]) and not bool(target.get("object",false))
static func controlled(target:Dictionary)->bool:return target.get("active_effects",[]).any(func(effect):return str(effect.get("control_type","")) in ["stun","root","slow"] and float(effect.get("remaining_duration",0.0))>0.0)

static func basic_attack_multiplier(unit:Dictionary,target:Dictionary)->float:
	var multiplier:=1.0+int(unit.ranger_runtime.hatred)*hatred_damage_per_stack(unit)
	if float(unit.ranger_runtime.executioner_remaining)>0.0:multiplier*=1.15
	if int(unit.ranger_runtime.hatred)>=int(RangerData.VALUES.hatred_max) and has_talent(unit,"ranger_l24_2"):multiplier*=1.10
	if float(unit.ranger_runtime.vault_empower_remaining)>0.0:
		var per_stack:=0.15 if has_talent(unit,"ranger_l12_2") else float(RangerData.VALUES.e_bonus_per_hatred)
		multiplier*=1.0+int(unit.ranger_runtime.vault_hatred_snapshot)*per_stack
	return multiplier

static func on_basic_attack_released(unit:Dictionary,target:Dictionary)->Dictionary:
	telemetry_add(unit,"basic_attacks")
	if controlled(target) and has_talent(unit,"ranger_l30_3"):unit.ranger_runtime.executioner_remaining=3.0
	var target_id:=str(target.get("combat_id",""))
	if unit.ranger_runtime.manticore_target!=target_id:unit.ranger_runtime.manticore_target=target_id;unit.ranger_runtime.manticore_count=0
	unit.ranger_runtime.manticore_count=int(unit.ranger_runtime.manticore_count)+1
	var percent_request:={}
	if has_talent(unit,"ranger_l24_3") and int(unit.ranger_runtime.manticore_count)>=3:
		unit.ranger_runtime.manticore_count=0;percent_request=PercentageHealthDamageSystem.request(unit,target,0.04,0.01,"Manticore");telemetry_add(unit,"manticore_procs")
	var empowered:=float(unit.ranger_runtime.vault_empower_remaining)>0.0
	return {"multiplier":basic_attack_multiplier(unit,target),"percent_request":percent_request,"empowered":empowered}

static func on_basic_attack_resolved(unit:Dictionary,result:Dictionary,target_defeated:bool,empowered:bool)->void:
	if float(result.get("resolved_damage",0.0))<=0.0:return
	add_hatred(unit,1)
	unit.ranger_runtime.basic_attack_quest=int(unit.ranger_runtime.basic_attack_quest)+1
	if has_talent(unit,"ranger_l9_3"):
		unit.ranger_runtime.creed_bonus=minf(0.06,floori(int(unit.ranger_runtime.basic_attack_quest)/50.0)*0.01)
	if has_talent(unit,"ranger_l27_r2"):telemetry_add(unit,"slot_recharge_reduced",AbilitySlotSystem.reduce_active_recharge(unit.ranger_runtime.slots.r,5.0))
	if empowered:
		unit.ranger_runtime.vault_empower_remaining=0.0
		if target_defeated and has_talent(unit,"ranger_l12_2"):
			var slot:Dictionary=unit.ranger_runtime.slots.e
			if int(slot.current_charges)<int(slot.max_charges):slot.current_charges=int(slot.current_charges)+1;if not slot.timers.is_empty():slot.timers.remove_at(0)
			telemetry_add(unit,"vault_resets")

static func trait_armor(unit:Dictionary)->float:
	if not has_talent(unit,"ranger_l21_3"):return 0.0
	return 15.0+(3.0*int(unit.ranger_runtime.hatred) if float(unit.ranger_runtime.gloom_remaining)>0.0 else 0.0)

static func activate_gloom(unit:Dictionary)->bool:
	if not has_talent(unit,"ranger_l21_3") or float(unit.ability_cds[4])>0.0:return false
	unit.ranger_runtime.gloom_remaining=5.0;unit.ranger_runtime.hatred=0;unit.ranger_runtime.hatred_remaining=0.0;unit.ability_cds[4]=5.0;refresh_derived_stats(unit);return true

static func update(unit:Dictionary,delta:float)->Dictionary:
	var runtime:Dictionary=unit.ranger_runtime;var result:={"gloom_heal":0.0}
	if float(runtime.strafe_remaining)<=0.0 and int(runtime.hatred)>0:
		runtime.hatred_remaining=maxf(0.0,float(runtime.hatred_remaining)-delta)
		if runtime.hatred_remaining<=0.0:telemetry_add(unit,"hatred_expired",int(runtime.hatred));runtime.hatred=0
	runtime.executioner_remaining=maxf(0.0,float(runtime.executioner_remaining)-delta);runtime.vault_empower_remaining=maxf(0.0,float(runtime.vault_empower_remaining)-delta);runtime.gloom_remaining=maxf(0.0,float(runtime.gloom_remaining)-delta)
	var w_rate:=1.5 if has_talent(unit,"ranger_l24_1") and int(runtime.hatred)>=int(RangerData.VALUES.hatred_max) else 1.0
	AbilitySlotSystem.update(runtime.slots.e,delta);AbilitySlotSystem.update(runtime.slots.r,delta)
	if has_talent(unit,"ranger_l21_3"):result.gloom_heal=RangerData.scaled(1.25,int(unit.get("level",1)))*int(runtime.hatred)*delta
	refresh_derived_stats(unit);return result

