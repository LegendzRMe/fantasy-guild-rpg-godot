extends RefCounted

const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func unit(hp:float=100.0,armor:float=0.0,crit:float=0.0)->Dictionary:
	return {"level":1,"hp":hp,"max_hp":hp,"shield":0.0,"shield_sources":[],"armor":armor,"critical_chance":crit,"critical_damage":2.0,"damage_multiplier":1.0,"healing_multiplier":1.0,"damage_taken_multiplier":1.0,"healing_taken_multiplier":1.0,"active_effects":[],"passive_cooldowns":{},"equipped_items":[]}

static func run()->Array:
	var errors:=[]
	TestSupport.check(errors,CombatSystem.LEVEL_CAP==30 and CombatSystem.clamp_level(99)==30,"The combat level cap should be centralized at 30.")
	var expected_level_four_health:=2765.0*pow(1.04,3)
	var expected_level_four_power:=88.0*pow(1.04,3)
	var level_stats:=CombatSystem.calculate_final_stats(GameData.CLASSES.Guardian,4,[])
	TestSupport.check(errors,is_equal_approx(level_stats.health,expected_level_four_health) and is_equal_approx(level_stats.power,expected_level_four_power),"Guardian Health and Power should use its source four-percent exponential level growth.")
	var capped_stats:=CombatSystem.calculate_final_stats(GameData.CLASSES.Guardian,99,[])
	TestSupport.check(errors,capped_stats.level==30 and is_equal_approx(capped_stats.health,2765.0*pow(1.04,29)),"Final stat calculation should clamp levels before applying growth.")

	var bulwark:=ItemData.create_instance("ashwood_bulwark","bulwark_test")
	var guardian_stats:=CombatSystem.calculate_final_stats(GameData.CLASSES.Guardian,1,[bulwark])
	TestSupport.check(errors,guardian_stats.health==2765.0 and guardian_stats.power==88.0 and guardian_stats.armor==20.0,"Final stats should combine Guardian source bases and equipment modifiers.")
	var layered_stats:=CombatSystem.calculate_final_stats(GameData.CLASSES.Guardian,1,[bulwark],[{"stat_modifiers":{"power":2.0,"movement_speed_multiplier":1.1}}],[{"stat_modifiers":{"armor":5.0,"movement_speed_multiplier":0.8}}])
	TestSupport.check(errors,layered_stats.power==90.0 and layered_stats.armor==15.0 and is_equal_approx(layered_stats.movement_speed,118.8) and layered_stats.basic_action_amount==90.0,"Equipment, buffs, and debuffs should resolve before derived Basic Action values.")

	var ashfang:=ItemData.create_instance("test_ashfang_knives","ashfang_test")
	var stormbreaker:=ItemData.create_instance("test_stormbreaker","stormbreaker_test")
	var rapid_stats:=CombatSystem.calculate_final_stats(GameData.CLASSES.Rogue,1,[ashfang])
	var heavy_stats:=CombatSystem.calculate_final_stats(GameData.CLASSES.Guardian,1,[stormbreaker])
	TestSupport.check(errors,is_equal_approx(rapid_stats.weapon_amount_multiplier,0.8) and is_equal_approx(rapid_stats.weapon_interval_multiplier,0.8),"Dual-wield weapons should use the rapid Basic Action profile.")
	TestSupport.check(errors,is_equal_approx(heavy_stats.weapon_amount_multiplier,1.25) and is_equal_approx(heavy_stats.weapon_interval_multiplier,1.25),"Two-handed weapons should use the heavy Basic Action profile.")
	TestSupport.check(errors,rapid_stats.basic_action_amount>GameData.CLASSES.Rogue.base_power and heavy_stats.basic_action_amount>GameData.CLASSES.Guardian.base_power,"Weapon Power and weapon profiles should change Basic Action results.")

	var source:=unit(100,0,0);var armored:=unit(100,100,0)
	var physical:=CombatSystem.resolve_damage(source,armored,{"amount":40.0,"source_action":"basic_attack","damage_type":"physical"},0.9)
	var expected_reduction:=100.0/(100.0+110.0)
	TestSupport.check(errors,is_equal_approx(physical.armor_reduction,expected_reduction) and is_equal_approx(physical.health_damage,40.0*(1.0-expected_reduction)),"Armor should use the attacker-level constant and reduce non-true damage.")
	TestSupport.check(errors,is_equal_approx(CombatSystem.calculate_armor_reduction(100000.0,30),0.75),"Armor reduction should respect the 75-percent cap.")
	var true_target:=unit(100,100,0);source.critical_chance=1.0
	var true_result:=CombatSystem.resolve_damage(source,true_target,{"amount":40.0,"source_action":"basic_attack","damage_type":"true"},0.0)
	TestSupport.check(errors,true_result.health_damage==40.0 and not true_result.critical,"True Damage should ignore Armor and not critically strike by default.")

	var shielded:=unit();CombatSystem.apply_shield(shielded,30.0,{"source_id":"test_ward","creator_index":2})
	var shield_result:=CombatSystem.resolve_damage(unit(),shielded,{"amount":40.0,"source_action":"basic_attack","damage_type":"physical"},0.9)
	TestSupport.check(errors,shield_result.shield_damage==30.0 and shield_result.health_damage==10.0 and shield_result.shield_absorptions[0].creator_index==2,"Damage should remove sourced Shields before Health and report the Shield creator.")
	var layered_health:=unit();layered_health.temporary_hp=30.0;CombatSystem.apply_shield(layered_health,20.0,{"source_id":"layered_ward"})
	var layered_first:=CombatSystem.resolve_damage(unit(),layered_health,{"amount":40.0,"source_action":"basic_attack","damage_type":"physical"},0.9)
	var layered_second:=CombatSystem.resolve_damage(unit(),layered_health,{"amount":20.0,"source_action":"basic_attack","damage_type":"physical"},0.9)
	TestSupport.check(errors,layered_first.shield_damage==20.0 and layered_first.temporary_hp_damage==20.0 and layered_first.health_damage==0.0 and layered_second.temporary_hp_damage==10.0 and layered_second.health_damage==10.0 and layered_health.hp==90.0,"Damage should remove Shields, then temporary HP, then regular Health.")
	var critical_target:=unit();source.critical_chance=1.0
	var critical_damage:=CombatSystem.resolve_damage(source,critical_target,{"amount":10.0,"source_action":"basic_attack","damage_type":"physical"},0.0)
	TestSupport.check(errors,critical_damage.critical and critical_damage.health_damage==20.0,"Direct eligible damage should use the default 200-percent critical multiplier.")

	var healing_target:=unit();healing_target.hp=95.0
	var direct_heal:=CombatSystem.resolve_healing(source,healing_target,{"amount":10.0,"source_action":"basic_ability"},0.0)
	TestSupport.check(errors,direct_heal.critical and direct_heal.effective_amount==5.0 and direct_heal.overhealing==15.0,"Healing should report effective healing and overhealing after critical resolution.")
	healing_target.hp=20.0
	var periodic_heal:=CombatSystem.resolve_healing(source,healing_target,{"amount":10.0,"source_action":"periodic"},0.0)
	TestSupport.check(errors,not periodic_heal.critical and periodic_heal.effective_amount==10.0,"Periodic healing should not critically heal by default.")
	var negative_damage_target:=unit(100,0,0);negative_damage_target.shield=10.0
	var negative_damage:=CombatSystem.resolve_damage(source,negative_damage_target,{"amount":5.0,"flat_bonus":-20.0,"source_action":"basic_attack"},0.9)
	TestSupport.check(errors,negative_damage.resolved_damage==0.0 and negative_damage_target.hp==100.0 and negative_damage_target.shield==10.0,"Negative damage modifiers should resolve to zero without creating Shields or changing Health.")
	var negative_heal_target:=unit();negative_heal_target.hp=50.0
	var negative_heal:=CombatSystem.resolve_healing(source,negative_heal_target,{"amount":5.0,"flat_bonus":-20.0,"source_action":"basic_heal"},0.9)
	TestSupport.check(errors,negative_heal.effective_amount==0.0 and negative_heal_target.hp==50.0,"Negative healing modifiers should resolve to zero without damaging the target.")

	var focus:=ItemData.create_instance("cinderlight_focus","focus_test")
	var cleric_focus_stats:=CombatSystem.calculate_final_stats(GameData.CLASSES.Cleric,1,[focus])
	TestSupport.check(errors,cleric_focus_stats.power==63.0 and cleric_focus_stats.basic_action_type=="heal" and cleric_focus_stats.basic_action_amount==63.0 and cleric_focus_stats.basic_heal_amount==63.0 and is_equal_approx(cleric_focus_stats.critical_chance,0.13),"Power should scale a Cleric's canonical Basic Heal while Critical Chance resolves independently.")
	TestSupport.check(errors,ItemData.can_equip(bulwark,GameData.CLASSES.Guardian,"Guardian") and not ItemData.can_equip(bulwark,GameData.CLASSES.Cleric,"Cleric"),"Armor equipment should enforce armor-family requirements.")
	TestSupport.check(errors,ItemData.can_equip(focus,GameData.CLASSES.Cleric,"Cleric") and ItemData.can_equip(focus,GameData.CLASSES.Mage,"Mage") and not ItemData.can_equip(ashfang,GameData.CLASSES.Mage,"Mage"),"Weapons should enforce each class's declared proficiency list.")
	TestSupport.check(errors,ItemData.can_equip(stormbreaker,GameData.CLASSES.Guardian,"Guardian"),"Stormbreaker should keep its explicit Guardian testing compatibility.")
	TestSupport.check(errors,ItemData.item_tooltip(focus).contains("Grace") and ItemData.item_tooltip(ItemData.create_instance("test_soul_furnace","tooltip_soul")).contains("Soul Furnace"),"Item tooltips should expose named passive effects.")

	var tagged_target:=unit();var tagged_result:=CombatSystem.resolve_damage(unit(),tagged_target,{"amount":5.0,"source_action":"basic_attack","damage_type":"physical"},0.9)
	var tagged_events:=CombatSystem.event_bundle_for_damage(source,tagged_target,tagged_result,{"action_tags":["basic_attack"],"origin":"test_attack"})
	TestSupport.check(errors,tagged_events.any(func(event):return event.event_type=="basic_attack_hit" and "basic_action" in event.action_tags and "physical" in event.action_tags and event.origin=="test_attack"),"Basic Attack events should retain exact and shared Basic Action tags.")
	var basic_heal_target:=unit();basic_heal_target.hp=50.0
	var basic_heal_result:=CombatSystem.resolve_healing(source,basic_heal_target,{"amount":10.0,"source_action":"basic_heal"},0.0)
	var basic_heal_events:=CombatSystem.event_bundle_for_healing(source,basic_heal_target,basic_heal_result,{"origin":"test_basic_heal"})
	TestSupport.check(errors,basic_heal_events.any(func(event):return event.event_type=="basic_heal_done" and event.source_action=="basic_heal" and "basic_action" in event.action_tags),"Basic Heals should remain distinct while carrying the Basic Action grouping tag.")
	TestSupport.check(errors,"basic_heal" in CombatSystem.ACTION_SOURCES and "basic_action" not in CombatSystem.ACTION_SOURCES,"Basic Action should remain a grouping term, not a source action.")

	var crossing_event:={"event_type":"damage_taken","action_tags":["physical","damage"],"originating_effect_id":"","trigger_chain":[],"source_is_summon":false,"crossed_below_half":true}
	var non_crossing_event:=crossing_event.duplicate(true);non_crossing_event.crossed_below_half=false
	var dawn:=ItemData.create_instance("test_aegis_last_dawn","dawn_test")
	TestSupport.check(errors,CombatSystem.evaluate_passives(unit(),crossing_event,[dawn],ItemData.PASSIVE_EFFECTS,0.0,0.0).size()==1 and CombatSystem.evaluate_passives(unit(),non_crossing_event,[dawn],ItemData.PASSIVE_EFFECTS,0.0,0.0).is_empty(),"Last Dawn should trigger only on an above-to-below-half Health crossing.")
	var recursive_event:={"event_type":"basic_attack_hit","action_tags":["basic_attack","basic_action","physical"],"originating_effect_id":"bloodletting","trigger_chain":[],"source_is_summon":false}
	TestSupport.check(errors,CombatSystem.evaluate_passives(unit(),recursive_event,[ashfang],ItemData.PASSIVE_EFFECTS,0.0,0.0).is_empty(),"An item effect should never recursively trigger itself.")
	var proc_event:=recursive_event.duplicate(true);proc_event.originating_effect_id=""
	TestSupport.check(errors,CombatSystem.evaluate_passives(unit(),proc_event,[ashfang],ItemData.PASSIVE_EFFECTS,0.0,0.34).size()==1 and CombatSystem.evaluate_passives(unit(),proc_event,[ashfang],ItemData.PASSIVE_EFFECTS,0.0,0.36).is_empty(),"Bloodletting should use its authored 35-percent per-hit proc chance without speed normalization.")
	var zero_chance_passives:=ItemData.PASSIVE_EFFECTS.duplicate(true);zero_chance_passives.bloodletting=zero_chance_passives.bloodletting.duplicate(true);zero_chance_passives.bloodletting.chance=0.0
	TestSupport.check(errors,CombatSystem.evaluate_passives(unit(),proc_event,[ashfang],zero_chance_passives,0.0,0.0).is_empty(),"A zero-percent passive should never trigger, including on an exact zero roll.")
	var borrowed:=ItemData.create_instance("test_mirror_borrowed_time","borrowed_test");var cast_event:={"event_type":"basic_ability_cast","action_tags":["basic_ability"],"originating_effect_id":"","trigger_chain":[],"source_is_summon":false};var cooldown_unit:=unit()
	var first_borrowed:=CombatSystem.evaluate_passives(cooldown_unit,cast_event,[borrowed],ItemData.PASSIVE_EFFECTS,0.0,0.0);var blocked_borrowed:=CombatSystem.evaluate_passives(cooldown_unit,cast_event,[borrowed],ItemData.PASSIVE_EFFECTS,4.0,0.0);var ready_borrowed:=CombatSystem.evaluate_passives(cooldown_unit,cast_event,[borrowed],ItemData.PASSIVE_EFFECTS,8.0,0.0)
	TestSupport.check(errors,first_borrowed.size()==1 and blocked_borrowed.is_empty() and ready_borrowed.size()==1,"Passive internal cooldowns should be tracked independently per item.")
	var stacked:=CombatSystem.apply_named_effect([{"id":"ward","amount":5.0,"remaining_duration":2.0}],{"id":"ward","amount":3.0,"remaining_duration":6.0})
	TestSupport.check(errors,stacked.size()==1 and stacked[0].amount==5.0 and stacked[0].remaining_duration==6.0,"Identical named effects should keep the strongest value and refresh duration.")
	var charges:=CombatSystem.store_charge([{"amount":10.0},{"amount":20.0},{"amount":30.0}],25.0,3)
	TestSupport.check(errors,charges.map(func(charge):return charge.amount)==[20.0,30.0,25.0],"Retribution should replace the smallest stored charge and append the replacement as the newest charge.")
	TestSupport.check(errors,CombatSystem.damage_threat({"resolved_damage":50.0},5.0)==250.0 and CombatSystem.healing_threat({"effective_amount":40.0})==20.0 and CombatSystem.distributed_threat(20.0,4)==5.0,"Damage, healing, and distributed threat helpers should use the canonical ratios.")
	TestSupport.check(errors,CombatSystem.required_aggro_threat(100.0,true)==110.00000000000001 or is_equal_approx(CombatSystem.required_aggro_threat(100.0,true),110.0),"Nearby attackers should pull aggro at 110 percent.")
	TestSupport.check(errors,is_equal_approx(CombatSystem.required_aggro_threat(100.0,false),130.0),"Distant attackers should pull aggro at 130 percent.")

	var testing:=SaveManager.testing_state()
	TestSupport.check(errors,testing.item_instances.size()==10 and ItemData.TESTING_DEFINITION_IDS.all(func(id):return testing.item_instances.any(func(item):return item.definition_id==id)),"The testing save should seed one copy of every required Legendary item.")
	TestSupport.check(errors,SaveManager.fresh_state().item_instances.is_empty() and ItemData.seed_testing_instances(ItemData.seed_testing_instances([])).size()==10,"Normal saves should receive no test items and repeated testing seeding should not create duplicates.")
	var duplicate_vault:=ItemData.create_instance("test_ashfang_knives","duplicate_vault");var duplicate_equipped:=ItemData.create_instance("test_ashfang_knives","duplicate_equipped");duplicate_equipped.owner_state="equipped";duplicate_equipped.equipped_hero_index=4
	var deduplicated:=ItemData.seed_testing_instances([duplicate_vault,duplicate_equipped])
	TestSupport.check(errors,deduplicated.size()==10 and deduplicated.any(func(item):return item.instance_id=="duplicate_equipped"),"Testing-item deduplication should preserve an equipped instance in preference to a duplicate Vault copy.")
	TestSupport.check(errors,testing.heroes.all(func(hero):return hero.equipment_slots.values().all(func(value):return value==null)),"Testing items should begin unequipped.")
	var equip_result:=ItemData.equip_in_state(testing,4,"testing_test_ashfang_knives",GameData.CLASSES)
	TestSupport.check(errors,equip_result.success and testing.heroes[4].equipment_slots.weapon=="testing_test_ashfang_knives" and testing.item_instances.any(func(item):return item.instance_id=="testing_test_ashfang_knives" and item.owner_state=="equipped" and item.equipped_hero_index==4),"Equipment ownership should move atomically from Vault to hero slot.")
	testing.heroes[0].equipment_slots.weapon="testing_test_ashfang_knives";ItemData.reconcile_ownership(testing)
	TestSupport.check(errors,testing.heroes[0].equipment_slots.weapon=="testing_test_ashfang_knives" and testing.heroes[4].equipment_slots.weapon==null,"Ownership reconciliation should clear duplicate references so one instance cannot be equipped twice.")

	var legacy:=SaveManager.fresh_state();legacy.heroes[0].erase("equipment_slots");legacy.heroes[0].erase("prestige_rank");legacy.heroes[0].legacy_rank=2;legacy.erase("item_instances");legacy.heroes[0].gear=999
	var migrated:=SaveManager.migrate_state(legacy,true)
	TestSupport.check(errors,migrated.heroes[0].equipment_slots.size()==6 and migrated.has("item_instances") and migrated.heroes[0].prestige_rank==2,"Save migration should add equipment and canonical Prestige fields without losing legacy values.")
	TestSupport.check(errors,migrated.heroes[0].gear==999,"Legacy Gear Score should remain serialized but no longer affect combat resolution.")
	return errors
