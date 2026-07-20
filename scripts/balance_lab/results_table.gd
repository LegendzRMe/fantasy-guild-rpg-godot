extends PanelContainer

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

const TEXT := Color("dce7f7")
const MUTED := Color("9fb0c8")
const GOLD := Color("ffca4f")
const GREEN := Color("61e5a8")

var status_label:Label
var summary_label:Label
var table:Tree
var detail:RichTextLabel

func _ready()->void:
	name="ResultsTable"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel",UiFactory.ui_box(Color("162131"),10,Color("35445a"),1))
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",6);add_child(content)
	var title_row:=HBoxContainer.new();content.add_child(title_row)
	var heading:=UiFactory.label("RESULTS",18,GOLD);heading.name="BalanceResultsHeading";heading.custom_minimum_size.x=100;heading.autowrap_mode=TextServer.AUTOWRAP_OFF;title_row.add_child(heading)
	status_label=UiFactory.label("Choose settings and run a simulation.",14,MUTED);status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;status_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_row.add_child(status_label)
	summary_label=UiFactory.label("No report loaded",14,MUTED);content.add_child(summary_label)
	table=Tree.new();table.name="BalanceResultsTree";table.size_flags_vertical=Control.SIZE_EXPAND_FILL;table.custom_minimum_size.y=220;table.columns=6;table.column_titles_visible=true;table.hide_root=true
	for column in 6:table.set_column_title(column,["BUILD","SCENARIO","DPS / HPS","TOTAL","CRIT","WASTE"][column])
	table.set_column_expand(0,true);table.set_column_expand(1,true)
	for column in [2,3,4,5]:table.set_column_expand(column,false);table.set_column_custom_minimum_width(column,88)
	table.item_selected.connect(_show_selected_detail);content.add_child(table)
	detail=RichTextLabel.new();detail.name="BalanceResultDetail";detail.bbcode_enabled=true;detail.fit_content=false;detail.custom_minimum_size.y=105;detail.scroll_active=true;detail.add_theme_font_size_override("normal_font_size",14);detail.add_theme_color_override("default_color",TEXT);detail.text="[color=#9fb0c8]Select a result row to see its action breakdown.[/color]";content.add_child(detail)

func set_running()->void:
	status_label.text="Running calculations..."
	status_label.add_theme_color_override("font_color",GOLD)

func show_message(message:String,is_error:bool=false)->void:
	status_label.text=message
	status_label.add_theme_color_override("font_color",Color("ff7d7d") if is_error else MUTED)

func show_report(report:Dictionary)->void:
	table.clear()
	var root:=table.create_item()
	for result in report.get("results",[]):
		var item:=table.create_item(root);item.set_metadata(0,result)
		item.set_text(0,str(result.build_name).trim_prefix("[Prototype] ").trim_suffix(" Basic Action"))
		item.set_text(1,str(result.scenario_name));item.set_text(2,"%.2f"%float(result.mean_per_second));item.set_text(3,"%.0f"%float(result.mean_effective_output));item.set_text(4,"%.1f%%"%(float(result.critical_rate)*100.0));item.set_text(5,"%.0f"%float(result.mean_wasted_output))
		item.set_custom_color(2,GREEN)
	status_label.text="Simulation complete";status_label.add_theme_color_override("font_color",GREEN)
	summary_label.text="%d comparisons • %d runs each • Seed %d"%[int(report.get("result_count",0)),int(report.get("iterations_per_result",0)),int(report.get("base_seed",0))]
	detail.text="[color=#9fb0c8]Select a result row to see its action breakdown.[/color]"

func _show_selected_detail()->void:
	var selected:=table.get_selected()
	if selected==null:return
	var result:Dictionary=selected.get_metadata(0)
	var lines:Array=["[color=#ffca4f][font_size=18]%s[/font_size][/color]"%str(result.build_name),"%s • Level %d • %s"%[str(result.scenario_name),int(result.level),"DPS" if str(result.mode)=="damage" else "HPS"],"","[color=#9fb0c8]Per-action average[/color]"]
	for action_id in result.get("by_action",{}):
		var action:Dictionary=result.by_action[action_id]
		lines.append("[color=#61e5a8]%s[/color]   %.0f output   %.1f casts   %.1f results"%[str(action_id).replace("_"," ").capitalize(),float(action.effective_output),float(action.cast_count),float(action.result_count)])
	lines.append("");lines.append("Range: %.2f–%.2f • Median %.2f • Standard deviation %.2f"%[float(result.minimum_per_second),float(result.maximum_per_second),float(result.median_per_second),float(result.standard_deviation)])
	detail.text="\n".join(lines)
