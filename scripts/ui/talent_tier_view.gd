extends VBoxContainer

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

signal details_requested(tier_id:String,option_id:String)
signal plan_toggled(tier_id:String,option_id:String)
signal selection_confirmed(tier_id:String,option_id:String)

const HOLD_SECONDS := 0.85

var _hold_tween:Tween
var _hold_button:Button
var _hold_progress:ProgressBar
var _hold_tier_id := ""
var _hold_option_id := ""
var _hold_completed := false

func configure(tier_id:String,tier_number:int,unlock_level:int,kind:String,hero_level:int,revealed:bool,options:Array,class_color:Color,text_color:Color,muted_color:Color,gold_color:Color)->void:
	name="TalentTier%s"%tier_number
	add_theme_constant_override("separation",6)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",8);add_child(header)
	var level_badge:=Label.new();level_badge.name="TalentTierLevel";level_badge.text="LV %d"%unlock_level;level_badge.custom_minimum_size=Vector2(62,25);level_badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;level_badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;level_badge.add_theme_font_size_override("font_size",12);level_badge.add_theme_color_override("font_color",gold_color if hero_level>=unlock_level else muted_color);level_badge.add_theme_stylebox_override("normal",UiFactory.ui_box(Color("172234"),4,gold_color if hero_level>=unlock_level else Color("35445a"),1));header.add_child(level_badge)
	var tier_title:=Label.new();tier_title.text="TIER %d  •  %s"%[tier_number,kind.replace("_"," ").to_upper()];tier_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tier_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;tier_title.add_theme_font_size_override("font_size",14);tier_title.add_theme_color_override("font_color",text_color);header.add_child(tier_title)
	var tier_state:=Label.new();tier_state.text="AVAILABLE" if hero_level>=unlock_level else "LOCKED";tier_state.custom_minimum_size.x=82;tier_state.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;tier_state.autowrap_mode=TextServer.AUTOWRAP_OFF;tier_state.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;tier_state.add_theme_font_size_override("font_size",11);tier_state.add_theme_color_override("font_color",class_color if hero_level>=unlock_level else muted_color);header.add_child(tier_state)
	if not revealed:
		var hidden:=Label.new();hidden.text="◇  TALENT CHOICES HIDDEN  •  Reach Level %d with this class to reveal them."%unlock_level;hidden.custom_minimum_size=Vector2(0,48);hidden.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hidden.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hidden.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;hidden.add_theme_font_size_override("font_size",13);hidden.add_theme_color_override("font_color",muted_color);hidden.add_theme_stylebox_override("normal",UiFactory.ui_box(Color("131b28"),5,Color("2b374a"),1));add_child(hidden)
		return
	var row:=HBoxContainer.new();row.name="TalentTierOptions";row.add_theme_constant_override("separation",8);add_child(row)
	for option in options:
		_add_option_card(row,tier_id,hero_level>=unlock_level,option,class_color,text_color,muted_color,gold_color)

func _add_option_card(row:HBoxContainer,tier_id:String,tier_unlocked:bool,option:Dictionary,class_color:Color,text_color:Color,muted_color:Color,gold_color:Color)->void:
	var option_id:=str(option.id);var selected:=bool(option.get("selected",false));var planned:=bool(option.get("planned",false));var available:=bool(option.get("available",true))
	var holder:=Control.new();holder.name="TalentOption_%s"%option_id;holder.custom_minimum_size=Vector2(0,82);holder.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(holder)
	var card:=Button.new();card.name="TalentOptionCard";card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);card.focus_mode=Control.FOCUS_ALL;card.alignment=HORIZONTAL_ALIGNMENT_CENTER;card.add_theme_font_size_override("font_size",13);card.text="%s\n%s"%["◆" if selected else "◇",str(option.display_name).to_upper()]
	var border:=gold_color if selected else Color("b381ff") if planned else class_color if available else Color("35445a")
	var background:=Color("2a3850") if selected else Color("242f45") if planned else Color("1b283a") if available else Color("141c29")
	card.add_theme_color_override("font_color",gold_color if selected else text_color if available else muted_color)
	card.add_theme_stylebox_override("normal",UiFactory.ui_box(background,6,border,3 if selected or planned else 1));card.add_theme_stylebox_override("hover",UiFactory.ui_box(Color("2a3b55"),6,border,2));card.add_theme_stylebox_override("pressed",UiFactory.ui_box(Color("162033"),6,border,3));holder.add_child(card)
	var can_choose:=tier_unlocked and available and not selected
	card.tooltip_text="Hold to choose. Tap for details." if can_choose else "Tap for details."
	card.button_down.connect(func():_begin_hold(card,holder.get_node("HoldProgress") as ProgressBar,tier_id,option_id,can_choose))
	card.button_up.connect(func():_finish_hold(tier_id,option_id))
	var progress:=ProgressBar.new();progress.name="HoldProgress";progress.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);progress.show_percentage=false;progress.max_value=1.0;progress.value=0.0;progress.mouse_filter=Control.MOUSE_FILTER_IGNORE;progress.add_theme_stylebox_override("background",UiFactory.ui_box(Color.TRANSPARENT,6));progress.add_theme_stylebox_override("fill",UiFactory.ui_box(Color(gold_color,.22),6,gold_color,2));holder.add_child(progress)
	if selected:
		var state_badge:=Label.new();state_badge.name="TalentStateBadge";state_badge.text="SELECTED";state_badge.position=Vector2(8,5);state_badge.size=Vector2(80,18);state_badge.add_theme_font_size_override("font_size",9);state_badge.add_theme_color_override("font_color",gold_color);state_badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;holder.add_child(state_badge)
	if not selected:
		var heart:=Button.new();heart.name="TalentPlanHeart";heart.text="♥" if planned else "♡";heart.tooltip_text="Remove planned talent" if planned else "Plan this talent";heart.set_anchors_preset(Control.PRESET_TOP_RIGHT);heart.position=Vector2(-37,2);heart.size=Vector2(35,30);heart.flat=true;heart.focus_mode=Control.FOCUS_NONE;heart.add_theme_font_size_override("font_size",18);heart.add_theme_color_override("font_color",Color("caa7ff") if planned else muted_color);heart.pressed.connect(func():plan_toggled.emit(tier_id,option_id));holder.add_child(heart)

func _begin_hold(button:Button,progress:ProgressBar,tier_id:String,option_id:String,can_choose:bool)->void:
	_hold_button=button;_hold_progress=progress;_hold_tier_id=tier_id;_hold_option_id=option_id;_hold_completed=false
	if not can_choose:return
	if _hold_tween!=null:_hold_tween.kill()
	progress.value=0.0
	_hold_tween=create_tween();_hold_tween.tween_property(progress,"value",1.0,HOLD_SECONDS)
	_hold_tween.tween_callback(func():
		_hold_completed=true
		selection_confirmed.emit(_hold_tier_id,_hold_option_id))

func _finish_hold(tier_id:String,option_id:String)->void:
	if _hold_tween!=null and _hold_tween.is_running():_hold_tween.kill()
	if _hold_progress!=null and is_instance_valid(_hold_progress):_hold_progress.value=0.0
	if not _hold_completed:details_requested.emit(tier_id,option_id)
	_hold_button=null;_hold_progress=null;_hold_tween=null
