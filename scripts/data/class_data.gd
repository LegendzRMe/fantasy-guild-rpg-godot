extends RefCounted

const TalentData = preload("res://scripts/data/talent_data.gd")
const GuardianData = preload("res://scripts/data/guardian_data.gd")
const ClericData = preload("res://scripts/data/cleric_data.gd")
const RangerData = preload("res://scripts/data/ranger_data.gd")
const MageData = preload("res://scripts/data/mage_data.gd")
const WarlockData = preload("res://scripts/data/warlock_data.gd")
const RogueData = preload("res://scripts/data/rogue_data.gd")
const SlayerData = preload("res://scripts/data/slayer_data.gd")
const PriestData = preload("res://scripts/data/priest_data.gd")
const ShamanData = preload("res://scripts/data/shaman_data.gd")
const TemplarData = preload("res://scripts/data/templar_data.gd")

const CLASS_IDS_BY_DISPLAY_NAME := {"Guardian":"guardian","Cleric":"cleric","Rogue":"rogue","Ranger":"ranger","Mage":"mage","Warlock":"warlock","Slayer":"slayer","Priest":"priest","Shaman":"shaman","Templar":"templar"}

const CLASSES := {
	"Guardian":GuardianData.CLASS_DEFINITION,
	"Cleric":ClericData.CLASS_DEFINITION,
	"Rogue":RogueData.CLASS_DEFINITION,
	"Ranger":RangerData.CLASS_DEFINITION,
	"Mage":MageData.CLASS_DEFINITION,
	"Warlock":WarlockData.CLASS_DEFINITION,
	"Slayer":SlayerData.CLASS_DEFINITION,
	"Priest":PriestData.CLASS_DEFINITION,
	"Shaman":ShamanData.CLASS_DEFINITION,
	"Templar":TemplarData.CLASS_DEFINITION
}

const ABILITIES := {"Guardian":["Storm Bolt","Thunder Clap","Dwarf Toss","Avatar"],"Cleric":["Healing Brew","Cloud Serpent","Blinding Wind","Heroic Ability"],"Rogue":["Sinister Strike","Blade Flurry","Eviscerate","Heroic Ability"],"Ranger":["Hungering Arrow","Multishot","Vault","Heroic Ability"],"Mage":["Flamestrike","Living Bomb","Gravity Lapse","Heroic Ability"],"Warlock":["Fel Flame","Drain Life","Corruption","Heroic Ability"],"Slayer":["Dive","Sweeping Strike","Evasion","Heroic Ability"],"Priest":["Flash Heal","Divine Star","Chastise","Heroic Ability"],"Shaman":["Chain Lightning","Feral Spirit","Windfury","Heroic Ability"],"Templar":["Blade Dash","Twin Blades","Shield Ally","Heroic Ability"]}
const TRAITS := {"Guardian":"Second Wind","Cleric":"Fast Feet","Rogue":"Vanish","Ranger":"Hatred","Mage":"Verdant Spheres","Warlock":"Life Tap","Slayer":"Betrayer's Thirst","Priest":"Pursued by Grace","Shaman":"Frostwolf Resilience","Templar":"Shield Overload"}
const ABILITY_TARGETING := {"Guardian":["directional","self","ground","self"],"Cleric":["self","ally","self","self"],"Rogue":["directional","self","enemy","self"],"Ranger":["directional","directional","ground","directional"],"Mage":["ground","enemy","directional","ground"],"Warlock":["directional","enemy","directional","ground"],"Slayer":["enemy","ground","self","ground"],"Priest":["self","directional","directional","self"],"Shaman":["enemy","directional","self","directional"],"Templar":["directional","enemy","self","ground"]}
const ABILITY_RANGES := {"Guardian":[390.0,0.0,235.0,0.0],"Cleric":[0.0,260.0,0.0,0.0],"Rogue":[134.55,75.68,50.45,0.0],"Ranger":[386.36,294.32,168.18,329.45],"Mage":[319.55,185.0,336.36,336.36],"Warlock":[353.18,235.45,336.36,336.36],"Slayer":[151.36,109.32,0.0,134.55],"Priest":[269.09,294.32,353.18,0.0],"Shaman":[390.0,390.0,0.0,405.0],"Templar":[TemplarData.SPACE.q_distance,TemplarData.SPACE.w_charge,0.0,INF]}
const ABILITY_DESCRIPTIONS := {
	"Guardian":["Throw a physical line projectile that damages and Stuns the first enemy hit.","Damage and Slow enemies around the Guardian.","Leap to a valid location, damage nearby enemies, and gain Armor.","Use the selected Heroic: Avatar or Haymaker."],
	"Cleric":["Heal the lowest-Health wounded ally in range.","Summon a Cloud Serpent on an allied hero.","Damage, Slow, and Blind the nearest enemies.","Use the selected Heroic ability."],"Rogue":["Dash toward the first enemy hit.","Damage enemies around the Rogue.","Spend Combo Points on a melee finisher.","Use Smoke Bomb or Cloak of Shadows."],"Ranger":["Fire a powerful shot at the assigned target.","Quickly reposition away from danger.","Damage enemies across a wide area.","Rain arrows across the battlefield."],"Mage":["After 1 second, damage enemies at the selected point.","Apply a periodic bomb that explodes and spreads once.","Fire a line projectile that Stuns the first enemy hit.","Use the selected Heroic: Phoenix or Pyroblast."],"Warlock":["Release an expanding wave of Fel Flame.","Channel damage and healing on a selected enemy.","Send three sequential Corruption bursts forward.","Use the selected Heroic: Horrify or Rain of Destruction."],"Slayer":["Dive through a selected enemy.","Dash through enemies and empower Basic Attacks.","Evade hostile damaging Basic Actions.","Use Metamorphosis or The Hunt."],"Priest":["After a short cast, heal the most-wounded ally in range.","Send a star outward to damage enemies and back to heal allies.","Launch a line projectile that damages and Roots enemies.","Use Holy Word: Salvation or Lightbomb."],"Shaman":["Strike one enemy and bounce lightning through nearby enemies.","Send a Rooting spirit through every enemy in its path.","Move faster and empower the next three Basic Attacks.","Use Sundering or Earthquake."],"Templar":["Dash outward and return, damaging every enemy crossed.","Charge a nearby enemy and strike twice with Basic Attacks.","Shield the closest other ally and redirect their damage threat.","Use Suppression Pulse or Purifier Beam."]
}

static func class_id_for(value:String)->String:
	if value in CLASS_IDS_BY_DISPLAY_NAME:return CLASS_IDS_BY_DISPLAY_NAME[value]
	var normalized:=value.to_snake_case();return normalized if normalized in CLASS_IDS_BY_DISPLAY_NAME.values() else ""

static func class_display_name(class_id:String)->String:
	for display_name in CLASS_IDS_BY_DISPLAY_NAME:if CLASS_IDS_BY_DISPLAY_NAME[display_name]==class_id:return display_name
	return class_id.capitalize()

static func class_definition(value:String)->Dictionary:
	var display_name:=value if value in CLASSES else class_display_name(value);return CLASSES.get(display_name,{})
