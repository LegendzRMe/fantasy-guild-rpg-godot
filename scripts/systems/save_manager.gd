extends RefCounted

const AshwoodManager = preload("res://scripts/systems/ashwood_manager.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const TeamManager = preload("res://scripts/systems/team_manager.gd")
const ProfessionSystem = preload("res://scripts/systems/profession_system.gd")
const GuildHallData = preload("res://scripts/data/guild_hall_data.gd")
const GuildMemberData = preload("res://scripts/data/guild_member_data.gd")
const RecruitmentData = preload("res://scripts/data/recruitment_data.gd")
const RecruitmentSystem = preload("res://scripts/systems/recruitment_system.gd")
const GameClockSystem = preload("res://scripts/systems/game_clock_system.gd")
const TavernFacilityData = preload("res://scripts/data/tavern_facility_data.gd")
const TavernFacilitySystem = preload("res://scripts/systems/tavern_facility_system.gd")
const CookingData = preload("res://scripts/data/cooking_data.gd")
const CookingSystem = preload("res://scripts/systems/cooking_system.gd")
const TavernManagementData = preload("res://scripts/data/tavern_management_data.gd")
const TavernManagementSystem = preload("res://scripts/systems/tavern_management_system.gd")
const CampaignSystem = preload("res://scripts/systems/campaign_system.gd")
const SaveSchema = preload("res://scripts/systems/save_schema.gd")
const LEGACY_SAVE_PATH := "user://guild_save.json"
const SAVE_SCHEMA_VERSION := 6

static func component_versions() -> Dictionary:
	return {
		"professions":ProfessionSystem.SAVE_VERSION,
		"recruitment":RecruitmentSystem.SAVE_VERSION,
		"tavern_facility":TavernFacilitySystem.SAVE_VERSION,
		"cooking":CookingSystem.SAVE_VERSION,
		"tavern_management":TavernManagementSystem.SAVE_VERSION,
		"campaign":CampaignSystem.SAVE_VERSION,
		"storage":InventorySystem.ITEM_STORAGE_LOCATION_VERSION
	}

static func save_slot_path(slot:int) -> String:
	return "user://guild_save_%d.json" % (slot+1)

static func save_backup_path(slot:int) -> String:
	return save_slot_path(slot)+".bak"

static func save_temporary_path(slot:int) -> String:
	return save_slot_path(slot)+".tmp"

static func _read_dictionary(path:String)->Dictionary:
	if not FileAccess.file_exists(path):return {}
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:return {}
	return parser.data if parser.data is Dictionary else {}

static func resolved_load_path(slot:int) -> String:
	var path:=save_slot_path(slot)
	if _read_dictionary(path).is_empty() and not _read_dictionary(save_backup_path(slot)).is_empty():
		return save_backup_path(slot)
	if slot==0 and not FileAccess.file_exists(path) and FileAccess.file_exists(LEGACY_SAVE_PATH):
		return LEGACY_SAVE_PATH
	return path

static func slot_state(slot:int) -> Dictionary:
	var path:=resolved_load_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	return _read_dictionary(path)

static func default_casting_settings() -> Dictionary:
	return {"pc":{"ground":"cursor","directional":"cursor","area":"instant","enemy":"target","ally":"target"},"mobile":{"ground":"facing","directional":"facing","area":"instant","enemy":"target","ally":"target"}}

static func hero_state(hero_name:String,hero_class:String,level:int,gear:int,member_type:String="guild_recruit",special:bool=false,legacy_rank:int=0,extras:Dictionary={})->Dictionary:
	return GuildMemberData.create(hero_name,hero_class,level,gear,member_type,special,legacy_rank,extras)

static func _fresh_state_base() -> Dictionary:
	return {"save_version":SAVE_SCHEMA_VERSION,"component_versions":component_versions(),"guild_name":"", "faction":"Unaffiliated", "guild_prestige_rank":1, "guild_renown":0, "prestige_tokens":0, "class_talent_discovery":{}, "tutorial_complete":false,"major_systems_unlocked":false,"seen_page_intros":{},"codex_seen_entries":{}, "zone0":AshwoodManager.default_progress(), "casting_settings":default_casting_settings(), "game_clock":GameClockSystem.default_state(), "recruitment":RecruitmentData.default_state(), "tavern_facility":TavernFacilityData.default_state(), "cooking":CookingData.default_state(), "tavern_management":TavernManagementData.default_state(), "guild_hall_room_unlocks":GuildHallData.default_room_unlocks(), "guild_hall_new_rooms":[], "guild_hall_scroll_position":GuildHallData.DEFAULT_SCROLL_POSITION, "guild_hall_tutorial_step":0, "guild_hall_tutorial_complete":false, "guild_hall_scroll_hint_dismissed":false, "item_instances":[], "material_stacks":[], "next_item_instance_id":1, "next_material_stack_id":1, "guild_recipes":{}, "discovered_rune_patterns":[], "rune_collection":{}, "profession_orders":[], "next_profession_order_id":1, "profession_completion_alerts":[], "profession_debug":{}, "gold":0, "ore":8, "herbs":8, "dust":4, "tonics":0, "provisions":0, "vault_level":1, "vault_limit":30, "depot_level":1, "depot_limit":30, "dungeon_clears":[0,0], "zone_progress":[0,0], "zone_branches":[[false,false],[false,false]], "unlocked_dungeon":0, "selected_team":[0,1], "active_team":[0,1], "saved_teams":[[],[],[],[],[]], "team_names":["Team 1","Team 2","Team 3","Team 4","Team 5"], "heroes":[
		hero_state("Brann","Guardian",1,10,"founding_recruit"),
		hero_state("Sera","Cleric",1,10,"founding_recruit")
	]}

static func fresh_state() -> Dictionary:
	var state:=_fresh_state_base()
	state["campaign"]=CampaignSystem.default_state()
	return state

static func testing_heroes() -> Array:
	return [
		hero_state("Brann","Guardian",4,16,"founding_recruit"),
		hero_state("Sera","Cleric",4,16,"founding_recruit"),
		hero_state("Wren","Ranger",4,16),
		hero_state("Nyx","Mage",4,16),
		hero_state("Kestrel","Rogue",4,16),
		hero_state("Morrow","Warlock",4,16),
		hero_state("Kaelith","Slayer",30,16),
		hero_state("Elowen","Priest",30,16),
		hero_state("Torren","Shaman",30,16,"guild_recruit",false,0,{"talent_mastery":{}}),
		hero_state("Rehgar Stone","Shaman",30,16,"guild_recruit",false,0,{"talent_mastery":{"shaman_l9_1":200,"shaman_l9_2":100,"shaman_l9_3":100}}),
		hero_state("Aurex","Templar",30,16,"guild_recruit",false,0),
		hero_state("Seraphine","Protector",30,16,"guild_recruit",false,0),
		hero_state("Lunara","Sentinel",30,16,"guild_recruit",false,0),
		hero_state("Garran Grey","Huntsman",30,16,"guild_recruit",false,0),
		hero_state("Malfira Greenbough","Druid",30,16,"guild_recruit",false,0),
		hero_state("Garrick Ironward","Warrior",30,16,"guild_recruit",false,0),
		hero_state("Morvane Frost","Death Knight",30,16,"guild_recruit",false,0,{"talent_mastery":{}}),
		hero_state("Tharos Mastered","Death Knight",30,16,"guild_recruit",false,0,{"talent_mastery":{"death_knight_l9_1":50}}),
		hero_state("Rokan Wildspear","Beastmaster",30,16,"guild_recruit",false,0),
		hero_state("Kharazim","Monk",30,17,"guild_recruit",false,0),
		hero_state("Yrel","Paladin",30,18,"guild_recruit",false,0),
		hero_state("Johanna","Crusader",30,18,"guild_recruit",false,0),
		hero_state("Ettin Chieftain","Vanguard",30,19,"guild_recruit",false,0),
		hero_state("Elira Lifebloom","Vitalist",30,20,"guild_recruit",false,0),
		hero_state("Kael Runebraid","Spirit Weaver",30,20,"guild_recruit",false,0),
		hero_state("Aldren Vale","Guardian",4,18,"special_hero",true,1,{"signature_ability":"Oath of Cinders","story_lead":"The traitor's broken oath-seal"}),
		hero_state("Mira Thorn","Ranger",4,18,"special_hero",true,1,{"signature_ability":"Ghostmark Volley","story_lead":"Unnatural tracks leaving Ashwood"}),
		hero_state("Ilyra Voss","Mage",4,18,"special_hero",true,1,{"signature_ability":"Runebreak","story_lead":"The force inside the servant's runes"})
	]

static func ensure_testing_roster(state:Dictionary) -> void:
	var existing_ids:Dictionary={}
	var existing_names:Dictionary={}
	for saved_hero in state.heroes:
		existing_ids[str(saved_hero.get("hero_id",""))]=true
		existing_names[str(saved_hero.get("display_name",saved_hero.get("name","")))]=true
	for required_hero in testing_heroes():
		if existing_ids.has(str(required_hero.hero_id)) or existing_names.has(str(required_hero.display_name)):continue
		state.heroes.append(required_hero)
		existing_ids[str(required_hero.hero_id)]=true
		existing_names[str(required_hero.display_name)]=true

static func testing_state() -> Dictionary:
	var state:=fresh_state()
	state.merge({
		"guild_name":"Testing Guild",
		"guild_prestige_rank":10,
		"guild_renown":1000,
		"tutorial_complete":true,
		"major_systems_unlocked":true,
		"zone0":AshwoodManager.testing_progress(),
		"gold":9999,
		"ore":999,
		"herbs":999,
		"dust":999,
		"provisions":999,
		"prestige_tokens":999,
		"class_talent_discovery":{"guardian":30,"cleric":30,"rogue":30,"ranger":30,"mage":30,"warlock":30,"slayer":30,"priest":30,"shaman":30,"templar":30,"protector":30,"sentinel":30,"huntsman":30,"druid":30,"warrior":30,"death_knight":30,"beastmaster":30,"monk":30},
		"vault_level":10,
		"vault_limit":300,
		"depot_level":10,
		"depot_limit":300,
		"dungeon_clears":[3,3],
		"zone_progress":[10,10],
		"zone_branches":[[true,true],[true,true]],
		"unlocked_dungeon":1,
		"selected_team":[0,1,2,3],
		"active_team":[0,1,2,3],
		"saved_teams":[[0,1,2,3],[],[],[],[]],
		"heroes":testing_heroes()
	},true)
	state.item_instances=ItemData.testing_instances()
	state=migrate_state(state,true,true)
	CampaignSystem.unlock_all_regions(state);state.campaign.council_unlocked=true;state.campaign.combat_hall_unlocked=true;state.guild_hall_room_unlocks["council_chamber"]=false;state.guild_hall_room_unlocks["combat_hall"]=true
	return state

static func load_state(slot:int) -> Dictionary:
	var state:=fresh_state()
	var save_declared_tutorial:=false
	var save_declared_major_systems:=false
	var path:=resolved_load_path(slot)
	if FileAccess.file_exists(path):
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			save_declared_tutorial=parsed.has("tutorial_complete")
			save_declared_major_systems=parsed.has("major_systems_unlocked")
			state.merge(parsed,true)
			if not save_declared_major_systems:
				state.erase("major_systems_unlocked")
	return migrate_state(state,save_declared_tutorial,slot==3)

static func migrate_state(state:Dictionary, save_declared_tutorial:bool, testing_save:bool=false) -> Dictionary:
	var defaults:=fresh_state()
	state["save_version"]=SAVE_SCHEMA_VERSION
	SaveSchema.repair_root(state,defaults)
	# JSON arrays can still parse while containing invalid entries. Discard only
	# unusable records before migration code calls Dictionary methods on them.
	state["heroes"]=state.heroes.filter(func(entry):return entry is Dictionary)
	state["item_instances"]=state.item_instances.filter(func(entry):return entry is Dictionary)
	state["material_stacks"]=state.material_stacks.filter(func(entry):return entry is Dictionary)
	# The early prototype's generic dungeon token had no defined economy. It is
	# intentionally discarded instead of being converted into either real currency.
	state.erase("tokens")
	if not state.has("prestige_tokens"):state["prestige_tokens"]=0
	if state.guild_name!="" and not save_declared_tutorial:
		state["tutorial_complete"]=true
	if not state.has("active_team"):
		state["active_team"]=state.selected_team.duplicate()
	if not state.has("saved_teams"):
		state["saved_teams"]=[[],[],[],[],[]]
	if not state.has("team_names"):
		state["team_names"]=["Team 1","Team 2","Team 3","Team 4","Team 5"]
	if not state.has("zone_progress"):
		state["zone_progress"]=[0,0]
	if not state.has("zone_branches"):
		state["zone_branches"]=[[false,false],[false,false]]
	if not state.has("guild_prestige_rank"):
		state["guild_prestige_rank"]=1
	if not state.has("guild_renown"):
		state["guild_renown"]=0
	if not state.has("faction"):
		state["faction"]="Unaffiliated"
	if not state.has("major_systems_unlocked"):
		state["major_systems_unlocked"]=state.heroes.size()>=4
	if not state.has("seen_page_intros") or not state.seen_page_intros is Dictionary:
		state["seen_page_intros"]={}
	if not state.has("zone0"):
		state["zone0"]=AshwoodManager.testing_progress() if state.heroes.size()>=4 else AshwoodManager.default_progress()
	else:
		state["zone0"]=AshwoodManager.migrate_progress(state.zone0)
	if bool(state.get("tutorial_complete",false)):
		state.zone0.heroes_unlocked=true
	if not state.has("casting_settings"):
		state["casting_settings"]=default_casting_settings()
	else:
		var casting_defaults:=default_casting_settings()
		for device in casting_defaults:
			if not state.casting_settings.has(device) or not state.casting_settings[device] is Dictionary:
				state.casting_settings[device]=casting_defaults[device].duplicate(true)
			else:
				for category in casting_defaults[device]:
					if not state.casting_settings[device].has(category):
						state.casting_settings[device][category]=casting_defaults[device][category]
	if not state.has("item_instances") or not state.item_instances is Array:state["item_instances"]=[]
	if testing_save or str(state.get("guild_name",""))=="Testing Guild":
		ensure_testing_roster(state)
		state["item_instances"]=state.item_instances.filter(func(item):return str(item.get("instance_id","")) not in ItemData.LEGACY_TEST_INSTANCE_IDS)
		for saved_hero in state.heroes:
			if not saved_hero.has("equipment_slots") or not saved_hero.equipment_slots is Dictionary:continue
			for saved_slot in ItemData.EQUIPMENT_SLOTS:
				if str(saved_hero.equipment_slots.get(saved_slot,"")) in ItemData.LEGACY_TEST_INSTANCE_IDS:saved_hero.equipment_slots[saved_slot]=null
		state["item_instances"]=ItemData.seed_testing_instances(state.item_instances)
	var used_hero_ids:Dictionary={}
	for hero_index in state.heroes.size():
		var hero:Dictionary=state.heroes[hero_index]
		hero["level"]=CombatSystem.clamp_level(int(hero.get("level",1)))
		hero["xp"]=clampi(int(hero.get("xp",0)),0,int(hero.level)*100-1)
		hero["experience"]=int(hero.xp)
		var hero_class:=str(hero.get("class",GameData.class_display_name(str(hero.get("class_id","")))))
		if not GameData.CLASSES.has(hero_class):hero_class=GameData.class_display_name(str(hero.get("class_id","")))
		hero["class"]=hero_class;hero["class_id"]=GameData.class_id_for(hero_class)
		var base_hero_id:=str(hero.get("hero_id",str(hero.get("name","hero")).to_snake_case()))
		if base_hero_id=="":base_hero_id="hero_%d"%(hero_index+1)
		var unique_hero_id:=base_hero_id;var suffix:=2
		while used_hero_ids.has(unique_hero_id):unique_hero_id="%s_%d"%[base_hero_id,suffix];suffix+=1
		hero["hero_id"]=unique_hero_id;used_hero_ids[unique_hero_id]=true
		if not hero.has("member_type"):
			hero["member_type"]="founding_recruit"
		if not hero.has("is_special_hero"):
			hero["is_special_hero"]=false
		var special:=bool(hero.is_special_hero)
		hero["identity_type"]="special" if special else "standard"
		hero["named_hero_definition_id"]=str(hero.get("named_hero_definition_id",hero.get("special_identifier",""))) if special else ""
		hero["display_name"]=str(hero.get("display_name",hero.get("name","Hero")))
		hero["name"]=str(hero.display_name)
		hero["editable_name"]=not special;hero["editable_appearance"]=not special;hero["can_edit_name"]=not special;hero["can_edit_appearance"]=not special
		if not hero.get("appearance_data") is Dictionary:hero["appearance_data"]={}
		if not hero.has("playable_race_id"):hero["playable_race_id"]=""
		if not hero.get("selected_talents") is Dictionary:hero["selected_talents"]={}
		if not hero.get("planned_talents") is Dictionary:hero["planned_talents"]={}
		if not hero.get("talent_mastery") is Dictionary:hero["talent_mastery"]={}
		if not hero.has("selected_heroic_id"):hero["selected_heroic_id"]=""
		if not hero.has("legacy_rank"):
			hero["legacy_rank"]=0
		if not hero.has("prestige_rank"):hero["prestige_rank"]=clampi(int(hero.get("legacy_rank",0)),0,5)
		hero["prestige_rank"]=clampi(int(hero.prestige_rank),0,5)
		if not hero.has("prestige_reward_floor_rank"):hero["prestige_reward_floor_rank"]=int(hero.prestige_rank) if special else 0
		if not hero.has("completed_prestige_cycles"):hero["completed_prestige_cycles"]=0
		if not hero.has("active_prestige_challenge_id"):hero["active_prestige_challenge_id"]=str(hero.get("active_prestige_challenge",""))
		if not hero.get("completed_prestige_challenge_ids") is Array:hero["completed_prestige_challenge_ids"]=hero.get("completed_prestige_challenges",[]).duplicate()
		if not hero.get("prestige_specialization_ids") is Array:hero["prestige_specialization_ids"]=[]
		if not hero.get("prestige_reward_history") is Array:hero["prestige_reward_history"]=[]
		if not hero.has("prestige_five_legacy_id"):hero["prestige_five_legacy_id"]=""
		if not hero.has("is_guild_champion"):hero["is_guild_champion"]=false
		if not hero.get("profession_progress") is Dictionary:hero["profession_progress"]={}
		if not hero.get("pvp_progress") is Dictionary:hero["pvp_progress"]={}
		if not hero.has("guild_position_id"):hero["guild_position_id"]=""
		if not hero.has("active_prestige_challenge"):hero["active_prestige_challenge"]=""
		if not hero.has("completed_prestige_challenges") or not hero.completed_prestige_challenges is Array:hero["completed_prestige_challenges"]=[]
		if not hero.has("legacy_perk_ids") or not hero.legacy_perk_ids is Array:hero["legacy_perk_ids"]=[]
		if not hero.has("prestige_unlock_tags") or not hero.prestige_unlock_tags is Array:hero["prestige_unlock_tags"]=[]
		if not hero.has("equipment"):
			hero["equipment"]=[]
		if not hero.has("equipment_slots") or not hero.equipment_slots is Dictionary:
			hero["equipment_slots"]=ItemData.empty_equipment_slots()
		else:
			for slot in ItemData.EQUIPMENT_SLOTS:
				if not hero.equipment_slots.has(slot):hero.equipment_slots[slot]=null
		state.class_talent_discovery=TalentSystem.record_class_discovery(state.class_talent_discovery,str(hero.class_id),int(hero.level))
	if testing_save or str(state.get("guild_name",""))=="Testing Guild":
		for class_definition in GameData.CLASSES.values():state.class_talent_discovery[str(class_definition.class_id)]=30
	state["selected_team"]=TeamManager.runtime_team(state.selected_team,state.heroes)
	state["active_team"]=TeamManager.runtime_team(state.active_team,state.heroes)
	state["saved_teams"]=TeamManager.runtime_saved_teams(state.saved_teams,state.heroes)
	# Ashwood's original prototype inventory stored disconnected text records.
	# Convert those exact owned instances once, preserving their equipped hero.
	var existing_ids:Dictionary={}
	for existing_item in state.item_instances:existing_ids[str(existing_item.get("instance_id",""))]=true
	for legacy_item in state.zone0.get("inventory",[]):
		if not legacy_item is Dictionary:continue
		var converted:=ItemData.legacy_ashwood_instance(legacy_item)
		var converted_id:=str(converted.get("instance_id",""))
		if not existing_ids.has(converted_id):
			state.item_instances.append(converted);existing_ids[converted_id]=true
		var owner_index:=int(legacy_item.get("equipped_by",-1))
		if owner_index>=0 and owner_index<state.heroes.size():
			var converted_slot:=str(converted.get("slot",""))
			if converted_slot in ItemData.EQUIPMENT_SLOTS:state.heroes[owner_index].equipment_slots[converted_slot]=converted_id
	state.zone0["inventory"]=[]
	ItemData.reconcile_ownership(state)
	InventorySystem.ensure_storage_state(state)
	ProfessionSystem.ensure_state(state)
	GuildHallData.ensure_state(state)
	GameClockSystem.ensure_state(state)
	TavernFacilitySystem.ensure_state(state)
	RecruitmentSystem.ensure_state(state)
	CookingSystem.ensure_state(state)
	TavernManagementSystem.ensure_state(state)
	CampaignSystem.ensure_state(state)
	state.component_versions.merge(component_versions(),true)
	return state

static func save_state(slot:int, state:Dictionary) -> bool:
	state["save_version"]=SAVE_SCHEMA_VERSION
	if not state.get("component_versions") is Dictionary:state["component_versions"]={}
	InventorySystem.ensure_storage_state(state)
	ProfessionSystem.ensure_state(state)
	GuildHallData.ensure_state(state)
	GameClockSystem.ensure_state(state)
	TavernFacilitySystem.ensure_state(state)
	RecruitmentSystem.ensure_state(state)
	CookingSystem.ensure_state(state)
	TavernManagementSystem.ensure_state(state)
	CampaignSystem.ensure_state(state)
	state.component_versions.merge(component_versions(),true)
	var schema_errors:=SaveSchema.validation_errors(state)
	if not schema_errors.is_empty():
		push_error("Guild save schema validation failed: %s"%" ".join(schema_errors))
		return false
	var live_path:=save_slot_path(slot)
	var temporary_path:=save_temporary_path(slot)
	var backup_path:=save_backup_path(slot)
	var persisted_state:=state.duplicate(true)
	persisted_state.selected_team=TeamManager.persisted_team(state.selected_team,state.heroes)
	persisted_state.active_team=TeamManager.persisted_team(state.active_team,state.heroes)
	persisted_state.saved_teams=TeamManager.persisted_saved_teams(state.saved_teams,state.heroes)
	var serialized:=JSON.stringify(persisted_state)
	var file:=FileAccess.open(temporary_path,FileAccess.WRITE)
	if file==null:
		push_error("Unable to open temporary guild save for writing: %s"%temporary_path)
		return false
	file.store_string(serialized)
	file.flush()
	file.close()
	if _read_dictionary(temporary_path).is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
		push_error("Guild save verification failed; the existing save was preserved.")
		return false
	var live_absolute:=ProjectSettings.globalize_path(live_path)
	var temporary_absolute:=ProjectSettings.globalize_path(temporary_path)
	var backup_absolute:=ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):DirAccess.remove_absolute(backup_absolute)
	if FileAccess.file_exists(live_path):
		var backup_error:=DirAccess.rename_absolute(live_absolute,backup_absolute)
		if backup_error!=OK:
			DirAccess.remove_absolute(temporary_absolute)
			push_error("Unable to preserve the previous guild save; save was cancelled.")
			return false
	var replace_error:=DirAccess.rename_absolute(temporary_absolute,live_absolute)
	if replace_error!=OK:
		if FileAccess.file_exists(backup_path):DirAccess.rename_absolute(backup_absolute,live_absolute)
		push_error("Unable to install the verified guild save; the previous save was restored.")
		return false
	return true

static func delete_slot(slot:int) -> void:
	var slot_path:=save_slot_path(slot)
	if FileAccess.file_exists(slot_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path))
	for recovery_path in [save_backup_path(slot),save_temporary_path(slot)]:
		if FileAccess.file_exists(recovery_path):DirAccess.remove_absolute(ProjectSettings.globalize_path(recovery_path))
	if slot==0 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH))
