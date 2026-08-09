extends "res://scripts/runtime/shared_combat_runtime.gd"

func templar_redirect_threat(source:Dictionary,target:Dictionary,resolved_damage:float)->void:
	if resolved_damage<=0.0:return
	for link in source.get("templar_shield_links",[]):
		if float(link.get("remaining",0.0))<=0.0:continue
		var owner=unit_by_combat_id(str(link.get("owner_id","")));if owner==null or owner.hp<=0.0:continue
		var duplicated_threat:=resolved_damage*CombatSystem.DAMAGE_THREAT_RATIO*float(source.get("threat_modifier",1.0));add_enemy_threat(target,int(owner.battle_index),duplicated_threat);TemplarSystem.telemetry_add(owner,"linked_damage",resolved_damage);TemplarSystem.telemetry_add(owner,"linked_threat",duplicated_threat)
		if TemplarSystem.has_talent(owner,"templar_l18_2"):
			owner.templar_runtime.together_bucket=float(owner.templar_runtime.together_bucket)+resolved_damage;var threshold:=maxf(1.0,float(link.get("snapshot_hp",owner.max_hp))*float(TemplarData.VALUES.together_threshold))
			while float(owner.templar_runtime.together_bucket)>=threshold:owner.templar_runtime.together_bucket=float(owner.templar_runtime.together_bucket)-threshold;TemplarSystem.reduce_trait_cooldown(owner,1.0)

func templar_after_damage(source:Dictionary,target:Dictionary,result:Dictionary,source_action:String,originating_effect_id:String)->void:
	var hostile:=str(source.get("combat_affiliation",source.get("combat_team","")))!=str(target.get("combat_affiliation",target.get("combat_team","")))
	if hostile and str(target.get("class",""))=="Templar" and not target.get("templar_runtime",{}).is_empty():
		var request:=TemplarSystem.try_activate_trait_after_damage(target,float(result.get("resolved_damage",0.0)));if not request.is_empty():apply_unit_shield(target,target,float(request.amount),"Shield Overload",str(request.source_id),INF,float(request.duration));TemplarSystem.telemetry_add(target,"trait_shield",float(request.amount));if TemplarSystem.has_talent(target,"templar_l21_1"):target.ability_cds[0]=maxf(0.0,float(target.ability_cds[0])-float(TemplarData.VALUES.zeal_q_reduction))
	if str(source.get("class",""))=="Templar" and source_action=="basic_attack" and originating_effect_id=="" and float(result.get("resolved_damage",0.0))>0.0:TemplarSystem.note_successful_basic_attack(source,target,false);if TemplarSystem.has_talent(source,"templar_l24_3"):CombatSystem.apply_control(target,"slow",float(TemplarData.VALUES.blades_slow_duration),float(TemplarData.VALUES.blades_slow))
	for absorption in result.get("shield_absorptions",[]):
		var shield_origin=absorption.get("origin",null);if not hostile or not shield_origin is Dictionary or str(shield_origin.get("name",""))!="templar_shield_ally":continue
		var owner=unit_by_combat_id(str(shield_origin.get("owner_id","")));if owner!=null and TemplarSystem.named_shield_amount(target,str(absorption.get("source_id","")))<=0.0:TemplarSystem.note_e_depletion(owner)

func resolve_shaman_frostwolf_from_basic(hero:Dictionary,stacks:int)->void:
	for activation in ShamanSystem.add_frostwolf_stacks(hero,stacks,float(hero.hp)):
		var healing:=deal_healing(hero,hero,float(activation.raw_healing),"basic_heal","Frostwolf Resilience","shaman_trait");ShamanSystem.telemetry_add(hero,"frostwolf_healing",float(healing.effective_amount));ShamanSystem.telemetry_add(hero,"frostwolf_overhealing",float(healing.overhealing))
		var request:=ShamanSystem.overflow_shield_request(hero,activation,healing)
		if not request.is_empty():
			var existing:=0.0;for shield_source in hero.get("shield_sources",[]):if str(shield_source.get("source_id",""))==str(request.source_id):existing+=float(shield_source.get("amount",0.0))
			var room:=maxf(0.0,float(request.cap)-existing);var applied:=apply_unit_shield(hero,hero,minf(room,float(request.amount)),"Overflowing Resilience",str(request.source_id),float(request.cap),float(request.duration));ShamanSystem.telemetry_add(hero,"overflow_shield",float(applied.get("amount",0.0)))

func item_feedback(text_value:String,position:Vector2,color:Color=C_GOLD)->void:
	if not is_testing_save():return
	item_feedback_feed.append(text_value)
	if item_feedback_feed.size()>5:item_feedback_feed.pop_front()
	add_effect("cast",position,position,text_value,color)

func current_damage_taken_multiplier(unit:Dictionary)->float:
	var multiplier:float=float(unit.get("damage_taken_multiplier",1.0))
	for effect in unit.get("active_effects",[]):
		if effect.has("damage_taken_multiplier") and float(effect.get("remaining_duration",0.0))>0.0:multiplier*=float(effect.damage_taken_multiplier)
	return multiplier

func refresh_item_combat_stats(hero:Dictionary)->void:
	var soul_multiplier:float=1.0+float(hero.get("soul_furnace_stacks",0))*0.05
	var last_dawn_active:bool=false
	for shield_source in hero.get("shield_sources",[]):
		if str(shield_source.get("source_id",""))=="last_dawn" and float(shield_source.get("amount",0.0))>0:last_dawn_active=true;break
	hero.power=float(hero.get("base_power",hero.get("power",0.0)))*soul_multiplier*(1.5 if last_dawn_active else 1.0)
	hero.basic_action_amount=hero.power*float(hero.get("basic_action_power_ratio",1.0));hero.damage=hero.basic_action_amount
	if str(hero.get("basic_action_type","attack"))=="heal":hero.basic_heal_amount=hero.basic_action_amount
	var interval:float=float(hero.get("base_basic_action_interval",1.25))/maxf(0.1,1.0+float(hero.get("soul_furnace_stacks",0))*0.05)
	hero.basic_attack_interval=interval;hero.basic_heal_interval=interval

func apply_passive_trigger(owner:Dictionary,event:Dictionary,target:Dictionary)->void:
	for proc in CombatSystem.evaluate_passives(owner,event,owner.get("equipped_items",[]),ItemData.PASSIVE_EFFECTS,battle_time):
		var passive:Dictionary=proc.passive;var result:Dictionary=passive.effect_result;var passive_id:String=str(passive.id)
		match passive_id:
			"grace":
				var bonus:=CombatSystem.resolve_healing(owner,target,{"amount":float(result.get("amount",0.0)),"source_action":"basic_ability","can_crit":false})
				combat_events.append(CombatSystem.create_event("healing_done",owner,target,bonus,{"action_tags":["basic_ability"],"originating_effect_id":passive_id,"origin":proc.item_instance_id}))
				if bonus.effective_amount>0:add_effect("heal",owner.pos,target.pos,"+%d"%int(bonus.effective_amount),C_GREEN)
			"bloodletting":
				var stack:={"remaining_duration":4.0,"tick_timer":1.0,"amount":7.5,"source_unit":owner,"source_index":int(owner.get("battle_index",-1))}
				if not target.has("bloodletting_stacks"):target["bloodletting_stacks"]=[]
				if target.bloodletting_stacks.size()>=5:
					for stack_index in target.bloodletting_stacks.size():target.bloodletting_stacks[stack_index].remaining_duration=4.0
				else:target.bloodletting_stacks.append(stack)
				item_feedback("Bloodletting %d/5"%target.bloodletting_stacks.size(),target.pos,Color("d96a72"))
			"thunder_wake":
				for foe in enemies:
					if foe==target or foe.hp<=0 or foe.pos.distance_to(target.pos)>float(result.get("radius",145.0)):continue
					deal_damage(owner,foe,float(event.get("amount",0.0)),"basic_ability","magical","Thunder Wake",false,passive_id,[passive_id])
					foe.active_effects=CombatSystem.apply_named_effect(foe.get("active_effects",[]),{"id":"vulnerable","damage_taken_multiplier":1.15,"remaining_duration":4.0})
				item_feedback("Thunder Wake",target.pos,Color("70b9ff"))
			"last_dawn":
				var shield_amount:float=float(owner.max_hp)*0.75
				apply_unit_shield(owner,owner,shield_amount,"Last Dawn","last_dawn")
				refresh_item_combat_stats(owner);item_feedback("Last Dawn",owner.pos,C_GOLD)
			"overflowing_grace":
				var shield_amount:float=float(event.get("overhealing",0.0))*(2.0 if bool(event.get("critical",false)) and "direct" in event.get("action_tags",[]) else 1.0)
				var shield_cap:float=float(target.max_hp)*0.60
				var applied:=apply_unit_shield(owner,target,shield_amount,"Overflowing Grace","overflowing_grace",shield_cap)
				if float(applied.get("amount",0.0))>0:item_feedback("Overflowing Grace +%d"%int(applied.amount),target.pos,C_GREEN)
			"thousand_cuts":
				owner.thousand_cuts_count=int(owner.get("thousand_cuts_count",0))+1
				if owner.thousand_cuts_count>=3:
					owner.thousand_cuts_count=0;item_feedback("Thousand Cuts",target.pos,Color("e6b35f"))
					for extra_strike in 2:deal_damage(owner,target,float(owner.get("basic_action_amount",owner.get("damage",0.0)))*0.60,"basic_attack",str(event.get("damage_or_healing_type","physical")),"Thousand Cuts",false,passive_id,[passive_id])
			"retribution":
				owner.retribution_charges=CombatSystem.store_charge(owner.get("retribution_charges",[]),float(event.get("amount",0.0))*0.50,3)
				item_feedback("Retribution %d/3"%owner.retribution_charges.size(),owner.pos,Color("ef9e56"))

			"endless_momentum":
				owner.ability_cds=CombatSystem.reduce_cooldowns(owner.ability_cds,1.0,0.25)
				if hero_has_passive(owner,"twin_incantation"):
					for charge_index in owner.get("q_charge_timers",[]).size():owner.q_charge_timers[charge_index]=maxf(0.0,float(owner.q_charge_timers[charge_index])-1.0)
					owner.ability_cds[0]=0.0 if int(owner.get("q_charges",0))>0 else (float(owner.q_charge_timers[0]) if not owner.q_charge_timers.is_empty() else 0.0)
				item_feedback("Endless Momentum",owner.pos,Color("b381ff"))
			"soul_furnace":
				var defeated:Dictionary=event.target_unit;var gained:=1 if bool(defeated.get("summoned_unit",false)) else 5 if "boss" in defeated.get("combat_tags",[]) else 3 if "elite" in defeated.get("combat_tags",[]) or "heavy" in defeated.get("combat_tags",[]) else 1
				owner.soul_furnace_stacks=int(owner.get("soul_furnace_stacks",0))+gained;refresh_item_combat_stats(owner);item_feedback("Soul Furnace +%d"%gained,owner.pos,Color("d16ca8"))
			_:
				if str(result.get("category",""))=="buff":
					var named_effect:=result.duplicate(true);named_effect["remaining_duration"]=float(passive.get("duration",0.0));owner.active_effects=CombatSystem.apply_named_effect(owner.get("active_effects",[]),named_effect)

func build_damage_request(target:Dictionary,resolved_amount:float,source_action:String,damage_type:String,can_crit_override)->Dictionary:
	var request:={"amount":resolved_amount,"source_action":source_action,"damage_type":damage_type,"damage_taken_multiplier":current_damage_taken_multiplier(target)}
	if not target.get("armor_reduction_sources",[]).is_empty():request["base_armor_override"]=ArmorReductionSystem.effective_armor(target)
	if str(target.get("class",""))=="Guardian" and not target.get("guardian_runtime",{}).is_empty():
		var armor_sources:Array=target.guardian_runtime.temporary_armor_sources.duplicate(true)
		var guardian_block:=BlockChargeSystem.armor_source_legacy(target.guardian_runtime,int(GuardianData.VALUES.block_charges),float(GuardianData.VALUES.block_armor),"dwarf_block","block_charges","block_state",true)
		if damage_type=="physical" and source_action=="basic_attack" and not guardian_block.is_empty():armor_sources.append(guardian_block)
		request["armor_sources"]=armor_sources
	elif str(target.get("class",""))=="Cleric" and not target.get("cleric_runtime",{}).is_empty():
		var cleric_armor:=ClericSystem.active_armor(target)
		if cleric_armor>0.0:request["armor_sources"]=[{"id":"safety_sprint","armor":cleric_armor,"remaining":1.0}]
	elif str(target.get("class",""))=="Ranger" and not target.get("ranger_runtime",{}).is_empty():
		var ranger_armor:=RangerSystem.trait_armor(target)
		if ranger_armor>0.0:request["armor_sources"]=[{"id":"gloom","armor":ranger_armor,"remaining":1.0}]
	elif str(target.get("class",""))=="Warlock" and not target.get("warlock_runtime",{}).is_empty():
		var warlock_armor:=WarlockSystem.fel_armor(target)
		if warlock_armor>0.0:request["armor_sources"]=[{"id":"fel_armor","armor":warlock_armor,"remaining":float(target.warlock_runtime.fel_armor_remaining)}]
	elif str(target.get("class",""))=="Rogue" and not target.get("rogue_runtime",{}).is_empty():
		var armor_sources:Array=target.rogue_runtime.temporary_armor_sources.duplicate(true)
		var rogue_block:=BlockChargeSystem.armor_source_legacy(target.rogue_runtime,3,float(RogueData.VALUES.combat_readiness_armor),"combat_readiness","block_charges","block_state",true)
		if damage_type=="physical" and source_action=="basic_attack" and not rogue_block.is_empty():armor_sources.append(rogue_block)
		if not armor_sources.is_empty():request["armor_sources"]=armor_sources
	elif str(target.get("class",""))=="Slayer" and not target.get("slayer_runtime",{}).is_empty():
		var armor_sources:Array=target.slayer_runtime.temporary_armor_sources.duplicate(true);var block_source:=BlockChargeSystem.armor_source(target,SlayerSystem.scaled(target,float(SlayerData.VALUES.block_armor)),"reflexive_block","slayer_block")
		if not block_source.is_empty():armor_sources.append(block_source)
		if not armor_sources.is_empty():request["armor_sources"]=armor_sources
	elif str(target.get("class",""))=="Shaman" and not target.get("shaman_runtime",{}).is_empty():
		var shaman_block:=BlockChargeSystem.armor_source(target,float(ShamanData.VALUES.feral_resilience_block_armor),"feral_resilience","shaman_block")
		if not shaman_block.is_empty():request["armor_sources"]=[shaman_block]
	elif str(target.get("class",""))=="Templar" and not target.get("templar_runtime",{}).is_empty():
		var templar_sources:Array=[]
		var templar_block:=BlockChargeSystem.armor_source(target,float(TemplarData.VALUES.reactive_parry_armor),"reactive_parry","templar_block")
		if source_action=="basic_attack" and not templar_block.is_empty():templar_sources.append(templar_block)
		if TemplarSystem.has_talent(target,"templar_l21_3") and (bool(target.templar_runtime.trait_active) or float(target.templar_runtime.trait_after_armor)>0.0):templar_sources.append({"id":"phase_bulwark","armor":float(TemplarData.VALUES.phase_bulwark_armor),"remaining":1.0})
		if not templar_sources.is_empty():request["armor_sources"]=templar_sources
	elif str(target.get("class",""))=="Protector" and not target.get("protector_runtime",{}).is_empty():
		var protector_sources:=ProtectorSystem.armor_sources(target)
		if not protector_sources.is_empty():request["armor_sources"]=protector_sources
	var shared_armor:Array=target.get("temporary_armor_sources",[]).duplicate(true)
	if not shared_armor.is_empty():
		var combined:Array=request.get("armor_sources",[]).duplicate(true);combined.append_array(shared_armor);request["armor_sources"]=combined
	if source_action=="percentage_health":request["outgoing_multiplier"]=1.0;request["can_crit"]=false
	if can_crit_override!=null:request["can_crit"]=bool(can_crit_override)
	return request

func finalize_damage_events(source:Dictionary,target:Dictionary,result:Dictionary,source_action:String,damage_type:String,origin,source_is_summon:bool,originating_effect_id:String,trigger_chain:Array,before_ratio:float,retribution_bonus:float)->void:
	var crossed_below_half:bool=before_ratio>0.50 and float(target.get("hp",0.0))/maxf(1.0,float(target.get("max_hp",1.0)))<0.50
	var context:={"source_action":source_action,"damage_type":damage_type,"action_tags":[source_action],"origin":origin,"source_is_summon":source_is_summon,"originating_effect_id":originating_effect_id,"trigger_chain":trigger_chain,"crossed_below_half":crossed_below_half}
	var events:=CombatSystem.event_bundle_for_damage(source,target,result,context);combat_events.append_array(events)
	for event in events:
		if event.event_type=="damage_taken":apply_passive_trigger(target,event,target)
		elif event.event_type in ["basic_attack_hit","direct_damage_dealt","periodic_damage_dealt","critical_result"]:apply_passive_trigger(source,event,target)
	var enemy_index:int=enemies.find(target);var source_index:int=int(source.get("battle_index",-1))
	if enemy_index>=0 and source_index>=0:add_damage_threat(target,source_index,float(result.get("resolved_damage",0.0)))
	if enemy_index>=0:templar_redirect_threat(source,target,float(result.get("resolved_damage",0.0)))
	var living_enemy_count:int=enemies.filter(func(enemy):return enemy.hp>0 and not bool(enemy.get("ignores_tank_aggro",false))).size()
	for absorption in result.get("shield_absorptions",[]):
		var creator_index:int=int(absorption.get("creator_index",-1))
		if creator_index>=0:
			var per_enemy:=CombatSystem.distributed_threat(CombatSystem.shield_absorption_threat(float(absorption.amount),float(heroes[creator_index].get("threat_modifier",1.0))),living_enemy_count)
			for enemy in enemies:if enemy.hp>0:add_enemy_threat(enemy,creator_index,per_enemy)
	if retribution_bonus>0.0 and target.hp>0:deal_damage(source,target,retribution_bonus,"summon","true","Retribution",false,"retribution",["retribution"]);item_feedback("Retribution %d"%int(retribution_bonus),target.pos,Color("ef9e56"))
	if bool(result.get("defeated",false)) and not bool(target.get("item_defeat_processed",false)):
		target["item_defeat_processed"]=true
		var defeat_event:=CombatSystem.create_event("unit_defeated",source,target,result,context)
		for hero in heroes:
			if hero.hp>0:apply_passive_trigger(hero,defeat_event,target)
			if str(hero.get("class",""))=="Guardian" and not hero.get("guardian_runtime",{}).is_empty():GuardianSystem.process_marked_death(hero,str(target.get("combat_id","")),battle_time);GuardianSystem.process_haymaker_death(hero,str(target.get("combat_id","")),battle_time)
			if str(hero.get("class",""))=="Slayer" and not hero.get("slayer_runtime",{}).is_empty():SlayerSystem.process_defeat(hero,target)
			if str(hero.get("class",""))=="Shaman" and not hero.get("shaman_runtime",{}).is_empty() and not bool(target.get("summoned_unit",false)) and not bool(target.get("object",false)):ShamanSystem.note_echo_defeat(hero,str(target.get("combat_id","")))

func deal_damage(source:Dictionary,target:Dictionary,amount:float,source_action:String,damage_type:String,origin=null,source_is_summon:bool=false,originating_effect_id:String="",trigger_chain:Array=[],can_crit_override=null)->Dictionary:
	if CombatSystem.is_protected(target):
		for prevention_effect in target.get("active_effects",[]):
			if str(prevention_effect.get("id","")) not in ["protected","invulnerable"]:continue
			var prevention_owner=unit_by_combat_id(str(prevention_effect.get("owner_id","")))
			if prevention_owner!=null and str(prevention_owner.get("class",""))=="Priest":PriestSystem.telemetry_add(prevention_owner,"salvation_prevented",maxf(0.0,amount))
		return {"raw_amount":maxf(0.0,amount),"resolved_damage":0.0,"health_damage":0.0,"shield_damage":0.0,"armor_prevented":0.0,"protected_prevented":maxf(0.0,amount),"defeated":false,"critical":false,"immune":true,"evaded":false,"overkill":0.0,"shield_absorptions":[]}
	var hostile:bool=str(source.get("combat_affiliation",source.get("combat_team","")))!=str(target.get("combat_affiliation",target.get("combat_team","")))
	if EvasionSystem.should_evade(target,source_action,hostile,bool(source.get("bypass_evasion",false))):
		var miss:=EvasionSystem.miss_result(source_action,damage_type);combat_events.append(CombatSystem.create_event("basic_attack_evaded",source,target,miss,{"source_action":source_action,"action_tags":[source_action],"origin":origin}));if str(target.get("class",""))=="Slayer":SlayerSystem.telemetry_add(target,"evaded_attacks");return miss
	var active_damage_multiplier:=1.0
	for active_effect in source.get("active_effects",[]):
		if float(active_effect.get("remaining_duration",0.0))>0.0:active_damage_multiplier=maxf(active_damage_multiplier,float(active_effect.get("damage_multiplier",1.0)))
	var resolved_amount:=amount*ProtectorSystem.outgoing_damage_multiplier(source)*active_damage_multiplier;var retribution_bonus:float=0.0;var shaman_basic_origin:=""
	if source_action=="basic_attack":
		for effect in source.get("active_effects",[]):resolved_amount*=float(effect.get("basic_attack_damage_multiplier",1.0))
	if str(source.get("class",""))=="Templar" and source_action=="basic_attack" and not source.get("templar_runtime",{}).is_empty():
		resolved_amount*=TemplarSystem.basic_attack_multiplier(source)
		if originating_effect_id=="":
			resolved_amount+=TemplarSystem.titan_bonus(source,false)
			if float(source.templar_runtime.final_cut_remaining)>0.0:resolved_amount+=amount*(float(TemplarData.VALUES.final_cut_low_bonus) if float(source.hp)/maxf(1.0,float(source.max_hp))<.25 else float(TemplarData.VALUES.final_cut_bonus));source.templar_runtime.final_cut_remaining=0.0
	if str(source.get("class",""))=="Shaman" and not source.get("shaman_runtime",{}).is_empty():
		resolved_amount*=ShamanSystem.alpha_multiplier(source,str(target.get("combat_id","")))
		if source_action=="basic_attack" and originating_effect_id=="":
			var remaining:=int(source.shaman_runtime.windfury_attacks);shaman_basic_origin="windfury_attack_%d"%(int(ShamanData.VALUES.e_attacks)-remaining+1) if remaining>0 else "normal_basic_attack"
			if ShamanSystem.reward_active(source,"maelstrom_1"):resolved_amount+=ShamanSystem.ability_amount(source,float(ShamanData.VALUES.maelstrom_damage_1))
			if ShamanSystem.reward_active(source,"maelstrom_2"):resolved_amount+=ShamanSystem.ability_amount(source,float(ShamanData.VALUES.maelstrom_damage_2))
	var slayer_primary:bool=str(source.get("class",""))=="Slayer" and source_action=="basic_attack" and originating_effect_id=="" and not source.get("slayer_runtime",{}).is_empty()
	if slayer_primary:
		resolved_amount=(amount+SlayerSystem.unending_hatred_bonus(source))*(1.0+SlayerSystem.basic_attack_bonus(source))
		if SlayerSystem.prepare_basic_attack(source,target):
			var percent_request:=PercentageHealthDamageSystem.request(source,target,float(SlayerData.VALUES.fiery_brand_fraction),float(SlayerData.VALUES.fiery_brand_boss_fraction),"Fiery Brand");deal_damage(source,target,float(percent_request.amount),"percentage_health","physical","Fiery Brand",false,"slayer_fiery_brand",[],false)
	if str(source.get("class",""))=="Rogue" and source_action=="basic_attack" and originating_effect_id=="" and RogueSystem.has_talent(source,"rogue_l12_2") and source.get("rogue_runtime",{}).get("garrotes",[]).any(func(instance):return str(instance.get("target_id",""))==str(target.get("combat_id","")) and float(instance.get("remaining_duration",0.0))>0.0):resolved_amount*=1.40
	if MageSystem.gravity_crush_applies(source,target,source_action,originating_effect_id,origin):resolved_amount*=1.0+float(MageData.VALUES.gravity_crush)
	var ranger_basic_result:={}
	if str(source.get("class",""))=="Ranger" and source_action=="basic_attack" and originating_effect_id=="" and not source.get("ranger_runtime",{}).is_empty():
		ranger_basic_result=RangerSystem.on_basic_attack_released(source,target);resolved_amount*=float(ranger_basic_result.multiplier)
	if str(source.get("class",""))=="Cleric" and source_action=="basic_attack" and ClericSystem.has_talent(source,"cleric_l21_2") and CombatSystem.is_blinded(target):resolved_amount*=2.0
	var guardian_basic_result:={}
	if str(source.get("class",""))=="Guardian" and source_action=="basic_attack" and not source.get("guardian_runtime",{}).is_empty():
		guardian_basic_result=GuardianSystem.on_basic_attack(source,target,battle_time);resolved_amount*=float(guardian_basic_result.damage_multiplier);resolved_amount+=amount*float(guardian_basic_result.bonus_damage_multiplier)
	if source_action=="basic_attack":
		for effect_index in range(source.get("active_effects",[]).size()-1,-1,-1):
			var active_effect:Dictionary=source.active_effects[effect_index]
			if str(active_effect.get("consume_on",""))=="basic_attack":resolved_amount+=float(active_effect.get("amount",0.0));source.active_effects.remove_at(effect_index)
		if originating_effect_id!="retribution" and not source.get("retribution_charges",[]).is_empty():
			retribution_bonus=float(source.retribution_charges.pop_front().amount)
	var before_ratio:float=float(target.get("hp",0.0))/maxf(1.0,float(target.get("max_hp",1.0)))
	var damage_request:=build_damage_request(target,resolved_amount,source_action,damage_type,can_crit_override)
	var previews_mage_barrier:bool=str(target.get("class",""))=="Mage" and not target.get("mage_runtime",{}).is_empty() and str(source.get("combat_team",""))!=str(target.get("combat_team",""))
	var resolution_roll:=-1.0
	if previews_mage_barrier:
		resolution_roll=randf()
		var preview_target:Dictionary=target.duplicate(true);var preview:=CombatSystem.resolve_damage(source,preview_target,damage_request,resolution_roll);var barrier:=MageSystem.try_arcane_barrier(target,bool(preview.get("defeated",false)))
		if bool(barrier.triggered):apply_unit_shield(target,target,float(barrier.shield),"Arcane Barrier","mage_arcane_barrier",INF,float(barrier.duration));item_feedback("Arcane Barrier",target.pos,CLASSES.Mage.color)
	var result:=CombatSystem.resolve_damage(source,target,damage_request,resolution_roll) if previews_mage_barrier else CombatSystem.resolve_damage(source,target,damage_request)
	if str(source.get("class",""))=="Sentinel" and source_action in ["basic_ability","heroic"] and originating_effect_id!="sentinel_e_auto" and float(result.get("resolved_damage",0.0))>0.0 and TargetCategorySystem.qualifies_immediate(target):SentinelSystem.reduce_q(source,float(SentinelData.VALUES.q_ability_cdr))
	if str(source.get("class",""))=="Rogue" and source_action=="basic_attack" and not source.get("rogue_runtime",{}).is_empty() and bool(source.rogue_runtime.vanish_active):RogueSystem.break_vanish(source)
	if str(target.get("class",""))=="Rogue" and not target.get("rogue_runtime",{}).is_empty() and float(result.get("resolved_damage",0.0))>0.0 and bool(target.rogue_runtime.vanish_active) and not StealthDetectionSystem.is_unrevealable(target):RogueSystem.break_vanish(target)
	if str(target.get("class",""))=="Rogue" and not target.get("rogue_runtime",{}).is_empty() and damage_type=="physical":BlockChargeSystem.consume_legacy(target.rogue_runtime,3,source_action,float(result.get("resolved_damage",0.0)),bool(result.get("evaded",false)))
	if str(target.get("class",""))=="Slayer" and not target.get("slayer_runtime",{}).is_empty() and BlockChargeSystem.consume(target,source_action,float(result.get("resolved_damage",0.0)),bool(result.get("evaded",false)),"slayer_block"):SlayerSystem.telemetry_add(target,"block_consumed")
	if str(target.get("class",""))=="Shaman" and not target.get("shaman_runtime",{}).is_empty():BlockChargeSystem.consume(target,source_action,float(result.get("resolved_damage",0.0)),bool(result.get("evaded",false)),"shaman_block")
	if str(target.get("class",""))=="Templar" and not target.get("templar_runtime",{}).is_empty():BlockChargeSystem.consume(target,source_action,float(result.get("resolved_damage",0.0)),bool(result.get("evaded",false)),"templar_block")
	if str(source.get("class",""))=="Protector" and source_action=="basic_attack" and originating_effect_id=="" and not source.get("protector_runtime",{}).is_empty():
		ProtectorSystem.note_basic_attack(source,target,combat_blockers,Vector2(source.pos),Vector2(target.pos),float(result.get("resolved_damage",0.0)))
		ProtectorSystem.telemetry_add(source,"basic_attack_damage",float(result.get("resolved_damage",0.0)))
		ProtectorSystem.telemetry_add(source,"basic_attack_threat",CombatSystem.damage_threat(result,float(source.get("threat_modifier",1.0))))
		if ProtectorSystem.has_talent(source,"protector_l18_2") and ProtectorSystem.crosses_own_wall(source,source.pos,target.pos,combat_blockers) and float(result.get("resolved_damage",0.0))>0.0:CombatSystem.apply_control(target,"slow",float(ProtectorData.VALUES.w_crossing_duration),float(ProtectorData.VALUES.w_crossing_slow))
	if str(source.get("class",""))=="Sentinel" and source_action=="basic_attack" and originating_effect_id=="" and not source.get("sentinel_runtime",{}).is_empty():
		var sentinel_basic:=SentinelSystem.note_basic_attack(source,target,float(result.get("resolved_damage",0.0)))
		if float(sentinel_basic.get("self_heal_fraction",0.0))>0.0:
			var self_result:=deal_healing(source,source,float(source.max_hp)*float(sentinel_basic.self_heal_fraction),"trait","Hunter's Mark","sentinel_mark");SentinelSystem.telemetry_add(source,"d_self_healing",float(self_result.effective_amount))
		if bool(sentinel_basic.get("own_mark",false)) and SentinelSystem.has_talent(source,"sentinel_l12_2"):
			for ally in heroes:if ally.hp>0.0 and ally.pos.distance_to(target.pos)<=float(SentinelData.SPACE.mark_mending_radius):deal_healing(source,ally,float(ally.max_hp)*.04,"trait","Mark of Mending","sentinel_mark_mending")
		if bool(sentinel_basic.get("own_mark",false)) and SentinelSystem.has_talent(source,"sentinel_l18_3"):
			for splash_target in enemies:if splash_target!=target and splash_target.hp>0.0 and splash_target.pos.distance_to(target.pos)<=90.0:deal_damage(source,splash_target,float(result.get("resolved_damage",0.0)),"splash","physical","Huntress' Fury",false,"sentinel_huntress_splash",[],false)
		if bool(sentinel_basic.get("auto_flare",false)):source.sentinel_runtime.pending_flares.append({"center":Vector2(target.pos),"remaining":float(SentinelData.VALUES.e_delay),"automatic":true})
		if SentinelSystem.has_talent(source,"sentinel_l24_3"):
			var ice_id:="sentinel_iceblade:%s"%str(source.combat_id);var ice_amount:=.02
			for ice_effect in target.get("active_effects",[]):if str(ice_effect.get("source_id",""))==ice_id:ice_amount=minf(.10,float(ice_effect.get("amount",0.0))+.02)
			OutgoingDamageReductionSystem.apply(target,ice_id,ice_amount,2.0)
		if not source.sentinel_runtime.elune_chosen.is_empty() and float(source.sentinel_runtime.elune_chosen.get("remaining",0.0))>0.0:
			var chosen=SentinelSystem.select_lowest(heroes,source.pos,float(SentinelData.SPACE.q_range));if chosen!=null:deal_healing(source,chosen,float(result.get("resolved_damage",0.0))*1.75,"trait","Elune's Chosen","sentinel_elune_chosen")
	templar_after_damage(source,target,result,source_action,originating_effect_id)
	if str(target.get("class",""))=="Protector" and not target.get("protector_runtime",{}).is_empty():
		ProtectorSystem.telemetry_add(target,"damage_taken",float(result.get("resolved_damage",0.0)))
		if bool(result.get("defeated",false)):ProtectorSystem.telemetry_add(target,"deaths")
	if bool(result.get("defeated",false)):
		for sentinel in heroes:
			if str(sentinel.get("class",""))!="Sentinel" or sentinel.get("sentinel_runtime",{}).is_empty():continue
			SentinelSystem.note_defeat(sentinel,target);var reveal:Dictionary=sentinel.sentinel_runtime.w_reveals.get(str(target.combat_id),{})
			if not reveal.is_empty() and not bool(reveal.get("reset_used",false)):sentinel.sentinel_runtime.w_slot.current_charges=mini(int(sentinel.sentinel_runtime.w_slot.max_charges),int(sentinel.sentinel_runtime.w_slot.current_charges)+1);reveal.reset_used=true;SentinelSystem.telemetry_add(sentinel,"w_death_resets")
	if str(source.get("class",""))=="Rogue" and source_action=="basic_attack" and originating_effect_id=="" and not source.get("rogue_runtime",{}).is_empty():
		if ComboPointSystem.successful_hit(result):
			RogueSystem.double_strike_roll(source)
			if RogueSystem.has_talent(source,"rogue_l30_1"):
				for garrote in source.rogue_runtime.garrotes:
					if str(garrote.target_id)==str(target.get("combat_id","")):garrote.remaining_duration=float(RogueData.VALUES.garrote_duration)
		RogueSystem.consume_slice_attack(source)
	if str(target.get("class",""))=="Warlock" and not target.get("warlock_runtime",{}).is_empty() and float(result.get("health_damage",0.0))>0.0:
		var circle:=WarlockSystem.try_demonic_circle(target,float(result.health_damage),{"health_cost":false})
		if bool(circle.triggered):
			target.hp=float(target.hp)+float(result.health_damage);result.health_damage=0.0;result.resolved_damage=float(result.shield_damage);result.defeated=false;result.overkill=0.0
			clear_hero_command(target,"demonic circle");target.command_state=CombatRulesV1.CommandState.INCAPACITATED;target.incapacitated=true
		else:WarlockSystem.convert_health_loss(target,float(result.health_damage),{"exclude_health_loss_cooldown_conversion":false})
	if bool(result.get("defeated",false)) and str(target.get("combat_affiliation",""))=="player":target["was_defeated"]=true
	if str(source.get("class",""))=="Mage" and source_action=="basic_attack" and originating_effect_id=="" and not source.get("mage_runtime",{}).is_empty():
		MageSystem.telemetry_add(source,"basic_attacks_released");MageSystem.telemetry_add(source,"basic_attack_hits")
		var sunfire:=MageSystem.sunfire_release(source,true)
		if bool(sunfire.armed) and float(sunfire.damage)>0.0:deal_damage(source,target,float(sunfire.damage),"basic_ability","magical","Sunfire Enchantment",false,"mage_sunfire",[],false)
	if str(target.get("class",""))=="Guardian" and not target.get("guardian_runtime",{}).is_empty():
		var consumed:=GuardianSystem.consume_block(target,damage_type,source_action,float(result.raw_amount))
		if consumed:GuardianSystem.telemetry_add(target,"block_prevented",float(result.armor_prevented))
		elif float(result.armor_prevented)>0.0:GuardianSystem.telemetry_add(target,"temporary_armor_prevented",float(result.armor_prevented))
		if float(result.resolved_damage)>0.0:GuardianSystem.note_damage(target,float(result.resolved_damage))
		if source_action=="basic_attack" and float(result.resolved_damage)>0.0:
			var imposing_amount:=GuardianSystem.imposing_presence_amount(target,battle_time)
			if imposing_amount>0.0:CombatSystem.apply_control(source,"attack_speed",2.5,imposing_amount)
		var after_ratio:float=float(target.get("hp",0.0))/maxf(1.0,float(target.get("max_hp",1.0)))
		GuardianSystem.try_hardened_shield(target,before_ratio,after_ratio,float(result.resolved_damage),battle_time)
	if str(target.get("class",""))=="Cleric" and not target.get("cleric_runtime",{}).is_empty() and float(result.resolved_damage)>0.0:ClericSystem.note_hostile_damage(target,float(result.resolved_damage))
	if str(source.get("class",""))=="Cleric" and source_action=="basic_attack" and float(result.resolved_damage)>0.0:ClericSystem.reduce_mistweaver(source,1.0)
	if str(source.get("class",""))=="Cleric" and source_action=="basic_attack" and not source.get("cleric_runtime",{}).is_empty():ClericSystem.telemetry_add(source,"offensive_basic_attacks");if float(result.resolved_damage)>0.0:ClericSystem.telemetry_add(source,"offensive_basic_attack_hits")
	if not ranger_basic_result.is_empty():
		RangerSystem.on_basic_attack_resolved(source,result,bool(result.get("defeated",false)),bool(ranger_basic_result.empowered))
		if RangerSystem.has_talent(source,"ranger_l21_2") and float(result.resolved_damage)>0.0:
			var life_fraction:=0.10+0.02*int(source.ranger_runtime.hatred);var life_result:=deal_healing(source,source,float(result.resolved_damage)*life_fraction,"basic_heal","Tempered by Discipline");RangerSystem.telemetry_add(source,"healing",float(life_result.effective_amount))
		var percent_request:Dictionary=ranger_basic_result.percent_request
		if not percent_request.is_empty() and target.hp>0.0:
			var percent_result:=deal_damage(source,target,float(percent_request.amount),"percentage_health","physical","Manticore",false,"ranger_manticore",[],false);RangerSystem.telemetry_add(source,"percentage_damage",float(percent_result.resolved_damage))
	if not guardian_basic_result.is_empty() and float(guardian_basic_result.stun)>0.0:CombatSystem.apply_control(target,"stun",float(guardian_basic_result.stun))
	if slayer_primary:
		var trait_result:=SlayerSystem.note_basic_attack(source,target,result)
		if float(trait_result.raw_healing)>0.0:
			var heal:=deal_healing(source,source,float(trait_result.raw_healing),"basic_heal","Betrayer's Thirst","slayer_trait")
			if float(heal.overhealing)>0.0:
				var shield_gain:=SlayerSystem.add_unending_thirst(source,float(heal.overhealing));if shield_gain>0.0:apply_unit_shield(source,source,shield_gain,"Unending Thirst","slayer_unending_thirst",INF)
		if SlayerSystem.has_talent(source,"slayer_l30_1") and SlayerSystem.successful(result):CombatSystem.apply_control(target,"slow",float(SlayerData.VALUES.nexus_duration),float(SlayerData.VALUES.nexus_slow))
	if str(source.get("class",""))=="Slayer" and not source.get("slayer_runtime",{}).is_empty():SlayerSystem.note_damage_participation(source,target,float(result.get("resolved_damage",0.0)))
	if str(source.get("class",""))=="Priest" and source_action=="basic_attack" and originating_effect_id in ["","priest_surge"] and not source.get("priest_runtime",{}).is_empty():
		var priest_basic:=PriestSystem.note_basic_attack(source,target,result,originating_effect_id)
		if bool(priest_basic.get("successful",false)):
			var pursued_target=PriestSystem.most_wounded(heroes,source,float(PriestData.SPACE.pursued_radius))
			if pursued_target!=null:var pursued:=deal_healing(source,pursued_target,PriestSystem.trait_amount(source,float(PriestData.VALUES.pursued_heal)),"basic_heal","Pursued by Grace","priest_trait");PriestSystem.telemetry_add(source,"pursued_heals");PriestSystem.telemetry_add(source,"pursued_effective",float(pursued.effective_amount));PriestSystem.telemetry_add(source,"pursued_overhealing",float(pursued.overhealing))
			if float(source.priest_runtime.blessed_remaining)>0.0:
				for ally in heroes:if ally.hp>0.0 and ally.pos.distance_to(source.pos)<=float(PriestData.SPACE.blessed_champion_radius):var blessed:=deal_healing(source,ally,float(source.priest_runtime.blessed_snapshot)*float(PriestData.VALUES.blessed_champion_rate),"basic_heal","Blessed Champion","priest_blessed_champion");PriestSystem.telemetry_add(source,"blessed_champion_heals",float(blessed.effective_amount))
			if bool(priest_basic.get("trigger_surge",false)):deal_damage(source,target,float(source.get("damage",0.0)),"basic_attack","physical","Surge of Light",false,"priest_surge",[],true)
			if bool(priest_basic.get("refresh_renew",false)):
				for renew in source.priest_runtime.periodic_heals:if str(renew.get("id",""))=="priest_renew":renew.remaining_duration=float(PriestData.VALUES.renew_duration);PriestSystem.telemetry_add(source,"renew_refreshes")
			if bool(priest_basic.get("trigger_varian",false)):
				source.priest_runtime.periodic_damage=source.priest_runtime.periodic_damage.filter(func(instance):return str(instance.get("target_id",""))!=str(target.combat_id));source.priest_runtime.periodic_damage.append(PeriodicStatusSystem.create("priest_varian",str(source.combat_id),str(target.combat_id),PriestSystem.ability_amount(source,float(PriestData.VALUES.varian_damage))/float(PriestData.VALUES.varian_duration),float(PriestData.VALUES.varian_duration),float(PriestData.VALUES.varian_tick)))
	if str(source.get("class",""))=="Shaman" and source_action=="basic_attack" and originating_effect_id=="" and not source.get("shaman_runtime",{}).is_empty():
		var shaman_basic:=ShamanSystem.note_basic_attack(source,str(target.get("combat_id","")),result,shaman_basic_origin)
		if bool(shaman_basic.get("successful",false)):
			if float(shaman_basic.bonus_damage)>0.0:
				var bonus:=deal_damage(source,target,float(shaman_basic.bonus_damage),"basic_attack","physical","Shaman Basic Attack Bonus",false,"shaman_basic_bonus",[],false)
				if bool(shaman_basic.rolling):var rolling_heal:=deal_healing(source,source,float(bonus.resolved_damage),"basic_heal","Rolling Thunder","shaman_rolling");ShamanSystem.telemetry_add(source,"rolling_damage",float(bonus.resolved_damage));ShamanSystem.telemetry_add(source,"rolling_healing",float(rolling_heal.effective_amount))
			resolve_shaman_frostwolf_from_basic(source,int(shaman_basic.frostwolf_stacks))
			if bool(shaman_basic.windfury_finished) and int(shaman_basic.tempest_subhits)>0:
				for subhit in int(shaman_basic.tempest_subhits):deal_damage(source,target,float(result.resolved_damage)*float(ShamanData.VALUES.tempest_subhit_damage),"basic_attack","physical","Tempest Fury",false,"tempest_fury_subhit",[],false);ShamanSystem.telemetry_add(source,"tempest_subhits")
			if bool(shaman_basic.fury_recast):ShamanSystem.begin_windfury(source,true);source.ability_cds[2]=float(ShamanData.VALUES.e_cooldown)
	if str(target.get("class",""))=="Priest" and not target.get("priest_runtime",{}).is_empty() and float(result.get("health_damage",0.0))>float(target.max_hp)*float(PriestData.VALUES.blessed_recovery_threshold) and PriestSystem.has_talent(target,"priest_l18_2") and float(target.priest_runtime.blessed_recovery_ready_in)<=0.0:
		target.priest_runtime.periodic_heals.append(PeriodicStatusSystem.create("priest_blessed_recovery",str(target.combat_id),str(target.combat_id),float(target.max_hp)*float(PriestData.VALUES.blessed_recovery_fraction)/float(PriestData.VALUES.blessed_recovery_duration),float(PriestData.VALUES.blessed_recovery_duration),1.0));target.priest_runtime.blessed_recovery_ready_in=float(PriestData.VALUES.blessed_recovery_cooldown)
	if testing_zone_active and "training" in target.get("combat_tags",[]) and float(result.get("resolved_damage",0.0))>0.0:target["seconds_since_damage"]=0.0
	finalize_damage_events(source,target,result,source_action,damage_type,origin,source_is_summon,originating_effect_id,trigger_chain,before_ratio,retribution_bonus)
	return result

func deal_healing(source:Dictionary,target:Dictionary,amount:float,source_action:String="basic_ability",origin=null,originating_effect_id:String="")->Dictionary:
	if bool(target.get("spirit_form",false)):return {"raw_amount":amount,"effective_amount":0.0,"overhealing":maxf(0.0,amount),"critical":false}
	var incoming_multiplier:=1.0
	for hero in heroes:
		if str(hero.get("class",""))!="Cleric" or not ClericSystem.has_talent(hero,"cleric_l24_3"):continue
		if hero.get("cleric_runtime",{}).get("serpents",[]).any(func(serpent):return str(serpent.get("host_id",""))==str(target.get("combat_id",""))):incoming_multiplier=maxf(incoming_multiplier,1.10)
	if str(source.get("combat_id",""))!=str(target.get("combat_id","")):
		for rogue in heroes:
			if str(rogue.get("class",""))=="Rogue" and RogueSystem.has_talent(rogue,"rogue_l21_3") and rogue.get("rogue_runtime",{}).get("garrotes",[]).any(func(instance):return str(instance.get("target_id",""))==str(target.get("combat_id","")) and float(instance.get("remaining_duration",0.0))>0.0):incoming_multiplier=minf(incoming_multiplier,float(RogueData.VALUES.strangle_external_multiplier))
	var result:=CombatSystem.resolve_healing(source,target,{"amount":amount,"source_action":source_action,"incoming_multiplier":incoming_multiplier})
	var context:={"source_action":source_action,"action_tags":[source_action,"healing"],"origin":origin,"originating_effect_id":originating_effect_id};var events:=CombatSystem.event_bundle_for_healing(source,target,result,context);combat_events.append_array(events)
	for event in events:
		if event.event_type=="overhealing_done" or float(event.get("effective_amount",0.0))>0.0 and event.event_type in ["direct_healing_done","periodic_healing_done","critical_result"]:apply_passive_trigger(source,event,target)
	var source_index:int=int(source.get("battle_index",-1))
	if source_index>=0:add_healing_threat(source_index,float(result.get("effective_amount",0.0)))
	return result

func apply_unit_shield(source:Dictionary,target:Dictionary,amount:float,origin=null,source_id:String="shield",cap:float=INF,duration:float=0.0)->Dictionary:
	if bool(target.get("spirit_form",false)):return {"amount":0.0,"requested_amount":amount,"blocked":true}
	var result:=CombatSystem.apply_shield(target,amount,{"creator_index":int(source.get("battle_index",-1)),"source_id":source_id,"origin":origin,"cap":cap,"duration":duration,"source_action":"basic_ability"});var event:=CombatSystem.create_event("shield_applied",source,target,result,{"source_action":"basic_ability","action_tags":["basic_ability","shield"],"origin":origin});combat_events.append(event);return result

func update_timed_combat_effects(unit:Dictionary,delta:float)->void:
	ArmorReductionSystem.update(unit,delta)
	for armor_index in range(unit.get("temporary_armor_sources",[]).size()-1,-1,-1):
		unit.temporary_armor_sources[armor_index].remaining=float(unit.temporary_armor_sources[armor_index].get("remaining",0.0))-delta
		if float(unit.temporary_armor_sources[armor_index].remaining)<=0.0:unit.temporary_armor_sources.remove_at(armor_index)
	for shield_index in range(unit.get("shield_sources",[]).size()-1,-1,-1):
		var shield_source:Dictionary=unit.shield_sources[shield_index];var shield_duration:=float(shield_source.get("remaining_duration",0.0))
		if shield_duration<=0.0:continue
		shield_source.remaining_duration=shield_duration-delta
		if float(shield_source.remaining_duration)<=0.0:
			unit.shield=maxf(0.0,float(unit.get("shield",0.0))-float(shield_source.get("amount",0.0)));unit.shield_sources.remove_at(shield_index)
		else:unit.shield_sources[shield_index]=shield_source
	for effect_index in range(unit.get("active_effects",[]).size()-1,-1,-1):
		var active_effect:Dictionary=unit.active_effects[effect_index]
		if float(active_effect.get("delay",0.0))>0.0:
			active_effect.delay=maxf(0.0,float(active_effect.delay)-delta);unit.active_effects[effect_index]=active_effect;continue
		if float(active_effect.get("remaining_duration",0.0))<=0.0:continue
		active_effect.remaining_duration=float(active_effect.remaining_duration)-delta
		if active_effect.remaining_duration<=0.0:unit.active_effects.remove_at(effect_index)
		else:unit.active_effects[effect_index]=active_effect
	if not unit.has("bloodletting_stacks"):return
	for stack_index in range(unit.bloodletting_stacks.size()-1,-1,-1):
		var stack:Dictionary=unit.bloodletting_stacks[stack_index];stack.remaining_duration=float(stack.remaining_duration)-delta;stack.tick_timer=float(stack.tick_timer)-delta
		if stack.tick_timer<=0.0 and unit.hp>0:
			stack.tick_timer+=1.0
			var dot_source:Dictionary=stack.source_unit
			var dot_result:=deal_damage(dot_source,unit,float(stack.amount),"periodic","physical","Bloodletting",false,"bloodletting",["bloodletting"],true)
			if float(dot_result.get("resolved_damage",0.0))>0:add_effect("hit",dot_source.get("pos",unit.pos),unit.pos,"-%d"%int(dot_result.resolved_damage),Color("d96a72"))
		if stack.remaining_duration<=0.0:unit.bloodletting_stacks.remove_at(stack_index)
		else:unit.bloodletting_stacks[stack_index]=stack

func update_item_runtime(hero:Dictionary,delta:float)->void:

	refresh_item_combat_stats(hero)
	if hero_has_passive(hero,"borrowed_time") and not bool(hero.get("borrowed_time_armed",false)):
		hero.borrowed_time_timer=float(hero.get("borrowed_time_timer",0.0))+delta
		if hero.borrowed_time_timer>=8.0:hero.borrowed_time_timer=0.0;hero.borrowed_time_armed=true;item_feedback("Borrowed Time Ready",hero.pos,Color("b8d5ff"))
	if hero_has_passive(hero,"twin_incantation"):
		for charge_index in range(hero.q_charge_timers.size()-1,-1,-1):
			hero.q_charge_timers[charge_index]=float(hero.q_charge_timers[charge_index])-delta
			if hero.q_charge_timers[charge_index]<=0.0:hero.q_charge_timers.remove_at(charge_index);hero.q_charges=mini(2,int(hero.q_charges)+1)
		hero.ability_cds[0]=0.0 if int(hero.q_charges)>0 else (float(hero.q_charge_timers[0]) if not hero.q_charge_timers.is_empty() else 0.0)
	for repeat_index in range(hero.get("pending_repeats",[]).size()-1,-1,-1):
		var repeat:Dictionary=hero.pending_repeats[repeat_index];repeat.remaining=float(repeat.remaining)-delta
		if repeat.remaining<=0.0:
			hero.pending_repeats.remove_at(repeat_index)
			var old_selected:int=selected;var old_focused:int=focused_enemy_index;var old_target:int=int(hero.target);var old_heal_target:int=int(hero.heal_target)
			selected=int(hero.get("battle_index",0));focused_enemy_index=int(repeat.enemy_target);hero.target=int(repeat.assigned_target);hero.heal_target=int(repeat.ally_target)
			use_ability(int(repeat.slot),repeat.position,true)
			selected=old_selected;focused_enemy_index=old_focused;hero.target=old_target;hero.heal_target=old_heal_target
		else:hero.pending_repeats[repeat_index]=repeat

func add_enemy_threat(enemy:Dictionary,hero_index:int,amount:float) -> void:
	if amount<=0 or hero_index<0 or hero_index>=heroes.size() or bool(enemy.get("ignores_tank_aggro",false)):return
	var threat_table:Dictionary=enemy.get("threat",{})
	threat_table[hero_index]=float(threat_table.get(hero_index,0.0))+amount
	enemy.threat=threat_table

func add_damage_threat(enemy:Dictionary,hero_index:int,damage_dealt:float) -> void:
	if damage_dealt<=0:return
	add_enemy_threat(enemy,hero_index,damage_dealt*CombatSystem.DAMAGE_THREAT_RATIO*float(heroes[hero_index].get("threat_modifier",1.0)))

func add_healing_threat(healer_index:int,effective_healing:float) -> void:
	if effective_healing<=0:return
	var living_count:int=enemies.filter(func(enemy):return enemy.hp>0 and not bool(enemy.get("ignores_tank_aggro",false))).size()
	var per_enemy:float=CombatSystem.distributed_threat(effective_healing*CombatSystem.HEALING_THREAT_RATIO*float(heroes[healer_index].get("threat_modifier",1.0)),living_count)
	for enemy in enemies:
		if enemy.hp>0:add_enemy_threat(enemy,healer_index,per_enemy)
