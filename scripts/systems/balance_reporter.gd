extends RefCounted

static func write_reports(report:Dictionary,output_directory:String)->Dictionary:
	var absolute_directory:=_absolute_path(output_directory)
	var error:=DirAccess.make_dir_recursive_absolute(absolute_directory)
	if error!=OK:return {"success":false,"error":"Could not create output directory: %s"%error}
	var json_path:=absolute_directory.path_join("latest.json")
	var csv_path:=absolute_directory.path_join("latest.csv")
	var json_error:=_write_text(json_path,JSON.stringify(report,"\t"))
	if json_error!=OK:return {"success":false,"error":"Could not write JSON report: %s"%json_error}
	var csv_error:=_write_text(csv_path,to_csv(report))
	if csv_error!=OK:return {"success":false,"error":"Could not write CSV report: %s"%csv_error}
	return {"success":true,"json_path":json_path,"csv_path":csv_path}

static func to_csv(report:Dictionary)->String:
	var columns:=["scenario_id","scenario_name","mode","duration","build_id","build_name","class_id","level","iterations","mean_per_second","standard_deviation","minimum_per_second","p10_per_second","median_per_second","p90_per_second","maximum_per_second","mean_effective_output","mean_wasted_output","mean_cast_count","mean_result_count","critical_rate","notes"]
	var lines:=[",".join(columns)]
	for result in report.get("results",[]):
		var values:Array=[]
		for column in columns:values.append(_csv_cell(result.get(column,"")))
		lines.append(",".join(values))
	return "\n".join(lines)+"\n"

static func _absolute_path(path:String)->String:
	if path.begins_with("res://") or path.begins_with("user://"):return ProjectSettings.globalize_path(path)
	if path.is_absolute_path():return path
	return ProjectSettings.globalize_path("res://").path_join(path)

static func _write_text(path:String,content:String)->Error:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return FileAccess.get_open_error()
	file.store_string(content)
	file.close()
	return OK

static func _csv_cell(value:Variant)->String:
	var text:=str(value)
	if text.contains(",") or text.contains("\"") or text.contains("\n"):
		return "\"%s\""%text.replace("\"","\"\"")
	return text
