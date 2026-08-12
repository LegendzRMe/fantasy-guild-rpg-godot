extends RefCounted

const DruidData=preload("res://scripts/data/druid_data.gd")
const DruidSystem=preload("res://scripts/systems/druid_system.gd")

static func amount(hero:Dictionary,value:float)->int:return floori(DruidSystem.power_scaled(hero,value))

static func details(hero:Dictionary,key:String,heroic_id:String="")->Dictionary:
	match key:
		"D":return {"key":"D","title":"Innervate","meta":"Cooldown: 25 seconds • Ally target","description":"For 5 seconds, the ally's Q, W, and E cooldowns recharge 50% faster.","sections":[{"heading":"RESOURCE FREE","body":"Innervate restores no Mana and works on any living allied Hero except Druid."}],"note":"Revitalize also accelerates Druid; Shan'do's Clarity adds a charge."}
		"Q":return {"key":"Q","title":"Regrowth","meta":"Cooldown: 5 seconds • %s-second HoT"%str(DruidSystem.regrowth_duration(hero)),"description":"Heal one selected allied Hero for %d over %s seconds, beginning one second after application."%[amount(hero,DruidData.VALUES.regrowth_tick)*int(DruidSystem.regrowth_duration(hero)),str(DruidSystem.regrowth_duration(hero))],"sections":[{"heading":"PROACTIVE HEALING","body":"Each source owns one Regrowth per target. Recasting refreshes it; another Druid remains independent."}],"note":"Regrowth-specific talents do not modify Basic Attack mini-HoTs."}
		"W":return {"key":"W","title":"Moonfire","meta":"Cooldown: 3 seconds • Ground area","description":"Deal %d Magical damage and Reveal contacts for 2 seconds. Each qualifying enemy adds %d direct healing to every ally with this Druid's Regrowth."%[amount(hero,DruidData.VALUES.moonfire_damage),amount(hero,DruidData.VALUES.moonfire_heal)],"sections":[{"heading":"COMBINED HEAL","body":"Up to five contacts are combined into one healing event per Regrowth ally."}],"note":"Nature's Balance increases radius by the project-approved 75%."}
		"E":return {"key":"E","title":"Entangling Roots","meta":"Cooldown: 12 seconds • 3-second growth","description":"Grow a ground area that deals %d Magical damage once and attempts a 1.25-second Root as it reaches each enemy."%amount(hero,DruidData.VALUES.roots_damage),"sections":[],"note":"Boss control profiles can resist the Root without preventing damage."}
		"R":
			if heroic_id=="druid_l15_r1":return {"key":"R","title":"Tranquility","meta":"Cooldown: 80 seconds • Duration: 8 seconds","description":"Heal nearby allied Heroes for %d per second. Own-Regrowth allies inside gain 10 universal Armor."%amount(hero,DruidData.VALUES.tranquility_tick),"sections":[],"note":"Tagged periodic healing, not target-bound healing-over-time."}
			if heroic_id=="druid_l15_r2":return {"key":"R","title":"Twilight Dream","meta":"Cooldown: 90 seconds • Delay: 0.5 seconds","description":"Deal %d Magical damage nearby, Silence for 3 seconds, and refresh every active own Regrowth globally."%amount(hero,DruidData.VALUES.twilight_damage),"sections":[],"note":"Astral Communion teleports after a channel and adds a free Moonfire."}
	return {"key":key,"title":"Druid Ability","meta":"","description":"","sections":[],"note":""}
