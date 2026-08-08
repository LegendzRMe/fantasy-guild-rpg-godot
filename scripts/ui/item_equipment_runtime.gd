extends "res://scripts/ui/guild_hall_runtime.gd"

func hero_equipped_items(hero:Dictionary)->Array:
	return ItemData.equipped_instances(hero,state.get("item_instances",[]))

func has_item_passive(items:Array,passive_id:String)->bool:
	for item in items:
		if passive_id in item.get("passive_effect_ids",[]):return true
	return false

func hero_has_passive(hero:Dictionary,passive_id:String)->bool:
	return has_item_passive(hero.get("equipped_items",[]),passive_id)

func equipped_item_in_slot(hero:Dictionary,slot:String)->Dictionary:
	var instance_id=hero.get("equipment_slots",{}).get(slot,null)
	if instance_id==null:return {}
	for item in state.get("item_instances",[]):
		if str(item.get("instance_id",""))==str(instance_id):return item
	return {}

func hero_final_stats(hero:Dictionary,buffs:Array=[])->Dictionary:
	return CombatSystem.calculate_final_stats(CLASSES[hero["class"]],int(hero.get("level",1)),hero_equipped_items(hero),buffs)

func select_equipment_slot(slot:String)->void:
	equipment_selected_slot=slot
	equipment_candidate_id=""
	var current:=equipped_item_in_slot(state.heroes[selected_roster_index],slot)
	if current.is_empty():show_equipment_carousel(selected_roster_index,slot)
	else:open_item_card(str(current.get("instance_id","")),"roster_slot")

func close_item_overlay()->void:
	if item_card_overlay!=null and is_instance_valid(item_card_overlay):item_card_overlay.queue_free()
	item_card_overlay=null
	item_overlay_mode=""
	item_overlay_back_action=Callable()
	item_overlay_confirmation_active=false
	item_carousel_swiping=false
	item_carousel_drag_offset=0.0
	item_carousel_transitioning=false

func navigate_item_overlay_back()->void:
	if item_overlay_confirmation_active:return
	if item_overlay_back_action.is_valid():
		var back_action:=item_overlay_back_action
		item_overlay_back_action=Callable()
		back_action.call()
	else:close_item_overlay()

func create_item_overlay(back_action:Callable=Callable())->Control:
	close_item_overlay()
	item_overlay_back_action=back_action
	var overlay:=Control.new();overlay.name="ItemOverlay";overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_STOP;ui.add_child(overlay);item_card_overlay=overlay
	var backdrop:=Button.new();backdrop.name="ItemCardBackdrop";backdrop.flat=true;backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.focus_mode=Control.FOCUS_NONE;backdrop.add_theme_stylebox_override("normal",ui_box(Color(0.01,0.02,0.04,.76),0));backdrop.pressed.connect(func():
		if not item_overlay_confirmation_active:close_item_overlay())

	overlay.add_child(backdrop)
	if back_action.is_valid():
		var back:=compact_button("Back",navigate_item_overlay_back,104);back.name="ItemOverlayBack";back.position=Vector2(24,20);back.custom_minimum_size=Vector2(104,44);overlay.add_child(back)
	return overlay

func equipment_comparison(instance_id:String,hero_index:int)->Dictionary:
	if hero_index<0 or hero_index>=state.heroes.size():return {}
	var item:=ItemData.item_by_instance_id(state.get("item_instances",[]),instance_id)
	if item.is_empty():return {}
	var before:=hero_final_stats(state.heroes[hero_index]);var simulated:Dictionary=state.duplicate(true)
	var result:=ItemData.equip_in_state(simulated,hero_index,instance_id,CLASSES)
	if not bool(result.get("success",false)):return {"summary":str(result.get("reason","Cannot equip"))}
	var simulated_items:=ItemData.equipped_instances(simulated.heroes[hero_index],simulated.item_instances)
	var after:=CombatSystem.calculate_final_stats(CLASSES[simulated.heroes[hero_index]["class"]],int(simulated.heroes[hero_index].get("level",1)),simulated_items)
	var rows:Array=[]
	var comparisons:=[
		["Health",float(before.health),float(after.health),false],
		["Power",float(before.power),float(after.power),false],
		["Armor",float(before.armor),float(after.armor),false],
		["Armor Reduction",float(before.armor_reduction)*100.0,float(after.armor_reduction)*100.0,true],
		["Basic Action",float(before.basic_action_amount),float(after.basic_action_amount),false],
		["Action Interval",float(before.basic_action_interval),float(after.basic_action_interval),false],
		["Critical Chance",float(before.critical_chance)*100.0,float(after.critical_chance)*100.0,true]
	]
	for comparison in comparisons:
		if is_equal_approx(comparison[1],comparison[2]):continue
		var suffix:="%" if comparison[3] else (" sec" if comparison[0]=="Action Interval" else "")
		var direction:="faster" if comparison[0]=="Action Interval" and comparison[2]<comparison[1] else "slower" if comparison[0]=="Action Interval" else "increased" if comparison[2]>comparison[1] else "decreased"
		var before_text:=str(int(floor(float(comparison[1])))) if comparison[0]=="Basic Action" else "%.1f"%comparison[1]
		var after_text:=str(int(floor(float(comparison[2])))) if comparison[0]=="Basic Action" else "%.1f"%comparison[2]
		rows.append("%s   %s%s  →  %s%s  (%s)"%[comparison[0],before_text,suffix,after_text,suffix,direction])
	var current:=equipped_item_in_slot(state.heroes[hero_index],str(item.get("slot","")))
	var old_passives:Array=current.get("passive_effect_ids",[]) if not current.is_empty() else []
	var new_passives:Array=item.get("passive_effect_ids",[])
	for passive_id in old_passives:
		if passive_id not in new_passives:rows.append("Passive lost: %s"%ItemData.PASSIVE_EFFECTS.get(passive_id,{"display_name":passive_id}).display_name)
	for passive_id in new_passives:
		if passive_id not in old_passives:rows.append("Passive gained: %s"%ItemData.PASSIVE_EFFECTS.get(passive_id,{"display_name":passive_id}).display_name)
	var previous_owner:=int(item.get("equipped_hero_index",-1))
	if previous_owner>=0 and previous_owner!=hero_index:rows.push_front("Currently equipped by %s. Moving it leaves that slot empty."%state.heroes[previous_owner].name)
	if rows.is_empty():rows.append("No resolved combat values change.")
	return {"summary":"\n".join(rows)}

func item_card_actions(item:Dictionary,origin:String)->Array:
	if bool(item.get("is_material",false)):
		return [{"id":"release_material","label":"Release to Depot"}] if InventorySystem.storage_location(item)=="vault" else [{"id":"protect_material","label":"Protect in Vault"}]
	if origin=="equipment_preview":
		var current:=equipped_item_in_slot(state.heroes[pending_item_hero_index],str(item.get("slot",""))) if pending_item_hero_index>=0 else {}
		var previous_owner:=int(item.get("equipped_hero_index",-1));var label_text:="Move Item" if previous_owner>=0 and previous_owner!=pending_item_hero_index else "Replace" if not current.is_empty() and str(current.get("instance_id",""))!=str(item.get("instance_id","")) else "Equip"
		return [{"id":"confirm_equip","label":label_text},{"id":"cancel_preview","label":"Cancel"}]
	var owner:=int(item.get("equipped_hero_index",-1))
	if origin=="roster_slot":return [{"id":"unequip_item","label":"Unequip"},{"id":"change_equipment","label":"Change Equipment"}]
	if owner<0:
		if InventorySystem.storage_location(item)=="depot":return [{"id":"move_to_vault","label":"Protect in Vault"}]
		return [{"id":"move_to_depot","label":"Send to Depot"},{"id":"choose_hero","label":"Choose Hero"}]
	if origin=="vault":return [{"id":"unequip_item","label":"Unequip"},{"id":"change_hero","label":"Change Hero"}]
	return [{"id":"view_hero","label":"View Hero"},{"id":"change_hero","label":"Change Hero"},{"id":"unequip_item","label":"Unequip"}]

func open_item_card(entry_id:String,origin:String="vault",comparison:Dictionary={},back_action:Callable=Callable())->void:
	var entry:=InventorySystem.entry_by_id(state,entry_id)
	if entry.is_empty():return
	var data:=InventorySystem.material_card_data(entry) if bool(entry.get("is_material",false)) else ItemData.item_card_data(entry,state.heroes)
	var overlay:=create_item_overlay(back_action);item_overlay_mode="item_card";var card:=ItemCardView.new();card.name="SharedItemCard";card.position=Vector2((W-460.0)*.5,50);card.size=Vector2(460,620);card.configure(data,item_card_actions(entry,origin),comparison);card.close_requested.connect(navigate_item_overlay_back);card.action_requested.connect(func(action):handle_item_card_action(action,entry_id));overlay.add_child(card)

func handle_item_card_action(action:String,entry_id:String)->void:
	var item:=InventorySystem.entry_by_id(state,entry_id)
	if item.is_empty():close_item_overlay();return
	match action:
		"release_material":close_item_overlay();request_material_transfer(entry_id,"depot")
		"protect_material":close_item_overlay();request_material_transfer(entry_id,"vault")
		"move_to_depot":close_item_overlay();request_storage_transfer(entry_id,"depot")
		"move_to_vault":close_item_overlay();request_storage_transfer(entry_id,"vault")
		"choose_hero","change_hero":show_item_hero_selector(entry_id)
		"change_equipment":show_equipment_carousel(selected_roster_index,str(item.get("slot","")),str(item.get("instance_id","")))
		"view_hero":
			var owner:=int(item.get("equipped_hero_index",-1))
			if owner>=0:selected_roster_index=owner
			equipment_selected_slot="";close_item_overlay();show_roster()
		"unequip_item":
			var owner:=int(item.get("equipped_hero_index",-1))
			if owner>=0:ItemData.unequip_from_state(state,owner,str(item.get("slot","")))
			save_game();close_item_overlay()
			if screen=="vault":show_vault()
			else:show_roster()
		"confirm_equip":confirm_item_equip(entry_id,pending_item_hero_index,pending_item_origin)
		"cancel_preview":navigate_item_overlay_back()

func item_icon_control(item:Dictionary,icon_size:Vector2)->Control:
	var definition:=ItemData.definition_for_instance(item)

	var icon_path:=str(definition.get("icon_path",item.get("icon_path","")))
	if icon_path!="" and ResourceLoader.exists(icon_path):
		var icon:=TextureRect.new()
		icon.texture=load(icon_path);icon.custom_minimum_size=icon_size;icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		return icon
	var fallback:=label(InventorySystem.fallback_glyph(str(definition.get("fallback_icon_type",item.get("fallback_icon_type",item.get("slot","item"))))),24,Color(ItemData.RARITY_COLORS.get(str(item.get("rarity","Common")),"e9f1ff")))
	fallback.custom_minimum_size=icon_size;fallback.autowrap_mode=TextServer.AUTOWRAP_OFF;fallback.clip_text=true;fallback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;fallback.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;fallback.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return fallback

func create_item_carousel_track(overlay:Control)->Control:
	var track:=Control.new();track.name="ItemCarouselTrack";track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);track.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(track)
	item_carousel_track=track
	return track

func carousel_can_shift(direction:int)->bool:
	if item_overlay_mode=="equipment_carousel":return item_carousel_index+direction>=0 and item_carousel_index+direction<item_carousel_items.size()
	if item_overlay_mode=="hero_carousel":return hero_carousel_index+direction>=0 and hero_carousel_index+direction<hero_carousel_indices.size()
	return false

func update_item_carousel_drag(offset:float)->void:
	var track:=item_carousel_track
	if track==null:return
	var direction:=-1 if offset>0.0 else 1
	var resistance:=1.0 if carousel_can_shift(direction) else 0.22
	item_carousel_drag_offset=clampf(offset*resistance,-300.0,300.0);track.position.x=item_carousel_drag_offset

func finish_item_carousel_drag(offset:float)->void:
	var track:=item_carousel_track
	if track==null:return
	var overlay_ref:=item_card_overlay
	var direction:=-1 if offset>0.0 else 1
	if absf(offset)<55.0 or not carousel_can_shift(direction):
		item_carousel_transitioning=true
		var reset:=create_tween();reset.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);reset.tween_property(track,"position:x",0.0,.14);reset.finished.connect(func():item_carousel_transitioning=false;item_carousel_drag_offset=0.0)
		return
	item_carousel_transitioning=true
	var slide:=create_tween();slide.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);slide.tween_property(track,"position:x",-float(direction)*W,.16);slide.finished.connect(func():item_carousel_transitioning=false;item_carousel_drag_offset=0.0;if item_card_overlay==overlay_ref:shift_active_item_carousel(direction))

func animate_item_carousel_shift(direction:int)->void:
	if item_carousel_transitioning or not carousel_can_shift(direction):return
	finish_item_carousel_drag(-80.0 if direction>0 else 80.0)

func make_item_carousel_peek(item:Dictionary,direction:int)->Button:
	var rarity_color:=Color(ItemData.RARITY_COLORS.get(str(item.get("rarity","Common")),"e9f1ff"))
	var peek:=Button.new();peek.name="ItemCarouselPeekLeft" if direction<0 else "ItemCarouselPeekRight";peek.position=Vector2(292,150) if direction<0 else Vector2(768,150);peek.size=Vector2(220,420);peek.clip_contents=true;peek.modulate=Color(0.62,0.62,0.67,0.72);peek.add_theme_stylebox_override("normal",ui_box(Color("111b2a"),10,rarity_color,2));peek.pressed.connect(func():animate_item_carousel_shift(direction))
	var content:=VBoxContainer.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,12);content.alignment=BoxContainer.ALIGNMENT_CENTER;content.mouse_filter=Control.MOUSE_FILTER_IGNORE;peek.add_child(content)
	content.add_child(item_icon_control(item,Vector2(180,300)))
	return peek

func show_equipment_carousel(hero_index:int,slot:String,return_instance_id:String="",preferred_index:int=0)->void:
	if hero_index<0 or hero_index>=state.heroes.size():return
	var hero:Dictionary=state.heroes[hero_index]
	var candidates:Array=[]
	for item in state.get("item_instances",[]):
		if str(item.get("slot",""))!=slot or str(item.get("instance_id",""))==return_instance_id:continue
		if ItemData.compatibility_reason(item,CLASSES[hero["class"]],str(hero["class"]))=="":candidates.append(item)
	candidates.sort_custom(func(a,b):return str(a.get("display_name",""))<str(b.get("display_name","")))
	item_carousel_items=candidates;item_carousel_index=clampi(preferred_index,0,maxi(0,candidates.size()-1));item_carousel_hero_index=hero_index;item_carousel_slot=slot;item_carousel_return_instance_id=return_instance_id
	var return_action:Callable=Callable()
	if return_instance_id!="":return_action=func(id=return_instance_id):open_item_card(id,"roster_slot")
	var overlay:=create_item_overlay(return_action);item_overlay_mode="equipment_carousel"
	var heading:=label("%s EQUIPMENT  •  %s"%[slot.to_upper(),str(hero.get("name","Hero"))],18,C_GOLD);heading.position=Vector2(150,24);heading.size=Vector2(300,40);overlay.add_child(heading)
	if candidates.is_empty():
		var empty_panel:=PanelContainer.new();empty_panel.name="EquipmentCarouselEmpty";empty_panel.position=Vector2(390,205);empty_panel.size=Vector2(500,250);empty_panel.add_theme_stylebox_override("panel",ui_box(Color("172234"),12,Color("35445a"),2));overlay.add_child(empty_panel)
		var empty_text:=label("No compatible %s items are currently stored."%slot.capitalize(),20,C_MUTED);empty_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;empty_panel.add_child(empty_text)
		return
	var current:Dictionary=candidates[item_carousel_index]
	var track:=create_item_carousel_track(overlay)
	if item_carousel_index>0:track.add_child(make_item_carousel_peek(candidates[item_carousel_index-1],-1))
	if item_carousel_index<candidates.size()-1:track.add_child(make_item_carousel_peek(candidates[item_carousel_index+1],1))
	var card:=ItemCardView.new();card.name="EquipmentCarouselCard";card.position=Vector2((W-460.0)*.5,50);card.size=Vector2(460,620);card.configure(ItemData.item_card_data(current,state.heroes),[{"id":"equip_carousel_item","label":"Equip"}]);card.action_requested.connect(func(_action):equip_item_carousel_candidate());track.add_child(card)
	var tap_target:=Button.new();tap_target.name="EquipmentCarouselTapTarget";tap_target.position=Vector2((W-460.0)*.5,50);tap_target.size=Vector2(460,275);tap_target.flat=true;tap_target.focus_mode=Control.FOCUS_NONE;tap_target.add_theme_stylebox_override("normal",ui_box(Color(0,0,0,0),12));tap_target.add_theme_stylebox_override("hover",ui_box(Color(1,1,1,.035),12,C_GOLD,1));tap_target.pressed.connect(equip_item_carousel_candidate);track.add_child(tap_target)
	var previous:=compact_button("←",func():animate_item_carousel_shift(-1),58);previous.name="EquipmentCarouselPrevious";previous.position=Vector2(218,330);previous.custom_minimum_size=Vector2(58,58);previous.disabled=item_carousel_index==0;overlay.add_child(previous)
	var next:=compact_button("→",func():animate_item_carousel_shift(1),58);next.name="EquipmentCarouselNext";next.position=Vector2(1004,330);next.custom_minimum_size=Vector2(58,58);next.disabled=item_carousel_index==candidates.size()-1;overlay.add_child(next)

func equip_item_carousel_candidate()->void:
	if item_carousel_items.is_empty():return
	var item:Dictionary=item_carousel_items[item_carousel_index]
	var previous_owner:=int(item.get("equipped_hero_index",-1))
	if previous_owner>=0 and previous_owner!=item_carousel_hero_index:
		item_overlay_confirmation_active=true
		var dialog:=ConfirmationDialog.new();dialog.name="MoveEquipmentConfirmation";dialog.title="Move Equipment?";dialog.dialog_text="%s is equipped by %s. Move it to %s?"%[str(item.get("display_name","This item")),str(state.heroes[previous_owner].get("name","another hero")),str(state.heroes[item_carousel_hero_index].get("name","this hero"))];dialog.ok_button_text="Move Item";item_card_overlay.add_child(dialog)
		dialog.confirmed.connect(func():item_overlay_confirmation_active=false;complete_item_carousel_equip(str(item.get("instance_id",""))))
		dialog.canceled.connect(func():item_overlay_confirmation_active=false)
		dialog.close_requested.connect(func():item_overlay_confirmation_active=false)
		dialog.popup_centered(Vector2i(480,210))
		return
	complete_item_carousel_equip(str(item.get("instance_id","")))

func complete_item_carousel_equip(instance_id:String)->void:
	var hero_index:=item_carousel_hero_index
	var result:=ItemData.equip_in_state(state,hero_index,instance_id,CLASSES)
	if bool(result.get("success",false)):save_game();toast="Equipment updated";equipment_selected_slot="";equipment_candidate_id=""
	else:toast=str(result.get("reason","Cannot equip this item"))
	toast_time=2.5;close_item_overlay();selected_roster_index=hero_index;show_roster()

func make_hero_carousel_card(hero_index:int,focused:bool,direction:int=0)->Button:
	var hero:Dictionary=state.heroes[hero_index]
	var item:=ItemData.item_by_instance_id(state.get("item_instances",[]),hero_carousel_item_id);var slot:=str(item.get("slot",""));var current:=equipped_item_in_slot(hero,slot);var current_name:="None" if current.is_empty() else str(current.get("display_name","Item"))
	var card:=Button.new();card.name="HeroCarouselCard" if focused else "HeroCarouselPeekLeft" if direction<0 else "HeroCarouselPeekRight";card.position=Vector2(390,145) if focused else Vector2(282,205) if direction<0 else Vector2(778,205);card.size=Vector2(500,430) if focused else Vector2(220,310);card.text="%s\n\n%s\n%s  •  Level %d\n\nCurrent %s\n%s\n\n%s"%[role_glyph(str(hero.get("class",""))),str(hero.get("name","Hero")),str(hero.get("class","Hero")),int(hero.get("level",1)),slot.capitalize(),current_name,"SELECT HERO" if focused else ""];card.add_theme_font_size_override("font_size",24 if focused else 16);card.add_theme_color_override("font_color",CLASSES[str(hero.get("class","Guardian"))].color);card.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.modulate=Color.WHITE if focused else Color(0.62,0.62,0.67,0.72);card.add_theme_stylebox_override("normal",ui_box(Color("172234"),12,C_GOLD if focused else Color("35445a"),3 if focused else 2))
	return card

func show_item_hero_selector(instance_id:String,preferred_index:int=0)->void:
	var item:=ItemData.item_by_instance_id(state.get("item_instances",[]),instance_id)
	if item.is_empty():return
	var compatible:Array=[]
	for hero_index in state.heroes.size():
		var hero:Dictionary=state.heroes[hero_index]
		if str(hero.get("activity",""))=="" and ItemData.compatibility_reason(item,CLASSES[hero["class"]],str(hero["class"]))=="":compatible.append(hero_index)
	hero_carousel_indices=compatible;hero_carousel_index=clampi(preferred_index,0,maxi(0,compatible.size()-1));hero_carousel_item_id=instance_id
	var overlay:=create_item_overlay();item_overlay_mode="hero_carousel"
	var heading:=label("CHOOSE HERO  •  %s"%str(item.get("display_name","Item")),18,C_GOLD);heading.position=Vector2(150,24);heading.size=Vector2(600,40);overlay.add_child(heading)
	if compatible.is_empty():

		var empty:=label("No available hero can equip this item.",20,C_MUTED);empty.position=Vector2(390,320);empty.size=Vector2(500,80);empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;overlay.add_child(empty)
		return
	var track:=create_item_carousel_track(overlay)
	if hero_carousel_index>0:
		var left:=make_hero_carousel_card(compatible[hero_carousel_index-1],false,-1);left.pressed.connect(func():animate_item_carousel_shift(-1));track.add_child(left)
	if hero_carousel_index<compatible.size()-1:
		var right:=make_hero_carousel_card(compatible[hero_carousel_index+1],false,1);right.pressed.connect(func():animate_item_carousel_shift(1));track.add_child(right)
	var focus:=make_hero_carousel_card(compatible[hero_carousel_index],true);focus.pressed.connect(func():open_equipment_preview(instance_id,compatible[hero_carousel_index],"vault"));track.add_child(focus)
	var previous:=compact_button("←",func():animate_item_carousel_shift(-1),58);previous.name="HeroCarouselPrevious";previous.position=Vector2(210,330);previous.custom_minimum_size=Vector2(58,58);previous.disabled=hero_carousel_index==0;overlay.add_child(previous)
	var next:=compact_button("→",func():animate_item_carousel_shift(1),58);next.name="HeroCarouselNext";next.position=Vector2(1012,330);next.custom_minimum_size=Vector2(58,58);next.disabled=hero_carousel_index==compatible.size()-1;overlay.add_child(next)

func shift_active_item_carousel(direction:int)->void:
	if item_overlay_mode=="equipment_carousel":
		var next_index:=clampi(item_carousel_index+direction,0,maxi(0,item_carousel_items.size()-1))
		if next_index!=item_carousel_index:show_equipment_carousel(item_carousel_hero_index,item_carousel_slot,item_carousel_return_instance_id,next_index)
	elif item_overlay_mode=="hero_carousel":
		var next_index:=clampi(hero_carousel_index+direction,0,maxi(0,hero_carousel_indices.size()-1))
		if next_index!=hero_carousel_index:show_item_hero_selector(hero_carousel_item_id,next_index)

func open_equipment_preview(instance_id:String,hero_index:int,origin:String)->void:
	pending_item_instance_id=instance_id;pending_item_hero_index=hero_index;pending_item_origin=origin;equipment_candidate_id=instance_id
	var back_action:Callable
	if origin=="vault":back_action=func():show_item_hero_selector(instance_id,hero_carousel_index)
	else:
		var preview_item:=ItemData.item_by_instance_id(state.get("item_instances",[]),instance_id)
		back_action=func():show_equipment_carousel(hero_index,str(preview_item.get("slot","")),item_carousel_return_instance_id,item_carousel_index)
	open_item_card(instance_id,"equipment_preview",equipment_comparison(instance_id,hero_index),back_action)

func confirm_item_equip(instance_id:String,hero_index:int,origin:String)->void:
	var result:=ItemData.equip_in_state(state,hero_index,instance_id,CLASSES)
	if bool(result.get("success",false)):save_game();toast="Equipment updated";toast_time=2.5
	else:toast=str(result.get("reason","Cannot equip this item"));toast_time=2.5
	close_item_overlay();pending_item_instance_id="";pending_item_hero_index=-1;equipment_candidate_id=""
	if origin=="roster":selected_roster_index=hero_index;show_roster()
	else:show_vault()
