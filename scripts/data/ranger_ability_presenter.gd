extends RefCounted

const RangerData = preload("res://scripts/data/ranger_data.gd")
const RangerSystem = preload("res://scripts/systems/ranger_system.gd")

static func amount(hero:Dictionary,value:float)->int:return floori(RangerData.scaled(value,int(hero.get("level",1))))

static func details(hero:Dictionary,key:String,heroic_id:String="")->Dictionary:
	match key:
		"Q":return {"key":"Q","title":"Hungering Arrow","meta":"Cooldown: 10 seconds","description":"Fire a directional arrow dealing %d damage, then seeking nearby enemies twice for %d damage per hit."%[amount(hero,140.0),amount(hero,80.0)],"sections":[{"heading":"SEEKING","body":"The same target may be struck again. Targets resolve deterministically by distance, then stable combat ID."}],"note":"A missed initial arrow still spends its cooldown."}
		"W":return {"key":"W","title":"Multishot","meta":"Cooldown: 13 seconds","description":"Unleash an expanding 50-degree cone that deals %d Physical damage to each enemy once."%amount(hero,159.0),"sections":[{"heading":"EXPANDING CONE","body":"The wave expands from short range to full range over 0.375 seconds."}],"note":"Distinct targets are tracked once per cast."}
		"E":return {"key":"E","title":"Vault","meta":"Cooldown: 10 seconds","description":"Vault to a valid location. The next Basic Attack within 2 seconds gains 6% damage per Hatred held when Vault was released.","sections":[{"heading":"MOVEMENT","body":"Vault crosses units but not solid walls, clears the current assignment, and consumes Blind on the empowered Basic Attack normally."}],"note":"Moving across the battlefield remains a deliberate commitment."}
		"R":
			if heroic_id in ["ranger_r1","ranger_l15_r1"]:return {"key":"R","title":"Strafe","meta":"Cooldown: 60 seconds  •  Duration: 4 seconds","description":"Move while firing 8 shots per second at nearby enemies for %d damage each."%amount(hero,70.0),"sections":[{"heading":"CHANNEL RULES","body":"Normal Basic Attacks pause. Movement and Vault remain available; Q, W, and D are unavailable. True control interrupts."}],"note":"Hatred expiration pauses while Strafe is active."}
			if heroic_id in ["ranger_r2","ranger_l15_r2"]:return {"key":"R","title":"Rain of Vengeance","meta":"2 charges  •  50-second sequential recharge","description":"After 0.25 seconds, sweep a rectangle for %d Physical damage and Stun each target for 0.5 seconds."%amount(hero,250.0),"sections":[{"heading":"CHARGES","body":"Only one charge recharges at a time. A pre-release interruption preserves the charge and applies a 10-second slot lockout."}],"note":"Each enemy can be hit only once per cast."}
		"D":
			if RangerSystem.has_talent(hero,"ranger_l21_3"):return {"key":"D","title":"Gloom","meta":"Passive and Active Trait  •  Cooldown: 5 seconds","description":"Passively gain 15 Armor and regenerate Health per Hatred. Activate to consume Hatred and gain 3 additional Armor per stack for 5 seconds.","sections":[],"note":"The passive regeneration scales with level."}
			return {"key":"D","title":"Hatred","meta":"Passive Trait","description":"Successful Basic Attacks grant Hatred for 5 seconds, up to 10. Each stack grants 8% Basic Attack damage and 1% Movement Speed.","sections":[{"heading":"SHARED TIMER","body":"Each successful eligible Basic Attack refreshes the full stack timer. Strafe pauses it."}],"note":"D is informational until Gloom is selected."}
	return {"key":key,"title":"Ranger Ability","meta":"","description":"","sections":[],"note":""}

