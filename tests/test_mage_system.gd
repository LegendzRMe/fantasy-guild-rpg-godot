extends RefCounted

const AbilityPowerSystem = preload("res://scripts/systems/ability_power_system.gd")
const LivingBombLineageSystem = preload("res://scripts/systems/living_bomb_lineage_system.gd")
const MageAbilityPresenter = preload("res://scripts/data/mage_ability_presenter.gd")
const MageData = preload("res://scripts/data/mage_data.gd")
const MageSystem = preload("res://scripts/systems/mage_system.gd")
const StatusEffectSystem = preload("res://scripts/systems/status_effect_system.gd")
const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func mage(talents:Array=[])->Dictionary:
	var selected:={}
	for index in talents.size():selected["tier_%d"%(index+1)]=talents[index]
	var hero:={"class":"Mage","combat_id":"hero:mage","level":1,"hp":1595.0,"max_hp":1595.0,"power":65.0,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"selected_talents":selected,"active_effects":[]}
	MageSystem.initialize_runtime(hero,true);return hero

static func run()->Array:
	var errors:=[];var definition:Dictionary=MageData.CLASS_DEFINITION
	TestSupport.check(errors,definition.base_health==1595.0 and definition.base_power==65.0 and is_equal_approx(1.0/float(definition.basic_action_interval),1.11) and definition.base_armor==0.0,"Mage V1 should expose the locked Level 1 chassis.")
	TestSupport.check(errors,definition.basic_action_damage_type=="physical" and is_equal_approx(float(definition.basic_action_range),185.0),"Mage Basic Attacks should be physical ranged actions at the shared source-to-world range.")
	TestSupport.check(errors,is_equal_approx(MageData.scaled(100.0,4),100.0*pow(1.04,3)) and is_equal_approx(MageData.pyro_scaled(100.0,4),100.0*pow(1.05,3)),"Mage normal and Pyroblast scaling should remain separate and deterministic.")
	var tiers:Array=definition.talent_tier_definitions
	TestSupport.check(errors,tiers.size()==8 and tiers[0].unlock_level==9 and tiers[2].option_ids==["mage_l15_r1","mage_l15_r2"] and tiers[6].heroic_requirements.mage_l27_r2=="mage_l15_r2","Mage should expose the approved eight-tier talent tree and matching Heroic upgrades.")
	var power_hero:=mage(["mage_l9_2"]);power_hero.mage_runtime.arcane_dynamo_stacks=5;power_hero.mage_runtime.arcane_dynamo_remaining=5.0;power_hero.mage_runtime.sunfire_power_remaining=10.0
	TestSupport.check(errors,is_equal_approx(MageSystem.refresh_ability_power(power_hero),0.24) and is_equal_approx(AbilityPowerSystem.apply(100.0,power_hero),124.0),"Ability Power sources should stack additively and apply after the base ability amount.")
	var raw_power_hero:=mage();raw_power_hero.power=130.0;TestSupport.check(errors,is_equal_approx(MageSystem.scaled_ability_amount(raw_power_hero,345.0),690.0),"Mage ability amounts should apply current raw Power before Ability Power.")
	var trait_hero:=mage();TestSupport.check(errors,MageSystem.activate_trait(trait_hero) and MageSystem.trait_is_armed(trait_hero) and trait_hero.mage_runtime.trait.recharge_timers.is_empty(),"Verdant Spheres should arm without beginning its ordinary recharge.")
	TestSupport.check(errors,MageSystem.consume_empowerment(trait_hero,"Q") and trait_hero.mage_runtime.trait.recharge_timers.size()==1,"Ordinary Verdant Spheres recharge should begin after the empowered ability consumes it.")
	MageSystem.update(trait_hero,6.0);TestSupport.check(errors,trait_hero.mage_runtime.trait.current_charges==1,"Verdant Spheres should restore its sequential charge after six seconds.")
	var mana_tap:=mage(["","mage_l12_2"]);MageSystem.activate_trait(mana_tap);TestSupport.check(errors,mana_tap.mage_runtime.trait.recharge_timers.size()==1,"Mana Tap should begin recharge when Verdant Spheres is activated.")
	var twin:=mage(["","","","","","mage_l24_3"]);TestSupport.check(errors,twin.mage_runtime.trait.max_charges==2 and twin.mage_runtime.trait.current_charges==2,"Twin Spheres should store two sequential charges.")
	MageSystem.activate_trait(twin);MageSystem.consume_empowerment(twin,"Q");MageSystem.activate_trait(twin);MageSystem.consume_empowerment(twin,"W");TestSupport.check(errors,twin.mage_runtime.trait.current_charges==0 and twin.mage_runtime.trait.recharge_timers.size()==1,"Twin Spheres should spend sequential charges without starting parallel recharge timers.")
	MageSystem.update(twin,12.1);TestSupport.check(errors,twin.mage_runtime.trait.current_charges==2 and twin.mage_runtime.trait.recharge_timers.is_empty(),"Twin Spheres should restore both missing charges sequentially across two recharge periods.")
	var dynamo:=mage(["","mage_l12_3"]);for cast_index in 7:MageSystem.commit_basic_ability(dynamo)
	TestSupport.check(errors,dynamo.mage_runtime.arcane_dynamo_stacks==5 and is_equal_approx(MageSystem.refresh_ability_power(dynamo),0.05),"Arcane Dynamo should cap at five additive one-percent stacks.")
	var convection:=mage(["mage_l9_1"]);var reward:=MageSystem.add_convection_hits(convection,40)
	TestSupport.check(errors,reward.completions==2 and convection.max_hp==1795.0 and convection.mage_runtime.convection_bonus_damage==400.0,"Convection should repeat every twenty encounter-scoped qualifying hits.")
	convection.level=4;convection.power=MageData.scaled(65.0,4);TestSupport.check(errors,is_equal_approx(MageSystem.flamestrike_amount(convection),MageData.scaled(345.0,4)+400.0),"Convection's flat encounter reward should not receive level scaling and should benefit only future Flamestrike resolutions.")
	var barrier:=mage(["mage_l9_3"]);var barrier_result:=MageSystem.try_arcane_barrier(barrier,true)
	TestSupport.check(errors,barrier_result.triggered and is_equal_approx(float(barrier_result.shield),797.5) and not MageSystem.try_arcane_barrier(barrier,true).triggered,"Arcane Barrier should automatically create a 50% maximum-Health shield before lethal damage and enter cooldown.")
	var ordinary:={"max_hp":1000.0};var boss:={"boss":true,"max_hp":5000.0,"percent_damage_health_basis":4000.0}
	TestSupport.check(errors,MageSystem.burned_flesh_request(ordinary).amount==80.0 and MageSystem.burned_flesh_request(boss).amount==160.0,"Burned Flesh should use eight percent for ordinary targets and four percent of the explicit Boss health basis.")
	var boss_control:={"boss":true,"active_effects":[]};var stun:=StatusEffectSystem.apply_control(boss_control,"stun",1.5)
	TestSupport.check(errors,not stun.applied and stun.resisted,"Bosses should collide with control but resist Stun by default.")
	var vulnerable_boss:={"boss":true,"control_profile":{"stun_multiplier":0.25},"active_effects":[]};var reduced_stun:=StatusEffectSystem.apply_control(vulnerable_boss,"stun",2.0)
	TestSupport.check(errors,reduced_stun.applied and is_equal_approx(float(reduced_stun.duration),0.5),"An explicit Boss control profile should permit a reduced Stun.")
	var gravity_target:={"combat_id":"enemy:gravity","active_effects":[{"id":"mage_gravity_crush","owner_id":"hero:mage","remaining_duration":4.0}]}
	TestSupport.check(errors,MageSystem.gravity_crush_applies(raw_power_hero,gravity_target,"basic_attack") and MageSystem.gravity_crush_applies(raw_power_hero,gravity_target,"basic_ability") and not MageSystem.gravity_crush_applies(raw_power_hero,gravity_target,"percentage_health") and not MageSystem.gravity_crush_applies(raw_power_hero,gravity_target,"basic_ability","item_proc"),"Gravity Crush should include Mage-owned normal damage but exclude percentage and item-effect damage.")
	var lineage:=LivingBombLineageSystem.create_state();var first:=LivingBombLineageSystem.create_primary(lineage,"hero:mage","enemy:a");var removed:=LivingBombLineageSystem.remove_bomb(lineage,"enemy:a",true);var spread:=LivingBombLineageSystem.create_spread(lineage,removed,"enemy:b",3.0,true)
	TestSupport.check(errors,not spread.is_empty() and not LivingBombLineageSystem.can_infect_from(lineage,spread,"enemy:a"),"Living Bomb lineage should survive parent detonation and prevent reinfection.")
	LivingBombLineageSystem.remove_bomb(lineage,"enemy:b",true);LivingBombLineageSystem.cleanup_lineage(lineage,str(first.lineage_id));TestSupport.check(errors,lineage.lineages.is_empty(),"Completed Living Bomb lineages should clean up after the final active bomb.")
	var presenter:=MageAbilityPresenter.details(mage(),"Q");TestSupport.check(errors,str(presenter.description).contains("345") and not str(presenter.description).contains("345."),"Mage player-facing damage should be rounded down to whole numbers.")
	TestSupport.check(errors,MageData.VALUES.presence_event_ceiling==5 and MageData.VALUES.rebirth_charges==3 and not MageData.VALUES.rebirth_path_damage_on_reposition,"Presence and Rebirth limits should stay explicit and the unverified reposition path-damage behavior should remain disabled by configuration.")
	return errors
