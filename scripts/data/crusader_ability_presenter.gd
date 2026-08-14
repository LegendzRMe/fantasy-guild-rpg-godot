extends RefCounted
const CrusaderData=preload("res://scripts/data/crusader_data.gd")
static func amount(hero:Dictionary,value:float)->int:return floori(CrusaderData.scaled(value,int(hero.get("level",1))))
static func details(hero:Dictionary,key:String,heroic_id:String="")->Dictionary:
	match key:
		"D":return {"key":"D","title":"Iron Skin","meta":"22 sec cooldown - No Mana","description":"Gain a %d Shield for 4 seconds. Crusader is Unstoppable only while this specific Shield exists."%amount(hero,810)}
		"Q":return {"key":"Q","title":"Punish","meta":"8 sec cooldown","description":"Strike a 160-degree frontal area for %d and apply a 50%% Slow that decays over 2 seconds."%amount(hero,113)}
		"W":return {"key":"W","title":"Condemn","meta":"10 sec cooldown - 1 sec preparation","description":"Move freely during preparation, then deal %d, pull nearby enemies inward, and Stun for 0.25 seconds."%amount(hero,55)}
		"E":return {"key":"E","title":"Shield Glare","meta":"13 sec cooldown","description":"Deal %d in a long directional cone and Blind affected enemies for 1.5 seconds."%amount(hero,59)}
		"R":
			if heroic_id=="crusader_l15_r2":return {"key":"R","title":"Blessed Shield","meta":"65 sec cooldown","description":"Deal %d and Stun the first target for 1.5 seconds, then bounce to two targets for %d and 0.75-second Stuns."%[amount(hero,114),amount(hero,57)]}
			return {"key":"R","title":"Falling Sword","meta":"50 sec cooldown - 2 sec airborne","description":"Steer while airborne and grant allies underneath Unstoppable, then land for %d and a 0.25-second Stun."%amount(hero,225)}
	return {}
