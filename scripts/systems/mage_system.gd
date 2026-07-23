extends RefCounted

const MageData = preload("res://scripts/data/mage_data.gd")
const AbilityPowerSystem = preload("res://scripts/systems/ability_power_system.gd")
const LivingBombLineageSystem = preload("res://scripts/systems/living_bomb_lineage_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()

static func grants_level_18(unit:Dictionary,id:String)->bool:
	return has_talent(unit,id) or has_talent(unit,"mage_l24_3")

static func default_telemetry()->Dictionary:
	return {"basic_attacks_released":0,"basic_attack_hits":0,"basic_attack_misses":0,"trait_activations":0,"empowerments":{},"invalid_attempts":0,
		"ability_power_current":0.0,"ability_power_sources":{},"ability_power_weighted":0.0,"ability_power_sample_time":0.0,"ability_power_average":0.0,"ability_power_peak":0.0,"time_at_maximum_dynamo":0.0,"sunfire_power_uptime":0.0,
		"armed_time_total":0.0,"normal_recharge_starts":0,"mana_tap_recharge_starts":0,"twin_spheres_charge_uses":0,"empowered_w_during_cooldown":0,
		"q_casts":0,"q_normal_casts":0,"q_empowered_casts":0,"q_hits":0,"q_misses":0,"q_targets_per_resolution":[],"convection_progress":0,"convection_completions":0,"convection_bonus_damage":0.0,"convection_bonus_health":0.0,"w_casts":0,"w_empowered_casts":0,"w_ticks":0,"w_explosions":0,
		"spread_infections":0,"maximum_concurrent_bombs":0,"e_casts":0,"e_hits":0,"stuns_applied":0,"stuns_resisted":0,
		"phoenix_casts":0,"phoenix_hits":0,"phoenix_repositions":0,"pyro_casts":0,"pyro_interrupts":0,"pyro_projectiles_released":0,"pyro_target_invalidations":0,"arcane_barrier_triggers":0,"arcane_barrier_shield_created":0.0,"pyromaniac_reduction":0.0}

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false)->void:
	var charges:=2 if has_talent(unit,"mage_l24_3") else 1
	unit["mage_runtime"]={
		"trait":{"max_charges":charges,"current_charges":charges,"recharge_timers":[],"armed":false,"armed_since":0.0,"armed_duration":0.0},
		"convection_progress":0,"convection_completions":0,"convection_bonus_damage":0.0,"convection_bonus_health":0.0,
		"arcane_barrier_ready_in":0.0,"arcane_dynamo_stacks":0,"arcane_dynamo_remaining":0.0,
		"sunfire_charges":0,"sunfire_sequence_hits":0,"sunfire_sequence_failed":false,"sunfire_power_remaining":0.0,
		"bomb_state":LivingBombLineageSystem.create_state(),"delayed_effects":[],"pyro_projectiles":[],"phoenix":{},
		"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()
	}
	refresh_ability_power(unit)

static func telemetry_add(unit:Dictionary,key:String,value=1)->void:
	var runtime:Dictionary=unit.get("mage_runtime",{})
	if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=runtime.telemetry.get(key,0)+value

static func refresh_ability_power(unit:Dictionary)->float:
	if unit.get("mage_runtime",{}).is_empty():return float(unit.get("ability_power_percent",0.0))
	var sources:Dictionary={}
	var base:=float(unit.get("base_ability_power_percent",unit.get("stats",{}).get("ability_power_percent",0.0)))
	if base!=0.0:sources["base_and_items"]=base
	if has_talent(unit,"mage_l9_2"):sources["fel_infusion"]=0.04
	if float(unit.mage_runtime.arcane_dynamo_remaining)>0.0:sources["arcane_dynamo"]=int(unit.mage_runtime.arcane_dynamo_stacks)*float(MageData.VALUES.arcane_dynamo_per_stack)
	if float(unit.mage_runtime.sunfire_power_remaining)>0.0:sources["sunfire_enchantment"]=0.15
	unit["ability_power_sources"]=sources
	unit["ability_power_percent"]=sources.values().reduce(func(total,value):return float(total)+float(value),0.0)
	if bool(unit.mage_runtime.telemetry_enabled):unit.mage_runtime.telemetry.ability_power_peak=maxf(float(unit.mage_runtime.telemetry.ability_power_peak),float(unit.ability_power_percent))
	return float(unit.ability_power_percent)

static func ability_amount(unit:Dictionary,amount:float)->float:
	refresh_ability_power(unit);return AbilityPowerSystem.apply(amount,unit)

static func scaled_ability_amount(unit:Dictionary,level_one_amount:float,pyroblast:bool=false)->float:
	var level:=int(unit.get("level",1))
	var authored:=MageData.pyro_scaled(level_one_amount,level) if pyroblast else MageData.scaled(level_one_amount,level)
	var expected_power:=maxf(0.001,MageData.scaled(float(MageData.VALUES.basic_attack_damage),level))
	var raw_power_ratio:=maxf(0.0,float(unit.get("power",expected_power)))/expected_power
	return ability_amount(unit,authored*raw_power_ratio)

static func flamestrike_amount(unit:Dictionary)->float:
	var level:=int(unit.get("level",1));var expected_power:=maxf(0.001,MageData.scaled(float(MageData.VALUES.basic_attack_damage),level));var raw_power_ratio:=maxf(0.0,float(unit.get("power",expected_power)))/expected_power
	var pre_ability_power:=MageData.scaled(float(MageData.VALUES.q_damage),level)*raw_power_ratio+float(unit.get("mage_runtime",{}).get("convection_bonus_damage",0.0))
	return ability_amount(unit,pre_ability_power)

static func gravity_crush_applies(source:Dictionary,target:Dictionary,source_action:String,originating_effect_id:String="",origin=null)->bool:
	if source_action=="percentage_health" or originating_effect_id!="" and str(origin)!="Sunfire Enchantment":return false
	if source_action not in ["basic_attack","basic_ability","heroic","periodic"]:return false
	if source_action=="basic_attack" or str(origin)=="Sunfire Enchantment":pass
	elif str(source.get("class",""))!="Mage":return false
	return target.get("active_effects",[]).any(func(effect):return str(effect.get("id",""))=="mage_gravity_crush" and str(effect.get("owner_id",""))==str(source.get("combat_id","")) and float(effect.get("remaining_duration",0.0))>0.0)

static func trait_can_activate(unit:Dictionary)->bool:
	var trait_state:Dictionary=unit.get("mage_runtime",{}).get("trait",{})
	return not trait_state.is_empty() and not bool(trait_state.armed) and int(trait_state.current_charges)>0

static func activate_trait(unit:Dictionary,now:float=0.0)->bool:
	if not trait_can_activate(unit):telemetry_add(unit,"invalid_attempts");return false
	var trait_state:Dictionary=unit.mage_runtime.trait
	trait_state.current_charges=int(trait_state.current_charges)-1;trait_state.armed=true;trait_state.armed_since=now;trait_state.armed_duration=0.0
	if int(trait_state.max_charges)>1:telemetry_add(unit,"twin_spheres_charge_uses")
	if has_talent(unit,"mage_l12_2"):_start_trait_recharge(trait_state);telemetry_add(unit,"mana_tap_recharge_starts")
	if grants_level_18(unit,"mage_l18_3"):
		unit.mage_runtime.sunfire_charges=2;unit.mage_runtime.sunfire_sequence_hits=0;unit.mage_runtime.sunfire_sequence_failed=false
	telemetry_add(unit,"trait_activations");return true

static func _start_trait_recharge(trait_state:Dictionary)->void:
	var missing:=int(trait_state.max_charges)-int(trait_state.current_charges)
	if missing>0 and trait_state.recharge_timers.is_empty():trait_state.recharge_timers.append(float(MageData.VALUES.trait_recharge))

static func consume_empowerment(unit:Dictionary,ability_key:String)->bool:
	var trait_state:Dictionary=unit.get("mage_runtime",{}).get("trait",{})
	if trait_state.is_empty() or not bool(trait_state.armed):return false
	trait_state.armed=false;telemetry_add(unit,"armed_time_total",float(trait_state.get("armed_duration",0.0)));trait_state.armed_duration=0.0
	if not has_talent(unit,"mage_l12_2"):_start_trait_recharge(trait_state);telemetry_add(unit,"normal_recharge_starts")
	if bool(unit.mage_runtime.telemetry_enabled):unit.mage_runtime.telemetry.empowerments[ability_key]=int(unit.mage_runtime.telemetry.empowerments.get(ability_key,0))+1
	return true

static func trait_is_armed(unit:Dictionary)->bool:return bool(unit.get("mage_runtime",{}).get("trait",{}).get("armed",false))

static func commit_basic_ability(unit:Dictionary)->void:
	if not has_talent(unit,"mage_l12_3"):return
	unit.mage_runtime.arcane_dynamo_stacks=mini(int(MageData.VALUES.arcane_dynamo_max),int(unit.mage_runtime.arcane_dynamo_stacks)+1)
	unit.mage_runtime.arcane_dynamo_remaining=float(MageData.VALUES.arcane_dynamo_duration);refresh_ability_power(unit)

static func add_convection_hits(unit:Dictionary,count:int)->Dictionary:
	var result:={"completions":0,"damage_gained":0.0,"health_gained":0.0}
	if not has_talent(unit,"mage_l9_1") or count<=0:return result
	unit.mage_runtime.convection_progress=min(2147483600,int(unit.mage_runtime.convection_progress)+count)
	while int(unit.mage_runtime.convection_progress)>=int(MageData.VALUES.convection_required):
		unit.mage_runtime.convection_progress=int(unit.mage_runtime.convection_progress)-int(MageData.VALUES.convection_required)
		unit.mage_runtime.convection_completions=min(1073741800,int(unit.mage_runtime.convection_completions)+1)
		unit.mage_runtime.convection_bonus_damage+=float(MageData.VALUES.convection_damage);unit.mage_runtime.convection_bonus_health+=float(MageData.VALUES.convection_health)
		unit.max_hp=float(unit.max_hp)+float(MageData.VALUES.convection_health);unit.hp=minf(float(unit.max_hp),float(unit.hp)+float(MageData.VALUES.convection_health))
		result.completions=int(result.completions)+1;result.damage_gained+=float(MageData.VALUES.convection_damage);result.health_gained+=float(MageData.VALUES.convection_health)
	telemetry_add(unit,"convection_progress",count);telemetry_add(unit,"convection_completions",int(result.completions));telemetry_add(unit,"convection_bonus_damage",float(result.damage_gained));telemetry_add(unit,"convection_bonus_health",float(result.health_gained));return result

static func flamestrike_radius(unit:Dictionary,empowered:bool)->float:
	return float(MageData.SPACE.q_empowered_radius if empowered else MageData.SPACE.q_radius)

static func flamestrike_range(unit:Dictionary)->float:
	return float(MageData.SPACE.q_cast_range)*(1.4 if has_talent(unit,"mage_l30_1") else 1.0)

static func bomb_radius(unit:Dictionary)->float:
	return float(MageData.SPACE.w_explosion_radius)*(1.2 if has_talent(unit,"mage_l21_3") else 1.0)

static func gravity_range(unit:Dictionary)->float:
	return float(MageData.SPACE.e_range)*(1.3 if has_talent(unit,"mage_l12_1") else 1.0)

static func burned_flesh_request(target:Dictionary)->Dictionary:
	var is_boss:bool=bool(target.get("boss",false)) or "boss" in target.get("combat_tags",[])
	var fraction:float=float(MageData.VALUES.burned_flesh_boss if is_boss else MageData.VALUES.burned_flesh_normal)
	var basis:float=float(target.get("percent_damage_health_basis",target.get("max_hp",0.0)))
	return {"amount":basis*fraction,"fraction":fraction,"health_basis":basis,"is_boss":is_boss}

static func try_arcane_barrier(unit:Dictionary,would_be_defeated:bool)->Dictionary:
	if not would_be_defeated or not has_talent(unit,"mage_l9_3") or float(unit.mage_runtime.arcane_barrier_ready_in)>0.0:return {"triggered":false,"shield":0.0}
	var shield:float=float(unit.get("max_hp",0.0))*float(MageData.VALUES.arcane_barrier_fraction)
	unit.mage_runtime.arcane_barrier_ready_in=float(MageData.VALUES.arcane_barrier_cooldown);telemetry_add(unit,"arcane_barrier_triggers");telemetry_add(unit,"arcane_barrier_shield_created",shield)
	return {"triggered":true,"shield":shield,"duration":float(MageData.VALUES.arcane_barrier_duration)}

static func sunfire_release(unit:Dictionary,will_hit:bool)->Dictionary:
	if unit.get("mage_runtime",{}).is_empty() or int(unit.mage_runtime.sunfire_charges)<=0:return {"armed":false,"damage":0.0}
	unit.mage_runtime.sunfire_charges=int(unit.mage_runtime.sunfire_charges)-1
	if not will_hit:unit.mage_runtime.sunfire_sequence_failed=true;return {"armed":true,"damage":0.0}
	unit.mage_runtime.sunfire_sequence_hits=int(unit.mage_runtime.sunfire_sequence_hits)+1
	if int(unit.mage_runtime.sunfire_charges)==0 and int(unit.mage_runtime.sunfire_sequence_hits)==2 and not bool(unit.mage_runtime.sunfire_sequence_failed):unit.mage_runtime.sunfire_power_remaining=10.0
	return {"armed":true,"damage":scaled_ability_amount(unit,float(MageData.VALUES.sunfire_damage))}

static func update(unit:Dictionary,delta:float)->void:
	var runtime:Dictionary=unit.mage_runtime;var trait_state:Dictionary=runtime.trait
	if bool(trait_state.armed):trait_state.armed_duration=float(trait_state.get("armed_duration",0.0))+delta
	var recharge_delta:=delta
	while recharge_delta>0.0 and not trait_state.recharge_timers.is_empty():
		var timer_after:=float(trait_state.recharge_timers[0])-recharge_delta
		if timer_after>0.0:trait_state.recharge_timers[0]=timer_after;break
		recharge_delta=-timer_after;trait_state.recharge_timers.remove_at(0);trait_state.current_charges=mini(int(trait_state.max_charges),int(trait_state.current_charges)+1)
		if int(trait_state.current_charges)<int(trait_state.max_charges):trait_state.recharge_timers.append(float(MageData.VALUES.trait_recharge))
	runtime.arcane_barrier_ready_in=maxf(0.0,float(runtime.arcane_barrier_ready_in)-delta)
	runtime.arcane_dynamo_remaining=maxf(0.0,float(runtime.arcane_dynamo_remaining)-delta)
	if float(runtime.arcane_dynamo_remaining)<=0.0:runtime.arcane_dynamo_stacks=0
	runtime.sunfire_power_remaining=maxf(0.0,float(runtime.sunfire_power_remaining)-delta);var current_power:=refresh_ability_power(unit)
	if bool(runtime.telemetry_enabled):
		runtime.telemetry.ability_power_current=current_power;runtime.telemetry.ability_power_sources=AbilityPowerSystem.source_breakdown(unit);runtime.telemetry.ability_power_sample_time=float(runtime.telemetry.ability_power_sample_time)+delta;runtime.telemetry.ability_power_weighted=float(runtime.telemetry.ability_power_weighted)+current_power*delta;runtime.telemetry.ability_power_average=float(runtime.telemetry.ability_power_weighted)/maxf(0.001,float(runtime.telemetry.ability_power_sample_time))
		if int(runtime.arcane_dynamo_stacks)>=int(MageData.VALUES.arcane_dynamo_max):runtime.telemetry.time_at_maximum_dynamo=float(runtime.telemetry.time_at_maximum_dynamo)+delta
		if float(runtime.sunfire_power_remaining)>0.0:runtime.telemetry.sunfire_power_uptime=float(runtime.telemetry.sunfire_power_uptime)+delta

static func clear_temporary_state(unit:Dictionary)->void:
	if unit.get("mage_runtime",{}).is_empty():return
	unit.mage_runtime.trait.armed=false;unit.mage_runtime.sunfire_charges=0;unit.mage_runtime.sunfire_sequence_hits=0;unit.mage_runtime.sunfire_sequence_failed=false

static func slot_state(unit:Dictionary)->Dictionary:
	var trait_state:Dictionary=unit.get("mage_runtime",{}).get("trait",{})
	return {"charges":int(trait_state.get("current_charges",0)),"max_charges":int(trait_state.get("max_charges",1)),"armed":bool(trait_state.get("armed",false)),"recharge":float(trait_state.get("recharge_timers",[0.0])[0]) if not trait_state.get("recharge_timers",[]).is_empty() else 0.0}
