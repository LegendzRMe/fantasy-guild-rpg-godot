extends RefCounted

static func check(errors:Array,condition:bool,message:String) -> void:
	if not condition:
		errors.append(message)
