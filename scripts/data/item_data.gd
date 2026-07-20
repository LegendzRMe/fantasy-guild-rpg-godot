extends RefCounted

const EQUIPMENT_SLOTS := ["weapon","head","chest","hands","neck","trinket"]
const ARMOR_SLOTS := ["head","chest","hands"]
const ARMOR_FAMILIES := ["cloth","leather","mail","plate"]
const WEAPON_FAMILIES := ["dual_wield","one_handed","two_handed","weapon_and_shield","bow","crossbow","firearm","wand","focus","staff"]
const RARITIES := ["Poor","Common","Uncommon","Rare","Epic","Legendary"]
const RARITY_COLORS := {"Poor":"777d89","Common":"e9f1ff","Uncommon":"54d69a","Rare":"5fa8ff","Epic":"b381ff","Legendary":"e69a45"}
const TESTING_DEFINITION_IDS := ["test_ashfang_knives","test_stormbreaker","test_crown_twin_incantations","test_aegis_last_dawn","test_mantle_overflowing_grace","test_gloves_thousand_cuts","test_gauntlets_retribution","test_pendant_endless_momentum","test_mirror_borrowed_time","test_soul_furnace"]
const LEGACY_TEST_INSTANCE_IDS := ["test_ashwood_bulwark","test_cinderlight_focus","test_marchwarden_grips"]

const PASSIVE_EFFECTS := {
	"grace":{"id":"grace","display_name":"Grace","description":"Direct critical heals, including Basic Heals, restore a small additional amount of Health.","trigger":"direct_healing_done","chance":1.0,"internal_cooldown":0.0,"required_tags":["critical"],"excluded_tags":["periodic"],"effect_result":{"category":"healing","amount":4.0},"duration":0.0,"maximum_stacks":1,"stacking_rule":"strongest_refresh"},
	"marchwarden_retaliation":{"id":"marchwarden_retaliation","display_name":"Retaliation","description":"After taking Physical Damage, the next Basic Attack deals bonus Physical Damage.","trigger":"damage_taken","chance":1.0,"internal_cooldown":5.0,"required_tags":["physical"],"excluded_tags":[],"effect_result":{"category":"buff","id":"retaliation_ready","amount":6.0,"consume_on":"basic_attack"},"duration":0.0,"maximum_stacks":1,"stacking_rule":"strongest_refresh"},
	"bloodletting":{"id":"bloodletting","display_name":"Bloodletting","description":"Basic Attacks have a 35% chance to inflict 30 Periodic Physical Damage over four seconds, stacking five times.","trigger":"basic_attack_hit","chance":0.35,"internal_cooldown":0.0,"required_tags":["basic_attack"],"excluded_tags":["periodic"],"effect_result":{"category":"debuff","id":"bloodletting","total_damage":30.0,"ticks":4,"damage_type":"physical","can_crit":true},"duration":4.0,"maximum_stacks":5,"stacking_rule":"independent_stacks"},
	"thunder_wake":{"id":"thunder_wake","display_name":"Thunder Wake","description":"Basic Attacks explode around the target for equal Magical Damage without striking that target twice, and make nearby enemies Vulnerable for four seconds.","trigger":"basic_attack_hit","chance":1.0,"internal_cooldown":0.0,"required_tags":["basic_attack"],"excluded_tags":[],"effect_result":{"category":"damage","id":"thunder_wake","damage_type":"magical","radius":145.0,"vulnerable":0.15},"duration":4.0,"maximum_stacks":1,"stacking_rule":"refresh"},
	"twin_incantation":{"id":"twin_incantation","display_name":"Twin Incantation","description":"Q stores two independently recharging charges. Casting E restores one missing Q charge.","trigger":"basic_ability_cast","chance":1.0,"internal_cooldown":0.0,"required_tags":[],"excluded_tags":[],"effect_result":{"category":"buff","id":"twin_incantation"},"duration":0.0,"maximum_stacks":2,"stacking_rule":"charges"},
	"last_dawn":{"id":"last_dawn","display_name":"Last Dawn","description":"Crossing below 50% Health grants a Shield equal to 75% maximum Health and 50% Power while that Shield remains.","trigger":"damage_taken","chance":1.0,"internal_cooldown":15.0,"required_tags":[],"excluded_tags":[],"effect_result":{"category":"shield","id":"last_dawn","max_health_coefficient":0.75,"power_multiplier":1.5},"duration":0.0,"maximum_stacks":1,"stacking_rule":"source_shield"},
	"overflowing_grace":{"id":"overflowing_grace","display_name":"Overflowing Grace","description":"Overhealing becomes a Shield, doubled by direct critical healing, up to 60% of the target's maximum Health.","trigger":"overhealing_done","chance":1.0,"internal_cooldown":0.0,"required_tags":[],"excluded_tags":[],"effect_result":{"category":"shield","id":"overflowing_grace","shield_cap":0.60,"critical_multiplier":2.0},"duration":0.0,"maximum_stacks":1,"stacking_rule":"add_to_cap"},
	"thousand_cuts":{"id":"thousand_cuts","display_name":"Thousand Cuts","description":"Every third Basic Attack triggers two extra strikes for 60% damage each.","trigger":"basic_attack_hit","chance":1.0,"internal_cooldown":0.0,"required_tags":["basic_attack"],"excluded_tags":[],"effect_result":{"category":"damage","id":"thousand_cuts","strike_count":2,"damage_multiplier":0.60},"duration":0.0,"maximum_stacks":3,"stacking_rule":"counter"},
	"retribution":{"id":"retribution","display_name":"Retribution","description":"Physical Damage stores 50% of the resolved amount in up to three charges. Basic Attacks consume the oldest as bonus True Damage.","trigger":"damage_taken","chance":1.0,"internal_cooldown":0.0,"required_tags":["physical"],"excluded_tags":[],"effect_result":{"category":"buff","id":"retribution","stored_multiplier":0.50,"damage_type":"true"},"duration":0.0,"maximum_stacks":3,"stacking_rule":"charges"},
	"endless_momentum":{"id":"endless_momentum","display_name":"Endless Momentum","description":"Critical damage or healing reduces Q, W, and E cooldowns by one second and R by 0.25 seconds.","trigger":"critical_result","chance":1.0,"internal_cooldown":0.0,"required_tags":["critical"],"excluded_tags":[],"effect_result":{"category":"buff","id":"endless_momentum"},"duration":0.0,"maximum_stacks":1,"stacking_rule":"none"},
	"borrowed_time":{"id":"borrowed_time","display_name":"Borrowed Time","description":"Every eight seconds, the next Basic Ability repeats after 0.4 seconds without consuming a cooldown or charge.","trigger":"basic_ability_cast","chance":1.0,"internal_cooldown":8.0,"required_tags":["basic_ability"],"excluded_tags":[],"effect_result":{"category":"buff","id":"borrowed_time","repeat_delay":0.4},"duration":0.0,"maximum_stacks":1,"stacking_rule":"armed"},
	"soul_furnace":{"id":"soul_furnace","display_name":"Soul Furnace","description":"Enemy defeats grant battle-only stacks of 5% Power and 5% Basic Action Speed.","trigger":"unit_defeated","chance":1.0,"internal_cooldown":0.0,"required_tags":[],"excluded_tags":[],"effect_result":{"category":"buff","id":"soul_furnace","power_per_stack":0.05,"speed_per_stack":0.05},"duration":0.0,"maximum_stacks":0,"stacking_rule":"unlimited"}
}

const ITEMS := {
	"pinewatch_bow":{"definition_id":"pinewatch_bow","display_name":"Pinewatch Bow","slot":"weapon","tier":1,"rarity":"Common","armor_family_requirement":"","weapon_family_requirement":"bow","allowed_classes":["Ranger"],"stat_modifiers":{"power":2.0},"passive_effect_ids":[],"icon_path":"res://assets/items/pinewatch_bow.png","fallback_icon_type":"bow","testing_only":false},
	"pilgrims_vestment":{"definition_id":"pilgrims_vestment","display_name":"Pilgrim's Vestment","slot":"chest","tier":1,"rarity":"Common","armor_family_requirement":"mail","weapon_family_requirement":"","allowed_classes":["Cleric"],"stat_modifiers":{"armor":6.0},"passive_effect_ids":[],"icon_path":"res://assets/items/pilgrims_vestment.png","fallback_icon_type":"chest","testing_only":false},
	"marchwarden_plate":{"definition_id":"marchwarden_plate","display_name":"Marchwarden Plate","slot":"chest","tier":1,"rarity":"Rare","armor_family_requirement":"plate","weapon_family_requirement":"","allowed_classes":["Guardian"],"stat_modifiers":{"armor":18.0},"passive_effect_ids":[],"icon_path":"res://assets/items/marchwarden_plate.png","fallback_icon_type":"chest","testing_only":false},
	"ashwood_bulwark":{"definition_id":"ashwood_bulwark","display_name":"Ashwood Bulwark","slot":"chest","tier":1,"rarity":"Common","armor_family_requirement":"plate","weapon_family_requirement":"","stat_modifiers":{"armor":20.0},"passive_effect_ids":[],"icon_path":"res://assets/items/ashwood_bulwark.png","fallback_icon_type":"chest","testing_only":false},
	"cinderlight_focus":{"definition_id":"cinderlight_focus","display_name":"Cinderlight Focus","slot":"weapon","tier":1,"rarity":"Uncommon","armor_family_requirement":"","weapon_family_requirement":"focus","stat_modifiers":{"power":3.0,"critical_chance":0.08},"passive_effect_ids":["grace"],"icon_path":"res://assets/items/cinderlight_focus.png","fallback_icon_type":"focus","testing_only":false},
	"marchwarden_grips":{"definition_id":"marchwarden_grips","display_name":"Marchwarden Grips","slot":"hands","tier":1,"rarity":"Uncommon","armor_family_requirement":"plate","weapon_family_requirement":"","stat_modifiers":{"armor":12.0},"passive_effect_ids":["marchwarden_retaliation"],"icon_path":"res://assets/items/marchwarden_grips.png","fallback_icon_type":"hands","testing_only":false},
	"test_ashfang_knives":{"definition_id":"test_ashfang_knives","display_name":"Ashfang Knives","slot":"weapon","tier":9,"rarity":"Legendary","armor_family_requirement":"","weapon_family_requirement":"dual_wield","stat_modifiers":{"power":25.0,"critical_chance":0.20},"passive_effect_ids":["bloodletting"],"icon_path":"res://assets/items/test_ashfang_knives.png","fallback_icon_type":"dual_wield","testing_only":true},
	"test_stormbreaker":{"definition_id":"test_stormbreaker","display_name":"Stormbreaker","slot":"weapon","tier":9,"rarity":"Legendary","armor_family_requirement":"","weapon_family_requirement":"two_handed","testing_allowed_classes":["Guardian"],"stat_modifiers":{"power":40.0},"passive_effect_ids":["thunder_wake"],"icon_path":"res://assets/items/test_stormbreaker.png","fallback_icon_type":"two_handed","testing_only":true},
	"test_crown_twin_incantations":{"definition_id":"test_crown_twin_incantations","display_name":"Crown of Twin Incantations","slot":"head","tier":9,"rarity":"Legendary","armor_family_requirement":["cloth","mail"],"weapon_family_requirement":"","stat_modifiers":{"critical_chance":0.10},"passive_effect_ids":["twin_incantation"],"icon_path":"res://assets/items/test_crown_twin_incantations.png","fallback_icon_type":"head","testing_only":true},
	"test_aegis_last_dawn":{"definition_id":"test_aegis_last_dawn","display_name":"Aegis of the Last Dawn","slot":"chest","tier":9,"rarity":"Legendary","armor_family_requirement":"plate","weapon_family_requirement":"","stat_modifiers":{"armor":45.0,"health_multiplier":1.20},"passive_effect_ids":["last_dawn"],"icon_path":"res://assets/items/test_aegis_last_dawn.png","fallback_icon_type":"chest","testing_only":true},
	"test_mantle_overflowing_grace":{"definition_id":"test_mantle_overflowing_grace","display_name":"Mantle of Overflowing Grace","slot":"chest","tier":9,"rarity":"Legendary","armor_family_requirement":"mail","weapon_family_requirement":"","stat_modifiers":{"power":20.0,"critical_chance":0.15},"passive_effect_ids":["overflowing_grace"],"icon_path":"res://assets/items/test_mantle_overflowing_grace.png","fallback_icon_type":"chest","testing_only":true},
	"test_gloves_thousand_cuts":{"definition_id":"test_gloves_thousand_cuts","display_name":"Gloves of a Thousand Cuts","slot":"hands","tier":9,"rarity":"Legendary","armor_family_requirement":"leather","weapon_family_requirement":"","stat_modifiers":{"basic_action_speed":0.25},"passive_effect_ids":["thousand_cuts"],"icon_path":"res://assets/items/test_gloves_thousand_cuts.png","fallback_icon_type":"hands","testing_only":true},
	"test_gauntlets_retribution":{"definition_id":"test_gauntlets_retribution","display_name":"Gauntlets of Retribution","slot":"hands","tier":9,"rarity":"Legendary","armor_family_requirement":"plate","weapon_family_requirement":"","stat_modifiers":{"armor":15.0},"passive_effect_ids":["retribution"],"icon_path":"res://assets/items/test_gauntlets_retribution.png","fallback_icon_type":"hands","testing_only":true},
	"test_pendant_endless_momentum":{"definition_id":"test_pendant_endless_momentum","display_name":"Pendant of Endless Momentum","slot":"neck","tier":9,"rarity":"Legendary","armor_family_requirement":"","weapon_family_requirement":"","stat_modifiers":{"critical_chance":0.20},"passive_effect_ids":["endless_momentum"],"icon_path":"res://assets/items/test_pendant_endless_momentum.png","fallback_icon_type":"neck","testing_only":true},
	"test_mirror_borrowed_time":{"definition_id":"test_mirror_borrowed_time","display_name":"Mirror of Borrowed Time","slot":"trinket","tier":9,"rarity":"Legendary","armor_family_requirement":"","weapon_family_requirement":"","stat_modifiers":{},"passive_effect_ids":["borrowed_time"],"icon_path":"res://assets/items/test_mirror_borrowed_time.png","fallback_icon_type":"trinket","testing_only":true},
	"test_soul_furnace":{"definition_id":"test_soul_furnace","display_name":"Soul Furnace","slot":"trinket","tier":9,"rarity":"Legendary","armor_family_requirement":"","weapon_family_requirement":"","stat_modifiers":{},"passive_effect_ids":["soul_furnace"],"icon_path":"res://assets/items/test_soul_furnace.png","fallback_icon_type":"trinket","testing_only":true}
}

static func empty_equipment_slots()->Dictionary:
	return {"weapon":null,"head":null,"chest":null,"hands":null,"neck":null,"trinket":null}

static func create_instance(definition_id:String,instance_id:String)->Dictionary:
	var definition:Dictionary=ITEMS.get(definition_id,{})
	var slot:String=str(definition.get("slot",""));var weapon_family:String=str(definition.get("weapon_family_requirement",definition.get("weapon_proficiency_requirement","")))
	return {"instance_id":instance_id,"definition_id":definition_id,"display_name":definition.get("display_name",definition_id),"slot":slot,"tier":definition.get("tier",1),"rarity":definition.get("rarity","Common"),"armor_family_requirement":definition.get("armor_family_requirement",""),"weapon_family_requirement":weapon_family,"allowed_classes":definition.get("allowed_classes",definition.get("testing_allowed_classes",[])).duplicate(),"stat_modifiers":definition.get("stat_modifiers",{}).duplicate(true),"passive_effect_ids":definition.get("passive_effect_ids",[]).duplicate(),"icon_path":definition.get("icon_path",""),"fallback_icon_type":definition.get("fallback_icon_type",weapon_family if slot=="weapon" and weapon_family!="" else slot),"testing_only":bool(definition.get("testing_only",false)),"owner_state":"vault","equipped_hero_index":-1}

static func testing_instances()->Array:
	var result:Array=[]
	for definition_id in TESTING_DEFINITION_IDS:result.append(create_instance(definition_id,"testing_%s"%definition_id))
	return result

static func seed_testing_instances(existing:Array)->Array:
	var result:Array=[];var definitions:Dictionary={}
	for existing_item in existing:
		var definition_id:String=str(existing_item.get("definition_id",""))
		if definition_id in TESTING_DEFINITION_IDS and definitions.has(definition_id):
			var kept_index:int=int(definitions[definition_id]);var kept_item:Dictionary=result[kept_index]
			if str(kept_item.get("owner_state","vault"))!="equipped" and str(existing_item.get("owner_state","vault"))=="equipped":result[kept_index]=existing_item.duplicate(true)
			continue
		result.append(existing_item.duplicate(true))
		if definition_id in TESTING_DEFINITION_IDS:definitions[definition_id]=result.size()-1
	for definition_id in TESTING_DEFINITION_IDS:
		if not definitions.has(definition_id):result.append(create_instance(definition_id,"testing_%s"%definition_id))
	return result

static func definition_for_instance(item_instance:Dictionary)->Dictionary:
	return ITEMS.get(str(item_instance.get("definition_id","")),item_instance)

static func compatibility_reason(item:Dictionary,class_definition:Dictionary,hero_class:String="")->String:
	var definition:Dictionary=definition_for_instance(item);var slot:String=str(definition.get("slot",""))
	if slot not in EQUIPMENT_SLOTS:return "Unsupported equipment slot"
	var allowed_classes:Array=definition.get("allowed_classes",definition.get("testing_allowed_classes",[]))
	if not allowed_classes.is_empty() and hero_class not in allowed_classes:return "Only %s can equip this item"%" or ".join(allowed_classes)
	if slot in ARMOR_SLOTS:
		var requirement=definition.get("armor_family_requirement","");var allowed:Array=requirement if requirement is Array else [str(requirement)] if str(requirement)!="" else []
		if not allowed.is_empty() and str(class_definition.get("armor_family","")) not in allowed:return "Requires %s armor"%" or ".join(allowed.map(func(value):return str(value).capitalize()))
	if slot=="weapon":
		var weapon_family:String=str(definition.get("weapon_family_requirement",definition.get("weapon_proficiency_requirement","")))
		if weapon_family!="" and weapon_family not in class_definition.get("weapon_proficiencies",[]):return "Requires %s proficiency"%weapon_family.replace("_"," ").capitalize()
	return ""

static func can_equip(item:Dictionary,class_definition:Dictionary,hero_class:String="")->bool:
	return compatibility_reason(item,class_definition,hero_class)==""

static func equipped_instances(hero:Dictionary,item_instances:Array)->Array:
	var by_id:Dictionary={};var result:Array=[]
	for item in item_instances:by_id[str(item.get("instance_id",""))]=item
	var slots:Dictionary=hero.get("equipment_slots",{})
	for slot in EQUIPMENT_SLOTS:
		var instance_id=slots.get(slot,null)
		if instance_id!=null and by_id.has(str(instance_id)):result.append(by_id[str(instance_id)])
	return result

static func item_by_instance_id(item_instances:Array,instance_id:String)->Dictionary:
	for item in item_instances:if str(item.get("instance_id",""))==instance_id:return item
	return {}

static func reconcile_ownership(state:Dictionary)->void:
	for item in state.get("item_instances",[]):item["owner_state"]="vault";item["equipped_hero_index"]=-1
	var claimed_instances:Dictionary={}
	for hero_index in state.get("heroes",[]).size():
		var hero:Dictionary=state.heroes[hero_index]
		for slot in EQUIPMENT_SLOTS:
			var instance_id=hero.get("equipment_slots",{}).get(slot,null)
			if instance_id==null:continue
			if claimed_instances.has(str(instance_id)):hero.equipment_slots[slot]=null;continue
			var item:=item_by_instance_id(state.item_instances,str(instance_id))
			if item.is_empty():hero.equipment_slots[slot]=null
			else:claimed_instances[str(instance_id)]=true;item.owner_state="equipped";item.equipped_hero_index=hero_index

static func equip_in_state(state:Dictionary,hero_index:int,instance_id:String,classes:Dictionary)->Dictionary:
	if hero_index<0 or hero_index>=state.heroes.size():return {"success":false,"reason":"Invalid hero"}
	var item:=item_by_instance_id(state.get("item_instances",[]),instance_id)
	if item.is_empty():return {"success":false,"reason":"Item is not in the Vault"}
	var hero:Dictionary=state.heroes[hero_index];var reason:String=compatibility_reason(item,classes[hero["class"]],str(hero["class"]))
	if reason!="":return {"success":false,"reason":reason}
	var slot:String=str(item.slot);var replaced_id=hero.equipment_slots.get(slot,null);var previous_owner:int=int(item.get("equipped_hero_index",-1))
	if previous_owner>=0 and previous_owner<state.heroes.size():
		for previous_slot in EQUIPMENT_SLOTS:
			if str(state.heroes[previous_owner].equipment_slots.get(previous_slot,""))==instance_id:state.heroes[previous_owner].equipment_slots[previous_slot]=null
	if replaced_id!=null:
		var replaced:=item_by_instance_id(state.item_instances,str(replaced_id))
		if not replaced.is_empty():replaced.owner_state="vault";replaced.equipped_hero_index=-1
	hero.equipment_slots[slot]=instance_id;item.owner_state="equipped";item.equipped_hero_index=hero_index
	return {"success":true,"reason":"","replaced_instance_id":replaced_id,"previous_owner":previous_owner}

static func unequip_from_state(state:Dictionary,hero_index:int,slot:String)->Dictionary:
	if hero_index<0 or hero_index>=state.heroes.size() or slot not in EQUIPMENT_SLOTS:return {"success":false}
	var instance_id=state.heroes[hero_index].equipment_slots.get(slot,null)
	if instance_id==null:return {"success":true,"instance_id":null}
	state.heroes[hero_index].equipment_slots[slot]=null;var item:=item_by_instance_id(state.item_instances,str(instance_id))
	if not item.is_empty():item.owner_state="vault";item.equipped_hero_index=-1
	return {"success":true,"instance_id":instance_id}

static func item_tooltip(item:Dictionary)->String:
	var definition:Dictionary=definition_for_instance(item);var slot:String=str(definition.get("slot","")).capitalize();var family:String=str(definition.get("weapon_family_requirement",""))
	var lines:Array=[str(definition.get("display_name","Item")).to_upper(),"Tier %s - %s"%[roman_tier(int(definition.get("tier",1))),definition.get("rarity","Common")],slot+(" - "+family.replace("_"," ").capitalize() if family!="" else "")]
	var armor_requirement=definition.get("armor_family_requirement","")
	if armor_requirement is Array and not armor_requirement.is_empty():lines.append("Requires %s Armor"%" or ".join(armor_requirement))
	elif str(armor_requirement)!="":lines.append("Requires %s Armor"%str(armor_requirement).capitalize())
	lines.append("")
	for stat in definition.get("stat_modifiers",{}):
		var value:float=float(definition.stat_modifiers[stat]);var is_percent:String="%" if str(stat).ends_with("_multiplier") or str(stat) in ["critical_chance","basic_action_speed"] else ""
		var shown_value:String=str(int(round((value-1.0)*100.0))) if str(stat).ends_with("_multiplier") else str(int(round(value*100.0))) if is_percent=="%" else str(int(round(value)))
		lines.append("+%s%s %s"%[shown_value,is_percent,str(stat).trim_suffix("_multiplier").replace("_"," ").capitalize()])
	for passive_id in definition.get("passive_effect_ids",[]):
		var passive:Dictionary=PASSIVE_EFFECTS.get(passive_id,{})
		if not passive.is_empty():lines.append("");lines.append(str(passive.display_name));lines.append(str(passive.description))
	return "\n".join(lines)

static func roman_tier(tier:int)->String:
	return {1:"I",2:"II",3:"III",4:"IV",5:"V",6:"VI",7:"VII",8:"VIII",9:"IX",10:"X"}.get(tier,str(tier))

static func _stat_display(stat_name:String,value:float)->String:
	var percent_stat:=stat_name in ["critical_chance","basic_action_speed"] or stat_name.ends_with("_multiplier")
	var shown:=value*100.0 if percent_stat else value
	if stat_name.ends_with("_multiplier"):shown=(value-1.0)*100.0
	var prefix:="+" if shown>=0.0 else ""
	var shown_text:=str(int(round(shown))) if is_equal_approx(shown,round(shown)) else ("%.1f"%shown).trim_suffix("0").trim_suffix(".")
	return "%s%s%s %s"%[prefix,shown_text,"%" if percent_stat else "",stat_name.trim_suffix("_multiplier").replace("_"," ").capitalize()]

static func item_card_data(item:Dictionary,heroes:Array=[])->Dictionary:
	var definition:Dictionary=definition_for_instance(item);var passives:Array=[]
	for passive_id in definition.get("passive_effect_ids",[]):
		var passive:Dictionary=PASSIVE_EFFECTS.get(passive_id,{})
		if not passive.is_empty():passives.append({"id":passive_id,"title":passive.get("display_name",passive_id),"description":passive.get("description","")})
	var stats:Array=[]
	for stat_name in definition.get("stat_modifiers",{}):stats.append({"id":stat_name,"value":float(definition.stat_modifiers[stat_name]),"text":_stat_display(str(stat_name),float(definition.stat_modifiers[stat_name]))})
	var owner_index:=int(item.get("equipped_hero_index",-1));var owner_name:="";var owner_class:=""
	if owner_index>=0 and owner_index<heroes.size():owner_name=str(heroes[owner_index].get("name","Hero"));owner_class=str(heroes[owner_index].get("class",""))
	var slot:=str(definition.get("slot",""));var weapon_family:=str(definition.get("weapon_family_requirement",""))
	return {"kind":"equipment","instance_id":item.get("instance_id",""),"definition_id":item.get("definition_id",""),"display_name":definition.get("display_name","Item"),"tier":int(definition.get("tier",1)),"tier_text":"Tier %s"%roman_tier(int(definition.get("tier",1))),"rarity":definition.get("rarity","Common"),"slot":slot,"slot_text":slot.capitalize(),"armor_family_requirement":definition.get("armor_family_requirement",""),"weapon_family_requirement":weapon_family,"icon_path":definition.get("icon_path",item.get("icon_path","")),"fallback_icon_type":definition.get("fallback_icon_type",item.get("fallback_icon_type",weapon_family if slot=="weapon" else slot)),"stats":stats,"passives":passives,"owner_index":owner_index,"owner_name":owner_name,"owner_class":owner_class,"status":"Equipped by %s  •  %s"%[owner_name,owner_class] if owner_name!="" else "Stored in Guild Vault"}

static func legacy_ashwood_instance(legacy_item:Dictionary)->Dictionary:
	var display_name:=str(legacy_item.get("name","Ashwood Item"));var definition_id:=""
	match display_name:
		"Pinewatch Bow":definition_id="pinewatch_bow"
		"Pilgrim's Vestment","Pilgrim’s Vestment":definition_id="pilgrims_vestment"
		"Marchwarden Plate":definition_id="marchwarden_plate"
	var instance_id:=str(legacy_item.get("id",""))
	if instance_id=="":instance_id="legacy_%s"%display_name.to_lower().replace(" ","_").replace("'","")
	if definition_id!="":return create_instance(definition_id,instance_id)
	var hero_class:=str(legacy_item.get("class",""));var weapon_family:String=str({"Ranger":"bow","Mage":"wand","Warlock":"wand","Rogue":"dual_wield"}.get(hero_class,""))
	var slot:="weapon" if weapon_family!="" else "chest";var armor_family:String=str({"Guardian":"plate","Cleric":"mail","Ranger":"mail","Rogue":"leather","Mage":"cloth","Warlock":"cloth"}.get(hero_class,""))
	return {"instance_id":instance_id,"definition_id":"legacy_%s"%display_name.to_lower().replace(" ","_").replace("'",""),"display_name":display_name,"slot":slot,"tier":1,"rarity":str(legacy_item.get("rarity","Common")),"armor_family_requirement":armor_family if slot!="weapon" else "","weapon_family_requirement":weapon_family,"allowed_classes":[hero_class] if hero_class!="" else [],"stat_modifiers":{},"passive_effect_ids":[],"icon_path":"","fallback_icon_type":weapon_family if slot=="weapon" else slot,"testing_only":false,"owner_state":"vault","equipped_hero_index":-1}
