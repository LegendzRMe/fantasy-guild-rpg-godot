extends RefCounted

const STORAGE_PAGE_SIZE := 30
const STORAGE_PAGE_COUNT := 6
const MATERIAL_STACK_LIMIT := 100
const VAULT_WARNING_THRESHOLD := 0.80
const VAULT_CRITICAL_THRESHOLD := 1.00
const LONG_PRESS_DURATION := 0.35
const DRAG_THRESHOLD := 10.0
const PAGE_HOVER_DURATION := 0.40

const MATERIAL_DEFINITIONS := {
	"ore":{"display_name":"Ore","fallback_icon_type":"ore","color":"a9b5c7"},
	"herbs":{"display_name":"Herbs","fallback_icon_type":"herb","color":"54d69a"},
	"dust":{"display_name":"Arcane Dust","fallback_icon_type":"dust","color":"b381ff"},
	"tonics":{"display_name":"Field Tonics","fallback_icon_type":"tonic","color":"6ed9ef"}
}

static func capacity(state:Dictionary)->int:
	return maxi(0,int(state.get("vault_limit",30)))

static func flat_position(entry:Dictionary)->int:
	return int(entry.get("storage_page",0))*STORAGE_PAGE_SIZE+int(entry.get("storage_slot_index",-1))

static func position_for_flat(flat_index:int)->Dictionary:
	return {"storage_page":flat_index/STORAGE_PAGE_SIZE,"storage_slot_index":flat_index%STORAGE_PAGE_SIZE}

static func _all_entry_refs(state:Dictionary)->Array:
	var result:Array=[]
	for item in state.get("item_instances",[]):result.append(item)
	for stack in state.get("material_stacks",[]):result.append(stack)
	return result

static func entry_references(state:Dictionary)->Array:
	# Deliberately returns live entry dictionaries for drag/drop and transactions.
	return _all_entry_refs(state)

static func entry_by_id(state:Dictionary,entry_id:String)->Dictionary:
	for entry in _all_entry_refs(state):
		if str(entry.get("instance_id",""))==entry_id:return entry
	return {}

static func entry_at(state:Dictionary,page:int,slot:int)->Dictionary:
	var target:=page*STORAGE_PAGE_SIZE+slot
	for entry in _all_entry_refs(state):
		if flat_position(entry)==target:return entry
	return {}

static func occupied_count(state:Dictionary)->int:
	return _all_entry_refs(state).size()

static func empty_slots(state:Dictionary)->int:
	return maxi(0,capacity(state)-occupied_count(state))

static func occupancy_ratio(state:Dictionary)->float:
	return float(occupied_count(state))/float(maxi(1,capacity(state)))

static func warning_state(state:Dictionary)->String:
	var ratio:=occupancy_ratio(state)
	if empty_slots(state)<=0 or ratio>=VAULT_CRITICAL_THRESHOLD:return "critical"
	if ratio>=VAULT_WARNING_THRESHOLD:return "warning"
	return "normal"

static func _first_empty_flat(state:Dictionary)->int:
	var occupied:Dictionary={}
	for entry in _all_entry_refs(state):occupied[flat_position(entry)]=true
	for flat_index in capacity(state):
		if not occupied.has(flat_index):return flat_index
	return -1

static func _assign_position(entry:Dictionary,flat_index:int)->void:
	var position:=position_for_flat(flat_index)
	entry["storage_page"]=position.storage_page
	entry["storage_slot_index"]=position.storage_slot_index

static func _next_material_id(state:Dictionary)->String:
	var next_id:=maxi(1,int(state.get("next_material_stack_id",1)))
	var result:="material_stack_%d"%next_id
	while not entry_by_id(state,result).is_empty():
		next_id+=1
		result="material_stack_%d"%next_id
	state["next_material_stack_id"]=next_id+1
	return result

static func next_item_instance_id(state:Dictionary,prefix:String="item")->String:
	var next_id:=maxi(1,int(state.get("next_item_instance_id",1)))
	var result:="%s_%d"%[prefix,next_id]
	while not entry_by_id(state,result).is_empty():
		next_id+=1
		result="%s_%d"%[prefix,next_id]
	state["next_item_instance_id"]=next_id+1
	return result

static func _material_stack(state:Dictionary,material_id:String,quantity:int)->Dictionary:
	var definition:Dictionary=MATERIAL_DEFINITIONS.get(material_id,{"display_name":material_id.capitalize(),"fallback_icon_type":"material","color":"e9f1ff"})
	return {"instance_id":_next_material_id(state),"definition_id":"material_%s"%material_id,"material_id":material_id,"display_name":definition.display_name,"quantity":quantity,"max_stack":MATERIAL_STACK_LIMIT,"icon_path":"","fallback_icon_type":definition.fallback_icon_type,"color":definition.color,"is_material":true,"owner_state":"vault","equipped_hero_index":-1}

static func sync_legacy_material_totals(state:Dictionary)->void:
	for material_id in MATERIAL_DEFINITIONS:state[material_id]=0
	for stack in state.get("material_stacks",[]):
		var material_id:=str(stack.get("material_id",""))
		if material_id in MATERIAL_DEFINITIONS:state[material_id]=int(state.get(material_id,0))+int(stack.get("quantity",0))

static func ensure_storage_state(state:Dictionary)->void:
	if not state.has("item_instances") or not state.item_instances is Array:state["item_instances"]=[]
	if not state.has("material_stacks") or not state.material_stacks is Array:state["material_stacks"]=[]
	if not state.has("vault_limit"):state["vault_limit"]=30
	var tracks_unlocked_pages:=state.has("vault_level");var unlocked_pages:=clampi(int(state.get("vault_level",1)),1,STORAGE_PAGE_COUNT)
	if tracks_unlocked_pages:state["vault_level"]=unlocked_pages
	# Older builds unlocked a visual page while adding only ten physical slots.
	# Migrate once to the current one-page/one-bag/30-slot contract, while leaving
	# room for future equipped bags to provide variable capacity after migration.
	if tracks_unlocked_pages and int(state.get("storage_page_capacity_version",0))<2:
		state["vault_limit"]=clampi(maxi(int(state.vault_limit),unlocked_pages*STORAGE_PAGE_SIZE),STORAGE_PAGE_SIZE,STORAGE_PAGE_SIZE*STORAGE_PAGE_COUNT)
		state["storage_page_capacity_version"]=2
	if not state.has("next_material_stack_id"):state["next_material_stack_id"]=1
	if not state.has("next_item_instance_id"):state["next_item_instance_id"]=1

	# An instance ID is the ownership identity. Keep exactly one copy during migration.
	var unique_items:Array=[];var seen_ids:Dictionary={}
	for raw_item in state.item_instances:
		if not raw_item is Dictionary:continue
		var item:Dictionary=raw_item
		var instance_id:=str(item.get("instance_id",""))
		if instance_id=="":instance_id=next_item_instance_id(state,"legacy_item");item["instance_id"]=instance_id
		if seen_ids.has(instance_id):continue
		seen_ids[instance_id]=true;item["is_material"]=false;unique_items.append(item)
	state["item_instances"]=unique_items

	var clean_stacks:Array=[];var stack_ids:Dictionary={}
	for raw_stack in state.material_stacks:
		if not raw_stack is Dictionary or int(raw_stack.get("quantity",0))<=0:continue
		var stack:Dictionary=raw_stack
		var material_id:=str(stack.get("material_id",""))
		if material_id=="":continue
		var instance_id:=str(stack.get("instance_id",""))
		if instance_id=="" or seen_ids.has(instance_id) or stack_ids.has(instance_id):instance_id=_next_material_id(state);stack["instance_id"]=instance_id
		stack_ids[instance_id]=true;stack["is_material"]=true;stack["max_stack"]=maxi(1,int(stack.get("max_stack",MATERIAL_STACK_LIMIT)));clean_stacks.append(stack)
	state["material_stacks"]=clean_stacks

	# Legacy saves stored one number per material. Convert once, preserving every unit.
	if state.material_stacks.is_empty():
		for material_id in MATERIAL_DEFINITIONS:
			var remaining:=maxi(0,int(state.get(material_id,0)))
			while remaining>0:
				var amount:=mini(MATERIAL_STACK_LIMIT,remaining)
				state.material_stacks.append(_material_stack(state,material_id,amount));remaining-=amount

	# Preserve every pre-existing entry even if a very old save reported too little capacity.
	if _all_entry_refs(state).size()>capacity(state):state["vault_limit"]=_all_entry_refs(state).size()
	var occupied:Dictionary={};var unplaced:Array=[]
	for entry in _all_entry_refs(state):
		var flat:=flat_position(entry)
		if flat<0 or flat>=capacity(state) or occupied.has(flat):unplaced.append(entry)
		else:occupied[flat]=true
	for entry in unplaced:
		var open_flat:=-1
		for flat_index in capacity(state):
			if not occupied.has(flat_index):open_flat=flat_index;break
		if open_flat<0:
			open_flat=capacity(state);state["vault_limit"]=open_flat+1
		_assign_position(entry,open_flat);occupied[open_flat]=true
	sync_legacy_material_totals(state)

static func move_entry(state:Dictionary,entry_id:String,target_page:int,target_slot:int)->Dictionary:
	ensure_storage_state(state)
	var source:=entry_by_id(state,entry_id)
	var target_flat:=target_page*STORAGE_PAGE_SIZE+target_slot
	if source.is_empty() or target_flat<0 or target_flat>=capacity(state):return {"success":false,"reason":"Invalid storage position"}
	var source_flat:=flat_position(source)
	if source_flat==target_flat:return {"success":true,"swapped":false}
	var target:=entry_at(state,target_page,target_slot)
	_assign_position(source,target_flat)
	if not target.is_empty():_assign_position(target,source_flat)
	return {"success":true,"swapped":not target.is_empty()}

static func add_equipment(state:Dictionary,item:Dictionary)->Dictionary:
	ensure_storage_state(state)
	var instance_id:=str(item.get("instance_id",""))
	if instance_id=="":instance_id=next_item_instance_id(state,str(item.get("definition_id","item")));item["instance_id"]=instance_id
	if not entry_by_id(state,instance_id).is_empty():return {"success":false,"reason":"Duplicate item instance","collected":0,"rejected":1}
	var open_flat:=_first_empty_flat(state)
	if open_flat<0:return {"success":false,"reason":"Guild Vault Full","collected":0,"rejected":1}
	item["is_material"]=false
	item["owner_state"]=str(item.get("owner_state","vault"))
	item["equipped_hero_index"]=int(item.get("equipped_hero_index",-1))
	_assign_position(item,open_flat);state.item_instances.append(item)
	return {"success":true,"reason":"","collected":1,"rejected":0,"instance_id":instance_id}

static func add_material(state:Dictionary,material_id:String,quantity:int)->Dictionary:
	ensure_storage_state(state)
	var requested:=maxi(0,quantity);var remaining:=requested
	for stack in state.material_stacks:
		if str(stack.get("material_id",""))!=material_id:continue
		var room:=maxi(0,int(stack.get("max_stack",MATERIAL_STACK_LIMIT))-int(stack.get("quantity",0)))
		var added:=mini(room,remaining);stack["quantity"]=int(stack.get("quantity",0))+added;remaining-=added
		if remaining<=0:break
	while remaining>0:
		var open_flat:=_first_empty_flat(state)
		if open_flat<0:break
		var added:=mini(MATERIAL_STACK_LIMIT,remaining);var stack:=_material_stack(state,material_id,added);_assign_position(stack,open_flat);state.material_stacks.append(stack);remaining-=added
	sync_legacy_material_totals(state)
	return {"success":remaining==0,"requested":requested,"collected":requested-remaining,"rejected":remaining,"reason":"" if remaining==0 else "Guild Vault Full"}

static func consume_material(state:Dictionary,material_id:String,quantity:int)->Dictionary:
	ensure_storage_state(state)
	var requested:=maxi(0,quantity);var available:=0
	for stack in state.material_stacks:
		if str(stack.get("material_id",""))==material_id:available+=int(stack.get("quantity",0))
	if available<requested:return {"success":false,"reason":"Missing %s"%MATERIAL_DEFINITIONS.get(material_id,{"display_name":material_id}).display_name}
	var remaining:=requested
	for index in range(state.material_stacks.size()-1,-1,-1):
		var stack:Dictionary=state.material_stacks[index]
		if str(stack.get("material_id",""))!=material_id:continue
		var consumed:=mini(remaining,int(stack.get("quantity",0)));stack["quantity"]=int(stack.quantity)-consumed;remaining-=consumed
		if int(stack.quantity)<=0:state.material_stacks.remove_at(index)
		if remaining<=0:break
	sync_legacy_material_totals(state)
	return {"success":true,"consumed":requested}

static func simulate_inventory_transaction(state:Dictionary,inputs:Array,outputs:Array)->Dictionary:
	var simulated:Dictionary=state.duplicate(true);ensure_storage_state(simulated)
	for input in inputs:
		if str(input.get("kind","material"))!="material":return {"success":false,"reason":"Unsupported inventory input"}
		var consumed:=consume_material(simulated,str(input.get("material_id","")),int(input.get("quantity",0)))
		if not consumed.success:return {"success":false,"reason":consumed.reason}
	var output_results:Array=[]
	for output in outputs:
		var result:Dictionary
		if str(output.get("kind","equipment"))=="material":result=add_material(simulated,str(output.get("material_id","")),int(output.get("quantity",0)))
		else:
			var item:Dictionary=output.get("item",output).duplicate(true);result=add_equipment(simulated,item)
		output_results.append(result)
		if not bool(result.get("success",false)):return {"success":false,"reason":result.get("reason","Not Enough Storage Space"),"output_results":output_results}
	return {"success":true,"reason":"","state":simulated,"output_results":output_results}

static func apply_inventory_transaction(state:Dictionary,inputs:Array,outputs:Array)->Dictionary:
	var simulation:=simulate_inventory_transaction(state,inputs,outputs)
	if not simulation.success:return simulation
	var simulated:Dictionary=simulation.state
	for key in ["item_instances","material_stacks","next_material_stack_id","next_item_instance_id","vault_limit","ore","herbs","dust","tonics"]:
		if simulated.has(key):state[key]=simulated[key]
	return simulation

static func material_card_data(stack:Dictionary)->Dictionary:
	return {"kind":"material","instance_id":stack.get("instance_id",""),"display_name":stack.get("display_name","Material"),"icon_path":stack.get("icon_path",""),"fallback_icon_type":stack.get("fallback_icon_type","material"),"rarity":"Material","tier":0,"slot":"material","quantity":int(stack.get("quantity",0)),"max_stack":int(stack.get("max_stack",MATERIAL_STACK_LIMIT)),"status":"Stored in Guild Vault","stats":[],"passives":[]}

static func fallback_glyph(fallback_type:String)->String:
	return {"bow":"BOW","weapon_and_shield":"SHD","shield":"SHD","dual_wield":"DW","one_handed":"1H","two_handed":"2H","wand":"WND","focus":"FOC","staff":"STF","firearm":"GUN","crossbow":"XBOW","head":"HELM","chest":"CHEST","hands":"GLOVE","neck":"NECK","trinket":"RELIC","ore":"ORE","herb":"HERB","dust":"DUST","tonic":"TONIC","material":"MAT"}.get(fallback_type,str(fallback_type).left(5).to_upper())

static func matches_filter(entry:Dictionary,category:String,status:String,rarity:String,tier:int)->bool:
	var is_material:=bool(entry.get("is_material",false))
	var slot:=str(entry.get("slot",""))
	if category=="Weapons" and (is_material or slot!="weapon"):return false
	if category=="Armor" and (is_material or slot not in ["head","chest","hands"]):return false
	if category=="Neck" and (is_material or slot!="neck"):return false
	if category=="Trinkets" and (is_material or slot!="trinket"):return false
	if category=="Materials" and not is_material:return false
	if status=="Equipped" and (is_material or int(entry.get("equipped_hero_index",-1))<0):return false
	if status=="Unequipped" and (is_material or int(entry.get("equipped_hero_index",-1))>=0):return false
	if rarity!="All Rarities" and (is_material or str(entry.get("rarity",""))!=rarity):return false
	if tier>0 and (is_material or int(entry.get("tier",0))!=tier):return false
	return true
