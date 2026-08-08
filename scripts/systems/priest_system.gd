extends RefCounted

const PriestData=preload("res://scripts/data/priest_data.gd")
const AbilityPowerSystem=preload("res://scripts/systems/ability_power_system.gd")
const AutomaticAllyResolutionSystem=preload("res://scripts/systems/automatic_ally_resolution_system.gd")
const TargetCategorySystem=preload("res://scripts/systems/combat_target_category_system.gd")
const PeriodicStatusSystem=preload("res://scripts/systems/periodic_status_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func scaled(unit:Dictionary,value:float)->float:return PriestData.scaled(value,int(unit.get("level",1)))

static func default_telemetry()->Dictionary:
	var result:Dictionary={}
	for key in ["basic_attacks","pursued_heals","pursued_effective","pursued_overhealing","q_casts","q_completions","q_interruptions","q_effective","q_overhealing","q_full_health","q_self","q_ties","w_casts","w_outbound","w_qualifying","w_capped","w_return_allies","w_healing","w_overhealing","e_casts","e_hits","e_roots","e_resisted","piercing_activations","spirit_triggers","spirit_time","spirit_basic_attacks","spirit_basic_abilities","heroics_blocked","spirit_expiry","redemptions","redemption_unavailable","salvation_casts","salvation_healing","salvation_prevented","salvation_interruptions","lightbomb_casts","lightbomb_self","lightbomb_hits","lightbomb_shield_contacts","blessed_champion_heals","zeal_damage","zeal_healing","zeal_transfers","devotion_applications","push_stacks","tyr_stacks","renew_ticks","renew_refreshes","benediction_attacks","benediction_ready","benediction_resets","guardian_triggers","varian_damage","varian_healing"]:result[key]=0.0
	return result

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false)->void:
	var base_ap:=float(unit.get("stats",{}).get("ability_power_percent",unit.get("ability_power_percent",0.0)))
	unit["base_ability_power_percent"]=base_ap
	unit["priest_runtime"]={
		"previous_flash_target":"","q_pending":false,"q_cast_token":0,"q_completed_token":0,
		"divine_stars":[],"delayed_effects":[],"periodic_heals":[],"periodic_damage":[],
		"spirit_form":false,"spirit_remaining":0.0,"redemption_ready_in":0.0,
		"blessed_remaining":0.0,"blessed_snapshot":0.0,"piercing_progress":0,
		"zeal_target":"","zeal_remaining":0.0,"blessed_recovery_ready_in":0.0,
		"push_stacks":0,"push_remaining":0.0,"tyr_stacks":0,"benediction_progress":0,"benediction_armed":false,
		"temporary_armor_sources":[],"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()
	}
	refresh_ability_power(unit)

static func telemetry_add(unit:Dictionary,key:String,value=1)->void:
	var runtime:Dictionary=unit.get("priest_runtime",{})
	if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=runtime.telemetry.get(key,0)+value

static func refresh_ability_power(unit:Dictionary)->float:
	var sources:Dictionary={};var base:=float(unit.get("base_ability_power_percent",0.0))
	if base!=0.0:sources["base_and_items"]=base
	var progress:=int(unit.get("priest_runtime",{}).get("piercing_progress",0))
	if progress>0:sources["piercing_light"]=progress*0.01
	unit["ability_power_sources"]=sources
	unit["ability_power_percent"]=sources.values().reduce(func(total,value):return float(total)+float(value),0.0)
	return float(unit.ability_power_percent)

static func ability_amount(unit:Dictionary,value:float)->float:
	var level:=int(unit.get("level",1));var expected:=maxf(0.001,PriestData.scaled(float(PriestData.VALUES.basic_attack_damage),level));var power_ratio:=maxf(0.0,float(unit.get("power",expected)))/expected
	refresh_ability_power(unit);return AbilityPowerSystem.apply(PriestData.scaled(value,level)*power_ratio,unit)

static func trait_amount(unit:Dictionary,value:float)->float:
	var multiplier:=1.0+int(unit.get("priest_runtime",{}).get("push_stacks",0))*float(PriestData.VALUES.push_pursued) if has_talent(unit,"priest_l21_2") else 1.0
	return scaled(unit,value)*multiplier

static func successful(result:Dictionary)->bool:return not bool(result.get("evaded",false)) and not bool(result.get("immune",false)) and float(result.get("resolved_damage",0.0))>0.0

static func capped_immediate_contacts(contacts:Array)->int:
	var qualifying:=0
	for target in contacts:
		if TargetCategorySystem.qualifies_immediate(target):qualifying+=1
	return mini(qualifying,int(PriestData.VALUES.hero_hit_cap))

static func most_wounded(allies:Array,unit:Dictionary,radius:float):return AutomaticAllyResolutionSystem.most_wounded(allies,unit,radius,true,true)
static func lightbomb_recipient(allies:Array,unit:Dictionary):return AutomaticAllyResolutionSystem.closest_other_or_self(allies,unit,float(PriestData.SPACE.lightbomb_selection_range))

static func begin_flash_heal(unit:Dictionary)->int:
	unit.priest_runtime.q_cast_token=int(unit.priest_runtime.q_cast_token)+1;unit.priest_runtime.q_pending=true;telemetry_add(unit,"q_casts");return int(unit.priest_runtime.q_cast_token)

static func interrupt_flash_heal(unit:Dictionary)->void:
	if bool(unit.get("priest_runtime",{}).get("q_pending",false)):unit.priest_runtime.q_pending=false;telemetry_add(unit,"q_interruptions")

static func flash_heal_amount(unit:Dictionary,recipient:Dictionary)->float:
	var amount:=ability_amount(unit,float(PriestData.VALUES.q_heal))
	if has_talent(unit,"priest_l9_1") and str(unit.priest_runtime.previous_flash_target)!="" and str(unit.priest_runtime.previous_flash_target)!=str(recipient.get("combat_id","")):amount*=1.0+float(PriestData.VALUES.evenhanded_healing)
	return amount

static func complete_flash_heal(unit:Dictionary,recipient:Dictionary,resolved_amount:float)->Dictionary:
	var previous:=str(unit.priest_runtime.previous_flash_target);var recipient_id:=str(recipient.get("combat_id",""));var changed:=previous!="" and previous!=recipient_id
	unit.priest_runtime.previous_flash_target=recipient_id;unit.priest_runtime.q_pending=false;unit.priest_runtime.q_completed_token=int(unit.priest_runtime.q_cast_token);telemetry_add(unit,"q_completions")
	if has_talent(unit,"priest_l9_1") and changed:unit.ability_cds[0]=maxf(0.0,float(unit.ability_cds[0])-float(PriestData.VALUES.q_cooldown)*float(PriestData.VALUES.evenhanded_refund))
	if has_talent(unit,"priest_l9_3"):unit.priest_runtime.blessed_remaining=float(PriestData.VALUES.blessed_champion_duration);unit.priest_runtime.blessed_snapshot=resolved_amount
	if has_talent(unit,"priest_l18_1"):
		if str(unit.priest_runtime.zeal_target)!=recipient_id:telemetry_add(unit,"zeal_transfers")
		unit.priest_runtime.zeal_target=recipient_id;unit.priest_runtime.zeal_remaining=float(PriestData.VALUES.zeal_duration)
	return {"changed":changed,"renew":has_talent(unit,"priest_l24_1"),"devotion":has_talent(unit,"priest_l18_3"),"guardian":has_talent(unit,"priest_l30_1")}

static func note_basic_attack(unit:Dictionary,target:Dictionary,result:Dictionary,origin:String="manual")->Dictionary:
	if not successful(result):return {"successful":false}
	telemetry_add(unit,"basic_attacks");if bool(unit.priest_runtime.spirit_form):telemetry_add(unit,"spirit_basic_attacks")
	var output:={"successful":true,"trigger_surge":false,"refresh_renew":has_talent(unit,"priest_l24_1"),"trigger_varian":has_talent(unit,"priest_l30_3"),"origin":origin}
	if has_talent(unit,"priest_l12_2"):
		unit.ability_cds[2]=maxf(0.0,float(unit.ability_cds[2])-float(PriestData.VALUES.surge_reduction))
		output.trigger_surge=origin!="priest_surge" and target.get("active_effects",[]).any(func(effect):return str(effect.get("id",""))=="priest_chastise_root" and str(effect.get("owner_id",""))==str(unit.get("combat_id","")) and float(effect.get("remaining_duration",0.0))>0.0)
	if has_talent(unit,"priest_l21_2"):unit.priest_runtime.push_stacks=mini(int(PriestData.VALUES.push_max),int(unit.priest_runtime.push_stacks)+1);unit.priest_runtime.push_remaining=float(PriestData.VALUES.push_duration);telemetry_add(unit,"push_stacks")
	if has_talent(unit,"priest_l21_3"):unit.priest_runtime.tyr_stacks=mini(int(PriestData.VALUES.tyr_max),int(unit.priest_runtime.tyr_stacks)+1);telemetry_add(unit,"tyr_stacks")
	if has_talent(unit,"priest_l24_3") and not bool(unit.priest_runtime.benediction_armed):
		unit.priest_runtime.benediction_progress+=1;telemetry_add(unit,"benediction_attacks")
		if int(unit.priest_runtime.benediction_progress)>=int(PriestData.VALUES.benediction_attacks):unit.priest_runtime.benediction_armed=true;telemetry_add(unit,"benediction_ready")
	return output

static func consume_benediction(unit:Dictionary,slot:int)->bool:
	if not has_talent(unit,"priest_l24_3") or not bool(unit.priest_runtime.benediction_armed) or slot<0 or slot>2:return false
	unit.ability_cds[slot]=0.0;unit.priest_runtime.benediction_armed=false;unit.priest_runtime.benediction_progress=0;telemetry_add(unit,"benediction_resets");return true

static func note_piercing_cast(unit:Dictionary,contacts:Array)->bool:
	if not has_talent(unit,"priest_l12_3") or int(unit.priest_runtime.piercing_progress)>=int(PriestData.VALUES.piercing_max):return false
	var qualifying:=contacts.filter(func(target):return TargetCategorySystem.qualifies_quest(target)).size()
	if qualifying<2:return false
	unit.priest_runtime.piercing_progress+=1;refresh_ability_power(unit);telemetry_add(unit,"piercing_activations");return true

static func divine_star_multiplier(unit:Dictionary)->Dictionary:
	var stacks:=int(unit.priest_runtime.tyr_stacks) if has_talent(unit,"priest_l21_3") else 0;var multiplier:=1.0
	if has_talent(unit,"priest_l21_3"):multiplier+=float(PriestData.VALUES.tyr_base)+stacks*float(PriestData.VALUES.tyr_per_stack)
	unit.priest_runtime.tyr_stacks=0
	return {"multiplier":multiplier,"stacks":stacks}

static func add_named_armor(target:Dictionary,source_id:String,amount:float,duration:float)->void:
	if not target.has("temporary_armor_sources") or not target.temporary_armor_sources is Array:target["temporary_armor_sources"]=[]
	target.temporary_armor_sources=target.temporary_armor_sources.filter(func(source):return str(source.get("id",""))!=source_id)
	target.temporary_armor_sources.append({"id":source_id,"armor":amount,"remaining":duration})

static func update_named_armor(target:Dictionary,delta:float)->void:
	for source in target.get("temporary_armor_sources",[]):source.remaining=maxf(0.0,float(source.get("remaining",0.0))-delta)
	target["temporary_armor_sources"]=target.get("temporary_armor_sources",[]).filter(func(source):return float(source.get("remaining",0.0))>0.0)

static func enter_spirit(unit:Dictionary)->void:
	unit.hp=1.0;unit.incapacitated=false;unit.spirit_form=true;unit.priest_runtime.spirit_form=true;unit.priest_runtime.spirit_remaining=float(PriestData.VALUES.spirit_duration)
	for slot in 3:unit.ability_cds[slot]=0.0
	unit.shield=0.0;unit.shield_sources=[];unit.temporary_armor_sources=[];telemetry_add(unit,"spirit_triggers")

static func spirit_active(unit:Dictionary)->bool:return bool(unit.get("priest_runtime",{}).get("spirit_form",false))

static func update(unit:Dictionary,delta:float)->Dictionary:
	var runtime:Dictionary=unit.get("priest_runtime",{});var output:={"spirit_expired":false,"renew_ticks":[],"varian_ticks":[]}
	if runtime.is_empty():return output
	for key in ["blessed_remaining","zeal_remaining","blessed_recovery_ready_in","push_remaining","redemption_ready_in"]:runtime[key]=maxf(0.0,float(runtime.get(key,0.0))-delta)
	if float(runtime.push_remaining)<=0.0:runtime.push_stacks=0
	if float(runtime.zeal_remaining)<=0.0:runtime.zeal_target=""
	if bool(runtime.spirit_form):runtime.spirit_remaining=maxf(0.0,float(runtime.spirit_remaining)-delta);telemetry_add(unit,"spirit_time",delta);output.spirit_expired=float(runtime.spirit_remaining)<=0.0
	for index in range(runtime.periodic_heals.size()-1,-1,-1):
		var advanced:=PeriodicStatusSystem.advance(runtime.periodic_heals[index],delta);runtime.periodic_heals[index]=advanced
		for tick in int(advanced.due_ticks):output.renew_ticks.append(advanced.duplicate(true))
		if bool(advanced.expired):runtime.periodic_heals.remove_at(index)
	for index in range(runtime.periodic_damage.size()-1,-1,-1):
		var advanced:=PeriodicStatusSystem.advance(runtime.periodic_damage[index],delta);runtime.periodic_damage[index]=advanced
		for tick in int(advanced.due_ticks):output.varian_ticks.append(advanced.duplicate(true))
		if bool(advanced.expired):runtime.periodic_damage.remove_at(index)
	return output

static func movement_multiplier(unit:Dictionary)->float:
	var bonus:=int(unit.get("priest_runtime",{}).get("push_stacks",0))*float(PriestData.VALUES.push_speed) if has_talent(unit,"priest_l21_2") else 0.0
	if bool(unit.get("priest_runtime",{}).get("divine_star_moving",false)) and has_talent(unit,"priest_l21_1"):bonus+=float(PriestData.VALUES.speed_pious_movement)
	return 1.0+bonus

static func reset_encounter(unit:Dictionary)->void:
	var redemption:=float(unit.get("priest_runtime",{}).get("redemption_ready_in",0.0));var telemetry_enabled:=bool(unit.get("priest_runtime",{}).get("telemetry_enabled",false));initialize_runtime(unit,telemetry_enabled);unit.priest_runtime.redemption_ready_in=redemption
