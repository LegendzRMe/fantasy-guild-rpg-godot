extends RefCounted

const SpiritWeaverData=preload("res://scripts/data/spiritweaver_data.gd")
const SpiritWeaverSystem=preload("res://scripts/systems/spiritweaver_system.gd")
const StatusEffectSystem=preload("res://scripts/systems/status_effect_system.gd")
const TestSupport=preload("res://tests/test_support.gd")

static func hero(talents:Dictionary={},heroic:String="spiritweaver_l15_r1",level:int=1,id:String="hero:spiritweaver")->Dictionary:
	var maximum:=SpiritWeaverData.scaled(float(SpiritWeaverData.VALUES.health),level)
	var unit:={"class":"Spirit Weaver","combat_id":id,"level":level,"hp":maximum,"max_hp":maximum,"selected_talents":talents,"selected_heroic_id":heroic,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"active_effects":[],"base_basic_action_interval":float(SpiritWeaverData.VALUES.basic_attack_interval)}
	SpiritWeaverSystem.initialize_runtime(unit,true)
	return unit

static func run()->Array:
	var errors:Array=[]
	var definition:=SpiritWeaverData.CLASS_DEFINITION
	TestSupport.check(errors,str(definition.primary_role)=="Healer" and not bool(definition.uses_mana) and str(definition.resource_id)=="","Spirit Weaver should be a resource-free Healer.")
	TestSupport.check(errors,is_equal_approx(float(definition.base_health),1900.0) and is_equal_approx(float(definition.base_power),110.0) and is_equal_approx(float(definition.basic_action_interval),.9) and is_equal_approx(float(definition.basic_action_range),1.5*SpiritWeaverData.SOURCE_TO_WORLD),"Spirit Weaver should retain the audited Rehgar melee chassis.")
	TestSupport.check(errors,SpiritWeaverData.TALENT_TIERS.size()==8 and SpiritWeaverData.TALENT_TIERS.reduce(func(total,tier):return total+tier.option_ids.size(),0)==22 and SpiritWeaverData.TEST_BUILDS.size()==4,"Spirit Weaver should expose eight tiers, twenty-two choices, and four focused Range builds.")
	TestSupport.check(errors,SpiritWeaverData.TALENT_TIERS[6].heroic_requirements=={"spiritweaver_l27_r1":"spiritweaver_l15_r1","spiritweaver_l27_r2":"spiritweaver_l15_r2"},"Spirit Weaver Heroic upgrades should require their matching Heroic.")
	for level in [1,15,30]:
		var factor:=pow(1.04,level-1)
		TestSupport.check(errors,is_equal_approx(SpiritWeaverData.scaled(1900.0,level),1900.0*factor) and is_equal_approx(SpiritWeaverData.scaled(110.0,level),110.0*factor) and is_equal_approx(SpiritWeaverData.scaled(60.0,level),60.0*factor) and is_equal_approx(SpiritWeaverData.scaled(260.0,level),260.0*factor),"Health, attack, Basic Heal, and Chain Heal should use 4%% scaling at Level %d."%level)
		TestSupport.check(errors,is_equal_approx(SpiritWeaverData.scaled(64.0,level),64.0*factor) and is_equal_approx(SpiritWeaverData.scaled(160.0,level),160.0*factor) and is_equal_approx(SpiritWeaverData.scaled(1180.0,level),1180.0*factor) and is_equal_approx(SpiritWeaverData.scaled(90.0,level),90.0*factor),"W, Earthliving, Ancestral, and Earthgrasp should scale at Level %d."%level)
	var baseline:=hero()
	TestSupport.check(errors,not bool(baseline.spiritweaver_runtime.wolf_active) and not SpiritWeaverSystem.advance_wolf(baseline,2.99) and SpiritWeaverSystem.advance_wolf(baseline,.01) and bool(baseline.spiritweaver_runtime.wolf_active),"Automatic Ghost Wolf should enter after exactly three inactive seconds.")
	TestSupport.check(errors,is_equal_approx(SpiritWeaverSystem.movement_multiplier(baseline),1.20),"Baseline Ghost Wolf should grant 20% movement speed.")
	SpiritWeaverSystem.note_action(baseline);TestSupport.check(errors,not bool(baseline.spiritweaver_runtime.wolf_active) and is_zero_approx(float(baseline.spiritweaver_runtime.wolf_timer)),"A committed personal action should exit Wolf and reset its timer.")
	var feral:=hero({"tier_1":"spiritweaver_l9_3"});SpiritWeaverSystem.advance_wolf(feral,3.0);TestSupport.check(errors,is_equal_approx(SpiritWeaverSystem.movement_multiplier(feral),1.40),"Feral Heart should grant 40% movement during Wolf's first second.");SpiritWeaverSystem.advance_wolf(feral,1.0);TestSupport.check(errors,is_equal_approx(SpiritWeaverSystem.movement_multiplier(feral),1.30),"Feral Heart should settle to 30% movement after the first second.")
	var rising:=hero({"tier_1":"spiritweaver_l9_1","tier_6":"spiritweaver_l24_1"});var bearer:={"combat_id":"ally:a","hp":1000.0,"max_hp":1000.0};var shield:=SpiritWeaverSystem.create_w(rising,"ally:a");for contact in 20:SpiritWeaverSystem.note_w_contact(rising,shield,bearer,32.0)
	TestSupport.check(errors,int(shield.stacks)==15 and is_equal_approx(float(bearer.max_hp),1040.0) and int(rising.spiritweaver_runtime.stormcaller["ally:a"])==20,"Rising Storm should cap per-instance damage stacks at 15 while Stormcaller keeps its separate Hero stack count.")
	for contact in 180:SpiritWeaverSystem.note_w_contact(rising,shield,bearer,32.0)
	TestSupport.check(errors,int(rising.spiritweaver_runtime.stormcaller["ally:a"])==200 and is_equal_approx(float(bearer.max_hp),1400.0),"Stormcaller should cap at 200 contacts and +400 encounter maximum Health without healing current Health.")
	var category_quest:=hero({"tier_1":"spiritweaver_l9_1"});var category_bearer:={"combat_id":"ally:q","hp":1000.0,"max_hp":1000.0};var category_w:=SpiritWeaverSystem.create_w(category_quest,"ally:q");SpiritWeaverSystem.note_w_contact(category_quest,category_w,category_bearer,32.0,{"target_category":"summon"});TestSupport.check(errors,category_quest.spiritweaver_runtime.stormcaller.is_empty(),"Disposable summoned trash should not advance Stormcaller progression.")
	var colossal:=hero({"tier_1":"spiritweaver_l9_2","tier_2":"spiritweaver_l12_3","tier_4":"spiritweaver_l18_1","tier_5":"spiritweaver_l21_3","tier_6":"spiritweaver_l24_2"});var totem:=SpiritWeaverSystem.create_totem(colossal,Vector2(100,100))
	TestSupport.check(errors,bool(totem.healing) and is_equal_approx(float(totem.remaining),10.0) and is_equal_approx(float(totem.max_hp),260.0*1.25) and is_equal_approx(SpiritWeaverSystem.totem_radius(colossal),float(SpiritWeaverData.SPACE.e_radius)*1.5),"Healing and Colossal Totem should compose duration, baseline Health override, and radius correctly.")
	var events:=SpiritWeaverSystem.advance(colossal,2.0);TestSupport.check(errors,events.any(func(event):return str(event.kind)=="totem_heal") and events.any(func(event):return str(event.kind)=="wellspring") and events.any(func(event):return str(event.kind)=="totem_slow"),"Healing Totem, Wellspring, and Earthbind Slow should remain separate simultaneous events.")
	var totem_shield:=SpiritWeaverSystem.create_w(colossal,str(totem.combat_id),true);SpiritWeaverSystem.note_w_contact(colossal,totem_shield,totem,32.0);TestSupport.check(errors,colossal.spiritweaver_runtime.stormcaller.is_empty(),"A Totem-borne Lightning Shield must never gain Stormcaller maximum Health.")
	var purge:=hero({"tier_8":"spiritweaver_l30_3"});purge.ability_cds[4]=60.0;TestSupport.check(errors,is_equal_approx(SpiritWeaverSystem.purge_recharge_rate(purge),1.5),"Cleansing Tempest should be a 1.5x recharge rate, not a flat cooldown replacement.")
	var enemy:={"active_effects":[{"id":"positive","beneficial":true,"dispellable":true,"remaining_duration":5.0},{"id":"scripted","beneficial":true,"dispellable":false,"remaining_duration":5.0}]};var removed:=StatusEffectSystem.remove_dispellable_positive_effects(enemy);TestSupport.check(errors,removed==["positive"] and enemy.active_effects.size()==1 and str(enemy.active_effects[0].id)=="scripted","Purge's shared dispel should remove only explicitly beneficial, dispellable effects.")
	var controlled:={"active_effects":[{"id":"ordinary_root","control_type":"root","remaining_duration":3.0},{"id":"uncleansable_stun","control_type":"stun","cleansable":false,"remaining_duration":3.0},{"id":"scripted_fear","control_type":"fear","scripted":true,"remaining_duration":3.0}]};var controls_removed:=StatusEffectSystem.remove_removable_controls(controlled);TestSupport.check(errors,controls_removed==["root"] and controlled.active_effects.size()==2,"Purge should retain controls explicitly marked uncleansable or scripted.")
	var first:=hero({},"spiritweaver_l15_r1",1,"hero:first");var second:=hero({},"spiritweaver_l15_r1",1,"hero:second");SpiritWeaverSystem.create_w(first,"ally:a");SpiritWeaverSystem.create_totem(first,Vector2.ZERO);TestSupport.check(errors,second.spiritweaver_runtime.lightning_shields.is_empty() and second.spiritweaver_runtime.totem.is_empty(),"Multiple Spirit Weavers should retain isolated W and Totem ownership.")
	return errors
