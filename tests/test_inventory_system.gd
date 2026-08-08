extends RefCounted

const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func empty_state(capacity:int=30)->Dictionary:
	return {"vault_limit":capacity,"item_instances":[],"material_stacks":[],"next_item_instance_id":1,"next_material_stack_id":1,"ore":0,"herbs":0,"dust":0,"tonics":0,"heroes":[]}

static func item(definition_id:String,instance_id:String)->Dictionary:
	return ItemData.create_instance(definition_id,instance_id)

static func run()->Array:
	var errors:=[]
	TestSupport.check(errors,is_equal_approx(InventorySystem.LONG_PRESS_DURATION,.35),"Vault long press should default to 350 milliseconds.")
	TestSupport.check(errors,is_equal_approx(InventorySystem.PAGE_HOVER_DURATION,.4),"Cross-page drag hover should default to 400 milliseconds.")
	TestSupport.check(errors,GameData.STORAGE_BAG_CAPACITY==InventorySystem.STORAGE_PAGE_SIZE,"Each unlocked bag selector should represent exactly one complete physical storage page.")
	TestSupport.check(errors,InventorySystem.STORAGE_PAGE_COUNT==10,"The Vault and Workshop Depot should each support ten bag pages.")
	var legacy_page_capacity:=empty_state(40);legacy_page_capacity["vault_level"]=2;InventorySystem.ensure_storage_state(legacy_page_capacity)
	TestSupport.check(errors,legacy_page_capacity.vault_limit==60 and legacy_page_capacity.storage_page_capacity_version==2,"Older ten-slot bag unlocks should migrate once into complete 30-slot pages without losing entries.")
	legacy_page_capacity.vault_limit=45;InventorySystem.ensure_storage_state(legacy_page_capacity)
	TestSupport.check(errors,legacy_page_capacity.vault_limit==45,"After migration, storage capacity should remain ready for future variable-size equipped bags.")

	var movement:=empty_state(30);InventorySystem.add_equipment(movement,item("pinewatch_bow","bow_1"));InventorySystem.add_equipment(movement,item("pilgrims_vestment","vest_1"))
	var first_position:=InventorySystem.flat_position(InventorySystem.entry_by_id(movement,"bow_1"));var move_result:=InventorySystem.move_entry(movement,"bow_1",0,8)
	TestSupport.check(errors,move_result.success and InventorySystem.flat_position(InventorySystem.entry_by_id(movement,"bow_1"))==8,"Moving an item into an empty storage slot should persist its new position.")
	var vest_position:=InventorySystem.flat_position(InventorySystem.entry_by_id(movement,"vest_1"));var swap_result:=InventorySystem.move_entry(movement,"bow_1",0,vest_position)
	TestSupport.check(errors,swap_result.success and swap_result.swapped and InventorySystem.flat_position(InventorySystem.entry_by_id(movement,"vest_1"))==8,"Dropping on an occupied storage slot should swap positions.")
	var invalid_before:=InventorySystem.flat_position(InventorySystem.entry_by_id(movement,"bow_1"));var invalid_result:=InventorySystem.move_entry(movement,"bow_1",99,99)
	TestSupport.check(errors,not invalid_result.success and InventorySystem.flat_position(InventorySystem.entry_by_id(movement,"bow_1"))==invalid_before,"An invalid storage drop must leave the item in its original position.")

	var page_state:=empty_state(60);InventorySystem.add_equipment(page_state,item("marchwarden_plate","plate_1"));InventorySystem.move_entry(page_state,"plate_1",1,4)
	TestSupport.check(errors,InventorySystem.entry_by_id(page_state,"plate_1").storage_page==1 and InventorySystem.entry_by_id(page_state,"plate_1").storage_slot_index==4,"Manual movement between storage pages should persist page and slot.")
	page_state.heroes=[{"name":"Brann","class":"Guardian","equipment_slots":ItemData.empty_equipment_slots()}];ItemData.equip_in_state(page_state,0,"plate_1",GameData.CLASSES);InventorySystem.move_entry(page_state,"plate_1",0,9)
	TestSupport.check(errors,page_state.heroes[0].equipment_slots.chest=="plate_1" and InventorySystem.entry_by_id(page_state,"plate_1").equipped_hero_index==0,"Reordering an equipped item must not unequip it.")

	var materials:=empty_state(2);var material_result:=InventorySystem.add_material(materials,"ore",98);InventorySystem.add_material(materials,"herbs",100);var additional:=InventorySystem.add_material(materials,"ore",5)
	TestSupport.check(errors,material_result.success and additional.collected==5 and additional.rejected==0 and InventorySystem.occupied_count(materials)==0 and InventorySystem.depot_entry_references(materials).size()==3,"Materials should stack in the unlimited Materials Depot without occupying protected Vault slots.")
	var ore_stack:Dictionary=materials.material_stacks.filter(func(stack):return str(stack.material_id)=="ore")[0];var protect_result:=InventorySystem.transfer_material(materials,str(ore_stack.instance_id),50,"vault")
	TestSupport.check(errors,protect_result.success and InventorySystem.occupied_count(materials)==1 and materials.ore==53,"Protecting part of a material stack should occupy a Vault slot and remove that quantity from Workshop availability.")
	var protected_stack:Dictionary=materials.material_stacks.filter(func(stack):return InventorySystem.storage_location(stack)=="vault")[0];var release_result:=InventorySystem.transfer_material(materials,str(protected_stack.instance_id),20,"depot")
	TestSupport.check(errors,release_result.success and materials.ore==73,"Releasing protected materials should return them to the Workshop's available Depot total.")
	var full_depot:=empty_state(30);full_depot.depot_level=1;full_depot.depot_limit=30
	for depot_index in 30:InventorySystem.add_equipment(full_depot,item("pinewatch_bow","full_depot_%d"%depot_index));InventorySystem.transfer_entry(full_depot,"full_depot_%d"%depot_index,"depot")
	var depot_overflow:=InventorySystem.add_material(full_depot,"herbs",1)
	TestSupport.check(errors,not depot_overflow.success and depot_overflow.rejected==1 and depot_overflow.reason=="Workshop Depot Full","A full Depot should reject only material overflow until another bag is unlocked.")
	InventorySystem.add_equipment(materials,item("pinewatch_bow","depot_bow"));var send_gear:=InventorySystem.transfer_entry(materials,"depot_bow","depot");var depot_gear:=InventorySystem.entry_by_id(materials,"depot_bow")
	TestSupport.check(errors,send_gear.success and InventorySystem.storage_location(depot_gear)=="depot" and InventorySystem.occupied_count(materials)==1,"Unequipped equipment should move to the Workshop Depot and stop occupying a Vault slot.")
	var protect_gear:=InventorySystem.transfer_entry(materials,"depot_bow","vault");TestSupport.check(errors,protect_gear.success and InventorySystem.storage_location(depot_gear)=="vault" and InventorySystem.occupied_count(materials)==2,"Workshop equipment should return to the next free protected Vault slot in one transfer.")
	var warning:=empty_state(10)
	for index in 8:InventorySystem.add_equipment(warning,item("pinewatch_bow","warning_%d"%index))
	TestSupport.check(errors,InventorySystem.warning_state(warning)=="warning","The Vault warning should begin at the configured 80 percent threshold.")
	InventorySystem.transfer_entry(materials,"depot_bow","depot");InventorySystem.add_equipment(materials,item("pinewatch_bow","first_bow"));TestSupport.check(errors,not InventorySystem.add_equipment(materials,item("pinewatch_bow","blocked_bow")).success,"New equipment should require an empty protected Vault slot even when the Depot has room.")

	var freed:=empty_state(1);InventorySystem.add_material(freed,"ore",8);var crafted:=InventorySystem.simulate_inventory_transaction(freed,[{"kind":"material","material_id":"ore","quantity":8}],[{"kind":"equipment","item":item("pinewatch_bow","crafted_bow")}])
	TestSupport.check(errors,crafted.success and InventorySystem.entry_by_id(crafted.state,"crafted_bow").is_empty()==false,"A fully consumed material stack should free a slot for a crafted output.")
	var not_freed:=empty_state(1);InventorySystem.add_equipment(not_freed,item("pilgrims_vestment","occupied_slot"));InventorySystem.add_material(not_freed,"ore",100);var blocked:=InventorySystem.simulate_inventory_transaction(not_freed,[{"kind":"material","material_id":"ore","quantity":8}],[{"kind":"equipment","item":item("pinewatch_bow","blocked_craft")}])
	TestSupport.check(errors,not blocked.success and not_freed.ore==100 and InventorySystem.entry_by_id(not_freed,"blocked_craft").is_empty(),"A failed transaction must remain atomic and consume nothing.")
	var multi:=empty_state(2);InventorySystem.add_material(multi,"ore",8);InventorySystem.add_material(multi,"herbs",1);var multi_result:=InventorySystem.apply_inventory_transaction(multi,[{"kind":"material","material_id":"ore","quantity":8},{"kind":"material","material_id":"herbs","quantity":1}],[{"kind":"equipment","item":item("pinewatch_bow","multi_bow")},{"kind":"material","material_id":"dust","quantity":4}])
	TestSupport.check(errors,multi_result.success and InventorySystem.occupied_count(multi)==1 and multi.dust==4,"Multi-input transactions should place equipment in the Vault and material outputs in the Depot atomically.")

	var legacy:=SaveManager.fresh_state();legacy.guild_name="Legacy Inventory";legacy.heroes.append({"name":"Wren","class":"Ranger","level":3,"xp":0,"gear":12,"equipment":[],"equipment_slots":ItemData.empty_equipment_slots()});legacy.zone0.inventory=[
		{"id":"ashwood_item_1","name":"Pinewatch Bow","class":"Ranger","slot":"Weapon","rarity":"Common","power":1,"equipped_by":2},
		{"id":"ashwood_item_2","name":"Pilgrim's Vestment","class":"Cleric","slot":"Armor","rarity":"Common","power":1,"equipped_by":1},
		{"id":"ashwood_item_3","name":"Marchwarden Plate","class":"Guardian","slot":"Weapon","rarity":"Rare","power":3,"equipped_by":0}
	]
	legacy=SaveManager.migrate_state(legacy,true,false);var migrated_again:=SaveManager.migrate_state(legacy,true,false)
	TestSupport.check(errors,migrated_again.item_instances.size()==3 and migrated_again.zone0.inventory.is_empty(),"Legacy Ashwood equipment should migrate exactly once without duplicates.")
	TestSupport.check(errors,migrated_again.heroes[2].equipment_slots.weapon=="ashwood_item_1" and migrated_again.heroes[1].equipment_slots.chest=="ashwood_item_2" and migrated_again.heroes[0].equipment_slots.chest=="ashwood_item_3","The three existing normal-save items should preserve Wren, Sera, and Brann as owners.")
	var positions:Dictionary={}
	for owned_item in migrated_again.item_instances:positions[InventorySystem.flat_position(owned_item)]=true
	TestSupport.check(errors,positions.size()==migrated_again.item_instances.size(),"Every owned equipment instance should have exactly one unique storage position.")

	for definition_id in ["pinewatch_bow","pilgrims_vestment","marchwarden_plate"]:
		var card:=ItemData.item_card_data(ItemData.create_instance(definition_id,"card_%s"%definition_id),[])
		TestSupport.check(errors,card.display_name!="" and str(card.icon_path).begins_with("res://assets/items/") and ResourceLoader.exists(card.icon_path) and card.fallback_icon_type!="" and card.passives.is_empty(),"Normal Ashwood items should have temporary icon-backed Item Cards and omit empty passive sections.")
	var testing:=SaveManager.testing_state();testing=SaveManager.migrate_state(testing,true,true)
	TestSupport.check(errors,testing.item_instances.size()==10 and testing.item_instances.all(func(test_item):var card:=ItemData.item_card_data(test_item,testing.heroes);return card.tier==9 and card.rarity=="Legendary" and not card.passives.is_empty() and ResourceLoader.exists(card.icon_path)),"All ten testing items should remain unique and expose complete icon-backed Tier IX Legendary Item Cards.")

	return errors
