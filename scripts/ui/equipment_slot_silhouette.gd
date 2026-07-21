extends Control

var slot := "head"
var silhouette_color := Color(0.55,0.64,0.76,0.20)

func configure(slot_id:String,color:Color=Color(0.55,0.64,0.76,0.20))->void:
	slot=slot_id;silhouette_color=color;mouse_filter=Control.MOUSE_FILTER_IGNORE;queue_redraw()

func _draw()->void:
	var c:=silhouette_color
	match slot:
		"head":
			draw_arc(Vector2(39,31),20,PI,TAU,24,c,5);draw_line(Vector2(19,31),Vector2(23,48),c,5);draw_line(Vector2(59,31),Vector2(55,48),c,5);draw_line(Vector2(23,48),Vector2(55,48),c,5)
		"chest":
			var points:=PackedVector2Array([Vector2(25,14),Vector2(14,23),Vector2(21,34),Vector2(24,53),Vector2(54,53),Vector2(57,34),Vector2(64,23),Vector2(53,14),Vector2(47,22),Vector2(31,22),Vector2(25,14)]);draw_polyline(points,c,5,true)
		"weapon":
			draw_line(Vector2(22,51),Vector2(56,17),c,7);draw_line(Vector2(18,42),Vector2(31,55),c,5);draw_circle(Vector2(19,54),4,c)
		"neck":
			draw_arc(Vector2(39,24),22,0.15,PI-0.15,24,c,4);draw_line(Vector2(17,28),Vector2(39,51),c,4);draw_line(Vector2(61,28),Vector2(39,51),c,4);draw_circle(Vector2(39,51),5,c)
		"hands":
			draw_rect(Rect2(24,20,29,32),c,false,5);for x in [27.0,34.0,41.0,48.0]:draw_line(Vector2(x,20),Vector2(x,11),c,4)
		"trinket":
			var points:=PackedVector2Array([Vector2(39,11),Vector2(58,30),Vector2(39,53),Vector2(20,30),Vector2(39,11)]);draw_polyline(points,c,5,true);draw_circle(Vector2(39,31),6,c)
