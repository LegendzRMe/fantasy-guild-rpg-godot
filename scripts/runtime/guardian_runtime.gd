extends "res://scripts/runtime/enemy_combat_runtime.gd"

func guardian_clamped_point(hero:Dictionary,point:Vector2,range_limit:float)->Vector2:
	if range_limit<=0.0:return hero.pos
	var offset:Vector2=point-hero.pos
	if offset.length()<=range_limit:return point.clamp(Vector2(55,70),Vector2(1225,620))
	return (hero.pos+offset.normalized()*range_limit).clamp(Vector2(55,70),Vector2(1225,620))

func guardian_heroic_id(hero:Dictionary)->String:
	var heroic:=str(hero.get("selected_heroic_id",""))
	return heroic if heroic in ["guardian_l15_r1","guardian_l15_r2"] else "guardian_l15_r1"

func guardian_scaled(hero:Dictionary,key:String)->float:
	return GuardianData.scaled(float(GuardianData.VALUES[key]),int(hero.level))

func guardian_damage_near(hero:Dictionary,point:Vector2,radius:float,amount:float,origin:String)->Array:
	var hits:Array=[]
	for foe in enemies:
		if foe.hp<=0 or foe.pos.distance_to(point)>radius:continue
		deal_damage(hero,foe,amount,"heroic" if origin=="Haymaker" else "basic_ability","physical",origin)
		hits.append(foe)
	for blocker in combat_blockers:
		if bool(blocker.get("destructible",false)) and CombatGeometry.blocker_active(blocker) and blocker.rect.get_center().distance_to(point)<=radius:
			blocker.current_health=maxf(0.0,float(blocker.current_health)-amount)
	return hits

func cast_guardian_ability(slot:int,cast_position:Vector2,item_repeat:bool=false)->bool:
	var hero:Dictionary=heroes[selected]
	if slot<0 or slot>3 or (not item_repeat and float(hero.ability_cds[slot])>0.0):return false
	match slot:
		0:return cast_storm_bolt(hero,cast_position)
		1:return cast_thunder_clap(hero)
		2:return cast_dwarf_toss(hero,cast_position)
		3:return cast_avatar(hero) if guardian_heroic_id(hero)=="guardian_l15_r1" else cast_haymaker(hero)
	return false

func cast_storm_bolt(hero:Dictionary,cast_position:Vector2)->bool:
	CombatRulesV1.preserve_command(hero)
	var runtime:Dictionary=hero.guardian_runtime
	var bolt_range:=float(GuardianData.SPACE.storm_bolt_range)*(1.5 if bool(runtime.quest_mythic_reached) else 1.0)
	var destination:Vector2=guardian_clamped_point(hero,cast_position,bolt_range)
	if destination==hero.pos:destination=hero.pos+hero.get("facing_direction",Vector2.RIGHT)*bolt_range
	hero.facing_direction=hero.pos.direction_to(destination)
	var projectile:=CombatProjectile.create("guardian_bolt:%d"%next_projectile_combat_id,str(hero.combat_id),"",hero.pos,destination,float(GuardianData.VALUES.storm_bolt_projectile_speed),{"guardian":true,"amount":guardian_scaled(hero,"storm_bolt_damage"),"width":float(GuardianData.SPACE.storm_bolt_width)*(2.0 if bool(runtime.quest_mythic_reached) else 1.0),"remaining_hits":999 if bool(runtime.quest_mythic_reached) else 2 if bool(runtime.quest_first_reached) else 1,"hit_ids":[]})
	next_projectile_combat_id+=1;combat_projectiles.append(projectile);hero.ability_cds[0]=float(GuardianData.VALUES.storm_bolt_cooldown);GuardianSystem.telemetry_add(hero,"storm_bolt_casts")
	CombatRulesV1.restore_preserved_command(hero,target_is_valid_for(hero,unit_by_combat_id(str(hero.get("preserved_target_id",""))),str(hero.get("preserved_target_kind",""))))
	return true

func cast_thunder_clap(hero:Dictionary)->bool:
	CombatRulesV1.preserve_command(hero)
	var targets:Array=[]
	for foe in enemies:
		if foe.hp>0 and foe.pos.distance_to(hero.pos)<=float(GuardianData.SPACE.thunder_clap_radius):targets.append(foe)
	var amount:=guardian_scaled(hero,"thunder_clap_damage")*(3.0 if targets.size()==1 and GuardianSystem.has_talent(hero,"guardian_l21_3") else 1.0)
	for foe in targets:
		deal_damage(hero,foe,amount,"basic_ability","physical","Thunder Clap")
		CombatSystem.apply_control(foe,"slow",2.5,0.30)
		CombatSystem.apply_control(foe,"attack_speed",3.5 if GuardianSystem.has_talent(hero,"guardian_l12_2") else 2.5,0.50 if GuardianSystem.has_talent(hero,"guardian_l12_2") else 0.30)
	if GuardianSystem.has_talent(hero,"guardian_l21_2") and not targets.is_empty():
		var healing:=deal_healing(hero,hero,float(hero.max_hp)*0.06*targets.size(),"basic_ability","Healing Static")
		GuardianSystem.telemetry_add(hero,"healing_static_healing",float(healing.effective_amount))
	if GuardianSystem.has_talent(hero,"guardian_l12_2"):hero.ability_cds[3]=float(hero.ability_cds[3])*pow(0.95,targets.size())
	if GuardianSystem.has_talent(hero,"guardian_l12_3") and not targets.is_empty():hero.guardian_runtime.delayed_effects.append({"remaining":2.0,"point":hero.pos,"amount":amount*0.75,"radius":GuardianData.SPACE.thunder_clap_radius})
	hero.ability_cds[1]=float(GuardianData.VALUES.thunder_clap_cooldown);GuardianSystem.telemetry_add(hero,"thunder_clap_casts",targets.size());CombatRulesV1.restore_preserved_command(hero,true)
	return true

func cast_dwarf_toss(hero:Dictionary,cast_position:Vector2)->bool:
	var toss_range:=float(GuardianData.SPACE.dwarf_toss_range)*(1.3 if GuardianSystem.has_talent(hero,"guardian_l24_1") else 1.0)
	var landing:Vector2=guardian_clamped_point(hero,cast_position,toss_range);var radius:=float(hero.get("combat_radius",42.0))
	var valid:=CombatGeometry.valid_position(landing,radius,combat_blockers) and CombatGeometry.has_line_of_sight(hero.pos,landing,combat_blockers)
	for unit in heroes+enemies:
		if unit!=hero and unit.hp>0 and unit.pos.distance_to(landing)<radius+float(unit.get("combat_radius",28.0)):valid=false;break
	if not valid:GuardianSystem.telemetry_add(hero,"dwarf_toss_invalid");return false
	var had_assignment:=int(hero.get("target",-1))>=0 or int(hero.get("heal_target",-1))>=0
	CombatRulesV1.clear_assignment(hero);hero.pos=landing;hero.dest=landing;hero.move_destination=landing;hero.command_state=CombatRulesV1.CommandState.IDLE
	var hits:=guardian_damage_near(hero,landing,float(GuardianData.SPACE.landing_radius),guardian_scaled(hero,"dwarf_toss_damage"),"Dwarf Toss")
	GuardianSystem.add_armor_source(hero,"dwarf_toss",float(GuardianData.VALUES.dwarf_toss_armor),float(GuardianData.VALUES.dwarf_toss_armor_duration)+(2.0 if GuardianSystem.has_talent(hero,"guardian_l21_3") else 0.0))
	if GuardianSystem.has_talent(hero,"guardian_l9_1"):GuardianSystem.grant_block(hero)
	if GuardianSystem.has_talent(hero,"guardian_l18_2"):
		for foe in hits:CombatSystem.apply_control(foe,"slow",1.5,0.80)
	hero.ability_cds[2]=maxf(0.0,float(GuardianData.VALUES.dwarf_toss_cooldown)-(hits.size() if GuardianSystem.has_talent(hero,"guardian_l24_1") else 0));GuardianSystem.telemetry_add(hero,"dwarf_toss_valid")
	if had_assignment:GuardianSystem.telemetry_add(hero,"dwarf_toss_assignments_cleared")
	return true

func cast_avatar(hero:Dictionary)->bool:
	CombatRulesV1.preserve_command(hero);GuardianSystem.begin_avatar(hero)
	if GuardianSystem.has_talent(hero,"guardian_l27_r1"):GuardianSystem.add_armor_source(hero,"unstoppable_force",20.0,float(GuardianData.VALUES.avatar_duration))
	hero.ability_cds[3]=float(GuardianData.VALUES.avatar_cooldown);CombatRulesV1.restore_preserved_command(hero,true);return true

func cast_haymaker(hero:Dictionary)->bool:
	var target_index:=combat_enemy_target()
	if target_index<0:return false
	var target:Dictionary=enemies[target_index];var amount:=guardian_scaled(hero,"haymaker_damage")*(1.25 if GuardianSystem.has_talent(hero,"guardian_l27_r2") else 1.0)
	deal_damage(hero,target,amount,"heroic","physical","Haymaker");CombatSystem.apply_control(target,"stun",0.25)
	if GuardianSystem.has_talent(hero,"guardian_l27_r2"):GuardianSystem.mark_haymaker(hero,str(target.combat_id),battle_time)
	if bool(target.get("boss",false)):CombatSystem.apply_control(target,"stagger",float(GuardianData.VALUES.haymaker_stagger));GuardianSystem.telemetry_add(hero,"haymaker_boss_staggers")
	else:target.pos=CombatGeometry.move_toward_safe(target.pos,target.pos+hero.pos.direction_to(target.pos)*float(GuardianData.SPACE.haymaker_launch),float(GuardianData.SPACE.haymaker_launch),float(target.get("combat_radius",28.0)),combat_blockers)
	hero.ability_cds[3]=float(GuardianData.VALUES.haymaker_cooldown);GuardianSystem.telemetry_add(hero,"haymaker_uses");return true

func use_guardian_active(hero:Dictionary,talent_id:String)->bool:
	if not GuardianSystem.has_talent(hero,talent_id):return false
	match talent_id:
		"guardian_l24_2":hero.guardian_runtime.stoneform_remaining=float(GuardianData.VALUES.stoneform_duration)
		"guardian_l30_2":GuardianSystem.add_armor_source(hero,"hardened_shield",float(GuardianData.VALUES.hardened_shield_armor),float(GuardianData.VALUES.hardened_shield_duration))
		"guardian_l30_3":
			for slot in 3:hero.ability_cds[slot]=0.0
		_:return false
	GuardianSystem.telemetry_add(hero,"capstone_uses");return true

func update_guardian_projectiles(delta:float)->void:
	for index in range(combat_projectiles.size()-1,-1,-1):
		var projectile:Dictionary=combat_projectiles[index]
		if not bool(projectile.get("payload",{}).get("guardian",false)):continue
		CombatProjectile.advance(projectile,delta);var source=unit_by_combat_id(str(projectile.source_id))
		var blocker_index:=CombatGeometry.first_blocker(projectile.previous_pos,projectile.pos,combat_blockers,"blocks_projectiles")
		if blocker_index>=0:
			var blocker:Dictionary=combat_blockers[blocker_index]
			if bool(blocker.get("destructible",false)):blocker.current_health=maxf(0.0,float(blocker.current_health)-float(projectile.payload.amount))
			if source!=null:GuardianSystem.telemetry_add(source,"storm_bolt_misses")
			combat_projectiles.remove_at(index);continue
		if source==null:combat_projectiles.remove_at(index);continue
		var removed:=false
		for foe in enemies:
			if foe.hp<=0 or str(foe.combat_id) in projectile.payload.hit_ids:continue
			if not CombatGeometry.segment_hits_circle(projectile.previous_pos,projectile.pos,foe.pos,float(projectile.payload.width)+float(foe.get("combat_radius",28.0))):continue
			var classifications:Array=foe.get("target_classifications",["heroic"] if bool(foe.get("boss",false)) else ["non_heroic"])
			var multiplier:=5.0 if GuardianSystem.has_talent(source,"guardian_l12_1") and "non_heroic" in classifications else 1.0
			deal_damage(source,foe,float(projectile.payload.amount)*multiplier,"basic_ability","physical","Storm Bolt");CombatSystem.apply_control(foe,"stun",float(GuardianData.VALUES.storm_bolt_stun))
			if "training" not in foe.get("combat_tags",[]) and "non_qualifying" not in foe.get("combat_tags",[]):GuardianSystem.mark_storm_bolt(source,str(foe.combat_id),battle_time)
			source.guardian_runtime.bronzebeard_empowered=3.0;GuardianSystem.telemetry_add(source,"storm_bolt_hits")
			projectile.payload.hit_ids.append(str(foe.combat_id));projectile.payload.remaining_hits=int(projectile.payload.remaining_hits)-1
			if int(projectile.payload.remaining_hits)<=0:combat_projectiles.remove_at(index);removed=true;break
		if not removed and CombatProjectile.arrived(projectile):
			if projectile.payload.hit_ids.is_empty():GuardianSystem.telemetry_add(source,"storm_bolt_misses")
			combat_projectiles.remove_at(index)

func update_guardian_runtime(delta:float)->void:
	update_guardian_projectiles(delta)
	for hero in heroes:
		if hero.hp<=0 or str(hero.get("class",""))!="Guardian" or hero.get("guardian_runtime",{}).is_empty():continue
		var result:=GuardianSystem.update_timers(hero,delta)
		if float(result.second_wind_heal)>0.0:deal_healing(hero,hero,float(result.second_wind_heal),"periodic","Second Wind")
		if float(result.stoneform_heal)>0.0:deal_healing(hero,hero,float(result.stoneform_heal),"periodic","Stoneform")
		for effect_index in range(hero.guardian_runtime.delayed_effects.size()-1,-1,-1):
			var effect:Dictionary=hero.guardian_runtime.delayed_effects[effect_index];effect.remaining=float(effect.remaining)-delta
			if effect.remaining<=0.0:guardian_damage_near(hero,effect.point,float(effect.radius),float(effect.amount),"Thunder Burn");hero.guardian_runtime.delayed_effects.remove_at(effect_index)
			else:hero.guardian_runtime.delayed_effects[effect_index]=effect
		if GuardianSystem.has_talent(hero,"guardian_l21_1"):
			hero.guardian_runtime.bronzebeard_tick=float(hero.guardian_runtime.bronzebeard_tick)-delta
			if hero.guardian_runtime.bronzebeard_tick<=0.0:
				hero.guardian_runtime.bronzebeard_tick+=1.0;var total:=0.0;var aura:=guardian_scaled(hero,"bronzebeard_damage")*(3.0 if hero.guardian_runtime.bronzebeard_empowered>0.0 else 1.0)
				for foe in enemies:
					if foe.hp>0 and foe.pos.distance_to(hero.pos)<=float(GuardianData.SPACE.aura_radius):var dealt:=deal_damage(hero,foe,aura,"periodic","physical","Bronzebeard Rage",false,"bronzebeard");total+=float(dealt.health_damage)+float(dealt.shield_damage)
				if total>0.0:var healed:=deal_healing(hero,hero,total*0.75,"periodic","Bronzebeard Rage");GuardianSystem.telemetry_add(hero,"bronzebeard_damage",total);GuardianSystem.telemetry_add(hero,"bronzebeard_healing",float(healed.effective_amount))
