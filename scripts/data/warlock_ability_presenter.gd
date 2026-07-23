extends RefCounted

const WarlockData = preload("res://scripts/data/warlock_data.gd")
const WarlockSystem = preload("res://scripts/systems/warlock_system.gd")

static func amount(hero:Dictionary, value:float, q_scaling:bool=false, qwe_power:bool=true) -> int:
	return floori(WarlockSystem.scaled_amount(hero, value, q_scaling, qwe_power))

static func details(hero:Dictionary, key:String, heroic_id:String="") -> Dictionary:
	match key:
		"Q":
			return {"key":"Q","title":"Fel Flame","meta":"Cooldown: %d seconds"%int(WarlockSystem.modified_base_cooldown(hero, 0)),"description":"Release an expanding wave of flame, dealing %d Magical damage to each enemy hit."%amount(hero, WarlockData.VALUES.q_damage, true),"sections":[{"heading":"CONTROL","body":"Aim the wave manually. Each target can be hit at most once by a cast, and the assigned Basic Action target is preserved."}],"note":"Pursuit of Flame eventually increases area, not damage."}
		"W":
			return {"key":"W","title":"Drain Life","meta":"Cooldown: %d seconds  •  Channel: 3 seconds"%int(WarlockSystem.modified_base_cooldown(hero, 1)),"description":"Channel on an enemy, dealing %d Magical damage and restoring %d Health per second."%[amount(hero, WarlockData.VALUES.w_damage_per_second), amount(hero, WarlockData.VALUES.w_healing_per_second)],"sections":[{"heading":"CHANNEL","body":"Movement, range or line-of-sight loss, Stun, Silence, Fear, knockback, or target invalidation ends the channel. Ordinary damage does not."},{"heading":"TICKS","body":"Damage and healing resolve independently four times each second."}],"note":"The cooldown begins when the valid channel commits and continues recovering while it is active."}
		"E":
			return {"key":"E","title":"Corruption","meta":"Cooldown: %d seconds  •  Duration: 6 seconds"%int(WarlockSystem.modified_base_cooldown(hero, 2)),"description":"Send three sequential shadow bursts forward. Each hit applies %d Periodic Magical damage over 6 seconds, stacking up to 3 times."%amount(hero, WarlockData.VALUES.e_damage, true),"sections":[{"heading":"SEQUENTIAL BURSTS","body":"The bursts land one after another rather than simultaneously. Each stack owns its own duration and tick schedule."},{"heading":"QUEST","body":"Echoed Corruption counts applications during the current encounter. At 40, later casts also burst in reverse. At 85, Corruption heals from actual resolved damage."}],"note":"Quest progress resets only when the encounter ends or restarts."}
		"R":
			if heroic_id=="warlock_l15_r1":
				return {"key":"R","title":"Horrify","meta":"Cooldown: %d seconds  •  Delay: 0.5 seconds"%int(WarlockSystem.modified_base_cooldown(hero, 3)),"description":"After a warning, deal %d Magical damage in an area and Fear enemies for 2 seconds."%amount(hero, WarlockData.VALUES.r1_damage, false, false),"sections":[{"heading":"FEAR","body":"A successfully Feared enemy is Silenced, cannot attack or receive commands, and moves away from the cast center without crossing walls or arena bounds."}],"note":"Boss control profiles may resist or shorten Fear. Only actual successful Fear triggers Haunt."}
			if heroic_id=="warlock_l15_r2":
				return {"key":"R","title":"Rain of Destruction","meta":"Cooldown: %d seconds  •  Cast: 1.5 seconds  •  Duration: 7 seconds"%int(WarlockSystem.modified_base_cooldown(hero, 3)),"description":"Cover the active arena with warned meteor impacts. Each meteor deals %d Magical damage in a small area."%amount(hero, WarlockData.VALUES.r2_meteor_damage, false, false),"sections":[{"heading":"PERSISTENT HEROIC","body":"After release, the rain continues independently if the Warlock moves or becomes incapacitated."}],"note":"Deep Impact keeps a random component while prioritizing recent enemy positions."}
		"D":
			return {"key":"D","title":"Life Tap","meta":"Health cost: 13% maximum Health  •  Lockout: 0.5 seconds","description":"Spend Health without dealing damage to reduce eligible Q, W, E, and tagged internal cooldowns by 25% of each modified base cooldown.","sections":[{"heading":"NONLETHAL HEALTH COST","body":"Life Tap bypasses Armor and Shields and cannot reduce the Warlock to zero. It is unavailable when nothing can benefit."},{"heading":"HEALTH-LOSS ENGINE","body":"Other actual Health loss grants proportional cooldown reduction after mitigation and Shields. Life Tap's own cost never feeds that loop."}],"note":"Improved Life Tap raises direct reduction to 40%. Dark Ritual separately reduces the selected Heroic."}
	return {"key":key,"title":"Warlock Ability","meta":"","description":"","sections":[],"note":""}
