extends RefCounted

const MAX_TEAM_SIZE := 4

static func hero_class_id(hero:Dictionary)->String:
	var class_id:=str(hero.get("class_id",""))
	return class_id if class_id!="" else str(hero.get("class","")).to_snake_case()

static func hero_index_for_id(heroes:Array,hero_id:String)->int:
	for index in heroes.size():
		if str(heroes[index].get("hero_id",""))==hero_id:return index
	return -1

static func runtime_team(team:Array,heroes:Array)->Array:
	var indices:Array=[]
	for member in team:
		var index:=hero_index_for_id(heroes,str(member)) if member is String else int(member)
		if index>=0:indices.append(index)
	return sanitize_team(indices,heroes)

static func persisted_team(team:Array,heroes:Array)->Array:
	var ids:Array=[]
	for member_index in sanitize_team(team,heroes):
		var hero_id:=str(heroes[int(member_index)].get("hero_id",""))
		if hero_id!="":ids.append(hero_id)
	return ids

static func runtime_saved_teams(saved_teams:Array,heroes:Array)->Array:
	var result:Array=[]
	for team in saved_teams:result.append(runtime_team(team,heroes) if team is Array else [])
	while result.size()<5:result.append([])
	return result.slice(0,5)

static func persisted_saved_teams(saved_teams:Array,heroes:Array)->Array:
	var result:Array=[]
	for team in saved_teams:result.append(persisted_team(team,heroes) if team is Array else [])
	while result.size()<5:result.append([])
	return result.slice(0,5)

static func can_add_member(team:Array,member_index:int,heroes:Array)->bool:
	if member_index<0 or member_index>=heroes.size() or has_member(team,member_index):return false
	var requested_class:=hero_class_id(heroes[member_index])
	for existing_index in team:
		if int(existing_index)>=0 and int(existing_index)<heroes.size() and hero_class_id(heroes[int(existing_index)])==requested_class:return false
	return team.size()<MAX_TEAM_SIZE

static func is_valid_party(team:Array,heroes:Array)->bool:
	return sanitize_team(team,heroes)==team and team.size()<=MAX_TEAM_SIZE

static func sanitize_team(team:Array,heroes:Array)->Array:
	var clean:Array=[];var seen_members:Dictionary={};var seen_classes:Dictionary={}
	for raw_member in team:
		var member_index:=int(raw_member)
		if member_index<0 or member_index>=heroes.size() or seen_members.has(member_index):continue
		var class_id:=hero_class_id(heroes[member_index])
		if class_id=="" or seen_classes.has(class_id):continue
		seen_members[member_index]=true;seen_classes[class_id]=true;clean.append(member_index)
		if clean.size()>=MAX_TEAM_SIZE:break
	return clean

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

static func toggle_member(team:Array, member_index:int,heroes:Array=[]) -> Array:
	if has_member(team,member_index):
		return remove_member(team,member_index)
	if team.size()<MAX_TEAM_SIZE and (heroes.is_empty() or can_add_member(team,member_index,heroes)):
		return add_member(team,member_index,heroes)
	return team.duplicate()

static func add_member(team:Array, member_index:int,heroes:Array=[]) -> Array:
	var next_team:=team.duplicate()
	if not has_member(next_team,member_index) and next_team.size()<MAX_TEAM_SIZE and (heroes.is_empty() or can_add_member(next_team,member_index,heroes)):
		next_team.append(member_index)
	return next_team

static func remove_member(team:Array, member_index:int) -> Array:
	var next_team:=[]
	for member in team:
		if member!=member_index:
			next_team.append(member)
	return next_team

static func place_member(team:Array, member_index:int, target_slot:int,heroes:Array=[]) -> Array:
	var already_present:=has_member(team,member_index)
	if not already_present and team.size()>=MAX_TEAM_SIZE:
		return team.duplicate()
	if not already_present and not heroes.is_empty() and not can_add_member(team,member_index,heroes):return team.duplicate()
	var next_team:=remove_member(team,member_index) if already_present else team.duplicate()
	var insertion_slot:=clampi(target_slot,0,next_team.size())
	next_team.insert(insertion_slot,member_index)
	return next_team

static func copy_team(team:Array) -> Array:
	return team.duplicate()

static func save_slot(saved_teams:Array, slot:int, team:Array,heroes:Array=[]) -> Array:
	var next_saved_teams:=saved_teams.duplicate()
	next_saved_teams[slot]=sanitize_team(team,heroes) if not heroes.is_empty() else copy_team(team)
	return next_saved_teams

static func load_slot(saved_teams:Array, slot:int,heroes:Array=[]) -> Array:
	var team:Array=saved_teams[slot]
	return (sanitize_team(team,heroes) if not heroes.is_empty() else copy_team(team)) if team.size()>0 else []

static func slot_names(team:Array, heroes:Array) -> String:
	if team.size()==0:
		return "Empty"
	var names:PackedStringArray=[]
	for member in team:
		names.append(heroes[member].name)
	return ", ".join(names)
