extends RefCounted

const GuardianData = preload("res://scripts/data/guardian_data.gd")

static func has_talent(unit:Dictionary,talent_id:String)->bool:
	return talent_id in unit.get("selected_talents",{}).values()

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false)->void:
	unit["guardian_runtime"]={
		"seconds_since_damage":0.0,"second_wind_active":false,"stoneform_remaining":0.0,"stoneform_tick":0.0,
		"block_charges":0,"quest_stacks":0,"quest_first_reached":false,"quest_mythic_reached":false,"quest_markers":{},
		"perfect_storm_ready_at":0.0,"skullcracker_target":"","skullcracker_count":0,"give_axe_remaining":0.0,"haymaker_markers":{},
		"bronzebeard_empowered":0.0,"bronzebeard_tick":0.0,"avatar_remaining":0.0,"avatar_health_bonus":0.0,
		"imposing_ready_at":0.0,"hardened_ready_at":0.0,"rewind_ready_at":0.0,"rewind_window_ends":0.0,"rewind_casts":{},
		"temporary_armor_sources":[],"delayed_effects":[],"ability_charges":default_charges(unit),"ability_recharge":{},
		"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()
	}

static func default_charges(unit:Dictionary)->Dictionary:
	return {"q":1,"w":2 if has_talent(unit,"guardian_l30_1") else 1,"e":2 if has_talent(unit,"guardian_l30_1") else 1,"r":2 if has_talent(unit,"guardian_l27_r2") else 1}

static func default_telemetry()->Dictionary:
	return {"storm_bolt_casts":0,"storm_bolt_hits":0,"storm_bolt_misses":0,"quest_sources":{},"quest_milestones":{},"storm_bolt_cooldown_reductions":0,"thunder_clap_casts":[],"healing_static_healing":0.0,"bronzebeard_damage":0.0,"bronzebeard_healing":0.0,"block_gained":0,"block_consumed":0,"block_prevented":0.0,"temporary_armor_prevented":0.0,"dwarf_toss_valid":0,"dwarf_toss_invalid":0,"dwarf_toss_assignments_cleared":0,"avatar_uses":0,"avatar_damage_taken":0.0,"haymaker_uses":0,"haymaker_interruptions":0,"haymaker_boss_staggers":0,"grand_slam_resets":0,"capstone_uses":0}

static func telemetry_add(unit:Dictionary,key:String,value=1)->void:
	var runtime:Dictionary=unit.get("guardian_runtime",{})
	if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=runtime.telemetry.get(key,0)+value

static func telemetry_append(unit:Dictionary,key:String,value)->void:
	var runtime:Dictionary=unit.get("guardian_runtime",{})
	if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	var entries:Array=runtime.telemetry.get(key,[])
	entries.append(value);runtime.telemetry[key]=entries

static func add_quest(unit:Dictionary,amount:int,source:String,now:float)->void:
	var runtime:Dictionary=unit.guardian_runtime
	runtime.quest_stacks=int(runtime.quest_stacks)+amount
	if bool(runtime.telemetry_enabled):runtime.telemetry.quest_sources[source]=int(runtime.telemetry.quest_sources.get(source,0))+amount
	if not runtime.quest_first_reached and runtime.quest_stacks>=int(GuardianData.VALUES.quest_first):
		runtime.quest_first_reached=true
		if bool(runtime.telemetry_enabled):runtime.telemetry.quest_milestones["first"]=now
	if not runtime.quest_mythic_reached and runtime.quest_stacks>=int(GuardianData.VALUES.quest_mythic):
		runtime.quest_mythic_reached=true
		if bool(runtime.telemetry_enabled):runtime.telemetry.quest_milestones["mythic"]=now

static func mark_storm_bolt(unit:Dictionary,target_id:String,now:float)->void:
	unit.guardian_runtime.quest_markers[target_id]=now+float(GuardianData.VALUES.quest_death_window)

static func process_marked_death(unit:Dictionary,target_id:String,now:float)->bool:
	var expires:float=float(unit.guardian_runtime.quest_markers.get(target_id,-1.0))
	unit.guardian_runtime.quest_markers.erase(target_id)
	if expires<now:return false
	add_quest(unit,5,"storm_bolt_death",now)
	if has_talent(unit,"guardian_l18_1") and now>=float(unit.guardian_runtime.perfect_storm_ready_at):
		unit.guardian_runtime.perfect_storm_ready_at=now+float(GuardianData.VALUES.perfect_storm_icd)
		unit.ability_cds[0]=0.0
	return true

static func on_basic_attack(unit:Dictionary,target:Dictionary,now:float)->Dictionary:
	var result:={"damage_multiplier":1.0,"bonus_damage_multiplier":0.0,"stun":0.0}
	var effects:Array=target.get("active_effects",[])
	var slowed:=effects.any(func(effect):return str(effect.get("control_type","")) in ["slow","root"])
	var stunned:=effects.any(func(effect):return str(effect.get("control_type",""))=="stun")
	var qualifying:bool="training" not in target.get("combat_tags",[]) and "non_qualifying" not in target.get("combat_tags",[])
	if qualifying and stunned:add_quest(unit,2,"stunned_basic_attack",now)
	elif qualifying and slowed:add_quest(unit,1,"controlled_basic_attack",now)
	if (slowed or stunned) and has_talent(unit,"guardian_l9_3"):unit.guardian_runtime.give_axe_remaining=3.0
	if float(unit.guardian_runtime.give_axe_remaining)>0.0:result.damage_multiplier=1.4
	if bool(unit.guardian_runtime.quest_first_reached):unit.ability_cds[0]=maxf(0.0,float(unit.ability_cds[0])-0.5);telemetry_add(unit,"storm_bolt_cooldown_reductions")
	if has_talent(unit,"guardian_l12_1"):unit.ability_cds[0]=maxf(0.0,float(unit.ability_cds[0])-1.5);telemetry_add(unit,"storm_bolt_cooldown_reductions")
	if has_talent(unit,"guardian_l27_r1") and float(unit.guardian_runtime.avatar_remaining)>0.0:
		unit.ability_cds[1]=maxf(0.0,float(unit.ability_cds[1])-0.75);unit.ability_cds[2]=maxf(0.0,float(unit.ability_cds[2])-0.75)
	if has_talent(unit,"guardian_l18_3"):
		var target_id:=str(target.get("combat_id",""))
		if unit.guardian_runtime.skullcracker_target!=target_id:unit.guardian_runtime.skullcracker_target=target_id;unit.guardian_runtime.skullcracker_count=0
		unit.guardian_runtime.skullcracker_count=int(unit.guardian_runtime.skullcracker_count)+1
		if unit.guardian_runtime.skullcracker_count>=3:unit.guardian_runtime.skullcracker_count=0;result.bonus_damage_multiplier=0.9;result.stun=0.25
	return result

static func mark_haymaker(unit:Dictionary,target_id:String,now:float)->void:
	unit.guardian_runtime.haymaker_markers[target_id]=now+3.0

static func process_haymaker_death(unit:Dictionary,target_id:String,now:float)->bool:
	var expires:=float(unit.guardian_runtime.haymaker_markers.get(target_id,-1.0));unit.guardian_runtime.haymaker_markers.erase(target_id)
	if expires<now or not has_talent(unit,"guardian_l27_r2"):return false
	unit.ability_cds[3]=0.0;telemetry_add(unit,"grand_slam_resets");return true

static func imposing_presence_amount(unit:Dictionary,now:float)->float:
	if not has_talent(unit,"guardian_l24_3"):return 0.0
	if now>=float(unit.guardian_runtime.imposing_ready_at):
		unit.guardian_runtime.imposing_ready_at=now+float(GuardianData.VALUES.imposing_presence_cooldown)
		return 0.50
	return 0.20

static func try_hardened_shield(unit:Dictionary,before_ratio:float,after_ratio:float,actual_damage:float,now:float)->bool:
	if not has_talent(unit,"guardian_l30_2") or actual_damage<=0.0 or before_ratio<0.30 or after_ratio>=0.30 or now<float(unit.guardian_runtime.hardened_ready_at):return false
	add_armor_source(unit,"hardened_shield",float(GuardianData.VALUES.hardened_shield_armor),float(GuardianData.VALUES.hardened_shield_duration))
	unit.guardian_runtime.hardened_ready_at=now+float(GuardianData.VALUES.capstone_cooldown);telemetry_add(unit,"capstone_uses");return true

static func record_rewind_cast(unit:Dictionary,ability_id:String,now:float)->bool:
	if not has_talent(unit,"guardian_l30_3") or now<float(unit.guardian_runtime.rewind_ready_at):return false
	if unit.guardian_runtime.rewind_casts.is_empty() or now>float(unit.guardian_runtime.rewind_window_ends):unit.guardian_runtime.rewind_casts={};unit.guardian_runtime.rewind_window_ends=now+float(GuardianData.VALUES.rewind_window)
	unit.guardian_runtime.rewind_casts[ability_id]=true
	if not ["q","w","e"].all(func(id):return bool(unit.guardian_runtime.rewind_casts.get(id,false))):return false
	for slot in 3:unit.ability_cds[slot]=0.0
	unit.guardian_runtime.rewind_casts={};unit.guardian_runtime.rewind_window_ends=0.0;unit.guardian_runtime.rewind_ready_at=now+float(GuardianData.VALUES.rewind_cooldown);telemetry_add(unit,"capstone_uses");return true

static func rewind_sequence_count(unit:Dictionary,now:float)->int:
	if now>float(unit.guardian_runtime.rewind_window_ends):return 0
	return unit.guardian_runtime.rewind_casts.size()

static func activate_stoneform(unit:Dictionary)->bool:
	if not has_talent(unit,"guardian_l24_2") or float(unit.ability_cds[4])>0.0:return false
	unit.guardian_runtime.stoneform_remaining=float(GuardianData.VALUES.stoneform_duration);unit.guardian_runtime.stoneform_tick=0.0;unit.ability_cds[4]=float(GuardianData.VALUES.stoneform_cooldown);return true

static func second_wind_profile(unit:Dictionary)->Dictionary:
	if has_talent(unit,"guardian_l9_2"):
		return {"normal":GuardianData.scaled(90.0,int(unit.level)),"low":GuardianData.scaled(180.0,int(unit.level)),"threshold":0.60}
	return {"normal":GuardianData.scaled(float(GuardianData.VALUES.second_wind_normal),int(unit.level)),"low":GuardianData.scaled(float(GuardianData.VALUES.second_wind_low),int(unit.level)),"threshold":float(GuardianData.VALUES.second_wind_threshold)}

static func note_damage(unit:Dictionary,resolved_damage:float)->void:
	if unit.get("guardian_runtime",{}).is_empty():return
	unit.guardian_runtime.seconds_since_damage=0.0;unit.guardian_runtime.second_wind_active=false
	if float(unit.guardian_runtime.avatar_remaining)>0.0:telemetry_add(unit,"avatar_damage_taken",resolved_damage)

static func active_armor(unit:Dictionary,damage_type:String="physical",source_action:String="basic_attack")->float:
	var strongest:=float(unit.get("armor",0.0))
	for source in unit.get("guardian_runtime",{}).get("temporary_armor_sources",[]):
		if float(source.get("remaining",0.0))>0.0:strongest=maxf(strongest,float(source.get("armor",0.0)))
	if damage_type=="physical" and source_action=="basic_attack" and int(unit.get("guardian_runtime",{}).get("block_charges",0))>0:strongest=maxf(strongest,float(GuardianData.VALUES.block_armor))
	return strongest

static func consume_block(unit:Dictionary,damage_type:String,source_action:String,raw_damage:float)->bool:
	if raw_damage<=0.0 or damage_type!="physical" or source_action!="basic_attack" or int(unit.guardian_runtime.block_charges)<=0:return false
	unit.guardian_runtime.block_charges=int(unit.guardian_runtime.block_charges)-1;telemetry_add(unit,"block_consumed");return true

static func grant_block(unit:Dictionary)->void:
	unit.guardian_runtime.block_charges=int(GuardianData.VALUES.block_charges);telemetry_add(unit,"block_gained",int(GuardianData.VALUES.block_charges))

static func add_armor_source(unit:Dictionary,id:String,armor:float,duration:float)->void:
	unit.guardian_runtime.temporary_armor_sources=unit.guardian_runtime.temporary_armor_sources.filter(func(source):return str(source.get("id",""))!=id)
	unit.guardian_runtime.temporary_armor_sources.append({"id":id,"armor":armor,"remaining":duration})

static func begin_avatar(unit:Dictionary)->void:
	var bonus:=GuardianData.scaled(float(GuardianData.VALUES.avatar_health),int(unit.level))
	unit.guardian_runtime.avatar_remaining=float(GuardianData.VALUES.avatar_duration);unit.guardian_runtime.avatar_health_bonus=bonus
	unit.max_hp+=bonus;unit.hp+=bonus;unit["combat_radius"]=float(unit.get("combat_radius",42.0))*float(GuardianData.VALUES.avatar_hitbox_multiplier);telemetry_add(unit,"avatar_uses")

static func end_avatar(unit:Dictionary)->void:
	var bonus:float=float(unit.guardian_runtime.avatar_health_bonus)
	unit.max_hp=maxf(1.0,unit.max_hp-bonus);unit.hp=maxf(1.0,minf(unit.hp,unit.max_hp));unit.guardian_runtime.avatar_health_bonus=0.0;unit.guardian_runtime.avatar_remaining=0.0;unit["combat_radius"]=42.0

static func update_timers(unit:Dictionary,delta:float)->Dictionary:
	var runtime:Dictionary=unit.guardian_runtime;var result:={"second_wind_heal":0.0,"stoneform_heal":0.0,"avatar_ended":false}
	runtime.seconds_since_damage=float(runtime.seconds_since_damage)+delta;runtime.give_axe_remaining=maxf(0.0,float(runtime.give_axe_remaining)-delta);runtime.bronzebeard_empowered=maxf(0.0,float(runtime.bronzebeard_empowered)-delta)
	for source in runtime.temporary_armor_sources:source.remaining=maxf(0.0,float(source.remaining)-delta)
	runtime.temporary_armor_sources=runtime.temporary_armor_sources.filter(func(source):return float(source.remaining)>0.0)
	if float(runtime.avatar_remaining)>0.0:
		runtime.avatar_remaining=maxf(0.0,float(runtime.avatar_remaining)-delta)
		if runtime.avatar_remaining<=0.0:end_avatar(unit);result.avatar_ended=true
	if float(runtime.stoneform_remaining)>0.0:
		runtime.stoneform_remaining=maxf(0.0,float(runtime.stoneform_remaining)-delta);result.stoneform_heal=float(unit.max_hp)*float(GuardianData.VALUES.stoneform_fraction)/float(GuardianData.VALUES.stoneform_duration)*delta
	elif float(runtime.seconds_since_damage)>=float(GuardianData.VALUES.second_wind_delay):
		var profile:=second_wind_profile(unit);runtime.second_wind_active=true;result.second_wind_heal=(float(profile.low) if unit.hp/unit.max_hp<float(profile.threshold) else float(profile.normal))*delta
	else:runtime.second_wind_active=false
	return result
