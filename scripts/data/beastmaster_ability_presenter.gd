extends RefCounted

const BeastmasterData=preload("res://scripts/data/beastmaster_data.gd")
const BeastmasterSystem=preload("res://scripts/systems/beastmaster_system.gd")

static func amount(hero:Dictionary,value:float)->int:return floori(BeastmasterData.scaled(value,int(hero.get("level",1))))
static func details(hero:Dictionary,key:String,heroic_id:String="")->Dictionary:
	match key:
		"D":return {"key":"D","title":"Misha, Focus!","meta":"Enemy or self target • No Mana","description":"Command Misha to prioritize an enemy, or target Beastmaster to retreat with 30% additional Movement Speed.","sections":[{"heading":"PASSIVE","body":"Misha gains 15% Movement Speed."}],"note":"No point, wait, or hold command."}
		"Q":return {"key":"Q","title":"Spirit Swoop","meta":"2 charges • %d sec recharge • No Mana"%int(BeastmasterSystem.q_recharge(hero)),"description":"Deal %d damage in a line and Slow %d%% for %.1f seconds; create %d Lesser Beast%s at the safe endpoint."%[amount(hero,float(BeastmasterData.VALUES.swoop_damage)),int(BeastmasterData.VALUES.crippling_slow*100.0 if BeastmasterSystem.has_talent(hero,"beastmaster_l18_1") else BeastmasterData.VALUES.swoop_slow*100.0),float(BeastmasterData.VALUES.crippling_duration if BeastmasterSystem.has_talent(hero,"beastmaster_l18_1") else BeastmasterData.VALUES.swoop_slow_duration),2 if BeastmasterSystem.has_talent(hero,"beastmaster_l9_1") else 1,"s" if BeastmasterSystem.has_talent(hero,"beastmaster_l9_1") else ""],"sections":[{"heading":"LESSER BEAST","body":"53 level-one Basic Attack damage; loses Health continuously and naturally expires near 17 seconds."}]}
		"W":return {"key":"W","title":"Misha, Charge!","meta":"10 sec cooldown • Misha required","description":"Misha charges in a line for %d damage and Stuns for 1.25 seconds."%amount(hero,float(BeastmasterData.VALUES.charge_damage)),"sections":[],"note":"Unavailable while Misha is defeated."}
		"E":return {"key":"E","title":"Greater Beast","meta":"60 sec cooldown • Misha required","description":"Summon a stronger autonomous beast at Misha's safe position. It loses Health continuously and naturally expires near 21 seconds.","sections":[{"heading":"HEALING","body":"Not an ordinary allied healing target; specific Beast-only healing can extend its life."}],"note":"Mend Pet is removed."}
		"R":
			if heroic_id=="beastmaster_l15_r1":return {"key":"R","title":"Bestial Wrath","meta":"50 sec cooldown","description":"Misha deals 200% increased Basic Attack damage for %d seconds."%int(BeastmasterSystem.bestial_duration(hero)),"sections":[],"note":"Unavailable while Misha is defeated."}
			return {"key":"R","title":"Unleash the Boars","meta":"60 sec cooldown","description":"Track up to five immediate targets for %d damage, Reveal, and a 40%% Slow for five seconds."%amount(hero,float(BeastmasterData.VALUES.boar_damage)*(1.5 if BeastmasterSystem.has_talent(hero,"beastmaster_l27_r2") else 1.0)),"sections":[{"heading":"KILL COMMAND","body":"The upgrade adds 50% damage and a 1.5-second Root."}],"note":"Boars are tracking effects, not pack summons."}
	return {}

