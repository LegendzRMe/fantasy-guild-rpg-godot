extends RefCounted

const TalentData = preload("res://scripts/data/talent_data.gd")
const GuardianData = preload("res://scripts/data/guardian_data.gd")
const ClericData = preload("res://scripts/data/cleric_data.gd")
const RangerData = preload("res://scripts/data/ranger_data.gd")

const CLASS_IDS_BY_DISPLAY_NAME := {"Guardian":"guardian","Cleric":"cleric","Rogue":"rogue","Ranger":"ranger","Mage":"mage","Warlock":"warlock"}

const CLASSES := {
	"Guardian":GuardianData.CLASS_DEFINITION,
	"Cleric":ClericData.CLASS_DEFINITION,
	"Rogue":{"class_id":"rogue","display_name":"Rogue","primary_role":"DPS","role":"DPS","basic_action_id":"rogue_basic_attack","trait_id":"rogue_opportunist","q_ability_id":"rogue_veiled_strike","w_ability_id":"rogue_shadowstep","e_ability_id":"rogue_fan_of_knives","heroic_option_ids":["rogue_deathmark"],"ai_behavior_tags":["damage","melee","mobile"],"talent_tier_definitions":TalentData.TIER_DEFINITIONS,"color":Color("e6b35f"),"ability":"Veiled Strike","base_health":175.0,"health_growth":0.03,"base_power":16.0,"power_growth":0.03,"base_armor":10.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.0,"basic_action_range":55.0,"movement_speed":155.0,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":0.0,"threat_modifier":1.0,"basic_action_damage_type":"physical","armor_family":"leather","armor_proficiency":"leather","weapon_proficiencies":["dual_wield","one_handed"]},
	"Ranger":RangerData.CLASS_DEFINITION,
	"Mage":{"class_id":"mage","display_name":"Mage","primary_role":"DPS","role":"DPS","basic_action_id":"mage_basic_attack","trait_id":"mage_arcane_echo","q_ability_id":"mage_arc_bolt","w_ability_id":"mage_blink","e_ability_id":"mage_arc_burst","heroic_option_ids":["mage_starfall"],"ai_behavior_tags":["damage","ranged","area"],"talent_tier_definitions":TalentData.TIER_DEFINITIONS,"color":Color("b381ff"),"ability":"Arc Burst","base_health":135.0,"health_growth":0.03,"base_power":14.0,"power_growth":0.03,"base_armor":3.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.1,"basic_action_range":190.0,"movement_speed":150.0,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":0.0,"threat_modifier":1.0,"basic_action_damage_type":"magical","armor_family":"cloth","armor_proficiency":"cloth","weapon_proficiencies":["wand","focus","staff"]},
	"Warlock":{"class_id":"warlock","display_name":"Warlock","primary_role":"DPS","role":"DPS","basic_action_id":"warlock_basic_attack","trait_id":"warlock_soulbrand","q_ability_id":"warlock_blackflame_bolt","w_ability_id":"warlock_dark_passage","e_ability_id":"warlock_withering_circle","heroic_option_ids":["warlock_soulstorm"],"ai_behavior_tags":["damage","ranged","periodic"],"talent_tier_definitions":TalentData.TIER_DEFINITIONS,"color":Color("d16ca8"),"ability":"Blackflame Bolt","base_health":145.0,"health_growth":0.03,"base_power":15.0,"power_growth":0.03,"base_armor":4.0,"basic_action_type":"attack","basic_action_power_coefficient":1.0,"basic_action_interval":1.1,"basic_action_range":185.0,"movement_speed":148.0,"base_critical_chance":0.05,"critical_damage":2.0,"health_regeneration":0.0,"threat_modifier":1.0,"basic_action_damage_type":"magical","armor_family":"cloth","armor_proficiency":"cloth","weapon_proficiencies":["wand","focus","staff"]}
}

const ABILITIES := {"Guardian":["Storm Bolt","Thunder Clap","Dwarf Toss","Avatar"],"Cleric":["Healing Brew","Cloud Serpent","Blinding Wind","Heroic Ability"],"Rogue":["Veiled Strike","Shadowstep","Fan of Knives","Deathmark"],"Ranger":["Hungering Arrow","Multishot","Vault","Heroic Ability"],"Mage":["Arc Bolt","Blink","Arc Burst","Starfall"],"Warlock":["Blackflame Bolt","Dark Passage","Withering Circle","Soulstorm"]}
const TRAITS := {"Guardian":"Second Wind","Cleric":"Fast Feet","Rogue":"Opportunist","Ranger":"Hatred","Mage":"Arcane Echo","Warlock":"Soulbrand"}
const ABILITY_TARGETING := {"Guardian":["directional","self","ground","self"],"Cleric":["self","ally","self","self"],"Rogue":["enemy","directional","area","enemy"],"Ranger":["directional","directional","ground","directional"],"Mage":["enemy","ground","area","ground"],"Warlock":["enemy","ground","ground","area"]}
const ABILITY_RANGES := {"Guardian":[390.0,0.0,235.0,0.0],"Cleric":[0.0,260.0,0.0,0.0],"Rogue":[0.0,160.0,120.0,0.0],"Ranger":[RangerData.SPACE.q_range,RangerData.SPACE.w_end_radius,RangerData.SPACE.e_range,RangerData.SPACE.rain_length],"Mage":[0.0,360.0,240.0,330.0],"Warlock":[0.0,330.0,270.0,0.0]}
const ABILITY_DESCRIPTIONS := {
	"Guardian":["Throw a physical line projectile that damages and Stuns the first enemy hit.","Damage and Slow enemies around the Guardian.","Leap to a valid location, damage nearby enemies, and gain Armor.","Use the selected Heroic: Avatar or Haymaker."],
	"Cleric":["Heal the lowest-Health wounded ally in range.","Summon a Cloud Serpent on an allied hero.","Damage, Slow, and Blind the nearest enemies.","Use the selected Heroic ability."],"Rogue":["Strike the assigned target for heavy melee damage.","Step quickly toward a chosen position.","Damage nearby enemies with thrown blades.","Mark the assigned enemy for a devastating strike."],"Ranger":["Fire a powerful shot at the assigned target.","Quickly reposition away from danger.","Damage enemies across a wide area.","Rain arrows across the battlefield."],"Mage":["Strike the assigned target with arcane power.","Blink instantly toward the chosen position.","Damage enemies surrounding the Mage.","Call down arcane energy on every enemy."],"Warlock":["Burn the assigned target with black flame.","Pass through shadow toward a chosen position.","Damage enemies inside a cursed area.","Unleash bound souls against every nearby enemy."]
}

static func class_id_for(value:String)->String:
	if value in CLASS_IDS_BY_DISPLAY_NAME:return CLASS_IDS_BY_DISPLAY_NAME[value]
	var normalized:=value.to_snake_case();return normalized if normalized in CLASS_IDS_BY_DISPLAY_NAME.values() else ""

static func class_display_name(class_id:String)->String:
	for display_name in CLASS_IDS_BY_DISPLAY_NAME:if CLASS_IDS_BY_DISPLAY_NAME[display_name]==class_id:return display_name
	return class_id.capitalize()

static func class_definition(value:String)->Dictionary:
	var display_name:=value if value in CLASSES else class_display_name(value);return CLASSES.get(display_name,{})
