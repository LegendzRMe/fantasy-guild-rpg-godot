extends RefCounted

const GameData = preload("res://scripts/data/game_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run() -> Array:
	var errors:=[]
	TestSupport.check(errors,GameData.CLASSES.keys()==["Guardian","Cleric","Rogue","Ranger","Mage","Warlock"],"Founding and Ashwood recruit classes should remain available in their established order.")
	TestSupport.check(errors,GameData.ABILITIES.size()==6 and GameData.ABILITY_TARGETING.size()==6,"Every current class should retain ability and targeting definitions.")
	var class_fields:=["class_id","display_name","primary_role","basic_action_id","trait_id","q_ability_id","w_ability_id","e_ability_id","heroic_option_ids","ai_behavior_tags","talent_tier_definitions","base_health","health_growth","base_power","power_growth","base_armor","basic_action_type","basic_action_power_coefficient","basic_action_interval","basic_action_range","movement_speed","base_critical_chance","critical_damage","health_regeneration","threat_modifier","basic_action_damage_type","armor_family","armor_proficiency","weapon_proficiencies"]
	TestSupport.check(errors,GameData.CLASSES.values().all(func(hero_class):return hero_class.has_all(class_fields)),"Every class should expose the shared combat-stat vocabulary.")
	var enemy_fields:=["base_health","health_growth","base_power","power_growth","base_armor","basic_action_type","basic_action_power_coefficient","basic_action_interval","basic_action_range","movement_speed","base_critical_chance","critical_damage","basic_action_damage_type","behavior_flags","combat_tags"]
	TestSupport.check(errors,GameData.ENEMIES.values().all(func(enemy):return enemy.has_all(enemy_fields)),"Every enemy should expose the shared runtime-stat vocabulary and behavior tags.")
	var defense_dummy:Dictionary=GameData.ENEMIES.get("Defense Dummy",{})
	var training_dummy:Dictionary=GameData.create_enemy("Dummy",Vector2.ZERO,0)
	var runtime_defense_dummy:Dictionary=GameData.create_enemy("Defense Dummy",Vector2.ZERO,0)
	TestSupport.check(errors,not bool(training_dummy.control_profile.get("displacement",true)) and not bool(runtime_defense_dummy.control_profile.get("displacement",true)),"Testing dummies should preserve their data-driven displacement immunity at runtime.")
	TestSupport.check(errors,not defense_dummy.is_empty() and float(defense_dummy.movement_speed)==0.0,"The defense testing dummy should remain stationary.")
	TestSupport.check(errors,float(defense_dummy.get("basic_action_range",0.0))>0.0 and float(defense_dummy.get("base_power",0.0))>0.0,"The defense testing dummy should attack at short range.")
	TestSupport.check(errors,GameData.ZONE_NAMES.size()==2 and GameData.ZONE_NODE_NAMES.size()==2,"Both current zones should remain defined.")
	TestSupport.check(errors,GameData.ZONE_NODE_POSITIONS.size()==12 and GameData.ZONE_BRANCHES.size()==2,"The current zone-map layout should remain intact.")
	TestSupport.check(errors,GameData.MISSIONS.size()==3 and GameData.MERCHANTS.size()==3 and GameData.PROFESSIONS.size()==15,"Current mission, merchant, and profession definitions should remain intact.")
	TestSupport.check(errors,GameData.GUILD_PAGE_INTROS.size()==7 and GameData.GUILD_PAGE_INTROS.values().all(func(intro):return str(intro.title)!="" and str(intro.body)!=""),"Every unlockable Guild Hall page should provide a broad first-visit explanation.")
	TestSupport.check(errors,GameData.STORAGE_BAG_SLOTS==6 and GameData.STORAGE_MAX_CAPACITY==180,"Current storage limits should remain intact.")
	return errors
