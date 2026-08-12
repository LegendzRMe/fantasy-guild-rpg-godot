extends RefCounted

const IMMEDIATE_CATEGORIES := ["standard","elite","named","boss","enemy_hero","summon","temporary_combat"]
const QUEST_CATEGORIES := ["standard","elite","named","boss","enemy_hero"]

static func category(unit:Dictionary) -> String:
	var tags:Array = unit.get("combat_tags",[])
	if bool(unit.get("object",false)) or "object" in tags:return "object"
	var authored:=str(unit.get("target_category",""))
	if authored in IMMEDIATE_CATEGORIES:return authored
	if "training" in tags:return "training"
	if "noncombat" in tags:return "noncombat"
	if bool(unit.get("summoned_unit",false)) or "summon" in tags:return "summon"
	if "temporary_combat" in tags:return "temporary_combat"
	if bool(unit.get("boss",false)) or "boss" in tags:return "boss"
	if "named" in tags:return "named"
	if "elite" in tags or "heavy" in tags:return "elite"
	if "enemy_hero" in tags:return "enemy_hero"
	return "standard"

static func qualifies_immediate(unit:Dictionary) -> bool:
	return category(unit) in IMMEDIATE_CATEGORIES

static func qualifies_quest(unit:Dictionary) -> bool:
	return category(unit) in QUEST_CATEGORIES
