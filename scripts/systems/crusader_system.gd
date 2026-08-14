extends RefCounted
const CrusaderData=preload("res://scripts/data/crusader_data.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func telemetry_default()->Dictionary:
	var r:={};for key in ["q_casts","q_contacts","q_average_contacts","w_casts","w_contacts","w_average_contacts","e_casts","e_contacts","e_average_contacts","casts_2_plus","casts_3_plus","casts_4_plus","casts_5_plus","iron_skin_activations","iron_skin_shield","shield_absorbed","shield_breaks","last_shield_break_time","iron_skin_active_time","steed_extension","laws_healing","fortress_uptime","shrinking_mitigation","damage_prevented","indestructible_triggers","indestructible_absorbed","unbreakable_restoration","light_shields","punish_slows","subdue_activations","condemn_pulls","condemn_stuns","resisted_displacement","glare_blinds","blind_immune_contacts","blessed_stuns","falling_controls","radiating_targets","eternal_cdr","renewal_cdr","renewal_enhanced_cdr","momentum_cdr","heavens_cdr","light_icd_cdr","normal_threat","multi_target_threat","authority_activations","authority_targets","authority_bonus_threat","current_highest_threat_targets"]:r[key]=0.0
	return r
static func add(unit:Dictionary,key:String,amount:float=1.0)->void:
	if bool(unit.get("crusader_runtime",{}).get("telemetry_enabled",false)):unit.crusader_runtime.telemetry[key]=float(unit.crusader_runtime.telemetry.get(key,0.0))+amount
static func owner_id(unit:Dictionary)->String:return str(unit.get("combat_id","crusader"))
static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false)->void:
	var max_charges:=2 if has_talent(unit,"crusader_l9_1") else 1
	unit["crusader_runtime"]={"e_slot":AbilitySlotSystem.create(max_charges,float(CrusaderData.VALUES.e_cooldown),AbilitySlotSystem.RechargeMode.SEQUENTIAL),"condemn":{},"iron_skin":{"current":0.0,"maximum":0.0,"remaining":0.0,"active":false,"started_at":0.0},"laws":{"remaining":0.0,"tick":1.0,"per_tick":0.0},"subdue_complete":false,"eternal_marks":{},"condemned":{},"sins":{},"fortress_stacks":0,"fortress_remaining":0.0,"holy_fury_stacks":0,"holy_fury_remaining":0.0,"holy_fury_tick":1.0,"authority":{},"light_icd":0.0,"indestructible_icd":0.0,"falling":{},"latest_contacts":{},"telemetry_enabled":telemetry_enabled,"telemetry":telemetry_default()}
	unit["base_basic_action_interval"]=float(CrusaderData.VALUES.basic_attack_interval);unit["basic_attack_interval"]=float(CrusaderData.VALUES.basic_attack_interval);unit["range"]=float(CrusaderData.SPACE.basic_range);unit["healing_received_sources"]=unit.get("healing_received_sources",[])
static func contact_count(value:int)->int:return mini(maxi(0,value),int(CrusaderData.VALUES.contact_cap))
static func note_contacts(unit:Dictionary,slot:String,count:int)->void:
	var capped:=contact_count(count);add(unit,"%s_contacts"%slot.to_lower(),capped);unit.crusader_runtime.latest_contacts[slot]=capped
	if bool(unit.crusader_runtime.telemetry_enabled):var prefix:=slot.to_lower();unit.crusader_runtime.telemetry["%s_average_contacts"%prefix]=float(unit.crusader_runtime.telemetry.get("%s_contacts"%prefix,0.0))/maxf(1.0,float(unit.crusader_runtime.telemetry.get("%s_casts"%prefix,0.0)))
	for threshold in range(2,6):if capped>=threshold:add(unit,"casts_%d_plus"%threshold)
static func movement_multiplier(unit:Dictionary)->float:
	if not has_talent(unit,"crusader_l18_2"):return 1.0
	return 1.0+float(CrusaderData.VALUES.conviction_charge if not unit.get("crusader_runtime",{}).get("condemn",{}).is_empty() else CrusaderData.VALUES.conviction_passive)
static func begin_condemn(unit:Dictionary)->bool:
	if float(unit.ability_cds[1])>0.0 or not unit.crusader_runtime.condemn.is_empty():return false
	unit.ability_cds[1]=float(CrusaderData.VALUES.w_cooldown);unit.crusader_runtime.condemn={"remaining":float(CrusaderData.VALUES.w_delay),"ready":false};add(unit,"w_casts");return true
static func take_condemn_resolution(unit:Dictionary)->bool:
	if unit.crusader_runtime.condemn.is_empty() or not bool(unit.crusader_runtime.condemn.get("ready",false)):return false
	unit.crusader_runtime.condemn={};return true
static func q_plan(unit:Dictionary,hits:int)->Dictionary:
	var capped:=contact_count(hits);var empowered:=has_talent(unit,"crusader_l12_1") and (capped>=2 or bool(unit.crusader_runtime.subdue_complete));var damage:=CrusaderData.scaled(float(CrusaderData.VALUES.q_damage),int(unit.level))
	if has_talent(unit,"crusader_l21_1"):damage*=1.0+float(CrusaderData.VALUES.roar_many if capped>=2 else CrusaderData.VALUES.roar_one)
	if has_talent(unit,"crusader_l12_1") and capped>=4:unit.crusader_runtime.subdue_complete=true;add(unit,"subdue_activations")
	if has_talent(unit,"crusader_l24_3"):var reduction:=minf(float(unit.ability_cds[4]),float(capped)*float(CrusaderData.VALUES.momentum_cdr));unit.ability_cds[4]-=reduction;add(unit,"momentum_cdr",reduction)
	add(unit,"q_casts");note_contacts(unit,"Q",capped);return {"damage":damage,"slow":float(CrusaderData.VALUES.subdue_slow if empowered else CrusaderData.VALUES.q_slow),"slow_duration":float(CrusaderData.VALUES.q_slow_duration),"decays":not empowered,"contacts":capped}
static func w_plan(unit:Dictionary,hits:int)->Dictionary:
	var capped:=contact_count(hits);if has_talent(unit,"crusader_l21_2"):unit.crusader_runtime.holy_fury_stacks=capped;unit.crusader_runtime.holy_fury_remaining=float(CrusaderData.VALUES.holy_fury_duration)
	note_contacts(unit,"W",capped);return {"damage":CrusaderData.scaled(float(CrusaderData.VALUES.w_damage),int(unit.level)),"contacts":capped,"reduction":float(capped)*float(CrusaderData.VALUES.shrinking_per_hit) if has_talent(unit,"crusader_l24_1") else 0.0}
static func e_plan(unit:Dictionary,hits:int,condemned_hits:int)->Dictionary:
	var capped:=contact_count(hits);var enhanced:=mini(capped,maxi(0,condemned_hits));var cdr:=0.0
	if has_talent(unit,"crusader_l24_2"):cdr=float(enhanced)*float(CrusaderData.VALUES.holy_renewal_condemned_cdr)+float(capped-enhanced)*float(CrusaderData.VALUES.holy_renewal_cdr);var actual:=AbilitySlotSystem.reduce_active_recharge(unit.crusader_runtime.e_slot,cdr);add(unit,"renewal_cdr",actual);add(unit,"renewal_enhanced_cdr",minf(actual,float(enhanced)*.5))
	if has_talent(unit,"crusader_l30_2"):var light_reduction:=minf(float(unit.crusader_runtime.light_icd),float(capped)*float(CrusaderData.VALUES.light_e_cdr));unit.crusader_runtime.light_icd-=light_reduction;add(unit,"light_icd_cdr",light_reduction)
	add(unit,"e_casts");note_contacts(unit,"E",capped);return {"damage":CrusaderData.scaled(float(CrusaderData.VALUES.e_damage),int(unit.level))*(1.0+float(CrusaderData.VALUES.zealous_damage) if has_talent(unit,"crusader_l9_1") else 1.0),"contacts":capped,"cdr":cdr}
static func spend_glare(unit:Dictionary)->bool:
	if not AbilitySlotSystem.spend(unit.crusader_runtime.e_slot,float(CrusaderData.VALUES.e_recast)):return false
	if has_talent(unit,"crusader_l18_3") and bool(unit.crusader_runtime.iron_skin.active):unit.crusader_runtime.iron_skin.remaining=float(unit.crusader_runtime.iron_skin.remaining)+float(CrusaderData.VALUES.steed_extension);add(unit,"steed_extension",float(CrusaderData.VALUES.steed_extension))
	return true
static func glare_ui_cooldown(unit:Dictionary)->float:
	var ui:=AbilitySlotSystem.ui_state(unit.crusader_runtime.e_slot);return 0.0 if int(ui.charges)>0 else float(ui.recharge)
static func iron_skin_plan(unit:Dictionary)->Dictionary:
	if float(unit.ability_cds[4])>0.0:return {}
	var maximum:=CrusaderData.scaled(float(CrusaderData.VALUES.d_shield),int(unit.level))*(1.0+float(CrusaderData.VALUES.hold_shield) if has_talent(unit,"crusader_l12_3") else 1.0);var duration:=float(CrusaderData.VALUES.d_duration)+(float(CrusaderData.VALUES.steed_duration) if has_talent(unit,"crusader_l18_3") else 0.0)
	unit.ability_cds[4]=float(CrusaderData.VALUES.d_cooldown)-(float(CrusaderData.VALUES.hold_cdr) if has_talent(unit,"crusader_l12_3") else 0.0);unit.crusader_runtime.iron_skin={"current":maximum,"maximum":maximum,"remaining":duration,"active":true,"elapsed":0.0};add(unit,"iron_skin_activations");add(unit,"iron_skin_shield",maximum)
	if has_talent(unit,"crusader_l9_3"):unit.crusader_runtime.laws={"remaining":float(CrusaderData.VALUES.laws_duration),"tick":1.0,"per_tick":float(unit.max_hp)*float(CrusaderData.VALUES.laws_fraction)/float(CrusaderData.VALUES.laws_duration)}
	return {"maximum":maximum,"duration":duration}
static func sync_iron_skin(unit:Dictionary,current:float,remaining:float)->bool:
	var was_active:=bool(unit.crusader_runtime.iron_skin.active);var old_remaining:=float(unit.crusader_runtime.iron_skin.remaining);unit.crusader_runtime.iron_skin.current=maxf(0.0,current);unit.crusader_runtime.iron_skin.remaining=maxf(0.0,remaining);unit.crusader_runtime.iron_skin.active=current>0.0 and remaining>0.0
	if was_active and not bool(unit.crusader_runtime.iron_skin.active) and current<=0.0 and old_remaining>0.0:add(unit,"shield_breaks");unit.crusader_runtime.telemetry.last_shield_break_time=float(unit.crusader_runtime.iron_skin.get("elapsed",0.0))
	return bool(unit.crusader_runtime.iron_skin.active)
static func restore_iron_skin(unit:Dictionary,hits:int)->float:
	if not has_talent(unit,"crusader_l30_3") or not bool(unit.crusader_runtime.iron_skin.active):return 0.0
	var room:=maxf(0.0,float(unit.crusader_runtime.iron_skin.maximum)-float(unit.crusader_runtime.iron_skin.current));var restored:=minf(room,float(unit.crusader_runtime.iron_skin.maximum)*float(CrusaderData.VALUES.unbreakable_restore)*float(contact_count(hits)));unit.crusader_runtime.iron_skin.current+=restored;add(unit,"unbreakable_restoration",restored);return restored
static func note_basic_attack(unit:Dictionary,target_id:String,successful:bool)->Dictionary:
	if not successful:return {}
	var result:={"fortress_armor":0.0,"w_cdr":0.0,"refresh_sins":false}
	if has_talent(unit,"crusader_l9_2"):unit.crusader_runtime.fortress_stacks=mini(int(CrusaderData.VALUES.fortress_max),int(unit.crusader_runtime.fortress_stacks)+1);unit.crusader_runtime.fortress_remaining=float(CrusaderData.VALUES.fortress_duration);result.fortress_armor=CrusaderData.scaled(float(CrusaderData.VALUES.fortress_stack)*int(unit.crusader_runtime.fortress_stacks),int(unit.level))
	if has_talent(unit,"crusader_l12_2") and unit.crusader_runtime.eternal_marks.has(target_id):unit.crusader_runtime.eternal_marks.erase(target_id);result.w_cdr=minf(float(unit.ability_cds[1]),float(CrusaderData.VALUES.eternal_cdr));unit.ability_cds[1]-=float(result.w_cdr);add(unit,"eternal_cdr",float(result.w_cdr))
	if has_talent(unit,"crusader_l18_1") and unit.crusader_runtime.sins.has(target_id):unit.crusader_runtime.sins[target_id]=float(CrusaderData.VALUES.sins_duration);result.refresh_sins=true
	return result
static func mark_condemn(unit:Dictionary,target_ids:Array)->void:
	for id in target_ids.slice(0,int(CrusaderData.VALUES.contact_cap)):
		if has_talent(unit,"crusader_l12_2"):unit.crusader_runtime.eternal_marks[id]=float(CrusaderData.VALUES.eternal_duration)
		if has_talent(unit,"crusader_l24_2"):unit.crusader_runtime.condemned[id]=float(CrusaderData.VALUES.condemned_duration)
static func mark_sins(unit:Dictionary,target_id:String)->void:if has_talent(unit,"crusader_l18_1"):unit.crusader_runtime.sins[target_id]=float(CrusaderData.VALUES.sins_duration)
static func is_condemned(unit:Dictionary,target_id:String)->bool:return float(unit.crusader_runtime.condemned.get(target_id,0.0))>0.0
static func set_authority(unit:Dictionary,target_ids:Array)->void:
	if not has_talent(unit,"crusader_l21_3") or target_ids.size()<3:return
	for id in target_ids:unit.crusader_runtime.authority[id]=float(CrusaderData.VALUES.e_blind)
	add(unit,"authority_activations");add(unit,"authority_targets",target_ids.size())
static func authority_multiplier(unit:Dictionary,target_id:String)->float:return float(CrusaderData.VALUES.authority_multiplier) if float(unit.get("crusader_runtime",{}).get("authority",{}).get(target_id,0.0))>0.0 else 1.0
static func begin_falling(unit:Dictionary)->bool:
	if str(unit.selected_heroic_id)!="crusader_l15_r1" or float(unit.ability_cds[3])>0.0:return false
	unit.ability_cds[3]=float(CrusaderData.VALUES.falling_cooldown);unit.crusader_runtime.falling={"remaining":float(CrusaderData.VALUES.falling_duration),"landing_ready":false,"barrage":float(CrusaderData.VALUES.heavens_interval),"barrages":0};return true
static func try_indestructible(unit:Dictionary,would_die:bool)->bool:
	if not would_die or not has_talent(unit,"crusader_l30_1") or float(unit.crusader_runtime.indestructible_icd)>0.0:return false
	unit.crusader_runtime.indestructible_icd=float(CrusaderData.VALUES.indestructible_icd);add(unit,"indestructible_triggers");return true
static func advance(unit:Dictionary,delta:float)->void:
	var rt:Dictionary=unit.crusader_runtime;AbilitySlotSystem.update(rt.e_slot,delta);rt.light_icd=maxf(0.0,float(rt.light_icd)-delta);rt.indestructible_icd=maxf(0.0,float(rt.indestructible_icd)-delta)
	if not rt.condemn.is_empty():rt.condemn.remaining=maxf(0.0,float(rt.condemn.remaining)-delta);if float(rt.condemn.remaining)<=0.0:rt.condemn.ready=true
	if bool(rt.iron_skin.active):rt.iron_skin.elapsed=float(rt.iron_skin.get("elapsed",0.0))+delta;rt.iron_skin.remaining=maxf(0.0,float(rt.iron_skin.remaining)-delta);add(unit,"iron_skin_active_time",delta)
	if int(rt.fortress_stacks)>0:add(unit,"fortress_uptime",delta)
	rt.fortress_remaining=maxf(0.0,float(rt.fortress_remaining)-delta);if float(rt.fortress_remaining)<=0.0:rt.fortress_stacks=0
	rt.holy_fury_remaining=maxf(0.0,float(rt.holy_fury_remaining)-delta);if float(rt.holy_fury_remaining)<=0.0:rt.holy_fury_stacks=0
	for map_key in ["eternal_marks","condemned","sins","authority"]:
		for id in rt[map_key].keys():rt[map_key][id]=maxf(0.0,float(rt[map_key][id])-delta);if float(rt[map_key][id])<=0.0:rt[map_key].erase(id)
	if not rt.falling.is_empty():rt.falling.remaining=maxf(0.0,float(rt.falling.remaining)-delta);rt.falling.barrage=float(rt.falling.barrage)-delta;if float(rt.falling.remaining)<=0.0:rt.falling.landing_ready=true
