extends VBoxContainer

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

signal option_pressed(tier_id:String,option_id:String)

func configure(tier_id:String,tier_number:int,unlock_level:int,kind:String,hero_level:int,revealed:bool,options:Array,class_color:Color,text_color:Color,muted_color:Color,gold_color:Color)->void:
	name="TalentTier%s"%tier_number
	add_theme_constant_override("separation",8)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",10);add_child(header)
	var level_badge:=Label.new();level_badge.name="TalentTierLevel";level_badge.text="LEVEL %d"%unlock_level;level_badge.custom_minimum_size=Vector2(88,30);level_badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;level_badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;level_badge.add_theme_font_size_override("font_size",13);level_badge.add_theme_color_override("font_color",gold_color if hero_level>=unlock_level else muted_color);level_badge.add_theme_stylebox_override("normal",UiFactory.ui_box(Color("172234"),5,gold_color if hero_level>=unlock_level else Color("35445a"),1));header.add_child(level_badge)
	var tier_title:=Label.new();tier_title.text="TIER %d  •  %s"%[tier_number,kind.replace("_"," ").to_upper()];tier_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tier_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;tier_title.add_theme_font_size_override("font_size",15);tier_title.add_theme_color_override("font_color",text_color);header.add_child(tier_title)
	var tier_state:=Label.new();tier_state.text="AVAILABLE" if hero_level>=unlock_level else "PLAN AHEAD" if revealed else "LOCKED";tier_state.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;tier_state.add_theme_font_size_override("font_size",12);tier_state.add_theme_color_override("font_color",class_color if hero_level>=unlock_level else muted_color);header.add_child(tier_state)
	if not revealed:
		var hidden:=Label.new();hidden.text="◆   TALENT CHOICES HIDDEN\nRaise a %s Hero to Level %d to reveal this tier."%[str(options[0].get("class_name","class")) if not options.is_empty() else "class",unlock_level];hidden.custom_minimum_size=Vector2(600,78);hidden.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hidden.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;hidden.add_theme_font_size_override("font_size",14);hidden.add_theme_color_override("font_color",muted_color);hidden.add_theme_stylebox_override("normal",UiFactory.ui_box(Color("131b28"),7,Color("2b374a"),1));add_child(hidden)
		return
	var row:=HBoxContainer.new();row.name="TalentTierOptions";row.add_theme_constant_override("separation",9);add_child(row)
	for option in options:
		var option_id:=str(option.id);var selected:=bool(option.get("selected",false));var planned:=bool(option.get("planned",false));var available:=bool(option.get("available",true))
		var card:=Button.new();card.name="TalentOption_%s"%option_id;card.custom_minimum_size=Vector2(0,126);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.focus_mode=Control.FOCUS_NONE;card.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.alignment=HORIZONTAL_ALIGNMENT_CENTER;card.add_theme_font_size_override("font_size",12)
		var status:="✓  SELECTED" if selected else "♥  PLANNED" if planned else "CHOOSE" if hero_level>=unlock_level else "♡  PLAN"
		if not available:status=str(option.get("unavailable_reason","UNAVAILABLE")).to_upper()
		card.text="%s\n%s\n\n%s"%[status,str(option.display_name).to_upper(),str(option.description)]
		var border:=gold_color if selected else Color("b381ff") if planned else class_color if available else Color("35445a")
		var background:=Color("2a3850") if selected else Color("242f45") if planned else Color("1b283a") if available else Color("141c29")
		card.add_theme_color_override("font_color",gold_color if selected else Color("caa7ff") if planned else text_color if available else muted_color)
		card.add_theme_stylebox_override("normal",UiFactory.ui_box(background,7,border,3 if selected or planned else 1));card.add_theme_stylebox_override("hover",UiFactory.ui_box(Color("2a3b55"),7,border,2));card.add_theme_stylebox_override("pressed",UiFactory.ui_box(Color("162033"),7,border,3));card.disabled=not available
		card.pressed.connect(func(id=option_id):option_pressed.emit(tier_id,id));row.add_child(card)
