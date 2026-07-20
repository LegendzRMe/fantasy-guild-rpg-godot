extends RefCounted

const ClassData = preload("res://scripts/data/class_data.gd")

# These scenarios are stable measuring sticks, not final encounter balance.
# Class-specific actions and rotations are intentionally supplied by build data.
const STANDARD_SCENARIOS := {
	"single_target_120":{
		"scenario_id":"single_target_120",
		"display_name":"Single Target (120 sec)",
		"mode":"damage",
		"duration":120.0,
		"targets":[{"target_id":"training_dummy","max_health":1000000000.0,"armor":0.0}]
	},
	"armored_target_120":{
		"scenario_id":"armored_target_120",
		"display_name":"Armored Target (120 sec)",
		"mode":"damage",
		"duration":120.0,
		"targets":[{"target_id":"armored_dummy","max_health":1000000000.0,"armor":100.0}]
	},
	"burst_target_30":{
		"scenario_id":"burst_target_30",
		"display_name":"Burst Target (30 sec)",
		"mode":"damage",
		"duration":30.0,
		"targets":[{"target_id":"burst_dummy","max_health":1000000000.0,"armor":0.0}]
	},
	"sustained_tank_healing_120":{
		"scenario_id":"sustained_tank_healing_120",
		"display_name":"Sustained Tank Healing (120 sec)",
		"mode":"healing",
		"duration":120.0,
		"targets":[{
			"target_id":"tank_ally",
			"max_health":1000.0,
			"initial_health_percent":0.65,
			"incoming_damage":20.0,
			"incoming_interval":1.25,
			"incoming_start":0.0
		}]
	},
	"party_healing_120":{
		"scenario_id":"party_healing_120",
		"display_name":"Party Healing (120 sec)",
		"mode":"healing",
		"duration":120.0,
		"targets":[
			{"target_id":"tank","max_health":1000.0,"initial_health_percent":0.75,"incoming_damage":16.0,"incoming_interval":1.25,"incoming_start":0.0},
			{"target_id":"ally_2","max_health":650.0,"initial_health_percent":0.80,"incoming_damage":9.0,"incoming_interval":2.0,"incoming_start":0.4},
			{"target_id":"ally_3","max_health":650.0,"initial_health_percent":0.80,"incoming_damage":9.0,"incoming_interval":2.0,"incoming_start":0.9},
			{"target_id":"ally_4","max_health":650.0,"initial_health_percent":0.80,"incoming_damage":9.0,"incoming_interval":2.0,"incoming_start":1.4}
		]
	}
}

static func standard_scenarios()->Array:
	var scenarios:Array=[]
	for scenario_id in STANDARD_SCENARIOS:
		scenarios.append(STANDARD_SCENARIOS[scenario_id].duplicate(true))
	return scenarios

static func prototype_baseline_builds(level:int=1)->Array:
	var builds:Array=[]
	for display_name in ClassData.CLASSES:
		var definition:Dictionary=ClassData.CLASSES[display_name]
		builds.append({
			"build_id":"prototype_%s_basic"%str(definition.class_id),
			"display_name":"[Prototype] %s Basic Action"%display_name,
			"class_id":definition.class_id,
			"level":level,
			"class_definition":definition.duplicate(true),
			"equipment":[],
			"actions":[],
			"notes":"Temporary Basic Action baseline; no final class abilities, talents, rotation, or utility are assumed."
		})
	return builds
