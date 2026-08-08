extends RefCounted

const SAVE_VERSION := 1
const CampaignData = preload("res://scripts/data/campaign_data.gd")
const GuildMemberData = preload("res://scripts/data/guild_member_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const ItemData = preload("res://scripts/data/item_data.gd")

static func _location_connections(region_id:String,index:int)->Array:
	var rows:Array=CampaignData.region(region_id).get("locations",[])
	var result:Array=[]
	if index>0:result.append(str(rows[index-1][0]))
	if index+1<rows.size():result.append(str(rows[index+1][0]))
	return result

static func default_region_state(region_id:String,unlocked:bool=false)->Dictionary:
	var locations:Dictionary={}
	var rows:Array=CampaignData.region(region_id).get("locations",[])
	for index in rows.size():
		var row:Array=rows[index];var location_type:=str(row[2])
		var initial_status:="available" if unlocked and index==0 else "discovered" if unlocked and location_type=="settlement" else "undiscovered"
		locations[str(row[0])]={"status":initial_status,"campaign_completed":false,"repeatable_pool":[],"repeatable_rotation":0,"returning_event_available":false,"guard_reward_claimed":false,"connected_locations":_location_connections(region_id,index)}
	return {"unlocked":unlocked,"completed":false,"campaign_step":0,"locations":locations,"returning_event_completed":false,"operations":{},"support_team_a":[],"support_team_b":[]}

static func default_rivals()->Dictionary:
	var result:Dictionary={}
	for rival_id in CampaignData.FIXED_RIVALS:
		var definition:Dictionary=CampaignData.FIXED_RIVALS[rival_id]
		result[rival_id]={"name":definition.name,"ratings":definition.ratings.duplicate(true),"identity":definition.identity,"standing":50,"relationship":0,"activity_log":["Entered the regional race."],"encounters":0}
	var names:=["Iron Lanterns","Saltroad Company","Blue Herons"]
	for index in names.size():
		result["background_%d"%index]={"name":names[index],"ratings":{"pve":4+index,"wealth":3+index,"reputation":6-index,"pvp":5,"recruitment":4+index},"identity":"A developing guild active between major stories.","standing":35+index*5,"relationship":0,"activity_log":["Registered at the Guild Council."],"encounters":0}
	return result

static func default_state()->Dictionary:
	var regions:Dictionary={}
	for region_id in CampaignData.REGION_ORDER:regions[region_id]=default_region_state(region_id,false)
	return {"version":SAVE_VERSION,"ashwood_complete":false,"regions":regions,"reputation":{},"decisions":{},"decision_log":[],"callbacks":[],"final_modifiers":[],"faction_titles":[],"council_unlocked":true,"combat_hall_unlocked":true,"rivals":default_rivals(),"rival_round":0,"guild_operations":[],"operation_counter":0,"recruited_factions":[],"debug_enabled":false,"finale_complete":false,"final_summary":{},"event_log":[]}

static func ensure_state(state:Dictionary)->Dictionary:
	if not state.get("campaign") is Dictionary:state["campaign"]=default_state()
	var campaign:Dictionary=state.campaign;var defaults:=default_state()
	for key in defaults:
		if not campaign.has(key) or typeof(campaign[key])!=typeof(defaults[key]):campaign[key]=defaults[key].duplicate(true) if defaults[key] is Array or defaults[key] is Dictionary else defaults[key]
	for region_id in CampaignData.REGION_ORDER:
		if not campaign.regions.get(region_id) is Dictionary:campaign.regions[region_id]=default_region_state(region_id,false)
		var region_defaults:=default_region_state(region_id,bool(campaign.regions[region_id].get("unlocked",false)))
		for key in region_defaults:
			if not campaign.regions[region_id].has(key) or typeof(campaign.regions[region_id][key])!=typeof(region_defaults[key]):campaign.regions[region_id][key]=region_defaults[key].duplicate(true) if region_defaults[key] is Array or region_defaults[key] is Dictionary else region_defaults[key]
		for location_id in region_defaults.locations:
			if not campaign.regions[region_id].locations.get(location_id) is Dictionary:campaign.regions[region_id].locations[location_id]=region_defaults.locations[location_id].duplicate(true)
			else:
				for field in region_defaults.locations[location_id]:
					if not campaign.regions[region_id].locations[location_id].has(field):campaign.regions[region_id].locations[location_id][field]=region_defaults.locations[location_id][field].duplicate(true) if region_defaults.locations[location_id][field] is Array else region_defaults.locations[location_id][field]
	for faction_id in CampaignData.FACTIONS:campaign.reputation[faction_id]=clampi(int(campaign.reputation.get(faction_id,0)),-100,100)
	campaign.version=SAVE_VERSION
	sync_ashwood(state)
	return campaign

static func sync_ashwood(state:Dictionary)->void:
	if not state.get("campaign") is Dictionary:return
	var ashwood_complete:=bool(state.get("zone0",{}).get("zone0_boss_defeated",state.get("zone0",{}).get("boss_defeated",false))) or int(state.get("zone0",{}).get("route_stage",0))>=6
	state.campaign.ashwood_complete=ashwood_complete
	state.campaign.council_unlocked=true
	state.campaign.combat_hall_unlocked=true
	if state.get("guild_hall_room_unlocks") is Dictionary:
		state.guild_hall_room_unlocks["combat_hall"]=true
		state.guild_hall_room_unlocks["council_chamber"]=false
	if ashwood_complete:unlock_region(state,"greyhaven_reach")

static func unlock_region(state:Dictionary,region_id:String)->bool:
	if region_id not in CampaignData.REGION_ORDER:return false
	var region_state:Dictionary=state.campaign.regions[region_id]
	if bool(region_state.unlocked):return false
	region_state.unlocked=true
	var first_id:=str(CampaignData.region(region_id).locations[0][0]);region_state.locations[first_id].status="available"
	for row in CampaignData.region(region_id).locations:
		if str(row[2])=="settlement":region_state.locations[str(row[0])].status="discovered"
	state.campaign.event_log.push_front("%s unlocked."%CampaignData.region(region_id).name)
	return true

static func unlock_all_regions(state:Dictionary)->void:
	ensure_state(state)
	for region_id in CampaignData.REGION_ORDER:unlock_region(state,region_id)

static func location_state(state:Dictionary,region_id:String,location_id:String)->Dictionary:
	ensure_state(state)
	return state.campaign.regions.get(region_id,{}).get("locations",{}).get(location_id,{})

static func reputation(state:Dictionary,faction_id:String)->int:
	ensure_state(state)
	return int(state.campaign.reputation.get(faction_id,0))

static func reputation_rank(state:Dictionary,faction_id:String)->Dictionary:
	return CampaignData.reputation_rank(reputation(state,faction_id))

static func adjust_reputation(state:Dictionary,faction_id:String,amount:int,reason:String="")->Dictionary:
	ensure_state(state)
	if faction_id not in CampaignData.FACTIONS:return {"changed":false,"old":0,"new":0}
	var old:=reputation(state,faction_id);var updated:=clampi(old+amount,-100,100)
	state.campaign.reputation[faction_id]=updated
	var faction:=CampaignData.faction(faction_id)
	if amount!=0:state.campaign.event_log.push_front("%s reputation %s%d%s."%[faction.name,"+" if amount>0 else "",amount," — "+reason if reason!="" else ""])
	if faction.region_id=="greyhaven_reach" and updated!=0:
		state.campaign.council_unlocked=true
	var recruited:=false
	if old<50 and updated>=50:recruited=_grant_faction_recruit(state,faction_id)
	return {"changed":old!=updated,"old":old,"new":updated,"rank":CampaignData.reputation_rank(updated).name,"recruited":recruited}

static func _grant_faction_recruit(state:Dictionary,faction_id:String)->bool:
	if faction_id in state.campaign.recruited_factions:return false
	var faction:=CampaignData.faction(faction_id);var target:=int(CampaignData.REGION_TARGET_LEVELS.get(faction.region_id,5));var hero_level:=maxi(1,target-2)
	var hero_id:="faction_%s"%faction_id
	if state.heroes.any(func(hero):return str(hero.get("hero_id",""))==hero_id):state.campaign.recruited_factions.append(faction_id);return false
	state.heroes.append(GuildMemberData.create(faction.recruit_name,faction.recruit_class,hero_level,maxi(10,hero_level*4),"faction_recruit",false,0,{"hero_id":hero_id,"faction_origin":faction_id}))
	state.campaign.recruited_factions.append(faction_id);var title:="Trusted of %s"%faction.name;if title not in state.campaign.faction_titles:state.campaign.faction_titles.append(title);state.campaign.event_log.push_front("%s joined from %s. Title earned: %s."%[faction.recruit_name,faction.name,title])
	return true

static func complete_campaign_encounter(state:Dictionary,region_id:String,location_id:String)->Dictionary:
	ensure_state(state)
	var region_state:Dictionary=state.campaign.regions[region_id];var loc_state:Dictionary=region_state.locations[location_id]
	if bool(loc_state.campaign_completed):return {"advanced":false}
	loc_state.campaign_completed=true;loc_state.status="completed";loc_state.repeatable_pool=repeatable_pool(region_id,location_id)
	var main_ids:=CampaignData.main_locations(region_id);var main_index:=main_ids.find(location_id)
	var reward_level:=int(CampaignData.REGION_MIN_LEVELS[region_id])+maxi(0,main_index)
	var reward_item:=grant_campaign_item(state,region_id,reward_level)
	state.gold=int(state.get("gold",0))+10+reward_level*2;state.guild_renown=int(state.get("guild_renown",0))+3+main_index
	var faction_ids:Array=CampaignData.region(region_id).factions
	if not faction_ids.is_empty():adjust_reputation(state,str(faction_ids[main_index%faction_ids.size()]),5,"regional campaign")
	region_state.campaign_step=maxi(int(region_state.campaign_step),main_index+1)
	var reveal_through:=mini(CampaignData.region(region_id).locations.size()-1,(main_index+1)*3)
	for reveal_index in range(reveal_through+1):
		var reveal_id:=str(CampaignData.region(region_id).locations[reveal_index][0])
		if str(region_state.locations[reveal_id].status)=="undiscovered":region_state.locations[reveal_id].status="discovered"
	if main_index+1<main_ids.size():
		var next_id:=str(main_ids[main_index+1]);region_state.locations[next_id].status="available"
		_discover_neighbors(region_state,location_id)
		return {"advanced":true,"decision_required":false,"item":reward_item}
	return {"advanced":true,"decision_required":true,"item":reward_item}

static func _discover_neighbors(region_state:Dictionary,location_id:String)->void:
	for connected_id in region_state.locations[location_id].connected_locations:
		if region_state.locations.has(connected_id) and str(region_state.locations[connected_id].status)=="undiscovered":region_state.locations[connected_id].status="discovered"

static func apply_decision(state:Dictionary,region_id:String,option_id:String)->Dictionary:
	ensure_state(state)
	if state.campaign.decisions.has(region_id):return {"success":false,"reason":"This decision is permanent."}
	var decision:=CampaignData.decision(region_id);var selected:Array=[]
	for option in decision.get("options",[]):
		if str(option[0])==option_id:selected=option;break
	if selected.is_empty():return {"success":false,"reason":"Unknown decision."}
	state.campaign.decisions[region_id]={"option_id":selected[0],"label":selected[1],"faction_id":selected[2]}
	state.campaign.decision_log.append({"region_id":region_id,"decision":decision.title,"outcome":selected[1]})
	var allied:=str(selected[2])
	for faction_id in CampaignData.region(region_id).factions:adjust_reputation(state,str(faction_id),15 if str(faction_id)==allied else -5 if allied!="" else 0,"permanent regional decision")
	complete_region(state,region_id)
	return {"success":true,"outcome":selected[1]}

static func complete_region(state:Dictionary,region_id:String)->void:
	var region_state:Dictionary=state.campaign.regions[region_id]
	if bool(region_state.completed):return
	region_state.completed=true
	for location_id in region_state.locations:
		if str(region_state.locations[location_id].status)=="undiscovered":region_state.locations[location_id].status="discovered"
	var target:=int(CampaignData.REGION_TARGET_LEVELS[region_id])
	for hero_index in state.get("active_team",[]):
		if int(hero_index)>=0 and int(hero_index)<state.heroes.size() and int(state.heroes[int(hero_index)].level)<target:
			state.heroes[int(hero_index)].level=target;state.heroes[int(hero_index)].xp=0;state.heroes[int(hero_index)].experience=0
	var callback_location:=str(CampaignData.region(region_id).locations[1][0]);region_state.locations[callback_location].returning_event_available=true
	state.campaign.callbacks.append({"region_id":region_id,"location_id":callback_location,"text":CampaignData.region(region_id).callback,"completed":false})
	advance_rivals(state,"Completed %s"%CampaignData.region(region_id).name)
	var next_index:=CampaignData.region_index(region_id)+1
	if next_index<CampaignData.REGION_ORDER.size():unlock_region(state,str(CampaignData.REGION_ORDER[next_index]))
	else:
		state.campaign.finale_complete=true;state.campaign.final_summary=campaign_summary(state)

static func repeatable_pool(region_id:String,location_id:String)->Array:
	var seed:int=absi(hash(region_id+":"+location_id));var pool:Array=[]
	for offset in 3:pool.append(CampaignData.REPEATABLE_TEMPLATES[(seed+offset*3)%CampaignData.REPEATABLE_TEMPLATES.size()])
	return pool

static func rotate_repeatable(state:Dictionary,region_id:String,location_id:String)->String:
	var loc_state:Dictionary=location_state(state,region_id,location_id)
	if loc_state.repeatable_pool.is_empty():loc_state.repeatable_pool=repeatable_pool(region_id,location_id)
	var index:int=int(loc_state.repeatable_rotation)%int(loc_state.repeatable_pool.size());loc_state.repeatable_rotation=index+1
	return str(loc_state.repeatable_pool[index])

static func resolve_repeatable(state:Dictionary,region_id:String,location_id:String)->Dictionary:
	var level:=int(CampaignData.REGION_MIN_LEVELS[region_id]);state.gold=int(state.get("gold",0))+5+level;state.guild_renown=int(state.get("guild_renown",0))+1
	var faction_id:=str(CampaignData.location(region_id,location_id).get("faction_id",""))
	if faction_id!="":adjust_reputation(state,faction_id,4,"completed faction request")
	return {"gold":5+level,"renown":1,"item":grant_campaign_item(state,region_id,level) if (int(state.gold)+level)%3==0 else {}}

static func grant_campaign_item(state:Dictionary,region_id:String,item_level:int)->Dictionary:
	var slots:=ItemData.EQUIPMENT_SLOTS;var slot:=str(slots[(item_level+CampaignData.region_index(region_id))%slots.size()]);var rarity:="Uncommon" if (item_level+state.item_instances.size())%4==0 else "Common"
	var instance_id:=InventorySystem.next_item_instance_id(state,"campaign")
	var adjective:="Stalwart" if slot in ["head","chest","hands"] else "Wayfarer's"
	var item:={"instance_id":instance_id,"definition_id":"campaign_%s_%s"%[region_id,slot],"item_form_id":"campaign_%s_%s"%[region_id,slot],"display_name":"%s %s"%[adjective,slot.capitalize()],"slot":slot,"item_family":"weapon" if slot=="weapon" else slot,"tier":maxi(1,ceili(float(item_level)/5.0)),"rarity":rarity,"item_level":item_level,"item_xp":0,"armor_family_requirement":"","weapon_family_requirement":"","allowed_classes":[],"stat_modifiers":{"power":float(maxi(1,item_level/3))} if slot in ["weapon","neck","trinket"] else {"armor":float(maxi(2,item_level/2))},"passive_effect_ids":[],"traits":[],"trait_capacity":2 if rarity=="Uncommon" else 1,"tags":["campaign"],"element":"","region":region_id,"source_region":region_id,"faction":"","boss_identity":"","source_type":"campaign","contained_parent_items":[],"enchanting_preparation":{},"favourite":false,"reserved":false,"locked":false,"breeding_stock":false,"never_disenchant":false,"never_separate":false,"awaiting_player_review":false,"world_only":false,"craft_only":false,"icon_path":"","fallback_icon_type":slot,"testing_only":false,"owner_state":"vault","equipped_hero_index":-1,"sell_value":4+item_level*2,"gear_power":item_level}
	var result:=InventorySystem.add_equipment(state,item);result["item"]=item if bool(result.get("success",false)) else {};return result

static func can_sell_item(item:Dictionary)->bool:
	return str(item.get("owner_state","vault"))!="equipped" and int(item.get("equipped_hero_index",-1))<0 and not bool(item.get("locked",false)) and not bool(item.get("favourite",false)) and int(item.get("sell_value",0))>0

static func sell_item(state:Dictionary,instance_id:String)->Dictionary:
	var item:=InventorySystem.entry_by_id(state,instance_id)
	if item.is_empty() or not can_sell_item(item):return {"success":false,"gold":0}
	var value:=int(item.sell_value);state.item_instances.erase(item);state.gold=int(state.get("gold",0))+value
	return {"success":true,"gold":value}

static func sell_all_common(state:Dictionary)->Dictionary:
	var sold:=0;var earned:=0
	for item in state.item_instances.duplicate():
		if str(item.get("rarity",""))=="Common" and can_sell_item(item):earned+=int(item.sell_value);state.item_instances.erase(item);sold+=1
	state.gold=int(state.get("gold",0))+earned
	return {"sold":sold,"gold":earned}

static func settlement_access(state:Dictionary,faction_id:String)->Dictionary:
	var value:=reputation(state,faction_id);var rank:=CampaignData.reputation_rank(value)
	return {"allowed":value>=0,"value":value,"rank":rank.name,"required":"Neutral (0)","guard_level_bonus":4 if value<=-50 else 2}

static func resolve_guard_victory(state:Dictionary,region_id:String,location_id:String,faction_id:String)->Dictionary:
	var loc_state:=location_state(state,region_id,location_id)
	adjust_reputation(state,faction_id,-20,"attacked faction guards")
	if bool(loc_state.guard_reward_claimed):return {"gold":0,"renown":0,"repeat":true}
	loc_state.guard_reward_claimed=true;state.guild_renown=int(state.get("guild_renown",0))+2
	return {"gold":0,"renown":2,"item":grant_campaign_item(state,region_id,int(CampaignData.REGION_TARGET_LEVELS[region_id]))}

static func complete_callback(state:Dictionary,region_id:String)->Dictionary:
	var region_state:Dictionary=state.campaign.regions[region_id]
	if bool(region_state.returning_event_completed):return {"success":false}
	region_state.returning_event_completed=true
	for entry in state.campaign.callbacks:
		if str(entry.region_id)==region_id:entry.completed=true
	var modifier:="Resolved callback: %s"%CampaignData.region(region_id).callback
	if modifier not in state.campaign.final_modifiers:state.campaign.final_modifiers.append(modifier)
	state.guild_renown=int(state.get("guild_renown",0))+5
	return {"success":true,"renown":5,"final_modifier":modifier}

static func set_support_team(state:Dictionary,region_id:String,team_key:String,hero_indices:Array)->Dictionary:
	ensure_state(state)
	if team_key not in ["support_team_a","support_team_b"]:return {"success":false,"reason":"Unknown support team."}
	var clean:Array=[]
	for value in hero_indices:
		var index:=int(value)
		if index>=0 and index<state.heroes.size() and index not in clean:clean.append(index)
	clean=clean.slice(0,4)
	var other_key:="support_team_b" if team_key=="support_team_a" else "support_team_a"
	if clean.any(func(index):return index in state.campaign.regions[region_id][other_key]):return {"success":false,"reason":"A hero cannot serve on both support teams."}
	state.campaign.regions[region_id][team_key]=clean
	return {"success":true,"team":clean}

static func resolve_operation(state:Dictionary,region_id:String)->Dictionary:
	ensure_state(state);var region_state:Dictionary=state.campaign.regions[region_id]
	var score:int=region_state.support_team_a.size()*2+region_state.support_team_b.size()*2
	for hero_index in region_state.support_team_a+region_state.support_team_b:score+=int(state.heroes[int(hero_index)].level)/10
	for faction_id in CampaignData.region(region_id).factions:
		if reputation(state,str(faction_id))>=50:score+=2
	var result:="Strong" if score>=18 else "Adequate" if score>=10 else "Weak" if score>0 else "Missing"
	state.campaign.operation_counter+=1
	var record:={"operation_id":"operation_%d"%state.campaign.operation_counter,"region_id":region_id,"support_score":score,"result":result,"team_a":region_state.support_team_a.duplicate(),"team_b":region_state.support_team_b.duplicate()}
	state.campaign.guild_operations.append(record);region_state.operations[record.operation_id]=record
	return record

static func advance_rivals(state:Dictionary,activity:String)->void:
	ensure_state(state);state.campaign.rival_round+=1
	var round_number:=int(state.campaign.rival_round)
	for rival_id in state.campaign.rivals:
		var rival:Dictionary=state.campaign.rivals[rival_id];var gain:int=1+(absi(hash(str(rival_id)+str(round_number)))%4)
		rival.standing=clampi(int(rival.standing)+gain,0,100);rival.encounters=int(rival.encounters)+1
		rival.activity_log.push_front("Round %d: %s (+%d standing)."%[round_number,activity,gain]);rival.activity_log=rival.activity_log.slice(0,8)

static func campaign_summary(state:Dictionary)->Dictionary:
	var completed:=0;var trusted:=0
	for region_id in CampaignData.REGION_ORDER:
		if bool(state.campaign.regions[region_id].completed):completed+=1
	for faction_id in CampaignData.FACTIONS:
		if reputation(state,faction_id)>=50:trusted+=1
	return {"regions_completed":completed,"decisions":state.campaign.decision_log.duplicate(true),"callbacks_resolved":state.campaign.callbacks.filter(func(entry):return bool(entry.completed)).size(),"final_modifiers":state.campaign.final_modifiers.duplicate(),"faction_titles":state.campaign.faction_titles.duplicate(),"trusted_factions":trusted,"roster_size":state.heroes.size(),"renown":int(state.get("guild_renown",0)),"gateway_outcome":state.campaign.decisions.get("grand_corruption_front",{}).get("label","Unresolved")}
