# Shared Block Charges V1

**Lifecycle:** Current contract.

`block_charge_system.gd` owns class-neutral charge storage, grants, caps, consumption, and UI counts. Guardian, Rogue, and Slayer may author different grants, but they must not create separate Block implementations.

An eligible hostile Basic Attack consumes one charge through the shared damage pipeline and receives the authored Armor value. Basic Abilities, Heroics, periodic damage, friendly actions, immunity, Blind misses, and Evaded actions do not consume charges. Evasion is checked before Block, so an Evaded Basic Attack preserves every charge and triggers no Block on-hit behavior.

Slayer's Reflexive Block grants three charges after a valid Dive and caps the shared pool at four. Its current authored Block Armor is 75. Testing and UI should read the shared charge state rather than class-specific fields.

