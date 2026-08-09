extends "res://scripts/runtime/app_state.gd"


# Narrow extension contracts implemented by later screen and combat layers.
func cancel_vault_input() -> void:
	pass


func show_hall() -> void:
	pass


func handle_guild_hall_input(_event: InputEvent) -> bool:
	return false


func open_item_card(_entry_id: String, _origin: String = "vault", _comparison: Dictionary = {}, _back_action: Callable = Callable()) -> void:
	pass


func compact_button(_text: String, _callback: Callable, _width: float = 100) -> Button:
	return null


func navigate_item_overlay_back() -> void:
	pass


func shift_active_item_carousel(_direction: int) -> void:
	pass


func update_item_carousel_drag(_offset: float) -> void:
	pass


func finish_item_carousel_drag(_offset: float) -> void:
	pass


func close_item_overlay() -> void:
	pass


func show_roster() -> void:
	pass


func show_tavern() -> void:
	pass


func tavern_time_text(_minutes: float) -> String:
	return ""


func show_team() -> void:
	pass


func show_dungeons() -> void:
	pass

func show_campaign_region(_region_id:String) -> void:
	pass

func show_campaign_location(_region_id:String,_location_id:String) -> void:
	pass

func start_campaign_encounter(_region_id:String,_location_id:String,_kind:String="campaign",_faction_id:String="") -> void:
	pass

func show_council_chamber(_tab:String="Factions") -> void:
	pass

func show_combat_hall() -> void:
	pass

func start_sentinel_testing_zone() -> void:
	pass


func show_zone_map(_zone: int) -> void:
	pass


func show_command_table() -> void:
	pass


func show_market() -> void:
	pass


func show_crafting() -> void:
	pass


func show_profession_trainer() -> void:
	pass


func request_profession_item_action(_hero_id: String, _action: String) -> void:
	pass


func prepare_prototype_parent_set(_hero_id: String) -> void:
	pass


func request_unlearn_profession(_hero_id: String) -> void:
	pass


func show_vault() -> void:
	pass


func show_guild_storage(_tab: String = "vault") -> void:
	pass


func request_material_transfer(_stack_id: String, _target_location: String) -> void:
	pass


func request_storage_transfer(_entry_id: String, _target_location: String) -> void:
	pass


func start_battle(_id: int, _node: int = 0, _party_override: Array = [], _profession_conflict_resolved:bool=false, _party_limit:int=4) -> void:
	pass


func start_testing_zone() -> void:
	pass


func start_warlock_testing_zone() -> void:
	pass


func start_rogue_testing_zone() -> void:
	pass

func start_slayer_testing_zone() -> void:
	pass

func start_priest_testing_zone() -> void:
	pass

func start_shaman_testing_zone() -> void:
	pass

func start_templar_testing_zone() -> void:
	pass

func start_protector_testing_zone() -> void:
	pass


func show_testing_zone_menu() -> void:
	pass


func start_testing_endless(_enemy_level: int) -> void:
	pass


func start_ashwood_battle(_encounter_key: String) -> void:
	pass


func show_ashwood_consequence(_text_value: String) -> void:
	pass


func start_tutorial() -> void:
	pass


func ashwood_story_is_pending(_encounter_key: String) -> bool:
	return false


func resume_pending_ashwood_story(_encounter_key: String) -> void:
	pass


func show_ashwood_victory() -> void:
	pass


func advance_ashwood_consequence() -> void:
	pass


func show_pending_special_choice() -> void:
	pass


func flash(_msg: String) -> void:
	pass
