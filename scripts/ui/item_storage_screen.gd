extends "res://scripts/ui/world_map_screen.gd"

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
	save_game();show_vault();flash("Item Storage organized.")
func request_bag_unlock(slot:int) -> void:
	if slot<state.vault_level:return
	var next_page:=int(state.vault_level);var cost=GameData.STORAGE_BAG_UNLOCK_BASE_COST*state.vault_level; var dialog:=ConfirmationDialog.new(); dialog.title="Unlock Storage"; dialog.dialog_text="Unlock a new storage page for ● %d?" % cost; dialog.ok_button_text="Unlock"
	dialog.confirmed.connect(func():
		if state.gold>=cost: state.gold-=cost; state.vault_level+=1; state.vault_limit=min(GameData.STORAGE_MAX_CAPACITY,state.vault_limit+GameData.STORAGE_BAG_CAPACITY);vault_page=next_page; save_game(); show_vault()
		else: flash("Not enough gold."))
	ui.add_child(dialog); dialog.popup_centered(Vector2i(420,180))

func show_vault() -> void:
	InventorySystem.ensure_storage_state(state);screen="vault";var root=base_screen("Item Storage");vault_slot_controls.clear();vault_page_controls.clear()
	var toolbar:=HBoxContainer.new();toolbar.custom_minimum_size.y=42;toolbar.add_theme_constant_override("separation",10);root.add_child(toolbar)
	var vault_gold:=label("●  %d"%state.gold,18,C_GOLD);vault_gold.custom_minimum_size.x=150;toolbar.add_child(vault_gold)
	var warning:=InventorySystem.warning_state(state);var capacity_color:=C_RED if warning=="critical" else Color("ef9f65") if warning=="warning" else C_MUTED;var capacity_text:="%d / %d Slots"%[InventorySystem.occupied_count(state),InventorySystem.capacity(state)];if warning=="critical":capacity_text="!  "+capacity_text
	var capacity_label:=label(capacity_text,17,capacity_color);capacity_label.custom_minimum_size.x=180;capacity_label.name="VaultCapacity";toolbar.add_child(capacity_label)
	var toolbar_spacer:=Control.new();toolbar_spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;toolbar.add_child(toolbar_spacer)
	var organize:=compact_button("⇅",auto_organize_vault,52);organize.custom_minimum_size.y=40;organize.tooltip_text="Auto Organize";toolbar.add_child(organize)

	var filters:=HBoxContainer.new();filters.add_theme_constant_override("separation",8);root.add_child(filters)
	filters.add_child(vault_option(["All Items","Weapons","Armor","Neck","Trinkets","Materials"],vault_category_filter,func(value):set_vault_filter("category",value),160))
	filters.add_child(vault_option(["All Status","Equipped","Unequipped"],vault_status_filter,func(value):set_vault_filter("status",value),145))
	filters.add_child(vault_option(["All Rarities"]+ItemData.RARITIES,vault_rarity_filter,func(value):set_vault_filter("rarity",value),150))
	var tier_values:Array=[0];tier_values.append_array(range(1,10));var tier:=vault_option(tier_values,vault_tier_filter,func(value):set_vault_filter("tier",value),115)
	for index in tier.item_count:tier.set_item_text(index,"All Tiers" if int(tier.get_item_metadata(index))==0 else "Tier %s"%ItemData.roman_tier(int(tier.get_item_metadata(index))))
	filters.add_child(tier)
	var page_count:=clampi(int(state.vault_level),1,GameData.STORAGE_BAG_SLOTS);vault_page=clampi(vault_page,0,page_count-1)
	var item_grid:=GridContainer.new();item_grid.name="VaultStorageGrid";item_grid.columns=GameData.STORAGE_COLUMNS;item_grid.add_theme_constant_override("h_separation",8);item_grid.add_theme_constant_override("v_separation",8);item_grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;root.add_child(item_grid)
	var first_flat:=vault_page*InventorySystem.STORAGE_PAGE_SIZE;var page_slots:=mini(InventorySystem.STORAGE_PAGE_SIZE,InventorySystem.capacity(state)-first_flat)
	for local_slot in page_slots:
		var flat_index:=first_flat+local_slot;var entry:=InventorySystem.entry_at(state,vault_page,local_slot);var visible_entry:=not entry.is_empty() and InventorySystem.matches_filter(entry,vault_category_filter,vault_status_filter,vault_rarity_filter,vault_tier_filter)
		var cell:=Button.new();cell.name="VaultSlot%d"%flat_index;cell.custom_minimum_size=Vector2(96,88);cell.focus_mode=Control.FOCUS_NONE;cell.text="";cell.add_theme_stylebox_override("normal",ui_box(Color("172234"),6,Color("35445a"),1));cell.add_theme_stylebox_override("hover",ui_box(Color("21324a"),6,Color("50637d"),2));vault_slot_controls[flat_index]=cell;item_grid.add_child(cell)
		if visible_entry:
			var frame_color:=Color(str(entry.get("color","54d69a"))) if bool(entry.get("is_material",false)) else Color(ItemData.RARITY_COLORS.get(str(entry.get("rarity","Common")),"e9f1ff"));cell.add_theme_stylebox_override("normal",ui_box(Color("172234"),6,frame_color,2));cell.add_theme_stylebox_override("hover",ui_box(Color("21324a"),6,frame_color,3));cell.add_theme_stylebox_override("pressed",ui_box(Color("101a29"),6,frame_color,3))
			var slot_icon:=item_icon_control(entry,Vector2(76,70));slot_icon.name="VaultSlotIcon";slot_icon.position=Vector2(10,8);slot_icon.size=Vector2(76,70);slot_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(slot_icon)
			if bool(entry.get("is_material",false)):
				var stack_count:=label(str(int(entry.get("quantity",0))),12,Color.WHITE);stack_count.name="VaultSlotStackCount";stack_count.position=Vector2(50,58);stack_count.size=Vector2(40,24);stack_count.autowrap_mode=TextServer.AUTOWRAP_OFF;stack_count.clip_text=true;stack_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;stack_count.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;stack_count.add_theme_stylebox_override("normal",ui_box(Color(0.02,0.03,0.05,.88),4));stack_count.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(stack_count)
			cell.gui_input.connect(func(event,id=str(entry.get("instance_id","")),control=cell):vault_slot_input(event,id,control))
		elif not entry.is_empty():cell.modulate=Color(1,1,1,.24)
	var expansion_gap:=Control.new();expansion_gap.custom_minimum_size.y=8;root.add_child(expansion_gap)
	var expansion_panel:=PanelContainer.new();expansion_panel.name="VaultExpansionRow";expansion_panel.add_theme_stylebox_override("panel",ui_box(Color("131e2e"),6,Color("2c3b50"),1));root.add_child(expansion_panel)
	var expansion_content:=HBoxContainer.new();expansion_content.alignment=BoxContainer.ALIGNMENT_CENTER;expansion_content.add_theme_constant_override("separation",16);expansion_panel.add_child(expansion_content)
	var bags:=HBoxContainer.new();bags.name="VaultPageBags";bags.add_theme_constant_override("separation",8);expansion_content.add_child(bags)
	for slot in GameData.STORAGE_BAG_SLOTS:
		var unlocked:bool=int(slot)<int(state.vault_level);var bag:=Button.new();bag.name="VaultPageBag%d"%slot;bag.custom_minimum_size=Vector2(58,48);bag.text="▣" if unlocked else "▧";bag.add_theme_font_size_override("font_size",24);bag.modulate=Color.WHITE if unlocked else Color(.35,.38,.45,1)
		if unlocked:
			bag.pressed.connect(func(index=slot):vault_page=index;show_vault());vault_page_controls[slot]=bag
			if slot==vault_page:bag.add_theme_stylebox_override("normal",ui_box(Color("2b3b52"),5,C_GOLD,2));bag.add_theme_stylebox_override("hover",ui_box(Color("324761"),5,C_GOLD,3))
		else:bag.pressed.connect(func(index=slot):request_bag_unlock(index))
		bags.add_child(bag)
