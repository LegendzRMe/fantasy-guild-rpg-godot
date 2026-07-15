extends RefCounted

const GameData = preload("res://scripts/data/game_data.gd")
const RosterManager = preload("res://scripts/systems/roster_manager.gd")
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run() -> Array:
	var errors:=[]
	var heroes:Array=SaveManager.testing_state().heroes.slice(0,4)
	heroes[3].is_special_hero=true
	TestSupport.check(errors,RosterManager.hero_matches(heroes[0],GameData.CLASSES,"brann","All roles","All classes","All Heroes"),"Roster search should remain case-insensitive.")
	TestSupport.check(errors,RosterManager.hero_matches(heroes[1],GameData.CLASSES,"","Healer","All classes","Standard Heroes"),"Roster role and type filters should compose.")
	TestSupport.check(errors,not RosterManager.hero_matches(heroes[3],GameData.CLASSES,"","All roles","Mage","Standard Heroes"),"Standard-hero filtering should exclude special heroes.")
	TestSupport.check(errors,RosterManager.hero_matches(heroes[3],GameData.CLASSES,"","All roles","Mage","Special Heroes"),"Special-hero filtering should include matching heroes.")
	var ascending:=RosterManager.sorted_indices(heroes,GameData.CLASSES,"","All roles","All classes","All Heroes","Name",false)
	var descending:=RosterManager.sorted_indices(heroes,GameData.CLASSES,"","All roles","All classes","All Heroes","Name",true)
	TestSupport.check(errors,ascending==[0,3,1,2],"Roster name sorting should preserve current ascending behavior.")
	TestSupport.check(errors,descending==[2,1,3,0],"Roster name sorting should preserve current descending behavior.")
	var healers:=RosterManager.sorted_indices(heroes,GameData.CLASSES,"","Healer","All classes","All Heroes","Name",false)
	TestSupport.check(errors,healers==[1],"Roster sorting should only return heroes that pass the active filters.")
	return errors
