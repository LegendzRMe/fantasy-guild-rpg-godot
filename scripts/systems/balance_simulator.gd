extends RefCounted

const CombatSystem = preload("res://scripts/systems/combat_system.gd")

const EPSILON := 0.00001
const MAX_EVENTS_PER_RUN := 1000000

static func build_supports_scenario(build:Dictionary,scenario:Dictionary)->bool:
	var definition:Dictionary=build.get("class_definition",{})
	var basic_type:String=str(definition.get("basic_action_type","attack"))
	var mode:String=str(scenario.get("mode","damage"))
	if basic_type=="attack" and mode=="damage":return true
	if basic_type=="heal" and mode=="healing":return true
	for action in build.get("actions",[]):
		if str(action.get("result_category","damage"))==mode:return true
	return false

static func simulate_suite(scenarios:Array,builds:Array,iterations:int=100,base_seed:int=1337)->Dictionary:
	var results:Array=[]
	for scenario in scenarios:
		for build in builds:
			if build_supports_scenario(build,scenario):
				results.append(simulate(build,scenario,iterations,base_seed))
	return {
		"schema_version":1,
		"iterations_per_result":maxi(1,iterations),
		"base_seed":base_seed,
		"result_count":results.size(),
		"results":results
	}

static func simulate(build:Dictionary,scenario:Dictionary,iterations:int=100,base_seed:int=1337)->Dictionary:
	var run_results:Array=[]
	var safe_iterations:=maxi(1,iterations)
	for iteration in safe_iterations:
		run_results.append(_simulate_once(build,scenario,base_seed+iteration))
	return _summarize(build,scenario,run_results,safe_iterations,base_seed)

static func _simulate_once(build:Dictionary,scenario:Dictionary,seed:int)->Dictionary:
	var definition:Dictionary=build.get("class_definition",{})
	var equipment:Array=build.get("equipment",[])
	var stats:Dictionary=CombatSystem.calculate_final_stats(definition,int(build.get("level",1)),equipment)
	var source:Dictionary=stats.duplicate(true)
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed
	var duration:=maxf(0.01,float(scenario.get("duration",60.0)))
	var mode:=str(scenario.get("mode","damage"))
	var targets:=_create_targets(scenario)
	var actions:Array=build.get("actions",[]).duplicate(true)
	actions.sort_custom(func(a:Dictionary,b:Dictionary):return int(a.get("priority",100))<int(b.get("priority",100)))
	var ready_times:Array=[]
	for action in actions:ready_times.append(maxf(0.0,float(action.get("initial_delay",0.0))))
	var basic_matches:=_basic_matches_mode(str(stats.get("basic_action_type","attack")),mode)
	var next_basic:=maxf(0.0,float(build.get("basic_action_initial_delay",0.0))) if basic_matches else INF
	var next_action_available:=0.0
	var metrics:=_empty_metrics(duration)
	var now:=0.0
	var event_count:=0
	while now<=duration+EPSILON and event_count<MAX_EVENTS_PER_RUN:
		var next_incoming:=_next_incoming_time(targets) if mode=="healing" else INF
		var next_ability:=_next_ability_time(actions,ready_times,next_action_available,mode,targets)
		var event_time:float=minf(next_basic,minf(next_incoming,next_ability))
		if event_time==INF or event_time>duration+EPSILON:break
		now=event_time
		if next_incoming<=now+EPSILON:
			_apply_due_incoming_damage(targets,now)
		if next_ability<=now+EPSILON:
			var action_index:=_ready_action_index(actions,ready_times,next_action_available,mode,now,targets)
			if action_index>=0:
				_resolve_action(source,targets,actions[action_index],mode,rng,metrics)
				ready_times[action_index]=now+maxf(EPSILON,float(actions[action_index].get("cooldown",1.0)))
				next_action_available=now+maxf(0.0,float(actions[action_index].get("lockout",build.get("global_cooldown",0.0))))
		if next_basic<=now+EPSILON:
			_resolve_basic_action(source,targets,definition,mode,rng,metrics)
			next_basic=now+maxf(0.1,float(stats.get("basic_action_interval",1.25)))
		event_count+=1
		if bool(scenario.get("stop_when_all_targets_defeated",false)) and _all_targets_defeated(targets):
			metrics.time_to_defeat=now
			break
	metrics.event_limit_reached=event_count>=MAX_EVENTS_PER_RUN
	metrics.duration_elapsed=now if metrics.time_to_defeat!=null else duration
	metrics.per_second=float(metrics.effective_output)/maxf(EPSILON,float(metrics.duration_elapsed))
	metrics.raw_per_second=float(metrics.raw_output)/maxf(EPSILON,float(metrics.duration_elapsed))
	return metrics

static func _create_targets(scenario:Dictionary)->Array:
	var targets:Array=[]
	for target_definition in scenario.get("targets",[]):
		var maximum:=maxf(1.0,float(target_definition.get("max_health",1000000000.0)))
		var health:=clampf(float(target_definition.get("initial_health",maximum*float(target_definition.get("initial_health_percent",1.0)))),0.0,maximum)
		targets.append({
			"target_id":str(target_definition.get("target_id","target_%d"%targets.size())),
			"hp":health,"max_hp":maximum,"armor":maxf(0.0,float(target_definition.get("armor",0.0))),
			"shield":0.0,"shield_sources":[],"damage_taken_multiplier":float(target_definition.get("damage_taken_multiplier",1.0)),
			"healing_taken_multiplier":float(target_definition.get("healing_taken_multiplier",1.0)),
			"incoming_damage":maxf(0.0,float(target_definition.get("incoming_damage",0.0))),
			"incoming_interval":maxf(EPSILON,float(target_definition.get("incoming_interval",1.0))),
			"next_incoming":maxf(0.0,float(target_definition.get("incoming_start",0.0)))
		})
	if targets.is_empty():
		targets.append({"target_id":"default_target","hp":1000000000.0,"max_hp":1000000000.0,"armor":0.0,"shield":0.0,"shield_sources":[],"damage_taken_multiplier":1.0,"healing_taken_multiplier":1.0,"incoming_damage":0.0,"incoming_interval":1.0,"next_incoming":INF})
	return targets

static func _empty_metrics(duration:float)->Dictionary:
	return {"duration_requested":duration,"duration_elapsed":duration,"raw_output":0.0,"effective_output":0.0,"wasted_output":0.0,"per_second":0.0,"raw_per_second":0.0,"cast_count":0,"result_count":0,"critical_count":0,"by_action":{},"time_to_defeat":null,"event_limit_reached":false}

static func _basic_matches_mode(basic_type:String,mode:String)->bool:
	return (basic_type=="attack" and mode=="damage") or (basic_type=="heal" and mode=="healing")

static func _next_incoming_time(targets:Array)->float:
	var result:=INF
	for target in targets:
		if float(target.get("incoming_damage",0.0))>0.0:result=minf(result,float(target.get("next_incoming",INF)))
	return result

static func _apply_due_incoming_damage(targets:Array,now:float)->void:
	for target in targets:
		if float(target.get("incoming_damage",0.0))<=0.0:continue
		while float(target.next_incoming)<=now+EPSILON:
			target.hp=maxf(0.0,float(target.hp)-float(target.incoming_damage))
			target.next_incoming=float(target.next_incoming)+float(target.incoming_interval)

static func _next_ability_time(actions:Array,ready_times:Array,next_action_available:float,mode:String,targets:Array)->float:
	if mode=="healing" and not _has_injured_target(targets):return INF
	var result:=INF
	for index in actions.size():
		if str(actions[index].get("result_category","damage"))!=mode:continue
		result=minf(result,maxf(float(ready_times[index]),next_action_available))
	return result

static func _ready_action_index(actions:Array,ready_times:Array,next_action_available:float,mode:String,now:float,targets:Array)->int:
	if next_action_available>now+EPSILON:return -1
	for index in actions.size():
		var action:Dictionary=actions[index]
		if str(action.get("result_category","damage"))!=mode or float(ready_times[index])>now+EPSILON:continue
		if mode=="healing" and not _has_injured_target(targets) and not bool(action.get("allow_overheal_cast",false)):continue
		return index
	return -1

static func _resolve_basic_action(source:Dictionary,targets:Array,definition:Dictionary,mode:String,rng:RandomNumberGenerator,metrics:Dictionary)->void:
	var action_id:=str(definition.get("basic_action_id","basic_action"))
	var action:Dictionary={"action_id":action_id,"display_name":action_id,"result_category":mode,"source_action":"basic_attack" if mode=="damage" else "basic_heal","amount":float(source.get("basic_action_amount",0.0)),"damage_type":str(source.get("basic_action_damage_type","physical")),"max_targets":1}
	_resolve_action(source,targets,action,mode,rng,metrics)

static func _resolve_action(source:Dictionary,targets:Array,action:Dictionary,mode:String,rng:RandomNumberGenerator,metrics:Dictionary)->void:
	var selected_targets:=_select_targets(targets,mode,int(action.get("max_targets",1)))
	if selected_targets.is_empty():return
	var action_id:=str(action.get("action_id","unnamed_action"))
	_record_cast(metrics,action_id)
	var amount:=float(action.get("amount",CombatSystem.calculate_power_scaled_amount(source,float(action.get("power_coefficient",0.0)),float(action.get("flat_bonus",0.0)),float(action.get("percentage_multiplier",1.0)))))
	for target in selected_targets:
		var result:Dictionary
		if mode=="damage":
			result=CombatSystem.resolve_damage(source,target,{"amount":amount,"source_action":str(action.get("source_action","basic_ability")),"damage_type":str(action.get("damage_type","physical")),"can_crit":bool(action.get("can_crit",CombatSystem.default_can_crit(str(action.get("source_action","basic_ability")),"damage",str(action.get("damage_type","physical"))))),"outgoing_multiplier":float(action.get("outgoing_multiplier",source.get("damage_multiplier",1.0)))},rng.randf())
			_record_result(metrics,action_id,float(result.get("raw_amount",0.0)),float(result.get("resolved_damage",0.0)),float(result.get("overkill",0.0)),bool(result.get("critical",false)))
		else:
			result=CombatSystem.resolve_healing(source,target,{"amount":amount,"source_action":str(action.get("source_action","basic_ability")),"can_crit":bool(action.get("can_crit",CombatSystem.default_can_crit(str(action.get("source_action","basic_ability")),"healing"))),"outgoing_multiplier":float(action.get("outgoing_multiplier",source.get("healing_multiplier",1.0)))},rng.randf())
			_record_result(metrics,action_id,float(result.get("amount",0.0)),float(result.get("effective_amount",0.0)),float(result.get("overhealing",0.0)),bool(result.get("critical",false)))

static func _select_targets(targets:Array,mode:String,maximum:int)->Array:
	var candidates:Array=[]
	for target in targets:
		if mode=="damage" and float(target.hp)>0.0:candidates.append(target)
		elif mode=="healing" and float(target.hp)<float(target.max_hp):candidates.append(target)
	if mode=="healing":candidates.sort_custom(func(a:Dictionary,b:Dictionary):return float(a.hp)/float(a.max_hp)<float(b.hp)/float(b.max_hp))
	return candidates.slice(0,mini(maxi(1,maximum),candidates.size()))

static func _has_injured_target(targets:Array)->bool:
	return targets.any(func(target:Dictionary):return float(target.hp)<float(target.max_hp))

static func _all_targets_defeated(targets:Array)->bool:
	return targets.all(func(target:Dictionary):return float(target.hp)<=0.0)

static func _record_result(metrics:Dictionary,action_id:String,raw:float,effective:float,wasted:float,critical:bool)->void:
	metrics.raw_output=float(metrics.raw_output)+raw
	metrics.effective_output=float(metrics.effective_output)+effective
	metrics.wasted_output=float(metrics.wasted_output)+wasted
	metrics.result_count=int(metrics.result_count)+1
	if critical:metrics.critical_count=int(metrics.critical_count)+1
	var breakdown:Dictionary=metrics.by_action[action_id]
	breakdown.raw_output=float(breakdown.raw_output)+raw
	breakdown.effective_output=float(breakdown.effective_output)+effective
	breakdown.wasted_output=float(breakdown.wasted_output)+wasted
	breakdown.result_count=int(breakdown.result_count)+1
	if critical:breakdown.critical_count=int(breakdown.critical_count)+1
	metrics.by_action[action_id]=breakdown

static func _record_cast(metrics:Dictionary,action_id:String)->void:
	metrics.cast_count=int(metrics.cast_count)+1
	if not metrics.by_action.has(action_id):metrics.by_action[action_id]={"raw_output":0.0,"effective_output":0.0,"wasted_output":0.0,"cast_count":0,"result_count":0,"critical_count":0}
	metrics.by_action[action_id].cast_count=int(metrics.by_action[action_id].cast_count)+1

static func _summarize(build:Dictionary,scenario:Dictionary,runs:Array,iterations:int,base_seed:int)->Dictionary:
	var rates:Array=[]
	var raw_rates:Array=[]
	var totals:Array=[]
	var raw_total:=0.0
	var effective_total:=0.0
	var waste_total:=0.0
	var cast_total:=0
	var result_total:=0
	var critical_total:=0
	var breakdown:Dictionary={}
	var limit_reached:=false
	for run in runs:
		rates.append(float(run.per_second));raw_rates.append(float(run.raw_per_second));totals.append(float(run.effective_output))
		raw_total+=float(run.raw_output);effective_total+=float(run.effective_output);waste_total+=float(run.wasted_output)
		cast_total+=int(run.cast_count);result_total+=int(run.result_count);critical_total+=int(run.critical_count);limit_reached=limit_reached or bool(run.event_limit_reached)
		for action_id in run.by_action:
			if not breakdown.has(action_id):breakdown[action_id]={"raw_output":0.0,"effective_output":0.0,"wasted_output":0.0,"cast_count":0,"result_count":0,"critical_count":0}
			for key in breakdown[action_id]:breakdown[action_id][key]=float(breakdown[action_id][key])+float(run.by_action[action_id].get(key,0.0))
	for action_id in breakdown:
		for key in breakdown[action_id]:breakdown[action_id][key]=float(breakdown[action_id][key])/iterations
	return {
		"scenario_id":str(scenario.get("scenario_id","scenario")),"scenario_name":str(scenario.get("display_name",scenario.get("scenario_id","Scenario"))),"mode":str(scenario.get("mode","damage")),"duration":float(scenario.get("duration",60.0)),
		"build_id":str(build.get("build_id","build")),"build_name":str(build.get("display_name",build.get("build_id","Build"))),"class_id":str(build.get("class_id",build.get("class_definition",{}).get("class_id",""))),"level":int(build.get("level",1)),"notes":str(build.get("notes","")),
		"iterations":iterations,"base_seed":base_seed,"mean_per_second":_mean(rates),"raw_mean_per_second":_mean(raw_rates),"standard_deviation":_standard_deviation(rates),"minimum_per_second":_minimum(rates),"maximum_per_second":_maximum(rates),"p10_per_second":_percentile(rates,0.10),"median_per_second":_percentile(rates,0.50),"p90_per_second":_percentile(rates,0.90),
		"mean_raw_output":raw_total/iterations,"mean_effective_output":effective_total/iterations,"mean_wasted_output":waste_total/iterations,"mean_cast_count":float(cast_total)/iterations,"mean_result_count":float(result_total)/iterations,"critical_rate":float(critical_total)/maxf(1.0,float(result_total)),"by_action":breakdown,"event_limit_reached":limit_reached
	}

static func _mean(values:Array)->float:
	if values.is_empty():return 0.0
	var total:=0.0
	for value in values:total+=float(value)
	return total/values.size()

static func _standard_deviation(values:Array)->float:
	if values.size()<2:return 0.0
	var average:=_mean(values);var squares:=0.0
	for value in values:squares+=pow(float(value)-average,2.0)
	return sqrt(squares/values.size())

static func _minimum(values:Array)->float:
	return float(values.min()) if not values.is_empty() else 0.0

static func _maximum(values:Array)->float:
	return float(values.max()) if not values.is_empty() else 0.0

static func _percentile(values:Array,percent:float)->float:
	if values.is_empty():return 0.0
	var sorted:=values.duplicate();sorted.sort()
	var index:=clampi(int(round((sorted.size()-1)*clampf(percent,0.0,1.0))),0,sorted.size()-1)
	return float(sorted[index])
