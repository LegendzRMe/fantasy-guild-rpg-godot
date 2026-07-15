extends RefCounted

const MAX_TEAM_SIZE := 4

static func has_member(team:Array, member_index:int) -> bool:
	for member in team:
		if member==member_index:
			return true
	return false

static func member_index(team:Array, member_index:int) -> int:
	for index in team.size():
		if team[index]==member_index:
			return index
	return -1

static func reserve_indices(hero_count:int, team:Array) -> Array:
	var reserve:=[]
	for index in hero_count:
		if not has_member(team,index):
			reserve.append(index)
	return reserve

static func toggle_member(team:Array, member_index:int) -> Array:
	if has_member(team,member_index):
		return remove_member(team,member_index)
	if team.size()<MAX_TEAM_SIZE:
		return add_member(team,member_index)
	return team.duplicate()

static func add_member(team:Array, member_index:int) -> Array:
	var next_team:=team.duplicate()
	if not has_member(next_team,member_index) and next_team.size()<MAX_TEAM_SIZE:
		next_team.append(member_index)
	return next_team

static func remove_member(team:Array, member_index:int) -> Array:
	var next_team:=[]
	for member in team:
		if member!=member_index:
			next_team.append(member)
	return next_team

static func copy_team(team:Array) -> Array:
	return team.duplicate()

static func save_slot(saved_teams:Array, slot:int, team:Array) -> Array:
	var next_saved_teams:=saved_teams.duplicate()
	next_saved_teams[slot]=copy_team(team)
	return next_saved_teams

static func load_slot(saved_teams:Array, slot:int) -> Array:
	var team:Array=saved_teams[slot]
	return copy_team(team) if team.size()>0 else []

static func slot_names(team:Array, heroes:Array) -> String:
	if team.size()==0:
		return "Empty"
	var names:PackedStringArray=[]
	for member in team:
		names.append(heroes[member].name)
	return ", ".join(names)
