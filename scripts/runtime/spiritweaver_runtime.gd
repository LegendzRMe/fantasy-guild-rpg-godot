extends "res://scripts/runtime/vitalist_runtime.gd"

func spiritweaver_allies()->Array:return player_healable_units().filter(func(ally):return spiritweaver_is_hero(ally))
func spiritweaver_enemies()->Array:return enemies.filter(func(enemy):return float(enemy.get("hp",0.0))>0.0 and not CombatSystem.is_invulnerable(enemy))
func spiritweaver_is_hero(unit:Dictionary)->bool:return unit in heroes or bool(unit.get("permanent_companion",false)) and bool(unit.get("ordinary_heal_eligible",false))
func spiritweaver_scaled(hero:Dictionary,value:float)->float:return SpiritWeaverData.scaled(value,int(hero.get("level",1)))
func spiritweaver_visual(kind:String,from:Vector2,to:Vector2,life:float=.4,metadata:Dictionary={})->void:effects.append({"kind":kind,"from":from,"to":to,"life":life,"max_life":life,"text":"","color":CLASSES.get("Spirit Weaver",{"color":Color("60b9d2")}).color,"metadata":metadata})
func spiritweaver_has_control(hero:Dictionary)->bool:return hero.get("active_effects",[]).any(func(effect):return str(effect.get("control_type","")) in ["stun","root","silence","fear"] and float(effect.get("remaining_duration",0.0))>0.0)
func spiritweaver_has_control_type(hero:Dictionary,kind:String)->bool:return hero.get("active_effects",[]).any(func(effect):return str(effect.get("control_type",""))==kind and float(effect.get("remaining_duration",0.0))>0.0)
func spiritweaver_commit(hero:Dictionary)->void:
	var leaving:=bool(hero.spiritweaver_runtime.wolf_active);SpiritWeaverSystem.note_action(hero)
	if leaving and SpiritWeaverSystem.has_talent(hero,"spiritweaver_l9_3"):vitalist_apply_armor(hero,hero,spiritweaver_scaled(hero,float(SpiritWeaverData.VALUES.feral_armor)),float(SpiritWeaverData.VALUES.feral_armor_duration))

func spiritweaver_basic_heal_bounce(hero:Dictionary,primary:Dictionary)->void:
	var candidates:=spiritweaver_allies().filter(func(ally):return ally!=primary and float(ally.hp)>0.0 and Vector2(ally.pos).distance_to(Vector2(primary.pos))<=float(SpiritWeaverData.SPACE.basic_heal_bounce));candidates.sort_custom(func(a,b):var ar:=float(a.hp)/maxf(1.0,float(a.max_hp));var br:=float(b.hp)/maxf(1.0,float(b.max_hp));return ar<br if not is_equal_approx(ar,br) else str(a.combat_id)<str(b.combat_id));if candidates.is_empty():return
	var target:Dictionary=candidates[0];var result:=deal_healing(hero,target,float(hero.basic_heal_amount)*float(SpiritWeaverData.VALUES.basic_heal_bounce),"basic_heal",null,"spiritweaver_basic_heal_bounce",["healing","basic_action"]);SpiritWeaverSystem.add(hero,"basic_bounces");SpiritWeaverSystem.add(hero,"basic_heal_effective",float(result.effective_amount));SpiritWeaverSystem.add(hero,"basic_heal_overheal",float(result.overhealing));spiritweaver_visual("spiritweaver_basic_bounce",primary.pos,target.pos,.3)
func resolve_spiritweaver_basic_heal(hero:Dictionary,target:Dictionary,result:Dictionary)->void:
	SpiritWeaverSystem.add(hero,"basic_heals");SpiritWeaverSystem.add(hero,"basic_heal_effective",float(result.effective_amount));SpiritWeaverSystem.add(hero,"basic_heal_overheal",float(result.overhealing));spiritweaver_basic_heal_bounce(hero,target);spiritweaver_commit(hero)
func spiritweaver_self_w(hero:Dictionary):
	for shield in hero.spiritweaver_runtime.lightning_shields:
		if str(shield.bearer_id)==str(hero.combat_id) and float(shield.remaining)>0.0:return shield
	return null
func resolve_spiritweaver_basic_attack(hero:Dictionary,target:Dictionary,result:Dictionary)->void:
	SpiritWeaverSystem.add(hero,"basic_attacks");SpiritWeaverSystem.add(hero,"basic_damage",float(result.resolved_damage));var wolf:=bool(hero.spiritweaver_runtime.wolf_active)
	if wolf:
		var bonus:=float(result.get("raw_amount",hero.damage))*float(SpiritWeaverData.VALUES.wolf_attack_bonus);var bonus_hit:=deal_damage(hero,target,bonus,"trait","physical","Ghost Wolf Lunge",false,"spiritweaver_wolf",[],true);SpiritWeaverSystem.add(hero,"wolf_lunges");SpiritWeaverSystem.add(hero,"wolf_bonus_damage",float(bonus_hit.resolved_damage));var self_w=spiritweaver_self_w(hero)
		if self_w!=null and SpiritWeaverSystem.has_talent(hero,"spiritweaver_l30_1"):var burst:=SpiritWeaverSystem.w_damage(hero,self_w)/float(SpiritWeaverData.VALUES.w_tick)*float(SpiritWeaverData.VALUES.cap_a_seconds);var burst_hit:=deal_damage(hero,target,burst,"trait","magical","Stormbound Fang",false,"spiritweaver_cap_a",[],true);SpiritWeaverSystem.add(hero,"cap_a_burst",float(burst_hit.resolved_damage))
	spiritweaver_commit(hero)
func spiritweaver_apply_purge_slow(hero:Dictionary,target:Dictionary)->Dictionary:
	var source_id:="spiritweaver_purge:%s"%str(hero.combat_id)
	var result:=StatusEffectSystem.apply_source_control(target,source_id,"slow",float(SpiritWeaverData.VALUES.d_slow_duration),float(SpiritWeaverData.VALUES.d_slow))
	if bool(result.applied):
		for effect in target.active_effects:
			if str(effect.get("id",""))=="control_slow:%s"%source_id:
				effect["decays"]=true
				effect["initial_duration"]=float(result.duration)
	return result
func spiritweaver_purge_retaliate(protected:Dictionary,attacker:Dictionary)->void:
	for effect in protected.get("active_effects",[]):
		if str(effect.get("effect_family",""))!="unstoppable" or not str(effect.get("source_id","")).begins_with("spiritweaver_purge:"):continue
		var owner=unit_by_combat_id(str(effect.source_id).trim_prefix("spiritweaver_purge:"));if owner!=null and SpiritWeaverSystem.has_talent(owner,"spiritweaver_l30_3"):spiritweaver_apply_purge_slow(owner,attacker);SpiritWeaverSystem.add(owner,"cap_c_retaliations")

func spiritweaver_q_candidates(origin:Vector2,healed:Array,range_limit:float)->Array:
	return spiritweaver_allies().filter(func(ally):return str(ally.combat_id) not in healed and Vector2(ally.pos).distance_to(origin)<=range_limit)
func spiritweaver_choose_q(hero:Dictionary,candidates:Array,lowest:bool):
	if candidates.is_empty():return null
	candidates.sort_custom(func(a,b):
		if lowest:
			var ar:=float(a.hp)/maxf(1.0,float(a.max_hp));var br:=float(b.hp)/maxf(1.0,float(b.max_hp));if not is_equal_approx(ar,br):return ar<br
		return str(a.combat_id)<str(b.combat_id))
	return candidates[0]
func spiritweaver_resolve_q(hero:Dictionary,initial:Dictionary,untalented:bool=false,multiplier:float=1.0)->Dictionary:
	var cast_id:="%s:q:%d"%[str(hero.combat_id),int(hero.spiritweaver_runtime.next_cast_id)];hero.spiritweaver_runtime.next_cast_id=int(hero.spiritweaver_runtime.next_cast_id)+1;var remaining:=SpiritWeaverSystem.q_recipient_count(hero,untalented);var healed:Array=[];var relays:Array=[];var origin:=Vector2(initial.pos);var target=initial;var initial_id:=str(initial.combat_id)
	while target!=null and remaining>0:
		var target_id:=str(target.combat_id);var inside:bool=not hero.spiritweaver_runtime.totem.is_empty() and Vector2(target.pos).distance_to(Vector2(hero.spiritweaver_runtime.totem.pos))<=SpiritWeaverSystem.totem_radius(hero);var amount:=spiritweaver_scaled(hero,float(SpiritWeaverData.VALUES.q_heal))*multiplier*(1.0+float(SpiritWeaverData.VALUES.cap_b_area_bonus) if not untalented and inside and SpiritWeaverSystem.has_talent(hero,"spiritweaver_l30_2") else 1.0);var before_ratio:=float(target.hp)/maxf(1.0,float(target.max_hp));var result:=deal_healing(hero,target,amount,"periodic" if untalented else "basic_ability",null,"spiritweaver_wellspring" if untalented else "spiritweaver_q",["healing"]);healed.append(target_id);SpiritWeaverSystem.add(hero,"q_recipients");SpiritWeaverSystem.add(hero,"q_healing",amount);SpiritWeaverSystem.add(hero,"q_effective",float(result.effective_amount));SpiritWeaverSystem.add(hero,"q_overheal",float(result.overhealing));if not untalented and SpiritWeaverSystem.has_talent(hero,"spiritweaver_l12_1") and before_ratio<.5:hero.spiritweaver_runtime.earthliving.append({"target_id":target_id,"remaining":float(SpiritWeaverData.VALUES.earthliving_duration),"tick":float(SpiritWeaverData.VALUES.earthliving_tick)});if not untalented and SpiritWeaverSystem.has_talent(hero,"spiritweaver_l21_1"):hero.ability_cds[0]=maxf(0.0,float(hero.ability_cds[0])-float(SpiritWeaverData.VALUES.tidal_cdr));SpiritWeaverSystem.add(hero,"tidal_reductions")
		var free_spirit:=not untalented and target_id!=initial_id and target_id==str(hero.combat_id) and SpiritWeaverSystem.has_talent(hero,"spiritweaver_l30_2") and "spirit" not in relays;if free_spirit:relays.append("spirit");SpiritWeaverSystem.add(hero,"q_relays")
		if not free_spirit:remaining-=1
		origin=Vector2(target.pos);var candidates:=spiritweaver_q_candidates(origin,healed,float(SpiritWeaverData.SPACE.q_bounce))
		if candidates.is_empty() and not untalented and SpiritWeaverSystem.has_talent(hero,"spiritweaver_l24_3") and "totem" not in relays and not hero.spiritweaver_runtime.totem.is_empty() and origin.distance_to(Vector2(hero.spiritweaver_runtime.totem.pos))<=float(SpiritWeaverData.SPACE.q_bounce):var relay_candidates:=spiritweaver_q_candidates(Vector2(hero.spiritweaver_runtime.totem.pos),healed,float(SpiritWeaverData.SPACE.q_bounce));if not relay_candidates.is_empty():relays.append("totem");origin=Vector2(hero.spiritweaver_runtime.totem.pos);candidates=relay_candidates;SpiritWeaverSystem.add(hero,"q_relays")
		target=spiritweaver_choose_q(hero,candidates,not untalented and SpiritWeaverSystem.has_talent(hero,"spiritweaver_l30_2"))
	hero.spiritweaver_runtime.latest_q={"cast_id":cast_id,"healed":healed,"relays":relays};return hero.spiritweaver_runtime.latest_q
func cast_spiritweaver_q(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[0])>0.0:return false
	var candidates:=spiritweaver_allies().filter(func(ally):return Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(SpiritWeaverData.SPACE.q_range));candidates.sort_custom(func(a,b):return Vector2(a.pos).distance_to(point)<Vector2(b.pos).distance_to(point));if candidates.is_empty():return false
	hero.ability_cds[0]=float(SpiritWeaverData.VALUES.q_cooldown);SpiritWeaverSystem.add(hero,"q_casts");spiritweaver_resolve_q(hero,candidates[0]);spiritweaver_commit(hero);spiritweaver_visual("spiritweaver_q",hero.pos,candidates[0].pos,.45);return true

func cast_spiritweaver_w(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[1])>0.0:return false
	var candidates:=spiritweaver_allies()
	var totem:Dictionary=hero.spiritweaver_runtime.totem
	if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l18_1") and not totem.is_empty():
		candidates.append(totem)
	candidates=candidates.filter(func(ally):return Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(SpiritWeaverData.SPACE.w_range))
	candidates.sort_custom(func(a,b):return Vector2(a.pos).distance_to(point)<Vector2(b.pos).distance_to(point))
	if candidates.is_empty():return false
	var bearer:Dictionary=candidates[0]
	if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l18_1") and not totem.is_empty() and Vector2(totem.pos).distance_to(Vector2(hero.pos))<=float(SpiritWeaverData.SPACE.w_range) and Vector2(totem.pos).distance_to(point)<=Vector2(bearer.pos).distance_to(point):
		bearer=totem
	var bearer_is_totem:bool=not totem.is_empty() and str(bearer.get("combat_id",""))==str(totem.get("combat_id",""))
	hero.ability_cds[1]=float(SpiritWeaverData.VALUES.w_cooldown)
	SpiritWeaverSystem.create_w(hero,str(bearer.combat_id),bearer_is_totem)
	if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l21_2") and not bearer_is_totem:
		apply_unit_shield(hero,bearer,float(bearer.max_hp)*float(SpiritWeaverData.VALUES.earth_shield),null,"spiritweaver_earth_shield",INF,float(SpiritWeaverData.VALUES.earth_shield_duration))
	spiritweaver_commit(hero)
	spiritweaver_visual("spiritweaver_w",hero.pos,bearer.pos,.45)
	return true
func spiritweaver_valid_ground(point:Vector2)->Vector2:return point if CombatGeometry.valid_position(point,12.0,combat_blockers,"spiritweaver_totem") else Vector2.INF
func cast_spiritweaver_e(hero:Dictionary,point:Vector2)->bool:
	var offset:=point-Vector2(hero.pos)
	var clamped:Vector2=Vector2(hero.pos)+offset.limit_length(float(SpiritWeaverData.SPACE.e_range))
	var totem:Dictionary=hero.spiritweaver_runtime.totem
	if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l9_2") and not totem.is_empty() and not bool(totem.repositioned):
		var reposition:Vector2=spiritweaver_valid_ground(clamped)
		if reposition!=clamped:return false
		totem.pos=reposition
		totem.repositioned=true
		SpiritWeaverSystem.add(hero,"e_repositions")
		spiritweaver_commit(hero)
		spiritweaver_visual("spiritweaver_totem_move",hero.pos,reposition,.4)
		return true
	if float(hero.ability_cds[2])>0.0:return false
	var location:=spiritweaver_valid_ground(clamped)
	if location!=clamped:return false
	hero.ability_cds[2]=float(SpiritWeaverData.VALUES.e_cooldown)
	var placed:=SpiritWeaverSystem.create_totem(hero,location)
	if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l24_2"):
		for enemy in spiritweaver_enemies():
			if Vector2(enemy.pos).distance_to(location)<=SpiritWeaverSystem.totem_radius(hero):
				var hit:=deal_damage(hero,enemy,spiritweaver_scaled(hero,float(SpiritWeaverData.VALUES.earthgrasp_damage)),"basic_ability","magical","Earthgrasp Totem",false,"spiritweaver_earthgrasp",[],true)
				SpiritWeaverSystem.add(hero,"e_damage",float(hit.resolved_damage))
	spiritweaver_commit(hero)
	spiritweaver_visual("spiritweaver_totem",hero.pos,placed.pos,.5)
	return true
func cast_spiritweaver_d(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[4])>0.0:return false
	var purge_range:=float(SpiritWeaverData.SPACE.purge_range)
	var allies:=spiritweaver_allies().filter(func(ally):return (ally!=hero or SpiritWeaverSystem.has_talent(hero,"spiritweaver_l30_3")) and Vector2(ally.pos).distance_to(Vector2(hero.pos))<=purge_range)
	var foes:=spiritweaver_enemies().filter(func(enemy):return TargetCategorySystem.qualifies_immediate(enemy) and Vector2(enemy.pos).distance_to(Vector2(hero.pos))<=purge_range)
	allies.sort_custom(func(a,b):return Vector2(a.pos).distance_to(point)<Vector2(b.pos).distance_to(point));foes.sort_custom(func(a,b):return Vector2(a.pos).distance_to(point)<Vector2(b.pos).distance_to(point));var ally=allies[0] if not allies.is_empty() else null;var foe=foes[0] if not foes.is_empty() else null;var use_ally:=ally!=null and (foe==null or Vector2(ally.pos).distance_to(point)<=Vector2(foe.pos).distance_to(point))
	if use_ally:
		var purge:=StatusEffectSystem.apply_source_unstoppable(ally,"spiritweaver_purge:%s"%str(hero.combat_id),float(SpiritWeaverData.VALUES.d_unstoppable));SpiritWeaverSystem.add(hero,"d_ally");SpiritWeaverSystem.add(hero,"d_removed",purge.removed.size());if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l18_2") and not purge.removed.is_empty():var healed:=deal_healing(hero,ally,spiritweaver_scaled(hero,float(SpiritWeaverData.VALUES.purification_heal)),"trait",null,"spiritweaver_purification",["healing"]);SpiritWeaverSystem.add(hero,"purification_healing",float(healed.effective_amount))
	elif foe!=null:
		spiritweaver_apply_purge_slow(hero,foe)
		var dispelled:=StatusEffectSystem.remove_dispellable_positive_effects(foe)
		SpiritWeaverSystem.add(hero,"d_removed",dispelled.size())
		SpiritWeaverSystem.add(hero,"d_enemy")
		if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l18_2"):var removed:=minf(float(foe.get("shield",0.0)),spiritweaver_scaled(hero,float(SpiritWeaverData.VALUES.purification_shield_damage)));foe.shield=maxf(0.0,float(foe.get("shield",0.0))-removed);SpiritWeaverSystem.add(hero,"shield_removed",removed);HealingReceivedModifierSystem.apply(foe,"spiritweaver_purification:%s"%str(hero.combat_id),-float(SpiritWeaverData.VALUES.purification_antiheal),float(SpiritWeaverData.VALUES.purification_duration),str(hero.combat_id));SpiritWeaverSystem.add(hero,"antiheal_time",float(SpiritWeaverData.VALUES.purification_duration))
	else:return false
	hero.ability_cds[4]=float(SpiritWeaverData.VALUES.d_cooldown);SpiritWeaverSystem.add(hero,"d_casts");spiritweaver_commit(hero);spiritweaver_visual("spiritweaver_purge",hero.pos,ally.pos if use_ally else foe.pos,.4);return true

func cast_spiritweaver_r(hero:Dictionary,point:Vector2)->bool:
	if float(hero.ability_cds[3])>0.0:return false
	if str(hero.selected_heroic_id)=="spiritweaver_l15_r1":
		var candidates:=spiritweaver_allies().filter(func(ally):return ally!=hero and Vector2(ally.pos).distance_to(Vector2(hero.pos))<=float(SpiritWeaverData.SPACE.ancestral_range));candidates.sort_custom(func(a,b):return Vector2(a.pos).distance_to(point)<Vector2(b.pos).distance_to(point));if candidates.is_empty():return false
		hero.ability_cds[3]=float(SpiritWeaverData.VALUES.ancestral_cooldown);hero.spiritweaver_runtime.pending_ancestral.append({"target_id":str(candidates[0].combat_id),"remaining":float(SpiritWeaverData.VALUES.ancestral_delay),"secondary":false});SpiritWeaverSystem.add(hero,"ancestral_casts");spiritweaver_commit(hero);return true
	var radius:=float(SpiritWeaverData.SPACE.bloodlust_radius)*(float(SpiritWeaverData.VALUES.war_shout_multiplier) if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l27_r2") else 1.0);var duration:=float(SpiritWeaverData.VALUES.bloodlust_duration)*(float(SpiritWeaverData.VALUES.war_shout_multiplier) if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l27_r2") else 1.0);var recipients:=spiritweaver_allies().filter(func(ally):return spiritweaver_is_hero(ally) and Vector2(ally.pos).distance_to(Vector2(hero.pos))<=radius)
	for ally in recipients:ally.active_effects=StatusEffectSystem.strongest_refresh(ally.get("active_effects",[]),{"id":"bloodlust:%s"%str(hero.combat_id),"source_id":str(hero.combat_id),"effect_family":"bloodlust","remaining_duration":duration,"movement_speed_multiplier":1.0+float(SpiritWeaverData.VALUES.bloodlust_move),"basic_action_speed":float(SpiritWeaverData.VALUES.bloodlust_speed),"basic_attack_leech":float(SpiritWeaverData.VALUES.bloodlust_leech)});SpiritWeaverSystem.add(hero,"bloodlust_recipients")
	hero.ability_cds[3]=float(SpiritWeaverData.VALUES.bloodlust_cooldown);SpiritWeaverSystem.add(hero,"bloodlust_casts");spiritweaver_commit(hero);spiritweaver_visual("spiritweaver_bloodlust",hero.pos,hero.pos,.7,{"radius":radius});return true
func cast_spiritweaver_ability(slot:int,point:Vector2)->bool:
	if selected<0 or selected>=heroes.size():return false
	var hero:Dictionary=heroes[selected];if str(hero.get("class",""))!="Spirit Weaver" or hero.get("spiritweaver_runtime",{}).is_empty() or float(hero.hp)<=0.0:return false
	if spiritweaver_has_control_type(hero,"silence") or spiritweaver_has_control_type(hero,"fear"):return false
	if spiritweaver_has_control_type(hero,"stun") and not (slot==4 and SpiritWeaverSystem.has_talent(hero,"spiritweaver_l30_3") and point.distance_to(Vector2(hero.pos))<58.0):return false
	match slot:
		0:return cast_spiritweaver_q(hero,point)
		1:return cast_spiritweaver_w(hero,point)
		2:return cast_spiritweaver_e(hero,point)
		3:return cast_spiritweaver_r(hero,point)
		4:return cast_spiritweaver_d(hero,point)
	return false

func spiritweaver_w_tick(hero:Dictionary,shield:Dictionary)->void:
	var bearer=unit_by_combat_id(str(shield.bearer_id));if bearer==null or float(bearer.get("hp",0.0))<=0.0:shield.remaining=0.0;return
	var contacts:=spiritweaver_enemies().filter(func(enemy):return Vector2(enemy.pos).distance_to(Vector2(bearer.pos))<=float(SpiritWeaverData.SPACE.w_radius)*(1.0+float(SpiritWeaverData.VALUES.stormcaller_radius) if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l9_1") else 1.0));contacts.sort_custom(func(a,b):return str(a.combat_id)<str(b.combat_id))
	for enemy in contacts:var hit:=deal_damage(hero,enemy,SpiritWeaverSystem.w_damage(hero,shield),"periodic","magical","Lightning Shield",false,"spiritweaver_w",[],true);SpiritWeaverSystem.note_w_contact(hero,shield,bearer,float(hit.resolved_damage),enemy);if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l12_2"):var healed:=deal_healing(hero,bearer,float(hit.resolved_damage)*(float(SpiritWeaverData.VALUES.electric_self_heal) if bearer==hero else float(SpiritWeaverData.VALUES.electric_heal)),"talent",null,"spiritweaver_electric",["healing"]);SpiritWeaverSystem.add(hero,"electric_healing",float(healed.effective_amount));bearer.active_effects=StatusEffectSystem.strongest_refresh(bearer.get("active_effects",[]),{"id":"electric_charge:%s"%str(shield.cast_id),"remaining_duration":float(SpiritWeaverData.VALUES.w_tick)+.1,"movement_speed_multiplier":1.0+float(SpiritWeaverData.VALUES.electric_move)})
func spiritweaver_totem_slow(hero:Dictionary)->void:
	var totem:Dictionary=hero.spiritweaver_runtime.totem;if totem.is_empty():return
	var slow:=float(SpiritWeaverData.VALUES.earthgrasp_slow) if float(totem.earthgrasp_remaining)>0.0 else float(SpiritWeaverData.VALUES.grounded_slow) if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l18_1") else float(SpiritWeaverData.VALUES.e_slow)
	for enemy in spiritweaver_enemies():if Vector2(enemy.pos).distance_to(Vector2(totem.pos))<=SpiritWeaverSystem.totem_radius(hero):var applied:=StatusEffectSystem.apply_source_control(enemy,"spiritweaver_totem:%s"%str(hero.combat_id),"slow",.35,slow);if bool(applied.applied):SpiritWeaverSystem.add(hero,"e_slow_time",.25)
func spiritweaver_totem_heal(hero:Dictionary)->void:
	var totem:Dictionary=hero.spiritweaver_runtime.totem;if totem.is_empty():return
	for ally in spiritweaver_allies():if Vector2(ally.pos).distance_to(Vector2(totem.pos))<=SpiritWeaverSystem.totem_radius(hero):var result:=deal_healing(hero,ally,float(ally.max_hp)*float(SpiritWeaverData.VALUES.healing_totem_percent),"periodic",null,"spiritweaver_healing_totem",["healing"]);SpiritWeaverSystem.add(hero,"healing_totem_healing",float(result.effective_amount))
func spiritweaver_wellspring(hero:Dictionary)->void:
	var totem:Dictionary=hero.spiritweaver_runtime.totem;if totem.is_empty():return
	var candidates:=spiritweaver_allies().filter(func(ally):return Vector2(ally.pos).distance_to(Vector2(totem.pos))<=float(SpiritWeaverData.SPACE.q_range));candidates.sort_custom(func(a,b):return float(a.hp)/maxf(1.0,float(a.max_hp))<float(b.hp)/maxf(1.0,float(b.max_hp)));if candidates.is_empty():return
	spiritweaver_resolve_q(hero,candidates[0],true,float(SpiritWeaverData.VALUES.wellspring_multiplier));SpiritWeaverSystem.add(hero,"wellspring_casts")
func spiritweaver_ancestral(hero:Dictionary,pending:Dictionary)->void:
	var target=unit_by_combat_id(str(pending.target_id));if target==null or float(target.get("hp",0.0))<=0.0:return
	var result:=deal_healing(hero,target,spiritweaver_scaled(hero,float(SpiritWeaverData.VALUES.ancestral_heal)),"heroic",null,"spiritweaver_ancestral",["healing"]);SpiritWeaverSystem.add(hero,"ancestral_healing",float(result.effective_amount));spiritweaver_visual("spiritweaver_ancestral",hero.pos,target.pos,.6)
	if not bool(pending.secondary) and SpiritWeaverSystem.has_talent(hero,"spiritweaver_l27_r1"):hero.spiritweaver_runtime.pending_ancestral.append({"target_id":str(target.combat_id),"remaining":float(SpiritWeaverData.VALUES.farseer_delay),"secondary":true})
	elif bool(pending.secondary):for ally in spiritweaver_allies():if ally!=target and Vector2(ally.pos).distance_to(Vector2(target.pos))<=float(SpiritWeaverData.SPACE.farseer_radius):var area:=deal_healing(hero,ally,spiritweaver_scaled(hero,float(SpiritWeaverData.VALUES.farseer_area_heal)),"heroic",null,"spiritweaver_farseer",["healing"]);SpiritWeaverSystem.add(hero,"ancestral_healing",float(area.effective_amount))
func spiritweaver_earthliving(hero:Dictionary,hot:Dictionary)->void:
	var target=unit_by_combat_id(str(hot.target_id));if target==null or float(target.get("hp",0.0))<=0.0:return
	var result:=deal_healing(hero,target,spiritweaver_scaled(hero,float(SpiritWeaverData.VALUES.earthliving_heal))/4.0,"periodic",null,"spiritweaver_earthliving",["healing"]);SpiritWeaverSystem.add(hero,"earthliving",float(result.effective_amount))
func update_spiritweaver_runtime(delta:float)->void:
	for hero in heroes:
		if str(hero.get("class",""))!="Spirit Weaver" or hero.get("spiritweaver_runtime",{}).is_empty():continue
		for event in SpiritWeaverSystem.advance(hero,delta):
			match str(event.kind):
				"wolf_enter":if SpiritWeaverSystem.has_talent(hero,"spiritweaver_l9_3"):vitalist_apply_armor(hero,hero,spiritweaver_scaled(hero,float(SpiritWeaverData.VALUES.feral_armor)),float(SpiritWeaverData.VALUES.feral_armor_duration));spiritweaver_visual("spiritweaver_wolf",hero.pos,hero.pos,.4)
				"w_tick":spiritweaver_w_tick(hero,event.shield)
				"earthliving":spiritweaver_earthliving(hero,event.hot)
				"totem_slow":spiritweaver_totem_slow(hero)
				"totem_heal":spiritweaver_totem_heal(hero)
				"wellspring":spiritweaver_wellspring(hero)
				"ancestral":spiritweaver_ancestral(hero,event.pending)
				"totem_end":SpiritWeaverSystem.add(hero,"e_destroyed")
		hero.ability_cds[4]=maxf(0.0,float(hero.ability_cds[4])-delta*(SpiritWeaverSystem.purge_recharge_rate(hero)-1.0))
