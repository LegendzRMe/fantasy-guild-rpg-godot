extends RefCounted
const VanguardData=preload("res://scripts/data/vanguard_data.gd")
static func amount(hero:Dictionary,value:float)->int:return floori(VanguardData.scaled(value,int(hero.get("level",1))))
static func details(hero:Dictionary,key:String,heroic_id:String="")->Dictionary:
	match key:
		"D":return {"key":"D","title":"Rockstar","meta":"Passive - No resource","description":"A committed Basic Ability grants %d Universal Armor for 2 seconds; a Heroic grants %d. Stronger active Rockstar Armor is never downgraded."%[amount(hero,25),amount(hero,50)]}
		"Q":return {"key":"Q","title":"Powerslide","meta":"12 sec cooldown","description":"Slide through enemies for %d damage and Stun them for 1.25 seconds."%amount(hero,105)}
		"W":return {"key":"W","title":"Face Melt","meta":"10 sec cooldown","description":"Deal %d damage to nearby enemies and safely knock them away."%amount(hero,68)}
		"E":return {"key":"E","title":"Overpower","meta":"12 sec recharge","description":"Grab one nearby enemy, safely flip it behind Vanguard, deal %d damage, and Stun for 0.25 seconds."%amount(hero,80)}
		"R":
			if heroic_id=="vanguard_l15_r2":return {"key":"R","title":"Lightning Breath","meta":"90 sec cooldown - 0.5 sec windup","description":"Become Unstoppable and channel for 4 seconds, dealing %d every 0.25 seconds in a rotatable frontal cone and stacking a source-owned Slow."%amount(hero,50)}
			return {"key":"R","title":"Mosh Pit","meta":"120 sec cooldown - 0.75 sec windup","description":"Channel for 4 seconds and continuously maintain Stun on susceptible nearby enemies. The baseline channel is interruptible."}
	return {}
