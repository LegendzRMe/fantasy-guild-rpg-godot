extends RefCounted

const RecruitmentData = preload("res://scripts/data/recruitment_data.gd")
const GuildMemberData = preload("res://scripts/data/guild_member_data.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const ProfessionData = preload("res://scripts/data/profession_data.gd")
const ProfessionSystem = preload("res://scripts/systems/profession_system.gd")
const CookingSystem = preload("res://scripts/systems/cooking_system.gd")

const SAVE_VERSION := 3

static func ensure_state(state:Dictionary) -> void:
	if not state.get("component_versions") is Dictionary:state["component_versions"]={}
	state.component_versions["recruitment"]=SAVE_VERSION
	var defaults:=RecruitmentData.default_state()
	if not state.get("recruitment") is Dictionary:state["recruitment"]=defaults.duplicate(true)
	for key in defaults:
		if not state.recruitment.has(key):state.recruitment[key]=defaults[key].duplicate(true) if defaults[key] is Array or defaults[key] is Dictionary else defaults[key]
	state.recruitment.hourly_budget=clampi(int(state.recruitment.get("hourly_budget",0)),0,int(RecruitmentData.CONFIG.max_hourly_budget))
	state.recruitment.tavern_name=str(state.recruitment.get("tavern_name","The Tavern")).strip_edges().left(32)
	if str(state.recruitment.tavern_name)=="":state.recruitment.tavern_name="The Tavern"
	state.recruitment.minutes_until_next_check=clampf(float(state.recruitment.get("minutes_until_next_check",RecruitmentData.CONFIG.check_interval_minutes)),0.0,float(RecruitmentData.CONFIG.check_interval_minutes))
	if not state.recruitment.get("candidates") is Array:state.recruitment.candidates=[]
	if not state.recruitment.get("activity_log") is Array:state.recruitment.activity_log=[]
	state.recruitment.activity_log=state.recruitment.activity_log.filter(func(entry):return entry is String and not str(entry).begins_with("Hourly recruitment budget set to ")).slice(-int(RecruitmentData.CONFIG.activity_log_limit))
	state.recruitment.next_candidate_id=maxi(1,int(state.recruitment.get("next_candidate_id",1)))
	var valid:Array=[];var seen:Dictionary={}
	for raw_candidate in state.recruitment.candidates:
		if not candidate_is_valid(raw_candidate):continue
		var candidate:Dictionary=raw_candidate
		var candidate_id:=str(candidate.candidate_id)
		if seen.has(candidate_id):continue
		candidate.remaining_wait_minutes=clampf(float(candidate.get("remaining_wait_minutes",RecruitmentData.CONFIG.candidate_wait_minutes)),0.01,float(RecruitmentData.CONFIG.candidate_wait_minutes))
		candidate.locked=bool(candidate.get("locked",false));refresh_disclosure_counts(candidate)
		valid.append(candidate);seen[candidate_id]=true
		if valid.size()>=int(RecruitmentData.CONFIG.candidate_capacity):break
	state.recruitment.candidates=valid

static func candidate_is_valid(value) -> bool:
	if not value is Dictionary:return false
	var candidate:Dictionary=value
	if str(candidate.get("candidate_id",""))=="" or not candidate.get("hero_record") is Dictionary:return false
	var hero:Dictionary=candidate.hero_record;var class_id:=str(hero.get("class_id",GameData.class_id_for(str(hero.get("class","")))))
	if str(hero.get("hero_id",""))=="" or str(hero.get("display_name",hero.get("name","")))=="" or not hero.get("equipment_slots") is Dictionary:return false
	if class_id not in RecruitmentData.BEGINNER_CLASS_IDS:return false
	if str(candidate.get("origin_zone_id",""))!=RecruitmentData.ORIGIN_ZONE_ID:return false
	var level:=int(hero.get("level",0))
	if level<int(RecruitmentData.CONFIG.minimum_candidate_level) or level>int(RecruitmentData.CONFIG.maximum_candidate_level):return false
	if int(candidate.get("signing_cost",-1))<0:return false
	if not candidate.get("equipment_instances",[]) is Array:return false
	for item in candidate.equipment_instances:
		if not item is Dictionary or str(item.get("instance_id",""))=="" or bool(item.get("testing_only",false)):return false
	return true

static func add_log(state:Dictionary,message:String) -> void:
	ensure_state(state)
	state.recruitment.activity_log.append(message)
	while state.recruitment.activity_log.size()>int(RecruitmentData.CONFIG.activity_log_limit):state.recruitment.activity_log.pop_front()

static func set_budget(state:Dictionary,budget:int) -> int:
	ensure_state(state);state.recruitment.hourly_budget=clampi(budget,0,int(RecruitmentData.CONFIG.max_hourly_budget))
	return int(state.recruitment.hourly_budget)

static func set_tavern_name(state:Dictionary,value:String) -> String:
	ensure_state(state);var cleaned:=value.strip_edges().left(32);state.recruitment.tavern_name=cleaned if cleaned!="" else "The Tavern";return str(state.recruitment.tavern_name)

static func progression_baseline(state:Dictionary) -> int:
	var levels:Array=[]
	for hero_index_value in state.get("active_team",state.get("selected_team",[])):
		var hero_index:=int(hero_index_value)
		if hero_index>=0 and hero_index<state.get("heroes",[]).size():levels.append(int(state.heroes[hero_index].get("level",1)))
	if levels.is_empty():
		for hero in state.get("heroes",[]):levels.append(int(hero.get("level",1)))
	if levels.is_empty():return 1
	var total:=0
	for level in levels:total+=int(level)
	return clampi(int(round(float(total)/levels.size())),int(RecruitmentData.CONFIG.minimum_candidate_level),int(RecruitmentData.CONFIG.maximum_candidate_level))

static func _best_profession_standard(state:Dictionary) -> Dictionary:
	var best:={"rank":0,"xp":0}
	for hero in state.get("heroes",[]):
		var progress:=ProfessionSystem.migrate_progress(hero.get("profession_progress",{}))
		if int(progress.profession_rank)>int(best.rank) or int(progress.profession_rank)==int(best.rank) and int(progress.profession_xp)>int(best.xp):
			best={"rank":int(progress.profession_rank),"xp":int(progress.profession_xp)}
	return best

static func _candidate_level(rng:RandomNumberGenerator,baseline:int,budget:int,prestige:int) -> int:
	return 1

static func _profession_progress(state:Dictionary,rng:RandomNumberGenerator,budget:int) -> Dictionary:
	var progress:=ProfessionSystem.default_progress();var best:=_best_profession_standard(state)
	if int(best.rank)<=0 or rng.randf()>0.08+budget*0.07:return progress
	var profession_ids:=ProfessionData.PROFESSIONS.keys();var profession_id:=str(profession_ids[rng.randi_range(0,profession_ids.size()-1)])
	progress.profession_id=profession_id;progress.profession_slots[0]=profession_id;progress.profession_rank=1
	var xp_ceiling:=maxi(0,int(best.xp));var fraction:=minf(1.0,0.10+budget*0.10+rng.randf_range(0.0,0.15))
	if budget==5 and rng.randf()<0.08:progress.profession_rank=mini(1,int(best.rank));fraction=1.0
	progress.profession_xp=mini(xp_ceiling,int(round(xp_ceiling*fraction)))
	progress.profession_milestones=["profession_introduction"]
	return progress

static func _candidate_equipment(rng:RandomNumberGenerator,hero:Dictionary,budget:int,candidate_id:String) -> Array:
	var result:Array=[];var definition_ids:Array=[]
	for definition_id in ItemData.ITEMS:
		var definition:Dictionary=ItemData.ITEMS[definition_id]
		if bool(definition.get("testing_only",false)) or int(definition.get("tier",1))>1:continue
		if ItemData.can_equip(definition,GameData.class_definition(str(hero["class"])),str(hero["class"])):definition_ids.append(str(definition_id))
	definition_ids.sort();var used_slots:Dictionary={};var chance:=0.08+budget*0.08+int(hero.level)*0.04
	for definition_id in definition_ids:
		if rng.randf()>chance:continue
		var item:=ItemData.create_instance(definition_id,"recruit_%s_%s"%[candidate_id,definition_id]);var slot:=str(item.slot)
		if used_slots.has(slot):continue
		item.owner_state="candidate";item.storage_location="candidate";item.equipped_hero_index=-1
		hero.equipment_slots[slot]=item.instance_id;result.append(item);used_slots[slot]=true
		if result.size()>=mini(2,maxi(0,int(hero.level)/2)):break
	return result

static func _disclosure_score(rng:RandomNumberGenerator,budget:int,prestige:int,personality_id:String) -> int:
	return clampi(int(round(budget*2.0+rng.randf_range(-4.0,4.0))),0,14)

static func field_is_revealed(candidate:Dictionary,field_id:String) -> bool:
	var targeted:String=str(candidate.get("targeted_reveals",{}).get(field_id,""))
	if targeted in ["full","partial"]:return true
	return float(candidate.get("information_disclosure_score",0))>=float(RecruitmentData.REVEAL_THRESHOLDS.get(field_id,101.0))

static func refresh_disclosure_counts(candidate:Dictionary) -> void:
	var count:=0
	for field_id in RecruitmentData.REVEAL_ORDER:
		if field_is_revealed(candidate,str(field_id)):count+=1
	candidate["revealed_field_count"]=count;candidate["total_revealable_field_count"]=RecruitmentData.REVEAL_ORDER.size()

static func generate_candidate(state:Dictionary,budget:int,forced_seed:int=-1) -> Dictionary:
	ensure_state(state);budget=clampi(budget,1,int(RecruitmentData.CONFIG.max_hourly_budget))
	var sequence:=int(state.recruitment.next_candidate_id);var candidate_id:="candidate_%d"%sequence
	var rng:=RandomNumberGenerator.new();rng.seed=forced_seed if forced_seed>=0 else hash("%s:%d:%d:%d"%[str(state.get("guild_name","guild")),sequence,int(state.get("guild_prestige_rank",1)),int(state.get("game_clock",{}).get("total_minutes",0))])
	var class_ids:Array=RecruitmentData.BEGINNER_CLASS_IDS;var class_id:=str(class_ids[rng.randi_range(0,class_ids.size()-1)]);var class_display:=GameData.class_display_name(class_id)
	var prestige:=maxi(0,int(state.get("guild_prestige_rank",1)));var level:=_candidate_level(rng,progression_baseline(state),budget,prestige)
	var name:=str(RecruitmentData.NAMES[rng.randi_range(0,RecruitmentData.NAMES.size()-1)]);var hero_id:="tavern_%s_%d"%[name.to_snake_case(),sequence]
	var hero:=GuildMemberData.create(name,class_display,level,10,"tavern_recruit",false,0,{"hero_id":hero_id})
	hero.profession_progress=ProfessionSystem.default_progress()
	var personalities:=RecruitmentData.PERSONALITIES.keys();var personality_id:=str(personalities[rng.randi_range(0,personalities.size()-1)])
	var equipment:Array=[]
	var quality_score:=clampi(5+budget*10+rng.randi_range(0,10),0,100)
	var disclosure:=_disclosure_score(rng,budget,prestige,personality_id)
	var profession_rank:=int(hero.profession_progress.get("profession_rank",0));var signing_cost:=maxi(1,level*8+int(round(quality_score/10.0))+equipment.size()*8+profession_rank*10)
	var definition:=GameData.class_definition(class_id);var candidate:={
		"candidate_id":candidate_id,"hero_record":hero,"equipment_instances":equipment,
		"broad_role":str(definition.get("primary_role",definition.get("role","Adventurer"))),
		"approximate_level_min":maxi(1,level-1),"approximate_level_max":mini(int(RecruitmentData.CONFIG.maximum_candidate_level),level+1),
		"quality_score":quality_score,"information_disclosure_score":disclosure,"revealed_field_count":0,
		"total_revealable_field_count":RecruitmentData.REVEAL_ORDER.size(),"signing_cost":signing_cost,
		"remaining_wait_minutes":float(RecruitmentData.CONFIG.candidate_wait_minutes),"locked":false,
		"origin_zone_id":RecruitmentData.ORIGIN_ZONE_ID,"origin_zone_name":RecruitmentData.ORIGIN_ZONE_NAME,
		"personality_id":personality_id,"positive_trait_id":null,"negative_trait_id":null,"title_id":null,
		"created_at_game_minute":float(state.get("game_clock",{}).get("total_minutes",0.0))
	}
	refresh_disclosure_counts(candidate);return candidate

static func _perform_hourly_check(state:Dictionary) -> Dictionary:
	ensure_state(state)
	if not state.recruitment.candidates.is_empty():return {"type":"full","message":"The Tavern is full; recruitment checks are paused."}
	var budget:=int(state.recruitment.hourly_budget)
	if budget<=0:return {"type":"no_budget","message":"No patron search ran because the Tavern Budget is 0 Gold."}
	if int(state.get("gold",0))<budget:
		var insufficient:="Tavern search paused: the guild cannot afford its %d Gold budget."%budget;add_log(state,insufficient);return {"type":"insufficient_gold","message":insufficient}
	state.gold=int(state.gold)-budget
	var candidate:=generate_candidate(state,budget);state.recruitment.next_candidate_id=int(state.recruitment.next_candidate_id)+1;state.recruitment.candidates.append(candidate)
	CookingSystem.on_candidate_arrived(state)
	var message:="%s arrived after the Tavern spent %d Gold finding a new patron."%[str(candidate.hero_record.display_name),budget];add_log(state,message)
	return {"type":"candidate_arrived","message":message,"candidate_id":candidate.candidate_id}

static func advance(state:Dictionary,game_minutes:float) -> Array:
	ensure_state(state);var events:Array=[];var remaining:=maxf(0.0,game_minutes);var guard:=0
	while remaining>0.0001 and guard<32:
		guard+=1
		if not state.recruitment.candidates.is_empty():
			var candidate:Dictionary=state.recruitment.candidates[0]
			if bool(candidate.locked):break
			var step:=minf(remaining,float(candidate.remaining_wait_minutes));candidate.remaining_wait_minutes-=step;remaining-=step
			if float(candidate.remaining_wait_minutes)<=0.0001:
				var message:="%s left the Tavern."%str(candidate.hero_record.display_name);state.recruitment.candidates.clear();add_log(state,message);events.append({"type":"candidate_expired","message":message})
			continue
		var check_step:=minf(remaining,float(state.recruitment.minutes_until_next_check));state.recruitment.minutes_until_next_check-=check_step;remaining-=check_step
		if float(state.recruitment.minutes_until_next_check)<=0.0001:
			state.recruitment.minutes_until_next_check=float(RecruitmentData.CONFIG.check_interval_minutes);events.append(_perform_hourly_check(state))
	return events

static func current_candidate(state:Dictionary) -> Dictionary:
	ensure_state(state);return state.recruitment.candidates[0] if not state.recruitment.candidates.is_empty() else {}

static func reject_candidate(state:Dictionary) -> Dictionary:
	var candidate:=current_candidate(state)
	if candidate.is_empty():return {"success":false,"reason":"There is no candidate to reject."}
	state.recruitment.candidates.clear();add_log(state,"%s was rejected."%str(candidate.hero_record.display_name));return {"success":true,"reason":"Candidate rejected."}

static func toggle_candidate_lock(state:Dictionary) -> Dictionary:
	var candidate:=current_candidate(state)
	if candidate.is_empty():return {"success":false,"reason":"There is no candidate to lock."}
	candidate.locked=not bool(candidate.locked);add_log(state,"%s was %s."%[str(candidate.hero_record.display_name),"locked" if candidate.locked else "unlocked"])
	return {"success":true,"reason":"Candidate locked." if candidate.locked else "Candidate unlocked.","locked":candidate.locked}

static func recruit_candidate(state:Dictionary,use_familiar_offer:bool=false) -> Dictionary:
	ensure_state(state);var candidate:=current_candidate(state)
	if candidate.is_empty():return {"success":false,"reason":"There is no candidate to recruit."}
	CookingSystem.ensure_state(state);var offer:=CookingSystem.familiar_offer_status(state);var signing_cost:=int(offer.get("cost",candidate.signing_cost)) if use_familiar_offer and bool(offer.get("available",false)) else int(candidate.signing_cost)
	if use_familiar_offer and not bool(offer.get("available",false)):return {"success":false,"reason":str(offer.get("reason","Familiar Offer is unavailable."))}
	if int(state.get("gold",0))<signing_cost:return {"success":false,"reason":"Requires %d Gold to sign this candidate."%signing_cost}
	var hero:Dictionary=candidate.hero_record.duplicate(true);var hero_id:=str(hero.hero_id)
	if state.get("heroes",[]).any(func(existing):return str(existing.get("hero_id",""))==hero_id):return {"success":false,"reason":"This candidate is already in the guild."}
	var hero_index:int=state.heroes.size();state.gold=int(state.gold)-signing_cost
	if use_familiar_offer:candidate.familiar_offer_used=true
	state.heroes.append(hero)
	for raw_item in candidate.equipment_instances:
		var item:Dictionary=raw_item.duplicate(true);item.owner_state="equipped";item.storage_location="vault";item.equipped_hero_index=hero_index;state.item_instances.append(item)
	ItemData.reconcile_ownership(state);state.recruitment.candidates.clear();add_log(state,"%s joined the guild for %d Gold."%[str(hero.display_name),signing_cost])
	return {"success":true,"reason":"%s joined the guild."%str(hero.display_name),"hero_index":hero_index,"hero_id":hero_id}

static func debug_spawn(state:Dictionary) -> Dictionary:
	ensure_state(state)
	if not state.recruitment.candidates.is_empty():return {"success":false,"reason":"Clear the current candidate first."}
	var budget:=maxi(1,int(state.recruitment.hourly_budget));var candidate:=generate_candidate(state,budget);state.recruitment.next_candidate_id+=1;state.recruitment.candidates.append(candidate);CookingSystem.on_candidate_arrived(state);return {"success":true,"candidate":candidate}

static func debug_set_disclosure(state:Dictionary,score:int) -> bool:
	var candidate:=current_candidate(state)
	if candidate.is_empty():return false
	candidate.information_disclosure_score=clampi(score,0,100);refresh_disclosure_counts(candidate);return true
