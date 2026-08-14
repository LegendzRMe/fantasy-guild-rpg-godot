extends RefCounted

const BeastmasterData=preload("res://scripts/data/beastmaster_data.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")
const BlockChargeSystem=preload("res://scripts/systems/block_charge_system.gd")
const SummonHealthDecaySystem=preload("res://scripts/systems/summon_health_decay_system.gd")
const StatusEffectSystem=preload("res://scripts/systems/status_effect_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values() or str(unit.get("selected_heroic_id",""))==id
static func owner_id(unit:Dictionary)->String:return str(unit.get("combat_id","beastmaster"))
static func successful(result:Dictionary)->bool:return float(result.get("resolved_damage",result.get("health_damage",0.0)))>0.0 and not bool(result.get("evaded",false))
static func default_telemetry()->Dictionary:
	var result:={}
	for key in ["d_commands","d_targets","d_retreats","misha_attacks","misha_damage","charge_casts","charge_contacts","charge_stuns","misha_deaths","misha_respawns","misha_healing","misha_blocks","bond_sent","bond_received","bestial_damage","apex_growth","apex_ramp","q_casts","q_summons","army_extra","lesser_active_peak","lesser_attacks","lesser_damage","lesser_hostile_deaths","lesser_decay_deaths","fresh_prevented","chain_uptime","pack_vitality_health","pack_assaults","wildfire_damage","greater_summons","greater_attacks","greater_damage","greater_hostile_deaths","greater_decay_deaths","greater_rally_uptime","fury_beastmaster","fury_misha","fury_lesser","fury_greater","fury_complete","hunted_applications","hunted_beastmaster","hunted_misha","hunted_expired","bestial_casts","spirit_healing","spirit_recipients","boar_casts","boar_targets","boar_contacts","boar_damage","boar_reveals","boar_slows","boar_roots"]:result[key]=0.0
	return result

static func telemetry_add(unit:Dictionary,key:String,value=1.0)->void:
	var runtime:Dictionary=unit.get("beastmaster_runtime",{});if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=float(runtime.telemetry.get(key,0.0))+float(value)

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false,encounter_id:String="")->void:
	var level:=int(unit.get("level",1));var misha:=create_misha(unit,Vector2(unit.get("pos",Vector2.ZERO))+Vector2(-45,35))
	unit["beastmaster_runtime"]={"encounter_id":encounter_id,"misha":misha,"misha_respawn_remaining":0.0,"q_slot":AbilitySlotSystem.create(2,q_recharge(unit)),"lesser_beasts":[],"greater_beasts":[],"summon_serial":0,"fury":0,"fury_complete":false,"hunted":{},"block_timer":float(BeastmasterData.VALUES.block_interval),"hawk_remaining":0.0,"dire_stacks":0,"thrill_remaining":0.0,"bestial_remaining":0.0,"boar_targets":[],"pack_commander_target":"","apex_health":0.0,"apex_target":"","apex_stacks":0,"wildfire_tick":1.0,"last_redirect":{},"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()}
	unit["basic_attack_interval"]=float(BeastmasterData.VALUES.basic_attack_interval);unit["base_basic_action_interval"]=float(BeastmasterData.VALUES.basic_attack_interval)
	if has_talent(unit,"beastmaster_l12_3"):unit["control_duration_multipliers"]={"slow":float(BeastmasterData.VALUES.unhindered_multiplier)};unit["slow_magnitude_multiplier"]=float(BeastmasterData.VALUES.unhindered_multiplier)
	BlockChargeSystem.initialize(unit,"block_state",int(BeastmasterData.VALUES.block_max));BlockChargeSystem.initialize(misha,"block_state",int(BeastmasterData.VALUES.block_max))

static func create_misha(unit:Dictionary,point:Vector2)->Dictionary:
	var level:=int(unit.get("level",1));var maximum:=BeastmasterData.scaled(float(BeastmasterData.VALUES.misha_health),level,1.0475)
	return {"combat_id":"%s:misha"%owner_id(unit),"owner_id":owner_id(unit),"source_id":"beastmaster_misha","source":"beastmaster_misha","team":"player","combat_team":"player","combat_affiliation":"player","target_category":"companion","combat_tags":["companion","beast"],"summoned_unit":true,"permanent_companion":true,"beast_category":"misha","ordinary_heal_eligible":true,"hp":maximum,"max_hp":maximum,"original_health":maximum,"health_decay_rate":0.0,"damage":BeastmasterData.scaled(float(BeastmasterData.VALUES.misha_damage),level),"attack_interval":float(BeastmasterData.VALUES.misha_interval),"attack_cooldown":0.0,"movement_speed":float(BeastmasterData.VALUES.misha_speed)*(1.0+float(BeastmasterData.VALUES.misha_passive_speed)),"range":float(BeastmasterData.SPACE.misha_range),"combat_radius":float(BeastmasterData.SPACE.misha_radius),"target_id":"","command_mode":"follow","active_effects":[],"threat":{},"pos":point}

static func misha_alive(unit:Dictionary)->bool:return float(unit.get("beastmaster_runtime",{}).get("misha",{}).get("hp",0.0))>0.0
static func q_recharge(unit:Dictionary)->float:return float(BeastmasterData.VALUES.army_recharge if has_talent(unit,"beastmaster_l9_1") else BeastmasterData.VALUES.q_recharge)
static func q_state(unit:Dictionary)->Dictionary:return AbilitySlotSystem.ui_state(unit.beastmaster_runtime.q_slot)
static func can_use_misha_action(unit:Dictionary)->bool:return misha_alive(unit)

static func command_misha(unit:Dictionary,target:Dictionary)->bool:
	if not misha_alive(unit) or target.is_empty():return false
	var misha:Dictionary=unit.beastmaster_runtime.misha
	if str(target.get("combat_id",""))==owner_id(unit):misha.command_mode="retreat";misha.target_id="";telemetry_add(unit,"d_retreats")
	else:misha.command_mode="focus";misha.target_id=str(target.get("combat_id",""));telemetry_add(unit,"d_targets")
	telemetry_add(unit,"d_commands");return true

static func next_summon_id(unit:Dictionary,kind:String)->String:
	unit.beastmaster_runtime.summon_serial=int(unit.beastmaster_runtime.summon_serial)+1;return "%s:%s:%d"%[owner_id(unit),kind,int(unit.beastmaster_runtime.summon_serial)]

static func create_beast(unit:Dictionary,kind:String,point:Vector2)->Dictionary:
	var greater:=kind=="greater";var level:=int(unit.get("level",1));var base_health:=float(BeastmasterData.VALUES.greater_health if greater else BeastmasterData.VALUES.lesser_health);var max_health:=BeastmasterData.scaled(base_health,level)
	if has_talent(unit,"beastmaster_l21_3"):max_health*=1.0+float(BeastmasterData.VALUES.pack_vitality)
	var decay:=BeastmasterData.scaled(float(BeastmasterData.VALUES.greater_decay if greater else BeastmasterData.VALUES.lesser_decay),level);var id:=next_summon_id(unit,kind)
	var beast:={"combat_id":id,"runtime_summon_id":id,"owner_id":owner_id(unit),"source_id":"beastmaster_greater_beast" if greater else "beastmaster_spirit_swoop","source":"beastmaster_greater_beast" if greater else "beastmaster_spirit_swoop","team":"player","combat_team":"player","combat_affiliation":"player","target_category":"summon","combat_tags":["summon","beast",kind],"summoned_unit":true,"permanent_companion":false,"beast_category":kind,"ordinary_heal_eligible":false,"hp":max_health,"max_hp":max_health,"original_health":max_health,"health_decay_rate":decay,"original_lifetime":base_health/float(BeastmasterData.VALUES.greater_decay if greater else BeastmasterData.VALUES.lesser_decay),"damage":BeastmasterData.scaled(float(BeastmasterData.VALUES.greater_damage if greater else BeastmasterData.VALUES.lesser_damage),level),"attack_interval":float(BeastmasterData.VALUES.greater_interval if greater else BeastmasterData.VALUES.lesser_interval),"attack_cooldown":0.0,"movement_speed":float(BeastmasterData.VALUES.greater_speed if greater else BeastmasterData.VALUES.lesser_speed),"range":float(BeastmasterData.SPACE.beast_range),"combat_radius":0.75*float(BeastmasterData.SPACE.source_to_world),"target_id":"","priority_target_id":"","pack_assault_pending":false,"fresh_remaining":float(BeastmasterData.VALUES.fresh_duration if has_talent(unit,"beastmaster_l12_2") else 0.0),"wildfire_tick_ids":[],"active_effects":[],"threat":{},"pos":point}
	if has_talent(unit,"beastmaster_l21_3"):telemetry_add(unit,"pack_vitality_health",max_health-BeastmasterData.scaled(base_health,level))
	return beast

static func cast_swoop(unit:Dictionary,endpoint:Vector2,contacts:Array=[])->Dictionary:
	var slot:Dictionary=unit.beastmaster_runtime.q_slot;if not AbilitySlotSystem.can_activate(slot):return {"cast":false}
	AbilitySlotSystem.spend(slot,1);var created:Array=[];for index in (2 if has_talent(unit,"beastmaster_l9_1") else 1):created.append(create_beast(unit,"lesser",endpoint+Vector2.from_angle(index*PI)*float(BeastmasterData.SPACE.lesser_spawn_offset)))
	unit.beastmaster_runtime.lesser_beasts.append_array(created);telemetry_add(unit,"q_casts");telemetry_add(unit,"q_summons",created.size());if created.size()>1:telemetry_add(unit,"army_extra",created.size()-1);telemetry_add(unit,"lesser_active_peak",maxi(0,unit.beastmaster_runtime.lesser_beasts.size()-int(unit.beastmaster_runtime.telemetry.get("lesser_active_peak",0))))
	if has_talent(unit,"beastmaster_l21_1") and not contacts.is_empty():unit.beastmaster_runtime.hawk_remaining=float(BeastmasterData.VALUES.hawk_duration)
	return {"cast":true,"beasts":created,"damage":BeastmasterData.scaled(float(BeastmasterData.VALUES.swoop_damage),int(unit.level)),"slow":float(BeastmasterData.VALUES.crippling_slow if has_talent(unit,"beastmaster_l18_1") else BeastmasterData.VALUES.swoop_slow),"slow_duration":float(BeastmasterData.VALUES.crippling_duration if has_talent(unit,"beastmaster_l18_1") else BeastmasterData.VALUES.swoop_slow_duration)}

static func cast_greater(unit:Dictionary)->Dictionary:
	if not misha_alive(unit) or float(unit.ability_cds[2])>0.0:return {"cast":false}
	var beast:=create_beast(unit,"greater",Vector2(unit.beastmaster_runtime.misha.pos));unit.beastmaster_runtime.greater_beasts.append(beast);unit.ability_cds[2]=float(BeastmasterData.VALUES.greater_cooldown);telemetry_add(unit,"greater_summons");return {"cast":true,"beast":beast}

static func charge_plan(unit:Dictionary,contacts:Array,preferred_target_id:String="")->Dictionary:
	if not misha_alive(unit) or float(unit.ability_cds[1])>0.0:return {"cast":false}
	var stacks:=int(unit.beastmaster_runtime.dire_stacks);unit.beastmaster_runtime.dire_stacks=0;unit.ability_cds[1]=float(BeastmasterData.VALUES.charge_cooldown);telemetry_add(unit,"charge_casts");telemetry_add(unit,"charge_contacts",contacts.size())
	var primary="";for target in contacts:if str(target.get("combat_id",""))==preferred_target_id:primary=preferred_target_id;break
	if primary=="" and not contacts.is_empty():primary=str(contacts[0].get("combat_id",""))
	if bool(unit.beastmaster_runtime.fury_complete):for target in contacts:apply_hunted(unit,str(target.get("combat_id","")))
	if has_talent(unit,"beastmaster_l30_2") and primary!="":pack_commander(unit,primary)
	return {"cast":true,"damage":BeastmasterData.scaled(float(BeastmasterData.VALUES.charge_damage),int(unit.level))*(1.0+stacks*float(BeastmasterData.VALUES.dire_per_stack)),"stun":float(BeastmasterData.VALUES.charge_stun),"primary_target_id":primary,"dire_stacks":stacks}

static func pack_commander(unit:Dictionary,target_id:String)->int:
	unit.beastmaster_runtime.pack_commander_target=target_id;var count:=0
	for beast in disposable_beasts(unit):beast.priority_target_id=target_id;beast.target_id=target_id;beast.pack_assault_pending=true;count+=1
	telemetry_add(unit,"pack_assaults",count);return count

static func disposable_beasts(unit:Dictionary)->Array:return unit.get("beastmaster_runtime",{}).get("lesser_beasts",[])+unit.get("beastmaster_runtime",{}).get("greater_beasts",[])
static func combat_beasts(unit:Dictionary)->Array:
	var result:Array=[]
	if misha_alive(unit):result.append(unit.beastmaster_runtime.misha)
	result.append_array(disposable_beasts(unit))
	return result
static func ordinary_heal_eligible(beast:Dictionary)->bool:return bool(beast.get("ordinary_heal_eligible",false))

static func coordinated_multiplier(unit:Dictionary,target_id:String)->float:
	if not has_talent(unit,"beastmaster_l9_2") or str(unit.beastmaster_runtime.misha.get("target_id",""))!=target_id:return 1.0
	for beast in disposable_beasts(unit):if float(beast.get("hp",0.0))>0.0 and str(beast.get("target_id",""))==target_id:return 1.0+float(BeastmasterData.VALUES.coordinated_bonus)
	return 1.0

static func note_primary_attack(unit:Dictionary,actor:String,target_id:String,result:Dictionary)->Dictionary:
	if not successful(result):return {"successful":false}
	if has_talent(unit,"beastmaster_l9_3") and actor in ["beastmaster","misha","lesser","greater"]:add_fury(unit,actor,1)
	if actor in ["beastmaster","misha"] and has_talent(unit,"beastmaster_l21_2"):unit.beastmaster_runtime.dire_stacks=mini(int(BeastmasterData.VALUES.dire_max),int(unit.beastmaster_runtime.dire_stacks)+1)
	if actor=="misha":
		telemetry_add(unit,"misha_attacks");telemetry_add(unit,"misha_damage",float(result.get("resolved_damage",0.0)))
		if has_talent(unit,"beastmaster_l18_2"):unit.ability_cds[1]=maxf(0.0,float(unit.ability_cds[1])-float(BeastmasterData.VALUES.aspect_cdr))
		if float(unit.beastmaster_runtime.hawk_remaining)>0.0:unit.beastmaster_runtime.hawk_remaining+=float(BeastmasterData.VALUES.hawk_extension)
		if has_talent(unit,"beastmaster_l30_1"):note_apex_attack(unit,target_id)
	elif actor=="beastmaster" and has_talent(unit,"beastmaster_l24_1"):unit.beastmaster_runtime.thrill_remaining=float(BeastmasterData.VALUES.thrill_duration)
	var hunted:=consume_hunted(unit,target_id,actor)
	return {"successful":true,"hunted_bonus":float(result.get("resolved_damage",0.0))*float(BeastmasterData.VALUES.hunted_bonus) if hunted else 0.0}

static func add_fury(unit:Dictionary,actor:String,amount:int)->int:
	if not has_talent(unit,"beastmaster_l9_3") or bool(unit.beastmaster_runtime.fury_complete):return 0
	var before:=int(unit.beastmaster_runtime.fury);unit.beastmaster_runtime.fury=mini(int(BeastmasterData.VALUES.fury_goal),before+maxi(0,amount));telemetry_add(unit,"fury_%s"%actor,int(unit.beastmaster_runtime.fury)-before)
	if int(unit.beastmaster_runtime.fury)>=int(BeastmasterData.VALUES.fury_goal):unit.beastmaster_runtime.fury_complete=true;telemetry_add(unit,"fury_complete")
	return int(unit.beastmaster_runtime.fury)-before

static func apply_hunted(unit:Dictionary,target_id:String)->void:
	unit.beastmaster_runtime.hunted[target_id]={"remaining":float(BeastmasterData.VALUES.hunted_duration),"beastmaster":true,"misha":true};telemetry_add(unit,"hunted_applications")
static func consume_hunted(unit:Dictionary,target_id:String,actor:String)->bool:
	if actor not in ["beastmaster","misha"] or not unit.beastmaster_runtime.hunted.has(target_id):return false
	var mark:Dictionary=unit.beastmaster_runtime.hunted[target_id];if float(mark.remaining)<=0.0 or not bool(mark.get(actor,false)):return false
	mark[actor]=false;unit.beastmaster_runtime.hunted[target_id]=mark;telemetry_add(unit,"hunted_%s"%actor);return true

static func note_apex_attack(unit:Dictionary,target_id:String)->void:
	if str(unit.beastmaster_runtime.apex_target)!=target_id:unit.beastmaster_runtime.apex_target=target_id;unit.beastmaster_runtime.apex_stacks=0
	unit.beastmaster_runtime.apex_stacks=mini(int(BeastmasterData.VALUES.apex_max),int(unit.beastmaster_runtime.apex_stacks)+1);telemetry_add(unit,"apex_ramp")
static func apex_multiplier(unit:Dictionary,target_id:String)->float:return 1.0+int(unit.beastmaster_runtime.apex_stacks)*float(BeastmasterData.VALUES.apex_per_stack) if has_talent(unit,"beastmaster_l30_1") and str(unit.beastmaster_runtime.apex_target)==target_id else 1.0

static func bestial_duration(unit:Dictionary)->float:return float(BeastmasterData.VALUES.spirit_duration if has_talent(unit,"beastmaster_l27_r1") else BeastmasterData.VALUES.bestial_duration)
static func cast_bestial(unit:Dictionary)->bool:
	if not misha_alive(unit) or str(unit.selected_heroic_id)!="beastmaster_l15_r1" or float(unit.ability_cds[3])>0.0:return false
	unit.ability_cds[3]=float(BeastmasterData.VALUES.bestial_cooldown);unit.beastmaster_runtime.bestial_remaining=bestial_duration(unit);telemetry_add(unit,"bestial_casts");return true
static func misha_damage_multiplier(unit:Dictionary,target_id:String)->float:
	var result:=coordinated_multiplier(unit,target_id)*apex_multiplier(unit,target_id)
	if float(unit.beastmaster_runtime.bestial_remaining)>0.0:result*=1.0+float(BeastmasterData.VALUES.bestial_bonus)
	return result

static func spirit_bond_heal(unit:Dictionary,resolved_damage:float)->Array:
	var healed:Array=[];if not has_talent(unit,"beastmaster_l27_r1") or float(unit.beastmaster_runtime.bestial_remaining)<=0.0:return healed
	var amount:=maxf(0.0,resolved_damage)*float(BeastmasterData.VALUES.spirit_heal)
	for beast in combat_beasts(unit):var actual:=minf(amount,maxf(0.0,float(beast.max_hp)-float(beast.hp)));beast.hp=float(beast.hp)+actual;if actual>0.0:healed.append({"target_id":str(beast.combat_id),"amount":actual});telemetry_add(unit,"spirit_healing",actual);telemetry_add(unit,"spirit_recipients")
	return healed

static func apply_primal(unit:Dictionary,attacker:Dictionary,target:Dictionary)->bool:
	var owned:bool=target==unit or str(target.get("owner_id",""))==owner_id(unit) or str(target.get("combat_id",""))==str(unit.beastmaster_runtime.misha.get("combat_id",""))
	if not has_talent(unit,"beastmaster_l24_2") or not owned:return false
	StatusEffectSystem.apply_source_control(attacker,"beastmaster_primal:%s"%owner_id(unit),"attack_speed",float(BeastmasterData.VALUES.primal_duration),float(BeastmasterData.VALUES.primal_suppression));return true

static func slow_request(unit:Dictionary,magnitude:float,duration:float)->Dictionary:
	var multiplier:=float(BeastmasterData.VALUES.unhindered_multiplier if has_talent(unit,"beastmaster_l12_3") else 1.0);return {"magnitude":magnitude*multiplier,"duration":duration*multiplier}

static func chain_multiplier(unit:Dictionary,lesser:Dictionary)->float:
	if not has_talent(unit,"beastmaster_l18_3"):return 1.0
	for greater in unit.beastmaster_runtime.greater_beasts:if float(greater.hp)>0.0 and Vector2(greater.pos).distance_to(Vector2(lesser.pos))<=float(BeastmasterData.SPACE.greater_rally):return 1.0+float(BeastmasterData.VALUES.chain_bonus)
	return 1.0

static func advance(unit:Dictionary,delta:float,active_combat:bool=false)->void:
	var runtime:Dictionary=unit.beastmaster_runtime;AbilitySlotSystem.update(runtime.q_slot,delta);runtime.hawk_remaining=maxf(0.0,float(runtime.hawk_remaining)-delta);runtime.thrill_remaining=maxf(0.0,float(runtime.thrill_remaining)-delta);runtime.bestial_remaining=maxf(0.0,float(runtime.bestial_remaining)-delta);runtime.wildfire_tick=maxf(0.0,float(runtime.wildfire_tick)-delta)
	for id in runtime.hunted.keys():
		var mark:Dictionary=runtime.hunted[id];mark.remaining=maxf(0.0,float(mark.remaining)-delta)
		if float(mark.remaining)<=0.0:
			if bool(mark.beastmaster) or bool(mark.misha):telemetry_add(unit,"hunted_expired")
			runtime.hunted.erase(id)
		else:runtime.hunted[id]=mark
	if has_talent(unit,"beastmaster_l12_1"):
		runtime.block_timer=float(runtime.block_timer)-delta
		while float(runtime.block_timer)<=0.0:
			runtime.block_timer+=float(BeastmasterData.VALUES.block_interval);BlockChargeSystem.grant(unit,1,int(BeastmasterData.VALUES.block_max));BlockChargeSystem.grant(runtime.misha,1,int(BeastmasterData.VALUES.block_max))
	if not misha_alive(unit):
		runtime.misha_respawn_remaining=maxf(0.0,float(runtime.misha_respawn_remaining)-delta)
		if float(runtime.misha_respawn_remaining)<=0.0:respawn_misha(unit)
	else:
		runtime.misha.hp=minf(float(runtime.misha.max_hp),float(runtime.misha.hp)+BeastmasterData.scaled(float(BeastmasterData.VALUES.misha_regeneration),int(unit.get("level",1)),1.0475)*delta)
		if has_talent(unit,"beastmaster_l30_1") and active_combat:
			var growth:=float(BeastmasterData.VALUES.apex_health_per_second)*maxf(0.0,delta);runtime.apex_health=float(runtime.apex_health)+growth;runtime.misha.max_hp=float(runtime.misha.max_hp)+growth;telemetry_add(unit,"apex_growth",growth)
	for collection_name in ["lesser_beasts","greater_beasts"]:
		for beast in runtime[collection_name]:beast.fresh_remaining=maxf(0.0,float(beast.fresh_remaining)-delta);beast.attack_cooldown=maxf(0.0,float(beast.attack_cooldown)-delta);SummonHealthDecaySystem.advance(beast,delta)
		var hostile_deaths:int=runtime[collection_name].filter(func(beast):return float(beast.hp)<=0.0 and bool(beast.get("defeated_by_hostile",false))).size();var decay_deaths:int=runtime[collection_name].filter(func(beast):return float(beast.hp)<=0.0 and not bool(beast.get("defeated_by_hostile",false))).size();runtime[collection_name]=runtime[collection_name].filter(func(beast):return float(beast.hp)>0.0)
		if hostile_deaths>0:telemetry_add(unit,"lesser_hostile_deaths" if collection_name=="lesser_beasts" else "greater_hostile_deaths",hostile_deaths)
		if decay_deaths>0:telemetry_add(unit,"lesser_decay_deaths" if collection_name=="lesser_beasts" else "greater_decay_deaths",decay_deaths)

static func defeat_misha(unit:Dictionary)->void:
	if not misha_alive(unit) and float(unit.beastmaster_runtime.misha_respawn_remaining)>0.0:return
	unit.beastmaster_runtime.misha.hp=0.0;unit.beastmaster_runtime.misha_respawn_remaining=float(BeastmasterData.VALUES.misha_respawn);unit.beastmaster_runtime.apex_health=0.0;unit.beastmaster_runtime.apex_stacks=0;unit.beastmaster_runtime.apex_target="";telemetry_add(unit,"misha_deaths")
static func respawn_misha(unit:Dictionary)->void:
	var previous:Dictionary=unit.beastmaster_runtime.misha;var misha:=create_misha(unit,Vector2(unit.get("pos",Vector2.ZERO))+Vector2(-45,35));misha.block_state=previous.get("block_state",{"charges":0,"maximum":2});unit.beastmaster_runtime.misha=misha;unit.beastmaster_runtime.misha_respawn_remaining=0.0;telemetry_add(unit,"misha_respawns")
static func reset_encounter(unit:Dictionary,new_encounter_id:String="")->void:initialize_runtime(unit,bool(unit.get("beastmaster_runtime",{}).get("telemetry_enabled",false)),new_encounter_id)
