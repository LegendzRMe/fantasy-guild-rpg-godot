extends RefCounted

const ZONE_ID := "ashwood_marches"
const MANDATORY_ORDER := ["first_battle","first_recruit","caravan","raider_cache","second_recruit","crossing","finale"]
const OPTIONAL_ORDER := ["ruined_chapel","rune_servant"]
const MAP_CONNECTIONS := [
	["first_battle","first_recruit"],["first_recruit","caravan"],["caravan","raider_cache"],
	["raider_cache","second_recruit"],["second_recruit","crossing"],["crossing","finale"],
	["raider_cache","ruined_chapel"],["ruined_chapel","rune_servant"]
]

const RARITY_COLORS := {
	"Poor":Color("8b9199"),
	"Common":Color("f0f0f0"),
	"Uncommon":Color("54d66f"),
	"Rare":Color("4e8cff"),
	"Epic":Color("a86bff"),
	"Legendary":Color("ff9a32")
}

const RECRUITS := {
	"ranger":{"name":"Wren","class":"Ranger","signature":"Trailseeker"},
	"rogue":{"name":"Kestrel","class":"Rogue","signature":"Veiled Strike"},
	"mage":{"name":"Nyx","class":"Mage","signature":"Arcane Focus"},
	"warlock":{"name":"Morrow","class":"Warlock","signature":"Blackflame Pact"}
}

const SPECIAL_HEROES := {
	"survivor_a":{"identifier":"SPECIAL_SURVIVOR_A","visual_identity":"ASHEN OATH","name":"Aldren Vale","class":"Guardian","role":"Tank","personality":"A steadfast former captain carrying the guilt of the lost party.","signature":"Oath of Cinders","reason":"He will not let another company vanish beneath his command.","lead":"He follows the traitor's broken oath-seal north."},
	"survivor_b":{"identifier":"SPECIAL_SURVIVOR_B","visual_identity":"GHOSTFEATHER","name":"Mira Thorn","class":"Ranger","role":"Damage","personality":"A sharp-eyed scout who trusts evidence more than promises.","signature":"Ghostmark Volley","reason":"Your guild finished the rescue her old party abandoned.","lead":"She has mapped unnatural tracks leaving Ashwood."},
	"survivor_c":{"identifier":"SPECIAL_SURVIVOR_C","visual_identity":"BROKEN RUNE","name":"Ilyra Voss","class":"Mage","role":"Damage / Control","personality":"A measured runebreaker fascinated by the force behind Ashwood's corruption.","signature":"Runebreak","reason":"Your guild can survive the answers she intends to uncover.","lead":"She recognizes the hidden hand inside the servant's runes."}
}

const ENCOUNTERS := {
	"first_battle":{
		"id":"first_battle","display_name":"First Ashwood Battle","map_position":Vector2(105,250),"optional":false,
		"scenario":"The Ashwood road narrows beneath scorched branches. Raiders step from the fog, certain that two travelers will be easy prey.",
		"replay_scenario":"Fresh raider bands keep testing the Ashwood road, hoping the guild patrols have finally moved on.",
		"combat_intro":"Raiders step from the Ashwood fog and block the road.",
		"objective":{"type":"elimination","label":"Defeat every attacker"},
		"waves":[["Raider","Raider","Swift","Raider"],["Raider","Archer","Raider"],["Raider","Stalker","Swift","Raider"],["Brute","Brute"]],
		"enemy_health_multiplier":0.30,
		"enemy_health_overrides":{"Swift":20.0,"Stalker":10.0,"Raider":50.0,"Archer":50.0,"Brute":100.0},
		"spawn_all_sides":true,
		"spawn_interval":1.65,
		"first_rewards":{"gold":10,"xp":20,"loot":[]},"repeat_rewards":{"gold":5,"xp":8,"loot_table":"early"},
		"story":"A howl rolls through the pines. Somewhere beyond the road, two different signals answer it.",
		"decisions":[
			{"id":"ranger_path","text":"A sharp whistle answers beyond the pines. Broken branches form an almost deliberate trail.","consequence":"A distant signal fire flickers between the trees. Someone is still holding the ridge.","effects":{"first_recruit_choice":"ranger","unlock":["first_recruit"]}},
			{"id":"rogue_path","text":"A lantern gutters between ruined walls. A shadow slips away, followed by the scrape of steel.","consequence":"A sealed gate shudders in the ruins. Someone on the other side is still fighting.","effects":{"first_recruit_choice":"rogue","unlock":["first_recruit"]}}
		]
	},
	"first_recruit":{
		"id":"first_recruit","display_name":"A Signal in the Trees","map_position":Vector2(265,175),"optional":false,
		"scenario":"An unknown survivor works desperately at a damaged mechanism while raiders close in. Hold the attackers back until the task is complete.",
		"replay_scenario":"Saboteurs have returned to tear apart the restored signal site and silence the warning it sends across Ashwood.",
		"objective":{"type":"protect_task","label":"Protect the stranger","duration":18.0},
		"waves":[["Raider","Swift"],["Archer","Raider"],["Brute","Swift","Raider"]],
		"first_rewards":{"gold":25,"xp":45,"loot":[]},"repeat_rewards":{"gold":12,"xp":18,"loot_table":"early"},
		"story":"The rescued stranger joins the guild. Smoke is already rising beyond the ridge.",
		"decisions":[
			{"id":"road","text":"Stay on the road and move quickly. Smoke is already rising beyond the ridge.","consequence":"The guild reaches the caravan road before the smoke thickens.","effects":{"approach_choice":"road","unlock":["caravan"]}},
			{"id":"investigate","text":"Search the tree line first. The markings resemble those left by the missing party.","consequence":"The markings describe a rune that grows before it strikes. The caravan will have to wait a little longer.","effects":{"approach_choice":"investigate","optional_clue":true,"unlock":["caravan"]}}
		]
	},
	"caravan":{
		"id":"caravan","display_name":"The Ambushed Caravan","map_position":Vector2(435,255),"optional":false,
		"scenario":"A merchant caravan has been pinned against the old road. Its wounded driver keeps the horses calm while raiders strip the wagons.",
		"replay_scenario":"Looters circle the damaged caravan again, convinced something valuable must still be hidden among the wreckage.",
		"objective":{"type":"protect_caravan","label":"Protect the damaged caravan","max_health":650.0,"starting_health":430.0,"objective_aggro_chance":0.78,"objective_threat":45.0},
		"waves":[["Raider","Archer"],["Swift","Raider","Archer"],["Brute","Raider"]],
		"first_rewards":{"gold":30,"xp":55,"loot":[]},"repeat_rewards":{"gold":15,"xp":24,"loot_table":"early"},
		"story":"The attackers break. Some flee into the woods while the wounded call for help.",
		"decisions":[
			{"id":"helped","text":"Stay with the wounded. The merchant watches the road nervously as you unpack the bandages.","consequence":"The merchant will remember who remained behind.","effects":{"merchant_decision":"helped","merchant_helped":true,"unlock":["raider_cache"]}},
			{"id":"chased","text":"The tracks are still fresh. Another minute may be enough for the raiders to disappear.","consequence":"The raiders' supply key is now in your possession. The road ahead has grown quieter.","effects":{"merchant_decision":"chased","raiders_chased":true,"unlock":["raider_cache"]}}
		]
	},
	"raider_cache":{
		"id":"raider_cache","display_name":"Raider Cache","map_position":Vector2(590,180),"optional":false,
		"scenario":"Crates of stolen equipment surround an old watch post. The remaining raiders have armed their strongest fighters.",
		"replay_scenario":"Scattered raiders are rebuilding the cache, reclaiming abandoned weapons and supplies before the guild can remove them.",
		"story_moments":["A scorched oath-seal bears a captain's note: 'Hold the road. No one else disappears for my command.'","A feather-shaped trail mark points away from the obvious path. Its maker trusted observation more than orders."],
		"objective":{"type":"elimination","label":"Break the cache defenders"},
		"waves":[["Raider","Archer","Shaman"],["Brute","Swift","Archer"],["Brute","Shaman","Raider"]],
		"first_rewards":{"gold":35,"xp":65,"loot":[{"rarity":"Common","family":"ashwood_arms"}]},"repeat_rewards":{"gold":18,"xp":30,"loot_table":"middle"},
		"story":"Among the stolen gear are two traces of magic leading deeper into Ashwood. A half-buried chapel path also waits beneath the roots.",
		"decisions":[
			{"id":"mage_path","text":"Blue light pulses beneath the broken observatory. A voice repeats measured words while the air crackles.","consequence":"The observatory pulse steadies. Someone there is still resisting the ritual.","effects":{"second_recruit_choice":"mage","unlock":["second_recruit"],"optional_available":true}},
			{"id":"warlock_path","text":"A black flame burns without smoke among the old stones. Someone speaks softly to an answer that cannot be heard.","consequence":"The black flame bends toward the old stones. Someone there is bargaining for time.","effects":{"second_recruit_choice":"warlock","unlock":["second_recruit"],"optional_available":true}}
		]
	},
	"ruined_chapel":{
		"id":"ruined_chapel","display_name":"Ruined Chapel","map_position":Vector2(585,350),"optional":true,
		"scenario":"Damaged equipment and frantic warnings cover a chapel floor. Expanding runes pulse beneath enemies whose eyes shine with borrowed will.",
		"replay_scenario":"Residual runes beneath the chapel continue attracting scavengers and creatures willing to trade safety for borrowed power.",
		"objective":{"type":"rune_survival","label":"Survive the chapel runes"},
		"waves":[["Shaman","Raider"],["Archer","Swift","Raider"],["Brute","Shaman"]],
		"first_rewards":{"gold":24,"xp":48,"loot":[]},"repeat_rewards":{"gold":13,"xp":24,"loot_table":"middle"},
		"story":"A warning names one member of the lost party as a willing hand. The servant below uses the same expanding rune.",
		"unlocks_on_clear":["rune_servant"]
	},
	"rune_servant":{
		"id":"rune_servant","display_name":"Servant Beneath the Chapel","map_position":Vector2(770,365),"optional":true,
		"scenario":"A named servant rises from the chapel crypt. A rune begins as a point of red light, then spreads across the floor.",
		"replay_scenario":"The empty crypt has become a gathering place for lesser servants attempting to reconstruct their fallen master's rune.",
		"objective":{"type":"rune_boss","label":"Defeat the servant and evade its rune"},
		"waves":[["Raider","Shaman"],["Rune Servant"]],
		"first_rewards":{"gold":45,"xp":70,"loot":[{"rarity":"Uncommon","family":"guardian_cleric"}]},"repeat_rewards":{"gold":18,"xp":32,"loot_table":"middle"},
		"story":"The servant falls. Its rune pattern is now familiar, but the greater hand behind it remains hidden."
	},
	"second_recruit":{
		"id":"second_recruit","display_name":"The Broken Ritual","map_position":Vector2(755,205),"optional":false,
		"scenario":"A lone caster stands inside a failing circle, repeating the final lines of a counter-ritual while enemies close from every side.",
		"replay_scenario":"Power still leaks from the broken ritual circle, drawing raiders, zealots, and creatures that believe they can claim it.",
		"story_moments":["A precise correction is carved beside the ritual: 'The rune is not alive. Something distant is thinking through it.'"],
		"objective":{"type":"ritual_defense","label":"Defend the ritual","duration":20.0,"enemy_health_remaining":0.12},
		"waves":[["Raider","Swift","Archer","Raider"],["Archer","Shaman","Raider"],["Brute","Swift","Archer","Raider"]],
		"first_rewards":{"gold":40,"xp":75,"loot":[]},"repeat_rewards":{"gold":20,"xp":36,"loot_table":"late"},
		"story":"The ritual detonates through the attackers. The caster accepts a place in the guild's active party.",
		"aftermath":"The caster admits the devastating ritual was not truly theirs. An unknown runebreaker granted it as a single-use boon, then vanished before giving a name. The borrowed pattern is already fading, but with time the caster believes they can learn to invoke that spell again.",
		"unlocks_on_clear":["crossing"]
	},
	"crossing":{
		"id":"crossing","display_name":"Ashen Crossing","map_position":Vector2(925,270),"optional":false,
		"scenario":"The full party reaches a narrow crossing beneath the keep. Mixed attackers press from every approach while cinders fall from the canopy.",
		"replay_scenario":"Enemy patrols repeatedly test the Ashen Crossing, searching for a weak watch and a route back through the guild's line.",
		"story_moments":["Three signs converge at the crossing: an oath-seal guarding the road, a scout's hidden feather, and a deliberately broken rune. The lost party's survivors have been resisting in very different ways."],
		"objective":{"type":"survival","label":"Hold the crossing","duration":30.0},
		"waves":[["Raider","Archer","Swift"],["Shaman","Brute","Archer"],["Brute","Swift","Raider","Shaman"],["Brute","Archer","Swift"]],
		"first_rewards":{"gold":50,"xp":85,"loot":[{"rarity":"Common","family":"ashwood_arms"}]},"repeat_rewards":{"gold":24,"xp":42,"loot_table":"late"},
		"story":"The crossing holds. Beyond it, two familiar silhouettes wait beside the gate—heroes the guild did not find in time.",
		"unlocks_on_clear":["finale"]
	},
	"finale":{
		"id":"finale","display_name":"Ashwood Finale","map_position":Vector2(1085,190),"optional":false,
		"scenario":"The unchosen recruits stand beneath the keep with glass-bright eyes. Behind them, the Ashwood servant prepares a rune that shakes the entire grove.",
		"replay_scenario":"Lingering corruption gathers beneath the keep, where lesser servants imitate the escaped traitor's rites and call new attackers from the wood.",
		"objective":{"type":"finale","label":"Subdue the controlled heroes and defeat the Ashwood servant"},
		"waves":[[],["Raider","Shaman","Brute"],["Ashwood Servant"]],
		"first_rewards":{"gold":80,"xp":120,"loot":[{"rarity":"Rare","family":"ashwood_arms"}]},"repeat_rewards":{"gold":35,"xp":58,"loot_table":"finale"},
		"story":"The local servant breaks. The lost party's traitor appears only long enough to call Ashwood a beginning, then vanishes through a darkened rune.",
		"special_choice":true
	}
}

const LOOT_NAMES := {
	"Guardian":["Ashwood Bulwark","Marchwarden Plate"],
	"Cleric":["Cinderlight Focus","Pilgrim's Vestment"],
	"Ranger":["Pinewatch Bow","Trailseeker Jerkin"],
	"Rogue":["Gloamsteel Knives","Silent Road Leathers"],
	"Mage":["Blue Ember Staff","Runespun Mantle"],
	"Warlock":["Blackflame Grimoire","Whisperbound Robe"]
}

static func encounter(encounter_id:String,progress:Dictionary={}) -> Dictionary:
	var result:Dictionary=ENCOUNTERS[encounter_id].duplicate(true)
	if encounter_id=="first_recruit":
		var choice=str(progress.get("first_recruit_choice","ranger"))
		result.display_name="The Hunter's Signal" if choice=="ranger" else "The Sealed Gate"
		result.scenario="An unknown hunter struggles to align a signal beacon while raiders close in. Protect the hunter until the beacon is lit." if choice=="ranger" else "A hooded stranger works at a sealed mechanism while raiders close in. Protect the stranger until the gate opens."
	if encounter_id=="second_recruit":
		var choice=str(progress.get("second_recruit_choice","mage"))
		result.display_name="The Broken Observatory" if choice=="mage" else "The Blackflame Stones"
		result.scenario="A measured voice repeats a counter-spell inside a blue rune circle. Protect the caster until the ritual completes." if choice=="mage" else "A quiet figure bargains with a smokeless flame inside a dark rune circle. Protect the caster until the ritual completes."
	return result

static func all_encounter_ids() -> Array:
	return MANDATORY_ORDER+OPTIONAL_ORDER
