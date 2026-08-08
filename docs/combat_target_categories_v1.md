# Combat Target Categories V1

**Lifecycle:** Current contract.

`combat_target_category_system.gd` normalizes combatants into these categories:

| Category | Immediate effects | Encounter quest progress |
|---|---:|---:|
| Standard | Yes | Yes |
| Elite | Yes | Yes |
| Named | Yes | Yes |
| Boss | Yes | Yes |
| Enemy hero | Yes | Yes |
| Summon | Yes | No |
| Temporary | Yes when hostile and damageable | No |
| Training | No; dedicated testing-only category | No |
| Object | Only when explicitly authored as damageable | No |

Immediate combat effects include damage, healing triggered by resolved damage, Metamorphosis contacts, Dive marks, Block grants, and Fiery Brand. Long-lived encounter progression such as Unending Hatred and Unbound excludes summons, temporary units, training targets, and objects so farming generated units cannot advance quests. Each new mechanic must explicitly select immediate or quest qualification instead of inferring from a display name.

When a converted source mechanic scales "per enemy Hero," the default PvE cap is five qualifying immediate contacts unless its class specification explicitly overrides that limit. Divine Star healing amplification and Lightbomb Shield generation use this rule; Piercing Light instead uses quest qualification and therefore excludes summons and temporary combat targets.
