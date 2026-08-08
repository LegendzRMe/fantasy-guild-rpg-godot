extends "res://scripts/ui/campaign_screen.gd"

# The old classic-MMO placeholder remains isolated in its parent for save/UI
# compatibility. This layer owns the playable member profession experience.

func craft(resource:String,cost:int,kind:String)->void:
	legacy_craft(resource,cost,kind)

func show_profession_trainer()->void:
	ProfessionSystem.ensure_state(state)
	screen="profession_trainer"
	var root:=base_screen("Profession Trainer","MERCHANT SERVICE  •  PROTOTYPE COSTS")
	var top:=HBoxContainer.new();root.add_child(top)
	var gold:=label("Gold  •  %d"%int(state.gold),19,C_GOLD);gold.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(gold)
	top.add_child(compact_button("Merchant Contacts",show_market,170))
	var selector:=OptionButton.new();selector.name="ProfessionTrainerMember";selector.custom_minimum_size=Vector2(420,44);root.add_child(selector)
	for hero_index in state.heroes.size():
		var hero:Dictionary=state.heroes[hero_index]
		var profession_id:=str(hero.profession_progress.profession_id)
		var status:="No Profession" if profession_id=="" else ProfessionData.profession_name(profession_id)
		selector.add_item("%s  •  %s"%[hero.display_name,status]);selector.set_item_metadata(hero_index,hero_index)
	if state.heroes.is_empty():return
	selected_profession_member=clampi(selected_profession_member,0,state.heroes.size()-1);selector.select(selected_profession_member)
	selector.item_selected.connect(func(index:int):selected_profession_member=int(selector.get_item_metadata(index));show_profession_trainer())
	var member:Dictionary=state.heroes[selected_profession_member];var current:Dictionary=member.profession_progress
	root.add_child(label("Each named member may learn one profession. The save model reserves a future second slot, but it is not active.",14,C_MUTED))
	var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",10);grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(grid)
	for profession_id in ProfessionData.PROFESSIONS:
		var definition:Dictionary=ProfessionData.PROFESSIONS[profession_id]
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(570,158);card.add_theme_stylebox_override("panel",ui_box(Color("182536"),8,Color("465b78"),1));grid.add_child(card)
		var content:=VBoxContainer.new();content.add_theme_constant_override("separation",5);card.add_child(content);content.add_child(label(str(definition.display_name),22,C_GOLD));content.add_child(label(str(definition.description),14,C_TEXT));content.add_child(label("Styles  •  %s"%" / ".join(definition.styles),13,C_MUTED));content.add_spacer(false)
		var learn:=compact_button("Learn • %d Gold"%ProfessionData.LEARN_COST,func(id=profession_id):request_learn_profession(id),170)
		learn.disabled=str(current.profession_id)!="" or int(state.gold)<ProfessionData.LEARN_COST
		learn.tooltip_text="A member may know only one profession." if str(current.profession_id)!="" else "Requires %d Gold."%ProfessionData.LEARN_COST if int(state.gold)<ProfessionData.LEARN_COST else "Confirm this profession."
		content.add_child(learn)
	var stock:=HBoxContainer.new();stock.alignment=BoxContainer.ALIGNMENT_CENTER;stock.add_theme_constant_override("separation",8);root.add_child(stock)
	stock.add_child(compact_button("Bulwark Recipe • 15g",func():buy_profession_recipe("forge_ashwood_bulwark",15),180))
	stock.add_child(compact_button("Catalyst Recipe • 10g",func():buy_profession_recipe("alchemy_basic_catalyst",10),180))
	stock.add_child(compact_button("Frostfall Pattern • 12g",func():buy_rune_pattern("pattern_frostfall",12),190))
	stock.add_child(compact_button("Runic Bolt Pattern • 12g",func():buy_rune_pattern("pattern_runic_bolt",12),195))

func request_learn_profession(profession_id:String)->void:
	if selected_profession_member<0 or selected_profession_member>=state.heroes.size():return
	var hero:Dictionary=state.heroes[selected_profession_member]
	var dialog:=ConfirmationDialog.new();dialog.title="LEARN %s?"%ProfessionData.profession_name(profession_id).to_upper();dialog.dialog_text="%s will learn %s for %d Gold.\n\nA member may know only one profession in this version."%[hero.display_name,ProfessionData.profession_name(profession_id),ProfessionData.LEARN_COST];dialog.ok_button_text="Learn Profession"
	dialog.confirmed.connect(func():
		var result:Dictionary=ProfessionSystem.learn_profession(state,str(hero.hero_id),profession_id)
		if bool(result.success):save_game();selected_roster_index=selected_profession_member;hero_roster_section="Professions";show_roster()
		else:flash(str(result.reason)))
	ui.add_child(dialog);dialog.popup_centered(Vector2i(560,280))

func request_unlearn_profession(hero_id:String)->void:
	var index:int=ProfessionSystem.hero_index(state,hero_id)
	if index<0:return
	var current:Dictionary=state.heroes[index].profession_progress
	var dialog:=ConfirmationDialog.new();dialog.title="UNLEARN %s?"%ProfessionData.profession_name(str(current.profession_id)).to_upper();dialog.dialog_text="Costs %d Gold. This permanently resets this member's Profession XP, Rank, choices, milestones, specialization progress, and personal techniques.\n\nGuild recipes, Pattern Mastery, crafted items, materials, Runes, and discoveries remain. Active orders must be cancelled first."%ProfessionData.UNLEARN_COST;dialog.ok_button_text="Unlearn and Reset"
	dialog.confirmed.connect(func():
		var result:Dictionary=ProfessionSystem.unlearn_profession(state,hero_id)
		if bool(result.success):save_game();show_roster()
		else:flash(str(result.reason)))
	ui.add_child(dialog);dialog.popup_centered(Vector2i(650,360))

func first_profession_action_item(action:String)->Dictionary:
	for item in state.item_instances:
		ProfessionSystem.migrate_item(item)
		if InventorySystem.storage_location(item)!="depot":continue
		if action=="separate" and item.contained_parent_items.size()==3 and not bool(item.never_separate) and not bool(item.favourite) and not bool(item.reserved):return item
		if action=="disenchant" and not bool(item.never_disenchant) and not bool(item.favourite) and not bool(item.reserved):return item
	return {}

func request_profession_item_action(hero_id:String,action:String)->void:
	var item:=first_profession_action_item(action)
	if item.is_empty():flash("No eligible Workshop Depot item is available for this action.");return
	var dialog:=ConfirmationDialog.new();dialog.title=("SEPARATE " if action=="separate" else "DISENCHANT ")+str(item.display_name).to_upper();dialog.ok_button_text="Separate and Restore Parents" if action=="separate" else "Permanently Disenchant"
	if action=="separate":
		var names:Array=item.contained_parent_items.map(func(parent):return str(parent.get("display_name",parent.get("instance_id","Parent"))));dialog.dialog_text="The combined result will be deleted. Exact parents returning:\n• %s\n\nTheir original XP, levels, traits, and enchantments return. Ingredients, Gold, and profession time do not."%"\n• ".join(names)
	else:dialog.dialog_text="This permanently destroys the item and all contained lineage. Outputs use only Arcane Dust, Trait Shards, Essences, and possible Lineage Echoes.\n\nRare or better items always require this confirmation."
	dialog.confirmed.connect(func():
		var result:Dictionary=ProfessionSystem.separate_item(state,hero_id,str(item.instance_id)) if action=="separate" else ProfessionSystem.disenchant_item(state,hero_id,str(item.instance_id))
		if bool(result.success):save_game();show_roster();flash(str(result.reason))
		else:flash(str(result.reason)))
	ui.add_child(dialog);dialog.popup_centered(Vector2i(650,380))

func prepare_prototype_parent_set(hero_id:String)->void:
	var item_ids:Array=[];var rarity:=""
	for item in state.item_instances:
		ProfessionSystem.migrate_item(item)
		if InventorySystem.storage_location(item)!="depot" or str(item.item_family)!="chest":continue
		if rarity=="":rarity=str(item.rarity)
		if str(item.rarity)!=rarity:continue
		item_ids.append(str(item.instance_id))
		if item_ids.size()==3:break
	if item_ids.size()<3:flash("Inspect Lineage requires three same-rarity chest parents in the Workshop Depot for this vertical slice.");return
	var inspection:Dictionary=ProfessionSystem.inspect_lineage(state,item_ids,"chest");var preferred:=""
	if not inspection.compatible_traits.is_empty():preferred=str(inspection.compatible_traits[0])
	var current:Dictionary=ProfessionSystem.progress(state,hero_id);if "enchant_guided_inheritance" not in current.known_personal_techniques:preferred=""
	var result:Dictionary=ProfessionSystem.prepare_parent_set(state,hero_id,item_ids,preferred,_material_available("defensive_stabilizer"))
	if bool(result.success):save_game();show_roster();flash("Lineage inspected: %d compatible, %d blocked. Parent metadata prepared."%[inspection.compatible_traits.size(),inspection.blocked_traits.size()])
	else:flash(str(result.reason))

func _material_available(material_id:String)->bool:
	for stack in state.material_stacks:
		if str(stack.get("material_id",""))==material_id and int(stack.get("quantity",0))>0:return true
	return false

func buy_profession_recipe(recipe_id:String,price:int)->void:
	if ProfessionSystem.recipe_is_learned(state,recipe_id):flash("The guild already knows this recipe.");return
	if int(state.gold)<price:flash("Not enough Gold.");return
	state.gold=int(state.gold)-price;ProfessionSystem.discover_recipe(state,recipe_id,true);save_game();show_profession_trainer();flash("Recipe learned guild-wide.")

func buy_rune_pattern(pattern_id:String,price:int)->void:
	if pattern_id in state.discovered_rune_patterns:flash("The guild already knows this Rune pattern.");return
	if int(state.gold)<price:flash("Not enough Gold.");return
	state.gold=int(state.gold)-price;ProfessionSystem.discover_rune_pattern(state,pattern_id);save_game();show_profession_trainer();flash("Rune pattern discovered.")

func workshop_member_ids()->Array:
	var result:Array=[]
	for hero in state.heroes:
		if str(hero.profession_progress.profession_id)!="" and str(hero.profession_progress.profession_id)!="cooking":result.append(str(hero.hero_id))
	return result

func prototype_order_inputs(recipe_id:String)->Dictionary:
	var recipe:=ProfessionData.recipe(recipe_id);var item_ids:Array=[];var preferred_trait:=""
	for item in state.item_instances:
		if item_ids.size()>=int(recipe.get("input_items",0)):break
		ProfessionSystem.migrate_item(item)
		if InventorySystem.storage_location(item)!="depot" or bool(item.favourite) or bool(item.reserved):continue
		if str(recipe.get("compatible_family",""))!="" and str(item.item_family)!=str(recipe.compatible_family):continue
		if str(recipe.get("input_rarity",""))!="" and str(item.rarity)!=str(recipe.input_rarity):continue
		if not item_ids.is_empty():
			var first:Dictionary=ProfessionSystem._item_by_id(state,str(item_ids[0]))
			if str(first.rarity)!=str(item.rarity):continue
		item_ids.append(str(item.instance_id));var preparation:Dictionary=item.get("enchanting_preparation",{});if preferred_trait=="":preferred_trait=str(preparation.get("preferred_trait",""))
	return {"item_instance_ids":item_ids,"preferred_trait":preferred_trait}

func start_workshop_recipe(hero_id:String,recipe_id:String)->void:
	var result:Dictionary=ProfessionSystem.start_profession_order(state,hero_id,recipe_id,prototype_order_inputs(recipe_id))
	if not bool(result.success):flash(str(result.reason));return
	save_game();profession_workshop_tab="Current Orders";show_crafting();flash("Profession order started.")

func workshop_order_action(order_id:String,action:String)->void:
	var result:Dictionary
	if action=="pause":result=ProfessionSystem.pause_profession_order(state,order_id,true)
	elif action=="resume":result=ProfessionSystem.pause_profession_order(state,order_id,false)
	elif action=="cancel":result=ProfessionSystem.cancel_profession_order(state,order_id)
	else:result=ProfessionSystem.complete_profession_order(state,order_id)
	if bool(result.get("success",false)):save_game();show_crafting();flash(str(result.get("reason","Order updated.")))
	else:flash(str(result.get("reason","Order action failed.")))

func set_workshop_tab(tab_name:String)->void:
	profession_workshop_tab=tab_name;show_crafting()

func show_crafting()->void:
	ProfessionSystem.ensure_state(state);screen="crafting"
	var root:=base_screen("Profession Workshop","MEMBER-OWNED PROFESSIONS  •  GUILD VAULT INPUTS")
	var tabs:=HBoxContainer.new();tabs.alignment=BoxContainer.ALIGNMENT_CENTER;tabs.add_theme_constant_override("separation",6);root.add_child(tabs)
	for tab_name in ["Current Orders","Recipes","Techniques","Specializations","Pattern Mastery","Rune Collection"]:
		var tab:=compact_button(tab_name,func(value=tab_name):set_workshop_tab(value),155)
		tab.name="Workshop%sTab"%tab_name.replace(" ","")
		if profession_workshop_tab==tab_name:
			tab.add_theme_color_override("font_color",C_GOLD)
		tabs.add_child(tab)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll)
	var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",9);scroll.add_child(content)
	var member_ids:=workshop_member_ids()
	if member_ids.is_empty():content.add_child(label("No member knows a profession. Visit the Merchant's Profession Trainer.",18,C_MUTED));content.add_child(button("Open Profession Trainer",show_profession_trainer,230));return
	if profession_workshop_tab=="Current Orders":populate_profession_orders(content)
	elif profession_workshop_tab=="Recipes":populate_profession_recipes(content,member_ids)
	elif profession_workshop_tab=="Pattern Mastery":populate_pattern_mastery(content)
	elif profession_workshop_tab=="Rune Collection":populate_rune_collection(content)
	else:populate_profession_techniques(content,member_ids)
	if is_testing_save():populate_profession_debug(content)

func populate_profession_orders(content:VBoxContainer)->void:
	var visible:=false
	for order in state.profession_orders:
		if str(order.status) in ["complete","cancelled"] or str(order.profession)=="cooking":continue
		visible=true;var card:=panel();content.add_child(card);var recipe:=ProfessionData.recipe(str(order.recipe_id));card.add_child(label("%s  •  %s"%[ProfessionSystem.hero_name(state,str(order.assigned_member_id)),str(recipe.get("display_name",order.recipe_id))],19,C_GOLD));card.add_child(label("%s  •  %s  •  %.1f sec remaining"%[str(order.station),str(order.status).capitalize(),float(order.remaining_time)],14,C_MUTED));card.add_child(label("Inputs: %d item(s), %d material group(s)"%[order.input_items.size(),order.input_materials.size()],13,C_TEXT));var actions:=HBoxContainer.new();card.add_child(actions);actions.add_child(compact_button("Resume" if bool(order.paused) else "Pause",func(id=str(order.order_id),paused=bool(order.paused)):workshop_order_action(id,"resume" if paused else "pause"),100));actions.add_child(compact_button("Cancel",func(id=str(order.order_id)):workshop_order_action(id,"cancel"),100));if is_testing_save():actions.add_child(compact_button("DEBUG Complete",func(id=str(order.order_id)):workshop_order_action(id,"complete"),150))
	if not visible:content.add_child(label("No current profession orders.",18,C_MUTED))

func populate_profession_recipes(content:VBoxContainer,member_ids:Array)->void:
	for hero_id in member_ids:
		var hero:Dictionary=state.heroes[ProfessionSystem.hero_index(state,hero_id)];content.add_child(label("%s - %s Rank %d"%[hero.display_name,ProfessionData.profession_name(str(hero.profession_progress.profession_id)),int(hero.profession_progress.profession_rank)],19,C_GOLD))
		for recipe_id in ProfessionData.RECIPES:
			var recipe:Dictionary=ProfessionData.RECIPES[recipe_id]
			if str(recipe.profession)!=str(hero.profession_progress.profession_id):continue
			var check:Dictionary=ProfessionSystem.can_start_order(state,hero_id,recipe_id,prototype_order_inputs(recipe_id));var row:=HBoxContainer.new();content.add_child(row);var title:=label("%s - %.0fs - +%d XP"%[str(recipe.display_name),float(recipe.duration),int(recipe.xp)],15,C_TEXT);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(title);var start:=compact_button("Start" if bool(check.success) else "Locked",func(member=hero_id,id=recipe_id):start_workshop_recipe(member,id),105);start.disabled=not bool(check.success);start.tooltip_text=str(check.reason);row.add_child(start)

func populate_profession_techniques(content:VBoxContainer,member_ids:Array)->void:
	for hero_id in member_ids:
		var current:Dictionary=ProfessionSystem.progress(state,hero_id);content.add_child(label("%s - %s lean"%[ProfessionSystem.hero_name(state,hero_id),ProfessionSystem.specialization_lean(current)],18,C_GOLD));content.add_child(label("Known actions: %s"%(", ".join(current.known_personal_techniques) if not current.known_personal_techniques.is_empty() else "No rank techniques selected yet."),14,C_TEXT))

func populate_pattern_mastery(content:VBoxContainer)->void:
	if state.guild_recipes.is_empty():content.add_child(label("No guild recipes discovered.",18,C_MUTED));return
	for recipe_id in state.guild_recipes:
		var record:Dictionary=state.guild_recipes[recipe_id];var recipe:=ProfessionData.recipe(str(recipe_id));var status:="Automation Eligible" if bool(record.automation_eligible) else str(record.knowledge_state).replace("_"," ").capitalize();content.add_child(label("%s  •  %d / %d successes  •  %s"%[str(recipe.get("display_name",recipe_id)),int(record.success_count),int(recipe.get("mastery_required",3)),status],16,C_GREEN if bool(record.automation_eligible) else C_TEXT))

func populate_rune_collection(content:VBoxContainer)->void:
	content.add_child(label("Patterns: %s"%(", ".join(state.discovered_rune_patterns) if not state.discovered_rune_patterns.is_empty() else "None"),15,C_TEXT))
	for rune_id in state.rune_collection:content.add_child(label("Reusable Rune  •  %s"%str(ProfessionData.RUNES.get(rune_id,{}).get("display_name",rune_id)),17,Color("c692ff")))

func populate_profession_debug(content:VBoxContainer)->void:
	content.add_child(rule());content.add_child(label("PROFESSION DEBUG",13,Color("b381ff")));var row:=HBoxContainer.new();content.add_child(row);row.add_child(compact_button("Add Gold",func():state.gold+=500;save_game();show_crafting(),100));row.add_child(compact_button("Add Materials",debug_add_profession_materials,125));row.add_child(compact_button("Add Parents",debug_add_parent_items,120));row.add_child(compact_button("Learn Content",debug_learn_profession_content,130));row.add_child(compact_button("Advance Timers",func():ProfessionSystem.process_orders(state,120.0);save_game();show_crafting(),135));row.add_child(compact_button("Toggle Echo",func():state.profession_debug.guaranteed_lineage_echo=not bool(state.profession_debug.guaranteed_lineage_echo);save_game();show_crafting(),115));var row_two:=HBoxContainer.new();content.add_child(row_two);row_two.add_child(compact_button("Add Profession XP",debug_add_profession_xp,150));row_two.add_child(compact_button("Increase Prestige",debug_increase_profession_prestige,145));row_two.add_child(compact_button("Master Pattern",debug_master_profession_pattern,135));row_two.add_child(compact_button("Toggle Recipe Drop",func():state.profession_debug.guaranteed_world_recipe_drop=not bool(state.profession_debug.guaranteed_world_recipe_drop);save_game();show_crafting(),155));row_two.add_child(compact_button("Reset Profession Data",debug_reset_profession_data,175))

func debug_add_profession_materials()->void:
	for material_id in ["ore","herbs","dust","arcane_essence","rune_fragment"]:InventorySystem.add_material(state,material_id,20)
	save_game();show_crafting()

func debug_add_parent_items()->void:
	for definition_id in ["pilgrims_vestment","ashwood_bulwark","pilgrims_vestment","ashwood_bulwark"]:InventorySystem.add_equipment(state,ItemData.create_instance(definition_id,InventorySystem.next_item_instance_id(state,"debug_parent")))
	save_game();show_crafting()

func debug_learn_profession_content()->void:
	for recipe_id in ProfessionData.RECIPES:ProfessionSystem.discover_recipe(state,recipe_id,true)
	for pattern_id in ProfessionData.STARTER_MERCHANT_PATTERNS:ProfessionSystem.discover_rune_pattern(state,pattern_id)
	save_game();show_crafting()

func debug_first_profession_hero_id()->String:
	var ids:=workshop_member_ids();return str(ids[0]) if not ids.is_empty() else ""

func debug_add_profession_xp()->void:
	var hero_id:=debug_first_profession_hero_id();if hero_id=="":flash("Train a profession first.");return
	ProfessionSystem.grant_xp(state,hero_id,250);save_game();show_crafting()

func debug_increase_profession_prestige()->void:
	var hero_id:=debug_first_profession_hero_id();var index:=ProfessionSystem.hero_index(state,hero_id);if index<0:flash("Train a profession first.");return
	state.heroes[index].prestige_rank=mini(5,int(state.heroes[index].prestige_rank)+1);ProfessionSystem.update_rank(state,hero_id);save_game();show_crafting()

func debug_master_profession_pattern()->void:
	if state.guild_recipes.is_empty():flash("Learn a recipe first.");return
	var recipe_id:=str(state.guild_recipes.keys()[0]);var required:=int(ProfessionData.recipe(recipe_id).get("mastery_required",3));state.guild_recipes[recipe_id].success_count=required;state.guild_recipes[recipe_id].knowledge_state="pattern_mastered";state.guild_recipes[recipe_id].automation_eligible=true;save_game();show_crafting()

func debug_reset_profession_data()->void:
	state.profession_orders=[];state.guild_recipes={};state.discovered_rune_patterns=[];state.rune_collection={};state.profession_completion_alerts=[]
	for hero in state.heroes:hero.profession_progress=ProfessionSystem.default_progress()
	save_game();show_crafting()
