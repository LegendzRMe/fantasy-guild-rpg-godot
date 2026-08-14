extends RefCounted

const WarriorData=preload("res://scripts/data/warrior_data.gd")
const WarriorSystem=preload("res://scripts/systems/warrior_system.gd")
static func amount(hero:Dictionary,value:float)->int:return floori(WarriorSystem.scaled(hero,value))
static func details(hero:Dictionary,key:String,heroic_id:String="")->Dictionary:
	match key:
		"D":
			if WarriorSystem.has_talent(hero,"warrior_l21_3"):return {"key":"D","title":"Shattering Throw","meta":"Cooldown: 30 seconds","description":"Deal %d damage plus up to %d shield-only damage; unused shield damage never spills into Health."%[amount(hero,50),amount(hero,1400)],"sections":[],"note":"Heroic Strike remains passive."}
			return {"key":"D","title":"Heroic Strike","meta":"Passive • 18-second cooldown","description":"The next successful primary Basic Attack deals %d in a separate bonus packet; successful primary attacks reduce its cooldown by 3 seconds."%amount(hero,125),"sections":[],"note":"A Blind or Evasion miss consumes the proc and resets the cooldown without success CDR."}
		"Q":return {"key":"Q","title":"Lion's Fang","meta":"Cooldown: 8 seconds • Traveling line","description":"Deal %d damage and Slow 35%% for 1.5 seconds. Heal %d per normal eligible contact or %d from a Boss."%[amount(hero,150),amount(hero,35),amount(hero,140)],"sections":[],"note":"Summon healing requires Lionheart."}
		"W":return {"key":"W","title":"Parry","meta":"2 charges • 10-second recharge","description":"For 1.25 seconds, hostile Basic Attack contacts deal no damage.","sections":[],"note":"Shield Wall converts this to one 5-second-recharge Protected charge."}
		"E":return {"key":"E","title":"Charge","meta":"Cooldown: 12 seconds • Enemy target","description":"Safely engage, deal %d damage, and Slow by 75%% for 1 second."%amount(hero,50),"sections":[],"note":"Warbringer permits allied targets and changes cooldown to 4 seconds."}
		"R":
			if heroic_id=="warrior_l12_r1":return {"key":"R","title":"Taunt","meta":"Cooldown: 16 seconds","description":"Force one hostile target, including a Boss, to prioritize Warrior for 1.25 seconds and apply profile-resolved Silence.","sections":[],"note":"Effective role Tank; no maximum-Health bonus."}
			if heroic_id=="warrior_l12_r2":return {"key":"R","title":"Colossus Smash","meta":"Cooldown: 20 seconds","description":"Leap safely, deal %d damage, and apply %d scaled Armor reduction for 3 seconds."%[amount(hero,185),amount(hero,25)],"sections":[],"note":"Strongest Armor-reduction source wins."}
			if heroic_id=="warrior_l12_r3":return {"key":"R","title":"Twin Blades of Fury","meta":"Passive specialization","description":"Double Attack Speed, reduce Basic Attack damage 25%%, and make primary attacks reduce Heroic Strike by 7 seconds total.","sections":[],"note":"R is displayed but not castable."}
	return {"key":key,"title":"Warrior Ability","meta":"","description":"","sections":[],"note":""}
