extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run(main:Node) -> Array:
	var errors:=[]
	var save_cards:=[]
	for candidate in main.ui.find_children("*","Button",true,false):
		if is_equal_approx(candidate.custom_minimum_size.y,210.0):
			save_cards.append(candidate)
	TestSupport.check(errors,save_cards.size()==4,"The save menu should render three live slots and one testing slot.")
	TestSupport.check(errors,save_cards.any(func(card):return card.text.begins_with("SAVE 1")),"The first live save card should remain available.")
	TestSupport.check(errors,save_cards.any(func(card):return card.text.begins_with("TESTING")),"The testing save card should remain available.")
	TestSupport.check(errors,main.tutorial_movement_target_reached(Vector2.ZERO,Vector2(70,0)),"Tutorial movement should accept a fair overlap around the marker.")
	TestSupport.check(errors,not main.tutorial_movement_target_reached(Vector2.ZERO,Vector2(74,0)),"Tutorial movement should still reject positions outside the forgiving marker area.")
	var four_hero_left:Vector2=main.centered_victory_position(0,4,125.0,445.0)
	var four_hero_right:Vector2=main.centered_victory_position(3,4,125.0,445.0)
	TestSupport.check(errors,is_equal_approx((four_hero_left.x+four_hero_right.x)*.5,main.W*.5),"A four-hero victory lineup should be centered on the screen rather than shifted right.")
	main.heroes=[{"pos":Vector2(417,465)},{"pos":Vector2(522,465)}]
	TestSupport.check(errors,main.victory_progress_center(0).x==417 and main.victory_progress_center(1).x==522 and main.victory_continue_prompt()=="CLICK TO CONTINUE","Victory XP bars should inherit each displayed Hero's exact center and use one uppercase continuation prompt.")
	main.heroes.clear()
	main.state=SaveManager.fresh_state()
	main.state.guild_name="Live Guild"
	main.state.tutorial_complete=true
	main.show_hall()
	await main.get_tree().process_frame
	var live_buttons:={}
	for candidate in main.ui.find_children("*","Button",true,false):
		live_buttons[candidate.text]=candidate
	TestSupport.check(errors,live_buttons.has("BATTLE") and not live_buttons["BATTLE"].disabled,"Battle should be available after the tutorial.")
	TestSupport.check(errors,live_buttons.has("Heroes") and not live_buttons["Heroes"].disabled,"Heroes should be available immediately after the tutorial.")
	for title in ["Command Table","Party","Vault","Tavern","Merchant","Workshop"]:
		var locked_button:Button=live_buttons.get(title)
		TestSupport.check(errors,locked_button!=null and locked_button.disabled,"%s should be locked for a new live guild."%title)
		if locked_button!=null:
			TestSupport.check(errors,locked_button.find_child("LockOverlay",true,false)!=null,"%s should display crossed chains and a centered lock."%title)
	main.current_save_slot=97
	live_buttons["Heroes"].pressed.emit()
	await main.get_tree().process_frame
	var first_page_intro:AcceptDialog=main.ui.find_child("GuildPageIntro",true,false)
	TestSupport.check(errors,main.screen=="roster" and first_page_intro!=null and "complete member directory" in first_page_intro.dialog_text,"The first visit to a newly available Guild Hall page should show its broad purpose over that page.")
	TestSupport.check(errors,bool(main.state.seen_page_intros.get("heroes",false)),"Showing a page introduction should persist its first-visit state in the guild save.")
	if first_page_intro!=null:first_page_intro.hide();first_page_intro.queue_free()
	main.show_hall()
	await main.get_tree().process_frame
	var repeat_heroes_button:Button=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.text=="Heroes")[0]
	repeat_heroes_button.pressed.emit()
	await main.get_tree().process_frame
	TestSupport.check(errors,main.screen=="roster" and main.ui.find_child("GuildPageIntro",true,false)==null,"Later visits should open the Guild Hall page directly without repeating its introduction.")
	main.current_team_slot=-1
	main.show_team()
	await main.get_tree().process_frame
	var team_selector:OptionButton=main.ui.find_child("TeamSelector",true,false)
	TestSupport.check(errors,team_selector!=null and team_selector.item_count==5 and team_selector.get_item_text(0)=="Team 1" and team_selector.get_item_text(4)=="Team 5","Team Builder should expose five plainly named teams without a separate Active Party entry.")
	var brann_team_cards:Array[Node]=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.custom_minimum_size==Vector2(180,100) and "Brann" in candidate.text)
	var reserve_team_card:Button=main.make_team_card(0,"reserve")
	var team_search:LineEdit=main.ui.find_children("*","LineEdit",true,false).filter(func(candidate):return candidate.placeholder_text=="Search" and candidate.custom_minimum_size.x>0)[0]
	var team_reserve_grid:GridContainer=main.ui.find_child("TeamReserveGrid",true,false)
	TestSupport.check(errors,team_search.custom_minimum_size==Vector2(210,32) and brann_team_cards.size()>0 and brann_team_cards[0].text.begins_with("1  FRONT") and reserve_team_card.custom_minimum_size==Vector2(150,74) and team_reserve_grid!=null and team_reserve_grid.columns==5,"Team Builder should show formation slots on large Active Party cards while retaining compact Guild Roster cards and a five-column grid for two rows.")
	reserve_team_card.free()
	var rapid_press:=InputEventMouseButton.new();rapid_press.button_index=MOUSE_BUTTON_LEFT;rapid_press.pressed=true
	brann_team_cards[0].gui_input.emit(rapid_press);brann_team_cards[0].gui_input.emit(rapid_press)
	TestSupport.check(errors,main.screen=="team","Rapid or double clicks on Team Builder cards should remain inside the team-management workflow.")
	main.team_dragging=false;main.team_drag_index=-1
	if main.team_drag_preview!=null:main.team_drag_preview.queue_free();main.team_drag_preview=null
	main.show_team()
	await main.get_tree().process_frame
	var sera_active_card:Button=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.custom_minimum_size==Vector2(180,100) and "Sera" in candidate.text)[0]
	main.start_team_drag(0,"active")
	main.end_team_drag(sera_active_card.global_position+sera_active_card.size*.5)
	TestSupport.check(errors,main.state.selected_team==[1,0] and main.state.active_team==[1,0],"Dragging the first Active Party hero onto the second slot should reorder and persist the party.")
	main.move_to_active_team(0,0)
	TestSupport.check(errors,main.state.selected_team==[0,1] and main.state.active_team==[0,1],"Active Party order should support moving a hero back to the front slot.")
	main.current_team_slot=0;main.state.active_team=[0];main.state.selected_team=[1,0]
	main.show_roster()
	await main.get_tree().process_frame
	var roster_team_selector:OptionButton=main.ui.find_child("RosterTeamSelector",true,false)
	TestSupport.check(errors,roster_team_selector!=null and roster_team_selector.item_count==5 and roster_team_selector.get_item_text(0)=="Team 1" and roster_team_selector.get_item_text(4)=="Team 5","Hero Roster should provide the same five-team selector as Team Builder.")
	TestSupport.check(errors,main.hero_roster_section=="Abilities" and main.ui.find_child("RosterAbilityQ",true,false)!=null,"Hero Roster should open on the cleaner Abilities workspace by default.")
	main.select_roster_section("Details")
	await main.get_tree().process_frame
	var active_stars:Array[Node]=main.ui.find_children("ActiveTeamStar","Button",true,false)
	TestSupport.check(errors,active_stars.size()==main.state.heroes.size() and active_stars.all(func(star):return star.text=="★"),"Hero Roster stars should reflect every member of the party currently selected in Team Builder, not only the default Active Party.")
	var roster_party_summary:Control=main.ui.find_child("RosterPartySummary",true,false);var roster_party_members:Control=main.ui.find_child("RosterPartyMembers",true,false)
	TestSupport.check(errors,roster_party_summary!=null and main.ui.find_children("RosterPartyMember*","Button",true,false).size()==main.state.selected_team.size(),"Hero Roster should keep every selected party member visible in its persistent party strip even when alphabetical paging places them elsewhere.")
	TestSupport.check(errors,roster_party_summary.position.x+roster_party_summary.size.x<=1216.0 and roster_party_members.get_combined_minimum_size().x<=roster_party_summary.size.x,"The Hero Roster team selector and all four party slots should fit inside the top-right safe area.")
	main.begin_roster_party_press(1,"active",Vector2.ZERO)
	main.update_roster_party_press(main.ROSTER_PARTY_HOLD_DURATION+.01)
	TestSupport.check(errors,main.team_dragging and main.team_drag_index==1 and main.team_drag_preview!=null and main.team_drag_preview.size==Vector2(58,48),"Holding a Hero Roster party symbol should begin a compact drag that can reorder or remove that hero.")
	main.roster_party_press_active=false;main.roster_party_press_index=-1;main.roster_party_press_origin="";main.team_dragging=false;main.team_drag_index=-1;main.team_drag_origin=""
	if main.team_drag_preview!=null:main.team_drag_preview.queue_free();main.team_drag_preview=null
	var pinned_cards:Array[Node]=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.custom_minimum_size==Vector2(132,74))
	TestSupport.check(errors,pinned_cards.size()>=2 and "Sera" in pinned_cards[0].text and "Brann" in pinned_cards[1].text,"The selected party should be pinned to the front of the Hero Roster in party order so every active star stays on the first page.")
	main.current_team_slot=-1;main.state.active_team=[0,1];main.state.selected_team=[0,1]
	var compact_roster_cards:Array[Node]=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.custom_minimum_size==Vector2(132,74))
	var compact_search:LineEdit=main.ui.find_children("*","LineEdit",true,false).filter(func(candidate):return candidate.placeholder_text=="Search" and candidate.custom_minimum_size.x>0)[0]
	var roster_gap:Control=main.ui.find_child("RosterDetailGap",true,false)
	TestSupport.check(errors,compact_roster_cards.size()==main.state.heroes.size() and compact_roster_cards.all(func(card):return card.focus_mode==Control.FOCUS_NONE and card.get_theme_stylebox("normal").corner_radius_top_left==4) and compact_search.custom_minimum_size==Vector2(190,32) and roster_gap!=null and roster_gap.custom_minimum_size.y==16,"Hero Roster should use narrower sharp filters and compact cards, avoid focus outlines, and keep a clear details gap.")
	var roster_label_texts:Array=main.ui.find_children("*","Label",true,false).map(func(candidate):return candidate.text)
	TestSupport.check(errors,main.ui.find_child("HeroExperienceBar",true,false)!=null and main.ui.find_child("HeroExperienceText",true,false)!=null,"Hero Roster should show experience as a numbered progress bar.")
	TestSupport.check(errors,["HEALTH","POWER","ARMOR"].all(func(title):return title in roster_label_texts),"Hero Roster should show compact Health, Power, and Armor stat tiles without a redundant Prestige caption.")
	TestSupport.check(errors,not roster_label_texts.any(func(text):return "Member Type" in str(text) or "Hero Legacy" in str(text) or "Gear Score" in str(text) or "SPECIAL HERO" in str(text)),"Retired Hero Roster labels should no longer be displayed.")
	var details_grid:GridContainer=main.ui.find_child("RosterDetailsGrid",true,false)
	TestSupport.check(errors,details_grid!=null and details_grid.columns==2 and details_grid.get_child_count()==4 and ["RosterDetailsAction","RosterDetailsDefense","RosterDetailsCritical","RosterDetailsProficiencies"].all(func(node_name):return main.ui.find_child(node_name,true,false)!=null),"Details should organize its four player-facing categories into a compact two-by-two grid.")
	TestSupport.check(errors,["BASIC ATTACK","DEFENSE & MOVEMENT","CRITICALS","PROFICIENCIES"].all(func(title):return title in roster_label_texts) and not roster_label_texts.any(func(text):return "CURRENT ATTRIBUTES" in str(text) or "EQUIPMENT EFFECTS" in str(text) or "consolidated view" in str(text)),"Details should use clear category headings without the old unstructured attribute list or empty equipment copy.")
	main.selected_roster_index=1;main.show_roster();await main.get_tree().process_frame
	var cleric_action_heading:Label=main.ui.find_child("RosterDetailsActionHeading",true,false)
	TestSupport.check(errors,cleric_action_heading!=null and cleric_action_heading.text=="BASIC HEAL" and main.ui.find_child("RosterDetailRowHealing",true,false)!=null and main.ui.find_child("RosterDetailRowDamageType",true,false)==null,"The organized action category should describe a healer's Basic Heal without irrelevant damage information.")
	main.selected_roster_index=0;main.show_roster();await main.get_tree().process_frame
	var roster_button_texts:Array=main.ui.find_children("*","Button",true,false).map(func(candidate):return candidate.text)
	TestSupport.check(errors,["Details","Talents","Abilities","Professions"].all(func(title):return title in roster_button_texts) and not "History" in roster_button_texts,"Hero Roster workspace should offer Details, Talents, Abilities, and Professions without History.")
	var hero_name_label:Label=main.ui.find_child("HeroName",true,false)
	var hero_prestige_label:Label=main.ui.find_child("HeroPrestige",true,false)
	var hero_level_label:Label=main.ui.find_child("HeroLevelClass",true,false)
	var hero_experience:Control=main.ui.find_child("HeroExperience",true,false)
	TestSupport.check(errors,hero_name_label!=null and hero_prestige_label!=null and hero_level_label!=null and hero_name_label.get_parent()==hero_level_label.get_parent() and hero_name_label.get_parent()==hero_prestige_label.get_parent() and hero_name_label.autowrap_mode==TextServer.AUTOWRAP_OFF and hero_prestige_label.autowrap_mode==TextServer.AUTOWRAP_OFF,"Name, Level and Class, and Prestige should share one stable identity line.")
	var hero_portrait:Control=main.ui.find_child("HeroPortrait",true,false)
	var hero_stats_group:Control=main.ui.find_child("HeroStatsGroup",true,false)
	TestSupport.check(errors,hero_experience!=null and hero_experience.custom_minimum_size==Vector2(330,24) and hero_experience.get_parent().name=="HeroExperienceRow" and hero_experience.get_parent().custom_minimum_size.x==464 and hero_experience.get_parent().alignment==BoxContainer.ALIGNMENT_CENTER,"The restrained experience bar should sit on a portrait-centered compact row immediately beneath hero identity.")
	TestSupport.check(errors,hero_portrait!=null and hero_stats_group!=null and hero_stats_group.custom_minimum_size==Vector2(230,54) and main.ui.find_children("HeroStat*Value","Label",true,false).size()==3,"Health, Power, and Armor should use three compact tiles aligned to the portrait width.")
	TestSupport.check(errors,is_equal_approx(hero_experience.global_position.x+hero_experience.size.x*.5,hero_portrait.global_position.x+hero_portrait.size.x*.5) and is_equal_approx(hero_stats_group.global_position.x+hero_stats_group.size.x*.5,hero_portrait.global_position.x+hero_portrait.size.x*.5),"The experience bar and stat tiles should share the hero portrait's rendered horizontal center.")
	TestSupport.check(errors,main.hero_roster_section=="Details" and main.ui.find_child("RosterWorkspacePanel",true,false)!=null,"Hero Roster should retain an explicitly chosen workspace while changing heroes.")
	main.select_roster_section("Abilities")
	await main.get_tree().process_frame
	var abilities_content:VBoxContainer=main.ui.find_child("RosterSectionContent",true,false)
	TestSupport.check(errors,main.ui.find_child("RosterTrait",true,false)!=null and main.ui.find_children("RosterAbility*","PanelContainer",true,false).size()==4 and main.ui.find_children("AbilityKeyBadge","Control",true,false).size()==5 and abilities_content.get_child_count()==5,"The concise Abilities workspace should show only its visual Q/W/E/R/D rows without repeating the selected tab title.")
	TestSupport.check(errors,abilities_content.get_child(0).name=="RosterAbilityQ" and abilities_content.get_child(1).name=="RosterAbilityW" and abilities_content.get_child(2).name=="RosterAbilityE" and abilities_content.get_child(3).name=="RosterAbilityR" and abilities_content.get_child(4).name=="RosterTrait","Hero Roster abilities should follow the combat action-bar order: Q, W, E, R, then D.")
	var locked_heroic_text:String="\n".join(main.ui.find_child("RosterAbilityR",true,false).find_children("*","Label",true,false).map(func(candidate):return candidate.text))
	TestSupport.check(errors,locked_heroic_text.contains("Choose your Heroic at Level 15") and not locked_heroic_text.contains("Avatar") and not locked_heroic_text.contains("Haymaker"),"A Hero without a selected Heroic should see only a locked R placeholder and its unlock level.")
	main.open_roster_ability_details(main.state.heroes[0],"Q");await main.get_tree().process_frame
	var ability_detail_text:String="\n".join(main.ui.find_child("RosterAbilityDetailsCard",true,false).find_children("*","Label",true,false).map(func(candidate):return candidate.text))
	TestSupport.check(errors,ability_detail_text.contains("Storm Bolt") and ability_detail_text.contains("PER-BATTLE QUEST") and ability_detail_text.contains("45-STACK REWARD") and ability_detail_text.contains("resets when the battle ends"),"Tapping a Guardian ability should open its complete, battle-accurate detail card.")
	main.ui.find_child("RosterAbilityDetailsBackdrop",true,false).emit_signal("pressed");await main.get_tree().process_frame
	main.state.heroes[0].level=15;main.state.heroes[0].selected_heroic_id="guardian_l15_r2";main.state.heroes[0].selected_talents["tier_3"]="guardian_l15_r2";main.select_roster_section("Abilities");await main.get_tree().process_frame
	var heroic_row:PanelContainer=main.ui.find_child("RosterAbilityR",true,false);var heroic_text:String="\n".join(heroic_row.find_children("*","Label",true,false).map(func(candidate):return candidate.text)) if heroic_row!=null else ""
	TestSupport.check(errors,heroic_row!=null and heroic_text.contains("Haymaker") and not heroic_text.contains("Avatar"),"Abilities should show only the Heroic that the Hero has unlocked and selected.")
	main.state.heroes[0].level=1;main.state.heroes[0].selected_heroic_id="";main.state.heroes[0].selected_talents.erase("tier_3")
	main.state.class_talent_discovery["guardian"]=30
	main.select_roster_section("Talents")
	await main.get_tree().process_frame
	var talents_content:VBoxContainer=main.ui.find_child("RosterSectionContent",true,false)
	TestSupport.check(errors,talents_content.get_child_count()==8 and main.ui.find_child("TalentOption_guardian_l15_r1",true,false)!=null and main.ui.find_child("TalentOption_guardian_l15_r2",true,false)!=null,"The visual Talent Tree should retain all eight tiers without repeating the selected tab title.")
	var talent_scroll:ScrollContainer=main.ui.find_child("RosterSectionScroll",true,false);talent_scroll.scroll_vertical=220;await main.get_tree().process_frame
	var planned_holder:Control=main.ui.find_child("TalentOption_guardian_l9_2",true,false);var planned_heart:Button=planned_holder.find_child("TalentPlanHeart",true,false);planned_heart.pressed.emit();await main.get_tree().process_frame;await main.get_tree().process_frame
	planned_holder=main.ui.find_child("TalentOption_guardian_l9_2",true,false);planned_heart=planned_holder.find_child("TalentPlanHeart",true,false)
	TestSupport.check(errors,main.state.heroes[0].planned_talents.get("tier_1","")=="guardian_l9_2" and planned_heart.text=="♥" and main.ui.find_child("RosterSectionScroll",true,false).scroll_vertical>=180,"Planning a future talent should update its top-right heart without resetting the Talent Tree to the top.")
	main.state.heroes[0].level=30;main.select_roster_section("Talents");await main.get_tree().process_frame
	var tier_one_card:Button=main.ui.find_child("TalentOption_guardian_l9_1",true,false).find_child("TalentOptionCard",true,false);tier_one_card.button_down.emit();await main.get_tree().create_timer(.9).timeout;await main.get_tree().process_frame
	var selected_badge:Label=main.ui.find_child("TalentOption_guardian_l9_1",true,false).find_child("TalentStateBadge",true,false)
	TestSupport.check(errors,main.state.heroes[0].selected_talents.get("tier_1","")=="guardian_l9_1" and selected_badge.text=="SELECTED","An unlocked talent should require the explicit confirmation signal and immediately show its selected state.")
	var heroic_view:Control=main.ui.find_child("TalentTier3",true,false);heroic_view.emit_signal("selection_confirmed","tier_3","guardian_l15_r2");await main.get_tree().process_frame
	var avatar_upgrade:Control=main.ui.find_child("TalentOption_guardian_l27_r1",true,false);var haymaker_upgrade:Control=main.ui.find_child("TalentOption_guardian_l27_r2",true,false)
	var avatar_card:Button=avatar_upgrade.find_child("TalentOptionCard",true,false);var haymaker_card:Button=haymaker_upgrade.find_child("TalentOptionCard",true,false)
	TestSupport.check(errors,main.state.heroes[0].selected_heroic_id=="guardian_l15_r2" and not avatar_card.tooltip_text.begins_with("Hold") and haymaker_card.tooltip_text.begins_with("Hold") and avatar_upgrade.find_child("TalentStateBadge",true,false)==null and haymaker_upgrade.find_child("TalentStateBadge",true,false)==null,"Choosing a Heroic should enable only its matching Level 27 upgrade without adding per-card instruction labels.")
	main.state.heroes[0]=TalentSystem.clear_all(main.state.heroes[0]);main.state.heroes[0].level=9;main.battle_hero_indices=[0];main.victory_level_ups=[{"slot":0,"level":9,"talent_tiers":["tier_1"]}];main.current_ashwood_encounter="";main.victory_talent_prompt_handled=false
	TestSupport.check(errors,main.open_victory_talent_choices() and main.ui.find_child("VictoryTalentChoiceOverlay",true,false)!=null and main.ui.find_child("VictoryTalentDecideLater",true,false)!=null,"A newly unlocked tier should offer its talent choices on the Victory screen with an explicit Decide Later option.")
	main.close_victory_talent_overlay();main.victory_talent_queue.clear();main.victory_talent_prompt_handled=false
	main.state.heroes[0]=TalentSystem.clear_all(main.state.heroes[0]);main.state.heroes[0].level=1
	main.select_roster_section("Professions")
	await main.get_tree().process_frame
	var professions_content:VBoxContainer=main.ui.find_child("RosterSectionContent",true,false)
	TestSupport.check(errors,professions_content.get_child_count()==0,"The empty Professions workspace should not repeat the selected tab title or add placeholder copy.")
	main.select_roster_section("Details")
	await main.get_tree().process_frame
	main.state.heroes[0].is_special_hero=true
	main.show_roster()
	await main.get_tree().process_frame
	var prestige_portrait:Button=main.ui.find_child("HeroPortrait",true,false)
	var prestige_ring:StyleBoxFlat=prestige_portrait.get_theme_stylebox("disabled") if prestige_portrait!=null else null
	TestSupport.check(errors,main.ui.find_child("SpecialHeroIndicator",true,false)==null and prestige_ring!=null and prestige_ring.border_width_left==6 and prestige_ring.border_color==main.C_GOLD,"Special heroes should use only the thick gold portrait ring, without a competing carousel star.")
	main.selected_roster_index=1
	main.show_roster()
	await main.get_tree().process_frame
	var unselected_special_card:Button=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.custom_minimum_size==Vector2(132,74) and "Brann" in candidate.text)[0]
	var unselected_special_style:StyleBoxFlat=unselected_special_card.get_theme_stylebox("normal")
	TestSupport.check(errors,unselected_special_style.border_color!=main.C_GOLD,"An unselected special hero card should not retain the selected hero's gold outline.")
	main.state.heroes[0].is_special_hero=false
	main.selected_roster_index=0
	main.toggle_active_team_from_roster(1)
	TestSupport.check(errors,main.state.active_team==[0] and main.state.selected_team==[0] and main.screen=="roster","Toggling a roster star off should immediately update the saved and currently edited Active Party.")
	main.toggle_active_team_from_roster(1)
	TestSupport.check(errors,main.state.active_team==[0,1] and main.state.selected_team==[0,1],"Toggling the roster star on should restore the hero without leaving Hero Roster.")
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
	var cache_clear_buttons:={}
	for candidate in main.ui.find_children("*","Button",true,false):cache_clear_buttons[candidate.text]=candidate
	TestSupport.check(errors,not cache_clear_buttons["Heroes"].disabled and not cache_clear_buttons["Vault"].disabled,"Heroes should remain available when the Raider Cache unlocks the Vault.")
	TestSupport.check(errors,cache_clear_buttons["Party"].disabled,"Party should remain locked before the permanent Special Hero choice.")
	main.state.zone0.party_management_unlocked=true
	main.show_hall()
	await main.get_tree().process_frame
	var party_button:Button=main.ui.find_children("*","Button",true,false).filter(func(candidate):return candidate.text=="Party")[0]
	TestSupport.check(errors,not party_button.disabled,"The Special Hero milestone should unlock Party Management.")
	var normal_vault_state:=SaveManager.fresh_state()
	normal_vault_state.guild_name="Normal Vault Test"
	normal_vault_state.heroes.append({"name":"Wren","class":"Ranger","level":3,"xp":0,"gear":12,"equipment":[],"equipment_slots":ItemData.empty_equipment_slots()})
	normal_vault_state.zone0.inventory=[
		{"id":"normal_bow","name":"Pinewatch Bow","class":"Ranger","slot":"Weapon","rarity":"Common","power":1,"equipped_by":2},
		{"id":"normal_vestment","name":"Pilgrim's Vestment","class":"Cleric","slot":"Armor","rarity":"Common","power":1,"equipped_by":1},
		{"id":"normal_plate","name":"Marchwarden Plate","class":"Guardian","slot":"Weapon","rarity":"Rare","power":3,"equipped_by":0}
	]
	main.state=SaveManager.migrate_state(normal_vault_state,true,false)
	main.show_vault()
	await main.get_tree().process_frame
	var normal_vault_slots:Array[Node]=main.ui.find_children("VaultSlot*","Button",true,false)
	var normal_vault_labels:Array=main.ui.find_children("*","Label",true,false).map(func(node):return str(node.text))
	TestSupport.check(errors,normal_vault_slots.size()==30 and normal_vault_slots.all(func(slot):return slot.global_position.y+slot.size.y<=main.H),"A normal save should render all thirty physical Item Storage slots inside the 720p screen.")
	TestSupport.check(errors,"ASHWOOD EQUIPMENT" not in normal_vault_labels and "EQUIPMENT VAULT" not in normal_vault_labels,"A normal save must not recreate either retired equipment list outside the physical storage grid.")
	for expected_item_id in ["normal_bow","normal_vestment","normal_plate"]:
		var stored_entry:Dictionary=InventorySystem.entry_by_id(main.state,str(expected_item_id))
		var stored_slot:Button=main.ui.find_child("VaultSlot%d"%InventorySystem.flat_position(stored_entry),true,false)
		var stored_frame:StyleBoxFlat=stored_slot.get_theme_stylebox("normal") if stored_slot!=null else null
		var expected_frame:=Color(ItemData.RARITY_COLORS.get(str(stored_entry.get("rarity","Common")),"e9f1ff"))
		TestSupport.check(errors,stored_slot!=null and stored_slot.tooltip_text=="" and stored_slot.find_child("VaultSlotIcon",true,false)!=null and stored_slot.find_child("VaultSlotName",true,false)==null and stored_slot.find_child("VaultSlotFooter",true,false)==null and stored_frame!=null and stored_frame.border_color.is_equal_approx(expected_frame),"%s should be represented only by its icon and rarity border, without hover details, inside Item Storage."%str(stored_entry.get("display_name","Item")))
	var normal_bow_entry:Dictionary=InventorySystem.entry_by_id(main.state,"normal_bow")
	var normal_bow_slot:Button=main.ui.find_child("VaultSlot%d"%InventorySystem.flat_position(normal_bow_entry),true,false)
	var normal_click:=InputEventMouseButton.new();normal_click.button_index=MOUSE_BUTTON_LEFT;normal_click.pressed=true;normal_click.position=normal_bow_slot.global_position+normal_bow_slot.size*.5
	normal_bow_slot.gui_input.emit(normal_click);main.vault_press_time=.1;main.finish_vault_pointer(normal_click.position)
	await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("SharedItemCard",true,false)!=null,"Tapping a normal-save equipment square should open the shared Item Card.")
	main.close_item_overlay()
	main.open_save_slot(0)
	TestSupport.check(errors,main.screen=="creation" and main.state.guild_name=="","An empty live slot should continue to guild creation.")
	main.open_save_slot(3)
	TestSupport.check(errors,main.screen=="hall" and main.state.guild_name=="Testing Guild","An empty testing slot should open its unlocked guild directly.")
	TestSupport.check(errors,main.state.tutorial_complete==true and main.state.heroes.size()==9,"The testing slot should bypass the tutorial with its complete roster.")
	await main.get_tree().process_frame
	var testing_buttons:={}
	for candidate in main.ui.find_children("*","Button",true,false):
		testing_buttons[candidate.text]=candidate
	for title in ["Command Table","Heroes","Party","Vault","Tavern","Merchant","Workshop"]:
		TestSupport.check(errors,testing_buttons.has(title) and not testing_buttons[title].disabled,"%s should remain available in the testing guild."%title)
	main.show_vault();await main.get_tree().process_frame
	var vault_texts:Array=main.ui.find_children("*","Label",true,false).map(func(node):return str(node.text))
	TestSupport.check(errors,"ASHWOOD EQUIPMENT" not in vault_texts and "EQUIPMENT VAULT" not in vault_texts,"Item Storage should no longer generate separate equipment-summary headings.")
	var physical_slots:Array[Node]=main.ui.find_children("VaultSlot*","Button",true,false)
	TestSupport.check(errors,physical_slots.size()==30 and physical_slots.all(func(slot):return slot.custom_minimum_size.x>=86 and slot.custom_minimum_size.y>=64),"The current storage page should use thirty large touch-friendly physical slots.")
	var visible_testing_items:=0
	for testing_item in main.state.item_instances:
		var testing_slot:Button=main.ui.find_child("VaultSlot%d"%InventorySystem.flat_position(testing_item),true,false)
		if testing_slot!=null and testing_slot.find_child("VaultSlotIcon",true,false)!=null and testing_slot.find_child("VaultSlotName",true,false)==null and testing_slot.find_child("VaultSlotFooter",true,false)==null:visible_testing_items+=1
	TestSupport.check(errors,visible_testing_items==10,"Item Storage should visibly contain all ten testing-save Legendary items as icon-only physical slots.")
	var stack_badges:Array[Node]=main.ui.find_children("VaultSlotStackCount","Label",true,false)
	TestSupport.check(errors,not stack_badges.is_empty() and stack_badges.all(func(badge):return badge.autowrap_mode==TextServer.AUTOWRAP_OFF and badge.size.x>=40 and "\n" not in badge.text),"Material quantities should remain on one centered line in the lower-right stack badge.")
	var page_bags:Array[Node]=main.ui.find_children("VaultPageBag*","Button",true,false)
	TestSupport.check(errors,page_bags.size()==GameData.STORAGE_BAG_SLOTS and main.ui.find_child("VaultPageBags",true,false)!=null and page_bags.all(func(page):return page.text in ["▣","▧"]),"The bag-shaped storage controls should be the only page selectors, without a duplicate numbered row.")
	var inspected_id:=str(main.state.item_instances[0].instance_id);main.begin_vault_press(inspected_id,Vector2(10,10));main.vault_press_time=.1;main.finish_vault_pointer(Vector2(10,10));await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("SharedItemCard",true,false)!=null,"A quick Vault click should open the shared Item Card without moving the item.")
	var shared_item_card:Control=main.ui.find_child("SharedItemCard",true,false)
	var card_rarity:Label=main.ui.find_child("ItemCardRarity",true,false);var card_tier:Label=main.ui.find_child("ItemCardTier",true,false);var card_name:Label=main.ui.find_child("ItemCardName",true,false);var card_type:Label=main.ui.find_child("ItemCardType",true,false)
	TestSupport.check(errors,card_rarity!=null and card_rarity.text=="★ LEGENDARY" and card_tier!=null and card_tier.text=="TIER IX","The Item Card should lead with Legendary rarity and Tier IX on one clear top line.")
	var item_card_icon:Control=main.ui.find_child("ItemCardIcon",true,false)
	TestSupport.check(errors,card_name!=null and card_name.text=="ASHFANG KNIVES" and card_type!=null and card_type.text=="Dual Wield Weapon" and item_card_icon!=null and item_card_icon.find_children("*","TextureRect",true,false).size()==1,"The Item Card should center its generated temporary icon, item name, and readable equipment type.")
	TestSupport.check(errors,main.ui.find_children("ItemCardStat*","Label",true,false).size()==2 and main.ui.find_child("ItemCardPassiveTitle0",true,false).text=="BLOODLETTING" and main.ui.find_child("ItemCardPassiveDescription0",true,false)!=null,"The Item Card should present concise stat rows followed by its named passive and description.")
	TestSupport.check(errors,main.ui.find_child("ItemCardStorageStatus",true,false)!=null,"An unequipped card should show that the item is stored in the Guild Vault.")
	TestSupport.check(errors,main.ui.find_child("ItemCardActionChooseHero",true,false)!=null,"An unequipped card should keep its Choose Hero action visible.")
	TestSupport.check(errors,shared_item_card.global_position.y+shared_item_card.size.y<=main.H,"The complete Item Card should remain inside the 720p screen (bottom %.1f, viewport %.1f)."%[shared_item_card.global_position.y+shared_item_card.size.y,main.H])
	var card_backdrop:Button=main.ui.find_child("ItemCardBackdrop",true,false);card_backdrop.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,main.item_card_overlay==null,"Clicking outside the shared Item Card should close it.")
	main.show_vault();await main.get_tree().process_frame;main.begin_vault_press(inspected_id,Vector2(10,10));main._process(.36)
	TestSupport.check(errors,main.vault_dragging,"A 350 millisecond press should begin touch-friendly item movement instead of opening the Item Card.")
	main.finish_vault_pointer(Vector2(-20,-20));await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("SharedItemCard",true,false)==null,"Releasing after a drag should never open the Item Card.")
	var merchant_item_count:int=main.state.item_instances.size();var merchant_gold_before:=int(main.state.gold);var purchase_result:Dictionary=main.purchase_merchant_item("pinewatch_bow",90,"Borin Ironhand")
	TestSupport.check(errors,purchase_result.success and main.state.item_instances.size()==merchant_item_count+1 and main.state.gold==merchant_gold_before-90 and main.state.item_instances[-1].owner_state=="vault","Merchant equipment purchases should enter Item Storage without auto-equipping.")
	main.state.vault_limit=InventorySystem.occupied_count(main.state);var stack_gold_before:=int(main.state.gold);var stack_purchase:Dictionary=main.purchase_merchant_material("dust",1,5);var blocked_gold_before:=int(main.state.gold);var blocked_purchase:Dictionary=main.purchase_merchant_material("dust",1,5)
	TestSupport.check(errors,stack_purchase.success and main.state.gold==stack_gold_before-5,"A merchant purchase should fill an existing material stack even with no empty slots.")
	TestSupport.check(errors,not blocked_purchase.success and main.state.gold==blocked_gold_before,"A merchant purchase that cannot fit should be blocked without deducting currency.")
	main.state.vault_limit=180;main.save_game()
	main.show_dungeons()
	await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("TestingResetStoryButton",true,false)!=null,"The testing World Map should expose the Ashwood story reset tool.")
	TestSupport.check(errors,main.ui.find_child("TestingWorldRegion",true,false)!=null,"The testing World Map should expose its training range.")
	main.show_roster();await main.get_tree().process_frame
	var empty_head_slot:Button=main.ui.find_child("HeroEquipmentSlotHead",true,false);var empty_head_icon:Control=empty_head_slot.find_child("HeroEquipmentIcon",true,false) if empty_head_slot!=null else null;TestSupport.check(errors,empty_head_slot!=null and empty_head_slot.text=="" and empty_head_slot.tooltip_text=="" and empty_head_icon!=null and empty_head_icon.get_script()==main.EquipmentSlotSilhouette and empty_head_slot.custom_minimum_size==Vector2(105,70),"Empty Hero equipment slots should use centered visual silhouettes without text labels.")
	main.select_equipment_slot("weapon");await main.get_tree().process_frame
	var carousel_card:Control=main.ui.find_child("EquipmentCarouselCard",true,false);var carousel_name:Label=main.ui.find_child("ItemCardName",true,false)
	TestSupport.check(errors,main.ui.find_child("HeroEquipmentBrowser",true,false)==null and main.ui.find_child("ItemCardBackdrop",true,false)!=null and carousel_card!=null and main.ui.find_child("EquipmentCarouselTapTarget",true,false)!=null and carousel_name!=null and carousel_name.text=="STORMBREAKER" and main.item_carousel_items.all(func(item):return ItemData.compatibility_reason(item,GameData.CLASSES.Guardian,"Guardian")==""),"The Hero Roster slot should open a darkened, directly tappable compatible-item card carousel without replacing Details.")
	main.equip_item_carousel_candidate();await main.get_tree().process_frame
	TestSupport.check(errors,main.state.heroes[0].equipment_slots.weapon=="testing_test_stormbreaker","Tapping the centered compatible card should equip and save the item.")
	var equipped_weapon_slot:Button=main.ui.find_child("HeroEquipmentSlotWeapon",true,false);TestSupport.check(errors,equipped_weapon_slot!=null and equipped_weapon_slot.text=="" and equipped_weapon_slot.tooltip_text=="" and equipped_weapon_slot.find_child("HeroEquipmentIcon",true,false)!=null and equipped_weapon_slot.custom_minimum_size==Vector2(105,70),"Equipped Hero slots should show only the item icon and rarity frame, with details available by clicking.")
	main.select_equipment_slot("weapon");await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("SharedItemCard",true,false)!=null and main.ui.find_child("ItemCardActionUnequipItem",true,false)!=null and main.ui.find_child("ItemCardActionChangeEquipment",true,false)!=null,"An occupied Hero slot should first open its current Item Card with Unequip and Change Equipment.")
	main.handle_item_card_action("change_equipment","testing_test_stormbreaker");await main.get_tree().process_frame
	TestSupport.check(errors,main.item_overlay_mode=="equipment_carousel" and main.ui.find_child("ItemOverlayBack",true,false)!=null,"Change Equipment should enter the compatible-card carousel with an explicit Back action.")
	main.navigate_item_overlay_back();await main.get_tree().process_frame
	TestSupport.check(errors,main.item_overlay_mode=="item_card" and main.ui.find_child("ItemCardName",true,false).text=="STORMBREAKER","Back from the equipment carousel should return to the originally equipped Item Card.")
	main.close_item_overlay()
	for equip_spec in [[0,"testing_test_aegis_last_dawn"],[0,"testing_test_gauntlets_retribution"],[0,"testing_test_pendant_endless_momentum"],[0,"testing_test_soul_furnace"],[1,"testing_test_crown_twin_incantations"],[1,"testing_test_mantle_overflowing_grace"],[1,"testing_test_mirror_borrowed_time"],[4,"testing_test_ashfang_knives"],[4,"testing_test_gloves_thousand_cuts"]]:
		TestSupport.check(errors,bool(ItemData.equip_in_state(main.state,int(equip_spec[0]),str(equip_spec[1]),GameData.CLASSES).success),"The testing setup should equip %s on a compatible hero."%equip_spec[1])
	main.show_vault();await main.get_tree().process_frame;main.open_item_card("testing_test_ashfang_knives","vault");await main.get_tree().process_frame
	var equipped_owner:Label=main.ui.find_child("ItemCardOwnerName",true,false)
	TestSupport.check(errors,equipped_owner!=null and equipped_owner.text=="Kestrel" and main.ui.find_child("ItemCardOwnerPortrait",true,false)!=null,"An equipped Item Card should show the owning hero beside a portrait placeholder.")
	TestSupport.check(errors,main.ui.find_child("ItemCardActionUnequipItem",true,false)!=null,"An equipped Vault card should expose Unequip as its first action.")
	TestSupport.check(errors,main.ui.find_child("ItemCardActionChangeHero",true,false)!=null,"An equipped Vault card should expose Change Hero as its second action.")
	TestSupport.check(errors,main.ui.find_child("ItemCardActionViewHero",true,false)==null,"The focused Vault card should not add an unrelated View Hero action.")
	main.close_item_overlay()
	main.open_item_card("testing_test_pendant_endless_momentum","vault");main.handle_item_card_action("change_hero","testing_test_pendant_endless_momentum");await main.get_tree().process_frame
	var first_hero_carousel_index:int=main.hero_carousel_index
	var hero_track:Control=main.ui.find_child("ItemCarouselTrack",true,false);var hero_left:Control=main.ui.find_child("HeroCarouselPeekLeft",true,false);var hero_right:Control=main.ui.find_child("HeroCarouselPeekRight",true,false);var hero_previous:Control=main.ui.find_child("HeroCarouselPrevious",true,false);var hero_next:Control=main.ui.find_child("HeroCarouselNext",true,false)
	TestSupport.check(errors,main.item_overlay_mode=="hero_carousel" and main.ui.find_child("HeroCarouselCard",true,false)!=null and main.ui.find_child("ItemOverlayBack",true,false)==null and main.hero_carousel_indices.size()>1,"Choosing an owner should use the centered Hero carousel without a redundant Back button.")
	TestSupport.check(errors,hero_track!=null and hero_right!=null and hero_next!=null and hero_next.position.x>hero_right.position.x+hero_right.size.x and (hero_left==null or hero_previous.position.x<hero_left.position.x),"Neighboring Hero cards should peek beside the focused card, with arrows immediately outside those previews.")
	main.update_item_carousel_drag(-80.0);TestSupport.check(errors,is_equal_approx(hero_track.position.x,-80.0),"Dragging the Hero carousel should move the visible cards continuously with the pointer.")
	main.finish_item_carousel_drag(-80.0);await main.get_tree().create_timer(.22).timeout
	TestSupport.check(errors,main.hero_carousel_index==first_hero_carousel_index+1,"Releasing a sufficient carousel drag should settle on the next hero without changing ownership.")
	var hero_backdrop:Button=main.ui.find_child("ItemCardBackdrop",true,false);hero_backdrop.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,main.item_card_overlay==null,"Tapping outside the Hero chooser should dismiss it directly.")
	main.state.selected_team=[0,1,4,2];main.state.active_team=[0,1,4,2]
	main.state.heroes[1].level=6
	main.show_testing_zone_menu();await main.get_tree().process_frame
	TestSupport.check(errors,main.screen=="testing_zone_menu" and main.ui.find_child("TestingEndlessLevel",true,false)!=null and main.ui.find_child("TestingEndlessStart",true,false)!=null,"The testing region should offer separate Dummy Range and fixed-level Endless Arena launch controls.")
	main.start_testing_zone()
	TestSupport.check(errors,main.testing_zone_active and main.enemies.size()==7 and main.enemies.filter(func(enemy):return bool(enemy.get("boss",false))).size()==2 and main.enemies.any(func(enemy):return float(enemy.get("control_profile",{}).get("blind_duration_multiplier",0.0))==0.5),"The testing range should retain its dummy layout and include default-immune and partially Blind-vulnerable Boss targets without waves.")
	var ranger_battle_index:int=main.heroes.find_custom(func(hero):return str(hero.get("class",""))=="Ranger")
	if ranger_battle_index>=0:
		var visual_ranger:Dictionary=main.heroes[ranger_battle_index];main.selected=ranger_battle_index
		var visual_enemy_states:Array=main.enemies.map(func(enemy):return {"pos":enemy.pos,"hp":enemy.hp});for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=Vector2(1100,100+enemy_index*70)
		var travel_dummy:Dictionary=main.enemies[0];travel_dummy.pos=visual_ranger.pos+Vector2.RIGHT*150.0;travel_dummy.hp=travel_dummy.max_hp;var q_health_before:float=travel_dummy.hp
		main.cast_ranger_q(visual_ranger,visual_ranger.pos+Vector2.RIGHT*400.0);main.update_ranger_runtime(.05)
		TestSupport.check(errors,is_equal_approx(travel_dummy.hp,q_health_before),"Hungering Arrow should not deal damage before its researched initial projectile travel time elapses.")
		main.update_ranger_runtime(.30);TestSupport.check(errors,travel_dummy.hp<q_health_before,"Hungering Arrow should resolve damage when its traveling projectile reaches the target.")
		visual_ranger.ranger_runtime.delayed_effects.clear();travel_dummy.hp=travel_dummy.max_hp;travel_dummy.pos=visual_ranger.pos+Vector2.RIGHT*100.0;var w_health_before:float=travel_dummy.hp
		main.cast_ranger_w(visual_ranger,visual_ranger.pos+Vector2.RIGHT*280.0);main.update_ranger_runtime(.05)
		TestSupport.check(errors,is_equal_approx(travel_dummy.hp,w_health_before),"Multishot should not deal damage before its expanding cone reaches the target.")
		main.update_ranger_runtime(.20);TestSupport.check(errors,travel_dummy.hp<w_health_before and main.effects.any(func(effect):return effect.kind=="ranger_arrow") and main.effects.any(func(effect):return effect.kind=="multishot"),"Ranger projectiles should synchronize readable battlefield effects with delayed impact damage.")
		main.effects.clear();visual_ranger.ranger_runtime.delayed_effects.clear();for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=visual_enemy_states[enemy_index].pos;main.enemies[enemy_index].hp=visual_enemy_states[enemy_index].hp
	else:TestSupport.check(errors,false,"The testing party should include a Ranger for combat-presentation coverage.")
	var mage_battle_index:int=main.heroes.find_custom(func(hero):return str(hero.get("class",""))=="Mage")
	if mage_battle_index>=0:
		var visual_mage:Dictionary=main.heroes[mage_battle_index];main.selected=mage_battle_index
		visual_mage.selected_talents={"tier_1":"mage_l9_1","tier_2":"mage_l12_2","tier_3":"mage_l15_r1","tier_4":"mage_l18_1","tier_5":"mage_l21_1","tier_6":"mage_l24_3","tier_7":"mage_l27_r1","tier_8":"mage_l30_3"};visual_mage.selected_heroic_id="mage_l15_r1";main.MageSystem.initialize_runtime(visual_mage,true)
		var mage_enemy_states:Array=main.enemies.map(func(enemy):return {"pos":enemy.pos,"hp":enemy.hp,"active_effects":enemy.active_effects.duplicate(true)})
		for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=Vector2(1100,80+enemy_index*75);main.enemies[enemy_index].hp=main.enemies[enemy_index].max_hp
		var flame_target:Dictionary=main.enemies[0];flame_target.pos=visual_mage.pos+Vector2.RIGHT*150.0;var flame_health_before:float=flame_target.hp
		main.cast_mage_q(visual_mage,flame_target.pos);main.update_mage_runtime(.9);TestSupport.check(errors,is_equal_approx(flame_target.hp,flame_health_before) and main.effects.any(func(effect):return effect.kind=="mage_flamestrike_warning" and float(effect.get("radius",0.0))>0.0),"Flamestrike should preserve and visibly represent its full one-second ground warning before damage.")
		main.update_mage_runtime(.2);TestSupport.check(errors,flame_target.hp<flame_health_before and main.effects.any(func(effect):return effect.kind=="mage_flamestrike_impact"),"Flamestrike should resolve with a visible impact at the chosen ground point.")
		main.focused_enemy_index=0;visual_mage.ability_cds[1]=0.0;var bomb_health_before:float=flame_target.hp;main.cast_mage_w(visual_mage);main.update_mage_runtime(3.1)
		TestSupport.check(errors,flame_target.hp<bomb_health_before and visual_mage.mage_runtime.telemetry.w_ticks==3 and visual_mage.mage_runtime.telemetry.w_explosions==1,"Living Bomb should deliver three periodic ticks and its host-centered explosion even across one large deterministic update.")
		var trait_charges_before:int=visual_mage.mage_runtime.trait.current_charges;main.begin_trait();TestSupport.check(errors,main.MageSystem.trait_is_armed(visual_mage) and visual_mage.mage_runtime.trait.current_charges==trait_charges_before-1,"Mage D input should arm Verdant Spheres and spend one stored charge.")
		visual_mage.ability_cds[1]=8.0;main.focused_enemy_index=0;main.use_ability(1);TestSupport.check(errors,visual_mage.ability_cds[1]==0.0 and visual_mage.mage_runtime.bomb_state.bombs_by_target.has(str(flame_target.combat_id)),"An armed Verdant Spheres should make Living Bomb usable through its ordinary cooldown without adding a new action slot.")
		var boss_target:Dictionary=main.enemies.filter(func(enemy):return bool(enemy.get("boss",false)))[0]
		for enemy in main.enemies:
			if enemy!=boss_target:enemy.pos=Vector2(1100,80+main.enemies.find(enemy)*70)
		boss_target.pos=visual_mage.pos+Vector2.RIGHT*160.0;visual_mage.ability_cds[2]=0.0;main.cast_mage_e(visual_mage,boss_target.pos);main.update_mage_runtime(1.0)
		TestSupport.check(errors,visual_mage.mage_runtime.telemetry.e_hits>=1 and visual_mage.mage_runtime.telemetry.stuns_resisted>=1 and not boss_target.active_effects.any(func(effect):return str(effect.get("control_type",""))=="stun"),"Gravity Lapse should collide with a Boss while the Boss resists Stun by default.")
		visual_mage.selected_heroic_id="mage_l15_r1";visual_mage.ability_cds[3]=0.0;var phoenix_destination:Vector2=Vector2(visual_mage.pos)+Vector2(90,80);TestSupport.check(errors,main.cast_phoenix(visual_mage,phoenix_destination),"Phoenix should accept a valid in-bounds launch destination.")
		main.update_mage_runtime(1.0);TestSupport.check(errors,not visual_mage.mage_runtime.phoenix.is_empty() and int(visual_mage.mage_runtime.phoenix.reposition_charges)==int(main.MageData.VALUES.rebirth_charges),"Rebirth should create three temporary R reposition charges after Phoenix arrives.")
		var reposition_before:int=visual_mage.mage_runtime.phoenix.reposition_charges;TestSupport.check(errors,not main.cast_phoenix(visual_mage,Vector2(visual_mage.mage_runtime.phoenix.pos)) and int(visual_mage.mage_runtime.phoenix.reposition_charges)==reposition_before,"An invalid no-movement Rebirth destination should consume no charge.")
		var reposition_destination:Vector2=phoenix_destination+Vector2(50,0);TestSupport.check(errors,main.cast_phoenix(visual_mage,reposition_destination) and int(visual_mage.mage_runtime.phoenix.reposition_charges)==reposition_before-1 and bool(visual_mage.mage_runtime.phoenix.traveling),"Rebirth should reuse R, consume one charge only for a valid destination, and enter relocation travel.")
		flame_target.pos=visual_mage.pos+Vector2.RIGHT*150.0;visual_mage.selected_heroic_id="mage_l15_r2";visual_mage.ability_cds[3]=0.0;main.focused_enemy_index=0;main.cast_pyroblast(visual_mage);main.issue_hero_move(visual_mage,visual_mage.pos+Vector2(20,0))
		TestSupport.check(errors,visual_mage.active_cast.is_empty() and is_equal_approx(visual_mage.ability_cds[3],main.CombatRulesV1.HEROIC_INTERRUPT_COOLDOWN),"Moving during Pyroblast's unreleased cast should apply the shared ten-second interrupted Heroic cooldown.")
		main.effects.clear();visual_mage.hp=visual_mage.max_hp;visual_mage.shield=0.0;visual_mage.shield_sources=[];main.MageSystem.initialize_runtime(visual_mage,true);for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=mage_enemy_states[enemy_index].pos;main.enemies[enemy_index].hp=mage_enemy_states[enemy_index].hp;main.enemies[enemy_index].active_effects=mage_enemy_states[enemy_index].active_effects
	else:TestSupport.check(errors,false,"The testing party should include a Mage for combat and presentation coverage.")
	var input_guardian:Dictionary=main.heroes[0];main.selected=0;input_guardian.selected_talents={"tier_6":"guardian_l24_2"};input_guardian.ability_cds[4]=0.0;main.begin_trait()
	TestSupport.check(errors,input_guardian.guardian_runtime.stoneform_remaining==10.0 and input_guardian.ability_cds[4]==60.0,"The existing D Trait input should activate Stoneform and expose its cooldown without another action slot.")
	input_guardian.guardian_runtime.stoneform_remaining=0.0
	input_guardian.selected_talents={"tier_8":"guardian_l30_3"};input_guardian.ability_cds[2]=0.0;var invalid_toss:bool=bool(main.cast_guardian_ability(2,Vector2(55,320)))
	TestSupport.check(errors,not invalid_toss and input_guardian.ability_cds[2]==0.0 and main.GuardianSystem.rewind_sequence_count(input_guardian,main.battle_time)==0,"An invalid Dwarf Toss should consume no cooldown and should not count toward Rewind.")
	var original_enemy_positions:Array=main.enemies.map(func(enemy):return enemy.pos)
	for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=Vector2(1100,100+enemy_index*70)
	input_guardian.ability_cds[1]=0.0
	var thunder_clap_cast:bool=bool(main.cast_guardian_ability(1,input_guardian.pos))
	TestSupport.check(errors,thunder_clap_cast and input_guardian.guardian_runtime.telemetry.thunder_clap_casts[-1]==0,"Thunder Clap should complete safely and record its per-cast target count without a telemetry type crash.")
	for enemy_index in main.enemies.size():main.enemies[enemy_index].pos=original_enemy_positions[enemy_index]
	var defense_dummy:Dictionary=main.enemies[-1]
	main.heroes[0].pos=defense_dummy.pos+Vector2(100,0);main.heroes[0].dest=main.heroes[0].pos;main.heroes[0].suppress_auto_target=true
	var defense_health_before:float=main.heroes[0].hp
	defense_dummy.cooldown=0.0
	main._process(.5);main._process(.5);main._process(.5)
	TestSupport.check(errors,main.heroes[0].hp<defense_health_before,"The enabled defense dummy should attack a hero who enters its short stationary range.")
	main.toggle_testing_dummy_attacks()
	defense_dummy.cooldown=0.0
	var disabled_health_before:float=main.heroes[0].hp
	main._process(2.0)
	TestSupport.check(errors,main.heroes[0].hp>=disabled_health_before,"Disabling dummy attacks should cancel and prevent defense-dummy attacks.")
	main.heroes[0].target=0;main.heroes[0].suppress_auto_target=false;main.selected=0;main.drag_has_moved=true;main.drag_target_type="ground";main.drag_cursor=Vector2(300,300);main.finish_hero_drag()
	TestSupport.check(errors,main.heroes[0].target==-1 and main.heroes[0].suppress_auto_target,"An explicit movement order should cancel and suppress automatic enemy reacquisition.")
	main.heroes[0].pos=main.heroes[1].pos+Vector2(50,0);main.heroes[0].dest=main.heroes[0].pos;main.assign_hero_ally(1,0);main.heroes[0].hp=main.heroes[0].max_hp
	var combat_event_count_before_basic_heal:int=main.combat_events.size()
	main._process(.5);main._process(.5)
	TestSupport.check(errors,main.heroes[1].heal_target==0 and int(main.heroes[1].basic_action_phase)==main.CombatRulesV1.BasicActionPhase.RECOVERY,"A healer should keep and execute its assigned heal cycle even while the target is at full health.")
	var basic_heal_events:Array=main.combat_events.slice(combat_event_count_before_basic_heal)
	TestSupport.check(errors,basic_heal_events.any(func(event):return event.event_type=="basic_heal_done" and event.source_action=="basic_heal" and "basic_action" in event.action_tags),"The assigned Cleric Basic Heal should use the distinct Basic Heal source and shared Basic Action grouping tag.")
	main.assign_hero_enemy(0,0);main.heroes[0].ability_cds=[0.0,0.0,0.0,0.0,0.0];main.begin_unit_cast(main.heroes[0],0,1.0,false)
	main.issue_hero_move(main.heroes[0],main.heroes[0].pos+Vector2(20,0))
	TestSupport.check(errors,main.heroes[0].active_cast.is_empty() and is_equal_approx(main.heroes[0].ability_cds[0],0.0),"Movement should interrupt an unreleased Basic Ability without applying its full cooldown.")
	main.assign_hero_enemy(0,0);main.begin_unit_cast(main.heroes[0],3,1.0,true);main.issue_hero_move(main.heroes[0],main.heroes[0].pos+Vector2(20,0))
	TestSupport.check(errors,main.heroes[0].active_cast.is_empty() and is_equal_approx(main.heroes[0].ability_cds[3],main.CombatRulesV1.HEROIC_INTERRUPT_COOLDOWN),"Movement should interrupt an unreleased Heroic and apply the shared ten-second interrupted cooldown.")
	main.heroes[0].ability_cds[2]=0.0;main.assign_hero_enemy(0,0);main.begin_unit_cast(main.heroes[0],2,0.0,false,2.0,false,8.0);main.update_unit_casts(main.heroes[0],.01)
	var channel_cooldown:float=main.heroes[0].ability_cds[2];main.interrupt_unit_action(main.heroes[0],"test interrupt")
	TestSupport.check(errors,main.heroes[0].active_channel.is_empty() and is_equal_approx(channel_cooldown,8.0) and is_equal_approx(main.heroes[0].ability_cds[2],8.0),"An interrupted active channel should keep its full cooldown and stop future channel time.")
	var regen_dummy:Dictionary=main.enemies[0];regen_dummy.hp=regen_dummy.max_hp*.5;regen_dummy.seconds_since_damage=main.TESTING_DUMMY_REGEN_DELAY
	main._process(1.0)
	TestSupport.check(errors,is_equal_approx(regen_dummy.hp,regen_dummy.max_hp*.6),"An undamaged testing dummy should regenerate ten percent of maximum health per second.")
	regen_dummy.hp=0.0;regen_dummy.respawn_timer=0.0
	main._process(main.TESTING_DUMMY_RESPAWN_TIME+.01)
	TestSupport.check(errors,is_equal_approx(regen_dummy.hp,regen_dummy.max_hp),"A defeated testing dummy should respawn at full health after five seconds.")
	var item_guardian:Dictionary=main.heroes[0];var item_cleric:Dictionary=main.heroes[1];var item_rogue:Dictionary=main.heroes[2]
	var rogue_stats:Dictionary=main.hero_final_stats(main.state.heroes[4])
	TestSupport.check(errors,item_guardian.max_hp>GameData.CLASSES.Guardian.base_health and int(item_cleric.q_charges)==2 and rogue_stats.basic_action_interval<GameData.CLASSES.Rogue.basic_action_interval,"Equipped health, Twin Incantation charges, and rapid Basic Action speed should be active in battle.")
	item_guardian.shield=0.0;item_guardian.shield_sources=[];item_guardian.hp=item_guardian.max_hp*.60
	var item_attacker:={"level":1,"critical_chance":0.0,"critical_damage":2.0,"damage_multiplier":1.0,"pos":Vector2.ZERO,"active_effects":[],"passive_cooldowns":{},"equipped_items":[]}
	main.deal_damage(item_attacker,item_guardian,item_guardian.max_hp*.20,"basic_attack","true","threshold_test")
	TestSupport.check(errors,item_guardian.shield>=item_guardian.max_hp*.74 and item_guardian.power>item_guardian.base_power,"Last Dawn should create its sourced Shield and Power bonus on a half-health crossing.")
	main.deal_damage(item_attacker,item_guardian,20.0,"basic_attack","physical","retribution_test")
	TestSupport.check(errors,not item_guardian.retribution_charges.is_empty(),"Resolved Physical Damage should store a Retribution charge.")
	var item_dummy:Dictionary=main.enemies[1];var nearby_item_dummy:Dictionary=main.enemies[2];item_dummy.hp=item_dummy.max_hp;nearby_item_dummy.hp=nearby_item_dummy.max_hp;item_dummy.active_effects=[];nearby_item_dummy.active_effects=[]
	item_guardian.critical_chance=1.0;item_guardian.ability_cds=[4.0,4.0,4.0,4.0,0.0]
	var original_hp_before_wake:float=item_dummy.hp;var nearby_hp_before_wake:float=nearby_item_dummy.hp
	main.deal_damage(item_guardian,item_dummy,item_guardian.damage,"basic_attack","physical","item_attack_test")
	TestSupport.check(errors,item_dummy.hp<original_hp_before_wake and item_dummy.active_effects.is_empty() and nearby_item_dummy.hp<nearby_hp_before_wake and nearby_item_dummy.active_effects.any(func(effect):return effect.id=="vulnerable") and item_guardian.ability_cds[0]<4.0,"Stormbreaker should spare the original target from its explosion, deal Magical Damage and apply Vulnerable nearby, and let the critical attack trigger Endless Momentum.")
	item_dummy.hp=1.0;item_dummy.item_defeat_processed=false
	main.deal_damage(item_guardian,item_dummy,50.0,"basic_attack","physical","soul_test")
	TestSupport.check(errors,item_guardian.soul_furnace_stacks>=1,"Soul Furnace should gain a battle-only stack when an enemy is defeated.")
	item_cleric.shield=0.0;item_cleric.shield_sources=[];item_cleric.hp=item_cleric.max_hp;item_cleric.critical_chance=1.0
	main.deal_healing(item_cleric,item_cleric,10.0,"basic_ability","overflow_test")
	TestSupport.check(errors,item_cleric.shield>0.0 and item_cleric.shield<=item_cleric.max_hp*.60,"Overflowing Grace should convert critical direct overhealing into a capped Shield.")
	main.selected=1;item_cleric.heal_target=0;item_cleric.ability_cds=[0.0,0.0,0.0,0.0,0.0]
	main.use_ability(0,item_cleric.pos);main.use_ability(0,item_cleric.pos);main.use_ability(0,item_cleric.pos)
	TestSupport.check(errors,int(item_cleric.q_charges)==0 and item_cleric.q_charge_timers.size()==2,"Twin Incantation should permit exactly two independently recharging Q casts.")
	main.use_ability(2,item_cleric.pos)
	TestSupport.check(errors,int(item_cleric.q_charges)==1 and item_cleric.q_charge_timers.size()==1,"Casting E should restore one missing Twin Incantation Q charge.")
	main.update_item_runtime(item_cleric,8.1);item_cleric.ability_cds[1]=0.0;main.use_ability(1,item_cleric.pos)
	TestSupport.check(errors,item_cleric.pending_repeats.size()==1 and not item_cleric.borrowed_time_armed,"Borrowed Time should arm after eight seconds and schedule one non-recursive repeat.")
	main.update_cleric_runtime(.01)
	TestSupport.check(errors,main.effects.any(func(effect):return effect.kind=="cloud_serpent_projectile"),"An active Cloud Serpent attack should launch its own visible projectile from the host marker.")
	main.effects.clear()
	# Ranger V1 deals substantially more Basic Attack damage than the old placeholder;
	# keep this item-proc fixture alive through all three attacks.
	item_dummy.max_hp=maxf(float(item_dummy.max_hp),5000.0);item_dummy.hp=item_dummy.max_hp;item_rogue.thousand_cuts_count=0
	var hp_before_three:float=item_dummy.hp
	main.deal_damage(item_rogue,item_dummy,item_rogue.damage,"basic_attack","physical","cut_one");main.deal_damage(item_rogue,item_dummy,item_rogue.damage,"basic_attack","physical","cut_two")
	var hp_before_third:float=item_dummy.hp;main.deal_damage(item_rogue,item_dummy,item_rogue.damage,"basic_attack","physical","cut_three")
	TestSupport.check(errors,int(item_rogue.thousand_cuts_count)==0 and hp_before_third-item_dummy.hp>(hp_before_three-hp_before_third)*.45,"Every third Basic Attack should trigger the two Thousand Cuts extra strikes without advancing its own counter.")
	main.start_testing_endless(17)
	TestSupport.check(errors,main.testing_zone_mode=="endless" and main.testing_endless_level==17 and main.enemies.size()==4 and main.enemies.all(func(enemy):return int(enemy.level)==17 and bool(enemy.get("testing_endless_enemy",false)) and enemy.rewarded),"Endless Arena should begin with non-rewarding enemies scaled to the selected fixed level.")
	for endless_enemy in main.enemies:endless_enemy.hp=0.0
	main.update_testing_endless(.8);main.update_testing_endless(.4)
	TestSupport.check(errors,main.testing_endless_defeated==4 and main.enemies.size()==1 and int(main.enemies[0].level)==17,"Endless Arena should clear defeated enemies, replace them continuously, and retain the selected enemy level.")
	main.show_roster()
	await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("TestingHeroLevel",true,false)!=null,"The testing Hero Roster should expose the hero level picker.")
	main.set_testing_hero_level(0,12.0)
	TestSupport.check(errors,int(main.state.heroes[0].level)==12,"The testing hero level picker should persist the selected level.")
	main.current_save_slot=0
	main.set_testing_hero_level(0,20.0)
	TestSupport.check(errors,int(main.state.heroes[0].level)==12,"Live save slots must not be able to invoke the testing level tool directly.")
	main.show_roster()
	await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("TestingHeroLevel",true,false)==null,"The hero level picker must remain hidden in live save slots.")
	main.show_dungeons()
	await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("TestingResetStoryButton",true,false)==null,"The story reset tool must remain hidden in live save slots.")
	main.current_save_slot=3
	InventorySystem.add_equipment(main.state,ItemData.create_instance("pinewatch_bow","testing_preserved_item"))
	main.state.zone0.next_item_id=42
	var testing_gold_before:int=int(main.state.gold)
	var testing_roster_size_before:int=main.state.heroes.size()
	main.reset_testing_ashwood_story()
	TestSupport.check(errors,main.screen=="zone_map" and main.state.zone0.encounters.first_battle.unlocked,"Reset Story should return to a fresh Ashwood map with the opening battle available.")
	TestSupport.check(errors,not main.state.zone0.zone0_boss_defeated and str(main.state.zone0.first_recruit_choice)=="" and not main.state.zone0.encounters.first_recruit.unlocked,"Reset Story should clear boss completion, decisions, and later encounter unlocks.")
	TestSupport.check(errors,not InventorySystem.entry_by_id(main.state,"testing_preserved_item").is_empty() and main.state.zone0.inventory.is_empty() and int(main.state.zone0.next_item_id)==42,"Reset Story should preserve unified Item Storage and the Ashwood item identifier sequence without restoring the retired inventory list.")
	TestSupport.check(errors,main.state.heroes.size()==testing_roster_size_before and int(main.state.heroes[0].level)==12 and int(main.state.gold)==testing_gold_before,"Reset Story should preserve testing heroes, chosen levels, and guild resources.")
	TestSupport.check(errors,main.state.selected_team==[0,1] and main.state.active_team==[0,1],"Reset Story should restore Brann and Sera as the story-testing party.")
	TestSupport.check(errors,FileAccess.file_exists(SaveManager.save_slot_path(3)),"Opening the testing slot should persist it independently.")
	SaveManager.delete_slot(3)
	TestSupport.check(errors,not FileAccess.file_exists(SaveManager.save_slot_path(3)),"The testing slot should delete independently.")
	return errors
