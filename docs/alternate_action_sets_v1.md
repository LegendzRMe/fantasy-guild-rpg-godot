# Alternate Action Sets V1

`alternate_action_set_system.gd` stores stable set IDs and slot-to-ability mappings. Activating a set changes the presented and executed Q/W/E ability IDs without moving the physical buttons or changing D/R. Alternate cooldowns are explicit and continue updating while hidden.

Rogue uses `normal` (`rogue_q`, `rogue_w`, `rogue_e`) and `stealth` (`rogue_stealth_q`, `rogue_stealth_w`, `rogue_stealth_e`). The system is deliberately not Rogue-specific so later forms, stances, weapon sets, possession, and enemy transformations can use the same contract.
