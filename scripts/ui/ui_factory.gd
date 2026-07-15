extends RefCounted

static func ui_box(color:Color, radius:int=8, border_color:Color=Color.TRANSPARENT, border_width:int=0) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=color
	box.corner_radius_top_left=radius
	box.corner_radius_top_right=radius
	box.corner_radius_bottom_left=radius
	box.corner_radius_bottom_right=radius
	box.border_color=border_color
	box.border_width_left=border_width
	box.border_width_right=border_width
	box.border_width_top=border_width
	box.border_width_bottom=border_width
	box.content_margin_left=14
	box.content_margin_right=14
	box.content_margin_top=10
	box.content_margin_bottom=10
	return box

static func build_theme(text_color:Color, muted_color:Color, gold_color:Color) -> Theme:
	var theme:=Theme.new()
	theme.set_stylebox("normal","Button",ui_box(Color("202b3b"),8,Color("35445a"),1))
	theme.set_stylebox("hover","Button",ui_box(Color("2b3b52"),8,gold_color,1))
	theme.set_stylebox("pressed","Button",ui_box(Color("172131"),8,gold_color,2))
	theme.set_stylebox("focus","Button",ui_box(Color.TRANSPARENT,8,gold_color,2))
	theme.set_stylebox("disabled","Button",ui_box(Color("182231"),8,Color("2b394d"),1))
	theme.set_color("font_color","Button",text_color)
	theme.set_color("font_hover_color","Button",Color.WHITE)
	theme.set_color("font_pressed_color","Button",gold_color)
	theme.set_color("font_disabled_color","Button",Color("7f8da1"))
	theme.set_stylebox("normal","LineEdit",ui_box(Color("131c29"),7,Color("35445a"),1))
	theme.set_stylebox("focus","LineEdit",ui_box(Color("131c29"),7,gold_color,2))
	theme.set_color("font_placeholder_color","LineEdit",muted_color)
	theme.set_stylebox("panel","Panel",ui_box(Color("162131"),12,Color("2d3b50"),1))
	theme.set_font_size("font_size","Button",16)
	theme.set_font_size("font_size","LineEdit",16)
	return theme

static func label(text:String, size:int, color:Color) -> Label:
	var result:=Label.new()
	result.text=text
	result.add_theme_font_size_override("font_size",size)
	result.add_theme_color_override("font_color",color)
	result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return result

static func rule() -> HSeparator:
	var result:=HSeparator.new()
	result.add_theme_constant_override("separation",2)
	return result

static func button(text:String, callback:Callable, width:float) -> Button:
	var result:=Button.new()
	result.text=text
	result.custom_minimum_size=Vector2(width,48)
	result.add_theme_font_size_override("font_size",17)
	result.pressed.connect(callback)
	return result

static func compact_button(text:String, callback:Callable, width:float) -> Button:
	var result:=Button.new()
	result.text=text
	result.custom_minimum_size=Vector2(width,34)
	result.add_theme_font_size_override("font_size",14)
	result.pressed.connect(callback)
	return result

static func panel(color:Color) -> VBoxContainer:
	var result:=VBoxContainer.new()
	result.add_theme_constant_override("separation",10)
	var box:=StyleBoxFlat.new()
	box.bg_color=color
	box.corner_radius_top_left=12
	box.corner_radius_top_right=12
	box.corner_radius_bottom_left=12
	box.corner_radius_bottom_right=12
	box.content_margin_left=20
	box.content_margin_right=20
	box.content_margin_top=16
	box.content_margin_bottom=16
	result.add_theme_stylebox_override("panel",box)
	return result
