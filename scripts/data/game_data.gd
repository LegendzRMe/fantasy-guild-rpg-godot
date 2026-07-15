extends RefCounted

const GUILD_PAGE_INTROS := {
	"command":{"title":"COMMAND TABLE","body":"The Command Table is where the guild will organize missions beyond the active party. It is intended for assigning available heroes to longer tasks, following opportunities, and collecting useful rewards."},
	"heroes":{"title":"HERO ROSTER","body":"Hero Roster is the guild's complete member directory. Review each hero's role and growth, inspect their abilities and equipment, and use the star on a card to update the Active Party."},
	"party":{"title":"PARTY MANAGEMENT","body":"Party Management is for building the group that enters battle. Arrange the Active Party, keep other heroes in reserve, and prepare saved formations for different kinds of encounters."},
	"vault":{"title":"ITEM STORAGE","body":"Item Storage keeps equipment, materials, and other valuables collected by the guild. As these systems expand, this is where items can be organized and prepared for the heroes who need them."},
	"tavern":{"title":"TAVERN","body":"The Tavern is intended as the guild's meeting place for new contacts, recruitment opportunities, rumors, and temporary arrangements that may help future expeditions."},
	"merchant":{"title":"MERCHANT CONTACTS","body":"Merchant Contacts gathers the traders the guild has discovered. This page will support buying, selling, specialized wares, and trade opportunities tied to different parts of the world."},
	"workshop":{"title":"WORKSHOP","body":"The Workshop is where guild professions turn gathered resources into useful supplies and equipment. It will grow into the main place for crafting, improving, and preparing expedition tools."}
}

const CLASSES := {
	"Guardian": {"role":"Tank", "color":Color("5fa8ff"), "hp":230.0, "damage":10.0, "range":55.0, "ability":"Shield Wall"},
	"Cleric": {"role":"Healer", "color":Color("ffd86a"), "hp":150.0, "damage":8.0, "range":150.0, "ability":"Radiant Mend"},
	"Rogue": {"role":"DPS", "color":Color("e6b35f"), "hp":175.0, "damage":16.0, "range":55.0, "ability":"Veiled Strike"},
	"Ranger": {"role":"DPS", "color":Color("65dc89"), "hp":165.0, "damage":14.0, "range":210.0, "ability":"Volley"},
	"Mage": {"role":"DPS", "color":Color("b381ff"), "hp":135.0, "damage":14.0, "range":190.0, "ability":"Arc Burst"},
	"Warlock": {"role":"DPS", "color":Color("d16ca8"), "hp":145.0, "damage":15.0, "range":185.0, "ability":"Blackflame Bolt"}
}

const ABILITIES := {
	"Guardian": ["Shield Wall", "Challenge", "Shield Rush", "Last Bastion"],
	"Cleric": ["Radiant Mend", "Sanctuary", "Purifying Light", "Divine Renewal"],
	"Rogue": ["Veiled Strike", "Shadowstep", "Fan of Knives", "Deathmark"],
	"Ranger": ["Piercing Shot", "Quickstep", "Volley", "Arrowstorm"],
	"Mage": ["Arc Bolt", "Blink", "Arc Burst", "Starfall"],
	"Warlock": ["Blackflame Bolt", "Dark Passage", "Withering Circle", "Soulstorm"]
}

const TRAITS := {
	"Guardian":"Bulwark",
	"Cleric":"Grace",
	"Rogue":"Opportunist",
	"Ranger":"Keen Eye",
	"Mage":"Arcane Echo",
	"Warlock":"Soulbrand"
}

const ABILITY_TARGETING := {
	"Guardian":["self","area","directional","area"],
	"Cleric":["ally","area","area","area"],
	"Rogue":["enemy","directional","area","enemy"],
	"Ranger":["enemy","directional","ground","ground"],
	"Mage":["enemy","ground","area","ground"],
	"Warlock":["enemy","ground","ground","area"]
}

const ABILITY_RANGES := {
	"Guardian":[0.0,170.0,100.0,0.0],
	"Cleric":[0.0,0.0,180.0,0.0],
	"Rogue":[0.0,160.0,120.0,0.0],
	"Ranger":[0.0,120.0,280.0,320.0],
	"Mage":[0.0,360.0,240.0,330.0],
	"Warlock":[0.0,330.0,270.0,0.0]
}

const ABILITY_DESCRIPTIONS := {
	"Guardian":["Reduce incoming damage for a short time.","Force nearby enemies to focus the Guardian.","Rush forward and strike enemies in the path.","Protect the entire party with a powerful barrier."],
	"Cleric":["Deliver a strong heal to the most wounded ally.","Restore health to the full party.","Heal allies and damage nearby enemies.","Greatly restore the party during an emergency."],
	"Rogue":["Strike the assigned target for heavy melee damage.","Step quickly toward a chosen position.","Damage nearby enemies with thrown blades.","Mark the assigned enemy for a devastating strike."],
	"Ranger":["Fire a powerful shot at the assigned target.","Quickly reposition away from danger.","Damage enemies across a wide area.","Rain arrows across the battlefield."],
	"Mage":["Strike the assigned target with arcane power.","Blink instantly toward the chosen position.","Damage enemies surrounding the Mage.","Call down arcane energy on every enemy."],
	"Warlock":["Burn the assigned target with black flame.","Pass through shadow toward a chosen position.","Damage enemies inside a cursed area.","Unleash bound souls against every nearby enemy."]
}

const WAVE_ENEMY_ROLES := ["Raider","Swift","Archer","Raider","Shaman","Brute"]

const ENEMIES := {
	"Dummy":{"base_hp":150.0,"color":Color("9a7652")},
	"Raider":{"base_hp":150.0,"color":Color("bd4d58")},
	"Swift":{"base_hp":90.0,"color":Color("e05f8f"),"prefers_backline":true},
	"Stalker":{"base_hp":45.0,"base_damage":8.0,"color":Color("d971b0"),"prefers_backline":true,"ignores_tank_aggro":true},
	"Archer":{"base_hp":150.0,"color":Color("8f68d8")},
	"Shaman":{"base_hp":150.0,"color":Color("58a878")},
	"Brute":{"base_hp":250.0,"color":Color("d97a45")},
	"Boss":{"base_hp":500.0,"color":Color("e5863f"),"boss":true},
	"Rune Servant":{"base_hp":420.0,"color":Color("ba565f"),"boss":true},
	"Ashwood Servant":{"base_hp":720.0,"color":Color("e06b42"),"boss":true},
	"Controlled Rogue":{"base_hp":220.0,"color":Color("e6b35f")},
	"Controlled Ranger":{"base_hp":210.0,"color":Color("65dc89"),"ranged":true},
	"Controlled Mage":{"base_hp":190.0,"color":Color("b381ff"),"ranged":true},
	"Controlled Warlock":{"base_hp":200.0,"color":Color("d16ca8"),"ranged":true}
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
const STORAGE_BAG_CAPACITY := 10
const STORAGE_BAG_UNLOCK_BASE_COST := 120
static func ability_tooltip(hero_class:String, slot:int) -> String:
	return ABILITY_DESCRIPTIONS[hero_class][slot]

static func enemy_color(enemy_type:String) -> Color:
	return ENEMIES.get(enemy_type, {"color":Color("bd4d58")})["color"]

static func create_enemy(enemy_type:String, pos:Vector2, dungeon_id:int) -> Dictionary:
	var enemy_data:Dictionary = ENEMIES.get(enemy_type, ENEMIES["Raider"])
	var boss:=bool(enemy_data.get("boss",false))
	var base_hp:float=enemy_data["base_hp"]
	var base_damage:float=float(enemy_data.get("base_damage",16.0))
	return {"type":enemy_type,"pos":pos,"facing_direction":Vector2.LEFT,"hp":base_hp*(1+dungeon_id*.25),"max_hp":base_hp*(1+dungeon_id*.25),"damage":base_damage+dungeon_id*4+(10 if boss else 0),"cooldown":1.0,"telegraph":0.0,"target":0,"threat":{},"objective_threat":0.0,"taunt_target":-1,"taunt_time":0.0,"prefers_backline":bool(enemy_data.get("prefers_backline",false)),"ignores_tank_aggro":bool(enemy_data.get("ignores_tank_aggro",false)),"special":"","special_index":0,"danger_pos":pos,"summoned":false,"enraged":false,"revealed":false,"rewarded":false,"boss":boss,"ranged":bool(enemy_data.get("ranged",false))}
