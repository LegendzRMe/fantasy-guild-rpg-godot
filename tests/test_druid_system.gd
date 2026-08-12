extends RefCounted

const TestSupport=preload("res://tests/test_support.gd")
const DruidData=preload("res://scripts/data/druid_data.gd")
const DruidSystem=preload("res://scripts/systems/druid_system.gd")
const PeriodicStatusSystem=preload("res://scripts/systems/periodic_status_system.gd")
const CombatSystem=preload("res://scripts/systems/combat_system.gd")

static func unit(talents:Dictionary={},id:String="hero:druid")->Dictionary:
	var hero:={"class":"Druid","combat_id":id,"level":1,"power":60.0,"base_power":60.0,"hp":1525.0,"max_hp":1525.0,"pos":Vector2(100,100),"selected_talents":talents,"selected_heroic_id":str(talents.get("tier_3","")),"ability_cds":[0.0,0.0,0.0,0.0,0.0],"active_effects":[],"healing_multiplier":1.0,"healing_over_time_multiplier":1.0,"critical_chance":0.0}
	DruidSystem.initialize_runtime(hero,true,"test:encounter");return hero

static func ally(id:String,pos:Vector2=Vector2(120,100))->Dictionary:
	return {"combat_id":id,"hp":500.0,"max_hp":1000.0,"pos":pos,"active_effects":[]}

static func enemy(id:String,category:String="standard")->Dictionary:
	return {"combat_id":id,"hp":1000.0,"max_hp":1000.0,"pos":Vector2(160,100),"target_category":category,"combat_tags":[category],"active_effects":[]}

static func run()->Array:
	var errors:Array=[];var definition:Dictionary=DruidData.CLASS_DEFINITION
	TestSupport.check(errors,is_equal_approx(float(definition.base_health),1525.0) and is_equal_approx(float(definition.health_regeneration),3.1796) and is_equal_approx(float(definition.base_power),60.0),"Druid should preserve the audited Level-1 Health, regeneration, and Basic Attack anchors.")
	TestSupport.check(errors,is_equal_approx(float(definition.basic_action_interval),0.9) and is_equal_approx(float(definition.basic_action_range),5.5*float(DruidData.SPACE.source_to_world)) and not bool(definition.uses_mana),"Druid should use the audited attack cadence/range and no resource.")
	TestSupport.check(errors,is_equal_approx(DruidData.scaled(60.0,2),62.4),"Druid flat native values should scale four percent per level.")

	var druid:=unit();var a:=ally("ally:a")
	var cast:=DruidSystem.apply_regrowth(druid,a)
	TestSupport.check(errors,not bool(cast.refreshed) and druid.druid_runtime.regrowths.size()==1 and is_equal_approx(float(druid.druid_runtime.regrowths[0].remaining_duration),20.0),"Regrowth should apply one 20-second source-owned record.")
	TestSupport.check(errors,is_equal_approx(float(a.hp),500.0) and is_equal_approx(DruidSystem.regrowth_tick_request(druid),19.0),"Baseline Regrowth should have no immediate heal and use 19 per scheduled tick.")
	var first:=DruidSystem.advance(druid,0.999)
	TestSupport.check(errors,first.regrowth_ticks.is_empty(),"Regrowth should not tick before one second.")
	first=DruidSystem.advance(druid,0.001)
	TestSupport.check(errors,first.regrowth_ticks.size()==1 and int(first.regrowth_ticks[0].ticks_resolved)==1,"Regrowth's first normal tick should occur at one second.")
	var ticks:=1
	for ignored in 19:ticks+=DruidSystem.advance(druid,1.0).regrowth_ticks.size()
	TestSupport.check(errors,ticks==20 and druid.druid_runtime.regrowths.is_empty(),"Regrowth should schedule exactly 20 one-second ticks and expire on the final tick.")
	DruidSystem.apply_regrowth(druid,a);DruidSystem.advance(druid,5.0);cast=DruidSystem.apply_regrowth(druid,a)
	TestSupport.check(errors,bool(cast.refreshed) and druid.druid_runtime.regrowths.size()==1 and is_equal_approx(float(druid.druid_runtime.regrowths[0].remaining_duration),20.0),"Same-source Regrowth should replace/refresh rather than stack.")
	var other:=unit({},"hero:druid:other");DruidSystem.apply_regrowth(other,a)
	TestSupport.check(errors,DruidSystem.regrowth_for(druid,"ally:a")!=null and DruidSystem.regrowth_for(other,"ally:a")!=null,"Different Druids should own independent Regrowths on one ally.")

	var tank:=ally("ally:tank");TestSupport.check(errors,DruidSystem.designate_basic_healing_target(druid,tank),"A living ally should be manually designatable.")
	var miss:=DruidSystem.note_basic_attack(druid,enemy("enemy:miss"),{"resolved_damage":0.0,"evaded":true},[druid,tank])
	TestSupport.check(errors,not bool(miss.applied) and druid.druid_runtime.mini_hots.is_empty(),"Missed, evaded, or fully prevented attacks must not apply a mini-HoT.")
	var hit:=DruidSystem.note_basic_attack(druid,enemy("enemy:hit"),{"resolved_damage":60.0},[druid,tank]);DruidSystem.note_basic_attack(druid,enemy("enemy:hit2"),{"resolved_damage":999.0},[druid,tank])
	TestSupport.check(errors,bool(hit.applied) and druid.druid_runtime.mini_hots.size()==2 and is_equal_approx(DruidSystem.basic_hot_tick_request(druid),30.0),"Each successful primary attack should apply an independent 30+30 mini-HoT unrelated to damage dealt.")
	var hot_ticks:Array=DruidSystem.advance(druid,1.0).mini_hot_ticks
	TestSupport.check(errors,hot_ticks.size()==2 and druid.druid_runtime.mini_hots.size()==2,"Overlapping mini-HoTs should tick independently.")
	DruidSystem.advance(druid,1.0);TestSupport.check(errors,druid.druid_runtime.mini_hots.is_empty(),"Mini-HoTs should expire after their second tick.")
	var far:=ally("ally:far",Vector2(1000,100));DruidSystem.designate_basic_healing_target(druid,far);hit=DruidSystem.note_basic_attack(druid,enemy("enemy:far"),{"resolved_damage":60.0},[druid,far])
	TestSupport.check(errors,not bool(hit.applied) and str(druid.druid_runtime.designated_ally_id)=="ally:far","An out-of-range designation should persist without receiving a new mini-HoT.")
	druid.healing_over_time_multiplier=1.2
	TestSupport.check(errors,is_equal_approx(DruidSystem.regrowth_tick_request(druid),22.8) and is_equal_approx(DruidSystem.basic_hot_tick_request(druid),36.0),"Generic HoT modifiers should affect both Regrowth and Basic Attack mini-HoTs.")
	var ysera:=unit({"tier_6":"druid_l24_1"});ysera.hp=ysera.max_hp
	TestSupport.check(errors,is_equal_approx(DruidSystem.regrowth_tick_request(ysera),33.25) and is_equal_approx(DruidSystem.basic_hot_tick_request(ysera),30.0),"Ysera's Regrowth bonus must not leak into the Basic Attack mini-HoT.")
	var healing_target:=ally("ally:heal");var resolved:=CombatSystem.resolve_healing(druid,healing_target,{"amount":DruidSystem.basic_hot_tick_request(druid),"source_action":"periodic"})
	TestSupport.check(errors,is_equal_approx(float(resolved.amount),36.0),"The shared healing pipeline should resolve generic HoT-scaled mini-Hot ticks once.")

	var moon:=unit({"tier_4":"druid_l18_1","tier_5":"druid_l21_2","tier_6":"druid_l24_3"});DruidSystem.apply_regrowth(moon,a);DruidSystem.apply_regrowth(moon,tank)
	var contacts:=[enemy("enemy:1"),enemy("enemy:2","elite"),enemy("enemy:3","summon"),enemy("enemy:4","temporary_combat"),enemy("enemy:5","boss"),enemy("enemy:6")]
	var plan:=DruidSystem.moonfire_plan(moon,contacts)
	TestSupport.check(errors,int(plan.count)==5 and is_equal_approx(float(plan.combined_heal),130.0*5.0*1.5),"Moonfire should cap at five immediate categories and combine healing once per Regrowth target with Moonlit Harmony.")
	TestSupport.check(errors,is_equal_approx(float(plan.extension),5.0) and is_equal_approx(float(plan.roots_cdr),3.0),"Moonfire should cap Wild Growth at five seconds and Lunar Roots at three seconds.")
	var no_hot:=unit();TestSupport.check(errors,is_equal_approx(float(DruidSystem.moonfire_plan(no_hot,[enemy("enemy:x")]).combined_heal),130.0),"Moonfire computes one contact's native request; runtime only emits it for active Regrowth targets.")

	var roots:=unit({"tier_1":"druid_l9_1","tier_4":"druid_l18_2"});var area:=DruidSystem.create_roots_area(roots,Vector2.ZERO)
	TestSupport.check(errors,DruidSystem.roots_radius(roots,0.0)>float(DruidData.SPACE.roots_initial_radius) and DruidSystem.roots_radius(roots,3.0)>float(DruidData.SPACE.roots_max_radius),"Deep Roots should increase both initial and maximum growing radii by 25%.")
	TestSupport.check(errors,is_equal_approx(float(area.remaining),3.0+1.25*1.4),"Deep Roots should extend post-growth persistence by 40%.")
	var rooted:=DruidSystem.note_root_result(roots,enemy("enemy:root"),true)
	TestSupport.check(errors,bool(rooted.verdant),"One successful primary Root should qualify Verdant Pulse.")
	var immune:=DruidSystem.note_root_result(roots,enemy("enemy:immune","boss"),false)
	TestSupport.check(errors,not bool(immune.verdant),"A Root-immune Boss should not qualify successful-Root talents.")
	var quest:=unit({"tier_1":"druid_l9_2"});var before:=DruidSystem.treant_damage(quest);DruidSystem.note_root_result(quest,enemy("enemy:q"),true);var after:=DruidSystem.treant_damage(quest)
	TestSupport.check(errors,is_equal_approx(after-before,7.0) and DruidSystem.create_treant(quest,Vector2.ZERO).target_category=="summon","Vengeful Roots should add encounter-scoped +7 damage and create a source-owned summon.")
	DruidSystem.reset_encounter(quest);TestSupport.check(errors,int(quest.druid_runtime.vengeful_quest_stacks)==0,"Vengeful quest progress should reset with the encounter.")

	var cure:=unit({"tier_4":"druid_l18_3"});var controlled:=ally("ally:controlled");controlled.active_effects=[{"control_type":"stun","remaining_duration":2.0},{"control_type":"root","remaining_duration":2.0},{"control_type":"slow","remaining_duration":2.0},{"control_type":"silence","remaining_duration":2.0},{"control_type":"fear","remaining_duration":2.0}]
	cast=DruidSystem.apply_regrowth(cure,controlled,true)
	TestSupport.check(errors,cast.removed.size()==3 and controlled.active_effects.size()==2 and controlled.active_effects.all(func(effect):return str(effect.control_type) in ["silence","fear"]),"Nature's Cure should remove all Stuns, Roots, and Slows while preserving Silence and Fear.")
	DruidSystem.apply_rejuvenation(cure,controlled);TestSupport.check(errors,cure.druid_runtime.recent_cure_count==3,"Generated Rejuvenation must not trigger an additional Nature's Cure cleanse.")

	var balance:=unit({"tier_6":"druid_l24_2"});DruidSystem.apply_regrowth(balance,a)
	TestSupport.check(errors,is_equal_approx(DruidSystem.regrowth_duration(balance),25.0) and PeriodicStatusSystem.remaining_tick_count(balance.druid_runtime.regrowths[0])==25 and is_equal_approx(DruidSystem.moonfire_radius(balance),float(DruidData.SPACE.moonfire_radius)*1.75),"Nature's Balance should produce 25 ticks and the project-approved +75% radius.")
	var verdant_timer:=float(balance.druid_runtime.regrowths[0].next_tick);var bonus:=DruidSystem.bonus_regrowth_ticks(balance)
	TestSupport.check(errors,bonus.size()==1 and is_equal_approx(float(balance.druid_runtime.regrowths[0].next_tick),verdant_timer),"Verdant bonus ticks must not consume or reset scheduled ticks.")
	DruidSystem.advance(balance,10.0);var remaining:=PeriodicStatusSystem.remaining_scheduled_amount(balance.druid_runtime.regrowths[0])
	TestSupport.check(errors,is_equal_approx(remaining,15.0*19.0),"Remaining Regrowth healing should derive from scheduled native ticks.")

	var innervator:=unit({"tier_2":"druid_l12_3","tier_5":"druid_l21_3","tier_8":"druid_l30_3"});DruidSystem.apply_regrowth(innervator,a);var innervate:=DruidSystem.cast_innervate(innervator,a)
	TestSupport.check(errors,bool(innervate.cast) and is_equal_approx(float(innervate.communion),190.0) and is_equal_approx(float(innervator.druid_runtime.regrowths[0].remaining_duration),20.0),"Nature's Communion should cash out 50% of 20 remaining native ticks and fully refresh without consuming Regrowth.")
	TestSupport.check(errors,int(innervator.druid_runtime.d_slot.max_charges)==2 and is_equal_approx(DruidSystem.innervate_recharge_rate(innervator),1.25),"Shan'do's Clarity should provide two charges and +25% recharge per own-Regrowth ally.")
	TestSupport.check(errors,is_equal_approx(DruidSystem.cooldown_rate_from_innervate(a,[innervator],0),1.5) and is_equal_approx(DruidSystem.cooldown_rate_from_innervate(a,[innervator],3),1.0),"Innervate should accelerate Q/W/E recharge by 50% and never Heroics.")
	TestSupport.check(errors,DruidData.TALENT_TIERS.size()==8 and DruidData.TEST_BUILDS.size()>=5 and DruidData.TEST_BUILDS.any(func(build):return "druid_l18_3" in build.get("talents",{}).values()),"Druid should expose the complete talent tree, five representative builds, and a Nature's Cure build.")
	return errors
