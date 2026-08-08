extends RefCounted

const ProfessionData = preload("res://scripts/data/profession_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const PrestigeSystem = preload("res://scripts/systems/prestige_system.gd")
const TavernFacilitySystem = preload("res://scripts/systems/tavern_facility_system.gd")
const CookingData = preload("res://scripts/data/cooking_data.gd")

const SAVE_VERSION := 3
const CLEAN_DISENCHANT_OUTPUTS := ["arcane_dust","trait_shard","arcane_essence","lineage_echo"]

static func default_progress()->Dictionary:
	return {"profession_id":"","profession_slots":[""],"profession_rank":0,"profession_xp":0,"profession_choices":{},"profession_milestones":[],"profession_specialization_score":[0,0],"profession_commitment":"","known_personal_techniques":[],"current_profession_order_id":"","profession_history":[],"rune_loadout":{}}

static func ensure_state(state:Dictionary)->void:
	if not state.get("component_versions") is Dictionary:state["component_versions"]={}
	state.component_versions["professions"]=SAVE_VERSION
	if not state.get("guild_recipes") is Dictionary:state["guild_recipes"]={}
	if not state.get("discovered_rune_patterns") is Array:state["discovered_rune_patterns"]=[]
	if not state.get("rune_collection") is Dictionary:state["rune_collection"]={}
	if not state.get("profession_orders") is Array:state["profession_orders"]=[]
	state.profession_orders=state.profession_orders.filter(func(value):return value is Dictionary)
	if not state.has("next_profession_order_id"):state["next_profession_order_id"]=1
	if not state.get("profession_completion_alerts") is Array:state["profession_completion_alerts"]=[]
	if not state.get("profession_debug") is Dictionary:state["profession_debug"]={"time_multiplier":ProfessionData.DEBUG_TIME_MULTIPLIER,"guaranteed_lineage_echo":false,"guaranteed_world_recipe_drop":false}
	for recipe_id in state.guild_recipes.keys():
		var record=state.guild_recipes[recipe_id]
		if not record is Dictionary:state.guild_recipes[recipe_id]=recipe_record(str(recipe_id),"discovered");continue
		if not record.has("recipe_id"):record["recipe_id"]=recipe_id
		if not record.has("knowledge_state"):record["knowledge_state"]="recipe_learned"
		if not record.has("success_count"):record["success_count"]=0
		if not record.has("automation_eligible"):record["automation_eligible"]=false
	for hero in state.get("heroes",[]):
		if not hero is Dictionary:continue
		hero["profession_progress"]=migrate_progress(hero.get("profession_progress",{}))
	for item in state.get("item_instances",[]):
		if item is Dictionary:migrate_item(item)

static func migrate_progress(raw)->Dictionary:
	var result:=default_progress()
	if raw is Dictionary:
		for key in raw:result[key]=raw[key]
	if not result.get("profession_slots") is Array:result["profession_slots"]=[str(result.get("profession_id",""))]
	if result.profession_slots.is_empty():result.profession_slots=[str(result.get("profession_id",""))]
	result.profession_slots[0]=str(result.get("profession_id",result.profession_slots[0]))
	if not result.get("profession_choices") is Dictionary:result["profession_choices"]={}
	for key in ["profession_milestones","known_personal_techniques","profession_history"]:
		if not result.get(key) is Array:result[key]=[]
	if not result.get("profession_specialization_score") is Array or result.profession_specialization_score.size()<2:result["profession_specialization_score"]=[0,0]
	if not result.get("rune_loadout") is Dictionary:result["rune_loadout"]={}
	result.profession_rank=clampi(int(result.get("profession_rank",0)),0,5)
	result.profession_xp=maxi(0,int(result.get("profession_xp",0)))
	return result

static func migrate_item(item:Dictionary)->void:
	var slot:=str(item.get("slot",""));var definition_id:=str(item.get("definition_id",""))
	if not item.has("item_form_id"):item["item_form_id"]=definition_id
	if not item.has("item_family"):item["item_family"]="weapon" if slot=="weapon" else slot if slot!="" else "misc"
	if not item.has("item_level"):item["item_level"]=maxi(1,int(item.get("tier",1)))
	if not item.has("item_xp"):item["item_xp"]=0
	if not item.get("traits") is Array:item["traits"]=item.get("passive_effect_ids",[]).duplicate()
	if not item.has("trait_capacity"):item["trait_capacity"]=trait_capacity(str(item.get("rarity","Common")))
	for key in ["tags","contained_parent_items"]:
		if not item.get(key) is Array:item[key]=[]
	for key in ["element","region","faction","boss_identity","source_type"]:
		if not item.has(key):item[key]="world" if key=="source_type" else ""
	if not item.get("enchanting_preparation") is Dictionary:item["enchanting_preparation"]={}
	for key in ["favourite","reserved","breeding_stock","never_disenchant","never_separate","awaiting_player_review","world_only","craft_only"]:
		if not item.has(key):item[key]=false

static func trait_capacity(rarity:String)->int:
	return int(ProfessionData.TRAIT_CAPACITY.get(rarity,1))

static func hero_index(state:Dictionary,hero_id:String)->int:
	for index in state.get("heroes",[]).size():
		if str(state.heroes[index].get("hero_id",""))==hero_id:return index
	return -1

static func progress(state:Dictionary,hero_id:String)->Dictionary:
	ensure_state(state);var index:=hero_index(state,hero_id)
	return state.heroes[index].profession_progress if index>=0 else {}

static func learn_profession(state:Dictionary,hero_id:String,profession_id:String)->Dictionary:
	ensure_state(state);var index:=hero_index(state,hero_id)
	if index<0:return {"success":false,"reason":"Unknown guild member"}
	if not ProfessionData.PROFESSIONS.has(profession_id):return {"success":false,"reason":"Unknown profession"}
	var availability:=TavernFacilitySystem.member_status(state,hero_id)
	if not bool(availability.available):return {"success":false,"reason":str(availability.label)}
	var current:Dictionary=state.heroes[index].profession_progress
	if str(current.profession_id)!="":return {"success":false,"reason":"This member already knows %s."%ProfessionData.profession_name(str(current.profession_id))}
	if int(state.get("gold",0))<ProfessionData.LEARN_COST:return {"success":false,"reason":"Requires %d Gold."%ProfessionData.LEARN_COST}
	state.gold=int(state.gold)-ProfessionData.LEARN_COST;var next:=default_progress();next.profession_id=profession_id;next.profession_slots[0]=profession_id;next.profession_milestones=["profession_introduction"];next.profession_history.append({"event":"learned","profession_id":profession_id})
	state.heroes[index].profession_progress=next;update_rank(state,hero_id)
	return {"success":true,"reason":"","hero_index":index}

static func unlearn_profession(state:Dictionary,hero_id:String)->Dictionary:
	ensure_state(state);var index:=hero_index(state,hero_id)
	if index<0:return {"success":false,"reason":"Unknown guild member"}
	var current:Dictionary=state.heroes[index].profession_progress;var profession_id:=str(current.profession_id)
	if profession_id=="":return {"success":false,"reason":"This member has no profession."}
	if str(current.current_profession_order_id)!="":return {"success":false,"reason":"Cancel or complete this member's active profession order first."}
	if int(state.get("gold",0))<ProfessionData.UNLEARN_COST:return {"success":false,"reason":"Requires %d Gold."%ProfessionData.UNLEARN_COST}
	state.gold=int(state.gold)-ProfessionData.UNLEARN_COST;var next:=default_progress();next.profession_history=current.profession_history.duplicate(true);next.profession_history.append({"event":"unlearned","profession_id":profession_id});state.heroes[index].profession_progress=next
	return {"success":true,"reason":""}

static func add_milestone(state:Dictionary,hero_id:String,milestone_id:String)->void:
	var current:=progress(state,hero_id)
	if current.is_empty():return
	if milestone_id not in current.profession_milestones:current.profession_milestones.append(milestone_id)
	update_rank(state,hero_id)

static func grant_xp(state:Dictionary,hero_id:String,amount:int)->void:
	var current:=progress(state,hero_id)
	if current.is_empty() or str(current.profession_id)=="":return
	current.profession_xp=int(current.profession_xp)+maxi(0,amount);update_rank(state,hero_id)

static func rank_requirement_status(state:Dictionary,hero_id:String,rank:int)->Dictionary:
	var index:=hero_index(state,hero_id);var current_progress:Dictionary=state.heroes[index].get("profession_progress",{}) if index>=0 else {};var requirements:Dictionary=CookingData.RANK_REQUIREMENTS if str(current_progress.get("profession_id",""))=="cooking" else ProfessionData.RANK_REQUIREMENTS;var requirement:Dictionary=requirements.get(rank,{})
	if index<0 or requirement.is_empty():return {"met":false,"reason":"Unknown rank requirement"}
	var current:Dictionary=state.heroes[index].profession_progress;var missing:Array=[]
	if int(current.profession_xp)<int(requirement.xp):missing.append("%d / %d Profession XP"%[int(current.profession_xp),int(requirement.xp)])
	if not PrestigeSystem.hero_meets_prestige_requirement(state.heroes[index],int(requirement.prestige_rank)):missing.append("Hero Prestige Rank %s"%[int(requirement.prestige_rank)])
	for milestone in requirement.milestones:
		if milestone not in current.profession_milestones:missing.append(str(milestone).replace("_"," ").capitalize())
	return {"met":missing.is_empty(),"reason":"Ready" if missing.is_empty() else "Requires: "+", ".join(missing),"missing":missing}

static func update_rank(state:Dictionary,hero_id:String)->int:
	var current:=progress(state,hero_id)
	if current.is_empty() or str(current.profession_id)=="":return 0
	while int(current.profession_rank)<5:
		var next_rank:=int(current.profession_rank)+1;var status:=rank_requirement_status(state,hero_id,next_rank)
		if not bool(status.met):break
		current.profession_rank=next_rank
	return int(current.profession_rank)

static func choose_specialization(state:Dictionary,hero_id:String,rank:int,choice_id:String)->Dictionary:
	var current:=progress(state,hero_id)
	if current.is_empty() or str(current.profession_id)=="":return {"success":false,"reason":"Learn a profession first."}
	if rank<1 or rank>int(current.profession_rank):return {"success":false,"reason":"Profession Rank %d is required."%rank}
	var rank_key:=str(rank)
	if current.profession_choices.has(rank_key):return {"success":false,"reason":"A choice has already been made at this rank."}
	var choices:Array=ProfessionData.CHOICES.get(str(current.profession_id),[])
	if rank>choices.size():return {"success":false,"reason":"No choice is defined for this rank."}
	var selected:Dictionary={}
	for choice in choices[rank-1]:
		if str(choice.id)==choice_id:selected=choice;break
	if selected.is_empty():return {"success":false,"reason":"That choice is not available at this rank."}
	current.profession_choices[rank_key]=choice_id;var style:=int(selected.style);current.profession_specialization_score[style]=int(current.profession_specialization_score[style])+1
	if choice_id not in current.known_personal_techniques:current.known_personal_techniques.append(choice_id)
	if str(current.profession_id)=="cooking" and current.profession_choices.size()>=5:current.profession_commitment=CookingData.commitment(current)
	return {"success":true,"reason":""}

static func specialization_lean(current:Dictionary)->String:
	if str(current.get("profession_id",""))=="":return "None"
	var styles:Array=ProfessionData.PROFESSIONS[str(current.profession_id)].styles;var scores:Array=current.get("profession_specialization_score",[0,0])
	if int(scores[0])==int(scores[1]):return "Balanced"
	return str(styles[0 if int(scores[0])>int(scores[1]) else 1])

static func recipe_record(recipe_id:String,knowledge_state:String="recipe_learned")->Dictionary:
	return {"recipe_id":recipe_id,"knowledge_state":knowledge_state,"success_count":0,"automation_eligible":false}

static func discover_recipe(state:Dictionary,recipe_id:String,complete:bool=false)->Dictionary:
	ensure_state(state)
	if not ProfessionData.RECIPES.has(recipe_id):return {"success":false,"reason":"Unknown recipe"}
	if not state.guild_recipes.has(recipe_id):state.guild_recipes[recipe_id]=recipe_record(recipe_id,"recipe_learned" if complete else "discovered")
	elif complete:state.guild_recipes[recipe_id].knowledge_state="recipe_learned"
	return {"success":true,"reason":""}

static func recipe_is_learned(state:Dictionary,recipe_id:String)->bool:
	ensure_state(state);return str(state.guild_recipes.get(recipe_id,{}).get("knowledge_state","unknown")) in ["recipe_learned","pattern_mastered"]

static func is_pattern_mastered(state:Dictionary,recipe_id:String)->bool:
	ensure_state(state);return str(state.guild_recipes.get(recipe_id,{}).get("knowledge_state",""))=="pattern_mastered"

static func is_recipe_automation_eligible(state:Dictionary,recipe_id:String)->bool:
	ensure_state(state);return bool(state.guild_recipes.get(recipe_id,{}).get("automation_eligible",false))

static func record_recipe_success(state:Dictionary,recipe_id:String)->void:
	discover_recipe(state,recipe_id,true);var record:Dictionary=state.guild_recipes[recipe_id];record.success_count=int(record.success_count)+1;var recipe:Dictionary=ProfessionData.recipe(recipe_id)
	if int(record.success_count)>=int(recipe.get("mastery_required",ProfessionData.PATTERN_MASTERY_DEFAULT)):record.knowledge_state="pattern_mastered";record.automation_eligible=true

static func get_recipe_inputs(recipe_id:String)->Dictionary:
	var recipe:=ProfessionData.recipe(recipe_id);return {"materials":recipe.get("materials",[]).duplicate(true),"input_items":int(recipe.get("input_items",0)),"compatible_family":recipe.get("compatible_family","")}

static func get_recipe_outputs(recipe_id:String)->Dictionary:
	var recipe:=ProfessionData.recipe(recipe_id);return {"materials":recipe.get("outputs",[]).duplicate(true),"item_definition_id":recipe.get("output_definition_id",""),"rune_id":recipe.get("rune_id",""),"meal_id":recipe.get("meal_id",""),"servings":int(recipe.get("servings",0))}

static func can_member_perform(state:Dictionary,hero_id:String,action_id:String)->Dictionary:
	ensure_state(state);var current:=progress(state,hero_id);var recipe:=ProfessionData.recipe(action_id)
	if current.is_empty():return {"success":false,"reason":"Unknown guild member."}
	if str(current.profession_id)=="":return {"success":false,"reason":"This member has not learned a profession."}
	if recipe.is_empty():return {"success":false,"reason":"Unknown profession action."}
	if str(recipe.profession)!=str(current.profession_id):return {"success":false,"reason":"Requires %s."%ProfessionData.profession_name(str(recipe.profession))}
	if int(current.profession_rank)<int(recipe.get("rank",0)):return {"success":false,"reason":"Requires %s Rank %d."%[ProfessionData.profession_name(str(recipe.profession)),int(recipe.rank)]}
	if str(recipe.profession)=="cooking":
		var meal:Dictionary=CookingData.meal(str(recipe.get("meal_id","")));var purpose:=str(meal.get("purpose",""));var required_choice:=""
		if str(recipe.get("meal_id",""))=="restorative_broth":required_choice="cooking_care_route"
		elif purpose=="candidate":required_choice="cooking_campaign_menus"
		elif purpose=="mission":required_choice="cooking_mission_meals"
		elif str(recipe.get("meal_id",""))=="house_banquet":required_choice="cooking_house_banquet"
		elif str(recipe.get("meal_id",""))=="guild_feast":required_choice="cooking_guild_feast"
		if required_choice!="" and required_choice not in current.known_personal_techniques:return {"success":false,"reason":"Requires %s."%required_choice.trim_prefix("cooking_").replace("_"," ").capitalize()}
	if str(current.current_profession_order_id)!="":return {"success":false,"reason":"Member is already working on profession order %s."%str(current.current_profession_order_id)}
	var availability:=TavernFacilitySystem.member_status(state,hero_id)
	if not bool(availability.available):return {"success":false,"reason":str(availability.label)}
	if str(recipe.get("action",""))=="rune" and str(recipe.get("pattern_id","")) not in state.discovered_rune_patterns:return {"success":false,"reason":"Requires discovered Rune pattern %s."%str(recipe.pattern_id)}
	if not recipe_is_learned(state,action_id) and not bool(recipe.get("auto_known",false)) and str(recipe.get("action","")) not in ["rune"]:return {"success":false,"reason":"The guild has not learned this recipe."}
	return {"success":true,"reason":""}

static func get_available_recipes(state:Dictionary,hero_id:String,_station_id:String="")->Array:
	var result:Array=[]
	for recipe_id in ProfessionData.RECIPES:
		var check:=can_member_perform(state,hero_id,recipe_id)
		if bool(check.success):result.append(recipe_id)
	return result

static func _material_quantity(state:Dictionary,material_id:String)->int:
	var amount:=0
	for stack in state.get("material_stacks",[]):
		if str(stack.get("material_id",""))==material_id and InventorySystem.storage_location(stack)=="depot":amount+=int(stack.get("quantity",0))
	return amount

static func _item_by_id(state:Dictionary,instance_id:String)->Dictionary:
	return ItemData.item_by_instance_id(state.get("item_instances",[]),instance_id)

static func _validate_item_inputs(state:Dictionary,recipe:Dictionary,item_ids:Array)->Dictionary:
	var needed:=int(recipe.get("input_items",0))
	if needed!=item_ids.size():return {"success":false,"reason":"Requires exactly %d complete parent items."%needed}
	var seen:Dictionary={};var items:Array=[];var rarity:="";var family:=str(recipe.get("compatible_family",""))
	for instance_id in item_ids:
		if seen.has(str(instance_id)):return {"success":false,"reason":"Each parent item must be a different instance."}
		seen[str(instance_id)]=true;var item:=_item_by_id(state,str(instance_id))
		if item.is_empty():return {"success":false,"reason":"Parent item %s is missing."%str(instance_id)}
		migrate_item(item)
		if str(item.get("owner_state","vault"))=="equipped":return {"success":false,"reason":"Equipped items cannot be used as parents."}
		if InventorySystem.storage_location(item)!="depot":return {"success":false,"reason":"Move Workshop input items to the Workshop Depot first."}
		if bool(item.get("reserved",false)) or bool(item.get("favourite",false)):return {"success":false,"reason":"Protected parent items must be unreserved first."}
		if family!="" and str(item.item_family)!=family:return {"success":false,"reason":"Requires three compatible %s parents."%family}
		if rarity=="":rarity=str(item.rarity)
		elif rarity!=str(item.rarity):return {"success":false,"reason":"Basic synthesis requires parents of the same rarity."}
		items.append(item)
	if str(recipe.get("input_rarity",""))!="" and rarity!=str(recipe.input_rarity):return {"success":false,"reason":"Requires %s parent items."%str(recipe.input_rarity)}
	return {"success":true,"reason":"","items":items,"rarity":rarity}

static func can_start_order(state:Dictionary,hero_id:String,recipe_id:String,inputs:Dictionary={})->Dictionary:
	var member_check:=can_member_perform(state,hero_id,recipe_id)
	if not bool(member_check.success):return member_check
	var recipe:=ProfessionData.recipe(recipe_id)
	for material in recipe.get("materials",[]):
		if _material_quantity(state,str(material.material_id))<int(material.quantity):return {"success":false,"reason":"Missing %d %s."%[int(material.quantity),str(material.material_id).replace("_"," ").capitalize()]}
	if int(recipe.get("input_items",0))>0:
		var item_check:=_validate_item_inputs(state,recipe,inputs.get("item_instance_ids",[]))
		if not bool(item_check.success):return item_check
	return {"success":true,"reason":""}

static func start_profession_order(state:Dictionary,hero_id:String,recipe_id:String,inputs:Dictionary={})->Dictionary:
	ensure_state(state);var validation:=can_start_order(state,hero_id,recipe_id,inputs)
	if not bool(validation.success):return validation
	var recipe:=ProfessionData.recipe(recipe_id);var material_inputs:Array=recipe.get("materials",[]).duplicate(true);var snapshots:Array=[]
	for material in material_inputs:
		var consumed:=InventorySystem.consume_material(state,str(material.material_id),int(material.quantity))
		if not bool(consumed.success):return consumed
	for instance_id in inputs.get("item_instance_ids",[]):
		var item:=_item_by_id(state,str(instance_id));snapshots.append(item.duplicate(true));state.item_instances.erase(item)
	var number:=maxi(1,int(state.next_profession_order_id));var order_id:="profession_order_%d"%number;state.next_profession_order_id=number+1;var duration:=float(recipe.get("duration",20.0))*maxf(0.01,float(state.profession_debug.get("time_multiplier",ProfessionData.DEBUG_TIME_MULTIPLIER)))
	var order:={"order_id":order_id,"profession":recipe.profession,"recipe_id":recipe_id,"action_id":recipe_id,"assigned_member_id":hero_id,"input_items":snapshots,"input_materials":material_inputs,"expected_output":get_recipe_outputs(recipe_id),"start_time":Time.get_unix_time_from_system(),"duration":duration,"remaining_time":duration,"status":"active","paused":false,"completion_result":{},"xp_reward":int(recipe.get("xp",0)),"mastery_progress":0,"preferred_trait":str(inputs.get("preferred_trait","")),"station":ProfessionData.PROFESSIONS[str(recipe.profession)].station}
	state.profession_orders.append(order);var current:=progress(state,hero_id);current.current_profession_order_id=order_id;current.profession_history.append({"event":"order_started","order_id":order_id,"recipe_id":recipe_id})
	return {"success":true,"reason":"","order_id":order_id,"order":order}

static func _order_index(state:Dictionary,order_id:String)->int:
	for index in state.get("profession_orders",[]).size():
		if str(state.profession_orders[index].get("order_id",""))==order_id:return index
	return -1

static func pause_profession_order(state:Dictionary,order_id:String,paused:bool=true)->Dictionary:
	var index:=_order_index(state,order_id)
	if index<0:return {"success":false,"reason":"Unknown profession order."}
	if str(state.profession_orders[index].status)!="active" and not bool(state.profession_orders[index].paused):return {"success":false,"reason":"Only active orders can be paused."}
	state.profession_orders[index].paused=paused;state.profession_orders[index].status="paused" if paused else "active";return {"success":true,"reason":""}

static func cancel_profession_order(state:Dictionary,order_id:String)->Dictionary:
	var index:=_order_index(state,order_id)
	if index<0:return {"success":false,"reason":"Unknown profession order."}
	var order:Dictionary=state.profession_orders[index]
	if str(order.status) in ["complete","cancelled"]:return {"success":false,"reason":"This order is already finished."}
	var outputs:Array=[]
	for material in order.input_materials:outputs.append({"kind":"material","material_id":material.material_id,"quantity":material.quantity})
	for item in order.input_items:outputs.append({"kind":"equipment","item":item})
	var storage_check:=InventorySystem.simulate_inventory_transaction(state,[],outputs)
	if not bool(storage_check.success):return {"success":false,"reason":"Cannot cancel: returned inputs need Guild Vault space."}
	InventorySystem.apply_inventory_transaction(state,[],outputs);order.status="cancelled";order.paused=false;var current:=progress(state,str(order.assigned_member_id));current.current_profession_order_id="";current.profession_history.append({"event":"order_cancelled","order_id":order_id})
	return {"success":true,"reason":"Inputs were returned; spent time was lost."}

static func evaluate_inheritance(parents:Array,preferred_trait:String="",result_family:String="")->Dictionary:
	var compatible:Array=[];var blocked:Array=[]
	for parent in parents:
		for inherited_trait in parent.get("traits",parent.get("passive_effect_ids",[])):
			var trait_id:=str(inherited_trait);var defensive:=trait_id in ["last_dawn","marchwarden_retaliation","retribution","warden"]
			if defensive and result_family not in ["head","chest","hands"]:blocked.append(trait_id)
			elif trait_id.begins_with("boss_") or trait_id.begins_with("world_"):blocked.append(trait_id)
			elif trait_id not in compatible:compatible.append(trait_id)
	var selected:Array=[]
	if preferred_trait!="" and preferred_trait in compatible:selected.append(preferred_trait)
	for compatible_trait in compatible:
		if compatible_trait not in selected:selected.append(compatible_trait)
	return {"visible_traits":compatible+blocked,"compatible_traits":compatible,"blocked_traits":blocked,"selected_traits":selected}

static func inspect_lineage(state:Dictionary,item_ids:Array,result_family:String="")->Dictionary:
	var parents:Array=[]
	for instance_id in item_ids:
		var item:=_item_by_id(state,str(instance_id))
		if item.is_empty():return {"success":false,"reason":"Parent item %s is missing."%str(instance_id)}
		migrate_item(item);parents.append(item)
	var inheritance:=evaluate_inheritance(parents,"",result_family);inheritance["success"]=true;inheritance["reason"]="";inheritance["inheritance_capacity"]=trait_capacity(str(parents[0].get("rarity","Common"))) if not parents.is_empty() else 0
	return inheritance

static func prepare_parent_set(state:Dictionary,hero_id:String,item_ids:Array,preferred_trait:String="",use_stabilizer:bool=false)->Dictionary:
	var current:=progress(state,hero_id)
	if str(current.get("profession_id",""))!="enchanting":return {"success":false,"reason":"Requires Enchanting."}
	if item_ids.is_empty() or item_ids.size()>3:return {"success":false,"reason":"Select one to three parent items."}
	var first_parent:=_item_by_id(state,str(item_ids[0]));var inspection:=inspect_lineage(state,item_ids,str(first_parent.get("item_family","")))
	if not bool(inspection.success):return inspection
	if preferred_trait!="" and preferred_trait not in inspection.compatible_traits:return {"success":false,"reason":"The preferred trait is blocked or absent from this lineage."}
	if preferred_trait!="" and "enchant_guided_inheritance" not in current.known_personal_techniques:return {"success":false,"reason":"Guided Inheritance is required to mark a preferred trait."}
	if use_stabilizer:
		var consumed:=InventorySystem.consume_material(state,"defensive_stabilizer",1)
		if not bool(consumed.success):return {"success":false,"reason":"Requires one Defensive Stabilizer."}
	for instance_id in item_ids:
		var item:=_item_by_id(state,str(instance_id));item.enchanting_preparation={"prepared_by":hero_id,"preferred_trait":preferred_trait,"stabilized":use_stabilizer}
	grant_xp(state,hero_id,6);return {"success":true,"reason":"Parent set prepared.","inspection":inspection}

static func evaluate_synthesis_result(state:Dictionary,recipe_id:String,parent_items:Array,options:Dictionary={})->Dictionary:
	var recipe:=ProfessionData.recipe(recipe_id)
	if recipe.is_empty():return {"success":false,"reason":"Unknown synthesis recipe."}
	var rarity:=str(parent_items[0].get("rarity","Common")) if not parent_items.is_empty() else "Common"
	if str(recipe.get("action",""))=="evolution":rarity=str(recipe.get("output_rarity",rarity))
	var definition_id:=str(recipe.get("output_definition_id",""))
	if definition_id=="":return {"success":false,"reason":"Discovery pool has no compatible result for these parent families."}
	var instance_id:=InventorySystem.next_item_instance_id(state,"crafted");var item:=ItemData.create_instance(definition_id,instance_id);migrate_item(item);item.rarity=rarity;item.trait_capacity=trait_capacity(rarity);item.source_type="crafted";item.craft_only=false;item.contained_parent_items=parent_items.duplicate(true);item.enchanting_preparation={"preferred_trait":options.get("preferred_trait","")}
	var inheritance:=evaluate_inheritance(parent_items,str(options.get("preferred_trait","")),str(item.item_family));item.traits=inheritance.selected_traits.slice(0,item.trait_capacity);item.passive_effect_ids=item.traits.duplicate()
	return {"success":true,"reason":"","item":item,"inheritance":inheritance,"controlled_pool":[definition_id]}

static func complete_profession_order(state:Dictionary,order_id:String)->Dictionary:
	ensure_state(state);var index:=_order_index(state,order_id)
	if index<0:return {"success":false,"reason":"Unknown profession order."}
	var order:Dictionary=state.profession_orders[index]
	if str(order.status)=="complete":return {"success":true,"reason":"","result":order.completion_result}
	if str(order.status)=="cancelled":return {"success":false,"reason":"Cancelled orders cannot complete."}
	var recipe:=ProfessionData.recipe(str(order.recipe_id));var outputs:Array=[];var result:Dictionary={}
	match str(recipe.get("action","")):
		"material":
			for material in recipe.get("outputs",[]):outputs.append({"kind":"material","material_id":material.material_id,"quantity":material.quantity})
		"rune":
			var rune_id:=str(recipe.rune_id);state.rune_collection[rune_id]=maxi(1,int(state.rune_collection.get(rune_id,0)));result={"rune_id":rune_id}
		"meal":
			var maker_id:=str(order.assigned_member_id);var duration_bonus:=0.0
			var servings:=TavernFacilitySystem.add_prepared_meals(state,str(recipe.meal_id),int(recipe.get("servings",1)),maker_id,duration_bonus);result={"meal_id":str(recipe.meal_id),"servings":servings,"duration_bonus_minutes":duration_bonus}
		"synthesis","evolution":
			var synthesis:=evaluate_synthesis_result(state,str(order.recipe_id),order.input_items,{"preferred_trait":order.preferred_trait})
			if not bool(synthesis.success):return synthesis
			outputs.append({"kind":"equipment","item":synthesis.item});result=synthesis
	if not outputs.is_empty():
		var output_check:=InventorySystem.simulate_inventory_transaction(state,[],outputs)
		if not bool(output_check.success):order.status="blocked";return {"success":false,"reason":"Order complete, but output is blocked: %s"%str(output_check.reason)}
		InventorySystem.apply_inventory_transaction(state,[],outputs)
	order.status="complete";order.paused=false;order.remaining_time=0.0;order.completion_result=result;var hero_id:=str(order.assigned_member_id);var current:=progress(state,hero_id);current.current_profession_order_id="";current.profession_history.append({"event":"order_completed","order_id":order_id,"recipe_id":order.recipe_id});grant_xp(state,hero_id,int(order.xp_reward));add_milestone(state,hero_id,"first_order");record_recipe_success(state,str(order.recipe_id));order.mastery_progress=int(state.guild_recipes[str(order.recipe_id)].success_count)
	if is_pattern_mastered(state,str(order.recipe_id)):add_milestone(state,hero_id,"pattern_mastered")
	state.profession_completion_alerts.append({"order_id":order_id,"member_id":hero_id,"text":"%s completed %s."%[hero_name(state,hero_id),str(recipe.display_name)]})
	if str(order.profession)=="cooking":
		add_milestone(state,hero_id,"cooking_first_meal")
		if int(recipe.get("rank",0))>=1:add_milestone(state,hero_id,"advanced_work")
		if int(recipe.get("rank",0))>=3 and is_pattern_mastered(state,str(order.recipe_id)):add_milestone(state,hero_id,"signature_work")
	return {"success":true,"reason":"","result":result}

static func process_orders(state:Dictionary,delta:float)->Array:
	ensure_state(state);var completed:Array=[]
	for order in state.profession_orders:
		if str(order.get("status",""))!="active" or bool(order.get("paused",false)):continue
		order.remaining_time=maxf(0.0,float(order.get("remaining_time",0.0))-maxf(0.0,delta))
		if float(order.remaining_time)<=0.0:
			var result:=complete_profession_order(state,str(order.order_id))
			if bool(result.success):completed.append(order.order_id)
	return completed

static func hero_name(state:Dictionary,hero_id:String)->String:
	var index:=hero_index(state,hero_id);return str(state.heroes[index].get("display_name",state.heroes[index].get("name","Hero"))) if index>=0 else "Hero"

static func member_activity(state:Dictionary,hero_id:String)->String:
	var facility_status:=TavernFacilitySystem.member_status(state,hero_id)
	if not bool(facility_status.available):return str(facility_status.label)
	var current:=progress(state,hero_id);var order_id:=str(current.get("current_profession_order_id",""))
	if order_id=="":return "Available"
	var index:=_order_index(state,order_id)
	if index<0:return "Available"
	var order:Dictionary=state.profession_orders[index];var verb:String=str({"forgecraft":"Forgecrafting","enchanting":"Enchanting","alchemy":"Distilling","inscription":"Inscribing","cooking":"Cooking"}.get(str(order.profession),"Working on"))
	return "%s %s%s"%[verb,str(ProfessionData.recipe(str(order.recipe_id)).get("display_name",order.recipe_id))," (Paused)" if bool(order.paused) else ""]

static func separate_item(state:Dictionary,hero_id:String,instance_id:String)->Dictionary:
	var current:=progress(state,hero_id)
	if str(current.get("profession_id",""))!="forgecraft":return {"success":false,"reason":"Requires Forgecraft."}
	var item:=_item_by_id(state,instance_id)
	if item.is_empty():return {"success":false,"reason":"Item is missing."}
	if str(item.get("owner_state","vault"))=="equipped":return {"success":false,"reason":"Equipped items cannot be separated."}
	if InventorySystem.storage_location(item)!="depot":return {"success":false,"reason":"Move the item to the Workshop Depot before separating it."}
	if bool(item.get("never_separate",false)) or bool(item.get("favourite",false)) or bool(item.get("reserved",false)):return {"success":false,"reason":"This item is protected from separation."}
	var parents:Array=item.get("contained_parent_items",[])
	if parents.size()!=3:return {"success":false,"reason":"This item does not contain an exact three-parent lineage."}
	var simulated:=state.duplicate(true);var simulated_item:=_item_by_id(simulated,instance_id);simulated.item_instances.erase(simulated_item)
	for parent in parents:
		var added:=InventorySystem.add_equipment(simulated,parent.duplicate(true))
		if not bool(added.success):return {"success":false,"reason":"Requires enough Vault space to restore all three exact parents."}
	state.item_instances.erase(item)
	for parent in parents:InventorySystem.add_equipment(state,parent.duplicate(true))
	grant_xp(state,hero_id,10);return {"success":true,"reason":"Exact parents restored. Ingredients, Gold, and profession time were not refunded.","restored":parents.duplicate(true)}

static func disenchant_item(state:Dictionary,hero_id:String,instance_id:String,preferred_trait:String="")->Dictionary:
	var current:=progress(state,hero_id)
	if str(current.get("profession_id",""))!="enchanting":return {"success":false,"reason":"Requires Enchanting."}
	if preferred_trait!="" and "enchant_targeted_reclamation" not in current.known_personal_techniques:return {"success":false,"reason":"Targeted Reclamation is required to prioritize a Trait Shard."}
	var item:=_item_by_id(state,instance_id)
	if item.is_empty():return {"success":false,"reason":"Item is missing."}
	if str(item.get("owner_state","vault"))=="equipped":return {"success":false,"reason":"Equipped items must be unequipped before disenchanting."}
	if InventorySystem.storage_location(item)!="depot":return {"success":false,"reason":"Move the item to the Workshop Depot before disenchanting it."}
	for flag in ["favourite","reserved","never_disenchant"]:
		if bool(item.get(flag,false)):return {"success":false,"reason":"This item is protected by %s."%flag.replace("_"," ").capitalize()}
	migrate_item(item);var rarity_index:=maxi(0,["Common","Uncommon","Rare","Epic","Legendary"].find(str(item.rarity)));var outputs:Array=[{"kind":"material","material_id":"arcane_dust","quantity":1+rarity_index}];var traits:Array=item.traits
	if not traits.is_empty():
		var selected_trait:=preferred_trait if preferred_trait in traits else str(traits[0]);outputs.append({"kind":"material","material_id":"trait_shard","quantity":1,"trait_id":selected_trait})
	if str(item.get("element",""))!="" or str(item.get("region",""))!="" or rarity_index>=2:outputs.append({"kind":"material","material_id":"arcane_essence","quantity":1})
	var echo:bool=bool(state.profession_debug.get("guaranteed_lineage_echo",false)) or (not item.contained_parent_items.is_empty() and rarity_index>=2)
	if echo:outputs.append({"kind":"material","material_id":"lineage_echo","quantity":1})
	var check:=InventorySystem.simulate_inventory_transaction(state,[],outputs)
	if not bool(check.success):return {"success":false,"reason":"Disenchanting output cannot fit in the Guild Vault."}
	state.item_instances.erase(item);InventorySystem.apply_inventory_transaction(state,[],outputs);grant_xp(state,hero_id,8+rarity_index*2)
	return {"success":true,"reason":"Item and contained lineage permanently destroyed.","outputs":outputs}

static func purify_material(state:Dictionary,hero_id:String)->Dictionary:
	var current:=progress(state,hero_id)
	if str(current.get("profession_id",""))!="alchemy" or "alchemy_purify" not in current.known_personal_techniques:return {"success":false,"reason":"Requires the Purify profession choice."}
	var transaction:=InventorySystem.apply_inventory_transaction(state,[{"kind":"material","material_id":"arcane_dust","quantity":4}],[{"kind":"material","material_id":"arcane_essence","quantity":1}])
	if not bool(transaction.success):return transaction
	grant_xp(state,hero_id,8);return {"success":true,"reason":"Four lower-quality Arcane Dust became one Arcane Essence."}

static func convert_material(state:Dictionary,hero_id:String)->Dictionary:
	var current:=progress(state,hero_id)
	if str(current.get("profession_id",""))!="alchemy" or "alchemy_convert" not in current.known_personal_techniques:return {"success":false,"reason":"Requires the Convert profession choice."}
	var transaction:=InventorySystem.apply_inventory_transaction(state,[{"kind":"material","material_id":"herbs","quantity":5}],[{"kind":"material","material_id":"ore_substitute","quantity":2}])
	if not bool(transaction.success):return transaction
	grant_xp(state,hero_id,8);return {"success":true,"reason":"Five Herbs became two Ore Substitutes; value was lost in conversion."}

static func refine_inherited_trait(state:Dictionary,hero_id:String,instance_id:String,trait_id:String)->Dictionary:
	var current:=progress(state,hero_id)
	if str(current.get("profession_id",""))!="enchanting":return {"success":false,"reason":"Requires Enchanting."}
	var item:=_item_by_id(state,instance_id);migrate_item(item)
	if item.is_empty() or trait_id not in item.traits:return {"success":false,"reason":"Enchanting cannot create an unrelated or blocked trait from nothing."}
	item["refined_traits"]=item.get("refined_traits",{});item.refined_traits[trait_id]=mini(1,int(item.refined_traits.get(trait_id,0))+1);grant_xp(state,hero_id,6);return {"success":true,"reason":""}

static func discover_rune_pattern(state:Dictionary,pattern_id:String)->void:
	ensure_state(state)
	if pattern_id not in state.discovered_rune_patterns:state.discovered_rune_patterns.append(pattern_id)

static func apply_rune(state:Dictionary,hero_id:String,ability_id:String,rune_id:String)->Dictionary:
	ensure_state(state);var index:=hero_index(state,hero_id)
	if index<0:return {"success":false,"reason":"Unknown guild member."}
	if rune_id!="" and int(state.rune_collection.get(rune_id,0))<=0:return {"success":false,"reason":"The guild has not crafted this reusable Rune."}
	if rune_id!="":
		var rune:Dictionary=ProfessionData.RUNES.get(rune_id,{})
		if rune.is_empty() or str(rune.ability_id)!=ability_id or str(rune.class_id)!=str(state.heroes[index].class_id):return {"success":false,"reason":"This Rune is not compatible with that member and ability."}
	state.heroes[index].profession_progress.rune_loadout[ability_id]=rune_id
	if rune_id=="":state.heroes[index].profession_progress.rune_loadout.erase(ability_id)
	return {"success":true,"reason":""}

static func ability_presentation(state:Dictionary,hero_id:String,ability_id:String,base_name:String)->Dictionary:
	var index:=hero_index(state,hero_id)
	if index<0:return {"display_name":base_name,"rune_id":"","mechanics_ability_id":ability_id}
	var rune_id:=str(state.heroes[index].profession_progress.get("rune_loadout",{}).get(ability_id,""));var rune:Dictionary=ProfessionData.RUNES.get(rune_id,{})
	var presentation:Dictionary=rune.get("presentation",{}).duplicate(true);presentation["display_name"]=presentation.get("display_name",base_name);presentation["rune_id"]=rune_id;presentation["mechanics_ability_id"]=ability_id
	return presentation
