extends RefCounted

const TalentData = preload("res://scripts/data/talent_data.gd")
const GuardianData = preload("res://scripts/data/guardian_data.gd")
const ClericData = preload("res://scripts/data/cleric_data.gd")
const RangerData = preload("res://scripts/data/ranger_data.gd")
const MageData = preload("res://scripts/data/mage_data.gd")
const WarlockData = preload("res://scripts/data/warlock_data.gd")
const RogueData = preload("res://scripts/data/rogue_data.gd")

const CLASS_IDS_BY_DISPLAY_NAME := {"Guardian":"guardian","Cleric":"cleric","Rogue":"rogue","Ranger":"ranger","Mage":"mage","Warlock":"warlock"}

const CLASSES := {
	"Guardian":GuardianData.CLASS_DEFINITION,
	"Cleric":ClericData.CLASS_DEFINITION,
	"Rogue":RogueData.CLASS_DEFINITION,
	"Ranger":RangerData.CLASS_DEFINITION,
	"Mage":MageData.CLASS_DEFINITION,
	"Warlock":WarlockData.CLASS_DEFINITION
}

const ABILITIES := {"Guardian":["Storm Bolt","Thunder Clap","Dwarf Toss","Avatar"],"Cleric":["Healing Brew","Cloud Serpent","Blinding Wind","Heroic Ability"],"Rogue":["Sinister Strike","Blade Flurry","Eviscerate","Heroic Ability"],"Ranger":["Hungering Arrow","Multishot","Vault","Heroic Ability"],"Mage":["Flamestrike","Living Bomb","Gravity Lapse","Heroic Ability"],"Warlock":["Fel Flame","Drain Life","Corruption","Heroic Ability"]}
const TRAITS := {"Guardian":"Second Wind","Cleric":"Fast Feet","Rogue":"Vanish","Ranger":"Hatred","Mage":"Verdant Spheres","Warlock":"Life Tap"}
const ABILITY_TARGETING := {"Guardian":["directional","self","ground","self"],"Cleric":["self","ally","self","self"],"Rogue":["directional","self","enemy","self"],"Ranger":["directional","directional","ground","directional"],"Mage":["ground","enemy","directional","ground"],"Warlock":["directional","enemy","directional","ground"]}
const ABILITY_RANGES := {"Guardian":[390.0,0.0,235.0,0.0],"Cleric":[0.0,260.0,0.0,0.0],"Rogue":[RogueData.SPACE.sinister_range,RogueData.SPACE.blade_radius,RogueData.SPACE.opener_range,0.0],"Ranger":[RangerData.SPACE.q_range,RangerData.SPACE.w_end_radius,RangerData.SPACE.e_range,RangerData.SPACE.rain_length],"Mage":[MageData.SPACE.q_cast_range,MageData.SPACE.w_cast_range,MageData.SPACE.e_range,MageData.SPACE.phoenix_cast_range],"Warlock":[WarlockData.SPACE.q_range,WarlockData.SPACE.w_cast_range,WarlockData.SPACE.e_range,WarlockData.SPACE.horrify_range]}
const ABILITY_DESCRIPTIONS := {
	"Guardian":["Throw a physical line projectile that damages and Stuns the first enemy hit.","Damage and Slow enemies around the Guardian.","Leap to a valid location, damage nearby enemies, and gain Armor.","Use the selected Heroic: Avatar or Haymaker."],
	"Cleric":["Heal the lowest-Health wounded ally in range.","Summon a Cloud Serpent on an allied hero.","Damage, Slow, and Blind the nearest enemies.","Use the selected Heroic ability."],"Rogue":["Dash toward the first enemy hit.","Damage enemies around the Rogue.","Spend Combo Points on a melee finisher.","Use Smoke Bomb or Cloak of Shadows."],"Ranger":["Fire a powerful shot at the assigned target.","Quickly reposition away from danger.","Damage enemies across a wide area.","Rain arrows across the battlefield."],"Mage":["After 1 second, damage enemies at the selected point.","Apply a periodic bomb that explodes and spreads once.","Fire a line projectile that Stuns the first enemy hit.","Use the selected Heroic: Phoenix or Pyroblast."],"Warlock":["Release an expanding wave of Fel Flame.","Channel damage and healing on a selected enemy.","Send three sequential Corruption bursts forward.","Use the selected Heroic: Horrify or Rain of Destruction."]
}

static func class_id_for(value:String)->String:
	if value in CLASS_IDS_BY_DISPLAY_NAME:return CLASS_IDS_BY_DISPLAY_NAME[value]
	var normalized:=value.to_snake_case();return normalized if normalized in CLASS_IDS_BY_DISPLAY_NAME.values() else ""

static func class_display_name(class_id:String)->String:
	for display_name in CLASS_IDS_BY_DISPLAY_NAME:if CLASS_IDS_BY_DISPLAY_NAME[display_name]==class_id:return display_name
	return class_id.capitalize()

static func class_definition(value:String)->Dictionary:
	var display_name:=value if value in CLASSES else class_display_name(value);return CLASSES.get(display_name,{})
