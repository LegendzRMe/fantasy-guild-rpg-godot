extends RefCounted

const GameData = preload("res://scripts/data/game_data.gd")
const PrestigeRewardSystem = preload("res://scripts/systems/prestige_reward_system.gd")
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run()->Array:
	var errors:Array=[]
	var state:=SaveManager.fresh_state();state.heroes[0].prestige_rank=1
	var first:=PrestigeRewardSystem.claim_rank_reward(state,0,1,GameData.CLASSES.Guardian)
	TestSupport.check(errors,first.success and first.state.item_instances.size()==1,"A Prestige reward transaction should grant compatible cached equipment when storage has room.")
	var item:Dictionary=first.state.item_instances[0]
	TestSupport.check(errors,str(item.get("armor_family_requirement","")) in ["","plate"] and str(item.get("weapon_family_requirement","")) in ["","one_handed","two_handed","weapon_and_shield"],"Prestige Cache equipment should be compatible with the completing class.")
	var repeated:=PrestigeRewardSystem.claim_rank_reward(first.state,0,1,GameData.CLASSES.Guardian)
	TestSupport.check(errors,not repeated.success and repeated.reason=="Prestige reward already claimed","Prestige rewards should be idempotent for each Hero and rank.")
	var named_state:=SaveManager.fresh_state();named_state.heroes[0]=SaveManager.hero_state("Named Guardian","Guardian",1,10,"special_hero",true,1)
	var retroactive:=PrestigeRewardSystem.claim_rank_reward(named_state,0,1,GameData.CLASSES.Guardian)
	TestSupport.check(errors,not retroactive.success and retroactive.reason.begins_with("Starting Prestige"),"Named Heroes should not receive rewards for their authored starting Prestige ranks.")
	return errors
