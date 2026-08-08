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
	main.state.gold=ProfessionData.LEARN_COST;main.select_roster_section("Professions")
	await main.get_tree().process_frame
	var professions_content:VBoxContainer=main.ui.find_child("RosterSectionContent",true,false)
	var profession_choices:Array[Node]=main.ui.find_children("RosterProfessionChoice_*","Button",true,false)
	var profession_cards:Array[Node]=main.ui.find_children("RosterProfessionCard_*","PanelContainer",true,false);var profession_scroll:ScrollContainer=main.ui.find_child("RosterSectionScroll",true,false)
	var cooking_choice:Button=main.ui.find_child("RosterProfessionChoice_cooking",true,false)
	TestSupport.check(errors,professions_content.get_child_count()>=3 and main.ui.find_child("RosterProfessionChoices",true,false)!=null and profession_choices.size()==5 and cooking_choice!=null and not cooking_choice.disabled and "Train" in cooking_choice.text and profession_choices.filter(func(choice):return choice!=cooking_choice).all(func(choice):return choice.disabled),"An untrained Hero should learn Tavern-trained Cooking through the same compact Professions grid as every other profession.")
	var profession_grid:GridContainer=main.ui.find_child("RosterProfessionChoices",true,false)
	TestSupport.check(errors,profession_cards.size()==5 and profession_cards.all(func(card):return card.custom_minimum_size.y<=92) and profession_grid.columns==2 and profession_grid.get_combined_minimum_size().x<=profession_scroll.size.x and profession_scroll.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED and profession_scroll.vertical_scroll_mode!=ScrollContainer.SCROLL_MODE_DISABLED,"Profession choices should wrap into compact rows inside the same vertical roster scroller used by Details, Talents, and Abilities.")
	if cooking_choice!=null:cooking_choice.pressed.emit();await main.get_tree().process_frame
	var cooking_training_dialog:ConfirmationDialog=main.ui.find_child("ProfessionTrainingJourneyDialog",true,false)
	TestSupport.check(errors,cooking_training_dialog!=null and main.screen=="roster" and "COOKING" in cooking_training_dialog.title,"Choosing Cooking should use the normal Hero Roster profession-training confirmation instead of redirecting to the Tavern.")
	if cooking_training_dialog!=null:cooking_training_dialog.hide();cooking_training_dialog.queue_free();await main.get_tree().process_frame
	main.state.zone0.encounters.caravan.first_clear_completed=true;main.state.gold=ProfessionData.LEARN_COST;main.select_roster_section("Professions");await main.get_tree().process_frame
	var forgecraft_choice:Button=main.ui.find_child("RosterProfessionChoice_forgecraft",true,false);TestSupport.check(errors,forgecraft_choice!=null and not forgecraft_choice.disabled and "Train" in forgecraft_choice.text,"Completing a trainer-linked world encounter should enable that profession's training journey from the Hero Roster.")
	if forgecraft_choice!=null:forgecraft_choice.pressed.emit();await main.get_tree().process_frame
	var training_dialog:ConfirmationDialog=main.ui.find_child("ProfessionTrainingJourneyDialog",true,false);TestSupport.check(errors,training_dialog!=null and training_dialog.ok_button_text=="Begin Training Journey" and "only one profession" in training_dialog.dialog_text.to_lower(),"Choosing a profession should confirm the Hero's trainer journey and clearly enforce the one-profession limit.")
	if training_dialog!=null:training_dialog.hide();training_dialog.queue_free()
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
	return errors
