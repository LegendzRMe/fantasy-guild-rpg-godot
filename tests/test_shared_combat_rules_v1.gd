extends RefCounted

const CombatRules = preload("res://scripts/combat/combat_rules_v1.gd")
const CombatGeometry = preload("res://scripts/combat/combat_geometry.gd")
const CombatProjectile = preload("res://scripts/combat/combat_projectile.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func test_unit(position:Vector2=Vector2(100,100))->Dictionary:
	return {"pos":position,"dest":position,"hp":100.0,"max_hp":100.0,"basic_action_interval":1.0,"ability_cds":[0.0,0.0,0.0,0.0,0.0]}

static func run()->Array:
	var errors:=[]
	var hero:=CombatRules.initialize_unit(test_unit(),"hero:test","player")
	CombatRules.assign_target(hero,"enemy:test","enemy")
	TestSupport.check(errors,hero.command_state==CombatRules.CommandState.ATTACK and hero.assigned_target_id=="enemy:test","An explicit attack command should store a stable target ID and attack state.")
	TestSupport.check(errors,CombatRules.begin_basic_action(hero,"enemy:test","enemy",0.0),"A ready unit should begin its Basic Action wind-up.")
	TestSupport.check(errors,CombatRules.advance_basic_action(hero,.29,.29)=="" and hero.basic_action_phase==CombatRules.BasicActionPhase.WINDUP,"A Basic Action should not resolve before its release point.")
	TestSupport.check(errors,CombatRules.advance_basic_action(hero,.02,.31)=="release" and hero.basic_action_phase==CombatRules.BasicActionPhase.RECOVERY,"A Basic Action should release once and enter recovery.")
	var ready_time:float=hero.next_action_ready_time
	CombatRules.issue_move(hero,Vector2(250,100))
	TestSupport.check(errors,hero.command_state==CombatRules.CommandState.MOVE and hero.assigned_target_id=="" and is_equal_approx(hero.next_action_ready_time,ready_time),"Movement should clear assignments without shortening released-action recovery.")
	CombatRules.advance_basic_action(hero,.68,.99)
	TestSupport.check(errors,hero.basic_action_phase==CombatRules.BasicActionPhase.RECOVERY,"Repeated commands must not enable animation-cancel action speed.")
	CombatRules.advance_basic_action(hero,.02,1.01)
	TestSupport.check(errors,hero.basic_action_phase==CombatRules.BasicActionPhase.READY,"Recovery should end at the original action interval.")

	var pillar:=CombatGeometry.create_blocker("pillar",Rect2(180,50,40,120))
	var wall:=CombatGeometry.create_blocker("wall",Rect2(300,50,30,120),{"destructible":true,"current_health":50.0,"maximum_health":50.0})
	TestSupport.check(errors,not CombatGeometry.has_line_of_sight(Vector2(100,100),Vector2(260,100),[pillar]),"A line-of-sight blocker should stop a segment through its rectangle.")
	TestSupport.check(errors,CombatGeometry.has_line_of_sight(Vector2(100,200),Vector2(260,200),[pillar]),"A clear segment should preserve line of sight.")
	var nudged:=CombatGeometry.apply_nudge(Vector2(160,100),Vector2(100,100),30.0,12.0,[pillar])
	TestSupport.check(errors,nudged.x<168.0,"A physical hit nudge must not push a unit through a solid blocker.")
	var projectile:=CombatProjectile.create("p:1","hero:test","enemy:test",Vector2(250,100),Vector2(400,100),600.0,{"amount":10.0})
	CombatProjectile.advance(projectile,.1)
	TestSupport.check(errors,CombatGeometry.first_blocker(projectile.previous_pos,projectile.pos,[wall],"blocks_projectiles")==0,"A world-space projectile should detect a newly present wall along its travelled segment.")

	CombatRules.incapacitate(hero)
	TestSupport.check(errors,hero.incapacitated and hero.command_state==CombatRules.CommandState.INCAPACITATED and hero.hp==0.0,"Zero-Health heroes should enter a non-commandable incapacitated state.")
	TestSupport.check(errors,CombatRules.revive(hero,.25) and is_equal_approx(hero.hp,25.0) and hero.command_state==CombatRules.CommandState.IDLE,"The future revive hook should restore a configured Health percentage and idle state.")
	return errors
