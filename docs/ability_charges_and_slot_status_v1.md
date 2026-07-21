# Ability Charges and Slot Status V1

`ability_slot_system.gd` is the shared pure-data model for charged abilities. A slot stores maximum/current charges, sequential or independent recharge timers, inter-cast delay, interrupted lockout, disabled state, and unavailable state.

Sequential recharge restores one charge at a time and then begins the next timer. Independent recharge keeps one timer per spent charge. `reduce_active_recharge` changes only the currently active timer. `ui_state` is the single presentation contract for charge pips/counts, recharge, inter-cast delay, lockout, disabled, and unavailable states.

Ranger Vault/Rain use sequential recharge. Existing Cleric charge behavior remains unchanged in combat, and the shared model's independent mode is covered for a future safe migration rather than forcing a risky behavior change in this feature.

