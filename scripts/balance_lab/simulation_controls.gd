extends PanelContainer

signal run_requested
signal scenario_changed(scenario_id:String)
signal open_reports_requested

const SimulationData = preload("res://scripts/data/simulation_data.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")

const TEXT := Color("dce7f7")
const MUTED := Color("9fb0c8")
const GOLD := Color("ffca4f")

var scenario_option:OptionButton
var level_spin:SpinBox
var iteration_option:OptionButton
var seed_spin:SpinBox
var run_button:Button

func _ready()->void:
	name="SimulationControls"
	custom_minimum_size=Vector2(300,0)
	add_theme_stylebox_override("panel",UiFactory.ui_box(Color("162131"),10,Color("35445a"),1))
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",7);add_child(content)
	content.add_child(_heading("SIMULATION SETUP"))
	content.add_child(UiFactory.label("Scenario",14,MUTED))
	scenario_option=OptionButton.new();scenario_option.name="BalanceScenarioOption";scenario_option.custom_minimum_size.y=38
	scenario_option.add_item("All Standard Scenarios");scenario_option.set_item_metadata(0,"all")
	for scenario in SimulationData.standard_scenarios():
		scenario_option.add_item(str(scenario.display_name));scenario_option.set_item_metadata(scenario_option.item_count-1,str(scenario.scenario_id))
	scenario_option.item_selected.connect(func(index:int):scenario_changed.emit(str(scenario_option.get_item_metadata(index))))
	content.add_child(scenario_option)
	content.add_child(UiFactory.label("Hero Level",14,MUTED))
	level_spin=_spin_box(1,30,1,1,"BalanceLevelSpin");content.add_child(level_spin)
	content.add_child(UiFactory.label("Simulation Runs",14,MUTED))
	iteration_option=OptionButton.new();iteration_option.name="BalanceIterationsOption";iteration_option.custom_minimum_size.y=44
	for value in [10,25,50,100,250,500,1000]:iteration_option.add_item("%d runs"%value);iteration_option.set_item_metadata(iteration_option.item_count-1,value)
	iteration_option.select(3);content.add_child(iteration_option)
	content.add_child(UiFactory.label("Random Seed",14,MUTED))
	seed_spin=_spin_box(1,999999999,1,1337,"BalanceSeedSpin");content.add_child(seed_spin)
	var explanation:=UiFactory.label("Using the same seed makes comparisons repeatable.",13,MUTED);explanation.custom_minimum_size.y=34;content.add_child(explanation)
	var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_child(spacer)
	run_button=UiFactory.button("RUN SIMULATION",func():run_requested.emit(),0);run_button.name="BalanceRunButton";run_button.custom_minimum_size.y=42;run_button.add_theme_color_override("font_color",GOLD);content.add_child(run_button)
	var folder_button:=UiFactory.button("OPEN REPORTS FOLDER",func():open_reports_requested.emit(),0);folder_button.name="BalanceOpenReportsButton";folder_button.custom_minimum_size.y=42;content.add_child(folder_button)

func selected_scenario_id()->String:
	return str(scenario_option.get_item_metadata(scenario_option.selected))

func selected_level()->int:
	return int(level_spin.value)

func selected_iterations()->int:
	return int(iteration_option.get_item_metadata(iteration_option.selected))

func selected_seed()->int:
	return int(seed_spin.value)

func set_running(running:bool)->void:
	run_button.disabled=running
	run_button.text="RUNNING..." if running else "RUN SIMULATION"

func _spin_box(minimum:float,maximum:float,step:float,value:float,node_name:String)->SpinBox:
	var result:=SpinBox.new();result.name=node_name;result.min_value=minimum;result.max_value=maximum;result.step=step;result.value=value;result.allow_greater=false;result.allow_lesser=false;result.custom_minimum_size.y=38
	return result

func _heading(text:String)->Label:
	var result:=UiFactory.label(text,18,GOLD);result.add_theme_color_override("font_outline_color",Color("111827"));result.add_theme_constant_override("outline_size",2)
	return result
