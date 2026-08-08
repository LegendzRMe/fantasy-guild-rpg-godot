# Slayer Geometry Calibration

**Lifecycle:** Calibration note. Values are provisional until live playtesting.

The project converts source range units with the existing `185 / 5.5` world-unit scale. Public sources do not provide collision widths or safe landing geometry, so every estimate is centralized in `SlayerData.SPACE`.

| Contract | Current prototype value |
|---|---:|
| Basic Attack range | 1.2 source units |
| Dive range | 4.5 source units |
| Dive landing offset | 52 world units |
| Sweeping Strike travel | 3.25 source units |
| Sweeping Strike half-width | 1.25 source units |
| Metamorphosis radius | 2.5 source units |
| The Hunt | Any valid enemy on the active battlefield |

Dive searches around its target for a collision-safe landing before spending cooldown or dealing damage. Sweeping Strike evaluates a swept segment; baseline respects blocker-safe movement, while completed Unbound crosses blockers. Immolation always queries Slayer's current Basic Attack range rather than caching a radius. Metamorphosis clamps its chosen center to authored range and arena bounds. The Hunt still requires a valid safe landing.

In Slayer Range, `Shift+1` through `Shift+9` and `Shift+0` load the ten representative builds. Observe whether Dive reads as arriving beside rather than inside targets, Sweeping Strike contacts match its visual width, and arena-edge casts remain safe. Record live observations here before changing centralized values.

