extends RefCounted

const GameData = preload("res://scripts/data/game_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")

static func create(
		hero_name:String,
		hero_class:String,
		level:int,
		gear:int,
		member_type:String="guild_recruit",
		special:bool=false,
		legacy_rank:int=0,
		extras:Dictionary={}
	) -> Dictionary:
	var identity_type:="special" if special else "standard"
	var hero_id:=str(extras.get("hero_id",hero_name.to_snake_case()))
	var hero:={
		"hero_id":hero_id,"class_id":GameData.class_id_for(hero_class),"identity_type":identity_type,
		"named_hero_definition_id":str(extras.get("named_hero_definition_id",extras.get("special_identifier",""))) if special else "",
		"name":hero_name,"display_name":hero_name,"class":hero_class,"editable_name":not special,
		"editable_appearance":not special,"can_edit_name":not special,"can_edit_appearance":not special,
		"appearance_data":{},"playable_race_id":"","level":level,"xp":0,"experience":0,"gear":gear,
		"selected_talents":{},"planned_talents":{},"selected_heroic_id":"","equipment":[],
		"equipment_slots":ItemData.empty_equipment_slots(),"member_type":member_type,"is_special_hero":special,
		"legacy_rank":legacy_rank,"prestige_rank":legacy_rank,
		"prestige_reward_floor_rank":legacy_rank if special else 0,"completed_prestige_cycles":0,
		"active_prestige_challenge_id":"","completed_prestige_challenge_ids":[],"prestige_specialization_ids":[],
		"prestige_reward_history":[],"prestige_five_legacy_id":"","is_guild_champion":false,
		"profession_progress":{},"pvp_progress":{},"guild_position_id":"","temporary_buffs":[],"active_prestige_challenge":"",
		"completed_prestige_challenges":[],"legacy_perk_ids":[],"prestige_unlock_tags":[]
	}
	hero.merge(extras,true)
	return hero
