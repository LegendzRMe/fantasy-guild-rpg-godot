extends RefCounted

const ItemData = preload("res://scripts/data/item_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")

const REWARD_DEFINITIONS := {
	1:{"prestige_tokens":0,"guild_renown":0,"guild_prestige":0,"cache_id":"prestige_rank_1","guild_specialization_choice_ids":[],"cosmetic_unlock_ids":[],"title_unlock_ids":[]},
	2:{"prestige_tokens":0,"guild_renown":0,"guild_prestige":0,"cache_id":"prestige_rank_2","guild_specialization_choice_ids":[],"cosmetic_unlock_ids":[],"title_unlock_ids":[]},
	3:{"prestige_tokens":0,"guild_renown":0,"guild_prestige":0,"cache_id":"prestige_rank_3","guild_specialization_choice_ids":[],"cosmetic_unlock_ids":[],"title_unlock_ids":[]},
	4:{"prestige_tokens":0,"guild_renown":0,"guild_prestige":0,"cache_id":"prestige_rank_4","guild_specialization_choice_ids":[],"cosmetic_unlock_ids":[],"title_unlock_ids":[]},
	5:{"prestige_tokens":0,"guild_renown":0,"guild_prestige":0,"cache_id":"prestige_rank_5","guild_specialization_choice_ids":[],"cosmetic_unlock_ids":[],"title_unlock_ids":[]}
}

const CACHE_DEFINITIONS := {
	"prestige_rank_1":{"cache_id":"prestige_rank_1","completed_prestige_rank":1,"rarity_floor":"Common","rarity_weights":{},"guaranteed_reward_entries":[],"optional_reward_entries":[],"equipment_count":1,"material_count":0,"currency_rewards":{},"class_specific_item_weights":{}},
	"prestige_rank_2":{"cache_id":"prestige_rank_2","completed_prestige_rank":2,"rarity_floor":"Uncommon","rarity_weights":{},"guaranteed_reward_entries":[],"optional_reward_entries":[],"equipment_count":1,"material_count":0,"currency_rewards":{},"class_specific_item_weights":{}},
	"prestige_rank_3":{"cache_id":"prestige_rank_3","completed_prestige_rank":3,"rarity_floor":"Uncommon","rarity_weights":{},"guaranteed_reward_entries":[],"optional_reward_entries":[],"equipment_count":1,"material_count":0,"currency_rewards":{},"class_specific_item_weights":{}},
	"prestige_rank_4":{"cache_id":"prestige_rank_4","completed_prestige_rank":4,"rarity_floor":"Rare","rarity_weights":{},"guaranteed_reward_entries":[],"optional_reward_entries":[],"equipment_count":1,"material_count":0,"currency_rewards":{},"class_specific_item_weights":{}},
	"prestige_rank_5":{"cache_id":"prestige_rank_5","completed_prestige_rank":5,"rarity_floor":"Rare","rarity_weights":{},"guaranteed_reward_entries":[],"optional_reward_entries":[],"equipment_count":1,"material_count":0,"currency_rewards":{},"class_specific_item_weights":{}}
}

static func reward_key(hero_id:String,rank:int)->String:
	return "%s:rank_%d"%[hero_id,rank]

static func compatible_definition_ids(class_definition:Dictionary,hero_class:String)->Array:
	var result:Array=[]
	for definition_id in ItemData.ITEMS:
		var definition:Dictionary=ItemData.ITEMS[definition_id]
		if bool(definition.get("testing_only",false)):continue
		if ItemData.can_equip(definition,class_definition,hero_class):result.append(definition_id)
	return result

static func build_cache_claim(cache_id:String,hero:Dictionary,class_definition:Dictionary)->Dictionary:
	var cache:Dictionary=CACHE_DEFINITIONS.get(cache_id,{})
	if cache.is_empty():return {"success":false,"reason":"Unknown Prestige Cache"}
	var compatible:=compatible_definition_ids(class_definition,str(hero.get("class",class_definition.get("display_name",""))))
	if compatible.is_empty():return {"success":false,"reason":"No compatible equipment definitions"}
	var outputs:Array=[]
	for count in int(cache.get("equipment_count",0)):
		var definition_id:String=str(compatible[count%compatible.size()])
		outputs.append({"kind":"equipment","item":ItemData.create_instance(definition_id,"")})
	return {"success":true,"reason":"","outputs":outputs,"source_hero_class_id":hero.get("class_id","")}

static func claim_rank_reward(state:Dictionary,hero_index:int,rank:int,class_definition:Dictionary)->Dictionary:
	if hero_index<0 or hero_index>=state.get("heroes",[]).size() or rank<1 or rank>5:return {"success":false,"reason":"Invalid Prestige reward"}
	var hero:Dictionary=state.heroes[hero_index];var key:=reward_key(str(hero.get("hero_id","")),rank)
	if int(hero.get("prestige_rank",0))<rank:return {"success":false,"reason":"Prestige rank has not been completed"}
	if rank<=int(hero.get("prestige_reward_floor_rank",0)):return {"success":false,"reason":"Starting Prestige ranks do not grant retroactive rewards"}
	if key in hero.get("prestige_reward_history",[]):return {"success":false,"reason":"Prestige reward already claimed"}
	var reward:Dictionary=REWARD_DEFINITIONS.get(rank,{})
	var cache_claim:=build_cache_claim(str(reward.get("cache_id","")),hero,class_definition)
	if not cache_claim.success:return cache_claim
	var inventory_check:=InventorySystem.simulate_inventory_transaction(state,[],cache_claim.outputs)
	if not inventory_check.success:return {"success":false,"reason":inventory_check.reason,"unclaimed":true}
	var next:=state.duplicate(true)
	var inventory_result:=InventorySystem.apply_inventory_transaction(next,[],cache_claim.outputs)
	if not inventory_result.success:return {"success":false,"reason":inventory_result.reason,"unclaimed":true}
	next["prestige_tokens"]=int(next.get("prestige_tokens",0))+int(reward.get("prestige_tokens",0))
	next["guild_renown"]=int(next.get("guild_renown",0))+int(reward.get("guild_renown",0))
	next.heroes[hero_index].prestige_reward_history.append(key)
	return {"success":true,"reason":"","state":next,"reward_key":key}
