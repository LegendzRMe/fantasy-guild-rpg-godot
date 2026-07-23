extends RefCounted

const TestSupport = preload("res://tests/test_support.gd")
const WarlockData = preload("res://scripts/data/warlock_data.gd")
const WarlockSystem = preload("res://scripts/systems/warlock_system.gd")
const PeriodicStatusSystem = preload("res://scripts/systems/periodic_status_system.gd")

static func make_warlock(talents:Dictionary={}, heroic_id:String="warlock_l15_r1") -> Dictionary:
	var unit:={
		"class":"Warlock","combat_id":"hero:warlock","level":1,
		"hp":1700.0,"max_hp":1700.0,"power":60.0,"armor":0.0,
		"ability_cds":[3.0,20.0,28.0,80.0,0.0],"selected_talents":talents,
		"selected_heroic_id":heroic_id,"stats":{"ability_power_percent":0.0},
		"damage_multiplier":1.0,"healing_taken_multiplier":1.0,"damage_taken_multiplier":1.0
	}
	WarlockSystem.initialize_runtime(unit,true)
	return unit

static func run() -> Array:
	var errors:=[]
	TestSupport.check(errors,WarlockData.CLASS_DEFINITION.base_health==1700.0,"Warlock should use the verified Level 1 Health chassis.")
	TestSupport.check(errors,WarlockData.CLASS_DEFINITION.base_armor==0.0,"Warlock should use zero Level 1 Armor.")
	TestSupport.check(errors,WarlockData.CLASS_DEFINITION.basic_action_damage_type=="physical","Warlock Basic Attacks should be Physical.")
	TestSupport.check(errors,not bool(WarlockData.CLASS_DEFINITION.uses_mana),"Warlock must not use Mana.")
	TestSupport.check(errors,str(WarlockData.CLASS_DEFINITION.resource_id)=="","Warlock must not expose an extra combat resource.")
	TestSupport.check(errors,is_equal_approx(WarlockData.scaled(100.0,2),104.0),"Warlock should use four-percent level scaling.")

	var unit:=make_warlock()
	unit["assigned_target_id"]="enemy:kept";unit["assigned_target_kind"]="enemy";unit["shield"]=500.0
	var result:=WarlockSystem.use_life_tap(unit)
	TestSupport.check(errors,bool(result.valid),"Life Tap should commit when eligible cooldowns can benefit.")
	TestSupport.check(errors,is_equal_approx(float(unit.hp),1478.0),"Life Tap should pay the precise 222/1700 maximum-Health ratio.")
	TestSupport.check(errors,is_equal_approx(float(unit.ability_cds[0]),2.25),"Life Tap should reduce Q by 0.75 seconds.")
	TestSupport.check(errors,is_equal_approx(float(unit.ability_cds[1]),15.0),"Life Tap should reduce W by 5 seconds.")
	TestSupport.check(errors,is_equal_approx(float(unit.ability_cds[2]),21.0),"Life Tap should reduce E by 7 seconds.")
	TestSupport.check(errors,is_equal_approx(float(unit.ability_cds[3]),80.0),"Normal Life Tap should not reduce the Heroic.")
	TestSupport.check(errors,is_equal_approx(float(unit.warlock_runtime.life_tap_lockout),0.5),"Successful Life Tap should start the input lockout.")
	TestSupport.check(errors,is_equal_approx(float(unit.shield),500.0) and str(unit.assigned_target_id)=="enemy:kept","Life Tap should bypass Shields and preserve the assigned Basic Action target.")

	var floor_unit:=make_warlock();floor_unit.ability_cds=[0.1,1.0,2.0,80.0,0.0];WarlockSystem.use_life_tap(floor_unit)
	TestSupport.check(errors,is_equal_approx(float(floor_unit.ability_cds[0]),0.0) and is_equal_approx(float(floor_unit.ability_cds[1]),0.0) and is_equal_approx(float(floor_unit.ability_cds[2]),0.0),"Life Tap should floor cooldowns at zero without storing overflow.")

	var lethal:=make_warlock();lethal.hp=222.0
	var lethal_result:=WarlockSystem.use_life_tap(lethal)
	TestSupport.check(errors,not bool(lethal_result.valid) and lethal_result.reason=="lethal","Life Tap must be nonlethal.")
	TestSupport.check(errors,is_equal_approx(float(lethal.hp),222.0),"Invalid Life Tap must not spend Health.")
	TestSupport.check(errors,is_equal_approx(float(lethal.warlock_runtime.life_tap_lockout),0.0),"Invalid Life Tap must not start its lockout.")

	var no_benefit:=make_warlock();no_benefit.ability_cds=[0.0,0.0,0.0,0.0,0.0]
	TestSupport.check(errors,not bool(WarlockSystem.use_life_tap(no_benefit).valid),"Life Tap should be unavailable when no effect can benefit.")

	var improved:=make_warlock({"tier_2":"warlock_l12_2"});WarlockSystem.use_life_tap(improved)
	TestSupport.check(errors,is_equal_approx(float(improved.ability_cds[0]),1.8),"Improved Life Tap should use 40% of modified base cooldown.")
	TestSupport.check(errors,is_equal_approx(float(improved.ability_cds[1]),12.0),"Improved Life Tap should reduce W by 8 seconds.")

	var dark_bargain:=make_warlock({"tier_5":"warlock_l21_3"})
	TestSupport.check(errors,is_equal_approx(float(dark_bargain.max_hp),2380.0),"Dark Bargain should increase maximum Health by 40%.")
	TestSupport.check(errors,is_equal_approx(WarlockSystem.modified_base_cooldown(dark_bargain,0),3.3),"Dark Bargain should increase modified cooldown bases by 10%.")
	WarlockSystem.use_life_tap(dark_bargain)
	TestSupport.check(errors,is_equal_approx(float(dark_bargain.ability_cds[0]),2.175),"Life Tap should reduce Dark Bargain Q by 25% of its modified 3.3-second base.")

	var hunger:=make_warlock({"tier_4":"warlock_l18_3"});hunger.armor=999.0;hunger.shield=999.0;var hunger_cost:=WarlockSystem.life_tap_cost(hunger);WarlockSystem.use_life_tap(hunger)
	TestSupport.check(errors,is_equal_approx(float(hunger.hp),1700.0-hunger_cost) and is_equal_approx(float(hunger.shield),999.0),"Armor, Shields, and Hunger for Power must not alter Life Tap's Health cost.")

	var passive:=make_warlock();passive.ability_cds=[3.0,20.0,28.0,80.0,0.0]
	var passive_result:=WarlockSystem.convert_health_loss(passive,111.0)
	TestSupport.check(errors,is_equal_approx(float(passive_result.tap_equivalent),0.5),"Half a Tap-equivalent of actual Health loss should remain fractional.")
	TestSupport.check(errors,is_equal_approx(float(passive.ability_cds[0]),2.625),"Half a Tap-equivalent should grant half the normal Q reduction.")
	TestSupport.check(errors,is_equal_approx(float(passive.ability_cds[3]),80.0),"Passive Health loss must not reduce Heroics.")

	var darkness:=make_warlock({"tier_6":"warlock_l24_3"});darkness.ability_cds=[0.0,0.0,0.0,0.0,0.0]
	WarlockSystem.record_owned_damage(darkness,600.0)
	TestSupport.check(errors,bool(darkness.warlock_runtime.darkness_armed),"Darkness Within should arm at 600 owned damage.")
	var darkness_result:=WarlockSystem.use_life_tap(darkness)
	TestSupport.check(errors,bool(darkness_result.valid) and bool(darkness_result.free),"Darkness Within should permit a free Life Tap with all cooldowns ready.")
	TestSupport.check(errors,is_equal_approx(float(darkness.hp),1700.0),"A free Life Tap should not spend Health.")
	TestSupport.check(errors,is_equal_approx(float(darkness.ability_power_percent),0.25),"Darkness Within should grant 25% Q/W/E Power.")

	var ritual:=make_warlock({"tier_8":"warlock_l30_2"});ritual.ability_cds=[0.0,0.0,0.0,80.0,0.0]
	var ritual_result:=WarlockSystem.use_life_tap(ritual)
	TestSupport.check(errors,bool(ritual_result.valid),"Dark Ritual should make Life Tap valid when only R is recharging.")
	TestSupport.check(errors,is_equal_approx(float(ritual.ability_cds[3]),76.0),"Dark Ritual should reduce Horrify by 5% of modified base cooldown.")

	var corruption:=PeriodicStatusSystem.make_instance("warlock_corruption","owner","target",6.0,1.0,{"cast_id":"cast:1","max_stacks":3})
	var stacks:Array=[]
	for index in 4:stacks=PeriodicStatusSystem.add_stack(stacks,corruption,3)
	TestSupport.check(errors,stacks.size()==3,"Corruption should retain at most three independent instances per owner and target.")
	var other_target:=PeriodicStatusSystem.make_instance("warlock_corruption","owner","other_target",6.0,1.0,{"cast_id":"cast:2","max_stacks":3})
	stacks=PeriodicStatusSystem.add_stack(stacks,other_target,3)
	TestSupport.check(errors,stacks.size()==4,"A different target should own an independent Corruption stack allowance.")
	var advanced:=PeriodicStatusSystem.advance(corruption,1.25)
	TestSupport.check(errors,int(advanced.due_ticks)==1 and is_equal_approx(float(advanced.remaining_duration),4.75),"Periodic instances should retain deterministic tick and duration state.")

	var target:={"hp":100.0,"combat_tags":["regular"]}
	TestSupport.check(errors,WarlockSystem.qualifying_target(target),"Standard combat enemies should qualify for Warlock quests.")
	target.combat_tags=["damageable_object"]
	TestSupport.check(errors,not WarlockSystem.qualifying_target(target),"Damageable objects should not qualify for Warlock talents.")

	var circle:=make_warlock({"tier_8":"warlock_l30_1"});circle.hp=100.0
	var circle_result:=WarlockSystem.try_demonic_circle(circle,100.0)
	TestSupport.check(errors,bool(circle_result.triggered) and is_equal_approx(float(circle.warlock_runtime.banished_remaining),3.0),"Demonic Circle should prevent eligible lethal damage and begin its three-second banish.")
	TestSupport.check(errors,is_equal_approx(float(circle.warlock_runtime.internal_cooldowns.demonic_circle.remaining),120.0),"Demonic Circle should start its nonreducible 120-second internal cooldown.")
	var circle_reduction:=WarlockSystem.convert_health_loss(circle,100.0,{"exclude_health_loss_cooldown_conversion":true})
	TestSupport.check(errors,is_equal_approx(float(circle_reduction.tap_equivalent),0.0),"Demonic-Circle-prevented damage must produce no health-loss conversion.")
	return errors
