extends RefCounted

const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const ClassData = preload("res://scripts/data/class_data.gd")
const TalentData = preload("res://scripts/data/talent_data.gd")

const GUILD_PAGE_INTROS := {
	"command":{"title":"COMMAND TABLE","body":"The Command Table is where the guild will organize missions beyond the active party. It is intended for assigning available heroes to longer tasks, following opportunities, and collecting useful rewards."},
	"heroes":{"title":"HERO ROSTER","body":"Hero Roster is the guild's complete member directory. Review each hero's role and growth, inspect their abilities and equipment, and use the star on a card to update the Active Party."},
	"party":{"title":"PARTY MANAGEMENT","body":"Party Management is for building the group that enters battle. Arrange the Active Party, keep other heroes in reserve, and prepare saved formations for different kinds of encounters."},
	"vault":{"title":"ITEM STORAGE","body":"Item Storage keeps equipment, materials, and other valuables collected by the guild. As these systems expand, this is where items can be organized and prepared for the heroes who need them."},
	"tavern":{"title":"TAVERN","body":"The Tavern is intended as the guild's meeting place for new contacts, recruitment opportunities, rumors, and temporary arrangements that may help future expeditions."},
	"merchant":{"title":"MERCHANT CONTACTS","body":"Merchant Contacts gathers the traders the guild has discovered. This page will support buying, selling, specialized wares, and trade opportunities tied to different parts of the world."},
	"workshop":{"title":"WORKSHOP","body":"The Workshop is where guild professions turn gathered resources into useful supplies and equipment. It will grow into the main place for crafting, improving, and preparing expedition tools."}
}

const TALENT_TIER_DEFINITIONS := TalentData.TIER_DEFINITIONS
const CLASS_IDS_BY_DISPLAY_NAME := ClassData.CLASS_IDS_BY_DISPLAY_NAME
const CLASSES := ClassData.CLASSES
const ABILITIES := ClassData.ABILITIES
const TRAITS := ClassData.TRAITS
const ABILITY_TARGETING := ClassData.ABILITY_TARGETING
const ABILITY_RANGES := ClassData.ABILITY_RANGES
const ABILITY_DESCRIPTIONS := ClassData.ABILITY_DESCRIPTIONS

const WAVE_ENEMY_ROLES := ["Raider","Swift","Archer","Raider","Shaman","Brute"]

const ENEMIES := {
	"Dummy":{"base_health":150.0,"health_growth":0.03,"base_power":0.0,"power_growth":0.03,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":0.0,"basic_action_interval":2.0,"basic_action_range":0.0,"movement_speed":0.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":[],"combat_tags":["training"],"color":Color("9a7652")},
	"Defense Dummy":{"base_health":5000.0,"health_growth":0.03,"base_power":12.0,"power_growth":0.03,"base_armor":15.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.8,"basic_action_range":125.0,"movement_speed":0.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":["ranged","stationary"],"combat_tags":["training","defense"],"color":Color("c06f45"),"ranged":true},
	"Raider":{"base_health":150.0,"health_growth":0.03,"base_power":16.0,"power_growth":0.03,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":2.03,"basic_action_range":44.0,"movement_speed":110.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":[],"combat_tags":["regular","melee"],"color":Color("bd4d58")},
	"Swift":{"base_health":90.0,"health_growth":0.03,"base_power":16.0,"power_growth":0.03,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":2.03,"basic_action_range":44.0,"movement_speed":160.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":["prefers_backline"],"combat_tags":["light","melee"],"color":Color("e05f8f"),"prefers_backline":true},
	"Stalker":{"base_health":45.0,"health_growth":0.03,"base_power":8.0,"power_growth":0.03,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":2.03,"basic_action_range":44.0,"movement_speed":160.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":["prefers_backline","ignores_tank_aggro"],"combat_tags":["light","melee"],"color":Color("d971b0"),"prefers_backline":true,"ignores_tank_aggro":true},
	"Archer":{"base_health":150.0,"health_growth":0.03,"base_power":16.0,"power_growth":0.03,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":2.03,"basic_action_range":185.0,"movement_speed":110.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":["ranged"],"combat_tags":["regular","ranged"],"color":Color("8f68d8"),"ranged":true},
	"Shaman":{"base_health":150.0,"health_growth":0.03,"base_power":16.0,"power_growth":0.03,"base_armor":0.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":3.2,"basic_action_range":185.0,"movement_speed":110.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"magical","behavior_flags":["ranged","healer"],"combat_tags":["regular","ranged"],"color":Color("58a878"),"ranged":true},
	"Brute":{"base_health":250.0,"health_growth":0.03,"base_power":16.0,"power_growth":0.03,"base_armor":12.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":2.03,"basic_action_range":44.0,"movement_speed":75.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":[],"combat_tags":["heavy","melee"],"color":Color("d97a45")},
	"Boss":{"base_health":500.0,"health_growth":0.03,"base_power":26.0,"power_growth":0.03,"base_armor":15.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":4.0,"basic_action_range":44.0,"movement_speed":75.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":["boss"],"combat_tags":["boss"],"color":Color("e5863f"),"boss":true},
	"Rune Servant":{"base_health":420.0,"health_growth":0.03,"base_power":26.0,"power_growth":0.03,"base_armor":15.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":4.0,"basic_action_range":44.0,"movement_speed":75.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"magical","behavior_flags":["boss"],"combat_tags":["boss"],"color":Color("ba565f"),"boss":true},
	"Ashwood Servant":{"base_health":720.0,"health_growth":0.03,"base_power":26.0,"power_growth":0.03,"base_armor":18.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":4.0,"basic_action_range":44.0,"movement_speed":75.0,"base_critical_chance":0.0,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":["boss"],"combat_tags":["boss"],"color":Color("e06b42"),"boss":true},
	"Controlled Rogue":{"base_health":220.0,"health_growth":0.03,"base_power":16.0,"power_growth":0.03,"base_armor":10.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.2,"basic_action_range":55.0,"movement_speed":145.0,"base_critical_chance":0.05,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":[],"combat_tags":["hero"],"color":Color("e6b35f")},
	"Controlled Ranger":{"base_health":210.0,"health_growth":0.03,"base_power":14.0,"power_growth":0.03,"base_armor":9.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.2,"basic_action_range":185.0,"movement_speed":145.0,"base_critical_chance":0.05,"critical_damage":2.0,"basic_action_damage_type":"physical","behavior_flags":["ranged"],"combat_tags":["hero","ranged"],"color":Color("65dc89"),"ranged":true},
	"Controlled Mage":{"base_health":190.0,"health_growth":0.03,"base_power":14.0,"power_growth":0.03,"base_armor":3.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.2,"basic_action_range":185.0,"movement_speed":145.0,"base_critical_chance":0.05,"critical_damage":2.0,"basic_action_damage_type":"magical","behavior_flags":["ranged"],"combat_tags":["hero","ranged"],"color":Color("b381ff"),"ranged":true},
	"Controlled Warlock":{"base_health":200.0,"health_growth":0.03,"base_power":15.0,"power_growth":0.03,"base_armor":4.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.2,"basic_action_range":185.0,"movement_speed":145.0,"base_critical_chance":0.05,"critical_damage":2.0,"basic_action_damage_type":"magical","behavior_flags":["ranged"],"combat_tags":["hero","ranged"],"color":Color("d16ca8"),"ranged":true}
}

const WORLD_MAP_SIZE := Vector2(1536,864)
const WORLD_ACTIVE_REGION := {"name":"ASHWOOD MARCHES","zone":0,"position":Vector2(345,405),"size":Vector2(250,94)}
const LOCKED_WORLD_REGIONS := [
	["EMBER WASTES",Vector2(155,175)],
	["FROSTPEAK",Vector2(760,105)],
	["MIREFANG WILDS",Vector2(1010,410)],
	["SUN COAST",Vector2(760,655)],
	["DREAD ISLE",Vector2(135,655)]
]

const ZONE_NAMES := ["Ashwood Marches","Mirefang Wilds"]
const ZONE_NODE_NAMES := [
	["Old Road","Bandit Camp","Timber Run","Broken Bridge","Wolf Hollow","Forest Shrine","Watchtower","Burned Village","Keep Approach","Ashwood Keep","Hidden Grove","Smuggler Cave"],
	["Fen Trail","Spore Hollow","Reed Crossing","Sunken Ruin","Bog Camp","Witch Pool","Rotwood","Drowned Court","Den Approach","Mirefang Den","Moonwell","Buried Temple"]
]
const ZONE_NODE_POSITIONS := [Vector2(25,245),Vector2(130,175),Vector2(235,245),Vector2(340,155),Vector2(445,235),Vector2(550,145),Vector2(655,225),Vector2(760,135),Vector2(865,215),Vector2(970,145),Vector2(350,330),Vector2(675,330)]
const ZONE_BRANCHES := [[3,10,0],[6,11,1]]
const MISSIONS := [
	["Ashwood Patrol","2 hours","Ore and ●"],
	["Supply Run","45 minutes","Crafting Materials"],
	["Scout Mirefang","4 hours","Map Intel"]
]

const MERCHANTS := [
	["Borin Ironhand","Travelling Blacksmith","Ashwood Marches","Weapons, armour, Mining tools, Blacksmithing recipes"],
	["Mira Greenbottle","Wandering Alchemist","Mirefang Wilds","Potions, herbs, Alchemy recipes"],
	["Corvin Vale","Trade Broker","Unknown","Selling services and merchant contracts"]
]

const PROFESSIONS := [
	["Alchemy","Field Tonics","3 Herbs","herbs",3,"tonic"],
	["Blacksmithing","Tempered Arms","4 Ore","ore",4,"gear"],
	["Enchanting","Arcane Reinforcement","3 Arcane Dust","dust",3,"gear"],
	["Engineering","Practice Mechanism","4 Ore","ore",4,"gear"],
	["Herbalism","Gathering Route","No cost","herbs",0,"tonic"],
	["Leatherworking","Reinforced Leather","3 Herbs","herbs",3,"gear"],
	["Mining","Ore Survey","No cost","ore",0,"gear"],
	["Skinning","Field Dressing","No cost","ore",0,"gear"],
	["Tailoring","Traveling Cloak","3 Arcane Dust","dust",3,"gear"],
	["Jewelcrafting","Cut Gem","3 Ore","ore",3,"gear"],
	["Inscription","Arcane Glyph","2 Herbs","herbs",2,"gear"],
	["Archaeology","Recovered Relic","No cost","ore",0,"gear"],
	["Cooking","Guild Feast","3 Herbs","herbs",3,"tonic"],
	["First Aid","Heavy Bandages","2 Herbs","herbs",2,"tonic"],
	["Fishing","Quiet Waters","No cost","herbs",0,"tonic"]
]
const STORAGE_ITEMS := [
	["Ore","ore",Color("a9b5c7")],
	["Herbs","herbs",Color("54d69a")],
	["Dust","dust",Color("b381ff")],
	["Tonics","tonics",Color("6ed9ef")]
]
const STORAGE_COLUMNS := 10
const STORAGE_BAG_SLOTS := 6
const STORAGE_MAX_CAPACITY := 180
const STORAGE_BAG_CAPACITY := 30
const STORAGE_BAG_UNLOCK_BASE_COST := 120

static func class_id_for(value:String)->String:
	if value in CLASS_IDS_BY_DISPLAY_NAME:return CLASS_IDS_BY_DISPLAY_NAME[value]
	var normalized:=value.to_snake_case()
	return normalized if normalized in CLASS_IDS_BY_DISPLAY_NAME.values() else ""

static func class_display_name(class_id:String)->String:
	for display_name in CLASS_IDS_BY_DISPLAY_NAME:
		if CLASS_IDS_BY_DISPLAY_NAME[display_name]==class_id:return display_name
	return class_id.capitalize()

static func class_definition(value:String)->Dictionary:
	var display_name:=value if value in CLASSES else class_display_name(value)
	return CLASSES.get(display_name,{})

static func ability_tooltip(hero_class:String, slot:int) -> String:
	return ABILITY_DESCRIPTIONS[hero_class][slot]

static func enemy_color(enemy_type:String) -> Color:
	return ENEMIES.get(enemy_type, {"color":Color("bd4d58")})["color"]

static func create_enemy(enemy_type:String, pos:Vector2, dungeon_id:int) -> Dictionary:
	var enemy_data:Dictionary = ENEMIES.get(enemy_type, ENEMIES["Raider"])
	var boss:=bool(enemy_data.get("boss",false))
	var enemy_level:int=CombatSystem.clamp_level(1+dungeon_id);var resolved:=CombatSystem.calculate_final_stats(enemy_data,enemy_level)
	return {"type":enemy_type,"definition":enemy_data,"stats":resolved,"level":enemy_level,"pos":pos,"facing_direction":Vector2.LEFT,"hp":resolved.health,"max_hp":resolved.health,"percent_damage_health_basis":resolved.health,"power":resolved.power,"armor":resolved.armor,"basic_action_type":"attack","basic_action_power_coefficient":resolved.basic_action_power_coefficient,"basic_action_amount":resolved.basic_action_amount,"basic_action_range":resolved.basic_action_range,"attack_range":resolved.basic_action_range,"damage":resolved.basic_action_amount,"range":resolved.basic_action_range,"movement_speed":resolved.movement_speed,"basic_action_interval":resolved.basic_action_interval,"basic_attack_interval":resolved.basic_action_interval,"critical_chance":resolved.critical_chance,"critical_damage":resolved.critical_damage,"basic_action_damage_type":resolved.basic_action_damage_type,"basic_attack_damage_type":resolved.basic_action_damage_type,"shield":0.0,"shield_sources":[],"active_effects":[],"passive_cooldowns":{},"cooldown":1.0,"telegraph":0.0,"target":0,"threat":{},"objective_threat":0.0,"taunt_target":-1,"taunt_time":0.0,"prefers_backline":bool(enemy_data.get("prefers_backline",false)),"ignores_tank_aggro":bool(enemy_data.get("ignores_tank_aggro",false)),"special":"","special_index":0,"danger_pos":pos,"summoned":false,"enraged":false,"revealed":false,"rewarded":false,"boss":boss,"ranged":bool(enemy_data.get("ranged",false)),"behavior_flags":enemy_data.behavior_flags.duplicate(),"combat_tags":enemy_data.combat_tags.duplicate()}
