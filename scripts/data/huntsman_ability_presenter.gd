extends RefCounted

const HuntsmanData = preload("res://scripts/data/huntsman_data.gd")
const HuntsmanSystem = preload("res://scripts/systems/huntsman_system.gd")

static func amount(hero:Dictionary, value:float) -> int:
	return floori(HuntsmanSystem.ability_amount(hero, value))

static func details(hero:Dictionary, key:String, heroic_id:String="") -> Dictionary:
	var worgen := HuntsmanSystem.is_worgen(hero)
	match key:
		"Q":
			if worgen: return {"key":"Q","title":"Razor Swipe","meta":"Cooldown: 4 seconds • Worgen movement","description":"Lunge a short distance and deal %d Physical damage to nearby enemies." % amount(hero, HuntsmanData.VALUES.swipe_damage),"sections":[{"heading":"FORM COOLDOWNS","body":"Razor Swipe and Gilnean Cocktail keep independent cooldowns while hidden by the other form."}],"note":"This does not transform Huntsman."}
			return {"key":"Q","title":"Gilnean Cocktail","meta":"Cooldown: %s seconds • Human projectile" % str(HuntsmanSystem.q_cooldown(hero, "human")),"description":"Hit the first enemy for %d Physical damage, then explode in a cone behind it for %d. The primary target cannot also take explosion damage." % [amount(hero, HuntsmanData.VALUES.cocktail_impact), amount(hero, HuntsmanData.VALUES.cocktail_explosion)],"sections":[],"note":"This does not transform Huntsman."}
		"W": return {"key":"W","title":"Inner Beast","meta":"Cooldown: 20 seconds • Self","description":"Gain 50% Attack Speed for %s seconds. Successful Basic Attacks refresh the duration and reduce this cooldown." % str(HuntsmanSystem.inner_beast_duration(hero)),"sections":[],"note":"The effect persists across form changes."}
		"E":
			if worgen: return {"key":"E","title":"Disengage","meta":"Shared cooldown: %s seconds • Aimed escape" % str(HuntsmanSystem.e_cooldown(hero)),"description":"Leap toward the chosen location and become Human. Disengage deals no damage.","sections":[],"note":"Darkflight and Disengage share one cooldown."}
			return {"key":"E","title":"Darkflight","meta":"Shared cooldown: %s seconds • Enemy target" % str(HuntsmanSystem.e_cooldown(hero)),"description":"Leap to an enemy, deal %d Physical damage, and become Worgen." % amount(hero, HuntsmanData.VALUES.darkflight_damage),"sections":[],"note":"Darkflight and Disengage share one cooldown."}
		"R":
			if heroic_id == "huntsman_l15_r1": return {"key":"R","title":"Go for the Throat","meta":"Cooldown: 80 seconds • Enemy target","description":"Leap to an enemy as Worgen and deal %d Physical damage. A kill grants one free repeat for 10 seconds." % amount(hero, HuntsmanData.VALUES.r1_damage),"sections":[],"note":"Unleashed increases damage and resets applicable cooldowns on a kill."}
			if heroic_id == "huntsman_l15_r2": return {"key":"R","title":"Marked for the Kill","meta":"Cooldown: 60 seconds • Human projectile","description":"Become Human and fire a long projectile for %d Physical damage. Reveal and mark the first enemy hit for 5 seconds. Qualifying actions add a level-scaled Armor-reduction stack." % amount(hero, HuntsmanData.VALUES.r2_damage),"sections":[{"heading":"REACTIVATE","body":"Reactivate once to leap to the marked prey and become Worgen without dealing damage or adding a stack."}],"note":"Only one marked target can be active per Huntsman."}
			return {"key":"R","title":"Heroic Ability","meta":"Unlocks at Level 15","description":"Choose Go for the Throat or Marked for the Kill from the Talent tree.","sections":[],"note":""}
		"D": return {"key":"D","title":"Curse of the Worgen","meta":"Passive Trait • Two forms","description":"Human fights at range. Worgen attacks in melee, gains level-scaled Armor, and deals 40% more Basic Attack damage.","sections":[{"heading":"FORM CHANGE","body":"Darkflight and Go for the Throat enter Worgen form. Disengage and Marked for the Kill enter Human form."}],"note":"The Trait cannot be activated manually."}
	return {"key":key,"title":"Huntsman Ability","meta":"","description":"","sections":[],"note":""}
