extends RefCounted

static func create(projectile_id:String,source_id:String,target_id:String,from:Vector2,to:Vector2,speed:float,payload:Dictionary)->Dictionary:
	return {"combat_id":projectile_id,"source_id":source_id,"target_id":target_id,"pos":from,"previous_pos":from,"destination":to,"speed":speed,"payload":payload.duplicate(true),"collision_radius":4.0,"maximum_travel_distance":maxf(1.0,from.distance_to(to)+24.0),"travelled":0.0,"piercing":false,"homing":false}

static func advance(projectile:Dictionary,delta:float)->void:
	projectile.previous_pos=projectile.pos
	var step:=minf(float(projectile.speed)*delta,float(projectile.pos.distance_to(projectile.destination)))
	projectile.pos=projectile.pos.move_toward(projectile.destination,step)
	projectile.travelled=float(projectile.get("travelled",0.0))+step

static func arrived(projectile:Dictionary)->bool:
	return projectile.pos.distance_to(projectile.destination)<=1.0 or float(projectile.travelled)>=float(projectile.maximum_travel_distance)
