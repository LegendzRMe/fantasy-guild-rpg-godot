extends RefCounted

enum CommandState { IDLE, MOVE, ATTACK, HEAL, CAST, CHANNEL, INCAPACITATED }
enum BasicActionPhase { READY, WINDUP, RECOVERY }

const IDLE_MELEE_DEFENSE_RADIUS := 72.0
const RANGE_TOLERANCE := 8.0
const PATH_FAILURE_TIMEOUT := 1.25
const HEROIC_INTERRUPT_COOLDOWN := 10.0
const DEFAULT_BASIC_ACTION_WINDUP_RATIO := 0.30
const DEFAULT_HIT_NUDGE_DISTANCE := 5.0
const DEFAULT_PROJECTILE_SPEED := 560.0
const LINE_OF_SIGHT_PROBE_SPACING := 32.0
const DEBUG_COMBAT_OVERLAY_ENABLED := false

static func command_name(value:int) -> String:
	return CommandState.keys()[clampi(value,0,CommandState.size()-1)]

static func phase_name(value:int) -> String:
	return BasicActionPhase.keys()[clampi(value,0,BasicActionPhase.size()-1)]

static func initialize_unit(unit:Dictionary,combat_id:String,team:String) -> Dictionary:
	unit["combat_id"]=combat_id
	unit["combat_team"]=team
	unit["command_state"]=CommandState.IDLE
	unit["assigned_target_id"]=""
	unit["assigned_target_kind"]=""
	unit["move_destination"]=unit.get("pos",Vector2.ZERO)
	unit["basic_action_phase"]=BasicActionPhase.READY
	unit["basic_action_timer"]=0.0
	unit["basic_action_release_time"]=maxf(0.05,float(unit.get("basic_action_interval",1.0))*DEFAULT_BASIC_ACTION_WINDUP_RATIO)
	unit["next_action_ready_time"]=0.0
	unit["pending_basic_action"]={}
	unit["preserved_command_state"]=CommandState.IDLE
	unit["preserved_target_id"]=""
	unit["preserved_target_kind"]=""
	unit["active_cast"]={}
	unit["active_channel"]={}
	unit["incapacitated"]=false
	unit["path_failure_timer"]=0.0
	unit["assignment_had_line_of_sight"]=false
	unit["last_command_failure"]=""
	unit["self_defense_target_id"]=""
	return unit

static func assign_target(unit:Dictionary,target_id:String,target_kind:String)->void:
	unit.assigned_target_id=target_id
	unit.assigned_target_kind=target_kind
	unit.command_state=CommandState.HEAL if target_kind=="ally" else CommandState.ATTACK
	unit.assignment_had_line_of_sight=false
	unit.path_failure_timer=0.0
	unit.self_defense_target_id=""

static func clear_assignment(unit:Dictionary,reason:String="")->void:
	unit.assigned_target_id=""
	unit.assigned_target_kind=""
	unit.self_defense_target_id=""
	unit.command_state=CommandState.INCAPACITATED if bool(unit.get("incapacitated",false)) else CommandState.IDLE
	unit.last_command_failure=reason
	unit.assignment_had_line_of_sight=false

static func issue_move(unit:Dictionary,destination:Vector2)->void:
	clear_assignment(unit)
	cancel_basic_windup(unit)
	unit.move_destination=destination
	unit.dest=destination
	unit.command_state=CommandState.MOVE

static func cancel_basic_windup(unit:Dictionary)->void:
	if int(unit.get("basic_action_phase",BasicActionPhase.READY))==BasicActionPhase.WINDUP:
		unit.basic_action_phase=BasicActionPhase.READY
		unit.basic_action_timer=0.0
		unit.pending_basic_action={}

static func begin_basic_action(unit:Dictionary,target_id:String,target_kind:String,current_time:float)->bool:
	if bool(unit.get("incapacitated",false)) or current_time+0.0001<float(unit.get("next_action_ready_time",0.0)):return false
	if int(unit.get("basic_action_phase",BasicActionPhase.READY))==BasicActionPhase.WINDUP:return false
	unit.basic_action_phase=BasicActionPhase.WINDUP
	unit.basic_action_timer=0.0
	unit.basic_action_release_time=maxf(0.05,float(unit.get("basic_action_interval",1.0))*DEFAULT_BASIC_ACTION_WINDUP_RATIO)
	unit.pending_basic_action={"target_id":target_id,"target_kind":target_kind}
	return true

static func advance_basic_action(unit:Dictionary,delta:float,current_time:float)->String:
	var phase:=int(unit.get("basic_action_phase",BasicActionPhase.READY))
	if phase==BasicActionPhase.READY:return ""
	if phase==BasicActionPhase.WINDUP:
		unit.basic_action_timer=float(unit.get("basic_action_timer",0.0))+delta
		if unit.basic_action_timer>=float(unit.get("basic_action_release_time",0.3)):
			unit.basic_action_phase=BasicActionPhase.RECOVERY
			unit.next_action_ready_time=current_time+maxf(0.0,float(unit.get("basic_action_interval",1.0))-float(unit.basic_action_timer))
			return "release"
		return ""
	if current_time+0.0001>=float(unit.get("next_action_ready_time",0.0)):
		unit.basic_action_phase=BasicActionPhase.READY
		unit.basic_action_timer=0.0
		unit.pending_basic_action={}
		return "ready"
	return ""

static func preserve_command(unit:Dictionary)->void:
	unit.preserved_command_state=int(unit.get("command_state",CommandState.IDLE))
	unit.preserved_target_id=str(unit.get("assigned_target_id",""))
	unit.preserved_target_kind=str(unit.get("assigned_target_kind",""))

static func restore_preserved_command(unit:Dictionary,target_valid:bool)->void:
	if target_valid and str(unit.get("preserved_target_id",""))!="":
		unit.command_state=int(unit.preserved_command_state)
		unit.assigned_target_id=str(unit.preserved_target_id)
		unit.assigned_target_kind=str(unit.preserved_target_kind)
	else:clear_assignment(unit,"preserved target invalid")
	unit.preserved_target_id="";unit.preserved_target_kind="";unit.preserved_command_state=CommandState.IDLE

static func incapacitate(unit:Dictionary)->void:
	unit.incapacitated=true;unit.hp=0.0;unit.dest=unit.pos;unit.move_destination=unit.pos
	cancel_basic_windup(unit);clear_assignment(unit,"incapacitated")
	unit.command_state=CommandState.INCAPACITATED;unit.active_cast={};unit.active_channel={}

static func revive(unit:Dictionary,health_percent:float)->bool:
	if not bool(unit.get("incapacitated",false)):return false
	unit.incapacitated=false;unit.hp=maxf(1.0,float(unit.get("max_hp",1.0))*clampf(health_percent,0.01,1.0));clear_assignment(unit);return true
