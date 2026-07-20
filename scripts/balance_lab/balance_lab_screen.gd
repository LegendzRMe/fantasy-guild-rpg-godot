extends Control

const BalanceReporter = preload("res://scripts/systems/balance_reporter.gd")
const BalanceSimulator = preload("res://scripts/systems/balance_simulator.gd")
const SimulationData = preload("res://scripts/data/simulation_data.gd")
const SimulationControls = preload("res://scripts/balance_lab/simulation_controls.gd")
const BuildSelector = preload("res://scripts/balance_lab/build_selector.gd")
const ResultsTable = preload("res://scripts/balance_lab/results_table.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")

const TEXT := Color("dce7f7")
const MUTED := Color("9fb0c8")
const GOLD := Color("ffca4f")

var controls
var build_selector
var results
var report_directory:String

func _ready()->void:
	name="BalanceLab"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_window().title="Fantasy Guild Balance Lab"
	get_window().min_size=Vector2i(1100,650)
	theme=UiFactory.build_theme(TEXT,MUTED,GOLD)
	report_directory=_default_report_directory()
	_build_interface()

func _build_interface()->void:
	var background:=ColorRect.new();background.color=Color("0f1825");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.add_theme_constant_override("margin_left",18);margin.add_theme_constant_override("margin_right",18);margin.add_theme_constant_override("margin_top",14);margin.add_theme_constant_override("margin_bottom",14);add_child(margin)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",10);margin.add_child(root)
	var header:=HBoxContainer.new();root.add_child(header)
	var titles:=VBoxContainer.new();titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(titles)
	titles.add_child(UiFactory.label("BALANCE LAB",32,TEXT));titles.add_child(UiFactory.label("Fast numerical comparisons for prototype combat values",14,MUTED))
	var warning:=UiFactory.label("PROTOTYPE DATA — NOT FINAL BALANCE",14,GOLD);warning.name="BalancePrototypeWarning";warning.custom_minimum_size.x=310;warning.autowrap_mode=TextServer.AUTOWRAP_OFF;warning.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;warning.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;header.add_child(warning)
	var columns:=HBoxContainer.new();columns.name="BalanceLabColumns";columns.size_flags_vertical=Control.SIZE_EXPAND_FILL;columns.clip_contents=true;columns.add_theme_constant_override("separation",12);root.add_child(columns)
	controls=SimulationControls.new();controls.run_requested.connect(run_simulation);controls.open_reports_requested.connect(open_reports_folder);controls.scenario_changed.connect(func(id:String):build_selector.show_scenario_hint(id));columns.add_child(controls)
	build_selector=BuildSelector.new();columns.add_child(build_selector)
	results=ResultsTable.new();columns.add_child(results)

func run_simulation()->void:
	if build_selector.selected_count()==0:
		results.show_message("Select at least one prototype build.",true)
		return
	controls.set_running(true);results.set_running()
	call_deferred("_execute_simulation")

func _execute_simulation()->void:
	var scenario_id:String=controls.selected_scenario_id()
	var scenarios:Array=SimulationData.standard_scenarios() if scenario_id=="all" else [SimulationData.STANDARD_SCENARIOS[scenario_id].duplicate(true)]
	var report:=BalanceSimulator.simulate_suite(scenarios,build_selector.selected_builds(controls.selected_level()),controls.selected_iterations(),controls.selected_seed())
	report["generated_at_utc"]=Time.get_datetime_string_from_system(true)
	report["report_label"]="Prototype Basic Action Baselines"
	report["warning"]="Temporary prototype data only. Final classes, abilities, talents, rotations, positioning, resources, passives, and utility are not represented."
	var write_result:=BalanceReporter.write_reports(report,report_directory)
	controls.set_running(false)
	if not bool(write_result.get("success",false)):
		results.show_message(str(write_result.get("error","Could not write reports.")),true)
		return
	results.show_report(report)

func open_reports_folder()->void:
	DirAccess.make_dir_recursive_absolute(report_directory)
	OS.shell_open(report_directory)

func _default_report_directory()->String:
	var project_root:=ProjectSettings.globalize_path("res://").trim_suffix("/").trim_suffix("\\")
	return project_root.get_base_dir().path_join(project_root.get_file()+" Balance Reports")
