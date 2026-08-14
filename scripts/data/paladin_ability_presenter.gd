extends RefCounted
const PaladinData=preload("res://scripts/data/paladin_data.gd")
const PaladinSystem=preload("res://scripts/systems/paladin_system.gd")
static func amount(hero:Dictionary,value:float)->int:return floori(PaladinData.scaled(value,int(hero.get("level",1))))
static func details(hero:Dictionary,key:String,heroic_id:String="")->Dictionary:
	match key:
		"D":return {"key":"D","title":"Divine Purpose","meta":"12 sec cooldown","description":"The next Q, W, or E commits immediately at maximum charge. Disabling interruption reduces this cooldown by 3 seconds."}
		"Q":return {"key":"Q","title":"Vindication","meta":"6 sec cooldown - 1.5 sec charge - No Mana","description":"Damage nearby enemies for %d-%d and heal Paladin for %d-%d. Partial releases use minimum values; maximum charge uses maximum values."%[amount(hero,42),amount(hero,160),amount(hero,96),amount(hero,370)]}
		"W":return {"key":"W","title":"Righteous Hammer","meta":"6 sec cooldown - 1.5 sec charge","description":"Strike a frontal arc for %d-%d, knocking enemies back. Maximum charge Stuns for 1 second."%[amount(hero,38),amount(hero,140)]}
		"E":return {"key":"E","title":"Avenging Wrath","meta":"6 sec cooldown - 1.5 sec charge","description":"Leap 2-7 source units based on charge, deal %d near landing, and Slow enemies by 60%%."%amount(hero,260)}
		"R":
			if heroic_id=="paladin_l15_r2":return {"key":"R","title":"Sacred Ground","meta":"60 sec cooldown","description":"Create a 7-second circular movement wall that damages enemies inside each second. Projectiles cross it."}
			return {"key":"R","title":"Ardent Defender","meta":"120 sec cooldown","description":"For 3 seconds, prevent incoming damage and heal for 50% of each prevented packet."}
	return {}
