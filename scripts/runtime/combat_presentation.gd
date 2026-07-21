extends "res://scripts/runtime/victory_runtime.gd"

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
	draw_rect(Rect2(18,16,285,190),Color(0.02,.03,.05,.88));draw_rect(Rect2(18,16,285,190),C_MUTED,false,2)
	for line_index in lines.size():draw_string(ThemeDB.fallback_font,Vector2(32,42+line_index*20),lines[line_index],HORIZONTAL_ALIGNMENT_LEFT,-1,13,C_TEXT)

func _draw() -> void:
	if screen not in ["combat","ashwood_victory"]:return
	draw_combat_background()
	draw_shared_combat_objects()
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
	for i in enemies.size():
		var e=enemies[i]; if e.hp<=0:continue
		if e.telegraph>0:
			var warning_pos=e.danger_pos if e.special=="danger" or e.special=="charge" or e.special=="basic" else e.pos; var warning_radius=38.0 if e.special=="basic" else 78.0 if e.special=="danger" else 115.0
			draw_circle(warning_pos,warning_radius,Color(1,.15,.12,.16));draw_arc(warning_pos,warning_radius,0,TAU,48,C_RED,3)
			if e.special=="charge": draw_dashed_line(e.pos,e.danger_pos,C_RED,5,10)
		var enemy_color=GameData.enemy_color(e.type)
		var target_outline:=Color.WHITE if focused_enemy_index==i else C_GOLD if heroes.size()>selected and heroes[selected].target==i else Color("5f2931")
		var enemy_radius:=62.0 if e.type=="Defense Dummy" else 46.0;draw_circle(e.pos,enemy_radius,enemy_color); draw_circle(e.pos,enemy_radius+6,target_outline,4); if not victory_sequence and (e.revealed or e.hp<e.max_hp):health_bar(e.pos+Vector2(-54,-enemy_radius-24),108,e.hp/e.max_hp,C_RED); draw_string(ThemeDB.fallback_font,e.pos+Vector2(-55,6),"DEFENSE" if e.type=="Defense Dummy" else e.type.substr(0,7),HORIZONTAL_ALIGNMENT_CENTER,110,15,C_TEXT)
		if testing_zone_active and not e.get("bloodletting_stacks",[]).is_empty():draw_string(ThemeDB.fallback_font,e.pos+Vector2(-50,enemy_radius+22),"Bloodletting x%d"%e.bloodletting_stacks.size(),HORIZONTAL_ALIGNMENT_CENTER,100,12,Color("f09a9f"))
	for i in heroes.size():
		var h=heroes[i]; var col=CLASSES[h["class"]].color; if h.hp<=0:col=Color("455067")
		if bool(h.get("incapacitated",false)):
			draw_circle(h.pos,50,Color("202735"));draw_line(h.pos+Vector2(-24,-24),h.pos+Vector2(24,24),C_RED,7);draw_line(h.pos+Vector2(-24,24),h.pos+Vector2(24,-24),C_RED,7);continue
		if int(h.get("basic_action_phase",CombatRulesV1.BasicActionPhase.READY))==CombatRulesV1.BasicActionPhase.WINDUP:
			var windup_progress:=clampf(float(h.basic_action_timer)/maxf(.01,float(h.basic_action_release_time)),0.0,1.0)
			draw_arc(h.pos,54,-PI/2,-PI/2+TAU*windup_progress,28,Color(col,.82),3)
			draw_circle(h.pos+h.facing_direction*43,5,Color(col,.72))
		if i==selected and not victory_sequence and not bool(h.get("independent",false)):
			draw_circle(h.pos,66,Color(C_GOLD,.18));draw_circle(h.pos,59,C_GOLD,4)
		if h.shield>0 and not victory_sequence:draw_circle(h.pos,63,Color("5fa8ff"),4)
		draw_circle(h.pos,48,col);draw_role_icon(h.pos,h["class"]);if not victory_sequence and (h.hp<h.max_hp or h.last_hit>0 or h.shield>0):health_bar_with_shield(h.pos+Vector2(-54,-70),108,h)
		if bool(h.get("independent",false)) and not victory_sequence:draw_string(ThemeDB.fallback_font,h.pos+Vector2(-42,-62),"ALLIED NPC",HORIZONTAL_ALIGNMENT_CENTER,84,12,C_GREEN)
		if testing_zone_active and not victory_sequence:
			var status_parts:Array[String]=[]
			if int(h.get("soul_furnace_stacks",0))>0:status_parts.append("Soul x%d"%h.soul_furnace_stacks)
			if not h.get("retribution_charges",[]).is_empty():status_parts.append("Ret %d"%h.retribution_charges.size())
			if hero_has_passive(h,"borrowed_time"):status_parts.append("Mirror Ready" if h.borrowed_time_armed else "Mirror %.1f"%maxf(0.0,8.0-float(h.borrowed_time_timer)))
			if hero_has_passive(h,"twin_incantation"):status_parts.append("Q %d/2"%h.q_charges)
			if not status_parts.is_empty():draw_string(ThemeDB.fallback_font,h.pos+Vector2(-65,79),"  ".join(status_parts),HORIZONTAL_ALIGNMENT_CENTER,130,11,C_GOLD)
	if dragging_hero:
		draw_dashed_line(heroes[selected].pos,drag_cursor,Color(C_GOLD,.75),6,8)
		var preview_color=C_GREEN if drag_target_type=="ally" else (C_RED if drag_target_type=="enemy" else C_GOLD)
		var preview_pos=drag_cursor
		if drag_target_type=="enemy":preview_pos=enemies[drag_target_index].pos
		elif drag_target_type=="ally":preview_pos=heroes[drag_target_index].pos
		draw_circle(preview_pos,42,Color(preview_color,.14));draw_arc(preview_pos,42,0,TAU,40,preview_color,4)
	if ability_aiming and selected<heroes.size():
		var aiming_hero=heroes[selected];var range_limit=float(ABILITY_RANGES[aiming_hero["class"]][aimed_ability_slot]);var aim_point=clamped_cast_point(aiming_hero,ability_aim_point,range_limit) if range_limit>0 else aiming_hero.pos
		if range_limit>0:draw_circle(aiming_hero.pos,range_limit,Color(C_GOLD,.035));draw_arc(aiming_hero.pos,range_limit,0,TAU,64,Color(C_GOLD,.55),2)
		if aimed_ability_category=="ground":draw_circle(aim_point,30,Color(C_GOLD,.16));draw_arc(aim_point,30,0,TAU,30,C_GOLD,3);draw_dashed_line(aiming_hero.pos,aim_point,Color(C_GOLD,.7),8,6)
		elif aimed_ability_category=="directional":draw_dashed_line(aiming_hero.pos,aim_point,C_GOLD,10,6);draw_circle(aim_point,14,Color(C_GOLD,.3))
		elif aimed_ability_category=="area":draw_circle(aiming_hero.pos,max(90.0,range_limit),Color(C_GOLD,.10));draw_arc(aiming_hero.pos,max(90.0,range_limit),0,TAU,48,C_GOLD,3)
	for fx in effects: draw_combat_effect(fx)
	if screen!="combat":return
	if tutorial_should_show_instruction_box():
		var instruction_pulse=.5+.5*sin(tutorial_timer*5.0) if tutorial_idle_hint_shown else 0.0
		var instruction_rect=Rect2(230,18,820,82)
		if tutorial_idle_hint_shown:draw_rect(instruction_rect.grow(3+instruction_pulse*5),Color(C_GOLD,.035+.055*instruction_pulse))
		draw_rect(instruction_rect,Color(0.03,.055,.09,.92));draw_rect(instruction_rect,Color(C_GOLD,.55+.4*instruction_pulse),false,2+instruction_pulse*2);draw_string(ThemeDB.fallback_font,Vector2(275,43),"TRAINING",HORIZONTAL_ALIGNMENT_CENTER,730,14,C_GOLD);draw_string(ThemeDB.fallback_font,Vector2(275,74),tutorial_prompt(),HORIZONTAL_ALIGNMENT_CENTER,730,19,C_TEXT)
		if tutorial_reject_time>0:
			draw_rect(Rect2(320,106,640,38),Color(0.03,.055,.09,.94));draw_rect(Rect2(320,106,640,38),Color(C_GOLD,.65),false,2);draw_string(ThemeDB.fallback_font,Vector2(345,131),tutorial_feedback_message,HORIZONTAL_ALIGNMENT_CENTER,590,15,C_GOLD)
	if testing_zone_active and not item_feedback_feed.is_empty():
		draw_rect(Rect2(18,18,250,24+item_feedback_feed.size()*19),Color(0.03,.05,.08,.76));draw_string(ThemeDB.fallback_font,Vector2(30,39),"ITEM EFFECTS",HORIZONTAL_ALIGNMENT_LEFT,-1,12,C_GOLD)
		for feed_index in item_feedback_feed.size():draw_string(ThemeDB.fallback_font,Vector2(30,59+feed_index*19),item_feedback_feed[feed_index],HORIZONTAL_ALIGNMENT_LEFT,225,12,C_TEXT)
	if not victory_sequence and (not tutorial_active or tutorial_step>=4):
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
				draw_string(ThemeDB.fallback_font,center+Vector2(-8,20),str(i+1),HORIZONTAL_ALIGNMENT_CENTER,16,11,C_GOLD if is_selected else C_MUTED)
		if tutorial_should_show_ability_bar():
			var active=heroes[selected];var keys=["Q","W","E","R","D"];var hero_level:=int(state.heroes[battle_hero_indices[selected]].level)
			var visible_slots:Array=[0,4]
			for ability_slot in [1,2,3]:
				if TalentSystem.ability_is_unlocked(hero_level,ability_slot) and (ability_slot!=3 or str(active.get("selected_heroic_id",""))!=""):visible_slots.insert(visible_slots.size()-1,ability_slot)
			for slot in visible_slots:
				var center=Vector2(484+slot*78,674);var action_name:String=str(ABILITIES[active["class"]][slot]) if slot<4 else "Stoneform" if active["class"]=="Guardian" and GuardianSystem.has_talent(active,"guardian_l24_2") else str(TRAITS[active["class"]])
				if slot==3 and active["class"]=="Cleric":action_name=str(ClericData.WORKING_NAMES.get(str(active.get("selected_heroic_id","")),"Heroic"))
				elif slot==4 and active["class"]=="Cleric" and ClericSystem.has_talent(active,"cleric_l12_2"):action_name="Safety Sprint"
				elif slot==4 and active["class"]=="Cleric" and ClericSystem.has_talent(active,"cleric_l12_3"):action_name="Let's Go!"
				draw_octagon(center,37,Color("263a57") if slot<3 else Color("59402b"),C_MUTED,3);draw_string(ThemeDB.fallback_font,center+Vector2(-34,-4),action_name.substr(0,10),HORIZONTAL_ALIGNMENT_CENTER,68,10,C_TEXT);draw_string(ThemeDB.fallback_font,center+Vector2(-28,25),keys[slot],HORIZONTAL_ALIGNMENT_CENTER,56,14,C_GOLD)
				if active.ability_cds[slot]>0:draw_octagon(center,37,Color(0,0,0,.62),C_MUTED,2);draw_string(ThemeDB.fallback_font,center+Vector2(-18,7),"%.1f"%active.ability_cds[slot],HORIZONTAL_ALIGNMENT_CENTER,36,15,C_TEXT)
			if active["class"]=="Guardian" and not active.get("guardian_runtime",{}).is_empty():
				var status_parts:Array=[]
				if GuardianSystem.has_talent(active,"guardian_l24_3"):status_parts.append("PRESENCE READY" if battle_time>=float(active.guardian_runtime.imposing_ready_at) else "PRESENCE %.0fs"%(float(active.guardian_runtime.imposing_ready_at)-battle_time))
				if GuardianSystem.has_talent(active,"guardian_l30_2"):status_parts.append("SHIELD READY" if battle_time>=float(active.guardian_runtime.hardened_ready_at) else "SHIELD %.0fs"%(float(active.guardian_runtime.hardened_ready_at)-battle_time))
				if GuardianSystem.has_talent(active,"guardian_l30_3"):status_parts.append("REWIND %d/3"%GuardianSystem.rewind_sequence_count(active,battle_time) if battle_time>=float(active.guardian_runtime.rewind_ready_at) else "REWIND %.0fs"%(float(active.guardian_runtime.rewind_ready_at)-battle_time))
				if not status_parts.is_empty():draw_string(ThemeDB.fallback_font,Vector2(450,620),"  •  ".join(status_parts),HORIZONTAL_ALIGNMENT_CENTER,390,11,C_MUTED)
			elif active["class"]=="Cleric" and not active.get("cleric_runtime",{}).is_empty() and testing_zone_active:
				var cleric_status:="FAST FEET  Q/E %.2fx  W %.2fx"%[ClericSystem.qwe_cooldown_rate(active),ClericSystem.w_cooldown_rate(active)] if ClericSystem.fast_feet_active(active) else "FAST FEET READY"
				draw_string(ThemeDB.fallback_font,Vector2(450,620),cleric_status,HORIZONTAL_ALIGNMENT_CENTER,390,11,C_MUTED)
		draw_string(ThemeDB.fallback_font,Vector2(1080,50),"●  %d"%state.gold,HORIZONTAL_ALIGNMENT_RIGHT,115,20,C_GOLD);draw_circle(Vector2(1235,42),25,Color(0.08,.11,.16,.9)); draw_string(ThemeDB.fallback_font,Vector2(1222,50),"Ⅱ",HORIZONTAL_ALIGNMENT_LEFT,-1,22,C_TEXT)

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
	if paused:
		draw_rect(Rect2(390,160,500,370 if testing_zone_active else 300),Color(0.03,.05,.08,.94)); draw_string(ThemeDB.fallback_font,Vector2(565,250),"PAUSED",HORIZONTAL_ALIGNMENT_LEFT,-1,34,C_GOLD); draw_rect(Rect2(490,285,300,58),C_PANEL_2); draw_string(ThemeDB.fallback_font,Vector2(600,322),"RESUME",HORIZONTAL_ALIGNMENT_LEFT,-1,20,C_TEXT)
		if testing_zone_active:draw_rect(Rect2(490,360,300,58),C_PANEL_2);draw_string(ThemeDB.fallback_font,Vector2(535,397),"DUMMY ATTACKS: %s"%("YES" if testing_dummy_attacks_enabled else "NO"),HORIZONTAL_ALIGNMENT_CENTER,210,18,C_GREEN if testing_dummy_attacks_enabled else C_MUTED)
		var retreat_y:=435 if testing_zone_active else 360;draw_rect(Rect2(490,retreat_y,300,58),C_PANEL_2); draw_string(ThemeDB.fallback_font,Vector2(600,retreat_y+37),"RETREAT",HORIZONTAL_ALIGNMENT_LEFT,-1,20,C_RED)
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
	draw_combat_debug_overlay()
	if toast_time>0:draw_string(ThemeDB.fallback_font,Vector2(480,680),toast,HORIZONTAL_ALIGNMENT_LEFT,-1,17,C_GOLD)

func health_bar(pos:Vector2,width:float,ratio:float,color:Color)->void:
	draw_rect(Rect2(pos,Vector2(width,7)),Color("11151e"));draw_rect(Rect2(pos,Vector2(width*clamp(ratio,0,1),7)),color)

func health_bar_with_shield(pos:Vector2,width:float,unit:Dictionary)->void:
	var health_ratio:float=clampf(float(unit.hp)/maxf(1.0,float(unit.max_hp)),0.0,1.0);health_bar(pos,width,health_ratio,C_GREEN)
	var shield_width:float=minf(width,float(unit.get("shield",0.0))/maxf(1.0,float(unit.max_hp))*width)
	if shield_width>0:draw_rect(Rect2(pos+Vector2(min(width-shield_width,width*health_ratio),0),Vector2(shield_width,7)),Color("55aaff"))
func add_effect(kind:String,from:Vector2,to:Vector2,text_value:String,color:Color)->void:
	effects.append({"kind":kind,"from":from,"to":to,"text":text_value,"color":color,"life":.75 if kind!="heroic" else 1.25,"max_life":.75 if kind!="heroic" else 1.25})
func draw_combat_effect(fx:Dictionary)->void:
	var progress=1.0-fx.life/fx.max_life
	var alpha=clamp(fx.life*2.0,0.0,1.0)
	var col=Color(fx.color,alpha)
	match fx.kind:
		"projectile":
			var p=fx.from.lerp(fx.to,clamp(progress*1.8,0.0,1.0));draw_line(p-Vector2(12,0),p+Vector2(8,0),col,5);draw_circle(p,5,Color.WHITE)
		"slash":
			draw_line(fx.to+Vector2(-22,-18),fx.to+Vector2(22,18),col,7);draw_line(fx.to+Vector2(-16,22),fx.to+Vector2(18,-16),Color.WHITE,3)
		"hit":
			draw_circle(fx.to,28+progress*22,Color(col,.16));draw_line(fx.from,fx.to,col,4)
		"heal":
			draw_line(fx.from,fx.to,col,4);draw_circle(fx.to,25+progress*30,Color(col,.18));draw_arc(fx.to,25+progress*30,0,TAU,30,col,3)
		"cast":
			draw_arc(fx.from,30+progress*18,0,TAU,32,col,4)
		"heroic":
			draw_circle(fx.from,38+progress*80,Color(col,.14));draw_arc(fx.from,38+progress*80,0,TAU,40,col,6)

	if fx.text!="":
		var text_pos=fx.to+Vector2(-28,-48-progress*30)
		draw_string(ThemeDB.fallback_font,text_pos,fx.text,HORIZONTAL_ALIGNMENT_CENTER,90,17,col)
func draw_role_icon(pos:Vector2,hero_class:String,ink:Color=Color("101827"))->void:
	if hero_class=="Guardian":
		var shield=PackedVector2Array([pos+Vector2(-11,-13),pos+Vector2(11,-13),pos+Vector2(9,5),pos+Vector2(0,15),pos+Vector2(-9,5)])
		draw_colored_polygon(shield,ink);draw_polyline(shield+PackedVector2Array([shield[0]]),Color.WHITE,2)
	elif hero_class=="Cleric":
		draw_rect(Rect2(pos+Vector2(-5,-15),Vector2(10,30)),ink);draw_rect(Rect2(pos+Vector2(-15,-5),Vector2(30,10)),ink)
	elif hero_class=="Mage":
		draw_line(pos+Vector2(-11,13),pos+Vector2(8,-8),ink,5);draw_circle(pos+Vector2(11,-11),6,ink);draw_circle(pos+Vector2(11,-11),2,Color.WHITE)
	elif hero_class=="Rogue":
		draw_line(pos+Vector2(-13,12),pos+Vector2(11,-12),ink,5);draw_line(pos+Vector2(-11,-12),pos+Vector2(13,12),ink,5)
	elif hero_class=="Warlock":
		draw_circle(pos,13,Color.TRANSPARENT,2);draw_arc(pos,14,0,TAU,28,ink,4);draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-15),pos+Vector2(10,6),pos+Vector2(0,2),pos+Vector2(-10,6)]),ink)
	else:
		# Ranged DPS use a bow marker. Future melee classes can use crossed swords.
		draw_arc(pos+Vector2(-3,0),15,-PI/2,PI/2,18,ink,4);draw_line(pos+Vector2(-3,-15),pos+Vector2(-3,15),ink,2);draw_line(pos+Vector2(-3,0),pos+Vector2(15,0),ink,3);draw_colored_polygon(PackedVector2Array([pos+Vector2(15,0),pos+Vector2(8,-5),pos+Vector2(8,5)]),ink)
func flash(msg:String)->void:toast=msg;toast_time=2.5;queue_redraw()
