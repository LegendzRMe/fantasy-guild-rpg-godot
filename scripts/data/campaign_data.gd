extends RefCounted

const REGION_ORDER := ["greyhaven_reach","kwaad_scar","consortium_crossroads","gallah_highlands","godfall_marches","grand_corruption_front"]
const REGION_TARGET_LEVELS := {"greyhaven_reach":5,"kwaad_scar":10,"consortium_crossroads":15,"gallah_highlands":20,"godfall_marches":25,"grand_corruption_front":30}
const REGION_MIN_LEVELS := {"greyhaven_reach":2,"kwaad_scar":6,"consortium_crossroads":11,"gallah_highlands":16,"godfall_marches":21,"grand_corruption_front":26}
const REPEATABLE_TEMPLATES := ["Patrol","Hunt","Escort","Gather","Defend","Rescue","Recover Relic","Faction Request","Rare Enemy","World Event"]
const REPUTATION_RANKS := [
	{"id":"hostile","name":"Hostile","minimum":-100,"maximum":-50},
	{"id":"unfriendly","name":"Unfriendly","minimum":-49,"maximum":-1},
	{"id":"neutral","name":"Neutral","minimum":0,"maximum":19},
	{"id":"cooperative","name":"Cooperative","minimum":20,"maximum":49},
	{"id":"trusted","name":"Trusted","minimum":50,"maximum":100}
]

const REGIONS := {
	"greyhaven_reach":{"name":"Greyhaven Reach","act":"ACT I — The Broken Compact","lesson":"A guild earns access through trust, not just victory.","summary":"Road wardens, guild delegates, and local farmers contest a sacred coast.","factions":["temple_wardens","greyhaven_council","local_compact"],"decision":"greyhaven_shrine","callback":"A displaced shrine keeper has returned to the Coastal Shrine.","locations":[
		["forest_road","Forest Road","main",Vector2(110,290),"The safe road ends where the old compact failed."],["old_mine","Old Mine","side",Vector2(260,420),"Missing miners left something awake below."],["greyhaven_watchtower","Greyhaven Watchtower","main",Vector2(310,250),"The watch reports raids from three directions."],["coastal_shrine","Coastal Shrine","main",Vector2(530,175),"Decide who will protect Greyhaven's sacred coast."],["sunken_archive","Sunken Archive","side",Vector2(570,390),"Tide-locked records expose the compact's first betrayal."],["greyhaven_settlement","Greyhaven Settlement","settlement",Vector2(360,500),"A permanent safe hub and market."],["temple_wardens_chapel","Temple Wardens' Chapel","faction",Vector2(760,115),"Temple Wardens", "temple_wardens"],["guild_council_lodge","Guild Council Lodge","faction",Vector2(790,285),"Greyhaven Guild Council", "greyhaven_council"],["local_compact_farmstead","Local Compact Farmstead","faction",Vector2(735,465),"Local Compact", "local_compact"]]},
	"kwaad_scar":{"name":"The Kwaad Scar","act":"ACT I — The Broken Compact","lesson":"Neutral contracts still choose who bears the cost.","summary":"Four powers race to control Hour Fortress and the scar roads.","factions":["zorel_house","gallah_relief","grand_scar_command","kwaad_elders"],"decision":"hour_fortress","callback":"A survivor requests judgment at Battlefield Hospital.","locations":[
		["scar_road","Scar Road","main",Vector2(100,310),"Cross the ruined trade artery."],["gilded_rest","Gilded Rest","settlement",Vector2(225,465),"A mercenary settlement and trade stop."],["battlefield_hospital","Battlefield Hospital","side",Vector2(280,155),"Relief workers are hiding a strategic patient."],["zorel_contract_camp","Zorel Contract Camp","faction",Vector2(430,455),"Zorel Contract House","zorel_house"],["grand_scar_outpost","Grand Scar Outpost","faction",Vector2(475,105),"Grand Scar Command","grand_scar_command"],["kwaad_truce_stones","Kwaad Truce Stones","faction",Vector2(620,430),"Kwaad Elders","kwaad_elders"],["broken_alliance_ruins","Broken Alliance Ruins","side",Vector2(590,235),"Recover proof of the alliance's collapse."],["hour_fortress","Hour Fortress","main",Vector2(810,255),"Choose who controls the fortress."],["scarwatch_outpost","Scarwatch Outpost","faction",Vector2(805,465),"Gallah Relief Expedition","gallah_relief"]]},
	"consortium_crossroads":{"name":"Consortium Crossroads","act":"ACT II — Sovereignty","lesson":"Political stability and freedom rarely share a clean border.","summary":"Delegations assemble while a saboteur exploits old grievances.","factions":["norath_delegation","sovereignty_coalition","grand_protectorate","ronah_liberation"],"decision":"summit_outcome","callback":"The coalition calls an emergency session at Crossroads Assembly.","locations":[
		["old_alliance_road","Old Alliance Road","main",Vector2(90,310),"Escort delegates through contested ground."],["crossroads_assembly","Crossroads Assembly","settlement",Vector2(250,245),"The region's political and trade hub."],["ronah_quarter","Ronah Quarter","faction",Vector2(280,470),"Ronah Liberation Movement","ronah_liberation"],["norath_delegation","Norath Delegation","faction",Vector2(430,95),"Norath Delegation","norath_delegation"],["sovereignty_camp","Sovereignty Coalition Camp","faction",Vector2(485,445),"Local Sovereignty Coalition","sovereignty_coalition"],["protectorate_camp","Grand Protectorate Camp","faction",Vector2(655,105),"Grand Protectorate","grand_protectorate"],["broken_alliance_monument","Broken Alliance Monument","side",Vector2(620,300),"A public memorial conceals a private message."],["summit_hall","Summit Hall","main",Vector2(825,250),"Shape the new political order."],["saboteur_warrens","Saboteur Warrens","side",Vector2(800,455),"Stop the faction exploiting the summit." ]]},
	"gallah_highlands":{"name":"Gallah Highlands","act":"ACT II — Sovereignty","lesson":"A cure can save a nation and still become a weapon.","summary":"Crystal sickness divides healers, wardens, smugglers, and the republic.","factions":["gallah_republic","curehouse","crystal_wardens","sinisvania","escape_network"],"decision":"crystal_cure","callback":"A cured refugee is missing from the Curehouse rolls.","locations":[
		["crystal_road","Crystal Road","main",Vector2(95,300),"Enter the highlands through a spreading crystal storm."],["high_gallah","High Gallah","settlement",Vector2(245,455),"Republic hub, inn, and Trading Post."],["curehouse","Curehouse","faction",Vector2(285,130),"Curehouse","curehouse"],["crystal_bastion","Crystal Warden Bastion","faction",Vector2(460,90),"Crystal Wardens","crystal_wardens"],["sinisvania_enclave","Sinisvania Enclave","faction",Vector2(470,460),"Sinisvania Enclave","sinisvania"],["smuggler_pass","Smuggler Pass","faction",Vector2(650,455),"Independent Escape Network","escape_network"],["shattered_quarry","Shattered Quarry","side",Vector2(620,245),"Recover a stable sample before the quarry collapses."],["rift_laboratory","Rift Laboratory","main",Vector2(810,230),"Decide who controls the cure research."],["frozen_reliquary","Frozen Reliquary","side",Vector2(800,440),"The republic's sealed evidence vault.","gallah_republic"]]},
	"godfall_marches":{"name":"The Godfall Marches","act":"ACT III — The Last Barrier","lesson":"Some barriers imprison danger; others imprison history.","summary":"Clans and relic armies hold a living barrier around a dead pantheon.","factions":["stonehorn_clan","ashen_vie","pantheon_pact","reliquary_command"],"decision":"living_barrier","callback":"The Living Barrier now speaks with a familiar voice.","locations":[
		["savage_road","Savage Road","main",Vector2(85,300),"Survive the marchers' proving ground."],["marchers_rest","Marcher's Rest","settlement",Vector2(235,455),"Last permanent shelter before Unum."],["stonehorn_camp","Stonehorn Camp","faction",Vector2(280,120),"Stonehorn Clan","stonehorn_clan"],["ashen_vie_camp","Ashen Vie Recovery Camp","faction",Vector2(455,455),"Ashen Vie","ashen_vie"],["reliquary_fort","Grand Reliquary Fort","faction",Vector2(475,90),"Grand Reliquary Command","reliquary_command"],["unum_ruins","Unum City Ruins","side",Vector2(625,260),"Recover the names of the vanished city."],["hollow_pantheon","Hollow Pantheon","faction",Vector2(650,450),"Pantheon Pact","pantheon_pact"],["living_barrier","Living Barrier Site","main",Vector2(810,225),"Preserve, break, or share control of the barrier."],["last_twelve_temple","Temple of the Last Twelve","side",Vector2(805,445),"The final surviving testimony." ]]},
	"grand_corruption_front":{"name":"Grand Corruption Front","act":"ACT III — The Last Barrier","lesson":"Every alliance is measured when the gateway opens.","summary":"The campaign converges on Nazareth and the origin gateway.","factions":["kingdom_grand","kingdom_independence","corr_hunters","grand_researchers"],"decision":"gateway_fate","callback":"All prior consequences converge at Grand Front Command.","locations":[
		["frontline_road","Frontline Road","main",Vector2(85,300),"Break through the corruption line."],["grand_front_command","Grand Front Command","settlement",Vector2(230,455),"Final headquarters and operation staging."],["origin_refuge","Origin Refuge","side",Vector2(280,115),"Evacuate survivors carrying gateway memories."],["corr_hunter_lodge","Corr-Hunter Lodge","faction",Vector2(450,95),"Corr-Hunters","corr_hunters"],["research_encampment","Research Encampment","faction",Vector2(465,455),"Researchers","grand_researchers"],["independence_camp","Independence Camp","faction",Vector2(650,455),"Kingdom of Independence","kingdom_independence"],["rift_scar","Rift Scar","side",Vector2(620,245),"Recover the final anchor shard."],["grastrof_approach","Grastrof's Approach","faction",Vector2(805,95),"Kingdom of Grand","kingdom_grand"],["gateway_site","Gateway Site","main",Vector2(815,300),"Defeat Nazareth and decide the Twilight gateway's fate." ]]}
}

const FACTIONS := {
	"temple_wardens":["Temple Wardens","greyhaven_reach","Aldric Dawn","Guardian"],"greyhaven_council":["Greyhaven Guild Council","greyhaven_reach","Lysa Quill","Mage"],"local_compact":["Local Compact","greyhaven_reach","Fen Reed","Ranger"],
	"zorel_house":["Zorel Contract House","kwaad_scar","Vexa Zorel","Rogue"],"gallah_relief":["Gallah Relief Expedition","kwaad_scar","Toma Vale","Cleric"],"grand_scar_command":["Grand Scar Command","kwaad_scar","Orin Pike","Guardian"],"kwaad_elders":["Kwaad Elders","kwaad_scar","Sable Scar","Warlock"],
	"norath_delegation":["Norath Delegation","consortium_crossroads","Eris North","Mage"],"sovereignty_coalition":["Local Sovereignty Coalition","consortium_crossroads","Jori Free","Ranger"],"grand_protectorate":["Grand Protectorate","consortium_crossroads","Cassian Ward","Guardian"],"ronah_liberation":["Ronah Liberation Movement","consortium_crossroads","Rin Ash","Rogue"],
	"gallah_republic":["Republic Council","gallah_highlands","Mara Glass","Mage"],"curehouse":["Curehouse","gallah_highlands","Sister Elia","Cleric"],"crystal_wardens":["Crystal Wardens","gallah_highlands","Bram Quartz","Guardian"],"sinisvania":["Sinisvania Enclave","gallah_highlands","Vey Night","Warlock"],"escape_network":["Independent Escape Network","gallah_highlands","Kite Snow","Rogue"],
	"stonehorn_clan":["Stonehorn Clan","godfall_marches","Rook Stone","Guardian"],"ashen_vie":["Ashen Vie","godfall_marches","Nia Ember","Cleric"],"pantheon_pact":["Pantheon Pact","godfall_marches","Omen Twelve","Warlock"],"reliquary_command":["Grand Reliquary Command","godfall_marches","Pella Rune","Mage"],
	"kingdom_grand":["Kingdom of Grand","grand_corruption_front","Dame Corra","Guardian"],"kingdom_independence":["Kingdom of Independence","grand_corruption_front","Tess Banner","Ranger"],"corr_hunters":["Corr-Hunters","grand_corruption_front","Hollis Rift","Rogue"],"grand_researchers":["Researchers","grand_corruption_front","Doctor Una","Mage"]
}

const DECISIONS := {
	"greyhaven_shrine":{"title":"Who guards the Coastal Shrine?","options":[["wardens","Entrust the Temple Wardens","temple_wardens"],["council","Grant a Council charter","greyhaven_council"],["compact","Return it to the Local Compact","local_compact"]]},
	"hour_fortress":{"title":"What becomes of Hour Fortress?","options":[["destroy","Destroy its engines",""],["gallah","Grant it to Gallah Relief","gallah_relief"],["zorel","Honor Zorel's contract","zorel_house"],["grand","Install Grand Scar Command","grand_scar_command"],["kwaad","Return it to the Kwaad Elders","kwaad_elders"]]},
	"summit_outcome":{"title":"What political order leaves Summit Hall?","options":[["norath","Norath-administered compact","norath_delegation"],["sovereignty","Independent sovereignty","sovereignty_coalition"],["protectorate","Grand protectorate","grand_protectorate"],["ronah","Ronah liberation charter","ronah_liberation"]]},
	"crystal_cure":{"title":"Who controls the crystal cure?","options":[["republic","Republic oversight","gallah_republic"],["curehouse","Open Curehouse stewardship","curehouse"],["wardens","Warden containment","crystal_wardens"],["sinisvania","Sinisvanian research pact","sinisvania"],["escape","Release it through the Escape Network","escape_network"]]},
	"living_barrier":{"title":"What is the fate of the Living Barrier?","options":[["preserve","Preserve it","reliquary_command"],["break","Break it","stonehorn_clan"],["shared","Share control","pantheon_pact"]]},
	"gateway_fate":{"title":"Nazareth falls. What becomes of the Twilight gateway?","options":[["seal","Seal it forever","kingdom_grand"],["study","Study it under guard","grand_researchers"],["repair","Repair the passage","kingdom_independence"],["limit","Limit and patrol access","corr_hunters"]]}
}

const FIXED_RIVALS := {
	"gilded_jackals":{"name":"Gilded Jackals","ratings":{"pve":8,"wealth":9,"reputation":3,"pvp":6,"recruitment":6},"identity":"Rich contract rivals who keep arriving one step ahead."},
	"crimson_standard":{"name":"Crimson Standard","ratings":{"pve":6,"wealth":5,"reputation":4,"pvp":9,"recruitment":8},"identity":"Aggressive duelists with little patience for diplomacy."},
	"wayfarer_accord":{"name":"Wayfarer Accord","ratings":{"pve":3,"wealth":5,"reputation":9,"pvp":4,"recruitment":8},"identity":"Beloved organizers whose field teams avoid hard fights."}
}

static func region(region_id:String)->Dictionary:
	return REGIONS.get(region_id,{})

static func region_index(region_id:String)->int:
	return REGION_ORDER.find(region_id)

static func location(region_id:String,location_id:String)->Dictionary:
	var rows:Array=region(region_id).get("locations",[])
	for index in rows.size():
		var row:Array=rows[index]
		if str(row[0])!=location_id:continue
		return {"id":row[0],"name":row[1],"type":row[2],"position":row[3],"purpose":row[4],"faction_id":str(row[5]) if row.size()>5 else "","index":index}
	return {}

static func faction(faction_id:String)->Dictionary:
	var row:Array=FACTIONS.get(faction_id,[])
	return {} if row.is_empty() else {"id":faction_id,"name":row[0],"region_id":row[1],"recruit_name":row[2],"recruit_class":row[3]}

static func decision(region_id:String)->Dictionary:
	return DECISIONS.get(str(region(region_id).get("decision","")),{})

static func main_locations(region_id:String)->Array:
	var result:Array=[]
	for row in region(region_id).get("locations",[]):
		if str(row[2])=="main":result.append(str(row[0]))
	return result

static func reputation_rank(value:int)->Dictionary:
	for rank in REPUTATION_RANKS:
		if value>=int(rank.minimum) and value<=int(rank.maximum):return rank
	return REPUTATION_RANKS[2]
