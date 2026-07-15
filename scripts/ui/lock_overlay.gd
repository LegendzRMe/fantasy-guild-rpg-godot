extends Control

const CHAIN_DARK := Color("574f68")
const CHAIN_MID := Color("b9a9cc")
const CHAIN_LIGHT := Color("eee8f7")
const LOCK_GOLD := Color("e5a91b")
const LOCK_DARK := Color("5d4310")
const SHACKLE := Color("78aebe")

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func ellipse_points(center:Vector2,radius_x:float,radius_y:float,rotation:float) -> PackedVector2Array:
	var points:=PackedVector2Array()
	for point_index in 17:
		var angle:=TAU*point_index/16.0
		points.append(center+Vector2(cos(angle)*radius_x,sin(angle)*radius_y).rotated(rotation))
	return points

func draw_chain(from:Vector2,to:Vector2) -> void:
	var direction:Vector2=from.direction_to(to)
	var distance:float=from.distance_to(to)
	var angle:float=direction.angle()
	draw_line(from,to,CHAIN_DARK,5.0,true)
	var link_count:=ceili(distance/13.0)
	for link_index in link_count+1:
		var center:Vector2=from+direction*min(distance,link_index*13.0)
		var link_angle:float=angle+(PI/2.0 if link_index%2 else 0.0)
		draw_polyline(ellipse_points(center,7.0,3.6,link_angle),CHAIN_DARK,4.2,true)
		draw_polyline(ellipse_points(center,7.0,3.6,link_angle),CHAIN_MID,2.4,true)
		if link_index%2==0:
			draw_polyline(ellipse_points(center-Vector2(0,1),6.2,2.8,link_angle),CHAIN_LIGHT,1.0,true)

func draw_lock() -> void:
	var center:Vector2=size*.5
	var tile:=Rect2(center-Vector2(29,31),Vector2(58,62))
	draw_rect(tile.grow(3),Color(0.015,0.02,0.03,.45),true)
	draw_rect(tile,Color("f4f5f7"),true)
	draw_rect(tile,Color("c8ced8"),false,1.5)
	var shackle_center:Vector2=center+Vector2(0,-5)
	draw_arc(shackle_center,13.0,PI,TAU,24,Color("426d7a"),8.0,true)
	draw_arc(shackle_center,13.0,PI,TAU,24,SHACKLE,5.0,true)
	var body:=Rect2(center+Vector2(-18,-3),Vector2(36,27))
	draw_rect(body,Color("9b6d0c"),true)
	draw_rect(Rect2(body.position+Vector2(2,2),body.size-Vector2(4,4)),LOCK_GOLD,true)
	draw_circle(center+Vector2(0,8),4.0,LOCK_DARK)
	draw_rect(Rect2(center+Vector2(-2,8),Vector2(4,8)),LOCK_DARK,true)

func _draw() -> void:
	if size.x<=0 or size.y<=0:return
	draw_chain(Vector2(-8,7),Vector2(size.x+8,size.y-7))
	draw_chain(Vector2(-8,size.y-7),Vector2(size.x+8,7))
	draw_lock()
