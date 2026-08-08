extends RefCounted

const RogueData=preload("res://scripts/data/rogue_data.gd")
const ComboPointSystem=preload("res://scripts/systems/combo_point_system.gd")
const AlternateActionSetSystem=preload("res://scripts/systems/alternate_action_set_system.gd")
const StealthDetectionSystem=preload("res://scripts/systems/stealth_detection_system.gd")
const StatusEffectSystem=preload("res://scripts/systems/status_effect_system.gd")
const BlockChargeSystem=preload("res://scripts/systems/block_charge_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func scaled(unit:Dictionary,value:float)->float:return RogueData.scaled(value,int(unit.get("level",1)))*maxf(0.0,float(unit.get("power",RogueData.scaled(RogueData.VALUES.basic_attack_damage,int(unit.get("level",1))))))/maxf(0.001,RogueData.scaled(RogueData.VALUES.basic_attack_damage,int(unit.get("level",1))))
static func default_telemetry()->Dictionary:return {
	"combo_generated":0,"combo_gain_sources":{},"combo_requested":0,"combo_spent":0,"combo_wasted":0,"combo_encounter_resets":0,"combo_defeat_resets":0,"double_strike_attempts":0,"double_strike_successes":0,
	"vanish_casts":0,"vanish_invalid":0,"stealthed_time":0.0,"invisible_time":0.0,"unrevealable_time":0.0,"opener_ready_time":0.0,"reveals":0,"detection_sources":{},"stealth_break_reasons":{},"action_set_swaps":0,"teleport_openers":0,
	"sinister_casts":0,"sinister_hits":0,"sinister_misses":0,"sinister_cooldown_reduction":0.0,"sinister_distance":0.0,"sinister_collisions":0,"blade_casts":0,"blade_hits":0,"eviscerate_casts":0,"eviscerate_damage_by_points":{},"eviscerate_points_used":0,"eviscerate_points_consumed":0,
	"openers":0,"ambush_hits":0,"armor_reduction_applied":0,"cheap_shot_results":{},"garrote_initial_damage":0.0,"garrote_ticks":0,"garrote_refreshes":0,"garrote_expirations":0,"garrote_dispels":0,"smoke_casts":0,"smoke_membership_time":0.0,"smoke_blocked_targets":0,"smoke_area_damage":0.0,"cloak_casts":0,"cloak_dots_removed":0,"cloak_unstoppable_time":0.0,"cloak_armor_prevented":0.0,"cloak_sources":{},
	"combat_readiness_gained":0,"combat_readiness_consumed":0,"combat_readiness_prevented":0.0,"fatal_finesse_progress":0,"slice_attacks":0,"slice_duration":0.0,"death_from_above_reduction":0.0,"strangle_healing_prevented":0.0,"seal_fate_activations":0,"assassinate_results":{},"blade_fury_activations":0,"adrenaline_free_eviscerates":0,"enveloping_auto_cloaks":0,"rupture_refreshes":0,"vigor_maximum":3,"vigor_retained":0
}

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false)->void:
	unit["basic_action_interval"]=float(unit.get("base_basic_action_interval",RogueData.CLASS_DEFINITION.basic_action_interval))
	var maximum:=int(RogueData.VALUES.vigor_combo_max if has_talent(unit,"rogue_l30_3") else RogueData.VALUES.combo_max)
	ComboPointSystem.initialize(unit,maximum);StealthDetectionSystem.initialize(unit)
	AlternateActionSetSystem.initialize(unit,{"normal":{0:"rogue_q",1:"rogue_w",2:"rogue_e"},"stealth":{0:"rogue_stealth_q",1:"rogue_stealth_w",2:"rogue_stealth_e"}},"normal")
	unit["rogue_runtime"]={"vanish_active":false,"vanish_elapsed":0.0,"stationary_elapsed":0.0,"last_position":unit.get("pos",Vector2.ZERO),"opener_ready":false,"initiative_remaining":0.0,"slice_remaining":0.0,"slice_attacks":0,"fatal_finesse_stacks":0,"garrotes":[],"delayed_effects":[],"smoke_clouds":[],"smoke_free_used":{},"block_charges":0,"temporary_armor_sources":[],"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry(),"rng":RandomNumberGenerator.new()}
	BlockChargeSystem.initialize_legacy(unit.rogue_runtime,3)
	unit.rogue_runtime.rng.seed=int(unit.get("combat_id","").hash())

static func telemetry_add(unit:Dictionary,key:String,value=1)->void:
	if unit.get("rogue_runtime",{}).is_empty() or not bool(unit.rogue_runtime.telemetry_enabled):return
	unit.rogue_runtime.telemetry[key]=unit.rogue_runtime.telemetry.get(key,0)+value

static func gain_points(unit:Dictionary,amount:int)->Dictionary:
	var result:=ComboPointSystem.gain(unit,amount);telemetry_add(unit,"combo_requested",amount);telemetry_add(unit,"combo_generated",int(result.gained));telemetry_add(unit,"combo_wasted",int(result.wasted));return result

static func break_vanish(unit:Dictionary)->void:
	if unit.get("rogue_runtime",{}).is_empty():return
	unit.rogue_runtime.vanish_active=false;unit.rogue_runtime.vanish_elapsed=0.0;unit.rogue_runtime.stationary_elapsed=0.0;unit.rogue_runtime.opener_ready=false
	StealthDetectionSystem.set_vanish(unit,false);AlternateActionSetSystem.activate(unit,"normal")

static func activate_vanish(unit:Dictionary)->bool:
	if unit.get("rogue_runtime",{}).is_empty() or float(unit.get("ability_cds",[0,0,0,0,0])[4])>0.0:return false
	unit.rogue_runtime.vanish_active=true;unit.rogue_runtime.vanish_elapsed=0.0;unit.rogue_runtime.stationary_elapsed=0.0;unit.rogue_runtime.last_position=unit.get("pos",Vector2.ZERO);unit.rogue_runtime.opener_ready=false
	StealthDetectionSystem.set_vanish(unit,true);unit.concealment.unrevealable_remaining=float(RogueData.VALUES.vanish_unrevealable);unit.concealment.unit_passing=true
	AlternateActionSetSystem.activate(unit,"stealth");unit.ability_cds[4]=float(RogueData.VALUES.vanish_cooldown);telemetry_add(unit,"vanish_casts");return true

static func opener_points(unit:Dictionary)->int:return 2 if has_talent(unit,"rogue_l12_3") else 1
static func opener_range(unit:Dictionary)->float:return float(RogueData.SPACE.opener_range)*(2.0 if bool(unit.get("rogue_runtime",{}).get("opener_ready",false)) else 1.0)

static func note_opener(unit:Dictionary)->void:
	gain_points(unit,opener_points(unit));telemetry_add(unit,"openers")
	if has_talent(unit,"rogue_l12_3"):unit.rogue_runtime.initiative_remaining=float(RogueData.VALUES.initiative_duration)
	break_vanish(unit)

static func apply_cloak(unit:Dictionary,source_id:String)->void:
	for index in range(unit.get("bloodletting_stacks",[]).size()-1,-1,-1):unit.bloodletting_stacks.remove_at(index)
	unit.active_effects=unit.get("active_effects",[]).filter(func(effect):return bool(effect.get("beneficial",false)) or not bool(effect.get("damage_over_time",false)))
	StatusEffectSystem.apply_unstoppable(unit,float(RogueData.VALUES.cloak_duration))
	var armor:=scaled(unit,float(RogueData.VALUES.cloak_armor));var sources:Array=unit.rogue_runtime.temporary_armor_sources
	for index in sources.size():
		if str(sources[index].get("id",""))==source_id:sources[index]={"id":source_id,"armor":armor,"remaining":float(RogueData.VALUES.cloak_duration)};return
	sources.append({"id":source_id,"armor":armor,"remaining":float(RogueData.VALUES.cloak_duration)})

static func double_strike_roll(unit:Dictionary,roll:float=-1.0)->Dictionary:
	if not has_talent(unit,"rogue_l9_3") or ComboPointSystem.current(unit)>=ComboPointSystem.maximum(unit):return {"attempted":false,"success":false}
	telemetry_add(unit,"double_strike_attempts");var resolved:float=float(unit.rogue_runtime.rng.randf()) if roll<0.0 else roll;var success:bool=resolved<float(RogueData.VALUES.double_strike_chance)
	if success:gain_points(unit,1);telemetry_add(unit,"double_strike_successes")
	return {"attempted":true,"success":success,"roll":resolved}

static func update(unit:Dictionary,delta:float)->void:
	var runtime:Dictionary=unit.get("rogue_runtime",{});if runtime.is_empty():return
	unit.basic_action_interval=attack_interval(unit)
	AlternateActionSetSystem.update_hidden_cooldowns(unit,delta);runtime.initiative_remaining=maxf(0.0,float(runtime.initiative_remaining)-delta);runtime.slice_remaining=maxf(0.0,float(runtime.slice_remaining)-delta)
	if float(runtime.slice_remaining)<=0.0:runtime.slice_attacks=0
	for source in runtime.temporary_armor_sources:source.remaining=maxf(0.0,float(source.remaining)-delta)
	runtime.temporary_armor_sources=runtime.temporary_armor_sources.filter(func(source):return float(source.remaining)>0.0)
	var moved:=Vector2(unit.get("pos",Vector2.ZERO)).distance_to(Vector2(runtime.last_position))>0.5;runtime.last_position=unit.get("pos",Vector2.ZERO)
	StealthDetectionSystem.update(unit,delta,moved)
	if bool(runtime.vanish_active):
		runtime.vanish_elapsed=float(runtime.vanish_elapsed)+delta;runtime.stationary_elapsed=0.0 if moved else float(runtime.stationary_elapsed)+delta
		telemetry_add(unit,"stealthed_time",delta)
		unit.concealment.invisible=float(runtime.stationary_elapsed)>=float(RogueData.VALUES.vanish_invisible_stationary)
		if bool(unit.concealment.invisible):telemetry_add(unit,"invisible_time",delta)
		if float(unit.concealment.unrevealable_remaining)>0.0:telemetry_add(unit,"unrevealable_time",delta)
		unit.concealment.unit_passing=float(unit.concealment.unrevealable_remaining)>0.0
		var ready_time:=1.5 if has_talent(unit,"rogue_l9_2") else float(RogueData.VALUES.vanish_teleport_ready);runtime.opener_ready=float(runtime.vanish_elapsed)>=ready_time;if bool(runtime.opener_ready):telemetry_add(unit,"opener_ready_time",delta)

static func movement_multiplier(unit:Dictionary)->float:
	var result:=1.0
	if bool(unit.get("rogue_runtime",{}).get("vanish_active",false)):result+=0.40 if has_talent(unit,"rogue_l30_2") else 0.20
	if float(unit.get("rogue_runtime",{}).get("initiative_remaining",0.0))>0.0:result+=float(RogueData.VALUES.initiative_speed)
	return result

static func attack_interval(unit:Dictionary)->float:
	return float(unit.get("base_basic_action_interval",0.5))/float(RogueData.VALUES.slice_speed_multiplier) if int(unit.get("rogue_runtime",{}).get("slice_attacks",0))>0 and float(unit.rogue_runtime.slice_remaining)>0.0 else float(unit.get("base_basic_action_interval",0.5))

static func consume_slice_attack(unit:Dictionary)->void:
	if int(unit.get("rogue_runtime",{}).get("slice_attacks",0))>0:unit.rogue_runtime.slice_attacks=int(unit.rogue_runtime.slice_attacks)-1

static func reset_encounter(unit:Dictionary)->void:
	ComboPointSystem.reset(unit);if not unit.get("rogue_runtime",{}).is_empty():unit.rogue_runtime.fatal_finesse_stacks=0;unit.rogue_runtime.garrotes=[];unit.rogue_runtime.smoke_clouds=[];break_vanish(unit)
