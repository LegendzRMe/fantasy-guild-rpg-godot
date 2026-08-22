extends RefCounted
const SpiritWeaverData=preload("res://scripts/data/spiritweaver_data.gd")
const SpiritWeaverSystem=preload("res://scripts/systems/spiritweaver_system.gd")
static func amount(hero:Dictionary,value:float)->int:return int(round(SpiritWeaverData.scaled(value,int(hero.get("level",1)))))
static func ability(hero:Dictionary,key:String)->Dictionary:
	match key:
		"Q":return {"key":"Q","title":"Chain Heal","meta":"8 sec cooldown - Allied target","description":"Heal up to %d allied Heroes for %d each through nearby bounces."%[SpiritWeaverSystem.q_recipient_count(hero),amount(hero,float(SpiritWeaverData.VALUES.q_heal))],"sections":[{"heading":"BOUNCE","body":"Each Hero once per cast; relay talents preserve separate healed-Hero and relay histories."}]}
		"W":return {"key":"W","title":"Lightning Shield","meta":"8 sec cooldown - 5 sec duration","description":"Attach to an ally and deal %d damage per second around its bearer."%amount(hero,float(SpiritWeaverData.VALUES.w_dps)),"sections":[{"heading":"OWNERSHIP","body":"Each cast owns its bearer, duration, contacts, and Rising Storm stacks."}]}
		"E":return {"key":"E","title":"Earthbind Totem","meta":"15 sec cooldown - Ground target","description":"Place a %d-Health deployable for %g seconds that Slows nearby enemies."%[amount(hero,float(SpiritWeaverData.VALUES.e_health)),float(SpiritWeaverData.VALUES.e_duration)],"sections":[{"heading":"DEPLOYABLE","body":"Enemies may destroy it. Colossal Totem can reposition the same instance once."}]}
		"D":return {"key":"D","title":"Purge","meta":"60 sec cooldown - Ally or enemy","description":"Cleanse an ally and grant 0.5 seconds Unstoppable, or apply an 80% decaying enemy Slow for two seconds.","sections":[{"heading":"TRAIT","body":"Ghost Wolf activates automatically after three seconds without your own Basic Action or successful ability."}]}
		"R":
			if str(hero.get("selected_heroic_id",""))=="spiritweaver_l15_r2":return {"key":"R","title":"Bloodlust","meta":"90 sec cooldown - Party support","description":"Nearby Heroes gain 40% Basic Action speed, 35% Move Speed, and 30% Basic Attack healing for six seconds.","sections":[]}
			return {"key":"R","title":"Ancestral Healing","meta":"100 sec cooldown - 1 sec delay","description":"Heal another allied Hero for %d after one second."%amount(hero,float(SpiritWeaverData.VALUES.ancestral_heal)),"sections":[]}
	return {}
