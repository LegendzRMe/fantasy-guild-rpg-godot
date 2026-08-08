extends RefCounted

const ShamanData=preload("res://scripts/data/shaman_data.gd")
const ProgressionScopeSystem=preload("res://scripts/systems/progression_scope_system.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func scaled(unit:Dictionary,value:float)->float:return ShamanData.scaled(value,int(unit.get("level",1)))
static func successful(result:Dictionary)->bool:return not bool(result.get("evaded",false)) and not bool(result.get("immune",false)) and float(result.get("resolved_damage",0.0))>0.0

static func default_telemetry()->Dictionary:
	var result:Dictionary={}
	for key in ["basic_hits","windfury_hits","tempest_subhits","frostwolf_stacks","frostwolf_activations","frostwolf_healing","frostwolf_overhealing","overflow_shield","q_casts","q_hits","q_bounces","q_repeat_hits","q_forks","stormcaller_casts","stormcaller_hits","w_casts","w_hits","w_extensions","w_distance","w_roots","w_root_resisted","w_return_casts","w_return_hits","e_casts","e_recasts","echo_progress","crash_progress","maelstrom_progress","feral_pack_progress","feral_pack_resets","rolling_consumed","rolling_damage","rolling_healing","ancestral_ready","ancestral_activations","ancestral_healing","gathering_generated","gathering_consumed","thunder_stacks","alpha_marks","worldbreaker_casts","worldbreaker_blocks","earthquake_pulses","earthen_shields"]:result[key]=0.0
	return result

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false,mastery:Dictionary={},encounter_id:String="")->void:
	unit["shaman_runtime"]={
		"frostwolf_stacks":0,"ancestral_stacks":0,"ancestral_ready":false,"ancestral_remaining":0.0,
		"windfury_remaining":0.0,"windfury_attacks":0,"windfury_targets":[],"elemental_remaining":0.0,"gathering_stacks":0,
		"feral_spirits":[],"earthquakes":[],"delayed_effects":[],"rolling_marks":{},"alpha_marks":{},"thunder_last_primary":"","thunder_stacks":0,
		"echo_assists":{},"q_slot":AbilitySlotSystem.create(1,float(ShamanData.VALUES.q_cooldown)),"mastery":mastery.duplicate(true),
		"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()
	}
	ProgressionScopeSystem.begin_encounter(unit.shaman_runtime,encounter_id if encounter_id!="" else ProgressionScopeSystem.new_encounter_id("shaman"))

static func telemetry_add(unit:Dictionary,key:String,value=1)->void:
	var runtime:Dictionary=unit.get("shaman_runtime",{});if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=runtime.telemetry.get(key,0)+value

static func mastery_progress(unit:Dictionary,talent_id:String)->int:return maxi(0,int(unit.get("shaman_runtime",{}).get("mastery",{}).get(talent_id,0)))
static func mastery_unlocked(unit:Dictionary,talent_id:String,goal:int)->bool:return mastery_progress(unit,talent_id)>=goal

static func add_mastery(unit:Dictionary,talent_id:String,amount:int=1)->int:
	var runtime:Dictionary=unit.shaman_runtime;runtime.mastery[talent_id]=maxi(0,int(runtime.mastery.get(talent_id,0))+amount);return int(runtime.mastery[talent_id])

static func encounter_progress(unit:Dictionary,key:String)->int:return int(unit.get("shaman_runtime",{}).get("encounter_progress",{}).get(key,0))
static func reward_active(unit:Dictionary,key:String)->bool:return ProgressionScopeSystem.reward_active(unit.shaman_runtime,key)

static func ability_amount(unit:Dictionary,value:float)->float:
	var level:=int(unit.get("level",1));var expected:=maxf(0.001,scaled(unit,float(ShamanData.VALUES.basic_attack_damage)));var ratio:=maxf(0.0,float(unit.get("power",expected)))/expected
	return scaled(unit,value)*ratio

static func frostwolf_heal_amount(unit:Dictionary)->float:
	var amount:=ability_amount(unit,float(ShamanData.VALUES.trait_heal))
	if has_talent(unit,"shaman_l9_3") and mastery_unlocked(unit,"shaman_l9_3",int(ShamanData.VALUES.maelstrom_mythic)):amount*=3.0
	return amount

static func add_frostwolf_stacks(unit:Dictionary,count:int,health_before:float=-1.0)->Array:
	var activations:Array=[];if count<=0:return activations
	var runtime:Dictionary=unit.shaman_runtime;runtime.frostwolf_stacks=int(runtime.frostwolf_stacks)+count;telemetry_add(unit,"frostwolf_stacks",count)
	while int(runtime.frostwolf_stacks)>=int(ShamanData.VALUES.trait_threshold):
		runtime.frostwolf_stacks=int(runtime.frostwolf_stacks)-int(ShamanData.VALUES.trait_threshold)
		if has_talent(unit,"shaman_l18_2"):
			runtime.ancestral_stacks=mini(int(ShamanData.VALUES.ancestral_max),int(runtime.ancestral_stacks)+1)
			if int(runtime.ancestral_stacks)>=int(ShamanData.VALUES.ancestral_max):runtime.ancestral_ready=true;telemetry_add(unit,"ancestral_ready")
		activations.append({"raw_healing":frostwolf_heal_amount(unit),"health_before":health_before if health_before>=0.0 else float(unit.get("hp",0.0))});telemetry_add(unit,"frostwolf_activations")
	return activations

static func overflow_shield_request(unit:Dictionary,activation:Dictionary,healing_result:Dictionary)->Dictionary:
	if not has_talent(unit,"shaman_l12_3"):return {}
	if float(activation.get("health_before",0.0))/maxf(1.0,float(unit.get("max_hp",1.0)))<=0.80:return {}
	var amount:=float(healing_result.get("overhealing",0.0))*float(ShamanData.VALUES.overflow_rate);if amount<=0.0:return {}
	return {"amount":amount,"cap":float(unit.max_hp)*float(ShamanData.VALUES.overflow_cap),"duration":float(ShamanData.VALUES.overflow_duration),"source_id":"shaman_overflowing_resilience"}

static func gathering_snapshot(unit:Dictionary)->float:
	if not has_talent(unit,"shaman_l21_3"):return 1.0
	var stacks:=int(unit.shaman_runtime.gathering_stacks);unit.shaman_runtime.gathering_stacks=0;telemetry_add(unit,"gathering_consumed",stacks);return 1.0+stacks*float(ShamanData.VALUES.gathering_per_stack)

static func note_ability_cast(unit:Dictionary,is_basic:bool=true)->void:
	if has_talent(unit,"shaman_l18_3"):unit.shaman_runtime.elemental_remaining=float(ShamanData.VALUES.elemental_duration)
	if not is_basic:return

static func note_ability_contacts(unit:Dictionary,contact_count:int)->bool:
	if has_talent(unit,"shaman_l18_2") and bool(unit.shaman_runtime.ancestral_ready) and contact_count>=2:
		unit.shaman_runtime.ancestral_ready=false;unit.shaman_runtime.ancestral_stacks=0;unit.shaman_runtime.ancestral_remaining=float(ShamanData.VALUES.ancestral_duration);telemetry_add(unit,"ancestral_activations");return true
	return false

static func note_damage(unit:Dictionary,resolved_damage:float)->float:
	if resolved_damage<=0.0 or float(unit.get("shaman_runtime",{}).get("ancestral_remaining",0.0))<=0.0:return 0.0
	return resolved_damage*float(ShamanData.VALUES.ancestral_heal)

static func alpha_multiplier(unit:Dictionary,target_id:String)->float:
	if not has_talent(unit,"shaman_l24_3") or float(unit.get("shaman_runtime",{}).get("alpha_marks",{}).get(target_id,0.0))<=0.0:return 1.0
	return 1.0+float(ShamanData.VALUES.alpha_bonus)

static func mark_alpha(unit:Dictionary,target_id:String)->void:
	if not has_talent(unit,"shaman_l24_3"):return
	unit.shaman_runtime.alpha_marks[target_id]=float(ShamanData.SPACE.alpha_mark_duration);telemetry_add(unit,"alpha_marks")

static func mark_rolling(unit:Dictionary,target_id:String)->void:
	if has_talent(unit,"shaman_l18_1"):unit.shaman_runtime.rolling_marks[target_id]=float(ShamanData.VALUES.rolling_duration)

static func note_basic_attack(unit:Dictionary,target_id:String,result:Dictionary,origin:String="normal_basic_attack")->Dictionary:
	if not successful(result):return {"successful":false}
	telemetry_add(unit,"basic_hits");var runtime:Dictionary=unit.shaman_runtime;var output:={"successful":true,"frostwolf_stacks":0,"bonus_damage":0.0,"rolling":false,"tempest_subhits":0,"windfury_finished":false,"fury_recast":false}
	var windfury:=origin.begins_with("windfury_attack_")
	if origin=="tempest_fury_subhit":telemetry_add(unit,"tempest_subhits");return output
	if has_talent(unit,"shaman_l21_3"):runtime.gathering_stacks=mini(int(ShamanData.VALUES.gathering_max),int(runtime.gathering_stacks)+1);telemetry_add(unit,"gathering_generated")
	if float(runtime.elemental_remaining)>0.0:output.bonus_damage+=float(result.get("resolved_damage",0.0))*float(ShamanData.VALUES.elemental_bonus);runtime.elemental_remaining=0.0
	if runtime.rolling_marks.has(target_id) and float(runtime.rolling_marks[target_id])>0.0:
		output.rolling=true;output.bonus_damage+=float(result.get("resolved_damage",0.0))*float(ShamanData.VALUES.rolling_bonus);runtime.rolling_marks.erase(target_id);output.frostwolf_stacks+=1;telemetry_add(unit,"rolling_consumed")
	if windfury:
		telemetry_add(unit,"windfury_hits");runtime.windfury_attacks=maxi(0,int(runtime.windfury_attacks)-1);output.frostwolf_stacks+=2 if has_talent(unit,"shaman_l21_1") else 1
		if target_id not in runtime.windfury_targets:runtime.windfury_targets.append(target_id)
		if has_talent(unit,"shaman_l9_3"):var progress:=ProgressionScopeSystem.add_encounter_progress(runtime,"maelstrom",1);add_mastery(unit,"shaman_l9_3",1);telemetry_add(unit,"maelstrom_progress");update_level9_rewards(unit,"maelstrom",progress)
		if int(runtime.windfury_attacks)<=0:
			output.windfury_finished=true;output.tempest_subhits=int(ShamanData.VALUES.tempest_subhits) if has_talent(unit,"shaman_l24_1") else 0
			output.fury_recast=has_talent(unit,"shaman_l30_2") and runtime.windfury_targets.size()>=3
	return output

static func update_level9_rewards(unit:Dictionary,quest:String,progress:int)->void:
	var runtime:Dictionary=unit.shaman_runtime
	if quest=="echo":
		if progress>=int(ShamanData.VALUES.echo_reward_1):
			ProgressionScopeSystem.set_reward(runtime,"echo_1");runtime.q_slot.recharge_duration=q_cooldown(unit)
		if progress>=int(ShamanData.VALUES.echo_reward_2) and not reward_active(unit,"echo_2"):
			ProgressionScopeSystem.set_reward(runtime,"echo_2");runtime.q_slot.max_charges=2;runtime.q_slot.current_charges=mini(2,int(runtime.q_slot.current_charges)+1)
	elif quest=="crash":
		if progress>=int(ShamanData.VALUES.crash_reward_1):ProgressionScopeSystem.set_reward(runtime,"crash_1")
		if progress>=int(ShamanData.VALUES.crash_reward_2):ProgressionScopeSystem.set_reward(runtime,"crash_2")
	elif quest=="maelstrom":
		if progress>=int(ShamanData.VALUES.maelstrom_reward_1):ProgressionScopeSystem.set_reward(runtime,"maelstrom_1")
		if progress>=int(ShamanData.VALUES.maelstrom_reward_2):ProgressionScopeSystem.set_reward(runtime,"maelstrom_2")

static func note_chain_cast(unit:Dictionary,primary_id:String,qualifying_ids:Array,source_tag:String="player_chain",quest_ids=null)->Dictionary:
	var runtime:Dictionary=unit.shaman_runtime;var unique:Dictionary={};for id in qualifying_ids:unique[str(id)]=true
	var quest_unique:Dictionary={};for id in (qualifying_ids if quest_ids==null else quest_ids):quest_unique[str(id)]=true
	var count:=unique.size();var quest_count:=quest_unique.size();var result:={"qualifying_count":count,"quest_count":quest_count,"crash_bonus_stacks":0,"stormcaller":false}
	if source_tag=="player_chain":
		telemetry_add(unit,"q_casts")
		if has_talent(unit,"shaman_l9_2") and quest_count>=3:
			var progress:=ProgressionScopeSystem.add_encounter_progress(runtime,"crash",1);add_mastery(unit,"shaman_l9_2",1);telemetry_add(unit,"crash_progress");update_level9_rewards(unit,"crash",progress)
			if reward_active(unit,"crash_2"):result.crash_bonus_stacks=2
		if has_talent(unit,"shaman_l24_2") and primary_id!="" and primary_id!=str(runtime.thunder_last_primary):runtime.thunder_last_primary=primary_id;runtime.thunder_stacks=mini(int(ShamanData.VALUES.thunder_max),int(runtime.thunder_stacks)+1);telemetry_add(unit,"thunder_stacks")
		result.stormcaller=has_talent(unit,"shaman_l30_1") and count>=int(ShamanData.VALUES.stormcaller_threshold)
	return result

static func chain_bounce_bonus(unit:Dictionary)->float:
	var bonus:=0.0
	if has_talent(unit,"shaman_l9_2"):
		if reward_active(unit,"crash_1"):bonus+=ability_amount(unit,float(ShamanData.VALUES.crash_bounce_bonus))
		if mastery_unlocked(unit,"shaman_l9_2",int(ShamanData.VALUES.crash_mythic)):bonus+=ability_amount(unit,float(ShamanData.VALUES.crash_mythic_bonus))
	return bonus

static func q_cooldown(unit:Dictionary)->float:return maxf(0.1,float(ShamanData.VALUES.q_cooldown)-(float(ShamanData.VALUES.echo_cooldown_reduction) if reward_active(unit,"echo_1") else 0.0))
static func q_max_charges(unit:Dictionary)->int:return 2 if reward_active(unit,"echo_2") else 1

static func note_echo_defeat(unit:Dictionary,target_id:String)->bool:
	if not has_talent(unit,"shaman_l9_1") or not unit.shaman_runtime.echo_assists.has(target_id):return false
	if float(unit.shaman_runtime.echo_assists[target_id])<=0.0:return false
	unit.shaman_runtime.echo_assists.erase(target_id);var progress:=ProgressionScopeSystem.add_encounter_progress(unit.shaman_runtime,"echo",1);add_mastery(unit,"shaman_l9_1",1);telemetry_add(unit,"echo_progress");update_level9_rewards(unit,"echo",progress);return true

static func note_feral_cast(unit:Dictionary,qualifying_count:int)->void:
	if not has_talent(unit,"shaman_l12_2"):return
	if qualifying_count<=0:
		if not reward_active(unit,"frostwolf_pack"):unit.shaman_runtime.encounter_progress["frostwolf_pack"]=0;telemetry_add(unit,"feral_pack_resets")
		return
	var progress:=ProgressionScopeSystem.add_encounter_progress(unit.shaman_runtime,"frostwolf_pack",1);telemetry_add(unit,"feral_pack_progress")
	if progress>=int(ShamanData.VALUES.frostwolf_pack_goal):ProgressionScopeSystem.set_reward(unit.shaman_runtime,"frostwolf_pack")

static func feral_cooldown(unit:Dictionary)->float:return float(ShamanData.VALUES.w_cooldown)*(0.5 if reward_active(unit,"frostwolf_pack") else 1.0)
static func windfury_movement_multiplier(unit:Dictionary)->float:
	var bonus:=float(ShamanData.VALUES.e_speed)
	if reward_active(unit,"maelstrom_1"):bonus=maxf(bonus,float(ShamanData.VALUES.maelstrom_move_1))
	if reward_active(unit,"maelstrom_2"):bonus+=float(ShamanData.VALUES.maelstrom_move_2)
	return 1.0+bonus

static func begin_windfury(unit:Dictionary,automatic:bool=false)->void:
	unit.shaman_runtime.windfury_remaining=float(ShamanData.VALUES.e_duration);unit.shaman_runtime.windfury_attacks=int(ShamanData.VALUES.e_attacks);unit.shaman_runtime.windfury_targets=[];telemetry_add(unit,"e_recasts" if automatic else "e_casts")

static func activate_frostwolf_grace(unit:Dictionary)->Dictionary:
	if not has_talent(unit,"shaman_l21_2") or float(unit.ability_cds[4])>0.0:return {}
	unit.ability_cds[4]=float(ShamanData.VALUES.frostwolf_grace_cooldown);var missing:=1.0-float(unit.hp)/maxf(1.0,float(unit.max_hp));return {"raw_healing":frostwolf_heal_amount(unit)*(1.0+missing*float(ShamanData.VALUES.frostwolf_grace_missing_bonus)),"health_before":float(unit.hp)}

static func update(unit:Dictionary,delta:float)->void:
	var runtime:Dictionary=unit.get("shaman_runtime",{});if runtime.is_empty():return
	for key in ["windfury_remaining","elemental_remaining","ancestral_remaining"]:runtime[key]=maxf(0.0,float(runtime[key])-delta)
	for marks_key in ["rolling_marks","alpha_marks","echo_assists"]:
		for id in runtime[marks_key].keys():runtime[marks_key][id]=float(runtime[marks_key][id])-delta;if float(runtime[marks_key][id])<=0.0:runtime[marks_key].erase(id)
	if float(runtime.windfury_remaining)<=0.0:runtime.windfury_attacks=0;runtime.windfury_targets=[]
	AbilitySlotSystem.update(runtime.q_slot,delta)

static func reset_encounter(unit:Dictionary,new_encounter_id:String="")->void:
	var mastery:Dictionary=unit.get("shaman_runtime",{}).get("mastery",{}).duplicate(true);var telemetry_enabled:=bool(unit.get("shaman_runtime",{}).get("telemetry_enabled",false));initialize_runtime(unit,telemetry_enabled,mastery,new_encounter_id)
