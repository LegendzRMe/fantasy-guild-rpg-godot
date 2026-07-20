extends RefCounted

const BATTLE_BOUNDS := Rect2(48,62,1184,505)

static func create_blocker(combat_id:String,rect:Rect2,flags:Dictionary={}) -> Dictionary:
	return {"combat_id":combat_id,"rect":rect,"blocks_movement":bool(flags.get("blocks_movement",true)),"blocks_line_of_sight":bool(flags.get("blocks_line_of_sight",true)),"blocks_projectiles":bool(flags.get("blocks_projectiles",true)),"destructible":bool(flags.get("destructible",false)),"current_health":float(flags.get("current_health",100.0)),"maximum_health":float(flags.get("maximum_health",100.0))}

static func blocker_active(blocker:Dictionary)->bool:
	return not bool(blocker.get("destructible",false)) or float(blocker.get("current_health",0.0))>0.0

static func segment_intersects_rect(from:Vector2,to:Vector2,rect:Rect2)->bool:
	if rect.has_point(from) or rect.has_point(to):return true
	var a:=rect.position;var b:=rect.position+Vector2(rect.size.x,0);var c:=rect.end;var d:=rect.position+Vector2(0,rect.size.y)
	return Geometry2D.segment_intersects_segment(from,to,a,b)!=null or Geometry2D.segment_intersects_segment(from,to,b,c)!=null or Geometry2D.segment_intersects_segment(from,to,c,d)!=null or Geometry2D.segment_intersects_segment(from,to,d,a)!=null

static func first_blocker(from:Vector2,to:Vector2,blockers:Array,flag:String)->int:
	for index in blockers.size():
		var blocker:Dictionary=blockers[index]
		if blocker_active(blocker) and bool(blocker.get(flag,false)) and segment_intersects_rect(from,to,blocker.rect):return index
	return -1

static func has_line_of_sight(from:Vector2,to:Vector2,blockers:Array)->bool:
	return first_blocker(from,to,blockers,"blocks_line_of_sight")<0

static func valid_position(position:Vector2,radius:float,blockers:Array)->bool:
	if not BATTLE_BOUNDS.grow(-radius).has_point(position):return false
	for blocker in blockers:
		if blocker_active(blocker) and bool(blocker.get("blocks_movement",false)) and blocker.rect.grow(radius).has_point(position):return false
	return true

static func move_toward_safe(from:Vector2,to:Vector2,distance:float,radius:float,blockers:Array)->Vector2:
	var candidate:=from.move_toward(to,distance)
	if valid_position(candidate,radius,blockers):return candidate
	var direction:=from.direction_to(to)
	for angle in [PI/4.0,-PI/4.0,PI/2.0,-PI/2.0]:
		candidate=from+direction.rotated(angle)*distance
		if valid_position(candidate,radius,blockers):return candidate
	return from

static func line_of_sight_position(from:Vector2,target:Vector2,desired_range:float,blockers:Array)->Vector2:
	var direction:=target.direction_to(from)
	for ring in range(0,5):
		var radius:=maxf(36.0,desired_range-ring*32.0)
		for step in 12:
			var candidate:=target+direction.rotated((step-6)*PI/12.0)*radius
			if valid_position(candidate,24.0,blockers) and has_line_of_sight(candidate,target,blockers):return candidate
	return from

static func apply_nudge(target_position:Vector2,source_position:Vector2,distance:float,radius:float,blockers:Array)->Vector2:
	var direction:=source_position.direction_to(target_position)
	if direction==Vector2.ZERO:direction=Vector2.RIGHT
	return move_toward_safe(target_position,target_position+direction*distance,distance,radius,blockers)
