extends RefCounted

const TestSupport=preload("res://tests/test_support.gd")
const ProtectorData=preload("res://scripts/data/protector_data.gd")
const ProtectorSystem=preload("res://scripts/systems/protector_system.gd")
const GuardianData=preload("res://scripts/data/guardian_data.gd")
const TemplarData=preload("res://scripts/data/templar_data.gd")
const CombatBalanceData=preload("res://scripts/data/combat_balance_data.gd")
const CombatGeometry=preload("res://scripts/combat/combat_geometry.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")

static func unit(talents:Dictionary={})->Dictionary:
	var hero:={"class":"Protector","combat_id":"hero:protector","battle_index":0,"level":1,"power":65.0,"base_power":65.0,"hp":1850.0,"max_hp":1850.0,"armor":0.0,"pos":Vector2(300,300),"range":float(ProtectorData.SPACE.basic_range),"selected_talents":talents,"selected_heroic_id":str(talents.get("tier_3","")),"ability_cds":[0.0,0.0,0.0,0.0,0.0],"active_effects":[]}
	ProtectorSystem.initialize_runtime(hero,true)
	return hero

static func run()->Array:
	var errors:Array=[]
	var definition:Dictionary=ProtectorData.CLASS_DEFINITION
	TestSupport.check(errors,is_equal_approx(float(definition.base_health),1850.0) and is_equal_approx(float(definition.base_armor),0.0),"Protector should preserve the locked fragile Level-1 chassis.")
	TestSupport.check(errors,is_equal_approx(float(definition.base_power),65.0) and is_equal_approx(float(definition.basic_action_interval),1.0),"Protector should use a 65 Physical Basic Attack at an approximately one-second interval.")
	TestSupport.check(errors,is_equal_approx(float(definition.basic_action_range),3.75*float(ProtectorData.SPACE.source_to_world)),"Protector Basic Attack range should convert exactly 3.75 source units.")
	TestSupport.check(errors,is_equal_approx(ProtectorData.scaled(100.0,2),104.0) and not bool(definition.uses_mana) and str(definition.resource_id)=="","Protector should scale at 4% and remain resource-free.")
	TestSupport.check(errors,is_equal_approx(float(CombatBalanceData.TANK_THREAT_MODIFIER),1.5) and is_equal_approx(float(GuardianData.CLASS_DEFINITION.threat_modifier),1.5) and is_equal_approx(float(TemplarData.CLASS_DEFINITION.threat_modifier),1.5) and is_equal_approx(float(definition.threat_modifier),1.5),"Guardian, Templar, and Protector should share the canonical 1.5 Tank damage-Threat modifier.")

	var wall:=CombatGeometry.create_segment_blocker("wall",Vector2(500,180),Vector2(500,420),18.0,{"owner_combat_id":"hero:protector","cast_id":"cast:1","remaining_duration":2.0,"blocks_movement":true,"blocks_line_of_sight":false,"blocks_projectiles":false})
	TestSupport.check(errors,ProtectorSystem.own_wall(unit(),wall) and CombatGeometry.first_blocker(Vector2(400,300),Vector2(600,300),[wall],"blocks_movement")==0,"Force Wall should retain deterministic owner-aware movement geometry.")
	TestSupport.check(errors,CombatGeometry.first_blocker(Vector2(400,300),Vector2(600,300),[wall],"blocks_projectiles")==-1 and CombatGeometry.has_line_of_sight(Vector2(400,300),Vector2(600,300),[wall]),"Force Wall must not block projectiles, attacks, or line of sight.")
	TestSupport.check(errors,ProtectorSystem.crosses_own_wall(unit(),Vector2(400,300),Vector2(600,300),[wall]),"Protector Q and Judgment should be able to identify crossings through their own Force Wall.")
	var pushed:=CombatGeometry.segment_blocker_push_out(Vector2(500,300),28.0,wall)
	TestSupport.check(errors,CombatGeometry.valid_position(pushed,28.0,[wall]),"A wall born under a unit should push it to a deterministic valid side.")
	TestSupport.check(errors,CombatGeometry.reflect_point_across_line(Vector2(450,300),Vector2(500,180),Vector2(500,420)).is_equal_approx(Vector2(550,300)),"Law and Order should mirror Smite across the oriented wall line rather than rotate around its center.")

	var baseline:=unit()
	TestSupport.check(errors,is_equal_approx(ProtectorSystem.wall_cooldown(baseline),18.0) and is_equal_approx(ProtectorSystem.wall_duration(baseline),2.0),"Baseline Force Wall should use the audited 18-second cooldown and 2-second duration.")
	var barrier:=unit({"tier_8":"protector_l30_2"})
	TestSupport.check(errors,is_equal_approx(ProtectorSystem.wall_cooldown(barrier),8.0) and is_equal_approx(ProtectorSystem.wall_duration(barrier),2.5) and is_equal_approx(ProtectorSystem.wall_range(barrier),float(ProtectorData.SPACE.w_range)*1.5),"Force Barrier should apply all three capstone modifiers from centralized values.")
	var radiant:=unit({"tier_1":"protector_l9_3","tier_2":"protector_l12_3"})
	TestSupport.check(errors,is_equal_approx(ProtectorSystem.smite_duration(radiant),5.0) and is_equal_approx(ProtectorSystem.smite_buff_duration(radiant),3.0) and is_equal_approx(float(ProtectorData.VALUES.e_reach),float(ProtectorData.SPACE.source_to_world)),"Radiant Path and Radiant Reach should extend the field, buff, and Basic Attack reach by their authored amounts.")
	var seal:=unit({"tier_8":"protector_l30_3"})
	TestSupport.check(errors,int(seal.protector_runtime.smite_slot.current_charges)==2 and AbilitySlotSystem.spend(seal.protector_runtime.smite_slot) and AbilitySlotSystem.spend(seal.protector_runtime.smite_slot) and not AbilitySlotSystem.can_activate(seal.protector_runtime.smite_slot),"Seal of El'druin should begin with and permit exactly two immediate Smite casts.")
	AbilitySlotSystem.update(seal.protector_runtime.smite_slot,float(ProtectorData.VALUES.e_cooldown))
	TestSupport.check(errors,int(seal.protector_runtime.smite_slot.current_charges)==1,"Seal of El'druin should recover charges sequentially.")
	var innervated:=unit();AbilitySlotSystem.spend(innervated.protector_runtime.smite_slot);var smite_before:float=float(innervated.protector_runtime.smite_slot.timers[0]);ProtectorSystem.update(innervated,2.0,1.5)
	TestSupport.check(errors,is_equal_approx(float(innervated.protector_runtime.smite_slot.timers[0]),smite_before-3.0),"External cooldown recovery should accelerate Protector's internal Smite charge slot.")

	var enemy:={"threat":{0:700.0,1:1400.0,2:500.0,3:1400.0}}
	var purge:=ProtectorSystem.clear_highest_other_ally_threat(enemy,0,[0,1,2,3])
	TestSupport.check(errors,bool(purge.cleared) and int(purge.hero_index)==1 and is_equal_approx(float(purge.amount),1400.0) and is_equal_approx(float(enemy.threat[0]),700.0) and is_equal_approx(float(enemy.threat[1]),0.0) and is_equal_approx(float(enemy.threat[3]),1400.0),"Purge Evil should deterministically clear only the earliest highest other living ally and preserve Protector Threat.")
	var no_purge:=ProtectorSystem.clear_highest_other_ally_threat({"threat":{0:50.0,1:0.0}},0,[0,1])
	TestSupport.check(errors,not bool(no_purge.cleared),"Purge Evil should do nothing when eligible allied Threat is zero.")

	var reduced:={"active_effects":[]}
	ProtectorSystem.apply_outgoing_reduction(reduced,"protector:a",3.0)
	ProtectorSystem.apply_outgoing_reduction(reduced,"protector:b",3.0)
	TestSupport.check(errors,is_equal_approx(ProtectorSystem.outgoing_damage_multiplier(reduced),0.5),"Overlapping Archangel reductions should resolve to one strongest 50% modifier rather than multiply.")
	var pursuit:=unit({"tier_1":"protector_l9_1"});pursuit.protector_runtime.pursuit_remaining=3.0
	TestSupport.check(errors,is_equal_approx(ProtectorSystem.movement_multiplier(pursuit),1.2),"Pursuit of Justice should grant exactly 20% Movement Speed.")
	var stalwart:=unit({"tier_2":"protector_l12_1"});stalwart.protector_runtime.stalwart_remaining=3.0
	TestSupport.check(errors,is_equal_approx(float(ProtectorSystem.armor_sources(stalwart)[0].armor),25.0),"Stalwart Angel should expose one conditional 25 universal Armor source.")
	TestSupport.check(errors,is_equal_approx(ProtectorSystem.judgment_cooldown(unit({"tier_7":"protector_l27_r1"})),30.0) and is_equal_approx(ProtectorSystem.sanctification_duration(unit({"tier_7":"protector_l27_r2"})),4.0),"Heroic upgrades should match only their authored Judgment or Sanctification modifiers.")
	TestSupport.check(errors,float(ProtectorData.VALUES.trait_duration)==4.0 and float(ProtectorData.VALUES.trait_damage)==450.0 and float(ProtectorData.VALUES.trait_linger)==3.0 and float(ProtectorData.VALUES.aspect_cooldown)==120.0,"Archangel's Wrath and Aspect should retain their locked state, explosion, linger, and fixed cooldown values.")
	TestSupport.check(errors,ProtectorData.TALENT_TIERS.size()==8 and ProtectorData.TEST_BUILDS.size()>=4,"Protector should expose all eight talent tiers and the required representative range presets.")
	return errors
