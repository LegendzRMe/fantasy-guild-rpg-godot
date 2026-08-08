extends "res://scripts/ui/tavern_screen.gd"

func vault_option(values:Array,current_value,callback:Callable,width:float)->OptionButton:
	var option:=OptionButton.new();option.custom_minimum_size=Vector2(width,40)
	for value in values:option.add_item(str(value));option.set_item_metadata(option.item_count-1,value)
	for index in option.item_count:
		if option.get_item_metadata(index)==current_value:option.select(index);break
	option.item_selected.connect(func(index):callback.call(option.get_item_metadata(index)))
	return option

func set_vault_filter(filter_name:String,value)->void:
	match filter_name:
		"category":vault_category_filter=str(value)
		"status":vault_status_filter=str(value)
		"rarity":vault_rarity_filter=str(value)
		"tier":vault_tier_filter=int(value)
	show_vault()

func auto_organize_vault()->void:
	var entries:=InventorySystem.entry_references(state)
	entries.sort_custom(func(a,b):
		var a_key:="9_%s"%a.get("material_id","") if bool(a.get("is_material",false)) else "%s_%s_%s"%[a.get("slot",""),a.get("rarity",""),a.get("display_name","")]
		var b_key:="9_%s"%b.get("material_id","") if bool(b.get("is_material",false)) else "%s_%s_%s"%[b.get("slot",""),b.get("rarity",""),b.get("display_name","")]
		return a_key<b_key)
	for index in entries.size():
		var position:=InventorySystem.position_for_flat(index);entries[index].storage_page=position.storage_page;entries[index].storage_slot_index=position.storage_slot_index
	save_game();show_vault();flash("Guild Vault organized.")

func storage_organize_key(entry:Dictionary)->String:
	return "0_%s_%s_%s"%[entry.get("slot",""),entry.get("rarity",""),entry.get("display_name","")] if not bool(entry.get("is_material",false)) else "1_%s_%s"%[entry.get("material_id",""),entry.get("display_name","")]

func auto_organize_depot()->void:
	state.item_instances.sort_custom(func(a,b):return storage_organize_key(a)<storage_organize_key(b))
	state.material_stacks.sort_custom(func(a,b):return storage_organize_key(a)<storage_organize_key(b))
	save_game();show_vault();flash("Workshop Depot organized.")

func storage_search_text_for(entry:Dictionary)->String:
	return " ".join([str(entry.get("display_name","")),str(entry.get("definition_id","")),str(entry.get("material_id","")),str(entry.get("slot","")),str(entry.get("rarity","")),str(entry.get("fallback_icon_type","")),"tier %s"%str(entry.get("tier",""))]).to_lower()

func apply_storage_search_filter()->void:
	var query:=storage_search.strip_edges().to_lower()
	for node in storage_entry_controls.values():
		if not is_instance_valid(node) or not node.has_meta("storage_location"):continue
		var location:=str(node.get_meta("storage_location"));var scope_matches:=storage_search_scope=="Both" or (storage_search_scope=="Guild Vault" and location=="vault") or (storage_search_scope=="Workshop Depot" and location=="depot")
		node.visible=query=="" or (scope_matches and query in str(node.get_meta("storage_search_text","")))

func set_storage_search_scope(value:String)->void:
	storage_search_scope=value if value in ["Both","Guild Vault","Workshop Depot"] else "Both";show_vault()

func add_storage_search_to_header(root:VBoxContainer)->void:
	var top:HBoxContainer=root.get_child(0);var search_row:=HBoxContainer.new();search_row.name="GuildStorageSearchRow";search_row.custom_minimum_size.y=40;search_row.add_theme_constant_override("separation",7)
	var search:=LineEdit.new();search.name="GuildStorageSearch";search.placeholder_text="Search items and materials";search.text=storage_search;search.clear_button_enabled=true;search.custom_minimum_size=Vector2(245,40);search.text_changed.connect(func(value):storage_search=value;apply_storage_search_filter());search_row.add_child(search)
	var scope:=vault_option(["Both","Guild Vault","Workshop Depot"],storage_search_scope,set_storage_search_scope,165);scope.name="GuildStorageSearchScope";scope.tooltip_text="Choose a split view or open either storage area at full width.";search_row.add_child(scope)
	top.add_child(search_row);top.move_child(search_row,top.get_child_count()-2)

func request_bag_unlock(slot:int) -> void:
	request_storage_bag_unlock("vault",slot)

func request_storage_bag_unlock(location:String,slot:int) -> void:
	var level_key:="vault_level" if location=="vault" else "depot_level";var limit_key:="vault_limit" if location=="vault" else "depot_limit";var current_level:=int(state.get(level_key,1))
	if slot<current_level or current_level>=GameData.STORAGE_BAG_SLOTS:return
	var next_page:=current_level;var cost=GameData.STORAGE_BAG_UNLOCK_BASE_COST*current_level;var storage_name:="Guild Vault" if location=="vault" else "Workshop Depot";var dialog:=ConfirmationDialog.new();dialog.title="Unlock %s Bag"%storage_name;dialog.dialog_text="Unlock bag %d of %d in the %s for ● %d?\n\nEach bag adds 30 storage slots."%[current_level+1,GameData.STORAGE_BAG_SLOTS,storage_name,cost];dialog.ok_button_text="Unlock Bag"
	dialog.confirmed.connect(func():
		if state.gold>=cost:
			state.gold-=cost;state[level_key]=current_level+1;state[limit_key]=mini(GameData.STORAGE_MAX_CAPACITY,int(state.get(limit_key,30))+GameData.STORAGE_BAG_CAPACITY)
			if location=="vault":vault_page=next_page
			else:depot_page=next_page
			save_game();show_vault()
		else: flash("Not enough gold."))
	ui.add_child(dialog); dialog.popup_centered(Vector2i(420,180))

func add_storage_bag_row(root:VBoxContainer,location:String,compact:bool=false)->void:
	var level:=int(state.get("vault_level" if location=="vault" else "depot_level",1));var current_page:=vault_page if location=="vault" else depot_page
	var panel:=PanelContainer.new();panel.name="VaultExpansionRow" if location=="vault" else "DepotExpansionRow";panel.add_theme_stylebox_override("panel",ui_box(Color("131e2e"),6,Color("2c3b50"),1));root.add_child(panel)
	var bags:=HBoxContainer.new();bags.name="VaultPageBags" if location=="vault" else "DepotPageBags";bags.alignment=BoxContainer.ALIGNMENT_CENTER;bags.add_theme_constant_override("separation",4 if compact else 8);panel.add_child(bags)
	for slot in GameData.STORAGE_BAG_SLOTS:
		var unlocked:bool=int(slot)<level;var bag:=Button.new();bag.name=("VaultPageBag%d" if location=="vault" else "DepotPageBag%d")%slot;bag.custom_minimum_size=Vector2(42,42) if compact else Vector2(52,48);bag.text="▣" if unlocked else "▧";bag.add_theme_font_size_override("font_size",18 if compact else 22);bag.modulate=Color.WHITE if unlocked else Color(.35,.38,.45,1);bag.tooltip_text=("Bag %d • Slots %d–%d"%[slot+1,slot*InventorySystem.STORAGE_PAGE_SIZE+1,(slot+1)*InventorySystem.STORAGE_PAGE_SIZE]) if unlocked else "Unlock bag %d of %d"%[slot+1,GameData.STORAGE_BAG_SLOTS]
		if unlocked:
			bag.pressed.connect(func(index=slot):
				if location=="vault":vault_page=index
				else:depot_page=index
				show_vault())
			if location=="vault":vault_page_controls[slot]=bag
			else:depot_page_controls[slot]=bag
			if slot==current_page:bag.add_theme_stylebox_override("normal",ui_box(Color("2b3b52"),5,C_GOLD,2));bag.add_theme_stylebox_override("hover",ui_box(Color("324761"),5,C_GOLD,3))
		else:bag.pressed.connect(func(index=slot):request_storage_bag_unlock(location,index))
		bags.add_child(bag)

func show_guild_storage(tab:String="vault") -> void:
	guild_storage_tab=tab if tab in ["vault","depot"] else "vault"
	show_vault()

func storage_tab_button(title:String,tab:String)->Button:
	var tab_button:=button(title,func():show_guild_storage(tab),230);tab_button.name="GuildStorage%sTab"%tab.capitalize();tab_button.custom_minimum_size.y=44
	if guild_storage_tab==tab:tab_button.add_theme_stylebox_override("normal",ui_box(Color("2b3b52"),5,C_GOLD,2));tab_button.add_theme_color_override("font_color",C_GOLD)
	return tab_button

func request_material_transfer(stack_id:String,target_location:String)->void:
	var stack:=InventorySystem.entry_by_id(state,stack_id)
	if stack.is_empty() or not bool(stack.get("is_material",false)):return
	var amount:=SpinBox.new();amount.name="MaterialTransferAmount";amount.min_value=1;amount.max_value=int(stack.get("quantity",1));amount.value=int(stack.get("quantity",1));amount.step=1;amount.position=Vector2(24,104);amount.size=Vector2(410,44)
	var dialog:=ConfirmationDialog.new();dialog.name="MaterialTransferDialog";dialog.title="Protect Material" if target_location=="vault" else "Release Material";dialog.dialog_text="Move %s to the %s?\n\nAmount:"%[str(stack.get("display_name","Material")),"Guild Vault" if target_location=="vault" else "Workshop Depot"];dialog.ok_button_text="Protect" if target_location=="vault" else "Release";dialog.min_size=Vector2i(460,240);dialog.add_child(amount)
	dialog.confirmed.connect(func():
		var result:=InventorySystem.transfer_material(state,stack_id,int(amount.value),target_location)
		if bool(result.get("success",false)):save_game();show_vault();flash("Material protected from production." if target_location=="vault" else "Material released to production.")
		else:flash(str(result.get("reason","Transfer failed."))))
	ui.add_child(dialog);dialog.popup_centered(Vector2i(460,240))

func add_storage_stack_count(cell:Button,entry:Dictionary,node_name:String)->void:
	var count:=Label.new();count.name=node_name;count.text=str(int(entry.get("quantity",0)));count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT);count.offset_left=-36;count.offset_top=-24;count.offset_right=-6;count.offset_bottom=-4;count.autowrap_mode=TextServer.AUTOWRAP_OFF;count.clip_text=true;count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;count.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;count.add_theme_font_size_override("font_size",10);count.add_theme_color_override("font_color",Color.WHITE);count.add_theme_stylebox_override("normal",ui_box(Color(0.02,0.03,0.05,.9),4));count.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(count)

func request_storage_transfer(entry_id:String,target_location:String)->void:
	var entry:=InventorySystem.entry_by_id(state,entry_id)
	if entry.is_empty():return
	if bool(entry.get("is_material",false)):request_material_transfer(entry_id,target_location);return
	var result:=InventorySystem.transfer_entry(state,entry_id,target_location)
	if bool(result.get("success",false)):
		save_game();show_vault();flash("Item protected in the Guild Vault." if target_location=="vault" else "Item sent to the Workshop Depot.")
	else:flash(str(result.get("reason","Transfer failed.")))

func populate_materials_depot(root:VBoxContainer)->void:
	var explanation:=PanelContainer.new();explanation.add_theme_stylebox_override("panel",ui_box(Color("172536"),6,Color("3d536d"),1));root.add_child(explanation)
	var explanation_text:=label("WORKSHOP SUPPLY  •  Materials arrive here automatically. Send unequipped gear here for enchanting, upgrades, or other Workshop orders. Vault items stay protected.",15,C_MUTED);explanation_text.custom_minimum_size=Vector2(1120,52);explanation_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;explanation_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;explanation.add_child(explanation_text)
	var entries:=InventorySystem.depot_entry_references(state);var total_units:=0;var material_stacks:=0;var equipment_count:=0
	for entry in entries:
		if bool(entry.get("is_material",false)):total_units+=int(entry.get("quantity",0));material_stacks+=1
		else:equipment_count+=1
	var summary:=HBoxContainer.new();summary.custom_minimum_size.y=44;summary.add_theme_constant_override("separation",12);root.add_child(summary)
	var summary_text:=label("%d / %d Slots  •  %d material stacks  •  %d gear items  •  %d units"%[InventorySystem.depot_occupied_count(state),InventorySystem.depot_capacity(state),material_stacks,equipment_count,total_units],17,C_GOLD);summary_text.custom_minimum_size.x=760;summary_text.autowrap_mode=TextServer.AUTOWRAP_OFF;summary_text.clip_text=true;summary_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;summary.add_child(summary_text)
	var summary_spacer:=Control.new();summary_spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;summary.add_child(summary_spacer);var workshop_link:=compact_button("Open Workshop",show_crafting,160);workshop_link.size_flags_vertical=Control.SIZE_SHRINK_CENTER;summary.add_child(workshop_link)
	var scroll:=ScrollContainer.new();scroll.name="MaterialsDepotScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
	var grid:=GridContainer.new();grid.name="MaterialsDepotGrid";grid.columns=4;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(grid)
	var page_count:=clampi(int(state.depot_level),1,GameData.STORAGE_BAG_SLOTS);depot_page=clampi(depot_page,0,page_count-1);var first_entry:=depot_page*InventorySystem.STORAGE_PAGE_SIZE;var visible_entries:=entries.slice(first_entry,mini(entries.size(),first_entry+InventorySystem.STORAGE_PAGE_SIZE))
	add_storage_bag_row(root,"depot")
	if entries.is_empty():var empty:=label("The Workshop Depot is empty. Collected materials and gear sent from the Vault will appear here.",18,C_MUTED);empty.custom_minimum_size=Vector2(900,120);empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;grid.add_child(empty);return
	if visible_entries.is_empty():var empty_page:=label("This Depot bag is empty.",18,C_MUTED);empty_page.custom_minimum_size=Vector2(900,120);empty_page.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;grid.add_child(empty_page);return
	for entry in visible_entries:
		var is_material:=bool(entry.get("is_material",false));var entry_button:=Button.new();entry_button.name="DepotStack_%s"%str(entry.get("instance_id",""));entry_button.custom_minimum_size=Vector2(280,138)
		entry_button.text="%s\n%s\n%s\n\nInspect / Protect"%[InventorySystem.fallback_glyph(str(entry.get("fallback_icon_type","material"))),str(entry.get("display_name","Material")),"%d available"%int(entry.get("quantity",0)) if is_material else "%s  •  Tier %s"%[str(entry.get("rarity","Common")),ItemData.roman_tier(int(entry.get("tier",1)))]]
		var frame_color:=Color(str(entry.get("color","e9f1ff"))) if is_material else Color(ItemData.RARITY_COLORS.get(str(entry.get("rarity","Common")),"e9f1ff"));entry_button.add_theme_font_size_override("font_size",15);entry_button.add_theme_color_override("font_color",frame_color);entry_button.tooltip_text="Available to Workshop orders. Tap to move this back to the protected Guild Vault.";entry_button.pressed.connect(func(id=str(entry.get("instance_id",""))):open_item_card(id,"depot"));grid.add_child(entry_button)

func populate_split_vault(root:VBoxContainer,full_width:bool=false)->void:
	var heading:=HBoxContainer.new();heading.custom_minimum_size.y=42;root.add_child(heading);var title:=label("GUILD VAULT",20,C_GOLD);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
	var warning:=InventorySystem.warning_state(state);var capacity_color:=C_RED if warning=="critical" else Color("ef9f65") if warning=="warning" else C_MUTED;var capacity:=label("%d / %d"%[InventorySystem.occupied_count(state),InventorySystem.capacity(state)],16,capacity_color);capacity.name="VaultCapacity";capacity.custom_minimum_size.x=92;capacity.autowrap_mode=TextServer.AUTOWRAP_OFF;capacity.clip_text=true;capacity.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;heading.add_child(capacity);var organize:=compact_button("⇅",auto_organize_vault,42);organize.name="AutoOrganizeVaultButton";organize.tooltip_text="Auto Organize Guild Vault";heading.add_child(organize)
	root.add_child(label("PROTECTED • Workshop cannot use these items",13,C_MUTED))
	var page_count:=clampi(int(state.vault_level),1,GameData.STORAGE_BAG_SLOTS);vault_page=clampi(vault_page,0,page_count-1)
	var scroll:=ScrollContainer.new();scroll.name="VaultStorageScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
	var grid:=GridContainer.new();grid.name="VaultStorageGrid";grid.columns=10 if full_width else 5;grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;scroll.add_child(grid)
	var first_flat:=vault_page*InventorySystem.STORAGE_PAGE_SIZE;var page_slots:=mini(InventorySystem.STORAGE_PAGE_SIZE,InventorySystem.capacity(state)-first_flat)
	for local_slot in page_slots:
		var flat_index:=first_flat+local_slot;var entry:=InventorySystem.entry_at(state,vault_page,local_slot);var cell:=Button.new();cell.name="VaultSlot%d"%flat_index;cell.custom_minimum_size=Vector2(96,58);cell.focus_mode=Control.FOCUS_NONE;cell.text="";cell.set_meta("storage_location","vault");cell.set_meta("storage_search_text","" if entry.is_empty() else storage_search_text_for(entry));cell.add_theme_stylebox_override("normal",ui_box(Color("172234"),6,Color("35445a"),1));cell.add_theme_stylebox_override("hover",ui_box(Color("21324a"),6,Color("50637d"),2));vault_slot_controls[flat_index]=cell;grid.add_child(cell)
		if not entry.is_empty():
			storage_entry_controls[str(entry.get("instance_id",""))]=cell
			var frame_color:=Color(str(entry.get("color","54d69a"))) if bool(entry.get("is_material",false)) else Color(ItemData.RARITY_COLORS.get(str(entry.get("rarity","Common")),"e9f1ff"));cell.add_theme_stylebox_override("normal",ui_box(Color("172234"),6,frame_color,2));cell.add_theme_stylebox_override("hover",ui_box(Color("21324a"),6,frame_color,3));cell.add_theme_stylebox_override("pressed",ui_box(Color("101a29"),6,frame_color,3))
			var icon:=item_icon_control(entry,Vector2(44,42));icon.name="VaultSlotIcon";icon.position=Vector2(26,8);icon.size=Vector2(44,42);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(icon)
			if bool(entry.get("is_material",false)):add_storage_stack_count(cell,entry,"VaultSlotStackCount")
			cell.gui_input.connect(func(event,id=str(entry.get("instance_id","")),control=cell):vault_slot_input(event,id,control))
	add_storage_bag_row(root,"vault",true)

func populate_split_depot(root:VBoxContainer,full_width:bool=false)->void:
	var entries:=InventorySystem.depot_entry_references(state);var materials:=0;var gear:=0
	for entry in entries:
		if bool(entry.get("is_material",false)):materials+=1
		else:gear+=1
	var heading:=HBoxContainer.new();heading.custom_minimum_size.y=42;root.add_child(heading);var title:=label("WORKSHOP DEPOT",20,C_GOLD);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title);var organize:=compact_button("⇅",auto_organize_depot,42);organize.name="AutoOrganizeDepotButton";organize.tooltip_text="Auto Organize Workshop Depot";heading.add_child(organize)
	var summary:=label("%d / %d SLOTS • %d MATERIAL • %d GEAR"%[InventorySystem.depot_occupied_count(state),InventorySystem.depot_capacity(state),materials,gear],13,C_MUTED);summary.name="DepotCapacity";root.add_child(summary)
	var page_count:=clampi(int(state.depot_level),1,GameData.STORAGE_BAG_SLOTS);depot_page=clampi(depot_page,0,page_count-1);var first:=depot_page*InventorySystem.STORAGE_PAGE_SIZE;var visible:=entries.slice(first,mini(entries.size(),first+InventorySystem.STORAGE_PAGE_SIZE))
	var scroll:=ScrollContainer.new();scroll.name="MaterialsDepotScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
	var grid:=GridContainer.new();grid.name="MaterialsDepotGrid";grid.columns=10 if full_width else 5;grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;scroll.add_child(grid)
	for local_slot in InventorySystem.STORAGE_PAGE_SIZE:
		var entry:Dictionary=visible[local_slot] if local_slot<visible.size() else {};var cell:=Button.new();cell.name="DepotStack_%s"%str(entry.get("instance_id","")) if not entry.is_empty() else "DepotSlot%d"%(first+local_slot);cell.custom_minimum_size=Vector2(96,58);cell.focus_mode=Control.FOCUS_NONE;cell.text="";cell.set_meta("storage_location","depot");cell.set_meta("storage_search_text","" if entry.is_empty() else storage_search_text_for(entry));cell.add_theme_stylebox_override("normal",ui_box(Color("172234"),6,Color("35445a"),1));cell.add_theme_stylebox_override("hover",ui_box(Color("21324a"),6,Color("50637d"),2));grid.add_child(cell)
		if not entry.is_empty():
			var entry_id:=str(entry.get("instance_id",""));storage_entry_controls[entry_id]=cell;var frame_color:=Color(str(entry.get("color","54d69a"))) if bool(entry.get("is_material",false)) else Color(ItemData.RARITY_COLORS.get(str(entry.get("rarity","Common")),"e9f1ff"));cell.add_theme_stylebox_override("normal",ui_box(Color("172234"),6,frame_color,2));cell.add_theme_stylebox_override("hover",ui_box(Color("21324a"),6,frame_color,3));cell.add_theme_stylebox_override("pressed",ui_box(Color("101a29"),6,frame_color,3))
			var icon:=item_icon_control(entry,Vector2(44,42));icon.name="DepotSlotIcon";icon.position=Vector2(26,8);icon.size=Vector2(44,42);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(icon)
			if bool(entry.get("is_material",false)):add_storage_stack_count(cell,entry,"DepotSlotStackCount")
			cell.tooltip_text="Click to inspect. Hold and drag left to protect in the Guild Vault.";cell.gui_input.connect(func(event,id=entry_id,control=cell):vault_slot_input(event,id,control))
	add_storage_bag_row(root,"depot",true)

func show_vault() -> void:
	InventorySystem.ensure_storage_state(state);screen="vault";var root=base_screen("Guild Storage");vault_slot_controls.clear();vault_page_controls.clear();depot_page_controls.clear();storage_entry_controls.clear();storage_panes.clear();add_storage_search_to_header(root)
	var both:=storage_search_scope=="Both";var layout:=HBoxContainer.new();layout.name="GuildStorageSplit" if both else "GuildStorageSingleView";layout.add_theme_constant_override("separation",14);layout.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(layout)
	var panes:Array=[["GuildVaultPane","vault"],["WorkshopDepotPane","depot"]] if both else [["GuildVaultPane","vault"]] if storage_search_scope=="Guild Vault" else [["WorkshopDepotPane","depot"]]
	for pane_data in panes:
		var panel:=PanelContainer.new();panel.name=str(pane_data[0]);panel.custom_minimum_size.x=590 if both else 0;panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",ui_box(Color("121d2d"),8,Color("40516a"),1));layout.add_child(panel)
		storage_panes[str(pane_data[1])]=panel
		var content:=VBoxContainer.new();content.add_theme_constant_override("separation",6);panel.add_child(content)
		if str(pane_data[1])=="vault":populate_split_vault(content,not both)
		else:populate_split_depot(content,not both)
	apply_storage_search_filter()
