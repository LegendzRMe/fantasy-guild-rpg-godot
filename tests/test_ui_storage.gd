extends RefCounted
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const ProfessionData = preload("res://scripts/data/profession_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run(main:Node) -> Array:
	var errors:=[]
	main.show_hall();await main.get_tree().process_frame
	var normal_vault_state:=SaveManager.fresh_state()
	normal_vault_state.guild_name="Normal Vault Test"
	normal_vault_state.heroes.append({"name":"Wren","class":"Ranger","level":3,"xp":0,"gear":12,"equipment":[],"equipment_slots":ItemData.empty_equipment_slots()})
	normal_vault_state.zone0.inventory=[
		{"id":"normal_bow","name":"Pinewatch Bow","class":"Ranger","slot":"Weapon","rarity":"Common","power":1,"equipped_by":2},
		{"id":"normal_vestment","name":"Pilgrim's Vestment","class":"Cleric","slot":"Armor","rarity":"Common","power":1,"equipped_by":1},
		{"id":"normal_plate","name":"Marchwarden Plate","class":"Guardian","slot":"Weapon","rarity":"Rare","power":3,"equipped_by":0}
	]
	main.state=SaveManager.migrate_state(normal_vault_state,true,false)
	main.show_vault()
	await main.get_tree().process_frame
	var normal_vault_slots:Array[Node]=main.ui.find_children("VaultSlot*","Button",true,false)
	var normal_vault_labels:Array=main.ui.find_children("*","Label",true,false).map(func(node):return str(node.text))
	TestSupport.check(errors,normal_vault_slots.size()==30 and normal_vault_slots.all(func(slot):return slot.global_position.y+slot.size.y<=main.H),"A normal save should render all thirty physical Item Storage slots inside the 720p screen.")
	TestSupport.check(errors,"ASHWOOD EQUIPMENT" not in normal_vault_labels and "EQUIPMENT VAULT" not in normal_vault_labels,"A normal save must not recreate either retired equipment list outside the physical storage grid.")
	for expected_item_id in ["normal_bow","normal_vestment","normal_plate"]:
		var stored_entry:Dictionary=InventorySystem.entry_by_id(main.state,str(expected_item_id))
		var stored_slot:Button=main.ui.find_child("VaultSlot%d"%InventorySystem.flat_position(stored_entry),true,false)
		var stored_frame:StyleBoxFlat=stored_slot.get_theme_stylebox("normal") if stored_slot!=null else null
		var expected_frame:=Color(ItemData.RARITY_COLORS.get(str(stored_entry.get("rarity","Common")),"e9f1ff"))
		TestSupport.check(errors,stored_slot!=null and stored_slot.tooltip_text=="" and stored_slot.find_child("VaultSlotIcon",true,false)!=null and stored_slot.find_child("VaultSlotName",true,false)==null and stored_slot.find_child("VaultSlotFooter",true,false)==null and stored_frame!=null and stored_frame.border_color.is_equal_approx(expected_frame),"%s should be represented only by its icon and rarity border, without hover details, inside Item Storage."%str(stored_entry.get("display_name","Item")))
	var normal_bow_entry:Dictionary=InventorySystem.entry_by_id(main.state,"normal_bow")
	var normal_bow_slot:Button=main.ui.find_child("VaultSlot%d"%InventorySystem.flat_position(normal_bow_entry),true,false)
	var normal_click:=InputEventMouseButton.new();normal_click.button_index=MOUSE_BUTTON_LEFT;normal_click.pressed=true;normal_click.position=normal_bow_slot.global_position+normal_bow_slot.size*.5
	normal_bow_slot.gui_input.emit(normal_click);main.vault_press_time=.1;main.finish_vault_pointer(normal_click.position)
	await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("SharedItemCard",true,false)!=null,"Tapping a normal-save equipment square should open the shared Item Card.")
	main.close_item_overlay()
	main.open_save_slot(0)
	TestSupport.check(errors,main.screen=="creation" and main.state.guild_name=="","An empty live slot should continue to guild creation.")
	main.open_save_slot(3)
	TestSupport.check(errors,main.screen=="hall" and main.state.guild_name=="Testing Guild","An empty testing slot should open its unlocked guild directly.")
	TestSupport.check(errors,main.state.tutorial_complete==true and main.state.heroes.size()==23,"The testing slot should bypass the tutorial with its complete roster.")
	await main.get_tree().process_frame
	for room_id in ["command_table","great_hall","infirmary","front_gate","guild_storage","tavern","trading_post","workshop","combat_hall"]:
		var testing_room:Button=main.ui.find_child("GuildRoom_%s"%room_id,true,false)
		TestSupport.check(errors,testing_room!=null and testing_room.find_child("LockOverlay",true,false)==null,"%s should remain available in the testing guild."%room_id)
	for room_id in ["council_chamber","lower_locked_3","lower_locked_4"]:
		var lower_room:Button=main.ui.find_child("GuildRoom_%s"%room_id,true,false)
		TestSupport.check(errors,lower_room!=null and lower_room.text.contains("LOCKED ROOM") and lower_room.find_child("LockOverlay",true,false)!=null,"Every lower expansion space should remain a neutral locked room, including in the testing guild.")
	TestSupport.check(errors,main.ui.find_child("GuildRoom_workshop",true,false).size.x>main.ui.find_child("GuildRoom_guild_storage",true,false).size.x*2,"The Workshop / Automation Wing should be materially wider than the combined Guild Storage room.")
	main.toggle_guild_hall_debug_panel();await main.get_tree().process_frame
	var debug_dismiss:Button=main.ui.find_child("GuildHallDebugDismissLayer",true,false);TestSupport.check(errors,debug_dismiss!=null and main.ui.find_child("GuildHallDebugPanel",true,false)!=null,"Guild Hall Test Controls should open above a click- and tap-outside dismissal layer.")
	if debug_dismiss!=null:debug_dismiss.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,not main.guild_hall_debug_open and main.ui.find_child("GuildHallDebugPanel",true,false)==null,"Clicking or tapping outside Guild Hall Test Controls should close the panel without running a test action.")
	main.show_tavern();await main.get_tree().process_frame
	TestSupport.check(errors,main.screen=="tavern" and main.ui.find_child("TavernHourlyBudget",true,false)!=null and main.ui.find_child("TavernCandidatePanel",true,false)!=null,"The existing Guild Hall Tavern should open the integrated Level 1 recruitment screen.")
	var tavern_debug:PanelContainer=main.ui.find_child("RecruitmentDebugPanel",true,false)
	TestSupport.check(errors,main.ui.find_child("RenameTavernButton",true,false)!=null and main.ui.find_child("TavernLevelBadge",true,false)!=null and main.ui.find_child("TavernGoldReadout",true,false)!=null and main.ui.find_child("TavernActivityScroll",true,false)!=null,"The Tavern should expose personalization, level, compact Gold, and a scrollable activity log without a Guild Clock card.")
	var recruitment_scroll:=main.ui.find_child("TavernRecruitmentPageScroll",true,false) as ScrollContainer
	if recruitment_scroll!=null:recruitment_scroll.scroll_vertical=80;await main.get_tree().process_frame
	var expected_recruitment_scroll:=recruitment_scroll.scroll_vertical if recruitment_scroll!=null else 0
	main.show_tavern();await main.get_tree().process_frame;await main.get_tree().process_frame
	var refreshed_recruitment_scroll:=main.ui.find_child("TavernRecruitmentPageScroll",true,false) as ScrollContainer
	TestSupport.check(errors,expected_recruitment_scroll>0 and refreshed_recruitment_scroll!=null and refreshed_recruitment_scroll.scroll_vertical==expected_recruitment_scroll,"Periodic Tavern refreshes should preserve the active tab's scroll position instead of snapping back to the top.")
	tavern_debug=main.ui.find_child("RecruitmentDebugPanel",true,false)
	TestSupport.check(errors,main.ui.find_child("TavernGuildClock",true,false)==null and tavern_debug!=null and tavern_debug.custom_minimum_size.y<=74 and main.ui.find_child("RecruitmentDebugDisclosure",true,false) is OptionButton,"Tavern testing controls should remain in one compact fixed-height row as activity grows.")
	var recruitment_production:Control=main.ui.find_child("TavernRecruitmentProduction",true,false)
	TestSupport.check(errors,recruitment_production!=null and tavern_debug.position.y>=recruitment_production.position.y+recruitment_production.size.y,"Recruitment test controls should live below the complete player-facing Tavern screen instead of reducing its usable space.")
	var rename_button:Button=main.ui.find_child("RenameTavernButton",true,false);var level_badge:Label=main.ui.find_child("TavernLevelBadge",true,false);var header_spacer:Control=main.ui.find_child("TavernHeaderSpacer",true,false);var gold_readout:Label=main.ui.find_child("TavernGoldReadout",true,false)
	TestSupport.check(errors,rename_button!=null and level_badge!=null and header_spacer!=null and gold_readout!=null and rename_button.get_index()<level_badge.get_index() and level_badge.get_index()<header_spacer.get_index() and header_spacer.get_index()<gold_readout.get_index(),"Rename Tavern and Tavern Level should stay beside the title on the left, with Gold separated on the right.")
	var initial_tavern_title:Label=main.ui.find_child("TavernTitleLabel",true,false);var tavern_return:Button=initial_tavern_title.get_parent().get_child(initial_tavern_title.get_parent().get_child_count()-1) if initial_tavern_title!=null else null
	TestSupport.check(errors,initial_tavern_title!=null and initial_tavern_title.autowrap_mode==TextServer.AUTOWRAP_OFF and initial_tavern_title.size.x>=280 and rename_button.size.y<=64 and tavern_return!=null and tavern_return.size.y<=64,"The Tavern header should keep its title readable on one line and prevent header buttons from stretching vertically.")
	main.request_rename_tavern();await main.get_tree().process_frame
	var rename_dialog:ConfirmationDialog=main.ui.find_child("RenameTavernDialog",true,false);var tavern_name_input:LineEdit=main.ui.find_child("TavernNameInput",true,false)
	if rename_dialog!=null and tavern_name_input!=null:tavern_name_input.text="The Copper Kettle";rename_dialog.confirmed.emit();await main.get_tree().process_frame
	var persisted_tavern_name:String=str(main.SaveManager.load_state(main.current_save_slot).recruitment.tavern_name);var tavern_title:Label=main.ui.find_child("TavernTitleLabel",true,false)
	TestSupport.check(errors,main.state.recruitment.tavern_name=="The Copper Kettle" and persisted_tavern_name=="The Copper Kettle" and tavern_title!=null and tavern_title.text=="The Copper Kettle","Renaming the Tavern should update the title and persist through the active save slot.")
	main.set_recruitment_budget(3);main.debug_complete_recruitment_hour();await main.get_tree().process_frame
	var tavern_candidate:Dictionary=main.RecruitmentSystem.current_candidate(main.state)
	TestSupport.check(errors,not tavern_candidate.is_empty() and main.ui.find_child("TavernInspectCandidate",true,false)!=null and main.ui.find_child("TavernRecruitCandidate",true,false)!=null and main.ui.find_child("TavernRejectCandidate",true,false)!=null and main.ui.find_child("TavernLockCandidate",true,false)!=null and main.ui.find_child("TavernTableTalk",true,false)==null,"An hourly Tavern check should show only current Level 1 actions and withhold staff-dependent Table Talk.")
	main.debug_set_recruitment_disclosure(20);main.inspect_tavern_candidate();await main.get_tree().process_frame
	var hidden_negative:Control=main.ui.find_child("RosterDetailRowNegativeTrait",true,false)
	TestSupport.check(errors,main.screen=="recruitment_preview" and main.ui.find_child("RecruitmentPreviewPortrait",true,false)!=null and main.ui.find_child("RosterWorkspace",true,false)!=null and main.ui.find_child("RecruitmentPreviewSectionDetails",true,false)!=null and hidden_negative!=null and hidden_negative.get_child(1).text=="Unknown","Candidate inspection should mirror the Hero Roster workspace in read-only mode and mark hidden fields as Unknown.")
	main.show_tavern();main.reject_tavern_candidate();await main.get_tree().process_frame
	TestSupport.check(errors,main.RecruitmentSystem.current_candidate(main.state).is_empty(),"Rejecting from the Tavern UI should clear the candidate slot immediately.")
	main.set_tavern_section("Recovery & Rest");await main.get_tree().process_frame
	var recovery_production:Control=main.ui.find_child("TavernRecoveryProduction",true,false);var recovery_debug:PanelContainer=main.ui.find_child("TavernRecoveryDebug",true,false)
	TestSupport.check(errors,recovery_production!=null and recovery_debug!=null and recovery_debug.custom_minimum_size.y<=52 and recovery_debug.position.y>=recovery_production.position.y+recovery_production.size.y,"Recovery testing controls should remain compact and below the player-facing recovery screen.")
	main.set_tavern_section("Kitchen");await main.get_tree().process_frame
	var provisions_readout:Label=main.ui.find_child("TavernProvisionsReadout",true,false);var kitchen_texts:Array=main.ui.find_children("*","Label",true,false).map(func(node):return str(node.text));var kitchen_buttons:Array=main.ui.find_children("*","Button",true,false)
	TestSupport.check(errors,provisions_readout!=null and provisions_readout.autowrap_mode==TextServer.AUTOWRAP_OFF and provisions_readout.size.x>=170 and not kitchen_texts.any(func(text):return "No profession" in text) and not kitchen_buttons.any(func(control):return "Learn Cooking" in control.text),"The Kitchen should keep Provisions on one line and avoid listing every untrained guild member.")
	var kitchen_header:=main.ui.find_child("TavernKitchenHeader",true,false) as PanelContainer;var kitchen_chef:=main.ui.find_child("TavernKitchenChef",true,false) as Label;var train_cooking:=main.ui.find_child("OpenCookingTrainingRoster",true,false) as Button
	TestSupport.check(errors,kitchen_header!=null and kitchen_header.size.y<=80 and kitchen_chef!=null and kitchen_chef.autowrap_mode==TextServer.AUTOWRAP_OFF and kitchen_chef.size.x>=190 and train_cooking!=null and train_cooking.size.y<=48,"The Kitchen header should remain a compact single row instead of allowing Chef text or the training button to stretch it vertically.")
	TestSupport.check(errors,main.ui.find_child("OpenCookingTrainingRoster",true,false)!=null or main.ui.find_child("TavernCookSelector",true,false)!=null,"The Kitchen should show either one selected Cook workspace or a concise link back to Hero Roster training.")
	main.set_tavern_section("Overview");await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("TavernHostAssignment",true,false)!=null and main.ui.find_child("TavernChefAssignment",true,false)!=null and main.ui.find_child("TavernStewardAssignment",true,false)==null and main.ui.find_child("TavernFutureStaffNote",true,false)!=null,"The Tavern Overview should keep current Host and Chef assignments compact while reserving future staff positions without another control.")
	main.set_tavern_section("Rest Area");await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("TavernRestMealSelector",true,false)!=null and main.state.tavern_management.rest_slots.size()==2,"The Rest Area should show the saved Rest Meal selector and two Level 1 rest slots.")
	var rest_meal_selector:=main.ui.find_child("TavernRestMealSelector",true,false) as OptionButton
	if rest_meal_selector!=null:rest_meal_selector.get_popup().popup();await main.get_tree().process_frame
	TestSupport.check(errors,rest_meal_selector!=null and not main.tavern_refresh_is_safe(),"The Tavern should defer periodic redraws while a meal or member selection menu is open.")
	if rest_meal_selector!=null:rest_meal_selector.get_popup().hide()
	main.set_tavern_section("Recruitment");await main.get_tree().process_frame
	var recruitment_texts:Array=main.ui.find_children("*","Label",true,false).map(func(node):return str(node.text));var recruitment_buttons:Array=main.ui.find_children("*","Button",true,false).map(func(node):return str(node.text))
	TestSupport.check(errors,not recruitment_texts.any(func(text):return "RECRUITMENT CAMPAIGN" in text) and not recruitment_buttons.any(func(text):return text in ["Local Notice","Guild Call","Grand Recruitment"] or "Local Notice" in text or "Guild Call" in text or "Grand Recruitment" in text),"Recruitment campaigns should remain absent from the current Tavern interface.")
	main.show_crafting();await main.get_tree().process_frame
	var workshop_tab_names:=["CurrentOrders","Recipes","Techniques","Specializations","PatternMastery","RuneCollection"]
	TestSupport.check(errors,workshop_tab_names.all(func(tab_name):return main.ui.find_child("Workshop%sTab"%tab_name,true,false)!=null),"The Workshop should always display every navigation tab, including Recipes.")
	var recipes_tab:Button=main.ui.find_child("WorkshopRecipesTab",true,false)
	if recipes_tab!=null:
		recipes_tab.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,main.profession_workshop_tab=="Recipes","The Recipes tab should be reachable from the Workshop navigation.")
	main.show_vault();await main.get_tree().process_frame
	var vault_texts:Array=main.ui.find_children("*","Label",true,false).map(func(node):return str(node.text))
	TestSupport.check(errors,"ASHWOOD EQUIPMENT" not in vault_texts and "EQUIPMENT VAULT" not in vault_texts and not vault_texts.any(func(text):return "PROTECTED VAULT" in text and "MOVE ITEMS" in text),"Item Storage should omit old summary headings and the transfer-instruction subtitle to reclaim vertical space.")
	var storage_search:LineEdit=main.ui.find_child("GuildStorageSearch",true,false);var storage_scope:OptionButton=main.ui.find_child("GuildStorageSearchScope",true,false)
	TestSupport.check(errors,storage_search!=null and storage_scope!=null and storage_scope.get_item_text(storage_scope.selected)=="Both","Guild Storage should place a shared search field in its header and default its location selector to both sides.")
	var physical_slots:Array[Node]=main.ui.find_children("VaultSlot*","Button",true,false)
	TestSupport.check(errors,physical_slots.size()==30 and physical_slots.all(func(slot):return slot.custom_minimum_size.x>=86 and slot.custom_minimum_size.y>=56),"The split Vault should keep thirty compact but touch-friendly physical slots visible.")
	var visible_testing_items:=0
	for testing_item in main.state.item_instances:
		var testing_slot:Button=main.ui.find_child("VaultSlot%d"%InventorySystem.flat_position(testing_item),true,false)
		if testing_slot!=null and testing_slot.find_child("VaultSlotIcon",true,false)!=null and testing_slot.find_child("VaultSlotName",true,false)==null and testing_slot.find_child("VaultSlotFooter",true,false)==null:visible_testing_items+=1
	TestSupport.check(errors,visible_testing_items==10,"Item Storage should visibly contain all ten testing-save Legendary items as icon-only physical slots.")
	TestSupport.check(errors,main.ui.find_child("GuildStorageSplit",true,false)!=null and main.ui.find_child("GuildVaultPane",true,false)!=null and main.ui.find_child("WorkshopDepotPane",true,false)!=null and main.ui.find_child("GuildStorageVaultTab",true,false)==null and main.ui.find_child("GuildStorageDepotTab",true,false)==null,"Guild Storage should show the Vault on the left and Workshop Depot on the right without tabs.")
	main.set_storage_search_scope("Guild Vault");await main.get_tree().process_frame
	var full_vault:Control=main.ui.find_child("GuildVaultPane",true,false);var full_vault_grid:GridContainer=main.ui.find_child("VaultStorageGrid",true,false)
	TestSupport.check(errors,main.ui.find_child("GuildStorageSingleView",true,false)!=null and full_vault!=null and main.ui.find_child("WorkshopDepotPane",true,false)==null and full_vault.size.x>1100 and full_vault_grid.columns==10,"Selecting Guild Vault should replace the split view with a full-width ten-column Vault.")
	main.set_storage_search_scope("Workshop Depot");await main.get_tree().process_frame
	var full_depot:Control=main.ui.find_child("WorkshopDepotPane",true,false);var full_depot_grid:GridContainer=main.ui.find_child("MaterialsDepotGrid",true,false)
	TestSupport.check(errors,main.ui.find_child("GuildStorageSingleView",true,false)!=null and full_depot!=null and main.ui.find_child("GuildVaultPane",true,false)==null and full_depot.size.x>1100 and full_depot_grid.columns==10,"Selecting Workshop Depot should replace the split view with a full-width ten-column Depot.")
	main.set_storage_search_scope("Both");await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("GuildStorageSplit",true,false)!=null and main.ui.find_child("GuildVaultPane",true,false)!=null and main.ui.find_child("WorkshopDepotPane",true,false)!=null,"Selecting Both should restore the default side-by-side storage view.")
	var page_bags:Array[Node]=main.ui.find_children("VaultPageBag*","Button",true,false)
	TestSupport.check(errors,page_bags.size()==GameData.STORAGE_BAG_SLOTS and main.ui.find_child("VaultPageBags",true,false)!=null and page_bags.all(func(page):return page.text in ["▣","▧"]),"The bag-shaped storage controls should be the only page selectors, without a duplicate numbered row.")
	var inspected_id:=str(main.state.item_instances[0].instance_id);main.begin_vault_press(inspected_id,Vector2(10,10));main.vault_press_time=.1;main.finish_vault_pointer(Vector2(10,10));await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("SharedItemCard",true,false)!=null,"A quick Vault click should open the shared Item Card without moving the item.")
	var shared_item_card:Control=main.ui.find_child("SharedItemCard",true,false)
	var card_rarity:Label=main.ui.find_child("ItemCardRarity",true,false);var card_tier:Label=main.ui.find_child("ItemCardTier",true,false);var card_name:Label=main.ui.find_child("ItemCardName",true,false);var card_type:Label=main.ui.find_child("ItemCardType",true,false)
	TestSupport.check(errors,card_rarity!=null and card_rarity.text=="★ LEGENDARY" and card_tier!=null and card_tier.text=="TIER IX","The Item Card should lead with Legendary rarity and Tier IX on one clear top line.")
	var item_card_icon:Control=main.ui.find_child("ItemCardIcon",true,false)
	TestSupport.check(errors,card_name!=null and card_name.text=="ASHFANG KNIVES" and card_type!=null and card_type.text=="Dual Wield Weapon" and item_card_icon!=null and item_card_icon.find_children("*","TextureRect",true,false).size()==1,"The Item Card should center its generated temporary icon, item name, and readable equipment type.")
	TestSupport.check(errors,main.ui.find_children("ItemCardStat*","Label",true,false).size()==2 and main.ui.find_child("ItemCardPassiveTitle0",true,false).text=="BLOODLETTING" and main.ui.find_child("ItemCardPassiveDescription0",true,false)!=null,"The Item Card should present concise stat rows followed by its named passive and description.")
	TestSupport.check(errors,main.ui.find_child("ItemCardStorageStatus",true,false)!=null,"An unequipped card should show that the item is stored in the Guild Vault.")
	TestSupport.check(errors,main.ui.find_child("ItemCardActionChooseHero",true,false)!=null,"An unequipped card should keep its Choose Hero action visible.")
	TestSupport.check(errors,shared_item_card.global_position.y+shared_item_card.size.y<=main.H,"The complete Item Card should remain inside the 720p screen (bottom %.1f, viewport %.1f)."%[shared_item_card.global_position.y+shared_item_card.size.y,main.H])
	var card_backdrop:Button=main.ui.find_child("ItemCardBackdrop",true,false);card_backdrop.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,main.item_card_overlay==null,"Clicking outside the shared Item Card should close it.")
	main.show_vault();await main.get_tree().process_frame;main.begin_vault_press(inspected_id,Vector2(10,10));main._process(.36)
	TestSupport.check(errors,main.vault_dragging,"A 350 millisecond press should begin touch-friendly item movement instead of opening the Item Card.")
	main.finish_vault_pointer(Vector2(-20,-20));await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("SharedItemCard",true,false)==null,"Releasing after a drag should never open the Item Card.")
	var depot_drop_pane:Control=main.ui.find_child("WorkshopDepotPane",true,false);main.begin_vault_press(inspected_id,Vector2(10,10));main._process(.36);main.finish_vault_pointer(depot_drop_pane.get_global_rect().get_center());await main.get_tree().process_frame
	TestSupport.check(errors,InventorySystem.storage_location(InventorySystem.entry_by_id(main.state,inspected_id))=="depot","Holding a Vault item and dragging it across the center divide should send it to the Workshop Depot.")
	var vault_drop_pane:Control=main.ui.find_child("GuildVaultPane",true,false);main.begin_vault_press(inspected_id,Vector2(10,10));main._process(.36);main.finish_vault_pointer(vault_drop_pane.get_global_rect().get_center());await main.get_tree().process_frame
	TestSupport.check(errors,InventorySystem.storage_location(InventorySystem.entry_by_id(main.state,inspected_id))=="vault","Holding a Depot item and dragging it left should protect it in the Guild Vault again.")
	var merchant_item_count:int=main.state.item_instances.size();var merchant_gold_before:=int(main.state.gold);var purchase_result:Dictionary=main.purchase_merchant_item("pinewatch_bow",90,"Borin Ironhand")
	TestSupport.check(errors,purchase_result.success and main.state.item_instances.size()==merchant_item_count+1 and main.state.gold==merchant_gold_before-90 and main.state.item_instances[-1].owner_state=="vault","Merchant equipment purchases should enter Item Storage without auto-equipping.")
	main.state.vault_limit=InventorySystem.occupied_count(main.state);var stack_gold_before:=int(main.state.gold);var stack_purchase:Dictionary=main.purchase_merchant_material("dust",1,5);var second_gold_before:=int(main.state.gold);var second_purchase:Dictionary=main.purchase_merchant_material("dust",1,5)
	TestSupport.check(errors,stack_purchase.success and second_purchase.success and main.state.gold==second_gold_before-5 and second_gold_before==stack_gold_before-5,"Merchant materials should enter the unlimited Depot even when the protected Vault has no empty slots.")
	main.show_guild_storage("depot");await main.get_tree().process_frame
	var depot_cards:Array[Node]=main.ui.find_children("DepotStack_*","Button",true,false);TestSupport.check(errors,main.ui.find_child("MaterialsDepotGrid",true,false)!=null and not depot_cards.is_empty() and main.ui.find_child("VaultCapacity",true,false)!=null and main.ui.find_child("DepotCapacity",true,false)!=null,"The side-by-side screen should present production-ready Depot entries alongside both capacity readouts.")
	var depot_grid:GridContainer=main.ui.find_child("MaterialsDepotGrid",true,false);var depot_squares:Array[Node]=depot_grid.find_children("*","Button",false,false) if depot_grid!=null else []
	TestSupport.check(errors,depot_squares.size()==30 and depot_squares.all(func(slot):return slot.custom_minimum_size==Vector2(96,58)),"The Workshop Depot should use the same thirty compact square slots and five-column layout as the Guild Vault.")
	var visible_depot_slots:=depot_squares.filter(func(slot):return slot.find_child("DepotSlotIcon",false,false)!=null);var material_depot_slots:=depot_squares.filter(func(slot):return slot.find_child("DepotSlotStackCount",false,false)!=null)
	TestSupport.check(errors,not visible_depot_slots.is_empty() and visible_depot_slots.all(func(slot):var icon=slot.find_child("DepotSlotIcon",false,false);return not icon is Label or icon.text not in ["ORE","HERB","DUST","TONIC","MAT","PROV"]),"Depot materials should use visual symbols instead of oversized letter abbreviations.")
	TestSupport.check(errors,not material_depot_slots.is_empty() and material_depot_slots.all(func(slot):var count=slot.find_child("DepotSlotStackCount",false,false);return count.autowrap_mode==TextServer.AUTOWRAP_OFF and count.anchor_left==1.0 and count.anchor_top==1.0 and count.offset_right<0 and count.offset_bottom<0),"Depot material quantities should remain anchored in the bottom-right corner of their slots.")
	var depot_organize:Button=main.ui.find_child("AutoOrganizeDepotButton",true,false);var vault_organize:Button=main.ui.find_child("AutoOrganizeVaultButton",true,false)
	TestSupport.check(errors,depot_organize!=null and vault_organize!=null and depot_organize.text==vault_organize.text and depot_organize.custom_minimum_size==vault_organize.custom_minimum_size and not main.ui.find_children("*","Button",true,false).any(func(control):return control.text=="Open Workshop"),"The Workshop Depot and Guild Vault should use the same compact auto-organize symbol and sizing.")
	if storage_search!=null:
		storage_search=main.ui.find_child("GuildStorageSearch",true,false);storage_search.text="ashfang";storage_search.text_changed.emit("ashfang")
		var searched_vault_slot:Button=main.ui.find_child("VaultSlot%d"%InventorySystem.flat_position(InventorySystem.entry_by_id(main.state,inspected_id)),true,false);TestSupport.check(errors,searched_vault_slot!=null and searched_vault_slot.visible and depot_cards.all(func(card):return not card.visible),"The shared search should filter both Vault and Depot squares by item name.")
		storage_search.text="";storage_search.text_changed.emit("")
	var depot_bags:Array[Node]=main.ui.find_children("DepotPageBag*","Button",true,false);TestSupport.check(errors,depot_bags.size()==10 and main.ui.find_child("DepotPageBags",true,false)!=null,"The Workshop Depot should have its own ten independently upgradeable bag slots.")
	var depot_stack_id:=str(main.state.material_stacks.filter(func(stack):return InventorySystem.storage_location(stack)=="depot")[0].instance_id);main.request_material_transfer(depot_stack_id,"vault");await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("MaterialTransferDialog",true,false)!=null and main.ui.find_child("MaterialTransferAmount",true,false)!=null,"Material protection should support selecting a partial stack quantity.")
	var transfer_dialog:ConfirmationDialog=main.ui.find_child("MaterialTransferDialog",true,false);if transfer_dialog!=null:transfer_dialog.hide();transfer_dialog.queue_free()
	main.state.vault_limit=180;main.save_game()
	main.show_dungeons()
	await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("TestingResetStoryButton",true,false)!=null,"The testing World Map should expose the Ashwood story reset tool.")
	TestSupport.check(errors,main.ui.find_child("TestingWorldRegion",true,false)==null,"The World Map should no longer duplicate Combat Hall training tools with an oversized Testing region.")
	var world_regions:Array[Node]=main.ui.find_children("WorldRegion_*","Button",true,false)
	TestSupport.check(errors,world_regions.size()==11,"The World Map should render all eleven centralized region definitions.")
	var ashwood_region:Button=main.ui.find_child("WorldRegion_ashwood_marches",true,false)
	TestSupport.check(errors,ashwood_region!=null and ashwood_region.get_child(0).get_child(1).text=="Tutorial","Ashwood Marches should display Tutorial instead of its encounter completion counter.")
	var greyhaven_region:Button=main.ui.find_child("WorldRegion_greyhaven_reach",true,false)
	if greyhaven_region!=null:greyhaven_region.pressed.emit()
	TestSupport.check(errors,main.screen=="campaign_region" and main.ui.find_child("CampaignRegionMap",true,false)!=null,"An unlocked campaign region should open its permanent regional map.")
	if ashwood_region!=null:ashwood_region.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,main.screen=="zone_map","Ashwood Marches should continue opening its existing internal encounter map.")
	main.show_dungeons();await main.get_tree().process_frame
	var world_return:Button=main.ui.find_child("WorldMapReturnButton",true,false);var world_zoom:HBoxContainer=main.ui.find_child("WorldMapZoomControls",true,false);TestSupport.check(errors,world_return!=null and world_zoom!=null and not world_return.get_global_rect().intersects(world_zoom.get_global_rect()),"World Map zoom controls must not cover the Return to Guild Hall button.")
	main.world_map_zoom=1.2;main.world_map_pan=Vector2(-100,-100);main.clamp_world_map_pan();var pan_before:Vector2=main.world_map_pan
	var mouse_pan:=InputEventMouseMotion.new();mouse_pan.relative=Vector2(-20,-10);main.world_map_dragging=true;main.handle_world_map_input(mouse_pan);main.world_map_dragging=false
	var mouse_pan_preserved:bool=Vector2(main.world_map_pan)!=pan_before
	var wheel_zoom_before:float=main.world_map_zoom;var wheel_zoom:=InputEventMouseButton.new();wheel_zoom.button_index=MOUSE_BUTTON_WHEEL_UP;wheel_zoom.pressed=true;wheel_zoom.position=Vector2(640,360);main.handle_world_map_input(wheel_zoom)
	var mouse_zoom_preserved:bool=float(main.world_map_zoom)>wheel_zoom_before
	var touch_one:=InputEventScreenTouch.new();touch_one.index=0;touch_one.position=Vector2(300,300);touch_one.pressed=true;main.handle_world_map_input(touch_one)
	var touch_two:=InputEventScreenTouch.new();touch_two.index=1;touch_two.position=Vector2(500,300);touch_two.pressed=true;main.handle_world_map_input(touch_two)
	var touch_zoom_before:float=main.world_map_zoom;var touch_pinch:=InputEventScreenDrag.new();touch_pinch.index=1;touch_pinch.position=Vector2(540,300);touch_pinch.relative=Vector2(40,0);main.handle_world_map_input(touch_pinch)
	TestSupport.check(errors,mouse_pan_preserved and mouse_zoom_preserved and main.world_map_zoom>touch_zoom_before,"World Map mouse panning, wheel zooming, and touch pinch zooming should remain operational.")
	main.show_roster();await main.get_tree().process_frame
	var empty_head_slot:Button=main.ui.find_child("HeroEquipmentSlotHead",true,false);var empty_head_icon:Control=empty_head_slot.find_child("HeroEquipmentIcon",true,false) if empty_head_slot!=null else null;TestSupport.check(errors,empty_head_slot!=null and empty_head_slot.text=="" and empty_head_slot.tooltip_text=="" and empty_head_icon!=null and empty_head_icon.get_script()==main.EquipmentSlotSilhouette and empty_head_slot.custom_minimum_size==Vector2(105,70),"Empty Hero equipment slots should use centered visual silhouettes without text labels.")
	main.select_equipment_slot("weapon");await main.get_tree().process_frame
	var carousel_card:Control=main.ui.find_child("EquipmentCarouselCard",true,false);var carousel_name:Label=main.ui.find_child("ItemCardName",true,false)
	TestSupport.check(errors,main.ui.find_child("HeroEquipmentBrowser",true,false)==null and main.ui.find_child("ItemCardBackdrop",true,false)!=null and carousel_card!=null and main.ui.find_child("EquipmentCarouselTapTarget",true,false)!=null and carousel_name!=null and carousel_name.text=="STORMBREAKER" and main.item_carousel_items.all(func(item):return ItemData.compatibility_reason(item,GameData.CLASSES.Guardian,"Guardian")==""),"The Hero Roster slot should open a darkened, directly tappable compatible-item card carousel without replacing Details.")
	main.equip_item_carousel_candidate();await main.get_tree().process_frame
	TestSupport.check(errors,main.state.heroes[0].equipment_slots.weapon=="testing_test_stormbreaker","Tapping the centered compatible card should equip and save the item.")
	var equipped_weapon_slot:Button=main.ui.find_child("HeroEquipmentSlotWeapon",true,false);TestSupport.check(errors,equipped_weapon_slot!=null and equipped_weapon_slot.text=="" and equipped_weapon_slot.tooltip_text=="" and equipped_weapon_slot.find_child("HeroEquipmentIcon",true,false)!=null and equipped_weapon_slot.custom_minimum_size==Vector2(105,70),"Equipped Hero slots should show only the item icon and rarity frame, with details available by clicking.")
	main.select_equipment_slot("weapon");await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("SharedItemCard",true,false)!=null and main.ui.find_child("ItemCardActionUnequipItem",true,false)!=null and main.ui.find_child("ItemCardActionChangeEquipment",true,false)!=null,"An occupied Hero slot should first open its current Item Card with Unequip and Change Equipment.")
	main.handle_item_card_action("change_equipment","testing_test_stormbreaker");await main.get_tree().process_frame
	TestSupport.check(errors,main.item_overlay_mode=="equipment_carousel" and main.ui.find_child("ItemOverlayBack",true,false)!=null,"Change Equipment should enter the compatible-card carousel with an explicit Back action.")
	main.navigate_item_overlay_back();await main.get_tree().process_frame
	TestSupport.check(errors,main.item_overlay_mode=="item_card" and main.ui.find_child("ItemCardName",true,false).text=="STORMBREAKER","Back from the equipment carousel should return to the originally equipped Item Card.")
	main.close_item_overlay()
	for equip_spec in [[0,"testing_test_aegis_last_dawn"],[0,"testing_test_gauntlets_retribution"],[0,"testing_test_pendant_endless_momentum"],[0,"testing_test_soul_furnace"],[1,"testing_test_crown_twin_incantations"],[1,"testing_test_mantle_overflowing_grace"],[1,"testing_test_mirror_borrowed_time"],[4,"testing_test_ashfang_knives"],[4,"testing_test_gloves_thousand_cuts"]]:
		TestSupport.check(errors,bool(ItemData.equip_in_state(main.state,int(equip_spec[0]),str(equip_spec[1]),GameData.CLASSES).success),"The testing setup should equip %s on a compatible hero."%equip_spec[1])
	main.show_vault();await main.get_tree().process_frame;main.open_item_card("testing_test_ashfang_knives","vault");await main.get_tree().process_frame
	var equipped_owner:Label=main.ui.find_child("ItemCardOwnerName",true,false)
	TestSupport.check(errors,equipped_owner!=null and equipped_owner.text=="Kestrel" and main.ui.find_child("ItemCardOwnerPortrait",true,false)!=null,"An equipped Item Card should show the owning hero beside a portrait placeholder.")
	TestSupport.check(errors,main.ui.find_child("ItemCardActionUnequipItem",true,false)!=null,"An equipped Vault card should expose Unequip as its first action.")
	TestSupport.check(errors,main.ui.find_child("ItemCardActionChangeHero",true,false)!=null,"An equipped Vault card should expose Change Hero as its second action.")
	TestSupport.check(errors,main.ui.find_child("ItemCardActionViewHero",true,false)==null,"The focused Vault card should not add an unrelated View Hero action.")
	main.close_item_overlay()
	main.open_item_card("testing_test_pendant_endless_momentum","vault");main.handle_item_card_action("change_hero","testing_test_pendant_endless_momentum");await main.get_tree().process_frame
	var first_hero_carousel_index:int=main.hero_carousel_index
	var hero_track:Control=main.ui.find_child("ItemCarouselTrack",true,false);var hero_left:Control=main.ui.find_child("HeroCarouselPeekLeft",true,false);var hero_right:Control=main.ui.find_child("HeroCarouselPeekRight",true,false);var hero_previous:Control=main.ui.find_child("HeroCarouselPrevious",true,false);var hero_next:Control=main.ui.find_child("HeroCarouselNext",true,false)
	TestSupport.check(errors,main.item_overlay_mode=="hero_carousel" and main.ui.find_child("HeroCarouselCard",true,false)!=null and main.ui.find_child("ItemOverlayBack",true,false)==null and main.hero_carousel_indices.size()>1,"Choosing an owner should use the centered Hero carousel without a redundant Back button.")
	TestSupport.check(errors,hero_track!=null and hero_right!=null and hero_next!=null and hero_next.position.x>hero_right.position.x+hero_right.size.x and (hero_left==null or hero_previous.position.x<hero_left.position.x),"Neighboring Hero cards should peek beside the focused card, with arrows immediately outside those previews.")
	main.update_item_carousel_drag(-80.0);TestSupport.check(errors,is_equal_approx(hero_track.position.x,-80.0),"Dragging the Hero carousel should move the visible cards continuously with the pointer.")
	main.finish_item_carousel_drag(-80.0);await main.get_tree().create_timer(.22).timeout
	TestSupport.check(errors,main.hero_carousel_index==first_hero_carousel_index+1,"Releasing a sufficient carousel drag should settle on the next hero without changing ownership.")
	var hero_backdrop:Button=main.ui.find_child("ItemCardBackdrop",true,false);hero_backdrop.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,main.item_card_overlay==null,"Tapping outside the Hero chooser should dismiss it directly.")
	return errors
