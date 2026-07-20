extends RefCounted

const PrestigeSystem = preload("res://scripts/systems/prestige_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run()->Array:
	var errors:=[]
	var heroes:=[{"prestige_rank":0},{"prestige_rank":2},{"prestige_rank":5},{"legacy_rank":3}]
	TestSupport.check(errors,PrestigeSystem.rank(heroes[2])==5 and PrestigeSystem.rank({"prestige_rank":99})==5,"Prestige rank should use the canonical field and clamp to five.")
	TestSupport.check(errors,PrestigeSystem.rank(heroes[3])==3,"Prestige helpers should retain a safe legacy-rank fallback for older data.")
	TestSupport.check(errors,PrestigeSystem.hero_meets_prestige_requirement(heroes[1],2) and not PrestigeSystem.hero_meets_prestige_requirement(heroes[0],1),"Hero Prestige requirements should compare through the shared helper.")
	TestSupport.check(errors,PrestigeSystem.team_meets_prestige_requirement([1,2],heroes,2) and not PrestigeSystem.team_meets_prestige_requirement([0,1],heroes,1),"Team Prestige requirements should require every assigned hero to qualify.")
	TestSupport.check(errors,PrestigeSystem.count_heroes_at_prestige(heroes,2)==3 and PrestigeSystem.highest_prestige_in_team([0,1,2],heroes)==5,"Prestige aggregation should support future unlock checks.")
	TestSupport.check(errors,PrestigeSystem.stars(heroes[1]).length()==5,"Prestige display should always expose a five-star scale.")
	return errors
