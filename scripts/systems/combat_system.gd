extends RefCounted

const LEVEL_CAP := 30
const DEFAULT_HEALTH_GROWTH := 0.03
const DEFAULT_POWER_GROWTH := 0.03
const ARMOR_BASE_CONSTANT := 100.0
const ARMOR_LEVEL_CONSTANT := 10.0
const ARMOR_REDUCTION_CAP := 0.75
const DAMAGE_THREAT_RATIO := 1.0
const HEALING_THREAT_RATIO := 0.5
const SHIELD_THREAT_RATIO := 0.25
const NEARBY_AGGRO_MULTIPLIER := 1.10
const DISTANT_AGGRO_MULTIPLIER := 1.30
const AGGRO_DISTANCE_THRESHOLD := 180.0

const ACTION_SOURCES := ["basic_attack","basic_heal","basic_ability","heroic","periodic","summon"]
const ACTION_TAGS := ["basic_action","basic_attack","basic_heal","basic_ability","heroic","direct","periodic","summon"]
const DAMAGE_TYPES := ["physical","magical","true"]
const RESULT_CATEGORIES := ["damage","healing","shield","buff","debuff"]

const WEAPON_PROFILES := {
	"rapid":{"amount_multiplier":0.80,"interval_multiplier":0.80},
	"balanced":{"amount_multiplier":1.00,"interval_multiplier":1.00},
	"heavy":{"amount_multiplier":1.25,"interval_multiplier":1.25},
	"guarded":{"amount_multiplier":0.90,"interval_multiplier":1.00}
}
const WEAPON_FAMILY_PROFILE := {
	"dual_wield":"rapid","bow":"rapid","wand":"rapid",
	"one_handed":"balanced","crossbow":"balanced","focus":"balanced",
	"two_handed":"heavy","firearm":"heavy","staff":"heavy",
	"weapon_and_shield":"guarded"
}

static func clamp_level(level:int)->int:
	return clampi(level,1,LEVEL_CAP)

static func level_scaled_stat(base_value:float,growth_rate:float,level:int)->float:
	return base_value*pow(1.0+growth_rate,clamp_level(level)-1)

static func weapon_profile_for_items(equipped_items:Array)->Dictionary:
	for item in equipped_items:
		if str(item.get("slot",""))!="weapon":continue
		var profile_id:String=str(item.get("weapon_profile",WEAPON_FAMILY_PROFILE.get(str(item.get("weapon_family_requirement","")),"balanced")))
		return WEAPON_PROFILES.get(profile_id,WEAPON_PROFILES.balanced).duplicate(true)
	return WEAPON_PROFILES.balanced.duplicate(true)

static func _modifier_sources(equipped_items:Array,buffs:Array,debuffs:Array)->Array:
	var sources:Array=[]
	for item in equipped_items:sources.append({"modifiers":item.get("stat_modifiers",{}),"direction":1.0})
	for buff in buffs:sources.append({"modifiers":buff.get("stat_modifiers",{}),"direction":1.0})
	for debuff in debuffs:sources.append({"modifiers":debuff.get("stat_modifiers",{}),"direction":-1.0})
	return sources

static func calculate_final_stats(definition:Dictionary,level:int=1,equipped_items:Array=[],buffs:Array=[],debuffs:Array=[])->Dictionary:
	var safe_level:int=clamp_level(level)
	var action_type:String=str(definition.get("basic_action_type","heal" if float(definition.get("basic_heal_coefficient",0.0))>0.0 else "attack"))
	var action_coefficient:float=float(definition.get("basic_action_power_coefficient",definition.get("basic_heal_coefficient",definition.get("basic_attack_coefficient",1.0))))
	var action_interval:float=float(definition.get("basic_action_interval",definition.get("basic_heal_interval",definition.get("basic_attack_interval",1.25))))
	var action_range:float=float(definition.get("basic_action_range",definition.get("attack_range",55.0)))
	var action_damage_type:String=str(definition.get("basic_action_damage_type",definition.get("basic_attack_damage_type","physical")))
	var stats:Dictionary={
		"level":safe_level,
		"health":level_scaled_stat(float(definition.get("base_health",1.0)),float(definition.get("health_growth",DEFAULT_HEALTH_GROWTH)),safe_level),
		"power":level_scaled_stat(float(definition.get("base_power",1.0)),float(definition.get("power_growth",DEFAULT_POWER_GROWTH)),safe_level),
		"armor":float(definition.get("base_armor",0.0)),
		"basic_action_type":action_type,"basic_action_power_coefficient":action_coefficient,"basic_action_interval":action_interval,"basic_action_range":action_range,
		"movement_speed":float(definition.get("movement_speed",110.0)),
		"critical_chance":float(definition.get("base_critical_chance",definition.get("critical_chance",0.05))),
		"critical_damage":float(definition.get("critical_damage",2.0)),
		"health_regeneration":float(definition.get("health_regeneration",0.0)),
		"threat_modifier":float(definition.get("threat_modifier",1.0)),
		"basic_action_damage_type":action_damage_type,
		"armor_family":str(definition.get("armor_family","")),
		"weapon_proficiencies":definition.get("weapon_proficiencies",[]).duplicate(),
		"behavior_flags":definition.get("behavior_flags",[]).duplicate(),
		"combat_tags":definition.get("combat_tags",[]).duplicate(),
		"basic_action_speed":0.0,"damage_multiplier":1.0,"healing_multiplier":1.0,"damage_taken_multiplier":1.0,"healing_taken_multiplier":1.0
	}
	var multiplier_values:Dictionary={}
	for source in _modifier_sources(equipped_items,buffs,debuffs):
		var modifiers:Dictionary=source.modifiers;var direction:float=float(source.direction)
		for stat in modifiers:
			var stat_name:String=str(stat);var value:float=float(modifiers[stat])
			if stat_name.ends_with("_multiplier"):multiplier_values[stat_name]=float(multiplier_values.get(stat_name,1.0))*value
			elif stats.has(stat_name):stats[stat_name]=float(stats[stat_name])+value*direction
	for multiplier_name in multiplier_values:
		var base_key:String=str(multiplier_name).trim_suffix("_multiplier")
		if stats.has(base_key):stats[base_key]=float(stats[base_key])*float(multiplier_values[multiplier_name])
	var weapon_profile:Dictionary=weapon_profile_for_items(equipped_items)
	stats["weapon_amount_multiplier"]=float(weapon_profile.amount_multiplier)
	stats["weapon_interval_multiplier"]=float(weapon_profile.interval_multiplier)
	stats["basic_action_amount"]=maxf(0.0,float(stats.power)*action_coefficient*float(stats.weapon_amount_multiplier))
	stats["basic_action_interval"]=maxf(0.1,action_interval*float(stats.weapon_interval_multiplier)/maxf(0.1,1.0+float(stats.basic_action_speed)))
	stats["armor_reduction"]=calculate_armor_reduction(float(stats.armor),safe_level)
	stats["basic_attack_damage"]=float(stats.basic_action_amount)
	stats["basic_heal_amount"]=float(stats.basic_action_amount) if action_type=="heal" else 0.0
	stats["basic_attack_interval"]=float(stats.basic_action_interval)
	stats["basic_heal_interval"]=float(stats.basic_action_interval)
	stats["attack_range"]=action_range
	stats["basic_attack_damage_type"]=action_damage_type
	return stats

static func calculate_power_scaled_amount(source:Dictionary,power_coefficient:float,flat_bonus:float=0.0,percentage_multiplier:float=1.0)->float:
	return maxf(0.0,(float(source.get("power",0.0))*power_coefficient+flat_bonus)*percentage_multiplier)

static func calculate_armor_reduction(armor:float,attacker_level:int=1)->float:
	var armor_constant:float=ARMOR_BASE_CONSTANT+ARMOR_LEVEL_CONSTANT*clamp_level(attacker_level)
	var safe_armor:float=maxf(0.0,armor)
	return clampf(safe_armor/(safe_armor+armor_constant),0.0,ARMOR_REDUCTION_CAP)

static func strongest_armor(base_armor:float,sources:Array,damage_type:String="physical",source_action:String="basic_attack")->float:
	var strongest:=base_armor
	for source in sources:
		if float(source.get("remaining",1.0))<=0.0:continue
		var restricted_type:=str(source.get("damage_type",""));var restricted_action:=str(source.get("source_action",""))
		if restricted_type!="" and restricted_type!=damage_type:continue
		if restricted_action!="" and restricted_action!=source_action:continue
		strongest=maxf(strongest,float(source.get("armor",0.0)))
	return strongest

static func default_can_crit(source_action:String,result_category:String,damage_type:String="physical")->bool:
	if result_category=="shield" or damage_type=="true" or source_action=="periodic":return false
	if result_category=="damage":return source_action in ["basic_attack","basic_ability","heroic"]
	if result_category=="healing":return source_action in ["basic_heal","basic_ability","heroic"]
	return false

static func _consume_shield_sources(target:Dictionary,amount:float)->Array:
	var remaining:float=amount;var absorptions:Array=[]
	if not target.has("shield_sources") or not target.shield_sources is Array:target["shield_sources"]=[]
	while remaining>0.0 and not target.shield_sources.is_empty():
		var shield_source:Dictionary=target.shield_sources[0];var absorbed:float=minf(remaining,float(shield_source.get("amount",0.0)))
		shield_source.amount=float(shield_source.get("amount",0.0))-absorbed;remaining-=absorbed
		absorptions.append({"amount":absorbed,"source_id":shield_source.get("source_id",""),"creator_index":int(shield_source.get("creator_index",-1)),"origin":shield_source.get("origin",null)})
		if shield_source.amount<=0.0001:target.shield_sources.remove_at(0)
		else:target.shield_sources[0]=shield_source
	return absorptions

static func resolve_damage(source:Dictionary,target:Dictionary,request:Dictionary,rng_roll:float=-1.0)->Dictionary:
	var source_action:String=str(request.get("source_action","basic_attack"));var damage_type:String=str(request.get("damage_type","physical"))
	var amount:float=maxf(0.0,float(request.get("amount",calculate_power_scaled_amount(source,float(request.get("power_coefficient",0.0))))))
	amount+=float(request.get("flat_bonus",0.0));amount*=float(request.get("outgoing_multiplier",source.get("damage_multiplier",1.0)))
	amount=maxf(0.0,amount)
	var can_crit:bool=bool(request.get("can_crit",default_can_crit(source_action,"damage",damage_type)));var roll:float=randf() if rng_roll<0 else rng_roll;var critical:bool=can_crit and roll<float(source.get("critical_chance",0.0))
	var critical_multiplier:float=float(request.get("critical_multiplier",source.get("critical_damage",2.0)))
	if critical:amount*=critical_multiplier
	amount*=float(request.get("damage_taken_multiplier",target.get("damage_taken_multiplier",1.0)))
	amount=maxf(0.0,amount)
	var resolved_armor:=strongest_armor(float(target.get("armor",0.0)),request.get("armor_sources",target.get("temporary_armor_sources",[])),damage_type,source_action)
	var reduction:float=0.0 if damage_type=="true" else calculate_armor_reduction(resolved_armor,int(source.get("level",1)))
	var mitigated_amount:float=amount*(1.0-reduction)
	var available_shield:float=maxf(0.0,float(target.get("shield",0.0)));var shield_damage:float=minf(available_shield,mitigated_amount)
	var shield_absorptions:Array=_consume_shield_sources(target,shield_damage);target["shield"]=available_shield-shield_damage
	var health_damage:float=minf(maxf(0.0,float(target.get("hp",0.0))),mitigated_amount-shield_damage);target["hp"]=maxf(0.0,float(target.get("hp",0.0))-health_damage)
	var resolved_damage:float=shield_damage+health_damage
	return {"amount":mitigated_amount,"raw_amount":amount,"resolved_damage":resolved_damage,"health_damage":health_damage,"shield_damage":shield_damage,"shield_absorptions":shield_absorptions,"overkill":maxf(0.0,mitigated_amount-resolved_damage),"critical":critical,"critical_multiplier":critical_multiplier,"damage_type":damage_type,"source_action":source_action,"result_category":"damage","armor":resolved_armor,"armor_reduction":reduction,"armor_prevented":maxf(0.0,amount-mitigated_amount),"defeated":health_damage>0.0 and float(target.get("hp",0.0))<=0.0}

static func default_control_profile(unit:Dictionary)->Dictionary:
	if not bool(unit.get("boss",false)):return {"stun_multiplier":1.0,"slow_multiplier":1.0,"attack_speed_multiplier":1.0,"displacement":true,"interruptible":true,"stagger_multiplier":1.0}
	return unit.get("control_profile",{"stun_multiplier":0.25,"slow_multiplier":0.5,"attack_speed_multiplier":0.5,"displacement":false,"interruptible":true,"stagger_multiplier":1.0})

static func apply_control(unit:Dictionary,control_type:String,duration:float,magnitude:float=0.0)->Dictionary:
	var profile:=default_control_profile(unit);var multiplier:=float(profile.get("%s_multiplier"%control_type,profile.get("slow_multiplier",1.0)))
	if control_type=="displacement" and not bool(profile.get("displacement",true)):return {"applied":false,"duration":0.0,"magnitude":0.0}
	var resolved_duration:=maxf(0.0,duration*multiplier);var resolved_magnitude:=magnitude*multiplier
	if resolved_duration<=0.0:return {"applied":false,"duration":0.0,"magnitude":0.0}
	if not unit.get("active_effects") is Array:unit["active_effects"]=[]
	unit.active_effects=apply_named_effect(unit.active_effects,{"id":"control_%s"%control_type,"control_type":control_type,"amount":resolved_magnitude,"remaining_duration":resolved_duration})
	return {"applied":true,"duration":resolved_duration,"magnitude":resolved_magnitude}

static func control_amount(unit:Dictionary,control_type:String)->float:
	var strongest:=0.0
	for effect in unit.get("active_effects",[]):
		if str(effect.get("control_type",""))==control_type and float(effect.get("remaining_duration",0.0))>0.0:strongest=maxf(strongest,float(effect.get("amount",0.0)))
	return strongest

static func is_stunned(unit:Dictionary)->bool:
	return unit.get("active_effects",[]).any(func(effect):return str(effect.get("control_type","")) in ["stun","stagger"] and float(effect.get("remaining_duration",0.0))>0.0)

static func resolve_healing(source:Dictionary,target:Dictionary,request:Dictionary,rng_roll:float=-1.0)->Dictionary:
	var source_action:String=str(request.get("source_action","basic_ability"));var amount:float=maxf(0.0,float(request.get("amount",calculate_power_scaled_amount(source,float(request.get("power_coefficient",0.0))))))
	amount+=float(request.get("flat_bonus",0.0));amount*=float(request.get("outgoing_multiplier",source.get("healing_multiplier",1.0)));amount*=float(request.get("incoming_multiplier",target.get("healing_taken_multiplier",1.0)))
	amount=maxf(0.0,amount)
	var can_crit:bool=bool(request.get("can_crit",default_can_crit(source_action,"healing")));var roll:float=randf() if rng_roll<0 else rng_roll;var critical:bool=can_crit and roll<float(source.get("critical_chance",0.0))
	var critical_multiplier:float=float(request.get("critical_multiplier",source.get("critical_damage",2.0)))
	if critical:amount*=critical_multiplier
	var missing_health:float=maxf(0.0,float(target.get("max_hp",0.0))-float(target.get("hp",0.0)));var effective:float=minf(amount,missing_health);var overhealing:float=maxf(0.0,amount-effective)
	target["hp"]=float(target.get("hp",0.0))+effective
	return {"amount":amount,"effective_amount":effective,"overhealing":overhealing,"critical":critical,"critical_multiplier":critical_multiplier,"source_action":source_action,"result_category":"healing","healing_type":"healing"}

static func apply_shield(target:Dictionary,amount:float,context:Dictionary={})->Dictionary:
	var current_shield:float=maxf(0.0,float(target.get("shield",0.0)));var cap:float=float(context.get("cap",INF));var applied:float=minf(maxf(0.0,amount),maxf(0.0,cap-current_shield))
	target["shield"]=current_shield+applied
	if not target.has("shield_sources") or not target.shield_sources is Array:target["shield_sources"]=[]
	if applied>0.0:target.shield_sources.append({"source_id":str(context.get("source_id","shield")),"creator_index":int(context.get("creator_index",-1)),"origin":context.get("origin",null),"amount":applied})
	return {"amount":applied,"critical":false,"result_category":"shield","source_action":str(context.get("source_action","basic_ability")),"source_id":str(context.get("source_id","shield"))}

static func create_event(event_type:String,source:Dictionary,target:Dictionary,result:Dictionary,context:Dictionary={})->Dictionary:
	var tags:Array=context.get("action_tags",[]).duplicate();var source_action:String=str(result.get("source_action",context.get("source_action","")));var result_category:String=str(result.get("result_category",context.get("result_category","")))
	if source_action!="" and source_action not in tags:tags.append(source_action)
	if source_action in ["basic_attack","basic_heal"] and "basic_action" not in tags:tags.append("basic_action")
	if source_action=="periodic" and "periodic" not in tags:tags.append("periodic")
	elif source_action!="periodic" and result_category in ["damage","healing"] and "direct" not in tags:tags.append("direct")
	if result_category!="" and result_category not in tags:tags.append(result_category)
	var result_type:String=str(result.get("damage_type",result.get("healing_type",context.get("damage_type",""))))
	if result_type!="" and result_type not in tags:tags.append(result_type)
	if bool(result.get("critical",false)) and "critical" not in tags:tags.append("critical")
	return {"event_type":event_type,"source_unit":source,"target_unit":target,"source_action":source_action,"action_tags":tags,"damage_or_healing_type":result_type,"amount":result.get("resolved_damage",result.get("effective_amount",result.get("amount",0.0))),"effective_amount":result.get("effective_amount",result.get("resolved_damage",0.0)),"overhealing":result.get("overhealing",0.0),"critical":bool(result.get("critical",false)),"origin":context.get("origin",null),"originating_item_id":context.get("originating_item_id",""),"source_is_summon":bool(context.get("source_is_summon",false)),"originating_effect_id":context.get("originating_effect_id",""),"trigger_chain":context.get("trigger_chain",[]).duplicate(),"crossed_below_half":bool(context.get("crossed_below_half",false)),"shield_source":context.get("shield_source",{})}

static func event_bundle_for_damage(source:Dictionary,target:Dictionary,result:Dictionary,context:Dictionary={})->Array:
	var events:Array=[];var action:String=str(result.get("source_action",""));var direct:bool=action!="periodic"
	if action=="basic_attack":events.append(create_event("basic_attack_hit",source,target,result,context));events.append(create_event("basic_action_completed",source,target,result,context))
	elif action=="basic_ability":events.append(create_event("basic_ability_hit",source,target,result,context))
	elif action=="heroic":events.append(create_event("heroic_hit",source,target,result,context))
	events.append(create_event("damage_dealt",source,target,result,context));events.append(create_event("direct_damage_dealt" if direct else "periodic_damage_dealt",source,target,result,context));events.append(create_event("damage_taken",source,target,result,context))
	for absorption in result.get("shield_absorptions",[]):events.append(create_event("shield_absorbed",source,target,{"amount":absorption.amount,"resolved_damage":absorption.amount,"source_action":action,"result_category":"shield"},context.merged({"shield_source":absorption},true)))
	if bool(result.get("critical",false)):events.append(create_event("critical_result",source,target,result,context))
	if bool(result.get("defeated",false)):events.append(create_event("unit_defeated",source,target,result,context))
	return events

static func event_bundle_for_healing(source:Dictionary,target:Dictionary,result:Dictionary,context:Dictionary={})->Array:
	var events:Array=[];var action:String=str(result.get("source_action",""))
	if action=="basic_heal":events.append(create_event("basic_heal_completed",source,target,result,context));events.append(create_event("basic_heal_done",source,target,result,context));events.append(create_event("basic_action_completed",source,target,result,context))
	events.append(create_event("healing_done",source,target,result,context));events.append(create_event("direct_healing_done" if action!="periodic" else "periodic_healing_done",source,target,result,context))
	if float(result.get("overhealing",0.0))>0.0:events.append(create_event("overhealing_done",source,target,result,context))
	if bool(result.get("critical",false)):events.append(create_event("critical_result",source,target,result,context))
	return events

static func passive_matches(passive:Dictionary,event:Dictionary)->bool:
	if str(passive.get("trigger",""))!=str(event.get("event_type","")):return false
	if str(passive.get("id",""))=="last_dawn" and not bool(event.get("crossed_below_half",false)):return false
	var tags:Array=event.get("action_tags",[])
	for tag in passive.get("required_tags",[]):if tag not in tags:return false
	for tag in passive.get("excluded_tags",[]):if tag in tags:return false
	var source_rules:Dictionary=passive.get("source_restrictions",{})
	if not bool(source_rules.get("allow_summons",passive.get("allow_summons",false))) and bool(event.get("source_is_summon",false)):return false
	return true

static func evaluate_passives(unit:Dictionary,event:Dictionary,equipped_items:Array,passive_definitions:Dictionary,now:float,rng_roll:float=-1.0)->Array:
	var triggered:Array=[]
	if not unit.has("passive_cooldowns"):unit["passive_cooldowns"]={}
	for item in equipped_items:
		for passive_id in item.get("passive_effect_ids",[]):
			var passive:Dictionary=passive_definitions.get(passive_id,{});var proc_key:String="%s:%s"%[item.get("instance_id",item.get("definition_id","item")),passive_id]
			var recursion_rules:Dictionary=passive.get("recursion_restrictions",{})
			var prevents_self:bool=bool(recursion_rules.get("prevent_self",true))
			if passive.is_empty() or prevents_self and (str(event.get("originating_effect_id",""))==str(passive_id) or passive_id in event.get("trigger_chain",[])) or not passive_matches(passive,event):continue
			if now<float(unit.passive_cooldowns.get(proc_key,-INF))+float(passive.get("internal_cooldown",0.0)):continue
			var roll:float=randf() if rng_roll<0 else rng_roll
			if roll>=float(passive.get("chance",1.0)):continue
			unit.passive_cooldowns[proc_key]=now;triggered.append({"passive":passive,"item_instance_id":item.get("instance_id","")})
	return triggered

static func apply_named_effect(active_effects:Array,effect:Dictionary)->Array:
	var next:Array=active_effects.duplicate(true);var effect_id:String=str(effect.get("id",""))
	for index in next.size():
		if str(next[index].get("id",""))==effect_id:
			if float(effect.get("amount",0.0))>=float(next[index].get("amount",0.0)):next[index]=effect.duplicate(true)
			else:next[index]["remaining_duration"]=maxf(float(next[index].get("remaining_duration",0.0)),float(effect.get("remaining_duration",effect.get("duration",0.0))))
			return next
	next.append(effect.duplicate(true));return next

static func damage_threat(result:Dictionary,threat_modifier:float=1.0)->float:
	return maxf(0.0,float(result.get("resolved_damage",float(result.get("health_damage",0.0))+float(result.get("shield_damage",0.0)))))*DAMAGE_THREAT_RATIO*threat_modifier

static func healing_threat(result:Dictionary,threat_modifier:float=1.0)->float:
	return maxf(0.0,float(result.get("effective_amount",0.0)))*HEALING_THREAT_RATIO*threat_modifier

static func shield_absorption_threat(absorbed:float,threat_modifier:float=1.0)->float:
	return maxf(0.0,absorbed)*SHIELD_THREAT_RATIO*threat_modifier

static func distributed_threat(total_threat:float,living_enemy_count:int)->float:
	return total_threat/maxi(1,living_enemy_count)

static func aggro_pull_multiplier(is_nearby:bool)->float:
	return NEARBY_AGGRO_MULTIPLIER if is_nearby else DISTANT_AGGRO_MULTIPLIER

static func required_aggro_threat(current_threat:float,is_nearby:bool)->float:
	return current_threat*aggro_pull_multiplier(is_nearby)

static func store_charge(charges:Array,value:float,maximum:int=3)->Array:
	var next:Array=charges.duplicate();var charge:={"amount":maxf(0.0,value)}
	if next.size()<maximum:next.append(charge);return next
	var smallest_index:int=0
	for index in next.size():if float(next[index].amount)<float(next[smallest_index].amount):smallest_index=index
	if value>float(next[smallest_index].amount):next.remove_at(smallest_index);next.append(charge)
	return next

static func reduce_cooldowns(cooldowns:Array,basic_amount:float=1.0,heroic_amount:float=0.25)->Array:
	var next:Array=cooldowns.duplicate()
	for index in next.size():next[index]=maxf(0.0,float(next[index])-(heroic_amount if index==3 else basic_amount))
	return next
