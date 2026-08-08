extends "res://scripts/runtime/ashwood_runtime.gd"

func _campaign_party(limit:int)->Array:
	var party:Array=[]
	if limit<=4:
		party=state.get("active_team",state.get("selected_team",[])).duplicate()
	else:
		for index in mini(limit,state.heroes.size()):party.append(index)
	return party

func _scrimmage_opponent_indices(controlled_party:Array,count:int)->Array:
	var candidates:Array=[]
	for hero_index in state.heroes.size():
		if hero_index not in controlled_party:candidates.append(hero_index)
	for hero_index in controlled_party:
		if hero_index not in candidates:candidates.append(hero_index)
	var opponents:Array=[]
	if candidates.is_empty():return opponents
	for index in count:opponents.append(int(candidates[index%candidates.size()]))
	return opponents

func _spawn_guildmate_scrimmage(controlled_party:Array,count:int)->void:
	var positions:=[Vector2(1010,145),Vector2(1120,205),Vector2(1000,270),Vector2(1120,335),Vector2(1000,400),Vector2(1120,465),Vector2(1000,530),Vector2(1120,590)]
	var opponents:=_scrimmage_opponent_indices(controlled_party,count)
	for index in opponents.size():
		var guildmate:Dictionary=state.heroes[int(opponents[index])]
		var enemy_type:="Controlled %s"%str(guildmate.get("class","Rogue"))
		if not GameData.ENEMIES.has(enemy_type):enemy_type="Controlled Rogue"
		spawn_enemy(positions[index],enemy_type)
		var opponent:Dictionary=enemies[-1]
		apply_testing_enemy_level(opponent,int(guildmate.get("level",1)))
		opponent.erase("testing_endless_enemy");opponent.erase("defeated_clear_time");opponent.rewarded=false
		opponent["display_name"]=str(guildmate.get("display_name",guildmate.get("name","Guildmate")))
		opponent["sparring_guildmate_id"]=str(guildmate.get("hero_id",""))
		opponent["sparring_guildmate_index"]=int(opponents[index])

func start_campaign_encounter(region_id:String,location_id:String,kind:String="campaign",faction_id:String="")->void:
	CampaignSystem.ensure_state(state)
	var is_test:=kind in ["raid_test","scrimmage_test","scrimmage_4_test"]
	var required_heroes:=4 if kind=="scrimmage_4_test" else 8
	if is_test and state.heroes.size()<required_heroes:flash("%d available guild heroes are required for this practice mode."%required_heroes);show_combat_hall();return
	if not is_test:
		if region_id not in CampaignData.REGION_ORDER or not bool(state.campaign.regions[region_id].unlocked):flash("That region is locked.");return
		var loc_state:=CampaignSystem.location_state(state,region_id,location_id)
		if loc_state.is_empty() or str(loc_state.status)=="undiscovered":flash("Discover this location first.");return
	var level:=int(CampaignData.REGION_TARGET_LEVELS.get(region_id,5));var node:=maxi(0,CampaignData.main_locations(region_id).find(location_id));var party_limit:=required_heroes if is_test else 4;var party:=_campaign_party(party_limit)
	if party.is_empty():flash("Choose an active party before starting this encounter.");return
	if is_test and party.size()<required_heroes:flash("Assign %d heroes to the active party for this practice mode."%required_heroes);show_combat_hall();return
	start_battle(maxi(0,level-1),node,party,false,party_limit)
	if screen!="combat":return
	current_campaign_battle={"region_id":region_id,"location_id":location_id,"kind":kind,"faction_id":faction_id,"start_gold":int(state.gold),"start_renown":int(state.guild_renown),"start_items":state.item_instances.duplicate(true),"party":battle_hero_indices.duplicate(),"support_result":{}}
	campaign_test_started_at=Time.get_ticks_msec()/1000.0;campaign_test_defeated=0
	if kind=="campaign" and region_id=="grand_corruption_front" and location_id=="gateway_site":
		current_campaign_battle.support_result=CampaignSystem.resolve_operation(state,region_id);var callback_bonus:=minf(.30,state.campaign.final_modifiers.size()*.05)
		current_campaign_battle["callback_bonus"]=callback_bonus
		for hero in heroes:hero.max_hp*=1.0+callback_bonus;hero.hp=hero.max_hp
	if kind=="raid_test":
		total_waves=4;encounter_id=4;wave_break=.5;testing_zone_active=false;testing_zone_mode="campaign_raid"
	elif kind in ["scrimmage_test","scrimmage_4_test"]:
		total_waves=0;wave_index=0;wave_spawn_remaining=0;wave_break=0;waiting_wave=false;testing_zone_active=false;testing_zone_mode="campaign_scrimmage"
		_spawn_guildmate_scrimmage(battle_hero_indices,4 if kind=="scrimmage_4_test" else 8)
	queue_redraw()

func _grant_campaign_xp(amount:int)->Array:
	var level_ups:Array=[]
	for hero_index in battle_hero_indices:
		var hero:Dictionary=state.heroes[int(hero_index)];var old_level:=int(hero.level);hero.xp=int(hero.get("xp",0))+amount
		while int(hero.level)<CombatSystem.LEVEL_CAP and int(hero.xp)>=int(hero.level)*100:hero.xp=int(hero.xp)-int(hero.level)*100;hero.level=int(hero.level)+1;hero.gear=int(hero.get("gear",10))+1
		if int(hero.level)>=CombatSystem.LEVEL_CAP:hero.xp=mini(int(hero.xp),CombatSystem.LEVEL_CAP*100-1)
		hero.experience=int(hero.xp);state.class_talent_discovery=TalentSystem.record_class_discovery(state.class_talent_discovery,str(hero.class_id),int(hero.level))
		if int(hero.level)>old_level:level_ups.append("%s reached level %d"%[str(hero.display_name),int(hero.level)])
	return level_ups

func finish_campaign_battle(win:bool)->void:
	var battle:Dictionary=current_campaign_battle.duplicate(true);var kind:=str(battle.kind);var is_test:=kind in ["raid_test","scrimmage_test","scrimmage_4_test"]
	if is_test:
		campaign_test_defeated=enemies.filter(func(enemy):return float(enemy.hp)<=0.0).size();state.gold=int(battle.start_gold);state.guild_renown=int(battle.start_renown);state.item_instances=battle.start_items.duplicate(true);ItemData.reconcile_ownership(state);save_game();_show_campaign_test_report(win,battle);return
	var result:Dictionary={"win":win,"kind":kind,"region_id":battle.region_id,"location_id":battle.location_id,"level_ups":[],"rewards":{},"decision_required":false}
	if win:
		result.level_ups=_grant_campaign_xp(45+int(CampaignData.REGION_MIN_LEVELS[str(battle.region_id)])*4)
		if kind=="campaign":
			var progress:=CampaignSystem.complete_campaign_encounter(state,str(battle.region_id),str(battle.location_id));result.rewards=progress;result.decision_required=bool(progress.get("decision_required",false))
		elif kind=="repeatable":result.rewards=CampaignSystem.resolve_repeatable(state,str(battle.region_id),str(battle.location_id))
		elif kind=="guard":result.rewards=CampaignSystem.resolve_guard_victory(state,str(battle.region_id),str(battle.location_id),str(battle.faction_id))
		save_game()
	campaign_last_result=result;_show_campaign_battle_result(result)

func _show_campaign_battle_result(result:Dictionary)->void:
	ui.visible=true;var overlay:=ColorRect.new();overlay.name="CampaignBattleResult";overlay.color=Color(0.03,0.05,0.09,.97);overlay.position=Vector2(255,85);overlay.size=Vector2(770,550);ui.add_child(overlay)
	var box:=VBoxContainer.new();box.position=Vector2(305,125);box.size=Vector2(670,470);box.add_theme_constant_override("separation",12);ui.add_child(box)
	var win:=bool(result.win);box.add_child(label("REGIONAL VICTORY" if win else "EXPEDITION DEFEAT",36,C_GOLD if win else C_RED));box.add_child(label(str(CampaignData.location(str(result.region_id),str(result.location_id)).name),22,C_TEXT))
	if win:
		box.add_child(label("Gold, Guild Renown, XP, reputation, and campaign loot have been applied.",16,C_GREEN))
		for level_up in result.level_ups:box.add_child(label(str(level_up),15,Color("75c8ff")))
	else:box.add_child(label("No one-time progress was consumed. Recover and try again.",16,C_MUTED))
	box.add_spacer(false)
	if win and bool(result.decision_required):box.add_child(button("Make Permanent Decision",func():current_campaign_battle={};show_campaign_decision(str(result.region_id)),300))
	else:box.add_child(button("Return to Location",func():current_campaign_battle={};show_campaign_location(str(result.region_id),str(result.location_id)),260))
	if not win:box.add_child(button("Retry Encounter",func():var retry:=current_campaign_battle.duplicate(true);current_campaign_battle={};start_campaign_encounter(str(retry.region_id),str(retry.location_id),str(retry.kind),str(retry.faction_id)),250))

func _show_campaign_test_report(win:bool,battle:Dictionary)->void:
	ui.visible=true;var duration:=maxf(0.0,Time.get_ticks_msec()/1000.0-campaign_test_started_at);var overlay:=ColorRect.new();overlay.name="CombatHallReport";overlay.color=Color(0.03,0.05,0.09,.97);overlay.position=Vector2(260,100);overlay.size=Vector2(760,520);ui.add_child(overlay)
	var mode_name:="Raid Test" if str(battle.kind)=="raid_test" else "4v4 Guildmate Scrimmage" if str(battle.kind)=="scrimmage_4_test" else "8v8 Guildmate Scrimmage"
	var box:=VBoxContainer.new();box.position=Vector2(315,145);box.size=Vector2(650,420);box.add_theme_constant_override("separation",14);ui.add_child(box);box.add_child(label("COMBAT HALL REPORT",36,C_GOLD));box.add_child(label("%s — %s"%[mode_name,"Victory" if win else "Defeat"],22,C_GREEN if win else C_RED));box.add_child(label("Duration: %.1f seconds\nEnemies defeated: %d\nControlled heroes: %d\nPerformance: %s"%[duration,campaign_test_defeated,battle.party.size(),"Strong" if win and duration<180 else "Adequate" if win else "Needs work"],18,C_TEXT));box.add_child(label("No Gold, Renown, items, campaign progress, or rival standing awarded.",15,C_MUTED));box.add_spacer(false);box.add_child(button("Return to Combat Hall",func():current_campaign_battle={};show_combat_hall(),260))
