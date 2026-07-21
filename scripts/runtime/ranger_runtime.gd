extends "res://scripts/runtime/cleric_runtime.gd"

func ranger_target_at(point:Vector2,max_distance:float=80.0):
	var best=null;var distance:=max_distance
	for foe in enemies:
		if foe.hp<=0:continue
		var candidate:float=foe.pos.distance_to(point)
		if candidate<distance:distance=candidate;best=foe
	return best

func ranger_scaled(hero:Dictionary,value:float)->float:return RangerData.scaled(value,int(hero.get("level",1)))

func ranger_clamped_point(hero:Dictionary,point:Vector2,range_limit:float)->Vector2:
	var offset:Vector2=point-Vector2(hero.pos)
	var destination:Vector2=point if offset.length()<=range_limit else Vector2(hero.pos)+offset.normalized()*range_limit
	return destination.clamp(Vector2(55,70),Vector2(1225,620))

func ranger_damage(hero:Dictionary,target:Dictionary,amount:float,action:String,origin:String,can_crit=true)->Dictionary:
	var multiplier:=1.10 if RangerSystem.has_talent(hero,"ranger_l24_2") and int(hero.ranger_runtime.hatred)>=int(RangerData.VALUES.hatred_max) else 1.0
	return deal_damage(hero,target,amount*multiplier,action,"physical",origin,false,"",[],can_crit)

func cast_ranger_q(hero:Dictionary,point:Vector2)->bool:
	var direction:Vector2=hero.pos.direction_to(point);if direction==Vector2.ZERO:direction=hero.facing_direction
	var candidates:Array=[]
	for foe in enemies:
		if foe.hp<=0:continue
		var projection:float=(foe.pos-hero.pos).dot(direction)
		if projection>=0.0 and projection<=float(RangerData.SPACE.q_range) and foe.pos.distance_to(hero.pos+direction*projection)<=float(RangerData.SPACE.q_hitbox):candidates.append(foe)
	if candidates.is_empty():hero.ability_cds[0]=float(RangerData.VALUES.q_cooldown);RangerSystem.telemetry_add(hero,"q_casts");return true
	candidates.sort_custom(func(a,b):return hero.pos.distance_squared_to(a.pos)<hero.pos.distance_squared_to(b.pos) or hero.pos.distance_squared_to(a.pos)==hero.pos.distance_squared_to(b.pos) and str(a.combat_id)<str(b.combat_id))
	var target:Dictionary=candidates[0];var initial:=ranger_scaled(hero,float(RangerData.VALUES.q_initial_damage))+float(hero.ranger_runtime.q_encounter_bonus)
	if RangerSystem.has_talent(hero,"ranger_l18_1") and not bool(target.get("boss",false)):initial*=2.0
	if RangerSystem.has_talent(hero,"ranger_l18_2") and CombatSystem.control_amount(target,"slow")>0.0:initial*=1.25
	var result:=ranger_damage(hero,target,initial,"basic_ability","Hungering Arrow");RangerSystem.telemetry_add(hero,"q_hits")
	if RangerSystem.has_talent(hero,"ranger_l9_1") and RangerSystem.qualifying_target(target):hero.ranger_runtime.q_encounter_bonus=minf(6000.0,float(hero.ranger_runtime.q_encounter_bonus)+6.0)
	if RangerSystem.has_talent(hero,"ranger_l21_1") and result.resolved_damage>0:deal_healing(hero,hero,float(hero.max_hp)*0.04,"basic_ability","Siphoning Arrow")
	var seeks:=int(RangerData.VALUES.q_seek_count)+(1 if RangerSystem.has_talent(hero,"ranger_l9_1") else 0);var seek_source:Dictionary=target
	for seek in seeks:
		var next=null;var best_distance:=float(RangerData.SPACE.q_seek_radius)
		for foe in enemies:
			if foe.hp<=0:continue
			var d:float=seek_source.pos.distance_to(foe.pos)
			if d<=best_distance:best_distance=d;next=foe
		if next==null:break
		var seek_amount:=ranger_scaled(hero,float(RangerData.VALUES.q_seek_damage))+float(hero.ranger_runtime.q_encounter_bonus)
		if RangerSystem.has_talent(hero,"ranger_l18_1") and not bool(next.get("boss",false)):seek_amount*=2.0
		if RangerSystem.has_talent(hero,"ranger_l18_2") and CombatSystem.control_amount(next,"slow")>0.0:seek_amount*=1.25
		var seek_result:=ranger_damage(hero,next,seek_amount,"basic_ability","Hungering Arrow Seek");RangerSystem.telemetry_add(hero,"q_hits");RangerSystem.telemetry_add(hero,"q_seeks")
		if RangerSystem.has_talent(hero,"ranger_l21_1") and seek_result.resolved_damage>0:deal_healing(hero,hero,float(hero.max_hp)*0.04,"basic_ability","Siphoning Arrow")
		seek_source=next
	hero.ability_cds[0]=float(RangerData.VALUES.q_cooldown);RangerSystem.telemetry_add(hero,"q_casts");return true

func cast_ranger_w(hero:Dictionary,point:Vector2)->bool:
	var direction:Vector2=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	var range_limit:=float(RangerData.SPACE.w_end_radius)*(1.2 if RangerSystem.has_talent(hero,"ranger_l12_1") else 1.0);var hit_count:=0
	for foe in enemies:
		if foe.hp<=0:continue
		var offset:Vector2=foe.pos-hero.pos;var angle:=absf(rad_to_deg(direction.angle_to(offset.normalized())))
		if offset.length()<=range_limit and angle<=float(RangerData.VALUES.w_angle)*0.5:
			var amount:=ranger_scaled(hero,float(RangerData.VALUES.w_damage))+float(hero.ranger_runtime.w_encounter_bonus);var hit:=ranger_damage(hero,foe,amount,"basic_ability","Multishot");hit_count+=1
			if RangerSystem.has_talent(hero,"ranger_l18_2"):CombatSystem.apply_control(foe,"slow",2.5,0.20)
			if RangerSystem.has_talent(hero,"ranger_l21_1") and hit_count<=5 and hit.resolved_damage>0:deal_healing(hero,hero,float(hero.max_hp)*0.02,"basic_ability","Siphoning Arrow")
			if RangerSystem.has_talent(hero,"ranger_l9_2") and RangerSystem.qualifying_target(foe):
				RangerSystem.add_hatred(hero,2);hero.ranger_runtime.w_quest_hits=int(hero.ranger_runtime.w_quest_hits)+1;hero.ranger_runtime.w_encounter_bonus=float(hero.ranger_runtime.w_encounter_bonus)+2.0
				if not bool(hero.ranger_runtime.w_quest_rewarded) and int(hero.ranger_runtime.w_quest_hits)>=20:hero.ranger_runtime.w_quest_rewarded=true;hero.ranger_runtime.w_encounter_bonus=float(hero.ranger_runtime.w_encounter_bonus)+40.0
	if RangerSystem.has_talent(hero,"ranger_l12_1"):
		for grenade_offset in [-0.35,0.0,0.35]:
			var ray:Vector2=direction.rotated(grenade_offset);var grenade_point:Vector2=Vector2(hero.pos)+ray*range_limit;var grenade_target=ranger_target_at(grenade_point,60.0)
			if grenade_target!=null:ranger_damage(hero,grenade_target,ranger_scaled(hero,100.0),"basic_ability","Arsenal Grenade")
	hero.ability_cds[1]=float(RangerData.VALUES.w_cooldown);RangerSystem.telemetry_add(hero,"w_casts");RangerSystem.telemetry_add(hero,"w_hits",hit_count);return true

func cast_ranger_e(hero:Dictionary,point:Vector2)->bool:
	var slot:Dictionary=hero.ranger_runtime.slots.e
	if not AbilitySlotSystem.spend(slot,0.5 if RangerSystem.has_talent(hero,"ranger_l30_1") else 0.0):return false
	var start:Vector2=hero.pos;var destination:Vector2=ranger_clamped_point(hero,point,float(RangerData.SPACE.e_range));hero.pos=destination;hero.dest=destination;hero.facing_direction=start.direction_to(destination)
	clear_hero_command(hero,"Vault");hero.ranger_runtime.vault_hatred_snapshot=int(hero.ranger_runtime.hatred);hero.ranger_runtime.vault_empower_remaining=float(RangerData.VALUES.e_empower_duration)
	if RangerSystem.has_talent(hero,"ranger_l12_3"):hero.ability_cds[0]=0.0
	if RangerSystem.has_talent(hero,"ranger_l30_1"):
		for step in [0.25,0.5,0.75]:hero.ranger_runtime.caltrops.append({"pos":start.lerp(destination,step),"arm":0.5,"remaining":10.0,"hit_ids":{}})
	hero.ability_cds[2]=0.0 if int(slot.current_charges)>0 else (float(slot.timers[0]) if not slot.timers.is_empty() else 0.0);RangerSystem.telemetry_add(hero,"vault_casts");return true

func cast_ranger_heroic(hero:Dictionary,point:Vector2)->bool:
	var heroic:=str(hero.get("selected_heroic_id",""))
	if heroic in ["ranger_r1","ranger_l15_r1"]:
		hero.ranger_runtime.strafe_remaining=float(RangerData.VALUES.r1_duration);hero.ranger_runtime.strafe_tick=0.0;hero.ranger_runtime.strafe_locks={};hero.ability_cds[3]=float(RangerData.VALUES.r1_cooldown);RangerSystem.telemetry_add(hero,"strafe_casts");return true
	if heroic not in ["ranger_r2","ranger_l15_r2"]:return false
	var slot:Dictionary=hero.ranger_runtime.slots.r
	if not AbilitySlotSystem.spend(slot,0.25):return false
	var direction:Vector2=Vector2(hero.pos).direction_to(point);if direction==Vector2.ZERO:direction=Vector2(hero.facing_direction)
	begin_unit_cast(hero,3,float(RangerData.VALUES.r2_delay),true,0.0,false,0.0)
	hero.ranger_runtime.delayed_effects.append({"kind":"rain","remaining":float(RangerData.VALUES.r2_delay),"origin":hero.pos,"direction":direction})
	hero.ability_cds[3]=0.0 if int(slot.current_charges)>0 else float(slot.timers[0]);RangerSystem.telemetry_add(hero,"rain_casts");return true

func cast_ranger_ability(slot:int,point:Vector2,item_repeat:bool=false)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected]
	if str(hero.get("class",""))!="Ranger" or hero.get("ranger_runtime",{}).is_empty():return false
	if float(hero.ranger_runtime.strafe_remaining)>0.0 and slot in [0,1,3]:return false
	if slot in [0,1] and not item_repeat and float(hero.ability_cds[slot])>0.0:return false
	return cast_ranger_q(hero,point) if slot==0 else cast_ranger_w(hero,point) if slot==1 else cast_ranger_e(hero,point) if slot==2 else cast_ranger_heroic(hero,point)

func update_ranger_runtime(delta:float)->void:
	for hero in heroes:
		if hero.hp<=0 or str(hero.get("class",""))!="Ranger" or hero.get("ranger_runtime",{}).is_empty():continue
		var result:=RangerSystem.update(hero,delta)
		if float(result.gloom_heal)>0.0:deal_healing(hero,hero,float(result.gloom_heal),"periodic","Gloom")
		var e_slot:Dictionary=hero.ranger_runtime.slots.e;var r_slot:Dictionary=hero.ranger_runtime.slots.r
		hero.ability_cds[2]=0.0 if int(e_slot.current_charges)>0 else (float(e_slot.timers[0]) if not e_slot.timers.is_empty() else 0.0)
		hero.ability_cds[3]=float(hero.ability_cds[3]) if float(hero.ranger_runtime.strafe_remaining)>0.0 else (0.0 if int(r_slot.current_charges)>0 else (float(r_slot.timers[0]) if not r_slot.timers.is_empty() else 0.0)) if str(hero.selected_heroic_id) in ["ranger_r2","ranger_l15_r2"] else hero.ability_cds[3]
		var true_control:bool=hero.get("active_effects",[]).any(func(active):return str(active.get("control_type","")) in ["stun","root","silence"] and float(active.get("remaining_duration",0.0))>0.0)
		if true_control and float(hero.ranger_runtime.strafe_remaining)>0.0:hero.ranger_runtime.strafe_remaining=0.0;hero.ranger_runtime.strafe_locks={}
		if float(hero.ranger_runtime.strafe_remaining)>0.0:
			hero.ranger_runtime.strafe_remaining=maxf(0.0,float(hero.ranger_runtime.strafe_remaining)-delta);hero.ranger_runtime.strafe_tick-=delta
			for target_id in hero.ranger_runtime.strafe_locks:hero.ranger_runtime.strafe_locks[target_id]=maxf(0.0,float(hero.ranger_runtime.strafe_locks[target_id])-delta)
			while float(hero.ranger_runtime.strafe_tick)<=0.0 and float(hero.ranger_runtime.strafe_remaining)>0.0:
				hero.ranger_runtime.strafe_tick+=1.0/float(RangerData.VALUES.r1_shots_per_second);var candidates:=enemies.filter(func(foe):return foe.hp>0 and foe.pos.distance_to(hero.pos)<=float(RangerData.SPACE.strafe_radius) and float(hero.ranger_runtime.strafe_locks.get(str(foe.combat_id),0.0))<=0.0)
				candidates.sort_custom(func(a,b):return hero.pos.distance_squared_to(a.pos)<hero.pos.distance_squared_to(b.pos) or hero.pos.distance_squared_to(a.pos)==hero.pos.distance_squared_to(b.pos) and str(a.combat_id)<str(b.combat_id))
				if not candidates.is_empty():var target:Dictionary=candidates[0];ranger_damage(hero,target,ranger_scaled(hero,float(RangerData.VALUES.r1_damage)),"heroic","Strafe");hero.ranger_runtime.strafe_locks[str(target.combat_id)]=float(RangerData.VALUES.r1_target_lockout);RangerSystem.telemetry_add(hero,"strafe_shots")
		for effect_index in range(hero.ranger_runtime.delayed_effects.size()-1,-1,-1):
			var effect:Dictionary=hero.ranger_runtime.delayed_effects[effect_index];effect.remaining-=delta
			if effect.remaining<=0.0:
				if not hero.get("active_cast",{}).is_empty():
					for foe in enemies:
						if foe.hp<=0:continue
						var offset:Vector2=foe.pos-effect.origin;var along:=offset.dot(effect.direction);var across:=absf(offset.cross(effect.direction))
						if along>=0.0 and along<=float(RangerData.SPACE.rain_length) and across<=float(RangerData.SPACE.rain_width)*0.5:ranger_damage(hero,foe,ranger_scaled(hero,float(RangerData.VALUES.r2_damage)),"heroic","Rain of Vengeance");CombatSystem.apply_control(foe,"stun",float(RangerData.VALUES.r2_stun));RangerSystem.telemetry_add(hero,"rain_hits")
				else:
					r_slot.current_charges=mini(int(r_slot.max_charges),int(r_slot.current_charges)+1)
					if not r_slot.timers.is_empty():r_slot.timers.remove_at(0)
					AbilitySlotSystem.set_lockout(r_slot,float(RangerData.VALUES.r2_interrupted_lockout))
				hero.ranger_runtime.delayed_effects.remove_at(effect_index)
			else:hero.ranger_runtime.delayed_effects[effect_index]=effect
		for hazard_index in range(hero.ranger_runtime.caltrops.size()-1,-1,-1):
			var hazard:Dictionary=hero.ranger_runtime.caltrops[hazard_index];hazard.arm-=delta;hazard.remaining-=delta
			if hazard.arm<=0.0:
				for foe in enemies:
					if foe.hp>0 and foe.pos.distance_to(hazard.pos)<=34.0 and not hazard.hit_ids.has(str(foe.combat_id)):hazard.hit_ids[str(foe.combat_id)]=true;ranger_damage(hero,foe,ranger_scaled(hero,60.0),"basic_ability","Caltrops");CombatSystem.apply_control(foe,"slow",1.0,0.40)
			if hazard.remaining<=0.0:hero.ranger_runtime.caltrops.remove_at(hazard_index)
			else:hero.ranger_runtime.caltrops[hazard_index]=hazard
