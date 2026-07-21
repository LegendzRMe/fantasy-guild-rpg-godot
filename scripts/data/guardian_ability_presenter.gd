extends RefCounted

const GuardianData = preload("res://scripts/data/guardian_data.gd")

static func _number(value:float)->String:
	return str(int(floor(value)))

static func _level_scaled(key:String,level:int)->String:
	return _number(GuardianData.scaled(float(GuardianData.VALUES[key]),level))

static func _power_scaled(key:String,current_power:float)->String:
	return _number(GuardianData.power_scaled(float(GuardianData.VALUES[key]),current_power))

static func details(hero:Dictionary,action_key:String,heroic_id:String="",current_power:float=-1.0)->Dictionary:
	var level:=int(hero.get("level",1))
	if current_power<0.0:current_power=GuardianData.scaled(float(GuardianData.VALUES.basic_attack_damage),level)
	var result:={"key":action_key,"title":"Ability","meta":"","description":"","sections":[],"note":"Current values include this Hero's Level and equipped Power."}
	match action_key:
		"Q":
			result.title="Storm Bolt"
			result.meta="Cooldown: 10 seconds  •  Physical  •  Directional"
			result.description="Throw a hammer, dealing %s damage to the first enemy hit and Stunning it for 1.25 seconds."%_power_scaled("storm_bolt_damage",current_power)
			result.sections=[
				{"heading":"PER-BATTLE QUEST","body":"Basic Attack qualifying enemies affected by Slows or Stuns. Slowed targets grant 1 stack, Stunned targets grant 2 stacks, and a qualifying target that dies within 3 seconds of being marked by Storm Bolt grants 5 stacks. Progress persists between waves and resets when the battle ends."},
				{"heading":"45-STACK REWARD","body":"Storm Bolt pierces one additional target, and Basic Attacks reduce its cooldown by 0.5 seconds."},
				{"heading":"160-STACK REWARD","body":"Storm Bolt gains 50% range, doubles in width, and pierces all valid targets."}
			]
		"W":
			result.title="Thunder Clap"
			result.meta="Cooldown: 8 seconds  •  Physical  •  Area around Hero"
			result.description="Blast nearby enemies for %s damage. Affected enemies are Slowed by 30%% and their Basic Action speed is reduced by 30%% for 2.5 seconds."%_power_scaled("thunder_clap_damage",current_power)
		"E":
			result.title="Dwarf Toss"
			result.meta="Cooldown: 10 seconds  •  Ground targeted"
			result.description="Leap to a valid target location and deal %s damage to nearby enemies on landing. Gain 30 Armor for 2 seconds. A valid leap clears the current assignment; an invalid leap consumes nothing."%_power_scaled("dwarf_toss_damage",current_power)
		"R":
			if heroic_id=="guardian_l15_r2":
				result.title="Haymaker"
				result.meta="Cooldown: 40 seconds  •  Physical  •  Enemy targeted"
				result.description="Stun the chosen enemy and wind up a punch that deals %s damage. Ordinary enemies are knocked backward; Bosses are staggered instead."%_power_scaled("haymaker_damage",current_power)
			else:
				result.title="Avatar"
				result.meta="Cooldown: 90 seconds  •  Duration: 20 seconds  •  Self cast"
				result.description="Transform for 20 seconds, gaining %s maximum and current Health and becoming visibly larger in combat."%_level_scaled("avatar_health",level)
		"D":
			result.title="Second Wind"
			result.meta="Passive Trait"
			result.description="After taking no resolved damage for 4 seconds, restore %s Health per second. Below 40%% Health, restore %s Health per second instead. Damage absorbed by a Shield still resets the delay."%[_level_scaled("second_wind_normal",level),_level_scaled("second_wind_low",level)]
	return result
