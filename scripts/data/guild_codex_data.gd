extends RefCounted

const GameData = preload("res://scripts/data/game_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const AshwoodData = preload("res://scripts/data/ashwood_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const ProfessionData = preload("res://scripts/data/profession_data.gd")
const ProfessionSystem = preload("res://scripts/systems/profession_system.gd")

const CATEGORIES := ["Guide","Enemies","Items & Loot","Locations","Journey","Workshop","Tavern"]

static func entry(category:String,entry_id:String,title:String,summary:String,details:String,discovered:bool=true)->Dictionary:
	return {"id":"%s:%s"%[category.to_snake_case(),entry_id],"category":category,"title":title,"summary":summary,"details":details,"discovered":discovered}

static func guide_entries()->Array:
	return [
		entry("Guide","guild_hall","Guild Hall","The guild's physical navigation hub.","Rooms in the Guild Hall open the guild's major systems. Drag or swipe horizontally to explore its public, core, production, and expansion wings."),
		entry("Guide","guild_vault","Guild Vault","The protected half of Guild Storage.","The Workshop never consumes anything protected in the Guild Vault. Equipment, valuables, and reserved material stacks occupy Vault slots."),
		entry("Guide","materials_depot","Workshop Depot","The production-ready half of Guild Storage.","Raw materials enter the Depot automatically. Unequipped gear can be sent here for enchanting, upgrading, separation, or other Workshop orders. Return anything to the Guild Vault to protect it."),
		entry("Guide","workshop_orders","Workshop Orders","Recipes queued for an eligible profession station.","Orders use only Workshop Depot resources and item inputs. Protected Vault holdings remain untouched. Finished equipment returns to the Guild Vault."),
		entry("Guide","gold","Gold","The guild's spendable currency.","Gold is used for purchases, services, and expansions. It is not stored in the Guild Vault or Materials Depot."),
		entry("Guide","renown","Renown","A record of the guild's growing reputation.","Renown reflects the guild's accomplishments and influence. It appears beside Gold in the Guild Hall header."),
		entry("Guide","discovery","Codex Discovery","Knowledge is recorded as the guild encounters it.","Enemies, locations, items, and journey records reveal as the guild experiences them. Undiscovered entries remain hidden rather than exposing future content.")
	]

static func completed_encounter_ids(state:Dictionary)->Array:
	var result:Array=[];var progress:Dictionary=state.get("zone0",{})
	for encounter_id in AshwoodData.all_encounter_ids():
		var encounter_progress:Dictionary=progress.get("encounters",{}).get(encounter_id,{})
		if bool(encounter_progress.get("first_clear_completed",false)):result.append(encounter_id)
	return result

static func discovered_enemy_names(state:Dictionary)->Dictionary:
	var discovered:Dictionary={}
	if bool(state.get("major_systems_unlocked",false)):
		for enemy_name in GameData.ENEMIES:discovered[enemy_name]=true
		return discovered
	for encounter_id in completed_encounter_ids(state):
		var encounter:Dictionary=AshwoodData.encounter(encounter_id,state.get("zone0",{}))
		for wave in encounter.get("waves",[]):
			for enemy_name in wave:discovered[str(enemy_name)]=true
		if encounter_id=="finale":
			for enemy_name in ["Controlled Rogue","Controlled Ranger","Controlled Mage","Controlled Warlock","Ashwood Servant"]:discovered[enemy_name]=true
	return discovered

static func enemy_source_lines(enemy_name:String,state:Dictionary)->Array:
	var sources:Array=[]
	for encounter_id in completed_encounter_ids(state):
		var encounter:Dictionary=AshwoodData.encounter(encounter_id,state.get("zone0",{}));var found:=false
		for wave in encounter.get("waves",[]):
			if enemy_name in wave:found=true;break
		if encounter_id=="finale" and enemy_name in ["Controlled Rogue","Controlled Ranger","Controlled Mage","Controlled Warlock","Ashwood Servant"]:found=true
		if found:sources.append(str(encounter.get("display_name",encounter_id)))
	return sources

static func enemy_entries(state:Dictionary)->Array:
	var result:Array=[];var discovered:=discovered_enemy_names(state)
	for enemy_name in GameData.ENEMIES:
		if enemy_name in ["Dummy","Defense Dummy"]:continue
		var enemy:Dictionary=GameData.ENEMIES[enemy_name];var sources:=enemy_source_lines(enemy_name,state);var known:=discovered.has(enemy_name)
		var tags:Array=enemy.get("combat_tags",[]);var details:="Health %d  •  Power %d  •  Armor %d\nDamage: %s\nTraits: %s\nKnown locations: %s\n\nLoot table: Possible rewards are recorded through discovered encounters; exact enemy-specific drop rates are not yet authored."%[int(enemy.get("base_health",0)),int(enemy.get("base_power",0)),int(enemy.get("base_armor",0)),str(enemy.get("basic_action_damage_type","physical")).capitalize(),", ".join(tags.map(func(value):return str(value).capitalize())) if not tags.is_empty() else "None recorded",", ".join(sources) if not sources.is_empty() else "No confirmed location"]
		result.append(entry("Enemies",str(enemy_name).to_snake_case(),str(enemy_name),"%s combatant"%str(enemy.get("basic_action_damage_type","physical")).capitalize(),details,known))
	return result

static func item_entries(state:Dictionary)->Array:
	var result:Array=[];var discovered:Dictionary={}
	for item in state.get("item_instances",[]):discovered[str(item.get("definition_id",""))]=true
	if bool(state.get("major_systems_unlocked",false)):
		for definition_id in ItemData.ITEMS:discovered[definition_id]=true
	for definition_id in ItemData.ITEMS:
		var item:Dictionary=ItemData.ITEMS[definition_id]
		if bool(item.get("testing_only",false)) and not bool(state.get("major_systems_unlocked",false)):continue
		var details:="%s %s  •  Tier %s\nSlot: %s\nKnown source: %s"%[str(item.get("rarity","Common")),str(item.get("display_name",definition_id)),ItemData.roman_tier(int(item.get("tier",1))),str(item.get("slot","item")).capitalize(),"Testing collection" if bool(item.get("testing_only",false)) else "World, merchant, or crafted discovery"]
		result.append(entry("Items & Loot",definition_id,str(item.get("display_name",definition_id)),"%s %s"%[str(item.get("rarity","Common")),str(item.get("slot","item")).capitalize()],details,discovered.has(definition_id)))
	for material_id in InventorySystem.MATERIAL_DEFINITIONS:
		var definition:Dictionary=InventorySystem.MATERIAL_DEFINITIONS[material_id];var known:bool=int(state.get(material_id,0))>0 or state.get("material_stacks",[]).any(func(stack):return str(stack.get("material_id",""))==material_id)
		result.append(entry("Items & Loot","material_%s"%material_id,str(definition.display_name),"Workshop material","Stored in the Workshop Depot when collected. Protect it in the Guild Vault to prevent Workshop consumption.",known or bool(state.get("major_systems_unlocked",false))))
	return result

static func location_entries(state:Dictionary)->Array:
	var result:Array=[];var progress:Dictionary=state.get("zone0",{});var encounters:Dictionary=progress.get("encounters",{})
	for encounter_id in AshwoodData.all_encounter_ids():
		var encounter:Dictionary=AshwoodData.encounter(encounter_id,progress);var saved:Dictionary=encounters.get(encounter_id,{});var known:bool=bool(saved.get("unlocked",false)) or bool(saved.get("first_clear_completed",false));var reward:Dictionary=encounter.get("first_rewards",{});var status:="Completed" if bool(saved.get("first_clear_completed",false)) else "Discovered"
		var details:="%s\n\nObjective: %s\nStatus: %s\nFirst-clear rewards: %d Gold, %d XP"%[str(encounter.get("scenario","No field report recorded.")),str(encounter.get("objective",{}).get("label","Unknown")),status,int(reward.get("gold",0)),int(reward.get("xp",0))]
		result.append(entry("Locations",encounter_id,str(encounter.get("display_name",encounter_id)),"Ashwood Marches  •  %s"%status,details,known))
	return result

static func journey_entries(state:Dictionary)->Array:
	var result:Array=[];var progress:Dictionary=state.get("zone0",{})
	for encounter_id in completed_encounter_ids(state):
		var encounter:Dictionary=AshwoodData.encounter(encounter_id,progress);var details:=str(encounter.get("story","The guild completed this chapter of its journey."));result.append(entry("Journey",encounter_id,str(encounter.get("display_name",encounter_id)),"Completed in the Ashwood Marches",details,true))
	return result

static func workshop_entries(state:Dictionary)->Array:
	var result:Array=[]
	for profession_id in ProfessionData.PROFESSIONS:
		var profession:Dictionary=ProfessionData.PROFESSIONS[profession_id];var category:="Tavern" if profession_id=="cooking" else "Workshop";result.append(entry(category,profession_id,str(profession.display_name),str(profession.description),"Station: %s\nStyles: %s\n\n%s"%[str(profession.station),", ".join(profession.styles),str(profession.description)],true))
	for recipe_id in ProfessionData.RECIPES:
		var recipe:Dictionary=ProfessionData.RECIPES[recipe_id];var known:bool=ProfessionSystem.recipe_is_learned(state,recipe_id) or bool(recipe.get("auto_known",false));var material_lines:Array=[]
		for material in recipe.get("materials",[]):material_lines.append("%d %s"%[int(material.get("quantity",0)),str(InventorySystem.MATERIAL_DEFINITIONS.get(str(material.get("material_id","")),{"display_name":str(material.get("material_id","material"))}).display_name)])
		var category:="Tavern" if str(recipe.get("profession",""))=="cooking" else "Workshop";var source_text:="Tavern Kitchen orders consume Provisions from the Depot." if category=="Tavern" else "Workshop orders consume these inputs only from the Workshop Depot.";result.append(entry(category,recipe_id,str(recipe.get("display_name",recipe_id)),"%s recipe"%str(recipe.get("profession","profession")).capitalize(),"Duration: %.0f seconds\nInputs: %s\n%s"%[float(recipe.get("duration",0)),", ".join(material_lines) if not material_lines.is_empty() else "Equipment or special inputs",source_text],known))
	return result

static func all_entries(state:Dictionary)->Array:
	var result:Array=[];result.append_array(guide_entries());result.append_array(enemy_entries(state));result.append_array(item_entries(state));result.append_array(location_entries(state));result.append_array(journey_entries(state));result.append_array(workshop_entries(state));return result
