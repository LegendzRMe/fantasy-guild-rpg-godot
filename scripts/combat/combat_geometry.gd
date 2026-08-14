extends RefCounted

const BATTLE_BOUNDS := Rect2(48,62,1184,505)

static func create_blocker(combat_id:String,rect:Rect2,flags:Dictionary={}) -> Dictionary:
	return {"combat_id":combat_id,"rect":rect,"blocks_movement":bool(flags.get("blocks_movement",true)),"blocks_line_of_sight":bool(flags.get("blocks_line_of_sight",true)),"blocks_projectiles":bool(flags.get("blocks_projectiles",true)),"destructible":bool(flags.get("destructible",false)),"current_health":float(flags.get("current_health",100.0)),"maximum_health":float(flags.get("maximum_health",100.0))}

static func create_segment_blocker(combat_id:String,from:Vector2,to:Vector2,thickness:float,flags:Dictionary={}) -> Dictionary:
	return {"combat_id":combat_id,"shape":"segment","from":from,"to":to,"thickness":maxf(1.0,thickness),"rect":Rect2(from.min(to),from.max(to)-from.min(to)).grow(maxf(1.0,thickness)*0.5),"blocks_movement":bool(flags.get("blocks_movement",true)),"blocks_line_of_sight":bool(flags.get("blocks_line_of_sight",false)),"blocks_projectiles":bool(flags.get("blocks_projectiles",false)),"destructible":bool(flags.get("destructible",false)),"current_health":float(flags.get("current_health",100.0)),"maximum_health":float(flags.get("maximum_health",100.0)),"owner_combat_id":str(flags.get("owner_combat_id","")),"cast_id":str(flags.get("cast_id","")),"temporary":bool(flags.get("temporary",true)),"remaining_duration":float(flags.get("remaining_duration",INF))}

static func create_ring_blocker(combat_id:String,center:Vector2,radius:float,thickness:float,flags:Dictionary={})->Dictionary:
	return {"combat_id":combat_id,"shape":"ring","center":center,"radius":maxf(1.0,radius),"thickness":maxf(1.0,thickness),"rect":Rect2(center-Vector2.ONE*(radius+thickness),Vector2.ONE*2.0*(radius+thickness)),"blocks_movement":bool(flags.get("blocks_movement",true)),"blocks_line_of_sight":bool(flags.get("blocks_line_of_sight",false)),"blocks_projectiles":bool(flags.get("blocks_projectiles",false)),"owner_combat_id":str(flags.get("owner_combat_id","")),"crossing_exception":str(flags.get("crossing_exception","")),"temporary":true,"remaining_duration":float(flags.get("remaining_duration",INF)),"destructible":false}

static func ring_crossed(from:Vector2,to:Vector2,blocker:Dictionary,padding:float=0.0)->bool:
	var radius:=float(blocker.radius);var a:=from.distance_to(Vector2(blocker.center));var b:=to.distance_to(Vector2(blocker.center));var half:=float(blocker.thickness)*.5+padding
	return (a<radius-half and b>radius+half) or (a>radius+half and b<radius-half) or absf(b-radius)<=half

static func blocker_active(blocker:Dictionary)->bool:
	return not bool(blocker.get("destructible",false)) or float(blocker.get("current_health",0.0))>0.0

static func segment_intersects_rect(from:Vector2,to:Vector2,rect:Rect2)->bool:
	if rect.has_point(from) or rect.has_point(to):return true
	var a:=rect.position;var b:=rect.position+Vector2(rect.size.x,0);var c:=rect.end;var d:=rect.position+Vector2(0,rect.size.y)
	return Geometry2D.segment_intersects_segment(from,to,a,b)!=null or Geometry2D.segment_intersects_segment(from,to,b,c)!=null or Geometry2D.segment_intersects_segment(from,to,c,d)!=null or Geometry2D.segment_intersects_segment(from,to,d,a)!=null

static func first_blocker(from:Vector2,to:Vector2,blockers:Array,flag:String,mover_id:String="",exception:String="")->int:
	for index in blockers.size():
		var blocker:Dictionary=blockers[index]
		if not blocker_active(blocker) or not bool(blocker.get(flag,false)):continue
		if str(blocker.get("shape","rect"))=="ring":
			if mover_id==str(blocker.get("owner_combat_id","")) or exception!="" and exception==str(blocker.get("crossing_exception","")):continue
			if ring_crossed(from,to,blocker):return index
		elif str(blocker.get("shape","rect"))=="segment":
			if segment_segment_distance(from,to,Vector2(blocker.from),Vector2(blocker.to))<=float(blocker.thickness)*0.5:return index
		elif segment_intersects_rect(from,to,blocker.rect):return index
	return -1

static func has_line_of_sight(from:Vector2,to:Vector2,blockers:Array)->bool:
	return first_blocker(from,to,blockers,"blocks_line_of_sight")<0

static func valid_position(position:Vector2,radius:float,blockers:Array,mover_id:String="")->bool:
	if not BATTLE_BOUNDS.grow(-radius).has_point(position):return false
	for blocker in blockers:
		if not blocker_active(blocker) or not bool(blocker.get("blocks_movement",false)):continue
		if str(blocker.get("shape","rect"))=="ring":
			if mover_id==str(blocker.get("owner_combat_id","")):continue
			if absf(position.distance_to(Vector2(blocker.center))-float(blocker.radius))<=radius+float(blocker.thickness)*.5:return false
		elif str(blocker.get("shape","rect"))=="segment":
			if segment_distance_to_point(Vector2(blocker.from),Vector2(blocker.to),position)<=radius+float(blocker.thickness)*0.5:return false
		elif blocker.rect.grow(radius).has_point(position):return false
	return true

static func move_toward_safe(from:Vector2,to:Vector2,distance:float,radius:float,blockers:Array,mover_id:String="",exception:String="")->Vector2:
	var candidate:=from.move_toward(to,distance)
	if valid_position(candidate,radius,blockers,mover_id) and first_blocker(from,candidate,blockers,"blocks_movement",mover_id,exception)<0:return candidate
	var direction:=from.direction_to(to)
	for angle in [PI/4.0,-PI/4.0,PI/2.0,-PI/2.0]:
		candidate=from+direction.rotated(angle)*distance
		if valid_position(candidate,radius,blockers,mover_id) and first_blocker(from,candidate,blockers,"blocks_movement",mover_id,exception)<0:return candidate
	return from

static func safe_endpoint(from:Vector2,intended:Vector2,radius:float,blockers:Array,mover_id:String="",exception:String="")->Vector2:
	if valid_position(intended,radius,blockers,mover_id) and first_blocker(from,intended,blockers,"blocks_movement",mover_id,exception)<0:return intended
	for step in range(19,-1,-1):
		var candidate:=from.lerp(intended,float(step)/20.0)
		if valid_position(candidate,radius,blockers,mover_id) and first_blocker(from,candidate,blockers,"blocks_movement",mover_id,exception)<0:return candidate
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

static func segment_distance_to_point(from:Vector2,to:Vector2,point:Vector2)->float:
	var segment:=to-from
	if segment.length_squared()<=0.0001:return from.distance_to(point)
	var factor:=clampf((point-from).dot(segment)/segment.length_squared(),0.0,1.0)
	return (from+segment*factor).distance_to(point)

static func segment_hits_circle(from:Vector2,to:Vector2,center:Vector2,radius:float)->bool:
	return segment_distance_to_point(from,to,center)<=radius

static func segment_segment_distance(a:Vector2,b:Vector2,c:Vector2,d:Vector2)->float:
	if Geometry2D.segment_intersects_segment(a,b,c,d)!=null:return 0.0
	return minf(minf(segment_distance_to_point(a,b,c),segment_distance_to_point(a,b,d)),minf(segment_distance_to_point(c,d,a),segment_distance_to_point(c,d,b)))

static func blocker_intersects_segment(blocker:Dictionary,from:Vector2,to:Vector2,padding:float=0.0)->bool:
	if str(blocker.get("shape","rect"))=="ring":return ring_crossed(from,to,blocker,padding)
	if str(blocker.get("shape","rect"))=="segment":return segment_segment_distance(from,to,Vector2(blocker.from),Vector2(blocker.to))<=float(blocker.thickness)*0.5+padding
	return segment_intersects_rect(from,to,Rect2(blocker.rect).grow(padding))

static func segment_blocker_push_out(position:Vector2,radius:float,blocker:Dictionary)->Vector2:
	var from:=Vector2(blocker.from);var to:=Vector2(blocker.to);var segment:=to-from
	var factor:=0.0 if segment.length_squared()<=0.0001 else clampf((position-from).dot(segment)/segment.length_squared(),0.0,1.0)
	var closest:=from+segment*factor;var normal:=closest.direction_to(position)
	if normal==Vector2.ZERO:normal=segment.normalized().orthogonal() if segment.length_squared()>0.0001 else Vector2.UP
	return (closest+normal*(radius+float(blocker.thickness)*0.5+1.0)).clamp(BATTLE_BOUNDS.position+Vector2.ONE*radius,BATTLE_BOUNDS.end-Vector2.ONE*radius)

static func reflect_point_across_line(point:Vector2,line_from:Vector2,line_to:Vector2)->Vector2:
	var line:=line_to-line_from
	if line.length_squared()<=0.0001:return line_from*2.0-point
	var projection:=line_from+line*clampf((point-line_from).dot(line)/line.length_squared(),0.0,1.0)
	return projection*2.0-point
