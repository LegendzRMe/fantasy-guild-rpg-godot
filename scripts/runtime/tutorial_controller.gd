extends "res://scripts/runtime/battle_setup.gd"

func start_tutorial()->void:
	state.selected_team=[0,1];state.active_team=[0,1];save_game();start_battle(0,0)
	tutorial_active=true;tutorial_step=0;tutorial_move_round=0;tutorial_timer=0;tutorial_hero_clicked=false;tutorial_ability_used=false
	tutorial_reject_time=0;tutorial_feedback_message="";tutorial_idle_time=0;tutorial_idle_hint_shown=false;tutorial_input_device="mobile" if OS.has_feature("mobile") else "pc"
	tutorial_targets=[Vector2(390,250)];tutorial_target_reached=[false]
	for h in heroes:CombatRulesV1.clear_assignment(h);h.target=-1;h.heal_target=-1
	queue_redraw()

func set_tutorial_movement_targets(round_index:int)->void:
	var layouts=[[Vector2(430,175),Vector2(430,400)],[Vector2(650,180),Vector2(570,430)],[Vector2(820,265),Vector2(700,470)]]
	tutorial_targets=layouts[clampi(round_index,0,layouts.size()-1)].duplicate();tutorial_target_reached=[false,false]

func tutorial_movement_target_reached(hero_position:Vector2,target_position:Vector2)->bool:
	return hero_position.distance_to(target_position)<=TUTORIAL_MOVEMENT_REACH_RADIUS

func tutorial_prompt()->String:
	var mobile=tutorial_input_device=="mobile"
	match tutorial_step:
		0:return "First, let's practice movement. Touch and drag either hero to the marker." if mobile else "First, let's practice movement. Drag either hero to the marked area."
		1:return "Touch and drag to reach both markers. One hero can visit both." if mobile else "Nice job. Reach both marked areas. One hero can visit both, or split up."
		2:return "Touch and drag Brann onto the training dummy." if mobile else "Now drag Brann to the training dummy. He will attack until it is destroyed."
		3:return "Oh no—Brann is hurt. Tap Brann to check his health." if mobile else "Oh no—Brann is hurt. Click Brann to check his health."
		4:return "Touch and drag Sera onto Brann to order her to heal him." if mobile else "Drag Sera onto Brann and release to order her to heal him."
		5:return "Sera will keep Brann as her healing target until you give different orders."
		6:return "Protect Sera! Touch and drag Brann onto the creature." if mobile else "Protect Sera! Drag Brann onto the creature and defeat it."
		7:return "Both heroes are hurt. Tap Sera, then tap Healing Brew." if mobile else "Both heroes are hurt. Select Sera, then press Q or click Healing Brew."
		8:return "Great work. Tap anywhere to continue." if mobile else "Great work. Click or press any key to continue."
	return ""

func tutorial_rejection_message()->String:
	var tap="Tap" if tutorial_input_device=="mobile" else "Click"
	match tutorial_step:
		0,1:return "Move either hero anywhere, then reach the highlighted marker to continue."
		2:return "Only Brann can be assigned to the Training Dummy."
		3:return "%s Brann to inspect his health."%tap
		4:return "Drag Sera directly onto Brann to set her healing target."
		5:return "Watch Sera finish healing Brann."
		6:return "Move Sera freely, or assign Brann to the Raider to continue."
		7:return "Select Sera first." if selected!=1 else "Use Healing Brew with Q or the highlighted button."
	return "Follow the highlighted action to continue."

func reject_tutorial_action(message:String="")->void:
	if not tutorial_active:return
	tutorial_reject_time=1.15
	tutorial_feedback_message=message if message!="" else tutorial_rejection_message()
	queue_redraw()

func tutorial_record_valid_action()->void:
	tutorial_idle_time=0
	tutorial_idle_hint_shown=false
	tutorial_reject_time=0
	tutorial_feedback_message=""

func spawn_tutorial_dummy()->void:
	spawn_enemy(Vector2(660,330),"Dummy");var tutorial_hp=heroes[0].damage*5.0;enemies[-1].hp=tutorial_hp;enemies[-1].max_hp=tutorial_hp;enemies[-1].damage=0.0;enemies[-1].rewarded=true

func spawn_tutorial_raider()->void:
	spawn_enemy(heroes[1].pos+Vector2(155,0),"Raider");var tutorial_hp=heroes[0].damage*8.0;enemies[-1].hp=tutorial_hp;enemies[-1].max_hp=tutorial_hp;enemies[-1].target=1;enemies[-1].rewarded=true;enemies[-1]["tutorial_opening_target"]=1

func tutorial_has_living_enemy(enemy_type:String)->bool:
	for enemy in enemies:
		if enemy.type==enemy_type and enemy.hp>0:return true
	return false

func tutorial_has_enemy(enemy_type:String)->bool:
	for enemy in enemies:
		if enemy.type==enemy_type:return true
	return false

func enter_tutorial_step(next_step:int)->void:
	tutorial_step=next_step;tutorial_timer=0;tutorial_idle_time=0;tutorial_idle_hint_shown=false;tutorial_reject_time=0;tutorial_feedback_message="";dragging_hero=false
	match tutorial_step:
		1:
			tutorial_move_round=0;set_tutorial_movement_targets(0)
		2:
			tutorial_targets=[];spawn_tutorial_dummy()
		3:
			tutorial_hero_clicked=false;heroes[0].hp=max(1,heroes[0].hp-90);CombatRulesV1.clear_assignment(heroes[0]);heroes[0].target=-1
		6:
			spawn_tutorial_raider()
		7:
			heroes[0].hp=max(1,heroes[0].hp-55);heroes[1].hp=max(1,heroes[1].hp-45);CombatRulesV1.clear_assignment(heroes[0]);CombatRulesV1.clear_assignment(heroes[1]);heroes[0].target=-1;heroes[0].dest=heroes[0].pos;heroes[1].target=-1;heroes[1].heal_target=0;heroes[1].dest=heroes[1].pos
		8:
			state.tutorial_complete=true;state.zone0.heroes_unlocked=true;save_game()
	queue_redraw()

func recover_tutorial_state()->void:

	if heroes.size()<2:
		start_tutorial();reject_tutorial_action("Training restarted so both heroes are available.");return
	var recovered=false
	for hero in heroes:
		if hero.hp<=0:
			hero.incapacitated=false;hero.hp=max(1.0,hero.max_hp*.6);hero.dest=hero.pos;CombatRulesV1.clear_assignment(hero);hero.target=-1;recovered=true
	if tutorial_step==6 and heroes[1].hp<heroes[1].max_hp*.22:
		heroes[1].hp=heroes[1].max_hp*.55;recovered=true
	if tutorial_step==2 and not tutorial_has_enemy("Dummy"):
		spawn_tutorial_dummy();recovered=true
	if tutorial_step==6 and not tutorial_has_enemy("Raider"):
		spawn_tutorial_raider();recovered=true
	if recovered:
		for enemy in enemies:enemy.telegraph=0.0;enemy.cooldown=max(enemy.cooldown,.8)
		reject_tutorial_action("Training restored the current step so you can continue.")

func update_tutorial(delta:float)->void:
	tutorial_reject_time=max(0.0,tutorial_reject_time-delta)
	tutorial_timer+=delta;tutorial_idle_time+=delta
	if tutorial_step==0:
		for h in heroes:
			if tutorial_movement_target_reached(h.pos,tutorial_targets[0]):enter_tutorial_step(1);break
	elif tutorial_step==1:
		for target_index in tutorial_targets.size():
			for h in heroes:
				if tutorial_movement_target_reached(h.pos,tutorial_targets[target_index]):tutorial_target_reached[target_index]=true
		if tutorial_target_reached.all(func(reached):return reached):
			tutorial_move_round+=1
			if tutorial_move_round<3:set_tutorial_movement_targets(tutorial_move_round);tutorial_idle_time=0
			else:enter_tutorial_step(2)
	elif tutorial_step==2 and tutorial_has_enemy("Dummy") and not tutorial_has_living_enemy("Dummy"):enter_tutorial_step(3)
	elif tutorial_step==3 and tutorial_hero_clicked and selected==0:enter_tutorial_step(4)
	elif tutorial_step==4 and heroes.size()>1 and heroes[1].heal_target==0 and heroes[0].hp>=heroes[0].max_hp:enter_tutorial_step(5)
	elif tutorial_step==5 and tutorial_timer>=2.8:enter_tutorial_step(6)
	elif tutorial_step==6 and tutorial_has_enemy("Raider") and not tutorial_has_living_enemy("Raider"):enter_tutorial_step(7)
	elif tutorial_step==7 and tutorial_ability_used:enter_tutorial_step(8)
	var awaiting_input=tutorial_step in [0,1,3,4,7] or tutorial_step==2 and (heroes.is_empty() or heroes[0].target<0) or tutorial_step==6 and (heroes.is_empty() or heroes[0].target<0)
	if awaiting_input and tutorial_idle_time>=10 and not tutorial_idle_hint_shown:
		tutorial_idle_hint_shown=true;reject_tutorial_action()
	queue_redraw()
