extends RefCounted

const ProtectorData=preload("res://scripts/data/protector_data.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")
const CombatGeometry=preload("res://scripts/combat/combat_geometry.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func ability_amount(unit:Dictionary,value:float)->float:
	var expected:=maxf(0.001,ProtectorData.scaled(float(ProtectorData.VALUES.basic_attack_damage),int(unit.get("level",1))))
	return ProtectorData.scaled(value,int(unit.get("level",1)))*maxf(0.0,float(unit.get("power",expected)))/expected

static func default_telemetry()->Dictionary:
	var result:Dictionary={}
	for key in ["basic_hits","basic_attack_damage","basic_attack_threat","damage_taken","deaths","time_alive","aggro_target_changes","q_throws","q_hits","q_teleports","q_knockbacks","q_displacement_resisted","q_rebuke_stuns","q_reforging_reduction","q_wall_crossings","q_piercing_activations","walls_cast","wall_active_seconds","wall_path_encounters","wall_crossing_attacks","restraining_uptime","force_barrier_casts","smite_casts","smite_hits","smite_allies_buffed","smite_self_buff_seconds","radiant_reach_seconds","purge_resets","purged_threat","law_duplicate_casts","law_overlap_dedupes","smite_charge_uses","judgment_casts","judgment_hits","judgment_displacements","sanctification_casts","sanctification_allies_protected","wrath_activations","aspect_activations","wrath_enemy_seconds","wrath_hits","wrath_damage_prevented","burning_damage"]:result[key]=0.0
	return result

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false)->void:
	unit["protector_runtime"]={"q_sequence":{},"walls":[],"smite_fields":[],"judgment":{},"sanctification_fields":[],"wrath":{},"wrath_resolved":false,"aspect_cooldown":0.0,"pursuit_remaining":0.0,"stalwart_remaining":0.0,"wicked_remaining":0.0,"burning_tick":0.0,"burning_empowered_remaining":0.0,"cast_counter":0,"last_purge":{},"smite_slot":AbilitySlotSystem.create(2 if has_talent(unit,"protector_l30_3") else 1,float(ProtectorData.VALUES.e_cooldown),AbilitySlotSystem.RechargeMode.SEQUENTIAL),"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()}

static func telemetry_add(unit:Dictionary,key:String,value=1)->void:
	var runtime:Dictionary=unit.get("protector_runtime",{});if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=runtime.telemetry.get(key,0)+value

static func next_cast_id(unit:Dictionary,prefix:String)->String:
	unit.protector_runtime.cast_counter=int(unit.protector_runtime.cast_counter)+1
	return "%s:%s:%d"%[prefix,str(unit.get("combat_id","protector")),int(unit.protector_runtime.cast_counter)]

static func wall_cooldown(unit:Dictionary)->float:return maxf(0.0,float(ProtectorData.VALUES.w_cooldown)-(float(ProtectorData.VALUES.force_barrier_reduction) if has_talent(unit,"protector_l30_2") else 0.0))
static func wall_duration(unit:Dictionary)->float:return float(ProtectorData.VALUES.w_duration)+(float(ProtectorData.VALUES.force_barrier_duration) if has_talent(unit,"protector_l30_2") else 0.0)
static func wall_range(unit:Dictionary)->float:return float(ProtectorData.SPACE.w_range)*(1.0+float(ProtectorData.VALUES.force_barrier_range) if has_talent(unit,"protector_l30_2") else 1.0)
static func smite_duration(unit:Dictionary)->float:return float(ProtectorData.VALUES.e_field_duration)+(float(ProtectorData.VALUES.e_radiant_bonus) if has_talent(unit,"protector_l9_3") else 0.0)
static func smite_buff_duration(unit:Dictionary)->float:return float(ProtectorData.VALUES.e_speed_duration)+(float(ProtectorData.VALUES.e_radiant_buff_bonus) if has_talent(unit,"protector_l9_3") else 0.0)
static func judgment_range(unit:Dictionary)->float:return float(ProtectorData.SPACE.r1_range)*(1.0+float(ProtectorData.VALUES.r1_upgrade_range) if has_talent(unit,"protector_l27_r1") else 1.0)
static func judgment_cooldown(unit:Dictionary)->float:return maxf(1.0,float(ProtectorData.VALUES.r1_cooldown)-(float(ProtectorData.VALUES.r1_upgrade_reduction) if has_talent(unit,"protector_l27_r1") else 0.0))
static func sanctification_duration(unit:Dictionary)->float:return float(ProtectorData.VALUES.r2_duration)+(float(ProtectorData.VALUES.r2_upgrade_duration) if has_talent(unit,"protector_l27_r2") else 0.0)

static func own_wall(unit:Dictionary,blocker:Dictionary)->bool:return str(blocker.get("owner_combat_id",""))==str(unit.get("combat_id","")) and str(blocker.get("shape",""))=="segment"
static func crosses_own_wall(unit:Dictionary,from:Vector2,to:Vector2,blockers:Array)->bool:
	for blocker in blockers:
		if own_wall(unit,blocker) and CombatGeometry.blocker_active(blocker) and CombatGeometry.blocker_intersects_segment(blocker,from,to):return true
	return false
static func intersecting_own_wall(unit:Dictionary,from:Vector2,to:Vector2,blockers:Array):
	for blocker in blockers:
		if own_wall(unit,blocker) and CombatGeometry.blocker_active(blocker) and CombatGeometry.blocker_intersects_segment(blocker,from,to):return blocker
	return null

static func clear_highest_other_ally_threat(enemy:Dictionary,protector_index:int,living_ally_indices:Array)->Dictionary:
	var chosen:=-1;var highest:=0.0
	for ally_index_value in living_ally_indices:
		var ally_index:=int(ally_index_value);if ally_index==protector_index:continue
		var amount:=float(enemy.get("threat",{}).get(ally_index,0.0))
		if amount>highest or is_equal_approx(amount,highest) and amount>0.0 and (chosen<0 or ally_index<chosen):chosen=ally_index;highest=amount
	if chosen<0:return {"cleared":false,"hero_index":-1,"amount":0.0}
	enemy.threat[chosen]=0.0;return {"cleared":true,"hero_index":chosen,"amount":highest}

static func apply_outgoing_reduction(unit:Dictionary,source_id:String,duration:float)->void:
	unit["active_effects"]=unit.get("active_effects",[]).filter(func(effect):return not (str(effect.get("effect_family",""))=="outgoing_damage_reduction" and str(effect.get("source_id",""))==source_id))
	unit.active_effects.append({"id":"protector_wrath_reduction:%s"%source_id,"effect_family":"outgoing_damage_reduction","source_id":source_id,"amount":float(ProtectorData.VALUES.trait_damage_reduction),"remaining_duration":duration})

static func outgoing_damage_multiplier(unit:Dictionary)->float:
	var strongest:=0.0
	for effect in unit.get("active_effects",[]):
		if str(effect.get("effect_family",""))=="outgoing_damage_reduction" and float(effect.get("remaining_duration",0.0))>0.0:strongest=maxf(strongest,float(effect.get("amount",0.0)))
	return 1.0-clampf(strongest,0.0,1.0)

static func movement_multiplier(unit:Dictionary)->float:
	var result:=1.0
	if float(unit.get("protector_runtime",{}).get("pursuit_remaining",0.0))>0.0:result+=float(ProtectorData.VALUES.q_pursuit_speed)
	if not unit.get("protector_runtime",{}).get("wrath",{}).is_empty():result+=float(ProtectorData.VALUES.trait_speed)
	return result

static func armor_sources(unit:Dictionary)->Array:
	if not has_talent(unit,"protector_l12_1"):return []
	var runtime:Dictionary=unit.get("protector_runtime",{})
	var sword_active:bool=not runtime.get("q_sequence",{}).is_empty() and float(runtime.q_sequence.get("remaining",0.0))>0.0
	return [{"id":"protector_stalwart","armor":float(ProtectorData.VALUES.q_stalwart_armor),"remaining":1.0}] if sword_active or float(runtime.get("stalwart_remaining",0.0))>0.0 else []

static func note_basic_attack(unit:Dictionary,target:Dictionary,blockers:Array,from:Vector2,to:Vector2,resolved_damage:float)->void:
	if resolved_damage<=0.0:return
	telemetry_add(unit,"basic_hits")
	var q:Dictionary=unit.protector_runtime.get("q_sequence",{})
	if has_talent(unit,"protector_l24_2") and not q.is_empty() and str(target.get("combat_id","")) in q.get("marked_ids",[]):
		unit.ability_cds[0]=maxf(0.0,float(unit.ability_cds[0])-float(ProtectorData.VALUES.q_reforging_reduction));telemetry_add(unit,"q_reforging_reduction",float(ProtectorData.VALUES.q_reforging_reduction))
	if has_talent(unit,"protector_l18_2") and crosses_own_wall(unit,from,to,blockers):
		unit.ability_cds[1]=maxf(0.0,float(unit.ability_cds[1])-float(ProtectorData.VALUES.w_crossing_reduction));telemetry_add(unit,"wall_crossing_attacks")

static func update(unit:Dictionary,delta:float)->void:
	var runtime:Dictionary=unit.get("protector_runtime",{});if runtime.is_empty():return
	for key in ["aspect_cooldown","pursuit_remaining","stalwart_remaining","wicked_remaining","burning_empowered_remaining"]:runtime[key]=maxf(0.0,float(runtime.get(key,0.0))-delta)
	var rate:=float(ProtectorData.VALUES.e_wicked_rate) if has_talent(unit,"protector_l24_3") and (not runtime.q_sequence.is_empty() or float(runtime.wicked_remaining)>0.0) else 1.0
	AbilitySlotSystem.update(runtime.smite_slot,delta,rate)
	unit.ability_cds[2]=float(AbilitySlotSystem.ui_state(runtime.smite_slot).recharge)
