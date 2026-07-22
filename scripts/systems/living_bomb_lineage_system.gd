extends RefCounted

static func create_state()->Dictionary:
	return {"next_bomb_id":1,"next_lineage_id":1,"bombs_by_target":{},"lineages":{}}

static func has_bomb(state:Dictionary,target_id:String)->bool:
	return state.get("bombs_by_target",{}).has(target_id)

static func bomb_for(state:Dictionary,target_id:String)->Dictionary:
	return state.get("bombs_by_target",{}).get(target_id,{})

static func create_primary(state:Dictionary,owner_id:String,target_id:String,duration:float=3.0,manual:bool=true)->Dictionary:
	var lineage_id:="lineage:%d"%int(state.next_lineage_id);state.next_lineage_id=int(state.next_lineage_id)+1
	state.lineages[lineage_id]={"visited":{target_id:true},"active_count":0}
	return _create_bomb(state,owner_id,target_id,lineage_id,0,duration,manual,false,true)

static func create_spread(state:Dictionary,parent:Dictionary,target_id:String,duration:float=3.0,allow_later_spread:bool=false)->Dictionary:
	var lineage_id:=str(parent.lineage_id);var lineage:Dictionary=state.lineages.get(lineage_id,{"visited":{},"active_count":0})
	if lineage.visited.has(target_id) or has_bomb(state,target_id):return {}
	lineage.visited[target_id]=true;state.lineages[lineage_id]=lineage
	return _create_bomb(state,str(parent.owner_id),target_id,lineage_id,int(parent.generation)+1,duration,false,true,allow_later_spread)

static func _create_bomb(state:Dictionary,owner_id:String,target_id:String,lineage_id:String,generation:int,duration:float,manual:bool,spread:bool,may_spread:bool)->Dictionary:
	var bomb_id:="bomb:%d"%int(state.next_bomb_id);state.next_bomb_id=int(state.next_bomb_id)+1
	var bomb:={"bomb_id":bomb_id,"owner_id":owner_id,"target_id":target_id,"lineage_id":lineage_id,"generation":generation,"manual":manual,"is_spread_bomb":spread,"remaining":duration,"tick_remaining":1.0,"may_spread":may_spread}
	state.bombs_by_target[target_id]=bomb
	state.lineages[lineage_id].active_count=int(state.lineages[lineage_id].active_count)+1
	return bomb

static func remove_bomb(state:Dictionary,target_id:String,keep_lineage:bool=false)->Dictionary:
	var bomb:Dictionary=bomb_for(state,target_id)
	if bomb.is_empty():return {}
	state.bombs_by_target.erase(target_id)
	var lineage_id:=str(bomb.lineage_id)
	if state.lineages.has(lineage_id):
		state.lineages[lineage_id].active_count=maxi(0,int(state.lineages[lineage_id].active_count)-1)
		if int(state.lineages[lineage_id].active_count)<=0 and not keep_lineage:state.lineages.erase(lineage_id)
	return bomb

static func cleanup_lineage(state:Dictionary,lineage_id:String)->void:
	if state.get("lineages",{}).has(lineage_id) and int(state.lineages[lineage_id].active_count)<=0:state.lineages.erase(lineage_id)

static func can_infect_from(state:Dictionary,parent:Dictionary,target_id:String)->bool:
	if has_bomb(state,target_id):return false
	var lineage:Dictionary=state.get("lineages",{}).get(str(parent.get("lineage_id","")),{})
	return not lineage.get("visited",{}).has(target_id)
