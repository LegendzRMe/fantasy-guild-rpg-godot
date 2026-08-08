extends RefCounted

const CampaignData = preload("res://scripts/data/campaign_data.gd")
const CampaignSystem = preload("res://scripts/systems/campaign_system.gd")
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run()->Array:
	var errors:Array=[]
	TestSupport.check(errors,CampaignData.REGION_ORDER.size()==6 and CampaignData.FACTIONS.size()==24,"The framework should define six sequential campaign regions and twenty-four regional factions.")
	var location_count:=0
	for region_id in CampaignData.REGION_ORDER:location_count+=CampaignData.region(region_id).locations.size()
	TestSupport.check(errors,location_count==54 and CampaignData.REGION_TARGET_LEVELS.values()==[5,10,15,20,25,30],"All fifty-four permanent locations and six level milestones should be data-driven.")
	var state:=SaveManager.fresh_state();CampaignSystem.ensure_state(state)
	TestSupport.check(errors,not state.campaign.regions.greyhaven_reach.unlocked and state.campaign.combat_hall_unlocked and state.guild_hall_room_unlocks.combat_hall,"A live guild should retain Ashwood's campaign gate while receiving immediate access to the Combat Hall.")
	state.zone0.zone0_boss_defeated=true;CampaignSystem.ensure_state(state)
	TestSupport.check(errors,state.campaign.regions.greyhaven_reach.unlocked and state.campaign.combat_hall_unlocked and state.guild_hall_room_unlocks.combat_hall,"Completing Ashwood should unlock Greyhaven without removing the always-available Combat Hall.")
	for location_id in CampaignData.main_locations("greyhaven_reach"):
		var progress:=CampaignSystem.complete_campaign_encounter(state,"greyhaven_reach",str(location_id));TestSupport.check(errors,bool(progress.advanced),"Each one-time Greyhaven story encounter should advance once.")
	var first_repeat:=CampaignSystem.complete_campaign_encounter(state,"greyhaven_reach","forest_road")
	TestSupport.check(errors,not bool(first_repeat.advanced),"A completed campaign encounter must never replay its one-time advancement.")
	var decision:=CampaignSystem.apply_decision(state,"greyhaven_reach","wardens")
	TestSupport.check(errors,bool(decision.success) and state.campaign.regions.greyhaven_reach.completed and state.campaign.regions.kwaad_scar.unlocked and state.campaign.decisions.greyhaven_reach.option_id=="wardens","A permanent regional decision should complete Greyhaven, persist its outcome, and unlock Kwaad.")
	var second_decision:=CampaignSystem.apply_decision(state,"greyhaven_reach","compact")
	TestSupport.check(errors,not bool(second_decision.success),"A saved permanent decision must reject replacement.")
	var roster_before:int=state.heroes.size();CampaignSystem.adjust_reputation(state,"temple_wardens",35,"test");CampaignSystem.adjust_reputation(state,"temple_wardens",20,"test");CampaignSystem.adjust_reputation(state,"temple_wardens",20,"test")
	TestSupport.check(errors,CampaignSystem.reputation_rank(state,"temple_wardens").name=="Trusted" and state.heroes.size()==roster_before+1 and state.heroes[-1].faction_origin=="temple_wardens","Trusted reputation should grant exactly one faction-origin recruit.")
	CampaignSystem.adjust_reputation(state,"local_compact",-60,"test");var denied:=CampaignSystem.settlement_access(state,"local_compact")
	TestSupport.check(errors,not bool(denied.allowed) and denied.rank=="Hostile" and int(denied.guard_level_bonus)==4,"Hostile faction access should be denied with the harder guard tier.")
	var item_result:=CampaignSystem.grant_campaign_item(state,"greyhaven_reach",5);var item_id:=str(item_result.instance_id);var gold_before:=int(state.gold);var sold:=CampaignSystem.sell_item(state,item_id)
	TestSupport.check(errors,bool(item_result.success) and bool(sold.success) and int(state.gold)>gold_before and state.item_instances.all(func(item):return str(item.instance_id)!=item_id),"Campaign equipment should enter the Vault and sell for Gold when unequipped and unlocked.")
	var support_state:=SaveManager.testing_state();var all_indices:Array=[];for index in 8:all_indices.append(index)
	var team_a:=CampaignSystem.set_support_team(support_state,"kwaad_scar","support_team_a",all_indices.slice(0,4));var duplicate:=CampaignSystem.set_support_team(support_state,"kwaad_scar","support_team_b",all_indices.slice(3,7));var operation:=CampaignSystem.resolve_operation(support_state,"kwaad_scar")
	TestSupport.check(errors,bool(team_a.success) and not bool(duplicate.success) and operation.result in ["Strong","Adequate","Weak","Missing"],"Support teams should reject duplicate heroes and save a scored operation result.")
	var rival_standing:=int(state.campaign.rivals.gilded_jackals.standing);CampaignSystem.advance_rivals(state,"test encounter")
	TestSupport.check(errors,int(state.campaign.rivals.gilded_jackals.standing)>rival_standing and state.campaign.rivals.gilded_jackals.activity_log.size()>1,"Rival guild standing and activity should advance after major encounters.")
	var migrated:=SaveManager.migrate_state({"guild_name":"Legacy Campaign Guild","heroes":state.heroes.duplicate(true)},false)
	TestSupport.check(errors,migrated.campaign is Dictionary and migrated.campaign.regions.size()==6,"Legacy saves should migrate into the campaign framework without requiring old campaign data.")
	return errors
