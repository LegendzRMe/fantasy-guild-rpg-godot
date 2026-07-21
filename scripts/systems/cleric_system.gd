extends RefCounted

const ClericData = preload("res://scripts/data/cleric_data.gd")

static func has_talent(hero:Dictionary,talent_id:String)->bool:
	return talent_id in hero.get("selected_talents", {}).values()

static func initialize_runtime(hero:Dictionary,telemetry_enabled:bool=false)->void:
	var telemetry:Dictionary={}
	for key in ["offensive_basic_attacks","offensive_basic_attack_hits","blind_misses","basic_heals","basic_heal_effective","basic_heal_overhealing","fast_feet_triggers","fast_feet_uptime","fast_feet_rate_total","q_casts","q_failed","q_effective_healing","q_overhealing","free_drinks_reductions","pick_me_up_activations","w_casts","serpent_attacks","serpent_damage","serpent_healing","serpent_no_target","serpent_bounces","e_casts","e_hits","blind_applications","blind_resistance","surging_winds_activations","mass_vortex_activations","jug_ticks","jug_healing","water_dragon_casts","water_dragon_impacts","mistweaver_activations","mistweaver_reductions","shake_it_off_armor_activations","kung_fu_hustle_seconds_saved"]:telemetry[key]=0.0
	hero["cleric_runtime"] = {
		"fast_feet_remaining":0.0, "fast_feet_active_bonus":false,
		"spell_power_remaining":0.0, "trait_cooldown":0.0,
		"serpents":[], "periodic_heals":[], "delayed_effects":[],
		"jug_active":false, "jug_remaining":0.0, "jug_tick_timer":0.0, "jug_completed_ticks":0,
		"mistweaver_ready_in":0.0, "telemetry_enabled":telemetry_enabled,
		"telemetry":telemetry
	}
	if has_talent(hero, "cleric_l30_2"):
		hero.cleric_runtime["w_charges"] = 2
		hero.cleric_runtime["w_recharge_timers"] = []

static func telemetry_add(hero:Dictionary,key:String,amount:float=1.0)->void:
	if hero.get("cleric_runtime", {}).is_empty() or not bool(hero.cleric_runtime.get("telemetry_enabled", false)):
		return
	hero.cleric_runtime.telemetry[key] = float(hero.cleric_runtime.telemetry.get(key, 0.0)) + amount

static func trigger_fast_feet(hero:Dictionary,duration_override:float=-1.0,active_bonus:bool=false)->void:
	var duration := duration_override if duration_override >= 0.0 else (2.5 if has_talent(hero, "cleric_l9_3") else float(ClericData.VALUES.fast_feet_duration))
	hero.cleric_runtime.fast_feet_remaining = maxf(float(hero.cleric_runtime.fast_feet_remaining), duration)
	hero.cleric_runtime.fast_feet_active_bonus = bool(hero.cleric_runtime.fast_feet_active_bonus) or active_bonus
	telemetry_add(hero,"fast_feet_triggers")

static func note_hostile_damage(hero:Dictionary,resolved_damage:float)->void:
	if resolved_damage > 0.0:
		trigger_fast_feet(hero)

static func fast_feet_active(hero:Dictionary)->bool:
	return float(hero.get("cleric_runtime", {}).get("fast_feet_remaining", 0.0)) > 0.0

static func movement_multiplier(hero:Dictionary)->float:
	if not fast_feet_active(hero):
		return 1.0
	return 1.30 if bool(hero.cleric_runtime.get("fast_feet_active_bonus", false)) else 1.10

static func qwe_cooldown_rate(hero:Dictionary)->float:
	if not fast_feet_active(hero):
		return 1.0
	if has_talent(hero, "cleric_l30_3"):
		return 3.0
	return 1.5

static func w_cooldown_rate(hero:Dictionary)->float:
	var rate := qwe_cooldown_rate(hero)
	if fast_feet_active(hero) and has_talent(hero, "cleric_l9_2"):
		rate += 0.75
	return rate

static func spell_power_multiplier(hero:Dictionary)->float:
	return 1.10 if float(hero.get("cleric_runtime", {}).get("spell_power_remaining", 0.0)) > 0.0 else 1.0

static func scaled_amount(hero:Dictionary,level_one_amount:float)->float:
	var level_one_power := float(ClericData.CLASS_DEFINITION.base_power)
	return maxf(0.0, float(hero.get("power", 0.0)) * level_one_amount / level_one_power * spell_power_multiplier(hero))

static func lowest_wounded_indices(allies:Array,limit:int=1,range_origin:Vector2=Vector2.ZERO,range_limit:float=INF,wounded_only:bool=true)->Array:
	var candidates:Array = []
	for index in allies.size():
		var ally:Dictionary = allies[index]
		if float(ally.get("hp", 0.0)) <= 0.0 or wounded_only and float(ally.get("hp", 0.0)) >= float(ally.get("max_hp", 0.0)):
			continue
		if range_limit < INF and range_origin.distance_to(ally.get("pos", range_origin)) > range_limit:
			continue
		candidates.append({"index":index, "ratio":float(ally.hp) / maxf(1.0, float(ally.max_hp)), "distance":range_origin.distance_to(ally.get("pos", range_origin)), "combat_id":str(ally.get("combat_id", index))})
	candidates.sort_custom(func(a,b):
		if not is_equal_approx(float(a.ratio), float(b.ratio)): return float(a.ratio) < float(b.ratio)
		if not is_equal_approx(float(a.distance), float(b.distance)): return float(a.distance) < float(b.distance)
		return str(a.combat_id) < str(b.combat_id))
	return candidates.slice(0, mini(limit, candidates.size())).map(func(entry): return int(entry.index))

static func nearest_enemy_indices(origin:Vector2,enemies:Array,limit:int)->Array:
	var candidates:Array=[]
	for index in enemies.size():
		if float(enemies[index].get("hp",0.0))>0.0:
			candidates.append({"index":index,"distance":origin.distance_to(enemies[index].get("pos",origin)),"combat_id":str(enemies[index].get("combat_id",index))})
	candidates.sort_custom(func(a,b):
		if not is_equal_approx(float(a.distance),float(b.distance)):return float(a.distance)<float(b.distance)
		return str(a.combat_id)<str(b.combat_id))
	return candidates.slice(0,mini(limit,candidates.size())).map(func(entry):return int(entry.index))

static func update_timers(hero:Dictionary,delta:float)->Dictionary:
	var runtime:Dictionary=hero.cleric_runtime
	var result:={"qwe_rate":qwe_cooldown_rate(hero),"w_rate":w_cooldown_rate(hero)}
	if fast_feet_active(hero):telemetry_add(hero,"fast_feet_uptime",delta);telemetry_add(hero,"fast_feet_rate_total",qwe_cooldown_rate(hero)*delta)
	runtime.fast_feet_remaining=maxf(0.0,float(runtime.fast_feet_remaining)-delta)
	if runtime.fast_feet_remaining<=0.0:runtime.fast_feet_active_bonus=false
	runtime.spell_power_remaining=maxf(0.0,float(runtime.spell_power_remaining)-delta)
	var trait_rate:=1.5 if fast_feet_active(hero) and has_talent(hero,"cleric_l12_3") else 1.0
	runtime.trait_cooldown=maxf(0.0,float(runtime.trait_cooldown)-delta*trait_rate)
	if hero.get("ability_cds",[]).size()>4:hero.ability_cds[4]=float(runtime.trait_cooldown)
	if has_talent(hero,"cleric_l30_1"):runtime.mistweaver_ready_in=maxf(0.0,float(runtime.mistweaver_ready_in)-delta)
	if has_talent(hero,"cleric_l30_2"):
		for timer_index in range(runtime.w_recharge_timers.size()-1,-1,-1):
			runtime.w_recharge_timers[timer_index]=float(runtime.w_recharge_timers[timer_index])-delta*w_cooldown_rate(hero)
			if runtime.w_recharge_timers[timer_index]<=0.0:runtime.w_recharge_timers.remove_at(timer_index);runtime.w_charges=mini(2,int(runtime.w_charges)+1)
		hero.ability_cds[1]=0.0 if int(runtime.w_charges)>0 else (float(runtime.w_recharge_timers.min()) if not runtime.w_recharge_timers.is_empty() else 0.0)
	return result

static func activate_safety_sprint(hero:Dictionary)->bool:
	if not has_talent(hero,"cleric_l12_2") or float(hero.cleric_runtime.trait_cooldown)>0.0:return false
	trigger_fast_feet(hero,3.0,true);hero.cleric_runtime.trait_cooldown=30.0
	if hero.get("ability_cds",[]).size()>4:hero.ability_cds[4]=30.0
	return true

static func active_armor(hero:Dictionary)->float:
	var strongest:=0.0
	if fast_feet_active(hero) and has_talent(hero,"cleric_l12_2"):strongest=30.0 if bool(hero.cleric_runtime.get("fast_feet_active_bonus",false)) else 10.0
	if hero.get("active_effects",[]).any(func(effect):return str(effect.get("id",""))=="shake_it_off_armor" and float(effect.get("remaining_duration",0.0))>0.0):strongest=maxf(strongest,35.0)
	return strongest

static func begin_jug(hero:Dictionary)->void:
	hero.cleric_runtime.jug_active=true
	hero.cleric_runtime.jug_remaining=float(ClericData.VALUES.r1_duration)
	hero.cleric_runtime.jug_tick_timer=0.0
	hero.cleric_runtime.jug_completed_ticks=0

static func stop_jug(hero:Dictionary)->float:
	var cooldown:=minf(70.0,float(ClericData.VALUES.r1_base_cooldown)+2.0*int(hero.cleric_runtime.jug_completed_ticks))
	hero.cleric_runtime.jug_active=false
	hero.cleric_runtime.jug_remaining=0.0
	return cooldown

static func reduce_mistweaver(hero:Dictionary,amount:float)->void:
	if has_talent(hero,"cleric_l30_1"):
		hero.cleric_runtime.mistweaver_ready_in=maxf(0.0,float(hero.cleric_runtime.mistweaver_ready_in)-amount)
