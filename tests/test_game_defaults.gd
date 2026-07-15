extends RefCounted

const GameData = preload("res://scripts/data/game_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run() -> Array:
	var errors:=[]
	TestSupport.check(errors,GameData.CLASSES.keys()==["Guardian","Cleric","Rogue","Ranger","Mage","Warlock"],"Founding and Ashwood recruit classes should remain available in their established order.")
	TestSupport.check(errors,GameData.ABILITIES.size()==6 and GameData.ABILITY_TARGETING.size()==6,"Every current class should retain ability and targeting definitions.")
	TestSupport.check(errors,GameData.ZONE_NAMES.size()==2 and GameData.ZONE_NODE_NAMES.size()==2,"Both current zones should remain defined.")
	TestSupport.check(errors,GameData.ZONE_NODE_POSITIONS.size()==12 and GameData.ZONE_BRANCHES.size()==2,"The current zone-map layout should remain intact.")
	TestSupport.check(errors,GameData.MISSIONS.size()==3 and GameData.MERCHANTS.size()==3 and GameData.PROFESSIONS.size()==15,"Current mission, merchant, and profession definitions should remain intact.")
	TestSupport.check(errors,GameData.GUILD_PAGE_INTROS.size()==7 and GameData.GUILD_PAGE_INTROS.values().all(func(intro):return str(intro.title)!="" and str(intro.body)!=""),"Every unlockable Guild Hall page should provide a broad first-visit explanation.")
	TestSupport.check(errors,GameData.STORAGE_BAG_SLOTS==6 and GameData.STORAGE_MAX_CAPACITY==180,"Current storage limits should remain intact.")
	return errors
