extends RefCounted

const MonkData=preload("res://scripts/data/monk_data.gd")
const MonkSystem=preload("res://scripts/systems/monk_system.gd")
static func amount(hero:Dictionary,value:float)->int:return floori(MonkData.scaled(value,int(hero.get("level",1))))
static func details(hero:Dictionary,key:String,heroic_id:String="")->Dictionary:
	match key:
		"D":
			var kind:=MonkSystem.ally_kind(hero);return {"key":"D","title":"Unassigned","meta":"Select a Guild-12 Ally"} if kind=="" else {"key":"D","title":"%s Ally"%kind.capitalize(),"meta":"45 sec cooldown","description":"Place a targetable ten-second %s Ally that is a valid Radiant Dash anchor."%kind}
		"Q":return {"key":"Q","title":"Radiant Dash","meta":"%d charges - %.0f sec recharge - No Mana"%[MonkSystem.q_max(hero),MonkSystem.q_recharge(hero)],"description":"Dash safely to an eligible ally or enemy. Allied Dash triggers ready Breath; enemy Dash activates ready Deadly Reach before an immediate Basic Attack."}
		"W":return {"key":"W","title":"Breath of Heaven","meta":"PASSIVE - 10 sec cooldown","description":"A ready allied Radiant Dash automatically heals eligible allies near the landing point for %d and grants Movement Speed."%amount(hero,float(MonkData.VALUES.breath_heal)),"note":"Cannot be manually activated."}
		"E":return {"key":"E","title":"Deadly Reach","meta":"PASSIVE - 10 sec cooldown","description":"A ready enemy Radiant Dash activates +100% Basic Attack Speed and range before its immediate attack.","note":"Cannot be manually activated."}
		"R":
			if heroic_id=="monk_l15_r1":return {"key":"R","title":"Divine Palm","meta":"50 sec cooldown","description":"Protect an eligible Hero-equivalent ally from lethal damage for four seconds, then heal %d."%amount(hero,float(MonkData.VALUES.palm_heal))}
			return {"key":"R","title":"Seven-Sided Strike","meta":"50 sec cooldown","description":"Become Invulnerable and strike %d times over two seconds. Each strike deals 7%% maximum Health, or 0.5%% to Bosses."%(11 if MonkSystem.has_talent(hero,"monk_l27_r2") else 7)}
	return {}
