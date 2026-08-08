# Named Shield Sources V1

**Lifecycle:** Current contract.

Every Shield contribution is stored in `shield_sources` with its own `source_id`, creator, amount, and optional duration. The unit's `shield` field is the aggregate. Damage and expiration reduce the contributing source as well as the aggregate, allowing multiple mechanics to coexist without overwriting one another.

Source-specific caps must be calculated against that source, not the aggregate Shield. Shadow Shield replaces only the previous `slayer_shadow_shield` source. Unending Thirst adds only up to 25% of Slayer's current maximum Health, coexists with Shadow Shield and unrelated Shields, synchronizes after absorption, and clamps to its lower cap when Metamorphosis ends. Its own decay removes only `slayer_unending_thirst` amounts.

