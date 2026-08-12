extends RefCounted

const DruidData=preload("res://scripts/data/druid_data.gd")
const PeriodicStatusSystem=preload("res://scripts/systems/periodic_status_system.gd")
const AbilityPowerSystem=preload("res://scripts/systems/ability_power_system.gd")
const StatusEffectSystem=preload("res://scripts/systems/status_effect_system.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")
const TargetCategorySystem=preload("res://scripts/systems/combat_target_category_system.gd")

const REGROWTH_TAGS := ["healing_over_time","regrowth"]
const BASIC_HOT_TAGS := ["healing_over_time","druid_basic_hot"]

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func owner_id(unit:Dictionary)->String:return str(unit.get("combat_id",""))
static func target_id(unit:Dictionary)->String:return str(unit.get("combat_id",""))
static func health_ratio(unit:Dictionary)->float:return float(unit.get("hp",0.0))/maxf(0.001,float(unit.get("max_hp",1.0)))
static func successful_hit(result:Dictionary)->bool:return not bool(result.get("evaded",false)) and not bool(result.get("immune",false)) and float(result.get("resolved_damage",0.0))>0.0

static func default_telemetry()->Dictionary:
	var result:Dictionary={}
	for key in ["regrowth_casts","regrowth_refreshes","regrowth_ticks","verdant_ticks","regrowth_healing","regrowth_overhealing","wild_growth_seconds","twilight_refreshes","cure_casts","cure_allies","cure_stuns","cure_roots","cure_slows","cure_empty","basic_attempts","basic_hits","basic_damage","mini_hot_applications","mini_hot_ticks","mini_hot_healing","mini_hot_overhealing","mini_hot_peak","moonfire_casts","moonfire_contacts","moonfire_qualifying","moonfire_damage","moonfire_reveals","moonfire_healing","lunar_roots_cdr","serenity_cdr","lunar_shower","roots_casts","roots_contacts","roots_success","roots_resisted","deep_roots_casts","emerald_cdr","verdant_activations","treant_summons","treant_lifetime","treant_attacks","treant_damage","quest_stacks","quest_peak_damage","innervate_casts","innervate_accelerated","shando_bonus","revitalize_uptime","communion_healing","tranquility_healing","tranquility_armor_uptime","twilight_damage","twilight_silence","astral_teleports","astral_free_moonfires"]:result[key]=0.0
	return result

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false,encounter_id:String="")->void:
	unit["druid_runtime"]={
		"regrowths":[],"mini_hots":[],"designated_ally_id":"","roots_areas":[],"treants":[],
		"d_slot":AbilitySlotSystem.create(2 if has_talent(unit,"druid_l12_3") else 1,float(DruidData.VALUES.innervate_cooldown),AbilitySlotSystem.RechargeMode.INDEPENDENT),
		"innervates":{},"revitalize_remaining":0.0,"tranquility_remaining":0.0,"tranquility_tick":1.0,
		"twilight_pending":0.0,"twilight_point":Vector2.ZERO,"astral_pending":0.0,"astral_ready":false,"astral_point":Vector2.ZERO,
		"lunar_shower_stacks":0,"lunar_shower_remaining":0.0,"vengeful_quest_stacks":0,
		"cast_sequence":0,"encounter_id":encounter_id,"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry(),
		"recent_cure_count":0,"recent_healing":0.0,"recent_overhealing":0.0,"recent_communion_snapshot":0.0
	}

static func telemetry_add(unit:Dictionary,key:String,value=1.0)->void:
	var runtime:Dictionary=unit.get("druid_runtime",{})
	if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=float(runtime.telemetry.get(key,0.0))+float(value)

static func next_cast_id(unit:Dictionary,prefix:String)->String:
	unit.druid_runtime.cast_sequence=int(unit.druid_runtime.cast_sequence)+1
	return "%s:%s:%d"%[prefix,owner_id(unit),int(unit.druid_runtime.cast_sequence)]

static func power_scaled(unit:Dictionary,value:float)->float:
	var expected:=maxf(0.001,DruidData.scaled(float(DruidData.VALUES.basic_attack_damage),int(unit.get("level",1))))
	var amount:=DruidData.scaled(value,int(unit.get("level",1)))*maxf(0.0,float(unit.get("power",expected)))/expected
	return AbilityPowerSystem.apply(amount,unit)

static func hot_multiplier(unit:Dictionary,tags:Array)->float:
	var base:float=float(unit.get("healing_over_time_multiplier",unit.get("stats",{}).get("healing_over_time_multiplier",unit.get("hot_multiplier",1.0))))
	var multiplier:=float(base) if "healing_over_time" in tags else 1.0
	for effect in unit.get("active_effects",[]):
		if "healing_over_time" in tags:multiplier*=float(effect.get("healing_over_time_multiplier",effect.get("hot_multiplier",1.0)))
	return multiplier

static func regrowth_duration(unit:Dictionary)->float:
	return float(DruidData.VALUES.regrowth_duration)+float(DruidData.VALUES.nature_balance_duration if has_talent(unit,"druid_l24_2") else 0.0)

static func regrowth_tick_request(unit:Dictionary)->float:
	var multiplier:=hot_multiplier(unit,["healing_over_time","regrowth"])
	if has_talent(unit,"druid_l24_1") and health_ratio(unit)>0.75:multiplier*=1.0+float(DruidData.VALUES.ysera_bonus)
	return power_scaled(unit,float(DruidData.VALUES.regrowth_tick))*multiplier

static func basic_hot_tick_request(unit:Dictionary)->float:
	return power_scaled(unit,float(DruidData.VALUES.basic_hot_tick))*hot_multiplier(unit,["healing_over_time","druid_basic_hot"])

static func active_regrowths(unit:Dictionary)->Array:
	return unit.get("druid_runtime",{}).get("regrowths",[]).filter(func(instance):return float(instance.get("remaining_duration",0.0))>0.0)

static func living_regrowth_count(unit:Dictionary,allies:Array=[])->int:
	var active:=active_regrowths(unit)
	if allies.is_empty():return active.size()
	var living_ids:Dictionary={}
	for ally in allies:
		if float(ally.get("hp",0.0))>0.0:living_ids[target_id(ally)]=true
	return active.filter(func(instance):return living_ids.has(str(instance.get("target_id","")))).size()

static func regrowth_for(unit:Dictionary,target:String):
	for instance in active_regrowths(unit):
		if str(instance.get("target_id",""))==target:return instance
	return null

static func cleanse_regrowth_target(unit:Dictionary,target:Dictionary)->Array:
	var removed:Array=[]
	if has_talent(unit,"druid_l18_3"):
		removed=StatusEffectSystem.remove_controls(target,["stun","root","slow"]);unit.druid_runtime.recent_cure_count=removed.size();telemetry_add(unit,"cure_casts")
		for control in removed:telemetry_add(unit,"cure_%s"%str(control)+("s" if not str(control).ends_with("s") else ""))
		telemetry_add(unit,"cure_allies" if not removed.is_empty() else "cure_empty")
	return removed

static func apply_regrowth(unit:Dictionary,target:Dictionary,direct:bool=true,perform_cleanse:bool=true)->Dictionary:
	var removed:Array=cleanse_regrowth_target(unit,target) if direct and perform_cleanse else []
	var duration:=regrowth_duration(unit)
	var instance:=PeriodicStatusSystem.create_healing("druid_regrowth",owner_id(unit),target_id(target),float(DruidData.VALUES.regrowth_tick),duration,float(DruidData.VALUES.regrowth_interval),REGROWTH_TAGS,{"family":"regrowth","cast_id":next_cast_id(unit,"regrowth")})
	var refreshed:=PeriodicStatusSystem.refresh_owned(unit.druid_runtime.regrowths,instance)
	unit.druid_runtime.regrowths=refreshed.instances
	telemetry_add(unit,"regrowth_casts");if bool(refreshed.refreshed):telemetry_add(unit,"regrowth_refreshes")
	return {"refreshed":bool(refreshed.refreshed),"duration":duration,"removed":removed,"lifebloom_fraction":float(DruidData.VALUES.lifebloom_missing) if direct and has_talent(unit,"druid_l30_1") else 0.0}

static func apply_rejuvenation(unit:Dictionary,target:Dictionary)->bool:
	if not has_talent(unit,"druid_l12_1") or target_id(target)==owner_id(unit):return false
	var duration:=regrowth_duration(unit)*float(DruidData.VALUES.rejuvenation_duration)
	var instance:=PeriodicStatusSystem.create_healing("druid_regrowth",owner_id(unit),owner_id(unit),float(DruidData.VALUES.regrowth_tick),duration,float(DruidData.VALUES.regrowth_interval),REGROWTH_TAGS,{"family":"regrowth","cast_id":next_cast_id(unit,"rejuvenation"),"generated":true})
	var existing=regrowth_for(unit,owner_id(unit))
	# A generated half-duration Rejuvenation must never shorten a stronger
	# direct self-Regrowth that is already running.
	if existing!=null and float(existing.get("remaining_duration",0.0))>=duration:return true
	unit.druid_runtime.regrowths=PeriodicStatusSystem.refresh_owned(unit.druid_runtime.regrowths,instance).instances
	return true

static func designate_basic_healing_target(unit:Dictionary,target:Dictionary)->bool:
	if target.is_empty() or float(target.get("hp",0.0))<=0.0:return false
	unit.druid_runtime.designated_ally_id=target_id(target);return true

static func note_basic_attack(unit:Dictionary,target:Dictionary,result:Dictionary,allies:Array)->Dictionary:
	telemetry_add(unit,"basic_attempts");telemetry_add(unit,"basic_damage",float(result.get("resolved_damage",0.0)))
	if not successful_hit(result):return {"successful":false,"applied":false}
	telemetry_add(unit,"basic_hits")
	var ally=null
	for candidate in allies:if target_id(candidate)==str(unit.druid_runtime.designated_ally_id):ally=candidate;break
	if ally==null or float(ally.get("hp",0.0))<=0.0 or Vector2(unit.get("pos",Vector2.ZERO)).distance_to(Vector2(ally.get("pos",Vector2.ZERO)))>float(DruidData.SPACE.regrowth_range):return {"successful":true,"applied":false}
	var instance:=PeriodicStatusSystem.create_healing("druid_basic_hot",owner_id(unit),target_id(ally),float(DruidData.VALUES.basic_hot_tick),float(DruidData.VALUES.basic_hot_duration),float(DruidData.VALUES.basic_hot_interval),BASIC_HOT_TAGS,{"family":"druid_basic_hot","cast_id":next_cast_id(unit,"basic_hot")})
	unit.druid_runtime.mini_hots.append(instance);telemetry_add(unit,"mini_hot_applications");telemetry_add(unit,"mini_hot_peak",maxi(0,unit.druid_runtime.mini_hots.size()-int(unit.druid_runtime.telemetry.get("mini_hot_peak",0))))
	return {"successful":true,"applied":true,"target":ally,"instance":instance}

static func advance_periodics(unit:Dictionary,delta:float)->Dictionary:
	var output:={"regrowth_ticks":[],"mini_hot_ticks":[]}
	for collection_name in ["regrowths","mini_hots"]:
		var collection:Array=unit.druid_runtime[collection_name]
		for index in range(collection.size()-1,-1,-1):
			var advanced:=PeriodicStatusSystem.advance(collection[index],delta);collection[index]=advanced
			for ignored in int(advanced.due_ticks):output["regrowth_ticks" if collection_name=="regrowths" else "mini_hot_ticks"].append(advanced.duplicate(true))
			if bool(advanced.expired):collection.remove_at(index)
		unit.druid_runtime[collection_name]=collection
	return output

static func bonus_regrowth_ticks(unit:Dictionary)->Array:
	return active_regrowths(unit).map(func(instance):return PeriodicStatusSystem.bonus_tick(instance))

static func refresh_all_regrowths(unit:Dictionary)->int:
	var count:=0
	for instance in unit.druid_runtime.regrowths:
		if float(instance.remaining_duration)<=0.0:continue
		instance.remaining_duration=regrowth_duration(unit);instance.duration=regrowth_duration(unit);count+=1
	telemetry_add(unit,"twilight_refreshes",count);return count

static func extend_all_regrowths(unit:Dictionary,seconds:float)->int:
	var count:=0
	for instance in unit.druid_runtime.regrowths:
		if float(instance.remaining_duration)<=0.0:continue
		instance.remaining_duration=float(instance.remaining_duration)+seconds;count+=1
	telemetry_add(unit,"wild_growth_seconds",seconds*count);return count

static func moonfire_radius(unit:Dictionary)->float:
	return float(DruidData.SPACE.moonfire_radius)*(1.0+float(DruidData.VALUES.nature_balance_area) if has_talent(unit,"druid_l24_2") else 1.0)

static func moonfire_plan(unit:Dictionary,contacts:Array,free_cast:bool=false,allies:Array=[])->Dictionary:
	var unique:Dictionary={}
	for target in contacts:
		if TargetCategorySystem.qualifies_immediate(target):unique[target_id(target)]=target
	var count:=mini(unique.size(),int(DruidData.VALUES.moonfire_cap));var regrowth_count:=living_regrowth_count(unit,allies)
	var healing_multiplier:=1.0
	if has_talent(unit,"druid_l24_1") and health_ratio(unit)<0.25:healing_multiplier*=1.0+float(DruidData.VALUES.ysera_bonus)
	if has_talent(unit,"druid_l24_3"):healing_multiplier*=1.0+float(DruidData.VALUES.moonlit_base)+regrowth_count*float(DruidData.VALUES.moonlit_per_regrowth)
	var extension:=minf(count,float(DruidData.VALUES.wild_growth_cap))*float(DruidData.VALUES.wild_growth_seconds) if has_talent(unit,"druid_l18_1") else 0.0
	var roots_cdr:=minf(count,float(DruidData.VALUES.lunar_roots_cap))*float(DruidData.VALUES.lunar_roots_cdr) if has_talent(unit,"druid_l21_2") else 0.0
	var serenity_cdr:=minf(count,float(DruidData.VALUES.serenity_cap))*float(DruidData.VALUES.serenity_cdr) if has_talent(unit,"druid_l27_r1") else 0.0
	var damage_multiplier:=1.0+int(unit.druid_runtime.lunar_shower_stacks)*float(DruidData.VALUES.lunar_shower_bonus)
	if has_talent(unit,"druid_l30_2") and count>0:
		unit.druid_runtime.lunar_shower_stacks=mini(int(DruidData.VALUES.lunar_shower_max),int(unit.druid_runtime.lunar_shower_stacks)+1);unit.druid_runtime.lunar_shower_remaining=float(DruidData.VALUES.lunar_shower_window)
	telemetry_add(unit,"moonfire_casts");telemetry_add(unit,"moonfire_contacts",contacts.size());telemetry_add(unit,"moonfire_qualifying",count)
	return {"count":count,"combined_heal":power_scaled(unit,float(DruidData.VALUES.moonfire_heal)*count)*healing_multiplier,"damage":power_scaled(unit,float(DruidData.VALUES.moonfire_damage))*damage_multiplier,"extension":extension,"roots_cdr":roots_cdr,"serenity_cdr":serenity_cdr,"reveal":float(DruidData.VALUES.moonfire_reveal)+float(DruidData.VALUES.celestial_reveal if has_talent(unit,"druid_l12_2") else 0.0),"free_cast":free_cast}

static func roots_radius(unit:Dictionary,elapsed:float,secondary:bool=false)->float:
	var progress:=clampf(elapsed/float(DruidData.VALUES.roots_growth),0.0,1.0)
	var maximum:=float(DruidData.SPACE.roots_max_radius)*(1.0+float(DruidData.VALUES.deep_roots_size) if has_talent(unit,"druid_l9_1") and not secondary else 1.0)
	return lerpf(float(DruidData.SPACE.roots_initial_radius),maximum,progress)

static func create_roots_area(unit:Dictionary,point:Vector2,secondary:bool=false)->Dictionary:
	var persistence:=float(DruidData.VALUES.roots_persistence)*(1.0+float(DruidData.VALUES.deep_roots_persistence) if has_talent(unit,"druid_l9_1") and not secondary else 1.0)
	return {"cast_id":next_cast_id(unit,"roots_secondary" if secondary else "roots"),"point":point,"elapsed":0.0,"remaining":float(DruidData.VALUES.roots_growth)+persistence,"contact_ids":[],"successful_roots":0,"secondary":secondary,"verdant_fired":false}

static func note_root_result(unit:Dictionary,target:Dictionary,applied:bool,secondary:bool=false,successful_index:int=0)->Dictionary:
	if secondary:return {"quest":false,"emerald":0.0,"verdant":false}
	telemetry_add(unit,"roots_contacts");telemetry_add(unit,"roots_success" if applied else "roots_resisted")
	if not applied:return {"quest":false,"emerald":0.0,"verdant":false}
	var quest:=has_talent(unit,"druid_l9_2") and TargetCategorySystem.qualifies_quest(target)
	if quest:unit.druid_runtime.vengeful_quest_stacks=int(unit.druid_runtime.vengeful_quest_stacks)+1;telemetry_add(unit,"quest_stacks")
	var emerald:=float(DruidData.VALUES.emerald_cdr) if has_talent(unit,"druid_l9_3") and successful_index<int(DruidData.VALUES.emerald_cap) else 0.0
	return {"quest":quest,"emerald":emerald,"verdant":has_talent(unit,"druid_l18_2")}

static func treant_damage(unit:Dictionary)->float:
	return power_scaled(unit,float(DruidData.VALUES.treant_damage)+int(unit.druid_runtime.vengeful_quest_stacks)*float(DruidData.VALUES.vengeful_per_root))

static func create_treant(unit:Dictionary,point:Vector2)->Dictionary:
	telemetry_add(unit,"treant_summons")
	return {"combat_id":next_cast_id(unit,"treant"),"owner_id":owner_id(unit),"source":"vengeful_roots","team":"player","target_category":"summon","pos":point,"hp":DruidData.scaled(float(DruidData.VALUES.treant_health),int(unit.get("level",1))),"max_hp":DruidData.scaled(float(DruidData.VALUES.treant_health),int(unit.get("level",1))),"attack_cooldown":0.0,"lifetime":float(DruidData.VALUES.treant_health)/float(DruidData.VALUES.treant_health_decay),"target_id":""}

static func innervate_recharge_rate(unit:Dictionary,allies:Array=[])->float:
	if not has_talent(unit,"druid_l12_3"):return 1.0
	return 1.0+living_regrowth_count(unit,allies)*float(DruidData.VALUES.shando_regrowth_rate)

static func cast_innervate(unit:Dictionary,target:Dictionary)->Dictionary:
	if target.is_empty() or float(target.get("hp",0.0))<=0.0 or target_id(target)==owner_id(unit) or not AbilitySlotSystem.spend(unit.druid_runtime.d_slot):return {"cast":false}
	unit.druid_runtime.innervates[target_id(target)]=float(DruidData.VALUES.innervate_duration)
	if has_talent(unit,"druid_l21_3"):unit.druid_runtime.revitalize_remaining=float(DruidData.VALUES.innervate_duration)
	var communion:=0.0;var regrowth=regrowth_for(unit,target_id(target))
	if has_talent(unit,"druid_l30_3") and regrowth!=null:
		var native_remaining:=PeriodicStatusSystem.remaining_scheduled_amount(regrowth)*float(DruidData.VALUES.nature_communion_remaining)
		var source_multiplier:=1.0+float(DruidData.VALUES.ysera_bonus) if has_talent(unit,"druid_l24_1") and health_ratio(unit)>0.75 else 1.0
		communion=power_scaled(unit,native_remaining)*hot_multiplier(unit,["healing_over_time","regrowth"])*source_multiplier
		regrowth.remaining_duration=regrowth_duration(unit);regrowth.duration=regrowth_duration(unit);unit.druid_runtime.recent_communion_snapshot=communion
	telemetry_add(unit,"innervate_casts");return {"cast":true,"target_id":target_id(target),"communion":communion}

static func cooldown_rate_from_innervate(target:Dictionary,druids:Array,slot:int)->float:
	if slot<0 or slot>2:return 1.0
	var rate:=1.0
	for druid in druids:
		if float(druid.get("druid_runtime",{}).get("innervates",{}).get(target_id(target),0.0))>0.0:rate+=float(DruidData.VALUES.innervate_rate_bonus)
		if druid==target and float(druid.get("druid_runtime",{}).get("revitalize_remaining",0.0))>0.0:rate+=float(DruidData.VALUES.innervate_rate_bonus)
	return rate

static func advance(unit:Dictionary,delta:float,allies:Array=[])->Dictionary:
	var output:=advance_periodics(unit,delta);var runtime:Dictionary=unit.druid_runtime
	var recharge_rate:=innervate_recharge_rate(unit,allies);var timer_before:=float(runtime.d_slot.timers[0]) if not runtime.d_slot.timers.is_empty() else 0.0
	AbilitySlotSystem.update(runtime.d_slot,delta,recharge_rate)
	if timer_before>0.0 and recharge_rate>1.0:telemetry_add(unit,"shando_bonus",minf(timer_before,maxf(0.0,delta)*(recharge_rate-1.0)))
	for id in runtime.innervates.keys():runtime.innervates[id]=maxf(0.0,float(runtime.innervates[id])-delta);if float(runtime.innervates[id])<=0.0:runtime.innervates.erase(id)
	if float(runtime.revitalize_remaining)>0.0:telemetry_add(unit,"revitalize_uptime",minf(float(runtime.revitalize_remaining),maxf(0.0,delta)))
	runtime.revitalize_remaining=maxf(0.0,float(runtime.revitalize_remaining)-delta);runtime.lunar_shower_remaining=maxf(0.0,float(runtime.lunar_shower_remaining)-delta)
	if float(runtime.lunar_shower_remaining)<=0.0:runtime.lunar_shower_stacks=0
	return output

static func reset_encounter(unit:Dictionary)->void:
	var enabled:=bool(unit.get("druid_runtime",{}).get("telemetry_enabled",false));initialize_runtime(unit,enabled,"")
