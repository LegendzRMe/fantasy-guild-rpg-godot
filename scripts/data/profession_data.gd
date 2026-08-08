extends RefCounted

const CookingData = preload("res://scripts/data/cooking_data.gd")

# Prototype profession content. IDs and mechanics are stable; names, costs, XP,
# durations, and choice effects are intentionally editable test values.
const LEARN_COST := 25
const UNLEARN_COST := 20
const DEBUG_TIME_MULTIPLIER := 1.0
const PATTERN_MASTERY_DEFAULT := 3

const PROFESSIONS := {
	"forgecraft":{"display_name":"Forgecraft","description":"Shapes item forms through recipes, synthesis, evolution, and separation.","short_description":"Craft, reshape, and improve equipment.","styles":["Blacksmith","Outfitting"],"station":"Forge"},
	"enchanting":{"display_name":"Enchanting","description":"Controls valid trait inheritance and reclaims magical materials from equipment.","short_description":"Imbue gear and reclaim magical materials.","styles":["Imbuement","Reclamation"],"station":"Enchanter's Table"},
	"alchemy":{"display_name":"Alchemy","description":"Transforms world materials into Catalysts, Stabilizers, Influences, and Essences.","short_description":"Refine materials into useful reagents.","styles":["Distillation","Transmutation"],"station":"Alembic"},
	"inscription":{"display_name":"Inscription","description":"Decodes patterns and crafts reusable, presentation-only ability Runes.","short_description":"Create reusable ability Runes.","styles":["Illumination","Worldscript (working title)"],"station":"Scriptorium"},
	"cooking":{"display_name":"Cooking","description":"Turns Provisions into patron services, mission meals, rest, and recovery.","short_description":"Serve patrons and care for guild Heroes.","styles":["Hospitality","Guild Care"],"station":"Tavern Kitchen"}
}

# Trainer routes remain visible before discovery so the Roster can communicate
# future profession choices without granting them before their world encounter.
const TRAINERS := {
	"forgecraft":{"trainer_name":"Borin Ironhand","location":"Ashwood Marches","unlock_encounter":"caravan","unlock_hint":"Complete The Ambushed Caravan","short_unlock_hint":"Ambushed Caravan"},
	"enchanting":{"trainer_name":"Undiscovered Enchanter","location":"Ashwood Marches","unlock_encounter":"ruined_chapel","unlock_hint":"Complete The Ruined Chapel","short_unlock_hint":"Ruined Chapel"},
	"alchemy":{"trainer_name":"Mira Greenbottle","location":"Mirefang Wilds","unlock_encounter":"","unlock_hint":"Reach Mirefang Wilds","short_unlock_hint":"Reach Mirefang Wilds"},
	"inscription":{"trainer_name":"Undiscovered Rune Archivist","location":"Ashwood Marches","unlock_encounter":"rune_servant","unlock_hint":"Defeat the Rune Servant","short_unlock_hint":"Rune Servant"},
	"cooking":{"trainer_name":"Tavern Kitchen","location":"Your Tavern","unlock_encounter":"","unlock_hint":"Visit the Tavern Kitchen","short_unlock_hint":"Tavern Kitchen"}
}

const RANK_REQUIREMENTS := {
	1:{"xp":20,"prestige_rank":0,"milestones":["profession_introduction"]},
	2:{"xp":75,"prestige_rank":1,"milestones":["first_order"]},
	3:{"xp":175,"prestige_rank":2,"milestones":["advanced_work"]},
	4:{"xp":350,"prestige_rank":3,"milestones":["pattern_mastered"]},
	5:{"xp":600,"prestige_rank":4,"milestones":["signature_work"]}
}

const CHOICES := {
	"forgecraft":[
		[{"id":"forge_core_form","style":0,"name":"Core Form [Prototype]","description":"Choose a core parent family to narrow Discovery Synthesis."},{"id":"forge_flexible_parentage","style":1,"name":"Flexible Parentage [Prototype]","description":"Allow one related parent and compatible hybrid outcomes."}],
		[{"id":"forge_guild_standard","style":0,"name":"Guild Standard [Prototype]","description":"Unlock repeatable guild-standard patterns."},{"id":"forge_refit","style":1,"name":"Refit [Prototype]","description":"Unlock controlled same-family item refits."}],
		[{"id":"forge_planned_evolution","style":0,"name":"Planned Evolution [Prototype]","description":"Unlock deliberate rarity-evolution orders."},{"id":"forge_hero_variant","style":1,"name":"Hero Variant [Prototype]","description":"Unlock hero-specific recipe variants."}],
		[{"id":"forge_tempered_pattern","style":0,"name":"Tempered Pattern [Prototype]","description":"Marks mastered standards for future routing."},{"id":"forge_hybrid_branch","style":1,"name":"Hybrid Branch [Prototype]","description":"Adds controlled hybrid discovery branches."}],
		[{"id":"forge_blacksmith_capstone","style":0,"name":"Blacksmith Capstone [Prototype]","description":"Prototype advanced certainty capstone."},{"id":"forge_outfitting_capstone","style":1,"name":"Outfitting Capstone [Prototype]","description":"Prototype advanced adaptation capstone."}]
	],
	"enchanting":[
		[{"id":"enchant_guided_inheritance","style":0,"name":"Guided Inheritance [Prototype]","description":"Mark one compatible parent trait as preferred."},{"id":"enchant_targeted_reclamation","style":1,"name":"Targeted Reclamation [Prototype]","description":"Prioritize one valid Trait Shard family."}],
		[{"id":"enchant_protect_trait","style":0,"name":"Trait Ward [Prototype]","description":"Use a Stabilizer to protect a compatible trait."},{"id":"enchant_essence_sorting","style":1,"name":"Essence Sorting [Prototype]","description":"Reveal valid Essence identities before reclamation."}],
		[{"id":"enchant_refinement","style":0,"name":"Lineage Refinement [Prototype]","description":"Unlock limited improvement of inherited traits."},{"id":"enchant_echo_recovery","style":1,"name":"Echo Recovery [Prototype]","description":"Unlock rare Lineage Echo recovery."}],
		[{"id":"enchant_capacity_reading","style":0,"name":"Capacity Reading [Prototype]","description":"Expose full rarity and compatibility capacity."},{"id":"enchant_boss_analysis","style":1,"name":"Boss Analysis [Prototype]","description":"Expose Boss identity during reclamation."}],
		[{"id":"enchant_imbuement_capstone","style":0,"name":"Imbuement Capstone [Prototype]","description":"Prototype lineage capstone."},{"id":"enchant_reclamation_capstone","style":1,"name":"Reclamation Capstone [Prototype]","description":"Prototype recovery capstone."}]
	],
	"alchemy":[
		[{"id":"alchemy_purify","style":0,"name":"Purify [Prototype]","description":"Combine lower-quality materials into a higher-quality output."},{"id":"alchemy_convert","style":1,"name":"Convert [Prototype]","description":"Convert an allowed material family at meaningful loss."}],
		[{"id":"alchemy_stable_batch","style":0,"name":"Stable Batch [Prototype]","description":"Unlock Defensive Stabilizer batches."},{"id":"alchemy_substitute","style":1,"name":"Material Substitute [Prototype]","description":"Replace one allowed known-recipe input at a cost."}],
		[{"id":"alchemy_pure_essence","style":0,"name":"Pure Essence [Prototype]","description":"Refine weaker Essences into Pure Essence."},{"id":"alchemy_regional_influence","style":1,"name":"Regional Influence [Prototype]","description":"Push discovery toward a known region."}],
		[{"id":"alchemy_advanced_catalyst","style":0,"name":"Advanced Catalyst [Prototype]","description":"Unlock advanced rarity catalysts."},{"id":"alchemy_element_shift","style":1,"name":"Element Shift [Prototype]","description":"Unlock controlled elemental substitutions."}],
		[{"id":"alchemy_distillation_capstone","style":0,"name":"Distillation Capstone [Prototype]","description":"Prototype purity capstone."},{"id":"alchemy_transmutation_capstone","style":1,"name":"Transmutation Capstone [Prototype]","description":"Prototype conversion capstone."}]
	],
	"inscription":[
		[{"id":"inscription_rune_crafting","style":0,"name":"Rune Crafting [Prototype]","description":"Craft a discovered pattern into a reusable Rune."},{"id":"inscription_decode_pattern","style":1,"name":"Decode Pattern [Prototype]","description":"Complete a pattern from Rune fragments."}],
		[{"id":"inscription_theme_adaptation","style":0,"name":"Theme Adaptation [Prototype]","description":"Adapt a Rune's presentation palette."},{"id":"inscription_region_script","style":1,"name":"Region Script [Prototype]","description":"Decode regional visual identities without making world choices."}],
		[{"id":"inscription_theme_set","style":0,"name":"Themed Set [Prototype]","description":"Unlock grouped visual Rune sets."},{"id":"inscription_faction_decode","style":1,"name":"Faction Decode [Prototype]","description":"Reveal faction pattern options only."}],
		[{"id":"inscription_master_illumination","style":0,"name":"Master Illumination [Prototype]","description":"Unlock advanced visual adaptations."},{"id":"inscription_boss_script","style":1,"name":"Boss Script [Prototype]","description":"Decode Boss pattern fragments."}],
		[{"id":"inscription_illumination_capstone","style":0,"name":"Illumination Capstone [Prototype]","description":"Prototype visual-theme capstone."},{"id":"inscription_world_capstone","style":1,"name":"Worldscript Capstone [Prototype]","description":"Prototype discovery capstone; working title."}]
	],
	"cooking":CookingData.PROFESSION_CHOICES
}

const RECIPES := {
	"forge_ashwood_bulwark":{"profession":"forgecraft","display_name":"Ashwood Bulwark Pattern","action":"synthesis","rank":0,"duration":25.0,"xp":20,"mastery_required":3,"input_items":3,"compatible_family":"chest","output_definition_id":"ashwood_bulwark","known_form":true},
	"forge_marchwarden_evolution":{"profession":"forgecraft","display_name":"Marchwarden Evolution [Prototype]","action":"evolution","rank":2,"duration":45.0,"xp":40,"mastery_required":3,"input_items":3,"compatible_family":"chest","input_rarity":"Uncommon","output_definition_id":"marchwarden_plate","output_rarity":"Rare","materials":[{"material_id":"basic_catalyst","quantity":1}],"known_form":true},
	"alchemy_basic_catalyst":{"profession":"alchemy","display_name":"Basic Catalyst","action":"material","rank":0,"duration":12.0,"xp":12,"mastery_required":3,"materials":[{"material_id":"ore","quantity":3},{"material_id":"herbs","quantity":1}],"outputs":[{"material_id":"basic_catalyst","quantity":1}]},
	"alchemy_defensive_stabilizer":{"profession":"alchemy","display_name":"Defensive Stabilizer","action":"material","rank":1,"duration":16.0,"xp":14,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"herbs","quantity":3},{"material_id":"dust","quantity":1}],"outputs":[{"material_id":"defensive_stabilizer","quantity":1}]},
	"alchemy_ashwood_influence":{"profession":"alchemy","display_name":"Ashwood Regional Influence","action":"material","rank":1,"duration":18.0,"xp":16,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"herbs","quantity":2},{"material_id":"ore","quantity":2}],"outputs":[{"material_id":"ashwood_influence","quantity":1}]},
	"alchemy_pure_essence":{"profession":"alchemy","display_name":"Pure Essence","action":"material","rank":2,"duration":24.0,"xp":22,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"arcane_essence","quantity":3}],"outputs":[{"material_id":"pure_essence","quantity":1}]},
	"alchemy_material_substitute":{"profession":"alchemy","display_name":"Material Substitute [Prototype]","action":"material","rank":1,"duration":15.0,"xp":14,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"herbs","quantity":4}],"outputs":[{"material_id":"ore_substitute","quantity":2}]},
	"inscription_frostfall":{"profession":"inscription","display_name":"Frostfall Rune","action":"rune","rank":0,"duration":20.0,"xp":20,"mastery_required":3,"pattern_id":"pattern_frostfall","rune_id":"rune_frostfall","materials":[{"material_id":"dust","quantity":3}]},
	"inscription_runic_bolt":{"profession":"inscription","display_name":"Runic Bolt Rune","action":"rune","rank":0,"duration":20.0,"xp":20,"mastery_required":3,"pattern_id":"pattern_runic_bolt","rune_id":"rune_runic_bolt","materials":[{"material_id":"ore","quantity":2},{"material_id":"dust","quantity":2}]},
	"cooking_common_table_meal":{"profession":"cooking","display_name":"Common Table Meal","action":"meal","rank":0,"duration":10.0,"xp":12,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":1}],"meal_id":"common_table_meal","servings":1},
	"cooking_restorative_broth":{"profession":"cooking","display_name":"Restorative Broth","action":"meal","rank":1,"duration":14.0,"xp":15,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":1}],"meal_id":"restorative_broth","servings":1},
	"cooking_adventurers_supper":{"profession":"cooking","display_name":"Adventurer's Supper","action":"meal","rank":3,"duration":20.0,"xp":22,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":2}],"meal_id":"adventurers_supper","servings":1},
	"cooking_hearthside_gathering":{"profession":"cooking","display_name":"Hearthside Gathering","action":"meal","rank":3,"duration":20.0,"xp":22,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":2}],"meal_id":"hearthside_gathering","servings":1},
	"cooking_craftsfolks_table":{"profession":"cooking","display_name":"Craftsfolk's Table","action":"meal","rank":3,"duration":20.0,"xp":22,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":2}],"meal_id":"craftsfolks_table","servings":1},
	"cooking_travellers_welcome":{"profession":"cooking","display_name":"Traveller's Welcome","action":"meal","rank":3,"duration":20.0,"xp":22,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":2}],"meal_id":"travellers_welcome","servings":1},
	"cooking_fortifying_meal":{"profession":"cooking","display_name":"Fortifying Meal","action":"meal","rank":3,"duration":20.0,"xp":22,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":2}],"meal_id":"fortifying_meal","servings":1},
	"cooking_hefty_meal":{"profession":"cooking","display_name":"Hefty Meal","action":"meal","rank":3,"duration":20.0,"xp":22,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":2}],"meal_id":"hefty_meal","servings":1},
	"cooking_fatty_meal":{"profession":"cooking","display_name":"Fatty Meal","action":"meal","rank":3,"duration":20.0,"xp":22,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":2}],"meal_id":"fatty_meal","servings":1},
	"cooking_hasty_meal":{"profession":"cooking","display_name":"Hasty Meal","action":"meal","rank":3,"duration":20.0,"xp":22,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":2}],"meal_id":"hasty_meal","servings":1},
	"cooking_house_banquet":{"profession":"cooking","display_name":"House Banquet","action":"meal","rank":5,"duration":35.0,"xp":40,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":8}],"meal_id":"house_banquet","servings":1},
	"cooking_guild_feast":{"profession":"cooking","display_name":"Guild Feast","action":"meal","rank":5,"duration":35.0,"xp":40,"mastery_required":3,"auto_known":true,"materials":[{"material_id":"provisions","quantity":8}],"meal_id":"guild_feast","servings":1}
	,"cooking_simple_stew":{"profession":"cooking","display_name":"Simple Stew","action":"meal","rank":0,"duration":8.0,"xp":8,"mastery_required":3,"auto_known":true,"prototype_tavern":true,"materials":[{"material_id":"provisions","quantity":1}],"meal_id":"simple_stew","servings":1}
	,"cooking_recovery_broth_hook":{"profession":"cooking","display_name":"Recovery Broth","action":"meal","rank":0,"duration":8.0,"xp":8,"mastery_required":3,"auto_known":true,"prototype_tavern":true,"materials":[{"material_id":"provisions","quantity":1}],"meal_id":"recovery_broth_hook","servings":1}
	,"cooking_recruiters_platter":{"profession":"cooking","display_name":"Recruiter's Platter","action":"meal","rank":0,"duration":10.0,"xp":8,"mastery_required":3,"auto_known":true,"prototype_tavern":true,"materials":[{"material_id":"provisions","quantity":2}],"meal_id":"recruiters_platter","servings":1}
	,"cooking_expedition_rations":{"profession":"cooking","display_name":"Expedition Rations","action":"meal","rank":0,"duration":10.0,"xp":8,"mastery_required":3,"auto_known":true,"prototype_tavern":true,"materials":[{"material_id":"provisions","quantity":2}],"meal_id":"expedition_rations","servings":1}
}

const RUNES := {
	"rune_frostfall":{"display_name":"Frostfall Rune","class_id":"mage","ability_id":"mage:q","presentation":{"display_name":"Frostfall","symbol":"❄","color":"7bd8ff","effect_tint":"8edfff","impact_label":"FROST SHATTER"}},
	"rune_runic_bolt":{"display_name":"Runic Bolt Rune","class_id":"guardian","ability_id":"guardian:q","presentation":{"display_name":"Runic Bolt","symbol":"◇","color":"c692ff","effect_tint":"bb82ff","impact_label":"RUNE IMPACT"}}
}

const STARTER_MERCHANT_RECIPES := ["forge_ashwood_bulwark","alchemy_basic_catalyst"]
const STARTER_MERCHANT_PATTERNS := ["pattern_frostfall","pattern_runic_bolt"]

const TRAIT_CAPACITY := {"Common":1,"Uncommon":2,"Rare":3,"Epic":4,"Legendary":4}

static func profession_name(profession_id:String)->String:
	return str(PROFESSIONS.get(profession_id,{}).get("display_name","None"))

static func recipe(recipe_id:String)->Dictionary:
	return RECIPES.get(recipe_id,{})
