extends SceneTree

const SAMPLE_STEP := 2
const CASES := [
	{"path":"res://assets/world_map.png","minimum_psnr":36.0},
	{"path":"res://assets/generated/ashwood_combat_background.png","minimum_psnr":38.0}
]

func _init()->void:
	var failed:=false
	for test_case in CASES:
		var source_path:String=test_case.path
		var source:=Image.load_from_file(ProjectSettings.globalize_path(source_path))
		var texture:=load(source_path) as Texture2D
		if source==null or texture==null:
			push_error("Unable to load texture quality fixture: %s"%source_path);failed=true;continue
		var imported:=texture.get_image()
		if source.get_size()!=imported.get_size():
			push_error("Imported texture dimensions changed for %s"%source_path);failed=true;continue
		var squared_error:=0.0;var channel_samples:=0
		for y in range(0,source.get_height(),SAMPLE_STEP):
			for x in range(0,source.get_width(),SAMPLE_STEP):
				var original:=source.get_pixel(x,y);var decoded:=imported.get_pixel(x,y)
				squared_error+=pow(original.r-decoded.r,2)+pow(original.g-decoded.g,2)+pow(original.b-decoded.b,2)
				channel_samples+=3
		var mse:=squared_error/maxf(1.0,float(channel_samples))
		var psnr:=INF if mse<=0.0 else 10.0*log(1.0/mse)/log(10.0)
		print("TEXTURE_QUALITY %s PSNR %.2f dB"%[source_path,psnr])
		if psnr<float(test_case.minimum_psnr):
			push_error("Imported texture quality %.2f dB is below %.2f dB for %s"%[psnr,float(test_case.minimum_psnr),source_path]);failed=true
	quit(1 if failed else 0)
