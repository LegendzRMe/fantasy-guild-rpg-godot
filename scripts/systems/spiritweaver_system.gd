extends RefCounted
const SpiritWeaverData=preload("res://scripts/data/spiritweaver_data.gd")
const StatusEffectSystem=preload("res://scripts/systems/status_effect_system.gd")
const TargetCategorySystem=preload("res://scripts/systems/combat_target_category_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return unit.get("selected_talents",{}).values().has(id)
static func owner_id(unit:Dictionary)->String:return str(unit.get("combat_id","spiritweaver"))
static func telemetry_default()->Dictionary:
	var result:={}
	for key in ["basic_attacks","basic_damage","basic_heals","basic_heal_effective","basic_heal_overheal","basic_bounces","q_casts","q_recipients","q_healing","q_effective","q_overheal","q_relays","tidal_reductions","earthliving","w_casts","w_contacts","w_damage","electric_healing","stormcaller_stacks","rising_stacks","e_casts","e_repositions","e_slow_time","e_damage","e_destroyed","healing_totem_healing","wellspring_casts","d_casts","d_ally","d_enemy","d_removed","purification_healing","shield_removed","antiheal_time","wolf_entries","wolf_exits","wolf_lunges","wolf_bonus_damage","ancestral_casts","ancestral_healing","bloodlust_casts","bloodlust_recipients","bloodlust_leech","cap_a_burst","cap_c_retaliations"] :result[key]=0.0
	return result
static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false)->void:
	unit["spiritweaver_runtime"]={"next_cast_id":1,"wolf_timer":0.0,"wolf_active":false,"wolf_age":0.0,"lightning_shields":[],"totem":{},"earthliving":[],"pending_ancestral":[],"healing_totem_icd":0.0,"bloodlust":[],"stormcaller":{},"latest_q":{},"telemetry_enabled":telemetry_enabled,"telemetry":telemetry_default()}
	unit.basic_heal_amount=SpiritWeaverData.scaled(float(SpiritWeaverData.VALUES.basic_heal),int(unit.get("level",1)));unit.base_basic_action_interval=float(SpiritWeaverData.VALUES.basic_attack_interval);unit.basic_attack_interval=unit.base_basic_action_interval;unit.basic_heal_interval=unit.base_basic_action_interval;unit.range=float(SpiritWeaverData.SPACE.basic_range)
static func add(unit:Dictionary,key:String,amount:float=1.0)->void:if bool(unit.get("spiritweaver_runtime",{}).get("telemetry_enabled",false)):unit.spiritweaver_runtime.telemetry[key]=float(unit.spiritweaver_runtime.telemetry.get(key,0.0))+amount
static func note_action(unit:Dictionary)->void:
	if bool(unit.spiritweaver_runtime.wolf_active):unit.spiritweaver_runtime.wolf_active=false;unit.spiritweaver_runtime.wolf_age=0.0;add(unit,"wolf_exits")
	unit.spiritweaver_runtime.wolf_timer=0.0
static func advance_wolf(unit:Dictionary,delta:float)->bool:
	if bool(unit.spiritweaver_runtime.wolf_active):unit.spiritweaver_runtime.wolf_age=float(unit.spiritweaver_runtime.wolf_age)+delta;return false
	unit.spiritweaver_runtime.wolf_timer=float(unit.spiritweaver_runtime.wolf_timer)+delta
	if float(unit.spiritweaver_runtime.wolf_timer)>=float(SpiritWeaverData.VALUES.wolf_delay):unit.spiritweaver_runtime.wolf_active=true;unit.spiritweaver_runtime.wolf_age=0.0;add(unit,"wolf_entries");return true
	return false
static func movement_multiplier(unit:Dictionary)->float:
	if not bool(unit.get("spiritweaver_runtime",{}).get("wolf_active",false)):return 1.0
	if has_talent(unit,"spiritweaver_l9_3"):return 1.0+(float(SpiritWeaverData.VALUES.feral_first_move) if float(unit.spiritweaver_runtime.wolf_age)<1.0 else float(SpiritWeaverData.VALUES.feral_later_move))
	return 1.0+float(SpiritWeaverData.VALUES.wolf_move)
static func create_w(unit:Dictionary,bearer_id:String,bearer_is_totem:bool=false)->Dictionary:
	var cast_id:="%s:w:%d"%[owner_id(unit),int(unit.spiritweaver_runtime.next_cast_id)];unit.spiritweaver_runtime.next_cast_id=int(unit.spiritweaver_runtime.next_cast_id)+1
	var shield:={"owner_id":owner_id(unit),"cast_id":cast_id,"bearer_id":bearer_id,"bearer_is_totem":bearer_is_totem,"remaining":float(SpiritWeaverData.VALUES.w_duration)+(float(SpiritWeaverData.VALUES.rising_duration) if has_talent(unit,"spiritweaver_l24_1") else 0.0),"tick":0.0,"stacks":0};unit.spiritweaver_runtime.lightning_shields.append(shield);add(unit,"w_casts");return shield
static func w_damage(unit:Dictionary,shield:Dictionary)->float:return SpiritWeaverData.scaled(float(SpiritWeaverData.VALUES.w_dps)*float(SpiritWeaverData.VALUES.w_tick),int(unit.level))*(1.0+float(shield.stacks)*float(SpiritWeaverData.VALUES.rising_per_contact))
static func note_w_contact(unit:Dictionary,shield:Dictionary,bearer:Dictionary,damage:float,target:Dictionary={})->void:
	add(unit,"w_contacts");add(unit,"w_damage",damage)
	if has_talent(unit,"spiritweaver_l24_1") and int(shield.stacks)<int(SpiritWeaverData.VALUES.rising_max):shield.stacks=int(shield.stacks)+1;add(unit,"rising_stacks")
	if has_talent(unit,"spiritweaver_l9_1") and not bool(shield.bearer_is_totem) and (target.is_empty() or TargetCategorySystem.qualifies_quest(target)):var id:=str(bearer.get("combat_id",""));var stacks:=mini(int(SpiritWeaverData.VALUES.stormcaller_max),int(unit.spiritweaver_runtime.stormcaller.get(id,0))+1);if stacks>int(unit.spiritweaver_runtime.stormcaller.get(id,0)):bearer.max_hp=float(bearer.max_hp)+float(SpiritWeaverData.VALUES.stormcaller_health);unit.spiritweaver_runtime.stormcaller[id]=stacks;add(unit,"stormcaller_stacks")
static func create_totem(unit:Dictionary,position:Vector2)->Dictionary:
	var colossal:=has_talent(unit,"spiritweaver_l9_2");var healing:=has_talent(unit,"spiritweaver_l12_3") and float(unit.spiritweaver_runtime.healing_totem_icd)<=0.0;var duration:=float(SpiritWeaverData.VALUES.healing_totem_duration) if healing else float(SpiritWeaverData.VALUES.e_duration)*(1.0+float(SpiritWeaverData.VALUES.colossal_duration) if colossal else 1.0);var maximum:=SpiritWeaverData.scaled(float(SpiritWeaverData.VALUES.e_health)*(1.0+float(SpiritWeaverData.VALUES.colossal_health) if colossal else 1.0),int(unit.level));var id:="%s:totem:%d"%[owner_id(unit),int(unit.spiritweaver_runtime.next_cast_id)];unit.spiritweaver_runtime.next_cast_id=int(unit.spiritweaver_runtime.next_cast_id)+1
	unit.spiritweaver_runtime.totem={"combat_id":id,"owner_id":owner_id(unit),"source_id":id,"combat_team":"player","combat_affiliation":"player","target_category":"summon","combat_tags":["summon","deployable","totem"],"summoned_unit":true,"ordinary_heal_eligible":false,"pos":position,"hp":maximum,"max_hp":maximum,"combat_radius":.125*SpiritWeaverData.SOURCE_TO_WORLD,"remaining":duration,"original_lifetime":duration,"slow_tick":0.0,"healing_tick":0.0,"wellspring_tick":0.0,"healing":healing,"repositioned":false,"earthgrasp_remaining":float(SpiritWeaverData.VALUES.earthgrasp_duration) if has_talent(unit,"spiritweaver_l24_2") else 0.0,"active_effects":[]}
	if healing:unit.spiritweaver_runtime.healing_totem_icd=float(SpiritWeaverData.VALUES.healing_totem_icd)
	add(unit,"e_casts");return unit.spiritweaver_runtime.totem
static func totem_radius(unit:Dictionary)->float:return float(SpiritWeaverData.SPACE.e_radius)*(1.0+float(SpiritWeaverData.VALUES.colossal_radius) if has_talent(unit,"spiritweaver_l9_2") else 1.0)
static func purge_recharge_rate(unit:Dictionary)->float:return 1.0+float(SpiritWeaverData.VALUES.cap_c_recharge) if has_talent(unit,"spiritweaver_l30_3") else 1.0
static func q_recipient_count(unit:Dictionary,untalented:bool=false)->int:return 1+int(SpiritWeaverData.VALUES.q_bounces)+(1 if not untalented and has_talent(unit,"spiritweaver_l18_3") else 0)
static func advance(unit:Dictionary,delta:float)->Array:
	var events:Array=[];if advance_wolf(unit,delta):events.append({"kind":"wolf_enter"});unit.spiritweaver_runtime.healing_totem_icd=maxf(0.0,float(unit.spiritweaver_runtime.healing_totem_icd)-delta)
	for shield in unit.spiritweaver_runtime.lightning_shields.duplicate():shield.remaining=float(shield.remaining)-delta;shield.tick=float(shield.tick)-delta;while float(shield.tick)<=0.0 and float(shield.remaining)>0.0:shield.tick=float(shield.tick)+float(SpiritWeaverData.VALUES.w_tick);events.append({"kind":"w_tick","shield":shield})
	unit.spiritweaver_runtime.lightning_shields=unit.spiritweaver_runtime.lightning_shields.filter(func(w):return float(w.remaining)>0.0)
	for hot in unit.spiritweaver_runtime.earthliving.duplicate():hot.remaining=float(hot.remaining)-delta;hot.tick=float(hot.tick)-delta;while float(hot.tick)<=0.0 and float(hot.remaining)>0.0:hot.tick=float(hot.tick)+float(SpiritWeaverData.VALUES.earthliving_tick);events.append({"kind":"earthliving","hot":hot})
	unit.spiritweaver_runtime.earthliving=unit.spiritweaver_runtime.earthliving.filter(func(hot):return float(hot.remaining)>0.0)
	for pending in unit.spiritweaver_runtime.pending_ancestral.duplicate():pending.remaining=float(pending.remaining)-delta;if float(pending.remaining)<=0.0:events.append({"kind":"ancestral","pending":pending})
	unit.spiritweaver_runtime.pending_ancestral=unit.spiritweaver_runtime.pending_ancestral.filter(func(p):return float(p.remaining)>0.0)
	var totem:Dictionary=unit.spiritweaver_runtime.totem
	if not totem.is_empty():totem.remaining=float(totem.remaining)-delta;totem.earthgrasp_remaining=maxf(0.0,float(totem.earthgrasp_remaining)-delta);totem.slow_tick=float(totem.slow_tick)-delta;totem.healing_tick=float(totem.healing_tick)-delta;totem.wellspring_tick=float(totem.wellspring_tick)-delta;if float(totem.slow_tick)<=0.0:totem.slow_tick=.25;events.append({"kind":"totem_slow"});if bool(totem.healing) and float(totem.healing_tick)<=0.0:totem.healing_tick=1.0;events.append({"kind":"totem_heal"});if has_talent(unit,"spiritweaver_l21_3") and float(totem.wellspring_tick)<=0.0:totem.wellspring_tick=float(SpiritWeaverData.VALUES.wellspring_interval);events.append({"kind":"wellspring"});if float(totem.remaining)<=0.0 or float(totem.hp)<=0.0:events.append({"kind":"totem_end"});unit.spiritweaver_runtime.totem={}
	return events
