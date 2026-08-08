extends RefCounted

const SlayerData = preload("res://scripts/data/slayer_data.gd")
const SlayerSystem = preload("res://scripts/systems/slayer_system.gd")

static func amount(hero:Dictionary,value:float) -> int:return floori(SlayerSystem.scaled(hero,value))
static func details(hero:Dictionary,key:String,heroic_id:String="") -> Dictionary:
	match key:
		"Q":return {"key":"Q","title":"Dive","meta":"Cooldown: 6 seconds • Enemy target","description":"Dive through a selected enemy for %d Physical damage and land safely on its opposite side."%amount(hero,SlayerData.VALUES.q_damage),"sections":[{"heading":"MOVEMENT","body":"Invalid or obstructed casts do not move Slayer or begin cooldown. Dive clears the assigned Basic Action target."}],"note":"Friend or Foe permits manually targeted allied heroes."}
		"W":return {"key":"W","title":"Sweeping Strike","meta":"Cooldown: 8 seconds • Directional dash","description":"Dash to a point and deal %d Physical damage once to each enemy crossed."%amount(hero,SlayerData.VALUES.w_damage),"sections":[{"heading":"BASIC ATTACK BONUS","body":"Damaging at least one enemy grants 35% Basic Attack damage for 3 seconds."}],"note":"The Unbound quest can unlock a second sequential charge for the encounter."}
		"E":return {"key":"E","title":"Evasion","meta":"Cooldown: 15 seconds • Duration: 2.5 seconds","description":"Evade all hostile damaging Basic Actions regardless of their authored damage type.","sections":[{"heading":"EVASION","body":"Evaded attacks deal no Health or Shield damage, apply no on-hit effects, and consume no Block charges."}],"note":"Abilities, Heroics, periodic effects, and environmental damage are not evaded."}
		"R":
			if heroic_id=="slayer_l15_r1":return {"key":"R","title":"Metamorphosis","meta":"Cooldown: 120 seconds • Duration: 18 seconds","description":"Transform at a selected location for %d Physical impact damage and gain %d temporary Health per valid hostile, up to five."%[amount(hero,SlayerData.VALUES.r1_damage),amount(hero,SlayerData.VALUES.r1_health_per_target)],"sections":[],"note":"Demonic Form does not make the temporary Health permanent."}
			if heroic_id=="slayer_l15_r2":return {"key":"R","title":"The Hunt","meta":"Cooldown: 100 seconds • Stun: 1 second","description":"Charge any valid enemy on the active battlefield and deal %d Physical damage."%amount(hero,SlayerData.VALUES.r2_damage),"sections":[],"note":"The charge and damage still occur if the target resists the Stun."}
			return {"key":"R","title":"Heroic Ability","meta":"Unlocks at Level 15","description":"Choose Metamorphosis or The Hunt in the Talent tree.","sections":[],"note":""}
		"D":
			if SlayerSystem.has_talent(hero,"slayer_l30_2"):return {"key":"D","title":"Thrill of Battle","meta":"Cooldown: 70 seconds","description":"Reset Dive, Sweeping Strike, Evasion, and the selected Heroic.","sections":[],"note":"This cooldown cannot be reduced by Betrayer's Thirst."}
			return {"key":"D","title":"Betrayer's Thirst","meta":"Passive Trait","description":"Successful Basic Attacks heal for 30% of resolved damage and reduce Q, W, E, and the selected Heroic by 1 second.","sections":[{"heading":"SUCCESSFUL ATTACK","body":"Positive Health or Shield damage qualifies. Blind, Evasion, immunity, Stasis, and zero damage do not."}],"note":"The trait reduces only an active sequential charge recharge."}
	return {"key":key,"title":"Slayer Ability","meta":"","description":"","sections":[],"note":""}
