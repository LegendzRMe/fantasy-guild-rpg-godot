extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const ProfessionData = preload("res://scripts/data/profession_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run(main:Node) -> Array:
	var errors:=[]
	main.show_zone_map(0)
	await main.get_tree().process_frame
	var fresh_map_buttons:Array[Node]=main.ui.find_children("*","Button",true,false)
	TestSupport.check(errors,fresh_map_buttons.any(func(candidate):return candidate.text=="First Ashwood Battle"),"A fresh Ashwood map should display Encounter 1.")
	TestSupport.check(errors,not fresh_map_buttons.any(func(candidate):return "Signal" in candidate.text or "Sealed Gate" in candidate.text),"A fresh Ashwood map should hide unrevealed encounters.")
	main.state.zone0.encounters.raider_cache.unlocked=true
	main.show_zone_map(0)
	await main.get_tree().process_frame
	var optional_hint:Button=main.ui.find_child("OptionalPathHint",true,false)
	TestSupport.check(errors,optional_hint!=null and optional_hint.disabled and "OPTIONAL PATH" in optional_hint.text,"A revealed branch point should show a locked optional-path hint before the secret route is discovered.")
	TestSupport.check(errors,main.ui.find_child("OptionalPathTrail",true,false)!=null,"The undiscovered optional path should have a visible dotted connection to its branch point.")
	main.state.zone0.encounters.raider_cache.unlocked=false
	main.open_ashwood_encounter("first_battle")
	TestSupport.check(errors,main.screen=="combat" and main.current_ashwood_encounter=="first_battle","Selecting Encounter 1 should skip previews and immediately begin combat.")
	TestSupport.check(errors,main.heroes.size()==2 and main.heroes.map(func(hero):return hero["class"])==["Guardian","Cleric"],"Encounter 1 should deploy both founding heroes.")
	TestSupport.check(errors,main.heroes[0].pos==Vector2(210,320) and main.heroes[1].pos==Vector2(145,215) and main.battle_formation_position(2)==Vector2(145,425) and main.battle_formation_position(3)==Vector2(90,320),"Combat should deploy ordered party slots as front, top, bottom, and back points of a diamond.")
	TestSupport.check(errors,main.heroes[0].max_hp==2765.0 and main.heroes[1].max_hp==1500.0,"Level-one heroes should begin at class base health without receiving the level-two health bonus early.")
	TestSupport.check(errors,main.objective_banner_time>0 and main.objective_combat_intro!="","Encounter 1 should briefly combine its story line and objective in the combat banner.")
	main.spawn_enemy(Vector2(1050,250),"Swift")
	main.spawn_enemy(Vector2(1050,420),"Stalker")
	main.heroes[0].target=-1
	main.focused_enemy_index=-1
	main.cycle_selected_enemy()
	TestSupport.check(errors,main.focused_enemy_index==0 and main.heroes[0].target==-1,"Tab cycling should focus an enemy without assigning an auto-attack target.")
	TestSupport.check(errors,main.combat_enemy_target()==0,"The Tab-focused enemy should remain available to targeted abilities.")
	TestSupport.check(errors,main.preferred_enemy_target(main.enemies[0])==1,"A newly arriving Swift should initially pressure the Cleric backline.")
	main.add_enemy_threat(main.enemies[0],0,50.0)
	TestSupport.check(errors,main.preferred_enemy_target(main.enemies[0])==0,"A Swift should switch to Brann after he establishes Tank aggro.")
	main.reduce_hero_threat(0,.25)
	TestSupport.check(errors,is_equal_approx(float(main.enemies[0].threat.get(0,0.0)),37.5),"Vanish's shared threat operation should reduce every stored enemy threat value for its Rogue by twenty-five percent.")
	var concealment_preview:={"class":"Rogue","ability_cds":[0.0,0.0,0.0,0.0,0.0],"selected_talents":{},"pos":Vector2.ZERO,"active_effects":[]};main.RogueSystem.initialize_runtime(concealment_preview,true);main.RogueSystem.activate_vanish(concealment_preview)
	TestSupport.check(errors,main.rogue_concealment_visual_state(concealment_preview)=="vanished","An active Vanish should expose its distinct segmented concealment presentation state.")
	concealment_preview.concealment.invisible=true;TestSupport.check(errors,main.rogue_concealment_visual_state(concealment_preview)=="invisible","Full Invisibility should replace the Vanish presentation with its lighter ghost shimmer state.")
	main.add_enemy_threat(main.enemies[1],0,500.0)
	TestSupport.check(errors,main.preferred_enemy_target(main.enemies[1])==1,"The weak Stalker should retain its backline Fixate even when Tank aggro is assigned.")
	main.enemies.clear();main.focused_enemy_index=-1
	main.update_objective_banner(6.0)
	TestSupport.check(errors,main.objective_banner_time==0,"The combat story and objective banner should automatically expire.")
	main.wave_index=main.total_waves
	main.wave_spawn_remaining=0
	main.objective_complete=true
	main.spawn_enemy(Vector2(900,330),"Raider")
	main.enemies[0].hp=0
	TestSupport.check(errors,main.ashwood_combat_complete(),"Encounter 1 should report completion after its final wave is defeated.")
	main._process(0.016)
	TestSupport.check(errors,main.screen=="combat" and main.victory_sequence and not main.pending_victory.is_empty(),"Encounter 1 completion should begin the staged battlefield Victory sequence.")
	TestSupport.check(errors,main.heroes.size()==2 and not main.ui.visible,"The staged Victory should hide combat UI while both founding heroes remain on the battlefield.")
	var opening_xp_progress:Dictionary=main.pending_victory.rewards.xp_progress[0]
	var xp_animation_start:Dictionary=main.victory_xp_animation_state(opening_xp_progress,int(main.pending_victory.rewards.xp),0.0)
	var xp_animation_end:Dictionary=main.victory_xp_animation_state(opening_xp_progress,int(main.pending_victory.rewards.xp),1.0)
	TestSupport.check(errors,float(xp_animation_end.xp)!=float(xp_animation_start.xp) or int(xp_animation_end.level)>int(xp_animation_start.level),"The battlefield Victory XP bar should animate from its pre-reward state to its awarded state.")
	main.victory_sequence=false
	main.show_ashwood_victory()
	await main.get_tree().process_frame
	var recap:PanelContainer=main.ui.find_child("AshwoodRecap",true,false)
	var recap_buttons:Array[Node]=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.is_visible_in_tree())
	TestSupport.check(errors,main.ashwood_victory_stage=="recap" and recap!=null and recap.size==Vector2(560,430),"The staged rewards should lead to a compact instant recap over the battlefield.")
	TestSupport.check(errors,recap_buttons.size()==1 and recap_buttons[0].text=="CONTINUE","An unresolved first-clear recap should use Continue to enter the required story decision.")
	TestSupport.check(errors,not recap_buttons.any(func(candidate):return candidate.text=="RETURN TO WORLD MAP"),"Return to World Map should remain unavailable until the story decision is made.")
	TestSupport.check(errors,not main.ui.find_children("*","Label",true,false).any(func(candidate):return "reveal rewards faster" in candidate.text.to_lower()),"The instant recap should not repeat the staged-reward speed-up instruction.")
	main.show_ashwood_decision_stage()
	TestSupport.check(errors,main.ashwood_victory_stage=="decision","The required recap action should present the story decisions in the same Victory scene.")
	main.resolve_ashwood_decision("ranger_path")
	TestSupport.check(errors,main.screen=="ashwood_victory" and main.ashwood_victory_stage=="consequence" and main.ashwood_next_encounter=="first_recruit" and main.ashwood_selected_decision_text!="","A selected decision should remain visible with its consequence and prepare the next encounter.")
	await main.get_tree().process_frame
	var consequence_buttons:Array[Node]=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.is_visible_in_tree())
	TestSupport.check(errors,main.ashwood_consequence_lines.size()>=3 and main.ashwood_consequence_phase==1 and consequence_buttons.is_empty(),"The decision result should begin with one revealed sentence and no navigation buttons.")
	while main.ashwood_consequence_phase<=main.ashwood_consequence_lines.size():main.advance_ashwood_consequence()
	await main.get_tree().process_frame
	consequence_buttons=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.is_visible_in_tree())
	TestSupport.check(errors,consequence_buttons.any(func(candidate):return candidate.text=="CONTINUE" and candidate.has_theme_stylebox_override("normal")),"A valid next encounter should provide an emphasized Continue action.")
	TestSupport.check(errors,consequence_buttons.any(func(candidate):return candidate.text=="RETURN TO WORLD MAP"),"Story consequences should retain a Return to World Map option.")
	main.continue_ashwood_adventure()
	TestSupport.check(errors,main.screen=="combat" and main.current_ashwood_encounter=="first_recruit","Continue should flow directly into the newly unlocked combat.")
	main.spawn_enemy(Vector2(1180,330),"Raider")
	var protection_enemy:Dictionary=main.enemies[-1]
	TestSupport.check(errors,main.preferred_enemy_target(protection_enemy)==main.OBJECTIVE_THREAT_TARGET,"Protection enemies should enter the battle targeting the vulnerable signal ally.")
	main.add_damage_threat(protection_enemy,0,10.0)
	TestSupport.check(errors,main.preferred_enemy_target(protection_enemy)==0,"Brann's five-times Tank threat should pull a protection enemy away from the ally.")
	main.add_enemy_threat(protection_enemy,1,80.0)
	protection_enemy.target=0
	TestSupport.check(errors,main.preferred_enemy_target(protection_enemy)==1,"Sufficient non-Tank threat should eventually pull an enemy away from Brann.")
	main.taunt_enemy(protection_enemy,0)
	TestSupport.check(errors,main.preferred_enemy_target(protection_enemy)==0,"Challenge should force the enemy onto Brann for its taunt duration.")
	protection_enemy.taunt_time=0.0
	main.add_enemy_threat(protection_enemy,1,160.0)
	TestSupport.check(errors,main.preferred_enemy_target(protection_enemy)==1,"After Challenge expires, targeting should return to the highest threat holder.")
	var living_threat_enemies:int=main.enemies.filter(func(enemy):return enemy.hp>0 and not bool(enemy.get("ignores_tank_aggro",false))).size()
	var healer_threat_before:=float(protection_enemy.threat.get(1,0.0))
	main.add_healing_threat(1,20.0)
	TestSupport.check(errors,is_equal_approx(float(protection_enemy.threat.get(1,0.0))-healer_threat_before,10.0/maxi(1,living_threat_enemies)),"Effective healing should create 0.5 total threat and distribute it across living enemies.")
	main.enemies.clear()
	main.objective_progress=.999
	main.objective_pressure_spawned=true
	main.update_ashwood_objective(.2)
	TestSupport.check(errors,main.objective_complete and main.heroes.size()==3 and main.heroes[-1]["class"]=="Ranger","Completing the signal should bring the selected rescued fighter onto the battlefield immediately.")
	TestSupport.check(errors,bool(main.heroes[-1].independent) and main.heroes[-1].combat_affiliation=="allied_npc" and main.player_controlled_hero_indices().size()==2,"The rescued fighter should act as an allied third party without becoming a player-controlled combat slot.")
	TestSupport.check(errors,main.battle_hero_indices.size()==3 and main.state.heroes.any(func(hero):return hero.name=="Wren"),"The allied fighter should still use compatible hero data so they can formally join after victory.")
	main.heroes[-1].hp-=25
	main.selected=1
	main.spawn_enemy(main.heroes[-1].pos,"Raider")
	main.dragging_hero=true;main.drag_start=main.heroes[1].pos;main.drag_has_moved=true
	main.update_hero_drag(main.heroes[-1].pos)
	TestSupport.check(errors,main.drag_target_type=="ally" and main.drag_target_index==2,"A Cleric drag should prioritize a living ally when an enemy overlaps the healing target.")
	main.finish_hero_drag()
	TestSupport.check(errors,main.heroes[1].heal_target==2,"Sera should be able to assign the independent allied fighter as a persistent healing target.")
	main.enemies.clear()
	main.spawn_enemy(Vector2(700,330),"Raider")
	main.heroes[-1].target=-1
	main._process(.016)
	TestSupport.check(errors,main.heroes[-1].target>=0 and main.selected==1,"The allied fighter should acquire enemies autonomously without taking player selection.")
	var joined_hero_count:int=main.heroes.size()
	main.add_first_recruit_to_battle()
	TestSupport.check(errors,main.heroes.size()==joined_hero_count,"Signal completion should not add the rescued fighter twice.")
	TestSupport.check(errors,main.objective_notice!="" and main.objective_notice_time>0,"Signal completion should briefly announce that the rescued fighter joined.")
	main.update_objective_notice(4.0)
	TestSupport.check(errors,main.objective_notice=="","The signal-completion notice should disappear automatically.")
	main.pending_victory={"encounter":"first_battle","first_clear":false,"story_pending":false,"rewards":{"xp":8,"gold":5,"drops":[],"level_ups":[]},"story":"","recruit":""}
	main.show_ashwood_victory()
	await main.get_tree().process_frame
	var replay_buttons:Array[Node]=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.is_visible_in_tree())
	TestSupport.check(errors,replay_buttons.any(func(candidate):return candidate.text=="AGAIN") and replay_buttons.any(func(candidate):return candidate.text=="RETURN TO WORLD MAP"),"Grinding recaps should offer Again and Return to World Map without a story decision stage.")
	TestSupport.check(errors,not replay_buttons.any(func(candidate):return candidate.text.to_lower()=="continue"),"Grinding recaps should not display a story Continue action.")
	main.replay_ashwood_encounter()
	TestSupport.check(errors,main.screen=="combat" and main.current_ashwood_encounter=="first_battle","Again should immediately replay the completed encounter.")
	main.start_ashwood_battle("caravan")
	TestSupport.check(errors,str(main.battle_objective.type)=="protect_caravan" and is_equal_approx(main.objective_max_health,650.0),"The caravan encounter should create a substantial health-based protection objective.")
	TestSupport.check(errors,main.objective_health>0 and main.objective_health<main.objective_max_health and is_equal_approx(main.objective_progress,main.objective_health/main.objective_max_health),"The caravan should begin visibly damaged with a matching health ratio.")
	main.battle_objective.objective_aggro_chance=1.0
	main.spawn_enemy(Vector2(1180,330),"Raider")
	var caravan_enemy:Dictionary=main.enemies[-1]
	TestSupport.check(errors,caravan_enemy.target==main.OBJECTIVE_THREAT_TARGET and main.preferred_enemy_target(caravan_enemy)==main.OBJECTIVE_THREAT_TARGET,"A caravan-focused spawn should enter already aggroed on the caravan.")
	var caravan_health_before:float=main.objective_health
	main.damage_battle_objective(17.0,caravan_enemy.pos)
	TestSupport.check(errors,is_equal_approx(main.objective_health,caravan_health_before-17.0),"Enemy attacks should damage the caravan's health rather than a signal timer.")
	main.wave_index=main.total_waves;main.wave_spawn_remaining=0
	for caravan_foe in main.enemies:caravan_foe.hp=0
	TestSupport.check(errors,main.ashwood_combat_complete(),"Defeating every attacker while the caravan survives should complete the encounter.")
	main.state.zone0.second_recruit_choice="mage"
	main.start_ashwood_battle("second_recruit")
	TestSupport.check(errors,main.ashwood_wave_roles(1).size()==4,"The ritual defense should begin with a slightly larger group to hold off.")
	main.enemies.clear();main.spawn_enemy(Vector2(1180,330),"Raider")
	main.enemies[-1].max_hp=100.0;main.enemies[-1].hp=100.0
	var ritual_roster_before:int=main.state.heroes.size()
	main.objective_progress=.999;main.objective_pressure_spawned=true
	main.update_ashwood_objective(.2)
	TestSupport.check(errors,main.objective_complete and is_equal_approx(float(main.enemies[0].hp),12.0),"Completing the ritual should visibly devastate living enemies without silently removing them.")
	TestSupport.check(errors,main.state.heroes.size()==ritual_roster_before+1 and main.heroes[-1]["class"]=="Mage" and bool(main.heroes[-1].independent),"The chosen ritual caster should join mid-fight as an autonomous allied participant.")
	TestSupport.check(errors,main.effects.any(func(effect):return str(effect.text).begins_with("RITUAL")),"Ritual completion should produce visible battlefield damage feedback.")
	main.pending_victory={"encounter":"second_recruit","first_clear":true,"story_pending":true,"rewards":{"xp":75,"gold":40,"drops":[],"level_ups":[]},"story":"","recruit":"Nyx — Mage"}
	main.show_ashwood_decision_stage()
	TestSupport.check(errors,main.ashwood_victory_stage=="consequence" and main.ashwood_consequence_lines.size()>=3,"The ritual aftermath should reveal its special-hero hint one sentence at a time.")
	TestSupport.check(errors,main.ashwood_consequence_lines.any(func(line):return "single-use boon" in line) and main.ashwood_consequence_lines.any(func(line):return "learn to invoke" in line),"The aftermath should explain the borrowed boon and foreshadow relearning the ritual spell.")
	SaveManager.delete_slot(97)
	main.state.zone0.vault_unlocked=true
	main.state.zone0.heroes_unlocked=true
	main.show_hall()
	await main.get_tree().process_frame
	var cache_great_hall:Button=main.ui.find_child("GuildRoom_great_hall",true,false)
	var cache_vault:Button=main.ui.find_child("GuildRoom_guild_storage",true,false)
	var cache_infirmary:Button=main.ui.find_child("GuildRoom_infirmary",true,false)
	TestSupport.check(errors,cache_great_hall!=null and cache_vault!=null and cache_infirmary!=null and cache_great_hall.find_child("LockOverlay",true,false)==null and cache_vault.find_child("LockOverlay",true,false)==null and cache_infirmary.find_child("LockOverlay",true,false)==null,"Core Guild Hall destinations should remain available throughout story progression.")
	main.state.zone0.party_management_unlocked=true
	main.show_hall()
	await main.get_tree().process_frame
	var infirmary_button:Button=main.ui.find_child("GuildRoom_infirmary",true,false)
	TestSupport.check(errors,infirmary_button!=null and infirmary_button.find_child("LockOverlay",true,false)==null and "COUNCIL CHAMBER" in infirmary_button.text,"The former unassigned space should remain save-compatible while becoming the Council Chamber.")
	if infirmary_button!=null:infirmary_button.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,main.screen=="campaign_council","The relocated Council Chamber should open its faction and regional-outcome interface.")
	return errors
