extends PanelContainer

const ClassData = preload("res://scripts/data/class_data.gd")
const SimulationData = preload("res://scripts/data/simulation_data.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")

const TEXT := Color("dce7f7")
const MUTED := Color("9fb0c8")
const GOLD := Color("ffca4f")

var checklist:=VBoxContainer.new()
var checks:Dictionary={}
var mode_hint:Label

func _ready()->void:
	name="BuildSelector"
	custom_minimum_size=Vector2(320,0)
	add_theme_stylebox_override("panel",UiFactory.ui_box(Color("162131"),10,Color("35445a"),1))
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",7);add_child(content)
	content.add_child(UiFactory.label("PROTOTYPE BUILDS",18,GOLD))
	mode_hint=UiFactory.label("Compatible builds run automatically for each scenario.",13,MUTED);mode_hint.custom_minimum_size.y=34;content.add_child(mode_hint)
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",8);content.add_child(actions)
	actions.add_child(UiFactory.compact_button("SELECT ALL",func():_set_all(true),120))
	actions.add_child(UiFactory.compact_button("CLEAR",func():_set_all(false),90))
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;content.add_child(scroll)
	checklist.size_flags_horizontal=Control.SIZE_EXPAND_FILL;checklist.add_theme_constant_override("separation",5);scroll.add_child(checklist)
	_rebuild()

func selected_builds(level:int)->Array:
	var result:Array=[]
	for build in SimulationData.prototype_baseline_builds(level):
		if checks.has(str(build.build_id)) and bool(checks[str(build.build_id)].button_pressed):result.append(build)
	return result

func selected_count()->int:
	return checks.values().filter(func(check:CheckBox):return check.button_pressed).size()

func show_scenario_hint(scenario_id:String)->void:
	if scenario_id=="all":mode_hint.text="Damage builds run in damage scenarios; the Cleric runs in healing scenarios."
	else:
		var scenario:Dictionary=SimulationData.STANDARD_SCENARIOS.get(scenario_id,{})
		mode_hint.text="This is a %s scenario; incompatible Basic Actions will be skipped."%str(scenario.get("mode","output"))

func _rebuild()->void:
	for child in checklist.get_children():child.queue_free()
	checks.clear()
	for build in SimulationData.prototype_baseline_builds(1):
		var definition:Dictionary=build.class_definition
		var check:=CheckBox.new();check.name="BalanceBuild%s"%str(definition.class_id).capitalize();check.button_pressed=true;check.custom_minimum_size=Vector2(270,52)
		check.text="%s\n%s • %s"%[str(definition.display_name),str(definition.primary_role),"Basic Heal" if str(definition.basic_action_type)=="heal" else "Basic Attack"]
		check.add_theme_font_size_override("font_size",15);check.add_theme_color_override("font_color",Color(definition.color));check.add_theme_stylebox_override("normal",UiFactory.ui_box(Color("1b283a"),7,Color("35445a"),1));check.add_theme_stylebox_override("hover",UiFactory.ui_box(Color("24344b"),7,Color(definition.color),1));checklist.add_child(check);checks[str(build.build_id)]=check

func _set_all(selected:bool)->void:
	for check in checks.values():check.button_pressed=selected
