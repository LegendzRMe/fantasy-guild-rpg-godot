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
const ProtectorData = preload("res://scripts/data/protector_data.gd")
const SentinelData = preload("res://scripts/data/sentinel_data.gd")
const HuntsmanData = preload("res://scripts/data/huntsman_data.gd")
const DruidData = preload("res://scripts/data/druid_data.gd")
const WarriorData = preload("res://scripts/data/warrior_data.gd")
const DeathKnightData = preload("res://scripts/data/death_knight_data.gd")
const BeastmasterData = preload("res://scripts/data/beastmaster_data.gd")
const MonkData = preload("res://scripts/data/monk_data.gd")

const CLASS_IDS_BY_DISPLAY_NAME := {"Guardian":"guardian","Cleric":"cleric","Rogue":"rogue","Ranger":"ranger","Mage":"mage","Warlock":"warlock","Slayer":"slayer","Priest":"priest","Shaman":"shaman","Templar":"templar","Protector":"protector","Sentinel":"sentinel","Huntsman":"huntsman","Druid":"druid","Warrior":"warrior","Death Knight":"death_knight","Beastmaster":"beastmaster","Monk":"monk"}

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
	"Templar":TemplarData.CLASS_DEFINITION,
	"Protector":ProtectorData.CLASS_DEFINITION,
	"Sentinel":SentinelData.CLASS_DEFINITION,
	"Huntsman":HuntsmanData.CLASS_DEFINITION,
	"Druid":DruidData.CLASS_DEFINITION,
	"Warrior":WarriorData.CLASS_DEFINITION,
	"Death Knight":DeathKnightData.CLASS_DEFINITION,
	"Beastmaster":BeastmasterData.CLASS_DEFINITION,
	"Monk":MonkData.CLASS_DEFINITION
}

const ABILITIES := {"Guardian":["Storm Bolt","Thunder Clap","Dwarf Toss","Avatar"],"Cleric":["Healing Brew","Cloud Serpent","Blinding Wind","Heroic Ability"],"Rogue":["Sinister Strike","Blade Flurry","Eviscerate","Heroic Ability"],"Ranger":["Hungering Arrow","Multishot","Vault","Heroic Ability"],"Mage":["Flamestrike","Living Bomb","Gravity Lapse","Heroic Ability"],"Warlock":["Fel Flame","Drain Life","Corruption","Heroic Ability"],"Slayer":["Dive","Sweeping Strike","Evasion","Heroic Ability"],"Priest":["Flash Heal","Divine Star","Chastise","Heroic Ability"],"Shaman":["Chain Lightning","Feral Spirit","Windfury","Heroic Ability"],"Templar":["Blade Dash","Twin Blades","Shield Ally","Heroic Ability"],"Protector":["El'druin's Might","Force Wall","Smite","Heroic Ability"],"Sentinel":["Light of Elune","Sentinel Shot","Lunar Flare","Heroic Ability"],"Huntsman":["Gilnean Cocktail","Inner Beast","Darkflight","Heroic Ability"],"Druid":["Regrowth","Moonfire","Entangling Roots","Heroic Ability"],"Warrior":["Lion's Fang","Parry","Charge","Specialization"],"Death Knight":["Death Coil","Howling Blast","Frozen Tempest","Heroic Ability"],"Beastmaster":["Spirit Swoop","Misha, Charge!","Greater Beast","Heroic Ability"],"Monk":["Radiant Dash","Breath of Heaven","Deadly Reach","Heroic Ability"]}
const TRAITS := {"Guardian":"Second Wind","Cleric":"Fast Feet","Rogue":"Vanish","Ranger":"Hatred","Mage":"Verdant Spheres","Warlock":"Life Tap","Slayer":"Betrayer's Thirst","Priest":"Pursued by Grace","Shaman":"Frostwolf Resilience","Templar":"Shield Overload","Protector":"Archangel's Wrath","Sentinel":"Hunter's Mark","Huntsman":"Curse of the Worgen","Druid":"Innervate","Warrior":"Heroic Strike","Death Knight":"Frostmourne Hungers","Beastmaster":"Misha, Focus!","Monk":"Chosen Trait"}
const ABILITY_TARGETING := {"Guardian":["directional","self","ground","self"],"Cleric":["self","ally","self","self"],"Rogue":["directional","self","enemy","self"],"Ranger":["directional","directional","ground","directional"],"Mage":["ground","enemy","directional","ground"],"Warlock":["directional","enemy","directional","ground"],"Slayer":["enemy","ground","self","ground"],"Priest":["self","directional","directional","self"],"Shaman":["enemy","directional","self","directional"],"Templar":["directional","enemy","self","ground"],"Protector":["ground","ground","ground","enemy"],"Sentinel":["self","directional","ground","ground"],"Huntsman":["directional","self","enemy","enemy"],"Druid":["ally","ground","ground","self"],"Warrior":["directional","self","enemy","enemy"],"Death Knight":["enemy","ground","self","directional"],"Beastmaster":["directional","directional","self","directional"],"Monk":["enemy","self","self","ally"]}
const ABILITY_RANGES := {"Guardian":[390.0,0.0,235.0,0.0],"Cleric":[0.0,260.0,0.0,0.0],"Rogue":[134.55,75.68,50.45,0.0],"Ranger":[386.36,294.32,168.18,329.45],"Mage":[319.55,185.0,336.36,336.36],"Warlock":[353.18,235.45,336.36,336.36],"Slayer":[151.36,109.32,0.0,134.55],"Priest":[269.09,294.32,353.18,0.0],"Shaman":[390.0,390.0,0.0,405.0],"Templar":[TemplarData.SPACE.q_distance,TemplarData.SPACE.w_charge,0.0,INF],"Protector":[ProtectorData.SPACE.q_range,ProtectorData.SPACE.w_range,ProtectorData.SPACE.e_range,ProtectorData.SPACE.r1_range],"Sentinel":[0.0,SentinelData.SPACE.w_range,SentinelData.SPACE.e_range,SentinelData.SPACE.e_range],"Huntsman":[HuntsmanData.SPACE.cocktail_range,0.0,HuntsmanData.SPACE.darkflight_range,HuntsmanData.SPACE.heroic_range],"Druid":[DruidData.SPACE.regrowth_range,DruidData.SPACE.moonfire_range,DruidData.SPACE.roots_range,DruidData.SPACE.twilight_radius],"Warrior":[WarriorData.SPACE.lions_fang_range,0.0,WarriorData.SPACE.charge_range,WarriorData.SPACE.colossus_range],"Death Knight":[DeathKnightData.SPACE.death_coil_range,DeathKnightData.SPACE.howling_range,0.0,DeathKnightData.SPACE.sindragosa_range],"Beastmaster":[BeastmasterData.SPACE.swoop_length,BeastmasterData.SPACE.charge_length,0.0,BeastmasterData.SPACE.boar_range],"Monk":[MonkData.SPACE.dash_range,0.0,0.0,MonkData.SPACE.palm_range]}
const ABILITY_DESCRIPTIONS := {
	"Monk":["Dash to an eligible allied anchor or enemy. Allied Dash triggers ready Breath; enemy Dash triggers ready Reach before its attack.","Passive cooldown: automatically triggers from allied Radiant Dash.","Passive cooldown: automatically triggers before an enemy Radiant Dash attack.","Use Divine Palm or Seven-Sided Strike."],
	"Guardian":["Throw a physical line projectile that damages and Stuns the first enemy hit.","Damage and Slow enemies around the Guardian.","Leap to a valid location, damage nearby enemies, and gain Armor.","Use the selected Heroic: Avatar or Haymaker."],
	"Warrior":["Send a shockwave through enemies, damaging, Slowing, and healing per eligible contact.","Parry hostile Basic Attacks using two charges.","Charge a hostile target or an ally with Warbringer.","Use Taunt or Colossus Smash; Twin Blades is passive."],
	"Death Knight":["Damage a hostile target or manually self-cast to heal.","Damage and Root a ground-targeted area.","Toggle an unlimited suppression aura that normally locks other abilities.","Use Army of the Dead or Summon Sindragosa."],
	"Beastmaster":["Send Spirit Swoop and create a Lesser Beast at its safe endpoint.","Command Misha to Charge through enemies.","Summon a Greater Beast at Misha's position.","Use Bestial Wrath or Unleash the Boars."],
	"Cleric":["Heal the lowest-Health wounded ally in range.","Summon a Cloud Serpent on an allied hero.","Damage, Slow, and Blind the nearest enemies.","Use the selected Heroic ability."],"Rogue":["Dash toward the first enemy hit.","Damage enemies around the Rogue.","Spend Combo Points on a melee finisher.","Use Smoke Bomb or Cloak of Shadows."],"Ranger":["Fire a powerful shot at the assigned target.","Quickly reposition away from danger.","Damage enemies across a wide area.","Rain arrows across the battlefield."],"Mage":["After 1 second, damage enemies at the selected point.","Apply a periodic bomb that explodes and spreads once.","Fire a line projectile that Stuns the first enemy hit.","Use the selected Heroic: Phoenix or Pyroblast."],"Warlock":["Release an expanding wave of Fel Flame.","Channel damage and healing on a selected enemy.","Send three sequential Corruption bursts forward.","Use the selected Heroic: Horrify or Rain of Destruction."],"Slayer":["Dive through a selected enemy.","Dash through enemies and empower Basic Attacks.","Evade hostile damaging Basic Actions.","Use Metamorphosis or The Hunt."],"Priest":["After a short cast, heal the most-wounded ally in range.","Send a star outward to damage enemies and back to heal allies.","Launch a line projectile that damages and Roots enemies.","Use Holy Word: Salvation or Lightbomb."],"Shaman":["Strike one enemy and bounce lightning through nearby enemies.","Send a Rooting spirit through every enemy in its path.","Move faster and empower the next three Basic Attacks.","Use Sundering or Earthquake."],"Templar":["Dash outward and return, damaging every enemy crossed.","Charge a nearby enemy and strike twice with Basic Attacks.","Shield the closest other ally and redirect their damage threat.","Use Suppression Pulse or Purifier Beam."],"Protector":["Throw El'druin, then recast to teleport to it.","Create temporary movement-blocking terrain.","Damage enemies and create an allied movement field.","Use Judgment or Sanctification."],"Sentinel":["Heal the lowest-Health allied Hero in range.","Fire a long-range projectile whose damage grows with travel.","Call down a delayed Stunning flare.","Use Shadowstalk or Starfall."],"Huntsman":["Fire Gilnean Cocktail or lunge with Razor Swipe.","Gain Attack Speed with Inner Beast.","Use Darkflight or Disengage to change form.","Use Go for the Throat or Marked for the Kill."],"Druid":["Maintain Regrowth on a selected ally.","Damage and Reveal an area, healing every own-Regrowth ally.","Grow a Rooting area over three seconds.","Use Tranquility or Twilight Dream."]
}

static func class_id_for(value:String)->String:
	if value in CLASS_IDS_BY_DISPLAY_NAME:return CLASS_IDS_BY_DISPLAY_NAME[value]
	var normalized:=value.to_snake_case();return normalized if normalized in CLASS_IDS_BY_DISPLAY_NAME.values() else ""

static func class_display_name(class_id:String)->String:
	for display_name in CLASS_IDS_BY_DISPLAY_NAME:if CLASS_IDS_BY_DISPLAY_NAME[display_name]==class_id:return display_name
	return class_id.capitalize()

static func class_definition(value:String)->Dictionary:
	var display_name:=value if value in CLASSES else class_display_name(value);return CLASSES.get(display_name,{})
