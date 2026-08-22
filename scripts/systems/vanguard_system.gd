extends RefCounted

const VanguardData=preload("res://scripts/data/vanguard_data.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")
const BlockChargeSystem=preload("res://scripts/systems/block_charge_system.gd")
const StatusEffectSystem=preload("res://scripts/systems/status_effect_system.gd")
const QuestProgressModifierSystem=preload("res://scripts/systems/quest_progress_modifier_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func owner_id(unit:Dictionary)->String:return str(unit.get("combat_id","vanguard"))
static func telemetry_default()->Dictionary:
	var result:={}
	for key in ["q_casts","q_contacts","q_stuns","q_misses","w_casts","w_contacts","w_displacements","e_casts","e_contacts","e_flips","basic_rockstar","heroic_rockstar","rockstar_armor","rockstar_mitigation","block_grants","stun_extensions","prog_progress","prog_completions","prog_triggers","prog_healing","wall_collisions","wall_damage","mosh_casts","mosh_stuns","mosh_interruptions","lightning_casts","lightning_hits","lightning_slow_points","pinball_hits","hammer_damage","echo_pulses","echo_hits","mic_cdr","encore_amp_contacts","encore_heroic_cdr","roots","silences","tour_slides","mosh_extension","encore_taunts","death_metal_triggers","death_metal_damage_taken","death_metal_healing","death_metal_survives","death_metal_defeats","resisted_control","resisted_displacement"]:result[key]=0.0
	return result
static func add(unit:Dictionary,key:String,amount:float=1.0)->void:
	if bool(unit.get("vanguard_runtime",{}).get("telemetry_enabled",false)):unit.vanguard_runtime.telemetry[key]=float(unit.vanguard_runtime.telemetry.get(key,0.0))+amount

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false,encounter_id:String="battle")->void:
	var e_charges:=3 if has_talent(unit,"vanguard_l24_3") else 1
	unit["vanguard_runtime"]={
		"e_slot":AbilitySlotSystem.create(e_charges,float(VanguardData.VALUES.e_cooldown),AbilitySlotSystem.RechargeMode.SEQUENTIAL),
		"quest":{"encounter_id":encounter_id,"progress":0,"complete":false},"healing_areas":[],"pinball":{},"delayed_roots":[],"amps":[],"echoes":[],"encore_marks":{},
		"mosh":{},"lightning":{},"heroic_windup":{},"wall_speed_remaining":0.0,"death_metal":{},"death_metal_icd":0.0,
		"latest_contacts":{},"telemetry_enabled":telemetry_enabled,"telemetry":telemetry_default()}
	unit["base_basic_action_interval"]=float(VanguardData.VALUES.basic_attack_interval);unit["basic_attack_interval"]=float(VanguardData.VALUES.basic_attack_interval);unit["range"]=float(VanguardData.SPACE.basic_range)
	BlockChargeSystem.initialize(unit,"block_state",int(VanguardData.VALUES.block_max))

static func contact_count(count:int)->int:return mini(maxi(0,count),int(VanguardData.VALUES.contact_cap))
static func note_contacts(unit:Dictionary,slot:String,count:int)->int:
	var capped:=contact_count(count);unit.vanguard_runtime.latest_contacts[slot]=capped;add(unit,"%s_contacts"%slot.to_lower(),capped);return capped
static func movement_multiplier(unit:Dictionary)->float:return 1.0+float(VanguardData.VALUES.wall_move) if float(unit.get("vanguard_runtime",{}).get("wall_speed_remaining",0.0))>0.0 else 1.0
static func e_ui_cooldown(unit:Dictionary)->float:
	var ui:=AbilitySlotSystem.ui_state(unit.vanguard_runtime.e_slot);return 0.0 if int(ui.charges)>0 and float(ui.lockout)<=0.0 else maxf(float(ui.recharge),float(ui.lockout))
static func spend_overpower(unit:Dictionary)->bool:return AbilitySlotSystem.spend(unit.vanguard_runtime.e_slot,float(VanguardData.VALUES.e_lockout) if has_talent(unit,"vanguard_l24_3") else 0.0)

static func q_plan(unit:Dictionary,contacts:int)->Dictionary:
	var capped:=note_contacts(unit,"Q",contacts);add(unit,"q_casts")
	if capped==0:add(unit,"q_misses")
	if has_talent(unit,"vanguard_l12_3"):unit.vanguard_runtime.wall_speed_remaining=float(VanguardData.VALUES.wall_move_duration)
	return {"damage":VanguardData.scaled(float(VanguardData.VALUES.q_damage),int(unit.level)),"contacts":capped,"stun":float(VanguardData.VALUES.q_stun),"cross_terrain":has_talent(unit,"vanguard_l12_1"),"push":has_talent(unit,"vanguard_l12_3")}
static func finish_q(unit:Dictionary,contacts:int)->float:
	if contacts>0 or not has_talent(unit,"vanguard_l12_1"):return 0.0
	var reduced:=minf(float(unit.ability_cds[0]),float(VanguardData.VALUES.crowd_surfer_cdr));unit.ability_cds[0]-=reduced;return reduced
static func w_plan(unit:Dictionary,target_ids:Array)->Dictionary:
	var capped:=note_contacts(unit,"W",target_ids.size());add(unit,"w_casts");var empowered:Array=[]
	for id in target_ids.slice(0,capped):if float(unit.vanguard_runtime.pinball.get(str(id),0.0))>0.0:empowered.append(str(id));unit.vanguard_runtime.pinball.erase(str(id))
	if has_talent(unit,"vanguard_l21_1") and capped>=2:var reduced:=minf(float(unit.ability_cds[1]),float(VanguardData.VALUES.mic_check_cdr));unit.ability_cds[1]-=reduced;add(unit,"mic_cdr",reduced)
	return {"damage":VanguardData.scaled(float(VanguardData.VALUES.w_damage),int(unit.level)),"contacts":capped,"empowered":empowered,"displacement":float(VanguardData.SPACE.w_displacement)*(float(VanguardData.VALUES.loud_multiplier) if has_talent(unit,"vanguard_l12_2") else 1.0),"pull":has_talent(unit,"vanguard_l21_3"),"radius":float(VanguardData.SPACE.w_radius)*(float(VanguardData.VALUES.loud_multiplier) if has_talent(unit,"vanguard_l12_2") else 1.0)}
static func e_plan(unit:Dictionary)->Dictionary:
	add(unit,"e_casts");note_contacts(unit,"E",1);return {"damage":VanguardData.scaled(float(VanguardData.VALUES.e_damage),int(unit.level)),"stun":float(VanguardData.VALUES.e_stun)}

static func note_stun(unit:Dictionary,ability:String,target_id:String,qualifies_quest:bool=true)->Dictionary:
	add(unit,"%s_stuns"%ability.to_lower());var result:={"heal_created":false,"quest_completed":false}
	if has_talent(unit,"vanguard_l9_2"):
		if qualifies_quest and not bool(unit.vanguard_runtime.quest.complete) and ability in ["Q","E"]:
			var gained:=mini(2,QuestProgressModifierSystem.amount(unit,1));unit.vanguard_runtime.quest.progress=mini(int(VanguardData.VALUES.prog_requirement),int(unit.vanguard_runtime.quest.progress)+gained);add(unit,"prog_progress",gained)
			if int(unit.vanguard_runtime.quest.progress)>=int(VanguardData.VALUES.prog_requirement):unit.vanguard_runtime.quest.complete=true;result.quest_completed=true;add(unit,"prog_completions")
		if qualifies_quest and bool(unit.vanguard_runtime.quest.complete):unit.vanguard_runtime.healing_areas.append({"remaining":float(VanguardData.VALUES.prog_duration),"tick":1.0,"source_target":target_id});result.heal_created=true;add(unit,"prog_triggers")
	return result
static func mark_pinball(unit:Dictionary,target_id:String)->void:if has_talent(unit,"vanguard_l18_1"):unit.vanguard_runtime.pinball[target_id]=float(VanguardData.VALUES.pinball_duration)
static func basic_attack_multiplier(unit:Dictionary,target:Dictionary)->float:return 1.0+float(VanguardData.VALUES.hammer_bonus) if has_talent(unit,"vanguard_l18_2") and target.get("active_effects",[]).any(func(effect):return str(effect.get("control_type",""))=="stun" and float(effect.get("remaining_duration",0.0))>0.0) else 1.0
static func note_basic_attack(unit:Dictionary,target:Dictionary,successful:bool)->bool:
	if not successful or not has_talent(unit,"vanguard_l9_1"):return false
	var extended:=StatusEffectSystem.extend_control_seconds(target,"stun",float(VanguardData.VALUES.stun_extension));if extended<=0.0:return false
	add(unit,"stun_extensions",extended/float(VanguardData.VALUES.stun_extension));return true

static func commit_ability(unit:Dictionary,heroic:bool)->Dictionary:
	var horde:=has_talent(unit,"vanguard_l30_2");var armor:=float(VanguardData.VALUES.horde_heroic if heroic and horde else VanguardData.VALUES.horde_basic if horde else VanguardData.VALUES.rockstar_heroic if heroic else VanguardData.VALUES.rockstar_basic)
	add(unit,"heroic_rockstar" if heroic else "basic_rockstar");add(unit,"rockstar_armor",VanguardData.scaled(armor,int(unit.level)))
	if has_talent(unit,"vanguard_l18_3"):unit.vanguard_runtime.echoes.append({"remaining":0.0});unit.vanguard_runtime.echoes.append({"remaining":float(VanguardData.VALUES.echo_second_delay)})
	return {"armor":VanguardData.scaled(armor,int(unit.level)),"duration":float(VanguardData.VALUES.rockstar_duration),"party":horde,"block_party":has_talent(unit,"vanguard_l9_3")}

static func begin_heroic(unit:Dictionary,heroic_id:String,emergency:bool=false)->bool:
	if not emergency and float(unit.ability_cds[3])>0.0:return false
	var mosh:=heroic_id=="vanguard_l15_r1";var windup:=0.0 if emergency else float(VanguardData.VALUES.mosh_windup if mosh else VanguardData.VALUES.lightning_windup)
	var duration:=float(VanguardData.VALUES.mosh_duration if mosh else VanguardData.VALUES.hellstorm_duration if has_talent(unit,"vanguard_l27_r2") and not emergency else VanguardData.VALUES.lightning_duration)
	unit.vanguard_runtime.heroic_windup={"id":heroic_id,"remaining":windup,"duration":duration,"emergency":emergency};if not emergency:unit.ability_cds[3]=float(VanguardData.VALUES.mosh_cooldown if mosh else VanguardData.VALUES.lightning_cooldown)
	if mosh and has_talent(unit,"vanguard_l27_r1") and not emergency:unit.ability_cds[0]=0.0
	add(unit,"mosh_casts" if mosh else "lightning_casts");return true
static func activate_heroic(unit:Dictionary)->Dictionary:
	var windup:Dictionary=unit.vanguard_runtime.heroic_windup;if windup.is_empty():return {}
	var id:=str(windup.id);var state:={"remaining":float(windup.duration),"duration":float(windup.duration),"emergency":bool(windup.emergency)};unit.vanguard_runtime.heroic_windup={}
	if id=="vanguard_l15_r1":unit.vanguard_runtime.mosh=state
	else:state["tick"]=0.0;unit.vanguard_runtime.lightning=state
	return {"id":id,"emergency":bool(state.emergency)}
static func interrupt_mosh(unit:Dictionary)->bool:
	if unit.get("vanguard_runtime",{}).get("mosh",{}).is_empty() or bool(unit.vanguard_runtime.mosh.get("emergency",false)):return false
	unit.vanguard_runtime.mosh={};add(unit,"mosh_interruptions");return true
static func tour_bus_slide(unit:Dictionary)->bool:
	if not has_talent(unit,"vanguard_l27_r1") or unit.vanguard_runtime.mosh.is_empty():return false
	unit.vanguard_runtime.mosh.remaining=float(unit.vanguard_runtime.mosh.remaining)+float(VanguardData.VALUES.tour_extension);unit.vanguard_runtime.mosh.duration=float(unit.vanguard_runtime.mosh.duration)+float(VanguardData.VALUES.tour_extension);add(unit,"tour_slides");add(unit,"mosh_extension",float(VanguardData.VALUES.tour_extension));return true

static func try_death_metal(unit:Dictionary,would_die:bool)->bool:
	if not would_die or not has_talent(unit,"vanguard_l30_3") or float(unit.vanguard_runtime.death_metal_icd)>0.0 or not unit.vanguard_runtime.death_metal.is_empty():return false
	var emergency_id:="vanguard_l15_r2" if str(unit.selected_heroic_id)=="vanguard_l15_r1" else "vanguard_l15_r1";unit.vanguard_runtime.death_metal={"remaining":float(VanguardData.VALUES.death_metal_duration),"heroic_id":emergency_id,"resolving":false};unit.vanguard_runtime.death_metal_icd=float(VanguardData.VALUES.lightning_cooldown if emergency_id=="vanguard_l15_r2" else VanguardData.VALUES.mosh_cooldown);begin_heroic(unit,emergency_id,true);activate_heroic(unit);add(unit,"death_metal_triggers");return true
static func death_metal_floor(unit:Dictionary,amount:float)->float:return maxf(0.0,float(unit.hp)-1.0) if not unit.get("vanguard_runtime",{}).get("death_metal",{}).is_empty() else amount

static func advance(unit:Dictionary,delta:float)->Array:
	var events:Array=[];var rt:Dictionary=unit.vanguard_runtime;AbilitySlotSystem.update(rt.e_slot,delta);rt.wall_speed_remaining=maxf(0.0,float(rt.wall_speed_remaining)-delta);rt.death_metal_icd=maxf(0.0,float(rt.death_metal_icd)-delta)
	for key in ["pinball","encore_marks"]:
		for id in rt[key].keys():
			rt[key][id]=float(rt[key][id])-delta
			if float(rt[key][id])<=0.0:
				if key=="encore_marks":events.append({"kind":"encore_taunt","target_id":id})
				rt[key].erase(id)
	for collection in ["delayed_roots","amps","echoes"]:
		for item in rt[collection]:item.remaining=float(item.remaining)-delta
	for item in rt.delayed_roots.filter(func(value):return float(value.remaining)<=0.0):events.append({"kind":"root","target_id":str(item.target_id)})
	rt.delayed_roots=rt.delayed_roots.filter(func(value):return float(value.remaining)>0.0)
	for item in rt.amps.filter(func(value):return float(value.remaining)<=0.0):events.append({"kind":"amp","position":Vector2(item.position)})
	rt.amps=rt.amps.filter(func(value):return float(value.remaining)>0.0)
	for item in rt.echoes.filter(func(value):return float(value.remaining)<=0.0):events.append({"kind":"echo"})
	rt.echoes=rt.echoes.filter(func(value):return float(value.remaining)>0.0)
	for area in rt.healing_areas:
		area.remaining=float(area.remaining)-delta;area.tick=float(area.tick)-delta
		while float(area.tick)<=0.0 and float(area.remaining)>=0.0:area.tick=float(area.tick)+1.0;events.append({"kind":"prog_heal"})
	rt.healing_areas=rt.healing_areas.filter(func(area):return float(area.remaining)>0.0)
	if not rt.heroic_windup.is_empty():rt.heroic_windup.remaining=float(rt.heroic_windup.remaining)-delta;if float(rt.heroic_windup.remaining)<=0.0:events.append({"kind":"heroic_activate"})
	if not rt.mosh.is_empty():rt.mosh.remaining=float(rt.mosh.remaining)-delta;if float(rt.mosh.remaining)<=0.0:var affected:Array=rt.mosh.get("affected",{}).keys();var emergency:=bool(rt.mosh.get("emergency",false));rt.mosh={};if not emergency:events.append({"kind":"mosh_end","targets":affected})
	if not rt.lightning.is_empty():rt.lightning.remaining=float(rt.lightning.remaining)-delta;rt.lightning.tick=float(rt.lightning.tick)-delta;while float(rt.lightning.tick)<=0.0 and float(rt.lightning.remaining)>=0.0:rt.lightning.tick=float(rt.lightning.tick)+float(VanguardData.VALUES.lightning_tick);events.append({"kind":"lightning_tick"});if float(rt.lightning.remaining)<=0.0:rt.lightning={}
	if not rt.death_metal.is_empty():rt.death_metal.remaining=float(rt.death_metal.remaining)-delta;if float(rt.death_metal.remaining)<=0.0:events.append({"kind":"death_metal_end"});rt.death_metal.resolving=true
	return events
