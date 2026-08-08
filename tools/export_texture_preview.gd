extends SceneTree

func _init()->void:
	var arguments:=OS.get_cmdline_user_args()
	if arguments.size()!=2:
		push_error("Usage: -- <res://texture> <output.png>")
		quit(2);return
	var texture:=load(arguments[0]) as Texture2D
	if texture==null:
		push_error("Unable to load texture: %s"%arguments[0])
		quit(3);return
	var output_path:=arguments[1]
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var error:=texture.get_image().save_png(output_path)
	if error!=OK:
		push_error("Unable to save texture preview: %s"%error_string(error))
		quit(4);return
	print("TEXTURE_PREVIEW_WRITTEN: %s"%output_path)
	quit(0)
