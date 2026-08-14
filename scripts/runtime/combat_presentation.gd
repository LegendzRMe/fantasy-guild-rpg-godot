extends "res://scripts/runtime/combat_effect_presentation.gd"

func octagon_points(center:Vector2,radius:float) -> PackedVector2Array:
	var points:=PackedVector2Array()
	for i in 8: points.append(center+Vector2(cos(PI/8+i*PI/4),sin(PI/8+i*PI/4))*radius)
	return points

func draw_octagon(center:Vector2,radius:float,fill:Color,outline:Color,width:float=3.0) -> void:
	var points=octagon_points(center,radius); draw_colored_polygon(points,fill); points.append(points[0]); draw_polyline(points,outline,width)

func draw_octagon_health(center:Vector2,radius:float,ratio:float) -> void:
	var points=octagon_points(center,radius);var edge_progress=clamp(ratio,0.0,1.0)*8.0
	for edge in 8:
		var fraction=clamp(edge_progress-edge,0.0,1.0)
		if fraction>0:draw_line(points[edge],points[edge].lerp(points[(edge+1)%8],fraction),C_GREEN,4)

func hero_channel_remaining_ratio(hero:Dictionary)->float:
	var channel:Dictionary=hero.get("active_channel",{})
	if not channel.is_empty():
		var duration:float=maxf(0.001,float(channel.get("duration",0.0)))
		return clampf(float(channel.get("remaining",0.0))/duration,0.0,1.0)
	var cleric_runtime:Dictionary=hero.get("cleric_runtime",{})
	if bool(cleric_runtime.get("jug_active",false)):
		return clampf(float(cleric_runtime.get("jug_remaining",0.0))/maxf(0.001,float(ClericData.VALUES.r1_duration)),0.0,1.0)
	return -1.0

func draw_hero_channel_bar(hero:Dictionary)->void:
	var ratio:=hero_channel_remaining_ratio(hero)
	if ratio<0.0:return
	var bar_position:=Vector2(hero.pos)+Vector2(-54,-58)
	draw_rect(Rect2(bar_position,Vector2(108,9)),Color("0d111a"))
	draw_rect(Rect2(bar_position+Vector2(2,2),Vector2(104*ratio,5)),Color("b77cff"))
	draw_rect(Rect2(bar_position,Vector2(108,9)),Color("e0c3ff"),false,1.5)

func rogue_concealment_visual_state(hero:Dictionary)->String:
	if not hero.has("concealment"):return ""
	if StealthDetectionSystem.is_invisible(hero):return "invisible"
	if bool(hero.get("rogue_runtime",{}).get("vanish_active",false)) or StealthDetectionSystem.is_stealthed(hero):return "vanished"
	return ""

func draw_rogue_concealment(hero:Dictionary,visual_state:String)->void:
	if visual_state=="":return
	var center:=Vector2(hero.pos)
	var rotation:float=fmod(battle_time*.9,TAU)
	if visual_state=="invisible":
		draw_circle(center,50,Color("d9f3ff",.06))
		for segment in 4:
			var start:float=rotation+segment*PI/2.0
			draw_arc(center,55,start,start+.52,10,Color("d9f3ff",.72),3)
		draw_arc(center,49,0,TAU,40,Color("b8ddff",.20),2)
	else:
		for segment in 6:
			var start:float=-rotation+segment*TAU/6.0
			draw_arc(center,56,start,start+.48,8,Color("c99cff",.78),3)
		draw_circle(center-Vector2(hero.get("facing_direction",Vector2.RIGHT))*12.0,43,Color("9f78df",.08))

func draw_octagon_vertical_fill(center:Vector2,radius:float,ratio:float,color:Color)->void:
	var points:=octagon_points(center,radius);var min_y:=points[0].y;var max_y:=points[0].y
	for point in points:min_y=minf(min_y,point.y);max_y=maxf(max_y,point.y)
	var cutoff:=lerpf(max_y,min_y,clampf(ratio,0.0,1.0));var clipped:=PackedVector2Array();var previous:=points[-1];var previous_inside:=previous.y>=cutoff
	for current in points:
		var current_inside:bool=current.y>=cutoff
		if current_inside!=previous_inside:
			var crossing:float=(cutoff-previous.y)/(current.y-previous.y)
			clipped.append(previous.lerp(current,crossing))
		if current_inside:clipped.append(current)
		previous=current;previous_inside=current_inside
	if clipped.size()>=3:draw_colored_polygon(clipped,color)

func draw_tutorial_dotted_path(from:Vector2,to:Vector2)->void:
	var length=from.distance_to(to)
	if length<1:return
	var direction=from.direction_to(to)
	var alpha=.8*(.5+.5*sin(tutorial_timer*3.2))
	var distance=fposmod(tutorial_timer*42.0,24.0)
	while distance<length:
		draw_circle(from+direction*distance,4.5,Color(C_GOLD,alpha))
		distance+=24.0

func draw_tutorial_glow(center:Vector2,radius:float,color:Color=C_GOLD)->void:
	var pulse=.5+.5*sin(tutorial_timer*4.0)
	var emphasis=1.55 if tutorial_reject_time>0 else 1.0
	draw_circle(center,radius+(8+pulse*5)*emphasis,Color(color,(.06+.06*pulse)*emphasis))
	draw_arc(center,radius+(7+pulse*3)*emphasis,0,TAU,48,Color(color,min(1.0,(.42+.35*pulse)*emphasis)),3*emphasis)

func draw_tutorial_box(rect:Rect2)->void:
	var pulse=.5+.5*sin(tutorial_timer*4.0)
	var emphasis=1.55 if tutorial_reject_time>0 else 1.0

	draw_rect(rect.grow((4+pulse*3)*emphasis),Color(C_GOLD,(.035+.035*pulse)*emphasis))
	draw_rect(rect.grow((2+pulse*2)*emphasis),Color(C_GOLD,min(1.0,(.5+.4*pulse)*emphasis)),false,3*emphasis)

func tutorial_should_show_instruction_box()->bool:
	return tutorial_active and tutorial_step!=8

func tutorial_should_show_ability_bar()->bool:
	if selected<0 or selected>=heroes.size():return false
	if not tutorial_active:return true
	return tutorial_step>=7 and (tutorial_step!=7 or selected==1)

func draw_damaged_caravan(center:Vector2) -> void:
	var body_rect:=Rect2(center+Vector2(-72,-24),Vector2(144,52))
	var canvas_points:=PackedVector2Array([center+Vector2(-58,-24),center+Vector2(-43,-58),center+Vector2(42,-58),center+Vector2(61,-24)])
	draw_colored_polygon(canvas_points,Color("c9b17d"))
	draw_polyline(PackedVector2Array([canvas_points[0],canvas_points[1],canvas_points[2],canvas_points[3]]),Color("7f6844"),4)
	draw_rect(body_rect,Color("805537"));draw_rect(body_rect,Color("d2a260"),false,4)
	for wheel_offset in [-43.0,43.0]:
		var wheel_center:=center+Vector2(wheel_offset,32)
		draw_circle(wheel_center,19,Color("28231f"));draw_circle(wheel_center,14,Color("765338"));draw_circle(wheel_center,4,Color("d2a260"))
		for spoke in 4:draw_line(wheel_center,wheel_center+Vector2.from_angle(spoke*PI/2.0)*13,Color("c18b50"),3)
	# Broken boards and torn canvas make its starting damage readable at a glance.
	draw_line(center+Vector2(-14,-22),center+Vector2(-2,1),Color("3c261f"),4)
	draw_line(center+Vector2(-2,1),center+Vector2(-13,23),Color("3c261f"),4)
	draw_line(center+Vector2(21,-55),center+Vector2(12,-38),Color("755d40"),3)
	draw_line(center+Vector2(12,-38),center+Vector2(27,-25),Color("755d40"),3)
	var health_ratio:float=objective_health/max(1.0,objective_max_health)
	health_bar(center+Vector2(-76,-82),152,health_ratio,C_GREEN if health_ratio>.45 else C_GOLD if health_ratio>.2 else C_RED)
	draw_string(ThemeDB.fallback_font,center+Vector2(-55,-91),"DAMAGED CARAVAN",HORIZONTAL_ALIGNMENT_CENTER,110,12,C_TEXT)

func draw_combat_background() -> void:
	# The composed clearing provides environmental depth while its open center
	# preserves the free-movement battlefield and readable combat telegraphs.
	draw_texture_rect(ASHWOOD_COMBAT_BACKGROUND,Rect2(0,0,W,H),false,Color("aeb8af"))
	draw_rect(Rect2(0,0,W,H),Color(0.025,0.045,0.04,.18))
	for x in range(0,1281,80):draw_line(Vector2(x,0),Vector2(x,H),Color(1,1,1,.018),1)
	for y in range(0,721,80):draw_line(Vector2(0,y),Vector2(W,y),Color(1,1,1,.018),1)

func draw_shared_combat_objects()->void:
	for blocker in combat_blockers:
		if not CombatGeometry.blocker_active(blocker):continue
		if str(blocker.get("shape","rect"))=="segment":
			draw_line(Vector2(blocker.from),Vector2(blocker.to),Color("66d8ff88"),float(blocker.thickness));draw_line(Vector2(blocker.from),Vector2(blocker.to),Color("dff8ff"),3)
			continue
		var fill:=Color("73513b") if bool(blocker.get("destructible",false)) else Color("465267")
		draw_rect(blocker.rect,fill);draw_rect(blocker.rect,C_GOLD if bool(blocker.get("destructible",false)) else C_MUTED,false,3)
		if bool(blocker.get("destructible",false)):
			health_bar(blocker.rect.position+Vector2(0,-12),blocker.rect.size.x,float(blocker.current_health)/maxf(1.0,float(blocker.maximum_health)),C_GOLD)
		if debug_combat_overlay:
			var flags:="M:%s  L:%s  P:%s"%[blocker.blocks_movement,blocker.blocks_line_of_sight,blocker.blocks_projectiles]
			draw_string(ThemeDB.fallback_font,blocker.rect.position+Vector2(-8,blocker.rect.size.y+17),flags,HORIZONTAL_ALIGNMENT_LEFT,-1,11,C_TEXT)
	for projectile in combat_projectiles:
		draw_line(projectile.previous_pos,projectile.pos,Color("f1d08b"),4);draw_circle(projectile.pos,5,Color.WHITE)

func draw_combat_debug_overlay()->void:
	if not debug_combat_overlay or selected<0 or selected>=heroes.size():return
	var hero:Dictionary=heroes[selected];var target=unit_by_combat_id(str(hero.get("assigned_target_id","")))
	var in_range:bool=target!=null and hero.pos.distance_to(target.pos)<=float(hero.get("range",0.0))
	var line_of_sight:bool=target!=null and CombatGeometry.has_line_of_sight(hero.pos,target.pos,combat_blockers)
	var cast_name:="none"
	if not hero.get("active_cast",{}).is_empty():cast_name="cast slot %d"%int(hero.active_cast.get("slot",-1))
	elif not hero.get("active_channel",{}).is_empty():cast_name="channel slot %d"%int(hero.active_channel.get("slot",-1))
	var lines:=["ID  %s"%hero.combat_id,"COMMAND  %s"%CombatRulesV1.command_name(int(hero.command_state)),"TARGET  %s (%s)"%[str(hero.assigned_target_id),str(hero.assigned_target_kind)],"ACTION  %s  %.2f"%[CombatRulesV1.phase_name(int(hero.basic_action_phase)),float(hero.basic_action_timer)],"READY AT  %.2f"%float(hero.next_action_ready_time),"IN RANGE  %s   LOS  %s"%[in_range,line_of_sight],"CAST  %s"%cast_name,"INCAPACITATED  %s"%bool(hero.incapacitated)]
	if str(hero.get("class",""))=="Warlock" and not hero.get("warlock_runtime",{}).is_empty():
		var runtime:Dictionary=hero.warlock_runtime;lines.append("TAP LOCK  %.2f"%float(runtime.life_tap_lockout));lines.append("DARKNESS  %.0f / %.0f"%[float(runtime.darkness_progress),float(WarlockData.VALUES.darkness_damage_requirement)]);lines.append("CORRUPTION  %d"%runtime.periodic_effects.size());lines.append("BANISHED  %.2f"%float(runtime.banished_remaining))
	if str(hero.get("class",""))=="Shaman" and not hero.get("shaman_runtime",{}).is_empty():
		var shaman:Dictionary=hero.shaman_runtime;lines.append("FROSTWOLF  %d / %d"%[int(shaman.frostwolf_stacks),int(ShamanData.VALUES.trait_threshold)]);lines.append("Q CHARGES  %d / %d"%[int(shaman.q_slot.current_charges),int(shaman.q_slot.max_charges)]);lines.append("WIND FURY  %d  %.2f"%[int(shaman.windfury_attacks),float(shaman.windfury_remaining)]);lines.append("ANCESTRAL  %d / %d%s"%[int(shaman.ancestral_stacks),int(ShamanData.VALUES.ancestral_max)," READY" if bool(shaman.ancestral_ready) else ""]);lines.append("GATHERING  %d / %d"%[int(shaman.gathering_stacks),int(ShamanData.VALUES.gathering_max)]);lines.append("THUNDER  %d / %d"%[int(shaman.thunder_stacks),int(ShamanData.VALUES.thunder_max)]);lines.append("ECHO/CRASH/MAEL  %d / %d / %d"%[int(shaman.encounter_progress.get("echo",0)),int(shaman.encounter_progress.get("crash",0)),int(shaman.encounter_progress.get("maelstrom",0))]);lines.append("MYTHIC  %d / %d / %d"%[ShamanSystem.mastery_progress(hero,"shaman_l9_1"),ShamanSystem.mastery_progress(hero,"shaman_l9_2"),ShamanSystem.mastery_progress(hero,"shaman_l9_3")])
	if str(hero.get("class",""))=="Templar" and not hero.get("templar_runtime",{}).is_empty():
		var templar:Dictionary=hero.templar_runtime;lines.append("OVERLOAD CD  %.2f"%float(templar.trait_cooldown));lines.append("D SHIELD  %.0f"%TemplarSystem.named_shield_amount(hero,"templar_shield_overload"));lines.append("PROTECTOR  %d"%int(templar.protector_stacks));lines.append("E DEPLETIONS  %d"%int(templar.give_twenty_depletions));lines.append("LINK BUCKET  %.1f"%float(templar.together_bucket))
	if str(hero.get("class",""))=="Protector" and not hero.get("protector_runtime",{}).is_empty():
		var protector:Dictionary=hero.protector_runtime;var owned_walls:Array=combat_blockers.filter(func(blocker):return ProtectorSystem.own_wall(hero,blocker));lines.append("SWORD  %s"%("ACTIVE" if not protector.q_sequence.is_empty() else "NONE"));lines.append("Q EMPOWERED  %s"%str(bool(protector.q_sequence.get("empowered",false))));lines.append("WALLS  %d  %s"%[owned_walls.size(),str(owned_walls.map(func(blocker):return "%s %.1f"%[str(blocker.cast_id),float(blocker.remaining_duration)]))]);lines.append("SMITE  %d/%d  FIELDS %d"%[int(protector.smite_slot.current_charges),int(protector.smite_slot.max_charges),protector.smite_fields.size()]);lines.append("LAST PURGE  %s"%str(protector.last_purge));lines.append("ASPECT CD  %.1f"%float(protector.aspect_cooldown));lines.append("WRATH  %s"%str(protector.wrath.get("phase","none")));lines.append("ARMOR SOURCES  %s"%str(ProtectorSystem.armor_sources(hero)))
	if str(hero.get("class",""))=="Sentinel" and not hero.get("sentinel_runtime",{}).is_empty():
		var sentinel:Dictionary=hero.sentinel_runtime;lines.append("Q CHARGES  %d / %d"%[int(sentinel.q_slot.current_charges),int(sentinel.q_slot.max_charges)]);lines.append("W CHARGES  %d / %d  SHOTS %d"%[int(sentinel.w_slot.current_charges),int(sentinel.w_slot.max_charges),sentinel.w_projectiles.size()]);lines.append("MARK  %s  %.1f"%[str(sentinel.marked_target_id),float(sentinel.mark_remaining)]);lines.append("FLARE QUEST  %d / 84"%int(sentinel.e_quest_stacks));lines.append("FLARES/FIELDS  %d / %d"%[sentinel.pending_flares.size(),sentinel.starfalls.size()]);lines.append("OVERFLOW  %.1f"%float(sentinel.overflow_bank));lines.append("TELEMETRY  %s"%str(sentinel.telemetry))
	if str(hero.get("class",""))=="Huntsman" and not hero.get("huntsman_runtime",{}).is_empty():
		var hunt:Dictionary=hero.huntsman_runtime;var recent_form_source:="none" if hunt.form_events.is_empty() else str(hunt.form_events[-1].source);var prepared_modifier:=HuntsmanSystem.prepare_basic_attack(hero,{"active_effects":[]})
		lines.append("FORM  %s  SOURCE %s"%[str(hunt.form).to_upper(),recent_form_source]);lines.append("BA RANGE %.1f  MOD %.2f  ARMOR %.1f"%[float(hero.range),float(prepared_modifier.multiplier),float(hero.armor)]);lines.append("Q HUMAN/WORGEN  %.1f / %.1f"%[float(hunt.human_q_cooldown),float(hunt.worgen_q_cooldown)]);lines.append("E SHARED  %.1f"%float(hunt.shared_e_cooldown));lines.append("INNER BEAST  %.1f (%.1f)"%[float(hunt.inner_beast_remaining),float(hunt.inner_beast_elapsed)]);lines.append("BLOCK %d  WIZENED %d / %.1f"%[BlockChargeSystem.charges(hero,"huntsman_block"),int(hunt.wizened_attacks),float(hunt.wizened_remaining)]);lines.append("MARK  %s  x%d  %.1f"%[str(hunt.marked_target_id),int(hunt.mark_stacks),float(hunt.mark_remaining)]);lines.append("COCKTAIL QUEST  %d / 15"%int(hunt.cocktail_quest_stacks));lines.append("TELEMETRY  %s"%str(hunt.telemetry))
	if str(hero.get("class",""))=="Druid" and not hero.get("druid_runtime",{}).is_empty():
		var druid:Dictionary=hero.druid_runtime;var designated=druid_ally_by_id(str(druid.designated_ally_id));var ally_distance:float=hero.pos.distance_to(designated.pos) if designated!=null else -1.0
		lines.append("LEVEL %d  POWER %.1f  HP %.1f%%"%[int(hero.level),float(hero.power),DruidSystem.health_ratio(hero)*100.0]);lines.append("BA %.1f / %.2fs  TARGET %s  DIST %.1f"%[float(hero.damage),float(hero.basic_attack_interval),str(druid.designated_ally_id),ally_distance]);lines.append("MINI HOTS %d  %s"%[druid.mini_hots.size(),str(druid.mini_hots.map(func(hot):return "%.2f"%float(hot.remaining_duration)))]);lines.append("REGROWTH %s"%str(druid.regrowths.map(func(hot):return "%s %.2f"%[str(hot.target_id),float(hot.remaining_duration)])));lines.append("TICK %.1f  Q/W/E %.1f/%.1f/%.1f"%[DruidSystem.regrowth_tick_request(hero),float(hero.ability_cds[0]),float(hero.ability_cds[1]),float(hero.ability_cds[2])]);lines.append("INNERVATE %d/%d  RECHARGE x%.2f  REVIT %.1f"%[int(druid.d_slot.current_charges),int(druid.d_slot.max_charges),DruidSystem.innervate_recharge_rate(hero,heroes),float(druid.revitalize_remaining)]);lines.append("ROOTS %d  QUEST %d  TREANTS %d  DMG %.1f"%[druid.roots_areas.size(),int(druid.vengeful_quest_stacks),druid.treants.size(),DruidSystem.treant_damage(hero)]);lines.append("TRANQ %.1f  TWILIGHT %.1f  SHOWER %d"%[float(druid.tranquility_remaining),float(druid.twilight_pending),int(druid.lunar_shower_stacks)]);lines.append("CURE %d  HEAL/OVER %.1f/%.1f  COMM %.1f"%[int(druid.recent_cure_count),float(druid.recent_healing),float(druid.recent_overhealing),float(druid.recent_communion_snapshot)])
		var telemetry_entries:Array=[];var telemetry_keys:Array=druid.telemetry.keys();telemetry_keys.sort()
		for telemetry_key in telemetry_keys:
			var telemetry_value:float=float(druid.telemetry[telemetry_key])
			if absf(telemetry_value)>0.0001:telemetry_entries.append("%s %.1f"%[str(telemetry_key).left(12).to_upper(),telemetry_value])
		if telemetry_entries.is_empty():lines.append("TELEMETRY  none")
		else:
			for entry_index in range(0,telemetry_entries.size(),2):lines.append("TEL  %s"%"  ".join(telemetry_entries.slice(entry_index,mini(entry_index+2,telemetry_entries.size()))))
	if str(hero.get("class",""))=="Warrior" and not hero.get("warrior_runtime",{}).is_empty():
		var warrior:Dictionary=hero.warrior_runtime;var w_state:=AbilitySlotSystem.ui_state(warrior.w_slot)
		lines.append("SPEC %s  ROLE %s"%[WarriorSystem.specialization(hero),str(hero.effective_role)]);lines.append("BA %.1f / %.2fs  HS %.1f"%[WarriorSystem.basic_attack_amount(hero),WarriorSystem.attack_interval(hero),float(warrior.heroic_strike_cooldown)]);lines.append("PARRY %.1f  W %d/%d"%[float(warrior.parry_remaining),int(w_state.charges),int(w_state.max_charges)]);lines.append("Q MAW %d/25  HIGH %d/%d/%d"%[int(warrior.lions_maw),WarriorSystem.high_progress(hero,"high_weapon"),WarriorSystem.high_progress(hero,"high_honors"),WarriorSystem.high_progress(hero,"high_endurance")]);lines.append("R %.1f  D %.1f  BANNER %s %.1f"%[float(warrior.taunt_cooldown),float(warrior.shattering_cooldown),str(warrior.banner_type),float(warrior.banner_remaining)]);lines.append("SUMMON LIFE %.1f -> %.1f"%[float(warrior.recent_summon_lifetime_before),float(warrior.recent_summon_lifetime_after)]);lines.append("TELEMETRY %s"%str(warrior.telemetry))
	if str(hero.get("class",""))=="Death Knight" and not hero.get("death_knight_runtime",{}).is_empty():
		var death_knight:Dictionary=hero.death_knight_runtime;var army_state:=AbilitySlotSystem.ui_state(death_knight.army_slot)
		lines.append("BA %.1f / %.2fs  ARMOR %.1f"%[DeathKnightSystem.basic_attack_amount(hero),float(hero.basic_attack_interval),float(hero.armor)]);lines.append("FROSTMOURNE x%d  D %.1f%s"%[int(death_knight.frostmourne_stacks),float(death_knight.frostmourne_cooldown)," PRIMED" if bool(death_knight.frostmourne_primed) else ""]);lines.append("Q/W/E/R %.1f / %.1f / %.1f / %.1f"%[float(hero.ability_cds[0]),float(hero.ability_cds[1]),float(hero.ability_cds[2]),float(hero.ability_cds[3])]);lines.append("TEMPEST %s %.1fs  LOCK %s"%["ON" if bool(death_knight.tempest.active) else "OFF",float(death_knight.tempest.active_duration),str(DeathKnightSystem.locked_slots(hero))]);lines.append("SUPPRESS %s  ICY %.0f%%"%[str(death_knight.suppression.values().map(func(value):return "%.0f%%"%(float(value.stacks)*100.0))),float(death_knight.icy_talons)*100.0]);lines.append("RUNE %d/5  RIME %.0f%%"%[int(death_knight.rune_stacks),IncomingDamageReductionSystem.strongest(hero)*100.0]);lines.append("PRESENCE %d/50  MASTERY %d"%[DeathKnightSystem.frost_presence_progress(hero),DeathKnightSystem.mastery_progress(hero)]);lines.append("ARMY %d/%d  %.1f  GHOULS %d"%[int(army_state.charges),int(army_state.max_charges),float(army_state.recharge),death_knight.ghouls.size()]);lines.append("BITING %s  REMORSE %d"%[str(death_knight.biting.values()),death_knight.remorseless.size()]);lines.append("HEAL x%.2f  INCOMING x%.2f"%[HealingReceivedModifierSystem.multiplier(hero),IncomingDamageReductionSystem.multiplier(hero)]);lines.append("TELEMETRY %s"%str(death_knight.telemetry))
	if str(hero.get("class",""))=="Beastmaster" and not hero.get("beastmaster_runtime",{}).is_empty():
		var beast:Dictionary=hero.beastmaster_runtime;var misha:Dictionary=beast.misha;var q_state:=AbilitySlotSystem.ui_state(beast.q_slot)
		lines.append("LEVEL %d  HP %.0f/%.0f  BA %.1f/%.2f"%[int(hero.level),float(hero.hp),float(hero.max_hp),float(hero.damage),float(hero.basic_attack_interval)]);lines.append("MISHA %s %.0f/%.0f  RESPAWN %.1f"%["ALIVE" if BeastmasterSystem.misha_alive(hero) else "DEAD",float(misha.hp),float(misha.max_hp),float(beast.misha_respawn_remaining)]);lines.append("COMMAND %s  TARGET %s"%[str(misha.command_mode),str(misha.target_id)]);lines.append("BLOCK BM/M %d/%d  Q %d/%d %.1f"%[BlockChargeSystem.charges(hero),BlockChargeSystem.charges(misha),int(q_state.charges),int(q_state.max_charges),float(q_state.recharge)]);lines.append("LESSER %d %s  GREATER %d %s  E %.1f"%[beast.lesser_beasts.size(),str(beast.lesser_beasts.map(func(unit):return "%.0f/%.1f"%[float(unit.hp),float(unit.health_decay_rate)])),beast.greater_beasts.size(),str(beast.greater_beasts.map(func(unit):return "%.0f/%.1f"%[float(unit.hp),float(unit.health_decay_rate)])),float(hero.ability_cds[2])]);lines.append("FURY %d/225 %s  HUNTED %s"%[int(beast.fury),"DONE" if bool(beast.fury_complete) else "",str(beast.hunted)]);lines.append("HAWK %.1f  DIRE %d  THRILL %.1f  PRIMAL %s"%[float(beast.hawk_remaining),int(beast.dire_stacks),float(beast.thrill_remaining),str(enemies.filter(func(unit):return unit.get("active_effects",[]).any(func(effect):return str(effect.get("source_id","")).begins_with("beastmaster_primal:"))).map(func(unit):return str(unit.combat_id)))]);lines.append("BESTIAL %.1f  BOARS %s  APEX %.0f/%s/%d"%[float(beast.bestial_remaining),str(beast.boar_targets),float(beast.apex_health),str(beast.apex_target),int(beast.apex_stacks)]);lines.append("PACK %s  WILDFIRE %d  REDIRECT %s"%[str(beast.pack_commander_target),BeastmasterSystem.disposable_beasts(hero).size() if BeastmasterSystem.has_talent(hero,"beastmaster_l30_3") else 0,str(beast.last_redirect)]);lines.append("TELEMETRY %s"%str(beast.telemetry))
	if str(hero.get("class",""))=="Monk" and not hero.get("monk_runtime",{}).is_empty():
		var monk:Dictionary=hero.monk_runtime;var monk_q:=MonkSystem.q_state(hero);var ally_state:="NONE" if monk.ally.is_empty() else "%s %.0f/%.0f %.1fs"%[str(monk.ally.ally_kind).to_upper(),float(monk.ally.hp),float(monk.ally.max_hp),float(monk.ally.remaining_duration)]
		lines.append("Q %d/%d  %.1f  W/E %.1f/%.1f"%[int(monk_q.charges),int(monk_q.max_charges),float(monk_q.recharge),float(monk.breath_cooldown),float(monk.reach_cooldown)]);lines.append("REACH %.1f  THIRD %d  SPEED %.1f"%[float(monk.reach_remaining),int(monk.third_counter),float(monk.trait_speed_remaining)]);lines.append("INSIGHT %d/100 %s"%[int(monk.insight_progress),"DONE" if bool(monk.insight_complete) else ""]);lines.append("ALLY %s  D %.1f  AURA %s"%[ally_state,float(monk.ally_cooldown),str(monk.ally_aura_recipients)]);lines.append("PALM %s  SEVEN %s  ECHOES %d"%[str(monk.palm),str(monk.seven),monk.echoes.size()]);lines.append("STORM %.1f  EPIPHANY %.1f"%[float(monk.storm_icd),float(monk.epiphany_icd)]);lines.append("TELEMETRY %s"%str(monk.telemetry))
	var debug_enemy=target if target in enemies else (enemies[focused_enemy_index] if focused_enemy_index>=0 and focused_enemy_index<enemies.size() else null)
	if debug_enemy!=null:
		lines.append("ENEMY  %s"%str(debug_enemy.get("combat_id","")));for hero_index in heroes.size():lines.append("THREAT %d  %.1f"%[hero_index,float(debug_enemy.get("threat",{}).get(hero_index,0.0))])
	var debug_height:=190.0+maxi(0,lines.size()-8)*20.0;draw_rect(Rect2(18,16,285,debug_height),Color(0.02,.03,.05,.88));draw_rect(Rect2(18,16,285,debug_height),C_MUTED,false,2)
	for line_index in lines.size():draw_string(ThemeDB.fallback_font,Vector2(32,42+line_index*20),lines[line_index],HORIZONTAL_ALIGNMENT_LEFT,-1,13,C_TEXT)
	if str(hero.get("class",""))=="Mage" and not hero.get("mage_runtime",{}).is_empty():
		draw_arc(hero.pos,MageSystem.flamestrike_range(hero),0,TAU,72,Color(CLASSES.Mage.color,.45),2)
		draw_arc(hero.pos,MageSystem.gravity_range(hero),0,TAU,72,Color("70b9ff",.35),2)
		for bomb in hero.mage_runtime.bomb_state.bombs_by_target.values():
			var bomb_target=unit_by_combat_id(str(bomb.target_id));if bomb_target!=null:draw_arc(bomb_target.pos,MageSystem.bomb_radius(hero),0,TAU,48,Color("ff9a4f",.38),2)
	elif str(hero.get("class",""))=="Warlock" and not hero.get("warlock_runtime",{}).is_empty():
		draw_arc(hero.pos,float(WarlockData.SPACE.q_range),0,TAU,72,Color(CLASSES.Warlock.color,.26),2);draw_arc(hero.pos,float(WarlockData.SPACE.w_cast_range),0,TAU,72,Color("d7a2ff",.24),2)
	elif str(hero.get("class",""))=="Shaman" and not hero.get("shaman_runtime",{}).is_empty():
		draw_arc(hero.pos,float(ShamanData.SPACE.q_range),0,TAU,72,Color(CLASSES.Shaman.color,.25),2)
		for spirit in hero.shaman_runtime.feral_spirits:draw_line(spirit.pos,Vector2(spirit.pos)+Vector2(spirit.direction)*float(spirit.remaining),Color("7ce7ff",.55),2)

func draw_world_combat_context() -> void:
	if tutorial_should_show_instruction_box():
		if tutorial_step==0 and not heroes.is_empty() and not tutorial_targets.is_empty():
			draw_tutorial_dotted_path(heroes[0].pos,tutorial_targets[0]);draw_tutorial_glow(heroes[0].pos,52,CLASSES["Guardian"].color)
		elif tutorial_step==2 and not heroes.is_empty() and not enemies.is_empty():
			draw_tutorial_glow(heroes[0].pos,52,CLASSES["Guardian"].color);draw_tutorial_glow(enemies[0].pos,52,C_RED)
		elif tutorial_step==3 and not heroes.is_empty():
			draw_tutorial_glow(heroes[0].pos,52,CLASSES["Guardian"].color)
		elif tutorial_step==4 and heroes.size()>1:
			draw_tutorial_glow(heroes[1].pos,52,CLASSES["Cleric"].color);draw_tutorial_glow(heroes[0].pos,52,C_GREEN)
		elif tutorial_step==6 and not heroes.is_empty() and not enemies.is_empty():
			draw_tutorial_glow(heroes[0].pos,52,CLASSES["Guardian"].color);draw_tutorial_glow(enemies[-1].pos,52,C_RED)
		for target_index in tutorial_targets.size():
			if target_index>=tutorial_target_reached.size() or not tutorial_target_reached[target_index]:
				var marker:Vector2=tutorial_targets[target_index]
				draw_circle(marker,44,Color(C_GREEN,.15));draw_arc(marker,44,0,TAU,40,C_GREEN,5)
				draw_line(marker+Vector2(0,-92),marker+Vector2(0,-58),C_GREEN,9)
				draw_colored_polygon(PackedVector2Array([marker+Vector2(-16,-65),marker+Vector2(16,-65),marker+Vector2(0,-45)]),C_GREEN)
	if current_ashwood_encounter!="" and not battle_objective.is_empty() and not victory_sequence:
		var objective_type:=str(battle_objective.type)
		var tracks_progress:=objective_type in ["protect_task","protect_caravan","ritual_defense","survival"]
		var progress_color:=C_GREEN if objective_type=="protect_caravan" else Color("6aa7ff")
		if objective_banner_time>0:
			var banner_alpha:float=clampf(objective_banner_time,0.0,1.0)
			var has_story:=objective_combat_intro!=""
			var objective_rect:=Rect2(310,18,660,76 if has_story else 58)
			draw_rect(objective_rect,Color(0.03,.055,.09,.92*banner_alpha));draw_rect(objective_rect,Color(C_GOLD,.65*banner_alpha),false,2)
			if has_story:draw_string(ThemeDB.fallback_font,Vector2(335,42),objective_combat_intro,HORIZONTAL_ALIGNMENT_CENTER,610,15,Color(C_MUTED,banner_alpha))
			draw_string(ThemeDB.fallback_font,Vector2(335,67 if has_story else 43),str(battle_objective.label).to_upper(),HORIZONTAL_ALIGNMENT_CENTER,610,16,Color(C_TEXT,banner_alpha))
			if tracks_progress:
				var progress_y:=78 if has_story else 52
				draw_rect(Rect2(355,progress_y,570,8),Color(0.06,.08,.12,banner_alpha));draw_rect(Rect2(355,progress_y,570*objective_progress,8),Color(progress_color,banner_alpha))
		elif tracks_progress and not objective_complete:
			draw_rect(Rect2(440,20,400,7),Color("10151e"));draw_rect(Rect2(440,20,400*objective_progress,7),progress_color)
		if objective_type=="protect_caravan" and objective_health>0:
			draw_damaged_caravan(objective_actor_pos)
		elif objective_type in ["protect_task","ritual_defense"] and not objective_complete:
			var actor_color:=Color("65dc89") if state.zone0.first_recruit_choice=="ranger" else Color("e6b35f")
			if objective_type=="ritual_defense":actor_color=Color("b381ff") if state.zone0.second_recruit_choice=="mage" else Color("d16ca8")
			draw_circle(objective_actor_pos,42,Color(actor_color,.18));draw_arc(objective_actor_pos,48,0,TAU,40,actor_color,4);draw_string(ThemeDB.fallback_font,objective_actor_pos+Vector2(-55,7),"SIGNAL" if objective_type=="protect_task" else "RITUAL",HORIZONTAL_ALIGNMENT_CENTER,110,14,C_TEXT)

	if rune_active:
		draw_circle(rune_center,rune_radius,Color(C_RED,.10));draw_arc(rune_center,rune_radius,0,TAU,64,Color(C_RED,.92),5);draw_circle(rune_center,118,Color(C_RED,.025));draw_arc(rune_center,118,0,TAU,64,Color(C_RED,.35),2)
	if objective_notice!="":draw_string(ThemeDB.fallback_font,Vector2(320,102),objective_notice,HORIZONTAL_ALIGNMENT_CENTER,640,17,C_GOLD)
	# World-space smoke belongs beneath units and combat HUD elements.
	for rogue in heroes:
		if str(rogue.get("class",""))!="Rogue" or rogue.get("rogue_runtime",{}).is_empty():continue
		for cloud in rogue.rogue_runtime.smoke_clouds:
			if float(cloud.remaining)>0.0:draw_circle(Vector2(cloud.center),float(cloud.radius),Color("778292",.18));draw_arc(Vector2(cloud.center),float(cloud.radius),0,TAU,48,Color("a7b0bf",.55),3)

func draw_combat_enemies() -> void:
	for i in enemies.size():
		var e=enemies[i]; if e.hp<=0:continue
		if e.telegraph>0:
			var warning_pos=e.danger_pos if e.special=="danger" or e.special=="charge" or e.special=="basic" else e.pos; var warning_radius=38.0 if e.special=="basic" else 78.0 if e.special=="danger" else 115.0
			draw_circle(warning_pos,warning_radius,Color(1,.15,.12,.16));draw_arc(warning_pos,warning_radius,0,TAU,48,C_RED,3)
			if e.special=="charge": draw_dashed_line(e.pos,e.danger_pos,C_RED,5,10)
		var enemy_color=GameData.enemy_color(e.type)
		var target_outline:=Color.WHITE if focused_enemy_index==i else C_GOLD if heroes.size()>selected and heroes[selected].target==i else Color("5f2931")
		var enemy_radius:=62.0 if e.type=="Defense Dummy" else 46.0;draw_circle(e.pos,enemy_radius,enemy_color); draw_circle(e.pos,enemy_radius+6,target_outline,4); if not victory_sequence and (e.revealed or e.hp<e.max_hp):health_bar(e.pos+Vector2(-54,-enemy_radius-24),108,e.hp/e.max_hp,C_RED); draw_string(ThemeDB.fallback_font,e.pos+Vector2(-55,6),"DEFENSE" if e.type=="Defense Dummy" else str(e.get("display_name",e.type)).substr(0,12),HORIZONTAL_ALIGNMENT_CENTER,110,15,C_TEXT)
		if not victory_sequence:
			for huntsman in heroes:
				if str(huntsman.get("class",""))=="Huntsman" and str(huntsman.get("huntsman_runtime",{}).get("marked_target_id",""))==str(e.get("combat_id","")):
					var mark_ratio:=clampf(float(huntsman.huntsman_runtime.mark_remaining)/maxf(.01,float(HuntsmanData.VALUES.mark_duration)),0.0,1.0);draw_arc(e.pos,enemy_radius+15,-PI/2,-PI/2+TAU*mark_ratio,40,CLASSES.Huntsman.color,4);draw_string(ThemeDB.fallback_font,e.pos+Vector2(19,-enemy_radius-8),"x%d"%int(huntsman.huntsman_runtime.mark_stacks),HORIZONTAL_ALIGNMENT_CENTER,28,11,CLASSES.Huntsman.color)
			for mage in heroes:
				if str(mage.get("class",""))=="Mage" and not mage.get("mage_runtime",{}).is_empty() and mage.mage_runtime.bomb_state.bombs_by_target.has(str(e.combat_id)):
					var bomb:Dictionary=mage.mage_runtime.bomb_state.bombs_by_target[str(e.combat_id)];var bomb_ratio:=clampf(float(bomb.remaining)/maxf(0.01,float(MageData.VALUES.w_duration)),0.0,1.0);draw_arc(e.pos,enemy_radius+12,-PI/2,-PI/2+TAU*bomb_ratio,36,Color("ff9a4f"),4)
			if testing_zone_active and not e.get("bloodletting_stacks",[]).is_empty():draw_string(ThemeDB.fallback_font,e.pos+Vector2(-50,enemy_radius+22),"Bloodletting x%d"%e.bloodletting_stacks.size(),HORIZONTAL_ALIGNMENT_CENTER,100,12,Color("f09a9f"))
			var corruption_stacks:=0
			for warlock in heroes:
				if str(warlock.get("class",""))=="Warlock" and not warlock.get("warlock_runtime",{}).is_empty():corruption_stacks+=warlock.warlock_runtime.periodic_effects.filter(func(instance):return str(instance.get("target_id",""))==str(e.combat_id)).size()
			for stack_index in corruption_stacks:draw_circle(e.pos+Vector2(-12+stack_index*12,-enemy_radius-10),4,Color("b15cff"))
			if CombatSystem.is_feared(e):draw_string(ThemeDB.fallback_font,e.pos+Vector2(-22,enemy_radius+19),"FEAR",HORIZONTAL_ALIGNMENT_CENTER,44,10,Color("d6a5ff"))
			elif CombatSystem.is_silenced(e):draw_string(ThemeDB.fallback_font,e.pos+Vector2(-26,enemy_radius+19),"SILENCE",HORIZONTAL_ALIGNMENT_CENTER,52,10,Color("d6a5ff"))

func draw_combat_summons() -> void:
	for mage in heroes:
		if str(mage.get("class",""))!="Mage" or mage.get("mage_runtime",{}).is_empty():continue
		var phoenix:Dictionary=mage.mage_runtime.phoenix
		if not phoenix.is_empty():
			var phoenix_pos:=Vector2(phoenix.pos);draw_circle(phoenix_pos,18,Color("ff7a3d",.30));draw_circle(phoenix_pos,11,Color("ffb34f"));draw_colored_polygon(PackedVector2Array([phoenix_pos+Vector2(0,-19),phoenix_pos+Vector2(-17,10),phoenix_pos,phoenix_pos+Vector2(17,10)]),Color("ffd15c"))
		for projectile in mage.mage_runtime.pyro_projectiles:
			var pyro_pos:=Vector2(projectile.pos);draw_circle(pyro_pos,18,Color("ff7a3d",.28));draw_circle(pyro_pos,11,Color("ff7a3d"));draw_circle(pyro_pos,5,Color("fff2a8"))
	for druid in heroes:
		if str(druid.get("class",""))!="Druid" or druid.get("druid_runtime",{}).is_empty():continue
		for treant in druid.druid_runtime.treants:
			var treant_pos:=Vector2(treant.pos);var life_ratio:=clampf(float(treant.hp)/maxf(1.0,float(treant.max_hp)),0.0,1.0)
			draw_circle(treant_pos,21,Color("74b96b",.18));draw_circle(treant_pos,13,Color("6f5438"));draw_line(treant_pos+Vector2(-9,-8),treant_pos+Vector2(-18,-20),Color("91d477"),5);draw_line(treant_pos+Vector2(9,-8),treant_pos+Vector2(18,-20),Color("91d477"),5);health_bar(treant_pos+Vector2(-22,-31),44,life_ratio,Color("78d878"))
	for death_knight in heroes:
		if str(death_knight.get("class",""))!="Death Knight" or death_knight.get("death_knight_runtime",{}).is_empty():continue
		for ghoul in death_knight.death_knight_runtime.ghouls:
			var ghoul_pos:=Vector2(ghoul.pos);var life_ratio:=clampf(float(ghoul.remaining_lifetime)/maxf(.01,float(ghoul.original_lifetime)),0.0,1.0)
			draw_circle(ghoul_pos,18,Color("62b5d9",.18));draw_circle(ghoul_pos,11,Color("7c92a4"));draw_line(ghoul_pos+Vector2(-8,5),ghoul_pos+Vector2(8,5),Color("d7edf8"),3);health_bar(ghoul_pos+Vector2(-20,-27),40,life_ratio,Color("75b8dc"))
	for beastmaster in heroes:
		if str(beastmaster.get("class",""))!="Beastmaster" or beastmaster.get("beastmaster_runtime",{}).is_empty():continue
		for beast in BeastmasterSystem.combat_beasts(beastmaster):
			var beast_pos:=Vector2(beast.pos);var ratio:=clampf(float(beast.hp)/maxf(1.0,float(beast.max_hp)),0.0,1.0);var category:=str(beast.get("beast_category",""));var color:=Color("b58a52") if category=="misha" else Color("8fbc62") if category=="lesser" else Color("c46d44")
			draw_circle(beast_pos,24 if category=="misha" else 18,Color(color,.22));draw_circle(beast_pos,15 if category=="misha" else 11,color);health_bar(beast_pos+Vector2(-24,-33),48,ratio,color)
			if float(beast.get("fresh_remaining",0.0))>0.0:draw_arc(beast_pos,28,0,TAU,32,Color("f6dc7a"),3)
			if category=="greater" and BeastmasterSystem.has_talent(beastmaster,"beastmaster_l18_3"):draw_arc(beast_pos,float(BeastmasterData.SPACE.greater_rally),0,TAU,48,Color(color,.22),2)
	for monk in heroes:
		if str(monk.get("class",""))!="Monk" or monk.get("monk_runtime",{}).get("ally",{}).is_empty():continue
		var ally:Dictionary=monk.monk_runtime.ally;var ally_pos:=Vector2(ally.pos);var ally_color:=Color("e7d8a2") if str(ally.ally_kind)=="spirit" else Color("a98b68") if str(ally.ally_kind)=="earth" else Color("a8e5ed")
		draw_circle(ally_pos,float(MonkData.SPACE.ally_radius),Color(ally_color,.18));draw_circle(ally_pos,14,ally_color);draw_arc(ally_pos,float(MonkData.SPACE.ally_aura_radius),0,TAU,48,Color(ally_color,.18),2);health_bar(ally_pos+Vector2(-22,-30),44,clampf(float(ally.hp)/maxf(1.0,float(ally.max_hp)),0.0,1.0),ally_color)

func draw_combat_heroes() -> void:
	for i in heroes.size():
		var h=heroes[i]; var col=CLASSES[h["class"]].color; if h.hp<=0:col=Color("455067")
		var concealment_visual:=rogue_concealment_visual_state(h)
		if concealment_visual!="":col=Color(col,.24 if concealment_visual=="invisible" else .58)
		if bool(h.get("incapacitated",false)):
			draw_circle(h.pos,50,Color("202735"));draw_line(h.pos+Vector2(-24,-24),h.pos+Vector2(24,24),C_RED,7);draw_line(h.pos+Vector2(-24,24),h.pos+Vector2(24,-24),C_RED,7);continue
		if int(h.get("basic_action_phase",CombatRulesV1.BasicActionPhase.READY))==CombatRulesV1.BasicActionPhase.WINDUP:
			var windup_progress:=clampf(float(h.basic_action_timer)/maxf(.01,float(h.basic_action_release_time)),0.0,1.0)
			draw_arc(h.pos,54,-PI/2,-PI/2+TAU*windup_progress,28,Color(col,.82),3)
			draw_circle(h.pos+h.facing_direction*43,5,Color(col,.72))
		if i==selected and not victory_sequence and not bool(h.get("independent",false)):
			draw_circle(h.pos,66,Color(C_GOLD,.18));draw_circle(h.pos,59,C_GOLD,4)
		if not victory_sequence and bool(h.get("spirit_form",false)):
			var spirit_pulse:=0.5+0.5*sin(battle_time*3.2)
			draw_circle(h.pos,69,Color("f7f2ff",.08+.08*spirit_pulse))
			draw_arc(h.pos,64,battle_time*.8,battle_time*.8+PI*1.55,42,Color("f4eaff",.72),4)
			draw_arc(h.pos,58,-battle_time*.6,-battle_time*.6+PI*1.25,36,Color("c9b8ff",.56),3)
		if h.shield>0 and not victory_sequence:draw_circle(h.pos,63,Color("5fa8ff"),4)
		var role_ink:=Color("d9f3ff",.38) if concealment_visual=="invisible" else Color("eadcff",.72) if concealment_visual=="vanished" else Color("101827")
		draw_circle(h.pos,48,col);draw_role_icon(h.pos,h["class"],role_ink);if not victory_sequence:draw_rogue_concealment(h,concealment_visual);if not victory_sequence and (h.hp<h.max_hp or h.last_hit>0 or h.shield>0):health_bar_with_shield(h.pos+Vector2(-54,-70),108,h)
		if not victory_sequence and str(h.get("class",""))=="Huntsman" and not h.get("huntsman_runtime",{}).is_empty():
			if HuntsmanSystem.is_worgen(h):draw_colored_polygon(PackedVector2Array([h.pos+Vector2(-28,-35),h.pos+Vector2(-17,-61),h.pos+Vector2(-4,-37)]),Color(CLASSES.Huntsman.color,.82));draw_colored_polygon(PackedVector2Array([h.pos+Vector2(28,-35),h.pos+Vector2(17,-61),h.pos+Vector2(4,-37)]),Color(CLASSES.Huntsman.color,.82))
			else:draw_arc(h.pos,54,-PI*.85,-PI*.15,18,Color("d8c29d"),4)
			if float(h.huntsman_runtime.inner_beast_remaining)>0.0:draw_arc(h.pos,58,battle_time*2.5,battle_time*2.5+PI*1.55,36,Color(CLASSES.Huntsman.color,.85),4)
		if not victory_sequence:draw_hero_channel_bar(h)
		if not victory_sequence and str(h.get("class",""))=="Rogue" and not h.get("rogue_runtime",{}).is_empty():
			var point_count:int=ComboPointSystem.current(h);var point_max:int=ComboPointSystem.maximum(h);var pip_start:float=float(h.pos.x)-(point_max-1)*7.0
			for point_index in point_max:draw_circle(Vector2(pip_start+point_index*14.0,h.pos.y-83),4.5,C_GOLD if point_index<point_count else Color("45546a"))
		if not victory_sequence and str(h.get("class",""))=="Slayer" and not h.get("slayer_runtime",{}).is_empty():
			if EvasionSystem.is_active(h):draw_arc(h.pos,57,battle_time*3.0,battle_time*3.0+PI*1.55,36,Color("e7fff2"),4)
			if float(h.slayer_runtime.get("metamorphosis_remaining",0.0))>0.0:draw_arc(h.pos,61,0,TAU,40,Color(CLASSES.Slayer.color,.78),5)
			var block_count:=BlockChargeSystem.charges(h,"slayer_block");var block_start:float=float(h.pos.x)-(int(SlayerData.VALUES.reflexive_block_max)-1)*7.0
			for block_index in int(SlayerData.VALUES.reflexive_block_max):draw_circle(Vector2(block_start+block_index*14.0,h.pos.y-83),4.5,Color("7dc3ff") if block_index<block_count else Color("45546a"))
		if not victory_sequence:
			var serpent_count:=ClericSystem.active_serpent_count(heroes,str(h.get("combat_id","")))
			for serpent_marker_index in mini(serpent_count,2):
				var marker_offset:=Vector2(-34,-49) if serpent_marker_index==0 else Vector2(34,-49)
				draw_circle(h.pos+marker_offset,7,Color("263142"));draw_circle(h.pos+marker_offset,4.5,Color.WHITE)
		if bool(h.get("independent",false)) and not victory_sequence:draw_string(ThemeDB.fallback_font,h.pos+Vector2(-42,-62),"ALLIED NPC",HORIZONTAL_ALIGNMENT_CENTER,84,12,C_GREEN)

func draw_combat_input_preview() -> void:
	if dragging_hero:
		draw_dashed_line(heroes[selected].pos,drag_cursor,Color(C_GOLD,.75),6,8)
		var preview_color=C_GREEN if drag_target_type=="ally" else (C_RED if drag_target_type=="enemy" else C_GOLD)
		var preview_pos=drag_cursor
		if drag_target_type=="enemy" and drag_target_index>=0 and drag_target_index<enemies.size():preview_pos=enemies[drag_target_index].pos
		elif drag_target_type=="ally" and drag_target_index>=0 and drag_target_index<heroes.size():preview_pos=heroes[drag_target_index].pos
		elif drag_target_type=="ally_companion" and drag_target_index>=0 and drag_target_index<heroes.size():preview_pos=heroes[drag_target_index].beastmaster_runtime.misha.pos
		draw_circle(preview_pos,42,Color(preview_color,.14));draw_arc(preview_pos,42,0,TAU,40,preview_color,4)
	if ability_aiming and selected<heroes.size():
		var aiming_hero=heroes[selected];var range_limit=float(ABILITY_RANGES[aiming_hero["class"]][aimed_ability_slot]);var aim_point=clamped_cast_point(aiming_hero,ability_aim_point,range_limit) if range_limit>0 else aiming_hero.pos
		if range_limit>0:draw_circle(aiming_hero.pos,range_limit,Color(C_GOLD,.035));draw_arc(aiming_hero.pos,range_limit,0,TAU,64,Color(C_GOLD,.55),2)
		if aimed_ability_category=="ground":
			var ground_radius:=MageSystem.flamestrike_radius(aiming_hero,MageSystem.trait_is_armed(aiming_hero)) if str(aiming_hero.get("class",""))=="Mage" and aimed_ability_slot==0 else float(MageData.SPACE.pyro_splash_radius) if str(aiming_hero.get("class",""))=="Mage" and aimed_ability_slot==3 else 30.0
			draw_circle(aim_point,ground_radius,Color(C_GOLD,.10));draw_arc(aim_point,ground_radius,0,TAU,48,C_GOLD,3);draw_dashed_line(aiming_hero.pos,aim_point,Color(C_GOLD,.7),8,6)
		elif aimed_ability_category=="directional":draw_dashed_line(aiming_hero.pos,aim_point,C_GOLD,10,6);draw_circle(aim_point,14,Color(C_GOLD,.3))
		elif aimed_ability_category=="area":draw_circle(aiming_hero.pos,max(90.0,range_limit),Color(C_GOLD,.10));draw_arc(aiming_hero.pos,max(90.0,range_limit),0,TAU,48,C_GOLD,3)

func draw_tutorial_instruction_hud()->void:
	if tutorial_should_show_instruction_box():
		var instruction_pulse=.5+.5*sin(tutorial_timer*5.0) if tutorial_idle_hint_shown else 0.0
		var instruction_rect=Rect2(230,18,820,82)
		if tutorial_idle_hint_shown:draw_rect(instruction_rect.grow(3+instruction_pulse*5),Color(C_GOLD,.035+.055*instruction_pulse))
		draw_rect(instruction_rect,Color(0.03,.055,.09,.92));draw_rect(instruction_rect,Color(C_GOLD,.55+.4*instruction_pulse),false,2+instruction_pulse*2);draw_string(ThemeDB.fallback_font,Vector2(275,43),"TRAINING",HORIZONTAL_ALIGNMENT_CENTER,730,14,C_GOLD);draw_string(ThemeDB.fallback_font,Vector2(275,74),tutorial_prompt(),HORIZONTAL_ALIGNMENT_CENTER,730,19,C_TEXT)
		if tutorial_reject_time>0:
			draw_rect(Rect2(320,106,640,38),Color(0.03,.055,.09,.94));draw_rect(Rect2(320,106,640,38),Color(C_GOLD,.65),false,2);draw_string(ThemeDB.fallback_font,Vector2(345,131),tutorial_feedback_message,HORIZONTAL_ALIGNMENT_CENTER,590,15,C_GOLD)

func draw_testing_status_hud()->void:
	if testing_zone_active and not item_feedback_feed.is_empty():
		draw_rect(Rect2(18,18,250,24+item_feedback_feed.size()*19),Color(0.03,.05,.08,.76));draw_string(ThemeDB.fallback_font,Vector2(30,39),"ITEM EFFECTS",HORIZONTAL_ALIGNMENT_LEFT,-1,12,C_GOLD)
		for feed_index in item_feedback_feed.size():draw_string(ThemeDB.fallback_font,Vector2(30,59+feed_index*19),item_feedback_feed[feed_index],HORIZONTAL_ALIGNMENT_LEFT,225,12,C_TEXT)
	if testing_zone_active and testing_zone_mode=="endless" and not victory_sequence:
		draw_rect(Rect2(525,18,230,48),Color(0.03,.05,.08,.78));draw_string(ThemeDB.fallback_font,Vector2(537,40),"ENDLESS ARENA  •  LEVEL %d"%testing_endless_level,HORIZONTAL_ALIGNMENT_LEFT,205,13,C_GOLD);draw_string(ThemeDB.fallback_font,Vector2(537,58),"DEFEATED  %d"%testing_endless_defeated,HORIZONTAL_ALIGNMENT_LEFT,205,12,C_MUTED)
	if testing_zone_active and testing_zone_mode=="rogue_range" and not victory_sequence:
		draw_rect(Rect2(470,18,340,42),Color(0.03,.05,.08,.78));draw_string(ThemeDB.fallback_font,Vector2(486,44),"ROGUE RANGE  -  SHIFT+1-6 BUILDS",HORIZONTAL_ALIGNMENT_CENTER,308,13,C_GOLD)
	if testing_zone_active and testing_zone_mode=="slayer_range" and not victory_sequence:
		draw_rect(Rect2(460,18,360,42),Color(0.03,.05,.08,.78));draw_string(ThemeDB.fallback_font,Vector2(476,44),"SLAYER RANGE  -  SHIFT+1-9 / 0 BUILDS",HORIZONTAL_ALIGNMENT_CENTER,328,13,C_GOLD)
	if testing_zone_active and testing_zone_mode=="priest_range" and not victory_sequence:
		draw_rect(Rect2(425,18,430,42),Color(0.03,.05,.08,.78));draw_string(ThemeDB.fallback_font,Vector2(441,44),"PRIEST RANGE  -  SHIFT+1-3 BUILDS  •  ALT+K/V/R/H",HORIZONTAL_ALIGNMENT_CENTER,398,13,C_GOLD)

func draw_party_portraits_hud()->void:
	var selectable_heroes:Array=player_controlled_hero_indices()
	for i in 8:
		var center=Vector2(451+i*54,604)
		var occupied=i<selectable_heroes.size()
		var hero_index:int=selectable_heroes[i] if occupied else -1
		var is_selected=occupied and hero_index==selected
		var portrait_radius=29.0 if is_selected else 26.0
		var portrait_fill=Color("26364a") if is_selected else Color("172130")
		if is_selected:
			var glow_color=Color(CLASSES[heroes[hero_index]["class"]].color,.16)
			draw_circle(center,35,glow_color)
			draw_octagon(center,33,Color.TRANSPARENT,C_GOLD,3)
		draw_octagon(center,portrait_radius,portrait_fill,Color("65758d") if occupied else Color("46546a"),3)
		if occupied:
			draw_octagon_health(center,portrait_radius+1,max(0,heroes[hero_index].hp/heroes[hero_index].max_hp))
			if heroes[hero_index].shield>0:draw_arc(center,portrait_radius+4,-PI*.75,-PI*.25,10,Color("55aaff"),4)
			var class_color:Color=CLASSES[heroes[hero_index]["class"]].color
			var icon_color=class_color if is_selected else class_color.lerp(Color("929aa6"),.68)
			draw_role_icon(center-Vector2(0,4),heroes[hero_index]["class"],icon_color)
			var regrowth_sources:=0;var designated:=false
			for druid in heroes:
				if str(druid.get("class",""))!="Druid" or druid.get("druid_runtime",{}).is_empty():continue
				if DruidSystem.regrowth_for(druid,str(heroes[hero_index].combat_id))!=null:regrowth_sources+=1
				designated=designated or (hero_index==int(druid.get("heal_target",-1)) and str(druid.druid_runtime.get("designated_ally_id",""))==str(heroes[hero_index].combat_id))
			if regrowth_sources>0:
				draw_arc(center,portrait_radius+7,-PI*.92,-PI*.08,18,Color("79d879"),4);draw_string(ThemeDB.fallback_font,center+Vector2(12,-17),str(regrowth_sources),HORIZONTAL_ALIGNMENT_CENTER,13,10,Color("b9ffb1"))
			if designated:draw_arc(center,portrait_radius+11,PI*.08,PI*.92,18,Color("e6d66f"),3)
			draw_string(ThemeDB.fallback_font,center+Vector2(-8,20),str(i+1),HORIZONTAL_ALIGNMENT_CENTER,16,11,C_GOLD if is_selected else C_MUTED)

func draw_ability_bar_hud()->void:
	if tutorial_should_show_ability_bar():
		var active=heroes[selected];var keys=["Q","W","E","R","D"];var hero_level:=int(state.heroes[battle_hero_indices[selected]].level)
		var visible_slots:Array=[0,4]
		if active["class"]=="Monk":visible_slots=[0,1,2,4]
		for ability_slot in [1,2,3]:
			if ability_slot not in visible_slots and TalentSystem.ability_is_unlocked(hero_level,ability_slot) and (ability_slot!=3 or str(active.get("selected_heroic_id",""))!=""):visible_slots.insert(visible_slots.size()-1,ability_slot)
		for slot in visible_slots:
			var center=Vector2(484+slot*78,674);var action_name:String=str(ABILITIES[active["class"]][slot]) if slot<4 else "Stoneform" if active["class"]=="Guardian" and GuardianSystem.has_talent(active,"guardian_l24_2") else str(TRAITS[active["class"]])
			if slot<3 and selected<battle_hero_indices.size():
				var saved_hero:Dictionary=state.heroes[battle_hero_indices[selected]];var ability_id:="%s:%s"%[str(saved_hero.class_id),["q","w","e"][slot]];var rune_presentation:Dictionary=ProfessionSystem.ability_presentation(state,str(saved_hero.hero_id),ability_id,action_name);action_name=str(rune_presentation.display_name)
			if active["class"]=="Rogue" and slot<3 and not active.get("rogue_runtime",{}).is_empty() and bool(active.rogue_runtime.vanish_active):action_name=["Ambush","Cheap Shot","Garrote"][slot]
			elif active["class"]=="Rogue" and slot==3:action_name=str(RogueData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			if slot==3 and active["class"]=="Cleric":action_name=str(ClericData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==4 and active["class"]=="Cleric" and ClericSystem.has_talent(active,"cleric_l12_2"):action_name="Safety Sprint"
			elif slot==4 and active["class"]=="Cleric" and ClericSystem.has_talent(active,"cleric_l12_3"):action_name="Let's Go!"
			elif slot==3 and active["class"]=="Ranger":action_name=str(RangerData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==4 and active["class"]=="Ranger" and RangerSystem.has_talent(active,"ranger_l21_3"):action_name="Gloom"
			elif slot==3 and active["class"]=="Mage":action_name=str(MageData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Warlock":action_name=str(WarlockData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Slayer":action_name=str(SlayerData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Priest":action_name=str(PriestData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Shaman":action_name=str(ShamanData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Templar":action_name=str(TemplarData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Protector":action_name=str(ProtectorData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Sentinel":action_name=str(SentinelData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif active["class"]=="Huntsman" and slot==0:action_name="Razor Swipe" if HuntsmanSystem.is_worgen(active) else "Gilnean Cocktail"
			elif active["class"]=="Huntsman" and slot==2:action_name="Disengage" if HuntsmanSystem.is_worgen(active) else "Darkflight"
			elif slot==3 and active["class"]=="Huntsman":action_name=str(HuntsmanData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Druid":action_name=str(DruidData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Death Knight":action_name=str(DeathKnightData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Beastmaster":action_name=str(BeastmasterData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==3 and active["class"]=="Monk":action_name=str(MonkData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
			elif slot==4 and active["class"]=="Monk":action_name=("%s Ally"%MonkSystem.ally_kind(active).capitalize()) if MonkSystem.ally_kind(active)!="" else "Unassigned"
			elif slot==2 and active["class"]=="Death Knight" and bool(active.get("death_knight_runtime",{}).get("tempest",{}).get("active",false)):action_name="Turn Off"
			elif slot==4 and active["class"]=="Slayer" and SlayerSystem.has_talent(active,"slayer_l30_2"):action_name="Thrill"
			elif slot==4 and active["class"]=="Protector" and ProtectorSystem.has_talent(active,"protector_l30_1"):action_name="Aspect"
			elif slot==4 and active["class"]=="Sentinel" and SentinelSystem.has_talent(active,"sentinel_l30_2") and float(active.get("sentinel_runtime",{}).get("d_cooldown",0.0))>0.0:action_name="Trueshot"
			var cleric_trait_active:bool=false
			if slot==4 and str(active.get("class",""))=="Cleric" and not active.get("cleric_runtime",{}).is_empty():cleric_trait_active=ClericSystem.fast_feet_active(active)
			var hatred_ratio:float=0.0
			if slot==4 and str(active.get("class",""))=="Ranger" and not active.get("ranger_runtime",{}).is_empty():hatred_ratio=clampf(float(active.ranger_runtime.hatred)/float(RangerData.VALUES.hatred_max),0.0,1.0)
			var ranger_hatred_full:bool=hatred_ratio>=1.0
			var mage_trait_armed:bool=slot==4 and str(active.get("class",""))=="Mage" and not active.get("mage_runtime",{}).is_empty() and MageSystem.trait_is_armed(active)
			var warlock_trait_state:Dictionary=WarlockSystem.slot_state(active) if slot==4 and str(active.get("class",""))=="Warlock" else {}
			var warlock_darkness_armed:bool=bool(warlock_trait_state.get("darkness_armed",false))
			var slayer_evasion_active:bool=slot==2 and str(active.get("class",""))=="Slayer" and EvasionSystem.is_active(active)
			var frostwolf_ratio:float=clampf(float(active.get("shaman_runtime",{}).get("frostwolf_stacks",0))/float(ShamanData.VALUES.trait_threshold),0.0,1.0) if slot==4 and str(active.get("class",""))=="Shaman" else 0.0
			var frostwolf_ready:bool=frostwolf_ratio>=0.8
			var templar_trait_active:bool=slot==4 and str(active.get("class",""))=="Templar" and bool(active.get("templar_runtime",{}).get("trait_active",false))
			var protector_trait_active:bool=slot==4 and str(active.get("class",""))=="Protector" and (bool(active.get("spirit_form",false)) or not active.get("protector_runtime",{}).get("wrath",{}).is_empty())
			var sentinel_trait_active:bool=slot==4 and str(active.get("class",""))=="Sentinel" and float(active.get("sentinel_runtime",{}).get("mark_remaining",0.0))>0.0
			var huntsman_trait_active:bool=slot==4 and str(active.get("class",""))=="Huntsman" and HuntsmanSystem.is_worgen(active)
			var highlighted_state:bool=cleric_trait_active or ranger_hatred_full or mage_trait_armed or warlock_darkness_armed or slayer_evasion_active or frostwolf_ready or templar_trait_active or protector_trait_active or sentinel_trait_active or huntsman_trait_active
			if highlighted_state:
				var trait_pulse:float=.5+.5*sin(battle_time*6.0);var trait_color:Color=Color(CLASSES[active["class"]].color)
				draw_octagon(center,43+trait_pulse*2.0,Color(trait_color,.08+.08*trait_pulse),Color(trait_color,.48+.42*trait_pulse),3.0+trait_pulse*2.0)
			draw_octagon(center,37,Color("263a57") if slot<3 else Color("59402b"),C_MUTED,3)
			if hatred_ratio>0.0:draw_octagon_vertical_fill(center,34,hatred_ratio,Color(CLASSES["Ranger"].color,.68))
			if frostwolf_ratio>0.0:draw_octagon_vertical_fill(center,34,frostwolf_ratio,Color(CLASSES["Shaman"].color,.68))
			if not warlock_trait_state.is_empty() and not warlock_darkness_armed:
				var darkness_ratio:=clampf(float(warlock_trait_state.darkness_progress)/maxf(1.0,float(warlock_trait_state.darkness_required)),0.0,1.0)
				if darkness_ratio>0.0:draw_octagon_vertical_fill(center,34,darkness_ratio,Color(CLASSES["Warlock"].color,.55))
			draw_string(ThemeDB.fallback_font,center+Vector2(-34,-4),action_name.substr(0,10),HORIZONTAL_ALIGNMENT_CENTER,68,10,C_TEXT);draw_string(ThemeDB.fallback_font,center+Vector2(-28,25),keys[slot],HORIZONTAL_ALIGNMENT_CENTER,56,14,C_GOLD)
			if active.ability_cds[slot]>0:draw_octagon(center,37,Color(0,0,0,.62),C_MUTED,2);draw_string(ThemeDB.fallback_font,center+Vector2(-18,7),"%.1f"%active.ability_cds[slot],HORIZONTAL_ALIGNMENT_CENTER,36,15,C_TEXT)
			if active["class"]=="Death Knight" and slot in DeathKnightSystem.locked_slots(active):draw_octagon(center,37,Color(0,0,0,.72),C_MUTED,2);draw_string(ThemeDB.fallback_font,center+Vector2(-23,7),"LOCK",HORIZONTAL_ALIGNMENT_CENTER,46,12,C_TEXT)
			if active["class"]=="Beastmaster" and not BeastmasterSystem.misha_alive(active) and (slot in [1,2,4] or slot==3 and str(active.selected_heroic_id)=="beastmaster_l15_r1"):draw_octagon(center,37,Color(0,0,0,.72),C_MUTED,2);draw_string(ThemeDB.fallback_font,center+Vector2(-23,7),"MISHA",HORIZONTAL_ALIGNMENT_CENTER,46,10,C_TEXT)
			if active["class"]=="Beastmaster" and slot==0 and not active.get("beastmaster_runtime",{}).is_empty():var beast_q:=AbilitySlotSystem.ui_state(active.beastmaster_runtime.q_slot);draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),"%d/%d"%[beast_q.charges,beast_q.max_charges],HORIZONTAL_ALIGNMENT_CENTER,34,10,C_TEXT)
			if active["class"]=="Rogue" and slot==2 and ComboPointSystem.current(active)<=0:draw_octagon(center,37,Color(0,0,0,.58),C_MUTED,2)
			if highlighted_state:draw_octagon(center,38,Color.TRANSPARENT,Color.WHITE,2)
			if active["class"]=="Shaman" and slot==2 and int(active.get("shaman_runtime",{}).get("windfury_attacks",0))>0:draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),str(int(active.shaman_runtime.windfury_attacks)),HORIZONTAL_ALIGNMENT_CENTER,24,11,C_TEXT)
			if not warlock_trait_state.is_empty() and slot==4:draw_string(ThemeDB.fallback_font,center+Vector2(14,-20),"%d%%"%int(warlock_trait_state.cost_percent),HORIZONTAL_ALIGNMENT_CENTER,42,9,C_TEXT)
			if active["class"]=="Ranger" and not active.get("ranger_runtime",{}).is_empty() and slot in [2,3]:
				var slot_key:="e" if slot==2 else "r";var charge_state:=AbilitySlotSystem.ui_state(active.ranger_runtime.slots[slot_key])
				draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),"%d/%d"%[charge_state.charges,charge_state.max_charges],HORIZONTAL_ALIGNMENT_CENTER,34,10,C_TEXT)
			if active["class"]=="Mage" and not active.get("mage_runtime",{}).is_empty():
				if slot==4:
					var trait_state:=MageSystem.slot_state(active);draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),"%d/%d"%[trait_state.charges,trait_state.max_charges],HORIZONTAL_ALIGNMENT_CENTER,34,10,C_TEXT)
				elif slot==3 and MageSystem.has_talent(active,"mage_l27_r1") and not active.mage_runtime.phoenix.is_empty():draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),"%d"%int(active.mage_runtime.phoenix.reposition_charges),HORIZONTAL_ALIGNMENT_CENTER,34,10,C_TEXT)
			if active["class"]=="Slayer" and slot==1 and not active.get("slayer_runtime",{}).is_empty():
				var slayer_slot:=AbilitySlotSystem.ui_state(active.slayer_runtime.w_slot);draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),"%d/%d"%[slayer_slot.charges,slayer_slot.max_charges],HORIZONTAL_ALIGNMENT_CENTER,34,10,C_TEXT)
			if active["class"]=="Shaman" and slot==0 and not active.get("shaman_runtime",{}).is_empty():
				var shaman_slot:=AbilitySlotSystem.ui_state(active.shaman_runtime.q_slot);draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),"%d/%d"%[shaman_slot.charges,shaman_slot.max_charges],HORIZONTAL_ALIGNMENT_CENTER,34,10,C_TEXT)
			if active["class"]=="Templar" and slot==3 and str(active.get("selected_heroic_id",""))=="templar_l15_r1" and not active.get("templar_runtime",{}).is_empty():draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),str(int(active.templar_runtime.r1_charges)),HORIZONTAL_ALIGNMENT_CENTER,24,11,C_TEXT)
			if active["class"]=="Protector" and slot==2 and not active.get("protector_runtime",{}).is_empty():
				var protector_slot:=AbilitySlotSystem.ui_state(active.protector_runtime.smite_slot);draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),"%d/%d"%[protector_slot.charges,protector_slot.max_charges],HORIZONTAL_ALIGNMENT_CENTER,34,10,C_TEXT)
			if active["class"]=="Death Knight" and slot==3 and str(active.get("selected_heroic_id",""))=="death_knight_l15_r1" and not active.get("death_knight_runtime",{}).is_empty():
				var death_knight_slot:=AbilitySlotSystem.ui_state(active.death_knight_runtime.army_slot);draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),"%d/%d"%[death_knight_slot.charges,death_knight_slot.max_charges],HORIZONTAL_ALIGNMENT_CENTER,34,10,C_TEXT)
			if active["class"]=="Sentinel" and slot in [0,1] and not active.get("sentinel_runtime",{}).is_empty():
				var sentinel_slot:=AbilitySlotSystem.ui_state(active.sentinel_runtime.q_slot if slot==0 else active.sentinel_runtime.w_slot);draw_string(ThemeDB.fallback_font,center+Vector2(18,-20),"%d/%d"%[sentinel_slot.charges,sentinel_slot.max_charges],HORIZONTAL_ALIGNMENT_CENTER,34,10,C_TEXT)

func draw_tutorial_completion_hud()->void:
	if tutorial_active and tutorial_step==4:
		draw_tutorial_box(Rect2(420,570,455,68))
	if tutorial_active and tutorial_step==7:
		if selected!=1:draw_tutorial_box(Rect2(478,570,54,68))
		draw_tutorial_box(Rect2(445,635,78,78))
	if tutorial_active and tutorial_step==8:
		draw_rect(Rect2(300,145,680,330),Color(0.025,.045,.075,.96));draw_rect(Rect2(300,145,680,330),Color(C_GREEN,.8),false,3)
		draw_string(ThemeDB.fallback_font,Vector2(350,195),"TRAINING COMPLETE",HORIZONTAL_ALIGNMENT_CENTER,580,32,C_GREEN)
		draw_string(ThemeDB.fallback_font,Vector2(375,242),"•  Drag heroes to move or assign targets",HORIZONTAL_ALIGNMENT_LEFT,530,20,C_TEXT)
		draw_string(ThemeDB.fallback_font,Vector2(375,282),"•  Brann draws enemy attention",HORIZONTAL_ALIGNMENT_LEFT,530,20,C_TEXT)
		draw_string(ThemeDB.fallback_font,Vector2(375,322),"•  Sera keeps a persistent healing target",HORIZONTAL_ALIGNMENT_LEFT,530,20,C_TEXT)
		draw_string(ThemeDB.fallback_font,Vector2(375,362),"•  Use the action bar for abilities",HORIZONTAL_ALIGNMENT_LEFT,530,20,C_TEXT)
		draw_string(ThemeDB.fallback_font,Vector2(365,427),"Tap to continue" if tutorial_input_device=="mobile" else "Click or press any key to continue",HORIZONTAL_ALIGNMENT_CENTER,550,18,C_GOLD)

func draw_pause_hud()->void:
	if paused:
		draw_rect(Rect2(390,160,500,370 if testing_zone_active else 300),Color(0.03,.05,.08,.94)); draw_string(ThemeDB.fallback_font,Vector2(565,250),"PAUSED",HORIZONTAL_ALIGNMENT_LEFT,-1,34,C_GOLD); draw_rect(Rect2(490,285,300,58),C_PANEL_2); draw_string(ThemeDB.fallback_font,Vector2(600,322),"RESUME",HORIZONTAL_ALIGNMENT_LEFT,-1,20,C_TEXT)
		if testing_zone_active and testing_zone_mode=="range":draw_rect(Rect2(490,360,300,58),C_PANEL_2);draw_string(ThemeDB.fallback_font,Vector2(535,397),"DUMMY ATTACKS: %s"%("YES" if testing_dummy_attacks_enabled else "NO"),HORIZONTAL_ALIGNMENT_CENTER,210,18,C_GREEN if testing_dummy_attacks_enabled else C_MUTED)
		elif testing_zone_active:draw_rect(Rect2(490,360,300,58),C_PANEL_2);draw_string(ThemeDB.fallback_font,Vector2(535,397),"ENEMY LEVEL: %d"%testing_endless_level,HORIZONTAL_ALIGNMENT_CENTER,210,18,C_GOLD)
		var retreat_y:=435 if testing_zone_active else 360;draw_rect(Rect2(490,retreat_y,300,58),C_PANEL_2); draw_string(ThemeDB.fallback_font,Vector2(600,retreat_y+37),"RETREAT",HORIZONTAL_ALIGNMENT_LEFT,-1,20,C_RED)

func draw_combat_hud() -> void:
	draw_tutorial_instruction_hud()
	draw_testing_status_hud()
	if not victory_sequence and (not tutorial_active or tutorial_step>=4):
		draw_party_portraits_hud()
		draw_ability_bar_hud()
		draw_string(ThemeDB.fallback_font,Vector2(1080,50),"●  %d"%state.gold,HORIZONTAL_ALIGNMENT_RIGHT,115,20,C_GOLD);draw_circle(Vector2(1235,42),25,Color(0.08,.11,.16,.9)); draw_string(ThemeDB.fallback_font,Vector2(1222,50),"Ⅱ",HORIZONTAL_ALIGNMENT_LEFT,-1,22,C_TEXT)
	draw_tutorial_completion_hud()
	draw_pause_hud()
	draw_victory_overlay()

func draw_victory_overlay() -> void:
	if victory_sequence and victory_phase>=1:
		draw_string(ThemeDB.fallback_font,Vector2(400,117),"VICTORY",HORIZONTAL_ALIGNMENT_CENTER,480,66,C_GOLD)
		if current_ashwood_encounter!="" and not pending_victory.is_empty():
			var reward:Dictionary=pending_victory.rewards
			if victory_phase>=2:draw_string(ThemeDB.fallback_font,Vector2(420,190),"●  +%d GOLD"%int(reward.gold),HORIZONTAL_ALIGNMENT_CENTER,440,32,C_GOLD)
			if victory_phase>=3:
				var drop_text:="NO EQUIPMENT DROP" if reward.drops.is_empty() else str(reward.drops[0].name).to_upper()
				draw_string(ThemeDB.fallback_font,Vector2(390,240),drop_text,HORIZONTAL_ALIGNMENT_CENTER,500,24,C_MUTED if reward.drops.is_empty() else AshwoodData.RARITY_COLORS[reward.drops[0].rarity])
			if victory_phase>=4:draw_string(ThemeDB.fallback_font,Vector2(390,282),"+%d XP PER HERO"%int(reward.xp),HORIZONTAL_ALIGNMENT_CENTER,500,26,Color("6aa7ff"))
			if victory_phase>=5:
				var xp_animation:float=clampf(victory_timer/1.6,0.0,1.0)
				var xp_progress:Array=reward.get("xp_progress",[])
				for i in heroes.size():
					var hero_index:int=battle_hero_indices[i]
					var progress_data:Dictionary={}
					for candidate in xp_progress:
						if int(candidate.hero_index)==hero_index:progress_data=candidate;break
					if progress_data.is_empty():progress_data={"before_level":state.heroes[hero_index].level,"before_xp":state.heroes[hero_index].xp}
					var shown_progress:Dictionary=victory_xp_animation_state(progress_data,int(reward.xp),xp_animation)
					var shown_level:int=int(shown_progress.level)
					var xp_ratio:float=float(shown_progress.ratio)
					var bar_center_x:float=victory_progress_center(i).x
					health_bar(Vector2(bar_center_x-45,505),90,xp_ratio,Color("6aa7ff"))
					draw_string(ThemeDB.fallback_font,Vector2(bar_center_x-50,532),"LV %d"%shown_level,HORIZONTAL_ALIGNMENT_CENTER,100,13,C_MUTED)
					if xp_animation>=.8 and int(progress_data.get("after_level",shown_level))>int(progress_data.get("before_level",shown_level)):
						var talent_unlocked:=false
						for level_up in reward.get("level_ups",[]):
							if int(level_up.get("hero_index",-1))==hero_index and not level_up.get("talent_tiers",[]).is_empty():talent_unlocked=true;break
						draw_string(ThemeDB.fallback_font,Vector2(bar_center_x-72,557),"NEW TALENT TIER!" if talent_unlocked else "LEVEL UP!",HORIZONTAL_ALIGNMENT_CENTER,144,15,C_GOLD if talent_unlocked else C_GREEN)
				if xp_animation>=1.0:draw_string(ThemeDB.fallback_font,Vector2(440,610),victory_continue_prompt(),HORIZONTAL_ALIGNMENT_CENTER,400,22,C_MUTED)
		else:
			if victory_phase>=2:draw_string(ThemeDB.fallback_font,Vector2(420,190),"●  +%d"%(90+dungeon_id*55),HORIZONTAL_ALIGNMENT_CENTER,440,36,C_GOLD)
			if victory_phase>=3:
				draw_string(ThemeDB.fallback_font,Vector2(390,230),"MATERIALS COLLECTED",HORIZONTAL_ALIGNMENT_CENTER,500,24,C_GREEN)
				for result_index in battle_material_results.size():
					var material_result:Dictionary=battle_material_results[result_index];var material_name:=str(InventorySystem.MATERIAL_DEFINITIONS.get(str(material_result.material_id),{"display_name":material_result.material_id}).display_name);var result_text:="%s  %d / %d"%[material_name,int(material_result.collected),int(material_result.requested)];if int(material_result.rejected)>0:result_text+="  •  %d NOT COLLECTED (VAULT FULL)"%int(material_result.rejected);draw_string(ThemeDB.fallback_font,Vector2(390,255+result_index*20),result_text,HORIZONTAL_ALIGNMENT_CENTER,500,14,C_RED if int(material_result.rejected)>0 else C_TEXT)
			if victory_phase>=4:draw_string(ThemeDB.fallback_font,Vector2(390,325),"SPECIAL REWARD",HORIZONTAL_ALIGNMENT_CENTER,500,24,Color("b381ff"))
			if victory_phase>=5:
				for level_up in victory_level_ups:
					var marker_center:=victory_progress_center(int(level_up.slot))
					var marker_text:="NEW TALENT TIER!" if not level_up.get("talent_tiers",[]).is_empty() else "LEVEL UP!"
					draw_string(ThemeDB.fallback_font,marker_center+Vector2(-72,92),marker_text,HORIZONTAL_ALIGNMENT_CENTER,144,15,C_GOLD if marker_text.begins_with("NEW") else C_GREEN)
				draw_string(ThemeDB.fallback_font,Vector2(440,585),victory_continue_prompt(),HORIZONTAL_ALIGNMENT_CENTER,400,24,C_MUTED)

func _draw() -> void:
	if screen not in ["combat","ashwood_victory"]:return
	draw_combat_background()
	draw_shared_combat_objects()
	draw_world_combat_context()
	draw_combat_enemies()
	draw_combat_summons()
	draw_combat_heroes()
	draw_combat_input_preview()
	for fx in effects:draw_combat_effect(fx)
	if screen=="combat":draw_combat_hud()
	draw_combat_debug_overlay()
	if toast_time>0 and screen!="combat":draw_string(ThemeDB.fallback_font,Vector2(480,680),toast,HORIZONTAL_ALIGNMENT_LEFT,-1,17,C_GOLD)

func flash(msg:String)->void:toast=msg;toast_time=2.5;queue_redraw()
