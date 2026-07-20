extends RefCounted

const MIN_PRESTIGE_RANK := 0
const MAX_PRESTIGE_RANK := 5

static func rank(hero:Dictionary)->int:
	return clampi(int(hero.get("prestige_rank",hero.get("legacy_rank",0))),MIN_PRESTIGE_RANK,MAX_PRESTIGE_RANK)

static func hero_meets_prestige_requirement(hero:Dictionary,required_rank:int)->bool:
	return rank(hero)>=clampi(required_rank,MIN_PRESTIGE_RANK,MAX_PRESTIGE_RANK)

static func team_meets_prestige_requirement(team:Array,heroes:Array,required_rank:int)->bool:
	if team.is_empty():return false
	for hero_index in team:
		if int(hero_index)<0 or int(hero_index)>=heroes.size() or not hero_meets_prestige_requirement(heroes[int(hero_index)],required_rank):return false
	return true

static func count_heroes_at_prestige(heroes:Array,required_rank:int)->int:
	var count:int=0
	for hero in heroes:if hero_meets_prestige_requirement(hero,required_rank):count+=1
	return count

static func highest_prestige_in_team(team:Array,heroes:Array)->int:
	var highest:int=0
	for hero_index in team:
		if int(hero_index)>=0 and int(hero_index)<heroes.size():highest=maxi(highest,rank(heroes[int(hero_index)]))
	return highest

static func stars(hero:Dictionary)->String:
	var hero_rank:int=rank(hero)
	return "★".repeat(hero_rank)+"☆".repeat(MAX_PRESTIGE_RANK-hero_rank)
