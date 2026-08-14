extends RefCounted

const DeathKnightData=preload("res://scripts/data/death_knight_data.gd")
const DeathKnightSystem=preload("res://scripts/systems/death_knight_system.gd")
static func amount(hero:Dictionary,value:float)->int:return floori(DeathKnightSystem.scaled(hero,value))

static func details(hero:Dictionary,action_key:String,heroic_id:String="")->Dictionary:
	match action_key:
		"trait":return {"key":"D","title":"Frostmourne Hungers","meta":"Cooldown: %g seconds"%DeathKnightSystem.frostmourne_cooldown(hero),"description":"Empower the next immediate primary Basic Attack for %d bonus damage. Encounter stacks add %d bonus and %s Basic Attack damage each."%[amount(hero,float(DeathKnightData.VALUES.frostmourne_damage)),amount(hero,float(DeathKnightData.VALUES.frostmourne_damage_per_stack)),str(DeathKnightSystem.scaled(hero,float(DeathKnightData.VALUES.frostmourne_basic_per_stack)))],"sections":[]}
		"q":return {"key":"Q","title":"Death Coil","meta":"Cooldown: 9 seconds","description":"Deal %d damage to an enemy or heal yourself for %d. It never targets another ally."%[amount(hero,float(DeathKnightData.VALUES.death_coil_damage)),amount(hero,float(DeathKnightData.VALUES.death_coil_heal))],"sections":[]}
		"w":return {"key":"W","title":"Howling Blast","meta":"Cooldown: 10 seconds","description":"Ground-target an area for %d damage and a %s-second Root."%[amount(hero,float(DeathKnightData.VALUES.howling_damage)),str(DeathKnightSystem.howling_root(hero))],"sections":[]}
		"e":var active:=bool(hero.get("death_knight_runtime",{}).get("tempest",{}).get("active",false));return {"key":"E","title":"Turn Off Frozen Tempest" if active else "Frozen Tempest","meta":"ACTIVE — no maximum duration" if active else "Cooldown on exit: %g seconds"%DeathKnightSystem.tempest_cooldown(hero),"description":"Toggle a one-second damage and suppression aura. While active, D/Q/W/R are locked unless Eternal Winter is selected.","sections":[]}
		"heroic":
			if heroic_id=="death_knight_l15_r1":return {"key":"R","title":"Army of the Dead","meta":"Six charges; %g-second charge cooldown"%(float(DeathKnightData.VALUES.army_charge_cooldown)-(float(DeathKnightData.VALUES.legion_cdr) if DeathKnightSystem.has_talent(hero,"death_knight_l27_r1") else 0.0)),"description":"Consume every available charge and summon %s 15-second Ghoul per charge."%("two" if DeathKnightSystem.has_talent(hero,"death_knight_l27_r1") else "one"),"sections":[]}
			return {"key":"R","title":"Summon Sindragosa","meta":"Cooldown: 100 seconds","description":"Deal %d damage in a long path, Slow 60%% for four seconds, and Blind for four seconds."%amount(hero,float(DeathKnightData.VALUES.sindragosa_damage)),"sections":[]}
	return {}
