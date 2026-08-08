extends PanelContainer

signal action_requested(action:String)
signal close_requested

const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const ItemData = preload("res://scripts/data/item_data.gd")

const CARD_BACKGROUND := Color("172234")
const CARD_INSET := Color("111b2a")
const TEXT_COLOR := Color("e9f1ff")
const MUTED_COLOR := Color("9fb1ca")
const STORED_COLOR := Color("54d69a")

var card_data:Dictionary={}

func _label(text:String,size:int,color:Color)->Label:
	var result:=Label.new()
	result.text=text
	result.add_theme_font_size_override("font_size",size)
	result.add_theme_color_override("font_color",color)
	result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return result

func _single_line_label(text:String,size:int,color:Color)->Label:
	var result:=_label(text,size,color)
	result.autowrap_mode=TextServer.AUTOWRAP_OFF
	result.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	return result

func _centered_label(text:String,size:int,color:Color)->Label:
	var result:=_label(text,size,color)
	result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	return result

func _rule(color:Color)->HSeparator:
	var separator:=HSeparator.new()
	var line:=StyleBoxFlat.new()
	line.bg_color=Color(color,.34)
	line.content_margin_top=1
	line.content_margin_bottom=1
	separator.add_theme_stylebox_override("separator",line)
	return separator

func _inset_panel(border_color:Color,border_width:int=1,radius:int=8)->StyleBoxFlat:
	var panel:=StyleBoxFlat.new()
	panel.bg_color=CARD_INSET
	panel.border_color=border_color
	panel.set_border_width_all(border_width)
	panel.corner_radius_top_left=radius
	panel.corner_radius_top_right=radius
	panel.corner_radius_bottom_left=radius
	panel.corner_radius_bottom_right=radius
	return panel

func _item_type_text(data:Dictionary)->String:
	if str(data.get("kind","equipment"))=="material":
		return "Material Stack  %d / %d"%[int(data.get("quantity",0)),int(data.get("max_stack",100))]
	var slot:=str(data.get("slot",""))
	var family:=str(data.get("weapon_family_requirement",""))
	if slot=="weapon":
		return "%s Weapon"%family.replace("_"," ").capitalize() if family!="" else "Weapon"
	var armor_requirement=data.get("armor_family_requirement","")
	var armor_family:=""
	if armor_requirement is Array and not armor_requirement.is_empty():armor_family=" or ".join(armor_requirement).capitalize()
	elif str(armor_requirement)!="":armor_family=str(armor_requirement).capitalize()
	if slot in ["head","chest","hands"]:
		return "%s%s Armor"%[armor_family+" " if armor_family!="" else "",slot.capitalize()]
	return str(data.get("slot_text",slot.capitalize()))

func _owner_glyph(hero_class:String)->String:
	return {"Guardian":"SHD","Cleric":"+","Ranger":"BOW","Mage":"WND","Rogue":"DW","Warlock":"WND"}.get(hero_class,hero_class.left(3).to_upper())

func _make_icon(data:Dictionary,rarity_color:Color)->Control:
	var frame:=PanelContainer.new()
	frame.name="ItemCardIcon"
	frame.custom_minimum_size=Vector2(126,126)
	frame.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel",_inset_panel(rarity_color,2,10))
	var icon_path:=str(data.get("icon_path",""))
	if icon_path!="" and ResourceLoader.exists(icon_path):
		var icon_texture:=TextureRect.new()
		icon_texture.texture=load(icon_path)
		icon_texture.custom_minimum_size=Vector2(112,112)
		icon_texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon_texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(icon_texture)
	else:
		var fallback:=_centered_label(InventorySystem.fallback_glyph(str(data.get("fallback_icon_type","item"))),29,rarity_color)
		fallback.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		fallback.custom_minimum_size=Vector2(112,112)
		frame.add_child(fallback)
	return frame

func _add_owner_row(outer:VBoxContainer,data:Dictionary,rarity_color:Color)->void:
	var owner_index:=int(data.get("owner_index",-1))
	var owner_name:=str(data.get("owner_name",""))
	if owner_index<0 or owner_name=="":
		var stored:=_single_line_label(str(data.get("status","Stored in Guild Vault")),15,STORED_COLOR)
		stored.name="ItemCardStorageStatus"
		stored.custom_minimum_size.y=42
		stored.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		stored.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		outer.add_child(stored)
		return
	var row:=HBoxContainer.new()
	row.name="ItemCardOwnerRow"
	row.alignment=BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size.y=52
	row.add_theme_constant_override("separation",10)
	outer.add_child(row)
	var prefix:=_single_line_label("Equipped by:",15,MUTED_COLOR)
	prefix.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	row.add_child(prefix)
	var portrait:=PanelContainer.new()
	portrait.name="ItemCardOwnerPortrait"
	portrait.custom_minimum_size=Vector2(44,44)
	portrait.tooltip_text="%s — %s"%[owner_name,str(data.get("owner_class","Hero"))]
	portrait.add_theme_stylebox_override("panel",_inset_panel(rarity_color,2,22))
	var portrait_glyph:=_centered_label(_owner_glyph(str(data.get("owner_class",""))),13,rarity_color)
	portrait_glyph.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	portrait.add_child(portrait_glyph)
	row.add_child(portrait)
	var owner:=_single_line_label(owner_name,16,TEXT_COLOR)
	owner.name="ItemCardOwnerName"
	owner.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	row.add_child(owner)

func _card_style(rarity_color:Color)->StyleBoxFlat:
	var panel:=StyleBoxFlat.new()
	panel.bg_color=CARD_BACKGROUND
	panel.border_color=rarity_color
	panel.set_border_width_all(3)
	panel.corner_radius_top_left=12
	panel.corner_radius_top_right=12
	panel.corner_radius_bottom_left=12
	panel.corner_radius_bottom_right=12
	panel.content_margin_left=24
	panel.content_margin_right=24
	panel.content_margin_top=18
	panel.content_margin_bottom=18
	return panel

func _add_card_header(outer:VBoxContainer,data:Dictionary,rarity:String,rarity_color:Color)->void:
	var top_line:=HBoxContainer.new()
	top_line.custom_minimum_size.y=28
	top_line.add_theme_constant_override("separation",16)
	outer.add_child(top_line)
	var rarity_prefix:="★ " if rarity=="Legendary" else ""
	var rarity_label:=_single_line_label(rarity_prefix+rarity.to_upper(),15,rarity_color)
	rarity_label.name="ItemCardRarity"
	rarity_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top_line.add_child(rarity_label)
	var tier_label:=_single_line_label(str(data.get("tier_text","" )).to_upper(),15,TEXT_COLOR)
	tier_label.name="ItemCardTier"
	tier_label.custom_minimum_size.x=90
	tier_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	top_line.add_child(tier_label)

	outer.add_child(_make_icon(data,rarity_color))
	var item_name:=_centered_label(str(data.get("display_name","Item")).to_upper(),25,rarity_color)
	item_name.name="ItemCardName"
	outer.add_child(item_name)
	var item_type:=_centered_label(_item_type_text(data),15,MUTED_COLOR)
	item_type.name="ItemCardType"
	outer.add_child(item_type)
	outer.add_child(_rule(rarity_color))

func _add_card_description(outer:VBoxContainer,data:Dictionary,comparison:Dictionary,rarity_color:Color)->void:
	var scroll:=ScrollContainer.new()
	scroll.name="ItemCardDescriptionScroll"
	scroll.custom_minimum_size.y=165
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var content:=VBoxContainer.new()
	content.name="ItemCardDescription"
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",7)
	scroll.add_child(content)
	var armor_requirement=data.get("armor_family_requirement","")
	if armor_requirement is Array and not armor_requirement.is_empty():content.add_child(_label("Requires %s Armor"%" or ".join(armor_requirement),13,MUTED_COLOR))
	elif str(armor_requirement)!="":content.add_child(_label("Requires %s Armor"%str(armor_requirement).capitalize(),13,MUTED_COLOR))
	var stat_index:=0
	for stat in data.get("stats",[]):
		var stat_label:=_label(str(stat.get("text","")),16,TEXT_COLOR)
		stat_label.name="ItemCardStat%d"%stat_index
		content.add_child(stat_label)
		stat_index+=1
	if not data.get("stats",[]).is_empty() and not data.get("passives",[]).is_empty():
		var stat_gap:=Control.new();stat_gap.custom_minimum_size.y=6;content.add_child(stat_gap)
	var passive_index:=0
	for passive in data.get("passives",[]):
		var passive_title:=_label(str(passive.get("title","")).to_upper(),17,rarity_color)
		passive_title.name="ItemCardPassiveTitle%d"%passive_index
		content.add_child(passive_title)
		var passive_description:=_label(str(passive.get("description","")),15,TEXT_COLOR)
		passive_description.name="ItemCardPassiveDescription%d"%passive_index
		content.add_child(passive_description)
		passive_index+=1
	if not comparison.is_empty():
		var comparison_gap:=Control.new();comparison_gap.custom_minimum_size.y=6;content.add_child(comparison_gap)
		var comparison_title:=_label("EQUIPMENT PREVIEW",14,Color("f5c451"));comparison_title.name="ItemCardComparisonTitle";content.add_child(comparison_title)
		var comparison_summary:=_label(str(comparison.get("summary","")),14,TEXT_COLOR);comparison_summary.name="ItemCardComparisonSummary";content.add_child(comparison_summary)

func _add_card_actions(outer:VBoxContainer,actions:Array)->void:
	if actions.is_empty():return
	var action_row:=HBoxContainer.new()
	action_row.name="ItemCardActions"
	action_row.alignment=BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation",12)
	outer.add_child(action_row)
	var action_width:=178.0 if actions.size()<=2 else 126.0
	for action in actions:
		var action_button:=Button.new()
		action_button.name="ItemCardAction"+str(action.get("id","Action")).replace("_"," ").capitalize().replace(" ","")
		action_button.text=str(action.get("label",action.get("id","Action"))).to_upper()
		action_button.custom_minimum_size=Vector2(action_width,46)
		action_button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		action_button.disabled=not bool(action.get("enabled",true))
		action_button.tooltip_text=str(action.get("reason",""))
		action_button.pressed.connect(func(action_id=str(action.get("id",""))):action_requested.emit(action_id))
		action_row.add_child(action_button)

func configure(data:Dictionary,actions:Array=[],comparison:Dictionary={})->void:
	card_data=data.duplicate(true)
	for child in get_children():child.queue_free()
	custom_minimum_size=Vector2(460,620)
	size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var rarity:=str(data.get("rarity","Common"))
	var rarity_color:=Color(ItemData.RARITY_COLORS.get(rarity,"718096")) if rarity!="Material" else STORED_COLOR
	add_theme_stylebox_override("panel",_card_style(rarity_color))
	var outer:=VBoxContainer.new()
	outer.add_theme_constant_override("separation",8)
	add_child(outer)
	_add_card_header(outer,data,rarity,rarity_color)
	_add_card_description(outer,data,comparison,rarity_color)
	_add_owner_row(outer,data,rarity_color)
	_add_card_actions(outer,actions)
