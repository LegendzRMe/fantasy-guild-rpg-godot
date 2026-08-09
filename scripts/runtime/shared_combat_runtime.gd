extends "res://scripts/runtime/tutorial_controller.gd"

func ensure_combat_runtime_fields(unit:Dictionary,default_id:String,team:String)->void:
	if not unit.has("combat_id"):CombatRulesV1.initialize_unit(unit,default_id,team)

func unit_by_combat_id(combat_id:String):
	for hero in heroes:
		if str(hero.get("combat_id",""))==combat_id:return hero
	for enemy in enemies:
		if str(enemy.get("combat_id",""))==combat_id:return enemy
	return null

func enemy_index_by_combat_id(combat_id:String)->int:
	for index in enemies.size():
		if str(enemies[index].get("combat_id",""))==combat_id:return index
	return -1

func hero_index_by_combat_id(combat_id:String)->int:
	for index in heroes.size():
		if str(heroes[index].get("combat_id",""))==combat_id:return index
	return -1

func target_is_valid_for(unit:Dictionary,target,kind:String)->bool:
	if target==null or bool(target.get("incapacitated",false)) or float(target.get("hp",0.0))<=0.0:return false
	if bool(target.get("spirit_form",false)):return false
	if kind=="enemy":
		if CombatSystem.is_invulnerable(target):return false
		if str(target.get("combat_team",""))==str(unit.get("combat_team","")):return false
		if target.has("concealment") and not StealthDetectionSystem.directly_targetable(unit,target,Vector2(unit.get("pos",Vector2.ZERO)).distance_to(Vector2(target.get("pos",Vector2.ZERO)))):return false
		return true
	if kind=="ally":return str(target.get("combat_team",""))==str(unit.get("combat_team",""))
	return false

func assign_hero_enemy(hero_index:int,enemy_index:int)->void:
	if hero_index<0 or hero_index>=heroes.size() or enemy_index<0 or enemy_index>=enemies.size():return
	ensure_combat_runtime_fields(heroes[hero_index],"hero:%d"%hero_index,"player");ensure_combat_runtime_fields(enemies[enemy_index],"enemy:%d"%enemy_index,"enemy")
	CombatRulesV1.assign_target(heroes[hero_index],str(enemies[enemy_index].combat_id),"enemy")
	heroes[hero_index].target=enemy_index;heroes[hero_index].heal_target=-1;heroes[hero_index].dest=heroes[hero_index].pos

func assign_hero_ally(hero_index:int,ally_index:int)->void:
	if hero_index<0 or hero_index>=heroes.size() or ally_index<0 or ally_index>=heroes.size():return
	ensure_combat_runtime_fields(heroes[hero_index],"hero:%d"%hero_index,"player");ensure_combat_runtime_fields(heroes[ally_index],"hero:%d"%ally_index,"player")
	CombatRulesV1.assign_target(heroes[hero_index],str(heroes[ally_index].combat_id),"ally")
	heroes[hero_index].heal_target=ally_index;heroes[hero_index].target=-1;heroes[hero_index].dest=heroes[hero_index].pos

func clear_hero_command(hero:Dictionary,reason:String="")->void:
	CombatRulesV1.clear_assignment(hero,reason);hero.target=-1;hero.heal_target=-1;hero.dest=hero.pos

func issue_hero_move(hero:Dictionary,destination:Vector2)->void:
	if str(hero.get("class",""))=="Protector" and str(hero.get("protector_runtime",{}).get("wrath",{}).get("phase",""))=="channel":return
	if not (str(hero.get("class",""))=="Ranger" and float(hero.get("ranger_runtime",{}).get("strafe_remaining",0.0))>0.0):interrupt_unit_action(hero,"movement")
	CombatRulesV1.issue_move(hero,destination);hero.target=-1;hero.heal_target=-1

func active_movement_multiplier(unit:Dictionary)->float:
	var multiplier:=1.0
	if str(unit.get("class",""))=="Huntsman" and not unit.get("huntsman_runtime",{}).is_empty():multiplier*=HuntsmanSystem.movement_multiplier(unit)
	if str(unit.get("class",""))=="Shaman" and int(unit.get("shaman_runtime",{}).get("windfury_attacks",0))>0:multiplier*=ShamanSystem.windfury_movement_multiplier(unit)
	if str(unit.get("class",""))=="Protector" and not unit.get("protector_runtime",{}).is_empty():multiplier*=ProtectorSystem.movement_multiplier(unit)
	for effect in unit.get("active_effects",[]):
		if float(effect.get("remaining_duration",0.0))>0.0:multiplier*=float(effect.get("movement_speed_multiplier",1.0))
	return multiplier

func active_basic_attack_range(unit:Dictionary)->float:
	var bonus:=0.0
	for effect in unit.get("active_effects",[]):
		if float(effect.get("remaining_duration",0.0))>0.0:bonus=maxf(bonus,float(effect.get("basic_attack_range_bonus",0.0)))
	return float(unit.get("range",0.0))+bonus

func begin_unit_cast(unit:Dictionary,slot:int,duration:float,is_heroic:bool=false,channel_duration:float=0.0,requires_line_of_sight:bool=true,full_cooldown:float=-1.0)->void:
	CombatRulesV1.preserve_command(unit)
	unit.command_state=CombatRulesV1.CommandState.CAST
	var resolved_cooldown:float=full_cooldown if full_cooldown>=0.0 else float([4.0,7.0,8.0,18.0][clampi(slot,0,3)])
	unit.active_cast={"slot":slot,"remaining":duration,"duration":duration,"is_heroic":is_heroic,"channel_duration":channel_duration,"requires_line_of_sight":requires_line_of_sight,"full_cooldown":resolved_cooldown,"target_id":str(unit.get("preserved_target_id","")),"released":false}

func interrupt_unit_action(unit:Dictionary,reason:String)->bool:
	if str(unit.get("class",""))=="Priest" and not unit.get("priest_runtime",{}).is_empty():PriestSystem.interrupt_flash_heal(unit)
	if str(unit.get("class",""))=="Priest" and bool(unit.get("priest_runtime",{}).get("salvation_started",false)):unit.priest_runtime.salvation_started=false;PriestSystem.telemetry_add(unit,"salvation_interruptions")
	if str(unit.get("class",""))=="Cleric" and bool(unit.get("cleric_runtime",{}).get("jug_active",false)):
		unit.ability_cds[3]=ClericSystem.stop_jug(unit);CombatRulesV1.restore_preserved_command(unit,true);unit.last_command_failure="channel interrupted: %s"%reason;return true
	if not unit.get("active_cast",{}).is_empty():
		var cast:Dictionary=unit.active_cast
		if bool(cast.get("uninterruptible",false)):return false
		var slot:int=int(cast.get("slot",-1))
		if slot>=0 and bool(cast.get("is_heroic",false)):unit.ability_cds[slot]=CombatRulesV1.HEROIC_INTERRUPT_COOLDOWN
		unit.active_cast={}
		if str(unit.get("class",""))=="Warlock" and bool(unit.get("active_channel",{}).get("background",false)):unit.active_channel={}
		CombatRulesV1.restore_preserved_command(unit,target_is_valid_for(unit,unit_by_combat_id(str(unit.get("preserved_target_id",""))),str(unit.get("preserved_target_kind",""))))
		unit.last_command_failure="cast interrupted: %s"%reason;return true
	if not unit.get("active_channel",{}).is_empty():
		unit.active_channel={};CombatRulesV1.restore_preserved_command(unit,target_is_valid_for(unit,unit_by_combat_id(str(unit.get("preserved_target_id",""))),str(unit.get("preserved_target_kind",""))))
		unit.last_command_failure="channel interrupted: %s"%reason;return true
	return false

func update_unit_casts(unit:Dictionary,delta:float)->void:
	if not unit.get("active_cast",{}).is_empty():
		var cast_target=unit_by_combat_id(str(unit.active_cast.get("target_id","")))
		if bool(unit.active_cast.get("requires_line_of_sight",true)) and cast_target!=null and not CombatGeometry.has_line_of_sight(unit.pos,cast_target.pos,combat_blockers):interrupt_unit_action(unit,"line of sight lost");return
		unit.active_cast.remaining=float(unit.active_cast.remaining)-delta
		if unit.active_cast.remaining<=0.0:
			var cast:Dictionary=unit.active_cast;unit.active_cast={}
			var cast_slot:int=int(cast.get("slot",-1));if cast_slot>=0:unit.ability_cds[cast_slot]=float(cast.get("full_cooldown",0.0))
			if float(cast.get("channel_duration",0.0))>0.0:unit.command_state=CombatRulesV1.CommandState.CHANNEL;unit.active_channel={"slot":cast.slot,"remaining":cast.channel_duration,"duration":cast.channel_duration,"requires_line_of_sight":cast.requires_line_of_sight,"target_id":cast.target_id}
			else:CombatRulesV1.restore_preserved_command(unit,target_is_valid_for(unit,unit_by_combat_id(str(unit.get("preserved_target_id",""))),str(unit.get("preserved_target_kind",""))))
	elif not unit.get("active_channel",{}).is_empty():
		var channel_target=unit_by_combat_id(str(unit.active_channel.get("target_id","")))
		if bool(unit.active_channel.get("requires_line_of_sight",true)) and channel_target!=null and not CombatGeometry.has_line_of_sight(unit.pos,channel_target.pos,combat_blockers):interrupt_unit_action(unit,"line of sight lost");return
		unit.active_channel.remaining=float(unit.active_channel.remaining)-delta
		if unit.active_channel.remaining<=0.0:unit.active_channel={};CombatRulesV1.restore_preserved_command(unit,target_is_valid_for(unit,unit_by_combat_id(str(unit.get("preserved_target_id",""))),str(unit.get("preserved_target_kind",""))))

func apply_hit_nudge(source:Dictionary,target:Dictionary)->void:
	if not bool(CombatSystem.default_control_profile(target).get("displacement",true)):return
	target.pos=CombatGeometry.apply_nudge(target.pos,source.get("pos",target.pos),CombatRulesV1.DEFAULT_HIT_NUDGE_DISTANCE,42.0,combat_blockers)
	if int(target.get("command_state",CombatRulesV1.CommandState.IDLE))==CombatRulesV1.CommandState.MOVE:target.dest=target.move_destination

func record_blind_miss(source:Dictionary,target:Dictionary)->void:
	combat_events.append_array(CombatSystem.event_bundle_for_basic_action_miss(source,target,{"damage_type":str(source.get("basic_attack_damage_type","physical")),"origin":"blind"}))
	if str(source.get("class",""))=="Cleric" and not source.get("cleric_runtime",{}).is_empty():ClericSystem.telemetry_add(source,"blind_misses");ClericSystem.telemetry_add(source,"offensive_basic_attacks")
	if str(source.get("class",""))=="Mage" and not source.get("mage_runtime",{}).is_empty():MageSystem.sunfire_release(source,false);MageSystem.telemetry_add(source,"basic_attacks_released");MageSystem.telemetry_add(source,"basic_attack_misses")
	call("add_effect","hit",source.get("pos",Vector2.ZERO),target.get("pos",Vector2.ZERO),"MISS",C_MUTED)

func spawn_basic_projectile(source:Dictionary,target:Dictionary,amount:float,damage_type:String,origin:String)->void:
	var projectile_id:="projectile:%d"%next_projectile_combat_id;next_projectile_combat_id+=1
	var will_miss:=CombatSystem.is_blinded(source)
	combat_projectiles.append(CombatProjectile.create(projectile_id,str(source.combat_id),str(target.combat_id),source.pos,target.pos,CombatRulesV1.DEFAULT_PROJECTILE_SPEED,{"amount":amount,"damage_type":damage_type,"origin":origin,"obstacle_damage":0.0 if will_miss else amount,"will_miss":will_miss}))

func update_combat_projectiles(delta:float)->void:
	for index in range(combat_projectiles.size()-1,-1,-1):
		var projectile:Dictionary=combat_projectiles[index];CombatProjectile.advance(projectile,delta)
		var blocker_index:=CombatGeometry.first_blocker(projectile.previous_pos,projectile.pos,combat_blockers,"blocks_projectiles")
		if blocker_index>=0:
			var blocker:Dictionary=combat_blockers[blocker_index]
			if bool(blocker.get("destructible",false)):blocker.current_health=maxf(0.0,float(blocker.current_health)-float(projectile.payload.get("obstacle_damage",0.0)))
			call("add_effect","hit",projectile.previous_pos,projectile.pos,"BLOCKED",C_MUTED);combat_projectiles.remove_at(index);continue
		if CombatProjectile.arrived(projectile):
			var source=unit_by_combat_id(str(projectile.source_id));var target=unit_by_combat_id(str(projectile.target_id))
			if source!=null and target_is_valid_for(source,target,"enemy") and target.pos.distance_to(projectile.destination)<=58.0:
				if bool(projectile.payload.get("will_miss",false)):record_blind_miss(source,target)
				else:
					var result:Dictionary=call("deal_damage",source,target,float(projectile.payload.amount),"basic_attack",str(projectile.payload.damage_type),str(projectile.payload.origin));apply_hit_nudge(source,target);call("add_effect","hit",source.pos,target.pos,"-%d"%int(result.resolved_damage),C_RED)
			combat_projectiles.remove_at(index)

func release_basic_action(unit:Dictionary)->void:
	var pending:Dictionary=unit.get("pending_basic_action",{});var target=unit_by_combat_id(str(pending.get("target_id","")));var kind:=str(pending.get("target_kind",""))
	if not target_is_valid_for(unit,target,kind):return
	if not CombatGeometry.has_line_of_sight(unit.pos,target.pos,combat_blockers):return
	if kind=="ally":
		var healing_result:Dictionary=call("deal_healing",unit,target,float(unit.get("basic_heal_amount",unit.get("basic_action_amount",0.0))),"basic_heal","cleric_basic_action")
		if str(unit.get("class",""))=="Cleric" and not unit.get("cleric_runtime",{}).is_empty():ClericSystem.telemetry_add(unit,"basic_heals");ClericSystem.telemetry_add(unit,"basic_heal_effective",float(healing_result.effective_amount));ClericSystem.telemetry_add(unit,"basic_heal_overhealing",float(healing_result.overhealing))
		call("add_effect","heal",unit.pos,target.pos,"+%d"%int(healing_result.effective_amount),C_GREEN)
	elif float(unit.get("range",0.0))>100.0:
		spawn_basic_projectile(unit,target,float(unit.get("damage",0.0)),str(unit.get("basic_attack_damage_type","physical")),"basic_attack")
	elif CombatSystem.is_blinded(unit):
		record_blind_miss(unit,target)
	else:
		var damage_result:Dictionary=call("deal_damage",unit,target,float(unit.get("damage",0.0)),"basic_attack",str(unit.get("basic_attack_damage_type","physical")),"basic_attack");apply_hit_nudge(unit,target);call("add_effect","slash",unit.pos,target.pos,"-%d"%int(damage_result.resolved_damage),CLASSES.get(str(unit.get("class","Guardian")),{"color":C_TEXT}).color)

func idle_defense_target(hero:Dictionary):
	var preferred=null;var closest=null;var closest_distance:=CombatRulesV1.IDLE_MELEE_DEFENSE_RADIUS
	for enemy in enemies:
		if enemy.hp<=0:continue
		var distance:float=hero.pos.distance_to(enemy.pos)
		if distance>CombatRulesV1.IDLE_MELEE_DEFENSE_RADIUS:continue
		if str(enemy.get("combat_id",""))==str(hero.get("self_defense_target_id","")):preferred=enemy
		if int(enemy.get("target",-1))==int(hero.get("battle_index",-1)):preferred=enemy
		if distance<closest_distance:closest_distance=distance;closest=enemy
	return preferred if preferred!=null else closest

func update_shared_hero(hero:Dictionary,delta:float)->void:
	ensure_combat_runtime_fields(hero,"hero:%d"%int(hero.get("battle_index",heroes.find(hero))),"player")
	var has_true_control:bool=hero.get("active_effects",[]).any(func(effect):return str(effect.get("control_type","")) in ["stun","root","silence","fear"] and float(effect.get("remaining_duration",0.0))>0.0)
	if has_true_control and (not hero.get("active_cast",{}).is_empty() or not hero.get("active_channel",{}).is_empty() or bool(hero.get("cleric_runtime",{}).get("jug_active",false))):interrupt_unit_action(hero,"crowd control")
	if hero.hp<=0.0:
		if str(hero.get("class",""))=="Priest" and not hero.get("priest_runtime",{}).is_empty() and not PriestSystem.spirit_active(hero):PriestSystem.enter_spirit(hero);clear_hero_command(hero,"spirit form");return
		if not bool(hero.get("incapacitated",false)):
			hero["was_defeated"]=true
			if str(hero.get("class",""))=="Rogue" and not hero.get("rogue_runtime",{}).is_empty():ComboPointSystem.reset(hero);RogueSystem.telemetry_add(hero,"combo_defeat_resets");RogueSystem.break_vanish(hero)
			interrupt_unit_action(hero,"incapacitated");CombatRulesV1.incapacitate(hero)
			if str(hero.combat_id) not in incapacitated_hero_ids:incapacitated_hero_ids.append(str(hero.combat_id))
		return
	if bool(hero.get("spirit_form",false)):
		if int(hero.get("command_state",CombatRulesV1.CommandState.IDLE))==CombatRulesV1.CommandState.MOVE:
			var spirit_before:Vector2=hero.pos
			hero.pos=CombatGeometry.move_toward_safe(hero.pos,hero.move_destination,float(hero.movement_speed)*active_movement_multiplier(hero)*delta,42.0,combat_blockers)
			hero.dest=hero.move_destination
			if hero.pos.distance_to(hero.move_destination)<=4.0:hero.command_state=CombatRulesV1.CommandState.IDLE;hero.dest=hero.pos
			elif hero.pos!=spirit_before:hero.facing_direction=spirit_before.direction_to(hero.pos)
		return
	if str(hero.get("class",""))=="Warlock" and float(hero.get("warlock_runtime",{}).get("banished_remaining",0.0))>0.0:return
	var fear_effects:Array=hero.get("active_effects",[]).filter(func(effect):return str(effect.get("control_type",""))=="fear" and float(effect.get("remaining_duration",0.0))>0.0)
	if not fear_effects.is_empty():
		var origin:=Vector2(hero.get("fear_origin",hero.pos-hero.facing_direction));var away:=origin.direction_to(hero.pos)
		if away==Vector2.ZERO:away=Vector2.RIGHT
		hero.pos=CombatGeometry.move_toward_safe(hero.pos,hero.pos+away*100.0,float(hero.movement_speed)*delta,42.0,combat_blockers);return
	update_unit_casts(hero,delta)
	if int(hero.command_state) in [CombatRulesV1.CommandState.CAST,CombatRulesV1.CommandState.CHANNEL]:return
	var phase_event:=CombatRulesV1.advance_basic_action(hero,delta,battle_time)
	if phase_event=="release":release_basic_action(hero)
	if bool(hero.get("independent",false)) and int(hero.command_state)==CombatRulesV1.CommandState.IDLE:
		var automatic_enemy_index:int=-1;var automatic_distance:float=INF
		for enemy_index in enemies.size():
			if enemies[enemy_index].hp>0 and hero.pos.distance_to(enemies[enemy_index].pos)<automatic_distance:automatic_enemy_index=enemy_index;automatic_distance=hero.pos.distance_to(enemies[enemy_index].pos)
		if automatic_enemy_index>=0:assign_hero_enemy(int(hero.get("battle_index",heroes.find(hero))),automatic_enemy_index)
	if int(hero.command_state)==CombatRulesV1.CommandState.MOVE:
		var before:Vector2=hero.pos;var move_multiplier:float=(ClericSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Cleric" and not hero.get("cleric_runtime",{}).is_empty() else RogueSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Rogue" and not hero.get("rogue_runtime",{}).is_empty() else SlayerSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Slayer" and not hero.get("slayer_runtime",{}).is_empty() else PriestSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Priest" and not hero.get("priest_runtime",{}).is_empty() else float(hero.get("ranger_movement_multiplier",1.0)))*cleric_host_movement_multiplier(hero)*active_movement_multiplier(hero);hero.pos=CombatGeometry.move_toward_safe(hero.pos,hero.move_destination,float(hero.movement_speed)*move_multiplier*delta,42.0,combat_blockers);hero.dest=hero.move_destination
		if hero.pos.distance_to(hero.move_destination)<=4.0:hero.command_state=CombatRulesV1.CommandState.IDLE;hero.dest=hero.pos
		elif hero.pos==before:hero.path_failure_timer=float(hero.path_failure_timer)+delta;if hero.path_failure_timer>=CombatRulesV1.PATH_FAILURE_TIMEOUT:clear_hero_command(hero,"movement path blocked")
		else:hero.path_failure_timer=0.0;hero.facing_direction=before.direction_to(hero.pos)
		return
	if int(hero.command_state) in [CombatRulesV1.CommandState.ATTACK,CombatRulesV1.CommandState.HEAL]:
		var target=unit_by_combat_id(str(hero.assigned_target_id));var kind:=str(hero.assigned_target_kind)
		if not target_is_valid_for(hero,target,kind):clear_hero_command(hero,"target invalid");return
		var has_los:=CombatGeometry.has_line_of_sight(hero.pos,target.pos,combat_blockers)
		if bool(hero.assignment_had_line_of_sight) and not has_los:clear_hero_command(hero,"line of sight lost");return
		var usable_range:=active_basic_attack_range(hero)-CombatRulesV1.RANGE_TOLERANCE;var distance:float=hero.pos.distance_to(target.pos)
		if not has_los:
			var angle_position:=CombatGeometry.line_of_sight_position(hero.pos,target.pos,usable_range,combat_blockers);var before:Vector2=hero.pos;var move_multiplier:float=(ClericSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Cleric" and not hero.get("cleric_runtime",{}).is_empty() else RogueSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Rogue" and not hero.get("rogue_runtime",{}).is_empty() else SlayerSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Slayer" and not hero.get("slayer_runtime",{}).is_empty() else PriestSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Priest" and not hero.get("priest_runtime",{}).is_empty() else float(hero.get("ranger_movement_multiplier",1.0)))*cleric_host_movement_multiplier(hero)*active_movement_multiplier(hero);hero.pos=CombatGeometry.move_toward_safe(hero.pos,angle_position,float(hero.movement_speed)*move_multiplier*delta,42.0,combat_blockers)
			if hero.pos==before:hero.path_failure_timer=float(hero.path_failure_timer)+delta;if hero.path_failure_timer>=CombatRulesV1.PATH_FAILURE_TIMEOUT:clear_hero_command(hero,"no reachable line of sight")
			return
		hero.assignment_had_line_of_sight=true;hero.path_failure_timer=0.0
		if distance>usable_range:
			var stop_point:Vector2=target.pos+target.pos.direction_to(hero.pos)*usable_range;var before:Vector2=hero.pos;var move_multiplier:float=(ClericSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Cleric" and not hero.get("cleric_runtime",{}).is_empty() else RogueSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Rogue" and not hero.get("rogue_runtime",{}).is_empty() else SlayerSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Slayer" and not hero.get("slayer_runtime",{}).is_empty() else PriestSystem.movement_multiplier(hero) if str(hero.get("class",""))=="Priest" and not hero.get("priest_runtime",{}).is_empty() else float(hero.get("ranger_movement_multiplier",1.0)))*cleric_host_movement_multiplier(hero)*active_movement_multiplier(hero);hero.pos=CombatGeometry.move_toward_safe(hero.pos,stop_point,float(hero.movement_speed)*move_multiplier*delta,42.0,combat_blockers);hero.facing_direction=before.direction_to(hero.pos);return
		hero.facing_direction=hero.pos.direction_to(target.pos);CombatRulesV1.begin_basic_action(hero,str(target.combat_id),kind,battle_time);return
	if int(hero.command_state)==CombatRulesV1.CommandState.IDLE:
		var defense_target=idle_defense_target(hero)
		if defense_target==null:hero.self_defense_target_id="";return
		hero.self_defense_target_id=str(defense_target.combat_id);hero.facing_direction=hero.pos.direction_to(defense_target.pos);CombatRulesV1.begin_basic_action(hero,str(defense_target.combat_id),"enemy",battle_time)

func revive_unit(combat_id:String,health_percent:float)->bool:
	var unit=unit_by_combat_id(combat_id)
	if unit==null:return false
	var revived:=CombatRulesV1.revive(unit,health_percent)
	if revived:incapacitated_hero_ids.erase(combat_id)
	return revived

# Extension points supplied by the presentation and encounter layers above the
# combat runtime chain. Keeping the contracts here lets focused runtime modules
# call them without depending on their concrete UI/story implementations.
func add_effect(_kind:String,_from:Vector2,_to:Vector2,_text_value:String,_color:Color)->void:pass
func use_ability(_slot:int,_cast_position:Vector2=Vector2.INF,_item_repeat:bool=false)->void:pass
func add_first_recruit_to_battle()->void:pass
func complete_ashwood_ritual()->void:pass
func finish_battle(_win:bool)->void:pass
func update_victory(_delta:float)->void:pass
func cleric_host_movement_multiplier(_target:Dictionary)->float:return 1.0
