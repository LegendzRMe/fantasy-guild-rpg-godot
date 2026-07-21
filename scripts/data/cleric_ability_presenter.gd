extends RefCounted

const ClericData = preload("res://scripts/data/cleric_data.gd")
const ClericSystem = preload("res://scripts/systems/cleric_system.gd")

static func _amount(hero:Dictionary,base_amount:float)->int:
	return int(floor(ClericSystem.scaled_amount(hero,base_amount)))

static func details(hero:Dictionary,action_key:String,heroic_id:String="")->Dictionary:
	match action_key:
		"Q":
			return {"key":"Q","title":"Healing Brew","meta":"Cooldown: 4 seconds","description":"Heal the lowest-Health wounded ally in range for %d."%_amount(hero,210.0),"sections":[{"heading":"TARGETING","body":"Self is valid. Ties resolve by Health percentage, distance, then stable combat ID. The cooldown is not spent when nobody is wounded."}],"note":"Uses current level, Power, equipment, and active Spell Power."}
		"W":
			return {"key":"W","title":"Cloud Serpent","meta":"Cooldown: 11 seconds  •  Duration: 8 seconds","description":"Attach a Cloud Serpent to the chosen allied hero. Once per second it damages the nearest enemy for %d and heals its host for %d."%[_amount(hero,26.0),_amount(hero,20.0)],"sections":[{"heading":"ASSIGNMENT","body":"The Cleric's current Basic Action assignment is preserved. Recasting on the same host refreshes the Serpent."}],"note":"Serpent attacks are Ability effects, not Basic Attacks, and cannot miss from Blind."}
		"E":
			return {"key":"E","title":"Blinding Wind","meta":"Cooldown: 12 seconds","description":"Damage the 2 nearest enemies for %d, Slow them by 15%% for 1.5 seconds, and Blind them for 1.5 seconds."%_amount(hero,133.0),"sections":[{"heading":"BLIND","body":"Blind causes Basic Attacks released while Blinded to miss. Boss Blind resistance is controlled by each unit's data profile; damage and Slow still resolve independently."}],"note":"Targets are deterministic: distance, then stable combat ID."}
		"R":
			if heroic_id in ["cleric_r1","cleric_l15_r1"]:return {"key":"R","title":"Jug of Healing","meta":"Channel: up to 6 seconds","description":"Every 0.25 seconds, heal the lowest-Health nearby ally for %d."%_amount(hero,75.0),"sections":[{"heading":"COOLDOWN","body":"Starts at 20 seconds and gains 2 seconds for each completed tick, to a maximum of 70 seconds."},{"heading":"INTERRUPTS","body":"Movement, true control, or pressing R again ends the channel. Ordinary damage does not."}],"note":"Overhealing ticks still count toward the resulting cooldown."}
			if heroic_id in ["cleric_r2","cleric_l15_r2"]:return {"key":"R","title":"Water Dragon","meta":"Cooldown: 50 seconds  •  Precast: 2 seconds","description":"After the precast, strike the nearest enemy and nearby enemies for %d, Slowing them by 70%% for 4 seconds."%_amount(hero,300.0),"sections":[{"heading":"INTERRUPTS","body":"Movement or true control before release applies the universal 10-second interrupted Heroic cooldown. Damage does not interrupt."}],"note":"Fails without spending cooldown when no enemy exists."}
		"D":
			return {"key":"D","title":"Fast Feet","meta":"Passive Trait","description":"Taking positive hostile combat damage grants 10% Move Speed and makes Q, W, and E cooldowns recover 50% faster for 1 second.","sections":[{"heading":"TRIGGER RULES","body":"Damage to Health or Shields activates Fast Feet. Blind misses and zero damage do not. Reapplication refreshes duration and never stacks."}],"note":"Fast Feet does not accelerate Heroic, Trait, item, or passive timers."}
	return {"key":action_key,"title":"Cleric Ability","meta":"","description":"","sections":[],"note":""}
