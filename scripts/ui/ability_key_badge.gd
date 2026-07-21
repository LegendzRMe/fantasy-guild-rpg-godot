extends Control

var key_text:String="Q"
var accent:Color=Color("5fa8ff")
var locked:bool=false

func configure(value:String,color:Color,is_locked:bool=false)->void:
	key_text=value;accent=color;locked=is_locked;custom_minimum_size=Vector2(58,58);mouse_filter=Control.MOUSE_FILTER_IGNORE;queue_redraw()

func _draw()->void:
	var center:=size*0.5;var radius:=minf(size.x,size.y)*0.44;var points:=PackedVector2Array()
	for index in 8:points.append(center+Vector2.UP.rotated(PI/8.0+TAU*index/8.0)*radius)
	var resolved_accent:=Color("65758d") if locked else accent
	draw_colored_polygon(points,Color("172234") if not locked else Color("141c29"))
	draw_polyline(points+PackedVector2Array([points[0]]),resolved_accent,3.0,true)
	var font:=ThemeDB.fallback_font;var font_size:=20;var text_size:=font.get_string_size(key_text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
	draw_string(font,center-Vector2(text_size.x*0.5,-text_size.y*0.28),key_text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,resolved_accent)
