extends RefCounted
const RogueData=preload("res://scripts/data/rogue_data.gd")
const RogueSystem=preload("res://scripts/systems/rogue_system.gd")

static func amount(hero:Dictionary,value:float)->int:return floori(RogueSystem.scaled(hero,value))
static func details(hero:Dictionary,key:String,heroic_id:String="",stealth:bool=false)->Dictionary:
	if stealth:
		match key:
			"Q":return {"key":"Q","title":"Ambush","meta":"Opener • Armor reduction: %d for 5 seconds"%amount(hero,RogueData.VALUES.ambush_armor_reduction),"description":"Strike for %d Physical damage and generate a Combo Point."%amount(hero,RogueData.VALUES.ambush_damage),"sections":[{"heading":"VANISH OPENER","body":"After Vanish is prepared, range is doubled and the Rogue teleports to the target before striking."}],"note":"The Armor reduction is applied after Ambush damage and uses the strongest active source."}
			"W":return {"key":"W","title":"Cheap Shot","meta":"Opener • Stun: 0.75 seconds • Blind: 2 seconds","description":"Deal %d Physical damage, then Stun and Blind the target through its control profile."%amount(hero,RogueData.VALUES.cheap_damage),"sections":[],"note":"Blind begins when the resolved Stun ends."}
			"E":return {"key":"E","title":"Garrote","meta":"Opener • Silence: 2.5 seconds • Duration: 7 seconds","description":"Deal %d Physical damage, then %d Periodic Physical damage over 7 seconds."%[amount(hero,RogueData.VALUES.garrote_initial),amount(hero,RogueData.VALUES.garrote_periodic)],"sections":[],"note":"Garrote is owned by this Rogue and supports Hemorrhage, Strangle, and Rupture."}
	match key:
		"Q":return {"key":"Q","title":"Sinister Strike","meta":"Cooldown: 5 seconds","description":"Dash toward the first enemy hit, dealing %d Physical damage and generating a Combo Point."%amount(hero,RogueData.VALUES.q_damage),"sections":[{"heading":"ON HIT","body":"The full cooldown begins first, then a successful hit reduces the remaining cooldown by 1 second."}],"note":"Invalid casts do not move the Rogue or begin cooldown."}
		"W":return {"key":"W","title":"Blade Flurry","meta":"Cooldown: 4 seconds","description":"Deal %d Physical damage to enemies around the Rogue and generate one Combo Point if any valid enemy is hit."%amount(hero,RogueData.VALUES.w_damage),"sections":[],"note":"Baseline generation is once per cast, not once per target."}
		"E":return {"key":"E","title":"Eviscerate","meta":"Cooldown: 1 second • Requires Combo Points","description":"Consume up to 3 Combo Points to deal %d / %d / %d Physical damage."%[amount(hero,85),amount(hero,170),amount(hero,255)],"sections":[],"note":"Vigor may store 5 points, but this finisher still uses and consumes at most 3."}
		"R":
			if heroic_id=="rogue_l15_r1":return {"key":"R","title":"Smoke Bomb","meta":"Duration: 5 seconds","description":"Create smoke that makes the Rogue Invisible and Unrevealable while inside.","sections":[],"note":"Smoke does not grant Armor or activate the opener action set."}
			if heroic_id=="rogue_l15_r2":return {"key":"R","title":"Cloak of Shadows","meta":"Cooldown: 15 seconds • Duration: 1.5 seconds","description":"Remove harmful periodic damage, become Unstoppable, and gain %d general Armor."%amount(hero,RogueData.VALUES.cloak_armor),"sections":[],"note":"Cloak does not break Vanish."}
			return {"key":"R","title":"Heroic Ability","meta":"Unlocks at Level 15","description":"Choose Smoke Bomb or Cloak of Shadows in the Talent tree.","sections":[],"note":""}
		"D":return {"key":"D","title":"Vanish","meta":"Cooldown: 8 seconds","description":"Become Stealthed, reduce current threat by 25%, gain 20% Movement Speed, and replace Q, W, and E with opener abilities.","sections":[{"heading":"PREPARATION","body":"The first second is Unrevealable. Remaining stationary for 1.5 seconds grants Invisible. After 3 seconds, openers gain doubled range and teleport."}],"note":"Combo Points persist when entering or leaving Vanish."}
	return {"key":key,"title":"Rogue Ability","meta":"","description":"","sections":[],"note":""}
