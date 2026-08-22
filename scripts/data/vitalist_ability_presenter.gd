extends RefCounted
const VitalistData=preload("res://scripts/data/vitalist_data.gd")
static func amount(hero:Dictionary,value:float)->int:return floori(VitalistData.scaled(value,int(hero.get("level",1))))
static func details(hero:Dictionary,key:String,heroic_id:String="")->Dictionary:
	match key:
		"D":return {"key":"D","title":"Bio-Kill Switch","meta":"16 sec recharge - No resource","description":"Snapshot and detonate owned infections: Q heals %d; W deals %d and Slows 70%% for 2 seconds."%[amount(hero,435),amount(hero,100)]}
		"Q":return {"key":"Q","title":"Healing Pathogen","meta":"10 sec cooldown - 4.5 sec infection","description":"Heal an ally for %d over 4.5 seconds. Every 0.75 seconds, the original cast can spread once to a nearby eligible ally."%amount(hero,222)}
		"W":return {"key":"W","title":"Weighted Pustule","meta":"10 sec cooldown - 3 sec infection","description":"Deal %d damage and apply a Slow that grows from 5%% to 50%%; expiry deals %d."%[amount(hero,20),amount(hero,88)]}
		"E":return {"key":"E","title":"Lurking Arm","meta":"10 sec cooldown - channeled zone","description":"Channel a zone dealing %d damage per second at full value to PvE enemies and Silencing susceptible targets. D remains usable."%amount(hero,136)}
		"R":
			if heroic_id=="vitalist_l15_r2":return {"key":"R","title":"Massive Shove","meta":"20 sec cooldown","description":"Capture one enemy and shove it to terrain or the encounter boundary for %d damage and a 0.5-second Stun."%amount(hero,190)}
			return {"key":"R","title":"Flailing Swipe","meta":"60 sec cooldown - 1.75 sec sequence","description":"Perform three expanding frontal swipes, each dealing %d damage and safely knocking enemies away."%amount(hero,48)}
	return {}
