extends RefCounted

const TeamManager = preload("res://scripts/systems/team_manager.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run() -> Array:
	var errors:=[]
	var team:=[0,1]
	TestSupport.check(errors,TeamManager.has_member(team,1),"Team membership lookup should find existing heroes.")
	TestSupport.check(errors,not TeamManager.has_member(team,3),"Team membership lookup should reject reserve heroes.")
	TestSupport.check(errors,TeamManager.reserve_indices(4,team)==[2,3],"Reserve indices should exclude active heroes.")
	TestSupport.check(errors,TeamManager.add_member(team,2)==[0,1,2],"Adding a hero should append to the active team.")
	TestSupport.check(errors,team==[0,1],"Team operations should not mutate their input arrays.")
	TestSupport.check(errors,TeamManager.remove_member([0,1,2],1)==[0,2],"Removing a hero should preserve the remaining order.")
	TestSupport.check(errors,TeamManager.place_member([0,1,2,3],0,3)==[1,2,3,0],"Moving the first hero to slot four should reorder the full party.")
	TestSupport.check(errors,TeamManager.place_member([0,1,2,3],3,0)==[3,0,1,2],"Moving the fourth hero to slot one should preserve the other heroes' relative order.")
	TestSupport.check(errors,TeamManager.place_member([0,1],2,1)==[0,2,1],"Dropping a reserve hero onto a party slot should insert them at that position.")
	TestSupport.check(errors,TeamManager.toggle_member([0,1],1)==[0],"Toggling an active hero should remove it.")
	TestSupport.check(errors,TeamManager.toggle_member([0,1,2,3],4)==[0,1,2,3],"The active team should remain capped at four heroes.")
	var saved:=[[],[],[],[],[]]
	var updated:=TeamManager.save_slot(saved,2,[0,3])
	TestSupport.check(errors,updated[2]==[0,3] and saved[2].is_empty(),"Saving a team should update a copied preset list.")
	TestSupport.check(errors,TeamManager.load_slot(updated,2)==[0,3],"Saved teams should load with their member order intact.")
	var heroes:=[{"name":"Brann"},{"name":"Sera"},{"name":"Wren"},{"name":"Nyx"}]
	TestSupport.check(errors,TeamManager.slot_names([0,3],heroes)=="Brann, Nyx","Saved-team summaries should use hero names.")
	var class_heroes:=[{"name":"Guardian A","class_id":"guardian"},{"name":"Guardian B","class_id":"guardian"},{"name":"Cleric","class_id":"cleric"},{"name":"Ranger","class_id":"ranger"}]
	TestSupport.check(errors,class_heroes.filter(func(hero):return hero.class_id=="guardian").size()==2,"The guild roster may contain multiple Heroes of one class.")
	TestSupport.check(errors,TeamManager.add_member([0],1,class_heroes)==[0] and not TeamManager.is_valid_party([0,1],class_heroes),"A party should reject a second Hero of the same class.")
	TestSupport.check(errors,TeamManager.sanitize_team([0,1,2],class_heroes)==[0,2],"Save migration should keep the first class representative and remove later duplicates.")
	TestSupport.check(errors,TeamManager.is_valid_party([0,2],class_heroes) and TeamManager.is_valid_party([1,3],class_heroes),"Separate raid parties may independently contain the same class.")
	return errors
