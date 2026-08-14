extends "res://scripts/runtime/victory_runtime.gd"

func health_bar(pos:Vector2,width:float,ratio:float,color:Color)->void:
	draw_rect(Rect2(pos,Vector2(width,7)),Color("11151e"));draw_rect(Rect2(pos,Vector2(width*clamp(ratio,0,1),7)),color)

func health_bar_with_shield(pos:Vector2,width:float,unit:Dictionary)->void:
	var health_ratio:float=clampf(float(unit.hp)/maxf(1.0,float(unit.max_hp)),0.0,1.0);health_bar(pos,width,health_ratio,C_GREEN)
	var temporary_width:float=minf(width,float(unit.get("temporary_hp",0.0))/maxf(1.0,float(unit.max_hp))*width)
	if temporary_width>0:draw_rect(Rect2(pos+Vector2(min(width-temporary_width,width*health_ratio),0),Vector2(temporary_width,7)),Color("e6b85c"))
	var shield_width:float=minf(width,float(unit.get("shield",0.0))/maxf(1.0,float(unit.max_hp))*width)
	if shield_width>0:draw_rect(Rect2(pos+Vector2(min(width-shield_width,width*health_ratio),0),Vector2(shield_width,7)),Color("55aaff"))
func add_effect(kind:String,from:Vector2,to:Vector2,text_value:String,color:Color)->void:
	effects.append({"kind":kind,"from":from,"to":to,"text":text_value,"color":color,"life":.75 if kind!="heroic" else 1.25,"max_life":.75 if kind!="heroic" else 1.25})
func draw_combat_effect(fx:Dictionary)->void:
	var progress=1.0-fx.life/fx.max_life
	var alpha=clamp(fx.life*2.0,0.0,1.0)
	var col=Color(fx.color,alpha)
	match fx.kind:
		"projectile":
			var p=fx.from.lerp(fx.to,clamp(progress*1.8,0.0,1.0));draw_line(p-Vector2(12,0),p+Vector2(8,0),col,5);draw_circle(p,5,Color.WHITE)
		"ranger_arrow":
			var arrow_direction:Vector2=fx.from.direction_to(fx.to)
			if arrow_direction==Vector2.ZERO:
				draw_arc(fx.to,12+progress*16,0,TAU,24,col,3)
			else:
				var arrow_position:Vector2=fx.from.lerp(fx.to,clampf(progress,0.0,1.0));var arrow_tip:=arrow_position+arrow_direction*8.0
				draw_line(arrow_position-arrow_direction*18.0,arrow_tip,col,4);draw_line(arrow_tip,arrow_tip-arrow_direction.rotated(.55)*10.0,col,3);draw_line(arrow_tip,arrow_tip-arrow_direction.rotated(-.55)*10.0,col,3)
		"multishot":
			var fan_direction:Vector2=fx.from.direction_to(fx.to);var fan_distance:float=fx.from.distance_to(fx.to)*clampf(progress,0.0,1.0)
			for arrow_index in range(-3,4):
				var shot_direction:=fan_direction.rotated(deg_to_rad(float(arrow_index)*8.0));var shot_tip:Vector2=fx.from+shot_direction*fan_distance
				draw_line(shot_tip-shot_direction*15.0,shot_tip,Color(col,.88),3)
		"cloud_serpent_projectile":
			var serpent_position:Vector2=fx.from.lerp(fx.to,clampf(progress,0.0,1.0));var serpent_direction:Vector2=fx.from.direction_to(fx.to)
			draw_line(serpent_position-serpent_direction*20.0,serpent_position,Color("79dfe8",alpha*.58),4);draw_circle(serpent_position,8,Color("8feaf2",alpha*.26));draw_circle(serpent_position,4.5,col);draw_circle(serpent_position,2,Color.WHITE)
		"guardian_thunder_clap":
			var thunder_center:=Vector2(fx.to);var thunder_radius:=float(fx.get("radius",145.0));var thunder_spread:=clampf(progress*1.7,0.0,1.0);var thunder_color:=Color("b68cff") if bool(fx.get("secondary",false)) else Color("62b8ff")
			draw_circle(thunder_center,thunder_radius*thunder_spread,Color(thunder_color,alpha*.10));draw_arc(thunder_center,thunder_radius*thunder_spread,0,TAU,64,Color(thunder_color,alpha),6)
			draw_arc(thunder_center,thunder_radius*maxf(0.12,thunder_spread*.68),0,TAU,48,Color.WHITE,alpha*3.5)
			for bolt_index in 8:
				var bolt_angle:float=TAU*float(bolt_index)/8.0+float(progress)*.22;var bolt_start:Vector2=thunder_center+Vector2.RIGHT.rotated(bolt_angle)*thunder_radius*thunder_spread*.28;var bolt_mid:Vector2=thunder_center+Vector2.RIGHT.rotated(bolt_angle+.07)*thunder_radius*thunder_spread*.62;var bolt_end:Vector2=thunder_center+Vector2.RIGHT.rotated(bolt_angle-.04)*thunder_radius*thunder_spread*.92
				draw_polyline(PackedVector2Array([bolt_start,bolt_mid,bolt_end]),Color(thunder_color,alpha*.88),3)
		"guardian_thunder_warning":
			var warning_center:=Vector2(fx.to);var warning_radius:=float(fx.get("radius",145.0));var warning_color:=Color("a879e8")
			draw_circle(warning_center,warning_radius,Color(warning_color,.035));draw_arc(warning_center,warning_radius,0,TAU,64,Color(warning_color,.38),2);draw_arc(warning_center,warning_radius+4,-PI/2,-PI/2+TAU*(1.0-progress),64,Color(warning_color,.72),4)
		"mage_gravity":
			var gravity_position:Vector2=fx.from.lerp(fx.to,clampf(progress,0.0,1.0));draw_circle(gravity_position,9,Color(col,.24));draw_circle(gravity_position,4,Color.WHITE);draw_line(fx.from,gravity_position,Color(col,.45),3)
		"mage_flamestrike_warning":
			var flame_center:=Vector2(fx.to);var flame_radius:=float(fx.get("radius",72.0));var warning_pulse:=0.5+0.5*sin(progress*TAU*4.0);var warning_color:=Color("d978ff") if bool(fx.get("repeat",false)) else Color("ff9b45")
			draw_circle(flame_center,flame_radius,Color(warning_color,.07+.035*warning_pulse));draw_arc(flame_center,flame_radius,0,TAU,64,Color(warning_color,.70),3)
			draw_arc(flame_center,flame_radius+5,-PI/2,-PI/2+TAU*(1.0-progress),64,Color.WHITE,.0 if progress>=1.0 else 5.0)
			draw_circle(flame_center,8+warning_pulse*3.0,Color(warning_color,.35));draw_line(flame_center+Vector2(-flame_radius*.42,0),flame_center+Vector2(flame_radius*.42,0),Color(warning_color,.38),2);draw_line(flame_center+Vector2(0,-flame_radius*.42),flame_center+Vector2(0,flame_radius*.42),Color(warning_color,.38),2)
		"mage_flamestrike_impact":
			var impact_center:=Vector2(fx.to);var impact_radius:=float(fx.get("radius",72.0));var expanding_radius:=lerpf(impact_radius*.35,impact_radius,clampf(progress*2.0,0.0,1.0))
			draw_circle(impact_center,expanding_radius,Color("ff742f",alpha*.24));draw_arc(impact_center,expanding_radius,0,TAU,64,Color("ffc45e",alpha),6);draw_arc(impact_center,impact_radius*(.25+.45*progress),0,TAU,48,Color.WHITE,alpha*4.0);draw_circle(impact_center,12+progress*20,Color("fff2b0",alpha*.72))
		"mage_phoenix":
			var phoenix_position:Vector2=fx.from.lerp(fx.to,clampf(progress,0.0,1.0));draw_circle(phoenix_position,12,Color("ffb34f",alpha));draw_line(fx.from,phoenix_position,Color("ff7a3d",alpha*.55),6)
		"mage_pyro":
			var pyro_position:Vector2=fx.from.lerp(fx.to,clampf(progress,0.0,1.0));draw_circle(pyro_position,13,Color("ff7a3d",alpha*.45));draw_circle(pyro_position,7,Color("ffd15c",alpha));draw_circle(pyro_position,3,Color.WHITE)
		"warlock_fel_flame":
			var flame_direction:Vector2=fx.from.direction_to(fx.to);var flame_length:float=fx.from.distance_to(fx.to)*clampf(progress,0.0,1.0);var flame_tip:Vector2=fx.from+flame_direction*flame_length;var side:Vector2=flame_direction.orthogonal();var start_radius:=float(fx.get("start_radius",18.0));var end_radius:=float(fx.get("end_radius",80.0))*clampf(progress,0.15,1.0)
			var wave:=PackedVector2Array([fx.from+side*start_radius,flame_tip+side*end_radius,flame_tip-side*end_radius,fx.from-side*start_radius]);draw_colored_polygon(wave,Color("7b2aa8",alpha*.18));draw_polyline(PackedVector2Array([wave[0],wave[1],wave[2],wave[3],wave[0]]),Color("c45cff",alpha),4)
		"warlock_drain_tether":
			var wobble:float=sin(progress*TAU*3.0)*5.0;var midpoint:Vector2=fx.from.lerp(fx.to,.5)+fx.from.direction_to(fx.to).orthogonal()*wobble;draw_polyline(PackedVector2Array([fx.from,midpoint,fx.to]),Color("b45cff",alpha*.85),5);draw_circle(fx.to,8,Color("d89aff",alpha*.35))
		"warlock_corruption_warning":
			var corruption_radius:=float(fx.get("radius",54.0));draw_circle(fx.to,corruption_radius,Color("7b2aa8",.07));draw_arc(fx.to,corruption_radius,0,TAU,40,Color("b15cff",alpha*.65),3)
		"warlock_corruption_impact":
			var corruption_radius:=float(fx.get("radius",54.0));draw_circle(fx.to,corruption_radius*clampf(progress*1.8,0.0,1.0),Color("8c35b8",alpha*.22));draw_arc(fx.to,corruption_radius,0,TAU,40,Color("df9cff",alpha),5)
		"warlock_horrify_warning":
			var fear_radius:=float(fx.get("radius",105.0));draw_circle(fx.to,fear_radius,Color("6b248f",.08));draw_arc(fx.to,fear_radius,-PI/2,-PI/2+TAU*(1.0-progress),52,Color("d091ff",.82),5)
		"warlock_horrify_impact":
			var fear_radius:=float(fx.get("radius",105.0));draw_circle(fx.to,fear_radius,Color("792da3",alpha*.18));draw_arc(fx.to,fear_radius*(.35+.65*progress),0,TAU,52,Color("e0a8ff",alpha),7)
		"warlock_rain_warning":
			var rain_radius:=float(fx.get("radius",42.0));draw_circle(fx.to,rain_radius,Color("7b2aa8",.10));draw_arc(fx.to,rain_radius,-PI/2,-PI/2+TAU*(1.0-progress),36,Color("dd7cff",.86),4)
		"warlock_rain_impact":
			var rain_radius:=float(fx.get("radius",42.0));draw_circle(fx.to,rain_radius,Color("7f2aa6",alpha*.27));draw_line(fx.to-Vector2(18,75),fx.to,Color("db8cff",alpha),9);draw_arc(fx.to,rain_radius,0,TAU,40,Color("ffd6ff",alpha),5)
		"warlock_life_tap":
			var tap_color:=Color("e2a5ff") if bool(fx.get("free",false)) else Color("b15cff");draw_circle(fx.from,30+progress*32,Color(tap_color,alpha*.12));draw_arc(fx.from,30+progress*32,0,TAU,36,Color(tap_color,alpha),5)
		"rogue_dash","rogue_opener":
			var rogue_direction:Vector2=Vector2(fx.from).direction_to(Vector2(fx.to));var rogue_position:Vector2=Vector2(fx.from).lerp(Vector2(fx.to),clampf(progress,0.0,1.0));var rogue_side:=rogue_direction.orthogonal()
			draw_line(fx.from,rogue_position,Color(col,alpha*.32),10);draw_line(rogue_position-rogue_direction*22.0-rogue_side*10.0,rogue_position,col,5);draw_line(rogue_position-rogue_direction*22.0+rogue_side*10.0,rogue_position,col,5)
			if fx.kind=="rogue_opener":draw_arc(fx.to,18+progress*18,0,TAU,28,Color.WHITE,4)
		"rogue_blade_flurry":
			var blade_radius:=float(fx.get("radius",75.0));var blade_rotation:float=float(progress)*TAU*1.8
			draw_circle(fx.from,blade_radius,Color(col,alpha*.08));draw_arc(fx.from,blade_radius,blade_rotation,blade_rotation+PI*1.45,48,col,7);draw_arc(fx.from,blade_radius*.68,-blade_rotation,-blade_rotation+PI*1.15,40,Color.WHITE,3)
		"rogue_eviscerate":
			var finisher_direction:Vector2=Vector2(fx.from).direction_to(Vector2(fx.to));var finisher_side:=finisher_direction.orthogonal()*18.0
			draw_line(fx.from,fx.to,Color(col,alpha*.35),5);draw_line(fx.to-finisher_side-finisher_direction*18.0,fx.to+finisher_side,col,8);draw_line(fx.to+finisher_side-finisher_direction*18.0,fx.to-finisher_side,Color.WHITE,3)
		"slayer_dive", "slayer_hunt":
			var dash_pos:Vector2=fx.from.lerp(fx.to,clampf(progress,0.0,1.0));var dash_dir:Vector2=fx.from.direction_to(fx.to);draw_line(fx.from,dash_pos,Color(col,.38),10);draw_line(dash_pos-dash_dir.rotated(.65)*15,dash_pos+dash_dir.rotated(.65)*15,col,5);draw_line(dash_pos-dash_dir.rotated(-.65)*15,dash_pos+dash_dir.rotated(-.65)*15,col,5)
		"slayer_sweep":
			var sweep_dir:Vector2=fx.from.direction_to(fx.to);var sweep_tip:Vector2=fx.from.lerp(fx.to,clampf(progress*1.5,0.0,1.0));var side:=sweep_dir.orthogonal()*float(fx.get("width",42.0));draw_colored_polygon(PackedVector2Array([fx.from-side*.25,sweep_tip-side,sweep_tip+side,fx.from+side*.25]),Color(col,.16));draw_line(sweep_tip-side,sweep_tip+side,col,5)
		"slayer_evasion":
			var evasion_radius:=float(fx.get("radius",54.0));draw_arc(fx.from,evasion_radius,progress*TAU,progress*TAU+PI*1.5,40,col,5);draw_arc(fx.from,evasion_radius-9,-progress*TAU,-progress*TAU+PI*1.5,36,Color.WHITE,2)
		"slayer_metamorphosis":
			var demon_radius:=float(fx.get("radius",84.0));draw_circle(fx.from,demon_radius*clampf(progress*1.8,0.0,1.0),Color(col,alpha*.18));draw_arc(fx.from,demon_radius,0,TAU,56,col,7)
		"priest_flash_cast","priest_flash_heal":
			draw_line(fx.from,fx.to,col,4);draw_arc(fx.to,24+progress*18,0,TAU,28,col,4)
		"priest_star":
			draw_line(fx.from,fx.to,Color(col,.55),3);draw_circle(fx.to,8+progress*3,col);draw_circle(fx.to,3,Color.WHITE)
		"priest_chastise":
			draw_line(fx.from,fx.to,Color(col,.8),maxf(3.0,float(fx.get("width",20.0))*.18));draw_line(fx.from,fx.to,Color.WHITE,2)
		"priest_lightbomb_warning","priest_salvation":
			var priest_radius:=float(fx.get("radius",80.0));draw_circle(fx.from,priest_radius,Color(col,.08));draw_arc(fx.from,priest_radius,0,TAU,48,col,4)
		"shaman_chain":
			var bolt_mid:Vector2=fx.from.lerp(fx.to,.5)+fx.from.direction_to(fx.to).orthogonal()*sin(progress*TAU*4.0)*8.0;draw_polyline(PackedVector2Array([fx.from,bolt_mid,fx.to]),Color("91e7ff",alpha),5);draw_circle(fx.to,7,Color.WHITE)
		"shaman_feral_spirit":
			var wolf_dir:Vector2=fx.from.direction_to(fx.to);var wolf_pos:Vector2=fx.from.lerp(fx.to,clampf(progress,0.0,1.0));draw_circle(wolf_pos,13,Color(col,alpha*.28));draw_line(wolf_pos-wolf_dir*24,wolf_pos,col,6);draw_arc(wolf_pos,18,0,TAU,24,col,3)
		"shaman_windfury":
			draw_arc(fx.from,36+progress*12,progress*TAU,progress*TAU+PI*1.6,36,col,5)
		"shaman_sundering":
			var rift_width:=maxf(5.0,float(fx.get("width",24.0))*.18);draw_line(fx.from,fx.to,Color("8fe7ff",alpha*.24),rift_width*2.0);draw_line(fx.from,fx.to,col,rift_width)
		"shaman_earthquake":
			var quake_radius:=float(fx.get("radius",180.0));draw_circle(fx.from,quake_radius,Color(col,alpha*.08));draw_arc(fx.from,quake_radius*clampf(progress*1.6,0.1,1.0),0,TAU,56,col,6)
		"templar_blade_dash":
			var dash_dir:Vector2=Vector2(fx.from).direction_to(Vector2(fx.to));draw_line(fx.from,fx.to,Color(col,.35),10);draw_line(fx.to-dash_dir*22,fx.to,col,5);draw_arc(fx.to,14,0,TAU,20,Color.WHITE,2)
		"templar_shield_ally":
			draw_line(fx.from,fx.to,Color(col,.55),4);draw_arc(fx.to,58,0,TAU,36,col,5)
		"templar_suppression":
			var pulse_radius:=float(fx.get("radius",100.0));draw_circle(fx.from,pulse_radius,Color(col,alpha*.10));draw_arc(fx.from,pulse_radius*clampf(progress*1.7,.1,1.0),0,TAU,48,col,6)
		"templar_purifier_beam":
			draw_line(fx.from,fx.to,Color(col,alpha*.65),12);draw_circle(fx.to,28,Color(col,alpha*.18));draw_arc(fx.to,32,0,TAU,32,Color.WHITE,3)
		"protector_sword_throw":
			var sword_pos:Vector2=Vector2(fx.from).lerp(Vector2(fx.to),clampf(progress,0.0,1.0));draw_line(fx.from,sword_pos,Color(col,.45),4);draw_line(sword_pos+Vector2(-10,16),sword_pos+Vector2(10,-16),col,7);draw_circle(sword_pos,18,Color(col,alpha*.12))
		"protector_teleport","protector_judgment":
			var dash_pos:Vector2=Vector2(fx.from).lerp(Vector2(fx.to),clampf(progress,0.0,1.0));draw_line(fx.from,dash_pos,Color(col,.4),12);draw_circle(dash_pos,20+progress*28,Color(col,alpha*.18));draw_arc(dash_pos,24+progress*30,0,TAU,36,col,5)
		"protector_wall_warning","protector_force_wall":
			draw_line(fx.from,fx.to,Color(col,alpha*.4),16);draw_line(fx.from,fx.to,Color.WHITE,3)
		"protector_smite":
			var side:Vector2=Vector2(fx.from).direction_to(Vector2(fx.to)).orthogonal()*float(fx.get("width",55.0));draw_colored_polygon(PackedVector2Array([fx.from-side*.35,fx.to-side,fx.to+side,fx.from+side*.35]),Color(col,alpha*.16));draw_line(fx.from,fx.to,col,5)
		"protector_judgment_warning":
			draw_line(fx.from,fx.to,Color(col,alpha*.4),5);draw_arc(fx.to,34,0,TAU,32,col,4)
		"protector_wrath","protector_wrath_explosion":
			var wrath_radius:=float(fx.get("radius",115.0));draw_circle(fx.from,wrath_radius,Color(col,alpha*.10));draw_arc(fx.from,wrath_radius*clampf(.3+progress,0.0,1.0),0,TAU,52,col,7)
		"sentinel_q":
			draw_line(fx.from,fx.to,Color(col,alpha*.55),4);draw_circle(fx.to,17+progress*24,Color(col,alpha*.16));draw_arc(fx.to,19+progress*25,0,TAU,30,col,4)
		"sentinel_w":
			var owl_dir:Vector2=Vector2(fx.from).direction_to(Vector2(fx.to));var owl_pos:Vector2=Vector2(fx.from).lerp(Vector2(fx.to),clampf(progress,0.0,1.0));var wing:=owl_dir.orthogonal()*float(fx.get("width",24.0))*.45;draw_line(fx.from,owl_pos,Color(col,alpha*.28),3);draw_polyline(PackedVector2Array([owl_pos-wing,owl_pos+owl_dir*11.0,owl_pos+wing]),col,5);draw_circle(owl_pos,4,Color.WHITE)
		"sentinel_flare_warning":
			var warning_radius:=float(fx.get("radius",62.0));draw_circle(fx.to,warning_radius,Color(col,.06));draw_arc(fx.to,warning_radius,-PI/2,-PI/2+TAU*(1.0-progress),48,col,4);draw_line(fx.to-Vector2(warning_radius*.35,0),fx.to+Vector2(warning_radius*.35,0),Color(col,.4),2);draw_line(fx.to-Vector2(0,warning_radius*.35),fx.to+Vector2(0,warning_radius*.35),Color(col,.4),2)
		"sentinel_flare":
			var flare_radius:=float(fx.get("radius",62.0));draw_circle(fx.to,flare_radius*clampf(progress*1.8,.2,1.0),Color(col,alpha*.20));draw_arc(fx.to,flare_radius,0,TAU,48,col,6);draw_circle(fx.to,10+progress*18,Color(Color.WHITE,alpha))
		"sentinel_shadowstalk":
			var shadow_radius:=float(fx.get("radius",105.0));var shadow_rotation:float=float(progress)*TAU
			draw_circle(fx.from,shadow_radius,Color(col,alpha*.07));draw_arc(fx.from,shadow_radius,shadow_rotation,shadow_rotation+PI*1.55,52,col,5);draw_arc(fx.from,shadow_radius-12,-shadow_rotation,-shadow_rotation+PI*1.3,48,Color.WHITE,2)
		"sentinel_starfall":
			var starfall_radius:=float(fx.get("radius",150.0));var star_pulse:float=.72+.12*sin(float(progress)*TAU*8.0)
			draw_circle(fx.to,starfall_radius,Color(col,alpha*.075));draw_arc(fx.to,starfall_radius,0,TAU,64,Color(col,alpha*.82),4)
			for star_index in 7:
				var star_angle:float=TAU*float(star_index)/7.0+float(progress)*.7;var star_distance:float=starfall_radius*(.25+.58*float((star_index%3)+1)/3.0);var star_position:=Vector2(fx.to)+Vector2.RIGHT.rotated(star_angle)*star_distance
				draw_circle(star_position,4+star_pulse*3,Color(Color.WHITE,alpha));draw_line(star_position-Vector2(0,18),star_position,Color(col,alpha*.55),3)
		"huntsman_cocktail_projectile","huntsman_marked_projectile":
			var bullet_pos:Vector2=Vector2(fx.from).lerp(Vector2(fx.to),clampf(progress,0.0,1.0));draw_line(fx.from,bullet_pos,Color(col,alpha*.45),4);draw_circle(bullet_pos,7,Color.WHITE);draw_arc(bullet_pos,11,0,TAU,16,col,3)
		"huntsman_cocktail_cone":
			var cone_dir:Vector2=Vector2(fx.from).direction_to(Vector2(fx.to));var cone_side:=cone_dir.orthogonal()*float(fx.get("radius",130.0))*.55;draw_colored_polygon(PackedVector2Array([fx.from,fx.to+cone_side,fx.to-cone_side]),Color(col,alpha*.16));draw_line(fx.from,fx.to+cone_side,col,3);draw_line(fx.from,fx.to-cone_side,col,3)
		"huntsman_swipe":
			draw_line(fx.from,fx.to,Color(col,alpha*.42),9);draw_arc(fx.to,float(fx.get("radius",60.0)),-PI*.85,PI*.25,30,col,7)
		"huntsman_darkflight","huntsman_disengage","huntsman_r1","huntsman_mark_leap":
			var leap_pos:Vector2=Vector2(fx.from).lerp(Vector2(fx.to),clampf(progress,0.0,1.0));draw_line(fx.from,leap_pos,Color(col,alpha*.35),10);draw_circle(leap_pos,15+progress*18,Color(col,alpha*.18));draw_arc(leap_pos,20+progress*20,0,TAU,28,col,4)
		"huntsman_inner_beast":
			var beast_radius:=float(fx.get("radius",62.0));draw_circle(fx.from,beast_radius,Color(col,alpha*.10));draw_arc(fx.from,beast_radius*(.55+.45*progress),0,TAU,40,col,6)
		"druid_regrowth","druid_regrowth_tick","druid_basic_hot_tick","druid_lifebloom","druid_moonfire_heal","druid_swiftness","druid_communion","druid_innervate":
			var leaf_pos:=Vector2(fx.from).lerp(Vector2(fx.to),clampf(progress,0.0,1.0));draw_line(fx.from,leaf_pos,Color(col,alpha*.48),4);draw_circle(leaf_pos,8,Color("91e883",alpha*.42));draw_arc(fx.to,20+progress*22,0,TAU,28,col,4)
		"druid_moonfire","druid_twilight":
			var lunar_radius:=float(fx.get("radius",52.0));draw_circle(fx.to,lunar_radius,Color(col,alpha*.09));draw_arc(fx.to,lunar_radius*clampf(.35+progress,0.0,1.0),0,TAU,52,col,6);draw_arc(fx.to,lunar_radius*.58,-PI*.65,PI*.65,30,Color("e9f4ff",alpha),4)
		"druid_roots":
			var root_radius:=float(fx.get("radius",34.0));draw_circle(fx.to,root_radius,Color("4f7e43",alpha*.14));draw_arc(fx.to,root_radius*(.4+.6*progress),0,TAU,36,col,5);for root_index in 6:var root_dir:=Vector2.RIGHT.rotated(TAU*float(root_index)/6.0);draw_line(fx.to+root_dir*8,fx.to+root_dir*root_radius,Color("6e9e52",alpha),3)
		"druid_tranquility","druid_wild_growth":
			var nature_radius:=float(fx.get("radius",75.0));draw_circle(fx.from,nature_radius,Color(col,alpha*.07));draw_arc(fx.from,nature_radius,progress*TAU,progress*TAU+PI*1.6,52,col,5);draw_arc(fx.from,nature_radius*.68,-progress*TAU,-progress*TAU+PI*1.35,44,Color("c7ffc0",alpha),3)
		"druid_treant","druid_treant_attack":
			draw_line(fx.from,fx.to,Color("75a95f",alpha*.58),6);draw_circle(fx.to,14+progress*18,Color(col,alpha*.18));draw_arc(fx.to,18+progress*20,0,TAU,28,col,4)
		"monk_dash_ally","monk_dash_enemy":
			var monk_pos:Vector2=fx.from.lerp(fx.to,clampf(progress,0.0,1.0));draw_line(fx.from,monk_pos,Color(col,alpha*.38),10);draw_arc(monk_pos,16,progress*TAU,progress*TAU+PI*1.5,24,col,5)
		"monk_breath":
			var breath_radius:=float(fx.get("radius",100.0));draw_circle(fx.from,breath_radius,Color(col,alpha*.07));draw_arc(fx.from,breath_radius*clampf(progress*1.7,.1,1.0),0,TAU,52,col,5)
		"monk_palm","monk_palm_trigger":
			draw_circle(fx.to,28+progress*30,Color(col,alpha*.14));draw_arc(fx.to,32+progress*26,0,TAU,36,col,6);draw_line(fx.to+Vector2(-12,0),fx.to+Vector2(12,0),Color.WHITE,4);draw_line(fx.to+Vector2(0,-12),fx.to+Vector2(0,12),Color.WHITE,4)
		"monk_seven_strike":
			draw_line(fx.from,fx.to,Color(col,alpha*.6),5);draw_arc(fx.to,12+progress*20,0,TAU,24,Color.WHITE,4)
		"monk_ally_spirit","monk_ally_earth","monk_ally_air":
			var ally_radius:=float(fx.get("radius",120.0));draw_circle(fx.from,ally_radius,Color(col,alpha*.06));draw_arc(fx.from,ally_radius,0,TAU,48,col,4)
		"slash":
			draw_line(fx.to+Vector2(-22,-18),fx.to+Vector2(22,18),col,7);draw_line(fx.to+Vector2(-16,22),fx.to+Vector2(18,-16),Color.WHITE,3)
		"hit":
			draw_circle(fx.to,28+progress*22,Color(col,.16));draw_line(fx.from,fx.to,col,4)
		"heal":
			draw_line(fx.from,fx.to,col,4);draw_circle(fx.to,25+progress*30,Color(col,.18));draw_arc(fx.to,25+progress*30,0,TAU,30,col,3)
		"cast":
			draw_arc(fx.from,30+progress*18,0,TAU,32,col,4)
		"heroic":
			draw_circle(fx.from,38+progress*80,Color(col,.14));draw_arc(fx.from,38+progress*80,0,TAU,40,col,6)

	if fx.text!="":
		var text_pos=fx.to+Vector2(-28,-48-progress*30)
		draw_string(ThemeDB.fallback_font,text_pos,fx.text,HORIZONTAL_ALIGNMENT_CENTER,90,17,col)
func draw_role_icon(pos:Vector2,hero_class:String,ink:Color=Color("101827"))->void:
	if hero_class in ["Guardian","Templar","Protector"]:
		var shield=PackedVector2Array([pos+Vector2(-11,-13),pos+Vector2(11,-13),pos+Vector2(9,5),pos+Vector2(0,15),pos+Vector2(-9,5)])
		draw_colored_polygon(shield,ink);draw_polyline(shield+PackedVector2Array([shield[0]]),Color.WHITE,2)
	elif hero_class in ["Cleric","Priest","Monk"]:
		draw_rect(Rect2(pos+Vector2(-5,-15),Vector2(10,30)),ink);draw_rect(Rect2(pos+Vector2(-15,-5),Vector2(30,10)),ink)
	elif hero_class=="Mage":
		draw_line(pos+Vector2(-11,13),pos+Vector2(8,-8),ink,5);draw_circle(pos+Vector2(11,-11),6,ink);draw_circle(pos+Vector2(11,-11),2,Color.WHITE)
	elif hero_class=="Rogue":
		draw_line(pos+Vector2(-13,12),pos+Vector2(11,-12),ink,5);draw_line(pos+Vector2(-11,-12),pos+Vector2(13,12),ink,5)
	elif hero_class=="Warlock":
		draw_circle(pos,13,Color.TRANSPARENT,2);draw_arc(pos,14,0,TAU,28,ink,4);draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-15),pos+Vector2(10,6),pos+Vector2(0,2),pos+Vector2(-10,6)]),ink)
	elif hero_class in ["Slayer","Shaman"]:
		draw_arc(pos+Vector2(-4,0),14,-1.1,1.1,18,ink,4);draw_arc(pos+Vector2(4,0),14,PI-1.1,PI+1.1,18,ink,4);draw_line(pos+Vector2(-12,12),pos+Vector2(12,-12),ink,3);draw_line(pos+Vector2(-12,-12),pos+Vector2(12,12),ink,3)
	else:
		# Ranged DPS use a bow marker. Future melee classes can use crossed swords.
		draw_arc(pos+Vector2(-3,0),15,-PI/2,PI/2,18,ink,4);draw_line(pos+Vector2(-3,-15),pos+Vector2(-3,15),ink,2);draw_line(pos+Vector2(-3,0),pos+Vector2(15,0),ink,3);draw_colored_polygon(PackedVector2Array([pos+Vector2(15,0),pos+Vector2(8,-5),pos+Vector2(8,5)]),ink)
