extends "res://scripts/runtime/sentinel_runtime.gd"

func huntsman_visual(kind:String, from:Vector2, to:Vector2, duration:float, extra:Dictionary={}) -> void:
	var effect := {"kind":kind,"from":from,"to":to,"text":"","color":CLASSES.Huntsman.color,"life":duration,"max_life":duration}
	effect.merge(extra, true)
	effects.append(effect)

func huntsman_target(hero:Dictionary, max_range:float):
	var index := combat_enemy_target()
	if index >= 0 and index < enemies.size() and enemies[index].hp > 0.0 and hero.pos.distance_to(enemies[index].pos) <= max_range:
		return enemies[index]
	return null

func huntsman_cast_cocktail(hero:Dictionary, point:Vector2) -> bool:
	if float(hero.huntsman_runtime.human_q_cooldown) > 0.0: return false
	var direction := Vector2(hero.pos).direction_to(point)
	if direction == Vector2.ZERO: direction = Vector2(hero.facing_direction)
	var range_limit := float(HuntsmanData.SPACE.cocktail_range) * (1.30 if HuntsmanSystem.has_talent(hero, "huntsman_l9_2") else 1.0)
	hero.huntsman_runtime.human_q_cooldown = HuntsmanSystem.q_cooldown(hero, "human")
	hero.huntsman_runtime.projectiles.append({"kind":"cocktail","position":Vector2(hero.pos),"direction":direction,"remaining":range_limit,"hit_ids":[]})
	HuntsmanSystem.telemetry_add(hero, "cocktail_casts")
	return true

func huntsman_resolve_swipe(hero:Dictionary, free_cast:bool=false) -> bool:
	if not free_cast and float(hero.huntsman_runtime.worgen_q_cooldown) > 0.0: return false
	if not free_cast: hero.huntsman_runtime.worgen_q_cooldown = HuntsmanSystem.q_cooldown(hero, "worgen")
	var distance := float(HuntsmanData.SPACE.swipe_distance) * (1.60 if HuntsmanSystem.has_talent(hero, "huntsman_l21_2") else 1.0)
	var start := Vector2(hero.pos)
	hero.pos = CombatGeometry.move_toward_safe(hero.pos, hero.pos + Vector2(hero.facing_direction) * distance, distance, 42.0, combat_blockers)
	hero.dest = hero.pos
	var damage := HuntsmanSystem.ability_amount(hero, float(HuntsmanData.VALUES.swipe_damage)) * (2.0 if HuntsmanSystem.has_talent(hero, "huntsman_l30_2") else 1.0)
	for target in enemies:
		if target.hp <= 0.0 or target.pos.distance_to(hero.pos) > float(HuntsmanData.SPACE.swipe_radius): continue
		var result := deal_damage(hero, target, damage, "basic_ability", "physical", "Razor Swipe", false, "huntsman_swipe", [], true)
		if float(result.get("resolved_damage", 0.0)) > 0.0:
			HuntsmanSystem.add_mark_stack(hero, target)
			HuntsmanSystem.refresh_inner_beast(hero, true)
			HuntsmanSystem.telemetry_add(hero, "swipe_damage", float(result.resolved_damage))
	HuntsmanSystem.telemetry_add(hero, "swipe_casts")
	huntsman_visual("huntsman_swipe", start, hero.pos, .32, {"radius":float(HuntsmanData.SPACE.swipe_radius)})
	return true

func huntsman_cast_inner_beast(hero:Dictionary) -> bool:
	if float(hero.ability_cds[1]) > 0.0: return false
	hero.ability_cds[1] = float(HuntsmanData.VALUES.inner_beast_cooldown)
	HuntsmanSystem.activate_inner_beast(hero)
	huntsman_visual("huntsman_inner_beast", hero.pos, hero.pos, .7, {"radius":62.0})
	return true

func huntsman_cast_darkflight(hero:Dictionary) -> bool:
	if float(hero.huntsman_runtime.shared_e_cooldown) > 0.0: return false
	var target = huntsman_target(hero, HuntsmanSystem.e_range(hero, "human"))
	if target == null: return false
	hero.huntsman_runtime.shared_e_cooldown = HuntsmanSystem.e_cooldown(hero)
	var start := Vector2(hero.pos)
	var travel_direction := Vector2(hero.pos).direction_to(target.pos)
	hero.pos = Vector2(target.pos) + Vector2(target.pos).direction_to(hero.pos) * 42.0
	hero.dest = hero.pos
	if travel_direction != Vector2.ZERO: hero.facing_direction = travel_direction
	HuntsmanSystem.change_form(hero, "worgen", "Darkflight", battle_time)
	var marked = unit_by_combat_id(str(hero.huntsman_runtime.marked_target_id))
	if marked != null: HuntsmanSystem.add_mark_stack(hero, marked)
	if HuntsmanSystem.has_talent(hero, "huntsman_l12_1"): BlockChargeSystem.grant(hero, 2, 2, "huntsman_block")
	if HuntsmanSystem.has_talent(hero, "huntsman_l18_3"):
		huntsman_resolve_swipe(hero, true)
	else:
		var result := deal_damage(hero, target, HuntsmanSystem.ability_amount(hero, float(HuntsmanData.VALUES.darkflight_damage)), "basic_ability", "physical", "Darkflight", false, "huntsman_darkflight", [], true)
		if float(result.get("resolved_damage", 0.0)) > 0.0:
			HuntsmanSystem.refresh_inner_beast(hero, true)
			HuntsmanSystem.telemetry_add(hero, "darkflight_damage", float(result.resolved_damage))
	HuntsmanSystem.telemetry_add(hero, "darkflight_casts")
	huntsman_visual("huntsman_darkflight", start, hero.pos, .34)
	return true

func huntsman_cast_disengage(hero:Dictionary, point:Vector2) -> bool:
	if float(hero.huntsman_runtime.shared_e_cooldown) > 0.0: return false
	var offset := point - Vector2(hero.pos)
	if offset == Vector2.ZERO: offset = -Vector2(hero.facing_direction)
	var destination := Vector2(hero.pos) + offset.normalized() * minf(offset.length(), HuntsmanSystem.e_range(hero, "worgen"))
	var start := Vector2(hero.pos)
	hero.pos = CombatGeometry.move_toward_safe(hero.pos, destination, hero.pos.distance_to(destination), 42.0, combat_blockers)
	hero.dest = hero.pos
	hero.huntsman_runtime.shared_e_cooldown = HuntsmanSystem.e_cooldown(hero)
	HuntsmanSystem.change_form(hero, "human", "Disengage", battle_time)
	if HuntsmanSystem.has_talent(hero, "huntsman_l12_2"): StealthDetectionSystem.set_stealth_source(hero, "huntsman_eyes:%s" % str(hero.combat_id), true);hero.huntsman_runtime["eyes_remaining"] = 3.0
	var marked = unit_by_combat_id(str(hero.huntsman_runtime.marked_target_id))
	if marked != null: HuntsmanSystem.add_mark_stack(hero, marked)
	HuntsmanSystem.telemetry_add(hero, "disengage_casts")
	huntsman_visual("huntsman_disengage", start, hero.pos, .34)
	return true

func huntsman_cast_heroic(hero:Dictionary, point:Vector2) -> bool:
	var heroic := str(hero.get("selected_heroic_id", ""))
	if heroic == "huntsman_l15_r1":
		if float(hero.ability_cds[3]) > 0.0 and not bool(hero.huntsman_runtime.r1_repeat_available): return false
		var target = huntsman_target(hero, float(HuntsmanData.SPACE.heroic_range))
		if target == null: return false
		var repeat := bool(hero.huntsman_runtime.r1_repeat_available)
		if repeat: hero.huntsman_runtime.r1_repeat_available = false;hero.huntsman_runtime.r1_repeat_remaining = 0.0
		else: hero.ability_cds[3] = float(HuntsmanData.VALUES.r1_cooldown)
		var start := Vector2(hero.pos)
		hero.pos = Vector2(target.pos) + Vector2(target.pos).direction_to(hero.pos) * 42.0;hero.dest = hero.pos
		HuntsmanSystem.change_form(hero, "worgen", "Go for the Throat", battle_time)
		var damage := HuntsmanSystem.ability_amount(hero, float(HuntsmanData.VALUES.r1_damage)) * (1.25 if HuntsmanSystem.has_talent(hero, "huntsman_l27_r1") else 1.0)
		var result := deal_damage(hero, target, damage, "heroic", "physical", "Go for the Throat", false, "huntsman_r1", [], true)
		if bool(result.get("defeated", false)):
			hero.huntsman_runtime.r1_repeat_available = true;hero.huntsman_runtime.r1_repeat_remaining = float(HuntsmanData.VALUES.r1_repeat_window)
			if HuntsmanSystem.has_talent(hero, "huntsman_l27_r1"):
				hero.huntsman_runtime.human_q_cooldown = 0.0;hero.huntsman_runtime.worgen_q_cooldown = 0.0;hero.huntsman_runtime.shared_e_cooldown = 0.0;hero.ability_cds[1] = 0.0
			HuntsmanSystem.telemetry_add(hero, "r1_resets")
		HuntsmanSystem.telemetry_add(hero, "r1_casts");HuntsmanSystem.telemetry_add(hero, "r1_damage", float(result.resolved_damage));huntsman_visual("huntsman_r1", start, hero.pos, .4);return true
	if heroic == "huntsman_l15_r2":
		if bool(hero.huntsman_runtime.marked_reactivation) and float(hero.huntsman_runtime.mark_remaining) > 0.0:
			var prey = unit_by_combat_id(str(hero.huntsman_runtime.marked_target_id))
			if prey == null or prey.hp <= 0.0: HuntsmanSystem.clear_mark(hero);return false
			var start := Vector2(hero.pos);hero.pos = Vector2(prey.pos) + Vector2(prey.pos).direction_to(hero.pos) * 42.0;hero.dest = hero.pos
			HuntsmanSystem.change_form(hero, "worgen", "Marked for the Kill Reactivation", battle_time);hero.huntsman_runtime.marked_reactivation = false;huntsman_visual("huntsman_mark_leap", start, hero.pos, .4);return true
		if float(hero.ability_cds[3]) > 0.0: return false
		var direction := Vector2(hero.pos).direction_to(point)
		if direction == Vector2.ZERO: direction = Vector2(hero.facing_direction)
		HuntsmanSystem.change_form(hero, "human", "Marked for the Kill", battle_time)
		hero.ability_cds[3] = float(HuntsmanData.VALUES.r2_cooldown)
		hero.huntsman_runtime.projectiles.append({"kind":"marked","position":Vector2(hero.pos),"direction":direction,"remaining":float(HuntsmanData.SPACE.marked_range),"hit_ids":[]})
		HuntsmanSystem.telemetry_add(hero, "r2_casts");return true
	return false

func cast_huntsman_ability(slot:int, point:Vector2, _item_repeat:bool=false) -> bool:
	if selected < 0 or selected >= heroes.size(): return false
	var hero:Dictionary = heroes[selected]
	if str(hero.get("class", "")) != "Huntsman" or hero.get("huntsman_runtime", {}).is_empty(): return false
	match slot:
		0: return huntsman_resolve_swipe(hero) if HuntsmanSystem.is_worgen(hero) else huntsman_cast_cocktail(hero, point)
		1: return huntsman_cast_inner_beast(hero)
		2: return huntsman_cast_disengage(hero, point) if HuntsmanSystem.is_worgen(hero) else huntsman_cast_darkflight(hero)
		3: return huntsman_cast_heroic(hero, point)
	return false

func update_huntsman_projectile(hero:Dictionary, projectile:Dictionary, delta:float) -> bool:
	var previous := Vector2(projectile.position)
	var speed := float(HuntsmanData.SPACE.marked_speed if projectile.kind == "marked" else HuntsmanData.SPACE.cocktail_speed)
	var step := minf(float(projectile.remaining), speed * delta)
	projectile.position = previous + Vector2(projectile.direction) * step;projectile.remaining = float(projectile.remaining) - step
	huntsman_visual("huntsman_marked_projectile" if projectile.kind == "marked" else "huntsman_cocktail_projectile", previous, projectile.position, maxf(.08, delta * 1.5))
	var width := float(HuntsmanData.SPACE.marked_width if projectile.kind == "marked" else HuntsmanData.SPACE.cocktail_width)
	var hits := enemies.filter(func(target): return target.hp > 0.0 and CombatGeometry.segment_distance_to_point(previous, projectile.position, target.pos) <= width + float(target.get("combat_radius", 28.0)))
	if hits.is_empty(): return float(projectile.remaining) > 0.0
	hits.sort_custom(func(a,b): return previous.distance_squared_to(a.pos) < previous.distance_squared_to(b.pos))
	var primary:Dictionary = hits[0]
	if projectile.kind == "marked":
		var result := deal_damage(hero, primary, HuntsmanSystem.ability_amount(hero, float(HuntsmanData.VALUES.r2_damage)), "heroic", "physical", "Marked for the Kill", false, "huntsman_r2", [], true)
		if float(result.get("resolved_damage", 0.0)) > 0.0:
			HuntsmanSystem.apply_mark(hero, primary);StealthDetectionSystem.reveal(primary, float(hero.huntsman_runtime.mark_remaining));HuntsmanSystem.telemetry_add(hero, "r2_damage", float(result.resolved_damage))
		return false
	var impact := deal_damage(hero, primary, HuntsmanSystem.ability_amount(hero, float(HuntsmanData.VALUES.cocktail_impact)), "basic_ability", "physical", "Gilnean Cocktail", false, "huntsman_cocktail_impact", [], true)
	HuntsmanSystem.telemetry_add(hero, "cocktail_impact_damage", float(impact.resolved_damage));HuntsmanSystem.refresh_inner_beast(hero, true);HuntsmanSystem.add_mark_stack(hero, primary)
	var explosion_multiplier := 1.0 + float(hero.huntsman_runtime.cocktail_quest_stacks) * 25.0 / maxf(1.0, float(HuntsmanData.VALUES.cocktail_explosion))
	var explosion_length := float(HuntsmanData.SPACE.cocktail_cone_range) * (1.35 if HuntsmanSystem.has_talent(hero, "huntsman_l9_2") else 1.0)
	for target in enemies:
		if target == primary or target.hp <= 0.0: continue
		var offset := Vector2(target.pos) - Vector2(primary.pos)
		if offset.length() > explosion_length or absf(Vector2(projectile.direction).angle_to(offset.normalized())) > float(HuntsmanData.SPACE.cocktail_cone_half_angle): continue
		var explosion := deal_damage(hero, target, HuntsmanSystem.ability_amount(hero, float(HuntsmanData.VALUES.cocktail_explosion)) * explosion_multiplier, "basic_ability", "physical", "Gilnean Cocktail Explosion", false, "huntsman_cocktail_explosion", [], true)
		if float(explosion.get("resolved_damage", 0.0)) > 0.0:
			HuntsmanSystem.add_mark_stack(hero, target);HuntsmanSystem.telemetry_add(hero, "cocktail_explosion_damage", float(explosion.resolved_damage))
			if HuntsmanSystem.has_talent(hero, "huntsman_l18_2") and TargetCategorySystem.qualifies_quest(target): hero.huntsman_runtime.cocktail_quest_stacks = mini(15, int(hero.huntsman_runtime.cocktail_quest_stacks) + 1)
	huntsman_visual("huntsman_cocktail_cone", primary.pos, primary.pos + Vector2(projectile.direction) * explosion_length, .45, {"radius":explosion_length})
	return false

func update_huntsman_runtime(delta:float) -> void:
	for hero in heroes:
		if str(hero.get("class", "")) != "Huntsman" or hero.get("huntsman_runtime", {}).is_empty(): continue
		HuntsmanSystem.update(hero, delta)
		if float(hero.huntsman_runtime.get("eyes_remaining", 0.0)) > 0.0:
			hero.huntsman_runtime.eyes_remaining = maxf(0.0, float(hero.huntsman_runtime.eyes_remaining) - delta)
			if float(hero.huntsman_runtime.eyes_remaining) <= 0.0: StealthDetectionSystem.set_stealth_source(hero, "huntsman_eyes:%s" % str(hero.combat_id), false)
		for index in range(hero.huntsman_runtime.projectiles.size() - 1, -1, -1):
			if not update_huntsman_projectile(hero, hero.huntsman_runtime.projectiles[index], delta): hero.huntsman_runtime.projectiles.remove_at(index)
